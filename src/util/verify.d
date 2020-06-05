module util.verify;

@safe @nogc pure nothrow:

import util.bools : Bool;

void verify(immutable Bool b) {
	if (!b.value) {
		assert(0);
	}
}

T unreachable(T)() {
	assert(0);
}
