module frontend.inferringType;

@safe @nogc pure nothrow:

import diag : Diag;
import frontend.ast : TypeAst;
import frontend.checkCtx : addDiag, CheckCtx;
import frontend.instantiate : instantiateStructNeverDelay, instantiateStructInst, tryGetTypeArg, TypeParamsScope;
import frontend.programState : ProgramState;
import frontend.typeFromAst : typeFromAst;
import model :
	asStructInst,
	asTypeParam,
	asUnion,
	body_,
	ClosureField,
	CommonTypes,
	decl,
	Expr,
	FunDecl,
	FunsMap,
	isBogus,
	isStructInst,
	isTypeParam,
	isUnion,
	Local,
	matchStructBody,
	matchType,
	Param,
	range,
	RecordField,
	StructsAndAliasesMap,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	TypeParam;
import util.bools : Bool, False, True;
import util.cell : Cell, cellGet, cellSet;
import util.collection.arr : Arr, at, emptyArr, emptyArr_mut;
import util.collection.arrUtil : find, findIndex, findPtr, map, mapOrNone, mapZipOrNone;
import util.collection.mutArr : MutArr;
import util.memory : allocate;
import util.opt : has, force, none, noneMut, Opt, some;
import util.ptr : Ptr, ptrEquals;
import util.sourceRange : SourceRange;
import util.sym : Sym, symEq;
import util.util : todo;

immutable(Ptr!Expr) allocExpr(Alloc)(ref Alloc alloc, immutable Expr e) {
	return allocate!Expr(alloc, e);
}

struct LambdaInfo {
	immutable Arr!Param lambdaParams;
	MutArr!(immutable Ptr!Local) locals = MutArr!(immutable Ptr!Local)();
	MutArr!(immutable Ptr!ClosureField) closureFields = MutArr!(immutable Ptr!ClosureField)();
}

struct ExprCtx {
	Ptr!CheckCtx checkCtx;
	immutable Ptr!StructsAndAliasesMap structsAndAliasesMap;
	immutable Ptr!FunsMap funsMap;
	immutable Ptr!CommonTypes commonTypes;
	immutable Ptr!FunDecl outermostFun;

	// Locals of the function or message. Lambda locals are stored in the lambda.
	// (Note the Let stores the local and this points to that.)
	MutArr!(immutable Ptr!Local) messageOrFunctionLocals = MutArr!(immutable Ptr!Local)();
	// These are pointers because MutArr currently only works on copyable values,
	// and LambdaInfo should not be copied.
	MutArr!(Ptr!LambdaInfo) lambdas = MutArr!(Ptr!LambdaInfo)();
}

ref ProgramState programState(ref ExprCtx ctx) {
	return ctx.checkCtx.deref.programState.deref;
}

void addDiag2(Alloc)(ref Alloc alloc, ref ExprCtx ctx, immutable SourceRange range, immutable Diag diag) {
	addDiag(alloc, ctx.checkCtx.deref, range, diag);
}

ref immutable(ProgramState) programState(ref immutable ExprCtx ctx) {
	return ctx.checkCtx.programState;
}

immutable(Type) typeFromAst2(Alloc)(ref Alloc alloc, ref ExprCtx ctx, ref immutable TypeAst typeAst) {
	return typeFromAst!Alloc(
		alloc,
		ctx.checkCtx.deref,
		typeAst,
		ctx.structsAndAliasesMap,
		TypeParamsScope(ctx.outermostFun.typeParams),
		noneMut!(Ptr!(MutArr!(Ptr!(StructInst)))));
}

immutable(Arr!Type) typeArgsFromAsts(Alloc)(ref Alloc alloc, ref ExprCtx ctx, ref immutable Arr!TypeAst typeAsts) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst2(alloc, ctx, it));
}

struct SingleInferringType {
	@safe @nogc pure nothrow:

	Cell!(immutable Opt!Type) type;

	this(immutable Opt!(Type) t) {
		type = Cell!(immutable Opt!Type)(t);
	}
}

immutable(Opt!Type) tryGetInferred(ref const SingleInferringType a) {
	return cellGet!(immutable Opt!Type)(a.type);
}

struct InferringTypeArgs {
	@safe @nogc pure nothrow:

	immutable Arr!TypeParam params;
	Arr!SingleInferringType args;

