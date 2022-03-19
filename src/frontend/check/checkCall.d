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
	matchTypesNoDiagnostic,
	programState,
	SingleInferringType,
	tryGetDeeplyInstantiatedType,
	tryGetInferred,
	tryGetTypeArgFromInferringTypeArgs_const,
	typeArgsFromAsts;
import frontend.check.instantiate :
	instantiateFun, instantiateSpecInst, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray, TypeParamsAndArgs;
import frontend.parse.ast : CallAst, ExprAst, NameAndRange, rangeOfNameAndRange, TypeAst;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	Arity,
	arity,
	arityMatches,
	body_,
	Called,
	CalledDecl,
	decl,
	Expr,
	FunDecl,
	FunFlags,
	isBogus,
	isPurityAlwaysCompatible,
	isVariadic,
	matchArity,
	matchCalledDecl,
	matchParams,
	matchSpecBody,
	matchType,
	Module,
	NameReferents,
	Param,
	Params,
	params,
	Purity,
	purityRange,
	returnType,
	sig,
	Sig,
	SpecBody,
	SpecDeclSig,
	SpecInst,
	SpecSig,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, only_const, ptrAt;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : exists, exists_const, fillArrOrFail, map_const;
import util.col.mutMaxArr :
	copyToFrom,
	fillMutMaxArr_mut,
	filterUnordered,
	initializeMutMaxArr,
	isEmpty,
	mapTo,
	mapTo_mut,
	MutMaxArr,
	mutMaxArr,
	mutMaxArrSize,
	only_const,
	push,
	pushUninitialized,
	tempAsArr,
	tempAsArr_const,
	tempAsArr_mut;
import util.memory : overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : Sym, symEq;
import util.util : Empty, todo;

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
	scope ref immutable CallAst ast,
	ref Expected expected,
) {
	FunOrLambdaInfo emptyFunInfo =
		FunOrLambdaInfo(noneMut!(Ptr!LocalsInfo), emptyArr!Param, none!(Ptr!(Expr.Lambda)));
	LocalsInfo emptyLocals = LocalsInfo(ptrTrustMe_mut(emptyFunInfo), noneMut!(Ptr!LocalNode));
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

	// TODO: may not need to be deeply instantiated to do useful filtering here
	immutable Opt!Type expectedReturnType = tryGetDeeplyInstantiatedType(ctx.alloc, ctx.programState, expected);
	if (has(expectedReturnType))
		filterByReturnType(ctx.alloc, ctx.programState, candidates, force(expectedReturnType));

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	immutable Opt!(Expr[]) args = fillArrOrFail!Expr(ctx.alloc, arity, (immutable size_t argIdx) @safe {
		if (isEmpty(candidates))
			// Already certainly failed.
			return none!Expr;

		CommonOverloadExpected common =
			getCommonOverloadParamExpected(ctx.alloc, ctx.programState, tempAsArr_mut(candidates), argIdx);
		pauseMeasure(ctx.alloc, ctx.perf, perfMeasurer);
		immutable Expr arg = checkExpr(ctx, locals, ast.args[argIdx], common.expected);
		resumeMeasure(ctx.alloc, ctx.perf, perfMeasurer);

		immutable Type actualArgType = inferred(common.expected);
		// If it failed to check, don't continue, just stop there.
		if (isBogus(actualArgType)) {
			someArgIsBogus = true;
			return none!Expr;
		}
		add(ctx.alloc, actualArgTypes, actualArgType);
		// If the Inferring already came from the candidate, no need to do more work.
		if (!common.isExpectedFromCandidate)
			filterByParamType(ctx.alloc, ctx.programState, candidates, actualArgType, argIdx);
		return some(arg);
	});

	if (someArgIsBogus)
		return bogus(expected, range);

	if (mutMaxArrSize(candidates) != 1 &&
		exists_const!Candidate(tempAsArr_const(candidates), (ref const Candidate it) => candidateIsPreferred(it))) {
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
				expectedReturnType,
				explicitTypeArgs.length,
				arity,
				finishArr(ctx.alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(ctx, diagRange, immutable Diag(
				immutable Diag.CallMultipleMatches(funName, candidatesForDiag(ctx.alloc, candidates))));
		return bogus(expected, range);
	} else
		return checkCallAfterChoosingOverload(
			ctx, isInLambda(locals), only_const(candidates), range, force(args), expected);
}

immutable(Expr) checkIdentifierCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	immutable Sym name,
	ref Expected expected,
) {
	//TODO:NEATER (don't make a synthetic AST, just directly call an appropriate function)
	immutable CallAst callAst = immutable CallAst(
		CallAst.Style.single,
		immutable NameAndRange(range.range.start, name),
		emptyArr!TypeAst,
		emptyArr!ExprAst);
	return checkCallNoLocals(ctx, range, callAst, expected);
}

