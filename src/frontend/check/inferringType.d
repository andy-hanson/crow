module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.instantiate : instantiateStructNeverDelay, tryGetTypeArg, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst : typeFromAst;
import frontend.lang : maxClosureFields, maxParams;
import frontend.parse.ast : TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	decl,
	Expr,
	ExprKind,
	FunFlags,
	FunKind,
	Local,
	Mutability,
	Param,
	range,
	SpecInst,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	VariableRef;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : only, sizeEq;
import util.col.arrUtil : arrLiteral, exists, findIndex, map;
import util.col.enumDict : enumDictFindKey;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : mapTo, MutMaxArr, push, tempAsArr;
import util.opt : has, force, none, noneMut, Opt, some;
import util.perf : Perf;
import util.ptr : castNonScope_ref;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym;
import util.union_ : UnionMutable;
import util.util : unreachable, verify;

struct ClosureFieldBuilder {
	@safe @nogc pure nothrow:

	immutable Sym name; // Redundant to the variableRef, but it's faster to keep this close
	immutable Mutability mutability;
	bool[4]* isUsed; // points to isUsed for the outer variable. Null for Param.
	immutable Type type; // Same as above
	immutable VariableRef variableRef;

	void setIsUsed(immutable LocalAccessKind accessKind) {
		if (isUsed != null) {
			(*isUsed)[accessKind] = true;
		}
	}
}

struct FunOrLambdaInfo {
	Opt!(LocalsInfo*) outer;
	immutable Param[] params;
	// none for a function.
	// WARN: This will not be initialized; but we allocate the pointer early.
	immutable Opt!(ExprKind.Lambda*) lambda;
	MutMaxArr!(maxParams, bool) paramsUsed = void;
	// Will be uninitialized for a function
	MutMaxArr!(maxClosureFields, ClosureFieldBuilder) closureFields = void;
}

struct LocalsInfo {
	FunOrLambdaInfo* funOrLambda;
	Opt!(LocalNode*) locals;
}

immutable(bool) isInLambda(ref LocalsInfo a) =>
	has(a.funOrLambda.outer);

struct LocalNode {
	Opt!(LocalNode*) prev;
	bool[4] isUsed; // One for each LocalAccessKind
	immutable Local* local;
}
enum LocalAccessKind { getOnStack, getThroughClosure, setOnStack, setThroughClosure }

void markIsUsedSetOnStack(scope ref LocalsInfo locals, immutable Local* local) {
	LocalNode* node = force(locals.locals);
	while (true) {
		if (node.local == local) {
			node.isUsed[LocalAccessKind.setOnStack] = true;
			break;
		}
		node = force(node.prev);
	}
}

struct ExprCtx {
	@safe @nogc pure nothrow:

	CheckCtx* checkCtxPtr;
	immutable StructsAndAliasesDict structsAndAliasesDict;
	immutable FunsDict funsDict;
	immutable CommonTypes commonTypes;
	immutable SpecInst*[] outermostFunSpecs;
	immutable Param[] outermostFunParams;
	immutable TypeParam[] outermostFunTypeParams;
	immutable FunFlags outermostFunFlags;
	FullIndexDict!(ModuleLocalFunIndex, bool) funsUsed;

	ref Alloc alloc() return scope =>
		checkCtx().alloc();

	ref const(AllSymbols) allSymbols() return scope const =>
		checkCtx().allSymbols();
	ref AllSymbols allSymbols() return scope =>
		checkCtx().allSymbols();

	ref Perf perf() return scope =>
		checkCtx().perf();

	ref CheckCtx checkCtx() return scope =>
		*checkCtxPtr;

	ref const(CheckCtx) checkCtx() return scope const =>
		*checkCtxPtr;
}

void markUsedLocalFun(ref ExprCtx a, immutable ModuleLocalFunIndex index) {
	a.funsUsed[index] = true;
}

