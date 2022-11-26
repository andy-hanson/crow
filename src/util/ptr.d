module util.ptr;

@safe @nogc pure nothrow:

import util.hash : Hasher, hashSizeT;

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
