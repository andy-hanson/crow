module util.comparison;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

alias Comparer(T) = immutable(Comparison) delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow;

enum Comparison {
	less,
	equal,
	greater,
}

immutable(Comparison) compareOr(
	immutable Comparison a,
	scope Comparison delegate() @safe @nogc pure nothrow cb,
) {
	return a == Comparison.equal
		? cb()
		: a;
}

immutable(Comparison) compareOr(
	immutable Comparison a,
	scope Comparison delegate() @safe @nogc pure nothrow cb0,
	scope Comparison delegate() @safe @nogc pure nothrow cb1,
) {
	return compareOr(a, () =>
		compareOr(cb0(), cb1));
}

immutable(Comparison) compareNat16(immutable ushort a, immutable ushort b) {
	return compareSizeT(a, b);
}

immutable(Comparison) compareNat32(immutable uint a, immutable uint b) {
	return compareSizeT(a, b);
}

immutable(Comparison) compareSizeT(immutable size_t a, immutable size_t b) {
	return a < b
			? Comparison.less
		: a > b
			? Comparison.greater
		: Comparison.equal;
}

immutable(Comparison) compareEnum(E)(immutable E a, immutable E b) {
	return compareNat32(uint(a), uint(b));
}

immutable(Comparison) compareBool(immutable bool a, immutable bool b) {
	return a
		? b ? Comparison.equal : Comparison.greater
		: b ? Comparison.less : Comparison.equal;
}

immutable(bool) ptrEquals(T)(immutable Ptr!T a, immutable Ptr!T b) {
	return a == b;
}
