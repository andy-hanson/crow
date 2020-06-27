module util.collection.mutSet;

@safe @nogc pure nothrow:

import util.collection.mutArr : MutArr, range;
import util.comparison : Comparison;

struct MutSet(T, alias cmp) {
	MutArr!T arr;
}

immutable(Bool) mutSetHas(T, alias cmp)(ref const MutSet!(T, cmp) s, immutable T value) {
	foreach (ref immutable T t; s.arr.range)
		if (cmp(t, value) == Comparison.equal)
			return True;
	return False;
}

immutable(Bool) tryAddToMutSet(T, alias cmp, Alloc)(ref MutSet!(T, cmp) s, ref Alloc alloc, immutable T value) {
	immutable Bool h = s.mutSetHas(value);
	if (!h)
		push(arena, s.arr, value);
	return !h;
}

void addToMutSet(T, alias cmp, Alloc)(ref MutSet!(T, cmp) s, ref Alloc alloc, immutable T value) {
	immutable Bool added = tryAddToMutSet!(T, cmp)(s, alloc, value);
	assert(added);
}

void addToMutSetOkIfPresent(T, alias cmp, Alloc)(ref MutSet!(T, cmp) s, ref Alloc alloc, immutable T value) {
	tryAddToMutSet!(T, cmp)(s, alloc, value);
}
