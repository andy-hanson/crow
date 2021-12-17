module test.testArrUtil;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.arrUtil : arrEqual, sortInPlace;
import util.comparison : compareNat32;
import util.util : verify;

void testArrUtil(ref Test test) {
	scope immutable(uint)[3] xs = [3, 1, 2];
	sortInPlace!(immutable uint)(xs, (ref immutable uint a, ref immutable uint b) =>
		compareNat32(a, b));
	verify(arrEqual!uint(xs, [1, 2, 3], (ref immutable uint a, ref immutable uint b) =>
		a == b));
}
