module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder :
	AllConstantsBuilder,
	getConstantArr,
	getConstantStr,
	getConstantSym;
import concretize.concretizeExpr : concretizeExpr;
import model.concreteModel :
	asFlags,
	asFunInst,
	asInst,
	body_,
	BuiltinStructKind,
	byVal,
	compareConcreteType,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFieldSource,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteFunSource,
	ConcreteLambdaImpl,
	ConcreteMutability,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteType,
	concreteType_fromStruct,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	ConcreteStructSource,
	hasSizeOrPointerSizeBytes,
	mustBeNonPointer,
	NeedsCtx,
	purity,
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
import util.collection.arr : at, empty, emptyArr, only, ptrAt, size, sizeEq;
import util.collection.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.collection.arrUtil :
	arrLiteral,
	arrMax,
	compareArr,
	every,
	everyWithIndex,
	exists,
	filterUnordered,
	fold,
	map,
	mapPtrsWithIndex,
	mapWithIndex;
import util.collection.mutArr : MutArr, mutArrIsEmpty, push;
import util.collection.mutDict : addToMutDict, getOrAdd, getOrAddAndDidAdd, mustDelete, MutDict, ValueAndDidAdd;
import util.collection.mutSet : addToMutSetOkIfPresent, MutSet;
import util.collection.str : compareStr, copyStr;
import util.comparison : Comparison;
import util.late : Late, lateIsSet, lateSet, lateSetMaybeOverwrite, lateSetOverwrite, lazilySet;
import util.memory : allocate, allocateMut;
import util.opt : force, has, none, Opt, some;
import util.ptr : castImmutable, castMutable, comparePtr, Ptr, ptrEquals;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, shortSymAlphaLiteralValue, Sym, symEq;
import util.types : Nat8, Nat16, safeSizeTToU8;
import util.util : max, roundUp, todo, unreachable, verify;

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

private immutable(Comparison) compareConcreteStructKey(ref const ConcreteStructKey a, ref const ConcreteStructKey b) {
	immutable Comparison res = comparePtr(a.decl, b.decl);
	return res != Comparison.equal ? res : compareConcreteTypeArr(a.typeArgs, b.typeArgs);
}

struct ConcreteFunKey {
	// We only need a FunDecl since we have the typeArgs and specImpls.
	// FunInst is for debug info
	immutable Ptr!FunInst inst;
	immutable ConcreteType[] typeArgs;
	immutable Ptr!ConcreteFun[] specImpls;
}

