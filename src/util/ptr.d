module util.ptr;

@safe @nogc pure nothrow:

import util.col.arr : PtrAndSmallNumber, SmallArray;
import util.hash : Hasher, hashSizeT;
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

	@system immutable(E) tag() immutable =>
		cast(E) (value & 0b11);
	@system immutable(T*) asPtr(T)() immutable =>
		cast(immutable T*) cast(void*) (value & ~0b11);
	@system immutable(T[]) asArray(T)() immutable =>
		SmallArray!T.decode(value & ~0b11);
	@system immutable(PtrAndSmallNumber!T) asPtrAndSmallNumber(T)() immutable =>
		PtrAndSmallNumber!T.decode(value & ~0b11);

	private:
	ulong value;
}

@trusted T* ptrTrustMe(T)(scope ref T t) =>
	castNonScope(&t);

void hashPtr(T)(ref Hasher hasher, const T* a) {
	hashSizeT(hasher, cast(immutable size_t) a);
}

@trusted immutable(T*) castImmutable(T)(T* a) =>
	cast(immutable) a;

@trusted T* castMutable(T)(immutable T* a) =>
	cast(T*) a;

@trusted inout(T) castNonScope(T)(scope inout T x) {
	static if (is(T == P*, P)) {
		immutable size_t res = cast(immutable size_t) x;
		return cast(inout T) res;
	} else static if (is(T == P[], P)) {
		immutable size_t res = cast(immutable size_t) x.ptr;
		return (cast(inout P*) res)[0 .. x.length];
	} else
		return x;
}

@trusted ref inout(T) castNonScope_ref(T)(scope ref inout T x) =>
	*castNonScope(&x);
