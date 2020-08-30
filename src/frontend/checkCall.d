module frontend.checkCall;

@safe @nogc pure nothrow:

import diag : Diag;
import frontend.ast :
	CallAst,
	CondAst,
	ExprAst,
	LetAst,
	matchExprAstKind,
	SeqAst,
	TypeAst;
import frontend.checkCtx : addDiag, CheckCtx;
import frontend.checkExpr : checkExpr;
import frontend.inferringType :
	addDiag2,
	allocExpr,
	bogus,
	check,
	CheckedExpr,
	Expected,
	ExprCtx,
	inferred,
	InferringTypeArgs,
	LambdaInfo,
	matchTypesNoDiagnostic,
	programState,
	SingleInferringType,
	StructAndField,
	tryGetDeeplyInstantiatedType,
	tryGetInferred,
	tryGetRecordField,
	tryGetTypeArgFromInferringTypeArgs_const,
	typeArgsFromAsts;
import frontend.instantiate : instantiateFun, instantiateSpecInst, instantiateStructNeverDelay, TypeParamsAndArgs;
import frontend.programState : ProgramState;
import model :
	accessedFieldType,
	arity,
	body_,
	Called,
	CalledDecl,
	decl,
	Expr,
	FunDecl,
	FunDeclAndArgs,
	FunFlags,
	FunKind,
	getType,
	isDataOrSendable,
	matchCalledDecl,
	matchSpecBody,
	matchType,
	Module,
	nSigs,
	params,
	Purity,
	returnType,
	sig,
	Sig,
	SpecBody,
	SpecInst,
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
import util.bools : Bool, False, True;
import util.collection.arr :
	Arr,
	at,
	empty,
	emptyArr,
	first,
	only,
	only_const,
	onlyPtr_mut,
	ptrAt,
	arrRange = range,
	size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil :
	eachCorresponds,
	exists,
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
import util.opt : force, has, mapOption_const, none, Opt, some;
import util.ptr : Ptr, ptrEquals;
import util.sourceRange : SourceRange;
import util.sym : mutSymSetHas, Sym, symEq;
import util.util : todo;

import core.stdc.stdio : printf; //TODO:KILL

