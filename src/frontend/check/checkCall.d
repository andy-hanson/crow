module frontend.check.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, eachImportAndReExport, ImportIndex, markUsedImport;
import frontend.check.checkExpr : checkExpr;
import frontend.check.dicts : FunDeclAndIndex, ModuleLocalFunIndex;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	CheckedExpr,
	Expected,
	ExprCtx,
	inferred,
	InferringTypeArgs,
	LambdaInfo,
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
	isDataOrSendable,
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
	returnType,
	sig,
	Sig,
	SpecBody,
	SpecInst,
	specs,
	SpecSig,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	typeIsBogus,
	TypeParam,
	typeParams,
	worstCasePurity;
import util.alloc.alloc : Alloc;
import util.collection.arr :
	at,
	empty,
	emptyArr,
	emptyArrWithSize,
	first,
	only,
	only_const,
	onlyPtr_mut,
	ptrAt,
	size,
	toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil :
	exists,
	exists_const,
	fillArr_mut,
	fillArrOrFail,
	filterUnordered,
	map,
	map_const,
	mapOrNone_const,
	sum,
	tail;
import util.collection.multiDict : multiDictGetAt;
import util.collection.mutArr :
	moveToArr,
	moveToArr_const,
	MutArr,
	mutArrIsEmpty,
	mutArrSize,
	newUninitializedMutArr,
	peek,
	push,
	setAt,
	tempAsArr,
	tempAsArr_mut;
import util.opt : force, has, none, Opt, some;
import util.memory : nu;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : Sym, symEq;
import util.util : Empty, todo, verify;

immutable(CheckedExpr) checkCall(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable CallAst ast,
	ref Expected expected,
) {
	immutable Sym funName = ast.funName.name;
	immutable ExprAst[] argAsts = toArr(ast.args);
	immutable size_t arity = size(argAsts);
	immutable Type[] explicitTypeArgs = typeArgsFromAsts(alloc, ctx, toArr(ast.typeArgs));
	MutArr!Candidate candidates = getInitialCandidates(alloc, ctx, funName, explicitTypeArgs, arity);

	// TODO: may not need to be deeply instantiated to do useful filtering here
	immutable Opt!Type expectedReturnType = tryGetDeeplyInstantiatedType(alloc, programState(ctx), expected);
	if (has(expectedReturnType))
		filterByReturnType(alloc, programState(ctx), candidates, force(expectedReturnType));

	ArrBuilder!Type actualArgTypes;
	bool someArgIsBogus = false;
	immutable Opt!(Expr[]) args = fillArrOrFail!Expr(alloc, arity, (immutable size_t argIdx) {
		if (mutArrIsEmpty(candidates))
			// Already certainly failed.
			return none!Expr;

		CommonOverloadExpected common =
			getCommonOverloadParamExpected(alloc, programState(ctx), tempAsArr_mut(candidates), argIdx);
		immutable Expr arg = checkExpr(alloc, ctx, at(argAsts, argIdx), common.expected);

		// If it failed to check, don't continue, just stop there.
		if (typeIsBogus(arg)) {
			someArgIsBogus = true;
			return none!Expr;
		}

		immutable Type actualArgType = inferred(common.expected);
		add(alloc, actualArgTypes, actualArgType);
		// If the Inferring already came from the candidate, no need to do more work.
		if (!common.isExpectedFromCandidate)
			filterByParamType(alloc, programState(ctx), candidates, actualArgType, argIdx);
		return some(arg);
	});

	if (someArgIsBogus)
		return bogus(expected, range);

	if (mutArrSize(candidates) != 1 &&
		exists_const!Candidate(tempAsArr(candidates), (ref const Candidate it) => candidateIsPreferred(it))) {
		filterUnordered!Candidate(candidates, (ref Candidate it) => candidateIsPreferred(it));
	}

	const Candidate[] candidatesArr = moveToArr_const(alloc, candidates);

	// Show diags at the function name and not at the whole call ast
	immutable FileAndRange diagRange = immutable FileAndRange(range.fileIndex, rangeOfNameAndRange(ast.funName));

	if (!has(args) || size(candidatesArr) != 1) {
		if (empty(candidatesArr)) {
			immutable CalledDecl[] allCandidates = getAllCandidatesAsCalledDecls(alloc, ctx, funName);
			addDiag2(alloc, ctx, diagRange, immutable Diag(nu!(Diag.CallNoMatch)(
				alloc,
				funName,
				expectedReturnType,
				size(explicitTypeArgs),
				arity,
				finishArr(alloc, actualArgTypes),
				allCandidates)));
		} else
			addDiag2(alloc, ctx, diagRange, immutable Diag(
				immutable Diag.CallMultipleMatches(funName, candidatesForDiag(alloc, candidatesArr))));
		return bogus(expected, range);
	} else
		return checkCallAfterChoosingOverload(alloc, ctx, only_const(candidatesArr), range, force(args), expected);
}

