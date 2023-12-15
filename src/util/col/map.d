module util.col.map;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : zip;
import util.col.mutMap : hasKey, mapToArray, moveToMap, mustAdd, mustGet, MutMap, MutMapValues, size, values;
public import util.col.mutMap : KeyValuePair;
import util.opt : Opt;

immutable struct Map(K, V) {
	@safe @nogc pure nothrow:

	private MutMap!(K, V) inner;

	@trusted Opt!V opIndex(in K key) scope =>
		inner[key];

	int opApply(in int delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb) scope =>
		inner.opApply(cb);
}
immutable(MutMapValues!(K, V)) values(K, V)(ref Map!(K, V) a) =>
	.values(a.inner);

size_t size(K, V)(in Map!(K, V) a) =>
	.size(a.inner);

bool hasKey(K, V)(in Map!(K, V) a, immutable K key) =>
	.hasKey(a.inner, key);

Map!(immutable K, immutable V) zipToMap(K, V, X, Y)(
	ref Alloc alloc,
	in immutable X[] xs,
	in immutable Y[] ys,
	in immutable(KeyValuePair!(immutable K, immutable V)) delegate(
		ref immutable X,
		ref immutable Y,
	) @safe @nogc pure nothrow cb,
) {
	MutMap!(immutable K, immutable V) res;
	zip!(immutable X, immutable Y)(xs, ys, (ref immutable X x, ref immutable Y y) {
		immutable KeyValuePair!(immutable K, immutable V) pair = cb(x, y);
		mustAdd!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	});
	return moveToMap!(immutable K, immutable V)(alloc, res);
}

Map!(K, V) makeMap(K, V, T)(
	ref Alloc alloc,
	in T[] inputs,
	in immutable(KeyValuePair!(K, V)) delegate(in T) @safe @nogc pure nothrow getPair,
) =>
	makeMapWithIndex!(K, V, T)(alloc, inputs, (size_t _, in T x) => getPair(x));

Map!(K, V) makeMapWithIndex(K, V, T)(
	ref Alloc alloc,
	in T[] inputs,
	in immutable(KeyValuePair!(K, V)) delegate(size_t, in T) @safe @nogc pure nothrow getPair,
) {
	MutMap!(immutable K, immutable V) res;
	foreach (size_t i, ref const T input; inputs) {
		immutable KeyValuePair!(K, V) pair = getPair(i, input);
		mustAdd!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	}
	Map!(K, V) mapRes = moveToMap!(K, V)(alloc, res);
	assert(size(mapRes) == inputs.length);
	return mapRes;
}

Map!(K, V) makeMapFromKeys(K, V)(
	ref Alloc alloc,
	scope immutable K[] keys,
	in immutable(V) delegate(immutable K) @safe @nogc pure nothrow getValue,
) =>
	makeMap!(K, V, K)(alloc, keys, (in K key) =>
		immutable KeyValuePair!(K, V)(key, getValue(key)));

@trusted immutable(V) mustGet(K, V)(Map!(K, V) a, in K key) =>
	.mustGet(a.inner, key);

Out[] mapToArray(Out, K, V)(
	ref Alloc alloc,
	in Map!(K, V) a,
	in Out delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) =>
	.mapToArray!(Out, K, V)(alloc, a.inner, cb);
