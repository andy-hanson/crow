module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArr, getConstantCStr, getConstantSym;
import concretize.concretizeExpr : concretizeBogus, concretizeBogusKind, concretizeFunBody;
import concretize.safeValue : bodyForSafeValue;
import frontend.storage : asBytes, FileContent, ReadFileResult;
import model.concreteModel :
	body_,
	BuiltinStructKind,
	byVal,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	concreteFunRange,
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
	isSelfMutable,
	mustBeByVal,
	purity,
	ReferenceKind,
	setBody,
	sizeOrPointerSizeBytes,
	TypeSize;
import model.constant : Constant, constantZero;
import model.diag : ReadFileDiag;
import model.model :
	body_,
	CommonTypes,
	decl,
	Destructure,
	EnumBackingType,
	EnumFunction,
	Expr,
	FieldMutability,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunInst,
	ImportFileType,
	isArray,
	isTuple,
	Local,
	Module,
	moduleUri,
	name,
	paramsArray,
	Program,
	Purity,
	range,
	RecordField,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	VarDecl,
	worsePurity;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only, only2, sizeEq;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : arrEqual, arrLiteral, arrMax, every, everyWithIndex, exists, fold, map, mapWithIndex, mapZip;
import util.col.hashTable : getOrAdd, getOrAddAndDidAdd, HashTable, moveToArray;
import util.col.map : Map, mustGetAt, values;
import util.col.mutArr : filterUnordered, MutArr, mutArrIsEmpty, push;
import util.col.mutMap : getOrAdd, getOrAddAndDidAdd, mustAddToMutMap, mustDelete, MutMap, ValueAndDidAdd;
import util.col.str : SafeCStr;
import util.hash : HashCode, Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite, lazilySet;
import util.memory : allocate;
import util.opt : force, has, none;
import util.ptr : castMutable;
import util.sourceRange : UriAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.uri : AllUris, Uri;
import util.util : max, roundUp, todo, unreachable;
import versionInfo : VersionInfo;

immutable struct TypeArgsScope {
	@safe @nogc pure nothrow:

	TypeParam[] typeParams;
	ConcreteType[] typeArgs;

	this(TypeParam[] tp, ConcreteType[] ta) {
		typeParams = tp;
		typeArgs = ta;
		assert(sizeEq(typeParams, typeArgs));
	}

	static TypeArgsScope empty() =>
		TypeArgsScope([], []);
}

private immutable struct ConcreteStructKey {
	@safe @nogc pure nothrow:

	StructDecl* decl;
	ConcreteType[] typeArgs;

	bool opEquals(scope ref ConcreteStructKey b) scope =>
		decl == b.decl && arrEqual!ConcreteType(typeArgs, b.typeArgs);

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
	return ConcreteStructKey(decl(*inst.inst), inst.typeArgs);
}

private VarDecl* getVarKey(return in ConcreteVar* a) =>
	a.source;

immutable struct ConcreteFunKey {
	@safe @nogc pure nothrow:

	// We only need a FunDecl since we have the typeArgs and specImpls.
	// FunInst is for debug info
	FunInst* inst;
	ConcreteType[] typeArgs;
	ConcreteFun*[] specImpls;

	bool opEquals(scope ConcreteFunKey b) scope =>
		// Compare decls, not insts.
		// Two different FunInsts may concretize to the same thing.
		// (e.g. f<?t> and f<bool> if ?t = bool)
		decl(*inst) == decl(*b.inst) &&
		arrEqual!ConcreteType(typeArgs, b.typeArgs) &&
		arrEqual!(ConcreteFun*)(specImpls, b.specImpls);

	HashCode hash() scope {
		Hasher hasher;
		hasher ~= decl(*inst);
		foreach (ConcreteType t; typeArgs)
			// Ignore 'reference', functions are unlikely to overload by that
			hasher ~= t.struct_;
		foreach (ConcreteFun* p; specImpls)
			hasher ~= p;
		return hasher.finish();
	}
}

private ContainingFunInfo toContainingFunInfo(ConcreteFunKey a) =>
	ContainingFunInfo(moduleUri(*decl(*a.inst)), decl(*a.inst).typeParams, a.typeArgs, a.specImpls);

