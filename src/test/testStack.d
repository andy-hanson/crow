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
import util.col.arrUtil : arrEqual;
import util.util : verify;

void testStack(ref Test test) {
	testPushPop(test);
	testDataReturn(test);
}

private:

@trusted void testPushPop(ref Test test) {
	withStacks!void((ref Stacks stacks) { testPushPop(test, stacks); });
}

@system void testPushPop(ref Test test, Stacks a) {
	verify(dataStackIsEmpty(a));
	verify(returnStackIsEmpty(a));

	dataPush(a, 42);
	verify(dataPeek(a) == 42);
	verify(dataPop(a) == 42);
	verify(dataStackIsEmpty(a));

	ulong* begin = dataEnd(a);

	dataPush(a, 5);
	dataPush(a, 6);
	expectDataStack(test, a, [5, 6]);

	dataPush(a, 7);
	verify(dataTop(a) == begin + 2);
	verify(dataEnd(a) == begin + 3);

	scope immutable ulong[] popped = dataPopN(a, 2);
	verify(arrEqual(popped, [6, 7]));
	expectDataStack(test, a, [5]);

	dataPush(a, 8);
	dataPush(a, 9);
	expectDataStack(test, a, [5, 8, 9]);
	ulong removed = dataRemove(a, 1);
	verify(removed == 8);
	expectDataStack(test, a, [5, 9]);

	dataPush(a, 11);
	dataPush(a, 13);

	expectDataStack(test, a, [5, 9, 11, 13]);

	dataReturn(a, 2, 1);
	expectDataStack(test, a, [5, 13]);

	verify(dataPop(a) == 13);
	verify(dataPop(a) == 5);
	verify(dataStackIsEmpty(a));
	verify(returnStackIsEmpty(a));
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
