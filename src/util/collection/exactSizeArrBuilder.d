module util.collection.exactSizeArrBuilder;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, arrOfRange_mut;
import util.memory : initMemory_mut;
import util.types : u8, u16, u32, u64;
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
	T* begin = cast(T*) alloc.allocateBytes(T.sizeof * size);
	return ExactSizeArrBuilder!T(begin, begin, begin + size);
}

@trusted void exactSizeArrBuilderAdd(T)(ref ExactSizeArrBuilder!T a, T value) {
	verify(a.cur < a.end);
	initMemory_mut!T(a.cur, value);
	a.cur++;
}

@trusted void add16(ref ExactSizeArrBuilder!ubyte a, immutable u16 value) {
	verify(a.cur + 2 <= a.end);
	u16* ptr = cast(u16*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add32(ref ExactSizeArrBuilder!ubyte a, immutable u32 value) {
	verify(a.cur + 4 <= a.end);
	u32* ptr = cast(u32*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add64(ref ExactSizeArrBuilder!ubyte a, immutable u64 value) {
	verify(a.cur + 8 <= a.end);
	u64* ptr = cast(u64*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add64TextPtr(ref ExactSizeArrBuilder!ubyte a, immutable size_t textIndex) {
	add64(a, cast(immutable u64) (a.begin + textIndex));
}

@trusted Arr!T finish(T)(ref ExactSizeArrBuilder!T a) {
	verify(a.cur == a.end);
	Arr!T res = arrOfRange_mut(a.begin, a.end);
	a.begin = null;
	a.cur = null;
	a.end = null;
	return res;
}