TypeArgsScope typeArgsScope(ref ConcreteFunKey a) =>
	typeArgsScope(toContainingFunInfo(a));

immutable struct ContainingFunInfo {
	Uri uri;
	TypeParam[] typeParams; // TODO: get this from cf?
	ConcreteType[] typeArgs;
	ConcreteFun*[] specImpls;
}

TypeArgsScope typeArgsScope(ContainingFunInfo a) =>
	TypeArgsScope(a.typeParams, a.typeArgs);

private immutable struct ConcreteFunBodyInputs {
	// NOTE: for a lambda, these are for the *outermost* fun (the one with type args and spec impls).
	ContainingFunInfo containing;
	// Body of the current fun, not the outer one.
	FunBody body_;
}

ConcreteType[] typeArgs(ref ConcreteFunBodyInputs a) =>
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
	const AllSymbols* allSymbolsPtr;
	const AllUris* allUrisPtr;
	CommonTypes* commonTypesPtr;
	immutable Program* programPtr;
	Map!(Uri, ReadFileResult) fileContents;
	Late!(ConcreteFun*) curExclusionFun_;
	Late!(ConcreteFun*) char8ArrayAsString_;
	AllConstantsBuilder allConstants;
	HashTable!(ConcreteStruct*, ConcreteStructKey, getStructKey) nonLambdaConcreteStructs;
	ArrBuilder!(ConcreteStruct*) allConcreteStructs;
	HashTable!(immutable ConcreteVar*, immutable VarDecl*, getVarKey) concreteVarLookup;
	MutMap!(ConcreteFunKey, ConcreteFun*) nonLambdaConcreteFuns;
	MutArr!DeferredRecordBody deferredRecords;
	MutArr!DeferredUnionBody deferredUnions;
	ArrBuilder!(ConcreteFun*) allConcreteFuns;

	// This will only have an entry while a ConcreteFun hasn't had it's body filled in yet.
	MutMap!(ConcreteFun*, ConcreteFunBodyInputs) concreteFunToBodyInputs;
	// Index in the MutArr!ConcreteLambdaImpl is the fun ID
	MutMap!(ConcreteStruct*, MutArr!ConcreteLambdaImpl) funStructToImpls;
	// TODO: do these eagerly
	Late!ConcreteType _bogusType;
	Late!ConcreteType _boolType;
	Late!ConcreteType _voidType;
	Late!ConcreteType nat64Type;
	Late!ConcreteType _ctxType;
	Late!ConcreteType _cStrType;

	ref Alloc alloc() return scope =>
		*allocPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	ref const(AllUris) allUris() return scope const =>
		*allUrisPtr;
	ref CommonTypes commonTypes() return scope const =>
		*commonTypesPtr;
	ConcreteFun* curExclusionFun() return scope const =>
		lateGet(curExclusionFun_);
	ConcreteFun* char8ArrayAsString() return scope const =>
		lateGet(char8ArrayAsString_);
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
		lateSet(res.info_, ConcreteStructInfo(
			ConcreteStructBody(ConcreteStructBody.Record([])),
			false));
		lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
		lateSet(res.typeSize_, TypeSize(0, 1));
		lateSet(res.fieldOffsets_, []);
		return ConcreteType(ReferenceKind.byVal, res);
	});

ConcreteType boolType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._boolType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.bool_, TypeArgsScope.empty));

ConcreteType voidType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._voidType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.void_, TypeArgsScope.empty));

ConcreteType cStrType(ref ConcretizeCtx a) =>
	lazilySet!ConcreteType(a._cStrType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.cString, TypeArgsScope.empty));

Constant constantCStr(ref ConcretizeCtx a, SafeCStr value) =>
	getConstantCStr(a.alloc, a.allConstants, value);

Constant constantSym(ref ConcretizeCtx a, Sym value) =>
	getConstantSym(a.alloc, a.allConstants, a.allSymbols, value);

