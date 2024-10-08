module test.testSortUtil;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.array : arraysEqual;
import util.col.sortUtil : sortInPlace;
import util.comparison : compareUint;

void testSortUtil(ref Test test) {
	scope uint[3] xs = [3, 1, 2];
	sortInPlace!(uint, compareUint)(xs);
	assert(arraysEqual!uint(xs, [1, 2, 3]));
}
