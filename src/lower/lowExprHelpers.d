module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asGcOrRawPointee,
	asPrimitive,
	AllLowTypes,
	asPtrRawConst,
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
	name,
	PrimitiveType;
import util.collection.arr : at, size;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate, nu;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.util : unreachable, verify;

immutable LowType boolType = immutable LowType(PrimitiveType.bool_);
private immutable LowType charType = immutable LowType(PrimitiveType.char_);
private immutable LowType charPtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(immutable Ptr!LowType(&charType)));
immutable LowType charPtrPtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(immutable Ptr!LowType(&charPtrConstType)));
immutable LowType int32Type = immutable LowType(PrimitiveType.int32);
immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
private immutable LowType nat8Type = immutable LowType(PrimitiveType.nat8);
private immutable LowType anyPtrConstType =
	immutable LowType(immutable LowType.PtrRawConst(immutable Ptr!LowType(&nat8Type)));
immutable LowType anyPtrMutType = immutable LowType(immutable LowType.PtrRawMut(immutable Ptr!LowType(&nat8Type)));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) genAddPtr(Alloc)(
	ref Alloc alloc,
	immutable LowType.PtrRawConst ptrType,
	ref immutable FileAndRange range,
	immutable LowExpr ptr,
	immutable LowExpr added,
) {
	return immutable LowExpr(
		immutable LowType(ptrType),
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.addPtr,
			allocate(alloc, ptr),
			allocate(alloc, added))));
}

immutable(LowExpr) genAsAnyPtrConst(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, ref immutable LowExpr a) {
	return immutable LowExpr(
		anyPtrConstType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialUnary(
			LowExprKind.SpecialUnary.Kind.asAnyPtr,
			allocate(alloc, a))));
}

immutable(LowExpr) genDrop(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr a,
	immutable ubyte localIndex,
) {
	// TODO: less hacky way?
	return immutable LowExpr(
		voidType,
		range,
		immutable LowExprKind(immutable LowExprKind.Let(
			genLocal(alloc, shortSymAlphaLiteral("dropped"), localIndex, a.type),
			allocate(alloc, a),
			allocate(alloc, genVoid(range)))));
}

private immutable(LowExpr) genDerefGcOrRawPtr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr ptr,
) {
	return genUnary(alloc, range, asGcOrRawPointee(ptr.type), LowExprKind.SpecialUnary.Kind.deref, ptr);
}

immutable(LowExpr) genDerefGcPtr(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable LowExpr ptr) {
	return genDerefGcOrRawPtr(alloc, range, ptr);
}

immutable(LowExpr) genDerefRawPtr(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable LowExpr ptr) {
	return genDerefGcOrRawPtr(alloc, range, ptr);
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

immutable(LowExpr) incrPointer(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowType.PtrRawConst ptrType,
	ref immutable LowExpr ptr,
) {
	return genAddPtr(alloc, ptrType, range, ptr, constantNat64(range, 1));
}

immutable(LowExpr) constantNat64(
	ref immutable FileAndRange range,
	immutable ulong value,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable Constant(immutable Constant.Integral(value))));
}

immutable(LowExpr) genTailRecur(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType returnType,
	immutable LowExpr[] args,
) {
	return immutable LowExpr(returnType, range, immutable LowExprKind(immutable LowExprKind.TailRecur(args)));
}

immutable(LowExpr) genCall(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowFunIndex called,
	immutable LowType returnType,
	immutable LowExpr[] args,
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

immutable(LowParam) genParam(immutable Sym name, immutable LowType type) {
	return immutable LowParam(
		immutable LowParamSource(immutable LowParamSource.Generated(name)),
		type);
}

immutable(LowExpr) paramRef(
	ref immutable FileAndRange range,
	immutable LowType type,
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
	immutable LowExpr left,
	immutable LowExpr right,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.wrapMulNat64,
			allocate(alloc, left),
			allocate(alloc, right))));
}

