module util.col.fullIndexMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.conv : safeToUint, safeToUshort;
import util.col.arr : castImmutable;
import util.col.arrUtil : makeArray, mapWithIndex;
import util.memory : overwriteMemory;

struct FullIndexMap(K, V) {
	@disable this();
	this(inout V[] vs) inout { values = vs; }

	ref inout(V) opIndex(K key) inout =>
		values[key.index];

	static if ( __traits(isCopyable, V)) {
		void opIndexAssign(V value, K key) {
			overwriteMemory!V(&values[key.index], value);
		}
	}

	//TODO: private:
	V[] values;
}

immutable(FullIndexMap!(K, V)) fullIndexMapCastImmutable(K, V)(const FullIndexMap!(K, V) a) =>
	immutable FullIndexMap!(K, V)(castImmutable(a.values));
immutable(FullIndexMap!(K, V)) fullIndexMapCastImmutable2(K, V)(const FullIndexMap!(K, immutable V) a) =>
	immutable FullIndexMap!(K, V)(castImmutable(a.values));

immutable(FullIndexMap!(K, V)) emptyFullIndexMap(K, V)() =>
	fullIndexMapOfArr!(K, V)([]);

immutable(size_t) fullIndexMapSize(K, V)(const FullIndexMap!(K, V) a) =>
	a.values.length;

immutable(FullIndexMap!(K, V)) fullIndexMapOfArr(K, V)(return scope immutable V[] values) =>
	immutable FullIndexMap!(K, V)(values);
private FullIndexMap!(K, V) fullIndexMapOfArr_mut(K, V)(V[] values) =>
	FullIndexMap!(K, V)(values);

FullIndexMap!(K, V) makeFullIndexMap_mut(K, V)(
	ref Alloc alloc,
	immutable size_t size,
	in V delegate(K) @safe @nogc pure nothrow cb,
) =>
	fullIndexMapOfArr_mut!(K, V)(makeArray(alloc, size, (size_t i) =>
		cb(K(i))));

void fullIndexMapEachKey(K, V)(
	in immutable FullIndexMap!(K, V) a,
	in void delegate(K) @safe @nogc pure nothrow cb,
) {
	foreach (size_t i; 0 .. fullIndexMapSize(a))
		cb(K(i));
}

void fullIndexMapEachValue(K, V)(
	in immutable FullIndexMap!(K, V) a,
	in void delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable V value; a.values)
		cb(value);
}

void fullIndexMapEach(K, V)(
	in immutable FullIndexMap!(K, V) a,
	in void delegate(K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (size_t key, ref immutable V value; a.values)
		cb(K(key), value);
}

pure void fullIndexMapEach_const(K, V)(
	scope const FullIndexMap!(K, V) a,
	in void delegate(K, ref const V) @safe @nogc pure nothrow cb,
) {
	foreach (size_t key, ref const V value; a.values)
		cb(K(key), value);
}

void fullIndexMapZip(K, V0, V1)(
	immutable FullIndexMap!(K, V0) a,
	ref FullIndexMap!(K, V1) b,
	in void delegate(K, ref immutable V0, ref V1) @safe @nogc pure nothrow cb,
) {
	assert(fullIndexMapSize(a) == fullIndexMapSize(b));
	foreach (size_t i; 0 .. fullIndexMapSize(a))
		cb(K(i), a.values[i], b.values[i]);
}

void fullIndexMapZip3(K, V0, V1, V2)(
	immutable FullIndexMap!(K, V0) a,
	immutable FullIndexMap!(K, V1) b,
	immutable FullIndexMap!(K, V2) c,
	in void delegate(K, ref immutable V0, ref immutable V1, ref immutable V2) @safe @nogc pure nothrow cb,
) {
	assert(fullIndexMapSize(a) == fullIndexMapSize(b));
	assert(fullIndexMapSize(b) == fullIndexMapSize(c));
	foreach (size_t i; 0 .. fullIndexMapSize(a))
		cb(K(i), a.values[i], b.values[i], c.values[i]);
}

immutable(FullIndexMap!(K, VOut)) mapFullIndexMap(K, VOut, VIn)(
	ref Alloc alloc,
	in immutable FullIndexMap!(K, VIn) a,
	in immutable(VOut) delegate(K, in immutable VIn) @safe @nogc pure nothrow cb,
) =>
	fullIndexMapOfArr!(K, VOut)(
		mapWithIndex!(immutable VOut, immutable VIn)(alloc, a.values, (size_t index, scope ref immutable VIn v) =>
			cb(K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));

FullIndexMap!(K, VOut) mapFullIndexMap_mut(K, VOut, VIn)(
	ref Alloc alloc,
	immutable FullIndexMap!(K, VIn) a,
	in VOut delegate(K, in immutable VIn) @safe @nogc pure nothrow cb,
) =>
	fullIndexMapOfArr_mut!(K, VOut)(
		mapWithIndex!(VOut, VIn)(alloc, a.values, (size_t index, scope ref immutable VIn v) =>
			cb(K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
