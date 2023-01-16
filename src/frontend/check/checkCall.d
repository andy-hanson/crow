module frontend.check.checkCall;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : eachImportAndReExport, ImportIndex, markUsedImport;
import frontend.check.checkExpr : checkExpr;
import frontend.check.dicts : FunDeclAndIndex, ModuleLocalFunIndex;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	checkCanDoUnsafe,
	Expected,
	ExprCtx,
	FunOrLambdaInfo,
	inferred,
	InferringTypeArgs,
	inferTypeArgsFrom,
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
	typeFromAst2;
import frontend.check.instantiate :
	instantiateFun,
	instantiateSpecInst,
	instantiateStructNeverDelay,
	noDelaySpecInsts,
	TypeArgsArray,
	typeArgsArray,
	TypeParamsAndArgs;
import frontend.check.typeFromAst : tryGetMatchingTypeArgs, tryUnpackTupleType;
import frontend.lang : maxSpecDepth, maxSpecImpls, maxTypeParams;
import frontend.parse.ast :
	CallAst, ExprAst, ExprAstKind, LambdaAst, NameAndRange, ParenthesizedAst, rangeOfNameAndRange, TypeAst;
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
	isPurityCompatible,
	isPurityAlwaysCompatible,
	isVariadic,
	NameReferents,
	Param,
	Params,
	Purity,
	PurityRange,
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
import util.col.arrUtil : every, exists, fillArrOrFail, map;
import util.col.mutMaxArr :
	copyToFrom,
	exists,
	fillMutMaxArr_mut,
	filterUnordered,
	filterUnorderedButDontRemoveAll,
	initializeMutMaxArr,
	isEmpty,
	isFull,
	mapTo,
	mustPop,
	MutMaxArr,
	mutMaxArr,
	mutMaxArrSize,
	only,
	push,
	pushUninitialized,
	size,
	tempAsArr,
	toArray;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, some;
import util.perf : endMeasure, PerfMeasure, PerfMeasurer, pauseMeasure, resumeMeasure, startMeasure;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : Sym;
import util.union_ : Union;
import util.util : todo;

Expr checkCall(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in CallAst ast, ref Expected expected) {
	PerfMeasurer perfMeasurer = startMeasure(ctx.alloc, ctx.perf, PerfMeasure.checkCall);
	Expr res = withCandidates!Expr(
		ctx, ast.funName.name, ast.typeArg, ast.args.length,
		(ref Candidates candidates) =>
			checkCallInner(ctx, locals, range, ast, expected, ast.typeArg, perfMeasurer, candidates));
	endMeasure(ctx.alloc, ctx.perf, perfMeasurer);
	return res;
}

Expr checkCallNoLocals(ref ExprCtx ctx, FileAndRange range, in CallAst ast, ref Expected expected) {
	FunOrLambdaInfo emptyFunInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), [], none!(ExprKind.Lambda*));
	LocalsInfo emptyLocals = LocalsInfo(ptrTrustMe(emptyFunInfo), noneMut!(LocalNode*));
	return checkCall(ctx, emptyLocals, range, ast, expected);
}

private Expr checkCallInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in CallAst ast,
	ref Expected expected,
	in Opt!(TypeAst*) explicitTypeArg,
	ref PerfMeasurer perfMeasurer,
	ref Candidates candidates,
) {
	Sym funName = ast.funName.name;
	size_t arity = ast.args.length;

	foreach (size_t argIdx; 0 .. arity)
		filterByLambdaArity(ctx.alloc, ctx.programState, ctx.commonTypes, candidates, ast.args[argIdx], argIdx);

	filterCandidates(candidates, (ref Candidate candidate) =>
		matchExpectedVsReturnTypeNoDiagnostic(
			ctx.alloc, ctx.programState, expected, candidate.called.returnType, inferringTypeArgs(candidate)));

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
		Expr arg = checkExpr(ctx, locals, ast.args[argIdx], expected);
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

	// Show diags at the function name and not at the whole call ast
	FileAndRange diagRange = FileAndRange(range.fileIndex, rangeOfNameAndRange(ast.funName, ctx.allSymbols));

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

Expr checkIdentifierCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	Sym name,
	ref Expected expected,
) {
	//TODO:NEATER (don't make a synthetic AST, just directly call an appropriate function)
	CallAst callAst = CallAst(CallAst.Style.single, NameAndRange(range.range.start, name), []);
	return checkCallNoLocals(ctx, range, callAst, expected);
}