private immutable(ContainingFunInfo) toContainingFunInfo(ref immutable ConcreteFunKey a) {
	return immutable ContainingFunInfo(typeParams(a.inst.deref().decl.deref()), a.typeArgs, a.specImpls);
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

private immutable(Comparison) compareConcreteFunKey(ref immutable ConcreteFunKey a, ref immutable ConcreteFunKey b) {
	// Compare decls, not insts.
	// Two different FunInsts may concretize to the same thing.
	// (e.g. f<?t> and f<bool> if ?t = bool)
	immutable Comparison cmpDecl = comparePtr(a.inst.deref().decl, b.inst.deref().decl);
	if (cmpDecl != Comparison.equal)
		return cmpDecl;
	else {
		immutable Comparison res = compareConcreteTypeArr(a.typeArgs, b.typeArgs);
		return res != Comparison.equal
			? res
			: compareArr!(Ptr!ConcreteFun)(
				a.specImpls,
				b.specImpls,
				(ref immutable Ptr!ConcreteFun x, ref immutable Ptr!ConcreteFun y) =>
					comparePtr(x, y));
	}
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
	immutable ConcreteField[] fields;
}

private struct DeferredUnionBody {
	Ptr!ConcreteStruct struct_;
	immutable Opt!ConcreteType[] members;
}

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	immutable Ptr!FunInst curIslandAndExclusionFun;
	immutable Ptr!StructInst ctxStructInst;
	immutable Ptr!CommonTypes commonTypesPtr;
	immutable Ptr!Program programPtr;
	AllConstantsBuilder allConstants;
	MutDict!(
		immutable ConcreteStructKey,
		immutable Ptr!ConcreteStruct,
		compareConcreteStructKey,
	) nonLambdaConcreteStructs;
	ArrBuilder!(immutable Ptr!ConcreteStruct) allConcreteStructs;
	MutDict!(immutable ConcreteFunKey, immutable Ptr!ConcreteFun, compareConcreteFunKey) nonLambdaConcreteFuns;
	MutArr!DeferredRecordBody deferredRecords;
	MutArr!DeferredUnionBody deferredUnions;
	ArrBuilder!(immutable Ptr!ConcreteFun) allConcreteFuns;
	MutSet!(immutable string, compareStr) allExternLibraryNames;

	// This will only have an entry while a ConcreteFun hasn't had it's body filled in yet.
	MutDict!(
		immutable Ptr!ConcreteFun,
		immutable ConcreteFunBodyInputs,
		comparePtr!ConcreteFun,
	) concreteFunToBodyInputs;
	MutDict!(
		immutable Ptr!ConcreteStruct,
		// Index in this array is the fun ID
		MutArr!(immutable ConcreteLambdaImpl),
		comparePtr!ConcreteStruct
	) funStructToImpls;
	// TODO: do these eagerly
	Late!(immutable ConcreteType) _boolType;
	Late!(immutable ConcreteType) _voidType;
	Late!(immutable ConcreteType) _ctxType;
	Late!(immutable ConcreteType) _strType;
	Late!(immutable ConcreteType) _symType;

	ref immutable(CommonTypes) commonTypes() return scope const {
		return commonTypesPtr.deref();
	}
	ref immutable(Program) program() return scope const {
		return programPtr.deref();
	}
}

immutable(ConcreteType) boolType(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._boolType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.bool_, TypeArgsScope.empty));
}

immutable(ConcreteType) voidType(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._voidType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.void_, TypeArgsScope.empty));
}

immutable(ConcreteType) strType(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._strType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.str, TypeArgsScope.empty));
}

immutable(ConcreteType) symType(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._symType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.sym, TypeArgsScope.empty));
}

immutable(ConcreteType) ctxType(ref Alloc alloc, ref ConcretizeCtx a) {
	immutable ConcreteType res = lazilySet(a._ctxType, () =>
		getConcreteType_forStructInst(alloc, a, a.ctxStructInst, TypeArgsScope.empty));
	verify(res.isPointer);
	return res;
}

immutable(Constant) constantStr(ref Alloc alloc, ref ConcretizeCtx a, immutable string value) {
	immutable ConcreteType strType = strType(alloc, a);
	return getConstantStr(alloc, a.allConstants, mustBeNonPointer(strType).deref(), value);
}

immutable(Constant) constantSym(ref Alloc alloc, ref ConcretizeCtx a, immutable Sym value) {
	return getConstantSym(alloc, a.allConstants, value);
}

immutable(Ptr!ConcreteFun) getOrAddConcreteFunAndFillBody(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	Ptr!ConcreteFun cf = castMutable(getOrAddConcreteFunWithoutFillingBody(alloc, ctx, key));
	fillInConcreteFunBody(alloc, ctx, cf);
	return castImmutable(cf);
}

