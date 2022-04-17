module util.ptr;

@safe @nogc pure nothrow:

import util.col.arr : PtrAndSmallNumber, SmallArray;
import util.hash : Hasher, hashSizeT;
import util.opt : hasInvalid;
import util.util : verify;

/*
WARN: It's the user's responsibility to ensure that the type associated with each kind is consistent.
Stores a kind in the lower 2 bits of the pointer.
Also can store array length in the upper 16 bits.
*/
struct TaggedPtr(E) {
	@safe @nogc pure nothrow:

	@system immutable this(immutable E tag, immutable void* ptr) {
		value = taggedValue(tag, cast(immutable ulong) ptr);
	}
	@system immutable this(T)(immutable E tag, immutable T[] values) {
		value = taggedValue(tag, SmallArray!T.encode(values));
	}
	@system immutable this(T)(immutable E tag, immutable PtrAndSmallNumber!T pn) {
		value = taggedValue(tag, pn.asUlong());
	}

	private static ulong taggedValue(immutable E tag, immutable ulong value) {
		immutable ulong tagValue = cast(immutable ulong) tag;
		verify(tagValue < 0b100);
		// Ptr must be word-aligned.
		verify((value & 0b11) == 0);
		return value | tagValue;
	}

	@system immutable(E) tag() immutable {
		return cast(E) (value & 0b11);
	}
	@system immutable(Ptr!T) asPtr(T)() immutable {
		return immutable Ptr!T(cast(immutable T*) cast(void*) (value & ~0b11));
	}
	@system immutable(T[]) asArray(T)() immutable {
		return SmallArray!T.decode(value & ~0b11);
	}
	@system immutable(PtrAndSmallNumber!T) asPtrAndSmallNumber(T)() immutable {
		return PtrAndSmallNumber!T.decode(value & ~0b11);
	}

	private:
	ulong value;
}

// Non-null
struct Ptr(T) {
	static immutable Ptr!T INVALID = immutable Ptr!T(null, true);
	static Ptr!T INVALID_mut = Ptr!T(null, true);

	@safe @nogc pure nothrow:
	@disable this(); // No nulls!
	@trusted this(inout T* p) inout {
		ptr = cast(inout void*) p;
		verify!"Ptr constructor"(ptr != null);
	}
	@trusted this(immutable T* p, immutable bool) immutable {
		ptr = p;
	}
	@trusted this(T* p, immutable bool) {
		ptr = cast(void*) p;
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
static assert(hasInvalid!(Ptr!int));

// Only for use as a sentinel
static immutable Ptr!T nullPtr(T) = immutable Ptr!T(null, true);
static Ptr!T nullPtr_mut(T) = Ptr!T(null, true);

@trusted immutable(Ptr!T) ptrTrustMe(T)(scope ref immutable T t) {
	return immutable Ptr!T(&t);
}

@trusted Ptr!T ptrTrustMe_mut(T)(scope ref T t) {
	return Ptr!T(&t);
}

@trusted const(Ptr!T) ptrTrustMe_const(T)(ref const T t) {
	return const Ptr!T(&t);
}

immutable(bool) ptrEquals(T)(const Ptr!T a, const Ptr!T b) {
	return a.ptr == b.ptr;
}

void hashPtr(T)(ref Hasher hasher, const Ptr!T a) {
	hashSizeT(hasher, cast(immutable size_t) a.rawPtr());
}

@trusted immutable(T*) castImmutable(T)(T* a) {
	return cast(immutable) a;
}

@trusted immutable(Ptr!T) castImmutable(T)(Ptr!T a) {
	return cast(immutable) a;
}

@trusted Ptr!T castMutable(T)(immutable Ptr!T a) {
	return cast(Ptr!T) a;
}
