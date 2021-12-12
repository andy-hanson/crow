module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.concretizeCtx :
	ConcretizeCtx,
	constantStr,
	ctxType,
	deferredFillRecordAndUnionBodies,
	getOrAddNonTemplateConcreteFunAndFillBody;
import interpret.debugging : writeConcreteFunName;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteFunToName,
	ConcreteLambdaImpl,
	ConcreteProgram,
	ConcreteStruct,
	mustBeNonPointer;
import model.constant : Constant;
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
import util.collection.arr : at, emptyArr, only;
import util.collection.arrBuilder : finishArr_immutable;
import util.collection.dict : getAt;
import util.collection.dictBuilder : finishDict, mustAddToDict, PtrDictBuilder;
import util.collection.mutArr : moveToArr, MutArr;
import util.collection.mutDict : mapToDict, mutDictIsEmpty;
import util.collection.mutSet : moveSetToArr;
import util.opt : force, has, Opt;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : hashPtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sym : AllSymbols, getSymFromAlphaIdentifier, shortSymAlphaLiteral, Sym;
import util.util : todo, verify;
import util.writer : finishWriter, Writer;

immutable(ConcreteProgram) concretize(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref immutable Program program,
) {
	return withMeasure!(immutable ConcreteProgram, () =>
		concretizeInner(alloc, allSymbols, program)
	)(alloc, perf, PerfMeasure.concretize);
}

private:

immutable(ConcreteProgram) concretizeInner(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref immutable Program program,
) {
	ConcretizeCtx ctx = ConcretizeCtx(
		getCurIslandAndExclusionFun(alloc, allSymbols, program),
		program.commonTypes.ctx,
		ptrTrustMe(program.commonTypes),
		ptrTrustMe(program));
	immutable Ptr!ConcreteStruct ctxStruct = ctxType(alloc, ctx).struct_;
	immutable Ptr!ConcreteFun markConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getMarkFun(alloc, program));
	immutable Ptr!ConcreteFun rtMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getRtMainFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));
	immutable Ptr!ConcreteFun userMainConcreteFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getUserMainFun(alloc, program));
	immutable Ptr!ConcreteFun allocFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getAllocFun(alloc, program));
	immutable Ptr!ConcreteFun allFunsFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getAllFunsFun(alloc, program));
	immutable Ptr!ConcreteFun staticSymsFun =
		getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, getStaticSymsFun(alloc, program));
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));

	immutable Ptr!ConcreteFun[] allConcreteFuns = finishArr_immutable(alloc, ctx.allConcreteFuns);
	immutable ConcreteFunToName funToName = getFunToName(alloc, ctx, allConcreteFuns);

	deferredFillRecordAndUnionBodies(alloc, ctx);

	return immutable ConcreteProgram(
		finishAllConstants(
			alloc,
			ctx.allConstants,
			allConcreteFuns,
			mustBeNonPointer(allFunsFun.deref().returnType),
			mustBeNonPointer(staticSymsFun.deref().returnType)),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		allConcreteFuns,
		funToName,
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

immutable(ConcreteFunToName) getFunToName(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
) {
	PtrDictBuilder!(ConcreteFun, Constant) res;
	foreach (immutable Ptr!ConcreteFun f; allConcreteFuns) {
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeConcreteFunName(writer, f.deref());
		immutable string name = finishWriter(writer);
		mustAddToDict(alloc, res, f, constantStr(alloc, ctx, name));
	}
	return finishDict(alloc, res);
}

immutable(bool) isNat(ref immutable CommonTypes commonTypes, immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.nat64));
}

immutable(bool) isInt32(ref immutable CommonTypes commonTypes, immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.int32));
}

immutable(bool) isStr(ref immutable CommonTypes commonTypes, immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.str));
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
	if (!isInt32(commonTypes, at(params, 0).type))
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
		shortSymAlphaLiteral("mark"));
	if (markFuns.length != 1)
		todo!void("wong number mark funs");
	immutable Ptr!FunDecl markFun = only(markFuns);
	//TODO: check the signature
	return nonTemplateFunInst(alloc, markFun);
}

immutable(Ptr!FunInst) getRtMainFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] mainFuns =
		getFuns(program.specialModules.runtimeMainModule.deref(), shortSymAlphaLiteral("rt-main"));
	if (mainFuns.length != 1)
		todo!void("wrong number rt-main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkRtMainSignature(program.commonTypes, mainFun.deref());
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getUserMainFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] mainFuns = getFuns(program.specialModules.mainModule.deref(), shortSymAlphaLiteral("main"));
	if (mainFuns.length != 1)
		todo!void("wrong number main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkUserMainSignature(program.commonTypes, mainFun.deref());
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getAllocFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] allocFuns = getFuns(
		program.specialModules.allocModule.deref(),
		shortSymAlphaLiteral("alloc"));
	if (allocFuns.length != 1)
		todo!void("wrong number alloc funs");
	immutable Ptr!FunDecl allocFun = only(allocFuns);
	// TODO: check the signature!
	return nonTemplateFunInst(alloc, allocFun);
}

immutable(Ptr!FunInst) getStaticSymsFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] funs = getFuns(
		program.specialModules.bootstrapModule.deref(),
		shortSymAlphaLiteral("static-syms"));
	if (funs.length != 1)
		todo!void("wrong number static-syms funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunInst) getAllFunsFun(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] funs =
		getFuns(program.specialModules.bootstrapModule.deref(), shortSymAlphaLiteral("all-funs"));
	if (funs.length != 1) todo!void("wrong number all-funs funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunInst) getCurIslandAndExclusionFun(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref immutable Program program,
) {
	immutable Sym sym = getSymFromAlphaIdentifier(allSymbols, "cur-island-and-exclusion");
	immutable Ptr!FunDecl[] funs = getFuns(program.specialModules.runtimeModule.deref(), sym);
	if (funs.length != 1)
		todo!void("wrong number cur-island-and=exclusion funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunDecl[]) getFuns(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = getAt(a.allExportedNames, name);
	return has(optReferents) ? force(optReferents).funs : emptyArr!(Ptr!FunDecl);
}
