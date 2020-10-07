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

immutable(T) min(T)(immutable T a, immutable T b) {
	return a < b ? a : b;
}

immutable(T) max(T)(immutable T a, immutable T b) {
	return a > b ? a : b;
}

immutable(T) roundUp(T)(immutable T a, immutable T b) {
	verify(b != 0);
	return a % b == 0 ? a : roundUp(cast(T) (a + 1), b);
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
