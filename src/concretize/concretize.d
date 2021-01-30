module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.concretizeCtx : ConcretizeCtx, constantStr, ctxType, getOrAddNonTemplateConcreteFunAndFillBody;
import interpret.debugging : writeConcreteFunName;
import model.concreteModel :
	ConcreteCommonFuns,
	ConcreteFun,
	ConcreteFunToName,
	ConcreteLambdaImpl,
	ConcreteProgram,
	ConcreteStruct;
import model.constant : Constant;
import model.model :
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
import util.bools : Bool;
import util.collection.arr : at, emptyArr, only, size;
import util.collection.arrBuilder : finishArr_immutable;
import util.collection.dict : getAt;
import util.collection.dictBuilder : addToDict, DictBuilder, finishDictShouldBeNoConflict;
import util.collection.mutArr : moveToArr, MutArr;
import util.collection.mutDict : mapToDict, mutDictIsEmpty;
import util.collection.mutSet : moveToArr;
import util.collection.str : strLiteral;
import util.memory : nu;
import util.opt : force, has, Opt;
import util.ptr : comparePtr, Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sym : AllSymbols, getSymFromAlphaIdentifier, shortSymAlphaLiteral, Sym;
import util.util : todo, verify;
import util.writer : finishWriter, Writer;

immutable(Ptr!ConcreteProgram) concretize(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
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
	// We remove items from these dicts when we process them.
	verify(mutDictIsEmpty(ctx.concreteFunToBodyInputs));

	immutable Ptr!ConcreteFun[] allConcreteFuns = finishArr_immutable(alloc, ctx.allConcreteFuns);
	immutable ConcreteFunToName funToName = getFunToName(alloc, ctx, allConcreteFuns);

	return nu!ConcreteProgram(
		alloc,
		finishAllConstants(alloc, ctx.allConstants),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		allConcreteFuns,
		funToName,
		mapToDict!(Ptr!ConcreteStruct, ConcreteLambdaImpl[], MutArr!(immutable ConcreteLambdaImpl))(
			alloc,
			ctx.funStructToImpls,
			(ref MutArr!(immutable ConcreteLambdaImpl) it) =>
				moveToArr(alloc, it)),
		nu!ConcreteCommonFuns(
			alloc,
			markConcreteFun,
			rtMainConcreteFun,
			userMainConcreteFun,
			allocFun),
		ctxStruct,
		moveToArr(alloc, ctx.allExternLibraryNames));
}

private:

immutable(ConcreteFunToName) getFunToName(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
) {
	DictBuilder!(Ptr!ConcreteFun, Constant, comparePtr!ConcreteFun) res;
	foreach (immutable Ptr!ConcreteFun f; allConcreteFuns) {
		Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
		writeConcreteFunName(writer, f);
		immutable string name = finishWriter(writer);
		addToDict(alloc, res, f, constantStr(alloc, ctx, name));
	}
	return finishDictShouldBeNoConflict(alloc, res);
}

immutable(Bool) isNat(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.nat64));
}

immutable(Bool) isInt32(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.integrals.int32));
}

immutable(Bool) isStr(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.str));
}

immutable(Bool) isFutNat(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return immutable Bool(
		isStructInst(type) &&
		ptrEquals(decl(asStructInst(type).deref), commonTypes.fut) &&
		isNat(commonTypes, only(typeArgs(asStructInst(type).deref))));
}

immutable(Bool) isArrStr(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return Bool(
		isStructInst(type) &&
		ptrEquals(decl(asStructInst(type).deref), commonTypes.arr) &&
		isStr(commonTypes, only(typeArgs(asStructInst(type).deref))));
}

void checkRtMainSignature(ref immutable CommonTypes commonTypes, immutable Ptr!FunDecl mainFun) {
	if (!noCtx(mainFun))
		todo!void("rt main must be noctx");
	if (isTemplate(mainFun))
		todo!void("rt main is template?");
	if (!isInt32(commonTypes, returnType(mainFun)))
		todo!void("checkRtMainSignature doesn't return int");
	immutable Param[] params = params(mainFun);
	if (size(params) != 3)
		todo!void("checkRtMainSignature wrong number params");
	if (!isInt32(commonTypes, at(params, 0).type))
		todo!void("checkRtMainSignature doesn't take int");
	// TODO: check p1 type is ptr c-str
	// TODO: check p2 type is fun-ptr2 fut<nat> ctx arr<str>)
}

void checkUserMainSignature(ref immutable CommonTypes commonTypes, immutable Ptr!FunDecl mainFun) {
	if (noCtx(mainFun))
		todo!void("main is noctx?");
	if (isTemplate(mainFun))
		todo!void("main is template?");
	if (!isFutNat(commonTypes, returnType(mainFun)))
		todo!void("checkUserMainSignature doesn't return fut nat");
	immutable Param[] params = params(mainFun);
	if (size(params) != 1)
		todo!void("checkUserMainSignature should take 1 param");
	if (!isArrStr(commonTypes, only(params).type))
		todo!void("checkUserMainSignature doesn't take arr str");
}

immutable(Ptr!FunInst) getMarkFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] markFuns = getFuns(program.specialModules.allocModule, shortSymAlphaLiteral("mark"));
	if (size(markFuns) != 1)
		todo!void("wong number mark funs");
	immutable Ptr!FunDecl markFun = only(markFuns);
	//TODO: check the signature
	return nonTemplateFunInst(alloc, markFun);
}

immutable(Ptr!FunInst) getRtMainFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] mainFuns =
		getFuns(program.specialModules.runtimeMainModule, shortSymAlphaLiteral("rt-main"));
	if (size(mainFuns) != 1)
		todo!void("wrong number rt-main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkRtMainSignature(program.commonTypes, mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getUserMainFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] mainFuns = getFuns(program.specialModules.mainModule, shortSymAlphaLiteral("main"));
	if (size(mainFuns) != 1)
		todo!void("wrong number main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkUserMainSignature(program.commonTypes, mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getAllocFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Ptr!FunDecl[] allocFuns = getFuns(program.specialModules.allocModule, shortSymAlphaLiteral("alloc"));
	if (size(allocFuns) != 1)
		todo!void("wrong number alloc funs");
	immutable Ptr!FunDecl allocFun = only(allocFuns);
	// TODO: check the signature!
	return nonTemplateFunInst(alloc, allocFun);
}

immutable(Ptr!FunInst) getCurIslandAndExclusionFun(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable Program program,
) {
	immutable string name = strLiteral("cur-island-and-exclusion");
	immutable Sym sym = getSymFromAlphaIdentifier(allSymbols, name);
	immutable Ptr!FunDecl[] funs = getFuns(program.specialModules.runtimeModule, sym);
	if (size(funs) != 1)
		todo!void("wrong number cur-island-and=exclusion funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Ptr!FunDecl[]) getFuns(ref immutable Module a, immutable Sym name) {
	immutable Opt!NameReferents optReferents = getAt(a.allExportedNames, name);
	return has(optReferents) ? force(optReferents).funs : emptyArr!(Ptr!FunDecl);
}
