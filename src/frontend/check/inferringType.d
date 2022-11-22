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
	asStructInst,
	asTypeParam,
	CommonTypes,
	decl,
	Expr,
	FunFlags,
	FunKindAndStructs,
	isBogus,
	isStructInst,
	isTypeParam,
	Local,
	matchType,
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
import util.col.arrUtil : arrLiteral, exists, map;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : mapTo, MutMaxArr, push, tempAsArr;
import util.memory : overwriteMemory;
import util.opt : has, force, none, noneMut, Opt, some;
import util.perf : Perf;
import util.ptr : castNonScope_ref;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym;
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
	immutable Opt!(Expr.Lambda*) lambda;
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
	matchType!(immutable bool)(
		type,
		(immutable Type.Bogus) =>
			false,
		(immutable TypeParam* p) {
			const Opt!(SingleInferringType*) inferring = tryGetTypeArgFromInferringTypeArgs(inferringTypeArgs, p);
			immutable Opt!Type inferred = has(inferring) ? cellGet(force(inferring).type) : none!Type;
			return has(inferred) && isStructInst(force(inferred))
				? isFunTypeWithArity(commonTypes, asStructInst(force(inferred)), arity)
				: true;
		},
		(immutable StructInst* i) =>
			isFunTypeWithArity(commonTypes, i, arity));

private immutable(bool) isFunTypeWithArity(
	ref immutable CommonTypes commonTypes,
	immutable StructInst* a,
	immutable size_t arity,
) {
	immutable StructDecl* actual = decl(*a);
	foreach (immutable FunKindAndStructs f; commonTypes.funKindsAndStructs)
		if (arity < f.structs.length && f.structs[arity] == actual)
			return true;			
	return false;
}

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
	immutable Expr.Loop* loop;
	immutable Type type;
	bool hasBreak;
}

struct TypeAndInferring {
	immutable Type type;
	InferringTypeArgs inferringTypeArgs;
}

struct Expected {
	@safe @nogc pure nothrow:

	struct Infer {}

	private:
	enum Kind { infer, type, typeAndInferring, loop }
	Kind kind;
	union {
		Infer infer_;
		immutable Type type_;
		TypeAndInferring[] typeAndInferring_;
		LoopInfo* loop_;
	}

	public:
	@disable this();
	this(Infer a) {
		kind = Kind.infer;
		infer_ = a;
	}
	this(immutable Type a) {
		kind = Kind.type;
		type_ = a;
	}
	this(return TypeAndInferring[] a) {
		kind = Kind.typeAndInferring;
		typeAndInferring_ = a;
	}
	this(return scope LoopInfo* a) {
		kind = Kind.loop;
		loop_ = a;
	}
}

private @trusted T matchExpected_const(T)(
	scope ref const Expected a,
	scope T delegate(immutable Expected.Infer) @safe @nogc pure nothrow cbInfer,
	scope T delegate(immutable Type) @safe @nogc pure nothrow cbType,
	scope T delegate(const TypeAndInferring[]) @safe @nogc pure nothrow cbTypeAndInferring,
	scope T delegate(const LoopInfo*) @safe @nogc pure nothrow cbLoop,
) {
	final switch (a.kind) {
		case Expected.Kind.infer:
			return cbInfer(a.infer_);
		case Expected.Kind.type:
			return cbType(a.type_);
		case Expected.Kind.typeAndInferring:
			return cbTypeAndInferring(a.typeAndInferring_);
		case Expected.Kind.loop:
			return cbLoop(a.loop_);
	}
}
private @trusted T matchExpected_mut(T)(
	scope ref Expected a,
	scope T delegate(immutable Expected.Infer) @safe @nogc pure nothrow cbInfer,
	scope T delegate(immutable Type) @safe @nogc pure nothrow cbType,
	scope T delegate(TypeAndInferring[]) @safe @nogc pure nothrow cbTypeAndInferring,
	scope T delegate(LoopInfo*) @safe @nogc pure nothrow cbLoop,
) {
	final switch (a.kind) {
		case Expected.Kind.infer:
			return cbInfer(a.infer_);
		case Expected.Kind.type:
			return cbType(a.type_);
		case Expected.Kind.typeAndInferring:
			return cbTypeAndInferring(a.typeAndInferring_);
		case Expected.Kind.loop:
			return cbLoop(a.loop_);
	}
}

@trusted Opt!(LoopInfo*) tryGetLoop(ref Expected expected) =>
	expected.kind == Expected.Kind.loop
		? some(expected.loop_)
		: noneMut!(LoopInfo*);

@trusted immutable(Opt!Type) tryGetInferred(ref const Expected expected) =>
	matchExpected_const!(immutable Opt!Type)(
		expected,
		(immutable Expected.Infer) =>
			none!Type,
		(immutable Type x) =>
			some(x),
		(const TypeAndInferring[] ti) =>
			ti.length == 1 ? some(only(ti).type) : none!Type,
		(const LoopInfo*) =>
			none!Type);

// TODO: if we have a bogus expected type we should probably not be doing any more checking at all?
immutable(bool) isBogus(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t) && isBogus(force(t));
}

