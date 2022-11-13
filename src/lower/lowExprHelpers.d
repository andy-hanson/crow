module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asGcOrRawPointee,
	asPrimitive,
	AllLowTypes,
	asPtrRawConst,
	debugName,
	LowExpr,
	LowExprKind,
	LowFunIndex,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowRecord,
	LowType,
	PrimitiveType,
	UpdateParam;
import util.alloc.alloc : Alloc;
import util.memory : allocate;
import util.sourceRange : FileAndRange;
import util.sym : shortSym, Sym, sym;
import util.util : unreachable, verify;

immutable LowType boolType = immutable LowType(PrimitiveType.bool_);
immutable LowType char8Type = immutable LowType(PrimitiveType.char8);
private immutable LowType char8PtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(&char8Type));
immutable LowType char8PtrPtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(&char8PtrConstType));
immutable LowType float32Type = immutable LowType(PrimitiveType.float32);
immutable LowType float64Type = immutable LowType(PrimitiveType.float64);
immutable LowType int8Type = immutable LowType(PrimitiveType.int8);
immutable LowType int16Type = immutable LowType(PrimitiveType.int16);
immutable LowType int32Type = immutable LowType(PrimitiveType.int32);
immutable LowType int64Type = immutable LowType(PrimitiveType.int64);
immutable LowType nat8Type = immutable LowType(PrimitiveType.nat8);
immutable LowType nat16Type = immutable LowType(PrimitiveType.nat16);
immutable LowType nat32Type = immutable LowType(PrimitiveType.nat32);
immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
private immutable LowType anyPtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(&nat8Type));
immutable LowType anyPtrMutType = immutable LowType(immutable LowType.PtrRawMut(&nat8Type));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) genAddPtr(
	ref Alloc alloc,
	immutable LowType.PtrRawConst ptrType,
	immutable FileAndRange range,
	immutable LowExpr ptr,
	immutable LowExpr added,
) =>
	immutable LowExpr(
		immutable LowType(ptrType),
		range,
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.addPtrAndNat64,
			ptr,
			added))));

immutable(LowExpr) genAsAnyPtrConst(ref Alloc alloc, immutable FileAndRange range, ref immutable LowExpr a) =>
	immutable LowExpr(
		anyPtrConstType,
		range,
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.SpecialUnary(
			LowExprKind.SpecialUnary.Kind.asAnyPtr,
			a))));

immutable(LowExpr) genDrop(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable LowExpr a,
	immutable size_t localIndex,
) {
	// TODO: less hacky way?
	return immutable LowExpr(
		voidType,
		range,
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.Let(
			genLocal(alloc, shortSym("dropped"), localIndex, a.type),
			a,
			genVoid(range)))));
}

private immutable(LowExpr) genDerefGcOrRawPtr(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowExpr ptr,
) =>
	genUnary(alloc, range, asGcOrRawPointee(ptr.type), LowExprKind.SpecialUnary.Kind.deref, ptr);

immutable(LowExpr) genDerefGcPtr(ref Alloc alloc, immutable FileAndRange range, immutable LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, range, ptr);

immutable(LowExprKind) genDerefGcPtr(ref Alloc alloc, immutable LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, immutable FileAndRange(), ptr).kind;

immutable(LowExpr) genDerefRawPtr(ref Alloc alloc, immutable FileAndRange range, immutable LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, range, ptr);

private immutable(LowExpr) genUnary(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowType type,
	immutable LowExprKind.SpecialUnary.Kind kind,
	immutable LowExpr arg,
) =>
	immutable LowExpr(
		type,
		range,
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.SpecialUnary(kind, arg))));

immutable(LowExpr) genIf(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowExpr cond,
	immutable LowExpr then,
	immutable LowExpr else_,
) =>
	immutable LowExpr(then.type, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.If(cond, then, else_))));

immutable(LowExpr) genIncrPointer(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowType.PtrRawConst ptrType,
	ref immutable LowExpr ptr,
) =>
	genAddPtr(alloc, ptrType, range, ptr, genConstantNat64(range, 1));

immutable(LowExpr) genConstantNat64(immutable FileAndRange range, immutable ulong value) =>
	immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable Constant(immutable Constant.Integral(value))));

