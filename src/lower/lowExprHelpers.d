module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteFun;
import model.constant : Constant, constantZero;
import model.model : BuiltinUnary, BuiltinBinary;
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
	LowVarIndex,
	PrimitiveType;
import model.typeLayout : typeSizeBytes;
import util.alloc.alloc : Alloc;
import util.col.array : mapWithIndex, newArray, newSmallArray, small, SmallArray;
import util.conv : safeToUint;
import util.integralValues : IntegralValue, integralValuesRange;
import util.memory : allocate;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol;

LowType boolType = LowType(PrimitiveType.bool_);
LowType char8Type = LowType(PrimitiveType.char8);
LowType char32Type = LowType(PrimitiveType.char32);
LowType char8PtrConstType() => LowType(LowType.PtrRawConst(&char8Type));
LowType float32Type() => LowType(PrimitiveType.float32);
LowType float64Type() => LowType(PrimitiveType.float64);
LowType int8Type() => LowType(PrimitiveType.int8);
LowType int16Type() => LowType(PrimitiveType.int16);
LowType int32Type() => LowType(PrimitiveType.int32);
LowType int64Type() => LowType(PrimitiveType.int64);
LowType nat8Type = LowType(PrimitiveType.nat8);
LowType nat16Type() => LowType(PrimitiveType.nat16);
LowType nat32Type() => LowType(PrimitiveType.nat32);
LowType nat64Type() => LowType(PrimitiveType.nat64);
private LowType anyPtrConstType() =>
	LowType(LowType.PtrRawConst(&nat8Type));
LowType anyPtrMutType() => LowType(LowType.PtrRawMut(&nat8Type));
LowType voidType = LowType(PrimitiveType.void_);
LowType voidConstPointerType() => LowType(LowType.PtrRawConst(&voidType));

LowExpr genAbort(LowType type, UriAndRange range) =>
	LowExpr(type, range, LowExprKind(LowExprKind.Abort()));

LowExpr genUnionAs(LowType asType, UriAndRange range, LowExpr* union_, uint memberIndex) =>
	LowExpr(asType, range, LowExprKind(LowExprKind.UnionAs(union_, memberIndex)));

LowExpr genUnionKind(UriAndRange range, LowExpr* union_) =>
	LowExpr(nat64Type, range, LowExprKind(LowExprKind.UnionKind(union_)));

LowExpr genUnionMatch(
	ref Alloc alloc,
	LowType type,
	UriAndRange range,
	LowExpr getUnion,
	SmallArray!LowType unionMembers,
	in LowExpr delegate(size_t, LowExpr) @safe @nogc pure nothrow cbCase,
) {
	assert(getUnion.kind.isA!(LowExprKind.LocalGet));
	LowExpr* getUnionPtr = allocate(alloc, getUnion);
	return LowExpr(type, range, LowExprKind(allocate(alloc,
		LowExprKind.Switch(
			genUnionKind(range, getUnionPtr),
			integralValuesRange(unionMembers.length),
			mapWithIndex!(LowExpr, LowType)(
				alloc, unionMembers, (size_t memberIndex, ref LowType memberType) =>
					cbCase(memberIndex, genUnionAs(memberType, range, getUnionPtr, safeToUint(memberIndex)))),
			genAbort(type, range)))));
}

LowExpr genAddPointer(ref Alloc alloc, LowType.PtrRawConst ptrType, UriAndRange range, LowExpr ptr, LowExpr added) =>
	LowExpr(LowType(ptrType), range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(BuiltinBinary.addPtrAndNat64, [ptr, added]))));

LowExpr genAsAnyPointerConst(ref Alloc alloc, UriAndRange range, LowExpr a) =>
	LowExpr(anyPtrConstType, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialUnary(BuiltinUnary.asAnyPtr, a))));

LowExpr genPointerToLocal(LowType type, UriAndRange range, LowLocal* local) =>
	LowExpr(type, range, LowExprKind(LowExprKind.PtrToLocal(local)));

LowExpr genFunPointer(LowType type, UriAndRange range, ConcreteFun* fun) =>
	LowExpr(type, range, LowExprKind(Constant(Constant.FunPointer(fun))));
LowExpr genFunPointer(LowType type, UriAndRange range, LowFunIndex fun) =>
	LowExpr(type, range, LowExprKind(LowExprKind.FunPointer(fun)));

