module frontend.check.checkCall.candidates;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : eachImportAndReExport, ImportAndReExportModules;
import frontend.check.exprCtx : ExprCtx;
import frontend.check.inferringType :
	matchTypes,
	nonInferring,
	SingleInferringType,
	tryGetNonInferringType,
	TypeAndContext,
	TypeContext;
import frontend.check.instantiate : InstantiateCtx;
import frontend.check.maps : FunsMap;
import frontend.lang : maxTypeParams;
import model.model :
	arityMatches,
	Called,
	CalledDecl,
	CalledSpecSig,
	Destructure,
	ExportVisibility,
	FunDecl,
	importCanSee,
	NameReferents,
	Params,
	paramTypeAt,
	ReturnAndParamTypes,
	SpecDeclSig,
	SpecInst,
	Type;
import util.alloc.alloc : Alloc;
import util.col.array : everyWithIndex, map, makeArray, small;
import util.col.arrayBuilder : buildArray, Builder;
import util.conv : safeToUshort;
import util.memory : allocate, overwriteMemory;
import util.col.mutMaxArr :
	asTemporaryArray,
	copyToFrom,
	fillMutMaxArr,
	filterUnordered,
	filterUnorderedButDontRemoveAll,
	initializeMutMaxArr,
	mustPopAndDrop,
	MutMaxArr,
	mutMaxArr,
	pushUninitialized;
import util.opt : force, has, Opt, optOrDefault;
import util.symbol : Symbol;

// Max number of candidates with same return type
size_t maxCandidates() => 128;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);

CalledDecl[] candidatesForDiag(ref Alloc alloc, in Candidates candidates) =>
	map(alloc, asTemporaryArray(candidates), (ref const Candidate c) => c.called);

CalledDecl[] getAllCandidatesAsCalledDecls(ref ExprCtx ctx, Symbol funName) =>
	buildArray!CalledDecl(ctx.alloc, (scope ref Builder!CalledDecl res) {
		eachFunInScope(funsInScope(ctx), funName, (CalledDecl called) {
			res ~= called;
		});
	});

struct Candidate {
	immutable CalledDecl called;
	// Note: this is always empty if calling a CalledSpecSig
	MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs;
}

inout(TypeContext) typeContextForCandidate(ref inout Candidate a) {
	// 'match' can't return 'inout' we must do it this way
	if (a.called.isA!(FunDecl*))
		return inout TypeContext(small!SingleInferringType(asTemporaryArray(a.typeArgs)));
	else {
		assert(a.called.isA!CalledSpecSig);
		// Spec is instantiated using the caller's types
		return TypeContext.nonInferring;
	}
}

private void initializeCandidate(ref Candidate a, CalledDecl called) {
	overwriteMemory(&a.called, called);
	initializeMutMaxArr(a.typeArgs);
	fillMutMaxArr(a.typeArgs, called.typeParams.length, (size_t i) => SingleInferringType());
}
// TODO: 'b' isn't really const since we're getting mutable 'typeArgs' from it
private void overwriteCandidate(ref Candidate a, ref const Candidate b) {
	overwriteMemory(&a.called, b.called);
	copyToFrom(a.typeArgs, b.typeArgs);
}

T withCandidates(T)(
	in FunsInScope funs,
	Symbol funName,
	size_t actualArity,
	// Filter candidates early to avoid a large array
	in bool delegate(ref Candidate) @safe @nogc pure nothrow cbFilterCandidate,
	in T delegate(ref Candidates) @safe @nogc pure nothrow cb,
) {
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate);
	eachFunInScope(funs, funName, (CalledDecl called) @trusted {
		if (arityMatches(called.arity, actualArity)) {
			Candidate* candidate = pushUninitialized(candidates);
			initializeCandidate(*candidate, called);
			if (!cbFilterCandidate(*candidate))
				mustPopAndDrop(candidates);
		}
	});
	return cb(candidates);
}

void eachCandidate(
	in FunsInScope funs,
	Symbol funName,
	size_t actualArity,
	in void delegate(ref Candidate) @safe @nogc pure nothrow cb,
) {
	eachFunInScope(funs, funName, (CalledDecl called) @trusted {
		if (arityMatches(called.arity, actualArity)) {
			Candidate candidate = void;
			initializeCandidate(candidate, called);
			cb(candidate);
		}
	});
}

void filterCandidates(
	scope ref Candidates candidates,
	in bool delegate(ref Candidate) @safe @nogc pure nothrow pred,
) {
	filterUnordered!(maxCandidates, Candidate)(candidates, pred, (ref Candidate a, ref const Candidate b) =>
		overwriteCandidate(a, b));
}

