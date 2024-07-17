module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArray, getConstantCString, getConstantSymbol;
import concretize.concretizeExpr :
	concretizeBogus,
	concretizeBogusKind,
	ConcretizeExprCtx,
	concretizeFunBody,
	ensureVariantMember,
	withConcretizeExprCtx;
import concretize.generate :
	bodyForEnumOrFlagsMembers,
	concretizeAutoFun,
	genConstant,
	genCreateRecord,
	genCreateUnion,
	genLocalGet,
	genRecordFieldCall,
	genRecordFieldGet,
	genRecordFieldPointer,
	genRecordFieldSet,
	genSeq,
	genStringLiteralKind,
	genUnionMemberGet,
	unwrapOptionType;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteFunSource,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteMutability,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVar,
	hasSizeOrPointerSizeBytes,
	isBogus,
	mustBeByVal,
	purity,
	ReferenceKind,
	sizeOrPointerSizeBytes,
	TypeSize;
import model.constant : Constant, constantZero;
import model.model :
	AutoFun,
	BuiltinFun,
	BuiltinType,
	CommonTypes,
	Destructure,
	eachTest,
	EnumOrFlagsFunction,
	EnumOrFlagsMember,
	Expr,
	FunBody,
	FunDecl,
	FunInst,
	getAllFlagsValue,
	ImportFileContent,
	IntegralType,
	isArrayOrMutArray,
	isLambdaType,
	isNonFunctionPointer,
	isString,
	isSymbol,
	isTuple,
	Local,
	Module,
	paramsArray,
	Program,
	ProgramWithMain,
	Purity,
	RecordField,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	Type,
	TypeParamIndex,
	UnionMember,
	VarDecl,
	worsePurity;
import util.alloc.alloc : Alloc;
import util.alloc.stackAlloc : withMapToStackArray;
import util.col.array :
	emptySmallArray,
	every,
	exists,
	fold,
	isEmpty,
	map,
	mapPointers,
	mapPointersWithIndex,
	mapWithIndex,
	mapZip,
	maxBy,
	newSmallArray,
	only,
	onlyPointer,
	small,
	SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildArray, Builder;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, moveToArray, MutHashTable;
import util.col.mutArr : filterUnordered, MutArr, mutArrIsEmpty, push;
import util.col.mutMap : getOrAddAndDidAdd, mustAdd, MutMap, ValueAndDidAdd;
import util.integralValues : IntegralValue;
import util.late : Late, late, lateGet, lateSet, lazilySet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOrDefault;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol;
import util.symbolSet : SymbolSet;
import util.util : enumConvert, max, roundUp, typeAs;
import versionInfo : OS, VersionInfo;

private alias TypeArgsScope = SmallArray!ConcreteType;

private ConcreteStructSource.Inst getStructKey(return in ConcreteStruct* a) =>
	a.source.as!(ConcreteStructSource.Inst);

private VarDecl* getVarKey(return in ConcreteVar* a) =>
	a.source;

private ConcreteFunKey getFunKey(return in ConcreteFun* a) =>
	a.source.as!ConcreteFunKey;

TypeArgsScope typeArgsScopeForFun(ConcreteFun* a) =>
	a.source.match!TypeArgsScope(
		(ConcreteFunKey x) =>
			x.typeArgs,
		(ref ConcreteFunSource.Lambda x) =>
			typeArgsScopeForFun(x.containingFun),
		(ref ConcreteFunSource.Test x) =>
			emptySmallArray!ConcreteType,
		(ref ConcreteFunSource.WrapMain x) =>
			emptySmallArray!ConcreteType);

immutable struct SpecsScope {
	SmallArray!(immutable SpecInst*) specs;
	SmallArray!(immutable ConcreteFun*) specImpls;
}
SpecsScope specsScopeForFun(ConcreteFun* a) =>
	a.source.match!SpecsScope(
		(ConcreteFunKey x) =>
			SpecsScope(x.decl.specs, x.specImpls),
		(ref ConcreteFunSource.Lambda x) =>
			specsScopeForFun(x.containingFun),
		(ref ConcreteFunSource.Test x) =>
			emptySpecsScope,
		(ref ConcreteFunSource.WrapMain x) =>
			emptySpecsScope);
