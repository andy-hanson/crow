module util.util;

@safe @nogc nothrow:

import util.bools : False;
import util.collection.arr : arrOfRange, at, range, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.str : emptyStr, Str, strLiteral;
import util.types : incr, Nat8, zero;

void repeatImpure(immutable size_t times, scope void delegate() @safe @nogc nothrow cb) {
	foreach (immutable size_t _; 0..times)
		cb();
}

pure:

struct NullDebug {
	@safe @nogc pure nothrow:

	void log(immutable Str) {}
}

T todo(T, Debug)(ref Debug dbg, immutable string message) {
	dbg.log(strLiteral("TODO: "));
	dbg.log(strLiteral(message));
	dbg.log(strLiteral("\n"));
	assert(0);
}

T todo(T)(immutable string message) {
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

immutable(Nat8) divRoundUp(immutable Nat8 a, immutable Nat8 b) {
	assert(!zero(b));
	immutable Nat8 div = a / b;
	immutable Nat8 mod = a % b;
	immutable Nat8 res = div + immutable Nat8(zero(mod) ? 0 : 1);
	verify(res * b >= a);
	return res;
}

void verify(immutable bool condition) {
	assert(condition);
}

void verify(Debug)(ref Debug dbg, immutable bool condition) {
	if (!condition)
		dbg.log("Verify failed.\n");
	assert(condition);
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