	static InferringTypeArgs none() {
		return InferringTypeArgs(emptyArr!TypeParam, emptyArr_mut!SingleInferringType);
	}
}

// Gets the type system to ensure that we set the expected type.
struct CheckedExpr {
	immutable Expr expr;
}

// Inferring type args are in 'a', not 'b'
immutable(Bool) matchTypesNoDiagnostic(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Type expectedType,
	ref immutable Type setType,
	ref InferringTypeArgs aInferringTypeArgs,
	immutable Bool allowConvertAToBUnion
) {
	immutable SetTypeResult result =
		checkAssignability(alloc, programState, expectedType, setType, aInferringTypeArgs, allowConvertAToBUnion);
	return matchSetTypeResult(
		result,
		(ref immutable SetTypeResult.Set) => True,
		(ref immutable SetTypeResult.Keep) => True,
		(ref immutable SetTypeResult.Fail) => False);
}

immutable(Bool) matchTypesNoDiagnostic(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Type a,
	ref immutable Type b,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	return matchTypesNoDiagnostic(alloc, programState, a, b, aInferringTypeArgs, False);
}

struct Expected {
	@safe @nogc pure nothrow:

	Cell!(immutable Opt!Type) type;
	InferringTypeArgs inferringTypeArgs;

	this(immutable Opt!Type init) {
		type = Cell!(immutable Opt!Type)(init);
		inferringTypeArgs = InferringTypeArgs.none;
	}
	this(immutable Opt!Type init, InferringTypeArgs ita) {
		type = Cell!(immutable Opt!Type)(init);
		inferringTypeArgs = ita;
	}

	static Expected infer() {
		return Expected(none!Type);
	}
}

immutable(Opt!Type) tryGetInferred(ref const Expected expected) {
	return cellGet(expected.type);
}

// TODO: if we have a bogus expected type we should probably not be doing any more checking at all?
immutable(Bool) isBogus(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	return Bool(has(t) && isBogus(force(t)));
}

Expected copyWithNewExpectedType(ref Expected expected, immutable Type type) {
	return Expected(some!Type(type), expected.inferringTypeArgs);
}

immutable(Opt!Type) shallowInstantiateType(ref const Expected expected) {
	immutable Opt!Type t = cellGet(expected.type);
	if (has(t) && isTypeParam(force(t))) {
		const Opt!(Ptr!SingleInferringType) typeArg =
			tryGetTypeArgFromInferringTypeArgs(expected.inferringTypeArgs, asTypeParam(force(t)));
		return has(typeArg) ? tryGetInferred(force(typeArg)) : none!Type;
	} else
		return t;
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeFor(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Expected expected,
	immutable Type t,
) {
	return tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, expected.inferringTypeArgs);
}

immutable(Opt!Type) tryGetDeeplyInstantiatedType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Expected expected,
) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t)
		? tryGetDeeplyInstantiatedTypeFor(alloc, programState, expected, force(t))
		: none!Type;
}

immutable(Bool) hasExpected(ref const Expected expected) {
	return has(tryGetInferred(expected));
}

immutable(CheckedExpr) bogusWithoutAffectingExpected(immutable SourceRange range) {
	return CheckedExpr(Expr(range, Expr.Bogus()));
}

immutable(CheckedExpr) bogusWithType(ref Expected expected, immutable SourceRange range, immutable Type setType) {
	cellSet(expected.type, some!Type(setType));
	return bogusWithoutAffectingExpected(range);
}

immutable(CheckedExpr) bogus(ref Expected expected, immutable SourceRange range) {
	return bogusWithType(expected, range, Type(Type.Bogus()));
}

immutable(CheckedExpr) bogusWithoutChangingExpected(ref Expected expected, immutable SourceRange range) {
	return hasExpected(expected)
		? bogusWithoutAffectingExpected(range)
		: bogus(expected, range);
}

immutable(Type) inferred(ref const Expected expected) {
	immutable Opt!Type opt = tryGetInferred(expected);
	return force(opt);
}

immutable(Bool) isExpectingString(ref const Expected expected, immutable Ptr!StructInst stringStructInst) {
	immutable Opt!Type t = tryGetInferred(expected);
	immutable Type stringType = immutable Type(stringStructInst);
	return immutable Bool(has(t) && typeEquals(force(t), stringType));
}