immutable struct UsedFun {
	immutable struct None {}
	mixin Union!(None, ImportIndex, ModuleLocalFunIndex);
}
static assert(UsedFun.sizeof <= 16);

void markUsedFun(ref ExprCtx ctx, in UsedFun used) {
	used.matchIn!void(
		(in UsedFun.None) {},
		(in ImportIndex it) =>
			markUsedImport(ctx.checkCtx, it),
		(in ModuleLocalFunIndex it) =>
			markUsedLocalFun(ctx, it));
}

void eachFunInScope(ref ExprCtx ctx, Sym funName, in void delegate(UsedFun, CalledDecl) @safe @nogc pure nothrow cb) {
	size_t totalIndex = 0;
	foreach (SpecInst* specInst; ctx.outermostFunSpecs)
		eachFunInScopeForSpec(specInst, totalIndex, funName, cb);

	foreach (ref FunDeclAndIndex f; ctx.funsDict[funName])
		cb(UsedFun(f.index), CalledDecl(f.decl));

	eachImportAndReExport(ctx.checkCtx, funName, (ImportIndex index, in NameReferents it) {
		foreach (FunDecl* f; it.funs)
			cb(UsedFun(index), CalledDecl(f));
	});
}
private void eachFunInScopeForSpec(
	SpecInst* specInst,
	ref size_t totalIndex,
	Sym funName,
	in void delegate(UsedFun, CalledDecl) @safe @nogc pure nothrow cb,
) {
	foreach (SpecInst* parent; specInst.parents)
		eachFunInScopeForSpec(parent, totalIndex, funName, cb);
	specInst.body_.match!void(
		(SpecBody.Builtin) {},
		(SpecDeclSig[] sigs) {
			foreach (size_t i, SpecDeclSig sig; sigs)
				if (sig.name == funName)
					cb(UsedFun(UsedFun.None()), CalledDecl(SpecSig(specInst, &sigs[i], totalIndex + i)));
			totalIndex += sigs.length;
		});
}

private:

size_t maxCandidates() => 64;
alias Candidates = MutMaxArr!(maxCandidates, Candidate);
alias ParamExpected = MutMaxArr!(maxCandidates, TypeAndInferring);

CalledDecl[] candidatesForDiag(ref Alloc alloc, in Candidates candidates) =>
	map(alloc, tempAsArr(candidates), (ref const Candidate c) => c.called);

bool candidateIsPreferred(in Candidate a) =>
	a.called.matchIn!bool(
		(in FunDecl x) =>
			x.flags.preferred,
		(in SpecSig) =>
			false);

struct Candidate {
	immutable UsedFun used;
	immutable CalledDecl called;
	// Note: this is always empty if calling a SpecSig
	MutMaxArr!(maxTypeParams, SingleInferringType) typeArgs;
}
void initializeCandidate(ref Candidate a, UsedFun used, CalledDecl called) {
	overwriteMemory(&a.used, used);
	overwriteMemory(&a.called, called);
	initializeMutMaxArr(a.typeArgs);
}
// TODO: 'b' isn't really const since we're getting mutable 'typeArgs' from it
void overwriteCandidate(ref Candidate a, ref const Candidate b) {
	overwriteMemory(&a.used, b.used);
	overwriteMemory(&a.called, b.called);
	copyToFrom(a.typeArgs, b.typeArgs);
}

inout(InferringTypeArgs) inferringTypeArgs(return scope ref inout Candidate a) =>
	inout InferringTypeArgs(a.called.typeParams, tempAsArr(a.typeArgs));

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

