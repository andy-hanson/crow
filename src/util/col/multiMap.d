module util.col.multiMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.map : Map, mapToArray, values;
import util.col.mutMap : getOrAdd, mapToMap, MutMap, MutMapValues;
import util.opt : force, has, Opt;

immutable struct MultiMap(K, V) {
	@safe @nogc pure nothrow:

	private Map!(K, V[]) inner;

	immutable(V[]) opIndex(in K key) immutable {
		Opt!(V[]) res = inner[key];
		return has(res) ? force(res) : [];
	}

	int opApply(in int delegate(immutable K, immutable V[]) @safe @nogc pure nothrow cb) scope =>
		inner.opApply((immutable K key, ref immutable V[] value) => cb(key, value));
}

immutable(MutMapValues!(K, V[])) values(K, V)(ref MultiMap!(K, V) a) =>
	.values(a.inner);

alias MultiMapCb(K, V) = void delegate(K, V) @safe @nogc pure nothrow;

MultiMap!(K, V) makeMultiMap(K, V)(
	ref Alloc alloc,
	in void delegate(in MultiMapCb!(K, V) add) @safe @nogc pure nothrow cb,
) {
	MutMap!(K, ArrBuilder!(immutable V)) builder;
	cb((K key, V value) {
		add(alloc, getOrAdd(alloc, builder, key, () => ArrBuilder!(immutable V)()), value);
	});
	return toMultiMap!(K, V)(alloc, builder);
}

private MultiMap!(K, V) toMultiMap(K, V)(ref Alloc alloc, ref MutMap!(K, ArrBuilder!V) builder) =>
	MultiMap!(K, V)(
		mapToMap!(K, V[], ArrBuilder!(immutable V))(alloc, builder, (ref ArrBuilder!(immutable V) arr) =>
			finishArr!V(alloc, arr)));

Out[] mapToArray(Out, K, V)(
	ref Alloc alloc,
	in MultiMap!(K, V) a,
	in Out delegate(immutable K, immutable V[]) @safe @nogc pure nothrow cb,
) =>
	.mapToArray!(Out, K, V[])(alloc, a.inner, (immutable K k, ref immutable V[] v) =>
		cb(k, v));
