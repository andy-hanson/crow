module util.col.mutIndexDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : fillArr_mut;
import util.col.mutDict : ValueAndDidAdd;
import util.memory : overwriteMemory;
import util.opt : force, has, MutOpt, noneMut, someMut;

struct MutIndexDict(K, V) {
	private MutOpt!V[] values_;

	ref const(MutOpt!V) opIndex(immutable K key) const =>
		values_[key.index];
}

MutIndexDict!(K, V) newMutIndexDict(K, V)(ref Alloc alloc, size_t size) =>
	MutIndexDict!(K, V)(fillArr_mut!(MutOpt!V)(alloc, size, (size_t _) =>
		noneMut!V));

ref const(V) mustGetAt(K, V)(ref const MutIndexDict!(K, V) a, immutable K key) =>
	force(getAt(a, key));

immutable(ValueAndDidAdd!V) getOrAddAndDidAdd(K, V)(
	ref MutIndexDict!(K, V) a,
	immutable K key,
	in immutable(V) delegate() @safe @nogc pure nothrow getValue,
) {
	size_t index = key.index;
	if (has(a.values_[index]))
		return immutable ValueAndDidAdd!V(force(a.values_[index]), false);
	else {
		immutable V value = getValue();
		overwriteMemory!(MutOpt!V)(&a.values_[index], someMut!V(value));
		return immutable ValueAndDidAdd!V(value, true);
	}
}