ConcreteFun* getOrAddConcreteFunAndFillBody(ref ConcretizeCtx ctx, ConcreteFunKey key) {
	ConcreteFun* cf = getOrAddConcreteFunWithoutFillingBody(ctx, key);
	fillInConcreteFunBody(ctx, paramsArray(decl(*key.inst).params), cf);
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
	ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(containing, FunBody(FunBody.ExpressionBody(body_)));
	mustAddToMutMap(ctx.alloc, ctx.concreteFunToBodyInputs, res, bodyInputs);
	fillInConcreteFunBody(ctx, [modelParam], res);
	addConcreteFun(ctx, res);
	return res;
}

ConcreteFun* getOrAddNonTemplateConcreteFunAndFillBody(ref ConcretizeCtx ctx, FunInst* decl) =>
	getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(decl, [], []));

private ConcreteType getConcreteType_forStructInst(
	ref ConcretizeCtx ctx,
	StructInst* i,
	in TypeArgsScope typeArgsScope,
) {
	ConcreteType[] typeArgs = typesToConcreteTypes(ctx, typeArgs(*i), typeArgsScope);
	ConcreteStructKey key = ConcreteStructKey(decl(*i), typeArgs);
	ValueAndDidAdd!(ConcreteStruct*) res =
		getOrAddAndDidAdd!(ConcreteStruct*, ConcreteStructKey, getStructKey)(
			ctx.alloc, ctx.nonLambdaConcreteStructs, key, () {
				Purity purity = fold!(Purity, ConcreteType)(
					i.purityRange.bestCase, typeArgs, (Purity p, in ConcreteType ta) =>
						worsePurity(p, purity(ta)));
				ConcreteStruct.SpecialKind specialKind = isArray(ctx.commonTypes, *i)
					? ConcreteStruct.SpecialKind.array
					: isTuple(ctx.commonTypes, *i)
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
		initializeConcreteStruct(ctx, typeArgs, *i, castMutable(res.value), typeArgsScope);
	if (!lateIsSet(res.value.defaultReferenceKind_))
		// The only way 'defaultIsPointer' would not be set is if we are still computing the size of 's'.
		// In that case, it's a recursive record, so it should be by-ref.
		lateSet(castMutable(res.value).defaultReferenceKind_, ReferenceKind.byRef);
	return ConcreteType(lateGet(res.value.defaultReferenceKind_), res.value);
}

ConcreteType getConcreteType(ref ConcretizeCtx ctx, in Type t, in TypeArgsScope typeArgsScope) =>
	t.matchWithPointers!ConcreteType(
		(Type.Bogus) =>
			bogusType(ctx),
		(TypeParam* p) {
			// Handle calledConcreteFun first
			assert(p == &typeArgsScope.typeParams[p.index]);
			return typeArgsScope.typeArgs[p.index];
		},
		(StructInst* i) =>
			getConcreteType_forStructInst(ctx, i, typeArgsScope));

ConcreteType[] typesToConcreteTypes(ref ConcretizeCtx ctx, in Type[] types, in TypeArgsScope typeArgsScope) =>
	map(ctx.alloc, types, (ref Type t) =>
		getConcreteType(ctx, t, typeArgsScope));

ConcreteType concreteTypeFromClosure(
	ref ConcretizeCtx ctx,
	ConcreteField[] closureFields,
	ConcreteStructSource source,
) {
	if (empty(closureFields))
		return voidType(ctx);
	else {
		Purity purity = fold!(Purity, ConcreteField)(Purity.data, closureFields, (Purity p, in ConcreteField f) {
			// TODO: lambda fields are never mutable, use a different type?
			assert(f.mutability == ConcreteMutability.const_);
			return worsePurity(p, purity(f.type));
		});
		ConcreteStruct* cs = allocate(ctx.alloc, ConcreteStruct(purity, ConcreteStruct.SpecialKind.none, source));
		lateSet(cs.info_, getConcreteStructInfoForFields(closureFields));
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
	if (!lateIsSet(a.struct_.defaultReferenceKind_))
		lateSet(
			a.struct_.defaultReferenceKind_,
			getDefaultReferenceKindForFields(size.typeSize, a.isSelfMutable, a.fieldsType));
	lateSet(a.struct_.typeSize_, size.typeSize);
	lateSet(a.struct_.fieldOffsets_, size.fieldOffsets);
}

private:

ConcreteFun* getOrAddConcreteFunWithoutFillingBody(ref ConcretizeCtx ctx, ref ConcreteFunKey key) =>
	getOrAdd!(ConcreteFunKey, ConcreteFun*)(ctx.alloc, ctx.nonLambdaConcreteFuns, key, () {
		ConcreteFun* res = getConcreteFunFromKey(ctx, key);
		addConcreteFun(ctx, res);
		return res;
	});

ConcreteFun* getConcreteFunFromKey(ref ConcretizeCtx ctx, ref ConcreteFunKey key) {
	FunDecl* decl = decl(*key.inst);
	TypeArgsScope typeScope = typeArgsScope(key);
	ConcreteType returnType = getConcreteType(ctx, decl.returnType, typeScope);
	ConcreteLocal[] params = concretizeFunctionParams(ctx, paramsArray(decl.params), typeScope);
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(ConcreteFunSource(key.inst), returnType, params));
	ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(
		toContainingFunInfo(key),
		decl.body_);
	mustAddToMutMap(ctx.alloc, ctx.concreteFunToBodyInputs, res, bodyInputs);
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
	arrLiteral!ConcreteLocal(ctx.alloc, [
		ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Closure()), closureType),
		concretizeParamDestructure(ctx, param, typeArgsScope),
	]);

ConcreteLocal concretizeParamDestructure(ref ConcretizeCtx ctx, ref Destructure x, TypeArgsScope typeArgsScope) =>
	ConcreteLocal(
		x.matchWithPointers!ConcreteLocalSource(
			(Destructure.Ignore*) =>
				ConcreteLocalSource(ConcreteLocalSource.Generated(sym!"ignore")),
			(Local* x) =>
				ConcreteLocalSource(x),
			(Destructure.Split*) =>
				ConcreteLocalSource(ConcreteLocalSource.Generated(sym!"destruct"))),
		getConcreteType(ctx, x.type, typeArgsScope));

void addConcreteFun(ref ConcretizeCtx ctx, ConcreteFun* fun) {
	add(ctx.alloc, ctx.allConcreteFuns, fun);
}

ConcreteFun* concreteFunForTest(ref ConcretizeCtx ctx, ref Test test, size_t testIndex) {
	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.Test(range(test), testIndex))),
		voidType(ctx),
		[]));
	ContainingFunInfo containing = ContainingFunInfo(test.moduleUri, [], [], []);
	ConcreteExpr body_ = concretizeFunBody(ctx, containing, res, [], test.body_);
	lateSet(res._body_, ConcreteFunBody(body_));
	addConcreteFun(ctx, res);
	return res;
}

