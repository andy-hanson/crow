module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.checkConcreteModel : checkConcreteProgram, ConcreteCommonTypes;
import concretize.concretizeCtx :
	boolType,
	char8Type,
	char32Type,
	concreteFunForWrapMain,
	ConcreteLambdaImpl,
	ConcreteVariantMember,
	ConcretizeCtx,
	deferredFillRecordAndUnionBodies,
	exceptionType,
	finishConcreteVars,
	getConcreteFun,
	getNonTemplateConcreteFun,
	getVar,
	nat64Type,
	symbolType,
	symbolArrayType,
	voidType;
import concretize.gatherInfo : getYieldingFuns;
import concretize.generate : generateCallLambda;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructInfo,
	ConcreteStructBody,
	ConcreteType,
	mustBeByVal;
import model.model : BuiltinFun, CommonFuns, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
import util.col.array : map, small;
import util.col.arrayBuilder : asTemporaryArray, finish;
import util.col.mutArr : asTemporaryArray, moveAndMapToArray, MutArr, push;
import util.col.mutMap : mustGet;
import util.late : late, lateSet;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.util : castNonScope_ref, ptrTrustMe;
import versionInfo : VersionInfo;

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
	lateSet(ctx.createErrorFunction_, getNonTemplateConcreteFun(ctx, commonFuns.createError));
	lateSet(ctx.char8ArrayTrustAsString_, getNonTemplateConcreteFun(ctx, commonFuns.char8ArrayTrustAsString));
	lateSet(ctx.equalNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.equalNat64));
	lateSet(ctx.lessNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.lessNat64));
	lateSet(ctx.newChar8ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char8Type(ctx)], []));
	lateSet(ctx.newChar32ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char32Type(ctx)], []));
	lateSet(ctx.newJsonFromPairsFunction_, getNonTemplateConcreteFun(ctx, commonFuns.newJsonFromPairs));
	ConcreteCommonFuns concreteCommonFuns = ConcreteCommonFuns(
		alloc: getNonTemplateConcreteFun(ctx, commonFuns.allocate),
		curJmpBuf: getNonTemplateConcreteFun(ctx, commonFuns.curJmpBuf),
		setCurJmpBuf: getNonTemplateConcreteFun(ctx, commonFuns.setCurJmpBuf),
		curThrown: getVar(ctx, commonFuns.curThrown),
		mark: getNonTemplateConcreteFun(ctx, commonFuns.mark),
		rethrowCurrentException: getNonTemplateConcreteFun(ctx, commonFuns.rethrowCurrentException),
		runFiber: getNonTemplateConcreteFun(ctx, commonFuns.runFiber),
		rtMain: getNonTemplateConcreteFun(ctx, commonFuns.rtMain),
		setjmp: getNonTemplateConcreteFun(ctx, commonFuns.setjmp),
		throwImpl: getNonTemplateConcreteFun(ctx, commonFuns.throwImpl),
		userMain: concretizeMainFun(ctx, program.mainFun),
		gcRoot: getNonTemplateConcreteFun(ctx, commonFuns.gcRoot),
		setGcRoot: getNonTemplateConcreteFun(ctx, commonFuns.setGcRoot),
		popGcRoot: getNonTemplateConcreteFun(ctx, commonFuns.popGcRoot));

	finishLambdas(ctx);

	immutable ConcreteFun*[] allConcreteFuns = finish(alloc, ctx.allConcreteFuns);

	foreach (ConcreteStruct* variant, MutArr!ConcreteVariantMember x; ctx.variantStructToMembers)
		lateSet(
			variant.body_.as!(ConcreteStructBody.Union).members_,
			moveAndMapToArray(alloc, x, (ref ConcreteVariantMember member) => member.type));

	deferredFillRecordAndUnionBodies(ctx);

	ConcreteProgram res = ConcreteProgram(
		versionInfo,
		finishAllConstants(alloc, ctx.allConstants, symbolArrayType(ctx)),
		finish(alloc, ctx.allConcreteStructs),
		finishConcreteVars(ctx),
		allConcreteFuns,
		getYieldingFuns(alloc, concreteCommonFuns, allConcreteFuns),
		concreteCommonFuns);
	checkConcreteProgram(
		showCtx,
		ConcreteCommonTypes(
			bool_: boolType(ctx),
			exception: exceptionType(ctx),
			nat64: nat64Type(ctx),
			symbol: symbolType(ctx),
			void_: voidType(ctx)),
		res);
	return res;
}

ConcreteFun* concretizeMainFun(ref ConcretizeCtx ctx, ref MainFun main) =>
	main.match!(ConcreteFun*)(
		(MainFun.Nat64OfArgs x) =>
			getNonTemplateConcreteFun(ctx, x.fun),
		(MainFun.Void x) =>
			concreteFunForWrapMain(ctx, x.stringList, x.fun));

void finishLambdas(ref ConcretizeCtx ctx) {
	foreach (ConcreteStruct* struct_, MutArr!ConcreteLambdaImpl impls; ctx.lambdaStructToImpls) {
		ConcreteType[] memberTypes = map(ctx.alloc, asTemporaryArray(impls), (ref ConcreteLambdaImpl x) =>
			x.closureType);
		struct_.info = ConcreteStructInfo(
			body_: ConcreteStructBody(ConcreteStructBody.Union(late(small!ConcreteType(memberTypes)))),
			isSelfMutable: false);
		push(ctx.alloc, ctx.deferredTypeSize, struct_);
	}

	foreach (ConcreteFun* fun; asTemporaryArray(ctx.allConcreteFuns)) {
		if (fun.body_.isA!(ConcreteFunBody.Builtin)) {
			ConcreteFunBody.Builtin builtin = fun.body_.as!(ConcreteFunBody.Builtin);
			if (builtin.kind.isA!(BuiltinFun.CallLambda)) {
				ConcreteStruct* lambda = mustBeByVal(fun.params[0].type);
				fun.overwriteBody(generateCallLambda(
					ctx, fun, lambda.body_.as!(ConcreteStructBody.Union).members,
					asTemporaryArray(mustGet(ctx.lambdaStructToImpls, lambda))));
			}
		}
	}
}
