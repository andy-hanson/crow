module util.collection.exactSizeArrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : allocateBytes;
import util.collection.arr : arrOfRange_mut;
import util.memory : initMemory_mut, memset;
import util.util : verify;

//TODO:MOVE
struct ExactSizeArrBuilder(T) {
	private:
	T* begin;
	T* cur;
	T* end;
}

immutable(size_t) exactSizeArrBuilderCurSize(T)(ref const ExactSizeArrBuilder!T a) {
	return a.cur - a.begin;
}

@trusted ExactSizeArrBuilder!T newExactSizeArrBuilder(T, Alloc)(ref Alloc alloc, immutable size_t size) {
	T* begin = cast(T*) allocateBytes(alloc, T.sizeof * size);
	return ExactSizeArrBuilder!T(begin, begin, begin + size);
}

@trusted void exactSizeArrBuilderAdd(T)(ref ExactSizeArrBuilder!T a, T value) {
	verify(a.cur < a.end);
	initMemory_mut!T(a.cur, value);
	a.cur++;
}

@trusted void add16(ref ExactSizeArrBuilder!ubyte a, immutable ushort value) {
	verify(a.cur + 2 <= a.end);
	ushort* ptr = cast(ushort*) a.cur;
	*ptr = value;
	a.cur = cast(ubyte*) (ptr + 1);
}

@trusted void add32(ref ExactSizeArrBuilder!ubyte a, immutable uint value) {
	verify(a.cur + 4 <= a.end);
	uint* ptr = cast(uint*) a.cur;
	*ptr = value;
	a.cur = cast(ubyte*) (ptr + 1);
}

@trusted void add64(ref ExactSizeArrBuilder!ubyte a, immutable ulong value) {
	verify(a.cur + 8 <= a.end);
	ulong* ptr = cast(ulong*) a.cur;
	*ptr = value;
	a.cur = cast(ubyte*) (ptr + 1);
}

@trusted void add0Bytes(ref ExactSizeArrBuilder!ubyte a, immutable size_t nBytes) {
	verify(a.cur + nBytes <= a.end);
	memset(a.cur, 0, nBytes);
	a.cur += nBytes;
}

@trusted void add64TextPtr(ref ExactSizeArrBuilder!ubyte a, immutable size_t textIndex) {
	add64(a, cast(immutable ulong) (a.begin + textIndex));
}

@trusted T[] finish(T)(ref ExactSizeArrBuilder!T a) {
	verify(a.cur == a.end);
	T[] res = arrOfRange_mut(a.begin, a.end);
	a.begin = null;
	a.cur = null;
	a.end = null;
	return res;
}
