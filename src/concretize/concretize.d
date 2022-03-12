module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.concretizeCtx :
	ConcretizeCtx,
	ctxType,
	deferredFillRecordAndUnionBodies,
	getOrAddNonTemplateConcreteFunAndFillBody;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteLambdaImpl,
	ConcreteProgram,
	ConcreteStruct,
	mustBeNonPointer;
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
	params,
	Program,
	returnType,
	Type,
	typeArgs,
	typeEquals;
import util.alloc.alloc : Alloc;
import util.col.arr : emptyArr, only;
import util.col.arrBuilder : finishArr_immutable;
import util.col.dict : getAt;
import util.col.mutArr : moveToArr, MutArr;
import util.col.mutDict : mapToDict, mutDictIsEmpty;
import util.col.mutSet : moveSetToArr;
import util.opt : force, has, Opt;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : hashPtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.sym : AllSymbols, shortSym, SpecialSym, Sym, symEq, symForSpecial;
import util.util : todo, verify;
import versionInfo : VersionInfo;

immutable(ConcreteProgram) concretize(
	ref Alloc alloc,
	scope ref Perf perf,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
	immutable Ptr!Module mainModule,
) {
	return withMeasure!(immutable ConcreteProgram, () =>
		concretizeInner(alloc, versionInfo, allSymbols, allPaths, program, mainModule)
	)(alloc, perf, PerfMeasure.concretize);
}

private:

immutable(ConcreteProgram) concretizeInner(
	ref Alloc alloc,
	immutable VersionInfo versionInfo,
	ref AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
	immutable Ptr!Module mainModule,
) {
	ConcretizeCtx ctx = ConcretizeCtx(
		ptrTrustMe_mut(alloc),
		versionInfo,
		ptrTrustMe_const(allSymbols),
		getCurExclusionFun(alloc, program),
		program.commonTypes.ctx,
		ptrTrustMe(program.commonTypes),
		ptrTrustMe(program));
	immutable Ptr!ConcreteStruct ctxStruct = ctxType(ctx).struct_;
	immutable Ptr!ConcreteFun markConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getMarkFun(alloc, program));
	immutable Ptr!ConcreteFun rtMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getRtMainFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));
	immutable Ptr!ConcreteFun userMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getUserMainFun(alloc, program, mainModule));
	immutable Ptr!ConcreteFun allocFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getAllocFun(alloc, program));
	immutable Ptr!ConcreteFun allFunsFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getAllFunsFun(alloc, program));
	immutable Ptr!ConcreteFun staticSymsFun =
		getOrAddNonTemplateConcreteFunAndFillBody(ctx, getStaticSymsFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));

	immutable Ptr!ConcreteFun[] allConcreteFuns = finishArr_immutable(alloc, ctx.allConcreteFuns);

	deferredFillRecordAndUnionBodies(ctx);

	return immutable ConcreteProgram(
		finishAllConstants(
			alloc,
			ctx.allConstants,
			allSymbols,
			allConcreteFuns,
			mustBeNonPointer(allFunsFun.deref().returnType),
			mustBeNonPointer(staticSymsFun.deref().returnType)),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		allConcreteFuns,
		mapToDict!(
			Ptr!ConcreteStruct,
			ConcreteLambdaImpl[],
			MutArr!(immutable ConcreteLambdaImpl),
			ptrEquals!ConcreteStruct,
			hashPtr!ConcreteStruct,
		)(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!(immutable ConcreteLambdaImpl) it) =>
				moveToArr(alloc, it)),
		immutable ConcreteCommonFuns(markConcreteFun, rtMainConcreteFun, userMainConcreteFun, allocFun),
		ctxStruct,
		moveSetToArr(alloc, ctx.allExternLibraryNames));
}

immutable(bool) isNat(ref immutable CommonTypes commonTypes, immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.nat64));
}

immutable(bool) isInt32(ref immutable CommonTypes commonTypes, immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.int32));
}

