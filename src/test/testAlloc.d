module test.testAlloc;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc :
	Alloc,
	allocOwns,
	allocateUninitialized,
	finishAlloc,
	FinishedAlloc,
	freeAlloc,
	freeElements,
	MetaAlloc,
	newAlloc,
	verifyOwns;
import util.util : verify;

@trusted void testAlloc(ref Test test) {
	ulong[0x1000] memory = void;
	MetaAlloc meta = MetaAlloc(memory);
	Alloc alloc = newAlloc(&meta);

	ulong* w0 = allocateUninitialized!ulong(alloc);
	verifyOwns(alloc, w0[0 .. 1]);
	ulong testValue;
	verify(!allocOwns(alloc, (&testValue)[0 .. 1]));

	ulong* w1 = allocateUninitialized!ulong(alloc);
	verify(w1 == w0 + 1);
	freeElements(alloc, w1[0 .. 1]);
	ulong* w2 = allocateUninitialized!ulong(alloc);
	verify(w2 == w1);

	FinishedAlloc finished = finishAlloc(alloc);
	freeAlloc(finished);
	//TODO: assert 'meta' is now empty again
}
