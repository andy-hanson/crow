module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArr, getConstantCStr, getConstantSym;
import concretize.concretizeExpr : concretizeExpr;
import concretize.safeValue : bodyForSafeValue;
import model.concreteModel :
	asFlags,
	asFunInst,
	asInst,
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
	ConcreteMutability,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteType,
	concreteTypeEqual,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	ConcreteStructSource,
	hashConcreteType,
	hasSizeOrPointerSizeBytes,
	isSelfMutable,
	mustBeByVal,
	NeedsCtx,
	purity,
	ReferenceKind,
	sizeOrPointerSizeBytes,
	TypeSize;
import model.constant : Constant;
import model.model :
	body_,
	CommonTypes,
	decl,
	EnumBackingType,
	EnumFunction,
	Expr,
	FieldMutability,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunInst,
	matchFunBody,
	matchStructBody,
	matchType,
	Module,
	name,
	noCtx,
	Param,
	params,
	paramsArray,
	Program,
	Purity,
	range,
	RecordField,
	returnType,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	worsePurity;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, ptrAt, sizeEq;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil :
	arrEqual,
	arrLiteral,
	arrMax,
	every,
	everyWithIndex,
	exists,
	filterUnordered,
	fold,
	map,
	mapPtrsWithIndex,
	mapWithIndex;
import util.col.mutArr : MutArr, mutArrIsEmpty, push;
import util.col.mutDict :
	addToMutDict,
	getOrAdd,
	getOrAddAndDidAdd,
	mustDelete,
	MutDict,
	MutPtrDict,
	ValueAndDidAdd;
import util.col.mutSet : addToMutSetOkIfPresent, MutSymSet;
import util.col.str : SafeCStr;
import util.hash : Hasher;
import util.late : Late, lateGet, lateIsSet, lateSet, lateSetOverwrite, lazilySet;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, Opt, some;
import util.ptr : castImmutable, castMutable, hashPtr, Ptr, ptrEquals;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, shortSymValue, Sym;
import util.util : max, roundUp, todo, unreachable, verify;
import versionInfo : VersionInfo;

struct TypeArgsScope {
	@safe @nogc pure nothrow:

	/*
	Suppose we have:
	pair<?ts> record
		a ?ts
		b ?ts
	make-pair pair ?tf(value ?tf)
		new value, value

	When we instantiate the struct 'pair' for the return type, and are getting the type for 'a':
	The StructInst* for that will already have an instantiated fieldTypes containing ?tf and not ?ts.
	So the only type params and args we need here come from the concretefun.
	TODO:PERF no need to store typeParams then.
	*/

	immutable TypeParam[] typeParams;
	immutable ConcreteType[] typeArgs;

	immutable this(immutable TypeParam[] tp, immutable ConcreteType[] ta) {
		typeParams = tp;
		typeArgs = ta;
		verify(sizeEq(typeParams, typeArgs));
	}

	static immutable(TypeArgsScope) empty() {
		return immutable TypeArgsScope(emptyArr!TypeParam, emptyArr!ConcreteType);
	}
}

private struct ConcreteStructKey {
	immutable Ptr!StructDecl decl;
	immutable ConcreteType[] typeArgs;
}

private immutable(bool) concreteStructKeyEqual(ref const ConcreteStructKey a, ref const ConcreteStructKey b) {
	return ptrEquals(a.decl, b.decl) && concreteTypeArrEquals(a.typeArgs, b.typeArgs);
}

private void hashConcreteStructKey(ref Hasher hasher, ref const ConcreteStructKey a) {
	hashPtr(hasher, a.decl);
	foreach (immutable ConcreteType t; a.typeArgs)
		hashConcreteType(hasher, t);
}

struct ConcreteFunKey {
	// We only need a FunDecl since we have the typeArgs and specImpls.
	// FunInst is for debug info
	immutable Ptr!FunInst inst;
	immutable ConcreteType[] typeArgs;
	immutable Ptr!ConcreteFun[] specImpls;
}

private immutable(ContainingFunInfo) toContainingFunInfo(ref immutable ConcreteFunKey a) {
	return immutable ContainingFunInfo(a.inst.deref().decl.deref().typeParams, a.typeArgs, a.specImpls);
}

immutable(TypeArgsScope) typeArgsScope(ref immutable ConcreteFunKey a) {
	immutable ContainingFunInfo info = toContainingFunInfo(a);
	return immutable typeArgsScope(info);
}

struct ContainingFunInfo {
	immutable TypeParam[] typeParams; // TODO: get this from cf?
	immutable ConcreteType[] typeArgs;
	immutable Ptr!ConcreteFun[] specImpls;
}

immutable(TypeArgsScope) typeArgsScope(ref immutable ContainingFunInfo a) {
	return immutable TypeArgsScope(a.typeParams, a.typeArgs);
}

