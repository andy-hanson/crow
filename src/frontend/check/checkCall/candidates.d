module frontend.check.checkCall.candidates;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : eachImportAndReExport;
import frontend.parse.ast : TypeAst;
import frontend.check.inferringType :
	ExprCtx,
	InferringTypeArgs,
	matchTypesNoDiagnostic,
	SingleInferringType,
	tryGetInferred,
	tryGetTypeArgFromInferringTypeArgs,
	typeFromAst2;
import frontend.check.instantiate : instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst : tryGetMatchingTypeArgs;
import frontend.lang : maxTypeParams;
import frontend.programState : ProgramState;
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
	TypeParam;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : everyWithIndex, map, zipPtrFirst;
import util.memory : overwriteMemory;
import util.col.mutMaxArr :
	copyToFrom,
	fillMutMaxArr,
	filterUnordered,
	filterUnorderedButDontRemoveAll,
	initializeMutMaxArr,
	mapTo,
	MutMaxArr,
	mutMaxArr,
	pushUninitialized,
	tempAsArr;
import util.opt : force, has, MutOpt, none, Opt, some;
import util.sym : Sym;

size_t maxCandidates() => 256;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);

CalledDecl[] candidatesForDiag(ref Alloc alloc, in Candidates candidates) =>
	map(alloc, tempAsArr(candidates), (ref const Candidate c) => c.called);

CalledDecl[] getAllCandidatesAsCalledDecls(ref ExprCtx ctx, Sym funName) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(ctx, funName, (CalledDecl called) {
		add(ctx.alloc, res, called);
	});
	return finishArr(ctx.alloc, res);
}

struct Candidate {
	immutable CalledDecl called;
	// Note: this is always empty if calling a CalledSpecSig
	MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs;
}

inout(InferringTypeArgs) inferringTypeArgs(return scope ref inout Candidate a) =>
	inout InferringTypeArgs(a.called.typeParams, tempAsArr(a.typeArgs));

private void initializeCandidate(ref Candidate a, CalledDecl called) {
	overwriteMemory(&a.called, called);
	initializeMutMaxArr(a.typeArgs);
}
// TODO: 'b' isn't really const since we're getting mutable 'typeArgs' from it
private void overwriteCandidate(ref Candidate a, ref const Candidate b) {
	overwriteMemory(&a.called, b.called);
	copyToFrom(a.typeArgs, b.typeArgs);
}

T withCandidates(T)(
	ref ExprCtx ctx,
	Sym funName,
	in Opt!(TypeAst*) explicitTypeArg,
	size_t actualArity,
	in T delegate(ref Candidates) @safe @nogc pure nothrow cb,
) {
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate);
	getInitialCandidates(ctx, candidates, funName, explicitTypeArg, actualArity);
	return cb(candidates);
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

void eachFunInScope(ref ExprCtx ctx, Sym funName, in void delegate(CalledDecl) @safe @nogc pure nothrow cb) {
	size_t totalIndex = 0;
	foreach (SpecInst* specInst; ctx.outermostFunSpecs)
		eachFunInScopeForSpec(specInst, totalIndex, funName, cb);

	foreach (FunDecl* f; ctx.funsDict[funName])
		cb(CalledDecl(f));

	eachImportAndReExport(ctx.checkCtx, funName, (in NameReferents x) {
		foreach (FunDecl* f; x.funs)
			cb(CalledDecl(f));
	});
}

bool testCandidateForSpecSig(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref Candidate specCandidate,
	in ReturnAndParamTypes returnAndParamTypes,
	in InferringTypeArgs callInferringTypeArgs,
) {
	bool res = matchTypesNoDiagnostic(
		alloc, programState,
		specCandidate.called.returnType, inferringTypeArgs(specCandidate),
		returnAndParamTypes.returnType, callInferringTypeArgs);
	return res && everyWithIndex!Type(returnAndParamTypes.paramTypes, (size_t argIdx, in Type paramType) =>
		testCandidateParamType(alloc, programState, specCandidate, paramType, argIdx, callInferringTypeArgs));
}