void getInitialCandidates(
	ref ExprCtx ctx,
	scope ref Candidates candidates,
	Sym funName,
	in Opt!(TypeAst*) explicitTypeArg,
	size_t actualArity,
) {
	eachFunInScope(ctx, funName, (UsedFun used, CalledDecl called) @trusted {
		if (arityMatches(arity(called), actualArity)) {
			size_t nTypeParams = called.typeParams.length;
			TypeAst[] args = tryGetMatchingTypeArgs(nTypeParams, explicitTypeArg);
			if (args.length == nTypeParams || args.length == 0) {
				Candidate* candidate = pushUninitialized(candidates);
				initializeCandidate(*candidate, used, called);
				fillMutMaxArr_mut(candidate.typeArgs, nTypeParams, (size_t i) =>
					SingleInferringType(args.length == 0 ? none!Type : some(typeFromAst2(ctx, args[i]))));
			}
		}
	});
}

CalledDecl[] getAllCandidatesAsCalledDecls(ref ExprCtx ctx, Sym funName) {
	ArrBuilder!CalledDecl res = ArrBuilder!CalledDecl();
	eachFunInScope(ctx, funName, (UsedFun, CalledDecl called) {
		add(ctx.alloc, res, called);
	});
	return finishArr(ctx.alloc, res);
}