immutable(Ptr!ConcreteFun) getConcreteFunForLambdaAndFillBody(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun containingConcreteFun,
	immutable size_t index,
	immutable ConcreteType returnType,
	immutable Ptr!ConcreteParam closureParam,
	ref immutable ConcreteParam[] params,
	ref immutable ContainingFunInfo containing,
	ref immutable Expr body_,
) {
	Ptr!ConcreteFun res = allocateMut(alloc, ConcreteFun(
		immutable ConcreteFunSource(
			allocate(alloc, immutable ConcreteFunSource.Lambda(body_.range, containingConcreteFun, index))),
		returnType,
		NeedsCtx.yes,
		some(closureParam),
		params));
	immutable ConcreteFunBodyInputs bodyInputs = immutable ConcreteFunBodyInputs(containing, immutable FunBody(body_));
	addToMutDict(alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	fillInConcreteFunBody(alloc, ctx, res);
	add(alloc, ctx.allConcreteFuns, castImmutable(res));
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) getOrAddNonTemplateConcreteFunAndFillBody(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!FunInst decl,
) {
	immutable ConcreteFunKey key = immutable ConcreteFunKey(decl, emptyArr!ConcreteType, emptyArr!(Ptr!ConcreteFun));
	return getOrAddConcreteFunAndFillBody(alloc, ctx, key);
}

immutable(ConcreteType) getConcreteType_forStructInst(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!StructInst i,
	immutable TypeArgsScope typeArgsScope,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes(alloc, ctx, typeArgs(i.deref()), typeArgsScope);
	if (ptrEquals(i.deref().decl, ctx.commonTypes.byVal))
		return byVal(only(typeArgs));
	else {
		immutable ConcreteStructKey key = ConcreteStructKey(i.deref().decl, typeArgs);
		immutable ValueAndDidAdd!(immutable Ptr!ConcreteStruct) res =
			getOrAddAndDidAdd(alloc, ctx.nonLambdaConcreteStructs, key, () {
				immutable Purity purity = fold(
					i.deref().bestCasePurity,
					typeArgs,
					(immutable Purity p, ref immutable ConcreteType ta) =>
						worsePurity(p, purity(ta)));
				immutable Ptr!ConcreteStruct res = allocate(alloc, immutable ConcreteStruct(
					purity,
					immutable ConcreteStructSource(immutable ConcreteStructSource.Inst(i, key.typeArgs))));
				add(alloc, ctx.allConcreteStructs, res);
				return res;
			});
		if (res.didAdd)
			initializeConcreteStruct(alloc, ctx, typeArgs, i.deref(), castMutable(res.value), typeArgsScope);
		return concreteType_fromStruct(res.value);
	}
}

immutable(ConcreteType) getConcreteType(
	ref Alloc alloc,
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
			return at(typeArgsScope.typeArgs, p.deref().index);
		},
		(immutable Ptr!StructInst i) =>
			getConcreteType_forStructInst(alloc, ctx, i, typeArgsScope));
}

immutable(ConcreteType[]) typesToConcreteTypes(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Type[] types,
	immutable TypeArgsScope typeArgsScope,
) {
	return map!ConcreteType(alloc, types, (ref immutable Type t) =>
		getConcreteType(alloc, ctx, t, typeArgsScope));
}

immutable(ConcreteType) concreteTypeFromClosure(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteField[] closureFields,
	immutable ConcreteStructSource source,
) {
	if (empty(closureFields))
		return voidType(alloc, ctx);
	else {
		immutable Purity purity = fold(
			Purity.data,
			closureFields,
			(immutable Purity p, ref immutable ConcreteField f) {
				// TODO: lambda fields are never mutable, use a different type?
				verify(f.mutability == ConcreteMutability.const_);
				return worsePurity(p, purity(f.type));
			});
		Ptr!ConcreteStruct cs = allocateMut(alloc, ConcreteStruct(purity, source));
		lateSet(cs.deref().info_, getConcreteStructInfoForFields(closureFields));
		setConcreteStructRecordSize(
			alloc, ctx, cs, false, closureFields, false, ForcedByValOrRefOrNone.none, FieldsType.closure);
		add(alloc, ctx.allConcreteStructs, castImmutable(cs));
		// TODO: consider passing closure by value
		return immutable ConcreteType(true, castImmutable(cs));
	}
}

