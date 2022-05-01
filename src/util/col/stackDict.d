module util.col.stackDict;

@safe @nogc pure nothrow:

import util.ptr : ptrTrustMe, ptrTrustMe_mut;
import util.util : verify;

struct StackDict(K, V) {
	static assert(is(K == P*, P));

	private:
	@disable this(ref const StackDict);
	immutable K key = null;
	immutable V value = void;
	immutable StackDict!(K, V)* next = void;
}

ref immutable(V) stackDictMustGet(K, V)(return scope ref immutable StackDict!(K, V) a, scope immutable K key) {
	verify(a.key != null);
	return a.key == key ? a.value : stackDictMustGet!(K, V)(*a.next, key);
}

@trusted immutable(StackDict!(K, V)) stackDictAdd(K, V)(
	return scope ref immutable StackDict!(K, V) a,
	immutable K key,
	immutable V value,
) {
	verify(key != null);
	return StackDict!(K, V)(key, value, ptrTrustMe(a));
}

struct MutStackDict(K, V) {
	@disable this(ref const MutStackDict);
	static assert(is(K == P*, P));

	private:
	@disable this(ref const MutStackDict);
	immutable K key = null;
	V value = void;
	MutStackDict!(K, V)* next = void;
}

ref V mutStackDictMustGet(K, V)(return scope ref MutStackDict!(K, V) a, scope immutable K key) {
	verify(a.key != null);
	return a.key == key
		? a.value
		: mutStackDictMustGet!(K, V)(*a.next, key);
}

@trusted MutStackDict!(K, V) mutStackDictAdd(K, V)(return scope ref MutStackDict!(K, V) a, immutable K key, V value) {
	verify(key != null);
	return MutStackDict!(K, V)(key, value, ptrTrustMe_mut(a));
}