immutable(CheckedExpr) checkIdentifierCall(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	immutable Sym name,
	ref Expected expected,
) {
	//TODO:NEATER (don't make a synthetic AST, just directly call an appropriate function)
	immutable CallAst callAst = immutable CallAst(
		CallAst.Style.single,
		immutable NameAndRange(range.range.start, name),
		emptyArrWithSize!TypeAst,
		emptyArrWithSize!ExprAst);
	return checkCall(alloc, ctx, range, callAst, expected);
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
		matchSpecBody(
			specInst.body_,
			(ref immutable SpecBody.Builtin) {},
			(ref immutable Sig[] sigs) {
				foreach (immutable size_t i; 0 .. size(sigs))
					if (symEq(at(sigs, i).name, funName)) {
						immutable Opt!UsedFun used = none!UsedFun;
						cb(used, immutable CalledDecl(immutable SpecSig(specInst, ptrAt(sigs, i), totalIndex + i)));
					}
				totalIndex += size(sigs);
			});

	foreach (ref immutable FunDeclAndIndex f; multiDictGetAt(ctx.funsDict, funName)) {
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

immutable(CalledDecl[]) candidatesForDiag(ref Alloc alloc, ref const Candidate[] candidates) {
	return map_const!CalledDecl(alloc, candidates, (ref const Candidate c) =>
		c.called);
}

immutable(bool) candidateIsPreferred(ref const Candidate a) {
	return matchCalledDecl!(immutable bool)(
		a.called,
		(immutable Ptr!FunDecl it) =>
			it.flags.preferred,
		(ref immutable SpecSig) =>
			false);
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

MutArr!Candidate getInitialCandidates(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Sym funName,
	immutable Type[] explicitTypeArgs,
	immutable size_t actualArity,
) {
	MutArr!Candidate res = MutArr!Candidate();
	eachFunInScope(ctx, funName, (ref immutable Opt!UsedFun used, immutable CalledDecl called) {
		immutable size_t nTypeParams = size(typeParams(called));
		if (arityMatches(arity(called), actualArity) &&
			(empty(explicitTypeArgs) || nTypeParams == size(explicitTypeArgs))) {
			SingleInferringType[] inferringTypeArgs = fillArr_mut!SingleInferringType(
				alloc,
				nTypeParams,
				(immutable size_t i) =>
					// InferringType for a type arg doesn't need a candidate;
					// that's for a (value) arg's expected type
					SingleInferringType(empty(explicitTypeArgs)
						? none!Type
						: some!Type(at(explicitTypeArgs, i))));
			push(alloc, res, Candidate(used, called, inferringTypeArgs));
		}
	});
	return res;
}

immutable(CalledDecl[]) getAllCandidatesAsCalledDecls(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Sym funName,
) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(ctx, funName, (ref immutable Opt!UsedFun, immutable CalledDecl called) {
		add(alloc, res, called);
	});
	return finishArr(alloc, res);
}

immutable(Type) getCandidateExpectedParameterTypeRecur(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	immutable Type candidateParamType,
) {
	return matchType(
		candidateParamType,
		(ref immutable Type.Bogus) =>
			immutable Type(Type.Bogus()),
		(immutable Ptr!TypeParam p) {
			const InferringTypeArgs ita = inferringTypeArgs_const(candidate);
			const Opt!(Ptr!SingleInferringType) sit = tryGetTypeArgFromInferringTypeArgs_const(ita, p);
			immutable Opt!Type inferred = has(sit) ? tryGetInferred(force(sit)) : none!Type;
			return has(inferred) ? force(inferred) : immutable Type(p);
		},
		(immutable Ptr!StructInst i) {
			//TODO:PERF, the map might change nothing, so don't reallocate in that situation
			immutable Type[] typeArgs = map!Type(alloc, i.typeArgs, (ref immutable Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return immutable Type(
				instantiateStructNeverDelay(alloc, programState, immutable StructDeclAndArgs(i.decl, typeArgs)));
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
			at(params, argIdx).type,
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
		immutable Type paramType = getCandidateExpectedParameterType(alloc, programState, first(candidates), argIdx);
		return has(expected) && !typeEquals(paramType, force(expected))
			// Only get an expected type if all candidates expect it.
			? Expected.infer()
			: getCommonOverloadParamExpectedForMultipleCandidates(
				alloc,
				programState,
				tail(candidates),
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
	switch (size(candidates)) {
		case 0:
			return CommonOverloadExpected(Expected.infer(), false);
		case 1: {
			Ptr!Candidate candidate = onlyPtr_mut(candidates);
			immutable Type t = getCandidateExpectedParameterType(alloc, programState, candidate.deref, argIdx);
			return CommonOverloadExpected(Expected(some(t), inferringTypeArgs(candidate)), true);
		}
		default:
			return CommonOverloadExpected(
				getCommonOverloadParamExpectedForMultipleCandidates(alloc, programState, candidates, argIdx, none!Type),
				false);
	}
}

immutable(Opt!(Diag.CantCall.Reason)) getCantCallReason(
	immutable bool calledIsVariadic,
	immutable FunFlags calledFlags,
	immutable FunFlags callerFlags,
	immutable bool inLambda,
) {
	return !calledFlags.noCtx && callerFlags.noCtx && !inLambda
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.unsafe && !callerFlags.trusted && !callerFlags.unsafe
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadic && callerFlags.noCtx
		? some(Diag.CantCall.Reason.variadicFromNoctx)
		: none!(Diag.CantCall.Reason);
}

void checkCallFlags(
	ref Alloc alloc,
	ref CheckCtx ctx,
	ref immutable FileAndRange range,
	immutable Ptr!FunDecl called,
	immutable FunFlags caller,
	const Opt!(Ptr!LambdaInfo) callerLambda,
) {
	immutable Opt!(Diag.CantCall.Reason) reason =
		getCantCallReason(isVariadic(called), called.flags, caller, has(callerLambda));
	if (has(reason))
		addDiag(alloc, ctx, range, immutable Diag(Diag.CantCall(force(reason), called)));
}

void checkCalledDeclFlags(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable CalledDecl res,
	ref immutable FileAndRange range,
) {
	return matchCalledDecl(
		res,
		(immutable Ptr!FunDecl f) {
			checkCallFlags(alloc, ctx.checkCtx, range, f, ctx.outermostFunFlags, peek(ctx.lambdas));
		},
		(ref immutable SpecSig) {
			// For a spec, we check the flags when providing the spec impl
		});
}

void filterByReturnType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!Candidate candidates,
	ref immutable Type expectedReturnType,
) {
	// Filter by return type. Also does type argument inference on the candidate.
	filterUnordered!Candidate(candidates, (ref Candidate candidate) {
		InferringTypeArgs ta = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic(alloc, programState, returnType(candidate.called), expectedReturnType, ta);
	});
}

void filterByParamType(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!Candidate candidates,
	immutable Type actualArgType,
	immutable size_t argIdx,
) {
	// Remove candidates that can't accept this as a param. Also does type argument inference on the candidate.
	filterUnordered!Candidate(candidates, (ref Candidate candidate) {
		immutable Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic(alloc, programState, expectedArgType, actualArgType, ita);
	});
}

immutable(Opt!Called) findSpecSigImplementation(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Sig specSig,
	immutable Ptr!FunDecl outerCalled,
) {
	immutable size_t nParams = matchArity!(immutable size_t)(
		arity(specSig),
		(immutable size_t n) =>
			n,
		(ref immutable Arity.Varargs) =>
			todo!(immutable size_t)("varargs in spec?"));
	MutArr!Candidate candidates = getInitialCandidates(alloc, ctx, specSig.name, emptyArr!Type, nParams);
	filterByReturnType(alloc, programState(ctx), candidates, specSig.returnType);
	foreach (immutable size_t argIdx; 0 .. nParams)
		filterByParamType(alloc, programState(ctx), candidates, paramTypeAt(specSig.params, argIdx), argIdx);

	// If any candidates left take specs -- leave as a TODO
	const Candidate[] candidatesArr = moveToArr_const(alloc, candidates);
	switch (size(candidatesArr)) {
		case 0:
			// TODO: use initial candidates in the error message
			addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.SpecImplNotFound(specSig.name)));
			return none!Called;
		case 1:
			return getCalledFromCandidate(alloc, ctx, range, only_const(candidatesArr), some(outerCalled));
		default:
			addDiag2(alloc, ctx, range, immutable Diag(
				immutable Diag.SpecImplFoundMultiple(specSig.name, candidatesForDiag(alloc, candidatesArr))));
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
		matchSpecBody(
			inst.body_,
			(ref immutable SpecBody.Builtin b) =>
				b.kind == kind && typeEquals(only(inst.typeArgs), type),
			(ref immutable Sig[]) =>
				//TODO: might inherit from builtin spec?
				false));
}

immutable(bool) checkBuiltinSpec(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Ptr!FunDecl called,
	ref immutable FileAndRange range,
	immutable SpecBody.Builtin.Kind kind,
	ref immutable Type typeArg,
 ) {
	// TODO: Instead of worstCasePurity(), it type is a type parameter,
	// see if the current function has its own spec requiring that it be data / send
	immutable bool typeIsGood = () {
		final switch (kind) {
			case SpecBody.Builtin.Kind.data:
				return worstCasePurity(typeArg) == Purity.data;
			case SpecBody.Builtin.Kind.send:
				return isDataOrSendable(worstCasePurity(typeArg));
		}
	}() || findBuiltinSpecOnType(ctx, kind, typeArg);
	if (!typeIsGood)
		addDiag2(alloc, ctx, range, immutable Diag(nu!(Diag.SpecBuiltinNotSatisfied)(alloc, kind, typeArg, called)));
	return typeIsGood;
}

// On failure, returns none.
//TODO: make @safe
@trusted immutable(Opt!(Called[])) checkSpecImpls(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	immutable Ptr!FunDecl called,
	immutable Type[] typeArgz,
	immutable Opt!(Ptr!FunDecl) outerCalled,
) {
	// We store the impls in a flat array. Calculate the size ahead of time.
	immutable size_t nImpls = sum(specs(called), (ref immutable Ptr!SpecInst specInst) =>
		nSigs(specInst.body_));
	if (nImpls != 0 && has(outerCalled)) {
		addDiag2(alloc, ctx, range, immutable Diag(
			immutable Diag.SpecImplHasSpecs(force(outerCalled), called)));
		return none!(Called[]);
	} else {
		MutArr!(immutable Called) res = newUninitializedMutArr!(immutable Called)(alloc, nImpls);
		size_t outI = 0;
		bool allSucceeded = true;
		foreach (immutable Ptr!SpecInst specInst; called.specs) {
			// specInst was instantiated potentially based on f's params.
			// Meed to instantiate it again.
			immutable TypeParamsAndArgs tpa = immutable TypeParamsAndArgs(called.typeParams, typeArgz);
			immutable Ptr!SpecInst specInstInstantiated = instantiateSpecInst(alloc, programState(ctx), specInst, tpa);
			immutable bool succeeded = matchSpecBody!(immutable bool)(
				specInstInstantiated.body_,
				(ref immutable SpecBody.Builtin b) =>
					checkBuiltinSpec(alloc, ctx, called, range, b.kind, only(typeArgs(specInstInstantiated))),
				(ref immutable Sig[] sigs) {
					foreach (ref immutable Sig sig; sigs) {
						immutable Opt!Called impl = findSpecSigImplementation(alloc, ctx, range, sig, called);
						if (!has(impl))
							return false;
						setAt(res, outI, force(impl));
						outI++;
					}
					return true;
				});
			if (!succeeded)
				allSucceeded = false;
		}
		if (allSucceeded) {
			verify(outI == nImpls);
			return some!(Called[])(moveToArr(alloc, res));
		} else
			return none!(Called[]);
	}
}

immutable(Opt!(Type[])) finishCandidateTypeArgs(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref const Candidate candidate,
) {
	immutable Opt!(Type[]) res = mapOrNone_const!Type(alloc, candidate.typeArgs, (ref const SingleInferringType i) =>
		tryGetInferred(i));
	if (!has(res))
		addDiag2(alloc, ctx, range, immutable Diag(Diag.CantInferTypeArguments()));
	return res;
}

immutable(Opt!Called) getCalledFromCandidate(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref const Candidate candidate,
	immutable Opt!(Ptr!FunDecl) outerCalled,
) {
	if (has(candidate.used))
		markUsedFun(ctx, force(candidate.used));
	checkCalledDeclFlags(alloc, ctx, candidate.called, range);
	immutable Opt!(Type[]) candidateTypeArgs = finishCandidateTypeArgs(alloc, ctx, range, candidate);
	if (has(candidateTypeArgs)) {
		immutable Type[] typeArgs = force(candidateTypeArgs);
		return matchCalledDecl(
			candidate.called,
			(immutable Ptr!FunDecl f) {
				immutable Opt!(Called[]) specImpls = checkSpecImpls(alloc, ctx, range, f, typeArgs, outerCalled);
				return has(specImpls)
					? some(immutable Called(
						instantiateFun(
							alloc,
							programState(ctx),
							immutable FunDeclAndArgs(f, typeArgs, force(specImpls)))))
					: none!Called;
			},
			(ref immutable SpecSig s) =>
				some(immutable Called(s)));
	} else
		return none!Called;
}

immutable(CheckedExpr) checkCallAfterChoosingOverload(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref const Candidate candidate,
	ref immutable FileAndRange range,
	immutable Expr[] args,
	ref Expected expected,
) {
	immutable Opt!Called opCalled = getCalledFromCandidate(alloc, ctx, range, candidate, none!(Ptr!FunDecl));
	if (has(opCalled)) {
		immutable Called called = force(opCalled);
		immutable Expr calledExpr = immutable Expr(range, Expr.Call(called, args));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(alloc, ctx, expected, returnType(called), calledExpr);
	} else
		return bogus(expected, range);
}
