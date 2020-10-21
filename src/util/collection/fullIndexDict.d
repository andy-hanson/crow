module util.collection.fullIndexDict;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, at, emptyArr, emptyArr_mut, setAt, size;
import util.collection.arrUtil : mapWithIndex;
import util.types : safeSizeTToU16, safeSizeTToU32;

struct FullIndexDict(K, V) {
	Arr!V values;
}

immutable(FullIndexDict!(K, V)) emptyFullIndexDict(K, V)() {
	return fullIndexDictOfArr!(K, V)(emptyArr!V);
}
FullIndexDict!(K, V) emptyFullIndexDict_mut(K, V)() {
	return fullIndexDictOfArr_mut!(K, V)(emptyArr_mut!V);
}

immutable(size_t) fullIndexDictSize(K, V)(ref const FullIndexDict!(K, V) a) {
	return size(a.values);
}

immutable(FullIndexDict!(K, V)) fullIndexDictOfArr(K, V)(immutable Arr!V values) {
	return immutable FullIndexDict!(K, V)(values);
}
FullIndexDict!(K, V) fullIndexDictOfArr_mut(K, V)(Arr!V values) {
	return FullIndexDict!(K, V)(values);
}


void fullIndexDictEachKey(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..fullIndexDictSize(a))
		cb(immutable K(i));
}

void fullIndexDictEachValue(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..fullIndexDictSize(a))
		cb(at(a.values, i));
}

void fullIndexDictEach(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..fullIndexDictSize(a))
		cb(immutable K(i), at(a.values, i));
}

ref immutable(V) fullIndexDictGet(K, V)(ref immutable FullIndexDict!(K, V) a, immutable K key) {
	return at(a.values, key.index);
}
ref const(V) fullIndexDictGet(K, V)(ref const FullIndexDict!(K, V) a, immutable K key) {
	return at(a.values, key.index);
}
ref V fullIndexDictGet(K, V)(ref FullIndexDict!(K, V) a, immutable K key) {
	return at(a.values, key.index);
}

void fullIndexDictSet(K, V)(ref FullIndexDict!(K, V) a, immutable K key, immutable V value) {
	setAt(a.values, key.index, value);
}

immutable(FullIndexDict!(K, VOut)) mapFullIndexDict(K, VOut, VIn, Alloc)(
	ref Alloc alloc,
	ref immutable FullIndexDict!(K, VIn) a,
	scope immutable(VOut) delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr!(K, VOut)(
		mapWithIndex(alloc, a.values, (immutable size_t index, ref immutable VIn v) =>
			cb(immutable K(K.sizeof == 4 ? safeSizeTToU32(index) : safeSizeTToU16(index)), v)));
}

