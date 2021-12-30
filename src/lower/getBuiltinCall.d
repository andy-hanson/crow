module lower.getBuiltinCall;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asPrimitive,
	isFunPtrType,
	isPrimitive,
	isPtrRawMut,
	LowExprKind,
	LowType,
	PrimitiveType;
import util.sym : Operator, operatorSymValue, shortSymValue, SpecialSym, specialSymValue, Sym;
import util.util : todo;

struct BuiltinKind {
	@safe @nogc pure nothrow:

	struct AllFuns {}
	struct CallFunPtr {}
	struct GetCtx {}
	struct InitConstants {}
	struct OptOr {}
	struct OptQuestion2 {}
	struct PtrCast {}
	struct SizeOf {}
	struct StaticSyms {}
	struct Zeroed {}

	immutable this(immutable AllFuns a) { kind_ = Kind.allFuns; allFuns_ = a; }
	immutable this(immutable CallFunPtr a) { kind_ = Kind.callFunPtr; callFunPtr_ = a; }
	immutable this(immutable GetCtx a) { kind_ = Kind.getCtx; getCtx_ = a; }
	@trusted immutable this(immutable Constant a) { kind_ = Kind.constant; constant_ = a; }
	immutable this(immutable InitConstants a) { kind_ = Kind.initConstants; initConstants_ = a; }
	immutable this(immutable OptOr a) { kind_ = Kind.optOr; optOr_ = a; }
	immutable this(immutable OptQuestion2 a) { kind_ = Kind.optQuestion2; optQuestion2_ = a; }
	immutable this(immutable LowExprKind.SpecialUnary.Kind a) { kind_ = Kind.unary; unary_ = a; }
	immutable this(immutable LowExprKind.SpecialBinary.Kind a) { kind_ = Kind.binary; binary_ = a; }
	immutable this(immutable PtrCast a) { kind_ = Kind.ptrCast; ptrCast_ = a; }
	immutable this(immutable SizeOf a) { kind_ = Kind.sizeOf; sizeOf_ = a; }
	immutable this(immutable StaticSyms a) { kind_ = Kind.staticSyms; staticSyms_ = a; }
	immutable this(immutable Zeroed a) { kind_ = Kind.zeroed; zeroed_ = a; }

	private:
	enum Kind {
		allFuns,
		callFunPtr,
		getCtx,
		constant,
		initConstants,
		unary,
		binary,
		optOr,
		optQuestion2,
		ptrCast,
		sizeOf,
		staticSyms,
		zeroed,
	}
	immutable Kind kind_;
	union {
		immutable AllFuns allFuns_;
		immutable CallFunPtr callFunPtr_;
		immutable GetCtx getCtx_;
		immutable Constant constant_;
		immutable InitConstants initConstants_;
		immutable LowExprKind.SpecialUnary.Kind unary_;
		immutable LowExprKind.SpecialBinary.Kind binary_;
		immutable OptOr optOr_;
		immutable OptQuestion2 optQuestion2_;
		immutable PtrCast ptrCast_;
		immutable SizeOf sizeOf_;
		immutable StaticSyms staticSyms_;
		immutable Zeroed zeroed_;
	}
}

