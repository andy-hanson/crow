module util.collection.dictUtil;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes;
import util.collection.arr : ptrAt, size;
import util.collection.dict : KeyValuePair;
import util.collection.multiDict : MultiDict;
import util.comparison : Comparison;
import util.memory : initMemory;
import util.ptr : Ptr;

@trusted immutable(MultiDict!(K, V, compare)) buildMultiDict(K, V, alias compare, T)(
	ref Alloc alloc,
	immutable T[] inputs,
	scope immutable(KeyValuePair!(K, V)) delegate(immutable size_t, immutable Ptr!T) @safe @nogc pure nothrow getPair,
) {
	immutable(K)* keys = cast(immutable K*) allocateBytes(alloc, K.sizeof * size(inputs));
	immutable(V)* values = cast(immutable V*) allocateBytes(alloc, V.sizeof * size(inputs));
	foreach (immutable size_t i; 0 .. size(inputs)) {
		immutable KeyValuePair!(K, V) pair = getPair(i, ptrAt(inputs, i));
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
