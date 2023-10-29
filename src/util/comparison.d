module util.comparison;

@safe @nogc pure nothrow:

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

Comparison compareNat32(uint a, uint b) =>
	compareT(a, b);

Comparison compareSizeT(size_t a, size_t b) =>
	compareT(a, b);

Comparison compareUlong(ulong a, ulong b) =>
	compareT(a, b);

private Comparison compareT(T)(T a, T b) =>
	a < b
	? Comparison.less
	: a > b
	? Comparison.greater
	: Comparison.equal;
