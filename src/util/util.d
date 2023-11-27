module util.util;

@safe @nogc pure nothrow:

version (WebAssembly) { } else {
	import core.stdc.stdio : fprintf;
	import app.fileSystem : stderr;
}

T typeAs(T)(T a) =>
	a;

ref T todo(T)(in immutable char* s) {
	debugLog(s);
	assert(0);
}

T min(T)(T a, T b) =>
	a < b ? a : b;

T max(T)(T a, T b) =>
	a > b ? a : b;

T clamp(T)(T a, T min, T max) {
	assert(min <= max);
	return a < min ? min : a > max ? max : a;
}

ulong abs(long a) =>
	a < 0 ? -a : a;

double abs(double a) =>
	a < 0 ? -a : a;

T roundUp(T)(T a, T b) {
	T res = roundUpRecur(a, b);
	assert(res >= a);
	assert(res % b == 0);
	return res;
}

//TODO: more efficient
private T roundUpRecur(T)(T a, T b) {
	assert(b != 0);
	return a % b == 0 ? a : roundUpRecur(a + 1, b);
}

T divRoundUp(T)(T a, T b) {
	assert(b != 0);
	T div = a / b;
	T mod = a % b;
	T res = div + (mod == 0 ? 0 : 1);
	assert(res * b >= a);
	return res;
}

bool isMultipleOf(T)(T a, T b) {
	assert(b != 0);
	return a % b == 0;
}

void debugLog(immutable char* message) {
	debugLog(message, 0);
}

version (WebAssembly) {
	// WARN: 'message' must be heap allocated, not on stack
	extern(C) void debugLog(scope immutable char* message, size_t value);
} else {
	void debugLog(in immutable char* message, size_t value) {
		// Log to stderr because LSP uses stdout
		debug {
			fprintf(stderr, "debug log: %s == %llu\n", message, value);
		}
	}
}

T unreachable(T)() {
	assert(0);
}

void drop(T)(T) {}
