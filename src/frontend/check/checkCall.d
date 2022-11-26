module frontend.check.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, eachImportAndReExport, ImportIndex, markUsedImport;
import frontend.check.checkExpr : checkExpr;
import frontend.check.dicts : FunDeclAndIndex, ModuleLocalFunIndex;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	Expected,
	ExprCtx,
	FunOrLambdaInfo,
	inferred,
	InferringTypeArgs,
	isInLambda,
	LocalNode,
	LocalsInfo,
	markUsedLocalFun,
	matchExpectedVsReturnTypeNoDiagnostic,
	matchTypesNoDiagnostic,
	mayBeFunTypeWithArity,
	programState,
	SingleInferringType,
	tryGetInferred,
	tryGetTypeArgFromInferringTypeArgs,
	TypeAndInferring,
	typeArgsFromAsts;
import frontend.check.instantiate :
	instantiateFun, instantiateSpecInst, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray, TypeParamsAndArgs;
import frontend.parse.ast : CallAst, ExprAst, LambdaAst, NameAndRange, rangeOfNameAndRange;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	Arity,
	arity,
	arityMatches,
	body_,
	Called,
	CalledDecl,
	CommonTypes,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	FunDeclAndTypeArgs,
	FunFlags,
	isPurityAlwaysCompatible,
	isVariadic,
	NameReferents,
	Param,
	Params,
	Purity,
	purityRange,
	SpecBody,
	SpecDeclSig,
	SpecInst,
	SpecSig,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : exists, fillArrOrFail, map;
import util.col.mutMaxArr :
	copyToFrom,
	fillMutMaxArr_mut,
	filterUnordered,
	initializeMutMaxArr,
	isEmpty,
	isFull,
	mapTo,
	mapTo_mut,
	mustPop,
	MutMaxArr,
	mutMaxArr,
	mutMaxArrSize,
	only,
	push,
	pushUninitialized,
	tempAsArr,
	toArray;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : Sym;
import util.union_ : Union;
import util.util : todo;

immutable(Expr) checkCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	scope ref immutable CallAst ast,
	ref Expected expected,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.alloc, ctx.perf, PerfMeasure.checkCall);
	scope TypeArgsArray explicitTypeArgs = typeArgsFromAsts(ctx, ast.typeArgs);
	immutable Expr res = withCandidates!(immutable Expr)(
		ctx, ast.funName.name, tempAsArr(explicitTypeArgs), ast.args.length,
		(ref Candidates candidates) =>
			checkCallInner(ctx, locals, range, ast, expected, tempAsArr(explicitTypeArgs), perfMeasurer, candidates));
	endMeasure(ctx.alloc, ctx.perf, perfMeasurer);
	return res;
}

immutable(Expr) checkCallNoLocals(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	scope immutable CallAst ast,
	ref Expected expected,
) {
	FunOrLambdaInfo emptyFunInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), [], none!(ExprKind.Lambda*));
	LocalsInfo emptyLocals = LocalsInfo(ptrTrustMe(emptyFunInfo), noneMut!(LocalNode*));
	return checkCall(ctx, emptyLocals, range, ast, expected);
}

