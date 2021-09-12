module util.util;

@safe @nogc nothrow:

import util.dbg : log, logNoNewline;
import util.types : incr, zero;

void repeatImpure(immutable size_t times, scope void delegate() @safe @nogc nothrow cb) {
	foreach (immutable size_t _; 0 .. times)
		cb();
}

pure:

T todo(T, Debug)(ref Debug dbg, immutable string message) {
	if (dbg.enabled()) {
		logNoNewline(dbg, "TODO: ");
		log(dbg, message);
	}
	assert(0);
}

T todo(T)(immutable string) {
	assert(0);
}

void repeat(immutable size_t times, scope void delegate() @safe @nogc pure nothrow cb) {
	foreach (immutable size_t _; 0 .. times)
		cb();
}

immutable(T) min(T)(immutable T a, immutable T b) {
	return a < b ? a : b;
}

immutable(T) max(T)(immutable T a, immutable T b) {
	return a > b ? a : b;
}

immutable(T) roundUp(T)(immutable T a, immutable T b) {
	immutable T res = roundUpRecur(a, b);
	verify(res >= a);
	verify(zero(res % b));
	return res;
}

//TODO: more efficient
private immutable(T) roundUpRecur(T)(immutable T a, immutable T b) {
	verify(!zero(b));
	return zero(a % b) ? a : roundUpRecur(incr(a), b);
}

immutable(T) divRoundUp(T)(immutable T a, immutable T b) {
	assert(!zero(b));
	immutable T div = a / b;
	immutable T mod = a % b;
	immutable T res = div + immutable T(zero(mod) ? 0 : 1);
	verify(res * b >= a);
	return res;
}

void verify(immutable bool condition) {
	if (!condition)
		assert(0);
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

struct Empty {}
