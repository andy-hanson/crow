module frontend.check.checkCall.checkCallSpecs;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate, eachCandidate, FunsInScope, funsInScope, testCandidateForSpecSig;
import frontend.check.exprCtx : addDiag2, ExprCtx;
import frontend.check.inferringType : SingleInferringType, tryGetInferred, TypeContext;
import frontend.check.instantiate :
	InstantiateCtx,
	instantiateFun,
	instantiateSpecInst,
	noDelaySpecInsts,
	TypeArgsArray,
	typeArgsArray;
import frontend.lang : maxSpecDepth, maxSpecImpls;
import model.diag : Diag;
import model.model :
	BuiltinSpec,
	Called,
	CalledSpecSig,
	FunDecl,
	FunDeclAndTypeArgs,
	isPurityAlwaysCompatible,
	isPurityCompatible,
	Purity,
	PurityRange,
	purityRange,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructInst,
	Type,
	TypeArgs;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : every, exists, first, only, small, zipFirst;
import util.col.arrayBuilder : add, ArrayBuilder, arrBuilderIsEmpty, finish;
import util.col.mutMaxArr : asTemporaryArray, isFull, mustPop, MutMaxArr, mutMaxArr, only, push, toArray;
import util.opt : force, has, none, Opt, optIf, optOr, some;
import util.sourceRange : Range;
import util.union_ : Union;
import util.util : enumConvert, ptrTrustMe;

bool isPurityAlwaysCompatibleConsideringSpecs(in immutable SpecInst*[] funSpecs, Type type, Purity expected) {
	PurityRange typePurity = purityRange(type);
	return isPurityAlwaysCompatible(expected, typePurity) ||
		exists!(SpecInst*)(funSpecs, (in SpecInst* inst) =>
			specProvidesPurity(inst, type, expected)) ||
		(type.isA!(StructInst*) &&
			isPurityCompatible(expected, typePurity.bestCase) &&
			every!Type(type.as!(StructInst*).typeArgs, (in Type typeArg) =>
				isPurityAlwaysCompatibleConsideringSpecs(funSpecs, typeArg, expected)));
}

Opt!Called checkCallSpecs(ref ExprCtx ctx, in Range range, ref const Candidate candidate) {
	CheckSpecsCtx checkSpecsCtx = CheckSpecsCtx(ctx.allocPtr, ctx.instantiateCtx, funsInScope(ctx));
	return getCalledFromCandidateAfterTypeChecks(checkSpecsCtx, candidate, DummyTrace()).match!(Opt!Called)(
		(Called x) =>
			checkSpecsCtx.hasErrors ? checkCallSpecsWithRealTrace(ctx, range, candidate) : some(x),
		(DummyTrace.NoMatch _) =>
			checkCallSpecsWithRealTrace(ctx, range, candidate));
}

private:

Opt!Called checkCallSpecsWithRealTrace(ref ExprCtx ctx, in Range range, ref const Candidate candidate) {
	CheckSpecsCtx checkSpecsCtx = CheckSpecsCtx(ctx.allocPtr, ctx.instantiateCtx, funsInScope(ctx));
	RealTrace trace = RealTrace(&ctx, range);
	return getCalledFromCandidateAfterTypeChecks(checkSpecsCtx, candidate, ptrTrustMe(trace)).match!(Opt!Called)(
		(Called x) =>
			checkSpecsCtx.hasErrors ? none!Called : some(x),
		(Diag.SpecNoMatch x) {
			addDiag2(ctx, range, Diag(x));
			return none!Called;
		});
}

struct CheckSpecsCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	InstantiateCtx instantiateCtx;
	immutable FunsInScope funsInScope;
	bool hasErrors;

	ref Alloc alloc() =>
		*allocPtr;
}

alias SpecImpls = MutMaxArr!(maxSpecImpls, Called);

immutable struct SpecResult(NoMatch) {
	mixin Union!(Called, NoMatch);
}

// Avoid allocating trace for SpecNotFound errors (which will be ignored if another candidate succeeds)
struct DummyTrace {
	immutable struct NoMatch {}
	alias Result = SpecResult!NoMatch;
	uint depth;

	alias MultipleMatches = bool;
}
struct RealTrace {
	@safe @nogc pure nothrow:

	alias NoMatch = Diag.SpecNoMatch;
	alias Result = SpecResult!NoMatch;
	ExprCtx* ctx;
	Range range;
	MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs) trace;

	alias MultipleMatches = ArrayBuilder!Called;

	this(return scope ExprCtx* c, Range r) {
		ctx = c;
		range = r;
		trace = mutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);
	}
}

