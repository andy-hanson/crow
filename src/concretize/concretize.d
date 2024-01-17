module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.checkConcreteModel : checkConcreteProgram, ConcreteCommonTypes;
import concretize.concretizeCtx :
	boolType,
	concreteFunForWrapMain,
	ConcretizeCtx,
	deferredFillRecordAndUnionBodies,
	finishConcreteVars,
	getOrAddConcreteFunAndFillBody,
	getOrAddNonTemplateConcreteFunAndFillBody,
	stringType,
	symbolArrayType,
	voidType;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	ConcreteCommonFuns, ConcreteFun, ConcreteFunKey, ConcreteLambdaImpl, ConcreteProgram, ConcreteStruct;
import model.model : CommonFuns, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
import util.col.array : emptySmallArray, newSmallArray;
import util.col.arrayBuilder : finish;
import util.col.mutArr : moveToArray, MutArr;
import util.col.mutMap : isEmpty, mapToMap;
import util.late : lateSet;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.symbol : AllSymbols;
import util.util : castNonScope, castNonScope_ref, ptrTrustMe;
import versionInfo : VersionInfo;

ConcreteProgram concretize(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in ShowCtx showCtx,
	in VersionInfo versionInfo,
	ref ProgramWithMain program,
	in FileContentGetters fileContentGetters,
) =>
	withMeasure!(ConcreteProgram, () =>
		concretizeInner(&alloc, allSymbols, showCtx, versionInfo, program, fileContentGetters)
	)(perf, alloc, PerfMeasure.concretize);

private:

ConcreteProgram concretizeInner(
	Alloc* allocPtr,
	scope ref AllSymbols allSymbols,
	in ShowCtx showCtx,
	in VersionInfo versionInfo,
	ref ProgramWithMain program,
	in FileContentGetters fileContentGetters,
) {
	ref Alloc alloc() =>
		*allocPtr;
	ConcretizeCtx ctx = ConcretizeCtx(
		allocPtr,
		versionInfo,
		ptrTrustMe(allSymbols),
		castNonScope(showCtx.allUrisPtr),
		program.program.commonTypes,
		ptrTrustMe(program.program),
		castNonScope_ref(fileContentGetters));
	CommonFuns commonFuns = program.program.commonFuns;
	lateSet(ctx.curExclusionFun_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.curExclusion));
	lateSet(ctx.char8ArrayAsString_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.char8ArrayAsString));
	lateSet(ctx.newVoidFutureFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newVoidFuture.decl,
		//TODO:avoid alloc
		newSmallArray(ctx.alloc, [voidType(ctx)]),
		emptySmallArray!(immutable ConcreteFun*))));
	ConcreteFun* markFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.mark);
	ConcreteFun* rtMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.rtMain);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));
	ConcreteFun* userMainConcreteFun = concretizeMainFun(ctx, program.mainFun);
	ConcreteFun* allocFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.alloc);
	ConcreteFun* throwImplFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.throwImpl);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finish(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	ConcreteProgram res = ConcreteProgram(
		finishAllConstants(alloc, ctx.allConstants, symbolArrayType(ctx)),
		finish(alloc, ctx.allConcreteStructs),
		finishConcreteVars(ctx),
		allConcreteFuns,
		mapToMap!(ConcreteStruct*, ConcreteLambdaImpl[], MutArr!ConcreteLambdaImpl)(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!ConcreteLambdaImpl it) =>
				moveToArray(alloc, it)),
		ConcreteCommonFuns(
			allocFun,
			markFun,
			rtMainConcreteFun,
			throwImplFun,
			userMainConcreteFun));
	checkConcreteProgram(showCtx, ConcreteCommonTypes(boolType(ctx), stringType(ctx), voidType(ctx)), res);
	return res;
}

ConcreteFun* concretizeMainFun(ref ConcretizeCtx ctx, ref MainFun main) =>
	main.match!(ConcreteFun*)(
		(MainFun.Nat64Future x) =>
			getOrAddNonTemplateConcreteFunAndFillBody(ctx, x.fun),
		(MainFun.Void x) =>
			concreteFunForWrapMain(ctx, x.stringList, x.fun));