immutable(LowExpr) genTailRecur(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowType returnType,
	immutable UpdateParam[] updateParams,
) =>
	immutable LowExpr(returnType, range, immutable LowExprKind(immutable LowExprKind.TailRecur(updateParams)));

immutable(LowExpr) genCall(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowFunIndex called,
	immutable LowType returnType,
	immutable LowExpr[] args,
) =>
	immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(called, args)));

immutable(LowExpr) genSizeOf(immutable FileAndRange range, immutable LowType t) =>
	immutable LowExpr(nat64Type, range, immutable LowExprKind(immutable LowExprKind.SizeOf(t)));

immutable(LowExpr) genLocalGet(ref Alloc alloc, immutable FileAndRange range, immutable LowLocal* local) =>
	immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalGet(local)));

immutable(LowParam) genParam(immutable Sym name, immutable LowType type) =>
	immutable LowParam(
		immutable LowParamSource(immutable LowParamSource.Generated(name)),
		type);

immutable(LowExpr) genParamGet(
	immutable FileAndRange range,
	immutable LowType type,
	immutable LowParamIndex param,
) =>
	immutable LowExpr(
		type,
		range,
		immutable LowExprKind(immutable LowExprKind.ParamGet(param)));

immutable(LowExpr) genWrapMulNat64(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowExpr left,
	immutable LowExpr right,
) =>
	immutable LowExpr(nat64Type, range, immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.wrapMulNat64, left, right))));

immutable(LowExpr) genPtrEq(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) =>
	immutable LowExpr(boolType, range, immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.eqPtr, a, b))));

immutable(LowExprKind) genEnumEq(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(eqForType(asPrimitive(a.type)), a, b)));
}

immutable(LowExprKind) genBitwiseNegate(ref Alloc alloc, immutable LowExpr a) =>
	immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialUnary(bitwiseNegateForType(asPrimitive(a.type)), a)));

immutable(LowExprKind) genEnumIntersect(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(intersectForType(asPrimitive(a.type)), a, b)));
}

immutable(LowExprKind) genEnumUnion(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(unionForType(asPrimitive(a.type)), a, b)));
}

private immutable(LowExprKind.SpecialUnary.Kind) bitwiseNegateForType(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			return unreachable!(LowExprKind.SpecialUnary.Kind);
		case PrimitiveType.nat8:
			return LowExprKind.SpecialUnary.Kind.bitwiseNotNat8;
		case PrimitiveType.nat16:
			return LowExprKind.SpecialUnary.Kind.bitwiseNotNat16;
		case PrimitiveType.nat32:
			return LowExprKind.SpecialUnary.Kind.bitwiseNotNat32;
		case PrimitiveType.nat64:
			return LowExprKind.SpecialUnary.Kind.bitwiseNotNat64;
	}
}

private immutable(LowExprKind.SpecialBinary.Kind) eqForType(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!(LowExprKind.SpecialBinary.Kind);
		case PrimitiveType.int8:
			return LowExprKind.SpecialBinary.Kind.eqInt8;
		case PrimitiveType.int16:
			return LowExprKind.SpecialBinary.Kind.eqInt16;
		case PrimitiveType.int32:
			return LowExprKind.SpecialBinary.Kind.eqInt32;
		case PrimitiveType.int64:
			return LowExprKind.SpecialBinary.Kind.eqInt64;
		case PrimitiveType.nat8:
			return LowExprKind.SpecialBinary.Kind.eqNat8;
		case PrimitiveType.nat16:
			return LowExprKind.SpecialBinary.Kind.eqNat16;
		case PrimitiveType.nat32:
			return LowExprKind.SpecialBinary.Kind.eqNat32;
		case PrimitiveType.nat64:
			return LowExprKind.SpecialBinary.Kind.eqNat64;
	}
}

