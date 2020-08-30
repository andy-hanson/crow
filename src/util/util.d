module util.util;

@safe @nogc pure nothrow:

import core.stdc.stdio : printf;

T todo(T)(immutable char* message) {
	debug {
		printf("TODO: %s\n", message);
	}
	assert(0);
}

void repeat(immutable size_t times, scope void delegate() @safe @nogc pure nothrow cb) {
	foreach (immutable size_t _; 0..times)
		cb();
}

immutable(size_t) min(immutable size_t a, immutable size_t b) {
	return a < b ? a : b;
}

immutable(size_t) max(immutable size_t a, immutable size_t b) {
	return a > b ? a : b;
}

immutable(size_t) roundUp(immutable size_t a, immutable size_t b) {
	assert(b != 0);
	return a % b == 0 ? a : roundUp(a + 1, b);
}
