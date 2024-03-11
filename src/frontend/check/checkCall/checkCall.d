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
	maxCandidates,
	testCandidateForSpecSig,
	testCandidateParamType,
	typeContextForCandidate,
	withCandidates;
import frontend.check.checkCall.checkCallSpecs : ArgsKind, checkCalled, checkCallSpecs, isEnum, isFlags;
import frontend.check.checkExpr : checkCanDoUnsafe, checkExpr, typeFromDestructure;
import frontend.check.exprCtx : addDiag2, ExprCtx, LocalsInfo, typeFromAst2;
import frontend.check.inferringType :
	asInferringTypeArgs,
	bogus,
	check,
	Expected,
	getExpectedForDiag,
	InferringTypeArgs,
	inferTypeArgsFrom,
	inferTypeArgsFromLambdaParameterType,
	matchExpectedVsReturnTypeNoDiagnostic,
	nonInferring,
	SingleInferringType,
	tryGetInferred,
	tryGetNonInferringType,
	TypeAndContext,
	TypeContext,
	withExpectCandidates;
import frontend.check.instantiate : InstantiateCtx;
import frontend.check.typeFromAst : getNTypeArgsForDiagnostic, unpackTupleIfNeeded;
import frontend.lang : maxTypeParams;
import model.ast : CallAst, CallNamedAst, ExprAst, LambdaAst, NameAndRange;
import model.diag : Diag;
import model.model :
	BuiltinSpec,
	Called,
	CalledDecl,
	CalledSpecSig,
	CallExpr,
	Destructure,
	Expr,
	ExprAndType,
	ExprKind,
	FunDecl,
	Local,
	Params,
	ReturnAndParamTypes,
	SpecDeclSig,
	SpecInst,
	Type;
import util.col.array :
	arraysCorrespond, every, exists, isEmpty, makeArrayOrFail, newArray, only, small, SmallArray, zipEvery;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.mutMaxArr : asTemporaryArray, isEmpty, fillMutMaxArr, MutMaxArr, mutMaxArr, mutMaxArrSize, only, size;
import util.opt : force, has, none, Opt, optIf, some, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : typeAs;

Expr checkCall(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref CallAst ast, ref Expected expected) {
	checkCallShouldUseSyntax(ctx, ast);
	return checkCallCommon(
		ctx, locals, source,
		// Show diags at the function name and not at the whole call ast
		ast.nameRange(source),
		ast.funName.name,
		has(ast.typeArg) ? some(typeFromAst2(ctx, *force(ast.typeArg))) : none!Type,
		ast.args,
		expected,
		(in CalledDecl _) => true);
}

Expr checkCallNamed(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref CallNamedAst ast,
	ref Expected expected,
) =>
	checkCallCommon(
		ctx,
		locals,
		source,
		source.range,
		symbol!"new",
		none!Type,
		ast.args,
		expected,
		(in CalledDecl x) =>
			parameterNamesAre(x, ast.names));

private bool parameterNamesAre(in CalledDecl a, in NameAndRange[] names) {
	assert(!isEmpty(names));
	Destructure[] actual = a.match!(Destructure[])(
		(ref FunDecl x) =>
			x.params.match!(Destructure[])(
				(Destructure[] y) => y,
				// will always fail because 'names' is always non-empty
				(ref Params.Varargs) => typeAs!(Destructure[])([])),
		(CalledSpecSig x) =>
			typeAs!(Destructure[])(x.nonInstantiatedSig.params));
	return arraysCorrespond!(Destructure, NameAndRange)(actual, names, (ref Destructure x, ref NameAndRange name) =>
		x.isA!(Local*) && x.as!(Local*).name == name.name);
}

Expr checkCallSpecial(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range range,
	Symbol funName,
	in ExprAst[] args,
	ref Expected expected,
) =>
	// TODO:NO ALLOC
	checkCallCommon(
		ctx, locals, source, range, funName, none!Type, newArray(ctx.alloc, args), expected,
		(in CalledDecl _) => true);