immutable(CheckedExpr) checkCall(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	ref immutable CallAst ast,
	ref Expected expected,
) {
	immutable Sym funName = ast.funName;
	immutable size_t arity = size(ast.args);
	immutable Arr!Type explicitTypeArgs = typeArgsFromAsts(alloc, ctx, ast.typeArgs);
	MutArr!Candidate candidates = getInitialCandidates(alloc, ctx, funName, explicitTypeArgs, arity);

	// TODO: may not need to be deeply instantiated to do useful filtering here
	immutable Opt!Type expectedReturnType = tryGetDeeplyInstantiatedType(alloc, programState(ctx), expected);
	if (has(expectedReturnType))
		filterByReturnType(alloc, programState(ctx), candidates, force(expectedReturnType));

	// Try to determine if the expression can have properties, without type-checking it.
	immutable Bool mightBePropertyAccess = Bool(
		arity == 1 &&
		exprMightHaveProperties(only(ast.args)) &&
		mutSymSetHas(programState(ctx).recordFieldNames, funName));

	ArrBuilder!Type actualArgTypes;
	Bool someArgIsBogus = False;
	immutable Opt!(Arr!Expr) args = fillArrOrFail!Expr(alloc, arity, (immutable size_t argIdx) {
		if (mutArrIsEmpty(candidates) && !mightBePropertyAccess)
			// Already certainly failed.
			return none!Expr;

		CommonOverloadExpected common = mightBePropertyAccess
			? CommonOverloadExpected(Expected.infer(), False)
			: getCommonOverloadParamExpected(alloc, programState(ctx), tempAsArr_mut(candidates), argIdx);
		immutable Expr arg = checkExpr(alloc, ctx, at(ast.args, argIdx), common.expected);

		// If it failed to check, don't continue, just stop there.
		if (typeIsBogus(arg)) {
			someArgIsBogus = True;
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

	const Arr!Candidate candidatesArr = moveToArr_const(alloc, candidates);

	if (mightBePropertyAccess && arity == 1 && has(args)) {
		immutable Opt!(Expr.RecordFieldAccess) rfa = tryGetRecordFieldAccess(alloc, ctx, funName, only(force(args)));
		if (has(rfa)) {
			if (!empty(candidatesArr))
				todo!void("ambiguous call vs property access");
			immutable Expr rfaExpr = immutable Expr(range, force(rfa));
			return check!Alloc(alloc, ctx, expected, accessedFieldType(force(rfa)), rfaExpr);
		}
	}

	if (!has(args) || size(candidatesArr) != 1) {
		if (empty(candidatesArr)) {
			immutable Arr!CalledDecl allCandidates = getAllCandidatesAsCalledDecls(alloc, ctx, funName);
			addDiag2(alloc, ctx, range, immutable Diag(Diag.CallNoMatch(
				funName,
				expectedReturnType,
				size(explicitTypeArgs),
				arity,
				finishArr(alloc, actualArgTypes),
				allCandidates)));
		} else {
			immutable Arr!CalledDecl matches = map_const!CalledDecl(alloc, candidatesArr, (ref const Candidate c) =>
				c.called);
			addDiag2(alloc, ctx, range, immutable Diag(Diag.CallMultipleMatches(funName, matches)));
		}
		return bogus(expected, range);
	} else
		return checkCallAfterChoosingOverload(alloc, ctx, only_const(candidatesArr), range, force(args), expected);
}


immutable(CheckedExpr) checkIdentifierCall(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	immutable Sym name,
	ref Expected expected,
) {
	immutable CallAst callAst = CallAst(name, emptyArr!TypeAst, emptyArr!ExprAst);
	return checkCall(alloc, ctx, range, callAst, expected);
}

private:

void eachFunInScope(
	ref ExprCtx ctx,
	immutable Sym funName,
	scope void delegate(immutable CalledDecl) @safe @nogc pure nothrow cb,
) {
	size_t totalIndex = 0;
	foreach (immutable Ptr!SpecInst specInst; arrRange(ctx.outermostFun.specs))
		matchSpecBody(
			specInst.body_,
			(ref immutable SpecBody.Builtin) {},
			(ref immutable Arr!Sig sigs) {
				foreach (immutable size_t i; 0..size(sigs))
					if (symEq(at(sigs, i).name, funName))
						cb(immutable CalledDecl(SpecSig(specInst, ptrAt(sigs, i), totalIndex + i)));
				totalIndex += size(sigs);
			});

	foreach (immutable Ptr!FunDecl f; arrRange(multiDictGetAt(ctx.funsMap, funName)))
		cb(immutable CalledDecl(f));

	foreach (immutable Ptr!Module m; arrRange(ctx.checkCtx.allFlattenedImports))
		foreach (immutable Ptr!FunDecl f; arrRange(multiDictGetAt(m.funsMap, funName)))
			if (f.isPublic)
				cb(immutable CalledDecl(f));
}

// If we call `foo: \x ...` where `foo` is a function that doesn't exist,
// don't continue checking the lambda it in the hopes that it might have a property.
immutable(Bool) exprMightHaveProperties(immutable ExprAst ast) {
	return matchExprAstKind!(immutable Bool)(
		ast.kind,
		(ref immutable CallAst) => True,
		(ref immutable CondAst e) =>
			immutable Bool(exprMightHaveProperties(e.then) && exprMightHaveProperties(e.else_)),
		(ref immutable CreateArrAst) => True,
		(ref immutable CreateRecordAst) => True,
		(ref immutable CreateRecordMultiLineAst) => True,
		(ref immutable IdentifierAst) => True,
		(ref immutable LambdaAst) => False,
		(ref immutable LetAst e) => exprMightHaveProperties(e.then),
		(ref immutable LiteralAst) => True,
		(ref immutable LiteralInnerAst) => True,
		//TODO:CHECK ALL BRANCHES
		(ref immutable MatchAst) => True,
		// Always returns fut
		//TODO: so should always be false?
		(ref immutable SeqAst e) => exprMightHaveProperties(e.then),
		(ref immutable RecordFieldSetAst) => False,
		// Always returns fut
		(ref immutable ThenAst) => False);
}

struct Candidate {
	immutable CalledDecl called;
	// Note: this is always empty if calling a SpecSig
	Arr!SingleInferringType typeArgs;
}

InferringTypeArgs inferringTypeArgs(ref Candidate a) {
	return InferringTypeArgs(typeParams(a.called), a.typeArgs);
}
const(InferringTypeArgs) inferringTypeArgs_const(ref const Candidate a) {
	return const InferringTypeArgs(typeParams(a.called), a.typeArgs);
}

MutArr!Candidate getInitialCandidates(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Sym funName,
	immutable Arr!Type explicitTypeArgs,
	immutable size_t actualArity,
) {
	MutArr!Candidate res = MutArr!Candidate();
	eachFunInScope(ctx, funName, (immutable CalledDecl called) {
		//debug {
		//	printf("Fun in scope! Its arity: %lu = %lu\n", arity(called), size(sig(called).params));
		//}
		immutable size_t nTypeParams = size(typeParams(called));
		if (arity(called) == actualArity &&
			(empty(explicitTypeArgs) || nTypeParams == size(explicitTypeArgs))) {
			Arr!SingleInferringType inferringTypeArgs = fillArr_mut!(SingleInferringType, Alloc)(
				alloc,
				nTypeParams,
				(immutable size_t i) =>
					// InferringType for a type arg doesn't need a candidate;
					// that's for a (value) arg's expected type
					SingleInferringType(empty(explicitTypeArgs)
						? none!Type
						: some!Type(at(explicitTypeArgs, i))));
			push(alloc, res, Candidate(called, inferringTypeArgs));
		}
	});
	return res;
}

immutable(Arr!CalledDecl) getAllCandidatesAsCalledDecls(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Sym funName,
) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(ctx, funName, (immutable CalledDecl called) {
		add(alloc, res, called);
	});
	return finishArr(alloc, res);
}

immutable(Type) getCandidateExpectedParameterTypeRecur(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	ref immutable Type candidateParamType,
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
			immutable Arr!Type typeArgs = map!Type(alloc, i.typeArgs, (ref immutable Type t) =>
				getCandidateExpectedParameterTypeRecur(alloc, programState, candidate, t));
			return immutable Type(
				instantiateStructNeverDelay(alloc, programState, immutable StructDeclAndArgs(i.decl, typeArgs)));
		});
}

