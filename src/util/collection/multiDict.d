module util.collection.multiDict;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, emptyArr;
import util.comparison : Comparison;

struct MultiDict(K, V, alias compare) {
	immutable size_t size;
	immutable K* keys;
	immutable V* values;
}

immutable(Arr!V) multiDictGetAt(K, V, alias compare)(immutable MultiDict!(K, V, compare) d, immutable K key) {
	foreach (immutable size_t i; 0..d.size) {
		if (compare(d.keys[i], key) == Comparison.equal) {
			size_t j = i + 1;
			for (; j < d.size; ++j) {
				if (!compare(d.keys[j], key) == Comparison.equal)
					break;
			}
			return immutable Arr!V(ptrAt(d.values, i), j - i);
		}
	}
	return emptyArr!V;
}