private immutable(bool) concreteFunKeyEqual(ref immutable ConcreteFunKey a, ref immutable ConcreteFunKey b) {
	// Compare decls, not insts.
	// Two different FunInsts may concretize to the same thing.
	// (e.g. f<?t> and f<bool> if ?t = bool)
	return ptrEquals(a.inst.deref().decl, b.inst.deref().decl) &&
		concreteTypeArrEquals(a.typeArgs, b.typeArgs) &&
		arrEqual!(immutable Ptr!ConcreteFun)(
			a.specImpls,
			b.specImpls,
			(ref immutable Ptr!ConcreteFun x, ref immutable Ptr!ConcreteFun y) =>
				ptrEquals(x, y));
}

private void hashConcreteFunKey(ref Hasher hasher, ref immutable ConcreteFunKey a) {
	hashPtr(hasher, a.inst.deref().decl);
	foreach (ref immutable ConcreteType t; a.typeArgs)
		hashConcreteType(hasher, t);
	foreach (immutable Ptr!ConcreteFun p; a.specImpls)
		hashPtr(hasher, p);
}

private struct ConcreteFunBodyInputs {
	// NOTE: for a lambda, these are for the *outermost* fun (the one with type args and spec impls).
	immutable ContainingFunInfo containing;
	// Body of the current fun, not the outer one.
	immutable FunBody body_;
}

ref immutable(ConcreteType[]) typeArgs(return scope ref immutable ConcreteFunBodyInputs a) {
	return a.containing.typeArgs;
}

immutable(TypeArgsScope) typeArgsScope(ref immutable ConcreteFunBodyInputs a) {
	return typeArgsScope(a.containing);
}

private struct DeferredRecordBody {
	Ptr!ConcreteStruct struct_;
	immutable bool packed;
	immutable bool isSelfMutable;
	immutable ConcreteField[] fields;
	immutable FieldsType fieldsType;
}

private struct DeferredUnionBody {
	Ptr!ConcreteStruct struct_;
	immutable Opt!ConcreteType[] members;
}

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	Ptr!Alloc allocPtr;
	immutable VersionInfo versionInfo;
	const Ptr!AllSymbols allSymbolsPtr;
	immutable Ptr!FunInst curExclusionFun;
	immutable Ptr!StructInst ctxStructInst;
	immutable Ptr!CommonTypes commonTypesPtr;
	immutable Ptr!Program programPtr;
	AllConstantsBuilder allConstants;
	MutDict!(
		immutable ConcreteStructKey,
		immutable Ptr!ConcreteStruct,
		concreteStructKeyEqual,
		hashConcreteStructKey,
	) nonLambdaConcreteStructs;
	ArrBuilder!(immutable Ptr!ConcreteStruct) allConcreteStructs;
	MutDict!(
		immutable ConcreteFunKey,
		immutable Ptr!ConcreteFun,
		concreteFunKeyEqual,
		hashConcreteFunKey,
	) nonLambdaConcreteFuns;
	MutArr!DeferredRecordBody deferredRecords;
	MutArr!DeferredUnionBody deferredUnions;
	ArrBuilder!(immutable Ptr!ConcreteFun) allConcreteFuns;
	MutSymSet allExternLibraryNames;

	// This will only have an entry while a ConcreteFun hasn't had it's body filled in yet.
	MutPtrDict!(ConcreteFun, immutable ConcreteFunBodyInputs) concreteFunToBodyInputs;
	// Index in the MutArr!(immutable ConcreteLambdaImpl) is the fun ID
	MutPtrDict!(ConcreteStruct, MutArr!(immutable ConcreteLambdaImpl)) funStructToImpls;
	// TODO: do these eagerly
	Late!(immutable ConcreteType) _boolType;
	Late!(immutable ConcreteType) _voidType;
	Late!(immutable ConcreteType) _ctxType;
	Late!(immutable ConcreteType) _cStrType;
	Late!(immutable ConcreteType) _symType;

	ref Alloc alloc() return scope {
		return allocPtr.deref();
	}

	ref const(AllSymbols) allSymbols() return scope const {
		return allSymbolsPtr.deref();
	}
	ref immutable(CommonTypes) commonTypes() return scope const {
		return commonTypesPtr.deref();
	}
	ref immutable(Program) program() return scope const {
		return programPtr.deref();
	}
}

immutable(ConcreteType) boolType(ref ConcretizeCtx a) {
	return lazilySet(a._boolType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.bool_, TypeArgsScope.empty));
}

immutable(ConcreteType) voidType(ref ConcretizeCtx a) {
	return lazilySet(a._voidType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.void_, TypeArgsScope.empty));
}

immutable(ConcreteType) cStrType(ref ConcretizeCtx a) {
	return lazilySet(a._cStrType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.cStr, TypeArgsScope.empty));
}

immutable(ConcreteType) symType(ref ConcretizeCtx a) {
	return lazilySet(a._symType, () =>
		getConcreteType_forStructInst(a, a.commonTypes.sym, TypeArgsScope.empty));
}

immutable(ConcreteType) ctxType(ref ConcretizeCtx a) {
	immutable ConcreteType res = lazilySet(a._ctxType, () =>
		getConcreteType_forStructInst(a, a.ctxStructInst, TypeArgsScope.empty));
	verify(res.reference == ReferenceKind.byRef);
	return res;
}

