module util.col.fullIndexDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.conv : safeToUint, safeToUshort;
import util.col.arr : castImmutable, emptyArr;
import util.col.arrUtil : fillArr_mut, mapWithIndex, mapWithIndex_mut;
import util.memory : overwriteMemory;
import util.ptr : Ptr;
import util.util : verify;

struct FullIndexDict(K, V) {
	@disable this();
	this(inout V[] vs) inout { values = vs; }

	ref inout(V) opIndex(immutable K key) inout {
		return values[key.index];
	}

	static if ( __traits(isCopyable, V)) {
		void opIndexAssign(V value, immutable K key) {
			overwriteMemory!V(&values[key.index], value);
		}
	}

	//TODO: private:
	V[] values;
}

immutable(V[]) asArray(K, V)(immutable FullIndexDict!(K, V) a) {
	return a.values;
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

FullIndexDict!(K, V) makeFullIndexDict_mut(K, V)(
	ref Alloc alloc,
	immutable size_t size,
	scope V delegate(immutable K) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr_mut!(K, V)(fillArr_mut(alloc, size, (immutable size_t i) =>
		cb(immutable K(i))));
}

void fullIndexDictEachKey(K, V)(
	immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i));
}

void fullIndexDictEachValue(K, V)(
	immutable FullIndexDict!(K, V) a,
	scope void delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable V value; a.values)
		cb(value);
}

void fullIndexDictEach(K, V)(
	immutable FullIndexDict!(K, V) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t key, ref immutable V value; a.values)
		cb(immutable K(key), value);
}

void fullIndexDictZip(K, V0, V1)(
	immutable FullIndexDict!(K, V0) a,
	ref FullIndexDict!(K, V1) b,
	scope void delegate(immutable K, ref immutable V0, ref V1) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i), a.values[i], b.values[i]);
}

void fullIndexDictZipPtrs(K, V0, V1)(
	immutable FullIndexDict!(K, V0) a,
	immutable FullIndexDict!(K, V1) b,
	scope void delegate(immutable K, immutable Ptr!V0, immutable Ptr!V1) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i), a.ptrAt(immutable K(i)), b.ptrAt(immutable K(i)));
}

void fullIndexDictZip3(K, V0, V1, V2)(
	immutable FullIndexDict!(K, V0) a,
	immutable FullIndexDict!(K, V1) b,
	immutable FullIndexDict!(K, V2) c,
	scope void delegate(immutable K, ref immutable V0, ref immutable V1, ref immutable V2) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	verify(fullIndexDictSize(b) == fullIndexDictSize(c));
	foreach (immutable size_t i; 0 .. fullIndexDictSize(a))
		cb(immutable K(i), a.values[i], b.values[i], c.values[i]);
}

immutable(Ptr!V) ptrAt(K, V)(immutable FullIndexDict!(K, V) a, immutable K key) {
	return immutable Ptr!V(&a.values[key.index]);
}
Ptr!V ptrAt_mut(K, V)(ref FullIndexDict!(K, V) a, immutable K key) {
	return Ptr!V(&a.values[key.index]);
}

immutable(FullIndexDict!(K, VOut)) mapFullIndexDict(K, VOut, VIn)(
	ref Alloc alloc,
	scope immutable FullIndexDict!(K, VIn) a,
	scope immutable(VOut) delegate(immutable K, scope ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr!(K, VOut)(
		mapWithIndex(alloc, a.values, (immutable size_t index, scope ref immutable VIn v) =>
			cb(immutable K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
}

FullIndexDict!(K, VOut) mapFullIndexDict_mut(K, VOut, VIn)(
	ref Alloc alloc,
	immutable FullIndexDict!(K, VIn) a,
	scope VOut delegate(immutable K, scope ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	return fullIndexDictOfArr_mut!(K, VOut)(
		mapWithIndex_mut!(VOut, VIn)(alloc, a.values, (immutable size_t index, scope ref immutable VIn v) =>
			cb(immutable K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
}