immutable(LowExpr) genPtrEq(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	return immutable LowExpr(boolType, range, immutable LowExprKind(immutable LowExprKind.SpecialBinary(
		LowExprKind.SpecialBinary.Kind.eqPtr,
		allocate(alloc, a),
		allocate(alloc, b))));
}

immutable(LowExprKind) genEnumEq(Alloc)(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
		eqForType(asPrimitive(a.type)),
		allocate(alloc, a),
		allocate(alloc, b)));
}

immutable(LowExprKind) genBitwiseNegate(Alloc)(ref Alloc alloc, immutable LowExpr a) {
	return immutable LowExprKind(immutable LowExprKind.SpecialUnary(
		bitwiseNegateForType(asPrimitive(a.type)),
		allocate(alloc, a)));
}

immutable(LowExprKind) genEnumIntersect(Alloc)(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
		intersectForType(asPrimitive(a.type)),
		allocate(alloc, a),
		allocate(alloc, b)));
}

immutable(LowExprKind) genEnumUnion(Alloc)(ref Alloc alloc, immutable LowExpr a, immutable LowExpr b) {
	verify(asPrimitive(a.type) == asPrimitive(b.type));
	return immutable LowExprKind(immutable LowExprKind.SpecialBinary(
		unionForType(asPrimitive(a.type)),
		allocate(alloc, a),
		allocate(alloc, b)));
}

private immutable(LowExprKind.SpecialUnary.Kind) bitwiseNegateForType(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
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
		case PrimitiveType.char_:
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
		case PrimitiveType.char_:
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
		case PrimitiveType.char_:
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

immutable(LowExprKind) genEnumToIntegral(Alloc)(ref Alloc alloc, immutable LowExpr inner) {
	return immutable LowExprKind(immutable LowExprKind.SpecialUnary(
		LowExprKind.SpecialUnary.Kind.enumToIntegral,
		allocate(alloc, inner)));
}

immutable(LowExpr) ptrCast(Alloc)(
	ref Alloc alloc,
	immutable LowType type,
	ref immutable FileAndRange range,
	immutable LowExpr inner,
) {
	return immutable LowExpr(type, range, ptrCastKind(alloc, inner));
}

immutable(LowExprKind) ptrCastKind(Alloc)(ref Alloc alloc, immutable LowExpr inner) {
	return immutable LowExprKind(immutable LowExprKind.PtrCast(allocate(alloc, inner)));
}

immutable(LowExpr) recordFieldGet(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr target,
	immutable LowType fieldType,
	immutable ubyte fieldIndex,
) {
	return immutable LowExpr(fieldType, range, immutable LowExprKind(
		immutable LowExprKind.RecordFieldGet(
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

immutable(LowExpr) genVoid(ref immutable FileAndRange source) {
	return immutable LowExpr(voidType, source, immutable LowExprKind(immutable Constant(immutable Constant.Void())));
}

immutable(Ptr!LowLocal) genLocal(Alloc)(
	ref Alloc alloc,
	immutable Sym name,
	immutable ubyte index,
	immutable LowType type,
) {
	return nu!LowLocal(alloc, immutable LowLocalSource(immutable LowLocalSource.Generated(name, index)), type);
}

immutable(LowExpr) genGetArrSize(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr arr,
) {
	return recordFieldGet(alloc, range, arr, nat64Type, 0);
}

immutable(LowExpr) genGetArrData(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr arr,
	ref immutable LowType.PtrRawConst elementPtrType,
) {
	return recordFieldGet(alloc, range, arr, immutable LowType(elementPtrType), 1);
}

immutable(LowType.PtrRawConst) getElementPtrTypeFromArrType(
	ref immutable AllLowTypes allTypes,
	ref immutable LowType.Record arrType,
) {
	immutable LowRecord arrRecord = fullIndexDictGet(allTypes.allRecords, arrType);
	verify(size(arrRecord.fields) == 2);
	verify(symEq(name(at(arrRecord.fields, 0)), shortSymAlphaLiteral("size")));
	verify(symEq(name(at(arrRecord.fields, 1)), shortSymAlphaLiteral("begin-ptr")));
	return asPtrRawConst(at(arrRecord.fields, 1).type);
}
