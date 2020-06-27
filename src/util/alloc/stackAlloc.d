module util.alloc.stackAlloc;

@safe @nogc pure nothrow:

struct StackAlloc {
	@safe @nogc pure nothrow:
	private:
	immutable size_t capacity = 1024;
	ubyte[capacity] data_ = void;
	size_t cur;

	public:
	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (cur + nBytes > capacity)
			assert(0); // TODO

		ubyte* res = data_.ptr + cur;
		cur += nBytes;
		return res;
	}

	void freePartial(ubyte*, size_t) {
		// do nothing
	}

	void free(ubyte*, size_t ) {
		// do nothing
	}
}
