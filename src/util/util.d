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
	verify(min <= max);
	return a < min ? min : a > max ? max : a;
}

ulong abs(long a) =>
	a < 0 ? -a : a;

double abs(double a) =>
	a < 0 ? -a : a;

T roundUp(T)(T a, T b) {
	T res = roundUpRecur(a, b);
	verify(res >= a);
	verify(res % b == 0);
	return res;
}

//TODO: more efficient
private T roundUpRecur(T)(T a, T b) {
	verify(b != 0);
	return a % b == 0 ? a : roundUpRecur(a + 1, b);
}

T divRoundUp(T)(T a, T b) {
	verify(b != 0);
	T div = a / b;
	T mod = a % b;
	T res = div + (mod == 0 ? 0 : 1);
	verify(res * b >= a);
	return res;
}

bool isMultipleOf(T)(T a, T b) {
	verify(b != 0);
	return a % b == 0;
}

void verify(immutable char* reason = null)(bool condition, in string file = __FILE__, int line = __LINE__) {
	if (!condition) {
		static if (reason != null)
			debugLog(reason, 0);
		verifyFail(file, line);
	}
}

void verifyEq(T)(T a, T b) {
	//if (a != b)
	//	debug {
	//		static if (T.sizeof == 8) {
	//			printf("%lu != %lu\n", a, b);
	//		} else {
	//			printf("%d != %d\n", a, b);
	//		}
	//	}
	verify(a == b);
}

@trusted void verifyFail(in string file = __FILE__, int line = __LINE__) {
	version (WebAssembly) {
		_verifyFail(file.ptr, file.length, line);
	} else {
		assert(0);
	}
}

version (WebAssembly) {
	private extern(C) void _verifyFail(immutable char* filePtr, size_t fileLength, int line);
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