@trusted immutable(T) matchBuiltinKind(T)(
	ref immutable BuiltinKind a,
	scope immutable(T) delegate(ref immutable BuiltinKind.AllFuns) @safe @nogc pure nothrow cbAllFuns,
	scope immutable(T) delegate(ref immutable BuiltinKind.CallFunPtr) @safe @nogc pure nothrow cbCallFunPtr,
	scope immutable(T) delegate(ref immutable BuiltinKind.GetCtx) @safe @nogc pure nothrow cbGetCtx,
	scope immutable(T) delegate(ref immutable Constant) @safe @nogc pure nothrow cbConstant,
	scope immutable(T) delegate(ref immutable BuiltinKind.InitConstants) @safe @nogc pure nothrow cbInitConstants,
	scope immutable(T) delegate(immutable LowExprKind.SpecialUnary.Kind) @safe @nogc pure nothrow cbUnary,
	scope immutable(T) delegate(immutable LowExprKind.SpecialBinary.Kind) @safe @nogc pure nothrow cbBinary,
	scope immutable(T) delegate(ref immutable BuiltinKind.OptOr) @safe @nogc pure nothrow cbOptOr,
	scope immutable(T) delegate(ref immutable BuiltinKind.OptQuestion2) @safe @nogc pure nothrow cbOptQuestion2,
	scope immutable(T) delegate(ref immutable BuiltinKind.PtrCast) @safe @nogc pure nothrow cbPtrCast,
	scope immutable(T) delegate(ref immutable BuiltinKind.SizeOf) @safe @nogc pure nothrow cbSizeOf,
	scope immutable(T) delegate(ref immutable BuiltinKind.StaticSyms) @safe @nogc pure nothrow cbStaticSyms,
	scope immutable(T) delegate(ref immutable BuiltinKind.Zeroed) @safe @nogc pure nothrow cbZeroed,
) {
	final switch (a.kind_) {
		case BuiltinKind.Kind.allFuns:
			return cbAllFuns(a.allFuns_);
		case BuiltinKind.Kind.callFunPtr:
			return cbCallFunPtr(a.callFunPtr_);
		case BuiltinKind.Kind.getCtx:
			return cbGetCtx(a.getCtx_);
		case BuiltinKind.Kind.constant:
			return cbConstant(a.constant_);
		case BuiltinKind.Kind.initConstants:
			return cbInitConstants(a.initConstants_);
		case BuiltinKind.Kind.unary:
			return cbUnary(a.unary_);
		case BuiltinKind.Kind.binary:
			return cbBinary(a.binary_);
		case BuiltinKind.Kind.optOr:
			return cbOptOr(a.optOr_);
		case BuiltinKind.Kind.optQuestion2:
			return cbOptQuestion2(a.optQuestion2_);
		case BuiltinKind.Kind.ptrCast:
			return cbPtrCast(a.ptrCast_);
		case BuiltinKind.Kind.sizeOf:
			return cbSizeOf(a.sizeOf_);
		case BuiltinKind.Kind.staticSyms:
			return cbStaticSyms(a.staticSyms_);
		case BuiltinKind.Kind.zeroed:
			return cbZeroed(a.zeroed_);
	}
}