private SpecsScope emptySpecsScope() =>
	SpecsScope(emptySmallArray!(immutable SpecInst*), emptySmallArray!(immutable ConcreteFun*));

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable VersionInfo versionInfo;
	immutable Program* programPtr;
	FileContentGetters fileContentGetters; // For 'assert' or 'forbid' messages and file imports
	SymbolSet allExterns;
	Late!(ConcreteFun*) createErrorFunction_;
	Late!(ConcreteFun*) char8ArrayTrustAsString_;
	Late!(ConcreteFun*) equalNat64Function_;
	Late!(ConcreteFun*) lessNat64Function_;
	Late!(ConcreteFun*) newChar8ListFunction_;
	Late!(ConcreteFun*) newChar32ListFunction_;
	Late!(ConcreteFun*) newJsonFromPairsFunction_;
	AllConstantsBuilder allConstants;
	MutHashTable!(ConcreteStruct*, ConcreteStructSource.Inst, getStructKey) nonLambdaConcreteStructs;
	ArrayBuilder!(ConcreteStruct*) allConcreteStructs;
	MutHashTable!(immutable ConcreteVar*, immutable VarDecl*, getVarKey) concreteVarLookup;
	MutHashTable!(ConcreteFun*, ConcreteFunKey, getFunKey) nonLambdaConcreteFuns;
	MutArr!(ConcreteStruct*) deferredTypeSize;
	MutArr!(ConcreteFun*) deferredVariantMethods;
	ArrayBuilder!(ConcreteFun*) allConcreteFuns;

	// Index in the MutArr!ConcreteLambdaImpl is the fun ID
	MutMap!(ConcreteStruct*, MutArr!ConcreteLambdaImpl) lambdaStructToImpls;
	MutMap!(ConcreteStruct*, MutArr!ConcreteVariantMemberAndMethodImpls) variantStructToMembers;
	Late!ConcreteType _bogusType;
	Late!ConcreteType _boolType;
	Late!ConcreteType _char8Type;
	Late!ConcreteType _char8ArrayType;
	Late!ConcreteType _char8ConstPointerType;
	Late!ConcreteType _char32Type;
	Late!ConcreteType _char32ArrayType;
	Late!ConcreteType _exceptionType;
	Late!ConcreteType _voidType;
	Late!ConcreteType _nat64Type;
	Late!ConcreteType _ctxType;
	Late!ConcreteType _symbolType;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref Program program() return scope const =>
		*programPtr;
	ref CommonTypes commonTypes() return scope const =>
		*program.commonTypes;
	ConcreteFun* char8ArrayTrustAsString() return scope const => // TODO: Since this is now the identity function, we probably don't need it here?
		lateGet(char8ArrayTrustAsString_);
	ConcreteFun* equalNat64Function() return scope const =>
		lateGet(equalNat64Function_);
	ConcreteFun* lessNat64Function() return scope const =>
		lateGet(lessNat64Function_);
	ConcreteFun* newChar8ListFunction() return scope const =>
		lateGet(newChar8ListFunction_);
	ConcreteFun* newChar32ListFunction() return scope const =>
		lateGet(newChar32ListFunction_);
	ConcreteFun* newJsonFromPairsFunction() return scope const =>
		lateGet(newJsonFromPairsFunction_);
	ConcreteFun* createErrorFunction() return scope const =>
		lateGet(createErrorFunction_);
}

immutable struct ConcreteLambdaImpl {
	ConcreteType closureType;
	ConcreteFun* impl;
}

immutable struct ConcreteVariantMemberAndMethodImpls {
	@safe @nogc pure nothrow:

	ConcreteType memberType;
	Late!(SmallArray!(Opt!(ConcreteFun*))) methodImpls_;

	SmallArray!(Opt!(ConcreteFun*)) methodImpls() =>
		lateGet(methodImpls_);
	void methodImpls(SmallArray!(Opt!(ConcreteFun*)) value) =>
		lateSet(methodImpls_, value);
}

immutable(ConcreteVar*[]) finishConcreteVars(ref ConcretizeCtx ctx) =>
	moveToArray!(immutable ConcreteVar*, immutable VarDecl*, getVarKey)(ctx.alloc, ctx.concreteVarLookup);

private ConcreteType bogusType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._bogusType, () {
		ConcreteStruct* res = allocate(a.alloc, ConcreteStruct(
			Purity.data,
			ConcreteStruct.SpecialKind.none,
			ConcreteStructSource(ConcreteStructSource.Bogus())));
		add(a.alloc, a.allConcreteStructs, res);
		res.info = ConcreteStructInfo(
			ConcreteStructBody(ConcreteStructBody.Record(emptySmallArray!ConcreteField)),
			false);
		res.defaultReferenceKind = ReferenceKind.byVal;
		res.typeSize = TypeSize(0, 1);
		res.fieldOffsets = typeAs!(immutable uint[])([]);
		return ConcreteType(ReferenceKind.byVal, res);
	});

ConcreteType boolType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._boolType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.bool_, emptySmallArray!ConcreteType));

ConcreteType voidType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._voidType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.void_, emptySmallArray!ConcreteType));

ConcreteType char8Type(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._char8Type, () =>
		getConcreteType_forStructInst(a, a.commonTypes.char8, emptySmallArray!ConcreteType));

ConcreteType char8ArrayType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._char8ArrayType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.char8Array, emptySmallArray!ConcreteType));
ConcreteType char8ConstPointerType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._char8ConstPointerType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.char8ConstPointer, emptySmallArray!ConcreteType));

ConcreteType char32Type(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._char32Type, () =>
		getConcreteType_forStructInst(a, a.commonTypes.char32, emptySmallArray!ConcreteType));

ConcreteType char32ArrayType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._char32ArrayType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.char32Array, emptySmallArray!ConcreteType));

ConcreteType nat64Type(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._nat64Type, () =>
		getConcreteType_forStructInst(a, a.commonTypes.integrals.nat64, emptySmallArray!ConcreteType));

