module util.col.sortUtil;

@safe @nogc pure nothrow:

import util.col.arr : empty;
import util.col.arrUtil : every;
import util.comparison : Comparer, Comparison;
import util.opt : force, has, none, Opt, some;
import util.memory : overwriteMemory;
import util.util : verify;

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

void eachSorted(K, A0, A1, A2, A3, A4)(
	in K lastComparable,
	in Comparer!K comparer,
	in A0[] a0,
	in K delegate(in A0) @safe @nogc pure nothrow getComparable0,
	in void delegate(in A0) @safe @nogc pure nothrow cb0,
	in A1[] a1,
	in K delegate(in A1) @safe @nogc pure nothrow getComparable1,
	in void delegate(in A1) @safe @nogc pure nothrow cb1,
	in A2[] a2,
	in K delegate(in A2) @safe @nogc pure nothrow getComparable2,
	in void delegate(in A2) @safe @nogc pure nothrow cb2,
	in A3[] a3,
	in K delegate(in A3) @safe @nogc pure nothrow getComparable3,
	in void delegate(in A3) @safe @nogc pure nothrow cb3,
	in A4[] a4,
	in K delegate(in A4) @safe @nogc pure nothrow getComparable4,
	in void delegate(in A4) @safe @nogc pure nothrow cb4,
) {
	size_t[5] indices;

	Opt!K getComparable(size_t i) {
		Opt!K get(T)(in T[] a, in K delegate(in T) @safe @nogc pure nothrow getComparable) {
			return indices[i] == a.length ? none!K : some(getComparable(a[indices[i]]));
		}
		final switch (i) {
			case 0: return get!A0(a0, getComparable0);
			case 1: return get!A1(a1, getComparable1);
			case 2: return get!A2(a2, getComparable2);
			case 3: return get!A3(a3, getComparable3);
			case 4: return get!A4(a4, getComparable4);
		}
	}
	void consume(size_t i) {
		size_t index = indices[i];
		final switch (i) {
			case 0: cb0(a0[index]); break;
			case 1: cb1(a1[index]); break;
			case 2: cb2(a2[index]); break;
			case 3: cb3(a3[index]); break;
			case 4: cb4(a4[index]); break;
		}
		indices[i]++;
	}

	while (true) {
		size_t best = indices.length;
		foreach (size_t i; 0 .. indices.length) {
			Opt!K k = getComparable(i);
			if (has(k)) {
				Opt!K bestK = best == indices.length ? none!K : getComparable(best);
				if (!has(bestK) || comparer(force(k), force(bestK)) != Comparison.greater)
					best = i;
			}
		}
		if (best == indices.length)
			break;
		else
			consume(best);
	}

	verify(every!size_t(indices, (in size_t i) => !has(getComparable(i))));
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