private immutable(Expr) checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	scope ref immutable CallAst ast,
	ref Expected expected,
	scope immutable Type[] explicitTypeArgs,
	ref PerfMeasurer perfMeasurer,
	ref Candidates candidates,
) {
	immutable Sym funName = ast.funName.name;
	immutable size_t arity = ast.args.length;

	foreach (immutable size_t argIdx; 0 .. arity)
		filterByLambdaArity(ctx.alloc, ctx.programState, ctx.commonTypes, candidates, ast.args[argIdx], argIdx);

	filterCandidates(candidates, (ref Candidate candidate) =>
		matchExpectedVsReturnTypeNoDiagnostic(
			ctx.alloc, ctx.programState, expected, candidate.called.returnType, inferringTypeArgs(candidate)));

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	immutable Opt!(Expr[]) args = fillArrOrFail!Expr(ctx.alloc, arity, (immutable size_t argIdx) @safe {
		if (isEmpty(candidates))
			// Already certainly failed.
			return none!Expr;

		ParamExpected paramExpected = mutMaxArr!(maxCandidates, TypeAndInferring);
		getParamExpected(ctx.alloc, ctx.programState, paramExpected, tempAsArr(candidates), argIdx);
		Expected expected = Expected(tempAsArr(castNonScope_ref(paramExpected)));

		pauseMeasure(ctx.alloc, ctx.perf, perfMeasurer);
		immutable Expr arg = checkExpr(ctx, locals, ast.args[argIdx], expected);
		resumeMeasure(ctx.alloc, ctx.perf, perfMeasurer);

		immutable Type actualArgType = inferred(expected);
		// If it failed to check, don't continue, just stop there.
		if (actualArgType.isA!(Type.Bogus)) {
			someArgIsBogus = true;
			return none!Expr;
		}
		add(ctx.alloc, actualArgTypes, actualArgType);
		filterByParamType(ctx.alloc, ctx.programState, candidates, actualArgType, argIdx);
		return some(arg);
	});

	if (someArgIsBogus)
		return bogus(expected, range);

	if (mutMaxArrSize(candidates) != 1 &&
		exists!(const Candidate)(tempAsArr(candidates), (ref const Candidate it) => candidateIsPreferred(it))) {
		filterCandidates(candidates, (ref Candidate it) => candidateIsPreferred(it));
	}

	// Show diags at the function name and not at the whole call ast
	immutable FileAndRange diagRange =
		immutable FileAndRange(range.fileIndex, rangeOfNameAndRange(ast.funName, ctx.allSymbols));

	if (!has(args) || mutMaxArrSize(candidates) != 1) {
		if (isEmpty(candidates)) {
			immutable CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(ctx, funName);
			addDiag2(ctx, diagRange, immutable Diag(immutable Diag.CallNoMatch(
				funName,
				tryGetInferred(expected),
				explicitTypeArgs.length,
				arity,
				finishArr(ctx.alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(ctx, diagRange, immutable Diag(
				immutable Diag.CallMultipleMatches(funName, candidatesForDiag(ctx.alloc, candidates))));
		return bogus(expected, range);
	} else
		return checkCallAfterChoosingOverload(ctx, isInLambda(locals), only(candidates), range, force(args), expected);
}

immutable(Expr) checkIdentifierCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	immutable Sym name,
	ref Expected expected,
) {
	//TODO:NEATER (don't make a synthetic AST, just directly call an appropriate function)
	immutable CallAst callAst =
		immutable CallAst(CallAst.Style.single, immutable NameAndRange(range.range.start, name), [], []);
	return checkCallNoLocals(ctx, range, callAst, expected);
}

struct UsedFun {
	struct None {}
	mixin Union!(immutable None, immutable ImportIndex, immutable ModuleLocalFunIndex);
}
static assert(UsedFun.sizeof <= 16);

void markUsedFun(ref ExprCtx ctx, ref immutable UsedFun used) {
	used.match!void(
		(immutable UsedFun.None) {},
		(immutable ImportIndex it) =>
			markUsedImport(ctx.checkCtx, it),
		(immutable ModuleLocalFunIndex it) =>
			markUsedLocalFun(ctx, it));
}

void eachFunInScope(
	ref ExprCtx ctx,
	immutable Sym funName,
	scope void delegate(immutable UsedFun, immutable CalledDecl) @safe @nogc pure nothrow cb,
) {
	size_t totalIndex = 0;
	foreach (immutable SpecInst* specInst; ctx.outermostFunSpecs)
		specInst.body_.match!void(
			(immutable SpecBody.Builtin) {},
			(immutable SpecDeclSig[] sigs) {
				foreach (immutable size_t i, ref immutable SpecDeclSig sig; sigs)
					if (sig.name == funName) {
						cb(immutable UsedFun(immutable UsedFun.None()), immutable CalledDecl(
							immutable SpecSig(specInst, &sigs[i], totalIndex + i)));
					}
				totalIndex += sigs.length;
			});

	foreach (ref immutable FunDeclAndIndex f; ctx.funsDict[funName])
		cb(immutable UsedFun(f.index), immutable CalledDecl(f.decl));

	eachImportAndReExport(ctx.checkCtx, funName, (immutable ImportIndex index, ref immutable NameReferents it) {
		foreach (immutable FunDecl* f; it.funs)
			cb(immutable UsedFun(index), immutable CalledDecl(f));
	});
}

private:

immutable size_t maxCandidates = 64;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);
alias ParamExpected = MutMaxArr!(maxCandidates, TypeAndInferring);

immutable(CalledDecl[]) candidatesForDiag(ref Alloc alloc, ref const Candidates candidates) =>
	map(alloc, tempAsArr(candidates), (ref const Candidate c) => c.called);

immutable(bool) candidateIsPreferred(ref const Candidate a) =>
	a.called.match!(immutable bool)(
		(ref immutable FunDecl x) =>
			x.flags.preferred,
		(immutable SpecSig) =>
			false);

struct Candidate {
	immutable UsedFun used;
	immutable CalledDecl called;
	// Note: this is always empty if calling a SpecSig
	MutMaxArr!(16, SingleInferringType) typeArgs;
}
void initializeCandidate(ref Candidate a, immutable UsedFun used, immutable CalledDecl called) {
	overwriteMemory(&a.used, used);
	overwriteMemory(&a.called, called);
	initializeMutMaxArr(a.typeArgs);
}
void overwriteCandidate(ref Candidate a, ref const Candidate b) {
	overwriteMemory(&a.used, b.used);
	overwriteMemory(&a.called, b.called);
	copyToFrom(a.typeArgs, b.typeArgs);
}

inout(InferringTypeArgs) inferringTypeArgs(return ref inout Candidate a) =>
	inout InferringTypeArgs(a.called.typeParams, tempAsArr(a.typeArgs));

immutable(T) withCandidates(T)(
	ref ExprCtx ctx,
	immutable Sym funName,
	scope immutable Type[] explicitTypeArgs,
	immutable size_t actualArity,
	scope immutable(T) delegate(ref Candidates) @safe @nogc pure nothrow cb,
) {
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate);
	getInitialCandidates(ctx, candidates, funName, explicitTypeArgs, actualArity);
	return cb(candidates);
}

void getInitialCandidates(
	ref ExprCtx ctx,
	scope ref Candidates candidates,
	immutable Sym funName,
	scope immutable Type[] explicitTypeArgs,
	immutable size_t actualArity,
) {
	eachFunInScope(ctx, funName, (immutable UsedFun used, immutable CalledDecl called) @trusted {
		immutable size_t nTypeParams = called.typeParams.length;
		immutable bool typeArgsMatch = empty(explicitTypeArgs) || nTypeParams == explicitTypeArgs.length;
		if (arityMatches(arity(called), actualArity) && typeArgsMatch) {
			Candidate* candidate = pushUninitialized(candidates);
			initializeCandidate(*candidate, used, called);
			if (empty(explicitTypeArgs))
				fillMutMaxArr_mut(candidate.typeArgs, nTypeParams, () => SingleInferringType(none!Type));
			else
				mapTo_mut!(16, SingleInferringType, Type)(
					candidate.typeArgs,
					explicitTypeArgs,
					(scope ref immutable Type explicitTypeArg) =>
						SingleInferringType(some!Type(explicitTypeArg)));
		}
	});
}

immutable(CalledDecl[]) getAllCandidatesAsCalledDecls(ref ExprCtx ctx, immutable Sym funName) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(ctx, funName, (immutable UsedFun, immutable CalledDecl called) {
		add(ctx.alloc, res, called);
	});
	return finishArr(ctx.alloc, res);
}

immutable(Type) getCandidateExpectedParameterTypeRecur(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	immutable Type candidateParamType,
) =>
	candidateParamType.matchWithPointers!(immutable Type)(
		(immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable TypeParam* p) {
			const InferringTypeArgs ita = inferringTypeArgs(candidate);
			const Opt!(SingleInferringType*) sit = tryGetTypeArgFromInferringTypeArgs(ita, p);
			immutable Opt!Type inferred = has(sit) ? tryGetInferred(*force(sit)) : none!Type;
			return has(inferred) ? force(inferred) : immutable Type(p);
		},
		(immutable StructInst* i) {
			scope TypeArgsArray outTypeArgs = typeArgsArray();
			mapTo(outTypeArgs, typeArgs(*i), (ref immutable Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return immutable Type(
				instantiateStructNeverDelay(alloc, programState, decl(*i), tempAsArr(outTypeArgs)));
		});

immutable(Type) getCandidateExpectedParameterType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	immutable size_t argIdx,
) =>
	getCandidateExpectedParameterTypeRecur(
		alloc,
		programState,
		candidate,
		paramTypeAt(candidate.called.params, argIdx));

immutable(Type) paramTypeAt(scope immutable Params params, immutable size_t argIdx) =>
	params.match!(immutable Type)(
		(immutable Param[] x) =>
			x[argIdx].type,
		(ref immutable Params.Varargs x) =>
			x.elementType);

void getParamExpected(
	ref Alloc alloc,
	ref ProgramState programState,
	ref ParamExpected paramExpected,
	Candidate[] candidates,
	immutable size_t argIdx,
) {
	foreach (ref Candidate candidate; candidates) {
		immutable Type t = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		immutable bool isDuplicate = ita.args.length == 0 &&
			exists!(const TypeAndInferring)(tempAsArr(paramExpected), (scope ref const TypeAndInferring x) =>
				x.type == t);
		if (!isDuplicate)
			paramExpected.push(TypeAndInferring(t, ita));
	}
}

immutable(Opt!(Diag.CantCall.Reason)) getCantCallReason(
	immutable bool calledIsVariadicNonEmpty,
	immutable FunFlags calledFlags,
	immutable FunFlags callerFlags,
	immutable bool callerInLambda,
) =>
	!calledFlags.noCtx && callerFlags.noCtx && !callerInLambda
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.safety == FunFlags.Safety.unsafe && callerFlags.safety == FunFlags.Safety.safe
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.noCtx
		? some(Diag.CantCall.Reason.variadicFromNoctx)
		: none!(Diag.CantCall.Reason);

enum ArgsKind { empty, nonEmpty }

void checkCallFlags(
	ref CheckCtx ctx,
	immutable FileAndRange range,
	immutable FunDecl* called,
	immutable FunFlags caller,
	immutable bool callerInLambda,
	immutable ArgsKind argsKind,
) {
	immutable Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		isVariadic(*called) && argsKind == ArgsKind.nonEmpty,
		called.flags,
		caller,
		callerInLambda);
	if (has(reason))
		addDiag(ctx, range, immutable Diag(Diag.CantCall(force(reason), called)));
}

void checkCalledDeclFlags(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	ref immutable CalledDecl res,
	immutable FileAndRange range,
	immutable ArgsKind argsKind,
) {
	res.matchWithPointers!void(
		(immutable FunDecl* f) @safe {
			checkCallFlags(ctx.checkCtx, range, f, ctx.outermostFunFlags, isInLambda, argsKind);
		},
		// For a spec, we check the flags when providing the spec impl
		(immutable SpecSig) {});
}

void filterByReturnTypeForSpec(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref Candidates candidates,
	immutable Type expectedReturnType,
) {
	// Filter by return type. Also does type argument inference on the candidate.
	filterCandidates(candidates, (ref Candidate candidate) =>
		matchTypesNoDiagnostic(
			alloc, programState, candidate.called.returnType, inferringTypeArgs(candidate), expectedReturnType));
}

void filterByLambdaArity(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable CommonTypes commonTypes,
	ref Candidates candidates,
	scope ref immutable ExprAst arg,
	immutable size_t argIdx,
) {
	if (arg.kind.isA!(LambdaAst*)) {
		immutable size_t arity = arg.kind.as!(LambdaAst*).params.length;
		filterCandidates(candidates, (ref Candidate candidate) {
			immutable Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
			return mayBeFunTypeWithArity(commonTypes, expectedArgType, inferringTypeArgs(candidate), arity);
		});
	}
}

void filterByParamType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref Candidates candidates,
	immutable Type actualArgType,
	immutable size_t argIdx,
) {
	// Remove candidates that can't accept this as a param. Also does type argument inference on the candidate.
	filterCandidates(candidates, (ref Candidate candidate) {
		immutable Type paramType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		return matchTypesNoDiagnostic(alloc, programState, paramType, inferringTypeArgs(candidate), actualArgType);
	});
}