immutable(Constant) constantCStr(ref ConcretizeCtx a, immutable SafeCStr value) {
	return getConstantCStr(a.alloc, a.allConstants, value);
}

immutable(Constant) constantSym(ref ConcretizeCtx a, immutable Sym value) {
	return getConstantSym(a.alloc, a.allConstants, a.allSymbols, value);
}

immutable(Ptr!ConcreteFun) getOrAddConcreteFunAndFillBody(ref ConcretizeCtx ctx, immutable ConcreteFunKey key) {
	Ptr!ConcreteFun cf = castMutable(getOrAddConcreteFunWithoutFillingBody(ctx, key));
	fillInConcreteFunBody(ctx, cf);
	return castImmutable(cf);
}

immutable(Ptr!ConcreteFun) getConcreteFunForLambdaAndFillBody(
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun containingConcreteFun,
	immutable size_t index,
	immutable ConcreteType returnType,
	immutable Ptr!ConcreteParam closureParam,
	ref immutable ConcreteParam[] params,
	ref immutable ContainingFunInfo containing,
	ref immutable Expr body_,
) {
	Ptr!ConcreteFun res = allocateMut(ctx.alloc, ConcreteFun(
		immutable ConcreteFunSource(
			allocate(ctx.alloc, immutable ConcreteFunSource.Lambda(body_.range, containingConcreteFun, index))),
		returnType,
		NeedsCtx.yes,
		some(closureParam),
		params));
	immutable ConcreteFunBodyInputs bodyInputs = immutable ConcreteFunBodyInputs(containing, immutable FunBody(body_));
	addToMutDict(ctx.alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	fillInConcreteFunBody(ctx, res);
	addConcreteFun(ctx, castImmutable(res));
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) getOrAddNonTemplateConcreteFunAndFillBody(
	ref ConcretizeCtx ctx,
	immutable Ptr!FunInst decl,
) {
	immutable ConcreteFunKey key = immutable ConcreteFunKey(decl, emptyArr!ConcreteType, emptyArr!(Ptr!ConcreteFun));
	return getOrAddConcreteFunAndFillBody(ctx, key);
}

immutable(ConcreteType) getConcreteType_forStructInst(
	ref ConcretizeCtx ctx,
	immutable Ptr!StructInst i,
	immutable TypeArgsScope typeArgsScope,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes(ctx, typeArgs(i.deref()), typeArgsScope);
	if (ptrEquals(i.deref().decl, ctx.commonTypes.byVal))
		return byVal(only(typeArgs));
	else {
		immutable ConcreteStructKey key = ConcreteStructKey(i.deref().decl, typeArgs);
		immutable ValueAndDidAdd!(immutable Ptr!ConcreteStruct) res =
			getOrAddAndDidAdd(ctx.alloc, ctx.nonLambdaConcreteStructs, key, () {
				immutable Purity purity = fold(
					i.deref().purityRange.bestCase,
					typeArgs,
					(immutable Purity p, ref immutable ConcreteType ta) =>
						worsePurity(p, purity(ta)));
				immutable Ptr!ConcreteStruct res = allocate(ctx.alloc, immutable ConcreteStruct(
					purity,
					immutable ConcreteStructSource(immutable ConcreteStructSource.Inst(i, key.typeArgs))));
				add(ctx.alloc, ctx.allConcreteStructs, res);
				return res;
			});
		if (res.didAdd)
			initializeConcreteStruct(ctx, typeArgs, i.deref(), castMutable(res.value), typeArgsScope);
		if (!lateIsSet(res.value.deref().defaultReferenceKind_))
			// The only way 'defaultIsPointer' would not be set is if we are still computing the size of 's'.
			// In that case, it's a recursive record, so it should be by-ref.
			lateSet(castMutable(res.value).deref().defaultReferenceKind_, ReferenceKind.byRef);
		return immutable ConcreteType(lateGet(res.value.deref().defaultReferenceKind_), res.value);
	}
}

immutable(ConcreteType) getConcreteType(
	ref ConcretizeCtx ctx,
	immutable Type t,
	immutable TypeArgsScope typeArgsScope,
) {
	return matchType!(immutable ConcreteType)(
		t,
		(immutable Type.Bogus) =>
			unreachable!(immutable ConcreteType),
		(immutable Ptr!TypeParam p) {
			// Handle calledConcreteFun first
			verify(ptrEquals(p, ptrAt(typeArgsScope.typeParams, p.deref().index)));
			return typeArgsScope.typeArgs[p.deref().index];
		},
		(immutable Ptr!StructInst i) =>
			getConcreteType_forStructInst(ctx, i, typeArgsScope));
}

immutable(ConcreteType[]) typesToConcreteTypes(
	ref ConcretizeCtx ctx,
	immutable Type[] types,
	immutable TypeArgsScope typeArgsScope,
) {
	return map!ConcreteType(ctx.alloc, types, (ref immutable Type t) =>
		getConcreteType(ctx, t, typeArgsScope));
}

immutable(ConcreteType) concreteTypeFromClosure(
	ref ConcretizeCtx ctx,
	ref immutable ConcreteField[] closureFields,
	immutable ConcreteStructSource source,
) {
	if (empty(closureFields))
		return voidType(ctx);
	else {
		immutable Purity purity = fold(
			Purity.data,
			closureFields,
			(immutable Purity p, ref immutable ConcreteField f) {
				// TODO: lambda fields are never mutable, use a different type?
				verify(f.mutability == ConcreteMutability.const_);
				return worsePurity(p, purity(f.type));
			});
		Ptr!ConcreteStruct cs = allocateMut(ctx.alloc, ConcreteStruct(purity, source));
		lateSet(cs.deref().info_, getConcreteStructInfoForFields(closureFields));
		setConcreteStructRecordSizeOrDefer(
			ctx, cs, false, closureFields, false, FieldsType.closure);
		add(ctx.alloc, ctx.allConcreteStructs, castImmutable(cs));
		// TODO: consider passing closure by value
		return immutable ConcreteType(ReferenceKind.byRef, castImmutable(cs));
	}
}

private void setConcreteStructRecordSizeOrDefer(
	ref ConcretizeCtx ctx,
	Ptr!ConcreteStruct cs,
	immutable bool packed,
	immutable ConcreteField[] fields,
	immutable bool isSelfMutable,
	immutable FieldsType fieldsType,
) {
	DeferredRecordBody deferred = DeferredRecordBody(cs, packed, isSelfMutable, fields, fieldsType);
	if (canGetRecordSize(fields))
		setConcreteStructRecordSize(ctx.alloc, deferred);
	else
		push(ctx.alloc, ctx.deferredRecords, deferred);
}

private void setConcreteStructRecordSize(ref Alloc alloc, DeferredRecordBody a) {
	immutable TypeSizeAndFieldOffsets size = recordSize(alloc, a.packed, a.fields);
	if (!lateIsSet(a.struct_.deref().defaultReferenceKind_))
		lateSet(
			a.struct_.deref().defaultReferenceKind_,
			getDefaultReferenceKindForFields(size.typeSize, a.isSelfMutable, a.fieldsType));
	lateSet(a.struct_.deref().typeSize_, size.typeSize);
	lateSet(a.struct_.deref().fieldOffsets_, size.fieldOffsets);
}

//TODO: do eagerly?
immutable(Ptr!ConcreteFun) getCurExclusionFun(ref ConcretizeCtx ctx) {
	return getOrAddNonTemplateConcreteFunAndFillBody(ctx, ctx.curExclusionFun);
}

private:

immutable(Ptr!ConcreteFun) getOrAddConcreteFunWithoutFillingBody(ref ConcretizeCtx ctx, immutable ConcreteFunKey key) {
	return getOrAdd(ctx.alloc, ctx.nonLambdaConcreteFuns, key, () {
		immutable Ptr!ConcreteFun res = getConcreteFunFromKey(ctx, key);
		addConcreteFun(ctx, res);
		return res;
	});
}

immutable(Ptr!ConcreteFun) getConcreteFunFromKey(ref ConcretizeCtx ctx, ref immutable ConcreteFunKey key) {
	immutable Ptr!FunDecl decl = key.inst.deref().decl;
	immutable TypeArgsScope typeScope = typeArgsScope(key);
	immutable ConcreteType returnType = getConcreteType(ctx, returnType(decl.deref()), typeScope);
	immutable ConcreteParam[] params = concretizeParams(ctx, paramsArray(params(decl.deref())), typeScope);
	Ptr!ConcreteFun res = allocateMut(ctx.alloc, ConcreteFun(
		immutable ConcreteFunSource(key.inst),
		returnType,
		getNeedsCtx(decl.deref(), key.specImpls),
		none!(Ptr!ConcreteParam),
		params));
	immutable ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(
		toContainingFunInfo(key),
		decl.deref().body_);
	addToMutDict(ctx.alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	return castImmutable(res);
}

immutable(NeedsCtx) getNeedsCtx(ref immutable FunDecl decl, immutable Ptr!ConcreteFun[] specImpls) {
	immutable bool res = !noCtx(decl) || exists!(immutable Ptr!ConcreteFun)(
		specImpls,
		(ref immutable Ptr!ConcreteFun impl) =>
			impl.deref().needsCtx == NeedsCtx.yes);
	return res ? NeedsCtx.yes : NeedsCtx.no;
}

void addConcreteFun(ref ConcretizeCtx ctx, immutable Ptr!ConcreteFun fun) {
	add(ctx.alloc, ctx.allConcreteFuns, fun);
}

immutable(Ptr!ConcreteFun) concreteFunForTest(
	ref ConcretizeCtx ctx,
	scope ref immutable Test test,
	immutable size_t testIndex,
) {
	Ptr!ConcreteFun res = allocateMut(ctx.alloc, ConcreteFun(
		immutable ConcreteFunSource(allocate(ctx.alloc, immutable ConcreteFunSource.Test(test.body_.range, testIndex))),
		voidType(ctx),
		NeedsCtx.yes,
		none!(Ptr!ConcreteParam),
		emptyArr!ConcreteParam));
	immutable ContainingFunInfo containing = immutable ContainingFunInfo(
		emptyArr!TypeParam,
		emptyArr!ConcreteType,
		emptyArr!(Ptr!ConcreteFun));
	immutable ConcreteExpr body_ =
		concretizeExpr(ctx, containing, castImmutable(res), test.body_);
	lateSet(res.deref()._body_, immutable ConcreteFunBody(body_));
	addConcreteFun(ctx, castImmutable(res));
	return castImmutable(res);
}

immutable(bool) concreteTypeArrEquals(ref immutable ConcreteType[] a, ref immutable ConcreteType[] b) {
	return arrEqual!ConcreteType(a, b, (ref immutable ConcreteType x, ref immutable ConcreteType y) =>
		concreteTypeEqual(x, y));
}

immutable(bool) canGetUnionSize(ref immutable Opt!ConcreteType[] members) {
	return every!(Opt!ConcreteType)(members, (ref immutable Opt!ConcreteType type) =>
		!has(type) || hasSizeOrPointerSizeBytes(force(type)));
}

immutable(TypeSize) unionSize(ref immutable Opt!ConcreteType[] members) {
	immutable size_t unionAlign = 8;
	immutable size_t maxMember = arrMax!(size_t, Opt!ConcreteType)(0, members, (ref immutable Opt!ConcreteType t) =>
		has(t) ? sizeOrPointerSizeBytes(force(t)).size : 0);
	immutable size_t sizeBytes = roundUp(8 + maxMember, unionAlign);
	return immutable TypeSize(sizeBytes, unionAlign);
}

immutable(ReferenceKind) getDefaultReferenceKindForFields(
	immutable TypeSize typeSize,
	immutable bool isSelfMutable,
	immutable FieldsType type,
) {
	immutable size_t maxSize = () {
		final switch (type) {
			case FieldsType.closure:
				return 8;
			case FieldsType.record:
				return 8 * 2;
		}
	}();
	return isSelfMutable || typeSize.size > maxSize ? ReferenceKind.byRef : ReferenceKind.byVal;
}

enum FieldsType { record, closure }

immutable(bool) canGetRecordSize(immutable ConcreteField[] fields) {
	return every!ConcreteField(fields, (ref immutable ConcreteField field) =>
		hasSizeOrPointerSizeBytes(field.type));
}

immutable(ConcreteStructInfo) getConcreteStructInfoForFields(immutable ConcreteField[] fields) {
	return immutable ConcreteStructInfo(
		immutable ConcreteStructBody(immutable ConcreteStructBody.Record(fields)),
		exists!ConcreteField(fields, (ref immutable ConcreteField field) =>
			field.mutability != ConcreteMutability.const_));
}

struct TypeSizeAndFieldOffsets {
	immutable TypeSize typeSize;
	immutable size_t[] fieldOffsets;
}

immutable(TypeSizeAndFieldOffsets) recordSize(
	ref Alloc alloc,
	immutable bool packed,
	immutable ConcreteField[] fields,
) {
	size_t maxFieldSize = 1;
	size_t maxFieldAlignment = 1;
	size_t offset = 0;
	immutable size_t[] fieldOffsets = map(alloc, fields, (ref immutable ConcreteField field) {
		immutable TypeSize fieldSize = sizeOrPointerSizeBytes(field.type);
		maxFieldSize = max(maxFieldSize, fieldSize.size);
		if (!packed) {
			maxFieldAlignment = max(maxFieldAlignment, fieldSize.alignment);
			offset = roundUp(offset, fieldSize.alignment);
		}
		immutable size_t fieldOffset = offset;
		offset += fieldSize.size;
		return fieldOffset;
	});
	immutable TypeSize typeSize = immutable TypeSize(roundUp(offset, maxFieldAlignment), maxFieldAlignment);
	return immutable TypeSizeAndFieldOffsets(typeSize, fieldOffsets);
}

void initializeConcreteStruct(
	ref ConcretizeCtx ctx,
	ref immutable ConcreteType[] typeArgs,
	ref immutable StructInst i,
	Ptr!ConcreteStruct res,
	immutable TypeArgsScope typeArgsScope,
) {
	matchStructBody!void(
		body_(i),
		(ref immutable StructBody.Bogus) => unreachable!void,
		(ref immutable StructBody.Builtin) {
			immutable BuiltinStructKind kind = getBuiltinStructKind(i.decl.deref().name);
			lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Builtin(kind, typeArgs)),
				false));
			lateSet(res.deref().typeSize_, getBuiltinStructSize(kind));
		},
		(ref immutable StructBody.Enum it) {
			lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForEnum(ctx.alloc, it)),
				false));
			lateSet(res.deref().typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.Flags it) {
			lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForFlags(ctx.alloc, it)),
				false));
			lateSet(res.deref().typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.ExternPtr it) {
			// byVal because the 'extern' type *is* a pointer
			lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(immutable ConcreteStructBody.ExternPtr()),
				false));
			lateSet(res.deref().typeSize_, getBuiltinStructSize(BuiltinStructKind.ptrMut));
		},
		(ref immutable StructBody.Record r) {
			// don't set 'defaultReferenceKind' until the end, unless explicit
			final switch (r.flags.forcedByValOrRef) {
				case ForcedByValOrRefOrNone.none:
					break;
				case ForcedByValOrRefOrNone.byVal:
					lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
					break;
				case ForcedByValOrRefOrNone.byRef:
					lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byRef);
					break;
			}

			immutable ConcreteField[] fields = map!ConcreteField(ctx.alloc, r.fields, (ref immutable RecordField f) =>
				immutable ConcreteField(
					f.name,
					toConcreteMutability(f.mutability),
					getConcreteType(ctx, f.type, typeArgsScope)));
			immutable bool packed = r.flags.packed;
			immutable ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			lateSet(res.deref().info_, info);
			if (r.flags.forcedByValOrRef == ForcedByValOrRefOrNone.byVal)
				verify(!info.isSelfMutable);
			setConcreteStructRecordSizeOrDefer(
				ctx, res, packed, fields, info.isSelfMutable, FieldsType.record);
		},
		(ref immutable StructBody.Union u) {
			lateSet(res.deref().defaultReferenceKind_, ReferenceKind.byVal);
			immutable Opt!ConcreteType[] members = map!(Opt!ConcreteType)(
				ctx.alloc,
				u.members,
				(ref immutable UnionMember it) =>
					has(it.type)
						? some(getConcreteType(ctx, force(it.type), typeArgsScope))
						: none!ConcreteType);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Union(members)), false));
			if (canGetUnionSize(members))
				lateSet(res.deref().typeSize_, unionSize(members));
			else
				push(ctx.alloc, ctx.deferredUnions, DeferredUnionBody(res, members));
		});
}

