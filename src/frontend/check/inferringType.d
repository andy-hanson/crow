module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.instantiate : instantiateStructNeverDelay, tryGetTypeArg_mut, TypeArgsArray, typeArgsArray;
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
import util.col.arr : only;
import util.col.arrUtil : arrLiteral, exists, indexOf, map, zip, zipEvery;
import util.col.enumDict : enumDictFindKey;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : MutMaxArr, push, tempAsArr;
import util.opt : has, force, MutOpt, none, noneMut, Opt, someMut, some;
import util.perf : Perf;
import util.ptr : castNonScope_ref;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym;
import util.union_ : UnionMutable;
import util.util : unreachable;

struct ClosureFieldBuilder {
	@safe @nogc pure nothrow:

	immutable Sym name; // Redundant to the variableRef, but it's faster to keep this close
	immutable Mutability mutability;
	bool[4]* isUsed; // points to isUsed for the outer variable. Null for Param.
	immutable Type type; // Same as above
	immutable VariableRef variableRef;

	void setIsUsed(LocalAccessKind accessKind) {
		if (isUsed != null) {
			(*isUsed)[accessKind] = true;
		}
	}
}

struct FunOrLambdaInfo {
	MutOpt!(LocalsInfo*) outer;
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
	MutOpt!(LocalNode*) locals;
}

bool isInLambda(ref LocalsInfo a) =>
	has(a.funOrLambda.outer);

struct LocalNode {
	MutOpt!(LocalNode*) prev;
	bool[4] isUsed; // One for each LocalAccessKind
	immutable Local* local;
}
enum LocalAccessKind { getOnStack, getThroughClosure, setOnStack, setThroughClosure }

