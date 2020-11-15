module util.alloc.globalAlloc;

// Intended for use by WASM which has problems with StackAlloc
// (tries to call 'memset' to initialize it, but that function doesn't exist)

import util.util : verifyFail;

@nogc nothrow: // not @safe, not pure

private ubyte* allocateImpl(immutable char* debugName)(
	ref GlobalAlloc!(debugName) alloc,
	immutable size_t nBytes,
) {
	if (cur + nBytes > capacity) {
		verifyFail();
	}
	ubyte* res = data_.ptr + cur;
	cur += nBytes;
	return res;
}

@safe pure:

struct GlobalAlloc(immutable char* debugName) {
	@safe @nogc pure nothrow:

	public:
	@trusted ubyte* allocate(immutable size_t nBytes) {
		alias PureFn = ubyte* function(ref GlobalAlloc!(debugName), immutable size_t) @safe @nogc pure nothrow;
		immutable PureFn fn = cast(PureFn) &allocateImpl!(debugName);
		return fn(this, nBytes);
	}

	void freePartial(ubyte*, immutable size_t) {
		// do nothing
	}

	void free(ubyte*, immutable size_t) {
		// do nothing
	}
}

private:

immutable size_t capacity = 256 * 1024 * 1024;
static ubyte[capacity] data_ = void;
static size_t cur;