ConcreteType exceptionType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._exceptionType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.exception, emptySmallArray!ConcreteType));

ConcreteType symbolType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._symbolType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.symbol, emptySmallArray!ConcreteType));

ConcreteStruct* symbolArrayType(ref ConcretizeCtx a) =>
	mustBeByVal(getConcreteType_forStructInst(a, a.commonTypes.symbolArray, emptySmallArray!ConcreteType));

ConcreteType getReferencedType(in ConcretizeCtx ctx, ConcreteType type) {
	ConcreteStructSource.Inst inst = type.struct_.source.as!(ConcreteStructSource.Inst);
	assert(inst.decl == ctx.commonTypes.reference);
	return only(inst.typeArgs);
}

Constant constantCString(ref ConcretizeCtx a, string value) =>
	getConstantCString(a.alloc, a.allConstants, value);

Constant constantSymbol(ref ConcretizeCtx a, Symbol value) =>
	getConstantSymbol(a.alloc, a.allConstants, value);

ConcreteFun* getConcreteFun(
	ref ConcretizeCtx ctx,
	FunDecl* decl,
	in ConcreteType[] typeArgs,
	in immutable ConcreteFun*[] specImpls,
) {
	ValueAndDidAdd!(ConcreteFun*) res = getOrAddAndDidAdd(
		ctx.alloc,
		ctx.nonLambdaConcreteFuns,
		ConcreteFunKey(decl, small!ConcreteType(typeArgs), small!(immutable ConcreteFun*)(specImpls)),
		() => getConcreteFunFromKey(ctx, ConcreteFunKey(
			decl, newSmallArray(ctx.alloc, typeArgs), newSmallArray(ctx.alloc, specImpls))));
	if (res.didAdd) {
		addConcreteFun(ctx, res.value);
		fillInConcreteFunBody(ctx, paramsArray(decl.params), res.value);
	}
	return res.value;
}
ConcreteFun* getNonTemplateConcreteFun(ref ConcretizeCtx ctx, FunInst* inst) {
	assert(!inst.decl.isTemplate);
	return getConcreteFun(ctx, inst.decl, [], []);
}

ConcreteFun* getConcreteFunForLambda(
	ref ConcretizeCtx ctx,
	ConcreteFun* containingConcreteFun,
	size_t index,
	ConcreteType returnType,
	Destructure modelParam,
	SmallArray!ConcreteLocal params,
	Expr* bodyExpr,
) {
	assert(!isBogus(returnType));
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Lambda(containingConcreteFun, bodyExpr, index))),
		returnType,
		params));
	fillInConcreteFunBody(ctx, [modelParam], res);
	addConcreteFun(ctx, res);
	return res;
}

private ConcreteType getConcreteType_forStructInst(
	ref ConcretizeCtx ctx,
	StructInst* inst,
	in TypeArgsScope typeArgsScope,
) {
	if (isString(Type(inst)))
		return char8ArrayType(ctx); // This makes 'string' *not* a distinct type from char8 array. So 'string' won't exist in the ConcreteModel
	if (isSymbol(Type(inst)))
		return char8ConstPointerType(ctx);	

	return withConcreteTypes(ctx, inst.typeArgs, typeArgsScope, (scope ConcreteType[] typeArgs) {
		StructDecl* decl = inst.decl;
		scope ConcreteStructSource.Inst key = ConcreteStructSource.Inst(decl, small!ConcreteType(typeArgs));
		ValueAndDidAdd!(ConcreteStruct*) res =
			getOrAddAndDidAdd!(ConcreteStruct*, ConcreteStructSource.Inst, getStructKey)(
				ctx.alloc, ctx.nonLambdaConcreteStructs, key, () {
					Purity purity = fold!(Purity, ConcreteType)(
						decl.purity, typeArgs, (Purity p, in ConcreteType ta) =>
							worsePurity(p, purity(ta)));
					ConcreteStruct.SpecialKind specialKind = isArrayOrMutArray(*decl)
						? ConcreteStruct.SpecialKind.arrayOrMutArray
						: inst == ctx.program.commonFuns.catchPointType
						? ConcreteStruct.SpecialKind.catchPoint
						: inst == ctx.commonTypes.fiber
						? ConcreteStruct.SpecialKind.fiber
						: isNonFunctionPointer(*decl)
						? ConcreteStruct.SpecialKind.pointer
						: isTuple(ctx.commonTypes, decl)
						? ConcreteStruct.SpecialKind.tuple
						: ConcreteStruct.SpecialKind.none;
					ConcreteStruct* res = allocate(ctx.alloc, ConcreteStruct(
						purity,
						specialKind,
						ConcreteStructSource(ConcreteStructSource.Inst(decl, newSmallArray(ctx.alloc, typeArgs)))));
					add(ctx.alloc, ctx.allConcreteStructs, res);
					return res;
				});
		if (res.didAdd) {
			initializeConcreteStruct(ctx, *inst, res.value, typeArgsScope);
			if (isLambdaType(*decl))
				mustAdd(ctx.alloc, ctx.lambdaStructToImpls, res.value, MutArr!ConcreteLambdaImpl());
		}
		if (!res.value.defaultReferenceKindIsSet)
			// The only way 'defaultIsPointer' would not be set is if we are still computing the size of 's'.
			// In that case, it's a recursive record, so it should be by-ref.
			res.value.defaultReferenceKind = ReferenceKind.byRef;
		return ConcreteType(res.value.defaultReferenceKind, res.value);
	});
}

