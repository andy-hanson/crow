module lower.getBuiltinCall;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asPrimitive,
	isFunPtrType,
	isPrimitive,
	isPtrRawConstOrMut,
	isPtrRawMut,
	LowExprKind,
	LowType,
	PrimitiveType;
import util.alloc.alloc : Alloc;
import util.sym : AllSymbols, safeCStrOfSym, Sym, sym;
import util.util : debugLog, todo;

struct BuiltinKind {
	@safe @nogc pure nothrow:

	struct CallFunPointer {}
	struct InitConstants {}
	struct OptOr {}
	struct OptQuestion2 {}
	struct PointerCast {}
	struct SizeOf {}
	struct StaticSymbols {}
	struct Zeroed {}

	immutable this(immutable CallFunPointer a) { kind_ = Kind.callFunPointer; callFunPointer_ = a; }
	@trusted immutable this(immutable Constant a) { kind_ = Kind.constant; constant_ = a; }
	immutable this(immutable InitConstants a) { kind_ = Kind.initConstants; initConstants_ = a; }
	immutable this(immutable OptOr a) { kind_ = Kind.optOr; optOr_ = a; }
	immutable this(immutable OptQuestion2 a) { kind_ = Kind.optQuestion2; optQuestion2_ = a; }
	immutable this(immutable LowExprKind.SpecialUnary.Kind a) { kind_ = Kind.unary; unary_ = a; }
	immutable this(immutable LowExprKind.SpecialBinary.Kind a) { kind_ = Kind.binary; binary_ = a; }
	immutable this(immutable LowExprKind.SpecialTernary.Kind a) { kind_ = Kind.ternary; ternary_ = a; }
	immutable this(immutable PointerCast a) { kind_ = Kind.pointerCast; pointerCast_ = a; }
	immutable this(immutable SizeOf a) { kind_ = Kind.sizeOf; sizeOf_ = a; }
	immutable this(immutable StaticSymbols a) { kind_ = Kind.staticSymbols; staticSymbols_ = a; }
	immutable this(immutable Zeroed a) { kind_ = Kind.zeroed; zeroed_ = a; }

	private:
	enum Kind {
		callFunPointer,
		constant,
		initConstants,
		unary,
		binary,
		ternary,
		optOr,
		optQuestion2,
		pointerCast,
		sizeOf,
		staticSymbols,
		zeroed,
	}
	immutable Kind kind_;
	union {
		immutable CallFunPointer callFunPointer_;
		immutable Constant constant_;
		immutable InitConstants initConstants_;
		immutable LowExprKind.SpecialUnary.Kind unary_;
		immutable LowExprKind.SpecialBinary.Kind binary_;
		immutable LowExprKind.SpecialTernary.Kind ternary_;
		immutable OptOr optOr_;
		immutable OptQuestion2 optQuestion2_;
		immutable PointerCast pointerCast_;
		immutable SizeOf sizeOf_;
		immutable StaticSymbols staticSymbols_;
		immutable Zeroed zeroed_;
	}
}

