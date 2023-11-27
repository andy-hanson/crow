module util.col.mapBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutMap : getOrAddAndDidAdd, moveToMap, MutMap, ValueAndDidAdd;
import util.col.map : Map;
import util.opt : has, none, Opt, some;

struct MapBuilder(K, V) {
	@disable this(ref const MapBuilder);

	private:
	MutMap!(immutable K, immutable V) builder;
}

void mustAddToMap(K, V)(ref Alloc alloc, ref MapBuilder!(K, V) a, immutable K key, immutable V value) {
	Opt!V res = tryAddToMap(alloc, a, key, value);
	assert(!has(res));
}

// If there is already a value there, does nothing and returns it
Opt!V tryAddToMap(K, V)(ref Alloc alloc, ref MapBuilder!(K, V) a, immutable K key, immutable V value) {
	ValueAndDidAdd!(immutable V) v = getOrAddAndDidAdd(alloc, a.builder, key, () => value);
	return v.didAdd ? none!V : some(v.value);
}

Map!(K, V) finishMap(K, V)(
	ref Alloc alloc,
	ref MapBuilder!(K, V) a,
) =>
	moveToMap!(K, V)(alloc, a.builder);
