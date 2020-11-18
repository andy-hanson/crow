module io.mallocator;

@safe @nogc pure nothrow:

import core.memory : pureFree, pureMalloc;
import util.util : verify;

struct Mallocator {
	@safe @nogc pure nothrow:

	@disable this(ref const Mallocator);

	@trusted ubyte* allocateBytes(immutable size_t size) {
		ubyte* res = cast(ubyte*) pureMalloc(size);
		verify(res != null);
		return res;
	}

	@trusted void freeBytes(ubyte* ptr, immutable size_t) {
		pureFree(cast(void*) ptr);
	}

	@trusted void freeBytesPartial(ubyte* ptr, immutable size_t) {
	}
}
