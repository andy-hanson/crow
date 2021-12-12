module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.instantiate : instantiateStructNeverDelay, tryGetTypeArg, TypeParamsScope;
import frontend.check.typeFromAst : typeFromAst;
import frontend.parse.ast : TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	asTypeParam,
	ClosureField,
	CommonTypes,
	decl,
	Expr,
	FunDecl,
	FunFlags,
	FunKind,
	isBogus,
	isTypeParam,
	Local,
	matchType,
	Param,
	range,
	SpecInst,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	TypeParam;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.collection.arr : emptyArr, emptyArr_mut, setAt, sizeEq;
import util.collection.arrUtil : map, mapOrNone, mapZipOrNone;
import util.collection.mutArr : MutArr;
import util.opt : has, force, none, noneMut, Opt, OptPtr, some, toOpt;
import util.perf : Perf;
import util.ptr : Ptr, ptrEquals;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.util : verify;

struct LambdaInfo {
	immutable FunKind funKind;
	immutable Param[] lambdaParams;
	MutArr!LocalAndUsed locals;
	MutArr!(immutable Ptr!ClosureField) closureFields;
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	Ptr!CheckCtx checkCtxPtr;
	immutable StructsAndAliasesDict structsAndAliasesDict;
	immutable FunsDict funsDict;
	immutable CommonTypes commonTypes;
	immutable CommonFuns commonFuns;
	immutable Ptr!SpecInst[] outermostFunSpecs;
	immutable Param[] outermostFunParams;
	immutable TypeParam[] outermostFunTypeParams;
	immutable FunFlags outermostFunFlags;
	bool[] funsUsed;
	bool[] paramsUsed;

	// Locals of the function or message. Lambda locals are stored in the lambda.
	// (Note the Let stores the local and this points to that.)
	MutArr!LocalAndUsed messageOrFunctionLocals;
	// These are pointers because MutArr currently only works on copyable values,
	// and LambdaInfo should not be copied.
	MutArr!(Ptr!LambdaInfo) lambdas;

	ref Perf perf() return scope {
		return checkCtx().perf();
	}
	ref CheckCtx checkCtx() return scope {
		return checkCtxPtr.deref();
	}
	ref const(CheckCtx) checkCtx() return scope const {
		return checkCtxPtr.deref();
	}
}

struct CommonFuns {
	immutable Ptr!FunDecl noneFun;
}

void markUsedLocalFun(ref ExprCtx a, immutable ModuleLocalFunIndex index) {
	setAt(a.funsUsed, index.index, true);
}

struct LocalAndUsed {
	bool isUsed;
	immutable Ptr!Local local;
}

immutable(FileAndRange) rangeInFile2(ref const ExprCtx ctx, immutable RangeWithinFile range) {
	return rangeInFile(ctx.checkCtx, range);
}

ref ProgramState programState(return scope ref ExprCtx ctx) {
	return ctx.checkCtx.programState;
}

void addDiag2(ref Alloc alloc, ref ExprCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiag(alloc, ctx.checkCtx, range, diag);
}

immutable(Type[]) typeArgsFromAsts(ref Alloc alloc, ref ExprCtx ctx, immutable TypeAst[] typeAsts) {
	return map!Type(alloc, typeAsts, (ref immutable TypeAst it) =>
		typeFromAst2(alloc, ctx, it));
}

immutable(Opt!Type) typeFromOptAst(ref Alloc alloc, ref ExprCtx ctx, immutable OptPtr!TypeAst ast) {
	immutable Opt!(Ptr!TypeAst) opt = toOpt(ast);
	return has(opt) ? some(typeFromAst2(alloc, ctx, force(opt).deref())) : none!Type;
}

immutable(Type) typeFromAst2(ref Alloc alloc, ref ExprCtx ctx, immutable TypeAst ast) {
	return typeFromAst(
		alloc,
		ctx.checkCtx,
		ctx.commonTypes,
		ast,
		ctx.structsAndAliasesDict,
		immutable TypeParamsScope(ctx.outermostFunTypeParams),
		noneMut!(Ptr!(MutArr!(Ptr!(StructInst)))));
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

	immutable TypeParam[] params;
	SingleInferringType[] args;

	static InferringTypeArgs none() {
		return InferringTypeArgs(emptyArr!TypeParam, emptyArr_mut!SingleInferringType);
	}

	this(immutable TypeParam[] ps, SingleInferringType[] as) {
		params = ps;
		args = as;
		verify(sizeEq(params, args));
		foreach (immutable size_t i, ref immutable TypeParam param; ps)
			verify(param.index == i);
	}
	const this(immutable TypeParam[] ps, const SingleInferringType[] as) {
		params = ps;
		args = as;
		verify(sizeEq(params, args));
		foreach (immutable size_t i, ref immutable TypeParam param; ps)
			verify(param.index == i);
	}
}

