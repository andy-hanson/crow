module util.collection.byteWriter;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.mutArr : moveToArr, MutArr, mutArrPtrAt, mutArrSize, push, pushAll;
import util.ptr : Ptr;
import util.types : Int16, Int32, Nat8, Nat16, Nat32, Nat48, Nat64;
import util.util : verify;

// NOTE: When this writes a u16/u32/u64, it is written in platform-dependent order.
// (And ByteReader reads it back in platform-dependent order)

struct ByteWriter {
	Ptr!Alloc alloc;
	MutArr!(immutable ubyte) bytes;
}

ByteWriter newByteWriter(Ptr!Alloc alloc) {
	return ByteWriter(alloc);
}

immutable(size_t) nextByteIndex(ref const ByteWriter writer) {
	return mutArrSize(writer.bytes);
}

immutable(ubyte[]) finishByteWriter(ref ByteWriter writer) {
	return moveToArr(writer.alloc.deref(), writer.bytes);
}

void pushInt16(ref ByteWriter writer, immutable Int16 value) {
	pushBytes!Int16(writer, value);
}

void pushInt32(ref ByteWriter writer, immutable Int32 value) {
	pushBytes!Int32(writer, value);
}

void pushU8(ref ByteWriter writer, immutable Nat8 value) {
	push(writer.alloc.deref(), writer.bytes, value.raw());
}

void pushU16(ref ByteWriter writer, immutable Nat16 value) {
	pushBytes!Nat16(writer, value);
}

void pushU32(ref ByteWriter writer, immutable Nat32 value) {
	pushBytes!Nat32(writer, value);
}

void pushU48(ref ByteWriter writer, immutable Nat48 value) {
	pushU16(writer, immutable Nat16(value.a));
	pushU16(writer, immutable Nat16(value.b));
	pushU16(writer, immutable Nat16(value.c));
}

void pushU64(ref ByteWriter writer, immutable Nat64 value) {
	pushBytes!Nat64(writer, value);
}

void writeInt16(ref ByteWriter writer, immutable Nat32 index, immutable Int16 value) {
	writeBytes!Int16(writer, index, value);
}

void writeU16(ref ByteWriter writer, immutable Nat32 index, immutable Nat16 value) {
	writeBytes!Nat16(writer, index, value);
}

void writeU32(ref ByteWriter writer, immutable Nat32 index, immutable Nat32 value) {
	writeBytes!Nat32(writer, index, value);
}

@trusted void pushBytes(T)(ref ByteWriter writer, immutable T value) {
	pushAll(writer.alloc.deref(), writer.bytes, asBytes!T(&value));
}

private:

@system immutable(ubyte[]) asBytes(T)(immutable T* value) {
	return (cast(immutable ubyte*) value)[0 .. T.sizeof];
}

@trusted void writeBytes(T)(ref ByteWriter writer, immutable Nat32 index, immutable T value) {
	verify(index.raw() + T.sizeof <= mutArrSize(writer.bytes));
	*(cast(T*) mutArrPtrAt(writer.bytes, index.raw())) = value;
}