Type getCandidateExpectedParameterTypeRecur(
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

Type getCandidateExpectedParameterType(
	ref Alloc alloc,
	ref ProgramState programState,
	in Candidate candidate,
	size_t argIdx,
) =>
	getCandidateExpectedParameterTypeRecur(
		alloc,
		programState,
		candidate,
		paramTypeAt(candidate.called.params, argIdx));

Type paramTypeAt(in Params params, size_t argIdx) =>
	params.matchIn!Type(
		(in Param[] x) =>
			x[argIdx].type,
		(in Params.Varargs x) =>
			x.elementType);

void getParamExpected(
	ref Alloc alloc,
	ref ProgramState programState,
	ref ParamExpected paramExpected,
	ref Candidates candidates,
	size_t argIdx,
) {
	foreach (ref Candidate candidate; candidates) {
		Type t = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
		InferringTypeArgs ita = inferringTypeArgs(candidate);
		bool isDuplicate = ita.args.length == 0 &&
			exists!TypeAndInferring(tempAsArr(paramExpected), (in TypeAndInferring x) =>
				x.type == t);
		if (!isDuplicate)
			paramExpected.push(TypeAndInferring(t, ita));
	}
}

Opt!(Diag.CantCall.Reason) getCantCallReason(
	ref ExprCtx ctx,
	bool calledIsVariadicNonEmpty,
	FunFlags calledFlags,
	FunFlags callerFlags,
	bool isCallerInLambda,
) =>
	!calledFlags.noCtx && callerFlags.noCtx && !calledFlags.forceCtx && !isCallerInLambda
		// TODO: need to explain this better in the case where noCtx is due to the lambda
		? some(Diag.CantCall.Reason.nonNoCtx)
		: calledFlags.summon && !callerFlags.summon
		? some(Diag.CantCall.Reason.summon)
		: calledFlags.safety == FunFlags.Safety.unsafe && !checkCanDoUnsafe(ctx)
		? some(Diag.CantCall.Reason.unsafe)
		: calledIsVariadicNonEmpty && callerFlags.noCtx
		? some(Diag.CantCall.Reason.variadicFromNoctx)
		: none!(Diag.CantCall.Reason);

enum ArgsKind { empty, nonEmpty }

void checkCallFlags(
	ref ExprCtx ctx,
	FileAndRange range,
	FunDecl* called,
	FunFlags caller,
	bool isCallerInLambda,
	ArgsKind argsKind,
) {
	Opt!(Diag.CantCall.Reason) reason = getCantCallReason(
		ctx,
		isVariadic(*called) && argsKind == ArgsKind.nonEmpty,
		called.flags,
		caller,
		isCallerInLambda);
	if (has(reason))
		addDiag2(ctx, range, Diag(Diag.CantCall(force(reason), called)));
}

void checkCalledDeclFlags(
	ref ExprCtx ctx,
	bool isInLambda,
	in CalledDecl res,
	FileAndRange range,
	ArgsKind argsKind,
) {
	res.matchWithPointers!void(
		(FunDecl* f) {
			checkCallFlags(ctx, range, f, ctx.outermostFunFlags, isInLambda, argsKind);
		},
		// For a spec, we check the flags when providing the spec impl
		(SpecSig) {});
}

bool testCandidateForSpecSig(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref Candidate specCandidate,
	in SpecDeclSig specSig,
	in InferringTypeArgs callInferringTypeArgs,
) {
	bool res = matchTypesNoDiagnostic(
		alloc, programState,
		specCandidate.called.returnType, inferringTypeArgs(specCandidate),
		specSig.returnType, callInferringTypeArgs);
	return res && everyInRange(specSigNParams(specSig), (size_t argIdx) =>
		testCandidateParamType(
			alloc, programState,
			specCandidate, paramTypeAt(specSig.params, argIdx), argIdx, callInferringTypeArgs));
}

void inferCandidateTypeArgsFromCheckedSpecSig(
	ref Alloc alloc,
	ref ProgramState programState,
	in Candidate specCandidate,
	in SpecDeclSig specSig,
	scope InferringTypeArgs callInferringTypeArgs,
) {
	inferTypeArgsFrom(
		alloc, programState, specSig.returnType, callInferringTypeArgs,
		specCandidate.called.returnType, inferringTypeArgs(specCandidate));
	foreach (size_t argIdx; 0 .. specSigNParams(specSig))
		inferTypeArgsFrom(
			alloc, programState,
			paramTypeAt(specSig.params, argIdx),
			callInferringTypeArgs,
			getCandidateExpectedParameterType(alloc, programState, specCandidate, argIdx),
			inferringTypeArgs(specCandidate));
}

bool everyInRange(size_t n, in bool delegate(size_t) @safe @nogc pure nothrow cb) {
	foreach (size_t i; 0 .. n)
		if (!cb(i))
			return false;
	return true;
}

void filterByLambdaArity(
	ref Alloc alloc,
	ref ProgramState programState,
	in CommonTypes commonTypes,
	scope ref Candidates candidates,
	in ExprAst arg,
	size_t argIdx,
) {
	Opt!size_t optArity = getLambdaArity(arg.kind);
	if (has(optArity)) {
		size_t arity = force(optArity);
		filterCandidates(candidates, (ref Candidate candidate) {
			Type expectedArgType = getCandidateExpectedParameterType(alloc, programState, candidate, argIdx);
			return mayBeFunTypeWithArity(commonTypes, expectedArgType, inferringTypeArgs(candidate), arity);
		});
	}
}

Opt!size_t getLambdaArity(in ExprAstKind a) =>
	a.isA!(LambdaAst*)
	? some(a.as!(LambdaAst*).params.length)
	: a.isA!(ParenthesizedAst*)
	? getLambdaArity(a.as!(ParenthesizedAst*).inner.kind)
	: none!size_t;

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

bool inferCandidateTypeArgsFromSpecs(ref ExprCtx ctx, scope ref Candidate candidate) {
	// For performance, don't bother unless we have something to infer from already
	if (isPartiallyInferred(candidate.typeArgs)) {
		return candidate.called.match!bool(
			(ref FunDecl called) =>
				every!(immutable SpecInst*)(called.specs, (in immutable SpecInst* spec) =>
					inferCandidateTypeArgsFromSpecInst(ctx, candidate, called, *spec)),
			(SpecSig _) => true);
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
	) && spec.body_.match!bool(
		(SpecBody.Builtin) =>
			// figure this out at the end
			true,
		(SpecDeclSig[] sigs) {
			foreach (ref SpecDeclSig sig; sigs)
				if (!inferCandidateTypeArgsFromSpecSig(ctx, callCandidate, called, sig)) {
					return false;
				}
			return true;
		});
}

bool inferCandidateTypeArgsFromSpecSig(
	ref ExprCtx ctx,
	scope ref Candidate callCandidate,
	in FunDecl called,
	in SpecDeclSig specSig,
) =>
	withCandidates(ctx, specSig.name, none!(TypeAst*), specSigNParams(specSig), (ref Candidates specCandidates) {
		const InferringTypeArgs constCallInferring = inferringTypeArgs(callCandidate);
		filterCandidates(specCandidates, (ref Candidate specCandidate) =>
			testCandidateForSpecSig(ctx.alloc, ctx.programState, specCandidate, specSig, constCallInferring));

		switch (size(specCandidates)) {
			case 0:
				return false;
			case 1:
				inferCandidateTypeArgsFromCheckedSpecSig(
					ctx.alloc, ctx.programState, only(specCandidates), specSig, inferringTypeArgs(callCandidate));
				return true;
			default:
				return true;
		}
	});

Opt!Called findSpecSigImplementation(
	ref ExprCtx ctx,
	bool isInLambda,
	FileAndRange range,
	ref SpecDeclSig specSig,
	ref SpecTrace trace,
) {
	size_t nParams = specSigNParams(specSig);
	return withCandidates(ctx, specSig.name, none!(TypeAst*), nParams, (ref Candidates candidates) {
		filterCandidates(candidates, (scope ref Candidate candidate) =>
			testCandidateForSpecSig(ctx.alloc, ctx.programState, candidate, specSig, InferringTypeArgs()));

		// If any candidates left take specs -- leave as a TODO
		switch (mutMaxArrSize(candidates)) {
			case 0:
				// TODO: use initial candidates in the error message
				addDiag2(ctx, range, Diag(Diag.SpecImplNotFound(specSig, toArray(ctx.alloc, trace))));
				return none!Called;
			case 1:
				return getCalledFromCandidate(ctx, isInLambda, range, only(candidates), ArgsKind.nonEmpty, trace);
			default:
				addDiag2(ctx, range, Diag(
					Diag.SpecImplFoundMultiple(specSig.name, candidatesForDiag(ctx.alloc, candidates))));
				return none!Called;
		}
	});
}

size_t specSigNParams(ref SpecDeclSig a) =>
	arity(a).match!size_t(
		(size_t n) =>
			n,
		(Arity.Varargs) =>
			todo!size_t("varargs in spec?"));

bool checkBuiltinSpec(ref ExprCtx ctx, FunDecl* called, FileAndRange range, SpecBody.Builtin.Kind kind, Type typeArg) {
	bool typeIsGood = isPurityAlwaysCompatibleConsideringSpecs(ctx, typeArg, purityOfBuiltinSpec(kind));
	if (!typeIsGood)
		addDiag2(ctx, range, Diag(Diag.SpecBuiltinNotSatisfied(kind, typeArg, called)));
	return typeIsGood;
}

Purity purityOfBuiltinSpec(SpecBody.Builtin.Kind kind) {
	final switch (kind) {
		case SpecBody.Builtin.Kind.data:
			return Purity.data;
		case SpecBody.Builtin.Kind.shared_:
			return Purity.shared_;
	}
}

public bool isPurityAlwaysCompatibleConsideringSpecs(ref ExprCtx ctx, Type type, Purity expected) {
	PurityRange typePurity = purityRange(type);
	return isPurityAlwaysCompatible(expected, typePurity) ||
		exists!(SpecInst*)(ctx.outermostFunSpecs, (in SpecInst* inst) =>
			specProvidesPurity(inst, type, expected)) ||
		(type.isA!(StructInst*) &&
			isPurityCompatible(expected, typePurity.bestCase) &&
			every!Type(typeArgs(*type.as!(StructInst*)), (in Type typeArg) =>
				isPurityAlwaysCompatibleConsideringSpecs(ctx, typeArg, expected)));
}

// Whether 'inst' tells us that 'type' has purity at least 'expected'
bool specProvidesPurity(in SpecInst* inst, in Type type, Purity expected) =>
	exists!(SpecInst*)(inst.parents, (in SpecInst* parent) =>
		specProvidesPurity(parent, type, expected)) ||
	inst.body_.matchIn!bool(
		(in SpecBody.Builtin b) =>
			only(typeArgs(*inst)) == type && isPurityCompatible(expected, purityOfBuiltinSpec(b.kind)),
		(in SpecDeclSig[]) =>
			false);

alias SpecImpls = MutMaxArr!(maxSpecImpls, Called);
alias SpecTrace = MutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);

