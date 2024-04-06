module util.col.sortUtil;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.array : isEmpty, map;
import util.comparison : Comparer, Comparison;
import util.memory : overwriteMemory;

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

void assertSortedAndUnique(T, K)(in T[] xs, in K delegate(in T) @safe @nogc pure nothrow getComparable) {
	foreach (size_t i; 1 .. xs.length)
		assert(getComparable(xs[i - 1]) < getComparable(xs[i]));
}