immutable(Type) getCandidateExpectedParameterType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref const Candidate candidate,
	ref immutable size_t argIdx,
) {
	return getCandidateExpectedParameterTypeRecur(
		alloc,
		programState,
		candidate,
		at(params(candidate.called), argIdx).type);
}

struct CommonOverloadExpected {
	Expected expected;
	immutable Bool isExpectedFromCandidate;
}

// For multiple candidates, only have an expected type if they have exactly the same param type
Expected getCommonOverloadParamExpectedForMultipleCandidates(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	const Arr!Candidate candidates,
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

CommonOverloadExpected getCommonOverloadParamExpected(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	Arr!Candidate candidates,
	immutable size_t argIdx,
) {
	switch (size(candidates)) {
		case 0:
			return CommonOverloadExpected(Expected.infer(), False);
		case 1: {
			Ptr!Candidate candidate = onlyPtr_mut(candidates);
			immutable Type t = getCandidateExpectedParameterType(alloc, programState, candidate.deref, argIdx);
			return CommonOverloadExpected(Expected(some(t), inferringTypeArgs(candidate)), True);
		}
		default:
			return CommonOverloadExpected(
				getCommonOverloadParamExpectedForMultipleCandidates(alloc, programState, candidates, argIdx, none!Type),
				False);
	}
}

immutable(Opt!(Expr.RecordFieldAccess)) tryGetRecordFieldAccess(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Sym funName,
	immutable Expr arg,
) {
	immutable Opt!StructAndField field = tryGetRecordField(getType(arg, ctx.commonTypes), funName);
	return has(field)
		? some(immutable Expr.RecordFieldAccess(
			allocExpr(alloc, arg),
			force(field).structInst,
			force(field).field))
		: none!(Expr.RecordFieldAccess);
}

immutable(Opt!(Diag.CantCall.Reason)) getCantCallReason(
	immutable FunFlags calledFlags,
	immutable FunFlags callerFlags,
	immutable Opt!FunKind lambdaKind,
) {
	immutable Bool callerIsNoCtx = has(lambdaKind)
		? Bool(force(lambdaKind) == FunKind.ptr)
		: callerFlags.noCtx;
	return !calledFlags.noCtx && callerIsNoCtx
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.unsafe && !callerFlags.trusted && !callerFlags.unsafe
		? some(Diag.CantCall.Reason.unsafe)
		: none!(Diag.CantCall.Reason);
}

void checkCallFlags(Alloc)(
	ref Alloc alloc,
	ref CheckCtx ctx,
	immutable SourceRange range,
	immutable Ptr!FunDecl called,
	immutable Ptr!FunDecl caller,
	const Opt!(Ptr!LambdaInfo) callerLambda,
) {
	immutable Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		called.flags,
		caller.flags,
		mapOption_const(callerLambda, (ref const Ptr!LambdaInfo it) => it.funKind));
	if (has(reason))
		addDiag(alloc, ctx, range, immutable Diag(Diag.CantCall(force(reason), called, caller)));
}