private Expr checkCallCommon(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range diagRange,
	Symbol funName,
	Opt!Type typeArg,
	ExprAst[] args,
	ref Expected expected,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow cbAdditionalFilter,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.perf, ctx.alloc, PerfMeasure.checkCall);
	Expr res = withCandidates!Expr(
		funsInScope(ctx), funName, args.length,
		(ref Candidate candidate) =>
			(!has(typeArg) || filterCandidateByExplicitTypeArg(ctx, candidate, force(typeArg))) &&
			matchExpectedVsReturnTypeNoDiagnostic(
				ctx.instantiateCtx, expected,
				TypeAndContext(candidate.called.returnType, typeContextForCandidate(candidate))) &&
			cbAdditionalFilter(candidate.called),
		(ref Candidates candidates) =>
			checkCallInner(
				ctx, locals, source, diagRange, funName, args, typeArg, perfMeasurer, candidates, expected));
	endMeasure(ctx.perf, ctx.alloc, perfMeasurer);
	return res;
}

Expr checkCallIdentifier(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, Symbol name, ref Expected expected) {
	checkCallIdentifierShouldUseSyntax(ctx, source.range, name);
	return checkCallSpecial(ctx, locals, source, source.range, name, [], expected);
}

private:

Expr checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range diagRange,
	Symbol funName,
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

	ArrayBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	Opt!(Expr[]) args = makeArrayOrFail!Expr(ctx.alloc, arity, (size_t argIdx) @safe {
		if (isEmpty(candidates))
			return none!Expr;

		filterCandidatesButDontRemoveAll(candidates, (ref Candidate x) =>
			preCheckCandidateSpecs(ctx, x));

		ParamExpected paramExpected = mutMaxArr!(maxCandidates, TypeAndContext);
		getParamExpected(ctx.instantiateCtx, paramExpected, candidates, argIdx);
		pauseMeasure(ctx.perf, ctx.alloc, perfMeasurer);
		ExprAndType arg = withExpectCandidates(asTemporaryArray(paramExpected), (ref Expected expected) =>
			checkExpr(ctx, locals, &argAsts[argIdx], expected));
		resumeMeasure(ctx.perf, ctx.alloc, perfMeasurer);
		// If it failed to check, don't continue, just stop there.
		if (arg.type.isA!(Type.Bogus)) {
			someArgIsBogus = true;
			return none!Expr;
		}
		add(ctx.alloc, actualArgTypes, arg.type);
		filterCandidates(candidates, (ref Candidate candidate) =>
			testCandidateParamType(ctx.instantiateCtx, candidate, argIdx, nonInferring(arg.type)));
		return some(arg.expr);
	});

	if (someArgIsBogus)
		return bogus(expected, source);

	filterCandidatesButDontRemoveAll(candidates, (ref Candidate x) =>
		preCheckCandidateSpecs(ctx, x));

	if (!has(args) || mutMaxArrSize(candidates) != 1) {
		if (isEmpty(candidates)) {
			CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(ctx, funName);
			addDiag2(ctx, diagRange, Diag(Diag.CallNoMatch(
				ctx.typeContainer,
				funName,
				getExpectedForDiag(ctx, expected),
				getNTypeArgsForDiagnostic(ctx.commonTypes, explicitTypeArg),
				arity,
				finish(ctx.alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(ctx, diagRange, Diag(
				Diag.CallMultipleMatches(funName, ctx.typeContainer, candidatesForDiag(ctx.alloc, candidates))));
		return bogus(expected, source);
	} else
		return checkCallAfterChoosingOverload(
			ctx, locals, only(candidates), source, diagRange, small!Expr(force(args)), expected);
}

void checkCallIdentifierShouldUseSyntax(ref ExprCtx ctx, Range range, Symbol name) {
	if (name == symbol!"new")
		addDiag2(ctx, range, Diag(Diag.CallShouldUseSyntax(0, Diag.CallShouldUseSyntax.Kind.new_)));
}

void checkCallShouldUseSyntax(ref ExprCtx ctx, in CallAst ast) {
	switch (ast.style) {
		case CallAst.Style.dot:
		case CallAst.Style.infix:
			Opt!(Diag.CallShouldUseSyntax.Kind) kind = shouldUseSyntaxKind(ast);
			if (has(kind))
				addDiag2(ctx, ast.funName.range, Diag(Diag.CallShouldUseSyntax(ast.args.length, force(kind))));
			break;
		default:
			break;
	}
}

Opt!(Diag.CallShouldUseSyntax.Kind) shouldUseSyntaxKind(in CallAst ast) {
	switch (ast.funName.name.value) {
		case symbol!"for-break".value:
			return optIf(secondArgIsLambda(ast), () => Diag.CallShouldUseSyntax.Kind.for_break);
		case symbol!"force".value:
			return some(Diag.CallShouldUseSyntax.Kind.force);
		case symbol!"for-loop".value:
			return optIf(secondArgIsLambda(ast), () => Diag.CallShouldUseSyntax.Kind.for_loop);
		case symbol!"new".value:
			return some(Diag.CallShouldUseSyntax.Kind.new_);
		case symbol!"not".value:
			return some(Diag.CallShouldUseSyntax.Kind.not);
		case symbol!"set-subscript".value:
			return some(Diag.CallShouldUseSyntax.Kind.set_subscript);
		case symbol!"subscript".value:
			return some(Diag.CallShouldUseSyntax.Kind.subscript);
		case symbol!"with-block".value:
			return optIf(secondArgIsLambda(ast), () => Diag.CallShouldUseSyntax.Kind.with_block);
		default:
			return none!(Diag.CallShouldUseSyntax.Kind);
	}
}
bool secondArgIsLambda(in CallAst ast) =>
	ast.args.length == 2 && ast.args[1].kind.isA!(LambdaAst*);

bool filterCandidateByExplicitTypeArg(ref ExprCtx ctx, scope ref Candidate candidate, Type typeArg) {
	size_t nTypeParams = mutMaxArrSize(candidate.typeArgs);
	Type[] args = unpackTupleIfNeeded(ctx.commonTypes, nTypeParams, &typeArg);
	bool ok = args.length == nTypeParams;
	if (ok)
		fillMutMaxArr(candidate.typeArgs, size(candidate.typeArgs), (size_t i) =>
			SingleInferringType(some(args[i])));
	return ok;
}

alias ParamExpected = MutMaxArr!(maxCandidates, TypeAndContext);

void getParamExpected(
	ref InstantiateCtx ctx,
	ref ParamExpected paramExpected,
	scope ref Candidates candidates,
	size_t argIdx,
) {
	foreach (ref Candidate candidate; candidates) {
		TypeAndContext expected = getCandidateExpectedParameterType(ctx, candidate, argIdx);
		bool isDuplicate = !expected.context.isInferring &&
			exists!TypeAndContext(asTemporaryArray(paramExpected), (in TypeAndContext x) =>
				!x.context.isInferring && x.type == expected.type);
		if (!isDuplicate)
			paramExpected ~= expected;
	}
}

void inferCandidateTypeArgsFromCheckedSpecSig(
	ref InstantiateCtx ctx,
	ref const Candidate specCandidate,
	in SpecDeclSig specSig,
	in ReturnAndParamTypes sigTypes,
	scope InferringTypeArgs callInferringTypeArgs,
) {
	inferTypeArgsFrom(
		ctx, sigTypes.returnType, callInferringTypeArgs,
		const TypeAndContext(specCandidate.called.returnType, typeContextForCandidate(specCandidate)));
	foreach (size_t argIdx; 0 .. specSig.params.length)
		inferTypeArgsFrom(
			ctx, sigTypes.paramTypes[argIdx], callInferringTypeArgs,
			getCandidateExpectedParameterType(ctx, specCandidate, argIdx));
}

enum TypeArgsInferenceState { none, partial, all }
TypeArgsInferenceState getInferenceState(in MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs) {
	bool hasInferred = false;
	bool hasUninferred = true;
	foreach (ref const SingleInferringType x; typeArgs) {
		if (has(tryGetInferred(x)))
			hasInferred = true;
		else
			hasUninferred = true;
	}
	return hasInferred
		? hasUninferred ? TypeArgsInferenceState.partial : TypeArgsInferenceState.all
		: TypeArgsInferenceState.none;
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
					TypeAndContext paramType = getCandidateExpectedParameterType(
						ctx.instantiateCtx, candidate, argIndex);
					inferTypeArgsFromLambdaParameterType(
						ctx.instantiateCtx, ctx.commonTypes,
						paramType.type, asInferringTypeArgs(typeContextForCandidate(candidate)),
						lambdaParamType);
				}
				return ContinueOrAbort.continue_;
			}
		} else
			return ContinueOrAbort.continue_;
	} else
		return ContinueOrAbort.continue_;
}

