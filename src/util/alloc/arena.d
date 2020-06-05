module util.arena;

@safe @nogc pure nothrow:

struct Arena(Allocator) {
	this(Allocator a) {
		allocator = a;
	}

	private:

	Allocator allocator;
	const ubyte* begin;
	ubyte* cur;
	const ubyte* end;

	~this() {
		if (begin != null)
			allocator.free(begin, end - begin);
	}


	byte* allocate(immutable size_t nBytes) {
		if (arena.begin == null) {
			immutable size_t size = ARENA_SIZE;
			arena.begin = malloc(size);
			assert(arena.begin != null);
			arena.cur = arena.begin;
			arena.end = arena.begin + size;
			// Fill with 0xff for debugging
			for (byte* b = arena.cur; b < arena.end; b++)
				*b = 0xff;
		}

		assert(n_bytes < 999999);

		byte* res = arena.cur;
		arena.cur = arena.cur + n_bytes;

		if (arena.cur > arena.end)
			todo("Ran out of space!");

		// Since we filled with 0xff, should still be that way!
		for (byte* b = res; b < arena.cur; b++)
			assert(*b == 0xff);

		return res;
	}

	void free(byte* ptr, size_t _size) {
		// do nothing
	}
}

//TODO:Don't hardcode
private immutable size_t ARENA_SIZE = 4 * 1024 * 1024;
