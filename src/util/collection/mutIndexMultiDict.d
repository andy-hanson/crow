module util.collection.mutIndexMultiDict;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, emptyArr;
import util.collection.mutArr : MutArr, mutArrOfOne, push, tempAsArr;
import util.collection.mutIndexDict : mustGetAt, MutIndexDict, newMutIndexDict, updateOrSet;
import util.opt : force, has, Opt;

struct MutIndexMultiDict(K, V) {
	private:
	MutIndexDict!(K, MutArr!V) inner;
}

MutIndexMultiDict!(K, V) newMutIndexMultiDict(K, V, Alloc)(ref Alloc alloc, immutable size_t size) {
	return MutIndexMultiDict!(K, V)(newMutIndexDict!(K, MutArr!V, Alloc)(alloc, size));
}

void mutIndexMultiDictAdd(K, V, Alloc)(
	ref Alloc alloc,
	ref MutIndexMultiDict!(K, V) a,
	immutable K key,
	immutable V value,
) {
	updateOrSet!(K, MutArr!V)(
		a.inner,
		key,
		(ref MutArr!V m) => push(alloc, m, value),
		() => mutArrOfOne!V(alloc, value));
}

// WARN: result is temporary only!
const(Arr!V) mutIndexMultiDictMustGetAt(K, V)(const ref MutIndexMultiDict!(K, V) a, immutable K key) {
	return tempAsArr(mustGetAt(a.inner, key));
}