T withTrace(T)(
	DummyTrace trace,
	FunDeclAndTypeArgs,
	in T delegate(scope DummyTrace) @safe @nogc pure nothrow cb,
) =>
	cb(DummyTrace(trace.depth + 1));
T withTrace(T)(
	scope RealTrace* trace,
	FunDeclAndTypeArgs called,
	in T delegate(scope RealTrace*) @safe @nogc pure nothrow cb,
) {
	push(trace.trace, called);
	T res = cb(trace);
	mustPop(trace.trace);
	return res;
}

void specMatchError(ref CheckSpecsCtx ctx, scope DummyTrace, Diag.SpecMatchError.Reason) {
	ctx.hasErrors = true;
}
void specMatchError(ref CheckSpecsCtx ctx, scope RealTrace* a, Diag.SpecMatchError.Reason reason) {
	ctx.hasErrors = true;
	addDiag2(*a.ctx, a.range, Diag(Diag.SpecMatchError(a.ctx.typeContainer, reason, toArray(a.ctx.alloc, a.trace))));
}

DummyTrace.NoMatch specNoMatch(scope DummyTrace, Diag.SpecNoMatch.Reason) =>
	DummyTrace.NoMatch();
RealTrace.NoMatch specNoMatch(scope RealTrace* a, Diag.SpecNoMatch.Reason reason) =>
	Diag.SpecNoMatch(a.ctx.typeContainer, reason, toArray(a.ctx.alloc, a.trace));
bool isFull(DummyTrace trace) {
	assert(trace.depth <= maxSpecDepth);
	return trace.depth == maxSpecDepth;
}
bool isFull(in RealTrace* trace) =>
	isFull(trace.trace);

Trace.Result checkCandidate(Trace)(
	ref CheckSpecsCtx ctx,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	ref Candidate candidate,
	scope Trace trace,
) =>
	testCandidateForSpecSig(ctx.instantiateCtx, candidate, sigType, TypeContext.nonInferring)
		? getCalledFromCandidateAfterTypeChecks(ctx, candidate, trace)
		: Trace.Result(specNoMatch(trace, Diag.SpecNoMatch.Reason(
			Diag.SpecNoMatch.Reason.SpecImplNotFound(sigDecl, sigType))));

Trace.Result getCalledFromCandidateAfterTypeChecks(Trace)(
	ref CheckSpecsCtx ctx,
	ref const Candidate candidate,
	scope Trace trace,
) {
	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; candidate.typeArgs) {
		Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else
			return Trace.Result(specNoMatch(trace, Diag.SpecNoMatch.Reason(
				Diag.SpecNoMatch.Reason.CantInferTypeArguments(candidate.called.as!(FunDecl*)))));
	}
	return candidate.called.matchWithPointers!(Trace.Result)(
		(FunDecl* f) {
			if (isFull(trace))
				return Trace.Result(specNoMatch(trace, Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.TooDeep())));
			else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, Called);
				Opt!(Trace.NoMatch) diag = checkSpecImpls(
					specImpls, ctx, f, small!Type(asTemporaryArray(candidateTypeArgs)), trace);
				return has(diag)
					? Trace.Result(force(diag))
					: Trace.Result(Called(instantiateFun(
						ctx.instantiateCtx, f,
						small!Type(asTemporaryArray(candidateTypeArgs)),
						small!Called(asTemporaryArray(specImpls)))));
			}
		},
		(CalledSpecSig s) =>
			Trace.Result(Called(s)));
}

bool deeper(DummyTrace.NoMatch, DummyTrace.NoMatch) =>
	false;
bool deeper(Diag.SpecNoMatch a, Diag.SpecNoMatch b) =>
	a.trace.length > b.trace.length;

void addMultipleMatch(ref CheckSpecsCtx, DummyTrace, ref bool b, Called) {
	b = true;
}
bool hasMultipleMatches(DummyTrace, bool b) =>
	b;
Called[] finishMultipleMatches(ref CheckSpecsCtx ctx, scope DummyTrace, bool) =>
	[];

void addMultipleMatch(ref CheckSpecsCtx ctx, scope RealTrace* trace, ref ArrayBuilder!Called builder, Called match) {
	add(ctx.alloc, builder, match);
}
bool hasMultipleMatches(scope RealTrace*, in ArrayBuilder!Called builder) =>
	!arrBuilderIsEmpty(builder);
Called[] finishMultipleMatches(ref CheckSpecsCtx ctx, scope RealTrace*, ref ArrayBuilder!Called builder) =>
	finish(ctx.alloc, builder);

