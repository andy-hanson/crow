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