immutable(ConcreteMutability) toConcreteMutability(immutable FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return ConcreteMutability.const_;
		case FieldMutability.private_:
			return ConcreteMutability.mutable;
		case FieldMutability.public_:
			return ConcreteMutability.mutable;
	}
}

immutable(TypeSize) typeSizeForEnumOrFlags(immutable EnumBackingType a) {
	immutable size_t size = sizeForEnumOrFlags(a);
	return immutable TypeSize(size, size);
}
immutable(size_t) sizeForEnumOrFlags(immutable EnumBackingType a) {
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

immutable(ConcreteStructBody.Enum) getConcreteStructBodyForEnum(
	ref Alloc alloc,
	ref immutable StructBody.Enum a,
) {
	immutable bool simple = everyWithIndex!(StructBody.Enum.Member)(
		a.members,
		(ref immutable StructBody.Enum.Member member, immutable size_t index) =>
			member.value.value == index);
	return simple
		? immutable ConcreteStructBody.Enum(a.backingType, a.members.length)
		: immutable ConcreteStructBody.Enum(
			a.backingType,
			map(alloc, a.members, (ref immutable StructBody.Enum.Member member) =>
				member.value));
}

immutable(ConcreteStructBody.Flags) getConcreteStructBodyForFlags(
	ref Alloc alloc,
	ref immutable StructBody.Flags a,
) {
	return immutable ConcreteStructBody.Flags(
		a.backingType,
		map!ulong(alloc, a.members, (ref immutable StructBody.Enum.Member member) =>
			member.value.asUnsigned()));
}

public void deferredFillRecordAndUnionBodies(ref ConcretizeCtx ctx) {
	if (!mutArrIsEmpty(ctx.deferredRecords) || !mutArrIsEmpty(ctx.deferredUnions)) {
		bool couldGetSomething = false;
		filterUnordered!DeferredRecordBody(ctx.deferredRecords, (ref DeferredRecordBody deferred) {
			immutable bool canGet = canGetRecordSize(deferred.fields);
			if (canGet) {
				setConcreteStructRecordSize(ctx.alloc, deferred);
				couldGetSomething = true;
			}
			return !canGet;
		});
		filterUnordered!DeferredUnionBody(ctx.deferredUnions, (ref DeferredUnionBody deferred) {
			immutable bool canGet = canGetUnionSize(deferred.members);
			if (canGet) {
				lateSet(deferred.struct_.deref().typeSize_, unionSize(deferred.members));
				couldGetSomething = true;
			}
			return !canGet;
		});
		verify(couldGetSomething);
		deferredFillRecordAndUnionBodies(ctx);
	}
}

void fillInConcreteFunBody(ref ConcretizeCtx ctx, Ptr!ConcreteFun cf) {
	// TODO: just assert it's not already set?
	if (!lateIsSet(cf.deref()._body_)) {
		// set to arbitrary temporarily
		lateSet(cf.deref()._body_, immutable ConcreteFunBody(immutable ConcreteFunBody.Extern(false)));
		immutable ConcreteFunBodyInputs inputs = mustDelete(ctx.concreteFunToBodyInputs, castImmutable(cf));
		immutable ConcreteFunBody body_ = matchFunBody!(
			immutable ConcreteFunBody,
			(ref immutable FunBody.Builtin) {
				immutable Ptr!FunInst inst = asFunInst(cf.deref().source);
				switch (name(inst.deref()).value) {
					case shortSymValue("all-tests"):
						return bodyForAllTests(ctx, castImmutable(cf).deref().returnType);
					case shortSymValue("safe-value"):
						return bodyForSafeValue(
							ctx,
							castImmutable(cf),
							concreteFunRange(castImmutable(cf).deref(), ctx.allSymbols),
							castImmutable(cf).deref().returnType);
					default:
						return immutable ConcreteFunBody(immutable ConcreteFunBody.Builtin(typeArgs(inputs)));
				}
			},
			(ref immutable FunBody.CreateEnum it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.CreateEnum(it.value)),
			(ref immutable FunBody.CreateRecord) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.CreateRecord()),
			(ref immutable FunBody.CreateUnion it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.CreateUnion(it.memberIndex)),
			(immutable EnumFunction it) {
				final switch (it) {
					case EnumFunction.equal:
					case EnumFunction.intersect:
					case EnumFunction.toIntegral:
					case EnumFunction.union_:
						return immutable ConcreteFunBody(it);
					case EnumFunction.members:
						return bodyForEnumOrFlagsMembers(ctx, castImmutable(cf).deref().returnType);
				}
			},
			(ref immutable FunBody.Extern e) {
				if (has(e.libraryName))
					addToMutSetOkIfPresent(ctx.alloc, ctx.allExternLibraryNames, force(e.libraryName));
				return immutable ConcreteFunBody(immutable ConcreteFunBody.Extern(e.isGlobal));
			},
			(ref immutable Expr e) =>
				immutable ConcreteFunBody(concretizeExpr(ctx, inputs.containing, castImmutable(cf), e)),
			(immutable FunBody.FileBytes e) {
				immutable ConcreteType type = cf.deref().returnType;
				//TODO:PERF creating a Constant per byte is expensive
				immutable Constant[] bytes = map(ctx.alloc, e.bytes, (ref immutable ubyte a) =>
					immutable Constant(immutable Constant.Integral(a)));
				immutable Constant arr = getConstantArr(ctx.alloc, ctx.allConstants, mustBeByVal(type), bytes);
				immutable FileAndRange range = concreteFunRange(castImmutable(cf).deref(), ctx.allSymbols);
				return immutable ConcreteFunBody(immutable ConcreteExpr(type, range, immutable ConcreteExprKind(arr)));
			},
			(immutable FlagsFunction it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.FlagsFn(
					getAllValue(asFlags(body_(mustBeByVal(castImmutable(cf).deref().returnType).deref()))),
					it)),
			(ref immutable FunBody.RecordFieldGet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldGet(it.fieldIndex)),
			(ref immutable FunBody.RecordFieldSet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldSet(it.fieldIndex)),
		)(inputs.body_);
		lateSetOverwrite(cf.deref()._body_, body_);
	}
}

