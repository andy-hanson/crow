module util.col.sortUtil;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.array : contains, every, isEmpty, map;
import util.comparison : Comparer, Comparison;
import util.memory : overwriteMemory;

bool sortedArrayContains(T, alias compare)(in T[] a, T value) {
	assertSortedAndUnique!(T, compare)(a);
	return binarySearch!(T, compare)(a, value);
}
private bool binarySearch(T, alias compare)(in T[] a, T value) {
	size_t left = 0; // inclusive
	size_t right = a.length; // exclusive
	while (right - left > 8) {
		size_t mid = left + (right - left) / 2;
		final switch (compare(value, a[mid])) {
			case Comparison.less:
				right = mid;
				break;
			case Comparison.equal:
				return true;
			case Comparison.greater:
				left = mid + 1;
				break;
		}
	}
	return contains(a[left .. right], value);
}

bool sortedArrayIsSuperset(T, alias compare)(in T[] a, in T[] b) {
	assertSortedAndUnique!(T, compare)(a);
	assertSortedAndUnique!(T, compare)(b);
	size_t ai = 0;
	size_t bi = 0;
	while (ai != a.length && bi != b.length) {
		if (a[ai] == b[bi]) {
			ai++;
			bi++;
		} else
			ai++;
	}
	bool res = bi == b.length;
	assert(res == every!T(b, (in T x) => sortedArrayContains!(T, compare)(a, x)));
	return res;
}

T[] sorted(T)(ref Alloc alloc, in T[] a, in Comparer!T compare) {
	T[] res = map(alloc, a, (ref T x) => x);
	sortInPlace!(T, compare)(res);
	return res;
}

//TODO:PERF More efficient than bubble sort..
void sortInPlace(T, alias compare)(scope T[] a) {
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
		sortInPlace!(T, compare)(a[0 .. lastNonSorted]);
	}
}

private void swap(T)(scope T[] a, size_t i, size_t j) {
	T tmp = a[i];
	overwriteMemory(&a[i], a[j]);
	overwriteMemory(&a[j], tmp);
}

// Returns a struct for use with 'eachSorted'
auto sortedIter(T, K, Ctx, alias getComparable, alias cbValue)(T[] values) {
	struct Iter {
		T[] values;
		bool isEmpty() scope const =>
			.isEmpty(values);
		K peek() scope const =>
			getComparable(values[0]);
		void callNext(scope ref Ctx ctx) scope {
			cbValue(ctx, values[0]);
			values = values[1 .. $];
		}
	}
	assertSorted!(T, K, getComparable)(values);
	return Iter(values);
}

// Iters should be the result of 'sortedIter'
void eachSorted(K, Ctx, Iters...)(scope ref Ctx ctx, scope Iters iters) {
	while (true) {
		size_t pickIter = iters.length;
		K pickK = K.max;
		static foreach (size_t i; 0 .. iters.length) {
			if (!iters[i].isEmpty && iters[i].peek < pickK) {
				pickIter = i;
				pickK = iters[i].peek;
			}
		}

		if (pickIter == iters.length)
			break;
		else {
			// This does 'iters[pickIter].callNext(ctx);'
			switch_: final switch (pickIter) {
				static foreach (size_t i; 0 .. iters.length) {
					case i:
						iters[i].callNext(ctx);
						break switch_;
				}
			}
		}
	}
	static foreach (size_t i; 0 .. iters.length)
		assert(iters[i].isEmpty);
}

private void assertSorted(T, K, alias getComparable)(in T[] xs) {
	foreach (size_t i; 1 .. xs.length)
		assert(getComparable(xs[i - 1]) <= getComparable(xs[i]));
}

void assertSortedAndUnique(T, alias compare)(in T[] xs) {
	foreach (size_t i; 1 .. xs.length)
		assert(compare(xs[i - 1], xs[i]) == Comparison.less);
}
