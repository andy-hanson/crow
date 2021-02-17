module util.alloc.rangeAlloc;

@safe @nogc pure nothrow:

import util.util : roundUp, verify;

struct RangeAlloc {
	@safe @nogc pure nothrow:

	@trusted this(ubyte* s, immutable size_t size) {
		verify(size % 8 == 0);
		start = s;
		cur = s;
		verify(isWordAligned(cur));
		end = s + size;
		verify(isWordAligned(end));
	}

	@trusted ubyte* allocateBytesImpl(immutable size_t nBytes) {
		verify(start <= cur);
		verify(cur <= end);
		verify(cur + nBytes <= end);
		ubyte* res = cur;
		verify(isWordAligned(res));
		cur += roundUp(nBytes, 8);
		verify(isWordAligned(cur));
		return res;
	}

	void freeBytesImpl(ubyte*, immutable size_t) {
		// do nothing
	}

	void freeBytesPartialImpl(ubyte*, immutable size_t) {
		// do nothing
	}

	RangeAlloc move() {
		ubyte* s = start;
		ubyte* c = cur;
		ubyte* e = end;
		start = null;
		cur = null;
		end = null;
		return RangeAlloc(s, c, e);
	}

	//TODO:private:

	@disable this();
	@disable this(ref const RangeAlloc);
	this(ubyte* s, ubyte* c, ubyte* e) {
		start = s;
		cur = c;
		end = e;
		verify(start <= cur);
		verify(cur <= end);
	}

	ubyte* start;
	ubyte* cur;
	ubyte* end;
}

private:

immutable(bool) isWordAligned(const ubyte* a) {
	return (cast(immutable size_t) a) % 8 == 0;
}
