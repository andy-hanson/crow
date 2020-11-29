module util.util;

@safe @nogc nothrow:

import util.bools : Bool, False;
import util.collection.str : Str, strLiteral;
import util.types : incr, Nat16, zero;

void repeatImpure(immutable size_t times, scope void delegate() @safe @nogc nothrow cb) {
	foreach (immutable size_t _; 0..times)
		cb();
}

pure:

struct NullDebug {
	@safe @nogc pure nothrow:

	immutable(Bool) enabled() {
		return False;
	}

	void log(immutable Str) {
		verifyFail();
	}
}

T todo(T, Debug)(ref Debug dbg, immutable string message) {
	if (dbg.enabled()) {
		dbg.log(strLiteral("TODO: "));
		dbg.log(strLiteral(message));
		dbg.log(strLiteral("\n"));
	}
	assert(0);
}

T todo(T)(immutable string) {
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
	verify(!zero(b));
	return zero(a % b) ? a : roundUp(incr(a), b);
}

immutable(Nat16) divRoundUp(immutable Nat16 a, immutable Nat16 b) {
	assert(!zero(b));
	immutable Nat16 div = a / b;
	immutable Nat16 mod = a % b;
	immutable Nat16 res = div + immutable Nat16(zero(mod) ? 0 : 1);
	verify(res * b >= a);
	return res;
}

void verify(immutable bool condition) {
	assert(condition);
}

void verify(Debug)(ref Debug dbg, immutable bool condition) {
	if (!condition) {
		if (dbg.enabled())
			dbg.log("Verify failed.\n");
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
	verify(False);
}

T unreachable(T)() {
	assert(0);
}
