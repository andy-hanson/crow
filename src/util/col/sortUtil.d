module util.col.sortUtil;

@safe @nogc pure nothrow:

import util.col.arr : empty;
import util.comparison : Comparer, Comparison;
import util.opt : none, Opt, some;
import util.memory : overwriteMemory;

//TODO:PERF More efficient than bubble sort..
void sortInPlace(T)(scope T[] a, in Comparer!T compare) {
	size_t n = a.length; // avoiding dscanner warning `Avoid subtracting from '.length' as it may be unsigned`
	if (n > 1) {
		size_t lastNonSorted = 0;
		foreach (size_t i; 0 .. n - 1) {
			final switch (compare(a[i], a[i + 1])) {
				case Comparison.less:
				case Comparison.equal:
					break;
				case Comparison.greater:
					swap(a, i, i + 1);
					lastNonSorted = i + 1;
					break;
			}
		}
		sortInPlace!T(a[0 .. lastNonSorted], compare);
	}
}

private void swap(T)(scope T[] a, size_t i, size_t j) {
	T tmp = a[i];
	overwriteMemory(&a[i], a[j]);
	overwriteMemory(&a[j], tmp);
}

void eachSorted(T, A0, A1, A2, A3)(
	in T lastComparable,
	in Comparer!T comparer,
	in A0[] a0,
	in T delegate(in A0) @safe @nogc pure nothrow getComparable0,
	in void delegate(in A0) @safe @nogc pure nothrow cb0,
	in A1[] a1,
	in T delegate(in A1) @safe @nogc pure nothrow getComparable1,
	in void delegate(in A1) @safe @nogc pure nothrow cb1,
	in A2[] a2,
	in T delegate(in A2) @safe @nogc pure nothrow getComparable2,
	in void delegate(in A2) @safe @nogc pure nothrow cb2,
	in A3[] a3,
	in T delegate(in A3) @safe @nogc pure nothrow getComparable3,
	in void delegate(in A3) @safe @nogc pure nothrow cb3,
) {
	if (!empty(a0) || !empty(a1) || !empty(a2) || !empty(a3)) {
		T c0 = empty(a0) ? lastComparable : getComparable0(a0[0]);
		T c1 = empty(a1) ? lastComparable : getComparable1(a1[0]);
		bool less01 = comparer(c0, c1) != Comparison.greater;
		T min01 = less01 ? c0 : c1;
		T c2 = empty(a2) ? lastComparable : getComparable2(a2[0]);
		T c3 = empty(a3) ? lastComparable : getComparable3(a3[0]);
		bool less23 = comparer(c2, c3) != Comparison.greater;
		T min23 = less23 ? c2 : c3;
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

immutable struct UnsortedPair {
	size_t index0;
	size_t index1;
}

// Returns index of lower value
Opt!UnsortedPair findUnsortedPair(T)(in T[] a, Comparer!T compare) {
	if (!empty(a)) {
		foreach (size_t i; 0 .. a.length - 1) {
			final switch (compare(a[i], a[i + 1])) {
				case Comparison.less:
				case Comparison.equal:
					break;
				case Comparison.greater:
					return some(UnsortedPair(i, i + 1));
			}
		}
	}
	return none!UnsortedPair;
}
