module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.constant : Constant, constantZero;
import model.lowModel :
	asGcOrRawPointee,
	AllLowTypes,
	debugName,
	LowExpr,
	LowExprKind,
	LowFunIndex,
	LowLocal,
	LowLocalSource,
	LowRecord,
	LowType,
	PrimitiveType;
import util.alloc.alloc : Alloc;
import util.memory : allocate, overwriteMemory;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol;

LowType boolType = LowType(PrimitiveType.bool_);
LowType char8Type = LowType(PrimitiveType.char8);
private LowType char8PtrConstType =
	LowType(LowType.PtrRawConst(&char8Type));
LowType char8PtrPtrConstType =
	LowType(LowType.PtrRawConst(&char8PtrConstType));
LowType float32Type = LowType(PrimitiveType.float32);
LowType float64Type = LowType(PrimitiveType.float64);
LowType int8Type = LowType(PrimitiveType.int8);
LowType int16Type = LowType(PrimitiveType.int16);
LowType int32Type = LowType(PrimitiveType.int32);
LowType int64Type = LowType(PrimitiveType.int64);
LowType nat8Type = LowType(PrimitiveType.nat8);
LowType nat16Type = LowType(PrimitiveType.nat16);
LowType nat32Type = LowType(PrimitiveType.nat32);
LowType nat64Type = LowType(PrimitiveType.nat64);
private LowType anyPtrConstType =
	LowType(LowType.PtrRawConst(&nat8Type));
LowType anyPtrMutType = LowType(LowType.PtrRawMut(&nat8Type));
LowType voidType = LowType(PrimitiveType.void_);

LowExpr genAddPtr(ref Alloc alloc, LowType.PtrRawConst ptrType, UriAndRange range, LowExpr ptr, LowExpr added) =>
	LowExpr(LowType(ptrType), range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.addPtrAndNat64, [ptr, added]))));

LowExpr genAsAnyPtrConst(ref Alloc alloc, UriAndRange range, LowExpr a) =>
	LowExpr(anyPtrConstType, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialUnary(LowExprKind.SpecialUnary.Kind.asAnyPtr, a))));

LowExpr genDrop(ref Alloc alloc, UriAndRange range, LowExpr a) =>
	LowExpr(voidType, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialUnary(LowExprKind.SpecialUnary.Kind.drop, a))));

// Ensures that the side-effect order is still 'a' before 'b'
LowExprKind genDropSecond(ref Alloc alloc, UriAndRange range, size_t localIndex, LowExpr a, LowExpr b) =>
	genLetTemp(alloc, range, localIndex, a, (LowExpr getA) =>
		genSeq(alloc, range, genDrop(alloc, range, b), getA)).kind;

private LowExpr genDerefGcOrRawPtr(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genUnary(alloc, range, asGcOrRawPointee(ptr.type), LowExprKind.SpecialUnary.Kind.deref, ptr);

LowExpr genDerefGcPtr(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, range, ptr);

LowExprKind genDerefGcPtr(ref Alloc alloc, LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, UriAndRange(), ptr).kind;

LowExpr genDerefRawPtr(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genDerefGcOrRawPtr(alloc, range, ptr);

private LowExpr genUnary(
	ref Alloc alloc,
	UriAndRange range,
	LowType type,
	LowExprKind.SpecialUnary.Kind kind,
	LowExpr arg,
) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(kind, arg))));

LowExpr genIf(ref Alloc alloc, UriAndRange range, LowExpr cond, LowExpr then, LowExpr else_) =>
	LowExpr(then.type, range, LowExprKind(allocate(alloc, LowExprKind.If(cond, then, else_))));

LowExpr genIncrPointer(ref Alloc alloc, UriAndRange range, LowType.PtrRawConst ptrType, LowExpr ptr) =>
	genAddPtr(alloc, ptrType, range, ptr, genConstantNat64(range, 1));

LowExpr genConstantNat64(UriAndRange range, ulong value) =>
	LowExpr(nat64Type, range, LowExprKind(Constant(Constant.Integral(value))));

LowExpr genCall(ref Alloc alloc, UriAndRange range, LowFunIndex called, LowType returnType, LowExpr[] args) =>
	LowExpr(returnType, range, LowExprKind(LowExprKind.Call(called, args)));

LowExpr genSizeOf(UriAndRange range, LowType t) =>
	LowExpr(nat64Type, range, LowExprKind(LowExprKind.SizeOf(t)));

LowExpr genLocalGet(UriAndRange range, LowLocal* local) =>
	LowExpr(local.type, range, LowExprKind(LowExprKind.LocalGet(local)));

LowExpr genLocalSet(ref Alloc alloc, UriAndRange range, LowLocal* local, LowExpr value) =>
	LowExpr(voidType, range, LowExprKind(allocate(alloc, LowExprKind.LocalSet(local, value))));

LowExpr genWrapMulNat64(ref Alloc alloc, UriAndRange range, LowExpr left, LowExpr right) =>
	LowExpr(nat64Type, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.wrapMulNat64, [left, right]))));

LowExpr genPtrEq(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) =>
	LowExpr(boolType, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.eqPtr, [a, b]))));

LowExprKind genEnumEq(ref Alloc alloc, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(eqForType(a.type.as!PrimitiveType), [a, b])));
}

LowExprKind genBitwiseNegate(ref Alloc alloc, LowExpr a) =>
	LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(bitwiseNegateForType(a.type.as!PrimitiveType), a)));

