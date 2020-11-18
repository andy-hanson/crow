module util.alloc.globalAlloc;

@safe @nogc pure nothrow:

import util.util : verifyFail;

struct GlobalAlloc {
	@safe @nogc pure nothrow:

	@trusted ubyte* allocateBytes(immutable size_t nBytes) {
		if (cur + nBytes > end)
			verifyFail();
		ubyte* res = cur;
		cur += nBytes;
		return res;
	}

	void freeBytes(ubyte*, immutable size_t) {
		// do nothing
	}

	void freeBytesPartial(ubyte*, immutable size_t) {
		// do nothing
	}

	private:

	@disable this();
	@disable this(ref const GlobalAlloc);

	@trusted this(bool) {
		cur = cast(ubyte*) globalData.ptr;
		end = (cast(ubyte*) globalData.ptr) + globalData.length;
	}

	ubyte* cur;
	ubyte* end;
}

GlobalAlloc globalAlloc() {
	return GlobalAlloc(true);
}

private:

// WARN: not actually const, made this way so it is pure
const ubyte[256 * 1024 * 1024] globalData = void;