public ConcreteFun* concreteFunForWrapMain(ref ConcretizeCtx ctx, StructInst* modelStringList, FunInst* modelMain) {
	ConcreteType stringListType = getConcreteType_forStructInst(ctx, modelStringList, TypeArgsScope.empty);
	ConcreteFun* innerMain = getOrAddNonTemplateConcreteFunAndFillBody(ctx, modelMain);
	/*
	This is like:
		wrapped-main nat^(_ string[])
			real-main
			0,
	*/
	ConcreteType nat64Type = getConcreteType_forStructInst(ctx, ctx.commonTypes.integrals.nat64, TypeArgsScope.empty);
	UriAndRange range = range(*decl(*modelMain));
	ConcreteExpr callMain = ConcreteExpr(voidType(ctx), range, ConcreteExprKind(ConcreteExprKind.Call(innerMain, [])));
	ConcreteExpr zero = ConcreteExpr(nat64Type, range, ConcreteExprKind(constantZero));
	ConcreteFun* newNat64Future = getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.newNat64Future,
		//TODO:avoid alloc
		arrLiteral(ctx.alloc, [nat64Type]),
		[]));
	ConcreteExpr callNewNatFuture = ConcreteExpr(newNat64Future.returnType, range, ConcreteExprKind(
		ConcreteExprKind.Call(newNat64Future, arrLiteral(ctx.alloc, [zero]))));
	ConcreteExpr body_ = ConcreteExpr(newNat64Future.returnType, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.Seq(callMain, callNewNatFuture))));

	ConcreteFun* res = allocate(ctx.alloc, ConcreteFun(
		ConcreteFunSource(allocate(ctx.alloc, ConcreteFunSource.WrapMain(range))),
		getConcreteType(ctx, ctx.program.commonFuns.newNat64Future.returnType, TypeArgsScope.empty),
		arrLiteral(ctx.alloc, [
			ConcreteLocal(ConcreteLocalSource(ConcreteLocalSource.Generated(sym!"args")), stringListType),
		])));
	setBody(*res, ConcreteFunBody(body_));
	addConcreteFun(ctx, res);
	return res;
}

