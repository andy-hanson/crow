module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantStr, getConstantStrOfSym;
import concretize.concretizeExpr : concretizeExpr;
import model.concreteModel :
	asFunInst,
	asInst,
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
	ConcreteFunSig,
	ConcreteFunSource,
	ConcreteLambdaImpl,
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
	purity,
	sizeOrPointerSizeBytes,
	TypeSize;
import model.constant : Constant;
import model.model :
	asEnum,
	body_,
	CommonTypes,
	decl,
	EnumBackingType,
	EnumFunction,
	Expr,
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
	worsePurity;
import util.collection.arr : at, empty, emptyArr, only, onlyPtr, ptrAt, size, sizeEq;
import util.collection.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.collection.arrUtil :
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
import util.late : Late, lateIsSet, lateSet, lateSetOverwrite, lazilySet;
import util.memory : allocate, nu, nuMut;
import util.opt : force, has, none, some;
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
	return immutable ContainingFunInfo(typeParams(a.inst.decl.deref()), a.typeArgs, a.specImpls);
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
	immutable Comparison cmpDecl = comparePtr(a.inst.decl, b.inst.decl);
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
	immutable ConcreteType[] members;
}

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	immutable Ptr!FunInst curIslandAndExclusionFun;
	immutable Ptr!StructInst ctxStructInst;
	immutable Ptr!CommonTypes commonTypes;
	immutable Ptr!Program program;
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
	Late!(immutable ConcreteType) _charType;
	Late!(immutable ConcreteType) _voidType;
	Late!(immutable ConcreteType) _anyPtrType;
	Late!(immutable ConcreteType) _ctxType;
	Late!(immutable ConcreteType) _strType;
}

immutable(ConcreteType) boolType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._boolType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.bool_, TypeArgsScope.empty));
}

private immutable(ConcreteType) charType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._charType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.char_, TypeArgsScope.empty));
}

immutable(ConcreteType) voidType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._voidType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.void_, TypeArgsScope.empty));
}

immutable(ConcreteType) anyPtrType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._anyPtrType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.anyPtr, TypeArgsScope.empty));
}

immutable(ConcreteType) strType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._strType, () {
		immutable ConcreteType charType = charType(alloc, a);
		return getConcreteType_forStructInst(alloc, a, a.commonTypes.str, TypeArgsScope.empty);
	});
}

immutable(ConcreteType) ctxType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	immutable ConcreteType res = lazilySet(a._ctxType, () =>
		getConcreteType_forStructInst(alloc, a, a.ctxStructInst, TypeArgsScope.empty));
	verify(res.isPointer);
	return res;
}

immutable(Constant) constantStr(Alloc)(ref Alloc alloc, ref ConcretizeCtx a, immutable string value) {
	immutable ConcreteType charType = charType(alloc, a);
	immutable ConcreteType strType = strType(alloc, a);
	immutable Ptr!ConcreteStruct strStruct = mustBeNonPointer(strType);
	return getConstantStr(alloc, a.allConstants, strStruct, charType, value);
}

private immutable(Constant) constantStrOfSym(Alloc)(ref Alloc alloc, ref ConcretizeCtx a, immutable Sym value) {
	immutable ConcreteType charType = charType(alloc, a);
	immutable ConcreteType strType = strType(alloc, a);
	immutable Ptr!ConcreteStruct strStruct = mustBeNonPointer(strType);
	return getConstantStrOfSym(alloc, a.allConstants, strStruct, charType, value);
}

immutable(Ptr!ConcreteFun) getOrAddConcreteFunAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	Ptr!ConcreteFun cf = castMutable(getOrAddConcreteFunWithoutFillingBody(alloc, ctx, key));
	fillInConcreteFunBody(alloc, ctx, cf);
	return castImmutable(cf);
}