LowExprKind genEnumIntersect(ref Alloc alloc, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(intersectForType(a.type.as!PrimitiveType), [a, b])));
}

LowExprKind genEnumUnion(ref Alloc alloc, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(unionForType(a.type.as!PrimitiveType), [a, b])));
}

private LowExprKind.SpecialUnary.Kind bitwiseNegateForType(PrimitiveType a) {
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
			assert(false);
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

private LowExprKind.SpecialBinary.Kind eqForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
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

private LowExprKind.SpecialBinary.Kind intersectForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
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

private LowExprKind.SpecialBinary.Kind unionForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
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

LowExprKind genEnumToIntegral(ref Alloc alloc, LowExpr inner) =>
	LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(LowExprKind.SpecialUnary.Kind.enumToIntegral, inner)));

LowExpr genPtrCast(ref Alloc alloc, LowType type, UriAndRange range, LowExpr inner) =>
	LowExpr(type, range, genPtrCastKind(alloc, inner));

LowExprKind genPtrCastKind(ref Alloc alloc, LowExpr inner) =>
	LowExprKind(allocate(alloc, LowExprKind.PtrCast(inner)));

LowExpr genRecordFieldGet(ref Alloc alloc, UriAndRange range, LowExpr target, LowType fieldType, size_t fieldIndex) =>
	LowExpr(fieldType, range, LowExprKind(allocate(alloc, LowExprKind.RecordFieldGet(target, fieldIndex))));

LowExpr genSeq(ref Alloc alloc, UriAndRange range, LowExpr first, LowExpr then) =>
	LowExpr(then.type, range, genSeqKind(alloc, first, then));
LowExprKind genSeqKind(ref Alloc alloc, LowExpr first, LowExpr then) =>
	LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.seq, [first, then])));

LowExpr genSeq(ref Alloc alloc, UriAndRange range, LowExpr line0, LowExpr line1, LowExpr line2) =>
	genSeq(alloc, range, line0, genSeq(alloc, range, line1, line2));

LowExpr genWriteToPtr(ref Alloc alloc, UriAndRange range, LowExpr ptr, LowExpr value) =>
	LowExpr(voidType, range, genWriteToPtr(alloc, ptr, value));
LowExprKind genWriteToPtr(ref Alloc alloc, LowExpr ptr, LowExpr value) =>
	LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(LowExprKind.SpecialBinary.Kind.writeToPtr, [ptr, value])));

LowExpr genVoid(UriAndRange source) =>
	LowExpr(voidType, source, LowExprKind(constantZero));

LowLocal* genLocal(ref Alloc alloc, Symbol name, size_t index, LowType type) =>
	allocate(alloc, genLocalByValue(alloc, name, index, type));
LowLocal genLocalByValue(ref Alloc alloc, Symbol name, size_t index, LowType type) =>
	LowLocal(LowLocalSource(allocate(alloc, LowLocalSource.Generated(name, index))), type);

LowExpr genLet(ref Alloc alloc, UriAndRange range, LowLocal* local, LowExpr init, LowExpr then) =>
	LowExpr(then.type, range, LowExprKind(allocate(alloc, LowExprKind.Let(local, init, then))));

LowExpr genLetTemp(
	ref Alloc alloc,
	UriAndRange range,
	size_t localIndex,
	LowExpr value,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbThen,
) {
	LowLocal* local = genLocal(alloc, symbol!"temp", localIndex, value.type);
	return genLet(alloc, range, local, value, cbThen(genLocalGet(range, local)));
}

LowExpr genGetArrSize(ref Alloc alloc, UriAndRange range, LowExpr arr) =>
	genRecordFieldGet(alloc, range, arr, nat64Type, 0);

LowExpr genGetArrData(ref Alloc alloc, UriAndRange range, LowExpr arr, LowType.PtrRawConst elementPtrType) =>
	genRecordFieldGet(alloc, range, arr, LowType(elementPtrType), 1);

LowType.PtrRawConst getElementPtrTypeFromArrType(ref AllLowTypes allTypes, LowType.Record arrType) {
	LowRecord arrRecord = allTypes.allRecords[arrType];
	assert(arrRecord.fields.length == 2);
	assert(debugName(arrRecord.fields[0]) == symbol!"size");
	assert(debugName(arrRecord.fields[1]) == symbol!"pointer");
	return arrRecord.fields[1].type.as!(LowType.PtrRawConst);
}

@trusted LowExpr genLoop(
	ref Alloc alloc,
	UriAndRange range,
	LowType type,
	in LowExpr delegate(LowExprKind.Loop*) @safe @nogc pure nothrow cbBody,
) {
	LowExprKind.Loop* res = allocate(alloc, LowExprKind.Loop(
		// Dummy initial body
		LowExpr(voidType, UriAndRange.empty, LowExprKind(constantZero))));
	overwriteMemory(&res.body_, cbBody(res));
	return LowExpr(type, range, LowExprKind(res));
}

LowExpr genLoopBreak(ref Alloc alloc, UriAndRange range, LowExprKind.Loop* loop, LowExpr value) =>
	LowExpr(voidType, range, LowExprKind(allocate(alloc, LowExprKind.LoopBreak(loop, value))));

LowExpr genLoopContinue(UriAndRange range, LowExprKind.Loop* loop) =>
	LowExpr(voidType, range, LowExprKind(LowExprKind.LoopContinue(loop)));
