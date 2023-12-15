module test.testMap;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.mutMap : mustAdd, mustDelete, mustGet, MutMap, size;

void testMap(ref Test test) {
	MutMap!(size_t, size_t) a;
	foreach (size_t key; [248, 344, 408, 24, 88, 216, 448, 16, 96, 600, 336, 768, 1368, 944, 536, 40, 1432]) {
		mustAdd(test.alloc, a, key, key);
		validate(a);
	}
	mustDelete(a, 536);
	mustDelete(a, 1368);
	validate(a);
}

private:

void validate(in MutMap!(size_t, size_t) a) {
	size_t count = 0;
	foreach (const size_t key, ref const size_t value; a) {
		count++;
		assert(mustGet(a, key) == value);
	}
	assert(size(a) == count);
}
