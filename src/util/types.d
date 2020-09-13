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

immutable(i32) safeI32FromU32(immutable u32 u) {
	verify(u <= 999);
	return cast(i32) u;
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

immutable(size_t) safeSizeTFromSSizeT(immutable ssize_t s) {
	verify(s >= 0);
	return cast(size_t) s;
}

immutable u8 MAX_UINT8 = 255;