Trace.Result findSpecSigImplementation(Trace)(
	ref CheckSpecsCtx ctx,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	scope Trace trace,
) {
	Cell!(Opt!Called) res;
	Trace.MultipleMatches multipleMatches;
	Cell!(Opt!(Trace.NoMatch)) deepestNoMatch = Cell!(Opt!(Trace.NoMatch))();
	eachCandidate(ctx.funsInScope, sigDecl.name, sigType.paramTypes.length, (ref Candidate candidate) {
		checkCandidate(ctx, sigDecl, sigType, candidate, trace).match!void(
			(Called x) {
				if (has(cellGet(res)))
					addMultipleMatch(ctx, trace, multipleMatches, x);
				else
					cellSet(res, some(x));
			},
			(Trace.NoMatch x) {
				if (!has(cellGet(deepestNoMatch)) || deeper(x, force(cellGet(deepestNoMatch))))
					cellSet(deepestNoMatch, some(x));
			});
	});
	if (has(cellGet(res))) {
		if (hasMultipleMatches(trace, multipleMatches)) {
			addMultipleMatch(ctx, trace, multipleMatches, force(cellGet(res)));
			specMatchError(ctx, trace, Diag.SpecMatchError.Reason(Diag.SpecMatchError.Reason.MultipleMatches(
				sigDecl.name, finishMultipleMatches(ctx, trace, multipleMatches))));
		}
		return Trace.Result(force(cellGet(res)));
	} else
		return Trace.Result(has(cellGet(deepestNoMatch))
			? force(cellGet(deepestNoMatch))
			: specNoMatch(trace, Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.SpecImplNotFound(sigDecl, sigType))));
}

bool checkBuiltinSpec(ref CheckSpecsCtx ctx, FunDecl* called, BuiltinSpec kind, Type typeArg) =>
	isPurityAlwaysCompatibleConsideringSpecs(ctx.funsInScope.outermostFunSpecs, typeArg, purityOfBuiltinSpec(kind));

Purity purityOfBuiltinSpec(BuiltinSpec kind) =>
	enumConvert!Purity(kind);

// Whether 'inst' tells us that 'type' has purity at least 'expected'
bool specProvidesPurity(in SpecInst* inst, in Type type, Purity expected) =>
	(has(inst.decl.builtin) &&
		only(inst.typeArgs) == type &&
		isPurityCompatible(expected, purityOfBuiltinSpec(force(inst.decl.builtin)))
	) ||
	exists!(SpecInst*)(inst.parents, (in SpecInst* parent) =>
		specProvidesPurity(parent, type, expected));

Opt!(Trace.NoMatch) checkSpecImpls(Trace)(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	in TypeArgs calledTypeArgs,
	scope Trace trace,
) =>
	first!(Trace.NoMatch, immutable SpecInst*)(called.specs, (SpecInst* specInst) =>
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		checkSpecImpl(res, ctx, called, trace, *instantiateSpecInst(
			ctx.instantiateCtx, specInst, calledTypeArgs, noDelaySpecInsts)));

Opt!(Trace.NoMatch) checkSpecImpl(Trace)(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	scope Trace outerTrace,
	in SpecInst specInstInstantiated,
) {
	SpecDecl* decl = specInstInstantiated.decl;
	TypeArgs typeArgs = specInstInstantiated.typeArgs;
	return withTrace!(Opt!(Trace.NoMatch))(outerTrace, FunDeclAndTypeArgs(called, typeArgs), (scope Trace trace) =>
		optOr!(Trace.NoMatch)(
			optIf(has(decl.builtin) && !checkBuiltinSpec(ctx, called, force(decl.builtin), only(typeArgs)),
				() => specNoMatch(trace, Diag.SpecNoMatch.Reason(
					Diag.SpecNoMatch.Reason.BuiltinNotSatisfied(force(decl.builtin), only(typeArgs))))),
			() => first!(Trace.NoMatch, immutable SpecInst*)(
				specInstInstantiated.parents, (SpecInst* parent) => checkSpecImpl(res, ctx, called, trace, *parent)),
			() => zipFirst!(Trace.NoMatch, SpecDeclSig, ReturnAndParamTypes)(
				decl.sigs, specInstInstantiated.sigTypes, (SpecDeclSig* sigDecl, in ReturnAndParamTypes sigType) =>
					findSpecSigImplementation(ctx, sigDecl, sigType, trace).match!(Opt!(Trace.NoMatch))(
						(Called x) {
							push(res, x);
							return none!(Trace.NoMatch);
						},
						(Trace.NoMatch x) =>
							some(x)))));
}
