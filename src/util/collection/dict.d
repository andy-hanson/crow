module util.collection.dict;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, ptrsRange;
import util.comparison : Comparison;
import util.opt : force, none, Opt, some;
import util.ptr : Ptr, ptrTrustMe;
import util.util : unreachable;

struct KeyValuePair(K, V) {
	K key;
	V value;
}

struct Dict(K, V, alias cmp) {
	//TODO: private:
	Arr!(KeyValuePair!(K, V)) pairs;
}

void dictEach(K, V, alias cmp)(
	ref immutable Dict!(K, V, cmp) a,
	scope void delegate(ref immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable KeyValuePair!(K, V) pair; a.pairs)
		cb(pair.key, pair.value);
}

immutable(Bool) hasKey(K, V, alias cmp)(ref immutable Dict!(K, V, cmp) a, immutable K key) {
	foreach (ref immutable KeyValuePair!(K, V) pair; a.pairs)
		if (cmp(pair.key, key) == Comparison.equal)
			return True;
	return False;
}

immutable(Opt!(Ptr!V)) getPtrAt(K, V, alias cmp)(immutable Dict!(K, V, cmp) d, immutable K key) {
	foreach (immutable Ptr!(KeyValuePair!(K, V)) pair; ptrsRange(d.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return some!(Ptr!V)(ptrTrustMe(pair.value));
	return none!(Ptr!V);
}

immutable(Opt!V) getAt(K, V, alias cmp)(immutable Dict!(K, V, cmp) d, immutable K key) {
	foreach (ref immutable KeyValuePair!(K, V) pair; d.pairs)
		if (cmp(pair.key, key) == Comparison.equal)
			return some!V(pair.value);
	return none!V;
}

immutable(V) mustGetAt(K, V, alias cmp)(ref immutable Dict!(K, V, cmp) d, immutable K key) {
	immutable Opt!V opt = getAt(d, key);
	return force(opt);
}

ref V mustGetAt_mut(K, V, alias cmp)(return scope ref Dict!(K, V, cmp) d, immutable K key) {
	foreach (ref KeyValuePair!(K, V) pair; d.pairs)
		if (cmp(pair.key, key) == Comparison.equal)
			return pair.value;
	return unreachable!V();
}
