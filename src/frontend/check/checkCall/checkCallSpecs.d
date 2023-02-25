module frontend.check.checkCall.checkCallSpecs;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate, Candidates, FunsInScope, funsInScope, testCandidateForSpecSig, withCandidates;
import frontend.check.inferringType :
	addDiag2, ExprCtx, InferringTypeArgs, programStatePtr, SingleInferringType, tryGetInferred;
import frontend.check.instantiate :
	instantiateFun,
	instantiateSpecInst,
	noDelaySpecInsts,
	TypeArgsArray,
	typeArgsArray,
	TypeParamsAndArgs;
import frontend.lang : maxSpecDepth, maxSpecImpls;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	Called,
	CalledSpecSig,
	decl,
	FunDecl,
	FunDeclAndTypeArgs,
	isPurityAlwaysCompatible,
	isPurityCompatible,
	Purity,
	PurityRange,
	purityRange,
	ReturnAndParamTypes,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructInst,
	Type,
	typeArgs;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderIsEmpty, consumeArr, finishArr;
import util.col.arrUtil : every, exists, first, zipFirst;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, only, push, tempAsArr, toArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;
import util.union_ : Union;
import util.util : verify;

Opt!Called checkCallSpecs(ref ExprCtx ctx, FileAndRange range, ref const Candidate candidate) {
	CheckSpecsCtx checkSpecsCtx = CheckSpecsCtx(ctx.allocPtr, ctx.programStatePtr, funsInScope(ctx));
	return getCalledFromCandidateAfterTypeChecks(checkSpecsCtx, candidate, DummyTrace()).match!(Opt!Called)(
		(Called x) {
			consumeArr(checkSpecsCtx.alloc, checkSpecsCtx.matchDiags, (Diag.SpecMatchError diag) {
				addDiag2(ctx, range, Diag(diag));
			});
			return some(x);
		},
		(DummyTrace.NoMatch _) {
			MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs) trace = mutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);
			addDiag2(
				ctx,
				range,
				Diag(getCalledFromCandidateAfterTypeChecks(checkSpecsCtx, candidate, RealTrace(ctx.allocPtr, &trace))
					.as!(Diag.SpecNoMatch)));
			return none!Called;
		});
}

bool isPurityAlwaysCompatibleConsideringSpecs(in immutable SpecInst*[] funSpecs, Type type, Purity expected) {
	PurityRange typePurity = purityRange(type);
	return isPurityAlwaysCompatible(expected, typePurity) ||
		exists!(SpecInst*)(funSpecs, (in SpecInst* inst) =>
			specProvidesPurity(inst, type, expected)) ||
		(type.isA!(StructInst*) &&
			isPurityCompatible(expected, typePurity.bestCase) &&
			every!Type(typeArgs(*type.as!(StructInst*)), (in Type typeArg) =>
				isPurityAlwaysCompatibleConsideringSpecs(funSpecs, typeArg, expected)));
}

private:

struct CheckSpecsCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	ProgramState* programStatePtr;
	immutable FunsInScope funsInScope;
	ArrBuilder!(Diag.SpecMatchError) matchDiags; 

	ref Alloc alloc() =>
		*allocPtr;
	ref ProgramState programState() =>
		*programStatePtr;
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
}
struct RealTrace {
	alias NoMatch = Diag.SpecNoMatch;
	alias Result = SpecResult!NoMatch;
	Alloc* alloc;
	MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs)* trace;
}

T withTrace(T)(
	DummyTrace trace,
	FunDeclAndTypeArgs,
	in T delegate(scope DummyTrace) @safe @nogc pure nothrow cb,
) =>
	cb(DummyTrace(trace.depth + 1));
T withTrace(T)(
	scope RealTrace trace,
	FunDeclAndTypeArgs called,
	in T delegate(scope RealTrace) @safe @nogc pure nothrow cb,
) {
	push(*trace.trace, called);
	T res = cb(trace);
	mustPop(*trace.trace);
	return res;
}

DummyTrace.NoMatch specNoMatch(scope DummyTrace, Diag.SpecNoMatch.Reason) =>
	DummyTrace.NoMatch();
RealTrace.NoMatch specNoMatch(scope RealTrace a, Diag.SpecNoMatch.Reason reason) =>
	Diag.SpecNoMatch(reason, toArray(*a.alloc, *a.trace));
bool isFull(DummyTrace trace) {
	verify(trace.depth <= maxSpecDepth);
	return trace.depth == maxSpecDepth;
}
bool isFull(RealTrace trace) =>
	isFull(*trace.trace);

Trace.Result checkCandidate(Trace)(
	ref CheckSpecsCtx ctx,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	ref Candidate candidate,
	scope Trace trace,
) =>
	testCandidateForSpecSig(ctx.alloc, ctx.programState, candidate, sigType, InferringTypeArgs())
		? getCalledFromCandidateAfterTypeChecks(ctx, candidate, trace)
		: Trace.Result(specNoMatch(
			trace,
			Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.SpecImplNotFound(sigDecl, sigType))));

Trace.Result getCalledFromCandidateAfterTypeChecks(Trace)(
	ref CheckSpecsCtx ctx,
	ref const Candidate candidate,
	scope Trace trace,
) {
	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; tempAsArr(candidate.typeArgs)) {
		Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else
			return Trace.Result(specNoMatch(
				trace,
				Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.CantInferTypeArguments())));
	}
	return candidate.called.matchWithPointers!(Trace.Result)(
		(FunDecl* f) {
			if (isFull(trace))
				return Trace.Result(specNoMatch(trace, Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.TooDeep())));
			else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, Called);
				Opt!(Trace.NoMatch) diag = checkSpecImpls(specImpls, ctx, f, tempAsArr(candidateTypeArgs), trace);
				return has(diag)
					? Trace.Result(force(diag))
					: Trace.Result(Called(instantiateFun(
						ctx.alloc, ctx.programState, f, tempAsArr(candidateTypeArgs), tempAsArr(specImpls))));
			}
		},
		(CalledSpecSig s) =>
			Trace.Result(Called(allocate(ctx.alloc, s))));
}