immutable(bool) isStr(ref immutable CommonTypes commonTypes, immutable Type type) {
	//TODO:better
	return isStructInst(type) && symEq(asStructInst(type).deref().decl.deref().name, shortSym("str"));
}

immutable(bool) isFutNat(ref immutable CommonTypes commonTypes, immutable Type type) {
	return isStructInst(type) &&
		ptrEquals(decl(asStructInst(type).deref), commonTypes.fut) &&
		isNat(commonTypes, only(typeArgs(asStructInst(type).deref)));
}

immutable(bool) isArrStr(ref immutable CommonTypes commonTypes, immutable Type type) {
	return isStructInst(type) &&
		ptrEquals(decl(asStructInst(type).deref), commonTypes.arr) &&
		isStr(commonTypes, only(typeArgs(asStructInst(type).deref)));
}

void checkRtMainSignature(ref immutable CommonTypes commonTypes, ref immutable FunDecl mainFun) {
	if (!noCtx(mainFun))
		todo!void("rt main must be noctx");
	if (isTemplate(mainFun))
		todo!void("rt main is template?");
	if (!isInt32(commonTypes, returnType(mainFun)))
		todo!void("checkRtMainSignature doesn't return int");
	immutable Param[] params = assertNonVariadic(params(mainFun));
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
	if (!isFutNat(commonTypes, returnType(mainFun)))
		todo!void("checkUserMainSignature doesn't return fut nat");
	immutable Param[] params = assertNonVariadic(params(mainFun));
	if (params.length != 1)
		todo!void("checkUserMainSignature should take 1 param");
	if (!isArrStr(commonTypes, only(params).type))
		todo!void("checkUserMainSignature doesn't take arr str");
}

immutable(Ptr!FunInst) getMarkFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] markFuns = getFuns(
		program.specialModules.allocModule.deref(),
		shortSym("mark"));
	if (markFuns.length != 1)
		todo!void("wong number mark funs");
	immutable Ptr!FunDecl markFun = only(markFuns);
	//TODO: check the signature
	return nonTemplateFunInst(alloc, markFun);
}

immutable(Ptr!FunInst) getRtMainFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] mainFuns =
		getFuns(program.specialModules.runtimeMainModule.deref(), shortSym("rt-main"));
	if (mainFuns.length != 1)
		todo!void("wrong number rt-main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkRtMainSignature(program.commonTypes, mainFun.deref());
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getUserMainFun(ref Alloc alloc, ref immutable Program program, immutable Ptr!Module mainModule) {
	immutable Ptr!FunDecl[] mainFuns = getFuns(mainModule.deref(), shortSym("main"));
	if (mainFuns.length != 1)
		todo!void("wrong number main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkUserMainSignature(program.commonTypes, mainFun.deref());
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getAllocFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] allocFuns = getFuns(
		program.specialModules.allocModule.deref(),
		shortSym("alloc"));
	if (allocFuns.length != 1)
		todo!void("wrong number alloc funs");
	immutable Ptr!FunDecl allocFun = only(allocFuns);
	// TODO: check the signature!
	return nonTemplateFunInst(alloc, allocFun);
}

immutable(Ptr!FunInst) getStaticSymsFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] funs = getFuns(
		program.specialModules.bootstrapModule.deref(),
		shortSym("static-syms"));
	if (funs.length != 1)
		todo!void("wrong number static-syms funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunInst) getAllFunsFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] funs =
		getFuns(program.specialModules.bootstrapModule.deref(), shortSym("all-funs"));
	if (funs.length != 1) todo!void("wrong number all-funs funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunInst) getCurExclusionFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] funs = getFuns(
		program.specialModules.runtimeModule.deref(),
		symForSpecial(SpecialSym.cur_exclusion));
	if (funs.length != 1)
		todo!void("wrong number cur-exclusion funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunDecl[]) getFuns(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = getAt(a.allExportedNames, name);
	return has(optReferents) ? force(optReferents).funs : emptyArr!(Ptr!FunDecl);
}
