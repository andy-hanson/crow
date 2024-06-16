module frontend.check.checkCall.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates :
	Candidate,
	candidatesForDiag,
	funsInExprScope,
	FunsInScope,
	getAllCandidatesAsCalledDecls,
	getCandidateExpectedParameterType,
	testCandidateForSpecSig,
	testCandidateParamType,
	typeContextForCandidate,
	withCandidates;
import frontend.check.checkCall.checkCallSpecs : ArgsKind, checkCalled, checkCallSpecs, isEnum, isFlags;
import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.checkExpr : checkCanDoUnsafe, checkExpr, checkLambda, typeFromDestructure;
import frontend.check.exprCtx : addDiag2, ExprCtx, LocalsInfo, typeFromAst2;
import frontend.check.inferringType :
	bogus,
	check,
	checkWithModifyExpected,
	Expected,
	getExpectedForDiag,
	inferred,
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
import frontend.check.instantiate : InstantiateCtx, makeOptionIfNotAlready, makeOptionType;
import frontend.check.typeFromAst : getNTypeArgsForDiagnostic, tryUnpackOptionType, unpackTupleIfNeeded;
import model.ast : CallAst, CallNamedAst, DestructureAst, ExprAst, LambdaAst, NameAndRange;
import model.diag : Diag, TypeContainer;
import model.model :
	BuiltinSpec,
	Called,
	CalledDecl,
	CalledSpecSig,
	CallExpr,
	CallOptionExpr,
	CommonTypes,
	Destructure,
	Expr,
	ExprAndType,
	ExprKind,
	FunDecl,
	FunFlags,
	Local,
	Params,
	ReturnAndParamTypes,
	Signature,
	SpecInst,
	Type;
import util.alloc.stackAlloc : MaxStackArray, withMaxStackArray;
import util.col.array :
	arraysCorrespond,
	copyArray,
	every,
	everyWithIndex,
	exists,
	filterUnordered,
	filterUnorderedButDontRemoveAll,
	isEmpty,
	map,
	newArray,
	only,
	zipEvery;
import util.col.arrayBuilder : finish;
import util.col.exactSizeArrayBuilder : ExactSizeArrayBuilder, newExactSizeArrayBuilder, smallFinish;
import util.late : Late, late, lateGet, lateSet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : typeAs;

Expr checkCall(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref CallAst ast, ref Expected expected) {
	checkCallShouldUseSyntax(ctx, ast);
	return ast.style == CallAst.Style.questionSubscript || ast.style == CallAst.Style.questionDot
		? checkOptionCall(ctx, locals, source, ast, expected)
		: exprFromCall(ctx, expected, source, checkCallCommon(
			ctx, locals,
			// Show diags at the function name and not at the whole call ast
			ast.nameRange(source),
			ast.funName.name,
			has(ast.typeArg) ? some(typeFromAst2(ctx, *force(ast.typeArg))) : none!Type,
			ast.args,
			expected,
			(in CalledDecl _) => true));
}

Expr checkCallNamed(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref CallNamedAst ast,
	ref Expected expected,
) =>
	exprFromCall(ctx, expected, source, checkCallCommon(
		ctx,
		locals,
		source.range,
		symbol!"new",
		none!Type,
		ast.args,
		expected,
		(in CalledDecl x) =>
			parameterNamesAre(x, ast.names)));

private Expr exprFromCall(ref ExprCtx ctx, ref Expected expected, ExprAst* source, Opt!CallExpr call) =>
	has(call)
		? check(ctx, expected, force(call).called.returnType, source, ExprKind(force(call)))
		: bogus(expected, source);

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
	Range range,
	Symbol funName,
	in ExprAst[] args,
	ref Expected expected,
) =>
	exprFromCall(ctx, expected, source, checkCallCommon(
		ctx, locals, range, funName, none!Type, newArray(ctx.alloc, args), expected,
		(in CalledDecl _) => true));

private Opt!CallExpr checkCallCommon(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Range diagRange,
	Symbol funName,
	Opt!Type typeArg,
	ExprAst[] argAsts,
	ref Expected expected,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow cbAdditionalFilter,
) {
	ExactSizeArrayBuilder!Expr args = newExactSizeArrayBuilder!Expr(ctx.alloc, argAsts.length);
	Opt!Called called = checkCallCb(
		ctx, locals, diagRange, funName, typeArg, argAsts.length, expected,
		(size_t i, ref Expected argExpected) {
			args ~= checkExpr(ctx, locals, &argAsts[i], argExpected);
		},
		cbAdditionalFilter,
		(scope ref Candidate[] candidates) =>
			everyWithIndex!ExprAst(argAsts, (size_t argIdx, ref ExprAst arg) =>
				inferCandidateTypeArgsFromExplicitlyTypedArgument(
					ctx, candidates, argIdx, arg
				) == ContinueOrAbort.continue_));
	return optIf(has(called), () => CallExpr(force(called), smallFinish(args)));
}

