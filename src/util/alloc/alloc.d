module util.alloc.alloc;

@nogc pure nothrow: // not @safe

import util.util : divRoundUp, verify;

struct Alloc {
	@safe @nogc pure nothrow:

	@disable this();
	@disable this(ref const Alloc);
	@trusted this(return scope word[] words) {
		start = words.ptr;
		cur = start;
		end = start + words.length;
	}

	Alloc move() {
		word* s = start;
		word* c = cur;
		word* e = end;
		start = null;
		cur = null;
		end = null;
		return Alloc(s, c, e);
	}

	private:

	this(word* s, word* c, word* e) {
		start = s;
		cur = c;
		end = e;
		verify(start <= cur);
		verify(cur <= end);
	}

	word* start;
	word* cur;
	word* end;
}

alias TempAlloc = Alloc;

@trusted void verifyOwns(T)(in Alloc alloc, in T[] values) {
	verify(alloc.start < cast(ulong*) values.ptr && cast(ulong*) (values.ptr + values.length) <= alloc.cur);
}

size_t curBytes(ref Alloc alloc) =>
	(alloc.cur - alloc.end) * word.sizeof;

ubyte* allocateBytes(ref Alloc alloc, size_t size) =>
	cast(ubyte*) allocateWords(alloc, divRoundUp(size, word.sizeof));

void withStackAlloc(size_t sizeWords, T)(in T delegate(ref Alloc) @safe @nogc pure nothrow cb) {
	ulong[sizeWords] mem = void;
	scope Alloc alloc = Alloc(mem);
	return cb(alloc);
}

private word* allocateWords(ref Alloc alloc, size_t nWords) {
	word* res = alloc.cur;
	alloc.cur += nWords;
	verify(alloc.cur <= alloc.end);
	return res;
}

T* allocateUninitialized(T)(ref Alloc alloc) =>
	&allocateElements!T(alloc, 1)[0];

T[] allocateElements(T)(ref Alloc alloc, size_t count) =>
	(cast(T*) allocateBytes(alloc, T.sizeof * count))[0 .. count];

private void freeBytes(ref Alloc alloc, ubyte* ptr, size_t) {
	// do nothing
}

void freeElements(T)(ref Alloc alloc, T[] range) {
	freeBytes(alloc, cast(ubyte*) range.ptr, T.sizeof * range.length);
}

private alias word = ulong;
