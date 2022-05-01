module util.col.multiDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : emptyArr;
import util.col.dict : dictEach, Dict, KeyValuePair;
import util.col.mutArr : moveToArr, MutArr, push;
import util.col.mutDict : getOrAdd, mapToDict, MutDict;
import util.opt : force, has, Opt;

struct MultiDict(K, V) {
	private immutable Dict!(K, V[]) inner;

	immutable(V[]) opIndex(immutable K key) immutable {
		immutable Opt!(V[]) res = inner[key];
		return has(res) ? force(res) : emptyArr!V;
	}
}

@trusted void multiDictEach(K, V)(
	ref immutable MultiDict!(K, V) a,
	scope void delegate(immutable K, immutable V[]) @safe @nogc pure nothrow cb,
) {
	dictEach!(K, V[])(a.inner, (immutable K key, ref immutable V[] value) {
		cb(key, value);
	});
}

@trusted immutable(MultiDict!(K, V)) buildMultiDict(K, V, T)(
	ref Alloc alloc,
	immutable T[] inputs,
	scope immutable(KeyValuePair!(K, V)) delegate(immutable size_t, immutable T*) @safe @nogc pure nothrow getPair,
) {
	MutDict!(immutable K, MutArr!(immutable V)) builder;
	foreach (immutable size_t i; 0 .. inputs.length) {
		immutable KeyValuePair!(K, V) pair = getPair(i, &inputs[i]);
		push(alloc, getOrAdd(alloc, builder, pair.key, () => MutArr!(immutable V)()), pair.value);
	}
	return immutable MultiDict!(K, V)(
		mapToDict!(K, V[], MutArr!(immutable V))(alloc, builder, (ref MutArr!(immutable V) arr) =>
			moveToArr!V(alloc, arr)));
}
