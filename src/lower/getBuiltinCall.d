module lower.getBuiltinCall;

@safe @nogc pure nothrow:

import model.constant : Constant, constantBool, constantZero;
import model.lowModel : isPrimitiveType, isPtrRawConstOrMut, LowExprKind, LowType, PrimitiveType;
import util.alloc.alloc : Alloc;
import util.symbol : AllSymbols, Symbol, symbol, writeSymbol;
import util.union_ : Union;
import util.util : todo;
import util.writer : debugLogWithWriter, Writer;

immutable struct BuiltinKind {
	immutable struct CallFunPointer {}
	immutable struct InitConstants {}
	immutable struct OptOr {}
	immutable struct OptQuestion2 {}
	immutable struct PointerCast {}
	immutable struct SizeOf {}
	immutable struct StaticSymbols {}

	mixin Union!(
		CallFunPointer,
		Constant,
		InitConstants,
		LowExprKind.SpecialUnary.Kind,
		LowExprKind.SpecialBinary.Kind,
		LowExprKind.SpecialTernary.Kind,
		OptOr,
		OptQuestion2,
		PointerCast,
		SizeOf,
		StaticSymbols);
}

BuiltinKind getBuiltinKind(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	Symbol name,
	LowType rt,
	size_t arity,
	LowType p0,
	LowType p1,
) {
	BuiltinKind unary(LowExprKind.SpecialUnary.Kind kind) {
		assert(arity == 1);
		return BuiltinKind(kind);
	}
	BuiltinKind binary(LowExprKind.SpecialBinary.Kind kind) {
		assert(arity == 2);
		return BuiltinKind(kind);
	}
	T failT(T)() {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "not a builtin fun: ";
			writeSymbol(writer, allSymbols, name);
		});
		return todo!T("not a builtin fun");
	}
	BuiltinKind fail() {
		return failT!BuiltinKind;
	}
	LowExprKind.SpecialUnary.Kind failUnary() {
		return failT!(LowExprKind.SpecialUnary.Kind);
	}
	LowExprKind.SpecialBinary.Kind failBinary() {
		return failT!(LowExprKind.SpecialBinary.Kind);
	}

	bool isUnaryFloat32() =>
		arity == 1 && isFloat32(rt) && isFloat32(p0);
	bool isUnaryFloat64() =>
		arity == 1 && isFloat64(rt) && isFloat64(p0);
	bool isBinaryFloat32() =>
		arity == 2 && isFloat32(rt) && isFloat32(p0) && isFloat32(p1);
	bool isBinaryFloat64() =>
		arity == 2 && isFloat64(rt) && isFloat64(p0) && isFloat64(p1);

	BuiltinKind unaryFloat64(LowExprKind.SpecialUnary.Kind kind) =>
		unary(isUnaryFloat64() ? kind : failUnary());
	BuiltinKind unaryFloat32Or64(LowExprKind.SpecialUnary.Kind kind32, LowExprKind.SpecialUnary.Kind kind64) =>
		unary(isUnaryFloat32() ? kind32 : isUnaryFloat64() ? kind64 : failUnary());
	BuiltinKind binaryFloat64(LowExprKind.SpecialBinary.Kind kind) =>
		binary(isBinaryFloat64() ? kind : failBinary());
	BuiltinKind binaryFloat32Or64(LowExprKind.SpecialBinary.Kind kind32, LowExprKind.SpecialBinary.Kind kind64) =>
		binary(isBinaryFloat32() ? kind32 : isBinaryFloat64() ? kind64 : failBinary());

	switch (name.value) {
		case symbol!"+".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.addFloat32
				: isBinaryFloat64()
				? LowExprKind.SpecialBinary.Kind.addFloat64
				: isPtrRawConstOrMut(rt) && isPtrRawConstOrMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.addPtrAndNat64
				: failBinary());
		case symbol!"-".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.subFloat32
				: isBinaryFloat64()
				? LowExprKind.SpecialBinary.Kind.subFloat64
				: isPtrRawConstOrMut(rt) && isPtrRawConstOrMut(p0) && isNat64(p1)
				? LowExprKind.SpecialBinary.Kind.subPtrAndNat64
				: failBinary());
		case symbol!"*".value:
			return isPtrRawConstOrMut(p0)
				? unary(LowExprKind.SpecialUnary.Kind.deref)
				: binary(isFloat32(rt)
					? LowExprKind.SpecialBinary.Kind.mulFloat32
					: isBinaryFloat64()
					? LowExprKind.SpecialBinary.Kind.mulFloat64
					: failBinary());
		case symbol!"==".value:
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
		case symbol!"&&".value:
			return binary(LowExprKind.SpecialBinary.Kind.and);
		case symbol!"||".value:
			return isBool(rt)
				? binary(LowExprKind.SpecialBinary.Kind.orBool)
				: BuiltinKind(BuiltinKind.OptOr());
		case symbol!"??".value:
			return BuiltinKind(BuiltinKind.OptQuestion2());
		case symbol!"&".value:
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
		case symbol!"~".value:
			return unary(isNat8(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat8
				: isNat16(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat16
				: isNat32(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat32
				: isNat64(rt)
				? LowExprKind.SpecialUnary.Kind.bitwiseNotNat64
				: failUnary());
		case symbol!"|".value:
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
		case symbol!"^".value:
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
		case symbol!"acos".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.acosFloat32, LowExprKind.SpecialUnary.Kind.acosFloat64);
		case symbol!"acosh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.acoshFloat32, LowExprKind.SpecialUnary.Kind.acoshFloat64);
		case symbol!"asin".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.asinFloat32, LowExprKind.SpecialUnary.Kind.asinFloat64);
		case symbol!"asinh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.asinhFloat32, LowExprKind.SpecialUnary.Kind.asinhFloat64);
		case symbol!"atan".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.atanFloat32, LowExprKind.SpecialUnary.Kind.atanFloat64);
		case symbol!"atan2".value:
			return binaryFloat32Or64(
				LowExprKind.SpecialBinary.Kind.atan2Float32, LowExprKind.SpecialBinary.Kind.atan2Float64);
		case symbol!"atanh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.atanhFloat32, LowExprKind.SpecialUnary.Kind.atanhFloat64);
		case symbol!"as-const".value:
		case symbol!"as-fun-pointer".value:
		case symbol!"as-mut".value:
		case symbol!"pointer-cast".value:
			return BuiltinKind(BuiltinKind.PointerCast());
		case symbol!"count-ones".value:
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.countOnesNat64
				: failUnary());
		case symbol!"cos".value:
			return unaryFloat32Or64(LowExprKind.SpecialUnary.Kind.cosFloat32, LowExprKind.SpecialUnary.Kind.cosFloat64);
		case symbol!"cosh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.coshFloat32, LowExprKind.SpecialUnary.Kind.coshFloat64);
		case symbol!"false".value:
			return BuiltinKind(constantBool(false));
		case symbol!"interpreter-backtrace".value:
			return BuiltinKind(LowExprKind.SpecialTernary.Kind.interpreterBacktrace);
		case symbol!"is-less".value:
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
		case symbol!"new-void".value:
			return isVoid(rt)
				? BuiltinKind(constantZero)
				: fail();
		case symbol!"null".value:
			return BuiltinKind(constantZero);
		case symbol!"reference-equal".value:
			return binary(LowExprKind.SpecialBinary.Kind.eqPtr);
		case symbol!"round".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.roundFloat32, LowExprKind.SpecialUnary.Kind.roundFloat64);
		case symbol!"set-deref".value:
			return binary(p0.isA!(LowType.PtrRawMut) ? LowExprKind.SpecialBinary.Kind.writeToPtr : failBinary());
		case symbol!"sin".value:
			return unaryFloat32Or64(LowExprKind.SpecialUnary.Kind.sinFloat32, LowExprKind.SpecialUnary.Kind.sinFloat64);
		case symbol!"sinh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.sinhFloat32, LowExprKind.SpecialUnary.Kind.sinhFloat64);
		case symbol!"size-of".value:
			return BuiltinKind(BuiltinKind.SizeOf());
		case symbol!"subscript".value:
			return p0.isA!(LowType.FunPointer)
				? BuiltinKind(BuiltinKind.CallFunPointer())
				// 'subscript' for fun / act is handled elsewhere, see concreteFunWillBecomeNonExternLowFun
				: fail();
		case symbol!"sqrt".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.sqrtFloat32, LowExprKind.SpecialUnary.Kind.sqrtFloat64);
		case symbol!"tan".value:
			return unaryFloat32Or64(LowExprKind.SpecialUnary.Kind.tanFloat32, LowExprKind.SpecialUnary.Kind.tanFloat64);
		case symbol!"tanh".value:
			return unaryFloat32Or64(
				LowExprKind.SpecialUnary.Kind.tanhFloat32, LowExprKind.SpecialUnary.Kind.tanhFloat64);
		case symbol!"to".value:
			return unary(isChar8(rt)
				? isNat8(p0)
					? LowExprKind.SpecialUnary.Kind.toChar8FromNat8
					: failUnary()
			: isFloat32(rt)
				? isFloat64(p0)
					? LowExprKind.SpecialUnary.Kind.toFloat32FromFloat64
					: failUnary()
			: isFloat64(rt)
				? isInt64(p0)
					? LowExprKind.SpecialUnary.Kind.toFloat64FromInt64
					: isNat64(p0)
					? LowExprKind.SpecialUnary.Kind.toFloat64FromNat64
					: isFloat32(p0)
					? LowExprKind.SpecialUnary.Kind.toFloat64FromFloat32
					: failUnary()
			: isInt64(rt)
				? isInt8(p0)
					? LowExprKind.SpecialUnary.Kind.toInt64FromInt8
					: isInt16(p0)
					? LowExprKind.SpecialUnary.Kind.toInt64FromInt16
					: isInt32(p0)
					? LowExprKind.SpecialUnary.Kind.toInt64FromInt32
					: failUnary()
			: isNat8(rt)
				? isChar8(p0)
					? LowExprKind.SpecialUnary.Kind.toNat8FromChar8
					: failUnary()
			: isNat64(rt)
				? isNat8(p0)
					? LowExprKind.SpecialUnary.Kind.toNat64FromNat8
					: isNat16(p0)
					? LowExprKind.SpecialUnary.Kind.toNat64FromNat16
					: isNat32(p0)
					? LowExprKind.SpecialUnary.Kind.toNat64FromNat32
					: isPtrRawConstOrMut(p0)
					? LowExprKind.SpecialUnary.Kind.toNat64FromPtr
					: failUnary()
			: failUnary());
		case symbol!"to-mut-pointer".value:
			return unary(isNat64(p0)
				? LowExprKind.SpecialUnary.Kind.toPtrFromNat64
				: failUnary());
		case symbol!"true".value:
			return BuiltinKind(constantBool(true));
		case symbol!"unsafe-add".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeAddInt64
				: failBinary());
		case symbol!"unsafe-div".value:
			return binary(isFloat32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeDivFloat32
				: isBinaryFloat64()
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
		case symbol!"unsafe-mod".value:
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeModNat64) : fail();
		case symbol!"unsafe-mul".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeMulInt64
				: failBinary());
		case symbol!"unsafe-sub".value:
			return binary(isInt8(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt8
				: isInt16(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt16
				: isInt32(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt32
				: isInt64(rt)
				? LowExprKind.SpecialBinary.Kind.unsafeSubInt64
				: failBinary());
		case symbol!"wrap-add".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapAddNat64
				: failBinary());
		case symbol!"wrap-mul".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapMulNat64
				: failBinary());
		case symbol!"wrap-sub".value:
			return binary(isNat8(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat8
				: isNat16(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat16
				: isNat32(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat32
				: isNat64(rt)
				? LowExprKind.SpecialBinary.Kind.wrapSubNat64
				: failBinary());
		case symbol!"zeroed".value:
			return BuiltinKind(constantZero);
		case symbol!"as-any-mut-pointer".value:
			return unary(LowExprKind.SpecialUnary.Kind.asAnyPtr);
		case symbol!"init-constants".value:
			return BuiltinKind(BuiltinKind.InitConstants());
		case symbol!"pointer-cast-from-extern".value:
		case symbol!"pointer-cast-to-extern".value:
			return BuiltinKind(BuiltinKind.PointerCast());
		case symbol!"static-symbols".value:
			return BuiltinKind(BuiltinKind.StaticSymbols());
		case symbol!"truncate-to".value:
			return unary(isFloat64(p0)
				? LowExprKind.SpecialUnary.Kind.truncateToInt64FromFloat64
				: failUnary());
		case symbol!"unsafe-bit-shift-left".value:
			return isNat64(rt) ? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftLeftNat64) : fail();
		case symbol!"unsafe-bit-shift-right".value:
			return isNat64(rt)
				? binary(LowExprKind.SpecialBinary.Kind.unsafeBitShiftRightNat64)
				: fail();
		case symbol!"unsafe-to".value:
			return unary(isInt8(rt)
				? isInt64(p0)
					? LowExprKind.SpecialUnary.Kind.unsafeToInt8FromInt64
					: failUnary()
				: isInt16(rt)
					? isInt64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToInt16FromInt64
						: failUnary()
				: isInt32(rt)
					? isInt64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToInt32FromInt64
						: failUnary()
				: isInt64(rt)
					? isNat64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToInt64FromNat64
						: failUnary()
				: isNat8(rt)
					? isNat64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToNat8FromNat64
						: failUnary()
				: isNat16(rt)
					? isNat64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToNat16FromNat64
						: failUnary()
				: isNat32(rt)
					? isInt32(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToNat32FromInt32
						: isNat64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToNat32FromNat64
						: failUnary()
				: isNat64(rt)
					? isInt64(p0)
						? LowExprKind.SpecialUnary.Kind.unsafeToNat64FromInt64
						: failUnary()
				: failUnary());
		default:
			return fail();
	}
}

private:

bool isBool(LowType a) =>
	isPrimitiveType(a, PrimitiveType.bool_);

bool isChar8(LowType a) =>
	isPrimitiveType(a, PrimitiveType.char8);

bool isInt8(LowType a) =>
	isPrimitiveType(a, PrimitiveType.int8);

bool isInt16(LowType a) =>
	isPrimitiveType(a, PrimitiveType.int16);

bool isInt32(LowType a) =>
	isPrimitiveType(a, PrimitiveType.int32);

bool isInt64(LowType a) =>
	isPrimitiveType(a, PrimitiveType.int64);

bool isNat8(LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat8);

bool isNat16(LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat16);

bool isNat32(LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat32);

bool isNat64(LowType a) =>
	isPrimitiveType(a, PrimitiveType.nat64);

bool isFloat32(LowType a) =>
	isPrimitiveType(a, PrimitiveType.float32);

bool isFloat64(LowType a) =>
	isPrimitiveType(a, PrimitiveType.float64);

bool isVoid(LowType a) =>
	isPrimitiveType(a, PrimitiveType.void_);