immutable(CheckedExpr) check(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref Expected expected,
	immutable Type exprType,
	ref immutable Expr expr,
) {
	// Allow implicitly converting to union
	// TODO: implicitly convert to Fut by wrapping in 'resolved'
	immutable Opt!Type t = tryGetInferred(expected);
	if (has(t) && isStructInst(force(t)) && isStructInst(exprType)) {
		immutable Ptr!StructInst expectedStruct = asStructInst(force(t));
		immutable Ptr!StructInst exprStruct = asStructInst(exprType);
		immutable StructBody body_ = body_(expectedStruct.decl.deref);
		if (isUnion(body_)) {
			immutable Arr!(Ptr!StructInst) members = asUnion(body_).members;
			// This is like 't' but with the union's type parameters
			immutable Opt!size_t opMemberIndex = findIndex(members, (ref immutable Ptr!StructInst it) =>
				ptrEquals(it.decl, exprStruct.decl));
			if (has(opMemberIndex)) {
				immutable size_t memberIndex = force(opMemberIndex);
				immutable Ptr!StructInst instantiatedExpectedUnionMember =
					instantiateStructInst(alloc, programState(ctx), at(members, memberIndex), expectedStruct);
				immutable(SetTypeResult) setTypeResult = setTypeNoDiagnosticWorker_forStructInst(
					alloc,
					programState(ctx),
					instantiatedExpectedUnionMember,
					exprStruct,
					expected.inferringTypeArgs,
					False);
				return matchSetTypeResult!CheckedExpr(
					setTypeResult,
					(ref immutable SetTypeResult.Set) =>
						todo!(immutable CheckedExpr)("should never happen?"),
					(ref immutable SetTypeResult.Keep) {
						immutable Opt!Type opU = tryGetDeeplyInstantiatedType(alloc, programState(ctx), expected);
						if (!has(opU))
							return todo!(immutable CheckedExpr)("expected check -- not deeply instantiated");
						return immutable CheckedExpr(immutable Expr(range(expr), Expr.ImplicitConvertToUnion(
							asStructInst(force(opU)),
							memberIndex,
							allocExpr(alloc, expr))));
					},
					(ref immutable SetTypeResult.Fail) {
						addDiag2(alloc, ctx, range(expr), immutable Diag(Diag.TypeConflict(force(t), exprType)));
						return immutable CheckedExpr(Expr(range(expr), Expr.Bogus()));
					});
			}
		}
	}

	if (setTypeNoDiagnostic(alloc, programState(ctx), expected, exprType))
		return CheckedExpr(expr);
	else {
		// Failed to set type. This happens if there was already an inferred type.
		addDiag2(alloc, ctx, expr.range(), immutable Diag(Diag.TypeConflict(force(t), exprType)));
		return bogus(expected, expr.range());
	}
}

// Note: this may infer type parameters
immutable(Bool) setTypeNoDiagnostic(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref Expected expected,
	immutable Type setType,
) {
	immutable SetTypeResult typeToSet = checkAssignabilityOpt!Alloc(alloc, programState, tryGetInferred(expected), setType, expected.inferringTypeArgs);
	return matchSetTypeResult(
		typeToSet,
		(ref immutable SetTypeResult.Set s) {
			cellSet(expected.type, some(s.type));
			return True;
		},
		(ref immutable SetTypeResult.Keep) =>
			True,
		(ref immutable SetTypeResult.Fail) =>
			False);
}

struct StructAndField {
	immutable Ptr!StructInst structInst;
	immutable Ptr!RecordField field;
}

immutable(Opt!StructAndField) tryGetRecordField(immutable Type targetType, immutable Sym fieldName) {
	return matchType(
		targetType,
		(ref immutable Type.Bogus) =>
			//TODO: want to avoid cascading errors here.
			none!StructAndField,
		(immutable Ptr!TypeParam) =>
			none!StructAndField,
		(immutable Ptr!StructInst targetStructInst) =>
			matchStructBody(
				body_(targetStructInst),
				(ref immutable StructBody.Bogus) =>
					none!StructAndField,
				(ref immutable StructBody.Builtin) =>
					none!StructAndField,
				(ref immutable StructBody.Record r) {
					immutable Opt!(Ptr!RecordField) field = findPtr(r.fields, (immutable Ptr!RecordField f) =>
						symEq(f.name, fieldName));
					return has(field)
						? some(immutable StructAndField(targetStructInst, force(field)))
						: none!StructAndField;
				},
				(ref immutable StructBody.Union) =>
					none!StructAndField));
}