immutable(Opt!Called) findSpecSigImplementation(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	immutable FileAndRange range,
	ref immutable SpecDeclSig specSig,
	ref SpecTrace trace,
) {
	immutable size_t nParams = arity(specSig).match!(immutable size_t)(
		(immutable size_t n) =>
			n,
		(immutable Arity.Varargs) =>
			todo!(immutable size_t)("varargs in spec?"));
	return withCandidates(ctx, specSig.name, [], nParams, (ref Candidates candidates) {
		filterByReturnTypeForSpec(ctx.alloc, ctx.programState, candidates, specSig.returnType);
		foreach (immutable size_t argIdx; 0 .. nParams)
			filterByParamType(ctx.alloc, ctx.programState, candidates, paramTypeAt(specSig.params, argIdx), argIdx);

		// If any candidates left take specs -- leave as a TODO
		switch (mutMaxArrSize(candidates)) {
			case 0:
				// TODO: use initial candidates in the error message
				addDiag2(ctx, range, immutable Diag(
					immutable Diag.SpecImplNotFound(specSig, toArray(ctx.alloc, trace))));
				return none!Called;
			case 1:
				return getCalledFromCandidate(ctx, isInLambda, range, only(candidates), ArgsKind.nonEmpty, trace);
			default:
				addDiag2(ctx, range, immutable Diag(
					immutable Diag.SpecImplFoundMultiple(specSig.name, candidatesForDiag(ctx.alloc, candidates))));
				return none!Called;
		}
	});
}