private @trusted void setToType(scope ref Expected expected, immutable Type type) {
	overwriteMemory(&castNonScope_ref(expected), Expected(type));
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
	scope immutable(T) delegate(scope ref Expected) @safe @nogc pure nothrow cb,
) {
	TypeAndInferring[1] t = [TypeAndInferring(newExpectedType, getInferringTypeArgs(expected))];
	Expected newExpected = Expected(t);
	immutable T res = cb(newExpected);
	return Pair!(T, Type)(res, inferred(newExpected));
}

immutable(Opt!Type) shallowInstantiateType(ref const Expected expected) =>
	matchExpected_const!(immutable Opt!Type)(
		expected,
		(immutable Expected.Infer) =>
			none!Type,
		(immutable Type x) =>
			some(x),
		(const TypeAndInferring[] choices) {
			if (choices.length == 1) {
				const TypeAndInferring choice = only(choices);
				if (isTypeParam(choice.type)) {
					const Opt!(SingleInferringType*) typeArg =
						tryGetTypeArgFromInferringTypeArgs(choice.inferringTypeArgs, asTypeParam(choice.type));
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
	matchExpected_mut!InferringTypeArgs(
		expected,
		(immutable Expected.Infer) =>
			unreachable!InferringTypeArgs,
		(immutable Type x) =>
			InferringTypeArgs(),
		(TypeAndInferring[] choices) =>
			only(choices).inferringTypeArgs,
		(LoopInfo*) =>
			unreachable!InferringTypeArgs);
private const(InferringTypeArgs) getInferringTypeArgs(ref const Expected expected) =>
	matchExpected_const!(const InferringTypeArgs)(
		expected,
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
	matchExpected_const!(immutable bool)(
		expected,
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

immutable(Expr) bogus(scope ref Expected expected, immutable FileAndRange range) {
	matchExpected_mut!void(
		expected,
		(immutable Expected.Infer) {
			setToBogus(expected);
		},
		(immutable(Type)) {},
		(TypeAndInferring[]) {
			setToBogus(expected);
		},
		(LoopInfo*) {});
	return immutable Expr(range, immutable Expr.Bogus());
}

immutable(Type) inferred(ref const Expected expected) =>
	matchExpected_const!(immutable Type)(
		expected,
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
	scope ref Expected expected,
	immutable Type exprType,
	immutable Expr expr,
) {
	if (setTypeNoDiagnostic(ctx.alloc, ctx.programState, expected, exprType))
		return expr;
	else {
		addDiag2(ctx, range(expr), matchExpected_const!(immutable Diag)(
			castNonScope_ref(expected),
			(scope immutable Expected.Infer) =>
				unreachable!(immutable Diag),
			(scope immutable Type x) =>
				immutable Diag(immutable Diag.TypeConflict(arrLiteral!Type(ctx.alloc, [x]), exprType)),
			(scope const TypeAndInferring[] xs) =>
				immutable Diag(immutable Diag.TypeConflict(
					map(ctx.alloc, xs, (scope ref const TypeAndInferring x) => x.type),
					exprType)),
			(scope const LoopInfo*) =>
				immutable Diag(immutable Diag.LoopNeedsBreakOrContinue())));
		return bogus(expected, range(expr));
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
	scope ref Expected expected,
	immutable Type actual,
) =>
	matchExpected_mut!(immutable bool)(
		expected,
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
	matchType!(immutable Opt!Type)(
		a,
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
	matchType!(immutable SetTypeResult)(
		a,
		(immutable Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			SetTypeResult.keep,
		(immutable TypeParam* pa) {
			Opt!(SingleInferringType*) aInferring = tryGetTypeArgFromInferringTypeArgs(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType(alloc, programState, *force(aInferring), b)
				: matchType!(immutable SetTypeResult)(
					b,
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
			matchType!(immutable SetTypeResult)(
				b,
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
	if (isBogus(a) || isBogus(b))
		return true;
	if (isTypeParam(a)) {
		const Opt!(SingleInferringType*) aSingle = tryGetTypeArgFromInferringTypeArgs(aInferring, asTypeParam(a));
		if (has(aSingle)) {
			immutable Opt!Type t = tryGetInferred(*force(aSingle));
			return !has(t) || isTypeMatchPossible(force(t), InferringTypeArgs(), b, bInferring);
		}
	}
	if (isTypeParam(b)) {
		const Opt!(SingleInferringType*) bSingle = tryGetTypeArgFromInferringTypeArgs(bInferring, asTypeParam(b));
		if (has(bSingle)) {
			immutable Opt!Type t = tryGetInferred(*force(bSingle));
			return !has(t) || isTypeMatchPossible(a, aInferring, force(t), InferringTypeArgs());
		}
	}
	if (isStructInst(a) && isStructInst(b)) {
		immutable StructInst* sa = asStructInst(a);
		immutable StructInst* sb = asStructInst(b);
		if (decl(*sa) != decl(*sb))
			return false;
		foreach (immutable size_t i; 0 .. typeArgs(*sa).length)
			if (!isTypeMatchPossible(typeArgs(*sa)[i], aInferring, typeArgs(*sb)[i], bInferring))
				return false;
		return true;
	}
	return false;
}
