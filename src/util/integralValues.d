module util.integralValues;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, AllocKind, freeElements, MetaAlloc, newAlloc;
import util.comparison : compareUlong;
import util.col.array : arraysEqual, everyWithIndex, makeArray, map, SmallArray;
import util.col.hashTable : ValueAndDidAdd;
import util.col.mutSet : getOrAddToMutSet, MutSet;
import util.col.sortUtil : sortInPlace;
import util.hash : HashCode, Hasher;

// A value of some contextually-known integral type.
immutable struct IntegralValue {
	@safe @nogc pure nothrow:

	// Large nat64 are represented as wrapped to negative values.
	ulong value;

	long asSigned() =>
		cast(long) value;
	ulong asUnsigned() =>
		value;
}

// Integral values, in sorted order. This is used to store the values used by a 'match'.
immutable struct IntegralValues {
	@safe @nogc pure nothrow:
	SmallArray!IntegralValue values;

	private this(IntegralValue[] v) {
		values = v;
	}

	alias values this;

	void assertIsRange(size_t size) scope {
		assert(values.length == size && isRange0ToN);
	}

	bool isRange0ToN() scope =>
		everyWithIndex!IntegralValue(values, (size_t i, ref IntegralValue value) =>
			value.asUnsigned == i);

	HashCode hash() scope {
		Hasher hasher;
		foreach (IntegralValue value; values)
			hasher ~= value.asUnsigned;
		return hasher.finish();
	}

	bool opEquals(in IntegralValues rhs) scope =>
		arraysEqual(this, rhs);
}

@trusted void initIntegralValues(MetaAlloc* metaAlloc) {
	integralValuesAlloc = newAlloc(AllocKind.integralValues, metaAlloc);
}

private __gshared Alloc* integralValuesAlloc;
private __gshared MutSet!IntegralValues cache;

@trusted pure IntegralValues integralValuesRange(size_t n) =>
	makeIntegralValues((ref Alloc alloc) => makeArray!IntegralValue(alloc, n, (size_t i) => IntegralValue(i)));

@trusted pure IntegralValues mapToIntegralValues(T)(
	in T[] xs,
	in IntegralValue delegate(in T) @safe @nogc pure nothrow cb,
) =>
	makeIntegralValues((ref Alloc alloc) {
		IntegralValue[] values = map!(IntegralValue, T)(alloc, xs, (ref T x) => cb(x));
		sortInPlace!IntegralValue(values, (in IntegralValue x, in IntegralValue y) =>
			compareUlong(x.asUnsigned, y.asUnsigned));
		return values;
	});

private @system pure IntegralValues makeIntegralValues(
	in IntegralValue[] delegate(ref Alloc) @safe @nogc pure nothrow cb,
) =>
	(cast(IntegralValues function(
		in IntegralValue[] delegate(ref Alloc) @safe @nogc pure nothrow
	) @safe @nogc pure nothrow) &makeIntegralValues_impure)(cb);

private @system IntegralValues makeIntegralValues_impure(
	in IntegralValue[] delegate(ref Alloc) @safe @nogc pure nothrow cb,
) {
	IntegralValue[] values = cb(*integralValuesAlloc);
	ValueAndDidAdd!IntegralValues res = getOrAddToMutSet(*integralValuesAlloc, cache, IntegralValues(values));
	if (!res.didAdd)
		freeElements(*integralValuesAlloc, values);
	return res.value;
}