module util.collection.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.mutArr : mutArrMoveToArr = moveToArr, MutArr, mutArrRange, push;
import util.comparison : Comparison;
import util.util : drop;

struct MutSet(T, alias cmp) {
	private MutArr!T arr;
}

immutable(T[]) moveToArr(T, alias cmp)(ref Alloc alloc, ref MutSet!(immutable T, cmp) a) {
	return mutArrMoveToArr(alloc, a.arr);
}

private immutable(bool) mutSetHas(T, alias cmp)(ref const MutSet!(T, cmp) a, immutable T value) {
	foreach (ref const T t; mutArrRange(a.arr))
		if (cmp(t, value) == Comparison.equal)
			return true;
	return false;
}

private immutable(bool) tryAddToMutSet(T, alias cmp)(ref Alloc alloc, ref MutSet!(T, cmp) s, immutable T value) {
	immutable bool add = !mutSetHas(s, value);
	if (add)
		push(alloc, s.arr, value);
	return add;
}

void addToMutSetOkIfPresent(T, alias cmp)(ref Alloc alloc, ref MutSet!(T, cmp) s, immutable T value) {
	drop(tryAddToMutSet!(T, cmp)(alloc, s, value));
}