// Also does type inference on the candidate
bool testCandidateParamType(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref Candidate candidate,
	Type actualArgType,
	size_t argIdx,
	in InferringTypeArgs callInferringTypeArgs,
) =>
	matchTypesNoDiagnostic(
		alloc, programState,
		getCandidateExpectedParameterType(alloc, programState, candidate, argIdx),
		inferringTypeArgs(candidate),
		actualArgType,
		callInferringTypeArgs);

Type getCandidateExpectedParameterType(
	ref Alloc alloc,
	ref ProgramState programState,
	in Candidate candidate,
	size_t argIndex,
) =>
	getCandidateExpectedParameterTypeRecur(
		alloc,
		programState,
		candidate,
		paramTypeAt(candidate.called, argIndex));

private Type getCandidateExpectedParameterTypeRecur(
	ref Alloc alloc,
	ref ProgramState programState,
	in Candidate candidate,
	Type candidateParamType,
) =>
	candidateParamType.matchWithPointers!Type(
		(Type.Bogus _) =>
			Type(Type.Bogus()),
		(TypeParam* p) {
			const InferringTypeArgs ita = inferringTypeArgs(candidate);
			MutOpt!(const(SingleInferringType)*) sit = tryGetTypeArgFromInferringTypeArgs(ita, p);
			Opt!Type inferred = has(sit) ? tryGetInferred(*force(sit)) : none!Type;
			return has(inferred) ? force(inferred) : Type(p);
		},
		(StructInst* i) {
			scope TypeArgsArray outTypeArgs = typeArgsArray();
			mapTo!(maxTypeParams, Type, Type)(outTypeArgs, typeArgs(*i), (ref Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return Type(instantiateStructNeverDelay(alloc, programState, decl(*i), tempAsArr(outTypeArgs)));
		});

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

private void getInitialCandidates(
	ref ExprCtx ctx,
	scope ref Candidates candidates,
	Sym funName,
	in Opt!(TypeAst*) explicitTypeArg,
	size_t actualArity,
) {
	eachFunInScope(ctx, funName, (CalledDecl called) {
		if (arityMatches(arity(called), actualArity)) {
			size_t nTypeParams = called.typeParams.length;
			TypeAst[] args = tryGetMatchingTypeArgs(nTypeParams, explicitTypeArg);
			if (args.length == nTypeParams || args.length == 0) {
				pushCandidate(ctx, candidates, called, args);
			}
		}
	});
}

private @trusted void pushCandidate(
	ref ExprCtx ctx,
	scope ref Candidates candidates,
	CalledDecl called,
	scope TypeAst[] typeArgs,
) {
	Candidate* candidate = pushUninitialized(candidates);
	initializeCandidate(*candidate, called);
	fillMutMaxArr(candidate.typeArgs, called.typeParams.length, (size_t i) =>
		SingleInferringType(empty(typeArgs) ? none!Type : some(typeFromAst2(ctx, typeArgs[i]))));
}

private void eachFunInScopeForSpec(
	SpecInst* specInst,
	ref size_t totalIndex,
	Sym funName,
	in void delegate(CalledDecl) @safe @nogc pure nothrow cb,
) {
	foreach (SpecInst* parent; specInst.parents)
		eachFunInScopeForSpec(parent, totalIndex, funName, cb);
	decl(*specInst).body_.match!void(
		(SpecDeclBody.Builtin) {},
		(SpecDeclSig[] sigs) {
			zipPtrFirst(sigs, specInst.sigTypes, (SpecDeclSig* sig, ref ReturnAndParamTypes signatureTypes) {
				if (sig.name == funName)
					cb(CalledDecl(CalledSpecSig(specInst, signatureTypes, sig, totalIndex)));
				totalIndex += 1;
			});
		});
}