// This is not the final check, but we do filter out some candidates or infer type arguments early based on specs.
bool preCheckCandidateSpecs(ref ExprCtx ctx, ref Candidate candidate) {
	// For performance, don't bother unless we have something to infer from already
	TypeArgsInferenceState state = getInferenceState(candidate.typeArgs);
	return state == TypeArgsInferenceState.none || candidate.called.match!bool(
		(ref FunDecl called) =>
			every!(immutable SpecInst*)(called.specs, (in immutable SpecInst* spec) =>
				preCheckCandidateSpec(ctx, candidate, called, *spec, state)),
		(CalledSpecSig _) => true);
}

bool preCheckCandidateSpec(
	ref ExprCtx ctx,
	ref Candidate callCandidate,
	in FunDecl called,
	in SpecInst spec,
	TypeArgsInferenceState state,
) =>
	every!(immutable SpecInst*)(spec.parents, (in immutable SpecInst* parent) =>
		preCheckCandidateSpec(ctx, callCandidate, called, *parent, state)
	) &&
	preCheckBuiltinSpec(ctx, callCandidate, called, spec) &&
	// For a builtin spec, we'll leave it for the end.
	(state != TypeArgsInferenceState.partial || zipEvery!(SpecDeclSig, ReturnAndParamTypes)(
		spec.decl.sigs, spec.sigTypes, (ref SpecDeclSig sig, ref ReturnAndParamTypes returnAndParamTypes) =>
			inferCandidateTypeArgsFromSpecSig(ctx, callCandidate, called, sig, returnAndParamTypes)));

