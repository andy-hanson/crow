module test.testMutMultiMap;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc : Alloc, withTempAlloc;
import util.col.mutMultiMap : add, countKeys, eachValueForKey, mayDeleteKey, mayDeletePair, MutMultiMap;

void testMutMultiMap(ref Test test) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc alloc) {
		testBasic(alloc);
	});
}

private:

void testBasic(ref Alloc alloc) {
	MutMultiMap!(uint, uint) a;

	add(alloc, a, 1, 11);
	add(alloc, a, 2, 21);
	add(alloc, a, 1, 12);
	add(alloc, a, 2, 22);
	assertValuesForKey(a, 1, [11, 12]);
	assertValuesForKey(a, 2, [21, 22]);
	assert(countKeys(a) == 2);

	bool deleted = mayDeletePair(a, 1, 11);
	assert(deleted);
	assertValuesForKey(a, 1, [12]);

	size_t i = 0;
	mayDeleteKey(a, 2, (uint x) {
		static immutable uint[] expected = [21, 22];
		assert(x == expected[i]);
		i++;
	});
	assertValuesForKey(a, 1, [12]);
	assertValuesForKey(a, 2, []);
	assert(countKeys(a) == 1);
}

void assertValuesForKey(in MutMultiMap!(uint, uint) a, uint key, in uint[] values) {
	size_t i = 0;
	eachValueForKey(a, key, (uint x) {
		assert(x == values[i]);
		i++;
	});
	assert(i == values.length);
}