// See if e.g. 'data<?t>' is declared on this function.
immutable(bool) findBuiltinSpecOnType(
	ref ExprCtx ctx,
	immutable SpecBody.Builtin.Kind kind,
	immutable Type type,
) =>
	exists!(immutable SpecInst*)(ctx.outermostFunSpecs, (ref immutable SpecInst* inst) =>
		inst.body_.match!(immutable bool)(
			(immutable SpecBody.Builtin b) =>
				b.kind == kind && only(typeArgs(*inst)) == type,
			(immutable SpecDeclSig[]) =>
				//TODO: might inherit from builtin spec?
				false));

immutable(bool) checkBuiltinSpec(
	ref ExprCtx ctx,
	immutable FunDecl* called,
	immutable FileAndRange range,
	immutable SpecBody.Builtin.Kind kind,
	immutable Type typeArg,
) {
	immutable bool typeIsGood = () {
		final switch (kind) {
			case SpecBody.Builtin.Kind.data:
				return isPurityAlwaysCompatible(Purity.data, purityRange(typeArg));
			case SpecBody.Builtin.Kind.send:
				return isPurityAlwaysCompatible(Purity.sendable, purityRange(typeArg));
		}
	}() || findBuiltinSpecOnType(ctx, kind, typeArg);
	if (!typeIsGood)
		addDiag2(ctx, range, immutable Diag(immutable Diag.SpecBuiltinNotSatisfied(kind, typeArg, called)));
	return typeIsGood;
}