immutable(Bool) structInstsEqual(
	ref immutable Ptr!StructInst a,
	ref immutable Ptr!StructInst b,
	scope immutable(Bool) delegate(ref immutable Type, ref immutable Type) @safe @nogc pure nothrow typeArgsEqual,
) {
	return immutable Bool(
		ptrEquals(decl(a), decl(b)) &&
		eachCorresponds(typeArgs(a), typeArgs(b), typeArgsEqual));
}

void checkCalledDeclFlags(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable CalledDecl res,
	ref immutable SourceRange range,
) {
	return matchCalledDecl(
		res,
		(immutable Ptr!FunDecl f) {
			checkCallFlags(alloc, ctx.checkCtx, range, f, ctx.outermostFun, peek(ctx.lambdas));
		},
		(ref immutable SpecSig) {
			// For a spec, we check the flags when providing the spec impl
		});
}

void filterByReturnType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!Candidate candidates,
	ref immutable Type expectedReturnType,
) {
	// Filter by return type. Also does type argument inference on the candidate.
	filterUnordered!Candidate(candidates, (ref Candidate candidate) {
		InferringTypeArgs ta = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic!Alloc(
			alloc,
			programState,
			returnType(candidate.called),
			expectedReturnType,
			ta,
			True);
	});
}

void filterByParamType(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref MutArr!Candidate candidates,
	ref immutable Type actualArgType,
	immutable size_t argIdx,
) {
	// Remove candidates that can't accept this as a param. Also does type argument inference on the candidate.
	filterUnordered(candidates, (ref Candidate candidate) {
		immutable Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		return matchTypesNoDiagnostic!Alloc(alloc, programState, expectedArgType, actualArgType, ita);
	});
}

immutable(Opt!Called) findSpecSigImplementation(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	ref immutable Sig specSig,
) {
	MutArr!Candidate candidates = getInitialCandidates(alloc, ctx, specSig.name, emptyArr!Type, arity(specSig));
	filterByReturnType(alloc, programState(ctx), candidates, specSig.returnType);
	foreach (immutable size_t argIdx; 0..arity(specSig))
		filterByParamType(alloc, programState(ctx), candidates, at(specSig.params, argIdx).type, argIdx);

	// If any candidates left take specs -- leave as a TODO
	const Arr!Candidate candidatesArr = moveToArr_const(alloc, candidates);
	switch (size(candidatesArr)) {
		case 0:
			addDiag2(alloc, ctx, range, immutable Diag(Diag.SpecImplNotFound(specSig.name)));
			return none!Called;
		case 1:
			return getCalledFromCandidate(alloc, ctx, range, only_const(candidatesArr), False);
		default:
			todo!void("diagnostic: multiple functions satisfy the spec");
			return none!Called;
	}
}

// See if e.g. 'data<?t>' is declared on this function.
immutable(Bool) findBuiltinSpecOnType(
	ref ExprCtx ctx,
	immutable SpecBody.Builtin.Kind kind,
	immutable Type type,
) {
	return exists(ctx.outermostFun.specs, (ref immutable Ptr!SpecInst inst) =>
		matchSpecBody(
			inst.body_,
			(ref immutable SpecBody.Builtin b) =>
				immutable Bool(
					b.kind == kind && typeEquals(only(inst.typeArgs), type)),
			(ref immutable Arr!Sig) =>
				//TODO: might inherit from builtin spec?
				False));
}

