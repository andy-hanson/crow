module frontend.check.getCommonTypes;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.instantiate : instantiateStruct;
import frontend.check.maps : StructsAndAliasesMap;
import frontend.programState : ProgramState;
import model.diag : Diag;
import model.model :
	CommonTypes,
	FunKind,
	IntegralTypes,
	Linkage,
	Purity,
	setBody,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Type,
	TypeParam,
	typeParams,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.enumMap : EnumMap;
import util.col.mutArr : MutArr;
import util.col.str : safeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, someMut, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndRange, RangeWithinFile;
import util.sym : Sym, sym;
import util.util : todo, verify;

CommonTypes getCommonTypes(
	ref CheckCtx ctx,
	in StructsAndAliasesMap structsAndAliasesMap,
	scope ref MutArr!(StructInst*) delayedStructInsts,
) {
	void addDiagMissing(Sym name) {
		addDiag(ctx, FileAndRange(ctx.curUri, RangeWithinFile.empty), Diag(Diag.CommonTypeMissing(name)));
	}

	StructInst* nonTemplateFromSym(Sym name) {
		Opt!(StructInst*) res =
			getCommonNonTemplateType(ctx.alloc, ctx.programState, structsAndAliasesMap, name, delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return instantiateNonTemplateStructDecl(
				ctx.alloc,
				ctx.programState,
				delayedStructInsts,
				bogusStructDecl(ctx.alloc, 0));
		}
	}
	StructInst* nonTemplate(string name)() {
		return nonTemplateFromSym(sym!name);
	}

	StructInst* bool_ = nonTemplate!"bool";
	StructInst* char8 = nonTemplate!"char8";
	StructInst* float32 = nonTemplate!"float32";
	StructInst* float64 = nonTemplate!"float64";
	StructInst* int8 = nonTemplate!"int8";
	StructInst* int16 = nonTemplate!"int16";
	StructInst* int32 = nonTemplate!"int32";
	StructInst* int64 = nonTemplate!"int64";
	StructInst* nat8 = nonTemplate!"nat8";
	StructInst* nat16 = nonTemplate!"nat16";
	StructInst* nat32 = nonTemplate!"nat32";
	StructInst* nat64 = nonTemplate!"nat64";
	StructInst* symbol = nonTemplate!"symbol";
	StructInst* void_ = nonTemplate!"void";

	StructDecl* getDeclFromSym(Sym name, size_t nTypeParameters) {
		Opt!(StructDecl*) res = getCommonTemplateType(structsAndAliasesMap, name, nTypeParameters);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return bogusStructDecl(ctx.alloc, nTypeParameters);
		}
	}
	StructDecl* getDecl(string name)(size_t nTypeParameters) {
		return getDeclFromSym(sym!name, nTypeParameters);
	}

	StructDecl* array = getDecl!"array"(1);
	StructDecl* future = getDecl!"future"(1);
	StructDecl* opt = getDecl!"option"(1);
	StructDecl* pointerConst = getDecl!"const-pointer"(1);
	StructDecl* pointerMut = getDecl!"mut-pointer"(1);
	EnumMap!(FunKind, StructDecl*) funs = immutable EnumMap!(FunKind, StructDecl*)([
		getDecl!"fun-fun"(2), getDecl!"fun-act"(2), getDecl!"fun-far"(2), getDecl!"fun-pointer"(2),
	]);

	StructDecl* constPointer = getDecl!"const-pointer"(1);
	StructInst* cStr = instantiateStruct(
		ctx.alloc, ctx.programState, constPointer, [Type(char8)], someMut(ptrTrustMe(delayedStructInsts)));

	StructDecl*[8] tuples = [
		getDecl!"tuple2"(2),
		getDecl!"tuple3"(3),
		getDecl!"tuple4"(4),
		getDecl!"tuple5"(5),
		getDecl!"tuple6"(6),
		getDecl!"tuple7"(7),
		getDecl!"tuple8"(8),
		getDecl!"tuple9"(9),
	];

	return CommonTypes(
		bool_,
		char8,
		cStr,
		float32,
		float64,
		IntegralTypes(int8, int16, int32, int64, nat8, nat16, nat32, nat64),
		symbol,
		void_,
		array,
		future,
		opt,
		pointerConst,
		pointerMut,
		tuples,
		funs);
}

private:

Opt!(StructDecl*) getCommonTemplateType(
	in StructsAndAliasesMap structsAndAliasesMap,
	Sym name,
	size_t expectedTypeParams,
) {
	Opt!StructOrAlias res = structsAndAliasesMap[name];
	if (has(res)) {
		// TODO: may fail -- builtin Template should not be an alias
		StructDecl* decl = force(res).as!(StructDecl*);
		if (decl.typeParams.length != expectedTypeParams)
			todo!void("getCommonTemplateType");
		return some(decl);
	} else
		return none!(StructDecl*);
}

Opt!(StructInst*) getCommonNonTemplateType(
	ref Alloc alloc,
	ref ProgramState programState,
	in StructsAndAliasesMap structsAndAliasesMap,
	Sym name,
	scope ref MutArr!(StructInst*) delayedStructInsts,
) {
	Opt!StructOrAlias opStructOrAlias = structsAndAliasesMap[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(alloc, programState, delayedStructInsts, force(opStructOrAlias))
		: none!(StructInst*);
}

Opt!(StructInst*) instantiateNonTemplateStructOrAlias(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref MutArr!(StructInst*) delayedStructInsts,
	StructOrAlias structOrAlias,
) {
	verify(empty(typeParams(structOrAlias)));
	return structOrAlias.matchWithPointers!(Opt!(StructInst*))(
		(StructAlias* x) =>
			target(*x),
		(StructDecl* x) =>
			some(instantiateNonTemplateStructDecl(alloc, programState, delayedStructInsts, x)));
}

StructInst* instantiateNonTemplateStructDecl(
	ref Alloc alloc,
	ref ProgramState programState,
	scope ref MutArr!(StructInst*) delayedStructInsts,
	StructDecl* structDecl,
) =>
	instantiateStruct(alloc, programState, structDecl, [], someMut(ptrTrustMe(delayedStructInsts)));

StructDecl* bogusStructDecl(ref Alloc alloc, size_t nTypeParameters) {
	ArrBuilder!TypeParam typeParams;
	FileAndRange fileAndRange = FileAndRange.empty;
	foreach (size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, TypeParam(fileAndRange, sym!"bogus", i));
	StructDecl* res = allocate(alloc, StructDecl(
		fileAndRange,
		safeCStr!"",
		sym!"bogus",
		small(finishArr(alloc, typeParams)),
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	setBody(*res, StructBody(StructBody.Bogus()));
	return res;
}
