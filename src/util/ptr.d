module util.ptr;

@safe @nogc pure nothrow:

// Non-null
struct Ptr(T) {
	@safe @nogc pure nothrow:
	this(T* p) {
		ptr = p;
		assert(ptr != null);
	}
	this(immutable T* p) immutable {
		ptr = p;
		assert(ptr != null);
	}

	private T* ptr;

	ref T deref() {
		return *ptr;
	}
	ref immutable(T) deref() immutable {
		return *ptr;
	}

	alias deref this;
}

@trusted Ptr!T ptrTrustMe(T)(ref T t) {
	return Ptr!T(&t);
}