immutable(BuiltinKind) getBuiltinKind(
	immutable Sym name,
	ref immutable LowType rt,
	ref immutable LowType p0,
	ref immutable LowType p1,
) {
	immutable(BuiltinKind) constant(immutable Constant kind) {
		return immutable BuiltinKind(kind);
	}
	immutable(BuiltinKind) constantBool(immutable bool value) {
		return constant(immutable Constant(immutable Constant.BoolConstant(value)));
	}
	immutable(BuiltinKind) unary(immutable LowExprKind.SpecialUnary.Kind kind) {
		return immutable BuiltinKind(kind);
	}
	immutable(BuiltinKind) binary(immutable LowExprKind.SpecialBinary.Kind kind) {
		return immutable BuiltinKind(kind);
	}

	immutable(T) failT(T)() {
		return todo!T("not a builtin fun");
	}
	immutable(BuiltinKind) fail() {
		return failT!(immutable BuiltinKind);
	}
	immutable(LowExprKind.SpecialUnary.Kind) failUnary() {
		return failT!(immutable LowExprKind.SpecialUnary.Kind);
	}
	immutable(LowExprKind.SpecialBinary.Kind) failBinary() {
		return failT!(immutable LowExprKind.SpecialBinary.Kind);
	}

	switch (name.value) {
		case operatorSymValue(Operator.plus):
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.addFloat32
				: isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.addFloat64
				: isPtrRawMut(rt) && isPtrRawMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.addPtrAndNat64
				: failBinary());
		case operatorSymValue(Operator.minus):
			return binary(isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.subFloat64
				: isPtrRawMut(rt) && isPtrRawMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.subPtrAndNat64
				: failBinary());
		case operatorSymValue(Operator.times):
			return isPtrRawMut(p0)
				? unary(LowExprKind.SpecialUnary.Kind.deref)
				: binary(isFloat64(rt) ? LowExprKind.SpecialBinary.Kind.mulFloat64 : failBinary());
		case operatorSymValue(Operator.equal):
			return binary(
				isNat8(p0) ? LowExprKind.SpecialBinary.Kind.eqNat8 :
				isNat16(p0) ? LowExprKind.SpecialBinary.Kind.eqNat16 :
				isNat32(p0) ? LowExprKind.SpecialBinary.Kind.eqNat32 :
				isNat64(p0) ? LowExprKind.SpecialBinary.Kind.eqNat64 :
				isInt8(p0) ? LowExprKind.SpecialBinary.Kind.eqInt8 :
				isInt16(p0) ? LowExprKind.SpecialBinary.Kind.eqInt16 :
				isInt32(p0) ? LowExprKind.SpecialBinary.Kind.eqInt32 :
				isInt64(p0) ? LowExprKind.SpecialBinary.Kind.eqInt64 :
				isFloat64(p0) ? LowExprKind.SpecialBinary.Kind.eqFloat64 :
				isPtrRawMut(p0) ? LowExprKind.SpecialBinary.Kind.eqPtr :
				failBinary());
		case operatorSymValue(Operator.and2):
			return binary(LowExprKind.SpecialBinary.Kind.and);
		case operatorSymValue(Operator.or2):
			return isBool(rt)
				? binary(LowExprKind.SpecialBinary.Kind.orBool)
				: immutable BuiltinKind(immutable BuiltinKind.OptOr());
		case operatorSymValue(Operator.question2):
			return immutable BuiltinKind(immutable BuiltinKind.OptQuestion2());
		case shortSymValue("as-ref"):
			return unary(LowExprKind.SpecialUnary.Kind.asRef);
		case operatorSymValue(Operator.and1):
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseAndNat64
				: failBinary());
		case operatorSymValue(Operator.tilde):
			return unary(isNat8(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat8
				: isNat16(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat16
				: isNat32(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat32
				: isNat64(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat64
				: failUnary());
		case operatorSymValue(Operator.or1):
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseOrNat64
				: failBinary());
		case operatorSymValue(Operator.xor1):
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.bitwiseXorNat64
				: failBinary());
		case shortSymValue("all-funs"):
			return immutable BuiltinKind(immutable BuiltinKind.AllFuns());
		case shortSymValue("as-const"):
		case shortSymValue("as-mut"):
		case shortSymValue("ptr-cast"):
			return immutable BuiltinKind(immutable BuiltinKind.PtrCast());
		case shortSymValue("count-ones"):
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.countOnesNat64
				: failUnary());
		case shortSymValue("false"):
			return constantBool(false);
		case shortSymValue("get-ctx"):
			return immutable BuiltinKind(immutable BuiltinKind.GetCtx());
		case shortSymValue("is-less"):
			return binary(
				isInt8(p0) ? LowExprKind.SpecialBinary.Kind.lessInt8 :
				isInt16(p0) ? LowExprKind.SpecialBinary.Kind.lessInt16 :
				isInt32(p0) ? LowExprKind.SpecialBinary.Kind.lessInt32 :
				isInt64(p0) ? LowExprKind.SpecialBinary.Kind.lessInt64 :
				isNat8(p0) ? LowExprKind.SpecialBinary.Kind.lessNat8 :
				isNat16(p0) ? LowExprKind.SpecialBinary.Kind.lessNat16 :
				isNat32(p0) ? LowExprKind.SpecialBinary.Kind.lessNat32 :
				isNat64(p0) ? LowExprKind.SpecialBinary.Kind.lessNat64 :
				isFloat32(p0) ? LowExprKind.SpecialBinary.Kind.lessFloat32 :
				isFloat64(p0) ? LowExprKind.SpecialBinary.Kind.lessFloat64 :
				isPtrRawMut(p0) ? LowExprKind.SpecialBinary.Kind.lessPtr :
				failBinary());
		case shortSymValue("is-nan"):
			return unary(
				isFloat32(p0) ? LowExprKind.SpecialUnary.Kind.isNanFloat32 :
				isFloat64(p0) ? LowExprKind.SpecialUnary.Kind.isNanFloat64 :
				failUnary());
		case shortSymValue("new-void"):
			return isVoid(rt)
				? constant(immutable Constant(immutable Constant.Void()))
				: fail();
		case shortSymValue("null"):
			return constant(immutable Constant(immutable Constant.Null()));
		case shortSymValue("ptr-to"):
			return unary(LowExprKind.SpecialUnary.Kind.ptrTo);
		case shortSymValue("ref-of-val"):
			return unary(LowExprKind.SpecialUnary.Kind.refOfVal);
		case shortSymValue("set-deref"):
			return binary(isPtrRawMut(p0) ? LowExprKind.SpecialBinary.Kind.writeToPtr : failBinary());
		case shortSymValue("size-of"):
			return immutable BuiltinKind(immutable BuiltinKind.SizeOf());
		case shortSymValue("subscript"):
			return isFunPtrType(p0)
				? immutable BuiltinKind(immutable BuiltinKind.CallFunPtr())
				: fail();
		case shortSymValue("static-syms"):
			return immutable BuiltinKind(immutable BuiltinKind.StaticSyms());
		case shortSymValue("to-char"):
			return unary(isNat8(p0)
				? LowExprKind.SpecialUnary.Kind.toCharFromNat8
				: failUnary());
		case shortSymValue("to-float64"):
			return unary(isInt64(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromInt64
				: isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromNat64
				: isFloat32(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32
				: failUnary());
		case shortSymValue("to-int64"):
			return unary(isInt16(p0)
				? LowExprKind.SpecialUnary.Kind.toInt64FromInt16
				: isInt32(p0)
				? LowExprKind.SpecialUnary.Kind.toInt64FromInt32
				: failUnary());
		case shortSymValue("to-nat64"):
			return unary(isNat8(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat8
				: isNat16(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat16
				: isNat32(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat32
				: isPtrRawMut(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromPtr
				: failUnary());
		case shortSymValue("to-nat8"):
			return unary(isChar(p0)
				? LowExprKind.SpecialUnary.Kind.toNat8FromChar
				: failUnary());
		case shortSymValue("to-mut-ptr"):
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.toPtrFromNat64
				: failUnary());
		case shortSymValue("true"):
			return constantBool(true);
		case shortSymValue("unsafe-div"):
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat32
				: isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat64
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt64
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat64
				: failBinary());
		case shortSymValue("unsafe-mod"):
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeModNat64) : fail();
		case shortSymValue("wrap-add"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat64
				: failBinary());
		case shortSymValue("wrap-mul"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulInt64
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat64
				: failBinary());
		case shortSymValue("wrap-sub"):
			return binary(isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat64
				: failBinary());
		case shortSymValue("zeroed"):
			return immutable BuiltinKind(immutable BuiltinKind.Zeroed());
		case specialSymValue(SpecialSym.as_any_mut_ptr):
			return unary(LowExprKind.SpecialUnary.Kind.asAnyPtr);
		case specialSymValue(SpecialSym.init_constants):
			return immutable BuiltinKind(immutable BuiltinKind.InitConstants());
		case specialSymValue(SpecialSym.ptr_cast_from_extern):
		case specialSymValue(SpecialSym.ptr_cast_to_extern):
			return immutable BuiltinKind(immutable BuiltinKind.PtrCast());
		case specialSymValue(SpecialSym.truncate_to_int64):
			return unary(isFloat64(p0)
				? LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64
				: failUnary());
		case specialSymValue(SpecialSym.unsafe_bit_shift_left):
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64) : fail();
		case specialSymValue(SpecialSym.unsafe_bit_shift_right):
			return isNat64(rt)
				? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64)
				: fail();
		case specialSymValue(SpecialSym.unsafe_to_int8):
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8) : fail();
		case specialSymValue(SpecialSym.unsafe_to_int16):
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16) : fail();
		case specialSymValue(SpecialSym.unsafe_to_int32):
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32) : fail();
		case specialSymValue(SpecialSym.unsafe_to_int64):
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64) : fail();
		case specialSymValue(SpecialSym.unsafe_to_nat8):
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8) : fail();
		case specialSymValue(SpecialSym.unsafe_to_nat16):
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16): fail();
		case specialSymValue(SpecialSym.unsafe_to_nat32):
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32) : fail();
		case specialSymValue(SpecialSym.unsafe_to_nat64):
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64) : fail();
		default:
			return fail();
	}
}

private:

immutable(bool) isPrimitiveType(immutable LowType a, immutable PrimitiveType p) {
	return isPrimitive(a) && asPrimitive(a) == p;
}

immutable(bool) isBool(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.bool_);
}

immutable(bool) isChar(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.char_);
}

immutable(bool) isInt8(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.int8);
}

immutable(bool) isInt16(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.int16);
}

immutable(bool) isInt32(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.int32);
}

immutable(bool) isInt64(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.int64);
}

immutable(bool) isNat8(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.nat8);
}

immutable(bool) isNat16(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.nat16);
}

immutable(bool) isNat32(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.nat32);
}

immutable(bool) isNat64(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.nat64);
}

immutable(bool) isFloat32(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.float32);
}

immutable(bool) isFloat64(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.float64);
}

immutable(bool) isVoid(immutable LowType a) {
	return isPrimitiveType(a, PrimitiveType.void_);
}