Opt!(Ptr!SingleInferringType) tryGetTypeArgFromInferringTypeArgs(
	ref InferringTypeArgs inferringTypeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	return tryGetTypeArg!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
}

const(Opt!(Ptr!SingleInferringType)) tryGetTypeArgFromInferringTypeArgs_const(
	ref const InferringTypeArgs inferringTypeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	return tryGetTypeArg!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
}

const(Opt!(Ptr!SingleInferringType)) tryGetTypeArgFromInferringTypeArgs(
	ref const InferringTypeArgs inferringTypeArgs,
	immutable Ptr!TypeParam typeParam,
) {
	return tryGetTypeArg!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
}

private:

struct SetTypeResult {
	@safe @nogc pure nothrow:

	// set a new type
	struct Set {
		immutable Type type;
	}
	// keep the type as-is
	struct Keep {}
	// type error
	struct Fail {}

	@trusted immutable this(immutable Set a) { kind = Kind.set; set = a; }
	immutable this(immutable Keep a) { kind = Kind.keep; keep = a; }
	immutable this(immutable Fail a) { kind = Kind.fail; fail = a; }

	private:

	enum Kind { set, keep, fail }
	immutable Kind kind;
	union {
		immutable Set set;
		immutable Keep keep;
		immutable Fail fail;
	}
}

@trusted immutable(T) matchSetTypeResult(T)(
	ref immutable SetTypeResult a,
	scope immutable(T) delegate(ref immutable SetTypeResult.Set) @safe @nogc pure nothrow cbSet,
	scope immutable(T) delegate(ref immutable SetTypeResult.Keep) @safe @nogc pure nothrow cbKeep,
	scope immutable(T) delegate(ref immutable SetTypeResult.Fail) @safe @nogc pure nothrow cbFail,
) {
	final switch (a.kind) {
		case SetTypeResult.Kind.set:
			return cbSet(a.set);
		case SetTypeResult.Kind.keep:
			return cbKeep(a.keep);
		case SetTypeResult.Kind.fail:
			return cbFail(a.fail);
	}
}

immutable(SetTypeResult) checkAssignabilityForStructInstsWithSameDecl(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl decl,
	ref immutable Arr!Type as,
	ref immutable Arr!Type bs,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	// If we need to set at least one type arg, return Set.
	// If all passed, return Keep.
	// Else, return Fail.
	Bool someIsSet = False;
	immutable Opt!(Arr!Type) newTypeArgs = mapZipOrNone!(Type, Type, Type, Alloc)(
		alloc,
		as,
		bs,
		(ref immutable Type a, ref immutable Type b) {
			immutable SetTypeResult res = checkAssignability(alloc, programState, a, b, aInferringTypeArgs, False);
			return matchSetTypeResult(
				res,
				(ref immutable SetTypeResult.Set s) {
					someIsSet = True;
					return some(s.type);
				},
				(ref immutable SetTypeResult.Keep) =>
					some(a),
				(ref immutable SetTypeResult.Fail) =>
					none!Type);
		});
	return has(newTypeArgs)
		? someIsSet
			? immutable SetTypeResult(immutable SetTypeResult.Set(immutable Type(
				instantiateStructNeverDelay(alloc, programState, StructDeclAndArgs(decl, force(newTypeArgs))))))
			: immutable SetTypeResult(SetTypeResult.Keep())
		: immutable SetTypeResult(SetTypeResult.Fail());
}

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forStructInst(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst a,
	immutable Ptr!StructInst b,
	ref InferringTypeArgs aInferringTypeArgs,
	immutable Bool allowConvertAToBUnion,
) {
	// Handling a union expected type is done in Expected::check
	// TODO: but it's done here to for case of call return type ...
	if (ptrEquals(a.decl, b.decl))
		return checkAssignabilityForStructInstsWithSameDecl!Alloc(
			alloc, programState, a.decl, a.typeArgs, b.typeArgs, aInferringTypeArgs);
	else {
		immutable StructBody bBody = body_(b.decl.deref);
		if (allowConvertAToBUnion && isUnion(bBody)) {
			immutable Opt!(Ptr!StructInst) bMember = find(asUnion(bBody).members, (ref immutable Ptr!StructInst i) =>
				ptrEquals(i.decl, a.decl));
			return has(bMember)
				? checkAssignabilityForStructInstsWithSameDecl(
					alloc,
					programState,
					a.decl,
					a.typeArgs,
					typeArgs(instantiateStructInst(alloc, programState, force(bMember), b).deref),
					aInferringTypeArgs)
				: SetTypeResult(SetTypeResult.Fail());
		} else
			return SetTypeResult(SetTypeResult.Fail());
	}
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeWorker(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Type t,
	ref const InferringTypeArgs inferringTypeArgs,
) {
	return matchType(
		t,
		(ref immutable Type.Bogus) =>
			some(immutable Type(Type.Bogus())),
		(immutable Ptr!TypeParam p) {
			const Opt!(Ptr!SingleInferringType) ta = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			// If it's not one of the inferring types, it's instantiated enough to return.
			return has(ta) ? tryGetInferred(force(ta)) : some(t);
		},
		(immutable Ptr!StructInst i) {
			immutable Opt!(Arr!Type) typeArgs = mapOrNone!Type(alloc, typeArgs(i), (ref immutable Type t) =>
				tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, inferringTypeArgs));
			return has(typeArgs)
				? some(immutable Type(instantiateStructNeverDelay(alloc, programState, StructDeclAndArgs(decl(i), force(typeArgs)))))
				: none!Type;
		});
}