bool preCheckBuiltinSpec(ref ExprCtx ctx, ref const Candidate callCandidate, in FunDecl called, in SpecInst spec) {
	if (has(spec.decl.builtin)) {
		bool checkTypeIfInferred(in bool delegate(in Type) @safe @nogc pure nothrow cb) {
			Opt!Type type = tryGetNonInferringType(
				ctx.instantiateCtx, TypeAndContext(only(spec.typeArgs), typeContextForCandidate(callCandidate)));
			return !has(type) || cb(force(type));
		}

		switch (force(spec.decl.builtin)) {
			case BuiltinSpec.enum_:
				return checkTypeIfInferred((in Type x) => isEnum(ctx.outermostFunSpecs, x));
			case BuiltinSpec.flags:
				return checkTypeIfInferred((in Type x) => isFlags(ctx.outermostFunSpecs, x));
			default:
				return true;
		}
	} else
		return true;
}

bool inferCandidateTypeArgsFromSpecSig(
	ref ExprCtx ctx,
	ref Candidate callCandidate,
	in FunDecl called,
	in SpecDeclSig specSig,
	in ReturnAndParamTypes returnAndParamTypes,
) {
	TypeContext callContext = typeContextForCandidate(callCandidate);
	return withCandidates!bool(
		funsInScope(ctx),
		specSig.name,
		specSig.params.length,
		(ref Candidate x) =>
			testCandidateForSpecSig(ctx.instantiateCtx, x, returnAndParamTypes, callContext),
		(ref Candidates specCandidates) {
			switch (size(specCandidates)) {
				case 0:
					return false;
				case 1:
					inferCandidateTypeArgsFromCheckedSpecSig(
						ctx.instantiateCtx,
						only(specCandidates),
						specSig,
						returnAndParamTypes,
						asInferringTypeArgs(callContext));
					return true;
				default:
					return true;
			}
		});
}

Expr checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	in LocalsInfo locals,
	ref const Candidate candidate,
	ExprAst* source,
	in Range diagRange,
	SmallArray!Expr args,
	ref Expected expected,
) {
	Called called = checkCallSpecs(ctx, diagRange, candidate);
	checkCalled(
		ctx.checkCtx, diagRange, called, ctx.outermostFunFlags, locals,
		isEmpty(args) ? ArgsKind.empty : ArgsKind.nonEmpty,
		() => checkCanDoUnsafe(ctx));
	Expr calledExpr = Expr(source, ExprKind(CallExpr(called, args)));
	//TODO: PERF second return type check may be unnecessary
	// if we already filtered by return type at the beginning
	return check(ctx, source, expected, called.returnType, calledExpr);
}
