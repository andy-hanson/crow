module util.collection.mutIndexMultiDict;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.collection.arrUtil : fillArr_mut;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictGet, fullIndexDictOfArr_mut;
import util.collection.mutArr : MutArr, push, tempAsArr;

struct MutIndexMultiDict(K, V) {
	private:
	FullIndexDict!(K, MutArr!V) inner;
}

MutIndexMultiDict!(K, V) newMutIndexMultiDict(K, V, Alloc)(ref Alloc alloc, immutable size_t size) {
	return MutIndexMultiDict!(K, V)(
		fullIndexDictOfArr_mut!(K, MutArr!V)(fillArr_mut!(MutArr!V)(alloc, size, (immutable size_t) =>
			MutArr!V())));
}

void mutIndexMultiDictAdd(K, V, Alloc)(
	ref Alloc alloc,
	ref MutIndexMultiDict!(K, V) a,
	immutable K key,
	immutable V value,
) {
	push(alloc, fullIndexDictGet(a.inner, key), value);
}

// WARN: result is temporary only!
const(Arr!V) mutIndexMultiDictMustGetAt(K, V)(const ref MutIndexMultiDict!(K, V) a, immutable K key) {
	return tempAsArr(fullIndexDictGet(a.inner, key));
}





