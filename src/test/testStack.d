module test.testStack;

@safe @nogc nothrow: // not pure

import interpret.stacks :
	dataEnd,
	dataPeek,
	dataPop,
	dataPopN,
	dataPush,
	dataRemove,
	dataReturn,
	dataStackIsEmpty,
	dataTop,
	returnStackIsEmpty,
	Stacks,
	withStacks;
import test.testUtil : expectDataStack, Test;
import util.col.array : arraysEqual;

void testStack(ref Test test) {
	testPushPop(test);
	testDataReturn(test);
}

private:

@trusted void testPushPop(ref Test test) {
	withStacks!void((ref Stacks stacks) { testPushPop(test, stacks); });
}

@system void testPushPop(ref Test test, Stacks a) {
	assert(dataStackIsEmpty(a));
	assert(returnStackIsEmpty(a));

	dataPush(a, 42);
	assert(dataPeek(a) == 42);
	assert(dataPop(a) == 42);
	assert(dataStackIsEmpty(a));

	ulong* begin = dataEnd(a);

	dataPush(a, 5);
	dataPush(a, 6);
	expectDataStack(test, a, [5, 6]);

	dataPush(a, 7);
	assert(dataTop(a) == begin + 2);
	assert(dataEnd(a) == begin + 3);

	scope immutable ulong[] popped = dataPopN(a, 2);
	assert(arraysEqual(popped, [6, 7]));
	expectDataStack(test, a, [5]);

	dataPush(a, 8);
	dataPush(a, 9);
	expectDataStack(test, a, [5, 8, 9]);
	ulong removed = dataRemove(a, 1);
	assert(removed == 8);
	expectDataStack(test, a, [5, 9]);

	dataPush(a, 11);
	dataPush(a, 13);

	expectDataStack(test, a, [5, 9, 11, 13]);

	dataReturn(a, 2, 1);
	expectDataStack(test, a, [5, 13]);

	assert(dataPop(a) == 13);
	assert(dataPop(a) == 5);
	assert(dataStackIsEmpty(a));
	assert(returnStackIsEmpty(a));
}

@trusted void testDataReturn(ref Test test) {
	withStacks!void((ref Stacks stacks) { testDataReturn(test, stacks); });
}

@system void testDataReturn(ref Test test, Stacks a) {
	foreach (ulong i; [1, 2, 3, 4, 5, 6])
		dataPush(a, i);

	dataReturn(a, 0, 0);
	expectDataStack(test, a, [1, 2, 3, 4, 5]);

	dataReturn(a, 3, 2);
	expectDataStack(test, a, [1, 4, 5]);

	dataReturn(a, 2, 0);
	expectDataStack(test, a, []);
}
