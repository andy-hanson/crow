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
import util.col.arr : only, sizeEq;
import util.col.arrUtil : arrLiteral, exists, indexOf, map;
import util.col.enumDict : enumDictFindKey;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : mapTo, MutMaxArr, push, tempAsArr;
import util.opt : has, force, MutOpt, none, noneMut, Opt, someMut, some;
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
	CommonTypes commonTypes;
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

TypeArgsArray typeArgsFromAsts(ref ExprCtx ctx, in TypeAst[] typeAsts) {
	TypeArgsArray res = typeArgsArray();
	mapTo(res, typeAsts, (ref TypeAst x) => typeFromAst2(ctx, x));
	return res;
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

// Inferring type args are in 'a', not 'b'
bool matchTypesNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	Type expectedType,
	scope InferringTypeArgs expectedTypeArgs,
	Type actualType,
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
			matchTypesNoDiagnostic(alloc, programState, candidateReturnType, candidateTypeArgs, t),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				Opt!Type t = tryGetDeeplyInstantiatedType(alloc, programState, expected);
				if (has(t))
					return matchTypesNoDiagnostic(
						alloc, programState, candidateReturnType, candidateTypeArgs, force(t));
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

void mustSetType(ref Alloc alloc, ref ProgramState programState, ref Expected expected, Type setType) {
	bool success = setTypeNoDiagnostic(alloc, programState, expected, setType);
	verify(success);
}

// Note: this may infer type parameters
private bool setTypeNoDiagnostic(ref Alloc alloc, ref ProgramState programState, ref Expected expected, Type actual) =>
	expected.match!bool(
		(Expected.Infer) {
			setToType(expected, actual);
			return true;
		},
		(Type x) {
			final switch (checkType(alloc, programState, x, InferringTypeArgs(), actual)) {
				case SetTypeResult.set:
					return unreachable!bool;
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
			setToType(expected, anyOk ? actual : Type(Type.Bogus()));
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

enum SetTypeResult {
	// Set expected to the actual type.
	set,
	// Keep the expected type (ignoring the actual type). This is useful when expected is bogus.
	keep,
	// Fail with a type error.
	fail,
}

Opt!Type tryGetDeeplyInstantiatedTypeWorker(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	in InferringTypeArgs inferringTypeArgs,
) =>
	a.matchWithPointers!(Opt!Type)(
		(Type.Bogus) =>
			some(Type(Type.Bogus())),
		(TypeParam* p) {
			MutOpt!(const(SingleInferringType)*) ta = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			// If it's not one of the inferring types, it's instantiated enough to return.
			return has(ta) ? tryGetInferred(*force(ta)) : some(a);
		},
		(StructInst* i) {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (Type x; typeArgs(*i)) {
				Opt!Type t = tryGetDeeplyInstantiatedTypeWorker(alloc, programState, x, inferringTypeArgs);
				if (has(t))
					push(newTypeArgs, force(t));
				else
					return none!Type;
			}
			return some(Type(instantiateStructNeverDelay(alloc, programState, decl(*i), tempAsArr(newTypeArgs))));
		});

SetTypeResult setTypeNoDiagnosticWorker_forSingleInferringType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref SingleInferringType inferring,
	Type actual,
) {
	Opt!Type inferred = tryGetInferred(inferring);
	SetTypeResult res = has(inferred)
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
SetTypeResult checkType(
	ref Alloc alloc,
	ref ProgramState programState,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	Type b,
) =>
	a.matchWithPointers!SetTypeResult(
		(Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			SetTypeResult.keep,
		(TypeParam* pa) {
			MutOpt!(SingleInferringType*) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType(alloc, programState, *force(aInferring), b)
				: b.matchWithPointers!(SetTypeResult)(
					(Type.Bogus) =>
						// Bogus is assignable to anything
						SetTypeResult.keep,
					(TypeParam* pb) =>
						pa == pb ? SetTypeResult.keep : SetTypeResult.fail,
					(StructInst*) =>
						// Expecting a type param, got a particular type
						SetTypeResult.fail);
		},
		(StructInst* ai) =>
			b.matchWithPointers!SetTypeResult(
				(Type.Bogus) =>
					// Bogus is assignable to anything
					SetTypeResult.keep,
				(TypeParam*) =>
					SetTypeResult.fail,
				(StructInst* bi) =>
					checkStructInsts(alloc, programState, *ai, aInferringTypeArgs, *bi)));

SetTypeResult checkStructInsts(
	ref Alloc alloc,
	ref ProgramState programState,
	ref StructInst ai,
	scope InferringTypeArgs aInferringTypeArgs,
	ref StructInst bi,
) {
	if (decl(ai) == decl(bi)) {
		// If we need to set at least one type arg, return Set.
		// If all passed, return Keep.
		// Else, return Fail.
		SetTypeResult res = SetTypeResult.keep;
		verify(sizeEq(typeArgs(ai), typeArgs(bi)));
		foreach (size_t i, a; typeArgs(ai)) {
			Type b = typeArgs(bi)[i];
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