immutable(Ptr!ConcreteFun) getConcreteFunForLambdaAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun containingConcreteFun,
	immutable size_t index,
	immutable ConcreteType returnType,
	immutable Ptr!ConcreteParam closureParam,
	ref immutable ConcreteParam[] params,
	ref immutable ContainingFunInfo containing,
	immutable Ptr!Expr body_,
) {
	Ptr!ConcreteFun res = nuMut!ConcreteFun(
		alloc,
		immutable ConcreteFunSource(
			nu!(ConcreteFunSource.Lambda)(alloc, body_.range, containingConcreteFun, index)),
		nu!ConcreteFunSig(alloc, returnType, true, some(closureParam), params));
	immutable ConcreteFunBodyInputs bodyInputs = immutable ConcreteFunBodyInputs(containing, immutable FunBody(body_));
	addToMutDict(alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	fillInConcreteFunBody(alloc, ctx, res);
	add(alloc, ctx.allConcreteFuns, castImmutable(res));
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) getOrAddNonTemplateConcreteFunAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!FunInst decl,
) {
	immutable ConcreteFunKey key = immutable ConcreteFunKey(decl, emptyArr!ConcreteType, emptyArr!(Ptr!ConcreteFun));
	return getOrAddConcreteFunAndFillBody(alloc, ctx, key);
}

immutable(ConcreteType) getConcreteType_forStructInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!StructInst i,
	immutable TypeArgsScope typeArgsScope,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes!Alloc(alloc, ctx, typeArgs(i), typeArgsScope);
	if (ptrEquals(i.decl, ctx.commonTypes.byVal))
		return byVal(only(typeArgs));
	else {
		immutable ConcreteStructKey key = ConcreteStructKey(i.decl, typeArgs);
		immutable ValueAndDidAdd!(immutable Ptr!ConcreteStruct) res =
			getOrAddAndDidAdd(alloc, ctx.nonLambdaConcreteStructs, key, () {
				immutable Purity purity = fold(
					i.bestCasePurity,
					typeArgs,
					(ref immutable Purity p, ref immutable ConcreteType ta) =>
						worsePurity(p, purity(ta)));
				immutable Ptr!ConcreteStruct res = nu!ConcreteStruct(
					alloc,
					purity,
					immutable ConcreteStructSource(immutable ConcreteStructSource.Inst(i, key.typeArgs)));
				add(alloc, ctx.allConcreteStructs, res);
				return res;
			});
		if (res.didAdd)
			initializeConcreteStruct!Alloc(alloc, ctx, typeArgs, i, castMutable(res.value), typeArgsScope);
		return concreteType_fromStruct(res.value);
	}
}

immutable(ConcreteType) getConcreteType(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Type t,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return matchType!(immutable ConcreteType)(
		t,
		(ref immutable Type.Bogus) =>
			unreachable!(immutable ConcreteType),
		(immutable Ptr!TypeParam p) {
			// Handle calledConcreteFun first
			verify(ptrEquals(p, ptrAt(typeArgsScope.typeParams, p.index)));
			return at(typeArgsScope.typeArgs, p.index);
		},
		(immutable Ptr!StructInst i) =>
			getConcreteType_forStructInst!Alloc(alloc, ctx, i, typeArgsScope));
}

immutable(ConcreteType[]) typesToConcreteTypes(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Type[] types,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return map!ConcreteType(alloc, types, (ref immutable Type t) =>
		getConcreteType(alloc, ctx, t, typeArgsScope));
}

immutable(ConcreteType) concreteTypeFromClosure(Alloc)(
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
			(ref immutable Purity p, ref immutable ConcreteField f) {
				verify(!f.isMutable); // TODO: lambda fields are never mutable, use a different type?
				return worsePurity(p, purity(f.type));
			});
		Ptr!ConcreteStruct cs = nuMut!ConcreteStruct(alloc, purity, source);
		lateSet(cs.info_, getConcreteStructInfoForFields(closureFields));
		immutable TypeSizeAndFieldOffsets size = recordSize(alloc, false, closureFields);
		lateSet(
			cs.defaultIsPointer_,
			getDefaultIsPointerForFields(ForcedByValOrRefOrNone.none, size.typeSize, false, FieldsType.closure));
		lateSet(cs.typeSize_, size.typeSize);
		lateSet(cs.fieldOffsets_, size.fieldOffsets);
		add(alloc, ctx.allConcreteStructs, castImmutable(cs));
		// TODO: consider passing closure by value
		return immutable ConcreteType(true, castImmutable(cs));
	}
}