immutable(SetTypeResult) checkAssignabilityOpt(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Opt!Type a,
	immutable Type b,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	return has(a)
		? checkAssignability(alloc, programState, force(a), b, aInferringTypeArgs, False)
		: immutable SetTypeResult(immutable SetTypeResult.Set(b));
}

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forSingleInferringType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref SingleInferringType sit,
	ref immutable Type setType,
) {
	InferringTypeArgs inferring = InferringTypeArgs.none();
	immutable SetTypeResult res = checkAssignabilityOpt!Alloc(alloc, programState, tryGetInferred(sit), setType, inferring);
	matchSetTypeResult!void(
		res,
		(ref immutable SetTypeResult.Set s) {
			cellSet(sit.type, some(s.type));
		},
		(ref immutable SetTypeResult.Keep) {},
		(ref immutable SetTypeResult.Fail) {});
	return res;
}


// TODO:NAME
// We are trying to assign 'a = b'.
// 'a' may contain type parameters from inferringTypeArgs. We'll infer those here.
// If 'allowConvertAToBUnion' is set, if 'b' is a union type and 'a' is a member, we'll set it to the union.
// When matching a type, we may fill in type parameters, so we may want to set a new more specific expected type.
immutable(SetTypeResult) checkAssignability(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Type a,
	ref immutable Type b,
	ref InferringTypeArgs aInferringTypeArgs,
	immutable Bool allowConvertAToBUnion,
) {
	return matchType!SetTypeResult(
		a,
		(ref immutable Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			immutable SetTypeResult(SetTypeResult.Keep()),
		(immutable Ptr!TypeParam pa) {
			Opt!(Ptr!SingleInferringType) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType!Alloc(alloc, programState, force(aInferring).deref, b)
				: matchType!SetTypeResult(
					b,
					(ref immutable Type.Bogus) =>
						// Bogus is assignable to anything
						immutable SetTypeResult(SetTypeResult.Keep()),
					(immutable Ptr!TypeParam pb) =>
						ptrEquals(pa, pb)
							? immutable SetTypeResult(SetTypeResult.Keep())
							: immutable SetTypeResult(SetTypeResult.Fail()),
					(immutable Ptr!StructInst) =>
						// Expecting a type param, got a particular type
						immutable SetTypeResult(SetTypeResult.Fail()));
		},
		(immutable Ptr!StructInst ai) =>
			matchType!SetTypeResult(
				b,
				(ref immutable Type.Bogus) =>
					// Bogus is assignable to anything
					immutable SetTypeResult(SetTypeResult.Keep()),
				(immutable Ptr!TypeParam) =>
					immutable SetTypeResult(SetTypeResult.Fail()),
				(immutable Ptr!StructInst bi) =>
					setTypeNoDiagnosticWorker_forStructInst(alloc, programState, ai, bi, aInferringTypeArgs, allowConvertAToBUnion)));
}



