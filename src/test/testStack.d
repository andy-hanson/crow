module test.testStack;

@safe @nogc nothrow: // not pure

import interpret.stacks :
	dataBegin,
	dataDropN,
	dataPeek,
	dataPop,
	dataPopAndSet,
	dataPopAndWriteToPtr,
	dataPopN,
	dataPush,
	dataPushRef,
	dataReadAndPush,
	dataRemove,
	dataRemoveN,
	dataStackIsEmpty,
	dataTempAsArr,
	returnStackIsEmpty,
	Stacks,
	withStacks;
import test.testUtil : expectDataStack, Test;
import util.col.arrUtil : arrEqual;
import util.conv : ulongOfBytes;
import util.util : verify;

@trusted void testStack(ref Test test) {
	testDataPopAndSet(test);
	testRemoveN(test);
	testDataPopAndWriteToPtr(test);
	testDataPushPop(test);
	testDataReadAndPush(test);
	testStackRef(test);
}

private:
@system:

void stackTest(void delegate(ref Test, ref Stacks) @nogc nothrow cb)(ref Test test) {
	withStacks!void((ref Stacks stacks) { cb(test, stacks); });
}

alias testDataPopAndSet = stackTest!((ref Test test, ref Stacks a) {
	dataPush(a, [1, 2, 3, 4, 5]);
	dataPopAndSet(a, 3, 2);
	expectDataStackAndClear(test, a, [1, 4, 5]);
});

alias testDataPopAndWriteToPtr = stackTest!((ref Test test, ref Stacks a) {
	ulong writeTo;
	dataPush(a, cast(immutable ulong) &writeTo);
	dataPush(a, 7);
	dataPopAndWriteToPtr(a, 0, 8);
	expectDataStack(test, a, []);
	verify(writeTo == 7);
});

alias testDataPushPop = stackTest!((ref Test test, ref Stacks a) {
	verify(dataStackIsEmpty(a));
	verify(returnStackIsEmpty(a));

	dataPush(a, 42);
	verify(dataPeek(a) == 42);
	verify(dataPop(a) == 42);
	verify(dataStackIsEmpty(a));

	dataPush(a, 5);
	dataPush(a, [6, 7]);
	expectDataStack(test, a, [5, 6, 7]);

	scope immutable ulong[] popped = dataPopN(a, 2);
	verify(dataArrEqual(popped, [6, 7]));
	expectDataStack(test, a, [5]);

	dataPush(a, 8);
	dataPush(a, 9);
	expectDataStack(test, a, [5, 8, 9]);
	immutable ulong removed = dataRemove(a, 1);
	verify(removed == 8);
	expectDataStack(test, a, [5, 9]);

	dataPush(a, 11);
	dataPush(a, 13);

	expectDataStack(test, a, [5, 9, 11, 13]);

	dataRemoveN(a, 2, 2);
	expectDataStack(test, a, [5, 13]);

	verify(dataPop(a) == 13);
	verify(dataPop(a) == 5);
	verify(dataStackIsEmpty(a));
	verify(returnStackIsEmpty(a));
});

alias testDataReadAndPush = stackTest!((ref Test test, ref Stacks a) {
	ubyte[5] byteData = [1, 2, 3, 4, 5];
	dataReadAndPush(a, &byteData[1], 3);
	expectDataStackAndClear(test, a, [ulongOfBytes([2, 3, 4, 0, 0, 0, 0, 0])]);

	ulong[5] longData = [1, 2, 3, 4, 5];
	dataReadAndPush(a, cast(ubyte*) &longData[1], 3 * ulong.sizeof);
	expectDataStackAndClear(test, a, [2, 3, 4]);
});

alias testRemoveN = stackTest!((ref Test test, ref Stacks a) {
	dataPush(a, [1, 2, 3, 4, 5, 6]);

	dataRemoveN(a, 0, 1);
	expectDataStack(test, a, [1, 2, 3, 4, 5]);

	dataRemoveN(a, 3, 2);
	expectDataStack(test, a, [1, 4, 5]);

	dataRemoveN(a, 2, 3);
	expectDataStack(test, a, []);
});

alias testStackRef = stackTest!((ref Test test, ref Stacks a) {
	dataPush(a, [1, 2, 3, 4]);
	dataPushRef(a, 1);
	verify(*(cast(const ulong*) dataPeek(a)) == 3);
	expectDataStackAndClear(test, a, [1, 2, 3, 4, cast(immutable ulong) (dataBegin(a) + 2)]);
});

void expectDataStackAndClear(ref Test test, ref Stacks a, scope immutable ulong[] expected) {
	expectDataStack(test, a, expected);
	dataDropN(a, expected.length);
}

immutable(bool) dataArrEqual(scope immutable ulong[] a, scope immutable ulong[] b) {
	return arrEqual!(immutable ulong)(a, b, (ref immutable ulong x, ref immutable ulong y) => x == y);
}
