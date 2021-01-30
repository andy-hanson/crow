module test.testArrUtil;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.arrUtil : arrEqual, sort;
import util.comparison : compareNat32;
import util.util : verify;

void testArrUtil(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	scope immutable uint[3] unsorted = [3, 1, 2];
	scope immutable uint[3] expected = [1, 2, 3];
	immutable Arr!uint sorted = sort!uint(test.alloc, unsorted, (ref immutable uint a, ref immutable uint b) =>
		compareNat32(a, b));
	verify(arrEqual!uint(sorted, expected, (ref immutable uint a, ref immutable uint b) =>
		immutable Bool(a == b)));
}