ConcreteType getConcreteType(ref ConcretizeCtx ctx, Type t, in TypeArgsScope typeArgsScope) =>
	t.matchWithPointers!ConcreteType(
		(Type.Bogus) =>
			bogusType(ctx),
		(TypeParamIndex x) =>
			typeArgsScope[x.index],
		(StructInst* i) =>
			getConcreteType_forStructInst(ctx, i, typeArgsScope));

T withConcreteTypes(T)(
	ref ConcretizeCtx ctx,
	in Type[] types,
	in TypeArgsScope typeArgsScope,
	in T delegate(scope ConcreteType[]) @safe @nogc pure nothrow cb,
) =>
	withMapToStackArray!(T, ConcreteType, Type)(types, (ref Type t) => getConcreteType(ctx, t, typeArgsScope), cb);

ConcreteType concreteTypeFromClosure(
	ref ConcretizeCtx ctx,
	SmallArray!ConcreteField closureFields,
	ConcreteStructSource source,
) {
	if (isEmpty(closureFields))
		return voidType(ctx);
	else {
		Purity purity = fold!(Purity, ConcreteField)(Purity.data, closureFields, (Purity p, in ConcreteField f) {
			// TODO: lambda fields are never mutable, use a different type?
			assert(f.mutability == ConcreteMutability.const_);
			return worsePurity(p, purity(f.type));
		});
		ConcreteStruct* cs = allocate(ctx.alloc, ConcreteStruct(purity, ConcreteStruct.SpecialKind.none, source));
		cs.info = getConcreteStructInfoForFields(closureFields);
		setConcreteStructRecordSizeOrDefer(ctx, cs);
		add(ctx.alloc, ctx.allConcreteStructs, cs);
		// TODO: consider passing closure by value
		return ConcreteType(ReferenceKind.byRef, cs);
	}
}

private void setConcreteStructRecordSizeOrDefer(ref ConcretizeCtx ctx, ConcreteStruct* cs) {
	if (canGetRecordSize(cs))
		setConcreteStructRecordSize(ctx.alloc, cs);
	else
		push(ctx.alloc, ctx.deferredTypeSize, cs);
}

private bool canGetRecordSize(in ConcreteStruct* a) =>
	every!ConcreteField(a.body_.as!(ConcreteStructBody.Record).fields, (in ConcreteField field) =>
		hasSizeOrPointerSizeBytes(field.type));

private void setConcreteStructRecordSize(ref Alloc alloc, ConcreteStruct* a) {
	FieldsType fieldsType = a.source.isA!(ConcreteStructSource.Lambda) ? FieldsType.closure : FieldsType.record;
	bool packed = fieldsType == FieldsType.record &&
		a.source.as!(ConcreteStructSource.Inst).decl.body_.as!(StructBody.Record).flags.packed;
	TypeSizeAndFieldOffsets size = recordSize(alloc, packed, a.body_.as!(ConcreteStructBody.Record).fields);
	if (!a.defaultReferenceKindIsSet)
		a.defaultReferenceKind = getDefaultReferenceKindForFields(size.typeSize, a.isSelfMutable, fieldsType);
	a.typeSize = size.typeSize;
	a.fieldOffsets = size.fieldOffsets;
}

private:

ConcreteFun* getConcreteFunFromKey(ref ConcretizeCtx ctx, ConcreteFunKey key) {
	TypeArgsScope typeScope = key.typeArgs;
	ConcreteType returnType = getConcreteType(ctx, key.decl.returnType, typeScope);
	SmallArray!ConcreteLocal params = map(ctx.alloc, paramsArray(key.decl.params), (ref Destructure x) =>
		concretizeParamDestructure(ctx, x, typeScope));
	return allocate(ctx.alloc, ConcreteFun(ConcreteFunSource(key), returnType, params));
}

public SmallArray!ConcreteLocal concretizeLambdaParams(
	ref ConcretizeCtx ctx,
	ConcreteType closureType,
	Destructure param,
	TypeArgsScope typeArgsScope,
) =>
	newSmallArray!ConcreteLocal(ctx.alloc, [
		ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Closure()), closureType),
		concretizeParamDestructure(ctx, param, typeArgsScope),
	]);

ConcreteLocal concretizeParamDestructure(ref ConcretizeCtx ctx, ref Destructure x, TypeArgsScope typeArgsScope) =>
	ConcreteLocal(
		x.matchWithPointers!ConcreteLocalSource(
			(Destructure.Ignore*) =>
				ConcreteLocalSource(ConcreteLocalSource.Generated.ignore),
			(Local* x) =>
				ConcreteLocalSource(x),
			(Destructure.Split*) =>
				ConcreteLocalSource(ConcreteLocalSource.Generated.destruct)),
		getConcreteType(ctx, x.type, typeArgsScope));