Expr checkCallArgAndLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ExprAst* argAst,
	DestructureAst* paramAst,
	ExprAst* bodyAst,
	ref Expected expected,
) =>
	checkCallSpecialCb2(
		ctx, locals, source, diagRange, funName, expected,
		(ref Expected argExpected) =>
			checkExpr(ctx, locals, argAst, argExpected),
		(ref Expected argExpected) =>
			checkLambda(ctx, locals, source, paramAst, bodyAst, argExpected),
		(scope ref Candidate[] candidates) =>
			inferCandidateTypeArgsFromLambdaParameter(ctx, candidates, 1, *paramAst) == ContinueOrAbort.continue_);

Expr checkCallArgAnd2Lambdas(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ExprAst* argAst,
	DestructureAst* paramAst,
	ExprAst* bodyAst,
	ExprAst* body2Ast, // second lambda has no param
	ref Expected expected,
) =>
	checkCallSpecialCbN(
		ctx, locals, source, diagRange, funName, expected, 3,
		(size_t i, ref Expected argExpected) {
			final switch (i) {
				case 0:
					return checkExpr(ctx, locals, argAst, argExpected);
				case 1:
					return checkLambda(ctx, locals, source, paramAst, bodyAst, argExpected);
				case 2:
					return checkLambda(ctx, locals, source, &voidDestructure, body2Ast, argExpected);
			}
		},
		(scope ref Candidate[] candidates) =>
			inferCandidateTypeArgsFromLambdaParameter(ctx, candidates, 1, *paramAst) == ContinueOrAbort.continue_);

private immutable DestructureAst voidDestructure = DestructureAst(DestructureAst.Void(Range.empty));

Expr checkCallSpecialCb1(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ref Expected expected,
	in Expr delegate(ref Expected) @safe @nogc pure nothrow cbArg,
) =>
	checkCallSpecialCbN(
		ctx, locals, source, diagRange, funName, expected, 1,
		(size_t i, ref Expected argExpected) {
			assert(i == 0);
			return cbArg(argExpected);
		},
		(scope ref Candidate[] candidates) => true);

Expr checkCallSpecialCb2(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ref Expected expected,
	in Expr delegate(ref Expected) @safe @nogc pure nothrow cbArg0,
	in Expr delegate(ref Expected) @safe @nogc pure nothrow cbArg1,
	in bool delegate(scope ref Candidate[]) @safe @nogc pure nothrow cbBeforeCheck,
) =>
	checkCallSpecialCbN(
		ctx, locals, source, diagRange, funName, expected, 2,
		(size_t i, ref Expected argExpected) {
			final switch (i) {
				case 0:
					return cbArg0(argExpected);
				case 1:
					return cbArg1(argExpected);
			}
		},
		cbBeforeCheck);

Expr checkCallSpecialCbN(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ref Expected expected,
	size_t nArgs,
	in Expr delegate(size_t, ref Expected) @safe @nogc pure nothrow cbCheckArg,
) =>
	checkCallSpecialCbN(
		ctx, locals, source, diagRange, funName, expected, nArgs, cbCheckArg,
		(scope ref Candidate[]) => true);
Expr checkCallSpecialCbN(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	Range diagRange,
	Symbol funName,
	ref Expected expected,
	size_t nArgs,
	in Expr delegate(size_t, ref Expected) @safe @nogc pure nothrow cbCheckArg,
	in bool delegate(scope ref Candidate[]) @safe @nogc pure nothrow cbBeforeCheck,
) {
	ExactSizeArrayBuilder!Expr args = newExactSizeArrayBuilder!Expr(ctx.alloc, nArgs);
	Opt!Called called = checkCallCb(
		ctx, locals, diagRange, funName, none!Type, nArgs, expected,
		(size_t i, ref Expected argExpected) {
			args ~= cbCheckArg(i, argExpected);
		},
		(in CalledDecl) => true,
		cbBeforeCheck);
	Opt!CallExpr call = optIf(has(called), () => CallExpr(force(called), smallFinish(args)));
	return exprFromCall(ctx, expected, source, call);
}