// On failure, returns false
bool checkSpecImpls(
	ref SpecImpls res,
	ref ExprCtx ctx,
	bool isInLambda,
	FileAndRange range,
	FunDecl* called,
	Type[] calledTypeArgs,
	ref SpecTrace trace,
) {
	foreach (SpecInst* specInst; called.specs) {
		// specInst was instantiated potentially based on f's params.
		// Meed to instantiate it again.
		SpecInst* specInstInstantiated = instantiateSpecInst(
			ctx.alloc, ctx.programState, specInst,
			TypeParamsAndArgs(called.typeParams, calledTypeArgs), noDelaySpecInsts);
		if (!checkSpecImpl(res, ctx, isInLambda, range, called, trace, specInstInstantiated))
			return false;
	}
	return true;
}

bool checkSpecImpl(
	ref SpecImpls res,
	ref ExprCtx ctx,
	bool isInLambda,
	FileAndRange range,
	FunDecl* called,
	ref SpecTrace trace,
	SpecInst* specInstInstantiated) {
	foreach (SpecInst* parent; specInstInstantiated.parents)
		if (!checkSpecImpl(res, ctx, isInLambda, range, called, trace, parent))
			return false;
	Type[] typeArgs = typeArgs(*specInstInstantiated);
	return specInstInstantiated.body_.match!bool(
		(SpecBody.Builtin b) =>
			checkBuiltinSpec(ctx, called, range, b.kind, only(typeArgs)),
		(SpecDeclSig[] sigs) {
			push(trace, FunDeclAndTypeArgs(called, typeArgs));
			foreach (ref SpecDeclSig sig; sigs) {
				Opt!Called impl = findSpecSigImplementation(ctx, isInLambda, range, sig, trace);
				if (!has(impl))
					return false;
				push(res, force(impl));
			}
			mustPop(trace);
			return true;
		});
}

