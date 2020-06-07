module util.ptr;

@safe @nogc pure nothrow:

// Non-null
struct Ptr(T) {
	@safe @nogc pure nothrow:
	this(T* p) {
		ptr = p;
		assert(ptr != null);
	}

	private T* ptr;

	ref immutable(T) deref() immutable {
		return *ptr;
	}

	alias deref this;
}
