module util.util;

@safe @nogc pure nothrow:

import core.stdc.stdio : printf;

T todo(T)(immutable char* message) {
	debug {
		printf("TODO: %s\n", message);
	}
	assert(0);
}