immutable(FileAndRange) rangeInFile2(ref const ExprCtx ctx, immutable RangeWithinFile range) =>
	rangeInFile(ctx.checkCtx, range);

ref ProgramState programState(return scope ref ExprCtx ctx) =>
	ctx.checkCtx.programState;

void addDiag2(ref ExprCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiag(ctx.checkCtx, range, diag);
}

TypeArgsArray typeArgsFromAsts(ref ExprCtx ctx, scope immutable TypeAst[] typeAsts) {
	TypeArgsArray res = typeArgsArray();
	mapTo(res, typeAsts, (ref immutable TypeAst x) => typeFromAst2(ctx, x));
	return res;
}

immutable(Opt!Type) typeFromOptAst(ref ExprCtx ctx, immutable Opt!(TypeAst*) ast) =>
	has(ast) ? some(typeFromAst2(ctx, *force(ast))) : none!Type;

immutable(Type) typeFromAst2(ref ExprCtx ctx, scope immutable TypeAst ast) =>
	typeFromAst(
		ctx.checkCtx,
		ctx.commonTypes,
		ast,
		ctx.structsAndAliasesDict,
		ctx.outermostFunTypeParams,
		noneMut!(MutArr!(StructInst*)*));

struct SingleInferringType {
	@safe @nogc pure nothrow:

	Cell!(immutable Opt!Type) type;

	this(immutable Opt!(Type) t) {
		type = Cell!(immutable Opt!Type)(t);
	}
}

immutable(Opt!Type) tryGetInferred(ref const SingleInferringType a) =>
	cellGet!(immutable Opt!Type)(a.type);

struct InferringTypeArgs {
	@safe @nogc pure nothrow:

	immutable TypeParam[] params;
	SingleInferringType[] args;
}

immutable(bool) mayBeFunTypeWithArity(
	ref immutable CommonTypes commonTypes,
	immutable Type type,
	scope InferringTypeArgs inferringTypeArgs,
	immutable size_t arity,
) =>
	type.matchWithPointers!(immutable bool)(
		(immutable Type.Bogus) =>
			false,
		(immutable TypeParam* p) {
			const Opt!(SingleInferringType*) inferring = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			immutable Opt!Type inferred = has(inferring) ? cellGet(force(inferring).type) : none!Type;
			return has(inferred) && force(inferred).isA!(StructInst*)
				? isFunTypeWithArity(commonTypes, force(inferred).as!(StructInst*), arity)
				: true;
		},
		(immutable StructInst* i) =>
			isFunTypeWithArity(commonTypes, i, arity));

private immutable(bool) isFunTypeWithArity(
	ref immutable CommonTypes commonTypes,
	immutable StructInst* a,
	immutable size_t arity,
) {
	immutable StructDecl* decl = decl(*a);
	return arityForFunStruct(decl) == arity && has(getFunKindFromStruct(commonTypes, decl));
}

immutable(Opt!FunKind) getFunKindFromStruct(ref immutable CommonTypes a, immutable StructDecl* s) {
	immutable size_t arity = arityForFunStruct(s);
	return enumDictFindKey!(FunKind, StructDecl*[10])(a.funStructs, (ref immutable(StructDecl*[10]) structs) =>
		arity < structs.length && structs[arity] == s);
}

private immutable(size_t) arityForFunStruct(immutable StructDecl* s) =>
	s.typeParams.length - 1; // overflow OK, will fail 'arity < structs.length'

// Inferring type args are in 'a', not 'b'
immutable(bool) matchTypesNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type expectedType,
	scope InferringTypeArgs expectedTypeArgs,
	immutable Type actualType,
) {
	final switch (checkType(alloc, programState, expectedType, expectedTypeArgs, actualType)) {
		case SetTypeResult.set:
		case SetTypeResult.keep:
			return true;
		case SetTypeResult.fail:
			return false;
	}
}

