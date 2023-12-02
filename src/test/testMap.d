module test.testMap;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.hash : hashString;
import util.col.mutMap : KeyValuePair, mustAddToMutMap, mustDelete, mutMapMustGet, MutMap, mutMapSize;

import core.stdc.stdio : printf;

void testMap(ref Test test) {
	debug {
		foreach (string x; ["a", "ab", "abc"]) {
			printf("hash of %.*s is %lu\n", cast(int) x.length, x.ptr, hashString(x).hashCode);
		}
	}

	MutMap!(size_t, size_t) a;
	foreach (size_t key; [248, 344, 408, 24, 88, 216, 448, 16, 96, 600, 336, 768, 1368, 944, 536, 40, 1432]) {
		debug {
			import core.stdc.stdio : printf;
			printf("now add %lu\n", key);
		}
		mustAddToMutMap(test.alloc, a, key, key);
		validate(a);
	}
	mustDelete(a, 536);
	mustDelete(a, 1368);
	validate(a);
}

private:

void validate(in MutMap!(size_t, size_t) a) {
	size_t size = 0;
	foreach (const size_t key, ref const size_t value; a) {
		size++;
		assert(mutMapMustGet(a, key) == value);
	}
	assert(mutMapSize(a) == size);
}
