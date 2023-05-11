module util.util;

@safe @nogc pure nothrow:

T typeAs(T)(T a) =>
	a;

T todo(T)(in immutable char* s) {
	debugLog(s);
	assert(0);
}

T min(T)(T a, T b) =>
	a < b ? a : b;

T max(T)(T a, T b) =>
	a > b ? a : b;

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

void verify(immutable char* reason = null)(bool condition) {
	version (assert) {
		if (!condition) {
			static if (reason != null)
				debugLog(reason, 0);
			verifyFail();
		}
	}
	version (WebAssembly) {
		if (!condition) {
			static if (reason != null)
				debugLog(reason, 0);
			verifyFail();
		}
	}
}

version (WebAssembly) {
	extern(C) void verifyFail();
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

version (WebAssembly) {
	extern(C) void verifyFail();
}
else {
	void verifyFail() {
		assert(0);
	}
}

void debugLog(in immutable char* message) {
	debugLog(message, 0);
}

version (WebAssembly) {
	// WARN: 'message' must be heap allocated, not on stack
	extern(C) void debugLog(scope immutable char* message, size_t value);
} else {
	void debugLog(in immutable char* message, size_t value) {
		import core.stdc.stdio : printf;
		debug {
			printf("debug log: %s == %llu\n", message, value);
		}
	}
}

T unreachable(T)() {
	assert(0);
}

void drop(T)(T) {}
