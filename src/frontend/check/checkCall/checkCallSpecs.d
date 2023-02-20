module frontend.check.checkCall.checkCallSpecs;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate, Candidates, candidatesForDiag, filterCandidates, testCandidateForSpecSig, withCandidates;
import frontend.check.inferringType :
	addDiag2, ExprCtx, InferringTypeArgs, programState, SingleInferringType, tryGetInferred;
import frontend.check.instantiate :
	instantiateFun,
	instantiateSpecInst,
	noDelaySpecInsts,
	TypeArgsArray,
	typeArgsArray,
	TypeParamsAndArgs;
import frontend.lang : maxSpecDepth, maxSpecImpls;
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
import util.col.arr : only;
import util.col.arrUtil : every, exists, zipEveryPtrFirst;
import util.col.mutMaxArr : isFull, mustPop, MutMaxArr, mutMaxArr, mutMaxArrSize, only, push, tempAsArr, toArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndRange;

Opt!Called checkCallSpecs(
	ref ExprCtx ctx,
	FileAndRange range,
	ref const Candidate candidate,
) {
	SpecTrace trace = mutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);
	return getCalledFromCandidate(ctx, range, candidate, trace);
}

bool isPurityAlwaysCompatibleConsideringSpecs(ref ExprCtx ctx, Type type, Purity expected) {
	PurityRange typePurity = purityRange(type);
	return isPurityAlwaysCompatible(expected, typePurity) ||
		exists!(SpecInst*)(ctx.outermostFunSpecs, (in SpecInst* inst) =>
			specProvidesPurity(inst, type, expected)) ||
		(type.isA!(StructInst*) &&
			isPurityCompatible(expected, typePurity.bestCase) &&
			every!Type(typeArgs(*type.as!(StructInst*)), (in Type typeArg) =>
				isPurityAlwaysCompatibleConsideringSpecs(ctx, typeArg, expected)));
}

private:

alias SpecImpls = MutMaxArr!(maxSpecImpls, Called);
alias SpecTrace = MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);

Opt!Called getCalledFromCandidate(
	ref ExprCtx ctx,
	FileAndRange range,
	ref const Candidate candidate,
	ref SpecTrace trace,
) {
	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; tempAsArr(candidate.typeArgs)) {
		Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else {
			addDiag2(ctx, range, Diag(Diag.CantInferTypeArguments(candidate.called.as!(FunDecl*))));
			return none!Called;
		}
	}
	return candidate.called.matchWithPointers!(Opt!Called)(
		(FunDecl* f) {
			if (isFull(trace)) {
				addDiag2(ctx, range, Diag(Diag.SpecImplTooDeep(toArray(ctx.alloc, trace))));
				return none!Called;
			} else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, Called);
				return checkSpecImpls(specImpls, ctx, range, f, tempAsArr(candidateTypeArgs), trace)
					? some(Called(
						instantiateFun(
							ctx.alloc,
							ctx.programState,
							f,
							tempAsArr(candidateTypeArgs),
							tempAsArr(specImpls))))
					: none!Called;
			}
		},
		(CalledSpecSig s) =>
			some(Called(allocate(ctx.alloc, s))));
}

Opt!Called findSpecSigImplementation(
	ref ExprCtx ctx,
	FileAndRange range,
	SpecDeclSig* sigDecl,
	in ReturnAndParamTypes sigType,
	ref SpecTrace trace,
) =>
	withCandidates(ctx, sigDecl.name, sigType.paramTypes.length, (ref Candidates candidates) {
		filterCandidates(candidates, (scope ref Candidate candidate) =>
			testCandidateForSpecSig(ctx.alloc, ctx.programState, candidate, sigType, InferringTypeArgs()));

		// If any candidates left take specs -- leave as a TODO
		switch (mutMaxArrSize(candidates)) {
			case 0:
				// TODO: use initial candidates in the error message
				addDiag2(ctx, range, Diag(Diag.SpecImplNotFound(sigDecl, sigType, toArray(ctx.alloc, trace))));
				return none!Called;
			case 1:
				return getCalledFromCandidate(ctx, range, only(candidates), trace);
			default:
				addDiag2(ctx, range, Diag(
					Diag.SpecImplFoundMultiple(sigDecl.name, candidatesForDiag(ctx.alloc, candidates))));
				return none!Called;
		}
	});

bool checkBuiltinSpec(
	ref ExprCtx ctx,
	FunDecl* called,
	FileAndRange range,
	SpecDeclBody.Builtin.Kind kind,
	Type typeArg,
) {
	bool typeIsGood = isPurityAlwaysCompatibleConsideringSpecs(ctx, typeArg, purityOfBuiltinSpec(kind));
	if (!typeIsGood)
		addDiag2(ctx, range, Diag(Diag.SpecBuiltinNotSatisfied(kind, typeArg, called)));
	return typeIsGood;
}

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

// On failure, returns false
bool checkSpecImpls(
	ref SpecImpls res,
	ref ExprCtx ctx,
	FileAndRange range,
	FunDecl* called,
	Type[] calledTypeArgs,
	ref SpecTrace trace,
) {
	foreach (SpecInst* specInst; called.specs) {
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		SpecInst* specInstInstantiated = instantiateSpecInst(
			ctx.alloc, ctx.programState, specInst,
			TypeParamsAndArgs(called.typeParams, calledTypeArgs), noDelaySpecInsts);
		if (!checkSpecImpl(res, ctx, range, called, trace, *specInstInstantiated))
			return false;
	}
	return true;
}

bool checkSpecImpl(
	ref SpecImpls res,
	ref ExprCtx ctx,
	FileAndRange range,
	FunDecl* called,
	ref SpecTrace trace,
	in SpecInst specInstInstantiated) {
	foreach (SpecInst* parent; specInstInstantiated.parents)
		if (!checkSpecImpl(res, ctx, range, called, trace, *parent))
			return false;
	Type[] typeArgs = typeArgs(specInstInstantiated);
	return specInstInstantiated.decl.body_.match!bool(
		(SpecDeclBody.Builtin b) =>
			checkBuiltinSpec(ctx, called, range, b.kind, only(typeArgs)),
		(SpecDeclSig[] sigDecls) {
			push(trace, FunDeclAndTypeArgs(called, typeArgs));
			bool res = zipEveryPtrFirst!(SpecDeclSig, ReturnAndParamTypes)(
				sigDecls, specInstInstantiated.sigTypes, (SpecDeclSig* sigDecl, in ReturnAndParamTypes sigType) {
					Opt!Called impl = findSpecSigImplementation(ctx, range, sigDecl, sigType, trace);
					if (!has(impl))
						return false;
					push(res, force(impl));
					return true;
				});
			if (res) mustPop(trace);
			return true;
		});
}
