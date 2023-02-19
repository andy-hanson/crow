module frontend.check.checkCall.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate,
	Candidates,
	candidatesForDiag,
	filterCandidates,
	filterCandidatesButDontRemoveAll,
	getAllCandidatesAsCalledDecls,
	getCandidateExpectedParameterType,
	inferringTypeArgs,
	maxCandidates,
	testCandidateForSpecSig,
	testCandidateParamType,
	withCandidates;
import frontend.check.checkCall.checkCalled : ArgsKind, checkCalled;
import frontend.check.checkCall.checkCallSpecs : checkCallSpecs;
import frontend.check.checkExpr : checkExpr, typeFromDestructure;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	Expected,
	ExprCtx,
	FunOrLambdaInfo,
	inferred,
	InferringTypeArgs,
	inferTypeArgsFrom,
	inferTypeArgsFromLambdaParameterType,
	isInLambda,
	LocalNode,
	LocalsInfo,
	matchExpectedVsReturnTypeNoDiagnostic,
	programState,
	SingleInferringType,
	tryGetInferred,
	TypeAndInferring;
import frontend.check.typeFromAst : tryUnpackTupleType;
import frontend.lang : maxTypeParams;
import frontend.parse.ast : CallAst, ExprAst, LambdaAst, rangeOfNameAndRange, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	arity,
	body_,
	Called,
	CalledDecl,
	CalledSpecSig,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	ReturnAndParamTypes,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	Type;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : every, exists, fillArrOrFail, zipEvery;
import util.col.mutMaxArr : exists, isEmpty, MutMaxArr, mutMaxArr, mutMaxArrSize, only, push, size, tempAsArr;
import util.opt : force, has, none, noneMut, Opt, some, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : Sym;

Expr checkCall(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in CallAst ast, ref Expected expected) =>
	checkCallCommon(
		ctx, locals, range,
		// Show diags at the function name and not at the whole call ast
		FileAndRange(range.fileIndex, rangeOfNameAndRange(ast.funName, ctx.allSymbols)),
		ast.funName.name, ast.typeArg, ast.args, expected);

Expr checkCallSpecial(size_t n)(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	Sym funName,
	in ExprAst[n] args,
	ref Expected expected,
) =>
	checkCallCommon(ctx, locals, range, range, funName, none!(TypeAst*), castNonScope_ref(args), expected);

Expr checkCallSpecial(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	Sym funName,
	in ExprAst[] args,
	ref Expected expected,
) =>
	checkCallCommon(ctx, locals, range, range, funName, none!(TypeAst*), castNonScope_ref(args), expected);

Expr checkCallSpecialNoLocals(
	ref ExprCtx ctx,
	FileAndRange range,
	Sym funName,
	in ExprAst[] args,
	ref Expected expected,
) {
	FunOrLambdaInfo emptyFunInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), none!(ExprKind.Lambda*));
	LocalsInfo emptyLocals = LocalsInfo(ptrTrustMe(emptyFunInfo), noneMut!(LocalNode*));
	return checkCallSpecial(ctx, emptyLocals, range, funName, args, expected);
}

private Expr checkCallCommon(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	FileAndRange diagRange,
	Sym funName,
	in Opt!(TypeAst*) typeArg,
	in ExprAst[] args,
	ref Expected expected,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.alloc, ctx.perf, PerfMeasure.checkCall);
	Expr res = withCandidates!Expr(
		ctx, funName, typeArg, args.length,
		(ref Candidates candidates) =>
			checkCallInner(
				ctx, locals, range, diagRange, funName, args, typeArg, perfMeasurer, candidates, expected));
	endMeasure(ctx.alloc, ctx.perf, perfMeasurer);
	return res;
}