struct LoopInfo {
	immutable Type voidType;
	immutable ExprKind.Loop* loop;
	immutable Type type;
	bool hasBreak;
}

struct TypeAndInferring {
	immutable Type type;
	InferringTypeArgs inferringTypeArgs;
}

struct Expected {
	struct Infer {}
	mixin UnionMutable!(immutable Infer, immutable Type, TypeAndInferring[], LoopInfo*);
}
static assert(Expected.sizeof == ulong.sizeof + size_t.sizeof * 2); // TODO: could probably be ulong.sizeof * 1!

@trusted Opt!(LoopInfo*) tryGetLoop(ref Expected expected) =>
	expected.isA!(LoopInfo*) ? some(expected.as!(LoopInfo*)) : noneMut!(LoopInfo*);

@trusted immutable(Opt!Type) tryGetInferred(ref const Expected expected) =>
	expected.matchConst!(immutable Opt!Type)(
		(immutable Expected.Infer) =>
			none!Type,
		(immutable Type x) =>
			some(x),
		(const TypeAndInferring[] ti) =>
			ti.length == 1 ? some(only(ti).type) : none!Type,
		(const LoopInfo*) =>
			none!Type);

// Returns an index into choices if it is the only allowed choice
immutable(Opt!size_t) findExpectedStruct(ref const Expected expected, immutable StructInst*[] choices) =>
	expected.matchConst!(immutable Opt!size_t)(
		(immutable Expected.Infer) =>
			none!size_t,
		(immutable Type x) =>
			x.isA!(StructInst*)
				? findIndex!(immutable StructInst*)(choices, (ref immutable StructInst* choice) =>
					choice == x.as!(StructInst*))
				: none!size_t,
		(const TypeAndInferring[] xs) {
			// This function will only be used with types like nat8 with no type arguments, so don't worry about those
			Opt!size_t rslt;
			foreach (ref const TypeAndInferring x; xs)
				if (x.type.isA!(StructInst*)) {
					immutable Opt!size_t here =
						findIndex!(immutable StructInst*)(choices, (ref immutable StructInst* choice) =>
							choice == x.type.as!(StructInst*));
					if (has(here)) {
						if (has(rslt))
							return none!size_t;
						else
							rslt = here;
					}
				}
			return rslt;
		},
		(const LoopInfo*) =>
			none!size_t);

// TODO: if we have a bogus expected type we should probably not be doing any more checking at all?
immutable(bool) isBogus(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t) && force(t).isA!(Type.Bogus);
}

private @trusted void setToType(scope ref Expected expected, immutable Type type) {
	expected = type;
}
private void setToBogus(scope ref Expected expected) {
	setToType(expected, immutable Type(immutable Type.Bogus()));
}

struct Pair(T, U) {
	T a;
	U b;
}
Pair!(T, Type) withCopyWithNewExpectedType(T)(
	ref Expected expected,
	immutable Type newExpectedType,
	scope immutable(T) delegate(ref Expected) @safe @nogc pure nothrow cb,
) {
	TypeAndInferring[1] t = [TypeAndInferring(newExpectedType, getInferringTypeArgs(expected))];
	Expected newExpected = Expected(t);
	immutable T res = cb(newExpected);
	return Pair!(T, Type)(castNonScope_ref(res), inferred(newExpected));
}

immutable(Opt!Type) shallowInstantiateType(ref const Expected expected) =>
	expected.matchConst!(immutable Opt!Type)(
		(immutable Expected.Infer) =>
			none!Type,
		(immutable Type x) =>
			some(x),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				const TypeAndInferring choice = only(choices);
				if (choice.type.isA!(TypeParam*)) {
					const Opt!(SingleInferringType*) typeArg =
						tryGetTypeArgFromInferringTypeArgs(choice.inferringTypeArgs, choice.type.as!(TypeParam*));
					return has(typeArg) ? tryGetInferred(*force(typeArg)) : none!Type;
				} else
					return some(choice.type);
			} else
				return none!Type;
		},
		(const LoopInfo*) => none!Type);

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeFor(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref const Expected expected,
	immutable Type t,
) =>
	tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, getInferringTypeArgs(expected));

