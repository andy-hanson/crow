module util.col.multiMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.map : mapEach, Map, KeyValuePair;
import util.col.mutArr : moveToArr, MutArr, push;
import util.col.mutMap : getOrAdd, mapToMap, MutMap;
import util.opt : force, has, Opt;

immutable struct MultiMap(K, V) {
	private Map!(K, V[]) inner;

	immutable(V[]) opIndex(in K key) immutable {
		Opt!(V[]) res = inner[key];
		return has(res) ? force(res) : [];
	}
}

@trusted void multiMapEach(K, V)(
	ref MultiMap!(K, V) a,
	in void delegate(immutable K, in immutable V[]) @safe @nogc pure nothrow cb,
) {
	mapEach!(K, V[])(a.inner, (immutable K key, ref immutable V[] value) {
		cb(key, value);
	});
}

alias MultiMapCb(K, V) = void delegate(K, V) @safe @nogc pure nothrow;

MultiMap!(K, V) makeMultiMap(K, V)(
	ref Alloc alloc,
	in void delegate(in MultiMapCb!(K, V) add) @safe @nogc pure nothrow cb,
) {
	MutMap!(immutable K, MutArr!(immutable V)) builder;
	cb((K key, V value) {
		push(alloc, getOrAdd(alloc, builder, key, () => MutArr!(immutable V)()), value);
	});
	return toMultiMap!(K, V)(alloc, builder);
}

MultiMap!(K, V) buildMultiMap(K, V, T)(
	ref Alloc alloc,
	T[] inputs,
	in KeyValuePair!(K, V) delegate(size_t, T*) @safe @nogc pure nothrow getPair,
) =>
	makeMultiMap!(K, V)(alloc, (in MultiMapCb!(K, V) cb) {
		foreach (size_t i; 0 .. inputs.length) {
			KeyValuePair!(K, V) pair = getPair(i, &inputs[i]);
			cb(pair.key, pair.value);
		}
	});

MultiMap!(K, V) groupBy(K, V)(ref Alloc alloc, in V[] inputs, in K delegate(in V) @safe @nogc pure nothrow getKey) {
	MutMap!(immutable K, MutArr!(immutable V)) builder;
	foreach (ref V input; inputs) {
		K key = getKey(input);
		push(alloc, getOrAdd(alloc, builder, key, () => MutArr!(immutable V)()), input);
	}
	return toMultiMap(alloc, builder);
}

private MultiMap!(K, V) toMultiMap(K, V)(ref Alloc alloc, ref MutMap!(K, MutArr!V) builder) =>
	MultiMap!(K, V)(
		mapToMap!(K, V[], MutArr!(immutable V))(alloc, builder, (ref MutArr!(immutable V) arr) =>
			moveToArr!V(alloc, arr)));

Out[] mapMultiMap(Out, K, V)(
	ref Alloc alloc,
	in MultiMap!(K, V) a,
	in Out delegate(K, in immutable V[]) @safe @nogc pure nothrow cb,
) {
	ArrBuilder!Out res;
	multiMapEach!(K, V)(a, (K key, in immutable V[] values) {
		add(alloc, res, cb(key, values));
	});
	return finishArr(alloc, res);
}