struct UsedFun {
	@safe @nogc pure nothrow:

	immutable this(immutable ImportIndex a) { kind = Kind.import_; import_ = a; }
	immutable this(immutable ModuleLocalFunIndex a) { kind = Kind.moduleLocal; moduleLocal = a; }

	private:
	enum Kind {
		import_,
		moduleLocal,
	}
	immutable Kind kind;
	union {
		immutable ImportIndex import_;
		immutable ModuleLocalFunIndex moduleLocal;
	}
}

private T matchUsedFun(T)(
	ref immutable UsedFun a,
	scope T delegate(immutable ImportIndex) @safe @nogc pure nothrow cbImport,
	scope T delegate(immutable ModuleLocalFunIndex) @safe @nogc pure nothrow cbModuleLocal,
) {
	final switch (a.kind) {
		case UsedFun.Kind.import_:
			return cbImport(a.import_);
		case UsedFun.Kind.moduleLocal:
			return cbModuleLocal(a.moduleLocal);
	}
}

void markUsedFun(ref ExprCtx ctx, ref immutable UsedFun used) {
	matchUsedFun!void(
		used,
		(immutable ImportIndex it) =>
			markUsedImport(ctx.checkCtx, it),
		(immutable ModuleLocalFunIndex it) =>
			markUsedLocalFun(ctx, it));
}

void eachFunInScope(
	ref ExprCtx ctx,
	immutable Sym funName,
	scope void delegate(ref immutable Opt!UsedFun, immutable CalledDecl) @safe @nogc pure nothrow cb,
) {
	size_t totalIndex = 0;
	foreach (immutable Ptr!SpecInst specInst; ctx.outermostFunSpecs)
		matchSpecBody!void(
			specInst.deref().body_,
			(immutable SpecBody.Builtin) {},
			(immutable SpecDeclSig[] sigs) {
				foreach (immutable size_t i, ref immutable SpecDeclSig sig; sigs)
					if (symEq(sig.sig.name, funName)) {
						immutable Opt!UsedFun used = none!UsedFun;
						cb(used, immutable CalledDecl(immutable SpecSig(specInst, ptrAt(sigs, i), totalIndex + i)));
					}
				totalIndex += sigs.length;
			});

	foreach (ref immutable FunDeclAndIndex f; ctx.funsDict[funName]) {
		immutable Opt!UsedFun used = some(immutable UsedFun(f.index));
		cb(used, immutable CalledDecl(f.decl));
	}

	eachImportAndReExport!Empty(
		ctx.checkCtx,
		funName,
		immutable Empty(),
		(immutable(Empty), immutable Ptr!Module, immutable ImportIndex index, ref immutable NameReferents it) {
			foreach (immutable Ptr!FunDecl f; it.funs) {
				immutable Opt!UsedFun used = some(immutable UsedFun(index));
				cb(used, immutable CalledDecl(f));
			}
			return immutable Empty();
		});
}

private:

immutable size_t maxCandidates = 64;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);

