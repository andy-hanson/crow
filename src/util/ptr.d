module util.ptr;

@safe @nogc pure nothrow:

@trusted T* ptrTrustMe(T)(scope ref T t) =>
	castNonScope(&t);

@trusted immutable(T*) castImmutable(T)(T* a) =>
	cast(immutable) a;

@trusted T* castMutable(T)(immutable T* a) =>
	cast(T*) a;

@trusted inout(T) castNonScope(T)(scope inout T x) {
	static if (is(T == P*, P)) {
		size_t res = cast(size_t) x;
		return cast(inout T) res;
	} else static if (is(T == P[], P)) {
		size_t res = cast(size_t) x.ptr;
		return (cast(inout P*) res)[0 .. x.length];
	} else
		return x;
}

@trusted ref inout(T) castNonScope_ref(T)(scope ref inout T x) =>
	*castNonScope(&x);
