module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import lowModel : LowExpr, LowExprKind, LowLocal, LowParam, LowType, PrimitiveType;
import util.memory : allocate;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;

immutable LowType byteType = immutable LowType(PrimitiveType.byte_);
immutable LowType charType = immutable LowType(PrimitiveType.char_);
immutable LowType charPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&charType)));
immutable LowType charPtrPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&charPtrType)));
immutable LowType int32Type = immutable LowType(PrimitiveType.int32);
immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
immutable LowType anyPtrType = immutable LowType(immutable LowType.NonFunPtr(immutable Ptr!LowType(&byteType)));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) addPtr(Alloc)(
	ref Alloc alloc,
	ref immutable LowType ptrType,
	ref immutable SourceRange range,
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

immutable(LowExpr) constantNat64(
	ref immutable SourceRange range,
	immutable size_t value,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialConstant(
			immutable LowExprKind.SpecialConstant.Integral(value))));
}

immutable(LowExpr) getSizeOf(immutable SourceRange range, immutable LowType t) {
	return immutable LowExpr(nat64Type, range, immutable LowExprKind(immutable LowExprKind.SizeOf(t)));
}

immutable(LowExpr) localRef(Alloc)(ref Alloc alloc, ref immutable SourceRange range, immutable Ptr!LowLocal local) {
	return immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalRef(local)));
}

immutable(LowExpr) paramRef(ref immutable SourceRange range, immutable Ptr!LowParam param) {
	return immutable LowExpr(param.type, range, immutable LowExprKind(immutable LowExprKind.ParamRef(param)));
}

immutable(LowExpr) mulNat64(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable LowExpr left,
	ref immutable LowExpr right,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.mulNat64,
			allocate(alloc, left),
			allocate(alloc, right))));
}

immutable(LowExpr) ptrCast(Alloc)(
	ref Alloc alloc,
	ref immutable LowType type,
	ref immutable SourceRange range,
	immutable LowExpr inner,
) {
	return immutable LowExpr(type, range, ptrCastKind(alloc, inner));
}

immutable(LowExprKind) ptrCastKind(Alloc)(ref Alloc alloc, immutable LowExpr inner) {
	return immutable LowExprKind(immutable LowExprKind.PtrCast(allocate(alloc, inner)));
}

immutable(LowExpr) seq(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
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
	ref immutable SourceRange range,
	ref immutable LowExpr ptr,
	ref immutable LowExpr value,
) {
	return immutable LowExpr(voidType, range, immutable LowExprKind(
		immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.writeToPtr,
			allocate(alloc, ptr),
			allocate(alloc, value))));
}