bool canGetUnionSize(in ConcreteType[] members) =>
	every!(ConcreteType)(members, (in ConcreteType type) =>
		hasSizeOrPointerSizeBytes(type));

TypeSize unionSize(in ConcreteType[] members) {
	size_t unionAlign = 8;
	size_t maxMember = arrMax!(size_t, ConcreteType)(0, members, (in ConcreteType x) =>
		sizeOrPointerSizeBytes(x).sizeBytes);
	size_t sizeBytes = roundUp(8 + maxMember, unionAlign);
	return TypeSize(sizeBytes, unionAlign);
}

ReferenceKind getDefaultReferenceKindForFields(TypeSize typeSize, bool isSelfMutable, FieldsType type) {
	size_t maxSize = () {
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
	size_t[] fieldOffsets;
}

TypeSizeAndFieldOffsets recordSize(ref Alloc alloc, bool packed, in ConcreteField[] fields) {
	size_t maxFieldSize = 1;
	size_t maxFieldAlignment = 1;
	size_t offsetBytes = 0;
	immutable size_t[] fieldOffsets = map!(size_t, ConcreteField)(alloc, fields, (ref ConcreteField field) {
		TypeSize fieldSize = sizeOrPointerSizeBytes(field.type);
		maxFieldSize = max(maxFieldSize, fieldSize.sizeBytes);
		if (!packed) {
			if (fieldSize.alignmentBytes != 0) {
				maxFieldAlignment = max(maxFieldAlignment, fieldSize.alignmentBytes);
				offsetBytes = roundUp(offsetBytes, fieldSize.alignmentBytes);
			}
		}
		size_t fieldOffset = offsetBytes;
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
	body_(*decl(i)).match!void(
		(StructBody.Bogus) => unreachable!void,
		(StructBody.Builtin) {
			BuiltinStructKind kind = getBuiltinStructKind(i.decl.name);
			lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.info_, ConcreteStructInfo(
				ConcreteStructBody(ConcreteStructBody.Builtin(kind, typeArgs)),
				false));
			lateSet(res.typeSize_, getBuiltinStructSize(kind));
		},
		(StructBody.Enum it) {
			lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.info_, ConcreteStructInfo(
				ConcreteStructBody(getConcreteStructBodyForEnum(ctx.alloc, it)),
				false));
			lateSet(res.typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(StructBody.Extern it) {
			lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.info_, ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Extern()), false));
			lateSet(res.typeSize_, has(it.size) ? force(it.size) : TypeSize(0, 0));
		},
		(StructBody.Flags it) {
			lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.info_, ConcreteStructInfo(
				ConcreteStructBody(getConcreteStructBodyForFlags(ctx.alloc, it)),
				false));
			lateSet(res.typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(StructBody.Record r) {
			// don't set 'defaultReferenceKind' until the end, unless explicit
			final switch (r.flags.forcedByValOrRef) {
				case ForcedByValOrRefOrNone.none:
					break;
				case ForcedByValOrRefOrNone.byVal:
					lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
					break;
				case ForcedByValOrRefOrNone.byRef:
					lateSet(res.defaultReferenceKind_, ReferenceKind.byRef);
					break;
			}

			ConcreteField[] fields = mapZip(
				ctx.alloc, r.fields, i.instantiatedTypes, (ref RecordField f, ref Type type) =>
					ConcreteField(
						f.name,
						toConcreteMutability(f.mutability),
						getConcreteType(ctx, type, typeArgsScope)));
			bool packed = r.flags.packed;
			ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			lateSet(res.info_, info);
			setConcreteStructRecordSizeOrDefer(ctx, res, packed, fields, info.isSelfMutable, FieldsType.record);
		},
		(StructBody.Union u) {
			lateSet(res.defaultReferenceKind_, ReferenceKind.byVal);
			ConcreteType[] members = mapZip(
				ctx.alloc, u.members, i.instantiatedTypes, (ref UnionMember x, ref Type type) =>
					getConcreteType(ctx, type, typeArgsScope));
			lateSet(res.info_, ConcreteStructInfo(ConcreteStructBody(ConcreteStructBody.Union(members)), false));
			if (canGetUnionSize(members))
				lateSet(res.typeSize_, unionSize(members));
			else
				push(ctx.alloc, ctx.deferredUnions, DeferredUnionBody(res, members));
		});
}

ConcreteMutability toConcreteMutability(FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return ConcreteMutability.const_;
		case FieldMutability.private_:
			return ConcreteMutability.mutable;
		case FieldMutability.public_:
			return ConcreteMutability.mutable;
	}
}

