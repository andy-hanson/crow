module interpret.applyFn;

@safe @nogc pure nothrow:

import util.conv : bitsOfFloat32, bitsOfFloat64, float32OfBits, float64OfBits;
import util.util : verify;

immutable(ulong) fnAddFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x + y)(a, b);
}
immutable(ulong) fnAddFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x + y)(a, b);
}
immutable(ulong) fnBitwiseNot(immutable ulong a) {
	return ~a;
}
immutable(ulong) fnBitwiseAnd(immutable ulong a, immutable ulong b) {
	return a & b;
}
immutable(ulong) fnBitwiseOr(immutable ulong a, immutable ulong b) {
	return a | b;
}
immutable(ulong) fnBitwiseXor(immutable ulong a, immutable ulong b) {
	return a ^ b;
}
immutable(ulong) fnCountOnesNat64(immutable ulong a) {
	return popcount(a);
}
immutable(ulong) fnEqBits(immutable ulong a, immutable ulong b) {
	return a == b;
}
immutable(ulong) fnEqFloat32(immutable ulong a, immutable ulong b) {
	return float32OfBits(a) == float32OfBits(b);
}
immutable(ulong) fnEqFloat64(immutable ulong a, immutable ulong b) {
	return float64OfBits(a) == float64OfBits(b);
}
immutable(ulong) fnFloat32FromFloat64(immutable ulong a) {
	return bitsOfFloat32(cast(float) float64OfBits(a));
}
immutable(ulong) fnFloat64FromFloat32(immutable ulong a) {
	return bitsOfFloat64(cast(double) float32OfBits(a));
}
immutable(ulong) fnFloat64FromInt64(immutable ulong a) {
	return bitsOfFloat64(cast(double) (cast(long) a));
}
immutable(ulong) fnFloat64FromNat64(immutable ulong a) {
	return bitsOfFloat64(cast(double) a);
}
immutable(ulong) fnInt64FromInt16(immutable ulong a) {
	return cast(ulong) (cast(long) (cast(short) a));
}
immutable(ulong) fnInt64FromInt32(immutable ulong a) {
	return u64OfI32(cast(int) a);
}
immutable(ulong) fnLessFloat32(immutable ulong a, immutable ulong b) {
	return float32OfBits(a) < float32OfBits(b);
}
immutable(ulong) fnLessFloat64(immutable ulong a, immutable ulong b) {
	return float64OfBits(a) < float64OfBits(b);
}
private immutable(ulong) fnLessT(T)(immutable ulong a, immutable ulong b) {
	return (cast(immutable T) a) < (cast(immutable T) b);
}
alias fnLessInt8 = fnLessT!(immutable byte);
alias fnLessInt16 = fnLessT!(immutable short);
alias fnLessInt32 = fnLessT!(immutable int);
alias fnLessInt64 = fnLessT!(immutable long);
alias fnLessNat8 = fnLessT!(immutable ubyte);
alias fnLessNat16 = fnLessT!(immutable ushort);
alias fnLessNat32 = fnLessT!(immutable uint);
alias fnLessNat64 = fnLessT!(immutable ulong);
immutable(ulong) fnMulFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x * y)(a, b);
}
immutable(ulong) fnMulFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x * y)(a, b);
}
immutable(ulong) fnSubFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x - y)(a, b);
}
immutable(ulong) fnSubFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x - y)(a, b);
}
immutable(ulong) fnTruncateToInt64FromFloat64(immutable ulong a) {
	return cast(ulong) cast(long) float64OfBits(a);
}
immutable(ulong) fnUnsafeBitShiftLeftNat64(immutable ulong a, immutable ulong b) {
	verify(b < 64);
	return a << b;
}
immutable(ulong) fnUnsafeBitShiftRightNat64(immutable ulong a, immutable ulong b) {
	verify(b < 64);
	return a >> b;
}
immutable(ulong) fnUnsafeDivFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x / y)(a, b);
}
immutable(ulong) fnUnsafeDivFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x / y)(a, b);
}
immutable(ulong) fnUnsafeDivInt8(immutable ulong a, immutable ulong b) {
	return cast(byte) a / cast(byte) b;
}
immutable(ulong) fnUnsafeDivInt16(immutable ulong a, immutable ulong b) {
	return cast(short) a / cast(short) b;
}
immutable(ulong) fnUnsafeDivInt32(immutable ulong a, immutable ulong b) {
	return cast(int) a / cast(int) b;
}
immutable(ulong) fnUnsafeDivInt64(immutable ulong a, immutable ulong b) {
	return cast(ulong) ((cast(long) a) / (cast(long) b));
}
immutable(ulong) fnUnsafeDivNat8(immutable ulong a, immutable ulong b) {
	return cast(ubyte) a / cast(ubyte) b;
}
immutable(ulong) fnUnsafeDivNat16(immutable ulong a, immutable ulong b) {
	return cast(ushort) a / cast(ushort) b;
}
immutable(ulong) fnUnsafeDivNat32(immutable ulong a, immutable ulong b) {
	return cast(uint) a / cast(uint) b;
}
immutable(ulong) fnUnsafeDivNat64(immutable ulong a, immutable ulong b) {
	return a / b;
}
immutable(ulong) fnUnsafeModNat64(immutable ulong a, immutable ulong b) {
	return a % b;
}
immutable(ulong) fnWrapAddIntegral(immutable ulong a, immutable ulong b) {
	return a + b;
}
immutable(ulong) fnWrapMulIntegral(immutable ulong a, immutable ulong b) {
	return a * b;
}
immutable(ulong) fnWrapSubIntegral(immutable ulong a, immutable ulong b) {
	return a - b;
}

//TODO:MOVE
pure immutable(ulong) u64OfI32(immutable int a) {
	return u64OfI64(a);
}

pure immutable(ulong) u64OfI64(immutable long a) {
	return cast(ulong) a;
}

private:

immutable(ulong) binaryFloat32s(alias cb)(immutable ulong a, immutable ulong b) {
	return bitsOfFloat32(cb(float32OfBits(a), float32OfBits(b)));
}

immutable(ulong) binaryFloat64s(alias cb)(immutable ulong a, immutable ulong b) {
	return bitsOfFloat64(cb(float64OfBits(a), float64OfBits(b)));
}

//TODO:PERF
pure immutable(long) popcount(immutable ulong a) {
	return a == 0
		? 0
		: popcount(a >> 1) + (a % 2 != 0 ? 1 : 0);
}
