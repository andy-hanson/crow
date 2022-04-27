module test.testMemory;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.memory : memmove;
import util.util : verify;

@trusted void testMemory(ref Test) {
	ubyte[8] xs = [0, 1, 2, 3, 4, 5, 6, 7];
	memmove(xs.ptr + 1, xs.ptr + 3, 5);
	verify(xs == [0, 3, 4, 5, 6, 7, 6, 7]);

	xs = [0, 1, 2, 3, 4, 5, 6, 7];
	memmove(xs.ptr + 3, xs.ptr + 1, 3);
	verify(xs == [0, 1, 2, 1, 2, 3, 6, 7]);
}
