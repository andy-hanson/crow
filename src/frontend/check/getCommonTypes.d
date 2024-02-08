module frontend.check.getCommonTypes;

@safe @nogc pure nothrow:

import frontend.check.instantiate : DelayStructInsts, InstantiateCtx, instantiateStruct;
import frontend.check.maps : StructsAndAliasesMap;
import model.ast : NameAndRange;
import model.diag : Diag, Diagnostic;
import model.model :
	CommonTypes,
	emptyTypeArgs,
	EnumBackingType,
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
import util.col.array : isEmpty, makeArray, small;
import util.col.arrayBuilder : add, ArrayBuilder;
import util.col.enumMap : EnumMap, makeEnumMap;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, someMut, some;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol, symbol, symbolOfEnum;
import util.uri : Uri;
import util.util : ptrTrustMe;

CommonTypes* getCommonTypes(
	ref Alloc alloc,
	Uri curUri,
	InstantiateCtx instantiateCtx,
	scope ref ArrayBuilder!Diagnostic diagnosticsBuilder,
	in StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayedStructInsts,
) {
	CommonTypesCtx ctx = CommonTypesCtx(
		ptrTrustMe(alloc),
		instantiateCtx,
		ptrTrustMe(diagnosticsBuilder),
		ptrTrustMe(structsAndAliasesMap),
		ptrTrustMe(delayedStructInsts));
	StructInst* char8 = nonTemplate(ctx, symbol!"char8");
	StructInst* symbolType = nonTemplate(ctx, symbol!"symbol");
	StructInst* void_ = nonTemplate(ctx, symbol!"void");
	StructDecl* array = getDecl(ctx, symbol!"array", 1);
	StructDecl* future = getDecl(ctx, symbol!"future", 1);
	StructDecl* pointerConst = getDecl(ctx, symbol!"const-pointer", 1);
	return allocate(alloc, CommonTypes(
		bool_: nonTemplate(ctx, symbol!"bool"),
		char8: char8,
		cString: instantiate1(ctx, pointerConst, char8),
		float32: nonTemplate(ctx, symbol!"float32"),
		float64: nonTemplate(ctx, symbol!"float64"),
		integrals: IntegralTypes(makeEnumMap!EnumBackingType((EnumBackingType type) =>
			nonTemplate(ctx, symbolOfEnum(type)))),
		string_: nonTemplate(ctx, symbol!"string"),
		symbol: symbolType,
		symbolArray: instantiate1(ctx, array, symbolType),
		void_: void_,
		array: array,
		future: future,
		voidFuture: instantiate1(ctx, future, void_),
		opt: getDecl(ctx, symbol!"option", 1),
		ptrConst: pointerConst,
		ptrMut: getDecl(ctx, symbol!"mut-pointer", 1),
		tuples2Through9: [
			getDecl(ctx, symbol!"tuple2", 2),
			getDecl(ctx, symbol!"tuple3", 3),
			getDecl(ctx, symbol!"tuple4", 4),
			getDecl(ctx, symbol!"tuple5", 5),
			getDecl(ctx, symbol!"tuple6", 6),
			getDecl(ctx, symbol!"tuple7", 7),
			getDecl(ctx, symbol!"tuple8", 8),
			getDecl(ctx, symbol!"tuple9", 9),
		],
		funStructs: immutable EnumMap!(FunKind, StructDecl*)([
			getDecl(ctx, symbol!"fun-data", 2),
			getDecl(ctx, symbol!"fun-shared", 2),
			getDecl(ctx, symbol!"fun-mut", 2),
			getDecl(ctx, symbol!"fun-pointer", 2),
		])));
}

private:

struct CommonTypesCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	InstantiateCtx instantiateCtx;
	ArrayBuilder!Diagnostic* diagnosticsBuilderPtr;
	StructsAndAliasesMap* structsAndAliasesMapPtr;
	DelayStructInsts* delayedStructInstsPtr;

	ref Alloc alloc() =>
		*allocPtr;
	ref ArrayBuilder!Diagnostic diagnosticsBuilder() =>
		*diagnosticsBuilderPtr;
	ref StructsAndAliasesMap structsAndAliasesMap() =>
		*structsAndAliasesMapPtr;
	ref DelayStructInsts delayedStructInsts() =>
		*delayedStructInstsPtr;
}

