module util.collection.byteReader;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.types : u8, u16, u32, u64;

struct ByteReader {
	private:
	immutable(u8)* ptr;
}

immutable(u8)* getPtr(ref ByteReader reader) {
	return reader.ptr;
}

void setPtr(ref ByteReader reader, immutable(u8)* ptr) {
	reader.ptr = ptr;
}

@trusted void skipBytes(ref ByteReader reader, immutable size_t size) {
	reader.ptr += size;
}

@trusted immutable(u8) readU8(ref ByteReader reader) {
	immutable u8 res = *reader.ptr;
	reader.ptr++;
	return res;
}

@trusted immutable(u16) readU16(ref ByteReader reader) {
	immutable(u16)* ptr = cast(immutable(u16)*) reader.ptr;
	immutable u16 res = *ptr;
	reader.ptr = cast(immutable(u8)*) (ptr + 1);
	return res;
}

@trusted immutable(u32) readU32(ref ByteReader reader) {
	immutable(u32)* ptr = cast(immutable(u32)*) reader.ptr;
	immutable u32 res = *ptr;
	reader.ptr = cast(immutable(u8)*) (ptr + 1);
	return res;
}

@trusted immutable(u64) readU64(ref ByteReader reader) {
	immutable(u64)* ptr = cast(immutable(u64)*) reader.ptr;
	immutable u64 res = *ptr;
	reader.ptr = cast(immutable(u8)*) (ptr + 1);
	return res;
}

@trusted immutable(Arr!u8) readU8Array(ref ByteReader reader, immutable size_t size) {
	immutable Arr!u8 res = immutable Arr!u8(reader.ptr, size);
	skipBytes(reader, size);
	return res;
}
