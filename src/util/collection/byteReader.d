module util.collection.byteReader;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.types : Nat8, Nat16, Nat32, Nat64, u8, u16, u32, u64;

struct ByteReader {
	private:
	immutable(u8)* ptr;
}

immutable(u8*) getPtr(ref const ByteReader reader) {
	return reader.ptr;
}

void setPtr(ref ByteReader reader, immutable(u8)* ptr) {
	reader.ptr = ptr;
}

@trusted void skipBytes(ref ByteReader reader, immutable size_t size) {
	reader.ptr += size;
}

@trusted immutable(Nat8) readU8(ref ByteReader reader) {
	immutable Nat8 res = immutable Nat8(*reader.ptr);
	reader.ptr++;
	return res;
}

@trusted immutable(Nat16) readU16(ref ByteReader reader) {
	immutable Nat16* ptr = cast(immutable Nat16*) reader.ptr;
	immutable Nat16 res = *ptr;
	reader.ptr = cast(immutable u8*) (ptr + 1);
	return res;
}

@trusted immutable(Nat32) readU32(ref ByteReader reader) {
	immutable Nat32* ptr = cast(immutable Nat32*) reader.ptr;
	immutable Nat32 res = *ptr;
	reader.ptr = cast(immutable u8*) (ptr + 1);
	return res;
}

@trusted immutable(Nat64) readU64(ref ByteReader reader) {
	immutable Nat64* ptr = cast(immutable Nat64*) reader.ptr;
	immutable Nat64 res = *ptr;
	reader.ptr = cast(immutable u8*) (ptr + 1);
	return res;
}

@trusted immutable(Arr!Nat8) readU8Array(ref ByteReader reader, immutable size_t size) {
	immutable Arr!Nat8 res = immutable Arr!Nat8(cast(immutable Nat8*) reader.ptr, size);
	skipBytes(reader, size);
	return res;
}

@trusted immutable(Arr!Nat16) readU16ArrayDoNotSkipBytes(ref ByteReader reader, immutable size_t size) {
	return immutable Arr!Nat16(cast(immutable Nat16*) reader.ptr, size);
}