void addConcreteFun(ref ConcretizeCtx ctx, ConcreteFun* fun) {
	add(ctx.alloc, ctx.allConcreteFuns, fun);
}

ConcreteFunBody bodyForAllTests(ref ConcretizeCtx ctx, ConcreteType returnType) =>
	ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(getConstantArray(
		ctx.alloc,
		ctx.allConstants,
		mustBeByVal(returnType),
		buildArray!Constant(ctx.alloc, (scope ref Builder!Constant out_) {
			size_t testIndex = 0;
			eachTest(ctx.program, ctx.allExterns, (Test* test) {
				out_ ~= Constant(Constant.FunPointer(concreteFunForTest(ctx, test, testIndex++)));
			});
		})))));

ConcreteFun* concreteFunForTest(ref ConcretizeCtx ctx, Test* test, size_t testIndex) {
	ConcreteType voidType = voidType(ctx);
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Test(test, testIndex))),
		voidType,
		emptySmallArray!ConcreteLocal));
	res.body_ = ConcreteFunBody(concretizeFunBody(ctx, res, [], test.body_));
	addConcreteFun(ctx, res);
	return res;
}

public ConcreteFun* concreteFunForWrapMain(ref ConcretizeCtx ctx, StructInst* modelStringList, FunInst* modelMain) {
	ConcreteType stringListType = getConcreteType_forStructInst(ctx, modelStringList, emptySmallArray!ConcreteType);
	ConcreteFun* innerMain = getNonTemplateConcreteFun(ctx, modelMain);
	/*
	This is like:
		wrapped-main nat^(_ string[])
			real-main
			0
	*/
	ConcreteType nat64 = nat64Type(ctx);
	UriAndRange range = modelMain.decl.range;
	ConcreteExpr callMain = ConcreteExpr(voidType(ctx), range, ConcreteExprKind(
		ConcreteExprKind.Call(innerMain, emptySmallArray!ConcreteExpr)));
	ConcreteExpr zero = ConcreteExpr(nat64, range, ConcreteExprKind(constantZero));
	ConcreteExpr body_ = genSeq(ctx.alloc, range, callMain, zero);
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.WrapMain(range))),
		nat64,
		newSmallArray(ctx.alloc, [
			ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Generated.args), stringListType),
		])));
	res.body_ = ConcreteFunBody(body_);
	addConcreteFun(ctx, res);
	return res;
}

bool canGetUnionSize(in ConcreteType[] members) =>
	every!ConcreteType(members, (in ConcreteType type) =>
		hasSizeOrPointerSizeBytes(type));

TypeSize unionSize(in ConcreteType[] members) {
	uint unionAlign = 8;
	uint maxMember = maxBy!(uint, ConcreteType)(0, members, (in ConcreteType x) =>
		sizeOrPointerSizeBytes(x).sizeBytes);
	uint sizeBytes = roundUp(8 + maxMember, unionAlign);
	return TypeSize(sizeBytes, unionAlign);
}

ReferenceKind getDefaultReferenceKindForFields(TypeSize typeSize, bool isSelfMutable, FieldsType type) {
	uint maxSize = () {
		final switch (type) {
			case FieldsType.closure:
				return 8;
			case FieldsType.record:
				return 8 * 2;
		}
	}();
	return isSelfMutable || typeSize.sizeBytes > maxSize ? ReferenceKind.byRef : ReferenceKind.byVal;
}

enum FieldsType { record, closure }

ConcreteStructInfo getConcreteStructInfoForFields(SmallArray!ConcreteField fields) =>
	ConcreteStructInfo(
		ConcreteStructBody(ConcreteStructBody.Record(fields)),
		exists!ConcreteField(fields, (in ConcreteField field) =>
			field.mutability != ConcreteMutability.const_));

immutable struct TypeSizeAndFieldOffsets {
	TypeSize typeSize;
	uint[] fieldOffsets;
}

TypeSizeAndFieldOffsets recordSize(ref Alloc alloc, bool packed, in ConcreteField[] fields) {
	uint maxFieldSize = 1;
	uint maxFieldAlignment = 1;
	uint offsetBytes = 0;
	immutable uint[] fieldOffsets = map!(immutable uint, ConcreteField)(alloc, fields, (ref ConcreteField field) {
		TypeSize fieldSize = sizeOrPointerSizeBytes(field.type);
		maxFieldSize = max(maxFieldSize, fieldSize.sizeBytes);
		if (!packed) {
			if (fieldSize.alignmentBytes != 0) {
				maxFieldAlignment = max(maxFieldAlignment, fieldSize.alignmentBytes);
				offsetBytes = roundUp(offsetBytes, fieldSize.alignmentBytes);
			}
		}
		uint fieldOffset = offsetBytes;
		offsetBytes += fieldSize.sizeBytes;
		return fieldOffset;
	});
	TypeSize typeSize = TypeSize(roundUp(offsetBytes, maxFieldAlignment), maxFieldAlignment);
	return TypeSizeAndFieldOffsets(typeSize, fieldOffsets);
}