// Gets the type system to ensure that we set the expected type.
struct CheckedExpr {
	immutable Expr expr;
}

// Inferring type args are in 'a', not 'b'
immutable(bool) matchTypesNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type expectedType,
	immutable Type setType,
	ref InferringTypeArgs aInferringTypeArgs
) {
	immutable SetTypeResult result =
		checkAssignability(alloc, programState, expectedType, setType, aInferringTypeArgs);
	return matchSetTypeResult!(immutable bool)(
		result,
		(ref immutable SetTypeResult.Set) => true,
		(ref immutable SetTypeResult.Keep) => true,
		(ref immutable SetTypeResult.Fail) => false);
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
immutable(bool) isBogus(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t) && isBogus(force(t));
}

Expected copyWithNewExpectedType(ref Expected expected, immutable Type type) {
	return Expected(some!Type(type), expected.inferringTypeArgs);
}

immutable(Opt!Type) shallowInstantiateType(ref const Expected expected) {
	immutable Opt!Type t = cellGet(expected.type);
	if (has(t) && isTypeParam(force(t))) {
		const Opt!(Ptr!SingleInferringType) typeArg =
			tryGetTypeArgFromInferringTypeArgs_const(expected.inferringTypeArgs, asTypeParam(force(t)));
		return has(typeArg) ? tryGetInferred(force(typeArg).deref()) : none!Type;
	} else
		return t;
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeFor(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Expected expected,
	immutable Type t,
) {
	return tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, expected.inferringTypeArgs);
}

immutable(Opt!Type) tryGetDeeplyInstantiatedType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Expected expected,
) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t)
		? tryGetDeeplyInstantiatedTypeFor(alloc, programState, expected, force(t))
		: none!Type;
}

immutable(CheckedExpr) bogus(ref Expected expected, immutable FileAndRange range) {
	cellSet(expected.type, some(immutable Type(immutable Type.Bogus())));
	return immutable CheckedExpr(immutable Expr(range, immutable Expr.Bogus()));
}

immutable(Type) inferred(ref const Expected expected) {
	immutable Opt!Type opt = tryGetInferred(expected);
	return force(opt);
}

immutable(CheckedExpr) check(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref Expected expected,
	immutable Type exprType,
	ref immutable Expr expr,
) {
	if (setTypeNoDiagnostic(alloc, programState(ctx), expected, exprType))
		return CheckedExpr(expr);
	else {
		// Failed to set type. This happens if there was already an inferred type.
		immutable Opt!Type t = tryGetInferred(expected);
		addDiag2(alloc, ctx, range(expr), immutable Diag(immutable Diag.TypeConflict(force(t), exprType)));
		return bogus(expected, range(expr));
	}
}

// Note: this may infer type parameters
private immutable(bool) setTypeNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	ref Expected expected,
	immutable Type setType,
) {
	immutable SetTypeResult typeToSet = checkAssignabilityOpt(
		alloc,
		programState,
		tryGetInferred(expected),
		setType,
		expected.inferringTypeArgs);
	return matchSetTypeResult!(immutable bool)(
		typeToSet,
		(ref immutable SetTypeResult.Set s) {
			cellSet(expected.type, some(s.type));
			return true;
		},
		(ref immutable SetTypeResult.Keep) =>
			true,
		(ref immutable SetTypeResult.Fail) =>
			false);
}

