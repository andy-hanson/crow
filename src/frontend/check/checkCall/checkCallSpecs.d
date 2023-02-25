module frontend.check.checkCall.checkCallSpecs;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate,
	Candidates,
	candidatesForDiag,
	filterCandidates,
	FunsInScope,
	funsInScope,
	testCandidateForSpecSig,
	withCandidates;
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
import util.col.arr : only;
import util.col.arrUtil : every, exists, first, zipFirst;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, only, push, tempAsArr, toArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;
import util.union_ : Union;

Opt!Called checkCallSpecs(ref ExprCtx ctx, FileAndRange range, ref const Candidate candidate) {
	SpecTrace trace = mutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);
	CheckSpecsCtx checkSpecsCtx = CheckSpecsCtx(ctx.allocPtr, ctx.programStatePtr, funsInScope(ctx));
	return getCalledFromCandidate(checkSpecsCtx, candidate, trace).match!(Opt!Called)(
		(Called x) =>
			some(x),
		(SpecDiag x) {
			addDiag2(ctx, range, diag(x));
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

	ref Alloc alloc() =>
		*allocPtr;
	ref ProgramState programState() =>
		*programStatePtr;
}

alias SpecImpls = MutMaxArr!(maxSpecImpls, Called);
alias SpecTrace = MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);

immutable struct SpecResult {
	mixin Union!(Called, SpecDiag);
}

immutable struct SpecDiag {
	@safe @nogc pure nothrow:
	mixin Union!(
		Diag.SpecBuiltinNotSatisfied,
		Diag.SpecImplFoundMultiple,
		Diag.SpecImplNotFound,
		Diag.CantInferTypeArguments,
		Diag.SpecImplTooDeep);
}

Diag diag(SpecDiag a) =>
	a.match!Diag(
		(Diag.SpecBuiltinNotSatisfied x) => Diag(x),
		(Diag.SpecImplFoundMultiple x) => Diag(x),
		(Diag.SpecImplNotFound x) => Diag(x),
		(Diag.CantInferTypeArguments x) => Diag(x),
		(Diag.SpecImplTooDeep x) => Diag(x));

SpecResult getCalledFromCandidate(
	ref CheckSpecsCtx ctx,
	ref const Candidate candidate,
	scope ref SpecTrace trace,
) {
	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; tempAsArr(candidate.typeArgs)) {
		Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else
			return SpecResult(SpecDiag(Diag.CantInferTypeArguments(candidate.called.as!(FunDecl*))));
	}
	return candidate.called.matchWithPointers!SpecResult(
		(FunDecl* f) {
			if (isFull(trace))
				return SpecResult(SpecDiag(Diag.SpecImplTooDeep(toArray(ctx.alloc, trace))));
			else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, Called);
				Opt!SpecDiag res = checkSpecImpls(specImpls, ctx, f, tempAsArr(candidateTypeArgs), trace);
				return has(res)
					? SpecResult(force(res))
					: SpecResult(Called(
						instantiateFun(
							ctx.alloc,
							ctx.programState,
							f,
							tempAsArr(candidateTypeArgs),
							tempAsArr(specImpls))));
			}
		},
		(CalledSpecSig s) =>
			SpecResult(Called(allocate(ctx.alloc, s))));
}

SpecResult findSpecSigImplementation(
	ref CheckSpecsCtx ctx,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	scope ref SpecTrace trace,
) =>
	withCandidates(ctx.funsInScope, sigDecl.name, sigType.paramTypes.length, (ref Candidates candidates) {
		filterCandidates(candidates, (scope ref Candidate candidate) =>
			testCandidateForSpecSig(ctx.alloc, ctx.programState, candidate, sigType, InferringTypeArgs()));

		// If any candidates left take specs -- leave as a TODO
		switch (mutMaxArrSize(candidates)) {
			case 0:
				return SpecResult(SpecDiag(Diag.SpecImplNotFound(sigDecl, sigType, toArray(ctx.alloc, trace))));
			case 1:
				return getCalledFromCandidate(ctx, only(candidates), trace);
			default:
				return SpecResult(SpecDiag(
					Diag.SpecImplFoundMultiple(sigDecl.name, candidatesForDiag(ctx.alloc, candidates))));
		}
	});

Opt!SpecDiag checkBuiltinSpec(
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	SpecDeclBody.Builtin.Kind kind,
	Type typeArg,
) =>
	isPurityAlwaysCompatibleConsideringSpecs(ctx.funsInScope.outermostFunSpecs, typeArg, purityOfBuiltinSpec(kind))
		? none!SpecDiag
		: some(SpecDiag(Diag.SpecBuiltinNotSatisfied(kind, typeArg, called)));

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

Opt!SpecDiag checkSpecImpls(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	in Type[] calledTypeArgs,
	scope ref SpecTrace trace,
) =>
	first!(SpecDiag, immutable SpecInst*)(called.specs, (SpecInst* specInst) @safe =>
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		checkSpecImpl(res, ctx, called, trace, *instantiateSpecInst(
			ctx.alloc, ctx.programState, specInst,
			TypeParamsAndArgs(called.typeParams, calledTypeArgs), noDelaySpecInsts)));

Opt!SpecDiag checkSpecImpl(
	ref SpecImpls res,
	ref CheckSpecsCtx ctx,
	FunDecl* called,
	scope ref SpecTrace trace,
	in SpecInst specInstInstantiated) {
	Type[] typeArgs = typeArgs(specInstInstantiated);
	Opt!SpecDiag diag = first!(SpecDiag, immutable SpecInst*)(specInstInstantiated.parents, (SpecInst* parent) =>
		checkSpecImpl(res, ctx, called, trace, *parent));
	return has(diag) ? diag : specInstInstantiated.decl.body_.match!(Opt!SpecDiag)(
		(SpecDeclBody.Builtin b) =>
			checkBuiltinSpec(ctx, called, b.kind, only(typeArgs)),
		(SpecDeclSig[] sigDecls) {
			push(trace, FunDeclAndTypeArgs(called, typeArgs));
			Opt!SpecDiag res = zipFirst!(SpecDiag, SpecDeclSig, ReturnAndParamTypes)(
				sigDecls, specInstInstantiated.sigTypes, (SpecDeclSig* sigDecl, in ReturnAndParamTypes sigType) =>
					findSpecSigImplementation(ctx, sigDecl, sigType, trace).match!(Opt!SpecDiag)(
						(Called x) {
							push(res, x);
							return none!SpecDiag;
						},
						(SpecDiag x) =>
							some(x)));
			if (!has(res)) mustPop(trace);
			return res;
		});
}