//TODO: do eagerly?
immutable(Ptr!ConcreteFun) getCurIslandAndExclusionFun(Alloc)(ref Alloc alloc, ref ConcretizeCtx ctx) {
	return getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, ctx.curIslandAndExclusionFun);
}

private:

immutable(Ptr!ConcreteFun) getOrAddConcreteFunWithoutFillingBody(Alloc)(
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

immutable(Ptr!ConcreteFun) getConcreteFunFromKey(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	immutable Ptr!FunDecl decl = key.inst.decl;
	immutable TypeArgsScope typeScope = typeArgsScope(key);
	immutable ConcreteType returnType = getConcreteType(alloc, ctx, returnType(decl), typeScope);
	immutable ConcreteParam[] params = concretizeParams(alloc, ctx, params(decl), typeScope);
	Ptr!ConcreteFun res = nuMut!ConcreteFun(
		alloc,
		immutable ConcreteFunSource(key.inst),
		nu!ConcreteFunSig(alloc, returnType, !noCtx(decl), none!(Ptr!ConcreteParam), params));
	immutable ConcreteFunBodyInputs bodyInputs = ConcreteFunBodyInputs(
		toContainingFunInfo(key),
		decl.body_);
	addToMutDict(alloc, ctx.concreteFunToBodyInputs, castImmutable(res), bodyInputs);
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) concreteFunForTest(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Test test,
	immutable size_t index,
) {
	Ptr!ConcreteFun res = nuMut!ConcreteFun(
		alloc,
		immutable ConcreteFunSource(nu!(ConcreteFunSource.Test)(alloc, test.body_.range, index)),
		nu!ConcreteFunSig(alloc, voidType(alloc, ctx), true, none!(Ptr!ConcreteParam), emptyArr!ConcreteParam));
	immutable ContainingFunInfo containing = immutable ContainingFunInfo(
		emptyArr!TypeParam,
		emptyArr!ConcreteType,
		emptyArr!(Ptr!ConcreteFun));
	immutable ConcreteExpr body_ =
		concretizeExpr!Alloc(alloc, ctx, containing, castImmutable(res), test.body_);
	lateSet(res._body_, nu!ConcreteFunBody(alloc, immutable ConcreteFunExprBody(body_)));
	add(alloc, ctx.allConcreteFuns, castImmutable(res));
	return castImmutable(res);
}

immutable(Comparison) compareConcreteTypeArr(ref immutable ConcreteType[] a, ref immutable ConcreteType[] b) {
	return compareArr!ConcreteType(a, b, (ref immutable ConcreteType x, ref immutable ConcreteType y) =>
		compareConcreteType(x, y));
}

immutable(bool) canGetUnionSize(ref immutable ConcreteType[] members) {
	return every!ConcreteType(members, (ref immutable ConcreteType type) =>
		hasSizeOrPointerSizeBytes(type));
}

immutable(TypeSize) unionSize(ref immutable ConcreteType[] members) {
	immutable Nat8 unionAlign = immutable Nat8(8);
	immutable Nat16 maxMember = arrMax(
		immutable Nat16(0),
		members,
		(ref immutable ConcreteType t) => sizeOrPointerSizeBytes(t).size);
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
		exists!ConcreteField(fields, (ref immutable ConcreteField field) => field.isMutable));
}

struct TypeSizeAndFieldOffsets {
	immutable TypeSize typeSize;
	immutable Nat16[] fieldOffsets;
}

