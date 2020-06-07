module util.comparison;

@safe @nogc pure nothrow:

enum Comparison {
	less,
	equal,
	greater,
}

immutable(Comparison) compareOr(immutable Comparison a, scope Comparison delegate() @safe @nogc pure nothrow cb) {
	return a == Comparison.equal
		? cb()
		: a;
}

immutable(Comparison) compareInt(int a, int b) {
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