void initializeConcreteStruct(
	ref ConcretizeCtx ctx,
	in StructInst inst,
	ConcreteStruct* res,
	in TypeArgsScope typeArgsScope,
) {
	inst.decl.body_.match!void(
		(StructBody.Bogus) {
			assert(false);
		},
		(BuiltinType x) {
			initializeConcreteStructForBuiltin(ctx, res, x);
		},
		(ref StructBody.Enum x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Enum(x.storage)), false);
			res.typeSize = typeSizeForEnumOrFlags(x.storage);
		},
		(StructBody.Extern x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Extern()), false);
			res.typeSize = optOrDefault!TypeSize(x.size, () => TypeSize(0, 0));
		},
		(StructBody.Flags x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Flags(x.storage)), false);
			res.typeSize = typeSizeForEnumOrFlags(x.storage);
		},
		(StructBody.Record r) {
			// don't set 'defaultReferenceKind' until the end, unless explicit
			if (has(r.flags.forcedByValOrRef))
				res.defaultReferenceKind = enumConvert!ReferenceKind(force(r.flags.forcedByValOrRef));

			SmallArray!ConcreteField fields = mapZip!(ConcreteField, RecordField, Type)(
				ctx.alloc, r.fields, inst.instantiatedTypes, (ref RecordField f, ref Type type) =>
					ConcreteField(
						f.name,
						has(f.mutability) ? ConcreteMutability.mutable : ConcreteMutability.const_,
						getConcreteType(ctx, type, typeArgsScope)));
			ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			res.info = info;
			setConcreteStructRecordSizeOrDefer(ctx, res);
		},
		(ref StructBody.Union u) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			SmallArray!ConcreteType members = mapZip!(ConcreteType, UnionMember, Type)(
				ctx.alloc, u.members, inst.instantiatedTypes, (ref UnionMember x, ref Type type) =>
					getConcreteType(ctx, type, typeArgsScope));
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Union(late(members))), false);
			if (canGetUnionSize(members))
				res.typeSize = unionSize(members);
			else
				push(ctx.alloc, ctx.deferredTypeSize, res);
		},
		(StructBody.Variant) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Union()), false);
			// Always defer since we need to wait to know all variant members
			push(ctx.alloc, ctx.deferredTypeSize, res);
			mustAdd(ctx.alloc, ctx.variantStructToMembers, res, MutArr!ConcreteVariantMemberAndMethodImpls());
		});
}

void initializeConcreteStructForBuiltin(ref ConcretizeCtx ctx, ConcreteStruct* struct_, BuiltinType type) {
	struct_.defaultReferenceKind = ReferenceKind.byVal;
	if (type != BuiltinType.lambda) { // Lambda types handled in 'finishLambdas'
		struct_.info = ConcreteStructInfo(
			ConcreteStructBody(allocate(ctx.alloc, ConcreteStructBody.Builtin(
				type, struct_.source.as!(ConcreteStructSource.Inst).typeArgs))),
			false);
		struct_.typeSize = getBuiltinStructSize(type, ctx.versionInfo);
	}
}

TypeSize typeSizeForEnumOrFlags(IntegralType a) {
	uint size = sizeForEnumOrFlags(a);
	return TypeSize(size, size);
}
uint sizeForEnumOrFlags(IntegralType a) {
	final switch (a) {
		case IntegralType.int8:
		case IntegralType.nat8:
			return 1;
		case IntegralType.int16:
		case IntegralType.nat16:
			return 2;
		case IntegralType.int32:
		case IntegralType.nat32:
			return 4;
		case IntegralType.int64:
		case IntegralType.nat64:
			return 8;
	}
}

public void deferredFillRecordAndUnionBodies(ref ConcretizeCtx ctx) {
	while (!mutArrIsEmpty(ctx.deferredTypeSize)) {
		bool couldGetSomething = false;
		filterUnordered!(ConcreteStruct*)(ctx.deferredTypeSize, (ref ConcreteStruct* struct_) {
			bool canGet;
			if (struct_.body_.isA!(ConcreteStructBody.Record)) {
				canGet = canGetRecordSize(struct_);
				if (canGet) setConcreteStructRecordSize(ctx.alloc, struct_);
			} else {
				ConcreteType[] members = struct_.body_.as!(ConcreteStructBody.Union).members;
				canGet = canGetUnionSize(members);
				if (canGet) struct_.typeSize = unionSize(members);
			}
			if (canGet) couldGetSomething = true;
			return !canGet;
		});
		assert(couldGetSomething);
	}
}

