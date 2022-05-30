module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.instantiate :
	instantiateStructNeverDelay, tryGetTypeArg_const, tryGetTypeArg_mut, TypeArgsArray, typeArgsArray, TypeParamsScope;
import frontend.check.typeFromAst : typeFromAst;
import frontend.lang : maxClosureFields, maxParams;
import frontend.parse.ast : TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	asTypeParam,
	CommonTypes,
	decl,
	Expr,
	FunFlags,
	isBogus,
	isTypeParam,
	Local,
	matchType,
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
import util.col.arr : sizeEq;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr;
import util.col.mutMaxArr : mapTo, MutMaxArr, push, tempAsArr;
import util.memory : overwriteMemory;
import util.opt : has, force, none, noneMut, Opt, some, someMut;
import util.perf : Perf;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : AllSymbols, Sym;
import util.util : unreachable, verify;

struct ClosureFieldBuilder {
	immutable Sym name; // Redundant to the variableRef, but it's faster to keep this close
	immutable Type type; // Same as above
	immutable VariableRef variableRef;
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

immutable(bool) isInLambda(ref LocalsInfo a) {
	return has(a.funOrLambda.outer);
}

struct LocalNode {
	Opt!(LocalNode*) prev;
	bool isUsedGet;
	bool isUsedSet;
	immutable Local* local;
}

void markIsUsedSet(scope ref LocalsInfo locals, immutable Local* local) {
	LocalNode* node = force(locals.locals);
	while (true) {
		if (node.local == local) {
			node.isUsedSet = true;
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

	ref Alloc alloc() return scope {
		return checkCtx().alloc();
	}

	ref const(AllSymbols) allSymbols() return scope const {
		return checkCtx().allSymbols();
	}
	ref AllSymbols allSymbols() return scope {
		return checkCtx().allSymbols();
	}
	ref Perf perf() return scope {
		return checkCtx().perf();
	}
	ref CheckCtx checkCtx() return scope {
		return *checkCtxPtr;
	}
	ref const(CheckCtx) checkCtx() return scope const {
		return *checkCtxPtr;
	}
}

void markUsedLocalFun(ref ExprCtx a, immutable ModuleLocalFunIndex index) {
	a.funsUsed[index] = true;
}

immutable(FileAndRange) rangeInFile2(ref const ExprCtx ctx, immutable RangeWithinFile range) {
	return rangeInFile(ctx.checkCtx, range);
}

ref ProgramState programState(return scope ref ExprCtx ctx) {
	return ctx.checkCtx.programState;
}

void addDiag2(ref ExprCtx ctx, immutable FileAndRange range, immutable Diag diag) {
	addDiag(ctx.checkCtx, range, diag);
}

TypeArgsArray typeArgsFromAsts(ref ExprCtx ctx, scope immutable TypeAst[] typeAsts) {
	TypeArgsArray res = typeArgsArray();
	mapTo(res, typeAsts, (ref immutable TypeAst x) => typeFromAst2(ctx, x));
	return res;
}

immutable(Opt!Type) typeFromOptAst(ref ExprCtx ctx, immutable Opt!(TypeAst*) ast) {
	return has(ast) ? some(typeFromAst2(ctx, *force(ast))) : none!Type;
}

immutable(Type) typeFromAst2(ref ExprCtx ctx, scope immutable TypeAst ast) {
	return typeFromAst(
		ctx.checkCtx,
		ctx.commonTypes,
		ast,
		ctx.structsAndAliasesDict,
		immutable TypeParamsScope(ctx.outermostFunTypeParams),
		noneMut!(MutArr!(StructInst*)*));
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
}

// Inferring type args are in 'a', not 'b'
immutable(bool) matchTypesNoDiagnostic(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type expectedType,
	immutable Type setType,
	scope ref InferringTypeArgs aInferringTypeArgs
) {
	return matchSetTypeResult!(immutable bool)(
		checkAssignability(alloc, programState, expectedType, setType, aInferringTypeArgs),
		(immutable(SetTypeResult.Set)) => true,
		(immutable(SetTypeResult.Keep)) => true,
		(immutable(SetTypeResult.Fail)) => false);
}

struct LoopInfo {
	immutable Type voidType;
	immutable Expr.Loop* loop;
	immutable Type type;
	bool hasBreak;
}

struct Expected {
	@safe @nogc pure nothrow:

	struct Infer {}

	InferringTypeArgs inferringTypeArgs; //TODO: only used with 'type'
	private:
	enum Kind { infer, type, loop }
	Kind kind;
	union {
		Infer infer_;
		Type type_;
		LoopInfo* loop_;
	}

	public:
	@disable this();
	this(immutable Infer a) {
		kind = Kind.infer;
		infer_ = a;
	}
	this(immutable Type a) {
		kind = Kind.type;
		type_ = a;
	}
	this(immutable Type type, InferringTypeArgs ita) {
		kind = Kind.type;
		type_ = type;
		inferringTypeArgs = ita;
	}
	this(return scope LoopInfo* a) {
		kind = Kind.loop;
		loop_ = a;
	}
}

private @trusted immutable(T) matchExpected(T)(
	ref Expected a,
	scope immutable(T) delegate(immutable Expected.Infer) @safe @nogc pure nothrow cbInfer,
	scope immutable(T) delegate(immutable Type) @safe @nogc pure nothrow cbType,
	scope immutable(T) delegate(LoopInfo*) @safe @nogc pure nothrow cbLoop,
) {
	final switch (a.kind) {
		case Expected.Kind.infer:
			return cbInfer(a.infer_);
		case Expected.Kind.type:
			return cbType(a.type_);
		case Expected.Kind.loop:
			return cbLoop(a.loop_);
	}
}

@trusted Opt!(LoopInfo*) tryGetLoop(ref Expected expected) {
	return expected.kind == Expected.Kind.loop
		? someMut(expected.loop_)
		: noneMut!(LoopInfo*);
}

immutable(Opt!Type) tryGetInferred(ref const Expected expected) {
	return expected.kind == Expected.Kind.type ? some(expected.type_) : none!Type;
}

// TODO: if we have a bogus expected type we should probably not be doing any more checking at all?
immutable(bool) isBogus(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	return has(t) && isBogus(force(t));
}

Expected copyWithNewExpectedType(ref Expected expected, immutable Type type) {
	return Expected(type, expected.inferringTypeArgs);
}

immutable(Opt!Type) shallowInstantiateType(ref const Expected expected) {
	immutable Opt!Type t = tryGetInferred(expected);
	if (has(t) && isTypeParam(force(t))) {
		const Opt!(SingleInferringType*) typeArg =
			tryGetTypeArgFromInferringTypeArgs_const(expected.inferringTypeArgs, asTypeParam(force(t)));
		return has(typeArg) ? tryGetInferred(*force(typeArg)) : none!Type;
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

immutable(Expr) bogus(ref Expected expected, immutable FileAndRange range) {
	matchExpected!void(
		expected,
		(immutable Expected.Infer) {
			overwriteMemory(&expected, Expected(immutable Type(immutable Type.Bogus())));
		},
		(immutable(Type)) {},
		(LoopInfo*) {});
	return immutable Expr(range, immutable Expr.Bogus());
}

immutable(Type) inferred(ref Expected expected) {
	return matchExpected!(immutable Type)(
		expected,
		(immutable Expected.Infer) =>
			unreachable!(immutable Type),
		(immutable Type x) =>
			x,
		(LoopInfo* x) =>
			// Just treat loop body as 'void'
			x.voidType);
}

immutable(Expr) check(
	ref ExprCtx ctx,
	ref Expected expected,
	immutable Type exprType,
	immutable Expr expr,
) {
	if (setTypeNoDiagnostic(ctx.alloc, ctx.programState, expected, exprType))
		return expr;
	else {
		addDiag2(ctx, range(expr), matchExpected!(immutable Diag)(
			expected,
			(immutable Expected.Infer) =>
				unreachable!(immutable Diag),
			(immutable Type t) =>
				immutable Diag(immutable Diag.TypeConflict(t, exprType)),
			(LoopInfo*) =>
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
	ref Expected expected,
	immutable Type setType,
) {
	return matchExpected!(immutable bool)(
		expected,
		(immutable Expected.Infer) {
			overwriteMemory(&expected, Expected(setType));
			return true;
		},
		(immutable Type expectedType) =>
			matchSetTypeResult!(immutable bool)(
				checkAssignability(alloc, programState, expectedType, setType, expected.inferringTypeArgs),
				(immutable SetTypeResult.Set s) {
					overwriteMemory(&expected, Expected(s.type));
					return true;
				},
				(immutable SetTypeResult.Keep) =>
					true,
				(immutable SetTypeResult.Fail) =>
					false),
		(LoopInfo* loop) =>
			false);
}

private Opt!(SingleInferringType*) tryGetTypeArgFromInferringTypeArgs_mut(
	return scope ref InferringTypeArgs inferringTypeArgs,
	immutable TypeParam* typeParam,
) {
	return tryGetTypeArg_mut!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
}

const(Opt!(SingleInferringType*)) tryGetTypeArgFromInferringTypeArgs_const(
	return scope ref const InferringTypeArgs inferringTypeArgs,
	immutable TypeParam* typeParam,
) {
	return tryGetTypeArg_const!SingleInferringType(inferringTypeArgs.params, inferringTypeArgs.args, typeParam);
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
	immutable SetTypeResult a,
	scope immutable(T) delegate(immutable SetTypeResult.Set) @safe @nogc pure nothrow cbSet,
	scope immutable(T) delegate(immutable SetTypeResult.Keep) @safe @nogc pure nothrow cbKeep,
	scope immutable(T) delegate(immutable SetTypeResult.Fail) @safe @nogc pure nothrow cbFail,
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
	immutable StructDecl* decl,
	immutable Type[] as,
	immutable Type[] bs,
	scope ref InferringTypeArgs aInferringTypeArgs,
) {
	// If we need to set at least one type arg, return Set.
	// If all passed, return Keep.
	// Else, return Fail.
	bool someIsSet = false;
	scope TypeArgsArray newTypeArgs = typeArgsArray();
	verify(sizeEq(as, bs));
	foreach (immutable size_t i, a; as) {
		immutable Type b = bs[i];
		immutable Opt!Type setType = matchSetTypeResult!(immutable Opt!Type)(
			checkAssignability(alloc, programState, a, b, aInferringTypeArgs),
			(immutable SetTypeResult.Set x) {
				someIsSet = true;
				return some(x.type);
			},
			(immutable(SetTypeResult.Keep)) =>
				some(a),
			(immutable(SetTypeResult.Fail)) =>
				none!Type);
		if (has(setType))
			push(newTypeArgs, force(setType));
		else
			return immutable SetTypeResult(immutable SetTypeResult.Fail());
	}
	return someIsSet
		? immutable SetTypeResult(immutable SetTypeResult.Set(immutable Type(
			instantiateStructNeverDelay(alloc, programState, decl, tempAsArr(newTypeArgs)))))
		: immutable SetTypeResult(immutable SetTypeResult.Keep());
}

immutable(SetTypeResult) setTypeNoDiagnosticWorker_forStructInst(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable StructInst a,
	ref immutable StructInst b,
	scope ref InferringTypeArgs aInferringTypeArgs,
) {
	// Handling a union expected type is done in Expected::check
	// TODO: but it's done here to for case of call return type ...
	if (decl(a) == decl(b))
		return checkAssignabilityForStructInstsWithSameDecl(
			alloc, programState, a.decl, a.typeArgs, b.typeArgs, aInferringTypeArgs);
	else
		return SetTypeResult(SetTypeResult.Fail());
}

immutable(Opt!Type) tryGetDeeplyInstantiatedTypeWorker(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable Type a,
	ref const InferringTypeArgs inferringTypeArgs,
) {
	return matchType!(immutable Opt!Type)(
		a,
		(immutable Type.Bogus) =>
			some(immutable Type(Type.Bogus())),
		(immutable TypeParam* p) {
			const Opt!(SingleInferringType*) ta = tryGetTypeArgFromInferringTypeArgs_const(inferringTypeArgs, p);
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
	InferringTypeArgs inferring = InferringTypeArgs();
	immutable SetTypeResult res = checkAssignabilityOpt(alloc, programState, tryGetInferred(sit), setType, inferring);
	matchSetTypeResult!void(
		res,
		(immutable SetTypeResult.Set s) {
			cellSet(sit.type, some(s.type));
		},
		(immutable SetTypeResult.Keep) {},
		(immutable SetTypeResult.Fail) {});
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
	scope ref InferringTypeArgs aInferringTypeArgs,
) {
	return matchType!(immutable SetTypeResult)(
		a,
		(immutable Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			immutable SetTypeResult(immutable SetTypeResult.Keep()),
		(immutable TypeParam* pa) {
			Opt!(SingleInferringType*) aInferring = tryGetTypeArgFromInferringTypeArgs_mut(aInferringTypeArgs, pa);
			return has(aInferring)
				? setTypeNoDiagnosticWorker_forSingleInferringType(alloc, programState, *force(aInferring), b)
				: matchType!(immutable SetTypeResult)(
					b,
					(immutable Type.Bogus) =>
						// Bogus is assignable to anything
						immutable SetTypeResult(immutable SetTypeResult.Keep()),
					(immutable TypeParam* pb) =>
						pa == pb
							? immutable SetTypeResult(immutable SetTypeResult.Keep())
							: immutable SetTypeResult(immutable SetTypeResult.Fail()),
					(immutable StructInst*) =>
						// Expecting a type param, got a particular type
						immutable SetTypeResult(immutable SetTypeResult.Fail()));
		},
		(immutable StructInst* ai) @safe =>
			matchType!(immutable SetTypeResult)(
				b,
				(immutable Type.Bogus) =>
					// Bogus is assignable to anything
					immutable SetTypeResult(immutable SetTypeResult.Keep()),
				(immutable TypeParam*) =>
					immutable SetTypeResult(immutable SetTypeResult.Fail()),
				(immutable StructInst* bi) =>
					setTypeNoDiagnosticWorker_forStructInst(
						alloc,
						programState,
						*ai,
						*bi,
						aInferringTypeArgs)));
}
