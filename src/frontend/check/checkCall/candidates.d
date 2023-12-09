module frontend.check.checkCall.candidates;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : eachImportAndReExport, ImportAndReExportModules;
import frontend.check.exprCtx : ExprCtx;
import frontend.check.inferringType :
	matchTypesNoDiagnostic,
	nonInferringTypeContext,
	SingleInferringType,
	tryGetDeeplyInstantiatedType,
	tryGetInferred,
	TypeAndContext,
	TypeContext;
import frontend.check.instantiate : InstantiateCtx, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.check.maps : FunsMap;
import frontend.lang : maxTypeParams;
import model.model :
	arity,
	arityMatches,
	CalledDecl,
	CalledSpecSig,
	decl,
	Destructure,
	FunDecl,
	NameReferents,
	Params,
	paramTypeAt,
	ReturnAndParamTypes,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructInst,
	typeArgs,
	Type,
	TypeParam,
	TypeParamIndex,
	TypeParams;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : everyWithIndex, map;
import util.memory : overwriteMemory;
import util.col.mutMaxArr :
	copyToFrom,
	fillMutMaxArr,
	filterUnordered,
	filterUnorderedButDontRemoveAll,
	initializeMutMaxArr,
	mapTo,
	mustPopAndDrop,
	MutMaxArr,
	mutMaxArr,
	pushUninitialized,
	tempAsArr;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.sym : Sym;
import util.util : typeAs, unreachable;

// Max number of candidates with same return type
size_t maxCandidates() => 64;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);

CalledDecl[] candidatesForDiag(ref Alloc alloc, in Candidates candidates) =>
	map(alloc, tempAsArr(candidates), (ref const Candidate c) => c.called);

CalledDecl[] getAllCandidatesAsCalledDecls(ref ExprCtx ctx, Sym funName) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(funsInScope(ctx), funName, (CalledDecl called) {
		add(ctx.alloc, res, called);
	});
	return finishArr(ctx.alloc, res);
}

struct Candidate {
	immutable CalledDecl called;
	// Note: this is always empty if calling a CalledSpecSig
	MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs;
}

@trusted inout(TypeContext) typeContextForCandidate(TypeParams outerContext, ref inout Candidate a) {
	// 'match' can't return 'inout' we must do it this way
	if (a.called.isA!(FunDecl*))
		return inout TypeContext(
			cast(inout) someMut!(SingleInferringType[])(cast(SingleInferringType[]) tempAsArr(a.typeArgs)));
	else {
		assert(a.called.isA!CalledSpecSig);
		// Spec is instantiated using the caller's types
		return cast(inout) nonInferringTypeContext();
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
	Sym funName,
	size_t actualArity,
	// Filter candidates early to avoid a large array
	in bool delegate(ref Candidate) @safe @nogc pure nothrow cbFilterCandidate,
	in T delegate(ref Candidates) @safe @nogc pure nothrow cb,
) {
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate);
	eachFunInScope(funs, funName, (CalledDecl called) @trusted {
		if (arityMatches(arity(called), actualArity)) {
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
	Sym funName,
	size_t actualArity,
	in void delegate(ref Candidate) @safe @nogc pure nothrow cb,
) {
	eachFunInScope(funs, funName, (CalledDecl called) @trusted {
		if (arityMatches(arity(called), actualArity)) {
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

void eachFunInScope(in FunsInScope a, Sym funName, in void delegate(CalledDecl) @safe @nogc pure nothrow cb) {
	foreach (SpecInst* specInst; a.outermostFunSpecs)
		eachFunInScopeForSpec(specInst, funName, cb);

	Opt!(immutable FunDecl*[]) funs = a.funsMap[funName];
	if (has(funs))
		foreach (FunDecl* f; force(funs))
			cb(CalledDecl(f));

	eachImportAndReExport(a.importsAndReExports, funName, (in NameReferents x) {
		foreach (FunDecl* f; x.funs)
			cb(CalledDecl(f));
	});
}

bool testCandidateForSpecSig(
	ref InstantiateCtx ctx,
	TypeParams outerContext,
	ref Candidate specCandidate,
	in ReturnAndParamTypes returnAndParamTypes,
	const TypeContext callTypeContext,
) {
	bool res = matchTypesNoDiagnostic(
		ctx,
		outerContext,
		TypeAndContext(specCandidate.called.returnType, typeContextForCandidate(outerContext, specCandidate)),
		const TypeAndContext(returnAndParamTypes.returnType, callTypeContext));
	return res && everyWithIndex!Type(returnAndParamTypes.paramTypes, (size_t argIdx, ref Type paramType) =>
		testCandidateParamType(ctx, outerContext, specCandidate, argIdx, const TypeAndContext(paramType, callTypeContext)));
}

// Also does type inference on the candidate
bool testCandidateParamType(
	ref InstantiateCtx ctx,
	TypeParams outerContext,
	ref Candidate candidate,
	size_t argIdx,
	const TypeAndContext actualArgType,
) {
	//TODO:INLINE-----------------------------------------------------------------------------------------------------------------
	TypeAndContext a = getCandidateExpectedParameterType(ctx, outerContext, candidate, argIdx);
	return matchTypesNoDiagnostic(
		ctx,
		outerContext,
		a,
		actualArgType);
}

@trusted inout(TypeAndContext) getCandidateExpectedParameterType(ref InstantiateCtx ctx, TypeParams outerContext, ref inout Candidate candidate, size_t argIndex) {
	Type declType = paramTypeAt(candidate.called, argIndex);
	Opt!Type instantiated = tryGetDeeplyInstantiatedType(ctx, inout TypeAndContext(declType, typeContextForCandidate(outerContext, candidate)));
	return has(instantiated)
		? inout TypeAndContext(force(instantiated), cast(inout) nonInferringTypeContext())
		: inout TypeAndContext(declType, typeContextForCandidate(outerContext, candidate));
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
	Sym funName,
	in void delegate(CalledDecl) @safe @nogc pure nothrow cb,
) {
	foreach (SpecInst* parent; specInst.parents)
		eachFunInScopeForSpec(parent, funName, cb);
	decl(*specInst).body_.match!void(
		(SpecDeclBody.Builtin) {},
		(SpecDeclSig[] sigs) {
			foreach (size_t sigIndex, ref SpecDeclSig sig; sigs) {
				if (sig.name == funName)
					cb(CalledDecl(CalledSpecSig(specInst, sigIndex)));
			}
		});
}