private InferringTypeArgs getInferringTypeArgs(ref Expected expected) =>
	expected.match!InferringTypeArgs(
		(immutable Expected.Infer) =>
			unreachable!InferringTypeArgs,
		(immutable Type x) =>
			InferringTypeArgs(),
		(TypeAndInferring[] choices) =>
			only(choices).inferringTypeArgs,
		(LoopInfo*) =>
			unreachable!InferringTypeArgs);
private const(InferringTypeArgs) getInferringTypeArgs(ref const Expected expected) =>
	expected.matchConst!(const InferringTypeArgs)(
		(immutable Expected.Infer) =>
			unreachable!(const InferringTypeArgs),
		(immutable Type t) =>
			const InferringTypeArgs(),
		(const TypeAndInferring[] choices) =>
			only(choices).inferringTypeArgs,
		(const LoopInfo*) =>
			unreachable!(const InferringTypeArgs));

private immutable(Opt!Type) tryGetDeeplyInstantiatedType(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref const Expected expected,
) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t)
		? tryGetDeeplyInstantiatedTypeFor(alloc, programState, expected, force(t))
		: none!Type;
}

immutable(bool) matchExpectedVsReturnTypeNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref const Expected expected,
	immutable Type candidateReturnType,
	scope InferringTypeArgs candidateTypeArgs,
) =>
	expected.matchConst!(immutable bool)(
		(immutable Expected.Infer) =>
			true,
		(immutable Type t) =>
			// We have a particular expected type, so infer its type args
			matchTypesNoDiagnostic(alloc, programState, candidateReturnType, candidateTypeArgs, t),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				immutable Opt!Type t = tryGetDeeplyInstantiatedType(alloc, programState, expected);
				if (has(t))
					return matchTypesNoDiagnostic(
						alloc, programState, candidateReturnType, candidateTypeArgs, force(t));
			}
			// Don't infer any type args here; multiple candidates and multiple possible return types.
			return exists!(const TypeAndInferring)(choices, (ref const TypeAndInferring x) =>
				isTypeMatchPossible(x.type, x.inferringTypeArgs, candidateReturnType, candidateTypeArgs));
		},
		(const LoopInfo*) =>
			false);

immutable(Expr) bogus(ref Expected expected, immutable FileAndRange range) {
	expected.match!void(
		(immutable Expected.Infer) {
			setToBogus(expected);
		},
		(immutable(Type)) {},
		(TypeAndInferring[]) {
			setToBogus(expected);
		},
		(LoopInfo*) {});
	return immutable Expr(range, immutable ExprKind(immutable ExprKind.Bogus()));
}

immutable(Type) inferred(ref const Expected expected) =>
	expected.matchConst!(immutable Type)(
		(immutable Expected.Infer) =>
			unreachable!(immutable Type),
		(immutable Type x) =>
			x,
		(const TypeAndInferring[] choices) =>
			// If there were multiple, we should have set the expected.
			only(choices).type,
		(const LoopInfo* x) =>
			// Just treat loop body as 'void'
			x.voidType);

immutable(Expr) check(
	ref ExprCtx ctx,
	ref Expected expected,
	immutable Type exprType,
	immutable Expr expr,
) {
	if (setTypeNoDiagnostic(ctx.alloc, ctx.programState, expected, exprType))
		return expr;
	else {
		addDiag2(ctx, expr.range, expected.matchConst!(immutable Diag)(
			(immutable Expected.Infer) =>
				unreachable!(immutable Diag),
			(immutable Type x) =>
				immutable Diag(immutable Diag.TypeConflict(arrLiteral!Type(ctx.alloc, [x]), exprType)),
			(const TypeAndInferring[] xs) =>
				immutable Diag(immutable Diag.TypeConflict(
					map(ctx.alloc, xs, (scope ref const TypeAndInferring x) => x.type),
					exprType)),
			(const LoopInfo*) =>
				immutable Diag(immutable Diag.LoopNeedsBreakOrContinue())));
		return bogus(expected, expr.range);
	}
}

