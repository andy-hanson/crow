module util.integralValues;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc, AllocKind, MetaAlloc, newAlloc;
import util.alloc.stackAlloc : withMapToStackArray, withStackArray;
import util.comparison : compareUlong;
import util.col.array : arraysEqual, copyArray, isEmpty, only, SmallArray;
import util.col.mutSet : getOrAddLazyAlloc, MutSet;
import util.col.sortUtil : assertSortedAndUnique, sortInPlace;
import util.conv : safeToUint;
import util.hash : HashCode, Hasher;
import util.memory : initMemory;

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

/*
Integral values, in sorted order with no repeats.
This is used to store the values used by a 'match'.
*/
immutable struct IntegralValues {
	@safe @nogc pure nothrow:
	SmallArray!IntegralValue values;

	private this(IntegralValue[] v) {
		values = v;
	}

	alias values this;

	bool isRange0ToN() scope =>
		isEmpty(values) || values[$ - 1].asUnsigned == values.length - 1;

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
	foreach (size_t i; 0 .. linear.length)
		initMemory(&linear[i], IntegralValue(i));
}

private __gshared Alloc* integralValuesAlloc;
private __gshared MutSet!IntegralValues cache;
private immutable IntegralValue[0x100] linear;

@trusted pure IntegralValues integralValuesRange(size_t n) {
	if (n <= linear.length) {
		IntegralValues res = IntegralValues(linear[0 .. n]);
		assert(res.isRange0ToN);
		return res;
	} else
		return withStackArray!(IntegralValues, IntegralValue)(
			n,
			(size_t x) => IntegralValue(x),
			(scope IntegralValue[] xs) => getOrAddIntegralValues(xs));
}

pure IntegralValues singleIntegralValue(in IntegralValue a) {
	ulong x = a.asUnsigned;
	return x < linear.length
		? IntegralValues(linear[safeToUint(x) .. safeToUint(x) + 1])
		: getOrAddIntegralValues([IntegralValue(x)]);
}

@trusted pure IntegralValues mapToIntegralValues(T)(
	in T[] xs,
	in IntegralValue delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	switch (xs.length) {
		case 0:
			return integralValuesRange(0);
		case 1:
			return singleIntegralValue(cb(only(xs)));
		default:
			return withMapToStackArray!(IntegralValues, IntegralValue, const T)(xs, cb, (scope IntegralValue[] values) {
				sortInPlace!IntegralValue(values, (in IntegralValue x, in IntegralValue y) =>
					compareUlong(x.asUnsigned, y.asUnsigned));
				assertSortedAndUnique!(IntegralValue, ulong)(values, (in IntegralValue x) => x.asUnsigned);
				return (values[$ - 1].asUnsigned == values.length)
					? integralValuesRange(xs.length)
					: getOrAddIntegralValues(values);
			});
	}
}

private @trusted pure IntegralValues getOrAddIntegralValues(in IntegralValue[] values) =>
	(cast(IntegralValues function(in IntegralValue[]) @safe @nogc pure nothrow) &getOrAddIntegralValues_impure)(values);

private @system IntegralValues getOrAddIntegralValues_impure(
	in IntegralValue[] values,
) =>
	getOrAddLazyAlloc!IntegralValues(
		*integralValuesAlloc, cache, IntegralValues(values),
		cast(IntegralValues delegate() @safe @nogc pure nothrow) () =>
			IntegralValues(copyArray(*integralValuesAlloc, values)));
