module util.collection.mutIndexDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.arr : at, setAt;
import util.collection.arrUtil : fillArr_mut;
import util.collection.mutDict : ValueAndDidAdd;
import util.opt : force, has, noneMut, Opt, someMut;

struct MutIndexDict(K, V) {
	private:
	Opt!V[] values_;
}

MutIndexDict!(K, V) newMutIndexDict(K, V)(ref Alloc alloc, immutable size_t size) {
	return MutIndexDict!(K, V)(fillArr_mut!(Opt!V)(alloc, size, (immutable size_t) =>
		noneMut!V));
}

ref const(Opt!V) getAt(K, V)(ref const MutIndexDict!(K, V) a, immutable K key) {
	return at(a.values_, key.index);
}

ref const(V) mustGetAt(K, V)(ref const MutIndexDict!(K, V) a, immutable K key) {
	return force(getAt(a, key));
}

immutable(ValueAndDidAdd!V) getOrAddAndDidAdd(K, V)(
	ref MutIndexDict!(K, V) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	immutable size_t index = key.index;
	if (has(at(a.values_, index)))
		return immutable ValueAndDidAdd!V(force(at(a.values_, index)), false);
	else {
		immutable V value = getValue();
		setAt(a.values_, index, someMut!V(value));
		return immutable ValueAndDidAdd!V(value, true);
	}
}
