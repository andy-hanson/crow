module test.testDict;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.mutDict : addToMutDict, mustDelete, MutDict;

void testDict(ref Test test) {
	MutDict!(immutable size_t, immutable size_t) a;
	immutable size_t[17] keys = [248, 344, 408, 24, 88, 216, 448, 16, 96, 600, 336, 768, 1368, 944, 536, 40, 1432];
	foreach (immutable size_t key; keys)
		addToMutDict(test.alloc, a, key, key);
	mustDelete(a, 536);
	mustDelete(a, 1368);
}

private:
