module util.col.fullIndexDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.conv : safeToUint, safeToUshort;
import util.col.arr : castImmutable;
import util.col.arrUtil : fillArr_mut, mapWithIndex;
import util.memory : overwriteMemory;
import util.util : verify;

struct FullIndexDict(K, V) {
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

immutable(V[]) asArray(K, V)(immutable FullIndexDict!(K, V) a) =>
	a.values;

immutable(FullIndexDict!(K, V)) fullIndexDictCastImmutable(K, V)(const FullIndexDict!(K, V) a) =>
	immutable FullIndexDict!(K, V)(castImmutable(a.values));
immutable(FullIndexDict!(K, V)) fullIndexDictCastImmutable2(K, V)(const FullIndexDict!(K, immutable V) a) =>
	immutable FullIndexDict!(K, V)(castImmutable(a.values));

immutable(FullIndexDict!(K, V)) emptyFullIndexDict(K, V)() =>
	fullIndexDictOfArr!(K, V)([]);

immutable(size_t) fullIndexDictSize(K, V)(const FullIndexDict!(K, V) a) =>
	a.values.length;

immutable(FullIndexDict!(K, V)) fullIndexDictOfArr(K, V)(return scope immutable V[] values) =>
	immutable FullIndexDict!(K, V)(values);
private FullIndexDict!(K, V) fullIndexDictOfArr_mut(K, V)(V[] values) =>
	FullIndexDict!(K, V)(values);

FullIndexDict!(K, V) makeFullIndexDict_mut(K, V)(
	ref Alloc alloc,
	immutable size_t size,
	in V delegate(K) @safe @nogc pure nothrow cb,
) =>
	fullIndexDictOfArr_mut!(K, V)(fillArr_mut(alloc, size, (size_t i) =>
		cb(K(i))));

void fullIndexDictEachKey(K, V)(
	in immutable FullIndexDict!(K, V) a,
	in void delegate(K) @safe @nogc pure nothrow cb,
) {
	foreach (size_t i; 0 .. fullIndexDictSize(a))
		cb(K(i));
}

void fullIndexDictEachValue(K, V)(
	in immutable FullIndexDict!(K, V) a,
	in void delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable V value; a.values)
		cb(value);
}

void fullIndexDictEach(K, V)(
	in immutable FullIndexDict!(K, V) a,
	in void delegate(K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (size_t key, ref immutable V value; a.values)
		cb(K(key), value);
}

pure void fullIndexDictEach_const(K, V)(
	scope const FullIndexDict!(K, V) a,
	in void delegate(K, ref const V) @safe @nogc pure nothrow cb,
) {
	foreach (size_t key, ref const V value; a.values)
		cb(K(key), value);
}

void fullIndexDictZip(K, V0, V1)(
	immutable FullIndexDict!(K, V0) a,
	ref FullIndexDict!(K, V1) b,
	in void delegate(K, ref immutable V0, ref V1) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	foreach (size_t i; 0 .. fullIndexDictSize(a))
		cb(K(i), a.values[i], b.values[i]);
}

void fullIndexDictZipPtrFirst(K, V0, V1)(
	FullIndexDict!(K, V0) a,
	FullIndexDict!(K, V1) b,
	in void delegate(K, V0*, in V1) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	foreach (size_t i; 0 .. fullIndexDictSize(a))
		cb(K(i), &a.values[i], b.values[i]);
}

void fullIndexDictZip3(K, V0, V1, V2)(
	immutable FullIndexDict!(K, V0) a,
	immutable FullIndexDict!(K, V1) b,
	immutable FullIndexDict!(K, V2) c,
	in void delegate(K, ref immutable V0, ref immutable V1, ref immutable V2) @safe @nogc pure nothrow cb,
) {
	verify(fullIndexDictSize(a) == fullIndexDictSize(b));
	verify(fullIndexDictSize(b) == fullIndexDictSize(c));
	foreach (size_t i; 0 .. fullIndexDictSize(a))
		cb(K(i), a.values[i], b.values[i], c.values[i]);
}

immutable(FullIndexDict!(K, VOut)) mapFullIndexDict(K, VOut, VIn)(
	ref Alloc alloc,
	in immutable FullIndexDict!(K, VIn) a,
	in immutable(VOut) delegate(K, scope ref immutable VIn) @safe @nogc pure nothrow cb,
) =>
	fullIndexDictOfArr!(K, VOut)(
		mapWithIndex!(immutable VOut, immutable VIn)(alloc, a.values, (size_t index, scope ref immutable VIn v) =>
			cb(K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));

FullIndexDict!(K, VOut) mapFullIndexDict_mut(K, VOut, VIn)(
	ref Alloc alloc,
	immutable FullIndexDict!(K, VIn) a,
	in VOut delegate(K, scope ref immutable VIn) @safe @nogc pure nothrow cb,
) =>
	fullIndexDictOfArr_mut!(K, VOut)(
		mapWithIndex!(VOut, VIn)(alloc, a.values, (size_t index, scope ref immutable VIn v) =>
			cb(K(K.sizeof == 4 ? safeToUint(index) : safeToUshort(index)), v)));