immutable size_t maxSpecImpls = 16;
immutable size_t maxSpecDepth = 8;

alias SpecImpls = MutMaxArr!(maxSpecImpls, immutable Called);
alias SpecTrace = MutMaxArr!(maxSpecDepth, immutable FunDeclAndTypeArgs);

// On failure, returns false
immutable(bool) checkSpecImpls(
	ref SpecImpls res,
	ref ExprCtx ctx,
	immutable bool isInLambda,
	immutable FileAndRange range,
	immutable FunDecl* called,
	immutable Type[] calledTypeArgs,
	ref SpecTrace trace,
) {
	foreach (immutable SpecInst* specInst; called.specs) {
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		immutable SpecInst* specInstInstantiated = instantiateSpecInst(
			ctx.alloc, ctx.programState, specInst, immutable TypeParamsAndArgs(called.typeParams, calledTypeArgs));
		immutable Type[] typeArgs = typeArgs(*specInstInstantiated);
		immutable bool ok = specInstInstantiated.body_.match!(immutable bool)(
			(immutable SpecBody.Builtin b) =>
				checkBuiltinSpec(ctx, called, range, b.kind, only(typeArgs)),
			(immutable SpecDeclSig[] sigs) {
				immutable FunDeclAndTypeArgs fa = immutable FunDeclAndTypeArgs(called, typeArgs);
				push(trace, fa);
				foreach (ref immutable SpecDeclSig sig; sigs) {
					immutable Opt!Called impl = findSpecSigImplementation(ctx, isInLambda, range, sig, trace);
					if (!has(impl))
						return false;
					push(res, force(impl));
				}
				mustPop(trace);
				return true;
			});
		if (!ok)
			return false;
	}
	return true;
}