void markIsUsedSetOnStack(scope ref LocalsInfo locals, Local* local) {
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
	private bool isInTrusted;
	private bool usedTrusted;

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

T withTrusted(T)(ref ExprCtx ctx, FileAndRange range, in T delegate() @safe @nogc pure nothrow cb) {
	Opt!(Diag.TrustedUnnecessary.Reason) reason = ctx.outermostFunFlags.safety != FunFlags.Safety.safe
		? some(Diag.TrustedUnnecessary.Reason.inUnsafeFunction)
		: ctx.isInTrusted
		? some(Diag.TrustedUnnecessary.Reason.inTrusted)
		: none!(Diag.TrustedUnnecessary.Reason);
	if(has(reason)) {
		addDiag2(ctx, range, Diag(Diag.TrustedUnnecessary(force(reason))));
		return cb();
	} else {
		ctx.isInTrusted = true;
		T res = cb();
		ctx.isInTrusted = false;
		if (!ctx.usedTrusted)
			addDiag2(ctx, range, Diag(Diag.TrustedUnnecessary(Diag.TrustedUnnecessary.Reason.unused)));
		ctx.usedTrusted = false;
		return res;
	}
}

bool checkCanDoUnsafe(ref ExprCtx ctx) {
	if (ctx.outermostFunFlags.safety == FunFlags.Safety.unsafe)
		return true;
	else {
		bool res = ctx.isInTrusted;
		if (res) ctx.usedTrusted = true;
		return res;
	}
}

void markUsedLocalFun(ref ExprCtx a, ModuleLocalFunIndex index) {
	a.funsUsed[index] = true;
}

FileAndRange rangeInFile2(in ExprCtx ctx, RangeWithinFile range) =>
	rangeInFile(ctx.checkCtx, range);

ref ProgramState programState(return scope ref ExprCtx ctx) =>
	ctx.checkCtx.programState;

void addDiag2(ref ExprCtx ctx, FileAndRange range, Diag diag) {
	addDiag(ctx.checkCtx, range, diag);
}

Opt!Type typeFromOptAst(ref ExprCtx ctx, in Opt!(TypeAst*) ast) =>
	has(ast) ? some(typeFromAst2(ctx, *force(ast))) : none!Type;

immutable(Type) typeFromAst2(ref ExprCtx ctx, in TypeAst ast) =>
	typeFromAst(
		ctx.checkCtx,
		ctx.commonTypes,
		ast,
		ctx.structsAndAliasesDict,
		ctx.outermostFunTypeParams,
		noneMut!(MutArr!(StructInst*)*));

struct SingleInferringType {
	@safe @nogc pure nothrow:

	private Cell!(Opt!Type) type;

	this(Opt!Type t) {
		type = Cell!(Opt!Type)(t);
	}
}

Opt!Type tryGetInferred(ref const SingleInferringType a) =>
	cellGet(a.type);

struct InferringTypeArgs {
	@safe @nogc pure nothrow:

	immutable TypeParam[] params;
	SingleInferringType[] args;
}

bool mayBeFunTypeWithArity(
	in CommonTypes commonTypes,
	in Type type,
	in InferringTypeArgs inferringTypeArgs,
	size_t arity,
) =>
	type.matchWithPointers!bool(
		(Type.Bogus) =>
			false,
		(TypeParam* p) {
			MutOpt!(const(SingleInferringType)*) inferring = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			Opt!Type inferred = has(inferring) ? cellGet(force(inferring).type) : none!Type;
			return has(inferred) && force(inferred).isA!(StructInst*)
				? isFunTypeWithArity(commonTypes, force(inferred).as!(StructInst*), arity)
				: true;
		},
		(StructInst* i) =>
			isFunTypeWithArity(commonTypes, i, arity));

private bool isFunTypeWithArity(in CommonTypes commonTypes, StructInst* a, size_t arity) {
	StructDecl* decl = decl(*a);
	return arityForFunStruct(decl) == arity && has(getFunKindFromStruct(commonTypes, decl));
}

Opt!FunKind getFunKindFromStruct(in CommonTypes a, StructDecl* s) {
	size_t arity = arityForFunStruct(s);
	return enumDictFindKey!(FunKind, StructDecl*[10])(a.funStructs, (in StructDecl*[10] structs) =>
		arity < structs.length && structs[arity] == s);
}

private size_t arityForFunStruct(StructDecl* s) =>
	s.typeParams.length - 1; // overflow OK, will fail 'arity < structs.length'

// We can infer type args of 'a' but can't change inferred type args for 'b'
bool matchTypesNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	Type expectedType,
	scope InferringTypeArgs expectedTypeArgs,
	Type actualType,
	in InferringTypeArgs actualTypeArgs,
) =>
	checkType(alloc, programState, expectedType, expectedTypeArgs, actualType, actualTypeArgs);

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
	immutable struct Infer {}
	mixin UnionMutable!(Infer, Type, TypeAndInferring[], LoopInfo*);
}
static assert(Expected.sizeof == ulong.sizeof + size_t.sizeof * 2); // TODO: could probably be ulong.sizeof * 1!

MutOpt!(LoopInfo*) tryGetLoop(ref Expected expected) =>
	expected.isA!(LoopInfo*) ? someMut(expected.as!(LoopInfo*)) : noneMut!(LoopInfo*);

@trusted Opt!Type tryGetInferred(ref const Expected expected) =>
	expected.matchConst!(Opt!Type)(
		(Expected.Infer) =>
			none!Type,
		(Type x) =>
			some(x),
		(const TypeAndInferring[] ti) =>
			ti.length == 1 ? some(only(ti).type) : none!Type,
		(const LoopInfo*) =>
			none!Type);

