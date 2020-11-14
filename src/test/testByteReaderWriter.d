module test.testByteReaderWriter;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, begin;
import util.collection.byteReader : ByteReader, readU8, readU16, readU32, readU64;
import util.collection.byteWriter : ByteWriter, finishByteWriter, newByteWriter, pushU8, pushU16, pushU32, pushU64;
import util.ptr : ptrTrustMe_mut;
import util.types : Nat8, Nat16, Nat32, Nat64, u8;
import util.util : verify;

@trusted void testByteReaderWriter(Alloc)(ref Alloc alloc) {
	ByteWriter!Alloc writer = newByteWriter(ptrTrustMe_mut(alloc));

	pushU8(writer, immutable Nat8(0xab));
	pushU16(writer, immutable Nat16(0xabcd));
	pushU32(writer, immutable Nat32(0xabcdef01));
	pushU64(writer, immutable Nat64(0x0123456789abcdef));

	immutable Arr!u8 bytes = finishByteWriter(writer);

	ByteReader reader = ByteReader(begin(bytes));
	verify(readU8(reader) == immutable Nat8(0xab));
	verify(readU16(reader) == immutable Nat16(0xabcd));
	verify(readU32(reader) == immutable Nat32(0xabcdef01));
	verify(readU64(reader) == immutable Nat64(0x0123456789abcdef));
}