void mustSetType(ref Alloc alloc, ref ProgramState programState, ref Expected expected, immutable Type setType) {
	immutable bool success = setTypeNoDiagnostic(alloc, programState, expected, setType);
	verify(success);
}

// Note: this may infer type parameters
private immutable(bool) setTypeNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	ref Expected expected,
	immutable Type actual,
) =>
	expected.match!(immutable bool)(
		(immutable Expected.Infer) {
			setToType(expected, actual);
			return true;
		},
		(immutable Type x) {
			final switch (checkType(alloc, programState, x, InferringTypeArgs(), actual)) {
				case SetTypeResult.set:
					return unreachable!(immutable bool);
				case SetTypeResult.keep:
					return true;
				case SetTypeResult.fail:
					return false;
			}
		},
		(TypeAndInferring[] choices) {
			bool anyOk = false;
			foreach (ref TypeAndInferring x; choices) {
				final switch (checkType(alloc, programState, x.type, x.inferringTypeArgs, actual)) {
					case SetTypeResult.set:
						// we'll do the set at the end
					case SetTypeResult.keep:
						anyOk = true;
						break;
					case SetTypeResult.fail:
						break;
				}
			}
			setToType(expected, anyOk ? actual : immutable Type(immutable Type.Bogus()));
			return anyOk;
		},
		(LoopInfo* loop) =>
			false);

inout(Opt!(SingleInferringType*)) tryGetTypeArgFromInferringTypeArgs(
	return scope ref inout InferringTypeArgs inferringTypeArgs,
	immutable TypeParam* typeParam,
) =>
	tryGetTypeArg(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);

private:

enum SetTypeResult {
	// Set expected to the actual type.
	set,
	// Keep the expected type (ignoring the actual type). This is useful when expected is bogus.
	keep,
	// Fail with a type error.
	fail,
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeWorker(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type a,
	scope const InferringTypeArgs inferringTypeArgs,
) =>
	a.matchWithPointers!(immutable Opt!Type)(
		(immutable Type.Bogus) =>
			some(immutable Type(Type.Bogus())),
		(immutable TypeParam* p) {
			const Opt!(SingleInferringType*) ta = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			// If it's not one of the inferring types, it's instantiated enough to return.
			return has(ta) ? tryGetInferred(*force(ta)) : some(a);
		},
		(immutable StructInst* i) {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (immutable Type x; typeArgs(*i)) {
				immutable Opt!Type t = tryGetDeeplyInstantiatedTypeWorker(alloc, programState, x, inferringTypeArgs);
				if (has(t))
					push(newTypeArgs, force(t));
				else
					return none!Type;
			}
			return some(immutable Type(
				instantiateStructNeverDelay(alloc, programState, decl(*i), tempAsArr(newTypeArgs))));
		});

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forSingleInferringType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref SingleInferringType inferring,
	immutable Type actual,
) {
	immutable Opt!Type inferred = tryGetInferred(inferring);
	immutable SetTypeResult res = has(inferred)
		? checkType(alloc, programState, force(inferred), InferringTypeArgs(), actual)
		: SetTypeResult.set;
	final switch (res) {
		case SetTypeResult.set:
			cellSet(inferring.type, some(actual));
			break;
		case SetTypeResult.keep:
		case SetTypeResult.fail:
			break;
	}
	return res;
}

