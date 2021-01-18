module util.collection.mutSet;

@safe @nogc pure nothrow:

import util.bools : Bool, False, not, True;
import util.collection.arr : Arr;
import util.collection.mutArr : mutArrMoveToArr = moveToArr, MutArr, mutArrRange, push;
import util.comparison : Comparison;

struct MutSet(T, alias cmp) {
	private MutArr!T arr;
}

immutable(Arr!T) moveToArr(Alloc, T, alias cmp)(ref Alloc alloc, ref MutSet!(immutable T, cmp) a) {
	return mutArrMoveToArr(alloc, a.arr);
}

immutable(Bool) mutSetHas(T, alias cmp)(ref const MutSet!(T, cmp) a, immutable T value) {
	foreach (ref const T t; mutArrRange(a.arr))
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