private immutable(LowExprKind.SpecialBinary.Kind) intersectForType(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!(LowExprKind.SpecialBinary.Kind);
		case PrimitiveType.int8:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndInt8;
		case PrimitiveType.int16:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndInt16;
		case PrimitiveType.int32:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndInt32;
		case PrimitiveType.int64:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndInt64;
		case PrimitiveType.nat8:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndNat8;
		case PrimitiveType.nat16:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndNat16;
		case PrimitiveType.nat32:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndNat32;
		case PrimitiveType.nat64:
			return LowExprKind.SpecialBinary.Kind.bitwiseAndNat64;
	}
}

private immutable(LowExprKind.SpecialBinary.Kind) unionForType(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			return unreachable!(LowExprKind.SpecialBinary.Kind);
		case PrimitiveType.int8:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrInt8;
		case PrimitiveType.int16:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrInt16;
		case PrimitiveType.int32:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrInt32;
		case PrimitiveType.int64:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrInt64;
		case PrimitiveType.nat8:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrNat8;
		case PrimitiveType.nat16:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrNat16;
		case PrimitiveType.nat32:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrNat32;
		case PrimitiveType.nat64:
			return LowExprKind.SpecialBinary.Kind.bitwiseOrNat64;
	}
}

immutable(LowExprKind) genEnumToIntegral(ref Alloc alloc, immutable LowExpr inner) =>
	immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.SpecialUnary(LowExprKind.SpecialUnary.Kind.enumToIntegral, inner)));

immutable(LowExpr) genPtrCast(
	ref Alloc alloc,
	immutable LowType type,
	immutable FileAndRange range,
	immutable LowExpr inner,
) =>
	immutable LowExpr(type, range, genPtrCastKind(alloc, inner));

immutable(LowExprKind) genPtrCastKind(ref Alloc alloc, immutable LowExpr inner) =>
	immutable LowExprKind(allocate(alloc, immutable LowExprKind.PtrCast(inner)));

immutable(LowExpr) genRecordFieldGet(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable LowExpr target,
	immutable LowType fieldType,
	immutable size_t fieldIndex,
) =>
	immutable LowExpr(fieldType, range, immutable LowExprKind(
		allocate(alloc, immutable LowExprKind.RecordFieldGet(target, fieldIndex))));

immutable(LowExpr) genSeq(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowExpr first,
	immutable LowExpr then,
) =>
	immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(allocate(alloc, immutable LowExprKind.Seq(first, then))));

immutable(LowExpr) genWriteToPtr(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable LowExpr ptr,
	immutable LowExpr value,
) =>
	immutable LowExpr(voidType, range, genWriteToPtr(alloc, ptr, value));
immutable(LowExprKind) genWriteToPtr(ref Alloc alloc, immutable LowExpr ptr, immutable LowExpr value) =>
	immutable LowExprKind(allocate(
		alloc,
		immutable LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.writeToPtr, ptr, value)));

immutable(LowExpr) genVoid(immutable FileAndRange source) =>
	immutable LowExpr(voidType, source, immutable LowExprKind(immutable Constant(immutable Constant.Void())));

immutable(LowLocal*) genLocal(
	ref Alloc alloc,
	immutable Sym name,
	immutable size_t index,
	immutable LowType type,
) =>
	allocate(alloc, immutable LowLocal(
		immutable LowLocalSource(immutable LowLocalSource.Generated(name, index)),
		type));

immutable(LowExpr) genGetArrSize(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable LowExpr arr,
) =>
	genRecordFieldGet(alloc, range, arr, nat64Type, 0);

immutable(LowExpr) genGetArrData(
	ref Alloc alloc,
	immutable FileAndRange range,
	ref immutable LowExpr arr,
	immutable LowType.PtrRawConst elementPtrType,
) =>
	genRecordFieldGet(alloc, range, arr, immutable LowType(elementPtrType), 1);

immutable(LowType.PtrRawConst) getElementPtrTypeFromArrType(
	ref immutable AllLowTypes allTypes,
	immutable LowType.Record arrType,
) {
	immutable LowRecord arrRecord = allTypes.allRecords[arrType];
	verify(arrRecord.fields.length == 2);
	verify(debugName(arrRecord.fields[0]) == shortSym("size"));
	verify(debugName(arrRecord.fields[1]) == sym!"begin-pointer");
	return asPtrRawConst(arrRecord.fields[1].type);
}
