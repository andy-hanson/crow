module util.col.exactSizeArrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements;
import util.col.arr : endPtr;
import util.col.str : eachChar, SafeCStr, safeCStrSize;
import util.memory : initMemory, memset;
import util.util : verify;

struct ExactSizeArrBuilder(T) {
	private:
	T[] inner;
	T* cur;
}

@trusted immutable(size_t) exactSizeArrBuilderCurSize(T)(ref const ExactSizeArrBuilder!T a) =>
	a.cur - a.inner.ptr;

@trusted ExactSizeArrBuilder!T newExactSizeArrBuilder(T)(ref Alloc alloc, size_t size) {
	T[] inner = allocateElements!T(alloc, size);
	return ExactSizeArrBuilder!T(inner, inner.ptr);
}

@trusted immutable(T*) exactSizeArrBuilderAdd(T)(scope ref ExactSizeArrBuilder!T a, immutable T value) {
	verify(a.cur < endPtr(a.inner));
	initMemory!T(a.cur, value);
	immutable T* res = cast(immutable) a.cur;
	a.cur++;
	return res;
}

void add16(scope ref ExactSizeArrBuilder!ubyte a, ushort value) {
	addT(a, value);
}

void add32(scope ref ExactSizeArrBuilder!ubyte a, uint value) {
	addT(a, value);
}

void add64(scope ref ExactSizeArrBuilder!ubyte a, ulong value) {
	addT(a, value);
}

@trusted private void addT(T)(scope ref ExactSizeArrBuilder!ubyte a, T value) {
	verify(a.cur + T.sizeof <= endPtr(a.inner));
	T* ptr = cast(T*) a.cur;
	*ptr = value;
	a.cur = cast(ubyte*) (ptr + 1);
}

void padTo(scope ref ExactSizeArrBuilder!ubyte a, size_t desiredSize) {
	if (exactSizeArrBuilderCurSize(a) < desiredSize)
		add0Bytes(a, desiredSize - exactSizeArrBuilderCurSize(a));
	verify(exactSizeArrBuilderCurSize(a) == desiredSize);
}

@trusted void add0Bytes(scope ref ExactSizeArrBuilder!ubyte a, size_t nBytes) {
	verify(a.cur + nBytes <= endPtr(a.inner));
	memset(a.cur, 0, nBytes);
	a.cur += nBytes;
}

@trusted void add64TextPtr(scope ref ExactSizeArrBuilder!ubyte a, size_t textIndex) {
	add64(a, cast(immutable ulong) &a.inner[textIndex]);
}

@trusted void addStringAndNulTerminate(scope ref ExactSizeArrBuilder!ubyte a, SafeCStr value) {
	verify(a.cur + safeCStrSize(value) < endPtr(a.inner));
	eachChar(value, (char c) @trusted {
		*a.cur = c;
		a.cur++;
	});
	*a.cur = '\0';
	a.cur++;
}

@trusted T[] finish(T)(ref ExactSizeArrBuilder!T a) {
	verify(a.cur == endPtr(a.inner));
	T[] res = a.inner;
	a.inner = [];
	a.cur = a.inner.ptr;
	return res;
}
