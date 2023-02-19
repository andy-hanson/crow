module util.col.dict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : zip;
import util.col.mutDict :
	addToMutDict,
	existsInMutDict,
	getAt_mut,
	hasKey_mut,
	moveToDict,
	mustGetAt_mut,
	MutDict,
	mutDictEach,
	mutDictEachIn;
public import util.col.mutDict : KeyValuePair;
import util.opt : Opt;

immutable struct Dict(K, V) {
	private MutDict!(immutable K, immutable V) inner;

	@trusted Opt!V opIndex(in K key) =>
		getAt_mut!(K, V)(inner, key);
}

bool hasKey(K, V)(in Dict!(K, V) a, immutable K key) =>
	hasKey_mut(a.inner, key);

Dict!(immutable K, immutable V) zipToDict(K, V, X, Y)(
	ref Alloc alloc,
	in immutable X[] xs,
	in immutable Y[] ys,
	in immutable(KeyValuePair!(immutable K, immutable V)) delegate(
		ref immutable X,
		ref immutable Y,
	) @safe @nogc pure nothrow cb,
) {
	MutDict!(immutable K, immutable V) res;
	zip!(immutable X, immutable Y)(xs, ys, (ref immutable X x, ref immutable Y y) {
		immutable KeyValuePair!(immutable K, immutable V) pair = cb(x, y);
		addToMutDict!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	});
	return moveToDict!(immutable K, immutable V)(alloc, res);
}

Dict!(K, V) makeDict(K, V, T)(
	ref Alloc alloc,
	in immutable T[] inputs,
	in immutable(KeyValuePair!(K, V)) delegate(scope ref immutable T) @safe @nogc pure nothrow getPair,
) {
	MutDict!(immutable K, immutable V) res;
	foreach (ref immutable T input; inputs) {
		immutable KeyValuePair!(K, V) pair = getPair(input);
		addToMutDict!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	}
	return moveToDict!(K, V)(alloc, res);
}

Dict!(K, V) makeDictFromKeys(K, V)(
	ref Alloc alloc,
	scope immutable K[] keys,
	in immutable(V) delegate(immutable K) @safe @nogc pure nothrow getValue,
) =>
	makeDict!(K, V, K)(alloc, keys, (scope ref immutable K key) =>
		immutable KeyValuePair!(K, V)(key, getValue(key)));

@trusted immutable(V) mustGetAt(K, V)(Dict!(K, V) a, in K key) =>
	mustGetAt_mut(a.inner, key);

void dictEach(K, V)(in Dict!(K, V) a, in void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb) {
	mutDictEach!(immutable K, immutable V)(a.inner, cb);
}
void dictEachIn(K, V)(in Dict!(K, V) a, in void delegate(in K, in V) @safe @nogc pure nothrow cb) {
	mutDictEachIn!(immutable K, immutable V)(a.inner, cb);
}
bool existsInDict(K, V)(in Dict!(K, V) a, in bool delegate(in K, in V) @safe @nogc pure nothrow cb) =>
	existsInMutDict!(immutable K, immutable V)(a.inner, cb);

Dict!(K, V) dictLiteral(K, V)(ref Alloc alloc, immutable K key, immutable V value) {
	MutDict!(immutable K, immutable V) res;
	addToMutDict(alloc, res, key, value);
	return moveToDict!(K, V)(alloc, res);
}

Dict!(K, VOut) mapValues(K, VOut, VIn)(
	ref Alloc alloc,
	Dict!(K, VIn) a,
	in immutable(VOut) delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	MutDict!(immutable K, immutable VOut) res;
	dictEach!(K, VIn)(a, (immutable K key, ref immutable VIn value) {
		addToMutDict(alloc, res, key, cb(key, value));
	});
	return moveToDict!(K, VOut)(alloc, res);
}
