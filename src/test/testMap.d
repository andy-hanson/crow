module test.testMap;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.mutMap : mustAdd, mustDelete, mustGet, MutMap, size;

void testMap(ref Test test) {
	MutMap!(uint, uint) a;
	foreach (uint key; [248, 344, 408, 24, 88, 216, 448, 16, 96, 600, 336, 768, 1368, 944, 536, 40, 1432]) {
		mustAdd(test.alloc, a, key, key);
		validate(a);
	}
	mustDelete(a, 536);
	mustDelete(a, 1368);
	validate(a);
}

private:

void validate(in MutMap!(uint, uint) a) {
	uint count = 0;
	foreach (const uint key, ref const uint value; a) {
		count++;
		assert(mustGet(a, key) == value);
	}
	assert(size(a) == count);
}