// Returns an index into choices if it is the only allowed choice
Opt!size_t findExpectedStruct(ref const Expected expected, immutable StructInst*[] choices) =>
	expected.matchConst!(Opt!size_t)(
		(Expected.Infer) =>
			none!size_t,
		(Type x) =>
			x.isA!(StructInst*)
				? indexOf(choices, x.as!(StructInst*))
				: none!size_t,
		(const TypeAndInferring[] xs) {
			// This function will only be used with types like nat8 with no type arguments, so don't worry about those
			Cell!(Opt!size_t) rslt;
			foreach (ref const TypeAndInferring x; xs)
				if (x.type.isA!(StructInst*)) {
					Opt!size_t here = indexOf(choices, x.type.as!(StructInst*));
					if (has(here)) {
						if (has(cellGet(rslt)))
							return none!size_t;
						else
							cellSet(rslt, here);
					}
				}
			return cellGet(rslt);
		},
		(const LoopInfo*) =>
			none!size_t);

// TODO: if we have a bogus expected type we should probably not be doing any more checking at all?
bool isBogus(ref const Expected expected) {
	Opt!Type t = tryGetInferred(expected);
	return has(t) && force(t).isA!(Type.Bogus);
}

private @trusted void setToType(scope ref Expected expected, Type type) {
	expected = type;
}
private void setToBogus(scope ref Expected expected) {
	setToType(expected, Type(Type.Bogus()));
}

struct Pair(T, U) {
	T a;
	U b;
}
Pair!(T, Type) withCopyWithNewExpectedType(T)(
	ref Expected expected,
	Type newExpectedType,
	in T delegate(ref Expected) @safe @nogc pure nothrow cb,
) {
	TypeAndInferring[1] t = [TypeAndInferring(newExpectedType, getInferringTypeArgs(expected))];
	Expected newExpected = Expected(t);
	T res = cb(newExpected);
	return Pair!(T, Type)(castNonScope_ref(res), inferred(newExpected));
}

Opt!Type shallowInstantiateType(ref const Expected expected) =>
	expected.matchConst!(Opt!Type)(
		(Expected.Infer) =>
			none!Type,
		(Type x) =>
			some(x),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				const TypeAndInferring choice = only(choices);
				if (choice.type.isA!(TypeParam*)) {
					MutOpt!(const(SingleInferringType)*) typeArg =
						tryGetTypeArgFromInferringTypeArgs(choice.inferringTypeArgs, choice.type.as!(TypeParam*));
					return has(typeArg) ? tryGetInferred(*force(typeArg)) : none!Type;
				} else
					return some(choice.type);
			} else
				return none!Type;
		},
		(const LoopInfo*) => none!Type);

Opt!Type tryGetDeeplyInstantiatedTypeFor(
	ref Alloc alloc,
	ref ProgramState programState,
	in Expected expected,
	Type t,
) =>
	tryGetDeeplyInstantiatedTypeWorker(alloc, programState, t, getInferringTypeArgs(expected));

private InferringTypeArgs getInferringTypeArgs(ref Expected expected) =>
	expected.match!InferringTypeArgs(
		(Expected.Infer) =>
			unreachable!InferringTypeArgs,
		(Type x) =>
			InferringTypeArgs(),
		(TypeAndInferring[] choices) =>
			only(choices).inferringTypeArgs,
		(LoopInfo*) =>
			unreachable!InferringTypeArgs);
private const(InferringTypeArgs) getInferringTypeArgs(ref const Expected expected) =>
	expected.matchConst!(const InferringTypeArgs)(
		(Expected.Infer) =>
			unreachable!(const InferringTypeArgs),
		(Type t) =>
			const InferringTypeArgs(),
		(const TypeAndInferring[] choices) =>
			only(choices).inferringTypeArgs,
		(const LoopInfo*) =>
			unreachable!(const InferringTypeArgs));

private Opt!Type tryGetDeeplyInstantiatedType(
	ref Alloc alloc,
	ref ProgramState programState,
	in Expected expected,
) {
	Opt!Type t = tryGetInferred(expected);
	return has(t)
		? tryGetDeeplyInstantiatedTypeFor(alloc, programState, expected, force(t))
		: none!Type;
}

bool matchExpectedVsReturnTypeNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	in Expected expected,
	Type candidateReturnType,
	scope InferringTypeArgs candidateTypeArgs,
) =>
	expected.matchConst!bool(
		(Expected.Infer) =>
			true,
		(Type t) =>
			// We have a particular expected type, so infer its type args
			matchTypesNoDiagnostic(alloc, programState, candidateReturnType, candidateTypeArgs, t, InferringTypeArgs()),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				Opt!Type t = tryGetDeeplyInstantiatedType(alloc, programState, expected);
				if (has(t))
					return matchTypesNoDiagnostic(
						alloc, programState, candidateReturnType, candidateTypeArgs, force(t), InferringTypeArgs());
			}
			// Don't infer any type args here; multiple candidates and multiple possible return types.
			return exists!(const TypeAndInferring)(choices, (in TypeAndInferring x) =>
				isTypeMatchPossible(x.type, x.inferringTypeArgs, candidateReturnType, candidateTypeArgs));
		},
		(const LoopInfo*) =>
			false);

Expr bogus(ref Expected expected, FileAndRange range) {
	expected.match!void(
		(Expected.Infer) {
			setToBogus(expected);
		},
		(Type _) {},
		(TypeAndInferring[]) {
			setToBogus(expected);
		},
		(LoopInfo*) {});
	return Expr(range, ExprKind(ExprKind.Bogus()));
}

Type inferred(ref const Expected expected) =>
	expected.matchConst!Type(
		(Expected.Infer) =>
			unreachable!Type,
		(Type x) =>
			x,
		(const TypeAndInferring[] choices) =>
			// If there were multiple, we should have set the expected.
			only(choices).type,
		(const LoopInfo* x) =>
			// Just treat loop body as 'void'
			x.voidType);

Expr check(ref ExprCtx ctx, ref Expected expected, Type exprType, Expr expr) {
	if (setTypeNoDiagnostic(ctx.alloc, ctx.programState, expected, exprType))
		return expr;
	else {
		addDiag2(ctx, expr.range, expected.matchConst!Diag(
			(Expected.Infer) =>
				unreachable!Diag,
			(Type x) =>
				Diag(Diag.TypeConflict(arrLiteral!Type(ctx.alloc, [x]), exprType)),
			(const TypeAndInferring[] xs) =>
				Diag(Diag.TypeConflict(
					map(ctx.alloc, xs, (scope ref const TypeAndInferring x) => x.type),
					exprType)),
			(const LoopInfo*) =>
				Diag(Diag.LoopNeedsBreakOrContinue())));
		return bogus(expected, expr.range);
	}
}

void setExpectedIfNoInferred(ref Expected expected, in Type delegate() @safe @nogc pure nothrow getType) {
	expected.matchConst!void(
		(Expected.Infer) {
			setToType(expected, getType());
		},
		(Type _) {},
		(const TypeAndInferring[]) {},
		(const LoopInfo*) {});
}

// Note: this may infer type parameters
private bool setTypeNoDiagnostic(ref Alloc alloc, ref ProgramState programState, ref Expected expected, Type actual) =>
	expected.match!bool(
		(Expected.Infer) {
			setToType(expected, actual);
			return true;
		},
		(Type x) =>
			checkType(alloc, programState, x, InferringTypeArgs(), actual, InferringTypeArgs()),
		(TypeAndInferring[] choices) {
			bool anyOk = false;
			foreach (ref TypeAndInferring x; choices)
				if (checkType(alloc, programState, x.type, x.inferringTypeArgs, actual, InferringTypeArgs()))
					anyOk = true;
			if (anyOk) setToType(expected, actual);
			return anyOk;
		},
		(LoopInfo* loop) =>
			false);

MutOpt!(SingleInferringType*) tryGetTypeArgFromInferringTypeArgs(
	return scope ref InferringTypeArgs inferringTypeArgs,
	TypeParam* typeParam,
) =>
	tryGetTypeArg_mut!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
MutOpt!(const(SingleInferringType)*) tryGetTypeArgFromInferringTypeArgs(
	return scope ref const InferringTypeArgs inferringTypeArgs,
	TypeParam* typeParam,
) =>
	tryGetTypeArg_mut(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);