void fillInConcreteFunBody(ref ConcretizeCtx ctx, in Destructure[] params, ConcreteFun* cf) {
	// set to arbitrary temporarily. (But it can't be a constant or something will optimize based on that!)
	cf.body_ = ConcreteFunBody(ConcreteFunBody.Extern(symbol!"bogus"));
	FunBody funBody = cf.source.match!FunBody(
		(ConcreteFunKey x) => x.decl.body_,
		(ref ConcreteFunSource.Lambda x) => FunBody(*x.bodyExpr),
		(ref ConcreteFunSource.Test x) => assert(false),
		(ref ConcreteFunSource.WrapMain x) => assert(false));
	ConcreteLocal[] concreteParams = cf.params;
	ConcreteFunBody body_ = funBody.match!ConcreteFunBody(
		(FunBody.Bogus) =>
			ConcreteFunBody(concretizeBogus(ctx, cf.returnType, cf.range)),
		(AutoFun x) =>
			withConcretizeExprCtx(ctx, cf, (ref ConcretizeExprCtx exprCtx) =>
				ConcreteFunBody(concretizeAutoFun(exprCtx, x))),
		(BuiltinFun x) =>
			x.isA!(BuiltinFun.AllTests)
				? bodyForAllTests(ctx, cf.returnType)
				: ConcreteFunBody(ConcreteFunBody.Builtin(x, cf.source.as!ConcreteFunKey.typeArgs)),
		(FunBody.CreateEnumOrFlags x) =>
			ConcreteFunBody(genConstant(cf.returnType, cf.range, Constant(IntegralValue(x.member.value.value)))),
		(FunBody.CreateExtern) =>
			ConcreteFunBody(genConstant(cf.returnType, cf.range, constantZero)),
		(FunBody.CreateRecord) =>
			isEmpty(concreteParams)
				? ConcreteFunBody(genConstant(
					cf.returnType, cf.range, Constant(Constant.Record(emptySmallArray!Constant))))
				: ConcreteFunBody(genCreateRecordFromParams(ctx.alloc, cf.returnType, cf.range, concreteParams)),
		(FunBody.CreateRecordAndConvertToVariant x) {
			ConcreteType memberType = getConcreteType(ctx, Type(x.member), cf.source.as!ConcreteFunKey.typeArgs);
			size_t memberIndex = ensureVariantMember(ctx, cf.returnType, memberType);
			return isEmpty(concreteParams)
				? ConcreteFunBody(genConstantUnionEmptyMemberType(ctx.alloc, cf.returnType, cf.range, memberIndex))
				: ConcreteFunBody(genCreateUnion(
					ctx.alloc, cf.returnType, cf.range, memberIndex,
					genCreateRecordFromParams(ctx.alloc, memberType, cf.range, concreteParams)));
		},
		(FunBody.CreateUnion x) =>
			createUnionBody(ctx.alloc, cf, x.member.memberIndex),
		(FunBody.CreateVariant x) =>
			createUnionBody(ctx.alloc, cf, ensureVariantMember(
				ctx, cf.returnType, isEmpty(concreteParams) ? voidType(ctx) : only(concreteParams).type)),
		(EnumOrFlagsFunction x) {
			final switch (x) {
				case EnumOrFlagsFunction.negate:
					return ConcreteFunBody(ConcreteFunBody.FlagsFn(
						getAllFlagsValue(mustBeByVal(cf.returnType)),
						x));
				case EnumOrFlagsFunction.equal:
				case EnumOrFlagsFunction.intersect:
				case EnumOrFlagsFunction.none:
				case EnumOrFlagsFunction.toIntegral:
				case EnumOrFlagsFunction.union_:
					return ConcreteFunBody(x);
				case EnumOrFlagsFunction.members:
					return bodyForEnumOrFlagsMembers(ctx, cf.returnType);
			}
		},
		(Expr x) =>
			ConcreteFunBody(concretizeFunBody(ctx, cf, params, x)),
		(FunBody.Extern x) =>
			ConcreteFunBody(ConcreteFunBody.Extern(x.libraryName)),
		(FunBody.FileImport x) =>
			ConcreteFunBody(concretizeFileImport(ctx, cf, x)),
		(FunBody.RecordFieldCall x) =>
			genRecordFieldCall(ctx, cf, x),
		(FunBody.RecordFieldGet x) =>
			ConcreteFunBody(genRecordFieldGet(
				cf.returnType, cf.range,
				allocate(ctx.alloc, genLocalGet(cf.range, onlyPointer(cf.params))),
				x.fieldIndex)),
		(FunBody.RecordFieldPointer x) =>
			ConcreteFunBody(genRecordFieldPointer(
				cf.returnType, cf.range,
				allocate(ctx.alloc, genLocalGet(cf.range, onlyPointer(cf.params))),
				x.fieldIndex)),
		(FunBody.RecordFieldSet x) {
			assert(cf.params.length == 2);
			return ConcreteFunBody(genRecordFieldSet(
				ctx,
				cf.range,
				genLocalGet(cf.range, &cf.params[0]),
				x.fieldIndex,
				genLocalGet(cf.range, &cf.params[1])));
		},
		(FunBody.UnionMemberGet x) =>
			genUnionMemberGet(ctx, cf, x.memberIndex),
		(FunBody.VarGet x) =>
			ConcreteFunBody(ConcreteFunBody.VarGet(getVar(ctx, x.var))),
		(FunBody.VariantMemberGet x) =>
			genUnionMemberGet(
				ctx, cf,
				ensureVariantMember(
					ctx, only(concreteParams).type, unwrapOptionType(ctx, cf.returnType))),
		(FunBody.VariantMethod x) {
			push(ctx.alloc, ctx.deferredVariantMethods, cf);
			return ConcreteFunBody(ConcreteFunBody.Deferred());
		},
		(FunBody.VarSet x) =>
			ConcreteFunBody(ConcreteFunBody.VarSet(getVar(ctx, x.var))));
	cf.overwriteBody(body_);
}

