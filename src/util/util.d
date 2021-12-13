module util.util;

@safe @nogc pure nothrow:

T todo(T)(immutable string) {
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

void verify(immutable bool condition) {
	version(assert) {
		if (!condition)
			assert(0);
	}
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

void verifyFail() {
	assert(0);
}

T unreachable(T)() {
	assert(0);
}

void drop(T)(T) {}

@trusted ref immutable(T) castImmutableRef(T)(ref const(T) a) {
	return cast(immutable) a;
}

struct Empty {}
