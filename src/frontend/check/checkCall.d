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
	inferred,
	InferringTypeArgs,
	markUsedLocalFun,
	matchTypesNoDiagnostic,
	programState,
	SingleInferringType,
	tryGetDeeplyInstantiatedType,
	tryGetInferred,
	tryGetTypeArgFromInferringTypeArgs_const,
	typeArgsFromAsts;
import frontend.check.instantiate : instantiateFun, instantiateSpecInst, instantiateStructNeverDelay, TypeParamsAndArgs;
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
	FunDeclAndArgs,
	FunFlags,
	isPurityAlwaysCompatible,
	isVariadic,
	matchArity,
	matchCalledDecl,
	matchParams,
	matchSpecBody,
	matchType,
	Module,
	NameReferents,
	nSigs,
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
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	typeIsBogus,
	TypeParam,
	typeParams;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, only_const, ptrAt;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil :
	exists,
	exists_const,
	fillArr_mut,
	fillArrOrFail,
	map,
	map_const,
	mapOrNone_const,
	sum;
import util.col.mutArr : moveToArr, MutArr, newUninitializedMutArr, peek;
import util.col.mutMaxArr :
	filterUnordered,
	isEmpty,
	MutMaxArr,
	mutMaxArr,
	mutMaxArrSize,
	only_const,
	push,
	tempAsArr_const,
	tempAsArr_mut;
import util.opt : force, has, none, Opt, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : Sym, symEq;
import util.util : Empty, todo, verify;

immutable(Expr) checkCall(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable CallAst ast,
	ref Expected expected,
) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.alloc, ctx.perf, PerfMeasure.checkCall);
	immutable Sym funName = ast.funName.name;
	immutable size_t arity = ast.args.length;
	immutable Type[] explicitTypeArgs = typeArgsFromAsts(ctx, ast.typeArgs);
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate);
	getInitialCandidates(ctx, candidates, funName, explicitTypeArgs, arity);

	// TODO: may not need to be deeply instantiated to do useful filtering here
	immutable Opt!Type expectedReturnType = tryGetDeeplyInstantiatedType(ctx.alloc, ctx.programState, expected);
	if (has(expectedReturnType))
		filterByReturnType(ctx.alloc, ctx.programState, candidates, force(expectedReturnType));

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	immutable Opt!(Expr[]) args = fillArrOrFail!Expr(ctx.alloc, arity, (immutable size_t argIdx) {
		if (isEmpty(candidates))
			// Already certainly failed.
			return none!Expr;

		CommonOverloadExpected common =
			getCommonOverloadParamExpected(ctx.alloc, ctx.programState, tempAsArr_mut(candidates), argIdx);
		pauseMeasure(ctx.alloc, ctx.perf, perfMeasurer);
		immutable Expr arg = checkExpr(ctx, ast.args[argIdx], common.expected);
		resumeMeasure(ctx.alloc, ctx.perf, perfMeasurer);

		// If it failed to check, don't continue, just stop there.
		if (typeIsBogus(arg)) {
			someArgIsBogus = true;
			return none!Expr;
		}

		immutable Type actualArgType = inferred(common.expected);
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
		filterUnordered!(maxCandidates, Candidate)(candidates, (ref Candidate it) => candidateIsPreferred(it));
	}

	// Show diags at the function name and not at the whole call ast
	immutable FileAndRange diagRange =
		immutable FileAndRange(range.fileIndex, rangeOfNameAndRange(ast.funName, ctx.allSymbols));

	immutable Expr res = () {
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
			return checkCallAfterChoosingOverload(ctx, only_const(candidates), range, force(args), expected);
	}();

	endMeasure(ctx.alloc, ctx.perf, perfMeasurer);
	return res;
}