private void setConcreteStructRecordSize(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	Ptr!ConcreteStruct cs,
	immutable bool packed,
	immutable ConcreteField[] fields,
	immutable bool isSelfMutable,
	immutable ForcedByValOrRefOrNone forcedByValOrRef,
	immutable FieldsType fieldsType,
) {
	if (canGetRecordSize(fields)) {
		immutable TypeSizeAndFieldOffsets size = recordSize(alloc, packed, fields);
		lateSetMaybeOverwrite(
			cs.deref().defaultIsPointer_,
			getDefaultIsPointerForFields(forcedByValOrRef, size.typeSize, isSelfMutable, fieldsType));
		lateSet(cs.deref().typeSize_, size.typeSize);
		lateSet(cs.deref().fieldOffsets_, size.fieldOffsets);
	} else {
		push(alloc, ctx.deferredRecords, DeferredRecordBody(cs, packed, fields));
	}
}

//TODO: do eagerly?
immutable(Ptr!ConcreteFun) getCurIslandAndExclusionFun(ref Alloc alloc, ref ConcretizeCtx ctx) {
	return getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, ctx.curIslandAndExclusionFun);
}

private:

immutable(Ptr!ConcreteFun) getOrAddConcreteFunWithoutFillingBody(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	return getOrAdd(alloc, ctx.nonLambdaConcreteFuns, key, () {
		immutable Ptr!ConcreteFun res = getConcreteFunFromKey(alloc, ctx, key);
		add(alloc, ctx.allConcreteFuns, res);
		return res;
	});
}

