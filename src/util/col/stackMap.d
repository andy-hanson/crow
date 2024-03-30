module util.col.stackMap;

@safe @nogc pure nothrow:

import util.util : ptrTrustMe;

struct StackMap(K, V) {
	private:
	@disable this(ref const StackMap);
	immutable K key = invalid!K;
	V value = void;
	StackMap!(K, V)* next;
}

private immutable(K) invalid(K)() {
	static if (is(K == P*, P))
		return null;
	else
		return K.INVALID;
}

ref inout(V) stackMapMustGet(K, V)(return ref inout(StackMap!(K, V)) a, scope immutable K key) {
	assert(a.key != invalid!K);
	return a.key == key
		? a.value
		: stackMapMustGet!(K, V)(*a.next, key);
}

@trusted inout(StackMap!(K, V)) stackMapAdd(K, V)(
	return scope ref inout StackMap!(K, V) a,
	immutable K key,
	inout V value,
) {
	assert(key != invalid!K);
	return inout StackMap!(K, V)(key, value, cast(inout StackMap!(K, V)*) ptrTrustMe(a));
}

@trusted T withStackMap(T, K, V)(in T delegate(ref StackMap!(K, V)) @safe @nogc pure nothrow cb) {
	StackMap!(K, V) map;
	return cb(map);
}
