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
	ConcreteVariantMemberAndMethodImpls,
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
import concretize.generate : generateCallLambda, generateCallVariantMethod;
import frontend.showModel : ShowCtx;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteProgram,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	ConcreteType,
	mustBeByVal;
import model.model : BuiltinExtern, BuiltinFun, CommonFuns, Config, FunBody, MainFun, ProgramWithMain;
import util.alloc.alloc : Alloc;
import util.col.array : map, small;
import util.col.arrayBuilder : asTemporaryArray, finish;
import util.col.map : keys;
import util.col.mutArr : asTemporaryArray, MutArr, push;
import util.col.mutMap : mustGet;
import util.late : late, lateSet;
import util.opt : has, Opt;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.symbol : Symbol, symbol, symbolOfEnum;
import util.symbolSet : buildSymbolSet, SymbolSet, SymbolSetBuilder;
import util.uri : Uri;
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
		ptrTrustMe(program.program),
		castNonScope_ref(fileContentGetters),
		allExterns(*program.mainConfig));
	CommonFuns commonFuns = program.program.commonFuns;
	lateSet(ctx.createErrorFunction_, getNonTemplateConcreteFun(ctx, commonFuns.createError));
	lateSet(ctx.equalNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.equalNat64));
	lateSet(ctx.lessNat64Function_, getNonTemplateConcreteFun(ctx, commonFuns.lessNat64));
	lateSet(ctx.newChar8ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char8Type(ctx)], []));
	lateSet(ctx.newChar32ListFunction_, getConcreteFun(ctx, ctx.program.commonFuns.newTList, [char32Type(ctx)], []));
	lateSet(ctx.newJsonFromPairsFunction_, getNonTemplateConcreteFun(ctx, commonFuns.newJsonFromPairs));
	ConcreteCommonFuns concreteCommonFuns = ConcreteCommonFuns(
		alloc: getNonTemplateConcreteFun(ctx, commonFuns.allocate),
		curCatchPoint: getNonTemplateConcreteFun(ctx, commonFuns.curCatchPoint),
		setCurCatchPoint: getNonTemplateConcreteFun(ctx, commonFuns.setCurCatchPoint),
		curThrown: getVar(ctx, commonFuns.curThrown),
		mark: getNonTemplateConcreteFun(ctx, commonFuns.mark),
		rethrowCurrentException: getNonTemplateConcreteFun(ctx, commonFuns.rethrowCurrentException),
		runFiber: getNonTemplateConcreteFun(ctx, commonFuns.runFiber),
		rtMain: getNonTemplateConcreteFun(ctx, commonFuns.rtMain),
		throwImpl: getNonTemplateConcreteFun(ctx, commonFuns.throwImpl),
		userMain: concretizeMainFun(ctx, program.mainFun),
		gcRoot: getNonTemplateConcreteFun(ctx, commonFuns.gcRoot),
		setGcRoot: getNonTemplateConcreteFun(ctx, commonFuns.setGcRoot),
		popGcRoot: getNonTemplateConcreteFun(ctx, commonFuns.popGcRoot));

	finishLambdas(ctx);
	finishVariants(ctx);

	immutable ConcreteFun*[] allConcreteFuns = finish(alloc, ctx.allConcreteFuns);

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

void finishVariants(ref ConcretizeCtx ctx) {
	foreach (ConcreteStruct* variant, MutArr!ConcreteVariantMemberAndMethodImpls x; ctx.variantStructToMembers)
		variant.body_.as!(ConcreteStructBody.Union).members =
			small!ConcreteType(map(ctx.alloc, asTemporaryArray(x), (ref ConcreteVariantMemberAndMethodImpls x) =>
				x.memberType));

	foreach (ConcreteFun* fun; ctx.deferredVariantMethods) {
		ConcreteStruct* variant = mustBeByVal(fun.params[0].type);
		size_t methodIndex = fun.source.as!ConcreteFunKey.decl.body_.as!(FunBody.VariantMethod).methodIndex;
		MutArr!ConcreteVariantMemberAndMethodImpls impls = mustGet(ctx.variantStructToMembers, variant);
		fun.overwriteBody(generateCallVariantMethod(ctx, fun, variant, asTemporaryArray(impls), methodIndex));
	}
}

SymbolSet allExterns(in Config mainConfig) =>
	buildSymbolSet((scope ref SymbolSetBuilder out_) {
		version (Windows)
			out_ ~= [symbolOfEnum(BuiltinExtern.DbgHelp), symbolOfEnum(BuiltinExtern.windows)];
		else
			out_ ~= [
				symbolOfEnum(BuiltinExtern.linux),
				symbolOfEnum(BuiltinExtern.posix),
				symbolOfEnum(BuiltinExtern.pthread),
				symbolOfEnum(BuiltinExtern.sodium),
				symbolOfEnum(BuiltinExtern.unwind),
			];
		out_ ~= [symbolOfEnum(BuiltinExtern.libc), symbolOfEnum(BuiltinExtern.native)];
		foreach (Symbol name, Opt!Uri uri; mainConfig.extern_)
			if (has(uri))
				out_ ~= name;
	});
