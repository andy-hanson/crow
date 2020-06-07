module util.types;

@safe @nogc pure nothrow:

alias u8 = ubyte;
alias u32 = uint;
alias u64 = ulong;

u32 safeSizeTToU32(immutable size_t s) {
	assert(s <= 99999);
	return cast(u32) s;
}

