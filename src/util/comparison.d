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
	return compareT(a, b);
}

immutable(Comparison) compareNat32(immutable uint a, immutable uint b) {
	return compareT(a, b);
}

immutable(Comparison) compareSizeT(immutable size_t a, immutable size_t b) {
	return compareT(a, b);
}

immutable(Comparison) compareUlong(immutable ulong a, immutable ulong b) {
	return compareT(a, b);
}

immutable(Comparison) compareEnum(E)(immutable E a, immutable E b) {
	return compareNat32(uint(a), uint(b));
}

private immutable(Comparison) compareT(T)(immutable T a, immutable T b) {
	return a < b
			? Comparison.less
		: a > b
			? Comparison.greater
		: Comparison.equal;
}
