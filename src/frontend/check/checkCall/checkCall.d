module frontend.check.checkCall.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate,
	Candidates,
	candidatesForDiag,
	filterCandidates,
	filterCandidatesButDontRemoveAll,
	funsInScope,
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
import frontend.check.exprCtx : addDiag2, ExprCtx, FunOrLambdaInfo, isInLambda, LocalNode, LocalsInfo, typeFromAst2;
import frontend.check.inferringType :
	bogus,
	check,
	Expected,
	inferred,
	InferringTypeArgs,
	inferTypeArgsFrom,
	inferTypeArgsFromLambdaParameterType,
	matchExpectedVsReturnTypeNoDiagnostic,
	SingleInferringType,
	tryGetInferred,
	TypeAndInferring;
import frontend.check.instantiate : InstantiateCtx;
import frontend.check.typeFromAst : getNTypeArgsForDiagnostic, unpackTupleIfNeeded;
import frontend.lang : maxTypeParams;
import frontend.parse.ast : CallAst, ExprAst, LambdaAst, nameRange, rangeOfNameAndRange;
import model.diag : Diag;
import model.model :
	arity,
	body_,
	Called,
	CalledDecl,
	CalledSpecSig,
	CallExpr,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	LambdaExpr,
	ReturnAndParamTypes,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	Type;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, every, exists, makeArrayOrFail, zipEvery;
import util.col.mutMaxArr :
	exists, isEmpty, fillMutMaxArr, MutMaxArr, mutMaxArr, mutMaxArrSize, only, push, size, tempAsArr;
import util.opt : force, has, none, noneMut, Opt, some, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : Range;
import util.sym : Sym, sym;

Expr checkCall(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref CallAst ast, ref Expected expected) {
	switch (ast.style) {
		case CallAst.Style.dot:
		case CallAst.Style.infix:
			checkCallShouldUseSyntax(
				ctx, rangeOfNameAndRange(ast.funName, ctx.allSymbols), ast.funNameName, ast.args.length);
			break;
		default:
			break;
	}
	return checkCallCommon(
		ctx, locals, source,
		// Show diags at the function name and not at the whole call ast
		nameRange(ctx.allSymbols, ast),
		ast.funName.name,
		has(ast.typeArg) ? some(typeFromAst2(ctx, *force(ast.typeArg))) : none!Type,
		ast.args,
		expected);
}

Expr checkCallSpecial(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Sym funName,
	in ExprAst[] args,
	ref Expected expected,
) =>
	// TODO:NO ALLOC
	checkCallCommon(ctx, locals, source, source.range, funName, none!Type, arrLiteral(ctx.alloc, args), expected);

Expr checkCallSpecialNoLocals(
	ref ExprCtx ctx,
	ExprAst* source,
	Sym funName,
	in ExprAst[] args,
	ref Expected expected,
) {
	FunOrLambdaInfo emptyFunInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), none!(LambdaExpr*));
	LocalsInfo emptyLocals = LocalsInfo(ptrTrustMe(emptyFunInfo), noneMut!(LocalNode*));
	return checkCallSpecial(ctx, emptyLocals, source, funName, args, expected);
}

private Expr checkCallCommon(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range diagRange,
	Sym funName,
	in Opt!Type typeArg,
	ExprAst[] args,
	ref Expected expected,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.perf, ctx.alloc, PerfMeasure.checkCall);
	Expr res = withCandidates!Expr(
		funsInScope(ctx), funName, args.length,
		(scope ref Candidate candidate) =>
			(!has(typeArg) || filterCandidateByExplicitTypeArg(ctx, candidate, force(typeArg))) &&
			matchExpectedVsReturnTypeNoDiagnostic(
				ctx.instantiateCtx, expected, candidate.called.returnType, inferringTypeArgs(candidate)),
		(ref Candidates candidates) =>
			checkCallInner(
				ctx, locals, source, diagRange, funName, args, typeArg, perfMeasurer, candidates, expected));
	endMeasure(ctx.perf, ctx.alloc, perfMeasurer);
	return res;
}