void addDiagMissing(ref CommonTypesCtx ctx, Symbol name) {
	add(ctx.alloc, ctx.diagnosticsBuilder, Diagnostic(Range.empty, Diag(Diag.CommonTypeMissing(name))));
}

StructDecl* getDecl(ref CommonTypesCtx ctx, Symbol name, size_t nTypeParameters) {
	Opt!(StructDecl*) res = getCommonTemplateType(ctx.structsAndAliasesMap, name, nTypeParameters);
	if (has(res))
		return force(res);
	else {
		addDiagMissing(ctx, name);
		return bogusStructDecl(ctx.alloc, nTypeParameters);
	}
}

StructInst* nonTemplate(ref CommonTypesCtx ctx, Symbol name) {
	Opt!(StructInst*) res =
		getCommonNonTemplateType(ctx.instantiateCtx, ctx.structsAndAliasesMap, name, ctx.delayedStructInsts);
	if (has(res))
		return force(res);
	else {
		addDiagMissing(ctx, name);
		return instantiateNonTemplateStructDecl(
			ctx.instantiateCtx, ctx.delayedStructInsts, bogusStructDecl(ctx.alloc, 0));
	}
}

StructInst* instantiate1(ref CommonTypesCtx ctx, StructDecl* decl, StructInst* typeArg) {
	Type[1] typeArgs = [Type(typeArg)];
	return instantiateStruct(ctx.instantiateCtx, decl, small!Type(typeArgs), someMut(ctx.delayedStructInstsPtr));
}

Opt!(StructDecl*) getCommonTemplateType(
	in StructsAndAliasesMap structsAndAliasesMap,
	Symbol name,
	size_t expectedTypeParams,
) {
	Opt!StructOrAlias res = structsAndAliasesMap[name];
	if (has(res) && force(res).isA!(StructDecl*)) {
		// TODO: may fail -- builtin Template should not be an alias
		StructDecl* decl = force(res).as!(StructDecl*);
		return optIf(decl.typeParams.length == expectedTypeParams, () => decl);
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
		? some(instantiateNonTemplateStructOrAlias(ctx, delayedStructInsts, force(opStructOrAlias)))
		: none!(StructInst*);
}

StructInst* instantiateNonTemplateStructOrAlias(
	ref InstantiateCtx ctx,
	scope ref DelayStructInsts delayedStructInsts,
	StructOrAlias structOrAlias,
) {
	assert(isEmpty(structOrAlias.typeParams));
	return structOrAlias.matchWithPointers!(StructInst*)(
		(StructAlias* x) =>
			x.target,
		(StructDecl* x) =>
			instantiateNonTemplateStructDecl(ctx, delayedStructInsts, x));
}

StructInst* instantiateNonTemplateStructDecl(
	ref InstantiateCtx ctx,
	scope ref DelayStructInsts delayedStructInsts,
	StructDecl* structDecl,
) =>
	instantiateStruct(ctx, structDecl, emptyTypeArgs, someMut(ptrTrustMe(delayedStructInsts)));

StructDecl* bogusStructDecl(ref Alloc alloc, size_t nTypeParameters) {
	UriAndRange uriAndRange = UriAndRange.empty;
	TypeParams typeParams = small!NameAndRange(makeArray!NameAndRange(alloc, nTypeParameters, (size_t i) =>
		NameAndRange(0, symbol!"")));
	StructDecl* res = allocate(alloc, StructDecl(
		StructDeclSource(allocate(alloc, StructDeclSource.Bogus(typeParams))),
		uriAndRange.uri,
		symbol!"",
		Visibility.public_,
		Linkage.internal,
		Purity.data,
		false));
	res.body_ = StructBody(StructBody.Bogus());
	return res;
}