immutable(CalledDecl[]) candidatesForDiag(ref Alloc alloc, ref const Candidates candidates) {
	return map_const!(CalledDecl, Candidate)(alloc, tempAsArr_const(candidates), (ref const Candidate c) =>
		c.called);
}

immutable(bool) candidateIsPreferred(ref const Candidate a) {
	return matchCalledDecl!(
		immutable bool,
		(immutable Ptr!FunDecl it) =>
			it.deref().flags.preferred,
		(ref immutable SpecSig) =>
			false,
	)(a.called);
}

struct Candidate {
	immutable Opt!UsedFun used;
	immutable CalledDecl called;
	// Note: this is always empty if calling a SpecSig
	MutMaxArr!(16, SingleInferringType) typeArgs;
}
void initializeCandidate(ref Candidate a, immutable Opt!UsedFun used, immutable CalledDecl called) {
	overwriteMemory(&a.used, used);
	overwriteMemory(&a.called, called);
	initializeMutMaxArr(a.typeArgs);
}
void overwriteCandidate(ref Candidate a, ref const Candidate b) {
	overwriteMemory(&a.used, b.used);
	overwriteMemory(&a.called, b.called);
	copyToFrom(a.typeArgs, b.typeArgs);
}

InferringTypeArgs inferringTypeArgs(return ref Candidate a) {
	return InferringTypeArgs(typeParams(a.called), tempAsArr_mut(a.typeArgs));
}
const(InferringTypeArgs) inferringTypeArgs_const(return ref const Candidate a) {
	return const InferringTypeArgs(typeParams(a.called), tempAsArr_const(a.typeArgs));
}

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
	eachFunInScope(ctx, funName, (ref immutable Opt!UsedFun used, immutable CalledDecl called) @trusted {
		immutable size_t nTypeParams = typeParams(called).length;
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
	eachFunInScope(ctx, funName, (ref immutable Opt!UsedFun, immutable CalledDecl called) {
		add(ctx.alloc, res, called);
	});
	return finishArr(ctx.alloc, res);
}

immutable(Type) getCandidateExpectedParameterTypeRecur(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	immutable Type candidateParamType,
) {
	return matchType!(immutable Type)(
		candidateParamType,
		(immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable Ptr!TypeParam p) @safe {
			const InferringTypeArgs ita = inferringTypeArgs_const(candidate);
			const Opt!(Ptr!SingleInferringType) sit = tryGetTypeArgFromInferringTypeArgs_const(ita, p);
			immutable Opt!Type inferred = has(sit) ? tryGetInferred(force(sit).deref()) : none!Type;
			return has(inferred) ? force(inferred) : immutable Type(p);
		},
		(immutable Ptr!StructInst i) @safe {
			scope TypeArgsArray typeArgs = typeArgsArray();
			mapTo(typeArgs, i.deref().typeArgs, (ref immutable Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return immutable Type(
				instantiateStructNeverDelay(alloc, programState, i.deref().decl, tempAsArr(typeArgs)));
		});
}

immutable(Type) getCandidateExpectedParameterType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	immutable size_t argIdx,
) {
	return getCandidateExpectedParameterTypeRecur(
		alloc,
		programState,
		candidate,
		paramTypeAt(params(candidate.called), argIdx));
}

immutable(Type) paramTypeAt(ref immutable Params params, immutable size_t argIdx) {
	return matchParams!(immutable Type)(
		params,
		(immutable Param[] params) =>
			params[argIdx].type,
		(ref immutable Params.Varargs varargs) =>
			varargs.elementType);
}

struct CommonOverloadExpected {
	Expected expected;
	immutable bool isExpectedFromCandidate;
}

// For multiple candidates, only have an expected type if they have exactly the same param type
Expected getCommonOverloadParamExpectedForMultipleCandidates(
	ref Alloc alloc,
	ref ProgramState programState,
	scope const Candidate[] candidates,
	immutable size_t argIdx,
	immutable Opt!Type expected,
) {
	if (empty(candidates))
		return Expected(expected);
	else {
		// If we get a template candidate and haven't inferred this param type yet, no expected type.
		immutable Type paramType = getCandidateExpectedParameterType(alloc, programState, candidates[0], argIdx);
		return has(expected) && !typeEquals(paramType, force(expected))
			// Only get an expected type if all candidates expect it.
			? Expected.infer()
			: getCommonOverloadParamExpectedForMultipleCandidates(
				alloc,
				programState,
				candidates[1 .. $],
				argIdx,
				some(paramType));
	}
}

CommonOverloadExpected getCommonOverloadParamExpected(
	ref Alloc alloc,
	ref ProgramState programState,
	Candidate[] candidates,
	immutable size_t argIdx,
) {
	switch (candidates.length) {
		case 0:
			return CommonOverloadExpected(Expected.infer(), false);
		case 1:
			return CommonOverloadExpected(
				Expected(
					some(getCandidateExpectedParameterType(alloc, programState, candidates[0], argIdx)),
					inferringTypeArgs(candidates[0])),
				true);
		default:
			return CommonOverloadExpected(
				getCommonOverloadParamExpectedForMultipleCandidates(alloc, programState, candidates, argIdx, none!Type),
				false);
	}
}

immutable(Opt!(Diag.CantCall.Reason)) getCantCallReason(
	immutable bool calledIsVariadicNonEmpty,
	immutable FunFlags calledFlags,
	immutable FunFlags callerFlags,
	immutable bool callerInLambda,
) {
	return !calledFlags.noCtx && callerFlags.noCtx && !callerInLambda
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.unsafe && !callerFlags.trusted && !callerFlags.unsafe
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.noCtx
		? some(Diag.CantCall.Reason.variadicFromNoctx)
		: none!(Diag.CantCall.Reason);
}

enum ArgsKind { empty, nonEmpty }

void checkCallFlags(
	ref CheckCtx ctx,
	immutable FileAndRange range,
	immutable Ptr!FunDecl called,
	immutable FunFlags caller,
	immutable bool callerInLambda,
	immutable ArgsKind argsKind,
) {
	immutable Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		isVariadic(called.deref()) && argsKind == ArgsKind.nonEmpty,
		called.deref().flags,
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
	matchCalledDecl!(
		void,
		(immutable Ptr!FunDecl f) {
			checkCallFlags(ctx.checkCtx, range, f, ctx.outermostFunFlags, isInLambda, argsKind);
		},
		(ref immutable SpecSig) {
			// For a spec, we check the flags when providing the spec impl
		},
	)(res);
}

void filterByReturnType(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref Candidates candidates,
	immutable Type expectedReturnType,
) {
	// Filter by return type. Also does type argument inference on the candidate.
	filterCandidates(candidates, (ref Candidate candidate) {
		InferringTypeArgs ta = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic(alloc, programState, returnType(candidate.called), expectedReturnType, ta);
	});
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
		immutable Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic(alloc, programState, expectedArgType, actualArgType, ita);
	});
}

