module util.collection.byteWriter;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.collection.mutArr : moveToArr, MutArr, mutArrPtrAt, mutArrSize, push, pushAll;
import util.ptr : Ptr;
import util.types : bottomU8OfU32, bottomU32OfU64, u8, u16, u32, u64;
import util.util : verify;

// NOTE: When this writes a u16/u32/u64, it is written in platform-dependent order.
// (And ByteReader reads it back in platform-dependent order)

struct ByteWriter(Alloc) {
	Ptr!Alloc alloc;
	MutArr!(immutable u8) bytes;
}

ByteWriter!Alloc newByteWriter(Alloc)(Ptr!Alloc alloc) {
	return ByteWriter!Alloc(alloc);
}

immutable(size_t) nextByteIndex(Alloc)(ref const ByteWriter!Alloc writer) {
	return mutArrSize(writer.bytes);
}

immutable(Arr!u8) finishByteWriter(Alloc)(ref ByteWriter!Alloc writer) {
	return moveToArr(writer.alloc, writer.bytes);
}

void pushU8(Alloc)(ref ByteWriter!Alloc writer, immutable u8 value) {
	push(writer.alloc, writer.bytes, value);
}

void pushU16(Alloc)(ref ByteWriter!Alloc writer, immutable u16 value) {
	pushBytes!u16(writer, value);
}

void pushU32(Alloc)(ref ByteWriter!Alloc writer, immutable u32 value) {
	pushBytes!u32(writer, value);
}

void pushU64(Alloc)(ref ByteWriter!Alloc writer, immutable u64 value) {
	pushBytes!u64(writer, value);
}

void writeU8(Alloc)(ref ByteWriter!Alloc writer, immutable size_t index, immutable u8 value) {
	setAt(writer.bytes, index, value);
}

void writeU16(Alloc)(ref ByteWriter!Alloc writer, immutable size_t index, immutable u16 value) {
	writeBytes!u16(writer, index, value);
}

void writeU32(Alloc)(ref ByteWriter!Alloc writer, immutable size_t index, immutable u32 value) {
	writeBytes!u32(writer, index, value);
}

void writeU64(Alloc)(ref ByteWriter!Alloc writer, immutable size_t index, immutable u64 value) {
	writeBytes!u64(writer, index, value);
}

private:

@trusted void pushBytes(T, Alloc)(ref ByteWriter!Alloc writer, immutable T value) {
	pushAll(writer.alloc, writer.bytes, asBytes!T(&value));
}

@system immutable(Arr!u8) asBytes(T)(immutable T* value) {
	return immutable Arr!u8(cast(immutable u8*) value, T.sizeof);
}

@trusted void writeBytes(T, Alloc)(ref ByteWriter!Alloc writer, immutable size_t index, immutable T value) {
	verify(index + T.sizeof <= mutArrSize(writer.bytes));
	*(cast(T*) mutArrPtrAt(writer.bytes, index)) = value;
}
