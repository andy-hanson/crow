module util.collection.mutSet;

@safe @nogc pure nothrow:

import util.bools : Bool, False, not, True;
import util.collection.mutArr : MutArr, mutArrRange, push;
import util.comparison : Comparison;

struct MutSet(T, alias cmp) {
	MutArr!T arr;
}

immutable(Bool) mutSetHas(T, alias cmp)(ref const MutSet!(T, cmp) s, immutable T value) {
	foreach (ref const T t; mutArrRange(s.arr))
		if (cmp(t, value) == Comparison.equal)
			return True;
	return False;
}

private immutable(Bool) tryAddToMutSet(T, alias cmp, Alloc)(ref Alloc alloc, ref MutSet!(T, cmp) s, immutable T value) {
	immutable Bool h = mutSetHas(s, value);
	if (not(h))
		push(alloc, s.arr, value);
	return not(h);
}

void addToMutSetOkIfPresent(T, alias cmp, Alloc)(ref Alloc alloc, ref MutSet!(T, cmp) s, immutable T value) {
	tryAddToMutSet!(T, cmp)(alloc, s, value);
}