TypeSize typeSizeForEnumOrFlags(EnumBackingType a) {
	size_t size = sizeForEnumOrFlags(a);
	return TypeSize(size, size);
}
size_t sizeForEnumOrFlags(EnumBackingType a) {
	final switch (a) {
		case EnumBackingType.int8:
		case EnumBackingType.nat8:
			return 1;
		case EnumBackingType.int16:
		case EnumBackingType.nat16:
			return 2;
		case EnumBackingType.int32:
		case EnumBackingType.nat32:
			return 4;
		case EnumBackingType.int64:
		case EnumBackingType.nat64:
			return 8;
	}
}

ConcreteStructBody.Enum getConcreteStructBodyForEnum(ref Alloc alloc, in StructBody.Enum a) {
	bool simple = everyWithIndex!(StructBody.Enum.Member)(a.members, (size_t index, in StructBody.Enum.Member member) =>
		member.value.value == index);
	return simple
		? ConcreteStructBody.Enum(a.backingType, EnumValues(a.members.length))
		: ConcreteStructBody.Enum(
			a.backingType,
			EnumValues(map(alloc, a.members, (ref StructBody.Enum.Member member) =>
				member.value)));
}

ConcreteStructBody.Flags getConcreteStructBodyForFlags(ref Alloc alloc, in StructBody.Flags a) =>
	ConcreteStructBody.Flags(
		a.backingType,
		map!(ulong, StructBody.Enum.Member)(alloc, a.members, (ref StructBody.Enum.Member member) =>
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
				lateSet(deferred.struct_.typeSize_, unionSize(deferred.members));
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
	if (!lateIsSet(cf._body_)) {
		// set to arbitrary temporarily
		setBody(*cf, ConcreteFunBody(ConcreteFunBody.Builtin([])));
		ConcreteFunBodyInputs inputs = mustDelete(ctx.concreteFunToBodyInputs, cf);
		ConcreteFunBody body_ = inputs.body_.match!ConcreteFunBody(
			(FunBody.Bogus) =>
				ConcreteFunBody(concretizeBogus(ctx, cf.returnType, concreteFunRange(*cf))),
			(FunBody.Builtin) {
				FunInst* inst = cf.source.as!(FunInst*);
				switch (inst.name.value) {
					case sym!"all-tests".value:
						return bodyForAllTests(ctx, cf.returnType);
					case sym!"safe-value".value:
						return bodyForSafeValue(ctx, cf, concreteFunRange(*cf), cf.returnType);
					default:
						return ConcreteFunBody(ConcreteFunBody.Builtin(typeArgs(inputs)));
				}
			},
			(FunBody.CreateEnum x) =>
				ConcreteFunBody(Constant(Constant.Integral(x.member.value.value))),
			(FunBody.CreateExtern) =>
				ConcreteFunBody(constantZero),
			(FunBody.CreateRecord) =>
				ConcreteFunBody(ConcreteFunBody.CreateRecord()),
			(FunBody.CreateUnion it) =>
				ConcreteFunBody(ConcreteFunBody.CreateUnion(it.memberIndex)),
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
			(FunBody.Extern x) =>
				ConcreteFunBody(ConcreteFunBody.Extern(x.libraryName)),
			(FunBody.ExpressionBody e) =>
				ConcreteFunBody(concretizeFunBody(ctx, inputs.containing, cf, params, e.expr)),
			(FunBody.FileImport x) =>
				ConcreteFunBody(concretizeFileImport(ctx, cf, x)),
			(FlagsFunction it) =>
				ConcreteFunBody(ConcreteFunBody.FlagsFn(
					getAllValue(body_(*mustBeByVal(cf.returnType)).as!(ConcreteStructBody.Flags)),
					it)),
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
		lateSetOverwrite(cf._body_, body_);
	}
}

ConcreteExpr concretizeFileImport(ref ConcretizeCtx ctx, ConcreteFun* cf, in FunBody.FileImport import_) {
	ConcreteType type = cf.returnType;
	UriAndRange range = concreteFunRange(*cf);
	ConcreteExprKind exprKind = mustGetAt(ctx.fileContents, import_.uri).match!ConcreteExprKind(
		(FileContent content) {
			//TODO:PERF creating a Constant per byte is expensive
			Constant[] bytes = map(ctx.alloc, asBytes(content), (ref immutable ubyte a) =>
				Constant(Constant.Integral(a)));
			final switch (import_.type) {
				case ImportFileType.nat8Array:
					return ConcreteExprKind(getConstantArr(ctx.alloc, ctx.allConstants, mustBeByVal(type), bytes));
				case ImportFileType.string:
					ConcreteType char8ArrayType = only(ctx.char8ArrayAsString.paramsIncludingClosure).type;
					ConcreteExpr char8s = ConcreteExpr(char8ArrayType, range, ConcreteExprKind(
						getConstantArr(ctx.alloc, ctx.allConstants, mustBeByVal(char8ArrayType), bytes)));
					return ConcreteExprKind(ConcreteExprKind.Call(
						ctx.char8ArrayAsString, arrLiteral(ctx.alloc, [char8s])));
			}
		},
		(ReadFileDiag diag) =>
			concretizeBogusKind(ctx, range));
	return ConcreteExpr(type, range, exprKind);
}

ConcreteVar* getVar(ref ConcretizeCtx ctx, VarDecl* decl) =>
	getOrAdd!(immutable ConcreteVar*, immutable VarDecl*, getVarKey)(ctx.alloc, ctx.concreteVarLookup, decl, () =>
		allocate(ctx.alloc, ConcreteVar(decl, getConcreteType(ctx, decl.type, TypeArgsScope()))));

ulong getAllValue(ConcreteStructBody.Flags flags) =>
	fold!(ulong, ulong)(0, flags.values, (ulong a, in ulong b) =>
		a | b);

ConcreteType arrayElementType(ConcreteType arrayType) =>
	only(mustBeByVal(arrayType).source.as!(ConcreteStructSource.Inst).typeArgs);

ConcreteFunBody bodyForEnumOrFlagsMembers(ref ConcretizeCtx ctx, ConcreteType returnType) {
	// First type arg is 'symbol'
	ConcreteType enumOrFlagsType =
		only2(mustBeByVal(arrayElementType(returnType)).source.as!(ConcreteStructSource.Inst).typeArgs)[1];
	Constant[] elements = map(ctx.alloc, enumOrFlagsMembers(enumOrFlagsType), (ref StructBody.Enum.Member member) =>
		Constant(Constant.Record(arrLiteral!Constant(ctx.alloc, [
			constantSym(ctx, member.name),
			Constant(Constant.Integral(member.value.value))]))));
	Constant arr = getConstantArr(ctx.alloc, ctx.allConstants, mustBeByVal(returnType), elements);
	return ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(arr)));
}

