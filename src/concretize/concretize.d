module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.checkConcreteModel : checkConcreteProgram, ConcreteCommonTypes;
import concretize.concretizeCtx :
	boolType,
	char8Type,
	char32Type,
	concreteFunForWrapMain,
	ConcretizeCtx,
	deferredFillRecordAndUnionBodies,
	finishConcreteVars,
	getOrAddConcreteFunAndFillBody,
	getOrAddNonTemplateConcreteFunAndFillBody,
	nat64Type,
	stringType,
	symbolType,
	symbolArrayType,
	voidType;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	ConcreteCommonFuns, ConcreteFun, ConcreteFunKey, ConcreteLambdaImpl, ConcreteProgram, ConcreteStruct, ConcreteType;
import model.model : CommonFuns, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
import util.col.array : emptySmallArray, newSmallArray;
import util.col.arrayBuilder : finish;
import util.col.mutArr : moveToArray, MutArr;
import util.col.mutMap : isEmpty, mapToMap;
import util.late : lateSet;
import util.opt : Opt, optIf;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.util : castNonScope_ref, ptrTrustMe;
import versionInfo : isVersion, VersionFun, VersionInfo;

ConcreteProgram concretize(
	scope ref Perf perf,
	ref Alloc alloc,
	in ShowCtx showCtx,
	in VersionInfo versionInfo,
	ref ProgramWithMain program,
	in FileContentGetters fileContentGetters,
) =>
	withMeasure!(ConcreteProgram, () =>
		concretizeInner(&alloc, showCtx, versionInfo, program, fileContentGetters)
	)(perf, alloc, PerfMeasure.concretize);

private:

ConcreteProgram concretizeInner(
	Alloc* allocPtr,
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
		program.program.commonTypes,
		ptrTrustMe(program.program),
		castNonScope_ref(fileContentGetters));
	CommonFuns commonFuns = program.program.commonFuns;
	lateSet(ctx.char8ArrayTrustAsString_, getOrAddNonTemplateConcreteFunAndFillBody(
		ctx, commonFuns.char8ArrayTrustAsString));
	lateSet(ctx.equalNat64Function_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.equalNat64));
	lateSet(ctx.lessNat64Function_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.lessNat64));
	lateSet(ctx.newNat64FutureFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newTFuture,
		//TODO:avoid alloc
		newSmallArray(ctx.alloc, [nat64Type(ctx)]),
		emptySmallArray!(immutable ConcreteFun*))));
	lateSet(ctx.newVoidFutureFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		commonFuns.newTFuture,
		//TODO:avoid alloc
		newSmallArray(ctx.alloc, [voidType(ctx)]),
		emptySmallArray!(immutable ConcreteFun*))));
	lateSet(ctx.andFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		commonFuns.and.decl,
		emptySmallArray!ConcreteType,
		emptySmallArray!(immutable ConcreteFun*))));
	lateSet(ctx.newChar8ListFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newTList,
		newSmallArray(ctx.alloc, [char8Type(ctx)]),
		emptySmallArray!(immutable ConcreteFun*))));
	lateSet(ctx.newChar32ListFunction_, getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newTList,
		newSmallArray(ctx.alloc, [char32Type(ctx)]),
		emptySmallArray!(immutable ConcreteFun*))));
	lateSet(ctx.newJsonFromPairsFunction_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.newJsonFromPairs));
	ConcreteFun* markFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.mark);
	ConcreteFun* rtMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.rtMain);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));
	ConcreteFun* userMainConcreteFun = concretizeMainFun(ctx, program.mainFun);
	ConcreteFun* allocFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.alloc);
	Opt!(ConcreteFun*) throwImplFun = optIf(!isVersion(versionInfo, VersionFun.isAbortOnThrow), () =>
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.throwImpl));
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finish(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	ConcreteProgram res = ConcreteProgram(
		versionInfo,
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
	checkConcreteProgram(
		showCtx,
		ConcreteCommonTypes(boolType(ctx), nat64Type(ctx), stringType(ctx), symbolType(ctx), voidType(ctx)),
		res);
	return res;
}

ConcreteFun* concretizeMainFun(ref ConcretizeCtx ctx, ref MainFun main) =>
	main.match!(ConcreteFun*)(
		(MainFun.Nat64Future x) =>
			getOrAddNonTemplateConcreteFunAndFillBody(ctx, x.fun),
		(MainFun.Void x) =>
			concreteFunForWrapMain(ctx, x.stringList, x.fun));
