module util.col.stackDict;

@safe @nogc pure nothrow:

import util.opt : none, Opt, some;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.util : verify;

struct StackDict(K, V) {
	private:
	@disable this(ref const StackDict);
	immutable K key = invalid!K;
	immutable V value = void;
	immutable StackDict!(K, V)* next = void;
}

private immutable(K) invalid(K)() {
	static if (is(K == P*, P))
		return null;
	else
		return K.INVALID;
}

ref immutable(V) stackDictMustGet(K, V)(return ref immutable StackDict!(K, V) a, scope immutable K key) {
	verify(a.key != invalid!K);
	return a.key == key ? a.value : stackDictMustGet!(K, V)(*a.next, key);
}

@trusted immutable(StackDict!(K, V)) stackDictAdd(K, V)(
	scope return ref immutable StackDict!(K, V) a,
	immutable K key,
	immutable V value,
) {
	verify(key != invalid!K);
	return StackDict!(K, V)(key, value, ptrTrustMe(a));
}

immutable(Opt!V) stackDictLastAdded(K, V)(
	return scope ref immutable StackDict!(K, V) a,
) =>
	a.key == invalid!K ? none!V : some(a.value);

struct MutStackDict(K, V) {
	private:
	//@disable this(ref const MutStackDict);
	immutable K key = invalid!K;
	V value = void;
	MutStackDict!(K, V)* next = void;
}

ref inout(V) mutStackDictMustGet(K, V)(return ref inout(MutStackDict!(K, V)) a, scope immutable K key) {
	verify(a.key != invalid!K);
	return a.key == key
		? a.value
		: mutStackDictMustGet!(K, V)(*a.next, key);
}

@trusted MutStackDict!(K, V) mutStackDictAdd(K, V)(
	return scope ref MutStackDict!(K, V) a,
	immutable K key,
	V value,
) {
	verify(key != invalid!K);
	return MutStackDict!(K, V)(key, value, ptrTrustMe(a));
}

// 2 StackDicts in one
alias StackDict2(K0, V0, K1, V1) = MutStackDict!(StackDict2Key!(K0, K1), StackDict2Value!(V0, V1));
private union StackDict2Key(K0, K1) {
	@safe @nogc pure nothrow:

	// For this to be correct, a K0 and K1 must never be bitwise equal.
	// This is satisfied for pointers to different types.
	static assert(is(K0 == P*, P));
	static assert(is(K1 == P*, P));

	immutable K0 k0;
	immutable K1 k1;

	immutable this(immutable K0 a) { k0 = a; }
	immutable this(immutable K1 a) { k1 = a; }

	static immutable(StackDict2Key!(K0, K1)) INVALID() =>
		immutable StackDict2Key!(K0, K1)(cast(immutable K0) null);
}
private union StackDict2Value(V0, V1) {
	@safe @nogc pure nothrow:

	V0 v0;
	V1 v1;

	inout this(inout V0 a) { v0 = a; }
	inout this(inout V1 a) { v1 = a; }
}

@trusted inout(StackDict2!(K0, V0, K1, V1)) stackDict2Add0(K0, V0, K1, V1)(
	return scope ref inout StackDict2!(K0, V0, K1, V1) a,
	return scope immutable K0 key,
	return scope inout V0 value,
) =>
	cast(inout(StackDict2!(K0, V0, K1, V1))) mutStackDictAdd!(StackDict2Key!(K0, K1), StackDict2Value!(V0, V1))(
		cast(StackDict2!(K0, V0, K1, V1)) a,
		immutable StackDict2Key!(K0, K1)(key),
		cast(StackDict2Value!(V0, V1)) inout StackDict2Value!(V0, V1)(value));

@trusted inout(StackDict2!(K0, V0, K1, V1)) stackDict2Add1(K0, V0, K1, V1)(
	return scope ref inout StackDict2!(K0, V0, K1, V1) a,
	return scope immutable K1 key,
	return scope inout V1 value,
) =>
	cast(inout(StackDict2!(K0, V0, K1, V1))) mutStackDictAdd!(StackDict2Key!(K0, K1), StackDict2Value!(V0, V1))(
		cast(StackDict2!(K0, V0, K1, V1)) a,
		immutable StackDict2Key!(K0, K1)(key),
		cast(StackDict2Value!(V0, V1)) inout StackDict2Value!(V0, V1)(value));

@trusted ref inout(V0) stackDict2MustGet0(K0, V0, K1, V1)(
	scope return ref inout(StackDict2!(K0, V0, K1, V1)) a,
	scope immutable K0 key,
) =>
	mutStackDictMustGet!(StackDict2Key!(K0, K1), StackDict2Value!(V0, V1))(
		a,
		immutable StackDict2Key!(K0, K1)(key)).v0;

@trusted inout(V1) stackDict2MustGet1(K0, V0, K1, V1)(
	return scope ref inout(StackDict2!(K0, V0, K1, V1)) a,
	scope immutable K1 key,
) =>
	mutStackDictMustGet!(StackDict2Key!(K0, K1), StackDict2Value!(V0, V1))(
		castNonScope_ref(a),
		immutable StackDict2Key!(K0, K1)(key)).v1;
