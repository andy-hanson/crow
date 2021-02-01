module util.collection.multiDict;

@safe @nogc pure nothrow:

import util.collection.arr : emptyArr;
import util.comparison : Comparison;
import util.util : verify;

struct MultiDict(K, V, alias compare) {
	private:
	immutable size_t size;
	immutable K* keys;
	immutable V* values;
}

@trusted void multiDictEach(K, V, alias compare)(
	ref immutable MultiDict!(K, V, compare) a,
	scope void delegate(ref immutable K, immutable V[]) @safe @nogc pure nothrow cb,
) {
	void recur(immutable K k, immutable size_t startI, immutable size_t curI) {
		verify(curI > startI);
		if (curI == a.size)
			cb(k, a.values[startI .. curI]);
		else {
			if (compare(a.keys[curI], k) == Comparison.equal)
				recur(k, startI, curI + 1);
			else {
				cb(k, a.values[startI .. curI]);
				recur(a.keys[curI], curI, curI + 1);
			}
		}
	}

	if (a.size != 0)
		recur(a.keys[0], 0, 1);
}

@trusted immutable(V[]) multiDictGetAt(K, V, alias compare)(
	ref immutable MultiDict!(K, V, compare) d,
	ref immutable K key,
) {
	foreach (immutable size_t i; 0 .. d.size) {
		if (compare(d.keys[i], key) == Comparison.equal) {
			size_t j = i + 1;
			for (; j < d.size; ++j) {
				if (!compare(d.keys[j], key) == Comparison.equal)
					break;
			}
			return d.values[i .. j];
		}
	}
	return emptyArr!V;
}
