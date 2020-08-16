module util.alloc.stackAlloc;

@safe @nogc pure nothrow:

struct StackAlloc(string debugName, size_t capacity) {
	@safe @nogc pure nothrow:
	private:
	ubyte[capacity] data_ = void;
	size_t cur;

	public:
	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (cur + nBytes > capacity) {
			debug {
				import core.stdc.stdio : printf;
				printf("Stack alloc %.*s ran out of space\n\n", cast(int) debugName.length, debugName.ptr);
				printf("capacity: %zd, already filled: %zd, tried to allocate: %zd\n", capacity, cur, nBytes);
			}
			assert(0); // TODO
		}

		ubyte* res = data_.ptr + cur;
		cur += nBytes;

		//debug {
		//	import core.stdc.stdio : printf;
		//	//printf("Allocate %lu bytes to %p (%lu out of %lu used)\n", nBytes, res, cur, capacity);
		//}

		return res;
	}

	void freePartial(ubyte*, size_t) {
		// do nothing
	}

	void free(ubyte*, size_t ) {
		// do nothing
	}
}