private alias CbCheckArg = void delegate(size_t argIndex, ref Expected) @safe @nogc pure nothrow;
private Opt!Called checkCallCb(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Range diagRange,
	Symbol funName,
	Opt!Type typeArg,
	size_t nArgs,
	ref Expected expected,
	in CbCheckArg cbCheckArg,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow cbAdditionalFilter,
	in bool delegate(scope ref Candidate[]) @safe @nogc pure nothrow cbBeforeCheck,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.perf, ctx.alloc, PerfMeasure.checkCall);
	Opt!Called res = withCandidates!(Opt!Called)(
		funsInExprScope(ctx), funName, nArgs,
		(ref Candidate candidate) =>
			(!has(typeArg) || filterCandidateByExplicitTypeArg(ctx.commonTypes, candidate, force(typeArg))) &&
			matchExpectedVsReturnTypeNoDiagnostic(
				ctx.instantiateCtx, expected,
				TypeAndContext(candidate.called.returnType, typeContextForCandidate(candidate))) &&
			cbAdditionalFilter(candidate.called),
		(scope Candidate[] candidates) =>
			cbBeforeCheck(candidates)
				? checkCallInner(
					ctx, locals, diagRange, funName, typeArg,
					perfMeasurer, candidates, expected, nArgs, cbCheckArg)
				: none!Called);
	endMeasure(ctx.perf, ctx.alloc, perfMeasurer);
	return res;
}

Expr checkCallIdentifier(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, Symbol name, ref Expected expected) {
	checkCallIdentifierShouldUseSyntax(ctx, source.range, name);
	return checkCallSpecial(ctx, locals, source, source.range, name, [], expected);
}

Opt!Called findFunctionForReturnAndParamTypes(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeContainer typeContainer,
	FunsInScope funsInScope,
	FunFlags outermostFunFlags,
	in LocalsInfo locals,
	Symbol name,
	Range diagRange,
	Opt!Type typeArg,
	in ReturnAndParamTypes returnAndParamTypes,
	in bool delegate() @safe @nogc pure nothrow canDoUnsafe,
) {
	size_t arity = returnAndParamTypes.paramTypes.length;
	return withCandidates!(Opt!Called)(
		funsInScope,
		name,
		arity,
		(scope ref Candidate x) =>
			(!has(typeArg) || filterCandidateByExplicitTypeArg(commonTypes, x, force(typeArg))) &&
			testCandidateForSpecSig(ctx.instantiateCtx, x, returnAndParamTypes, TypeContext.nonInferring),
		(scope Candidate[] candidates) {
			if (candidates.length != 1) {
				// TODO: If there is a function with the name, at least indicate that in the diag
				addDiag(ctx, diagRange, candidates.length == 0
					? Diag(Diag.FunctionWithSignatureNotFound(
						name, typeContainer,
						ReturnAndParamTypes(copyArray!Type(ctx.alloc, returnAndParamTypes.returnAndParamTypes))))
					: Diag(Diag.CallMultipleMatches(name, typeContainer,
						map(ctx.alloc, candidates, (ref Candidate x) => x.called))));
				return none!Called;
			} else
				return some(checkCallAfterChoosingOverload(
					ctx, typeContainer, funsInScope, outermostFunFlags, locals,
					only(candidates), diagRange, arity, canDoUnsafe));
		});
}

private:

Expr checkOptionCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref CallAst ast,
	ref Expected outerExpected,
) =>
	checkWithModifyExpected!2(
		ctx, outerExpected,
		// For the return type:
		// The whole expression should be expected to be an option, and the call's return type is the non-optional type.
		(Type option) {
			Opt!Type res = tryUnpackOptionType(ctx.commonTypes, option);
			return has(res) ? some!(Type[2])([force(res), option]) : none!(Type[2]);
		},
		(ref Expected innerExpected) {
			Late!ExprAndType firstArg = late!ExprAndType;
			assert(ast.args.length != 0);
			ExactSizeArrayBuilder!Expr restArgs = newExactSizeArrayBuilder!Expr(ctx.alloc, ast.args.length - 1);
			Opt!Called called = checkCallCb(
				ctx, locals, ast.funName.range, ast.funName.name, none!Type, ast.args.length, innerExpected,
				(size_t index, ref Expected argExpected) {
					ExprAst* argAst = &ast.args[index];
					if (index == 0) {
						// For the first argument: It's opposite of for the return type.
						// The call is expecting a non-option, but change that to be expecting an option.
						checkWithModifyExpected!1(
							ctx, argExpected,
							(Type x) => some!(Type[1])([Type(makeOptionType(ctx.instantiateCtx, ctx.commonTypes, x))]),
							(ref Expected optionalArgExpected) {
								Expr expr = checkExpr(ctx, locals, argAst, optionalArgExpected);
								Type option = inferred(optionalArgExpected);
								lateSet(firstArg, ExprAndType(expr, option));
								// We wrapped expected types in diagnostics, so it must unpack to an option
								Type nonOption = force(tryUnpackOptionType(ctx.commonTypes, option));
								return ExprAndType(expr, nonOption);
							});
					} else
						restArgs ~= checkExpr(ctx, locals, argAst, argExpected);
				},
				(in CalledDecl _) => true,
				(scope ref Candidate[] _) => true);
			return has(called)
				? ExprAndType(
					Expr(source, ExprKind(allocate(ctx.alloc,
						CallOptionExpr(force(called), lateGet(firstArg), smallFinish(restArgs))))),
					makeOptionIfNotAlready(ctx.instantiateCtx, ctx.commonTypes, force(called).returnType))
				: ExprAndType(bogus(innerExpected, source), Type.bogus);
		}).expr;