LowExpr genDrop(ref Alloc alloc, UriAndRange range, LowExpr a) =>
	a.type == voidType
		? a
		: LowExpr(voidType, range, LowExprKind(allocate(alloc,
			LowExprKind.SpecialUnary(BuiltinUnary.drop, a))));

private LowExpr genDerefGcOrRawPointer(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genUnary(alloc, range, asGcOrRawPointee(ptr.type), BuiltinUnary.deref, ptr);

LowExpr genDerefGcPointer(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genDerefGcOrRawPointer(alloc, range, ptr);

LowExpr genDerefRawPointer(ref Alloc alloc, UriAndRange range, LowExpr ptr) =>
	genDerefGcOrRawPointer(alloc, range, ptr);

private LowExpr genUnary(
	ref Alloc alloc,
	UriAndRange range,
	LowType type,
	BuiltinUnary kind,
	LowExpr arg,
) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(kind, arg))));

LowExpr genIf(ref Alloc alloc, UriAndRange range, LowExpr cond, LowExpr then, LowExpr else_) =>
	LowExpr(then.type, range, LowExprKind(allocate(alloc, LowExprKind.If(cond, then, else_))));

LowExpr genIncrPointer(ref Alloc alloc, UriAndRange range, LowType.PtrRawConst pointerType, LowExpr pointer) =>
	genAddPointer(alloc, pointerType, range, pointer, genConstantNat64(range, 1));

LowExpr genFalse(UriAndRange range) =>
	genConstantBool(range, false);
LowExpr genTrue(UriAndRange range) =>
	genConstantBool(range, true);
private LowExpr genConstantBool(UriAndRange range, bool value) =>
	genConstantIntegral(boolType, range, value);

LowExpr genConstantInt32(UriAndRange range, int value) =>
	genConstantIntegral(int32Type, range, value);

LowExpr genConstantNat64(UriAndRange range, ulong value) =>
	genConstantIntegral(nat64Type, range, value);

LowExpr genConstantIntegral(LowType type, UriAndRange range, ulong value) =>
	LowExpr(type, range, LowExprKind(Constant(IntegralValue(value))));

LowExpr genCallNoGcRoots(LowType type, UriAndRange range, LowFunIndex called, LowExpr[] args) =>
	LowExpr(type, range, LowExprKind(LowExprKind.Call(called, small!LowExpr(args))));
LowExpr genCallNoGcRoots(ref Alloc alloc, LowType type, UriAndRange range, LowFunIndex called, in LowExpr[] args) =>
	genCallNoGcRoots(type, range, called, newArray(alloc, args));
LowExpr genSizeOf(in AllLowTypes allTypes, UriAndRange range, LowType t) =>
	genConstantNat64(range, typeSizeBytes(allTypes, t));

LowExpr genLocalGet(UriAndRange range, LowLocal* local) =>
	LowExpr(local.type, range, LowExprKind(LowExprKind.LocalGet(local)));

LowExpr genLocalSet(ref Alloc alloc, UriAndRange range, LowLocal* local, LowExpr value) =>
	LowExpr(voidType, range, LowExprKind(allocate(alloc, LowExprKind.LocalSet(local, value))));

LowExpr genWrapMulNat64(ref Alloc alloc, UriAndRange range, LowExpr left, LowExpr right) =>
	LowExpr(nat64Type, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(BuiltinBinary.wrapMulNat64, [left, right]))));

LowExpr genPointerEqual(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) =>
	LowExpr(boolType, range, LowExprKind(allocate(alloc,
		LowExprKind.SpecialBinary(BuiltinBinary.eqPtr, [a, b]))));

LowExpr genEnumEq(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExpr(boolType, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(eqForType(a.type.as!PrimitiveType), [a, b]))));
}

LowExpr genBitwiseNegate(ref Alloc alloc, UriAndRange range, LowExpr a) =>
	LowExpr(a.type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(bitwiseNegateForType(a.type.as!PrimitiveType), a))));

LowExpr genEnumIntersect(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExpr(a.type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(intersectForType(a.type.as!PrimitiveType), [a, b]))));
}

LowExpr genEnumUnion(ref Alloc alloc, UriAndRange range, LowExpr a, LowExpr b) {
	assert(a.type.as!PrimitiveType == b.type.as!PrimitiveType);
	return LowExpr(a.type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(unionForType(a.type.as!PrimitiveType), [a, b]))));
}

