module interpret.applyFn;

@safe @nogc pure nothrow:

import util.conv : bitsOfFloat32, bitsOfFloat64, float32OfBits, float64OfBits;
import util.util : verify;

ulong fnAddFloat32(ulong a, ulong b) =>
	binaryFloat32s!((float x, float y) => x + y)(a, b);
ulong fnAddFloat64(ulong a, ulong b) =>
	binaryFloat64s!((double x, double y) => x + y)(a, b);
ulong fnBitwiseNot(ulong a) =>
	~a;
ulong fnBitwiseAnd(ulong a, ulong b) =>
	a & b;
ulong fnBitwiseOr(ulong a, ulong b) =>
	a | b;
ulong fnBitwiseXor(ulong a, ulong b) =>
	a ^ b;
ulong fnCountOnesNat64(ulong a) =>
	popcount(a);
ulong fnEqBits(ulong a, ulong b) =>
	a == b;
ulong fnEqFloat32(ulong a, ulong b) =>
	float32OfBits(a) == float32OfBits(b);
ulong fnEqFloat64(ulong a, ulong b) =>
	float64OfBits(a) == float64OfBits(b);
ulong fnFloat32FromFloat64(ulong a) =>
	bitsOfFloat32(cast(float) float64OfBits(a));
ulong fnFloat64FromFloat32(ulong a) =>
	bitsOfFloat64(cast(double) float32OfBits(a));
ulong fnFloat64FromInt64(ulong a) =>
	bitsOfFloat64(cast(double) (cast(long) a));
ulong fnFloat64FromNat64(ulong a) =>
	bitsOfFloat64(cast(double) a);
ulong fnInt64FromInt8(ulong a) =>
	cast(ulong) (cast(long) (cast(byte) a));
ulong fnInt64FromInt16(ulong a) =>
	cast(ulong) (cast(long) (cast(short) a));
ulong fnInt64FromInt32(ulong a) =>
	u64OfI32(cast(int) a);
ulong fnLessFloat32(ulong a, ulong b) =>
	float32OfBits(a) < float32OfBits(b);
ulong fnLessFloat64(ulong a, ulong b) =>
	float64OfBits(a) < float64OfBits(b);
private ulong fnLessT(T)(ulong a, ulong b) =>
	(cast(T) a) < (cast(T) b);
alias fnLessInt8 = fnLessT!byte;
alias fnLessInt16 = fnLessT!short;
alias fnLessInt32 = fnLessT!int;
alias fnLessInt64 = fnLessT!long;
alias fnLessNat8 = fnLessT!ubyte;
alias fnLessNat16 = fnLessT!ushort;
alias fnLessNat32 = fnLessT!uint;
alias fnLessNat64 = fnLessT!ulong;
ulong fnMulFloat32(ulong a, ulong b) =>
	binaryFloat32s!((float x, float y) => x * y)(a, b);
ulong fnMulFloat64(ulong a, ulong b) =>
	binaryFloat64s!((double x, double y) => x * y)(a, b);
ulong fnSubFloat32(ulong a, ulong b) =>
	binaryFloat32s!((float x, float y) => x - y)(a, b);
ulong fnSubFloat64(ulong a, ulong b) =>
	binaryFloat64s!((double x, double y) => x - y)(a, b);
ulong fnTruncateToInt64FromFloat64(ulong a) =>
	cast(ulong) cast(long) float64OfBits(a);
ulong fnUnsafeBitShiftLeftNat64(ulong a, ulong b) {
	verify(b < 64);
	return a << b;
}
ulong fnUnsafeBitShiftRightNat64(ulong a, ulong b) {
	verify(b < 64);
	return a >> b;
}
ulong fnUnsafeDivFloat32(ulong a, ulong b) =>
	binaryFloat32s!((float x, float y) => x / y)(a, b);
ulong fnUnsafeDivFloat64(ulong a, ulong b) =>
	binaryFloat64s!((double x, double y) => x / y)(a, b);
ulong fnUnsafeDivInt8(ulong a, ulong b) =>
	cast(byte) a / cast(byte) b;
ulong fnUnsafeDivInt16(ulong a, ulong b) =>
	cast(short) a / cast(short) b;
ulong fnUnsafeDivInt32(ulong a, ulong b) =>
	cast(int) a / cast(int) b;
ulong fnUnsafeDivInt64(ulong a, ulong b) =>
	cast(ulong) ((cast(long) a) / (cast(long) b));
ulong fnUnsafeDivNat8(ulong a, ulong b) =>
	cast(ubyte) a / cast(ubyte) b;
ulong fnUnsafeDivNat16(ulong a, ulong b) =>
	cast(ushort) a / cast(ushort) b;
ulong fnUnsafeDivNat32(ulong a, ulong b) =>
	cast(uint) a / cast(uint) b;
ulong fnUnsafeDivNat64(ulong a, ulong b) =>
	a / b;
ulong fnUnsafeModNat64(ulong a, ulong b) =>
	a % b;
ulong fnWrapAddIntegral(ulong a, ulong b) =>
	a + b;
ulong fnWrapMulIntegral(ulong a, ulong b) =>
	a * b;
ulong fnWrapSubIntegral(ulong a, ulong b) =>
	a - b;

//TODO:MOVE
pure ulong u64OfI32(int a) =>
	u64OfI64(a);

pure ulong u64OfI64(long a) =>
	cast(ulong) a;

private:

ulong binaryFloat32s(alias cb)(ulong a, ulong b) =>
	bitsOfFloat32(cb(float32OfBits(a), float32OfBits(b)));

ulong binaryFloat64s(alias cb)(ulong a, ulong b) =>
	bitsOfFloat64(cb(float64OfBits(a), float64OfBits(b)));

//TODO:PERF
pure long popcount(ulong a) =>
	a == 0
		? 0
		: popcount(a >> 1) + (a % 2 != 0 ? 1 : 0);
