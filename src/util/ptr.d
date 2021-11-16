module util.ptr;

@safe @nogc pure nothrow:

import util.collection.arr : ArrWithSize, begin, end, toArr;
import util.hash : Hasher, hashSizeT;
import util.util : verify;

struct TaggedPtr(E) {
	@safe @nogc pure nothrow:

	immutable this(immutable E tag, immutable void* ptr) {
		immutable size_t tagValue = cast(size_t) tag;
		immutable size_t ptrValue = cast(size_t) ptr;
		verify(tagValue < 4);
		// Ptr must be word-aligned.
		verify((ptrValue & 0b11) == 0);
		value = ptrValue | tagValue;
	}

	immutable(E) tag() immutable {
		return cast(E) (value & 0b11);
	}
	@system immutable(void*) ptr() immutable {
		return cast(immutable void*) cast(void*) (value & ~0b11);
	}
	@system immutable(T[]) arrWithSize(T)() immutable {
		return toArr(immutable ArrWithSize!T(cast(immutable ubyte*) ptr()));
	}

	private:
	size_t value;
}

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

	// Using a void* greatly speeds up compile times. Don't know why.
	private void* ptr;

	ref T deref() {
		return *rawPtr();
	}
	ref const(T) deref() const {
		return *rawPtr();
	}
	ref immutable(T) deref() immutable {
		return *rawPtr();
	}

	@trusted T* rawPtr() { return cast(T*) ptr; }
	@trusted const(T*) rawPtr() const { return cast(const T*) ptr; }
	@trusted immutable(T*) rawPtr() immutable { return cast(immutable T*) ptr; }
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

immutable(bool) ptrEqualsRaw(T)(const T* a, const T* b) {
	return a == b;
}

void hashPtr(T)(ref Hasher hasher, const Ptr!T a) {
	hashSizeT(hasher, cast(immutable size_t) a.rawPtr());
}

void hashPtrRaw(T)(ref Hasher hasher, const T* a) {
	hashSizeT(hasher, cast(immutable size_t) a);
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