private BuiltinUnary bitwiseNegateForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.char32:
		case PrimitiveType.fiberSuspension:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
		case PrimitiveType.int8:
		case PrimitiveType.int16:
		case PrimitiveType.int32:
		case PrimitiveType.int64:
			assert(false);
		case PrimitiveType.nat8:
			return BuiltinUnary.bitwiseNotNat8;
		case PrimitiveType.nat16:
			return BuiltinUnary.bitwiseNotNat16;
		case PrimitiveType.nat32:
			return BuiltinUnary.bitwiseNotNat32;
		case PrimitiveType.nat64:
			return BuiltinUnary.bitwiseNotNat64;
	}
}

private BuiltinBinary eqForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.char32:
		case PrimitiveType.fiberSuspension:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
		case PrimitiveType.int8:
			return BuiltinBinary.eqInt8;
		case PrimitiveType.int16:
			return BuiltinBinary.eqInt16;
		case PrimitiveType.int32:
			return BuiltinBinary.eqInt32;
		case PrimitiveType.int64:
			return BuiltinBinary.eqInt64;
		case PrimitiveType.nat8:
			return BuiltinBinary.eqNat8;
		case PrimitiveType.nat16:
			return BuiltinBinary.eqNat16;
		case PrimitiveType.nat32:
			return BuiltinBinary.eqNat32;
		case PrimitiveType.nat64:
			return BuiltinBinary.eqNat64;
	}
}

LowExpr genUnionKindEquals(ref Alloc alloc, UriAndRange range, LowExpr a, ulong value) =>
	LowExpr(boolType, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(
		BuiltinBinary.eqNat64, [genUnionKind(range, allocate(alloc, a)), genConstantNat64(range, value)]))));

private BuiltinBinary intersectForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.char32:
		case PrimitiveType.fiberSuspension:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
		case PrimitiveType.int8:
			return BuiltinBinary.bitwiseAndInt8;
		case PrimitiveType.int16:
			return BuiltinBinary.bitwiseAndInt16;
		case PrimitiveType.int32:
			return BuiltinBinary.bitwiseAndInt32;
		case PrimitiveType.int64:
			return BuiltinBinary.bitwiseAndInt64;
		case PrimitiveType.nat8:
			return BuiltinBinary.bitwiseAndNat8;
		case PrimitiveType.nat16:
			return BuiltinBinary.bitwiseAndNat16;
		case PrimitiveType.nat32:
			return BuiltinBinary.bitwiseAndNat32;
		case PrimitiveType.nat64:
			return BuiltinBinary.bitwiseAndNat64;
	}
}

private BuiltinBinary unionForType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.char32:
		case PrimitiveType.fiberSuspension:
		case PrimitiveType.float32:
		case PrimitiveType.float64:
		case PrimitiveType.void_:
			assert(false);
		case PrimitiveType.int8:
			return BuiltinBinary.bitwiseOrInt8;
		case PrimitiveType.int16:
			return BuiltinBinary.bitwiseOrInt16;
		case PrimitiveType.int32:
			return BuiltinBinary.bitwiseOrInt32;
		case PrimitiveType.int64:
			return BuiltinBinary.bitwiseOrInt64;
		case PrimitiveType.nat8:
			return BuiltinBinary.bitwiseOrNat8;
		case PrimitiveType.nat16:
			return BuiltinBinary.bitwiseOrNat16;
		case PrimitiveType.nat32:
			return BuiltinBinary.bitwiseOrNat32;
		case PrimitiveType.nat64:
			return BuiltinBinary.bitwiseOrNat64;
	}
}

LowExpr genEnumToIntegral(ref Alloc alloc, LowType type, UriAndRange range, LowExpr inner) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialUnary(BuiltinUnary.enumToIntegral, inner))));

LowExpr genPointerCast(ref Alloc alloc, LowType type, UriAndRange range, LowExpr inner) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.PtrCast(inner))));

LowExpr genCreateRecord(ref Alloc alloc, LowType type, UriAndRange range, in LowExpr[] args) =>
	genCreateRecord(type, range, newArray(alloc, args));
LowExpr genCreateRecord(LowType type, UriAndRange range, LowExpr[] args) =>
	LowExpr(type, range, LowExprKind(LowExprKind.CreateRecord(args)));

