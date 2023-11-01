module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.checkConcreteModel : checkConcreteProgram, ConcreteCommonTypes;
import concretize.concretizeCtx :
	boolType,
	concreteFunForWrapMain,
	ConcretizeCtx,
	cStrType,
	deferredFillRecordAndUnionBodies,
	getOrAddNonTemplateConcreteFunAndFillBody,
	voidType;
import frontend.showModel : ShowCtx;
import model.concreteModel :
	ConcreteCommonFuns, ConcreteFun, ConcreteLambdaImpl, ConcreteProgram, ConcreteStruct, mustBeByVal;
import model.model : CommonFuns, MainFun, Program;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : finishArr;
import util.col.mutArr : moveToArr, MutArr;
import util.col.mutMap : mapToMap, moveToValues, mutMapIsEmpty;
import util.late : lateSet;
import util.opt : force;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.util : verify;
import versionInfo : VersionInfo;

ConcreteProgram concretize(
	ref Alloc alloc,
	scope ref Perf perf,
	ref ShowCtx printCtx,
	in VersionInfo versionInfo,
	ref Program program,
) =>
	withMeasure!(ConcreteProgram, () =>
		concretizeInner(&alloc, printCtx, versionInfo, program)
	)(alloc, perf, PerfMeasure.concretize);

private:

ConcreteProgram concretizeInner(
	Alloc* allocPtr,
	ref ShowCtx printCtx,
	in VersionInfo versionInfo,
	ref Program program,
) {
	ref Alloc alloc() =>
		*allocPtr;
	ConcretizeCtx ctx = ConcretizeCtx(
		allocPtr,
		versionInfo,
		printCtx.allSymbolsPtr,
		ptrTrustMe(program.commonTypes),
		ptrTrustMe(program));
	CommonFuns commonFuns = program.commonFuns;
	lateSet(ctx.curExclusionFun_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.curExclusion));
	ConcreteFun* markFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.mark);
	ConcreteFun* rtMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.rtMain);
	// We remove items from these maps when we process them.
	verify(mutMapIsEmpty(ctx.concreteFunToBodyInputs));
	ConcreteFun* userMainConcreteFun = concretizeMainFun(ctx, force(commonFuns.main));
	ConcreteFun* allocFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.alloc);
	ConcreteFun* throwImplFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.throwImpl);
	ConcreteFun* staticSymbolsFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.staticSymbols);
	// We remove items from these maps when we process them.
	verify(mutMapIsEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finishArr(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	ConcreteProgram res = ConcreteProgram(
		finishAllConstants(alloc, ctx.allConstants, mustBeByVal(staticSymbolsFun.returnType)),
		finishArr(alloc, ctx.allConcreteStructs),
		moveToValues(alloc, ctx.concreteVarLookup),
		allConcreteFuns,
		mapToMap!(ConcreteStruct*, ConcreteLambdaImpl[], MutArr!ConcreteLambdaImpl)(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!ConcreteLambdaImpl it) =>
				moveToArr(alloc, it)),
		ConcreteCommonFuns(
			allocFun,
			commonFuns.funOrActSubscriptFunDecls,
			markFun,
			commonFuns.markVisitFunDecl,
			rtMainConcreteFun,
			throwImplFun,
			userMainConcreteFun));
	checkConcreteProgram(printCtx, ConcreteCommonTypes(boolType(ctx), cStrType(ctx), voidType(ctx)), res);
	return res;
}

ConcreteFun* concretizeMainFun(ref ConcretizeCtx ctx, ref MainFun main) =>
	main.match!(ConcreteFun*)(
		(MainFun.Nat64Future x) =>
			getOrAddNonTemplateConcreteFunAndFillBody(ctx, x.fun),
		(MainFun.Void x) =>
			concreteFunForWrapMain(ctx, x.stringList, x.fun));
