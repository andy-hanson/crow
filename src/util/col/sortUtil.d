module util.col.sortUtil;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : everyWithIndex, map;
import util.comparison : Comparer, Comparison;
import util.opt : force, has, none, Opt, some;
import util.memory : overwriteMemory;
import util.util : verify;

T[] sorted(T)(ref Alloc alloc, in T[] a, in Comparer!T compare) {
	T[] res = map(alloc, a, (ref T x) => x);
	sortInPlace!T(res, compare);
	return res;
}

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
	void verifySorted(T)(in T[] xs, in K delegate(in T) @safe @nogc pure nothrow getComparable) {
		.verifySorted!T(xs, (in T x, in T y) =>
			comparer(getComparable(x), getComparable(y)));
	}
	verifySorted!A0(a0, getComparable0);
	verifySorted!A1(a1, getComparable1);
	verifySorted!A2(a2, getComparable2);
	verifySorted!A3(a3, getComparable3);
	verifySorted!A4(a4, getComparable4);

	// For each list, this is the next index into that list.
	size_t[5] indices;

	Opt!K getComparable(size_t indexOfList) {
		Opt!K get(T)(in T[] a, in K delegate(in T) @safe @nogc pure nothrow getComparable) {
			return indices[indexOfList] == a.length ? none!K : some(getComparable(a[indices[indexOfList]]));
		}
		final switch (indexOfList) {
			case 0: return get!A0(a0, getComparable0);
			case 1: return get!A1(a1, getComparable1);
			case 2: return get!A2(a2, getComparable2);
			case 3: return get!A3(a3, getComparable3);
			case 4: return get!A4(a4, getComparable4);
		}
	}
	void consume(size_t indexOfList) {
		size_t index = indices[indexOfList];
		final switch (indexOfList) {
			case 0: cb0(a0[index]); break;
			case 1: cb1(a1[index]); break;
			case 2: cb2(a2[index]); break;
			case 3: cb3(a3[index]); break;
			case 4: cb4(a4[index]); break;
		}
		indices[indexOfList]++;
	}

	while (true) {
		size_t nextList = indices.length;
		foreach (size_t indexOfList; 0 .. indices.length) {
			Opt!K k = getComparable(indexOfList);
			if (has(k)) {
				Opt!K nextListK = nextList == indices.length ? none!K : getComparable(nextList);
				if (!has(nextListK) || comparer(force(k), force(nextListK)) != Comparison.greater)
					nextList = indexOfList;
			}
		}
		if (nextList == indices.length)
			break;
		else
			consume(nextList);
	}

	verify(everyWithIndex!size_t(indices, (size_t indexOfList, in size_t _) =>
		!has(getComparable(indexOfList))));
}

private:

void verifySorted(T)(in T[] xs, in Comparer!T comparer) {
	foreach (size_t i; 1 .. xs.length)
		verify(comparer(xs[i - 1], xs[i]) != Comparison.greater);
}
