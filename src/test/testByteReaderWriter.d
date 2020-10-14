module test.testByteReaderWriter;

@safe @nogc pure nothrow:

import util.alloc.stackAlloc : StackAlloc;
import util.collection.arr : Arr, begin;
import util.collection.byteReader : ByteReader, readU8, readU16, readU32, readU64;
import util.collection.byteWriter : ByteWriter, finishByteWriter, newByteWriter, pushU8, pushU16, pushU32, pushU64;
import util.ptr : ptrTrustMe_mut;
import util.types : u8;
import util.util : verify;

@trusted void testByteReaderWriter() {
	alias Alloc = StackAlloc!("test", 1024);
	Alloc alloc;
	ByteWriter!Alloc writer = newByteWriter(ptrTrustMe_mut(alloc));

	pushU8(writer, 0xab);
	pushU16(writer, 0xabcd);
	pushU32(writer, 0xabcdef01);
	pushU64(writer, 0x0123456789abcdef);

	immutable Arr!u8 bytes = finishByteWriter(writer);

	ByteReader reader = ByteReader(begin(bytes));
	checkEqual(readU8(reader), 0xab);
	checkEqual(readU16(reader), 0xabcd);
	checkEqual(readU32(reader), 0xabcdef01);
	checkEqual(readU64(reader), 0x0123456789abcdef);
}

private:

void checkEqual(T)(immutable T a, immutable T b) {
	if (a != b) {
		debug {
			import core.stdc.stdio : printf;
			printf("Expected %lu to equal %lu\n", cast(immutable size_t) a, cast(immutable size_t) b);
		}
		verify(false);
	}
}


