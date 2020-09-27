module util.comparison;

@safe @nogc pure nothrow:

import util.bools : Bool;
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

immutable(Comparison) compareInt(immutable int a, immutable int b) {
	return a < b
			? Comparison.less
		: a > b
			? Comparison.greater
		: Comparison.equal;
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

immutable(Comparison) compareChar(immutable char a, immutable char b) {
	return compareInt(a, b);
}

immutable(Comparison) compareEnum(E)(immutable E a, immutable E b) {
	return compareInt(int(a), int(b));
}

immutable(Comparison) compareBool(immutable Bool a, immutable Bool b) {
	return a
		? b ? Comparison.equal : Comparison.greater
		: b ? Comparison.less : Comparison.equal;
}

immutable(Bool) ptrEquals(T)(immutable Ptr!T a, immutable Ptr!T b) {
	return Bool(a == b);
}
