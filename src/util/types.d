module util.types;

@safe @nogc pure nothrow:

import util.util : verify;

immutable(ubyte) safeIncrU8(immutable ubyte a) {
	verify(a != ubyte.max);
	return cast(ubyte) (a + 1);
}

immutable(ubyte) bottomU8OfU64(immutable ulong u) {
	return cast(immutable ubyte) u;
}

immutable(ushort) bottomU16OfU64(immutable ulong u) {
	return cast(immutable ushort) u;
}

immutable(uint) bottomU32OfU64(immutable ulong u) {
	return cast(immutable uint) u;
}

immutable(int) safeI32FromU32(immutable uint u) {
	verify(u <= int.max);
	return cast(immutable int) u;
}

immutable(ushort) safeU32ToU16(immutable uint u) {
	verify(u <= ushort.max);
	return cast(immutable ushort) u;
}

immutable(ushort) safeSizeTToU16(immutable size_t s) {
	verify(s <= ushort.max);
	return cast(immutable ushort) s;
}

immutable(uint) safeSizeTToU32(immutable size_t s) {
	verify(s <= uint.max);
	return cast(immutable uint) s;
}

immutable(ushort) safeU16FromSizeT(immutable size_t a) {
	verify(a < ushort.max);
	return cast(immutable ushort) a;
}

immutable(int) safeIntFromSizeT(immutable size_t s) {
	verify(s <= int.max);
	return cast(immutable int) s;
}

immutable(int) safeIntFromU64(immutable ulong a) {
	verify(a <= int.max);
	return cast(immutable int) a;
}

immutable(ubyte) safeSizeTToU8(immutable size_t s) {
	verify(s <= 255);
	return cast(immutable ubyte) s;
}

immutable(uint) safeU32FromI64(immutable long a) {
	verify(a >= 0 && a <= uint.max);
	return cast(immutable uint) a;
}

immutable(uint) safeU32FromI32(immutable int a) {
	return safeU32FromI64(a);
}

immutable(ulong) safeU64FromI64(immutable long a) {
	verify(a >= 0);
	return cast(immutable ulong) a;
}

immutable(size_t) safeSizeTFromLong(immutable long s) {
	verify(s >= 0 && s <= size_t.max);
	return cast(immutable size_t) s;
}

immutable(size_t) safeSizeTFromU64(immutable ulong a) {
	verify(a <= size_t.max);
	return cast(immutable size_t) a;
}

immutable(ulong) abs(immutable long a) {
	return a < 0 ? -a : a;
}
immutable(double) abs(immutable double a) {
	return a < 0 ? -a : a;
}

immutable(uint) u32OfFloat32Bits(immutable float value) {
	Converter32 conv;
	conv.asFloat32 = value;
	return conv.asU32;
}

immutable(ulong) u64OfFloat32Bits(immutable float value) {
	return u32OfFloat32Bits(value);
}

immutable(float) float32OfU32Bits(immutable uint value) {
	Converter32 conv;
	conv.asU32 = value;
	return conv.asFloat32;
}

immutable(float) float32OfU64Bits(immutable ulong value) {
	return float32OfU32Bits(cast(uint) value);
}

immutable(uint) u32OfI32Bits(immutable int value) {
	Converter32 conv;
	conv.asI32 = value;
	return conv.asU32;
}

immutable(ulong) u64OfFloat64Bits(immutable double value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asU64;
}

immutable(double) float64OfU64Bits(immutable ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asFloat64;
}

immutable(int) i32OfU64Bits(immutable ulong value) {
	Converter32 conv;
	conv.asU32 = cast(uint) value;
	return conv.asI32;
}

immutable(long) i64OfU64Bits(immutable ulong value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asI64;
}

private:

union Converter32 {
	int asI32;
	uint asU32;
	float asFloat32;
}

union Converter64 {
	ulong asU64;
	long asI64;
	double asFloat64;
}
