module util.col.multiDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.dict : dictEach, Dict, KeyValuePair;
import util.col.mutArr : moveToArr, MutArr, push;
import util.col.mutDict : getOrAdd, mapToDict, MutDict;
import util.opt : force, has, Opt;

immutable struct MultiDict(K, V) {
	private Dict!(K, V[]) inner;

	immutable(V[]) opIndex(in K key) immutable {
		Opt!(V[]) res = inner[key];
		return has(res) ? force(res) : [];
	}
}

@trusted void multiDictEach(K, V)(
	ref MultiDict!(K, V) a,
	in void delegate(immutable K, immutable V[]) @safe @nogc pure nothrow cb,
) {
	dictEach!(K, V[])(a.inner, (immutable K key, ref immutable V[] value) {
		cb(key, value);
	});
}

@trusted MultiDict!(K, V) buildMultiDict(K, V, T)(
	ref Alloc alloc,
	T[] inputs,
	in KeyValuePair!(K, V) delegate(size_t, T*) @safe @nogc pure nothrow getPair,
) {
	MutDict!(immutable K, MutArr!(immutable V)) builder;
	foreach (size_t i; 0 .. inputs.length) {
		KeyValuePair!(K, V) pair = getPair(i, &inputs[i]);
		push(alloc, getOrAdd(alloc, builder, pair.key, () => MutArr!(immutable V)()), pair.value);
	}
	return MultiDict!(K, V)(
		mapToDict!(K, V[], MutArr!(immutable V))(alloc, builder, (ref MutArr!(immutable V) arr) =>
			moveToArr!V(alloc, arr)));
}