immutable(Ptr!ConcreteFun) getConcreteFunFromKey(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	immutable Ptr!FunDecl decl = key.inst.deref().decl;
	immutable TypeArgsScope typeScope = typeArgsScope(key);
	immutable ConcreteType returnType = getConcreteType(alloc, ctx, returnType(decl.deref()), typeScope);
	immutable ConcreteParam[] params = concretizeParams(alloc, ctx, paramsArray(params(decl.deref())), typeScope);
	Ptr!ConcreteFun res = allocateMut(alloc, ConcreteFun(
		immutable ConcreteFunSource(key.inst),
		returnType,
		noCtx(decl.deref()) ? NeedsCtx.no : NeedsCtx.yes,
		none!(Ptr!ConcreteParam),
		params));
	immutable ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(
		toContainingFunInfo(key),
		decl.deref().body_);
	addToMutDict(alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) concreteFunForTest(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Test test,
	immutable size_t index,
) {
	Ptr!ConcreteFun res = allocateMut(alloc, ConcreteFun(
		immutable ConcreteFunSource(allocate(alloc, immutable ConcreteFunSource.Test(test.body_.range, index))),
		voidType(alloc, ctx),
		NeedsCtx.yes,
		none!(Ptr!ConcreteParam),
		emptyArr!ConcreteParam));
	immutable ContainingFunInfo containing = immutable ContainingFunInfo(
		emptyArr!TypeParam,
		emptyArr!ConcreteType,
		emptyArr!(Ptr!ConcreteFun));
	immutable ConcreteExpr body_ =
		concretizeExpr(alloc, ctx, containing, castImmutable(res), test.body_);
	lateSet(res.deref()._body_, immutable ConcreteFunBody(immutable ConcreteFunExprBody(body_)));
	add(alloc, ctx.allConcreteFuns, castImmutable(res));
	return castImmutable(res);
}

immutable(Comparison) compareConcreteTypeArr(ref immutable ConcreteType[] a, ref immutable ConcreteType[] b) {
	return compareArr!ConcreteType(a, b, (ref immutable ConcreteType x, ref immutable ConcreteType y) =>
		compareConcreteType(x, y));
}

immutable(bool) canGetUnionSize(ref immutable Opt!ConcreteType[] members) {
	return every!(Opt!ConcreteType)(members, (ref immutable Opt!ConcreteType type) =>
		!has(type) || hasSizeOrPointerSizeBytes(force(type)));
}

immutable(TypeSize) unionSize(ref immutable Opt!ConcreteType[] members) {
	immutable Nat8 unionAlign = immutable Nat8(8);
	immutable Nat16 maxMember = arrMax(immutable Nat16(0), members, (ref immutable Opt!ConcreteType t) =>
		has(t) ? sizeOrPointerSizeBytes(force(t)).size : immutable Nat16(0));
	immutable Nat16 sizeBytes = roundUp(immutable Nat16(8) + maxMember, unionAlign.to16());
	return immutable TypeSize(sizeBytes, unionAlign);
}

immutable(bool) getDefaultIsPointerForFields(
	immutable ForcedByValOrRefOrNone forcedByValOrRef,
	immutable TypeSize typeSize,
	immutable bool isSelfMutable,
	immutable FieldsType type,
) {
	final switch (forcedByValOrRef) {
		case ForcedByValOrRefOrNone.none:
			immutable Nat16 maxSize = () {
				final switch (type) {
					case FieldsType.closure:
						return immutable Nat16(8);
					case FieldsType.record:
						return immutable Nat16(8 * 2);
				}
			}();
			return isSelfMutable || typeSize.size > maxSize;
		case ForcedByValOrRefOrNone.byVal:
			verify(!isSelfMutable);
			return false;
		case ForcedByValOrRefOrNone.byRef:
			return true;
	}
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
	immutable Nat16[] fieldOffsets;
}

immutable(TypeSizeAndFieldOffsets) recordSize(
	ref Alloc alloc,
	immutable bool packed,
	immutable ConcreteField[] fields,
) {
	Nat16 maxFieldSize = immutable Nat16(1);
	Nat8 maxFieldAlignment = immutable Nat8(1);
	Nat16 offset = immutable Nat16(0);
	immutable Nat16[] fieldOffsets = map(alloc, fields, (ref immutable ConcreteField field) {
		immutable TypeSize fieldSize = sizeOrPointerSizeBytes(field.type);
		maxFieldSize = max(maxFieldSize, fieldSize.size);
		if (!packed) {
			maxFieldAlignment = max(maxFieldAlignment, fieldSize.alignment);
			offset = roundUp(offset, fieldSize.alignment.to16());
		}
		immutable Nat16 fieldOffset = offset;
		offset += fieldSize.size;
		return fieldOffset;
	});
	immutable TypeSize typeSize = immutable TypeSize(roundUp(offset, maxFieldAlignment.to16()), maxFieldAlignment);
	return immutable TypeSizeAndFieldOffsets(typeSize, fieldOffsets);
}

void initializeConcreteStruct(
	ref Alloc alloc,
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
			lateSet(res.deref().defaultIsPointer_, false);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Builtin(kind, typeArgs)),
				false));
			lateSet(res.deref().typeSize_, getBuiltinStructSize(kind));
		},
		(ref immutable StructBody.Enum it) {
			lateSet(res.deref().defaultIsPointer_, false);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForEnum(alloc, it)),
				false));
			lateSet(res.deref().typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.Flags it) {
			lateSet(res.deref().defaultIsPointer_, false);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForFlags(alloc, it)),
				false));
			lateSet(res.deref().typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.ExternPtr it) {
			// defaultIsPointer is false because the 'extern' type *is* a pointer
			lateSet(res.deref().defaultIsPointer_, false);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(immutable ConcreteStructBody.ExternPtr()),
				false));
			lateSet(res.deref().typeSize_, getBuiltinStructSize(BuiltinStructKind.ptrMut));
		},
		(ref immutable StructBody.Record r) {
			// Initially make this a by-ref type, so we don't recurse infinitely when computing size
			// TODO: is this a bug? We compute the size based on assuming it's a pointer,
			// then make it not be a pointer and that would change the size?
			// A record forced by-val should be marked early, in case it needs a 'ptr' to itself
			lateSet(res.deref().defaultIsPointer_, r.flags.forcedByValOrRef != ForcedByValOrRefOrNone.byVal);

			immutable ConcreteField[] fields =
				mapPtrsWithIndex!ConcreteField(alloc, r.fields, (immutable size_t index, immutable Ptr!RecordField f) =>
					immutable ConcreteField(
						immutable ConcreteFieldSource(f),
						safeSizeTToU8(index),
						toConcreteMutability(f.deref().mutability),
						getConcreteType(alloc, ctx, f.deref().type, typeArgsScope)));
			immutable bool packed = r.flags.packed;
			immutable ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			lateSet(res.deref().info_, info);
			setConcreteStructRecordSize(
				alloc, ctx, res, packed, fields, info.isSelfMutable, r.flags.forcedByValOrRef, FieldsType.record);
		},
		(ref immutable StructBody.Union u) {
			lateSet(res.deref().defaultIsPointer_, false);
			immutable Opt!ConcreteType[] members = map!(Opt!ConcreteType)(
				alloc,
				u.members,
				(ref immutable UnionMember it) =>
					has(it.type)
						? some(getConcreteType(alloc, ctx, force(it.type), typeArgsScope))
						: none!ConcreteType);
			lateSet(res.deref().info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Union(members)), false));
			if (canGetUnionSize(members))
				lateSet(res.deref().typeSize_, unionSize(members));
			else
				push(alloc, ctx.deferredUnions, DeferredUnionBody(res, members));
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
	immutable ubyte size = sizeForEnumOrFlags(a);
	return immutable TypeSize(immutable Nat16(size), immutable Nat8(size));
}
immutable(ubyte) sizeForEnumOrFlags(immutable EnumBackingType a) {
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
		? immutable ConcreteStructBody.Enum(a.backingType, size(a.members))
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
			member.value.asUnsigned().raw()));
}

