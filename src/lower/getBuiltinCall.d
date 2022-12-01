module lower.getBuiltinCall;

@safe @nogc pure nothrow:

import model.constant : Constant, constantBool, constantZero;
import model.lowModel : isPtrRawConstOrMut, LowExprKind, LowType, PrimitiveType;
import util.alloc.alloc : Alloc;
import util.sym : AllSymbols, safeCStrOfSym, Sym, sym;
import util.union_ : Union;
import util.util : debugLog, todo;

struct BuiltinKind {
	struct CallFunPointer {}
	struct InitConstants {}
	struct OptOr {}
	struct OptQuestion2 {}
	struct PointerCast {}
	struct SizeOf {}
	struct StaticSymbols {}

	mixin Union!(
		immutable CallFunPointer,
		immutable Constant,
		immutable InitConstants,
		immutable LowExprKind.SpecialUnary.Kind,
		immutable LowExprKind.SpecialBinary.Kind,
		immutable LowExprKind.SpecialTernary.Kind,
		immutable OptOr,
		immutable OptQuestion2,
		immutable PointerCast,
		immutable SizeOf,
		immutable StaticSymbols);
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
			return constant(constantBool(false));
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
				? constant(constantZero)
				: fail();
		case sym!"null".value:
			return constant(constantZero);
		case sym!"set-deref".value:
			return binary(p0.isA!(LowType.PtrRawMut) ? LowExprKind.SpecialBinary.Kind.writeToPtr : failBinary());
		case sym!"size-of".value:
			return immutable BuiltinKind(immutable BuiltinKind.SizeOf());
		case sym!"subscript".value:
			return p0.isA!(LowType.FunPtr)
				? immutable BuiltinKind(immutable BuiltinKind.CallFunPointer())
				// 'subscript' for fun / act is handled elsewhere, see concreteFunWillBecomeNonExternLowFun
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
			return constant(constantBool(true));
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
			return constant(constantZero);
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
	a.isA!PrimitiveType && a.as!PrimitiveType == p;

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