StructBody.Enum.Member[] enumOrFlagsMembers(ConcreteType type) {
	StructBody body_ = body_(*decl(*mustBeByVal(type).source.as!(ConcreteStructSource.Inst).inst));
	return body_.match!(StructBody.Enum.Member[])(
		(StructBody.Bogus) =>
			unreachable!(StructBody.Enum.Member[]),
		(StructBody.Builtin) =>
			unreachable!(StructBody.Enum.Member[]),
		(StructBody.Enum it) =>
			it.members,
		(StructBody.Extern) =>
			unreachable!(StructBody.Enum.Member[]),
		(StructBody.Flags it) =>
			it.members,
		(StructBody.Record) =>
			unreachable!(StructBody.Enum.Member[]),
		(StructBody.Union) =>
			unreachable!(StructBody.Enum.Member[]));
}

ConcreteFunBody bodyForAllTests(ref ConcretizeCtx ctx, ConcreteType returnType) {
	Test[] allTests = () {
		ArrBuilder!Test allTestsBuilder;
		foreach (immutable Module* m; ctx.program.allModules)
			addAll(ctx.alloc, allTestsBuilder, m.tests);
		return finishArr(ctx.alloc, allTestsBuilder);
	}();
	Constant arr = getConstantArr(
		ctx.alloc,
		ctx.allConstants,
		mustBeByVal(returnType),
		mapWithIndex!(Constant, Test)(ctx.alloc, allTests, (size_t testIndex, ref Test it) =>
			Constant(Constant.FunPtr(concreteFunForTest(ctx, it, testIndex)))));
	return ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(arr)));
}

