module test.testStack;

@safe @nogc nothrow: // not pure

import interpret.bytecode : Operation;
import interpret.stacks :
	dataEnd,
	dataPeek,
	dataPop,
	dataPopN,
	dataPush,
	dataRemove,
	dataReturn,
	dataTop,
	Stacks,
	stacksForRange;
import test.testUtil : expectDataStack, Test;
import util.col.array : arraysEqual, endPtr;

void testStack(ref Test test) {
	testPushPop(test);
	testDataReturn(test);
}

private:

@trusted void testPushPop(ref Test test) {
	ulong[8] storage;
	Stacks a = stacksForRange(storage);

	assert(dataEnd(a) == &storage[0]);
	assert(a.returnPtr == cast(Operation**) endPtr(storage) - 1); // It pushes null by default

	dataPush(a, 42);
	assert(storage[0] == 42);
	assert(dataPeek(a) == 42);
	assert(dataPop(a) == 42);
	assert(dataEnd(a) == &storage[0]);

	ulong* begin = dataEnd(a);
	assert(begin == &storage[0]);

	dataPush(a, 5);
	dataPush(a, 6);
	expectDataStack(test, storage, a, [5, 6]);

	dataPush(a, 7);
	assert(dataTop(a) == begin + 2);
	assert(dataEnd(a) == begin + 3);

	scope immutable ulong[] popped = dataPopN(a, 2);
	assert(arraysEqual(popped, [6, 7]));
	expectDataStack(test, storage, a, [5]);

	dataPush(a, 8);
	dataPush(a, 9);
	expectDataStack(test, storage, a, [5, 8, 9]);
	ulong removed = dataRemove(a, 1);
	assert(removed == 8);
	expectDataStack(test, storage, a, [5, 9]);

	dataPush(a, 11);
	dataPush(a, 13);

	expectDataStack(test, storage, a, [5, 9, 11, 13]);

	dataReturn(a, 2, 1);
	expectDataStack(test, storage, a, [5, 13]);

	assert(dataPop(a) == 13);
	assert(dataPop(a) == 5);
	assert(dataEnd(a) == &storage[0]);
	assert(a.returnPtr == cast(Operation**) endPtr(storage) - 1);
}

@trusted void testDataReturn(ref Test test) {
	ulong[8] storage;
	Stacks a = stacksForRange(storage);

	foreach (ulong i; [1, 2, 3, 4, 5, 6])
		dataPush(a, i);

	dataReturn(a, 0, 0);
	expectDataStack(test, storage, a, [1, 2, 3, 4, 5]);

	dataReturn(a, 3, 2);
	expectDataStack(test, storage, a, [1, 4, 5]);

	dataReturn(a, 2, 0);
	expectDataStack(test, storage, a, []);
}