void filterCandidatesButDontRemoveAll(
	scope ref Candidates candidates,
	in bool delegate(ref Candidate) @safe @nogc pure nothrow pred,
) {
	filterUnorderedButDontRemoveAll!(maxCandidates, Candidate)(
		candidates, pred, (ref Candidate a, ref const Candidate b) =>
			overwriteCandidate(a, b));
}

immutable struct FunsInScope {
	SpecInst*[] outermostFunSpecs;
	FunsMap funsMap;
	ImportAndReExportModules importsAndReExports;
}
FunsInScope funsInScope(ref const ExprCtx ctx) {
	return FunsInScope(ctx.outermostFunSpecs, ctx.funsMap, ctx.checkCtx.importsAndReExports);
}

void eachFunInScope(in FunsInScope a, Symbol funName, in void delegate(CalledDecl) @safe @nogc pure nothrow cb) {
	foreach (SpecInst* specInst; a.outermostFunSpecs)
		eachFunInScopeForSpec(specInst, funName, cb);

	Opt!(immutable FunDecl*[]) funs = a.funsMap[funName];
	if (has(funs))
		foreach (FunDecl* f; force(funs))
			cb(CalledDecl(f));

	eachImportAndReExport(a.importsAndReExports, funName, (ExportVisibility visibility, in NameReferents x) {
		foreach (FunDecl* f; x.funs)
			if (importCanSee(visibility, f.visibility))
				cb(CalledDecl(f));
	});
}

bool testCandidateForSpecSig(
	ref InstantiateCtx ctx,
	ref Candidate specCandidate,
	in ReturnAndParamTypes returnAndParamTypes,
	const TypeContext callTypeContext,
) {
	bool res = matchTypes(
		ctx,
		TypeAndContext(specCandidate.called.returnType, typeContextForCandidate(specCandidate)),
		const TypeAndContext(returnAndParamTypes.returnType, callTypeContext));
	return res && everyWithIndex!Type(returnAndParamTypes.paramTypes, (size_t argIdx, ref Type paramType) =>
		testCandidateParamType(ctx, specCandidate, argIdx, const TypeAndContext(paramType, callTypeContext)));
}

// Also does type inference on the candidate
bool testCandidateParamType(
	ref InstantiateCtx ctx,
	ref Candidate candidate,
	size_t argIdx,
	const TypeAndContext actualArgType,
) =>
	matchTypes(ctx, getCandidateExpectedParameterType(ctx, candidate, argIdx), actualArgType);

@trusted inout(TypeAndContext) getCandidateExpectedParameterType(
	ref InstantiateCtx ctx,
	ref inout Candidate candidate,
	size_t argIndex,
) {
	Type declType = paramTypeAt(candidate.called, argIndex);
	Opt!Type instantiated = tryGetNonInferringType(
		ctx, inout TypeAndContext(declType, typeContextForCandidate(candidate)));
	return has(instantiated)
		? cast(inout) nonInferring(force(instantiated))
		: inout TypeAndContext(declType, typeContextForCandidate(candidate));
}

Called candidateBogusCalled(ref Alloc alloc, ref InstantiateCtx instantiateCtx, ref const Candidate candidate) {
	Type returnType = getCandidateTypeOrBogus(instantiateCtx, candidate, candidate.called.returnType);
	Type[] paramTypes = makeArray(alloc, candidate.called.arity.countParamDecls, (size_t i) =>
		getCandidateTypeOrBogus(instantiateCtx, candidate, paramTypeAt(candidate.called, i)));
	return Called(allocate(alloc, Called.Bogus(candidate.called, returnType, paramTypes)));
}

private Type getCandidateTypeOrBogus(ref InstantiateCtx ctx, ref const Candidate candidate, Type declaredType) {
	Opt!Type res = tryGetNonInferringType(ctx, TypeAndContext(declaredType, typeContextForCandidate(candidate)));
	return optOrDefault!Type(res, () => Type(Type.Bogus()));
}

private Type paramTypeAt(ref CalledDecl called, size_t argIndex) =>
	called.match!Type(
		(ref FunDecl f) =>
			paramTypeAt(f.params, argIndex),
		(CalledSpecSig s) =>
			s.paramTypes[argIndex]);

private Type paramTypeAt(in Params params, size_t argIndex) =>
	params.matchIn!Type(
		(in Destructure[] x) =>
			x[argIndex].type,
		(in Params.Varargs x) =>
			x.elementType);

private void eachFunInScopeForSpec(
	SpecInst* specInst,
	Symbol funName,
	in void delegate(CalledDecl) @safe @nogc pure nothrow cb,
) {
	foreach (SpecInst* parent; specInst.parents)
		eachFunInScopeForSpec(parent, funName, cb);
	foreach (size_t sigIndex, ref SpecDeclSig sig; specInst.decl.sigs) {
		if (sig.name == funName)
			cb(CalledDecl(CalledSpecSig(specInst, safeToUshort(sigIndex))));
	}
}