immutable(ulong) getAllValue(ref immutable ConcreteStructBody.Flags flags) {
	return fold(0, flags.values, (immutable ulong a, ref immutable ulong b) =>
		a | b);
}

immutable(ConcreteFunBody) bodyForEnumOrFlagsMembers(ref ConcretizeCtx ctx, immutable ConcreteType returnType) {
	immutable Ptr!ConcreteStruct arrayStruct = mustBeByVal(returnType);
	immutable ConcreteType elementType = only(asInst(arrayStruct.deref().source).typeArgs); // named<e>
	immutable ConcreteType enumOrFlagsType = only(asInst(mustBeByVal(elementType).deref().source).typeArgs);
	immutable Constant[] elements = map!Constant(
		ctx.alloc,
		enumOrFlagsMembers(enumOrFlagsType),
		(ref immutable StructBody.Enum.Member member) =>
			immutable Constant(immutable Constant.Record(arrLiteral!Constant(ctx.alloc, [
				constantSym(ctx, member.name),
				immutable Constant(immutable Constant.Integral(member.value.value))]))));
	immutable Constant arr = getConstantArr(ctx.alloc, ctx.allConstants, arrayStruct, elements);
	return immutable ConcreteFunBody(
		immutable ConcreteExpr(returnType, FileAndRange.empty, immutable ConcreteExprKind(arr)));
}

