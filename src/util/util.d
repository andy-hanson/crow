module util.util;

@safe @nogc nothrow:

void repeatImpure(immutable size_t times, scope void delegate() @safe @nogc nothrow cb) {
	foreach (immutable size_t _; 0..times)
		cb();
}

pure:

import core.stdc.stdio : printf;
import util.bools : False;
import util.types : incr, Nat8, zero;
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
	// TODO: In WASM assertions are turned off. Log somewhere instead?
	assert(condition);
}

void verifyEq(T)(immutable T a, immutable T b) {
	if (a != b)
		debug {
			static if (T.sizeof == 8) {
				printf("%lu != %lu\n", a, b);
			} else {
				printf("%d != %d\n", a, b);
			}
		}
	verify(a == b);
}

void verifyFail() {
	verify(False);
}

T unreachable(T)() {
	assert(0);
}