Opt!Called checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	in Range diagRange,
	Symbol funName,
	in Opt!Type explicitTypeArg,
	scope ref PerfMeasurer perfMeasurer,
	scope ref Candidate[] candidates,
	ref Expected expected,
	size_t nArgs,
	in CbCheckArg cbCheckArg,
) =>
	withMaxStackArray!(Opt!Called, Type)(nArgs, (scope ref MaxStackArray!Type actualArgTypes) {
		bool someArgIsBogus = false;
		foreach (size_t argIdx; 0 .. nArgs) {
			if (isEmpty(candidates))
				break;

			filterUnorderedButDontRemoveAll(candidates, (ref Candidate x) =>
				preCheckCandidateSpecs(ctx, x));

			Type argType = withParamExpected(ctx.instantiateCtx, candidates, argIdx, (ref Expected argExpected) {
				pauseMeasure(ctx.perf, ctx.alloc, perfMeasurer);
				cbCheckArg(argIdx, argExpected);
				resumeMeasure(ctx.perf, ctx.alloc, perfMeasurer);
			});
			// If it failed to check, don't continue, just stop there.
			if (argType.isBogus) {
				someArgIsBogus = true;
				candidates = [];
				break;
			}
			actualArgTypes ~= argType;
			filterUnordered(candidates, (ref Candidate candidate) =>
				testCandidateParamType(ctx.instantiateCtx, candidate, argIdx, nonInferring(argType)));
		}

		if (someArgIsBogus)
			return none!Called;

		filterUnorderedButDontRemoveAll(candidates, (ref Candidate x) =>
			preCheckCandidateSpecs(ctx, x));

		if (candidates.length != 1) {
			if (isEmpty(candidates)) {
				CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(ctx, funName);
				addDiag2(ctx, diagRange, Diag(Diag.CallNoMatch(
					ctx.typeContainer,
					funName,
					getExpectedForDiag(ctx, expected),
					getNTypeArgsForDiagnostic(ctx.commonTypes, explicitTypeArg),
					nArgs,
					newArray(ctx.alloc, actualArgTypes.finish),
					allCandidates)));
			} else
				addDiag2(ctx, diagRange, Diag(
					Diag.CallMultipleMatches(funName, ctx.typeContainer, candidatesForDiag(ctx.alloc, candidates))));
			return none!Called;
		} else
			return some(checkCallAfterChoosingOverload(
				ctx.checkCtx, ctx.typeContainer, funsInExprScope(ctx), ctx.outermostFunFlags, locals,
				only(candidates), diagRange, nArgs,
				() => checkCanDoUnsafe(ctx)));
	});

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

bool filterCandidateByExplicitTypeArg(ref CommonTypes commonTypes, scope ref Candidate candidate, Type typeArg) {
	size_t nTypeParams = candidate.typeArgs.length;
	Type[] args = unpackTupleIfNeeded(commonTypes, nTypeParams, &typeArg);
	bool ok = args.length == nTypeParams;
	if (ok)
		foreach (size_t i, ref SingleInferringType x; candidate.typeArgs)
			x.setAndIgnoreExisting(args[i]);
	return ok;
}

