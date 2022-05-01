module util.col.dict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : zip;
import util.col.mutDict :
	addToMutDict, getAt_mut, hasKey_mut, moveToDict, mustGetAt_mut, MutDict, mutDictEach;
public import util.col.mutDict : KeyValuePair;
import util.opt : Opt;

struct Dict(K, V) {
	private immutable MutDict!(K, V) inner;

	@trusted immutable(Opt!V) opIndex(immutable K key) immutable {
		return cast(immutable) getAt_mut(inner, key);
	}
}

immutable(bool) hasKey(K, V)(ref immutable Dict!(K, V) a, const K key) {
	return hasKey_mut(a.inner, key);
}

immutable(Dict!(K, V)) zipToDict(K, V, X, Y)(
	ref Alloc alloc,
	scope immutable X[] xs,
	scope immutable Y[] ys,
	scope immutable(KeyValuePair!(K, V)) delegate(ref immutable X, ref immutable Y) @safe @nogc pure nothrow cb,
) {
	MutDict!(immutable K, immutable V) res;
	zip!(X, Y)(xs, ys, (ref immutable X x, ref immutable Y y) {
		immutable KeyValuePair!(K, V) pair = cb(x, y);
		addToMutDict!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	});
	return moveToDict!(K, V)(alloc, res);
}

immutable(Dict!(K, V)) makeDict(K, V, T)(
	ref Alloc alloc,
	scope immutable T[] inputs,
	scope immutable(KeyValuePair!(K, V)) delegate(scope ref immutable T) @safe @nogc pure nothrow getPair,
) {
	MutDict!(immutable K, immutable V) res;
	foreach (ref immutable T input; inputs) {
		immutable KeyValuePair!(K, V) pair = getPair(input);
		addToMutDict!(immutable K, immutable V)(alloc, res, pair.key, pair.value);
	}
	return moveToDict!(K, V)(alloc, res);
}

immutable(Dict!(K, V)) makeDictFromKeys(K, V)(
	ref Alloc alloc,
	scope immutable K[] keys,
	scope immutable(V) delegate(immutable K) @safe @nogc pure nothrow getValue,
) {
	return makeDict!(K, V, K)(alloc, keys, (scope ref immutable K key) =>
		immutable KeyValuePair!(K, V)(key, getValue(key)));
}

@trusted immutable(V) mustGetAt(K, V)(immutable Dict!(K, V) a, const K key) {
	return cast(immutable) mustGetAt_mut(a.inner, key);
}

void dictEach(K, V)(
	ref immutable Dict!(K, V) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	mutDictEach!(K, V)(a.inner, cb);
}

immutable(Dict!(K, V)) dictLiteral(K, V)(
	ref Alloc alloc,
	immutable K key,
	immutable V value,
) {
	MutDict!(immutable K, immutable V) res;
	addToMutDict(alloc, res, key, value);
	return moveToDict!(K, V)(alloc, res);
}

immutable(Dict!(K, VOut)) mapValues(K, VIn, VOut)(
	ref Alloc alloc,
	immutable Dict!(K, VIn) a,
	scope immutable(VOut) delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	MutDict!(immutable K, immutable VOut) res;
	dictEach!(K, VIn)(a, (immutable K key, ref immutable VIn value) {
		addToMutDict(alloc, res, key, cb(key, value));
	});
	return moveToDict!(K, VOut)(alloc, res);
}
