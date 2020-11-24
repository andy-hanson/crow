module concretize.concretize;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : finishAllConstants;
import concretize.concretizeCtx : ConcretizeCtx, ctxType, getOrAddNonTemplateConcreteFunAndFillBody;
import model.concreteModel : ConcreteFun, ConcreteProgram, ConcreteStruct;
import model.model :
	asStructInst,
	CommonTypes,
	decl,
	FunDecl,
	FunInst,
	FunKind,
	getFunStructInfo,
	nonTemplateFunInst,
	isStructInst,
	isTemplate,
	noCtx,
	Param,
	params,
	Program,
	returnType,
	StructDecl,
	Type,
	typeArgs,
	typeEquals;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, first, only, size;
import util.collection.arrBuilder : finishArr_immutable;
import util.collection.arrUtil : filter;
import util.collection.mutDict : mutDictIsEmpty;
import util.collection.multiDict : multiDictGetAt;
import util.memory : nu;
import util.opt : force, has, Opt;
import util.ptr : Ptr, ptrEquals, ptrTrustMe;
import util.sym : shortSymAlphaLiteral;
import util.util : todo, verify;

immutable(Ptr!ConcreteProgram) concretize(Alloc)(ref Alloc alloc, ref immutable Program program) {
	ConcretizeCtx ctx = ConcretizeCtx(
		getGetVatAndActorFun(alloc, program),
		getIfFuns(program),
		getCallFuns(alloc, program),
		program.ctxStructInst,
		ptrTrustMe(program.commonTypes));
	immutable Ptr!ConcreteStruct ctxStruct = ctxType(alloc, ctx).struct_;
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

	return nu!ConcreteProgram(
		alloc,
		finishAllConstants(alloc, ctx.allConstants),
		finishArr_immutable(alloc, ctx.allConcreteStructs),
		finishArr_immutable(alloc, ctx.allConcreteFuns),
		rtMainConcreteFun,
		userMainConcreteFun,
		allocFun,
		ctxStruct);
}

private:

immutable(Bool) isInt32(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.int32));
}

immutable(Bool) isStr(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return typeEquals(type, immutable Type(commonTypes.str));
}

immutable(Bool) isFutInt32(ref immutable CommonTypes commonTypes, ref immutable Type type) {
	return Bool(
		isStructInst(type) &&
		ptrEquals(decl(asStructInst(type).deref), commonTypes.fut) &&
		isInt32(commonTypes, only(typeArgs(asStructInst(type).deref))));
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

	immutable Arr!Param params = params(mainFun);
	if (size(params) != 3)
		todo!void("checkRtMainSignature wrong number params");
	if (!isInt32(commonTypes, at(params, 0).type))
		todo!void("checkRtMainSignature doesn't take int");
	// TODO: check p1 type is ptr c-str
	// TODO: check p2 type is fun-ptr2 fut<int> ctx arr<str>)
	if (!isInt32(commonTypes, returnType(mainFun)))
		todo!void("checkRtMainSignature doesn't return int");
}

void checkUserMainSignature(ref immutable CommonTypes commonTypes, immutable Ptr!FunDecl mainFun) {
	if (noCtx(mainFun))
		todo!void("main is noctx?");
	if (isTemplate(mainFun))
		todo!void("main is template?");
	immutable Arr!Param params = params(mainFun);
	if (size(params) != 1)
		todo!void("checkUserMainSignature should take 1 param");
	if (!isArrStr(commonTypes, only(params).type))
		todo!void("checkUserMainSignature doesn't take arr str");
	if (!isFutInt32(commonTypes, returnType(mainFun)))
		todo!void("checkUserMainSignature doesn't return fut int-32");
}

immutable(Ptr!FunInst) getRtMainFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) mainFuns = multiDictGetAt(
		program.specialModules.runtimeMainModule.funsMap,
		shortSymAlphaLiteral("rt-main"));
	if (size(mainFuns) != 1)
		todo!void("wrong number rt-main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkRtMainSignature(program.commonTypes, mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getUserMainFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) mainFuns =
		multiDictGetAt(program.specialModules.mainModule.funsMap, shortSymAlphaLiteral("main"));
	if (size(mainFuns) != 1)
		todo!void("wrong number main funs");
	immutable Ptr!FunDecl mainFun = only(mainFuns);
	checkUserMainSignature(program.commonTypes, mainFun);
	return nonTemplateFunInst(alloc, mainFun);
}

immutable(Ptr!FunInst) getAllocFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) allocFuns =
		multiDictGetAt(program.specialModules.allocModule.funsMap, shortSymAlphaLiteral("alloc"));
	if (size(allocFuns) != 1)
		todo!void("wrong number alloc funs");
	immutable Ptr!FunDecl allocFun = only(allocFuns);
	// TODO: check the signature!
	return nonTemplateFunInst(alloc, allocFun);
}

//TODO: should be called 'getCurActorFun'?
immutable(Ptr!FunInst) getGetVatAndActorFun(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) funs =
		multiDictGetAt(program.specialModules.runtimeModule.funsMap, shortSymAlphaLiteral("cur-actor"));
	if (size(funs) != 1)
		todo!void("wrong number cur-actor funs");
	return nonTemplateFunInst(alloc, only(funs));
}

immutable(Arr!(Ptr!FunDecl)) getIfFuns(ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) ifFuns =
		multiDictGetAt(program.specialModules.bootstrapModule.funsMap, shortSymAlphaLiteral("if"));
	if (size(ifFuns) != 2)
		todo!void("wrong number 'if' funs");
	return ifFuns;
}

// Gets 'call' for 'fun' and 'fun-mut'
// 'call' for 'fun-ptr' is a builtin already so no need to handle that here
// Don't need 'call' for 'fun-ref' here.

immutable(Arr!(Ptr!FunDecl)) getCallFuns(Alloc)(ref Alloc alloc, ref immutable Program program) {
	immutable Arr!(Ptr!FunDecl) allCallFuns =
		multiDictGetAt(program.specialModules.bootstrapModule.funsMap, shortSymAlphaLiteral("call"));
	immutable Arr!(Ptr!FunDecl) res = filter!(Alloc, Ptr!FunDecl)(alloc, allCallFuns, (ref immutable Ptr!FunDecl f) {
		immutable Ptr!StructDecl decl = decl(asStructInst(first(params(f)).type).deref);
		immutable Opt!FunKind kind = getFunStructInfo(program.commonTypes, decl);
		if (has(kind))
			final switch (force(kind)) {
				case FunKind.ptr:
				case FunKind.ref_:
					return False;
				case FunKind.plain:
				case FunKind.mut:
					return True;
			}
		else
			return False;
	});
	// fun0, fun1, fun2, fun3, same for funMut
	verify(size(res) == 8);
	return res;
}
