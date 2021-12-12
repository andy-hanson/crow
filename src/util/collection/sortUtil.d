module util.collection.sortUtil;

@safe @nogc pure nothrow:

import util.collection.arr : empty;
import util.comparison : Comparer, Comparison;
import util.opt : none, Opt, some;

void eachSorted(T, A0, A1, A2, A3)(
	immutable T lastComparable,
	immutable Comparer!T comparer,
	immutable A0[] a0,
	scope immutable(T) delegate(ref immutable A0) @safe @nogc pure nothrow getComparable0,
	scope void delegate(ref immutable A0) @safe @nogc pure nothrow cb0,
	immutable A1[] a1,
	scope immutable(T) delegate(ref immutable A1) @safe @nogc pure nothrow getComparable1,
	scope void delegate(ref immutable A1) @safe @nogc pure nothrow cb1,
	immutable A2[] a2,
	scope immutable(T) delegate(ref immutable A2) @safe @nogc pure nothrow getComparable2,
	scope void delegate(ref immutable A2) @safe @nogc pure nothrow cb2,
	immutable A3[] a3,
	scope immutable(T) delegate(ref immutable A3) @safe @nogc pure nothrow getComparable3,
	scope void delegate(ref immutable A3) @safe @nogc pure nothrow cb3,
) {
	if (!empty(a0) || !empty(a1) || !empty(a2) || !empty(a3)) {
		immutable T c0 = empty(a0) ? lastComparable : getComparable0(a0[0]);
		immutable T c1 = empty(a1) ? lastComparable : getComparable1(a1[0]);
		immutable bool less01 = comparer(c0, c1) != Comparison.greater;
		immutable T min01 = less01 ? c0 : c1;
		immutable T c2 = empty(a2) ? lastComparable : getComparable2(a2[0]);
		immutable T c3 = empty(a3) ? lastComparable : getComparable3(a3[0]);
		immutable bool less23 = comparer(c2, c3) != Comparison.greater;
		immutable T min23 = less23 ? c2 : c3;
		if (comparer(min01, min23) != Comparison.greater) {
			if (less01) {
				cb0(a0[0]);
				eachSorted!(T, A0, A1, A2, A3)(
					lastComparable, comparer,
					a0[1 .. $], getComparable0, cb0,
					a1, getComparable1, cb1,
					a2, getComparable2, cb2,
					a3, getComparable3, cb3);
			} else {
				cb1(a1[0]);
				eachSorted!(T, A0, A1, A2, A3)(
					lastComparable, comparer,
					a0, getComparable0, cb0,
					a1[1 .. $], getComparable1, cb1,
					a2, getComparable2, cb2,
					a3, getComparable3, cb3);
			}
		} else {
			if (less23) {
				cb2(a2[0]);
				eachSorted!(T, A0, A1, A2, A3)(
					lastComparable, comparer,
					a0, getComparable0, cb0,
					a1, getComparable1, cb1,
					a2[1 .. $], getComparable2, cb2,
					a3, getComparable3, cb3);
			} else {
				cb3(a3[0]);
				eachSorted!(T, A0, A1, A2, A3)(
					lastComparable, comparer,
					a0, getComparable0, cb0,
					a1, getComparable1, cb1,
					a2, getComparable2, cb2,
					a3[1 .. $], getComparable3, cb3);
			}
		}
	}
}

struct UnsortedPair {
	immutable size_t index0;
	immutable size_t index1;
}

// Returns index of lower value
immutable(Opt!UnsortedPair) findUnsortedPair(T)(ref immutable T[] a, immutable Comparer!T compare) {
	if (!empty(a)) {
		foreach (immutable size_t i; 0 .. a.length - 1) {
			final switch (compare(a[i], a[i + 1])) {
				case Comparison.less:
				case Comparison.equal:
					break;
				case Comparison.greater:
					return some(immutable UnsortedPair(i, i + 1));
			}
		}
	}
	return none!UnsortedPair;
}
