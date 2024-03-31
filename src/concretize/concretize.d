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
	getConcreteFun,
	getNonTemplateConcreteFun,
	nat64Type,
	stringType,
	symbolType,
	symbolArrayType,
	voidType;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.concreteModel : ConcreteCommonFuns, ConcreteFun, ConcreteLambdaImpl, ConcreteProgram, ConcreteStruct;
import model.model : CommonFuns, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
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
	lateSet(ctx.char8ArrayTrustAsString_, getNonTemplateConcreteFun(ctx, commonFuns.char8ArrayTrustAsString));
	lateSet(ctx.equalNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.equalNat64));
	lateSet(ctx.lessNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.lessNat64));
	lateSet(ctx.newNat64FutureFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTFuture, [nat64Type(ctx)], []));
	lateSet(ctx.newVoidFutureFunction_, getConcreteFun(ctx, commonFuns.newTFuture, [voidType(ctx)], []));
	lateSet(ctx.andFunction_, getNonTemplateConcreteFun(ctx, commonFuns.and));
	lateSet(ctx.newChar8ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char8Type(ctx)], []));
	lateSet(ctx.newChar32ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char32Type(ctx)], []));
	lateSet(ctx.newJsonFromPairsFunction_, getNonTemplateConcreteFun(ctx, commonFuns.newJsonFromPairs));
	ConcreteFun* markFun = getNonTemplateConcreteFun(ctx, commonFuns.mark);
	ConcreteFun* rtMainConcreteFun = getNonTemplateConcreteFun(ctx, commonFuns.rtMain);
	// We remove items from these maps when we process them.
	assert(isEmpty(ctx.concreteFunToBodyInputs));
	ConcreteFun* userMainConcreteFun = concretizeMainFun(ctx, program.mainFun);
	ConcreteFun* allocFun = getNonTemplateConcreteFun(ctx, commonFuns.alloc);
	Opt!(ConcreteFun*) throwImplFun = optIf(!isVersion(versionInfo, VersionFun.isAbortOnThrow), () =>
		getNonTemplateConcreteFun(ctx, commonFuns.throwImpl));
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
			getNonTemplateConcreteFun(ctx, x.fun),
		(MainFun.Void x) =>
			concreteFunForWrapMain(ctx, x.stringList, x.fun));
