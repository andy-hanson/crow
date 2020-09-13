module util.util;

@safe @nogc pure nothrow:

import util.bools : Bool, False;
//import util.print : print;

T todo(T)(immutable char* message) {
	debug {
		//print("TODO: %s\n", message);
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
	verify(b != 0);
	return a % b == 0 ? a : roundUp(a + 1, b);
}

void verify(immutable bool condition) {
	// TODO: In WASM assertions are turned off. Log somewhere instead?
	assert(condition);
}

void verifyFail() {
	verify(False);
}

T unreachable(T)() {
	assert(0);
}
