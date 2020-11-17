module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asNonFunPtrType,
	LowExpr,
	LowExprKind,
	LowFunIndex,
	LowLocal,
	LowParamIndex,
	LowType,
	PrimitiveType;
import util.collection.arr : Arr, emptyArr;
import util.memory : allocate, nu;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.types : u8;

immutable LowType boolType = immutable LowType(PrimitiveType.bool_);
immutable LowType charType = immutable LowType(PrimitiveType.char_);
private immutable LowType charPtrType =
	immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&charType)));
immutable LowType charPtrPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&charPtrType)));
immutable LowType int32Type = immutable LowType(PrimitiveType.int32);
immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
private immutable LowType nat8Type = immutable LowType(PrimitiveType.nat8);
immutable LowType anyPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&nat8Type)));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) addPtr(Alloc)(
	ref Alloc alloc,
	ref immutable LowType ptrType,
	ref immutable FileAndRange range,
	ref immutable LowExpr ptr,
	immutable size_t value,
) {
	return immutable LowExpr(
		ptrType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.addPtr,
			allocate(alloc, ptr),
			allocate(alloc, constantNat64(range, value)))));
}

immutable(LowExpr) genDeref(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr ptr,
) {
	return genUnary(alloc, range, asNonFunPtrType(ptr.type).pointee, LowExprKind.SpecialUnary.Kind.deref, ptr);
}

private immutable(LowExpr) genUnary(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType type,
	immutable LowExprKind.SpecialUnary.Kind kind,
	immutable LowExpr arg,
) {
	return immutable LowExpr(
		type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialUnary(kind, allocate(alloc, arg))));
}

immutable(LowExpr) genIf(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr cond,
	immutable LowExpr then,
	immutable LowExpr else_,
) {
	return immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(nu!(LowExprKind.SpecialTrinary)(
			alloc,
			LowExprKind.SpecialTrinary.Kind.if_,
			allocate(alloc, cond),
			allocate(alloc, then),
			allocate(alloc, else_))));
}

immutable(LowExpr) genNat64Eq0(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr a,
) {
	return genBinary(alloc, range, boolType, LowExprKind.SpecialBinary.Kind.eqNat64, a, constantNat64(range, 0));
}

immutable(LowExpr) incrPointer(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowType ptrType,
	ref immutable LowExpr ptr,
) {
	return addPtr(alloc, ptrType, range, ptr, 1);
}

immutable(LowExpr) constantNat64(
	ref immutable FileAndRange range,
	immutable size_t value,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable Constant(immutable Constant.Integral(value))));
}

immutable(LowExpr) genCreateRecord(
	ref immutable FileAndRange range,
	immutable LowType.Record record,
	immutable Arr!LowExpr args,
) {
	return immutable LowExpr(
		immutable LowType(record),
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(args)));
}

immutable(LowExpr) genCreateRecord(ref immutable FileAndRange range, immutable LowType.Record record) {
	return genCreateRecord(range, record, emptyArr!LowExpr);
}

immutable(LowExpr) genCreateUnion(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType.Union union_,
	immutable u8 memberIndex,
	immutable LowExpr member,
) {
	return immutable LowExpr(
		immutable LowType(union_),
		range,
		immutable LowExprKind(immutable LowExprKind.ConvertToUnion(memberIndex, allocate(alloc, member))));
}

immutable(LowExpr) genBinary(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType returnType,
	immutable LowExprKind.SpecialBinary.Kind kind,
	immutable LowExpr a,
	immutable LowExpr b,
) {
	return immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(kind, allocate(alloc, a), allocate(alloc, b))));
}

immutable(LowExpr) decrNat64(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr arg,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.wrapSubNat64,
			allocate(alloc, arg),
			allocate(alloc, constantNat64(range, 1)))));
}

immutable(LowExpr) genCall(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowFunIndex called,
	immutable LowType returnType,
	immutable Arr!LowExpr args,
) {
	return immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(called, args)));
}

immutable(LowExpr) getSizeOf(immutable FileAndRange range, immutable LowType t) {
	return immutable LowExpr(nat64Type, range, immutable LowExprKind(immutable LowExprKind.SizeOf(t)));
}

immutable(LowExpr) localRef(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable Ptr!LowLocal local) {
	return immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalRef(local)));
}

immutable(LowExpr) paramRef(
	ref immutable FileAndRange range,
	ref immutable LowType type,
	immutable LowParamIndex param,
) {
	return immutable LowExpr(
		type,
		range,
		immutable LowExprKind(immutable LowExprKind.ParamRef(param)));
}

immutable(LowExpr) wrapMulNat64(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.wrapMulNat64,
			allocate(alloc, left),
			allocate(alloc, right))));
}

immutable(LowExpr) ptrCast(Alloc)(
	ref Alloc alloc,
	ref immutable LowType type,
	ref immutable FileAndRange range,
	immutable LowExpr inner,
) {
	return immutable LowExpr(type, range, ptrCastKind(alloc, inner));
}

immutable(LowExprKind) ptrCastKind(Alloc)(ref Alloc alloc, immutable LowExpr inner) {
	return immutable LowExprKind(immutable LowExprKind.PtrCast(allocate(alloc, inner)));
}

immutable(LowExpr) recordFieldAccess(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr target,
	immutable LowType fieldType,
	immutable u8 fieldIndex,
) {
	return immutable LowExpr(fieldType, range, immutable LowExprKind(
		immutable LowExprKind.RecordFieldAccess(
			allocate(alloc, target),
			fieldIndex)));
}

immutable(LowExpr) seq(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr first,
	immutable LowExpr then,
) {
	return immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(immutable LowExprKind.Seq(allocate(alloc, first), allocate(alloc, then))));
}

immutable(LowExpr) writeToPtr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr ptr,
	ref immutable LowExpr value,
) {
	return immutable LowExpr(voidType, range, immutable LowExprKind(
		immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.writeToPtr,
			allocate(alloc, ptr),
			allocate(alloc, value))));
}