ConcreteExpr genCreateRecordFromParams(
	ref Alloc alloc,
	ConcreteType recordType,
	UriAndRange range,
	ConcreteLocal[] params,
) =>
	genCreateRecord(recordType, range, mapPointers(alloc, params, (ConcreteLocal* param) =>
		genLocalGet(range, param)));

ConcreteFunBody createUnionBody(ref Alloc alloc, ConcreteFun* cf, size_t memberIndex) =>
	isEmpty(cf.params)
		? ConcreteFunBody(genConstantUnionEmptyMemberType(alloc, cf.returnType, cf.range, memberIndex))
		: ConcreteFunBody(genCreateUnion(
			alloc, cf.returnType, cf.range, memberIndex, genLocalGet(cf.range, onlyPointer(cf.params))));

ConcreteExpr genConstantUnionEmptyMemberType(
	ref Alloc alloc,
	ConcreteType type,
	UriAndRange range,
	size_t memberIndex,
) =>
	genConstant(type, range, Constant(allocate(alloc, Constant.Union(memberIndex, constantZero()))));

ConcreteExpr concretizeFileImport(ref ConcretizeCtx ctx, ConcreteFun* cf, ref FunBody.FileImport import_) =>
	withConcretizeExprCtx(ctx, cf, (ref ConcretizeExprCtx exprCtx) {
		ConcreteExprKind exprKind = import_.content.match!ConcreteExprKind(
			(immutable ubyte[] x) =>
				ConcreteExprKind(constantOfBytes(ctx, cf.returnType, x)),
			(string x) =>
				genStringLiteralKind(ctx, cf.range, x),
			(ImportFileContent.Bogus) =>
				concretizeBogusKind(exprCtx.concretizeCtx, cf.range));
		return ConcreteExpr(cf.returnType, cf.range, exprKind);
	});

Constant constantOfBytes(ref ConcretizeCtx ctx, ConcreteType arrayType, in ubyte[] bytes) {
	//TODO:PERF creating a Constant per byte is expensive
	Constant[] elements = map!(Constant, const ubyte)(ctx.alloc, bytes, (ref const ubyte a) =>
		Constant(IntegralValue(a)));
	return getConstantArray(ctx.alloc, ctx.allConstants, mustBeByVal(arrayType), elements);
}

public ConcreteVar* getVar(ref ConcretizeCtx ctx, VarDecl* decl) =>
	getOrAdd!(immutable ConcreteVar*, immutable VarDecl*, getVarKey)(ctx.alloc, ctx.concreteVarLookup, decl, () =>
		allocate(ctx.alloc, ConcreteVar(decl, getConcreteType(ctx, decl.type, emptySmallArray!ConcreteType))));

ulong getAllFlagsValue(ConcreteStruct* a) =>
	getAllFlagsValue(a.source.as!(ConcreteStructSource.Inst).decl.body_.as!(StructBody.Flags));

TypeSize getBuiltinStructSize(BuiltinType kind, in VersionInfo version_) {
	final switch (kind) {
		case BuiltinType.void_:
			return TypeSize(0, 1);
		case BuiltinType.bool_:
		case BuiltinType.char8:
		case BuiltinType.int8:
		case BuiltinType.nat8:
			return TypeSize(1, 1);
		case BuiltinType.int16:
		case BuiltinType.nat16:
			return TypeSize(2, 2);
		case BuiltinType.char32:
		case BuiltinType.float32:
		case BuiltinType.int32:
		case BuiltinType.nat32:
			return TypeSize(4, 4);
		case BuiltinType.float64:
		case BuiltinType.funPointer:
		case BuiltinType.int64:
		case BuiltinType.nat64:
		case BuiltinType.pointerConst:
		case BuiltinType.pointerMut:
		case BuiltinType.symbol:
			return TypeSize(8, 8);
		case BuiltinType.jsAny:
			assert(false);
		case BuiltinType.array:
		case BuiltinType.mutArray:
		case BuiltinType.string_:
			return TypeSize(16, 8);
		case BuiltinType.lambda:
			return TypeSize(16, 8); // TODO: I think this is no longer used? -----------------------------------------------------------------------
		case BuiltinType.catchPoint:
			if (version_.isInterpreted)
				// Keep in sync with 'struct CatchPoint' in 'runBytecode.d'
				return TypeSize(0x18, 8);
			else
				final switch (version_.os) {
					case OS.linux:
						// Keep in sync with 'catch point size' comment in writeToC_boilerplate_posix.c
						return TypeSize(0x40, 8);
					case OS.web:
						// Always interpreted
						assert(false);
					case OS.windows:
						// Keep in sync with 'catch point size' comment in writeToC_boilerplate_msvc.c
						return TypeSize(0x100, 16);
				}			
	}
}
