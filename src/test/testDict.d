module test.testDict;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.mutDict : addToMutDict, mustDelete, MutDict;

void testDict(ref Test test) {
	MutDict!(size_t, size_t) a;
	foreach (size_t key; [248, 344, 408, 24, 88, 216, 448, 16, 96, 600, 336, 768, 1368, 944, 536, 40, 1432])
		addToMutDict(test.alloc, a, key, key);
	mustDelete(a, 536);
	mustDelete(a, 1368);
}

private:
