module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArray, getConstantCString, getConstantSymbol;
import concretize.concretizeExpr : concretizeBogus, concretizeBogusKind, concretizeFunBody;
import concretize.generate : bodyForEnumOrFlagsMembers, concretizeAutoFun, getRecordFieldCall;
import frontend.storage : FileContentGetters;
import model.concreteModel :
	byVal,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteFunSource,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteMutability,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVar,
	EnumValues,
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
	emptySpecs,
	EnumFunction,
	EnumOrFlagsMember,
	Expr,
	FlagsFunction,
	FunBody,
	FunInst,
	ImportFileContent,
	ImportFileType,
	IntegralType,
	isTuple,
	Local,
	Module,
	paramsArray,
	Program,
	Purity,
	RecordField,
	Specs,
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
import util.col.array :
	arraysEqual,
	emptySmallArray,
	every,
	everyWithIndex,
	exists,
	fold,
	isEmpty,
	map,
	mapWithIndex,
	mapZip,
	maxBy,
	newArray,
	newSmallArray,
	only,
	small,
	SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildArray, Builder;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, moveToArray, MutHashTable;
import util.col.map : values;
import util.col.mutArr : filterUnordered, MutArr, mutArrIsEmpty, push;
import util.col.mutMap : getOrAdd, getOrAddAndDidAdd, mustAdd, mustDelete, MutMap, ValueAndDidAdd;
import util.hash : HashCode, Hasher;
import util.late : Late, lateGet, lazilySet;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOrDefault;
import util.sourceRange : UriAndRange;
import util.string : bytesOfString;
import util.symbol : Symbol, symbol;
import util.unicode : FileContent, unicodeDecodeAssertNoError;
import util.uri : Uri;
import util.util : enumConvert, max, roundUp, typeAs;
import versionInfo : VersionInfo;

alias TypeArgsScope = SmallArray!ConcreteType;

private immutable struct ConcreteStructKey {
	@safe @nogc pure nothrow:

	StructDecl* decl;
	SmallArray!ConcreteType typeArgs;

	bool opEquals(scope ref ConcreteStructKey b) scope =>
		decl == b.decl && arraysEqual!ConcreteType(typeArgs, b.typeArgs);

	HashCode hash() scope {
		Hasher hasher;
		hasher ~= decl;
		foreach (ConcreteType t; typeArgs)
			hasher ~= t.struct_;
		return hasher.finish();
	}
}

private ConcreteStructKey getStructKey(return in ConcreteStruct* a) {
	ConcreteStructSource.Inst inst = a.source.as!(ConcreteStructSource.Inst);
	return ConcreteStructKey(inst.inst.decl, inst.typeArgs);
}

private VarDecl* getVarKey(return in ConcreteVar* a) =>
	a.source;

ConcreteFunKey getFunKey(return in ConcreteFun* a) =>
	a.source.as!ConcreteFunKey;

ContainingFunInfo toContainingFunInfo(ConcreteFunKey a) =>
	ContainingFunInfo(a.decl.moduleUri, a.decl.specs, a.typeArgs, a.specImpls);

TypeArgsScope typeArgsScope(ref ConcreteFunKey a) =>
	typeArgsScope(toContainingFunInfo(a));

immutable struct ContainingFunInfo {
	Uri uri;
	Specs specs;
	SmallArray!ConcreteType typeArgs;
	SmallArray!(immutable ConcreteFun*) specImpls;
}

TypeArgsScope typeArgsScope(ContainingFunInfo a) =>
	TypeArgsScope(a.typeArgs);

private immutable struct ConcreteFunBodyInputs {
	// NOTE: for a lambda, these are for the *outermost* fun (the one with type args and spec impls).
	ContainingFunInfo containing;
	// Body of the current fun, not the outer one.
	FunBody body_;
}

private ConcreteType[] typeArgs(ref ConcreteFunBodyInputs a) =>
	a.containing.typeArgs;

TypeArgsScope typeArgsScope(ref ConcreteFunBodyInputs a) =>
	typeArgsScope(a.containing);

private immutable struct DeferredRecordBody {
	ConcreteStruct* struct_;
	bool packed;
	bool isSelfMutable;
	ConcreteField[] fields;
	FieldsType fieldsType;
}

private struct DeferredUnionBody {
	ConcreteStruct* struct_;
	immutable ConcreteType[] members;
}

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable VersionInfo versionInfo;
	CommonTypes* commonTypesPtr;
	immutable Program* programPtr;
	FileContentGetters fileContentGetters; // For 'assert' or 'forbid' messages and file imports
	Late!(ConcreteFun*) char8ArrayTrustAsString_;
	Late!(ConcreteFun*) equalNat64Function_;
	Late!(ConcreteFun*) lessNat64Function_;
	Late!(ConcreteFun*) newJsonFromPairsFunction_;
	Late!(ConcreteFun*) newVoidFutureFunction_;
	Late!(ConcreteFun*) andFunction_;
	AllConstantsBuilder allConstants;
	MutHashTable!(ConcreteStruct*, ConcreteStructKey, getStructKey) nonLambdaConcreteStructs;
	ArrayBuilder!(ConcreteStruct*) allConcreteStructs;
	MutHashTable!(immutable ConcreteVar*, immutable VarDecl*, getVarKey) concreteVarLookup;
	MutHashTable!(ConcreteFun*, ConcreteFunKey, getFunKey) nonLambdaConcreteFuns;
	MutArr!DeferredRecordBody deferredRecords;
	MutArr!DeferredUnionBody deferredUnions;
	ArrayBuilder!(ConcreteFun*) allConcreteFuns;

	// This will only have an entry while a ConcreteFun hasn't had it's body filled in yet.
	MutMap!(ConcreteFun*, ConcreteFunBodyInputs) concreteFunToBodyInputs;
	// Index in the MutArr!ConcreteLambdaImpl is the fun ID
	MutMap!(ConcreteStruct*, MutArr!ConcreteLambdaImpl) funStructToImpls;
	// TODO: do these eagerly
	Late!ConcreteType _bogusType;
	Late!ConcreteType _boolType;
	Late!ConcreteType _voidType;
	Late!ConcreteType _nat64Type;
	Late!ConcreteType _ctxType;
	Late!ConcreteType _stringType;
	Late!ConcreteType _symbolType;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref CommonTypes commonTypes() return scope const =>
		*commonTypesPtr;
	ConcreteFun* char8ArrayTrustAsString() return scope const =>
		lateGet(char8ArrayTrustAsString_);
	ConcreteFun* equalNat64Function() return scope const =>
		lateGet(equalNat64Function_);
	ConcreteFun* lessNat64Function() return scope const =>
		lateGet(lessNat64Function_);
	ConcreteFun* newJsonFromPairsFunction() return scope const =>
		lateGet(newJsonFromPairsFunction_);
	ConcreteFun* newVoidFutureFunction() return scope const =>
		lateGet(newVoidFutureFunction_);
	ConcreteFun* andFunction() return scope const =>
		lateGet(andFunction_);
	ref Program program() return scope const =>
		*programPtr;
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
			ConcreteStructBody(ConcreteStructBody.Record([])),
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

ConcreteType nat64Type(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._nat64Type, () =>
		getConcreteType_forStructInst(a, a.commonTypes.integrals.nat64, emptySmallArray!ConcreteType));

ConcreteType stringType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._stringType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.string_, emptySmallArray!ConcreteType));

ConcreteType symbolType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._symbolType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.symbol, emptySmallArray!ConcreteType));

ConcreteStruct* symbolArrayType(ref ConcretizeCtx a) =>
	mustBeByVal(getConcreteType_forStructInst(a, a.commonTypes.symbolArray, emptySmallArray!ConcreteType));

Constant constantCString(ref ConcretizeCtx a, string value) =>
	getConstantCString(a.alloc, a.allConstants, value);

Constant constantSymbol(ref ConcretizeCtx a, Symbol value) =>
	getConstantSymbol(a.alloc, a.allConstants, value);

ConcreteFun* getOrAddConcreteFunAndFillBody(ref ConcretizeCtx ctx, ConcreteFunKey key) {
	ConcreteFun* cf = getOrAddConcreteFunWithoutFillingBody(ctx, key);
	fillInConcreteFunBody(ctx, paramsArray(key.decl.params), cf);
	return cf;
}

ConcreteFun* getConcreteFunForLambdaAndFillBody(
	ref ConcretizeCtx ctx,
	ConcreteFun* containingConcreteFun,
	size_t index,
	ConcreteType returnType,
	Destructure modelParam,
	ConcreteLocal[] paramsIncludingClosure,
	ref ContainingFunInfo containing,
	ref Expr body_,
) {
	assert(!isBogus(returnType));
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Lambda(
			UriAndRange(containing.uri, body_.range),
			containingConcreteFun, index))),
		returnType,
		paramsIncludingClosure));
	ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(containing, FunBody(body_));
	mustAdd(ctx.alloc, ctx.concreteFunToBodyInputs, res, bodyInputs);
	fillInConcreteFunBody(ctx, [modelParam], res);
	addConcreteFun(ctx, res);
	return res;
}

ConcreteFun* getOrAddNonTemplateConcreteFunAndFillBody(ref ConcretizeCtx ctx, FunInst* inst) =>
	getOrAddConcreteFunAndFillBody(
		ctx, ConcreteFunKey(inst.decl, emptySmallArray!ConcreteType, emptySmallArray!(immutable ConcreteFun*)));

private ConcreteType getConcreteType_forStructInst(
	ref ConcretizeCtx ctx,
	StructInst* i,
	in TypeArgsScope typeArgsScope,
) {
	SmallArray!ConcreteType typeArgs = typesToConcreteTypes(ctx, i.typeArgs, typeArgsScope);
	ConcreteStructKey key = ConcreteStructKey(i.decl, typeArgs);
	ValueAndDidAdd!(ConcreteStruct*) res =
		getOrAddAndDidAdd!(ConcreteStruct*, ConcreteStructKey, getStructKey)(
			ctx.alloc, ctx.nonLambdaConcreteStructs, key, () {
				Purity purity = fold!(Purity, ConcreteType)(
					i.purityRange.bestCase, typeArgs, (Purity p, in ConcreteType ta) =>
						worsePurity(p, purity(ta)));
				ConcreteStruct.SpecialKind specialKind = i.decl == ctx.commonTypes.array
					? ConcreteStruct.SpecialKind.array
					: isTuple(ctx.commonTypes, i.decl)
					? ConcreteStruct.SpecialKind.tuple
					: ConcreteStruct.SpecialKind.none;
				ConcreteStruct* res = allocate(ctx.alloc, ConcreteStruct(
					purity,
					specialKind,
					ConcreteStructSource(ConcreteStructSource.Inst(i, key.typeArgs))));
				add(ctx.alloc, ctx.allConcreteStructs, res);
				return res;
			});
	if (res.didAdd)
		initializeConcreteStruct(ctx, typeArgs, *i, res.value, typeArgsScope);
	if (!res.value.defaultReferenceKindIsSet)
		// The only way 'defaultIsPointer' would not be set is if we are still computing the size of 's'.
		// In that case, it's a recursive record, so it should be by-ref.
		res.value.defaultReferenceKind = ReferenceKind.byRef;
	return ConcreteType(res.value.defaultReferenceKind, res.value);
}

ConcreteType getConcreteType(ref ConcretizeCtx ctx, Type t, in TypeArgsScope typeArgsScope) =>
	t.matchWithPointers!ConcreteType(
		(Type.Bogus) =>
			bogusType(ctx),
		(TypeParamIndex x) =>
			typeArgsScope[x.index],
		(StructInst* i) =>
			getConcreteType_forStructInst(ctx, i, typeArgsScope));

SmallArray!ConcreteType typesToConcreteTypes(ref ConcretizeCtx ctx, in Type[] types, in TypeArgsScope typeArgsScope) =>
	small!ConcreteType(map(ctx.alloc, types, (ref Type t) =>
		getConcreteType(ctx, t, typeArgsScope)));

ConcreteType concreteTypeFromClosure(
	ref ConcretizeCtx ctx,
	ConcreteField[] closureFields,
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
		setConcreteStructRecordSizeOrDefer(
			ctx, cs, false, closureFields, false, FieldsType.closure);
		add(ctx.alloc, ctx.allConcreteStructs, cs);
		// TODO: consider passing closure by value
		return ConcreteType(ReferenceKind.byRef, cs);
	}
}

private void setConcreteStructRecordSizeOrDefer(
	ref ConcretizeCtx ctx,
	ConcreteStruct* cs,
	bool packed,
	ConcreteField[] fields,
	bool isSelfMutable,
	FieldsType fieldsType,
) {
	DeferredRecordBody deferred = DeferredRecordBody(cs, packed, isSelfMutable, fields, fieldsType);
	if (canGetRecordSize(fields))
		setConcreteStructRecordSize(ctx.alloc, deferred);
	else
		push(ctx.alloc, ctx.deferredRecords, deferred);
}

private void setConcreteStructRecordSize(ref Alloc alloc, DeferredRecordBody a) {
	TypeSizeAndFieldOffsets size = recordSize(alloc, a.packed, a.fields);
	if (!a.struct_.defaultReferenceKindIsSet)
		a.struct_.defaultReferenceKind = getDefaultReferenceKindForFields(size.typeSize, a.isSelfMutable, a.fieldsType);
	a.struct_.typeSize = size.typeSize;
	a.struct_.fieldOffsets = size.fieldOffsets;
}

private:

ConcreteFun* getOrAddConcreteFunWithoutFillingBody(ref ConcretizeCtx ctx, ref ConcreteFunKey key) =>
	getOrAdd(ctx.alloc, ctx.nonLambdaConcreteFuns, key, () {
		ConcreteFun* res = getConcreteFunFromKey(ctx, key);
		addConcreteFun(ctx, res);
		return res;
	});

ConcreteFun* getConcreteFunFromKey(ref ConcretizeCtx ctx, ref ConcreteFunKey key) {
	TypeArgsScope typeScope = typeArgsScope(key);
	ConcreteType returnType = getConcreteType(ctx, key.decl.returnType, typeScope);
	ConcreteLocal[] params = concretizeFunctionParams(ctx, paramsArray(key.decl.params), typeScope);
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(ConcreteFunSource(key), returnType, params));
	ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(
		toContainingFunInfo(key),
		key.decl.body_);
	mustAdd(ctx.alloc, ctx.concreteFunToBodyInputs, res, bodyInputs);
	return res;
}

ConcreteLocal[] concretizeFunctionParams(ref ConcretizeCtx ctx, Destructure[] params, TypeArgsScope typeArgsScope) =>
	map(ctx.alloc, params, (ref Destructure x) => concretizeParamDestructure(ctx, x, typeArgsScope));

public ConcreteLocal[] concretizeLambdaParams(
	ref ConcretizeCtx ctx,
	ConcreteType closureType,
	Destructure param,
	TypeArgsScope typeArgsScope,
) =>
	newArray!ConcreteLocal(ctx.alloc, [
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

ConcreteFunBody bodyForAllTests(ref ConcretizeCtx ctx, ConcreteType returnType) {
	Test[] allTests = buildArray!Test(ctx.alloc, (scope ref Builder!Test res) {
		foreach (immutable Module* m; ctx.program.allModules)
			res ~= m.tests;
	});
	Constant arr = getConstantArray(
		ctx.alloc,
		ctx.allConstants,
		mustBeByVal(returnType),
		mapWithIndex!(Constant, Test)(ctx.alloc, allTests, (size_t testIndex, ref Test it) =>
			Constant(Constant.FunPointer(concreteFunForTest(ctx, it, testIndex)))));
	return ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(arr)));
}

ConcreteFun* concreteFunForTest(ref ConcretizeCtx ctx, ref Test test, size_t testIndex) {
	ConcreteType voidType = voidType(ctx);
	ConcreteType voidFutureType = ctx.newVoidFutureFunction.returnType;
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Test(test.range, testIndex))),
		voidFutureType,
		[]));
	ContainingFunInfo containing = ContainingFunInfo(
		test.moduleUri, emptySpecs, emptySmallArray!ConcreteType, emptySmallArray!(immutable ConcreteFun*));
	ConcreteType returnType = () {
		final switch (test.bodyType) {
			case Test.BodyType.void_:
				return voidType;
			case Test.bodyType.bogus:
			case Test.BodyType.voidFuture:
				return voidFutureType;
		}
	}();
	ConcreteExpr body_ = test.bodyType == Test.BodyType.bogus
		? concretizeBogus(ctx, returnType, test.range)
		: concretizeFunBody(ctx, containing, res, returnType, [], test.body_);
	ConcreteExpr body2 = () {
		final switch (test.bodyType) {
			case Test.BodyType.void_:
				return ConcreteExpr(voidFutureType, test.range, ConcreteExprKind(
					ConcreteExprKind.Call(ctx.newVoidFutureFunction, newArray(ctx.alloc, [body_]))));
			case Test.BodyType.bogus:
			case Test.BodyType.voidFuture:
				return body_;
		}
	}();
	res.body_ = ConcreteFunBody(body2);
	addConcreteFun(ctx, res);
	return res;
}

public ConcreteFun* concreteFunForWrapMain(ref ConcretizeCtx ctx, StructInst* modelStringList, FunInst* modelMain) {
	ConcreteType stringListType = getConcreteType_forStructInst(ctx, modelStringList, emptySmallArray!ConcreteType);
	ConcreteFun* innerMain = getOrAddNonTemplateConcreteFunAndFillBody(ctx, modelMain);
	/*
	This is like:
		wrapped-main nat^(_ string[])
			real-main
			0,
	*/
	ConcreteType nat64 = nat64Type(ctx);
	UriAndRange range = modelMain.decl.range;
	ConcreteExpr callMain = ConcreteExpr(voidType(ctx), range, ConcreteExprKind(ConcreteExprKind.Call(innerMain, [])));
	ConcreteExpr zero = ConcreteExpr(nat64, range, ConcreteExprKind(constantZero));
	ConcreteFun* newNat64Future = newNat64FutureFunction(ctx);
	ConcreteExpr callNewNatFuture = ConcreteExpr(newNat64Future.returnType, range, ConcreteExprKind(
		ConcreteExprKind.Call(newNat64Future, newArray(ctx.alloc, [zero]))));
	ConcreteExpr body_ = ConcreteExpr(newNat64Future.returnType, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.Seq(callMain, callNewNatFuture))));

	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.WrapMain(range))),
		getConcreteType(ctx, ctx.program.commonFuns.newNat64Future.returnType, emptySmallArray!ConcreteType),
		newArray(ctx.alloc, [
			ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Generated.args), stringListType),
		])));
	res.body_ = ConcreteFunBody(body_);
	addConcreteFun(ctx, res);
	return res;
}

ConcreteFun* newNat64FutureFunction(ref ConcretizeCtx ctx) =>
	getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newNat64Future.decl,
		//TODO:avoid alloc
		newSmallArray(ctx.alloc, [nat64Type(ctx)]),
		emptySmallArray!(immutable ConcreteFun*)));

bool canGetUnionSize(in ConcreteType[] members) =>
	every!(ConcreteType)(members, (in ConcreteType type) =>
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

bool canGetRecordSize(in ConcreteField[] fields) =>
	every!ConcreteField(fields, (in ConcreteField field) =>
		hasSizeOrPointerSizeBytes(field.type));

ConcreteStructInfo getConcreteStructInfoForFields(ConcreteField[] fields) =>
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
	ConcreteType[] typeArgs,
	in StructInst i,
	ConcreteStruct* res,
	in TypeArgsScope typeArgsScope,
) {
	i.decl.body_.match!void(
		(StructBody.Bogus) => assert(false),
		(BuiltinType x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(
				ConcreteStructBody(ConcreteStructBody.Builtin(x, typeArgs)),
				false);
			res.typeSize = getBuiltinStructSize(x);
		},
		(StructBody.Enum x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(
				ConcreteStructBody(getConcreteStructBodyForEnum(ctx.alloc, x)),
				false);
			res.typeSize = typeSizeForEnumOrFlags(x.storage);
		},
		(StructBody.Extern x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Extern()), false);
			res.typeSize = optOrDefault!TypeSize(x.size, () => TypeSize(0, 0));
		},
		(StructBody.Flags x) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			res.info = ConcreteStructInfo(
				ConcreteStructBody(getConcreteStructBodyForFlags(ctx.alloc, x)),
				false);
			res.typeSize = typeSizeForEnumOrFlags(x.storage);
		},
		(StructBody.Record r) {
			// don't set 'defaultReferenceKind' until the end, unless explicit
			if (has(r.flags.forcedByValOrRef))
				res.defaultReferenceKind = enumConvert!ReferenceKind(force(r.flags.forcedByValOrRef));

			ConcreteField[] fields = mapZip(
				ctx.alloc, r.fields, i.instantiatedTypes, (ref RecordField f, ref Type type) =>
					ConcreteField(
						f.name,
						has(f.mutability) ? ConcreteMutability.mutable : ConcreteMutability.const_,
						getConcreteType(ctx, type, typeArgsScope)));
			bool packed = r.flags.packed;
			ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			res.info = info;
			setConcreteStructRecordSizeOrDefer(ctx, res, packed, fields, info.isSelfMutable, FieldsType.record);
		},
		(StructBody.Union u) {
			res.defaultReferenceKind = ReferenceKind.byVal;
			ConcreteType[] members = mapZip(
				ctx.alloc, u.members, i.instantiatedTypes, (ref UnionMember x, ref Type type) =>
					getConcreteType(ctx, type, typeArgsScope));
			res.info = ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Union(members)), false);
			if (canGetUnionSize(members))
				res.typeSize = unionSize(members);
			else
				push(ctx.alloc, ctx.deferredUnions, DeferredUnionBody(res, members));
		});
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

ConcreteStructBody.Enum getConcreteStructBodyForEnum(ref Alloc alloc, in StructBody.Enum a) {
	bool simple = everyWithIndex!EnumOrFlagsMember(
		a.members, (size_t index, ref EnumOrFlagsMember member) =>
			member.value.value == index);
	return simple
		? ConcreteStructBody.Enum(a.storage, EnumValues(a.members.length))
		: ConcreteStructBody.Enum(
			a.storage,
			EnumValues(map(alloc, a.members, (ref EnumOrFlagsMember member) =>
				member.value)));
}

ConcreteStructBody.Flags getConcreteStructBodyForFlags(ref Alloc alloc, in StructBody.Flags a) =>
	ConcreteStructBody.Flags(
		a.storage,
		map!(immutable ulong, EnumOrFlagsMember)(alloc, a.members, (ref EnumOrFlagsMember member) =>
			member.value.asUnsigned()));

public void deferredFillRecordAndUnionBodies(ref ConcretizeCtx ctx) {
	if (!mutArrIsEmpty(ctx.deferredRecords) || !mutArrIsEmpty(ctx.deferredUnions)) {
		bool couldGetSomething = false;
		filterUnordered!DeferredRecordBody(ctx.deferredRecords, (ref DeferredRecordBody deferred) {
			bool canGet = canGetRecordSize(deferred.fields);
			if (canGet) {
				setConcreteStructRecordSize(ctx.alloc, deferred);
				couldGetSomething = true;
			}
			return !canGet;
		});
		filterUnordered!DeferredUnionBody(ctx.deferredUnions, (ref DeferredUnionBody deferred) {
			bool canGet = canGetUnionSize(deferred.members);
			if (canGet) {
				deferred.struct_.typeSize = unionSize(deferred.members);
				couldGetSomething = true;
			}
			return !canGet;
		});
		assert(couldGetSomething);
		deferredFillRecordAndUnionBodies(ctx);
	}
}

void fillInConcreteFunBody(ref ConcretizeCtx ctx, in Destructure[] params, ConcreteFun* cf) {
	// TODO: just assert it's not already set?
	if (!cf.bodyIsSet) {
		// set to arbitrary temporarily
		cf.body_ = ConcreteFunBody(ConcreteFunBody.CreateRecord());
		ConcreteFunBodyInputs inputs = mustDelete(ctx.concreteFunToBodyInputs, cf);
		ConcreteFunBody body_ = inputs.body_.match!ConcreteFunBody(
			(FunBody.Bogus) =>
				ConcreteFunBody(concretizeBogus(ctx, cf.returnType, cf.range)),
			(AutoFun x) =>
				ConcreteFunBody(concretizeAutoFun(ctx, cf, x)),
			(BuiltinFun x) =>
				x.isA!(BuiltinFun.AllTests)
					? bodyForAllTests(ctx, cf.returnType)
					: ConcreteFunBody(ConcreteFunBody.Builtin(x, typeArgs(inputs))),
			(FunBody.CreateEnumOrFlags x) =>
				ConcreteFunBody(Constant(Constant.Integral(x.member.value.value))),
			(FunBody.CreateExtern) =>
				ConcreteFunBody(constantZero),
			(FunBody.CreateRecord) =>
				ConcreteFunBody(ConcreteFunBody.CreateRecord()),
			(FunBody.CreateUnion x) =>
				ConcreteFunBody(ConcreteFunBody.CreateUnion(x.member.memberIndex)),
			(EnumFunction it) {
				final switch (it) {
					case EnumFunction.equal:
					case EnumFunction.intersect:
					case EnumFunction.toIntegral:
					case EnumFunction.union_:
						return ConcreteFunBody(it);
					case EnumFunction.members:
						return bodyForEnumOrFlagsMembers(ctx, cf.returnType);
				}
			},
			(Expr x) =>
				ConcreteFunBody(concretizeFunBody(ctx, inputs.containing, cf, cf.returnType, params, x)),
			(FunBody.Extern x) =>
				ConcreteFunBody(ConcreteFunBody.Extern(x.libraryName)),
			(FunBody.FileImport x) =>
				ConcreteFunBody(concretizeFileImport(ctx, cf, x)),
			(FlagsFunction it) =>
				ConcreteFunBody(ConcreteFunBody.FlagsFn(
					getAllValue(mustBeByVal(cf.returnType).body_.as!(ConcreteStructBody.Flags)),
					it)),
			(FunBody.RecordFieldCall x) =>
				ConcreteFunBody(getRecordFieldCall(ctx, x.funKind, cf.paramsIncludingClosure[0].type, x.fieldIndex)),
			(FunBody.RecordFieldGet it) =>
				ConcreteFunBody(ConcreteFunBody.RecordFieldGet(it.fieldIndex)),
			(FunBody.RecordFieldPointer x) =>
				ConcreteFunBody(ConcreteFunBody.RecordFieldPointer(x.fieldIndex)),
			(FunBody.RecordFieldSet it) =>
				ConcreteFunBody(ConcreteFunBody.RecordFieldSet(it.fieldIndex)),
			(FunBody.VarGet x) =>
				ConcreteFunBody(ConcreteFunBody.VarGet(getVar(ctx, x.var))),
			(FunBody.VarSet x) =>
				ConcreteFunBody(ConcreteFunBody.VarSet(getVar(ctx, x.var))));
		cf.overwriteBody(body_);
	}
}

ConcreteExpr concretizeFileImport(ref ConcretizeCtx ctx, ConcreteFun* cf, ref FunBody.FileImport import_) {
	ConcreteExprKind exprKind = import_.content.match!ConcreteExprKind(
		(immutable ubyte[] x) =>
			ConcreteExprKind(constantOfBytes(ctx, cf.returnType, x)),
		(string x) =>
			stringLiteralConcreteExprKind(ctx, cf.range, x),
		(ImportFileContent.Bogus) =>
			concretizeBogusKind(ctx, cf.range));
	return ConcreteExpr(cf.returnType, cf.range, exprKind);
}

Constant constantOfBytes(ref ConcretizeCtx ctx, ConcreteType arrayType, in ubyte[] bytes) {
	//TODO:PERF creating a Constant per byte is expensive
	Constant[] elements = map!(Constant, const ubyte)(ctx.alloc, bytes, (ref const ubyte a) =>
		Constant(Constant.Integral(a)));
	return getConstantArray(ctx.alloc, ctx.allConstants, mustBeByVal(arrayType), elements);
}

public ConcreteExpr stringLiteralConcreteExpr(ref ConcretizeCtx ctx, UriAndRange range, in string value) =>
	ConcreteExpr(stringType(ctx), range, stringLiteralConcreteExprKind(ctx, range, value));

ConcreteExprKind stringLiteralConcreteExprKind(ref ConcretizeCtx ctx, UriAndRange range, in string value) =>
	ConcreteExprKind(ConcreteExprKind.Call(ctx.char8ArrayTrustAsString, newArray(ctx.alloc, [
		char8ArrayExpr(ctx, only(ctx.char8ArrayTrustAsString.paramsIncludingClosure).type, range, value)])));

ConcreteExpr char8ArrayExpr(ref ConcretizeCtx ctx, ConcreteType type, in UriAndRange range, in string value) =>
	ConcreteExpr(type, range, ConcreteExprKind(constantOfBytes(ctx, type, bytesOfString(value))));

ConcreteExpr char32ArrayExpr(ref ConcretizeCtx ctx, ConcreteType type, in UriAndRange range, in string value) =>
	ConcreteExpr(type, range, ConcreteExprKind(char32ArrayConstant(ctx, type, value)));
private Constant char32ArrayConstant(ref ConcretizeCtx ctx, ConcreteType type, in string value) =>
	getConstantArray(
		ctx.alloc, ctx.allConstants, mustBeByVal(type),
		buildArray!Constant(ctx.alloc, (scope ref Builder!Constant out_) {
			unicodeDecodeAssertNoError(value, (dchar x) {
				out_ ~= Constant(Constant.Integral(x));
			});
		}));

ConcreteVar* getVar(ref ConcretizeCtx ctx, VarDecl* decl) =>
	getOrAdd!(immutable ConcreteVar*, immutable VarDecl*, getVarKey)(ctx.alloc, ctx.concreteVarLookup, decl, () =>
		allocate(ctx.alloc, ConcreteVar(decl, getConcreteType(ctx, decl.type, emptySmallArray!ConcreteType))));

ulong getAllValue(ConcreteStructBody.Flags flags) =>
	fold!(ulong, ulong)(0, flags.values, (ulong a, in ulong b) =>
		a | b);

public ConcreteType arrayElementType(ConcreteType arrayType) =>
	only(mustBeByVal(arrayType).source.as!(ConcreteStructSource.Inst).typeArgs);

TypeSize getBuiltinStructSize(BuiltinType kind) {
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
			return TypeSize(8, 8);
		case BuiltinType.lambda:
			return TypeSize(16, 8);
	}
}
