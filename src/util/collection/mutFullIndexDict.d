module util.collection.mutFullIndexDict;

@safe @nogc pure nothrow:

import util.collection.mutArr : MutArr, mutArrAt, mutArrSize, push, setAt;

//TODO: maybe should name this 'MutDefaultIndexDict'
struct MutFullIndexDict(K, V, alias defaultValue) {
	private:
	MutArr!V values;
}

const(V) mutFullIndexDictGet(K, V, alias defaultValue)(
	ref const MutFullIndexDict!(K, V, defaultValue) a,
	immutable K key,
) {
	return key.index < mutArrSize(a.values) ? mutArrAt(a.values, key.index) : defaultValue;
}

void mutFullIndexDictSet(Alloc, K, V, alias defaultValue)(
	ref Alloc alloc,
	ref MutFullIndexDict!(K, V, defaultValue) a,
	immutable K key,
	immutable V value,
) {
	immutable size_t index = key.index;
	while (mutArrSize(a.values) <= index)
		push(alloc, a.values, defaultValue);
	setAt(a.values, index, value);
}