Opt!Called getCalledFromCandidate(
	ref ExprCtx ctx,
	bool isInLambda,
	FileAndRange range,
	ref const Candidate candidate,
	ArgsKind argsKind,
	ref SpecTrace trace,
) {
	markUsedFun(ctx, candidate.used);
	checkCalledDeclFlags(ctx, isInLambda, candidate.called, range, argsKind);

	TypeArgsArray candidateTypeArgs = typeArgsArray();
	foreach (ref const SingleInferringType x; tempAsArr(candidate.typeArgs)) {
		Opt!Type t = tryGetInferred(x);
		if (has(t))
			push(candidateTypeArgs, force(t));
		else {
			addDiag2(ctx, range, Diag(Diag.CantInferTypeArguments(candidate.called.as!(FunDecl*))));
			return none!Called;
		}
	}
	return candidate.called.matchWithPointers!(Opt!Called)(
		(FunDecl* f) {
			if (isFull(trace)) {
				addDiag2(ctx, range, Diag(Diag.SpecImplTooDeep(toArray(ctx.alloc, trace))));
				return none!Called;
			} else {
				SpecImpls specImpls = mutMaxArr!(maxSpecImpls, Called);
				return checkSpecImpls(specImpls, ctx, isInLambda, range, f, tempAsArr(candidateTypeArgs), trace)
					? some(Called(
						instantiateFun(
							ctx.alloc,
							ctx.programState,
							f,
							tempAsArr(candidateTypeArgs),
							tempAsArr(specImpls))))
					: none!Called;
			}
		},
		(SpecSig s) =>
			some(Called(allocate(ctx.alloc, s))));
}

Expr checkCallAfterChoosingOverload(
	ref ExprCtx ctx,
	bool isInLambda,
	ref const Candidate candidate,
	FileAndRange range,
	Expr[] args,
	ref Expected expected,
) {
	SpecTrace trace = mutMaxArr!(maxSpecDepth, FunDeclAndTypeArgs);
	Opt!Called opCalled = getCalledFromCandidate(
		ctx, isInLambda, range, candidate, empty(args) ? ArgsKind.empty : ArgsKind.nonEmpty, trace);
	if (has(opCalled)) {
		Called called = force(opCalled);
		Expr calledExpr = Expr(range, ExprKind(ExprKind.Call(called, args)));
		//TODO: PERF second return type check may be unnecessary
		// if we already filtered by return type at the beginning
		return check(ctx, expected, called.returnType, calledExpr);
	} else
		return bogus(expected, range);
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
