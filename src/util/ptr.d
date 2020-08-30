module util.ptr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.comparison : Comparison;

// Non-null
struct Ptr(T) {
	@safe @nogc pure nothrow:
	@disable this(); // No nulls!
	this(T* p) {
		ptr = p;
		assert(ptr != null);
	}
	this(const T* p) const {
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
	ref const(T) deref() const {
		return *ptr;
	}
	ref immutable(T) deref() immutable {
		return *ptr;
	}

	immutable(T*) rawPtr() immutable { return ptr; }

	alias deref this;
}

@trusted immutable(Ptr!T) ptrTrustMe(T)(ref immutable T t) {
	return immutable Ptr!T(&t);
}

@trusted Ptr!T ptrTrustMe_mut(T)(ref T t) {
	return Ptr!T(&t);
}

immutable(Bool) ptrEquals(T)(const Ptr!T a, const Ptr!T b) {
	return Bool(a.ptr == b.ptr);
}

immutable(Comparison) comparePtr(T)(const Ptr!T a, const Ptr!T b) {
	return a.ptr < b.ptr
		? Comparison.less
		: a.ptr > b.ptr
		? Comparison.greater
		: Comparison.equal;
}

@trusted immutable(Ptr!T) castImmutable(T)(Ptr!T a) {
	return cast(immutable) a;
}

@trusted Ptr!T castMutable(T)(immutable Ptr!T a) {
	return cast(Ptr!T) a;
}
