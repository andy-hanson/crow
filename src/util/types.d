module util.types;

@safe @nogc pure nothrow:

import util.util : verify;

struct Void {}

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;
alias u64 = ulong;

alias i8 = byte;
alias i16 = short;
alias i32 = int;
alias i64 = long;

alias float32 = float;
alias float64 = double;

alias ssize_t = long;

immutable u8 maxU4 = 0xf;
immutable u8 maxU8 = 0xff; // TODO: just use u8.max
immutable u16 maxU16 = 0xffff; // TODO: just use u16.max
immutable u32 maxU32 = 0xffffffff; // TODO: just use u32.max
immutable u64 maxU64 = 0xffffffffffffffff; // TODO: just use u64.max

immutable(u8) bottomU8OfU32(immutable u32 u) {
	return cast(u8) (u & maxU8);
}

immutable(u16) bottomU16OfU64(immutable u64 u) {
	return cast(u16) (u & maxU16);
}

immutable(u32) bottomU32OfU64(immutable u64 u) {
	return cast(u32) (u & maxU32);
}

immutable(i32) safeI32FromU32(immutable u32 u) {
	verify(u <= i32.max);
	return cast(i32) u;
}

immutable(u8) safeU32ToU8(immutable u32 u) {
	return safeSizeTToU8(u);
}

immutable(u16) safeU32ToU16(immutable u32 u) {
	verify(u <= u16.max);
	return cast(u16) u;
}

immutable(u16) safeSizeTToU16(immutable size_t s) {
	verify(s <= u16.max);
	return cast(u16) s;
}

immutable(u32) safeSizeTToU32(immutable size_t s) {
	verify(s <= u32.max);
	return cast(u32) s;
}

immutable(int) safeIntFromSizeT(immutable size_t s) {
	verify(s <= int.max);
	return cast(int) s;
}

alias safeIntFromU64 = safeIntFromSizeT;

immutable(u8) safeSizeTToU8(immutable size_t s) {
	verify(s <= 255);
	return cast(u8) s;
}

immutable(size_t) safeSizeTFromSSizeT(immutable ssize_t s) {
	verify(s >= 0);
	return cast(size_t) s;
}

immutable(u8) catU4U4(immutable u8 a, immutable u8 b) {
	verify(a <= maxU4);
	verify(b <= maxU4);
	return safeU32ToU8((a << 4) | b);
}

struct U4U4 {
	immutable u8 a;
	immutable u8 b;
}

immutable(U4U4) u4u4OfU8(immutable u8 a) {
	return immutable U4U4(a >> 4, a & maxU4);
}

immutable(u64) u64OfFloat64Bits(immutable float64 value) {
	Converter64 conv;
	conv.asFloat64 = value;
	return conv.asU64;
}

immutable(float64) float64OfU64Bits(immutable u64 value) {
	Converter64 conv;
	conv.asU64 = value;
	return conv.asFloat64;
}

immutable(u64) bottomNBytes(immutable u64 value, immutable u8 nBytes) {
	immutable u64 nBits = nBytes * 8;
	immutable u64 mask = (1uL << nBits) - 1;
	return value & mask;
}

private:

union Converter64 {
	i64 asI64;
	u64 asU64;
	float64 asFloat64;
}
