module util.col.stackMap;

@safe @nogc pure nothrow:

import util.ptr : castNonScope_ref, ptrTrustMe;
import util.util : verify;

immutable struct StackMap(K, V) {
	private:
	@disable this(ref const StackMap);
	K key = invalid!K;
	V value;
	StackMap!(K, V)* next;
}

private immutable(K) invalid(K)() {
	static if (is(K == P*, P))
		return null;
	else
		return K.INVALID;
}

ref immutable(V) stackMapMustGet(K, V)(return ref StackMap!(K, V) a, scope immutable K key) {
	verify(a.key != invalid!K);
	return a.key == key ? a.value : stackMapMustGet!(K, V)(*a.next, key);
}

@trusted StackMap!(K, V) stackMapAdd(K, V)(
	scope return ref StackMap!(K, V) a,
	immutable K key,
	immutable V value,
) {
	verify(key != invalid!K);
	return StackMap!(K, V)(key, value, ptrTrustMe(a));
}

struct MutStackMap(K, V) {
	private:
	//TODO: @disable this(ref const MutStackMap);
	immutable K key = invalid!K;
	V value;
	MutStackMap!(K, V)* next;
}

ref inout(V) mutStackMapMustGet(K, V)(return ref inout(MutStackMap!(K, V)) a, scope immutable K key) {
	verify(a.key != invalid!K);
	return a.key == key
		? a.value
		: mutStackMapMustGet!(K, V)(*a.next, key);
}

@trusted MutStackMap!(K, V) mutStackMapAdd(K, V)(
	return scope ref MutStackMap!(K, V) a,
	immutable K key,
	V value,
) {
	verify(key != invalid!K);
	return MutStackMap!(K, V)(key, value, ptrTrustMe(a));
}

// 2 StackMaps in one
alias StackMap2(K0, V0, K1, V1) = MutStackMap!(StackMap2Key!(K0, K1), StackMap2Value!(V0, V1));
private union StackMap2Key(K0, K1) {
	@safe @nogc pure nothrow:

	// For this to be correct, a K0 and K1 must never be bitwise equal.
	// This is satisfied for pointers to different types.
	static assert(is(K0 == P*, P));
	static assert(is(K1 == P*, P));

	immutable K0 k0;
	immutable K1 k1;

	immutable this(immutable K0 a) { k0 = a; }
	immutable this(immutable K1 a) { k1 = a; }

	static immutable(StackMap2Key!(K0, K1)) INVALID() =>
		immutable StackMap2Key!(K0, K1)(cast(immutable K0) null);
}
private union StackMap2Value(V0, V1) {
	@safe @nogc pure nothrow:

	V0 v0;
	V1 v1;

	inout this(inout V0 a) { v0 = a; }
	inout this(inout V1 a) { v1 = a; }
}

@trusted immutable(StackMap2!(K0, V0, K1, V1)) stackMap2Add0(K0, V0, K1, V1)(
	return scope ref immutable StackMap2!(K0, V0, K1, V1) a,
	return scope immutable K0 key,
	return scope inout V0 value,
) =>
	cast(immutable(StackMap2!(K0, V0, K1, V1))) mutStackMapAdd!(StackMap2Key!(K0, K1), StackMap2Value!(V0, V1))(
		cast(StackMap2!(K0, V0, K1, V1)) a,
		immutable StackMap2Key!(K0, K1)(key),
		cast(StackMap2Value!(V0, V1)) inout StackMap2Value!(V0, V1)(value));

@trusted inout(StackMap2!(K0, V0, K1, V1)) stackMap2Add1(K0, V0, K1, V1)(
	return scope ref inout StackMap2!(K0, V0, K1, V1) a,
	return scope immutable K1 key,
	return scope inout V1 value,
) =>
	cast(inout(StackMap2!(K0, V0, K1, V1))) mutStackMapAdd!(StackMap2Key!(K0, K1), StackMap2Value!(V0, V1))(
		cast(StackMap2!(K0, V0, K1, V1)) a,
		immutable StackMap2Key!(K0, K1)(key),
		cast(StackMap2Value!(V0, V1)) inout StackMap2Value!(V0, V1)(value));

@trusted ref inout(V0) stackMap2MustGet0(K0, V0, K1, V1)(
	scope ref inout StackMap2!(K0, V0, K1, V1) a,
	scope immutable K0 key,
) =>
	mutStackMapMustGet!(StackMap2Key!(K0, K1), StackMap2Value!(V0, V1))(
		a,
		immutable StackMap2Key!(K0, K1)(key)).v0;

@trusted inout(V1) stackMap2MustGet1(K0, V0, K1, V1)(
	scope ref inout StackMap2!(K0, V0, K1, V1) a,
	scope immutable K1 key,
) =>
	mutStackMapMustGet!(StackMap2Key!(K0, K1), StackMap2Value!(V0, V1))(
		castNonScope_ref(a),
		immutable StackMap2Key!(K0, K1)(key)).v1;