immutable(Bool) checkBuiltinSpec(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Ptr!FunDecl called,
	immutable SourceRange range,
	immutable SpecBody.Builtin.Kind kind,
	ref immutable Type typeArg,
 ) {
	// TODO: Instead of worstCasePurity(), it type is a type parameter,
	// see if the current function has its own spec requiring that it be data / send
	immutable Bool typeIsGood = Bool(() {
		final switch (kind) {
			case SpecBody.Builtin.Kind.data:
				return worstCasePurity(typeArg) == Purity.data;
			case SpecBody.Builtin.Kind.send:
				return isDataOrSendable(worstCasePurity(typeArg));
		}
	}() || findBuiltinSpecOnType(ctx, kind, typeArg));
	if (!typeIsGood)
		addDiag2(alloc, ctx, range, immutable Diag(Diag.SpecBuiltinNotSatisfied(kind, typeArg, called)));
	return typeIsGood;
}

// On failure, returns none.
//TODO: make @safe
@trusted immutable(Opt!(Arr!Called)) checkSpecImpls(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	immutable Ptr!FunDecl called,
	immutable Arr!Type typeArgz,
	immutable Bool allowSpecs,
) {
	// We store the impls in a flat array. Calculate the size ahead of time.
	immutable size_t nImpls = sum!(Ptr!SpecInst)(called.specs, (ref immutable Ptr!SpecInst specInst) =>
		nSigs(specInst.body_));
	if (nImpls != 0 && !allowSpecs) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.SpecImplHasSpecs()));
		return none!(Arr!Called);
	} else {
		MutArr!(immutable Called) res = newUninitializedMutArr!(immutable Called)(alloc, nImpls);
		size_t outI = 0;
		Bool allSucceeded = True;
		foreach (immutable Ptr!SpecInst specInst; arrRange(called.specs)) {
			// specInst was instantiated potentially based on f's params.
			// Meed to instantiate it again.
			immutable TypeParamsAndArgs tpa = immutable TypeParamsAndArgs(called.typeParams, typeArgz);
			immutable Ptr!SpecInst specInstInstantiated = instantiateSpecInst(alloc, programState(ctx), specInst, tpa);
			immutable Bool succeeded = matchSpecBody(
				specInstInstantiated.body_,
				(ref immutable SpecBody.Builtin b) =>
					checkBuiltinSpec(alloc, ctx, called, range, b.kind, only(typeArgs(specInstInstantiated))),
				(ref immutable Arr!Sig sigs) {
					foreach (ref immutable Sig sig; arrRange(sigs)) {
						immutable Opt!Called impl = findSpecSigImplementation(alloc, ctx, range, sig);
						if (!has(impl))
							return False;
						setAt(res, outI, force(impl));
						outI++;
					}
					return True;
				});
			if (!succeeded)
				allSucceeded = False;
		}
		if (allSucceeded) {
			assert(outI == nImpls);
			return some(moveToArr(alloc, res));
		} else
			return none!(Arr!Called);
	}
}

immutable(Opt!(Arr!Type)) finishCandidateTypeArgs(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	ref const Candidate candidate,
) {
	immutable Opt!(Arr!Type) res = mapOrNone_const!Type(alloc, candidate.typeArgs, (ref const SingleInferringType i) =>
		tryGetInferred(i));
	if (!has(res))
		addDiag2(alloc, ctx, range, immutable Diag(Diag.CantInferTypeArguments()));
	return res;
}

immutable(Opt!Called) getCalledFromCandidate(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable SourceRange range,
	ref const Candidate candidate,
	immutable Bool allowSpecs,
) {
	checkCalledDeclFlags(alloc, ctx, candidate.called, range);
	immutable Opt!(Arr!Type) candidateTypeArgs = finishCandidateTypeArgs(alloc, ctx, range, candidate);
	if (has(candidateTypeArgs)) {
		immutable Arr!Type typeArgs = force(candidateTypeArgs);
		return matchCalledDecl(
			candidate.called,
			(immutable Ptr!FunDecl f) {
				immutable Opt!(Arr!Called) specImpls = checkSpecImpls(alloc, ctx, range, f, typeArgs, allowSpecs);
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

immutable(CheckedExpr) checkCallAfterChoosingOverload(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref const Candidate candidate,
	immutable SourceRange range,
	immutable Arr!Expr args,
	ref Expected expected,
) {
	immutable Opt!Called opCalled = getCalledFromCandidate(alloc, ctx, range, candidate, True);
	if (has(opCalled)) {
		immutable Called called = force(opCalled);
		immutable Expr calledExpr = immutable Expr(range, Expr.Call(called, args));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(alloc, ctx, expected, returnType(called), calledExpr);
	} else
		return bogus(expected, range);
}
