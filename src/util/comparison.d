module util.comparison;

@safe @nogc pure nothrow:

alias Comparer(T) =
	immutable(Comparison) delegate(scope ref immutable T, scope ref immutable T) @safe @nogc pure nothrow;
alias ConstComparer(T) =
	immutable(Comparison) delegate(scope ref const T, scope ref const T) @safe @nogc pure nothrow;

enum Comparison {
	less,
	equal,
	greater,
}

immutable(Comparison) oppositeComparison(immutable Comparison a) {
	final switch (a) {
		case Comparison.less:
			return Comparison.greater;
		case Comparison.equal:
			return Comparison.equal;
		case Comparison.greater:
			return Comparison.less;
	}
}

immutable(Comparison) compareNat16(immutable ushort a, immutable ushort b) =>
	compareT(a, b);

immutable(Comparison) compareNat32(immutable uint a, immutable uint b) =>
	compareT(a, b);

immutable(Comparison) compareSizeT(immutable size_t a, immutable size_t b) =>
	compareT(a, b);

immutable(Comparison) compareUlong(immutable ulong a, immutable ulong b) =>
	compareT(a, b);

private immutable(Comparison) compareT(T)(immutable T a, immutable T b) =>
	a < b
			? Comparison.less
		: a > b
			? Comparison.greater
		: Comparison.equal;
