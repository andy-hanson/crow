module test.testAlloc;

@safe @nogc nothrow: // not pure

import app.fileSystem : getNRandomBytes;
import test.testUtil : Test;
import util.alloc.alloc :
	Alloc,
	AllocAndValue,
	AllocKind,
	allocOwns,
	allocateElements,
	allocateUninitialized,
	assertOwns,
	finishAlloc,
	FinishedAlloc,
	freeAlloc,
	freeElements,
	MetaAlloc,
	newAlloc,
	withAlloc,
	withTempAlloc;
import util.col.arrUtil : every, makeArray;

void testAlloc(ref Test test) {
	testFreeAlloc(test);
	testFreeElements();
}

private:

// D's Random doesn't work with -betterC
struct Random {
	ubyte[0x1000] randomBytes;
	size_t i;
}
void initialize(ref Random a) {
	a.randomBytes = getNRandomBytes!0x1000();
}
pure ubyte nextByte(ref Random a) =>
	a.randomBytes[a.i++];
pure ushort nextShort(ref Random a) =>
	((cast(ushort) nextByte(a)) << 8) | nextByte(a);
pure bool nextBool(ref Random a) =>
	nextByte(a) >= 128;

void testFreeAlloc(ref Test test) {
	auto random = Random();
	initialize(random);

	withTempAlloc!void(test.metaAlloc, (ref Alloc setupAlloc) @trusted {
		ulong[] memory = allocateElements!ulong(setupAlloc, 0x1000000);
		MetaAlloc meta = MetaAlloc(memory);

		AllocAndValue!(ubyte[])[100] allocs;
		size_t[100] sizes;
		bool[100] freed;

		// We'll create 100 allocators. Fill each with 'i'. Then free every other one.
		foreach (size_t i; 0 .. allocs.length) {
			sizes[i] = nextShort(random);
			allocs[i] = withAlloc!(ubyte[])(AllocKind.test, &meta, (ref Alloc alloc) =>
				makeArray!ubyte(alloc, sizes[i], (size_t _) => cast(ubyte) i));
		}

		foreach (size_t i, ref AllocAndValue!(ubyte[]) alloc; allocs) {
			if (nextBool(random) == 1) {
				freed[i] = true;
				freeAlloc(alloc.alloc);
			}
		}

		foreach (size_t i; 0 .. 10) {
			size_t size = nextShort(random);
			withAlloc!(ubyte[])(AllocKind.test, &meta, (ref Alloc alloc) =>
				makeArray!ubyte(alloc, size, (size_t _) => cast(ubyte) i));
		}

		foreach (size_t i; 0 .. 100)
			if (!freed[i]) {
				assert(allocs[i].value.length == sizes[i]);
				assert(every!ubyte(allocs[i].value, (in ubyte x) => x == i));
			}
	});
}

@trusted void testFreeElements() {
	ulong[0x1000] memory = void;
	MetaAlloc meta = MetaAlloc(memory);
	Alloc* alloc = newAlloc(AllocKind.test, &meta);

	ulong* w0 = allocateUninitialized!ulong(*alloc);
	assertOwns(*alloc, w0[0 .. 1]);
	ulong testValue;
	assert(!allocOwns(*alloc, (&testValue)[0 .. 1]));

	ulong* w1 = allocateUninitialized!ulong(*alloc);
	assert(w1 == w0 + 1);
	freeElements(*alloc, w1[0 .. 1]);
	ulong* w2 = allocateUninitialized!ulong(*alloc);
	assert(w2 == w1);

	FinishedAlloc* finished = finishAlloc(alloc);
	freeAlloc(finished);
	//TODO: assert 'meta' is now empty again
}
