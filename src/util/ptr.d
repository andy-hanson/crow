module util.ptr;

@safe @nogc pure nothrow:

import util.collection.arr : begin, end;
import util.comparison : Comparison;
import util.util : verify;

// Non-null
struct Ptr(T) {
	@safe @nogc pure nothrow:
	@disable this(); // No nulls!
	this(immutable T* p) immutable {
		ptr = p;
		verify(ptr != null);
	}
	this(inout T* p) inout {
		ptr = p;
		verify(ptr != null);
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

	const(T*) rawPtr() const { return ptr; }
	immutable(T*) rawPtr() immutable { return ptr; }

	alias deref this;
}

@trusted immutable(Ptr!T) ptrTrustMe(T)(ref immutable T t) {
	return immutable Ptr!T(&t);
}

@trusted Ptr!T ptrTrustMe_mut(T)(ref T t) {
	return Ptr!T(&t);
}

@trusted const(Ptr!T) ptrTrustMe_const(T)(ref const T t) {
	return const Ptr!T(&t);
}

immutable(bool) ptrEquals(T)(const Ptr!T a, const Ptr!T b) {
	return a.ptr == b.ptr;
}

immutable(Comparison) comparePtr(T)(const Ptr!T a, const Ptr!T b) {
	return comparePtrRaw(a.ptr, b.ptr);
}

immutable(Comparison) comparePtrRaw(T)(const T* a, const T* b) {
	return a < b
		? Comparison.less
		: a > b
		? Comparison.greater
		: Comparison.equal;
}

@trusted immutable(Ptr!T) castImmutable(T)(Ptr!T a) {
	return cast(immutable) a;
}

@trusted Ptr!T castMutable(T)(immutable Ptr!T a) {
	return cast(Ptr!T) a;
}

struct PtrRange {
	const ubyte* begin;
	const ubyte* end;
}

@trusted const(PtrRange) ptrRangeOfArr(T)(const T[] a) {
	return const PtrRange(cast(const ubyte*) begin(a), cast(const ubyte*) end(a));
}

immutable(bool) contains(const PtrRange a, const PtrRange b) {
	return a.begin <= b.begin && b.end <= a.end;
}
