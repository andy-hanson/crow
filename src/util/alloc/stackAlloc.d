module util.alloc.stackAlloc;

@safe @nogc pure nothrow:

import core.stdc.stdlib : malloc;
import util.ptr : Ptr;

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

// Behaves exactly like StackAlloc, but not on stack
struct SingleHeapAlloc(ParentAlloc, string debugName, size_t capacity) {
	@safe @nogc pure nothrow:
	private:
	Ptr!ParentAlloc parentAlloc;
	ubyte* data_;
	size_t cur;

	@disable this();

	public:
	this(Ptr!ParentAlloc parent) {
		debug {
			import core.stdc.stdio : printf;
			if (false) printf("Init SingleHeapAlloc %.*s\n", cast(int) debugName.length, debugName.ptr);
		}
		parentAlloc = parent;
		data_ = parentAlloc.allocate(capacity);
		assert(data_ != null);
		cur = 0;
	}

	~this() {
		debug {
			import core.stdc.stdio : printf;
			if (false) printf("Delete SingleHeapAlloc %.*s\n", cast(int) debugName.length, debugName.ptr);
		}
		parentAlloc.free(data_, capacity);
	}

	@trusted ubyte* allocate(immutable size_t nBytes) {
		debug {
			import core.stdc.stdio : printf;
		}

		if (cur + nBytes > capacity) {
			debug {
				import core.stdc.stdio : printf;
				printf("SingleHeapAlloc %.*s ran out of space\n\n", cast(int) debugName.length, debugName.ptr);
				printf("capacity: %zd, already filled: %zd, tried to allocate: %zd\n", capacity, cur, nBytes);
			}
			assert(0); // TODO
		}

		ubyte* res = data_ + cur;
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