immutable(TypeSizeAndFieldOffsets) recordSize(Alloc)(
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

void initializeConcreteStruct(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteType[] typeArgs,
	immutable Ptr!StructInst i,
	Ptr!ConcreteStruct res,
	ref immutable TypeArgsScope typeArgsScope,
) {
	matchStructBody!void(
		body_(i),
		(ref immutable StructBody.Bogus) => unreachable!void,
		(ref immutable StructBody.Builtin) {
			immutable BuiltinStructKind kind = getBuiltinStructKind(i.decl.name);
			lateSet(res.defaultIsPointer_, false);
			lateSet(res.info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Builtin(kind, typeArgs)),
				false));
			lateSet(res.typeSize_, getBuiltinStructSize(kind));
		},
		(ref immutable StructBody.Enum it) {
			lateSet(res.defaultIsPointer_, false);
			lateSet(res.info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForEnum(alloc, it)),
				false));
			lateSet(res.typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.Flags it) {
			lateSet(res.defaultIsPointer_, false);
			lateSet(res.info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(getConcreteStructBodyForFlags(alloc, it)),
				false));
			lateSet(res.typeSize_, typeSizeForEnumOrFlags(it.backingType));
		},
		(ref immutable StructBody.ExternPtr it) {
			// defaultIsPointer is false because the 'extern' type *is* a pointer
			lateSet(res.defaultIsPointer_, false);
			lateSet(res.info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(immutable ConcreteStructBody.ExternPtr()),
				false));
			lateSet(res.typeSize_, getBuiltinStructSize(BuiltinStructKind.ptr));
		},
		(ref immutable StructBody.Record r) {
			// Initially make this a by-ref type, so we don't recurse infinitely when computing size
			// TODO: is this a bug? We compute the size based on assuming it's a pointer,
			// then make it not be a pointer and that would change the size?
			// A record forced by-val should be marked early, in case it needs a 'ptr' to itself
			lateSet(res.defaultIsPointer_, r.flags.forcedByValOrRef != ForcedByValOrRefOrNone.byVal);

			immutable ConcreteField[] fields =
				mapPtrsWithIndex!ConcreteField(alloc, r.fields, (immutable size_t index, immutable Ptr!RecordField f) =>
					immutable ConcreteField(
						immutable ConcreteFieldSource(f),
						safeSizeTToU8(index),
						f.isMutable,
						getConcreteType(alloc, ctx, f.type, typeArgsScope)));
			immutable bool packed = r.flags.packed;
			immutable ConcreteStructInfo info = getConcreteStructInfoForFields(fields);
			lateSet(res.info_, info);
			if (canGetRecordSize(fields)) {
				immutable TypeSizeAndFieldOffsets size = recordSize(alloc, packed, fields);
				lateSetOverwrite(res.defaultIsPointer_, getDefaultIsPointerForFields(
					r.flags.forcedByValOrRef,
					size.typeSize,
					info.isSelfMutable,
					FieldsType.record));
				lateSet(res.typeSize_, size.typeSize);
				lateSet(res.fieldOffsets_, size.fieldOffsets);
			} else {
				push(alloc, ctx.deferredRecords, DeferredRecordBody(res, packed, fields));
			}
		},
		(ref immutable StructBody.Union u) {
			lateSet(res.defaultIsPointer_, false);
			immutable ConcreteType[] members = map!ConcreteType(alloc, u.members, (ref immutable Ptr!StructInst si) =>
				getConcreteType_forStructInst(alloc, ctx, si, typeArgsScope));
			lateSet(res.info_, immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Union(members)), false));
			if (canGetUnionSize(members))
				lateSet(res.typeSize_, unionSize(members));
			else
				push(alloc, ctx.deferredUnions, DeferredUnionBody(res, members));
		});
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