Type withParamExpected(
	InstantiateCtx ctx,
	scope ref Candidate[] candidates,
	size_t argIdx,
	in void delegate(ref Expected) @safe @nogc pure nothrow cb,
) =>
	withMaxStackArray!(Type, TypeAndContext)(candidates.length, (ref MaxStackArray!TypeAndContext out_) {
		foreach (ref Candidate candidate; candidates) {
			TypeAndContext expected = getCandidateExpectedParameterType(ctx, candidate, argIdx);
			bool isDuplicate = !expected.context.isInferring &&
				exists!TypeAndContext(out_.soFar, (in TypeAndContext x) =>
					!x.context.isInferring && x.type == expected.type);
			if (!isDuplicate)
				out_ ~= expected;
		}
		return withExpectCandidates(out_.finish, cb);
	});

void inferCandidateTypeArgsFromCheckedSpecSig(
	InstantiateCtx ctx,
	ref const Candidate specCandidate,
	in Signature specSig,
	in ReturnAndParamTypes sigTypes,
	scope TypeContext callInferringTypeArgs,
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
TypeArgsInferenceState getInferenceState(in SingleInferringType[] typeArgs) {
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
	scope ref Candidate[] candidates,
	size_t argIndex,
	in ExprAst arg,
) =>
	arg.kind.isA!(LambdaAst*)
		? inferCandidateTypeArgsFromLambdaParameter(ctx, candidates, argIndex, arg.kind.as!(LambdaAst*).param)
		: ContinueOrAbort.continue_;

ContinueOrAbort inferCandidateTypeArgsFromLambdaParameter(
	ref ExprCtx ctx,
	scope ref Candidate[] candidates,
	size_t argIndex,
	ref DestructureAst paramAst,
) {
	// TODO: this means we may do 'typeFromDestructure' twice, once here and once when checking,
	// leading to duplicate diagnostics
	Opt!Type optLambdaParamType = typeFromDestructure(ctx, paramAst);
	if (has(optLambdaParamType)) {
		Type lambdaParamType = force(optLambdaParamType);
		if (lambdaParamType.isBogus)
			return ContinueOrAbort.abort;
		else {
			foreach (ref Candidate candidate; candidates) {
				TypeAndContext paramType = getCandidateExpectedParameterType(
					ctx.instantiateCtx, candidate, argIndex);
				inferTypeArgsFromLambdaParameterType(
					ctx.instantiateCtx, ctx.commonTypes,
					paramType.type, typeContextForCandidate(candidate),
					lambdaParamType);
			}
			return ContinueOrAbort.continue_;
		}
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
	(state != TypeArgsInferenceState.partial || zipEvery!(Signature, ReturnAndParamTypes)(
		spec.decl.sigs, spec.sigTypes, (ref Signature sig, ref ReturnAndParamTypes returnAndParamTypes) =>
			inferCandidateTypeArgsFromSpecSig(ctx, callCandidate, called, sig, returnAndParamTypes)));

bool preCheckBuiltinSpec(ref ExprCtx ctx, ref const Candidate callCandidate, in FunDecl called, in SpecInst spec) {
	if (has(spec.decl.builtin)) {
		bool checkTypeIfInferred(in bool delegate(in Type) @safe @nogc pure nothrow cb) {
			Opt!Type type = tryGetNonInferringType(
				ctx.instantiateCtx, const TypeAndContext(only(spec.typeArgs), typeContextForCandidate(callCandidate)));
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
	in Signature specSig,
	in ReturnAndParamTypes returnAndParamTypes,
) {
	TypeContext callContext = typeContextForCandidate(callCandidate);
	return withCandidates!bool(
		funsInExprScope(ctx),
		specSig.name,
		specSig.params.length,
		(ref Candidate x) =>
			testCandidateForSpecSig(ctx.instantiateCtx, x, returnAndParamTypes, callContext),
		(scope Candidate[] specCandidates) {
			switch (specCandidates.length) {
				case 0:
					return false;
				case 1:
					inferCandidateTypeArgsFromCheckedSpecSig(
						ctx.instantiateCtx, only(specCandidates), specSig, returnAndParamTypes, callContext);
					return true;
				default:
					return true;
			}
		});
}

Called checkCallAfterChoosingOverload(
	ref CheckCtx ctx,
	TypeContainer typeContainer,
	FunsInScope funsInScope,
	in FunFlags outermostFunFlags,
	in LocalsInfo locals,
	ref const Candidate candidate,
	in Range diagRange,
	size_t nArgs,
	in bool delegate() @safe @nogc pure nothrow canDoUnsafe,
) {
	Called called = checkCallSpecs(ctx, typeContainer, funsInScope, diagRange, candidate);
	checkCalled(
		ctx, diagRange, called, outermostFunFlags, locals,
		nArgs == 0 ? ArgsKind.empty : ArgsKind.nonEmpty, canDoUnsafe);
	return called;
}
