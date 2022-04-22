module test.testStack;

@safe @nogc nothrow: // not pure

import interpret.stacks :
	dataEnd,
	dataPeek,
	dataPop,
	dataPopN,
	dataPush,
	dataRemove,
	dataRemoveN,
	dataStackIsEmpty,
	dataTempAsArr,
	dataTop,
	returnStackIsEmpty,
	Stacks,
	withStacks;
import test.testUtil : Test;
import util.col.arrUtil : arrEqual;
import util.util : verify;

void testStack(ref Test test) {
	testPushPop(test);
	testRemoveN(test);
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
	verifyData(a, [5, 6]);

	dataPush(a, 7);
	verify(dataTop(a) == begin + 2);
	verify(dataEnd(a) == begin + 3);

	scope immutable ulong[] popped = dataPopN(a, 2);
	verify(dataArrEqual(popped, [6, 7]));
	verifyData(a, [5]);

	dataPush(a, 8);
	dataPush(a, 9);
	verifyData(a, [5, 8, 9]);
	immutable ulong removed = dataRemove(a, 1);
	verify(removed == 8);
	verifyData(a, [5, 9]);

	dataPush(a, 11);
	dataPush(a, 13);

	verifyData(a, [5, 9, 11, 13]);

	dataRemoveN(a, 2, 2);
	verifyData(a, [5, 13]);

	verify(dataPop(a) == 13);
	verify(dataPop(a) == 5);
	verify(dataStackIsEmpty(a));
	verify(returnStackIsEmpty(a));
}

@trusted void testRemoveN(ref Test test) {
	withStacks!void((ref Stacks stacks) { testPushPop(test, stacks); });
}

@system void testRemoveN(ref Test test, Stacks a) {
	foreach (immutable int i; [1, 2, 3, 4, 5, 6])
		dataPush(a, i);

	dataRemoveN(a, 0, 1);
	verifyData(a, [1, 2, 3, 4, 5]);

	dataRemoveN(a, 3, 2);
	verifyData(a, [1, 4, 5]);

	dataRemoveN(a, 2, 3);
	verifyData(a, []);
}

@trusted void verifyData(ref Stacks a, scope immutable ulong[] expected) {
	verify(dataArrEqual(dataTempAsArr(a), expected));
}

immutable(bool) dataArrEqual(scope immutable ulong[] a, scope immutable ulong[] b) {
	return arrEqual!(immutable ulong)(a, b, (ref immutable ulong x, ref immutable ulong y) => x == y);
}