immutable(ConcreteStructBody.Enum) getConcreteStructBodyForEnum(Alloc)(
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

immutable(ConcreteStructBody.Flags) getConcreteStructBodyForFlags(Alloc)(
	ref Alloc alloc,
	ref immutable StructBody.Flags a,
) {
	return immutable ConcreteStructBody.Flags(
		a.backingType,
		map(alloc, a.members, (ref immutable StructBody.Enum.Member member) =>
			member.value));
}

public void deferredFillRecordAndUnionBodies(Alloc)(ref Alloc alloc, ref ConcretizeCtx ctx) {
	if (!mutArrIsEmpty(ctx.deferredRecords) || !mutArrIsEmpty(ctx.deferredUnions)) {
		bool couldGetSomething = false;
		filterUnordered!DeferredRecordBody(ctx.deferredRecords, (ref DeferredRecordBody deferred) {
			immutable bool canGet = canGetRecordSize(deferred.fields);
			if (canGet) {
				immutable TypeSizeAndFieldOffsets info = recordSize(alloc, deferred.packed, deferred.fields);
				// NOTE: In the deferred case we don't compute 'defaultIsPointer_';
				// it's already been assumed to be a pointer so we can't change it.
				lateSet(deferred.struct_.typeSize_, info.typeSize);
				lateSet(deferred.struct_.fieldOffsets_, info.fieldOffsets);
				couldGetSomething = true;
			}
			return !canGet;
		});
		filterUnordered!DeferredUnionBody(ctx.deferredUnions, (ref DeferredUnionBody deferred) {
			immutable bool canGet = canGetUnionSize(deferred.members);
			if (canGet) {
				lateSet(deferred.struct_.typeSize_, unionSize(deferred.members));
				couldGetSomething = true;
			}
			return !canGet;
		});
		verify(couldGetSomething);
		deferredFillRecordAndUnionBodies(alloc, ctx);
	}
}

void fillInConcreteFunBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	Ptr!ConcreteFun cf,
) {
	// TODO: just assert it's not already set?
	if (!lateIsSet(cf._body_)) {
		// set to arbitrary temporarily
		lateSet(cf._body_, nu!ConcreteFunBody(alloc, immutable ConcreteFunBody.Extern(false)));
		immutable ConcreteFunBodyInputs inputs = mustDelete(ctx.concreteFunToBodyInputs, castImmutable(cf));
		immutable ConcreteFunBody body_ = matchFunBody!(immutable ConcreteFunBody)(
			inputs.body_,
			(ref immutable FunBody.Builtin) {
				immutable Ptr!FunInst inst = asFunInst(cf.source);
				return symEq(name(inst), shortSymAlphaLiteral("all-tests"))
					? bodyForAllTests!Alloc(alloc, ctx, castImmutable(cf).returnType())
					: immutable ConcreteFunBody(immutable ConcreteFunBody.Builtin(typeArgs(inputs)));
			},
			(ref immutable FunBody.CreateEnum it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.CreateEnum(it.value)),
			(ref immutable FunBody.CreateRecord) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.CreateRecord()),
			(immutable EnumFunction it) =>
				immutable ConcreteFunBody(it),
			(ref immutable FunBody.EnumToStr) =>
				bodyForEnumToStr(alloc, ctx, castImmutable(cf)),
			(ref immutable FunBody.Extern e) {
				if (has(e.libraryName))
					//TODO: don't always copy
					addToMutSetOkIfPresent(alloc, ctx.allExternLibraryNames, copyStr(alloc, force(e.libraryName)));
				return immutable ConcreteFunBody(immutable ConcreteFunBody.Extern(e.isGlobal));
			},
			(immutable Ptr!Expr e) =>
				immutable ConcreteFunBody(immutable ConcreteFunExprBody(
					allocate(
						alloc,
						concretizeExpr(alloc, ctx, inputs.containing, castImmutable(cf), e.deref)))),
			(ref immutable FunBody.RecordFieldGet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldGet(it.fieldIndex)),
			(ref immutable FunBody.RecordFieldSet it) =>
				immutable ConcreteFunBody(immutable ConcreteFunBody.RecordFieldSet(it.fieldIndex)));
		lateSetOverwrite(cf._body_, allocate(alloc, body_));
	}
}