immutable(Opt!Called) findSpecSigImplementation(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	immutable FileAndRange range,
	ref immutable Sig specSig,
	immutable Ptr!FunDecl outerCalled,
) {
	immutable size_t nParams = matchArity!(
		immutable size_t,
		(immutable size_t n) =>
			n,
		(ref immutable Arity.Varargs) =>
			todo!(immutable size_t)("varargs in spec?"),
	)(arity(specSig));
	return withCandidates(ctx, specSig.name, [], nParams, (ref Candidates candidates) {
		filterByReturnType(ctx.alloc, ctx.programState, candidates, specSig.returnType);
		foreach (immutable size_t argIdx; 0 .. nParams)
			filterByParamType(ctx.alloc, ctx.programState, candidates, paramTypeAt(specSig.params, argIdx), argIdx);

		// If any candidates left take specs -- leave as a TODO
		switch (mutMaxArrSize(candidates)) {
			case 0:
				// TODO: use initial candidates in the error message
				addDiag2(ctx, range, immutable Diag(immutable Diag.SpecImplNotFound(specSig.name)));
				return none!Called;
			case 1:
				return getCalledFromCandidate(
					ctx, isInLambda, range, only_const(candidates), some(outerCalled), ArgsKind.nonEmpty);
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
) {
	return exists!(Ptr!SpecInst)(ctx.outermostFunSpecs, (ref immutable Ptr!SpecInst inst) =>
		matchSpecBody!(immutable bool)(
			inst.deref().body_,
			(immutable SpecBody.Builtin b) =>
				b.kind == kind && typeEquals(only(inst.deref().typeArgs), type),
			(immutable SpecDeclSig[]) =>
				//TODO: might inherit from builtin spec?
				false));
}

immutable(bool) checkBuiltinSpec(
	ref ExprCtx ctx,
	immutable Ptr!FunDecl called,
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

// On failure, returns false
immutable(bool) checkSpecImpls(
	ref MutMaxArr!(maxSpecImpls, Called) res,
	ref ExprCtx ctx,
	immutable bool isInLambda,
	immutable FileAndRange range,
	immutable Ptr!FunDecl called,
	immutable Type[] typeArgz,
	immutable Opt!(Ptr!FunDecl) outerCalled,
) {
	foreach (immutable Ptr!SpecInst specInst; called.deref().specs) {
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		immutable TypeParamsAndArgs tpa = immutable TypeParamsAndArgs(called.deref().typeParams, typeArgz);
		immutable Ptr!SpecInst specInstInstantiated = instantiateSpecInst(ctx.alloc, ctx.programState, specInst, tpa);
		immutable bool ok = matchSpecBody!(immutable bool)(
			specInstInstantiated.deref().body_,
			(immutable SpecBody.Builtin b) =>
				checkBuiltinSpec(ctx, called, range, b.kind, only(typeArgs(specInstInstantiated.deref()))),
			(immutable SpecDeclSig[] sigs) {
				foreach (ref immutable SpecDeclSig sig; sigs) {
					if (has(outerCalled)) {
						addDiag2(ctx, range, immutable Diag(
							immutable Diag.SpecImplHasSpecs(force(outerCalled), called)));
						return false;
					}
					immutable Opt!Called impl = findSpecSigImplementation(ctx, isInLambda, range, sig.sig, called);
					if (!has(impl))
						return false;
					push(res, force(impl));
				}
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
	immutable Opt!(Ptr!FunDecl) outerCalled,
	immutable ArgsKind argsKind,
) {
	if (has(candidate.used))
		markUsedFun(ctx, force(candidate.used));
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
	return matchCalledDecl!(
		immutable Opt!Called,
		(immutable Ptr!FunDecl f) {
			MutMaxArr!(maxSpecImpls, Called) specImpls = mutMaxArr!(maxSpecImpls, Called);
			return checkSpecImpls(specImpls, ctx, isInLambda, range, f, tempAsArr(candidateTypeArgs), outerCalled)
				? some(immutable Called(
					instantiateFun(
						ctx.alloc,
						ctx.programState,
						f,
						tempAsArr(candidateTypeArgs),
						tempAsArr(specImpls))))
				: none!Called;
		},
		(ref immutable SpecSig s) =>
			some(immutable Called(s)),
	)(candidate.called);
}

immutable(Expr) checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	immutable bool isInLambda,
	ref const Candidate candidate,
	immutable FileAndRange range,
	immutable Expr[] args,
	ref Expected expected,
) {
	immutable Opt!Called opCalled = getCalledFromCandidate(
		ctx, isInLambda, range, candidate, none!(Ptr!FunDecl),
		empty(args) ? ArgsKind.empty : ArgsKind.nonEmpty);
	if (has(opCalled)) {
		immutable Called called = force(opCalled);
		immutable Expr calledExpr = immutable Expr(range, Expr.Call(called, args));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(ctx, expected, returnType(called), calledExpr);
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
