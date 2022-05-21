module util.util;

@safe @nogc pure nothrow:

immutable(T) as(T)(immutable T a) {
	return a;
}

T todo(T)(immutable char* s) {
	debugLog(s);
	assert(0);
}

immutable(T) min(T)(immutable T a, immutable T b) {
	return a < b ? a : b;
}

immutable(T) max(T)(immutable T a, immutable T b) {
	return a > b ? a : b;
}

immutable(ulong) abs(immutable long a) {
	return a < 0 ? -a : a;
}

immutable(double) abs(immutable double a) {
	return a < 0 ? -a : a;
}

immutable(T) roundUp(T)(immutable T a, immutable T b) {
	immutable T res = roundUpRecur(a, b);
	verify(res >= a);
	verify(res % b == 0);
	return res;
}

//TODO: more efficient
private immutable(T) roundUpRecur(T)(immutable T a, immutable T b) {
	verify(b != 0);
	return a % b == 0 ? a : roundUpRecur(a + 1, b);
}

immutable(T) divRoundUp(T)(immutable T a, immutable T b) {
	verify(b != 0);
	immutable T div = a / b;
	immutable T mod = a % b;
	immutable T res = div + immutable T(mod == 0 ? 0 : 1);
	verify(res * b >= a);
	return res;
}

void verify(immutable char* reason = null)(immutable bool condition) {
	version(assert) {
		if (!condition) {
			static if (reason != null)
				debugLog(reason, 0);
			verifyFail();
		}
	}
	version(WebAssembly) {
		if (!condition) {
			static if (reason != null)
				debugLog(reason, 0);
			verifyFail();
		}
	}
}

version(WebAssembly) {
	extern(C) void verifyFail();
}

void verifyEq(T)(immutable T a, immutable T b) {
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

version(WebAssembly) {
	extern(C) void verifyFail();
}
else {
	void verifyFail() {
		assert(0);
	}
}

void debugLog(immutable char* message) {
	debugLog(message, 0);
}

version (WebAssembly) {
	// WARN: 'message' must be heap allocated, not on stack
	extern(C) void debugLog(immutable char* message, immutable size_t value);
} else {
	void debugLog(immutable char* message, immutable size_t value) {
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

@trusted ref immutable(T) castImmutableRef(T)(ref const(T) a) {
	return cast(immutable) a;
}

struct Empty {}
