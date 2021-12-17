module util.col.fullIndexDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.conv : safeToUint, safeToUshort;
import util.col.arr : castImmutable, emptyArr, ptrAt, setAt;
import util.col.arrUtil : mapWithIndex, mapWithIndex_mut;
import util.ptr : Ptr;
import util.util : verify;

struct FullIndexDict(K, V) {
	@disable this();
	this(inout V[] vs) inout { values = vs; }

	//TODO:PRIVATE:
	V[] values;
}

immutable(FullIndexDict!(K, V)) fullIndexDictCastImmutable(K, V)(const FullIndexDict!(K, V) a) {
	return immutable FullIndexDict!(K, V)(castImmutable(a.values));
}
immutable(FullIndexDict!(K, V)) fullIndexDictCastImmutable2(K, V)(const FullIndexDict!(K, immutable V) a) {
	return immutable FullIndexDict!(K, V)(castImmutable(a.values));
}

immutable(FullIndexDict!(K, V)) emptyFullIndexDict(K, V)() {
	return fullIndexDictOfArr!(K, V)(emptyArr!V);
}

immutable(size_t) fullIndexDictSize(K, V)(ref const FullIndexDict!(K, V) a) {
	return a.values.length;
}

immutable(FullIndexDict!(K, V)) fullIndexDictOfArr(K, V)(immutable V[] values) {
	return immutable FullIndexDict!(K, V)(values);
}
FullIndexDict!(K, V) fullIndexDictOfArr_mut(K, V)(V[] values) {
	return FullIndexDict!(K, V)(values);
}

void fullIndexDictEachKey(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i));
}

void fullIndexDictEachValue(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable V value; a.values)
		cb(value);
}

void fullIndexDictEach(K, V)(
	ref immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t key, ref immutable V value; a.values)
		cb(immutable K(key), value);
}

void fullIndexDictZip(K, V0, V1)(
	ref immutable FullIndexDict!(K, V0) a,
	ref FullIndexDict!(K, V1) b,
	scope void delegate(immutable K, ref immutable V0, ref V1) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i), a.values[i], b.values[i]);
}

void fullIndexDictZip3(K, V0, V1, V2)(
	ref immutable FullIndexDict!(K, V0) a,
	ref immutable FullIndexDict!(K, V1) b,
	ref immutable FullIndexDict!(K, V2) c,
	scope void delegate(immutable K, ref immutable V0, ref immutable V1, ref immutable V2) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	verify(fullIndexDictSize(b) == fullIndexDictSize(c));
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i), a.values[i], b.values[i], c.values[i]);
}

ref inout(V) fullIndexDictGet(K, V)(ref inout FullIndexDict!(K, V) a, immutable K key) {
	verify(key.index < fullIndexDictSize(a));
	return a.values[key.index];
}
immutable(Ptr!V) fullIndexDictGetPtr(K, V)(ref immutable FullIndexDict!(K, V) a, immutable K key) {
	return ptrAt(a.values, key.index);
}
Ptr!V fullIndexDictGetPtr_mut(K, V)(ref FullIndexDict!(K, V) a, immutable K key) {
	return ptrAt(a.values, key.index);
}
void fullIndexDictSet(K, V)(ref FullIndexDict!(K, V) a, immutable K key, immutable V value) {
	setAt(a.values, key.index, value);
}

immutable(FullIndexDict!(K, VOut)) mapFullIndexDict(K, VOut, VIn)(
	ref Alloc alloc,
	immutable FullIndexDict!(K, VIn) a,
	scope immutable(VOut) delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr!(K, VOut)(
		mapWithIndex(alloc, a.values, (immutable size_t index, ref immutable VIn v) =>
			cb(immutable K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
}

FullIndexDict!(K, VOut) mapFullIndexDict_mut(K, VOut, VIn)(
	ref Alloc alloc,
	immutable FullIndexDict!(K, VIn) a,
	scope VOut delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr_mut!(K, VOut)(
		mapWithIndex_mut!(VOut, VIn)(alloc, a.values, (immutable size_t index, ref immutable VIn v) =>
			cb(immutable K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
}