public void deferredFillRecordAndUnionBodies(ref Alloc alloc, ref ConcretizeCtx ctx) {
	if (!mutArrIsEmpty(ctx.deferredRecords) || !mutArrIsEmpty(ctx.deferredUnions)) {
		bool couldGetSomething = false;
		filterUnordered!DeferredRecordBody(ctx.deferredRecords, (ref DeferredRecordBody deferred) {
			immutable bool canGet = canGetRecordSize(deferred.fields);
			if (canGet) {
				immutable TypeSizeAndFieldOffsets info = recordSize(alloc, deferred.packed, deferred.fields);
				// NOTE: In the deferred case we don't compute 'defaultIsPointer_';
				// it's already been assumed to be a pointer so we can't change it.
				lateSet(deferred.struct_.deref().typeSize_, info.typeSize);
				lateSet(deferred.struct_.deref().fieldOffsets_, info.fieldOffsets);
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
		deferredFillRecordAndUnionBodies(alloc, ctx);
	}
}

void fillInConcreteFunBody(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	Ptr!ConcreteFun cf,
) {
	// TODO: just assert it's not already set?
	if (!lateIsSet(cf.deref()._body_)) {
		// set to arbitrary temporarily
		lateSet(cf.deref()._body_, immutable ConcreteFunBody(immutable ConcreteFunBody.Extern(false)));
		immutable ConcreteFunBodyInputs inputs = mustDelete(ctx.concreteFunToBodyInputs, castImmutable(cf));
		immutable ConcreteFunBody body_ = matchFunBody!(immutable ConcreteFunBody)(
			inputs.body_,
			(ref immutable FunBody.Builtin) {
				immutable Ptr!FunInst inst = asFunInst(cf.deref().source);
				return symEq(name(inst.deref()), shortSymAlphaLiteral("all-tests"))
					? bodyForAllTests(alloc, ctx, castImmutable(cf).deref().returnType)
					: immutable ConcreteFunBody(immutable ConcreteFunBody.Builtin(typeArgs(inputs)));
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
						return bodyForEnumOrFlagsMembers(alloc, ctx, castImmutable(cf).deref().returnType);
				}
			},
			(ref immutable FunBody.Extern e) {
				if (has(e.libraryName))
					//TODO: don't always copy
					addToMutSetOkIfPresent(alloc, ctx.allExternLibraryNames, copyStr(alloc, force(e.libraryName)));
				return immutable ConcreteFunBody(immutable ConcreteFunBody.Extern(e.isGlobal));
			},
			(ref immutable Expr e) =>
				immutable ConcreteFunBody(immutable ConcreteFunExprBody(
					concretizeExpr(alloc, ctx, inputs.containing, castImmutable(cf), e))),
			(immutable FlagsFunction it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.FlagsFn(
					getAllValue(asFlags(body_(mustBeNonPointer(castImmutable(cf).deref().returnType).deref()))),
					it)),
			(ref immutable FunBody.RecordFieldGet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldGet(it.fieldIndex)),
			(ref immutable FunBody.RecordFieldSet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldSet(it.fieldIndex)));
		lateSetOverwrite(cf.deref()._body_, body_);
	}
}

immutable(ulong) getAllValue(ref immutable ConcreteStructBody.Flags flags) {
	return fold(0, flags.values, (immutable ulong a, ref immutable ulong b) =>
		a | b);
}

immutable(ConcreteFunBody) bodyForEnumOrFlagsMembers(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable ConcreteType returnType,
) {
	immutable Ptr!ConcreteStruct arrayStruct = mustBeNonPointer(returnType);
	immutable ConcreteType elementType = only(asInst(arrayStruct.deref().source).typeArgs); // named<e>
	immutable ConcreteType enumOrFlagsType = only(asInst(mustBeNonPointer(elementType).deref().source).typeArgs);
	immutable Constant[] elements = map!Constant(
		alloc,
		enumOrFlagsMembers(enumOrFlagsType),
		(ref immutable StructBody.Enum.Member member) =>
			immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [
				constantSym(alloc, ctx, member.name),
				immutable Constant(immutable Constant.Integral(member.value.value))]))));
	immutable Constant arr = getConstantArr(alloc, ctx.allConstants, arrayStruct, elements);
	return immutable ConcreteFunBody(immutable ConcreteFunExprBody(
		immutable ConcreteExpr(returnType, FileAndRange.empty, immutable ConcreteExprKind(arr))));
}