BuiltinStructKind getBuiltinStructKind(Sym name) {
	switch (name.value) {
		case sym!"bool".value:
			return BuiltinStructKind.bool_;
		case sym!"char8".value:
			return BuiltinStructKind.char8;
		case sym!"float32".value:
			return BuiltinStructKind.float32;
		case sym!"float64".value:
			return BuiltinStructKind.float64;
		case sym!"fun-act".value:
		case sym!"fun-fun".value:
			return BuiltinStructKind.fun;
		case sym!"fun-pointer".value:
			return BuiltinStructKind.funPointer;
		case sym!"int8".value:
			return BuiltinStructKind.int8;
		case sym!"int16".value:
			return BuiltinStructKind.int16;
		case sym!"int32".value:
			return BuiltinStructKind.int32;
		case sym!"int64".value:
			return BuiltinStructKind.int64;
		case sym!"nat8".value:
			return BuiltinStructKind.nat8;
		case sym!"nat16".value:
			return BuiltinStructKind.nat16;
		case sym!"nat32".value:
			return BuiltinStructKind.nat32;
		case sym!"nat64".value:
			return BuiltinStructKind.nat64;
		case sym!"const-pointer".value:
			return BuiltinStructKind.pointerConst;
		case sym!"mut-pointer".value:
			return BuiltinStructKind.pointerMut;
		case sym!"void".value:
			return BuiltinStructKind.void_;
		default:
			return todo!BuiltinStructKind("not a builtin struct");
	}
}

TypeSize getBuiltinStructSize(BuiltinStructKind kind) {
	final switch (kind) {
		case BuiltinStructKind.void_:
			return TypeSize(0, 1);
		case BuiltinStructKind.bool_:
		case BuiltinStructKind.char8:
		case BuiltinStructKind.int8:
		case BuiltinStructKind.nat8:
			return TypeSize(1, 1);
		case BuiltinStructKind.int16:
		case BuiltinStructKind.nat16:
			return TypeSize(2, 2);
		case BuiltinStructKind.float32:
		case BuiltinStructKind.int32:
		case BuiltinStructKind.nat32:
			return TypeSize(4, 4);
		case BuiltinStructKind.float64:
		case BuiltinStructKind.funPointer:
		case BuiltinStructKind.int64:
		case BuiltinStructKind.nat64:
		case BuiltinStructKind.pointerConst:
		case BuiltinStructKind.pointerMut:
			return TypeSize(8, 8);
		case BuiltinStructKind.fun:
			return TypeSize(16, 8);
	}
}
