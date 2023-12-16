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
	finishConcreteVars,
	getOrAddNonTemplateConcreteFunAndFillBody,
	voidType;
import frontend.showModel : ShowCtx;
import frontend.storage : ReadFileResult;
import model.concreteModel :
	ConcreteCommonFuns, ConcreteFun, ConcreteLambdaImpl, ConcreteProgram, ConcreteStruct, mustBeByVal;
import model.model : CommonFuns, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : finishArr;
import util.col.map : Map;
import util.col.mutArr : moveToArr, MutArr;
import util.col.mutMap : isEmpty, mapToMap;
import util.late : lateSet;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.uri : Uri;
import util.util : castNonScope, ptrTrustMe;
import versionInfo : VersionInfo;

ConcreteProgram concretize(
	scope ref Perf perf,
	ref Alloc alloc,
	in ShowCtx printCtx,
	in VersionInfo versionInfo,
	ref ProgramWithMain program,
	Map!(Uri, ReadFileResult) fileContents,
) =>
	withMeasure!(ConcreteProgram, () =>
		concretizeInner(&alloc, printCtx, versionInfo, program, fileContents)
	)(perf, alloc, PerfMeasure.concretize);

private:

ConcreteProgram concretizeInner(
	Alloc* allocPtr,
	in ShowCtx printCtx,
	in VersionInfo versionInfo,
	ref ProgramWithMain program,
	Map!(Uri, ReadFileResult) fileContents,
) {
	ref Alloc alloc() =>
		*allocPtr;
	ConcretizeCtx ctx = ConcretizeCtx(
		allocPtr,
		versionInfo,
		castNonScope(printCtx.allSymbolsPtr),
		castNonScope(printCtx.allUrisPtr),
		ptrTrustMe(program.program.commonTypes),
		ptrTrustMe(program.program),
		fileContents);
	CommonFuns commonFuns = program.program.commonFuns;
	lateSet(ctx.curExclusionFun_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.curExclusion));
	lateSet(ctx.char8ArrayAsString_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.char8ArrayAsString));
	ConcreteFun* markFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.mark);
	ConcreteFun* rtMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.rtMain);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));
	ConcreteFun* userMainConcreteFun = concretizeMainFun(ctx, program.mainFun);
	ConcreteFun* allocFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.alloc);
	ConcreteFun* throwImplFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.throwImpl);
	ConcreteFun* staticSymbolsFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.staticSymbols);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finishArr(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	ConcreteProgram res = ConcreteProgram(
		finishAllConstants(alloc, ctx.allConstants, mustBeByVal(staticSymbolsFun.returnType)),
		finishArr(alloc, ctx.allConcreteStructs),
		finishConcreteVars(ctx),
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