immutable(StructBody.Enum.Member[]) enumOrFlagsMembers(immutable ConcreteType type) {
	return matchStructBody!(immutable StructBody.Enum.Member[])(
		body_(decl(asInst(mustBeByVal(type).deref().source).inst.deref()).deref()),
		(ref immutable StructBody.Bogus) =>
			unreachable!(immutable StructBody.Enum.Member[]),
		(ref immutable StructBody.Builtin) =>
			unreachable!(immutable StructBody.Enum.Member[]),
		(ref immutable StructBody.Enum it) =>
			it.members,
		(ref immutable StructBody.Flags it) =>
			it.members,
		(ref immutable StructBody.ExternPtr) =>
			unreachable!(immutable StructBody.Enum.Member[]),
		(ref immutable StructBody.Record) =>
			unreachable!(immutable StructBody.Enum.Member[]),
		(ref immutable StructBody.Union) =>
			unreachable!(immutable StructBody.Enum.Member[]));
}

immutable(ConcreteFunBody) bodyForAllTests(ref ConcretizeCtx ctx, immutable ConcreteType returnType) {
	immutable Test[] allTests = () {
		ArrBuilder!Test allTestsBuilder;
		foreach (ref immutable Module m; ctx.program.allModules)
			addAll(ctx.alloc, allTestsBuilder, m.tests);
		return finishArr(ctx.alloc, allTestsBuilder);
	}();
	immutable Constant arr = getConstantArr(
		ctx.alloc,
		ctx.allConstants,
		mustBeByVal(returnType),
		mapWithIndex(ctx.alloc, allTests, (immutable size_t testIndex, scope ref immutable Test it) =>
			immutable Constant(immutable Constant.FunPtr(concreteFunForTest(ctx, it, testIndex)))));
	return immutable ConcreteFunBody(immutable ConcreteExpr(
		returnType,
		FileAndRange.empty,
		immutable ConcreteExprKind(arr)));
}