@trusted immutable(T) matchBuiltinKind(T)(
	ref immutable BuiltinKind a,
	scope immutable(T) delegate(ref immutable BuiltinKind.CallFunPointer) @safe @nogc pure nothrow cbCallFunPointer,
	scope immutable(T) delegate(ref immutable Constant) @safe @nogc pure nothrow cbConstant,
	scope immutable(T) delegate(ref immutable BuiltinKind.InitConstants) @safe @nogc pure nothrow cbInitConstants,
	scope immutable(T) delegate(immutable LowExprKind.SpecialUnary.Kind) @safe @nogc pure nothrow cbUnary,
	scope immutable(T) delegate(immutable LowExprKind.SpecialBinary.Kind) @safe @nogc pure nothrow cbBinary,
	scope immutable(T) delegate(immutable LowExprKind.SpecialTernary.Kind) @safe @nogc pure nothrow cbTernary,
	scope immutable(T) delegate(ref immutable BuiltinKind.OptOr) @safe @nogc pure nothrow cbOptOr,
	scope immutable(T) delegate(ref immutable BuiltinKind.OptQuestion2) @safe @nogc pure nothrow cbOptQuestion2,
	scope immutable(T) delegate(ref immutable BuiltinKind.PointerCast) @safe @nogc pure nothrow cbPointerCast,
	scope immutable(T) delegate(ref immutable BuiltinKind.SizeOf) @safe @nogc pure nothrow cbSizeOf,
	scope immutable(T) delegate(ref immutable BuiltinKind.StaticSymbols) @safe @nogc pure nothrow cbStaticSymbols,
	scope immutable(T) delegate(ref immutable BuiltinKind.Zeroed) @safe @nogc pure nothrow cbZeroed,
) {
	final switch (a.kind_) {
		case BuiltinKind.Kind.callFunPointer:
			return cbCallFunPointer(a.callFunPointer_);
		case BuiltinKind.Kind.constant:
			return cbConstant(a.constant_);
		case BuiltinKind.Kind.initConstants:
			return cbInitConstants(a.initConstants_);
		case BuiltinKind.Kind.unary:
			return cbUnary(a.unary_);
		case BuiltinKind.Kind.binary:
			return cbBinary(a.binary_);
		case BuiltinKind.Kind.ternary:
			return cbTernary(a.ternary_);
		case BuiltinKind.Kind.optOr:
			return cbOptOr(a.optOr_);
		case BuiltinKind.Kind.optQuestion2:
			return cbOptQuestion2(a.optQuestion2_);
		case BuiltinKind.Kind.pointerCast:
			return cbPointerCast(a.pointerCast_);
		case BuiltinKind.Kind.sizeOf:
			return cbSizeOf(a.sizeOf_);
		case BuiltinKind.Kind.staticSymbols:
			return cbStaticSymbols(a.staticSymbols_);
		case BuiltinKind.Kind.zeroed:
			return cbZeroed(a.zeroed_);
	}
}

