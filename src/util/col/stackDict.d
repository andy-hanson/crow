module util.col.stackDict;

@safe @nogc pure nothrow:

import util.ptr : Ptr, ptrTrustMe;
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
