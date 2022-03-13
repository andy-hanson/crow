module util.col.mutIndexMultiDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : fillArr_mut;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictOfArr_mut;
import util.col.mutArr : MutArr, push, tempAsArr;

struct MutIndexMultiDict(K, V) {
	private:
	FullIndexDict!(K, MutArr!V) inner;
}

MutIndexMultiDict!(K, V) newMutIndexMultiDict(K, V)(ref Alloc alloc, immutable size_t size) {
	return MutIndexMultiDict!(K, V)(
		fullIndexDictOfArr_mut!(K, MutArr!V)(fillArr_mut!(MutArr!V)(alloc, size, (immutable size_t) =>
			MutArr!V())));
}

void mutIndexMultiDictAdd(K, V)(
	ref Alloc alloc,
	ref MutIndexMultiDict!(K, V) a,
	immutable K key,
	immutable V value,
) {
	push(alloc, a.inner[key], value);
}

// WARN: result is temporary only!
const(V[]) mutIndexMultiDictMustGetAt(K, V)(const ref MutIndexMultiDict!(K, V) a, immutable K key) {
	return tempAsArr(a.inner[key]);
}





