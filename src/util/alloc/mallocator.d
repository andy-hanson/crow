module util.mallocator;

@safe @nogc pure nothrow:

import core.memory : pureFree, pureMalloc;

import util.verify : verify;

struct Mallocator {
	@safe @nogc pure nothrow:

	@trusted byte* allocate(immutable size_t size) {
		byte* res = cast(byte*) pureMalloc(size);
		assert(res != null);
		return res;
	}

	@trusted void free(byte* ptr, immutable size_t _size) {
		pureFree(cast(void*) ptr);
	}
}