LowExpr genRecordFieldGet(ref Alloc alloc, UriAndRange range, LowExpr target, LowType fieldType, size_t fieldIndex) =>
	LowExpr(fieldType, range, LowExprKind(LowExprKind.RecordFieldGet(allocate(alloc, target), fieldIndex)));

LowExpr genSeq(ref Alloc alloc, UriAndRange range, LowExpr first, LowExpr then) =>
	LowExpr(then.type, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(BuiltinBinary.seq, [first, then]))));

LowExpr genSeq(ref Alloc alloc, UriAndRange range, LowExpr line0, LowExpr line1, LowExpr line2) =>
	genSeq(alloc, range, line0, genSeq(alloc, range, line1, line2));

LowExpr genWriteToPointer(ref Alloc alloc, UriAndRange range, LowExpr pointer, LowExpr value) =>
	LowExpr(voidType, range, LowExprKind(allocate(alloc, LowExprKind.SpecialBinary(BuiltinBinary.writeToPtr, [pointer, value]))));

LowExpr genVoid(UriAndRange source) =>
	genZeroed(voidType, source);

LowExpr genZeroed(LowType type, UriAndRange range) =>
	LowExpr(type, range, LowExprKind(constantZero));

LowLocal* genLocal(ref Alloc alloc, Symbol name, size_t index, LowType type) =>
	allocate(alloc, genLocalByValue(alloc, name, index, type));
LowLocal genLocalByValue(ref Alloc alloc, Symbol name, size_t index, LowType type) =>
	LowLocal(LowLocalSource(allocate(alloc, LowLocalSource.Generated(name, index))), type);

// 'local.type' should not contain GC roots
LowExpr genLetNoGcRoot(ref Alloc alloc, UriAndRange range, LowLocal* local, LowExpr init, LowExpr then) =>
	LowExpr(then.type, range, LowExprKind(allocate(alloc, LowExprKind.Let(local, init, then))));

LowExpr genLetTempNoGcRoot(
	ref Alloc alloc,
	UriAndRange range,
	size_t localIndex,
	LowExpr value,
	in LowExpr delegate(LowExpr) @safe @nogc pure nothrow cbThen,
) {
	LowLocal* local = genLocal(alloc, symbol!"temp", localIndex, value.type);
	return genLetNoGcRoot(alloc, range, local, value, cbThen(genLocalGet(range, local)));
}

LowExpr genSeqThenReturnFirstNoGcRoot(ref Alloc alloc, UriAndRange range, size_t localIndex, LowExpr a, LowExpr b) =>
	genLetTempNoGcRoot(alloc, range, localIndex, a, (LowExpr getA) =>
		genSeq(alloc, range, b, getA));

LowExpr genGetArrSize(ref Alloc alloc, UriAndRange range, LowExpr arr) =>
	genRecordFieldGet(alloc, range, arr, nat64Type, 0);

LowExpr genGetArrData(ref Alloc alloc, UriAndRange range, LowExpr arr, LowType.PtrRawConst elementPointerType) =>
	genRecordFieldGet(alloc, range, arr, LowType(elementPointerType), 1);

LowType.PtrRawConst getElementPointerTypeFromArrType(in AllLowTypes allTypes, LowType.Record arrType) {
	LowRecord arrRecord = allTypes.allRecords[arrType];
	assert(arrRecord.fields.length == 2);
	assert(debugName(arrRecord.fields[0]) == symbol!"size");
	assert(debugName(arrRecord.fields[1]) == symbol!"pointer");
	return arrRecord.fields[1].type.as!(LowType.PtrRawConst);
}

@trusted LowExpr genLoop(ref Alloc alloc, LowType type, UriAndRange range, LowExpr body_) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.Loop(body_))));

LowExpr genLoopBreak(ref Alloc alloc, LowType type, UriAndRange range, LowExpr value) =>
	LowExpr(type, range, LowExprKind(allocate(alloc, LowExprKind.LoopBreak(value))));

LowExpr genLoopContinue(LowType type, UriAndRange range) =>
	LowExpr(type, range, LowExprKind(LowExprKind.LoopContinue()));

LowExpr genVarGet(LowType type, UriAndRange range, LowVarIndex var) =>
	LowExpr(type, range, LowExprKind(LowExprKind.VarGet(var)));

LowExpr genVarSet(ref Alloc alloc, UriAndRange range, LowVarIndex var, LowExpr value) =>
	LowExpr(voidType, range, LowExprKind(LowExprKind.VarSet(var, allocate(alloc, value))));
