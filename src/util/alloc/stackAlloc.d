module util.alloc.stackAlloc;

@safe @nogc pure nothrow:

import util.ptr : Ptr;
import util.util : verify, verifyFail;
import util.alloc.mallocator : Mallocator;

struct StackAlloc(immutable char* debugName, size_t capacity) {
	@safe @nogc pure nothrow:
	private:
	ubyte[capacity] data_ = void;
	size_t cur;

	public:
	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (cur + nBytes > capacity) {
			debug {
				//import util.print : print;
				//print("Stack alloc ran out of space\n");
				//print(debugName);
				//print("\n");
				//print("capacity: %zd, already filled: %zd, tried to allocate: %zd\n", capacity, cur, nBytes);
			}
			verifyFail();
		}

		ubyte* res = data_.ptr + cur;
		cur += nBytes;
		return res;
	}

	void freePartial(ubyte*, immutable size_t) {
		// do nothing
	}

	void free(ubyte*, immutable size_t) {
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
		parentAlloc = parent;
		data_ = parentAlloc.allocate(capacity);
		verify(data_ != null);
		cur = 0;
	}

	~this() {
		parentAlloc.free(data_, capacity);
	}

	@trusted ubyte* allocate(immutable size_t nBytes) {
		if (cur + nBytes > capacity) {
			debug {
				import util.print : print;
				print("SingleHeapAlloc ran out of space\n");
				print(debugName);
				print("\n");
				//print("capacity: %zd, already filled: %zd, tried to allocate: %zd\n", capacity, cur, nBytes);
			}
			verifyFail(); // TODO
		}

		ubyte* res = data_ + cur;
		cur += nBytes;
		return res;
	}

	void freePartial(ubyte*, immutable size_t) {
		// do nothing
	}

	void free(ubyte*, immutable size_t) {
		// do nothing
	}
}