private:

Opt!Type tryGetDeeplyInstantiatedTypeWorker(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	in InferringTypeArgs inferredTypeArgs,
) =>
	a.matchWithPointers!(Opt!Type)(
		(Type.Bogus) =>
			some(Type(Type.Bogus())),
		(TypeParam* p) {
			MutOpt!(const(SingleInferringType)*) ta = tryGetTypeArgFromInferringTypeArgs(inferredTypeArgs, p);
			// If it's not one of the inferring types, it's instantiated enough to return.
			return has(ta) ? tryGetInferred(*force(ta)) : some(a);
		},
		(StructInst* i) {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (Type x; typeArgs(*i)) {
				Opt!Type t = tryGetDeeplyInstantiatedTypeWorker(alloc, programState, x, inferredTypeArgs);
				if (has(t))
					push(newTypeArgs, force(t));
				else
					return none!Type;
			}
			return some(Type(instantiateStructNeverDelay(alloc, programState, decl(*i), tempAsArr(newTypeArgs))));
		});

/*
Tries to find a way for 'a' and 'b' to be the same type.
It can filll in type arguments for 'a'. But unknown types in 'b' it will assume compatibility.
Returns true if it succeeds.
*/
bool checkType(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	Type b,
	in InferringTypeArgs bInferredTypeArgs,
) =>
	a.matchWithPointers!bool(
		(Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			true,
		(TypeParam* pa) =>
			checkType_TypeParam(alloc, programState, pa, aInferringTypeArgs, b, bInferredTypeArgs),
		(StructInst* ai) =>
			b.matchWithPointers!bool(
				(Type.Bogus) =>
					true,
				(TypeParam* pb) =>
					checkType_TypeParamB(alloc, programState, a, aInferringTypeArgs, pb, bInferredTypeArgs),
				(StructInst* bi) =>
					decl(*ai) == decl(*bi) &&
					zipEvery!(Type, Type)(typeArgs(*ai), typeArgs(*bi), (in Type argA, in Type argB) =>
						checkType(alloc, programState, argA, aInferringTypeArgs, argB, bInferredTypeArgs))));

bool checkType_TypeParam(
	ref Alloc alloc,
	ref ProgramState programState,
	TypeParam* a,
	scope InferringTypeArgs aInferringTypeArgs,
	Type b,
	in InferringTypeArgs bInferredTypeArgs,
) {
	MutOpt!(SingleInferringType*) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, a);
	MutOpt!(const(SingleInferringType)*) bInferring = tryGetTypeArgFromInferringTypeArgs(bInferredTypeArgs, a);
	if (has(aInferring)) {
		Opt!Type inferred = tryGetInferred(*force(aInferring));
		bool ok = !has(inferred) || checkType(
			alloc, programState, force(inferred), InferringTypeArgs(), b, bInferredTypeArgs);
		if (ok) {
			Opt!Type bInferred = tryGetDeeplyInstantiatedTypeWorker(alloc, programState, b, bInferredTypeArgs);
			if (has(bInferred))
				cellSet(force(aInferring).type, bInferred);
		}
		return ok;
	} else if (has(bInferring)) {
		Opt!Type inferred = tryGetInferred(*force(bInferring));
		return has(inferred)
			? checkType(alloc, programState, force(inferred), aInferringTypeArgs, b, InferringTypeArgs())
			: b.isA!(TypeParam*) && a == b.as!(TypeParam*);
	} else
		// It's an outer type param (not in either inferring).
		return b.matchWithPointers!bool(
			(Type.Bogus) =>
				true,
			(TypeParam* bp) {
				if (bp == a)
					return true;
				else {
					MutOpt!(const(SingleInferringType)*) bInferringB =
						tryGetTypeArgFromInferringTypeArgs(bInferredTypeArgs, bp);
					if (has(bInferringB)) {
						Opt!Type inferred = tryGetInferred(*force(bInferringB));
						return !has(inferred) || force(inferred) == Type(a);
					} else
						return false;
				}
			},
			(StructInst*) =>
				false);
}

