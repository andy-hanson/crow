module util.col.map;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : zip;
import util.col.mutMap :
	addToMutMap,
	existsInMutMap,
	getAt_mut,
	hasKey_mut,
	moveToMap,
	mustGetAt_mut,
	MutMap,
	mutMapEach,
	mutMapEachIn;
public import util.col.mutMap : KeyValuePair;
import util.opt : Opt;

immutable struct Map(K, V) {
	private MutMap!(immutable K, immutable V) inner;

	@trusted Opt!V opIndex(in K key) scope =>
		getAt_mut!(K, V)(inner, key);
}

bool hasKey(K, V)(in Map!(K, V) a, immutable K key) =>
	hasKey_mut(a.inner, key);

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
		addToMutMap!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
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
		addToMutMap!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	}
	return moveToMap!(K, V)(alloc, res);
}

Map!(K, V) makeMapFromKeys(K, V)(
	ref Alloc alloc,
	scope immutable K[] keys,
	in immutable(V) delegate(immutable K) @safe @nogc pure nothrow getValue,
) =>
	makeMap!(K, V, K)(alloc, keys, (in K key) =>
		immutable KeyValuePair!(K, V)(key, getValue(key)));

@trusted immutable(V) mustGetAt(K, V)(Map!(K, V) a, in K key) =>
	mustGetAt_mut(a.inner, key);

void mapEach(K, V)(in Map!(K, V) a, in void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb) {
	mutMapEach!(immutable K, immutable V)(a.inner, cb);
}
void mapEachIn(K, V)(in Map!(K, V) a, in void delegate(in K, in V) @safe @nogc pure nothrow cb) {
	mutMapEachIn!(immutable K, immutable V)(a.inner, cb);
}
bool existsInMap(K, V)(in Map!(K, V) a, in bool delegate(in K, in V) @safe @nogc pure nothrow cb) =>
	existsInMutMap!(immutable K, immutable V)(a.inner, cb);

Map!(K, V) mapLiteral(K, V)(ref Alloc alloc, immutable K key, immutable V value) {
	MutMap!(immutable K, immutable V) res;
	addToMutMap(alloc, res, key, value);
	return moveToMap!(K, V)(alloc, res);
}