private Expr checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	FileAndRange diagRange,
	Sym funName,
	in ExprAst[] argAsts,
	in Opt!(TypeAst*) explicitTypeArg,
	ref PerfMeasurer perfMeasurer,
	ref Candidates candidates,
	ref Expected expected,
) {
	size_t arity = argAsts.length;

	filterCandidates(candidates, (ref Candidate candidate) =>
		matchExpectedVsReturnTypeNoDiagnostic(
			ctx.alloc, ctx.programState, expected, candidate.called.returnType, inferringTypeArgs(candidate)));

	// Apply explicitly typed arguments first
	foreach (size_t argIdx, ExprAst arg; argAsts)
		if (inferCandidateTypeArgsFromExplicitlyTypedArgument(ctx, candidates, argIdx, arg) == ContinueOrAbort.abort)
			return bogus(expected, range);

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	Opt!(Expr[]) args = fillArrOrFail!Expr(ctx.alloc, arity, (size_t argIdx) {
		if (isEmpty(candidates))
			return none!Expr;

		filterCandidatesButDontRemoveAll(candidates, (scope ref Candidate x) =>
			inferCandidateTypeArgsFromSpecs(ctx, x));

		ParamExpected paramExpected = mutMaxArr!(maxCandidates, TypeAndInferring);
		getParamExpected(ctx.alloc, ctx.programState, paramExpected, candidates, argIdx);
		Expected expected = Expected(tempAsArr(castNonScope_ref(paramExpected)));

		pauseMeasure(ctx.alloc, ctx.perf, perfMeasurer);
		Expr arg = checkExpr(ctx, locals, argAsts[argIdx], expected);
		resumeMeasure(ctx.alloc, ctx.perf, perfMeasurer);

		Type actualArgType = inferred(expected);
		// If it failed to check, don't continue, just stop there.
		if (actualArgType.isA!(Type.Bogus)) {
			someArgIsBogus = true;
			return none!Expr;
		}
		add(ctx.alloc, actualArgTypes, actualArgType);
		filterCandidates(candidates, (scope ref Candidate candidate) =>
			testCandidateParamType(ctx.alloc, ctx.programState, candidate, actualArgType, argIdx, InferringTypeArgs()));
		return some(arg);
	});

	if (someArgIsBogus)
		return bogus(expected, range);

	filterCandidatesButDontRemoveAll(candidates, (scope ref Candidate x) =>
		inferCandidateTypeArgsFromSpecs(ctx, x));

	if (mutMaxArrSize(candidates) != 1 &&
		exists!(maxCandidates, Candidate)(candidates, (in Candidate it) => candidateIsPreferred(it))) {
		filterCandidates(candidates, (ref Candidate it) => candidateIsPreferred(it));
	}

	if (!has(args) || mutMaxArrSize(candidates) != 1) {
		if (isEmpty(candidates)) {
			CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(ctx, funName);
			addDiag2(ctx, diagRange, Diag(Diag.CallNoMatch(
				funName,
				tryGetInferred(expected),
				getNTypeArgs(explicitTypeArg),
				arity,
				finishArr(ctx.alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(ctx, diagRange, Diag(Diag.CallMultipleMatches(funName, candidatesForDiag(ctx.alloc, candidates))));
		return bogus(expected, range);
	} else
		return checkCallAfterChoosingOverload(ctx, isInLambda(locals), only(candidates), range, force(args), expected);
}

private size_t getNTypeArgs(Opt!(TypeAst*) explicitTypeArg) {
	if (has(explicitTypeArg)) {
		Opt!(TypeAst[]) unpacked = tryUnpackTupleType(*force(explicitTypeArg));
		return has(unpacked) ? force(unpacked).length : 1;
	} else
		return 0;
}

Expr checkCallIdentifier(
	ref ExprCtx ctx,
	FileAndRange range,
	Sym name,
	ref Expected expected,
) =>
	checkCallSpecialNoLocals(ctx, range, name, [], expected);

private:

alias ParamExpected = MutMaxArr!(maxCandidates, TypeAndInferring);

bool candidateIsPreferred(in Candidate a) =>
	a.called.matchIn!bool(
		(in FunDecl x) =>
			x.flags.preferred,
		(in CalledSpecSig) =>
			false);

void getParamExpected(
	ref Alloc alloc,
	ref ProgramState programState,
	ref ParamExpected paramExpected,
	ref Candidates candidates,
	size_t argIdx,
) {
	foreach (scope ref Candidate candidate; candidates) {
		Type t = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		bool isDuplicate = ita.args.length == 0 &&
			exists!TypeAndInferring(tempAsArr(paramExpected), (in TypeAndInferring x) =>
				x.type == t);
		if (!isDuplicate)
			paramExpected.push(TypeAndInferring(t, ita));
	}
}

void inferCandidateTypeArgsFromCheckedSpecSig(
	ref Alloc alloc,
	ref ProgramState programState,
	in Candidate specCandidate,
	in SpecDeclSig specSig,
	in ReturnAndParamTypes sigTypes,
	scope InferringTypeArgs callInferringTypeArgs,
) {
	inferTypeArgsFrom(
		alloc, programState, sigTypes.returnType, callInferringTypeArgs,
		specCandidate.called.returnType, inferringTypeArgs(specCandidate));
	foreach (size_t argIdx; 0 .. specSig.params.length)
		inferTypeArgsFrom(
			alloc, programState,
			sigTypes.paramTypes[argIdx],
			callInferringTypeArgs,
			getCandidateExpectedParameterType(alloc, programState, specCandidate, argIdx),
			inferringTypeArgs(specCandidate));
}

bool isPartiallyInferred(in MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs) {
	bool hasInferred = false;
	bool hasUninferred = true;
	foreach (ref const SingleInferringType x; tempAsArr(typeArgs)) {
		if (has(tryGetInferred(x)))
			hasInferred = true;
		else
			hasUninferred = true;
	}
	return hasInferred && hasUninferred;
}

enum ContinueOrAbort { continue_, abort }

ContinueOrAbort inferCandidateTypeArgsFromExplicitlyTypedArgument(
	ref ExprCtx ctx,
	scope ref Candidates candidates,
	size_t argIndex,
	in ExprAst arg,
) {
	if (arg.kind.isA!(LambdaAst*)) {
		// TODO: this means we may do 'typeFromDestructure' twice, once here and once when checking,
		// leading to duplicate diagnostics
		Opt!Type optLambdaParamType = typeFromDestructure(ctx, arg.kind.as!(LambdaAst*).param);
		if (has(optLambdaParamType)) {
			Type lambdaParamType = force(optLambdaParamType);
			if (lambdaParamType.isA!(Type.Bogus))
				return ContinueOrAbort.abort;
			else {
				foreach (ref Candidate candidate; candidates) {
					Type paramType = getCandidateExpectedParameterType(
						ctx.alloc, ctx.programState, candidate, argIndex);
					inferTypeArgsFromLambdaParameterType(
						ctx.alloc, ctx.programState, ctx.commonTypes,
						paramType, candidate.inferringTypeArgs, lambdaParamType);
				}
				return ContinueOrAbort.continue_;
			}
		} else
			return ContinueOrAbort.continue_;
	} else
		return ContinueOrAbort.continue_;
}

bool inferCandidateTypeArgsFromSpecs(ref ExprCtx ctx, scope ref Candidate candidate) {
	// For performance, don't bother unless we have something to infer from already
	if (isPartiallyInferred(candidate.typeArgs)) {
		return candidate.called.match!bool(
			(ref FunDecl called) =>
				every!(immutable SpecInst*)(called.specs, (in immutable SpecInst* spec) =>
					inferCandidateTypeArgsFromSpecInst(ctx, candidate, called, *spec)),
			(CalledSpecSig _) => true);
	} else
		// figure this out at the end
		return true; 
}

bool inferCandidateTypeArgsFromSpecInst(
	ref ExprCtx ctx,
	scope ref Candidate callCandidate,
	in FunDecl called,
	in SpecInst spec,
) {
	return every!(immutable SpecInst*)(spec.parents, (in immutable SpecInst* parent) =>
		inferCandidateTypeArgsFromSpecInst(ctx, callCandidate, called, *parent)
	) && decl(spec).body_.match!bool(
		(SpecDeclBody.Builtin) =>
			// figure this out at the end
			true,
		(SpecDeclSig[] sigs) =>
			zipEvery!(SpecDeclSig, ReturnAndParamTypes)(
				sigs, spec.sigTypes, (in SpecDeclSig sig, in ReturnAndParamTypes returnAndParamTypes) =>
					inferCandidateTypeArgsFromSpecSig(ctx, callCandidate, called, sig, returnAndParamTypes)));
}

bool inferCandidateTypeArgsFromSpecSig(
	ref ExprCtx ctx,
	scope ref Candidate callCandidate,
	in FunDecl called,
	in SpecDeclSig specSig,
	in ReturnAndParamTypes returnAndParamTypes,
) =>
	withCandidates(ctx, specSig.name, none!(TypeAst*), specSig.params.length, (ref Candidates specCandidates) {
		const InferringTypeArgs constCallInferring = inferringTypeArgs(callCandidate);
		filterCandidates(specCandidates, (ref Candidate specCandidate) =>
			testCandidateForSpecSig(
				ctx.alloc, ctx.programState, specCandidate, returnAndParamTypes, constCallInferring));

		switch (size(specCandidates)) {
			case 0:
				return false;
			case 1:
				inferCandidateTypeArgsFromCheckedSpecSig(
					ctx.alloc, ctx.programState,
					only(specCandidates), specSig, returnAndParamTypes, inferringTypeArgs(callCandidate));
				return true;
			default:
				return true;
		}
	});

Expr checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	bool isInLambda,
	ref const Candidate candidate,
	FileAndRange range,
	Expr[] args,
	ref Expected expected,
) {
	Opt!Called opCalled = checkCallSpecs(ctx, range, candidate);
	if (has(opCalled)) {
		Called called = force(opCalled);
		checkCalled(ctx, range, called, isInLambda, empty(args) ? ArgsKind.empty : ArgsKind.nonEmpty);
		Expr calledExpr = Expr(range, ExprKind(ExprKind.Call(called, args)));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(ctx, expected, called.returnType, calledExpr);
	} else
		return bogus(expected, range);
}
