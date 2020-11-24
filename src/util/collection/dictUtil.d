module util.collection.dictUtil;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, ptrAt, ptrsRange, range, size;
import util.collection.dict : Dict, KeyValuePair;
import util.collection.multiDict : MultiDict;
import util.comparison : Comparison;
import util.memory : initMemory;
import util.ptr : Ptr;
import util.util : verify;

@trusted immutable(Dict!(K, V, compare)) buildDict(K, V, alias compare, T, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!T inputs,
	scope immutable(KeyValuePair!(K, V)) delegate(immutable Ptr!T) @safe @nogc pure nothrow getPair,
	scope void delegate(ref immutable K, ref immutable V, ref immutable V) @safe @nogc pure nothrow onConflict,
) {
	alias Pair = KeyValuePair!(K, V);
	Pair* res = cast(Pair*) alloc.allocateBytes(Pair.sizeof * size(inputs));
	size_t resI = 0;
	foreach (immutable Ptr!T input; ptrsRange(inputs)) {
		immutable Pair pair = getPair(input);
		Bool wasConflict = False;
		foreach (ref immutable Pair resPair; range(immutable Arr!Pair(cast(immutable) res, resI))) {
			if (compare(pair.key, resPair.key) == Comparison.equal) {
				onConflict(pair.key, resPair.value, pair.value);
				wasConflict = True;
				break;
			}
		}
		if (!wasConflict) {
			initMemory(res + resI, pair);
			resI ++;
		}
	}
	verify(resI <= size(inputs));
	alloc.freeBytesPartial(cast(ubyte*) (res + resI), Pair.sizeof * (size(inputs) - resI));
	return immutable Dict!(K, V, compare)(immutable Arr!Pair(cast(immutable) res, resI));
}

@trusted immutable(MultiDict!(K, V, compare)) buildMultiDict(K, V, alias compare, T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T inputs,
	scope immutable(KeyValuePair!(K, V)) delegate(immutable Ptr!T) @safe @nogc pure nothrow getPair,
) {
	immutable(K)* keys = cast(immutable K*) alloc.allocateBytes(K.sizeof * size(inputs));
	immutable(V)* values = cast(immutable V*) alloc.allocateBytes(V.sizeof * size(inputs));
	foreach (immutable size_t i; 0..size(inputs)) {
		immutable KeyValuePair!(K, V) pair = getPair(ptrAt(inputs, i));
		// Insert at the first place it's > the previous value.
		size_t insertAt = 0;
		for (; insertAt < i; insertAt++) {
			if (compare(pair.key, keys[insertAt]) == Comparison.greater)
				break;
		}
		for (size_t j = i; j > insertAt; j--) {
			initMemory(keys + j, keys[j - 1]);
			initMemory(values + j, values[j - 1]);
		}
		initMemory(keys + insertAt, pair.key);
		initMemory(values + insertAt, pair.value);
	}
	return immutable MultiDict!(K, V, compare)(size(inputs), cast(immutable) keys, cast(immutable) values);
}

