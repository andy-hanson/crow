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
import model.model :
	assertNonVariadic,
	asStructInst,
	CommonTypes,
	decl,
	FunDecl,
	FunInst,
	nonTemplateFunInst,
	isStructInst,
	isTemplate,
	Module,
	NameReferents,
	noCtx,
	Param,
	Program,
	Type,
	typeArgs;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : finishArr_immutable;
import util.col.mutArr : moveToArr, MutArr;
import util.col.mutDict : mapToDict, mutDictIsEmpty;
import util.opt : force, has, Opt;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : castNonScope;
import util.sym : AllSymbols, shortSym, SpecialSym, Sym, symForSpecial;
import util.util : todo, verify;
import versionInfo : VersionInfo;

immutable(ConcreteProgram) concretize(
	ref Alloc alloc,
	scope ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
	immutable Module* mainModule,
) =>
	withMeasure!(immutable ConcreteProgram, () =>
		concretizeInner(&alloc, versionInfo, &allSymbols, allPaths, program, mainModule)
	)(alloc, perf, PerfMeasure.concretize);

private:

immutable(ConcreteProgram) concretizeInner(
	Alloc* allocPtr,
	immutable VersionInfo versionInfo,
	AllSymbols* allSymbolsPtr,
	ref const AllPaths allPaths,
	ref immutable Program program,
	immutable Module* mainModule,
) {
	ref Alloc alloc() =>
		*allocPtr;
	ConcretizeCtx ctx = ConcretizeCtx(
		allocPtr,
		versionInfo,
		allSymbolsPtr,
		getCurExclusionFun(alloc, program),
		castNonScope(&program.commonTypes),
		castNonScope(&program));
	immutable ConcreteFun* markConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getMarkFun(alloc, program));
	immutable ConcreteFun* rtMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getRtMainFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));
	immutable ConcreteFun* userMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getUserMainFun(alloc, program, mainModule));
	immutable ConcreteFun* allocFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getAllocFun(alloc, program));
	immutable ConcreteFun* throwImplFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getThrowImplFun(alloc, program));
	immutable ConcreteFun* staticSymsFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getStaticSymsFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));

	immutable ConcreteFun*[] allConcreteFuns = finishArr_immutable(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	return immutable ConcreteProgram(
		finishAllConstants(
			alloc,
			ctx.allConstants,
			*allSymbolsPtr,
			mustBeByVal(staticSymsFun.returnType)),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		allConcreteFuns,
		mapToDict!(ConcreteStruct*, ConcreteLambdaImpl[], MutArr!(immutable ConcreteLambdaImpl))(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!(immutable ConcreteLambdaImpl) it) =>
				moveToArr(alloc, it)),
		immutable ConcreteCommonFuns(markConcreteFun, rtMainConcreteFun, userMainConcreteFun, allocFun, throwImplFun));
}

immutable(bool) isNat(ref immutable CommonTypes commonTypes, immutable Type type) =>
	type == immutable Type(commonTypes.integrals.nat64);

immutable(bool) isInt32(ref immutable CommonTypes commonTypes, immutable Type type) =>
	type == immutable Type(commonTypes.integrals.int32);

immutable(bool) isStr(ref immutable CommonTypes commonTypes, immutable Type type) =>
	//TODO:better
	isStructInst(type) && decl(*asStructInst(type)).name == shortSym("str");

immutable(bool) isFutNat(ref immutable CommonTypes commonTypes, immutable Type type) =>
	isStructInst(type) &&
		decl(*asStructInst(type)) == commonTypes.fut &&
		isNat(commonTypes, only(typeArgs(*asStructInst(type))));

immutable(bool) isArrStr(ref immutable CommonTypes commonTypes, immutable Type type) =>
	isStructInst(type) &&
		decl(*asStructInst(type)) == commonTypes.arr &&
		isStr(commonTypes, only(typeArgs(*asStructInst(type))));

void checkRtMainSignature(ref immutable CommonTypes commonTypes, ref immutable FunDecl mainFun) {
	if (!noCtx(mainFun))
		todo!void("rt main must be noctx");
	if (isTemplate(mainFun))
		todo!void("rt main is template?");
	if (!isInt32(commonTypes, mainFun.returnType))
		todo!void("checkRtMainSignature doesn't return int");
	immutable Param[] params = assertNonVariadic(mainFun.params);
	if (params.length != 3)
		todo!void("checkRtMainSignature wrong number params");
	if (!isInt32(commonTypes, params[0].type))
		todo!void("checkRtMainSignature doesn't take int");
	// TODO: check p1 type is ptr c-str
	// TODO: check p2 type is fun-ptr2 fut<nat> ctx arr<str>)
}

void checkUserMainSignature(ref immutable CommonTypes commonTypes, ref immutable FunDecl mainFun) {
	if (noCtx(mainFun))
		todo!void("main is noctx?");
	if (isTemplate(mainFun))
		todo!void("main is template?");
	if (!isFutNat(commonTypes, mainFun.returnType))
		todo!void("checkUserMainSignature doesn't return fut nat");
	immutable Param[] params = assertNonVariadic(mainFun.params);
	if (params.length != 1)
		todo!void("checkUserMainSignature should take 1 param");
	if (!isArrStr(commonTypes, only(params).type))
		todo!void("checkUserMainSignature doesn't take arr str");
}

immutable(FunInst*) getMarkFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] markFuns = getFuns(*program.specialModules.allocModule, shortSym("mark"));
	if (markFuns.length != 1)
		todo!void("wong number mark funs");
	immutable FunDecl* markFun = only(markFuns);
	//TODO: check the signature
	return nonTemplateFunInst(alloc, markFun);
}

immutable(FunInst*) getRtMainFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] mainFuns = getFuns(*program.specialModules.runtimeMainModule, shortSym("rt-main"));
	if (mainFuns.length != 1)
		todo!void("wrong number rt-main funs");
	immutable FunDecl* mainFun = only(mainFuns);
	checkRtMainSignature(program.commonTypes, *mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(FunInst*) getUserMainFun(ref Alloc alloc, ref immutable Program program, immutable Module* mainModule) {
	immutable FunDecl*[] mainFuns = getFuns(*mainModule, shortSym("main"));
	if (mainFuns.length != 1)
		todo!void("wrong number main funs");
	immutable FunDecl* mainFun = only(mainFuns);
	checkUserMainSignature(program.commonTypes, *mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(FunInst*) getAllocFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] allocFuns = getFuns(*program.specialModules.allocModule, shortSym("alloc"));
	if (allocFuns.length != 1)
		todo!void("wrong number alloc funs");
	immutable FunDecl* allocFun = only(allocFuns);
	// TODO: check the signature!
	return nonTemplateFunInst(alloc, allocFun);
}

immutable(FunInst*) getThrowImplFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] funs = getFuns(*program.specialModules.exceptionLowLevelModule, shortSym("throw-impl"));
	if (funs.length != 1)
		todo!void("wrong number throw-impl funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(FunInst*) getStaticSymsFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] funs = getFuns(*program.specialModules.bootstrapModule, shortSym("static-syms"));
	if (funs.length != 1)
		todo!void("wrong number static-syms funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(FunInst*) getCurExclusionFun(ref Alloc alloc, ref immutable Program program) {
	immutable FunDecl*[] funs =
		getFuns(*program.specialModules.runtimeModule, symForSpecial(SpecialSym.cur_exclusion));
	if (funs.length != 1)
		todo!void("wrong number cur-exclusion funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(FunDecl*[]) getFuns(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = a.allExportedNames[name];
	return has(optReferents) ? force(optReferents).funs : [];
}