immutable(Expr) checkIdentifierCall(
	ref ExprCtx ctx,
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
	return checkCall(ctx, range, callAst, expected);
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
	return map_const!CalledDecl(alloc, tempAsArr_const(candidates), (ref const Candidate c) =>
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
	SingleInferringType[] typeArgs;
}

InferringTypeArgs inferringTypeArgs(ref Candidate a) {
	return InferringTypeArgs(typeParams(a.called), a.typeArgs);
}
const(InferringTypeArgs) inferringTypeArgs_const(ref const Candidate a) {
	return const InferringTypeArgs(typeParams(a.called), a.typeArgs);
}

void getInitialCandidates(
	ref ExprCtx ctx,
	ref Candidates candidates,
	immutable Sym funName,
	immutable Type[] explicitTypeArgs,
	immutable size_t actualArity,
) {
	eachFunInScope(ctx, funName, (ref immutable Opt!UsedFun used, immutable CalledDecl called) {
		immutable size_t nTypeParams = typeParams(called).length;
		if (arityMatches(arity(called), actualArity) &&
			(empty(explicitTypeArgs) || nTypeParams == explicitTypeArgs.length)) {
			SingleInferringType[] inferringTypeArgs =
				fillArr_mut!SingleInferringType(ctx.alloc, nTypeParams, (immutable size_t i) =>
					// InferringType for a type arg doesn't need a candidate;
					// that's for a (value) arg's expected type
					SingleInferringType(empty(explicitTypeArgs)
						? none!Type
						: some!Type(explicitTypeArgs[i])));
			push(candidates, Candidate(used, called, inferringTypeArgs));
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
		(immutable Ptr!TypeParam p) {
			const InferringTypeArgs ita = inferringTypeArgs_const(candidate);
			const Opt!(Ptr!SingleInferringType) sit = tryGetTypeArgFromInferringTypeArgs_const(ita, p);
			immutable Opt!Type inferred = has(sit) ? tryGetInferred(force(sit).deref()) : none!Type;
			return has(inferred) ? force(inferred) : immutable Type(p);
		},
		(immutable Ptr!StructInst i) {
			//TODO:PERF, the map might change nothing, so don't reallocate in that situation
			immutable Type[] typeArgs = map!Type(alloc, i.deref().typeArgs, (ref immutable Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return immutable Type(
				instantiateStructNeverDelay(
					alloc,
					programState,
					immutable StructDeclAndArgs(i.deref().decl, typeArgs)));
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
	const Candidate[] candidates,
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
	ref immutable CalledDecl res,
	immutable FileAndRange range,
	immutable ArgsKind argsKind,
) {
	matchCalledDecl!(
		void,
		(immutable Ptr!FunDecl f) {
			checkCallFlags(ctx.checkCtx, range, f, ctx.outermostFunFlags, has(peek(ctx.lambdas)), argsKind);
		},
		(ref immutable SpecSig) {
			// For a spec, we check the flags when providing the spec impl
		},
	)(res);
}

void filterByReturnType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref Candidates candidates,
	immutable Type expectedReturnType,
) {
	// Filter by return type. Also does type argument inference on the candidate.
	filterUnordered!(maxCandidates, Candidate)(candidates, (ref Candidate candidate) {
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
	filterUnordered!(maxCandidates, Candidate)(candidates, (ref Candidate candidate) {
		immutable Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic(alloc, programState, expectedArgType, actualArgType, ita);
	});
}

immutable(Opt!Called) findSpecSigImplementation(
	ref ExprCtx ctx,
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
	Candidates candidates = mutMaxArr!(maxCandidates, Candidate)();
	getInitialCandidates(ctx, candidates, specSig.name, emptyArr!Type, nParams);
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
			return getCalledFromCandidate(ctx, range, only_const(candidates), some(outerCalled), ArgsKind.nonEmpty);
		default:
			addDiag2(ctx, range, immutable Diag(
				immutable Diag.SpecImplFoundMultiple(specSig.name, candidatesForDiag(ctx.alloc, candidates))));
			return none!Called;
	}
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

// On failure, returns none.
//TODO: make @safe
@trusted immutable(Opt!(Called[])) checkSpecImpls(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	immutable Ptr!FunDecl called,
	immutable Type[] typeArgz,
	immutable Opt!(Ptr!FunDecl) outerCalled,
) {
	// We store the impls in a flat array. Calculate the size ahead of time.
	immutable size_t nImpls = sum(called.deref().specs, (ref immutable Ptr!SpecInst specInst) =>
		nSigs(specInst.deref().body_));
	if (nImpls != 0 && has(outerCalled)) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.SpecImplHasSpecs(force(outerCalled), called)));
		return none!(Called[]);
	} else {
		MutArr!(immutable Called) res = newUninitializedMutArr!(immutable Called)(ctx.alloc, nImpls);
		size_t outI = 0;
		bool allSucceeded = true;
		foreach (immutable Ptr!SpecInst specInst; called.deref().specs) {
			// specInst was instantiated potentially based on f's params.
			// Meed to instantiate it again.
			immutable TypeParamsAndArgs tpa = immutable TypeParamsAndArgs(called.deref().typeParams, typeArgz);
			immutable Ptr!SpecInst specInstInstantiated =
				instantiateSpecInst(ctx.alloc, ctx.programState, specInst, tpa);
			immutable bool succeeded = matchSpecBody!(immutable bool)(
				specInstInstantiated.deref().body_,
				(immutable SpecBody.Builtin b) =>
					checkBuiltinSpec(ctx, called, range, b.kind, only(typeArgs(specInstInstantiated.deref()))),
				(immutable SpecDeclSig[] sigs) {
					foreach (ref immutable SpecDeclSig sig; sigs) {
						immutable Opt!Called impl = findSpecSigImplementation(ctx, range, sig.sig, called);
						if (!has(impl))
							return false;
						res[outI] = force(impl);
						outI++;
					}
					return true;
				});
			if (!succeeded)
				allSucceeded = false;
		}
		if (allSucceeded) {
			verify(outI == nImpls);
			return some!(Called[])(moveToArr(ctx.alloc, res));
		} else
			return none!(Called[]);
	}
}

immutable(Opt!(Type[])) finishCandidateTypeArgs(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref const Candidate candidate,
) {
	immutable Opt!(Type[]) res =
		mapOrNone_const!Type(ctx.alloc, candidate.typeArgs, (ref const SingleInferringType i) =>
			tryGetInferred(i));
	if (!has(res))
		addDiag2(ctx, range, immutable Diag(Diag.CantInferTypeArguments()));
	return res;
}

immutable(Opt!Called) getCalledFromCandidate(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref const Candidate candidate,
	immutable Opt!(Ptr!FunDecl) outerCalled,
	immutable ArgsKind argsKind,
) {
	if (has(candidate.used))
		markUsedFun(ctx, force(candidate.used));
	checkCalledDeclFlags(ctx, candidate.called, range, argsKind);
	immutable Opt!(Type[]) candidateTypeArgs = finishCandidateTypeArgs(ctx, range, candidate);
	if (has(candidateTypeArgs)) {
		immutable Type[] typeArgs = force(candidateTypeArgs);
		return matchCalledDecl!(
			immutable Opt!Called,
			(immutable Ptr!FunDecl f) {
				immutable Opt!(Called[]) specImpls = checkSpecImpls(ctx, range, f, typeArgs, outerCalled);
				return has(specImpls)
					? some(immutable Called(
						instantiateFun(
							ctx.alloc,
							ctx.programState,
							immutable FunDeclAndArgs(f, typeArgs, force(specImpls)))))
					: none!Called;
			},
			(ref immutable SpecSig s) =>
				some(immutable Called(s)),
		)(candidate.called);
	} else
		return none!Called;
}

immutable(Expr) checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	ref const Candidate candidate,
	immutable FileAndRange range,
	immutable Expr[] args,
	ref Expected expected,
) {
	immutable Opt!Called opCalled = getCalledFromCandidate(
		ctx, range, candidate, none!(Ptr!FunDecl),
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
