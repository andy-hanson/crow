module util.alloc.mallocator;

@safe @nogc pure nothrow:

import core.memory : pureFree, pureMalloc;

struct Mallocator {
	@safe @nogc pure nothrow:

	@trusted ubyte* allocate(immutable size_t size) {
		ubyte* res = cast(ubyte*) pureMalloc(size);
		assert(res != null);
		debug {
			import core.stdc.stdio : printf;
			if (false) printf("Mallocator allocate %lu bytes to %p\n", size, res);
		}
		return res;
	}

	@trusted void free(ubyte* ptr, immutable size_t size) {
		debug {
			import core.stdc.stdio : printf;
			if (false) printf("Mallocator free     %lu bytes from %p\n", size, ptr);
		}
		pureFree(cast(void*) ptr);
	}
}
