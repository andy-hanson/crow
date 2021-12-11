module interpret.applyFn;

@safe @nogc pure nothrow:

import util.types :
	bottomU16OfU64,
	bottomU32OfU64,
	float32OfU64Bits,
	float64OfU64Bits,
	u64OfFloat32Bits,
	u64OfFloat64Bits;
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
	return u64OfBool(a == b);
}
immutable(ulong) fnEqFloat64(immutable ulong a, immutable ulong b) {
	return u64OfBool(float64OfU64Bits(a) == float64OfU64Bits(b));
}
immutable(ulong) fnFloat64FromFloat32(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) float32OfU64Bits(a));
}
immutable(ulong) fnFloat64FromInt64(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) (cast(long) a));
}
immutable(ulong) fnFloat64FromNat64(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) a);
}
immutable(ulong) fnInt64FromInt16(immutable ulong a) {
	return cast(ulong) (cast(long) (cast(short) (bottomU16OfU64(a))));
}
immutable(ulong) fnInt64FromInt32(immutable ulong a) {
	return u64OfI32(cast(int) (bottomU32OfU64(a)));
}
immutable(ulong) fnIsNanFloat32(immutable ulong a) {
	return u64OfBool(isNaN(float32OfU64Bits(a)));
}
immutable(ulong) fnIsNanFloat64(immutable ulong a) {
	return u64OfBool(isNaN(float64OfU64Bits(a)));
}
immutable(ulong) fnLessFloat32(immutable ulong a, immutable ulong b) {
	return u64OfBool(float32OfU64Bits(a) < float32OfU64Bits(b));
}
immutable(ulong) fnLessFloat64(immutable ulong a, immutable ulong b) {
	return u64OfBool(float64OfU64Bits(a) < float64OfU64Bits(b));
}
immutable(ulong) fnLessInt8(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(byte) a) < (cast(byte) b));
}
immutable(ulong) fnLessInt16(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(short) a) < (cast(short) b));
}
immutable(ulong) fnLessInt32(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(int) a) < (cast(int) b));
}
immutable(ulong) fnLessInt64(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(long) a) < (cast(long) b));
}
immutable(ulong) fnLessNat(immutable ulong a, immutable ulong b) {
	return u64OfBool(a < b);
}
immutable(ulong) fnMulFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x * y)(a, b);
}
immutable(ulong) fnSubFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x - y)(a, b);
}
immutable(ulong) fnTruncateToInt64FromFloat64(immutable ulong a) {
	return cast(ulong) cast(long) float64OfU64Bits(a);
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
immutable(ulong) fnUnsafeDivInt64(immutable ulong a, immutable ulong b) {
	return cast(ulong) ((cast(long) a) / (cast(long) b));
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

pure immutable(ulong) u64OfBool(immutable bool value) {
	return value ? 1 : 0;
}

immutable(ulong) binaryFloat32s(alias cb)(immutable ulong a, immutable ulong b) {
	return u64OfFloat32Bits(cb(float32OfU64Bits(a), float32OfU64Bits(b)));
}

immutable(ulong) binaryFloat64s(alias cb)(immutable ulong a, immutable ulong b) {
	return u64OfFloat64Bits(cb(float64OfU64Bits(a), float64OfU64Bits(b)));
}

pure immutable(bool) isNaN(immutable double a) {
	return a != a;
}

//TODO:PERF
pure immutable(long) popcount(immutable ulong a) {
	return a == 0
		? 0
		: popcount(a >> 1) + (a % 2 != 0 ? 1 : 0);
}