immutable(Opt!Called) getCalledFromCandidate(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	immutable FileAndRange range,
	ref const Candidate candidate,
	immutable ArgsKind argsKind,
	ref SpecTrace trace,
) {
	markUsedFun(ctx, candidate.used);
	checkCalledDeclFlags(ctx, isInLambda, candidate.called, range, argsKind);

	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; tempAsArr(candidate.typeArgs)) {
		immutable Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else {
			addDiag2(ctx, range, immutable Diag(Diag.CantInferTypeArguments()));
			return none!Called;
		}
	}
	return candidate.called.matchWithPointers!(immutable Opt!Called)(
		(immutable FunDecl* f) {
			if (isFull(trace)) {
				addDiag2(ctx, range, immutable Diag(immutable Diag.SpecImplTooDeep(toArray(ctx.alloc, trace))));
				return none!Called;
			} else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, immutable Called);
				return checkSpecImpls(specImpls, ctx, isInLambda, range, f, tempAsArr(candidateTypeArgs), trace)
					? some(immutable Called(
						instantiateFun(
							ctx.alloc,
							ctx.programState,
							f,
							tempAsArr(candidateTypeArgs),
							tempAsArr(specImpls))))
					: none!Called;
			}
		},
		(immutable SpecSig s) =>
			some(immutable Called(allocate(ctx.alloc, s))));
}

immutable(Expr) checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	ref const Candidate candidate,
	immutable FileAndRange range,
	immutable Expr[] args,
	ref Expected expected,
) {
	SpecTrace trace = mutMaxArr!(maxSpecDepth, immutable FunDeclAndTypeArgs);
	immutable Opt!Called opCalled = getCalledFromCandidate(
		ctx, isInLambda, range, candidate, empty(args) ? ArgsKind.empty : ArgsKind.nonEmpty, trace);
	if (has(opCalled)) {
		immutable Called called = force(opCalled);
		immutable Expr calledExpr = immutable Expr(range, immutable ExprKind(immutable ExprKind.Call(called, args)));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(ctx, expected, called.returnType, calledExpr);
	} else
		return bogus(expected, range);
}

void filterCandidates(
	scope ref Candidates candidates,
	scope immutable(bool) delegate(ref Candidate) @safe @nogc pure nothrow pred,
) {
	filterUnordered!(maxCandidates, Candidate)(candidates, pred, (ref Candidate a, ref const Candidate b) =>
		overwriteCandidate(a, b));
}
