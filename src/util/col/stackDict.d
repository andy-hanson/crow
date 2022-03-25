module util.col.stackDict;

@safe @nogc pure nothrow:

import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.util : verify;

struct StackDict(K, V, immutable K emptySentinel, alias equal) {
	private:
	@disable this(ref const StackDict);
	immutable K key = emptySentinel;
	immutable V value = void;
	immutable Ptr!(StackDict!(K, V, emptySentinel, equal)) next = void;
}

ref immutable(V) stackDictMustGet(K, V, immutable K emptySentinel, alias equal)(
	return scope ref immutable StackDict!(K, V, emptySentinel, equal) a,
	scope immutable K key,
) {
	verify(!equal(a.key, emptySentinel));
	return equal(a.key, key)
		? a.value
		: stackDictMustGet!(K, V, emptySentinel, equal)(a.next.deref(), key);
}

@trusted immutable(StackDict!(K, V, emptySentinel, equal)) stackDictAdd(K, V, immutable K emptySentinel, alias equal)(
	return scope ref immutable StackDict!(K, V, emptySentinel, equal) a,
	immutable K key,
	immutable V value,
) {
	verify(!equal(key, emptySentinel));
	return StackDict!(K, V, emptySentinel, equal)(key, value, ptrTrustMe(a));
}

struct MutStackDict(K, V, immutable K emptySentinel, alias equal) {
	@disable this(ref const MutStackDict);
	immutable K key = emptySentinel;
	V value = void;
	Ptr!(MutStackDict!(K, V, emptySentinel, equal)) next = void;
}

ref V mutStackDictMustGet(K, V, immutable K emptySentinel, alias equal)(
	return scope ref MutStackDict!(K, V, emptySentinel, equal) a,
	scope immutable K key,
) {
	verify(!equal(a.key, emptySentinel));
	return equal(a.key, key)
		? a.value
		: mutStackDictMustGet!(K, V, emptySentinel, equal)(a.next.deref(), key);
}

@trusted MutStackDict!(K, V, emptySentinel, equal) mutStackDictAdd(K, V, immutable K emptySentinel, alias equal)(
	return scope ref MutStackDict!(K, V, emptySentinel, equal) a,
	immutable K key,
	V value,
) {
	verify(!equal(key, emptySentinel));
	return MutStackDict!(K, V, emptySentinel, equal)(key, value, ptrTrustMe_mut(a));
}