immutable(BuiltinKind) getBuiltinKind(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	immutable Sym name,
	immutable LowType rt,
	immutable LowType p0,
	immutable LowType p1,
) {
	immutable(BuiltinKind) constant(immutable Constant kind) =>
		immutable BuiltinKind(kind);
	immutable(BuiltinKind) constantBool(immutable bool value) =>
		constant(immutable Constant(immutable Constant.BoolConstant(value)));
	immutable(BuiltinKind) unary(immutable LowExprKind.SpecialUnary.Kind kind) =>
		immutable BuiltinKind(kind);
	immutable(BuiltinKind) binary(immutable LowExprKind.SpecialBinary.Kind kind) =>
		immutable BuiltinKind(kind);

	immutable(T) failT(T)() {
		debugLog("Unsupported builtin function:");
		debugLog(safeCStrOfSym(alloc, allSymbols, name).ptr);
		return todo!T("not a builtin fun");
	}
	immutable(BuiltinKind) fail() =>
		failT!(immutable BuiltinKind);
	immutable(LowExprKind.SpecialUnary.Kind) failUnary() =>
		failT!(immutable LowExprKind.SpecialUnary.Kind);
	immutable(LowExprKind.SpecialBinary.Kind) failBinary() =>
		failT!(immutable LowExprKind.SpecialBinary.Kind);

	switch (name.value) {
		case sym!"+".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.addFloat32
				: isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.addFloat64
				: isPtrRawConstOrMut(rt) && isPtrRawConstOrMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.addPtrAndNat64
				: failBinary());
		case sym!"-".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.subFloat32
				: isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.subFloat64
				: isPtrRawConstOrMut(rt) && isPtrRawConstOrMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.subPtrAndNat64
				: failBinary());
		case sym!"*".value:
			return isPtrRawConstOrMut(p0)
				? unary(LowExprKind.SpecialUnary.Kind.deref)
				: binary(isFloat32(rt)
					? LowExprKind.SpecialBinary.Kind.mulFloat32
					: isFloat64(rt)
					? LowExprKind.SpecialBinary.Kind.mulFloat64
					: failBinary());
		case sym!"==".value:
			return binary(
				isNat8(p0) ? LowExprKind.SpecialBinary.Kind.eqNat8 :
				isNat16(p0) ? LowExprKind.SpecialBinary.Kind.eqNat16 :
				isNat32(p0) ? LowExprKind.SpecialBinary.Kind.eqNat32 :
				isNat64(p0) ? LowExprKind.SpecialBinary.Kind.eqNat64 :
				isInt8(p0) ? LowExprKind.SpecialBinary.Kind.eqInt8 :
				isInt16(p0) ? LowExprKind.SpecialBinary.Kind.eqInt16 :
				isInt32(p0) ? LowExprKind.SpecialBinary.Kind.eqInt32 :
				isInt64(p0) ? LowExprKind.SpecialBinary.Kind.eqInt64 :
				isFloat32(p0) ? LowExprKind.SpecialBinary.Kind.eqFloat32 :
				isFloat64(p0) ? LowExprKind.SpecialBinary.Kind.eqFloat64 :
				isPtrRawConstOrMut(p0) ? LowExprKind.SpecialBinary.Kind.eqPtr :
				failBinary());
		case sym!"&&".value:
			return binary(LowExprKind.SpecialBinary.Kind.and);
		case sym!"||".value:
			return isBool(rt)
				? binary(LowExprKind.SpecialBinary.Kind.orBool)
				: immutable BuiltinKind(immutable BuiltinKind.OptOr());
		case sym!"??".value:
			return immutable BuiltinKind(immutable BuiltinKind.OptQuestion2());
		case sym!"&".value:
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
		case sym!"~".value:
			return unary(isNat8(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat8
				: isNat16(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat16
				: isNat32(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat32
				: isNat64(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat64
				: failUnary());
		case sym!"|".value:
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
		case sym!"^".value:
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
		case sym!"as-const".value:
		case sym!"as-mut".value:
		case sym!"pointer-cast".value:
			return immutable BuiltinKind(immutable BuiltinKind.PointerCast());
		case sym!"as-ref".value:
			return unary(LowExprKind.SpecialUnary.Kind.asRef);
		case sym!"count-ones".value:
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.countOnesNat64
				: failUnary());
		case sym!"false".value:
			return constantBool(false);
		case sym!"interpreter-backtrace".value:
			return immutable BuiltinKind(LowExprKind.SpecialTernary.Kind.interpreterBacktrace);
		case sym!"is-less".value:
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
				isPtrRawConstOrMut(p0) ? LowExprKind.SpecialBinary.Kind.lessPtr :
				failBinary());
		case sym!"new-void".value:
			return isVoid(rt)
				? constant(immutable Constant(immutable Constant.Void()))
				: fail();
		case sym!"null".value:
			return constant(immutable Constant(immutable Constant.Null()));
		case sym!"set-deref".value:
			return binary(isPtrRawMut(p0) ? LowExprKind.SpecialBinary.Kind.writeToPtr : failBinary());
		case sym!"size-of".value:
			return immutable BuiltinKind(immutable BuiltinKind.SizeOf());
		case sym!"subscript".value:
			return isFunPtrType(p0)
				? immutable BuiltinKind(immutable BuiltinKind.CallFunPointer())
				: fail();
		case sym!"to-char8".value:
			return unary(isNat8(p0)
				? LowExprKind.SpecialUnary.Kind.toChar8FromNat8
				: failUnary());
		case sym!"to-float32".value:
			return unary(isFloat64(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64
				: failUnary());
		case sym!"to-float64".value:
			return unary(isInt64(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromInt64
				: isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromNat64
				: isFloat32(p0)
				? LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32
				: failUnary());
		case sym!"to-int64".value:
			return unary(isInt16(p0)
				? LowExprKind.SpecialUnary.Kind.toInt64FromInt16
				: isInt32(p0)
				? LowExprKind.SpecialUnary.Kind.toInt64FromInt32
				: failUnary());
		case sym!"to-nat64".value:
			return unary(isNat8(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat8
				: isNat16(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat16
				: isNat32(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromNat32
				: isPtrRawConstOrMut(p0)
				? LowExprKind.SpecialUnary.Kind.toNat64FromPtr
				: failUnary());
		case sym!"to-nat8".value:
			return unary(isChar(p0)
				? LowExprKind.SpecialUnary.Kind.toNat8FromChar8
				: failUnary());
		case sym!"to-mut-pointer".value:
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.toPtrFromNat64
				: failUnary());
		case sym!"true".value:
			return constantBool(true);
		case sym!"unsafe-add".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt64
				: failBinary());
		case sym!"unsafe-div".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat32
				: isFloat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat64
				: isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivInt64
				: isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivNat64
				: failBinary());
		case sym!"unsafe-mod".value:
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeModNat64) : fail();
		case sym!"unsafe-mul".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt64
				: failBinary());
		case sym!"unsafe-sub".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt64
				: failBinary());
		case sym!"wrap-add".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat64
				: failBinary());
		case sym!"wrap-mul".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat64
				: failBinary());
		case sym!"wrap-sub".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat64
				: failBinary());
		case sym!"zeroed".value:
			return immutable BuiltinKind(immutable BuiltinKind.Zeroed());
		case sym!"as-any-mut-pointer".value:
			return unary(LowExprKind.SpecialUnary.Kind.asAnyPtr);
		case sym!"init-constants".value:
			return immutable BuiltinKind(immutable BuiltinKind.InitConstants());
		case sym!"pointer-cast-from-extern".value:
		case sym!"pointer-cast-to-extern".value:
			return immutable BuiltinKind(immutable BuiltinKind.PointerCast());
		case sym!"static-symbols".value:
			return immutable BuiltinKind(immutable BuiltinKind.StaticSymbols());
		case sym!"truncate-to-int64".value:
			return unary(isFloat64(p0)
				? LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64
				: failUnary());
		case sym!"unsafe-bit-shift-left".value:
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64) : fail();
		case sym!"unsafe-bit-shift-right".value:
			return isNat64(rt)
				? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64)
				: fail();
		case sym!"unsafe-to-int8".value:
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt8) : fail();
		case sym!"unsafe-to-int16".value:
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt16) : fail();
		case sym!"unsafe-to-int32".value:
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToInt32) : fail();
		case sym!"unsafe-to-int64".value:
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToInt64) : fail();
		case sym!"unsafe-to-nat8".value:
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat8) : fail();
		case sym!"unsafe-to-nat16".value:
			return isNat64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat16): fail();
		case sym!"unsafe-to-nat32".value:
			return unary(isInt32(p0)
				? LowExprKind.SpecialUnary.Kind.unsafeInt32ToNat32
				: isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.unsafeNat64ToNat32
				: failUnary());
		case sym!"unsafe-to-nat64".value:
			return isInt64(p0) ? unary(LowExprKind.SpecialUnary.Kind.unsafeInt64ToNat64) : fail();
		default:
			return fail();
	}
}

private:

immutable(bool) isPrimitiveType(immutable LowType a, immutable PrimitiveType p) =>
	isPrimitive(a) && asPrimitive(a) == p;

immutable(bool) isBool(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.bool_);

immutable(bool) isChar(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.char8);

immutable(bool) isInt8(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.int8);

immutable(bool) isInt16(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.int16);

immutable(bool) isInt32(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.int32);

immutable(bool) isInt64(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.int64);

immutable(bool) isNat8(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat8);

immutable(bool) isNat16(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat16);

immutable(bool) isNat32(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat32);

immutable(bool) isNat64(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat64);

immutable(bool) isFloat32(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.float32);

immutable(bool) isFloat64(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.float64);

immutable(bool) isVoid(immutable LowType a) =>
	isPrimitiveType(a, PrimitiveType.void_);
