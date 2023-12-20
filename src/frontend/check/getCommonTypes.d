module frontend.check.getCommonTypes;

@safe @nogc pure nothrow:

import frontend.check.instantiate : DelayStructInsts, InstantiateCtx, instantiateStruct;
import frontend.check.maps : StructsAndAliasesMap;
import model.ast : NameAndRange;
import model.diag : Diag, Diagnostic;
import model.model :
	CommonTypes,
	emptyTypeArgs,
	FunKind,
	IntegralTypes,
	Linkage,
	Purity,
	StructAlias,
	StructBody,
	StructDecl,
	StructDeclSource,
	StructInst,
	StructOrAlias,
	Type,
	TypeParams,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty, small;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.enumMap : EnumMap;
import util.memory : allocate;
import util.opt : force, has, none, Opt, someMut, some;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol, symbol;
import util.uri : Uri;
import util.util : ptrTrustMe, todo;

CommonTypes* getCommonTypes(
	ref Alloc alloc,
	Uri curUri,
	InstantiateCtx instantiateCtx,
	scope ref ArrayBuilder!Diagnostic diagnosticsBuilder,
	in StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayedStructInsts,
) {
	void addDiagMissing(Symbol name) {
		add(alloc, diagnosticsBuilder, Diagnostic(Range.empty, Diag(Diag.CommonTypeMissing(name))));
	}

	StructInst* nonTemplateFromSymbol(Symbol name) {
		Opt!(StructInst*) res =
			getCommonNonTemplateType(instantiateCtx, structsAndAliasesMap, name, delayedStructInsts);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return instantiateNonTemplateStructDecl(instantiateCtx, delayedStructInsts, bogusStructDecl(alloc, 0));
		}
	}
	StructInst* nonTemplate(string name)() {
		return nonTemplateFromSymbol(symbol!name);
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
	StructInst* symbolType = nonTemplate!"symbol";
	StructInst* void_ = nonTemplate!"void";

	StructDecl* getDeclFromSymbol(Symbol name, size_t nTypeParameters) {
		Opt!(StructDecl*) res = getCommonTemplateType(structsAndAliasesMap, name, nTypeParameters);
		if (has(res))
			return force(res);
		else {
			addDiagMissing(name);
			return bogusStructDecl(alloc, nTypeParameters);
		}
	}
	StructDecl* getDecl(string name)(size_t nTypeParameters) {
		return getDeclFromSymbol(symbol!name, nTypeParameters);
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
	StructInst* cString = instantiateStruct(
		instantiateCtx, constPointer, small!Type([Type(char8)]), someMut(ptrTrustMe(delayedStructInsts)));

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

	return allocate(alloc, CommonTypes(
		bool_,
		char8,
		cString,
		float32,
		float64,
		IntegralTypes(int8, int16, int32, int64, nat8, nat16, nat32, nat64),
		symbolType,
		void_,
		array,
		future,
		opt,
		pointerConst,
		pointerMut,
		tuples,
		funs));
}

private:

Opt!(StructDecl*) getCommonTemplateType(
	in StructsAndAliasesMap structsAndAliasesMap,
	Symbol name,
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
	ref InstantiateCtx ctx,
	in StructsAndAliasesMap structsAndAliasesMap,
	Symbol name,
	scope ref DelayStructInsts delayedStructInsts,
) {
	Opt!StructOrAlias opStructOrAlias = structsAndAliasesMap[name];
	return has(opStructOrAlias)
		? instantiateNonTemplateStructOrAlias(ctx, delayedStructInsts, force(opStructOrAlias))
		: none!(StructInst*);
}

Opt!(StructInst*) instantiateNonTemplateStructOrAlias(
	ref InstantiateCtx ctx,
	scope ref DelayStructInsts delayedStructInsts,
	StructOrAlias structOrAlias,
) {
	assert(isEmpty(structOrAlias.typeParams));
	return structOrAlias.matchWithPointers!(Opt!(StructInst*))(
		(StructAlias* x) =>
			x.target,
		(StructDecl* x) =>
			some(instantiateNonTemplateStructDecl(ctx, delayedStructInsts, x)));
}

StructInst* instantiateNonTemplateStructDecl(
	ref InstantiateCtx ctx,
	scope ref DelayStructInsts delayedStructInsts,
	StructDecl* structDecl,
) =>
	instantiateStruct(ctx, structDecl, emptyTypeArgs, someMut(ptrTrustMe(delayedStructInsts)));

StructDecl* bogusStructDecl(ref Alloc alloc, size_t nTypeParameters) {
	ArrayBuilder!NameAndRange typeParams;
	UriAndRange uriAndRange = UriAndRange.empty;
	foreach (size_t i; 0 .. nTypeParameters)
		add(alloc, typeParams, NameAndRange(0, symbol!"bogus"));
	StructDecl* res = allocate(alloc, StructDecl(
		StructDeclSource(allocate(alloc, StructDeclSource.Bogus(TypeParams(finish(alloc, typeParams))))),
		uriAndRange.uri,
		symbol!"bogus",
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	res.body_ = StructBody(StructBody.Bogus());
	return res;
}