immutable(ConcreteParam[]) concretizeParams(
	ref ConcretizeCtx ctx,
	immutable Param[] params,
	immutable TypeArgsScope typeArgsScope,
) {
	return mapPtrsWithIndex!ConcreteParam(ctx.alloc, params, (immutable size_t index, immutable Ptr!Param p) =>
		immutable ConcreteParam(
			immutable ConcreteParamSource(p),
			some!size_t(index),
			getConcreteType(ctx, p.deref().type, typeArgsScope)));
}

immutable(BuiltinStructKind) getBuiltinStructKind(immutable Sym name) {
	switch (name.value) {
		case shortSymValue("bool"):
			return BuiltinStructKind.bool_;
		case shortSymValue("char8"):
			return BuiltinStructKind.char8;
		case shortSymValue("float32"):
			return BuiltinStructKind.float32;
		case shortSymValue("float64"):
			return BuiltinStructKind.float64;
		case shortSymValue("fun0"):
		case shortSymValue("fun1"):
		case shortSymValue("fun2"):
		case shortSymValue("fun3"):
		case shortSymValue("fun4"):
		case shortSymValue("fun-act0"):
		case shortSymValue("fun-act1"):
		case shortSymValue("fun-act2"):
		case shortSymValue("fun-act3"):
		case shortSymValue("fun-act4"):
			return BuiltinStructKind.fun;
		case shortSymValue("fun-ptr0"):
		case shortSymValue("fun-ptr1"):
		case shortSymValue("fun-ptr2"):
		case shortSymValue("fun-ptr3"):
		case shortSymValue("fun-ptr4"):
		case shortSymValue("fun-ptr5"):
		case shortSymValue("fun-ptr6"):
			return BuiltinStructKind.funPtrN;
		case shortSymValue("int8"):
			return BuiltinStructKind.int8;
		case shortSymValue("int16"):
			return BuiltinStructKind.int16;
		case shortSymValue("int32"):
			return BuiltinStructKind.int32;
		case shortSymValue("int64"):
			return BuiltinStructKind.int64;
		case shortSymValue("nat8"):
			return BuiltinStructKind.nat8;
		case shortSymValue("nat16"):
			return BuiltinStructKind.nat16;
		case shortSymValue("nat32"):
			return BuiltinStructKind.nat32;
		case shortSymValue("nat64"):
			return BuiltinStructKind.nat64;
		case shortSymValue("const-ptr"):
			return BuiltinStructKind.ptrConst;
		case shortSymValue("mut-ptr"):
			return BuiltinStructKind.ptrMut;
		case shortSymValue("void"):
			return BuiltinStructKind.void_;
		default:
			return todo!(immutable BuiltinStructKind)("not a builtin struct");
	}
}

immutable(TypeSize) getBuiltinStructSize(immutable BuiltinStructKind kind) {
	final switch (kind) {
		case BuiltinStructKind.void_:
			return immutable TypeSize(0, 1);
		case BuiltinStructKind.bool_:
		case BuiltinStructKind.char8:
		case BuiltinStructKind.int8:
		case BuiltinStructKind.nat8:
			return immutable TypeSize(1, 1);
		case BuiltinStructKind.int16:
		case BuiltinStructKind.nat16:
			return immutable TypeSize(2, 2);
		case BuiltinStructKind.float32:
		case BuiltinStructKind.int32:
		case BuiltinStructKind.nat32:
			return immutable TypeSize(4, 4);
		case BuiltinStructKind.float64:
		case BuiltinStructKind.funPtrN:
		case BuiltinStructKind.int64:
		case BuiltinStructKind.nat64:
		case BuiltinStructKind.ptrConst:
		case BuiltinStructKind.ptrMut:
			return immutable TypeSize(8, 8);
		case BuiltinStructKind.fun:
			return immutable TypeSize(16, 8);
	}
}
