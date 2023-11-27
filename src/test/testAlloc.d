module test.testAlloc;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc :
	Alloc,
	allocOwns,
	allocateUninitialized,
	assertOwns,
	finishAlloc,
	FinishedAlloc,
	freeAlloc,
	freeElements,
	MetaAlloc,
	newAlloc;

@trusted void testAlloc(ref Test test) {
	ulong[0x1000] memory = void;
	MetaAlloc meta = MetaAlloc(memory);
	Alloc alloc = newAlloc(&meta);

	ulong* w0 = allocateUninitialized!ulong(alloc);
	assertOwns(alloc, w0[0 .. 1]);
	ulong testValue;
	assert(!allocOwns(alloc, (&testValue)[0 .. 1]));

	ulong* w1 = allocateUninitialized!ulong(alloc);
	assert(w1 == w0 + 1);
	freeElements(alloc, w1[0 .. 1]);
	ulong* w2 = allocateUninitialized!ulong(alloc);
	assert(w2 == w1);

	FinishedAlloc finished = finishAlloc(alloc);
	freeAlloc(finished);
	//TODO: assert 'meta' is now empty again
}