Expr checkCallIdentifier(ref ExprCtx ctx, ExprAst* source, Sym name, ref Expected expected) {
	checkCallShouldUseSyntax(ctx, source.range, name, 0);
	return checkCallSpecialNoLocals(ctx, source, name, [], expected);
}

private:

Expr checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range diagRange,
	Sym funName,
	ExprAst[] argAsts,
	in Opt!Type explicitTypeArg,
	scope ref PerfMeasurer perfMeasurer,
	ref Candidates candidates,
	ref Expected expected,
) {
	size_t arity = argAsts.length;

	// Apply explicitly typed arguments first
	foreach (size_t argIdx, ExprAst arg; argAsts)
		if (inferCandidateTypeArgsFromExplicitlyTypedArgument(ctx, candidates, argIdx, arg) == ContinueOrAbort.abort)
			return bogus(expected, source);

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	Opt!(Expr[]) args = makeArrayOrFail!Expr(ctx.alloc, arity, (size_t argIdx) @safe {
		if (isEmpty(candidates))
			return none!Expr;

		filterCandidatesButDontRemoveAll(candidates, (scope ref Candidate x) =>
			inferCandidateTypeArgsFromSpecs(ctx, x));

		ParamExpected paramExpected = mutMaxArr!(maxCandidates, TypeAndInferring);
		getParamExpected(ctx.instantiateCtx, paramExpected, candidates, argIdx);
		Expected expected = Expected(tempAsArr(castNonScope_ref(paramExpected)));

		pauseMeasure(ctx.perf, ctx.alloc, perfMeasurer);
		Expr arg = checkExpr(ctx, locals, &argAsts[argIdx], expected);
		resumeMeasure(ctx.perf, ctx.alloc, perfMeasurer);

		Type actualArgType = inferred(expected);
		// If it failed to check, don't continue, just stop there.
		if (actualArgType.isA!(Type.Bogus)) {
			someArgIsBogus = true;
			return none!Expr;
		}
		add(ctx.alloc, actualArgTypes, actualArgType);
		filterCandidates(candidates, (scope ref Candidate candidate) =>
			testCandidateParamType(ctx.instantiateCtx, candidate, actualArgType, argIdx, InferringTypeArgs()));
		return some(arg);
	});

	if (someArgIsBogus)
		return bogus(expected, source);

	filterCandidatesButDontRemoveAll(candidates, (scope ref Candidate x) =>
		inferCandidateTypeArgsFromSpecs(ctx, x));

	if (!has(args) || mutMaxArrSize(candidates) != 1) {
		if (isEmpty(candidates)) {
			CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(ctx, funName);
			addDiag2(ctx, diagRange, Diag(Diag.CallNoMatch(
				funName,
				tryGetInferred(expected),
				getNTypeArgsForDiagnostic(ctx.commonTypes, explicitTypeArg),
				arity,
				finishArr(ctx.alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(ctx, diagRange, Diag(Diag.CallMultipleMatches(funName, candidatesForDiag(ctx.alloc, candidates))));
		return bogus(expected, source);
	} else
		return checkCallAfterChoosingOverload(ctx, isInLambda(locals), only(candidates), source, force(args), expected);
}

void checkCallShouldUseSyntax(ref ExprCtx ctx, in Range range, Sym funName, size_t arity) {
	Opt!(Diag.CallShouldUseSyntax.Kind) kind = shouldUseSyntaxKind(funName, ctx.outermostFunName);
	if (has(kind))
		addDiag2(ctx, range, Diag(Diag.CallShouldUseSyntax(arity, force(kind))));
}

Opt!(Diag.CallShouldUseSyntax.Kind) shouldUseSyntaxKind(Sym calledFunName, Sym outermostFunName) {
	switch (calledFunName.value) {
		case sym!"for-break".value:
			return outermostFunName == sym!"for-break"
				? none!(Diag.CallShouldUseSyntax.Kind)
				: some(Diag.CallShouldUseSyntax.Kind.for_break);
		case sym!"force".value:
			return some(Diag.CallShouldUseSyntax.Kind.force);
		case sym!"for_loop".value:
			return some(Diag.CallShouldUseSyntax.Kind.for_loop);
		case sym!"new".value:
			return some(Diag.CallShouldUseSyntax.Kind.new_);
		case sym!"not".value:
			return some(Diag.CallShouldUseSyntax.Kind.not);
		case sym!"set-subscript".value:
			return some(Diag.CallShouldUseSyntax.Kind.set_subscript);
		case sym!"subscript".value:
			return some(Diag.CallShouldUseSyntax.Kind.subscript);
		case sym!"with-block".value:
			return some(Diag.CallShouldUseSyntax.Kind.with_block);
		default:
			return none!(Diag.CallShouldUseSyntax.Kind);
	}
}

bool filterCandidateByExplicitTypeArg(ref ExprCtx ctx, scope ref Candidate candidate, in Type typeArg) {
	size_t nTypeParams = mutMaxArrSize(candidate.typeArgs);
	Type[] args = unpackTupleIfNeeded(ctx.commonTypes, nTypeParams, &typeArg);
	bool ok = args.length == nTypeParams;
	if (ok)
		fillMutMaxArr(candidate.typeArgs, size(candidate.typeArgs), (size_t i) =>
			SingleInferringType(some(args[i])));
	return ok;
}

alias ParamExpected = MutMaxArr!(maxCandidates, TypeAndInferring);

void getParamExpected(
	ref InstantiateCtx ctx,
	ref ParamExpected paramExpected,
	scope ref Candidates candidates,
	size_t argIdx,
) {
	foreach (scope ref Candidate candidate; candidates) {
		Type t = getCandidateExpectedParameterType(ctx, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		bool isDuplicate = ita.args.length == 0 &&
			exists!TypeAndInferring(tempAsArr(paramExpected), (in TypeAndInferring x) =>
				x.type == t);
		if (!isDuplicate)
			paramExpected.push(TypeAndInferring(t, ita));
	}
}

void inferCandidateTypeArgsFromCheckedSpecSig(
	ref InstantiateCtx ctx,
	in Candidate specCandidate,
	in SpecDeclSig specSig,
	in ReturnAndParamTypes sigTypes,
	scope InferringTypeArgs callInferringTypeArgs,
) {
	inferTypeArgsFrom(
		ctx, sigTypes.returnType, callInferringTypeArgs,
		specCandidate.called.returnType, inferringTypeArgs(specCandidate));
	foreach (size_t argIdx; 0 .. specSig.params.length)
		inferTypeArgsFrom(
			ctx,
			sigTypes.paramTypes[argIdx],
			callInferringTypeArgs,
			getCandidateExpectedParameterType(ctx, specCandidate, argIdx),
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
					Type paramType = getCandidateExpectedParameterType(ctx.instantiateCtx, candidate, argIndex);
					inferTypeArgsFromLambdaParameterType(
						ctx.instantiateCtx, ctx.commonTypes,
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
) {
	const InferringTypeArgs constCallInferring = inferringTypeArgs(callCandidate);
	return withCandidates(
		funsInScope(ctx),
		specSig.name,
		specSig.params.length,
		(scope ref Candidate x) =>
			testCandidateForSpecSig(ctx.instantiateCtx, x, returnAndParamTypes, constCallInferring),
		(scope ref Candidates specCandidates) {
			switch (size(specCandidates)) {
				case 0:
					return false;
				case 1:
					inferCandidateTypeArgsFromCheckedSpecSig(
						ctx.instantiateCtx,
						only(specCandidates),
						specSig,
						returnAndParamTypes,
						inferringTypeArgs(callCandidate));
					return true;
				default:
					return true;
			}
		});
}

Expr checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	bool isInLambda,
	ref const Candidate candidate,
	ExprAst* source,
	Expr[] args,
	ref Expected expected,
) {
	Opt!Called opCalled = checkCallSpecs(ctx, source.range, candidate);
	if (has(opCalled)) {
		Called called = force(opCalled);
		checkCalled(ctx, source, called, isInLambda, empty(args) ? ArgsKind.empty : ArgsKind.nonEmpty);
		Expr calledExpr = Expr(source, ExprKind(CallExpr(called, args)));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(ctx, source, expected, called.returnType, calledExpr);
	} else
		return bogus(expected, source);
}
