module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.concretizeCtx :
	ConcretizeCtx, deferredFillRecordAndUnionBodies, getOrAddNonTemplateConcreteFunAndFillBody;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteLambdaImpl,
	ConcreteProgram,
	ConcreteStruct,
	mustBeByVal;
import model.model : CommonFuns, Program;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : finishArr_immutable;
import util.col.mutArr : moveToArr, MutArr;
import util.col.mutDict : mapToDict, mutDictIsEmpty;
import util.late : lateSet;
import util.opt : force;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castNonScope;
import util.sym : AllSymbols;
import util.util : verify;
import versionInfo : VersionInfo;

immutable(ConcreteProgram) concretize(
	ref Alloc alloc,
	scope ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
) =>
	withMeasure!(immutable ConcreteProgram, () =>
		concretizeInner(&alloc, versionInfo, &allSymbols, allPaths, program)
	)(alloc, perf, PerfMeasure.concretize);

private:

immutable(ConcreteProgram) concretizeInner(
	Alloc* allocPtr,
	immutable VersionInfo versionInfo,
	AllSymbols* allSymbolsPtr,
	ref const AllPaths allPaths,
	ref immutable Program program,
) {
	ref Alloc alloc() =>
		*allocPtr;
	ConcretizeCtx ctx = ConcretizeCtx(
		allocPtr,
		versionInfo,
		allSymbolsPtr,
		castNonScope(&program.commonTypes),
		castNonScope(&program));
	immutable CommonFuns commonFuns = force(program.commonFuns);
	lateSet(ctx.curExclusionFun_, getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.curExclusion));
	immutable ConcreteFun* markFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.mark);
	immutable ConcreteFun* rtMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.rtMain);
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));
	immutable ConcreteFun* userMainConcreteFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.main);
	immutable ConcreteFun* allocFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.alloc);
	immutable ConcreteFun* throwImplFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.throwImpl);
	immutable ConcreteFun* staticSymbolsFun = getOrAddNonTemplateConcreteFunAndFillBody(ctx, commonFuns.staticSymbols);
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finishArr_immutable(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	return immutable ConcreteProgram(
		finishAllConstants(
			alloc,
			ctx.allConstants,
			*allSymbolsPtr,
			mustBeByVal(staticSymbolsFun.returnType)),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		allConcreteFuns,
		mapToDict!(ConcreteStruct*, ConcreteLambdaImpl[], MutArr!(immutable ConcreteLambdaImpl))(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!(immutable ConcreteLambdaImpl) it) =>
				moveToArr(alloc, it)),
		immutable ConcreteCommonFuns(
			allocFun,
			commonFuns.callWithCtxFunDecls,
			markFun,
			commonFuns.markVisitFunDecl,
			rtMainConcreteFun,
			throwImplFun,
			userMainConcreteFun));
}
