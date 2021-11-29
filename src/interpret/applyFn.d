module interpret.applyFn;

@safe @nogc pure nothrow:

import util.types :
	bottomU16OfU64,
	bottomU32OfU64,
	float32OfU64Bits,
	float64OfU64Bits,
	Nat64,
	u64OfFloat32Bits,
	u64OfFloat64Bits;
import util.util : verify;

immutable(Nat64) fnAddFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x + y)(a, b);
}
immutable(Nat64) fnAddFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x + y)(a, b);
}
immutable(Nat64) fnBitwiseNot(immutable ulong a) {
	return immutable Nat64(~a);
}
immutable(Nat64) fnBitwiseAnd(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a & b);
}
immutable(Nat64) fnBitwiseOr(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a | b);
}
immutable(Nat64) fnBitwiseXor(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a ^ b);
}
immutable(Nat64) fnCountOnesNat64(immutable ulong a) {
	return immutable Nat64(popcount(a));
}
immutable(Nat64) fnEqBits(immutable ulong a, immutable ulong b) {
	return u64OfBool(a == b);
}
immutable(Nat64) fnEqFloat64(immutable ulong a, immutable ulong b) {
	return u64OfBool(float64OfU64Bits(a) == float64OfU64Bits(b));
}
immutable(Nat64) fnFloat64FromFloat32(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) float32OfU64Bits(a));
}
immutable(Nat64) fnFloat64FromInt64(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) (cast(long) a));
}
immutable(Nat64) fnFloat64FromNat64(immutable ulong a) {
	return u64OfFloat64Bits(cast(double) a);
}
immutable(Nat64) fnInt64FromInt16(immutable ulong a) {
	return immutable Nat64(cast(ulong) (cast(long) (cast(short) (bottomU16OfU64(a)))));
}
immutable(Nat64) fnInt64FromInt32(immutable ulong a) {
	return nat64OfI32(cast(int) (bottomU32OfU64(a)));
}
immutable(Nat64) fnIsNanFloat32(immutable ulong a) {
	return u64OfBool(isNaN(float32OfU64Bits(a)));
}
immutable(Nat64) fnIsNanFloat64(immutable ulong a) {
	return u64OfBool(isNaN(float64OfU64Bits(a)));
}
immutable(Nat64) fnLessFloat32(immutable ulong a, immutable ulong b) {
	return u64OfBool(float32OfU64Bits(a) < float32OfU64Bits(b));
}
immutable(Nat64) fnLessFloat64(immutable ulong a, immutable ulong b) {
	return u64OfBool(float64OfU64Bits(a) < float64OfU64Bits(b));
}
immutable(Nat64) fnLessInt8(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(byte) a) < (cast(byte) b));
}
immutable(Nat64) fnLessInt16(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(short) a) < (cast(short) b));
}
immutable(Nat64) fnLessInt32(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(int) a) < (cast(int) b));
}
immutable(Nat64) fnLessInt64(immutable ulong a, immutable ulong b) {
	return u64OfBool((cast(long) a) < (cast(long) b));
}
immutable(Nat64) fnLessNat(immutable ulong a, immutable ulong b) {
	return u64OfBool(a < b);
}
immutable(Nat64) fnMulFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x * y)(a, b);
}
immutable(Nat64) fnSubFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x - y)(a, b);
}
immutable(Nat64) fnTruncateToInt64FromFloat64(immutable ulong a) {
	return immutable Nat64(cast(ulong) cast(long) float64OfU64Bits(a));
}
immutable(Nat64) fnUnsafeBitShiftLeftNat64(immutable ulong a, immutable ulong b) {
	verify(b < 64);
	return immutable Nat64(a << b);
}
immutable(Nat64) fnUnsafeBitShiftRightNat64(immutable ulong a, immutable ulong b) {
	verify(b < 64);
	return immutable Nat64(a >> b);
}
immutable(Nat64) fnUnsafeDivFloat32(immutable ulong a, immutable ulong b) {
	return binaryFloat32s!((immutable float x, immutable float y) => x / y)(a, b);
}
immutable(Nat64) fnUnsafeDivFloat64(immutable ulong a, immutable ulong b) {
	return binaryFloat64s!((immutable double x, immutable double y) => x / y)(a, b);
}
immutable(Nat64) fnUnsafeDivInt64(immutable ulong a, immutable ulong b) {
	return immutable Nat64(cast(ulong) ((cast(long) a) / (cast(long) b)));
}
immutable(Nat64) fnUnsafeDivNat64(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a / b);
}
immutable(Nat64) fnUnsafeModNat64(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a % b);
}
immutable(Nat64) fnWrapAddIntegral(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a + b);
}
immutable(Nat64) fnWrapMulIntegral(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a * b);
}
immutable(Nat64) fnWrapSubIntegral(immutable ulong a, immutable ulong b) {
	return immutable Nat64(a - b);
}

//TODO:MOVE
pure immutable(Nat64) nat64OfI32(immutable int a) {
	return nat64OfI64(a);
}

pure immutable(Nat64) nat64OfI64(immutable long a) {
	return immutable Nat64(cast(ulong) a);
}

private:

pure immutable(Nat64) u64OfBool(immutable bool value) {
	return immutable Nat64(value ? 1 : 0);
}

immutable(Nat64) binaryFloat32s(alias cb)(immutable ulong a, immutable ulong b) {
	return u64OfFloat32Bits(cb(float32OfU64Bits(a), float32OfU64Bits(b)));
}

immutable(Nat64) binaryFloat64s(alias cb)(immutable ulong a, immutable ulong b) {
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
