module interpret.applyFn;

@safe @nogc pure nothrow:

import util.conv : bitsOfFloat32, bitsOfFloat64, float32OfBits, float64OfBits;
import util.util : verify;

private ulong binaryFloat32s(alias cb)(ulong a, ulong b) =>
	bitsOfFloat32(cb(float32OfBits(a), float32OfBits(b)));

private ulong binaryFloat64s(alias cb)(ulong a, ulong b) =>
	bitsOfFloat64(cb(float64OfBits(a), float64OfBits(b)));

private ulong unaryFloat64(alias cb)(ulong a) =>
	bitsOfFloat64(cb(float64OfBits(a)));

alias fnRoundFloat64 = unaryFloat64!((double a) => round(a));
alias fnSqrtFloat64 = unaryFloat64!((double a) => sqrt(a));
alias fnAcosFloat64 = unaryFloat64!((double a) => acos(a));
alias fnAcoshFloat64 = unaryFloat64!((double a) => acosh(a));
alias fnAsinFloat64 = unaryFloat64!((double a) => asin(a));
alias fnAsinhFloat64 = unaryFloat64!((double a) => asinh(a));
alias fnAtanFloat64 = unaryFloat64!((double a) => atan(a));
alias fnAtanhFloat64 = unaryFloat64!((double a) => atanh(a));
alias fnCosFloat64 = unaryFloat64!((double a) => cos(a));
alias fnCoshFloat64 = unaryFloat64!((double a) => cosh(a));
alias fnSinFloat64 = unaryFloat64!((double a) => sin(a));
alias fnSinhFloat64 = unaryFloat64!((double a) => sinh(a));
alias fnTanFloat64 = unaryFloat64!((double a) => tan(a));
alias fnTanhFloat64 = unaryFloat64!((double a) => tanh(a));
alias fnAtan2Float64 = binaryFloat64s!((double a, double b) => atan2(a, b));

alias fnAddFloat32 = binaryFloat32s!((float a, float b) => a + b);
alias fnAddFloat64 = binaryFloat64s!((double a, double b) => a + b);
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
alias fnMulFloat32 = binaryFloat32s!((float a, float b) => a * b);
alias fnMulFloat64 = binaryFloat64s!((double a, double b) => a * b);
alias fnSubFloat32 = binaryFloat32s!((float a, float b) => a - b);
alias fnSubFloat64 = binaryFloat64s!((double a, double b) => a - b);
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
alias fnUnsafeDivFloat32 = binaryFloat32s!((float a, float b) => a / b);
alias fnUnsafeDivFloat64 = binaryFloat64s!((double a, double b) => a / b);
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
ulong u64OfI32(int a) =>
	u64OfI64(a);

ulong u64OfI64(long a) =>
	cast(ulong) a;

private:

//TODO:PERF
long popcount(ulong a) =>
	a == 0
		? 0
		: popcount(a >> 1) + (a % 2 != 0 ? 1 : 0);

// Importing 'core.stdc.math' breaks WASM builds, so declaring here
extern(C) {
	double acos(double x);
	double acosh(double x);
	double asin(double x);
	double asinh(double x);
	double atan(double x);
	double atanh(double x);
	double atan2(double x, double y);
	double cos(double x);
	double cosh(double x);
	double round(double x);
	double sin(double x);
	double sinh(double x);
	double sqrt(double x);
	double tan(double x);
	double tanh(double x);
}