immutable(StructBody.Enum.Member[]) enumOrFlagsMembers(immutable ConcreteType type) {
	return matchStructBody!(immutable StructBody.Enum.Member[])(
		body_(decl(asInst(mustBeNonPointer(type).deref().source).inst.deref()).deref()),
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

immutable(ConcreteFunBody) bodyForAllTests(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable ConcreteType returnType,
) {
	immutable Test[] allTests = () {
		ArrBuilder!Test allTestsBuilder;
		foreach (ref immutable Module m; ctx.program.allModules)
			addAll(alloc, allTestsBuilder, m.tests);
		return finishArr(alloc, allTestsBuilder);
	}();
	immutable Constant arr = getConstantArr(
		alloc,
		ctx.allConstants,
		mustBeNonPointer(returnType),
		mapWithIndex(alloc, allTests, (immutable size_t index, ref immutable Test it) =>
			immutable Constant(immutable Constant.FunPtr(concreteFunForTest(alloc, ctx, it, index)))));
	immutable ConcreteExpr body_ = immutable ConcreteExpr(
		returnType,
		FileAndRange.empty,
		immutable ConcreteExprKind(arr));
	return immutable ConcreteFunBody(immutable ConcreteFunExprBody(body_));
}

immutable(ConcreteParam[]) concretizeParams(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Param[] params,
	immutable TypeArgsScope typeArgsScope,
) {
	return mapPtrsWithIndex!ConcreteParam(alloc, params, (immutable size_t index, immutable Ptr!Param p) =>
		immutable ConcreteParam(
			immutable ConcreteParamSource(p),
			some!size_t(index),
			getConcreteType(alloc, ctx, p.deref().type, typeArgsScope)));
}

immutable(BuiltinStructKind) getBuiltinStructKind(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("bool"):
			return BuiltinStructKind.bool_;
		case shortSymAlphaLiteralValue("char"):
			return BuiltinStructKind.char_;
		case shortSymAlphaLiteralValue("float32"):
			return BuiltinStructKind.float32;
		case shortSymAlphaLiteralValue("float64"):
			return BuiltinStructKind.float64;
		case shortSymAlphaLiteralValue("fun0"):
		case shortSymAlphaLiteralValue("fun1"):
		case shortSymAlphaLiteralValue("fun2"):
		case shortSymAlphaLiteralValue("fun3"):
		case shortSymAlphaLiteralValue("fun4"):
		case shortSymAlphaLiteralValue("fun-act0"):
		case shortSymAlphaLiteralValue("fun-act1"):
		case shortSymAlphaLiteralValue("fun-act2"):
		case shortSymAlphaLiteralValue("fun-act3"):
		case shortSymAlphaLiteralValue("fun-act4"):
			return BuiltinStructKind.fun;
		case shortSymAlphaLiteralValue("fun-ptr0"):
		case shortSymAlphaLiteralValue("fun-ptr1"):
		case shortSymAlphaLiteralValue("fun-ptr2"):
		case shortSymAlphaLiteralValue("fun-ptr3"):
		case shortSymAlphaLiteralValue("fun-ptr4"):
		case shortSymAlphaLiteralValue("fun-ptr5"):
		case shortSymAlphaLiteralValue("fun-ptr6"):
			return BuiltinStructKind.funPtrN;
		case shortSymAlphaLiteralValue("int8"):
			return BuiltinStructKind.int8;
		case shortSymAlphaLiteralValue("int16"):
			return BuiltinStructKind.int16;
		case shortSymAlphaLiteralValue("int32"):
			return BuiltinStructKind.int32;
		case shortSymAlphaLiteralValue("int64"):
			return BuiltinStructKind.int64;
		case shortSymAlphaLiteralValue("nat8"):
			return BuiltinStructKind.nat8;
		case shortSymAlphaLiteralValue("nat16"):
			return BuiltinStructKind.nat16;
		case shortSymAlphaLiteralValue("nat32"):
			return BuiltinStructKind.nat32;
		case shortSymAlphaLiteralValue("nat64"):
			return BuiltinStructKind.nat64;
		case shortSymAlphaLiteralValue("const-ptr"):
			return BuiltinStructKind.ptrConst;
		case shortSymAlphaLiteralValue("mut-ptr"):
			return BuiltinStructKind.ptrMut;
		case shortSymAlphaLiteralValue("void"):
			return BuiltinStructKind.void_;
		default:
			return todo!(immutable BuiltinStructKind)("not a builtin struct");
	}
}

immutable(TypeSize) getBuiltinStructSize(immutable BuiltinStructKind kind) {
	final switch (kind) {
		case BuiltinStructKind.void_:
			return immutable TypeSize(immutable Nat16(0), immutable Nat8(1));
		case BuiltinStructKind.bool_:
		case BuiltinStructKind.char_:
		case BuiltinStructKind.int8:
		case BuiltinStructKind.nat8:
			return immutable TypeSize(immutable Nat16(1), immutable Nat8(1));
		case BuiltinStructKind.int16:
		case BuiltinStructKind.nat16:
			return immutable TypeSize(immutable Nat16(2), immutable Nat8(2));
		case BuiltinStructKind.float32:
		case BuiltinStructKind.int32:
		case BuiltinStructKind.nat32:
			return immutable TypeSize(immutable Nat16(4), immutable Nat8(4));
		case BuiltinStructKind.float64:
		case BuiltinStructKind.funPtrN:
		case BuiltinStructKind.int64:
		case BuiltinStructKind.nat64:
		case BuiltinStructKind.ptrConst:
		case BuiltinStructKind.ptrMut:
			return immutable TypeSize(immutable Nat16(8), immutable Nat8(8));
		case BuiltinStructKind.fun:
			return immutable TypeSize(immutable Nat16(16), immutable Nat8(8));
	}
}
