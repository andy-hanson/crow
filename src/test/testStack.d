module test.testStack;

@safe @nogc nothrow: // not pure

import test.testUtil : Test;
import util.collection.arrUtil : arrEqual;
import util.collection.stack :
	asTempArr,
	peek,
	pop,
	popN,
	push,
	remove,
	setToArr,
	Stack,
	stackEnd,
	stackIsEmpty,
	stackSize,
	stackTop;
import util.util : verify;

void testStack(ref Test test) {
	testPushPop(test);
	testRemove(test);
}

private:

@trusted void testPushPop(ref Test test) {
	Stack!int a = Stack!int(test.alloc, 8);

	verify(stackIsEmpty(a));
	push(a, 42);
	verify(peek(a) == 42);
	verify(stackSize(a) == 1);
	verify(pop(a) == 42);
	verify(stackIsEmpty(a));

	int* begin = stackEnd(a);

	push(a, 1);
	push(a, 2);
	verifyStack(a, [1, 2]);

	setToArr(a, [5, 6, 7]);
	verify(stackTop(a) == begin + 2);
	verify(stackEnd(a) == begin + 3);

	immutable int[] popped = popN(a, 2);
	verify(intArrEqual(popped, [6, 7]));
	verifyStack(a, [5]);

	push(a, 8);
	push(a, 9);
	immutable int removed = remove(a, 1);
	verify(removed == 8);
	verifyStack(a, [5, 9]);

	push(a, 11);
	push(a, 13);

	verifyStack(a, [5, 9, 11, 13]);

	remove(a, 2, 2);
	verifyStack(a, [5, 13]);

	verify(pop(a) == 13);
	verify(pop(a) == 5);
	verify(stackIsEmpty(a));
}

@trusted void testRemove(ref Test test) {
	Stack!int a = Stack!int(test.alloc, 8);

	setToArr(a, [1, 2, 3, 4, 5, 6]);

	remove(a, 0, 1);
	verifyStack(a, [1, 2, 3, 4, 5]);

	remove(a, 3, 2);
	verifyStack(a, [1, 4, 5]);

	remove(a, 2, 3);
	verifyStack(a, []);
}

void verifyStack(ref Stack!int a, scope immutable int[] expected) {
	verify(intArrEqual(asTempArr(a), expected));
}

immutable(bool) intArrEqual(scope immutable int[] a, scope immutable int[] b) {
	return arrEqual(a, b, (ref immutable int x, ref immutable int y) => x == y);
}