bool checkType_TypeParamB(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	TypeParam* b,
	in InferringTypeArgs bInferredTypeArgs,
) {
	MutOpt!(const(SingleInferringType)*) bInferred = tryGetTypeArgFromInferringTypeArgs(bInferredTypeArgs, b);
	if (has(bInferred)) {
		Opt!Type inferred = tryGetInferred(*force(bInferred));
		return !has(inferred) || checkType(
			alloc, programState, a, aInferringTypeArgs, force(inferred), InferringTypeArgs());
	} else
		return false;
}

public void inferTypeArgsFrom(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	in Type b,
	in InferringTypeArgs bInferredTypeArgs,
) {
	MutOpt!(const(SingleInferringType)*) bInferred =
		b.isA!(TypeParam*)
		? tryGetTypeArgFromInferringTypeArgs(bInferredTypeArgs, b.as!(TypeParam*))
		: noneMut!(const(SingleInferringType)*);
	if (has(bInferred)) {
		Opt!Type optInferred = tryGetInferred(*force(bInferred));
		if (has(optInferred))
			inferTypeArgsFrom(alloc, programState, a, aInferringTypeArgs, force(optInferred), InferringTypeArgs());
	} else {
		a.matchWithPointers!void(
			(Type.Bogus) {},
			(TypeParam* ap) {
				MutOpt!(SingleInferringType*) optAInferring =
					tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, ap);
				SingleInferringType* aInferring = force(optAInferring);
				if (!has(tryGetInferred(*aInferring))) {
					Opt!Type t = tryGetDeeplyInstantiatedTypeWorker(alloc, programState, b, bInferredTypeArgs);
					if (has(t))
						cellSet(aInferring.type, t);
				}
			},
			(StructInst* ai) {
				if (b.isA!(StructInst*)) {
					const StructInst* bi = b.as!(StructInst*);
					if (decl(*ai) == decl(*bi))
						zip(typeArgs(*ai), typeArgs(*bi), (ref Type ta, ref Type tb) {
							inferTypeArgsFrom(alloc, programState, ta, aInferringTypeArgs, tb, bInferredTypeArgs);
						});
				}
			});
	}
}

bool isTypeMatchPossible(in Type a, in InferringTypeArgs aInferring, in Type b, in InferringTypeArgs bInferring) {
	if (a == b)
		return true;
	if (a.isA!(Type.Bogus) || b.isA!(Type.Bogus))
		return true;
	if (a.isA!(TypeParam*)) {
		MutOpt!(const(SingleInferringType)*) aSingle =
			tryGetTypeArgFromInferringTypeArgs(aInferring, a.as!(TypeParam*));
		if (has(aSingle)) {
			Opt!Type t = tryGetInferred(*force(aSingle));
			return !has(t) || isTypeMatchPossible(force(t), InferringTypeArgs(), b, bInferring);
		}
	}
	if (b.isA!(TypeParam*)) {
		MutOpt!(const(SingleInferringType)*) bSingle =
			tryGetTypeArgFromInferringTypeArgs(bInferring, b.as!(TypeParam*));
		if (has(bSingle)) {
			Opt!Type t = tryGetInferred(*force(bSingle));
			return !has(t) || isTypeMatchPossible(a, aInferring, force(t), InferringTypeArgs());
		}
	}
	if (a.isA!(StructInst*) && b.isA!(StructInst*)) {
		StructInst* sa = a.as!(StructInst*);
		StructInst* sb = b.as!(StructInst*);
		if (decl(*sa) != decl(*sb))
			return false;
		foreach (size_t i; 0 .. typeArgs(*sa).length)
			if (!isTypeMatchPossible(typeArgs(*sa)[i], aInferring, typeArgs(*sb)[i], bInferring))
				return false;
		return true;
	}
	return false;
}