// We are trying to assign 'a = b'.
// 'a' may contain type parameters from inferringTypeArgs. We'll infer those here.
// If 'allowConvertAToBUnion' is set, if 'b' is a union type and 'a' is a member, we'll set it to the union.
// When matching a type, we may fill in type parameters, so we may want to set a new more specific expected type.
immutable(SetTypeResult) checkType(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	immutable Type b,
) =>
	a.matchWithPointers!(immutable SetTypeResult)(
		(immutable Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			SetTypeResult.keep,
		(immutable TypeParam* pa) {
			Opt!(SingleInferringType*) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType(alloc, programState, *force(aInferring), b)
				: b.matchWithPointers!(immutable SetTypeResult)(
					(immutable Type.Bogus) =>
						// Bogus is assignable to anything
						SetTypeResult.keep,
					(immutable TypeParam* pb) =>
						pa == pb ? SetTypeResult.keep : SetTypeResult.fail,
					(immutable StructInst*) =>
						// Expecting a type param, got a particular type
						SetTypeResult.fail);
		},
		(immutable StructInst* ai) =>
			b.matchWithPointers!(immutable SetTypeResult)(
				(immutable Type.Bogus) =>
					// Bogus is assignable to anything
					SetTypeResult.keep,
				(immutable TypeParam*) =>
					SetTypeResult.fail,
				(immutable StructInst* bi) =>
					checkStructInsts(alloc, programState, *ai, aInferringTypeArgs, *bi)));

immutable(SetTypeResult) checkStructInsts(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable StructInst ai,
	scope InferringTypeArgs aInferringTypeArgs,
	ref immutable StructInst bi,
) {
	if (decl(ai) == decl(bi)) {
		// If we need to set at least one type arg, return Set.
		// If all passed, return Keep.
		// Else, return Fail.
		SetTypeResult res = SetTypeResult.keep;
		verify(sizeEq(typeArgs(ai), typeArgs(bi)));
		foreach (immutable size_t i, a; typeArgs(ai)) {
			immutable Type b = typeArgs(bi)[i];
			final switch (checkType(alloc, programState, a, aInferringTypeArgs, b)) {
				case SetTypeResult.set:
					res = SetTypeResult.set;
					break;
				case SetTypeResult.keep:
					break;
				case SetTypeResult.fail:
					return SetTypeResult.fail;
			}
		}
		return res;
	} else
		return SetTypeResult.fail;
}

immutable(bool) isTypeMatchPossible(
	immutable Type a,
	const InferringTypeArgs aInferring,
	immutable Type b,
	const InferringTypeArgs bInferring,
) {
	if (a == b)
		return true;
	if (a.isA!(Type.Bogus) || b.isA!(Type.Bogus))
		return true;
	if (a.isA!(TypeParam*)) {
		const Opt!(SingleInferringType*) aSingle = tryGetTypeArgFromInferringTypeArgs(aInferring, a.as!(TypeParam*));
		if (has(aSingle)) {
			immutable Opt!Type t = tryGetInferred(*force(aSingle));
			return !has(t) || isTypeMatchPossible(force(t), InferringTypeArgs(), b, bInferring);
		}
	}
	if (b.isA!(TypeParam*)) {
		const Opt!(SingleInferringType*) bSingle = tryGetTypeArgFromInferringTypeArgs(bInferring, b.as!(TypeParam*));
		if (has(bSingle)) {
			immutable Opt!Type t = tryGetInferred(*force(bSingle));
			return !has(t) || isTypeMatchPossible(a, aInferring, force(t), InferringTypeArgs());
		}
	}
	if (a.isA!(StructInst*) && b.isA!(StructInst*)) {
		immutable StructInst* sa = a.as!(StructInst*);
		immutable StructInst* sb = b.as!(StructInst*);
		if (decl(*sa) != decl(*sb))
			return false;
		foreach (immutable size_t i; 0 .. typeArgs(*sa).length)
			if (!isTypeMatchPossible(typeArgs(*sa)[i], aInferring, typeArgs(*sb)[i], bInferring))
				return false;
		return true;
	}
	return false;
}
