module util.comparison;

@safe @nogc pure nothrow:

import util.util : min;

alias Comparer(T) = immutable Comparison delegate(in T, in T) @safe @nogc pure nothrow;

enum Comparison {
	less,
	equal,
	greater,
}

Comparison oppositeComparison(Comparison a) {
	final switch (a) {
		case Comparison.less:
			return Comparison.greater;
		case Comparison.equal:
			return Comparison.equal;
		case Comparison.greater:
			return Comparison.less;
	}
}

Comparison compareOr(Comparison a, in Comparison delegate() @safe @nogc pure nothrow b) =>
	a != Comparison.equal ? a : b();

Comparison compareArrays(T)(in T[] a, in T[] b, in Comparer!T cb) {
	foreach (size_t i; 0 .. min(a.length, b.length)) {
		Comparison comp = cb(a[i], b[i]);
		if (comp != Comparison.equal)
			return comp;
	}
	return compareT(a.length, b.length);
}

alias compareChar = compareT!char;
alias compareUint = compareT!uint;
alias compareUlong = compareT!ulong;

private Comparison compareT(T)(T a, T b) =>
	a < b
	? Comparison.less
	: a > b
	? Comparison.greater
	: Comparison.equal;
