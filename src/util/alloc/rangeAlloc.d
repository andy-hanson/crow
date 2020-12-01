module util.alloc.rangeAlloc;

@safe @nogc pure nothrow:

import util.util : verify;

struct RangeAlloc {
	@safe @nogc pure nothrow:

	@trusted this(ubyte* s, immutable size_t size) {
		start = s;
		cur = s;
		end = s + size;
	}

	@trusted ubyte* allocateBytes(immutable size_t nBytes) {
		verify(start <= cur);
		verify(cur <= end);
		verify(cur + nBytes <= end);
		ubyte* res = cur;
		cur += nBytes;
		//TODO:KILL
		foreach (ref ubyte b; res[0..nBytes])
			b = 42;
		return res;
	}

	void freeBytes(ubyte*, immutable size_t) {
		// do nothing
	}

	void freeBytesPartial(ubyte*, immutable size_t) {
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