private Opt!(Ptr!SingleInferringType) tryGetTypeArgFromInferringTypeArgs(
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

immutable(SetTypeResult) checkAssignabilityForStructInstsWithSameDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructDecl decl,
	immutable Type[] as,
	immutable Type[] bs,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	// If we need to set at least one type arg, return Set.
	// If all passed, return Keep.
	// Else, return Fail.
	bool someIsSet = false;
	immutable Opt!(Type[]) newTypeArgs = mapZipOrNone!(Type, Type, Type)(
		alloc,
		as,
		bs,
		(ref immutable Type a, ref immutable Type b) {
			immutable SetTypeResult res = checkAssignability(alloc, programState, a, b, aInferringTypeArgs);
			return matchSetTypeResult(
				res,
				(ref immutable SetTypeResult.Set s) {
					someIsSet = true;
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
				instantiateStructNeverDelay(
					alloc,
					programState,
					immutable StructDeclAndArgs(decl, force(newTypeArgs))))))
			: immutable SetTypeResult(SetTypeResult.Keep())
		: immutable SetTypeResult(SetTypeResult.Fail());
}

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Ptr!StructInst a,
	immutable Ptr!StructInst b,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	// Handling a union expected type is done in Expected::check
	// TODO: but it's done here to for case of call return type ...
	if (ptrEquals(a.deref().decl, b.deref().decl))
		return checkAssignabilityForStructInstsWithSameDecl(
			alloc, programState, a.deref().decl, a.deref().typeArgs, b.deref().typeArgs, aInferringTypeArgs);
	else
		return SetTypeResult(SetTypeResult.Fail());
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeWorker(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type a,
	ref const InferringTypeArgs inferringTypeArgs,
) {
	return matchType!(
		immutable Opt!Type,
		(immutable Type.Bogus) =>
			some(immutable Type(Type.Bogus())),
		(immutable Ptr!TypeParam p) {
			const Opt!(Ptr!SingleInferringType) ta = tryGetTypeArgFromInferringTypeArgs_const(inferringTypeArgs, p);
			// If it's not one of the inferring types, it's instantiated enough to return.
			return has(ta) ? tryGetInferred(force(ta).deref()) : some(a);
		},
		(immutable Ptr!StructInst i) {
			immutable Opt!(Type[]) typeArgs = mapOrNone!Type(alloc, typeArgs(i.deref()), (ref immutable Type t) =>
				tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, inferringTypeArgs));
			return has(typeArgs)
				? some(immutable Type(instantiateStructNeverDelay(
					alloc,
					programState,
					immutable StructDeclAndArgs(decl(i.deref()), force(typeArgs)))))
				: none!Type;
		},
	)(a);
}

immutable(SetTypeResult) checkAssignabilityOpt(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Opt!Type a,
	immutable Type b,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	return has(a)
		? checkAssignability(alloc, programState, force(a), b, aInferringTypeArgs)
		: immutable SetTypeResult(immutable SetTypeResult.Set(b));
}

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forSingleInferringType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref SingleInferringType sit,
	immutable Type setType,
) {
	InferringTypeArgs inferring = InferringTypeArgs.none();
	immutable SetTypeResult res = checkAssignabilityOpt(alloc, programState, tryGetInferred(sit), setType, inferring);
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
immutable(SetTypeResult) checkAssignability(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type a,
	immutable Type b,
	ref InferringTypeArgs aInferringTypeArgs,
) {
	return matchType!(
		immutable SetTypeResult,
		(immutable Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			immutable SetTypeResult(SetTypeResult.Keep()),
		(immutable Ptr!TypeParam pa) {
			Opt!(Ptr!SingleInferringType) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType(alloc, programState, force(aInferring).deref, b)
				: matchType!(
					immutable SetTypeResult,
					(immutable Type.Bogus) =>
						// Bogus is assignable to anything
						immutable SetTypeResult(SetTypeResult.Keep()),
					(immutable Ptr!TypeParam pb) =>
						ptrEquals(pa, pb)
							? immutable SetTypeResult(SetTypeResult.Keep())
							: immutable SetTypeResult(SetTypeResult.Fail()),
					(immutable Ptr!StructInst) =>
						// Expecting a type param, got a particular type
						immutable SetTypeResult(SetTypeResult.Fail()),
				)(b);
		},
		(immutable Ptr!StructInst ai) =>
			matchType!(
				immutable SetTypeResult,
				(immutable Type.Bogus) =>
					// Bogus is assignable to anything
					immutable SetTypeResult(SetTypeResult.Keep()),
				(immutable Ptr!TypeParam) =>
					immutable SetTypeResult(SetTypeResult.Fail()),
				(immutable Ptr!StructInst bi) =>
					setTypeNoDiagnosticWorker_forStructInst(
						alloc,
						programState,
						ai,
						bi,
						aInferringTypeArgs),
			)(b)
	)(a);
}
