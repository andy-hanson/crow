module util.collection.dict;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, range;
import util.comparison : Comparison;
import util.opt : force, none, Opt, some;
import util.util : unreachable;

struct KeyValuePair(K, V) {
	K key;
	V value;
}

struct Dict(K, V, alias cmp) {
	private:
	Arr!(KeyValuePair!(K, V)) pairs;
}

immutable(Opt!V) getAt(K, V, alias cmp)(immutable Dict!(K, V, cmp) d, immutable K key) {
	foreach (ref immutable KeyValuePair!(K, V) pair; d.pairs.range)
		if (cmp(pair.key, key) == Comparison.equal)
			return some!V(pair.value);
	return none!V;
}

immutable(V) mustGetAt(K, V, alias cmp)(ref immutable Dict!(K, V, cmp) d, immutable K key) {
	immutable Opt!V opt = getAt(d, key);
	return opt.force;
}

ref V mustGetAt_mut(K, V, alias cmp)(return scope ref Dict!(K, V, cmp) d, immutable K key) {
	foreach (ref KeyValuePair!(K, V) pair; d.pairs.range)
		if (cmp(pair.key, key) == Comparison.equal)
			return pair.value;
	return unreachable!V();
}
