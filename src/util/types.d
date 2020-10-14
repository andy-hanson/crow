module util.types;

@safe @nogc pure nothrow:

import util.util : verify;

struct Void {}

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;
alias u64 = ulong;

alias i32 = int;

alias ssize_t = long;

immutable u8 maxU4 = 0xf;
immutable u8 maxU8 = 0xff;
immutable u16 maxU16 = 0xffff;
immutable u32 maxU32 = 0xffffffff;
immutable u64 maxU64 = 0xffffffffffffffff;

immutable(u8) bottomU8OfU32(immutable u32 u) {
	return cast(u8) (u & maxU8);
}

immutable(u32) bottomU32OfU64(immutable u64 u) {
	return cast(u32) (u & maxU32);
}

immutable(i32) safeI32FromU32(immutable u32 u) {
	verify(u <= 999);
	return cast(i32) u;
}

immutable(u8) safeU32ToU8(immutable u32 u) {
	return safeSizeTToU8(u);
}

immutable(u16) safeU32ToU16(immutable u32 u) {
	verify(u <= 999);
	return cast(u16) u;
}

immutable(u16) safeSizeTToU16(immutable size_t s) {
	verify(s <= 999);
	return cast(u16) s;
}

immutable(u32) safeSizeTToU32(immutable size_t s) {
	verify(s <= 99999);
	return cast(u32) s;
}

immutable(int) safeIntFromSizeT(immutable size_t s) {
	verify(s <= 9999);
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
