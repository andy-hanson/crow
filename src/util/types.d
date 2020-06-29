module util.types;

@safe @nogc pure nothrow:

struct Void {}

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;
alias u64 = ulong;

alias i32 = int;

alias ssize_t = long;

i32 safeI32FromU32(immutable u32 u) {
	assert(u <= 999);
	return cast(i32) u;
}

u16 safeU32ToU16(immutable u32 u) {
	assert(u <= 999);
	return cast(u16) u;
}

u16 safeSizeTToU16(immutable size_t s) {
	assert(s <= 999);
	return cast(u16) s;
}

u32 safeSizeTToU32(immutable size_t s) {
	assert(s <= 99999);
	return cast(u32) s;
}

size_t safeSizeTFromSSizeT(immutable ssize_t s) {
	assert(s >= 0);
	return cast(size_t) s;
}


immutable u8 MAX_UINT8 = 255;