bool deeper(DummyTrace.NoMatch, DummyTrace.NoMatch) =>
	false;
bool deeper(Diag.SpecNoMatch a, Diag.SpecNoMatch b) =>
	a.trace.length > b.trace.length;

Trace.Result findSpecSigImplementation(Trace)(
	ref CheckSpecsCtx ctx,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	scope Trace trace,
) =>
	withCandidates(ctx.funsInScope, sigDecl.name, sigType.paramTypes.length, (ref Candidates candidates) {
		Cell!(Opt!Called) res;
		ArrBuilder!Called multipleMatches;
		Cell!(Opt!(Trace.NoMatch)) deepestNoMatch = Cell!(Opt!(Trace.NoMatch))();
		foreach (ref Candidate candidate; candidates) {
			checkCandidate(ctx, sigDecl, sigType, candidate, trace).match!bool(
				(Called x) {
					if (has(cellGet(res))) {
						add(ctx.alloc, multipleMatches, x);
					} else
						cellSet(res, some(x));
					return false;
				},
				(Trace.NoMatch x) {
					if (!has(cellGet(deepestNoMatch)) || deeper(x, force(cellGet(deepestNoMatch))))
						cellSet(deepestNoMatch, some(x));
					return false;
				});
		}
		if (has(cellGet(res))) {
			if (arrBuilderIsEmpty(multipleMatches)) {
				return Trace.Result(force(cellGet(res)));
			} else {
				add(ctx.alloc, multipleMatches, force(cellGet(res)));
				add(ctx.alloc, ctx.matchDiags, Diag.SpecMatchError(Diag.SpecMatchError.Reason(
					Diag.SpecMatchError.Reason.MultipleMatches(sigDecl.name, finishArr(ctx.alloc, multipleMatches)))));
				return Trace.Result(force(cellGet(res)));
			}
		} else
			return Trace.Result(has(cellGet(deepestNoMatch))
				? force(cellGet(deepestNoMatch))
				: specNoMatch(
					trace,
					Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.SpecImplNotFound(sigDecl, sigType))));
	});

bool checkBuiltinSpec(
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	SpecDeclBody.Builtin.Kind kind,
	Type typeArg,
) =>
	isPurityAlwaysCompatibleConsideringSpecs(ctx.funsInScope.outermostFunSpecs, typeArg, purityOfBuiltinSpec(kind));

Purity purityOfBuiltinSpec(SpecDeclBody.Builtin.Kind kind) {
	final switch (kind) {
		case SpecDeclBody.Builtin.Kind.data:
			return Purity.data;
		case SpecDeclBody.Builtin.Kind.shared_:
			return Purity.shared_;
	}
}

// Whether 'inst' tells us that 'type' has purity at least 'expected'
bool specProvidesPurity(in SpecInst* inst, in Type type, Purity expected) =>
	exists!(SpecInst*)(inst.parents, (in SpecInst* parent) =>
		specProvidesPurity(parent, type, expected)) ||
	decl(*inst).body_.matchIn!bool(
		(in SpecDeclBody.Builtin b) =>
			only(typeArgs(*inst)) == type && isPurityCompatible(expected, purityOfBuiltinSpec(b.kind)),
		(in SpecDeclSig[]) =>
			false);

Opt!(Trace.NoMatch) checkSpecImpls(Trace)(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	in Type[] calledTypeArgs,
	scope Trace trace,
) =>
	first!(Trace.NoMatch, immutable SpecInst*)(called.specs, (SpecInst* specInst) =>
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		checkSpecImpl(res, ctx, called, trace, *instantiateSpecInst(
			ctx.alloc, ctx.programState, specInst,
			TypeParamsAndArgs(called.typeParams, calledTypeArgs), noDelaySpecInsts)));

Opt!(Trace.NoMatch) checkSpecImpl(Trace)(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	scope Trace outerTrace,
	in SpecInst specInstInstantiated,
) {
	Type[] typeArgs = typeArgs(specInstInstantiated);
	return withTrace!(Opt!(Trace.NoMatch))(outerTrace, FunDeclAndTypeArgs(called, typeArgs), (scope Trace trace) {
		Opt!(Trace.NoMatch) parentDiag = first!(Trace.NoMatch, immutable SpecInst*)(
			specInstInstantiated.parents, (SpecInst* parent) => checkSpecImpl(res, ctx, called, trace, *parent));
		return has(parentDiag) ? parentDiag : specInstInstantiated.decl.body_.match!(Opt!(Trace.NoMatch))(
			(SpecDeclBody.Builtin b) =>
				checkBuiltinSpec(ctx, called, b.kind, only(typeArgs))
					? none!(Trace.NoMatch)
					: some(specNoMatch(
						trace,
						Diag.SpecNoMatch.Reason(Diag.SpecNoMatch.Reason.BuiltinNotSatisfied(b.kind, only(typeArgs))))),
			(SpecDeclSig[] sigDecls) =>
				zipFirst!(Trace.NoMatch, SpecDeclSig, ReturnAndParamTypes)(
					sigDecls, specInstInstantiated.sigTypes, (SpecDeclSig* sigDecl, in ReturnAndParamTypes sigType) =>
						findSpecSigImplementation(ctx, sigDecl, sigType, trace).match!(Opt!(Trace.NoMatch))(
							(Called x) {
								push(res, x);
								return none!(Trace.NoMatch);
							},
							(Trace.NoMatch x) =>
								some(x))));
	});
}
