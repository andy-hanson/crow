module util.alloc.mallocator;

@safe @nogc pure nothrow:

import core.memory : pureFree, pureMalloc;
import util.util : todo, verify;

struct Mallocator {
	@safe @nogc pure nothrow:

	@trusted ubyte* allocate(immutable size_t size) {
		ubyte* res = cast(ubyte*) pureMalloc(size);
		verify(res != null);
		return res;
	}

	@trusted void free(ubyte* ptr, immutable size_t size) {
		pureFree(cast(void*) ptr);
	}
}