immutable(ConcreteFunBody) bodyForEnumToStr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteFun cf,
) {
	immutable ConcreteType strType = cf.returnType;
	immutable Ptr!ConcreteParam param = onlyPtr(cf.paramsExcludingCtxAndClosure);
	immutable ConcreteType enumType = param.type;
	immutable ConcreteExpr[] cases = map!(ConcreteExpr, StructBody.Enum.Member, Alloc)(
		alloc,
		asEnum(body_(decl(asInst(mustBeNonPointer(enumType).source).inst).deref())).members,
		(ref immutable StructBody.Enum.Member member) =>
			immutable ConcreteExpr(
				strType,
				FileAndRange.empty,
				immutable ConcreteExprKind(constantStrOfSym(alloc, ctx, member.name))));
	immutable ConcreteExpr matchedValue = immutable ConcreteExpr(
		enumType,
		FileAndRange.empty,
		immutable ConcreteExprKind(immutable ConcreteExprKind.ParamRef(param)));
	immutable ConcreteExpr body_ = immutable ConcreteExpr(
		strType,
		FileAndRange.empty,
		immutable ConcreteExprKind(immutable ConcreteExprKind.MatchEnum(allocate(alloc, matchedValue), cases)));
	return immutable ConcreteFunBody(immutable ConcreteFunExprBody(allocate(alloc, body_)));
}

immutable(ConcreteFunBody) bodyForAllTests(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable ConcreteType returnType,
) {
	ArrBuilder!Test allTestsBuilder;
	foreach (immutable Ptr!Module m; ctx.program.allModules)
		addAll(alloc, allTestsBuilder, m.tests);
	immutable Test[] allTests = finishArr(alloc, allTestsBuilder);

	immutable Ptr!ConcreteFun[] funs = mapWithIndex(
		alloc,
		allTests,
		(immutable size_t index, ref immutable Test it) =>
			concreteFunForTest(alloc, ctx, it, index));
	immutable Ptr!ConcreteStruct arrType = mustBeNonPointer(returnType);
	immutable ConcreteType elementType = elementTypeFromArrType(arrType);

	immutable ConcreteExpr[] args = map(alloc, funs, (ref immutable Ptr!ConcreteFun it) =>
		immutable ConcreteExpr(
			elementType,
			FileAndRange.empty,
			immutable ConcreteExprKind(immutable ConcreteExprKind.LambdaFunPtr(it))));

	immutable ConcreteExpr body_ = immutable ConcreteExpr(
		returnType,
		FileAndRange.empty,
		immutable ConcreteExprKind(nu!(ConcreteExprKind.CreateArr)(alloc, arrType, elementType, args)));
	return immutable ConcreteFunBody(immutable ConcreteFunExprBody(allocate(alloc, body_)));
}

immutable(ConcreteType) elementTypeFromArrType(ref immutable ConcreteStruct arrType) {
	return only(asInst(arrType.source).typeArgs);
}

immutable(ConcreteParam[]) concretizeParams(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Param[] params,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return mapPtrsWithIndex!ConcreteParam(alloc, params, (immutable size_t index, immutable Ptr!Param p) =>
		immutable ConcreteParam(
			immutable ConcreteParamSource(p),
			some!size_t(index),
			getConcreteType(alloc, ctx, p.type, typeArgsScope)));
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
		case shortSymAlphaLiteralValue("ptr"):
			return BuiltinStructKind.ptr;
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
		case BuiltinStructKind.ptr:
			return immutable TypeSize(immutable Nat16(8), immutable Nat8(8));
		case BuiltinStructKind.fun:
			return immutable TypeSize(immutable Nat16(16), immutable Nat8(8));
	}
}
