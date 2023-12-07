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
	MemorySummary,
	MetaAlloc,
	MetaMemorySummary,
	minFetchSizeWords,
	newAlloc,
	summarizeMemory,
	withAlloc,
	withTempAlloc,
	word;
import util.col.arrUtil : every, makeArray;
import util.ptr : ptrTrustMe;

void testAlloc(ref Test test) {
	testTempAlloc(test);
	testFreeAlloc(test);
	testFreeElements(test);
}

private:

void withTestMetaAlloc(ref Test test, in void delegate(MetaAlloc*) @safe @nogc pure nothrow cb) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc tempAlloc) {
		scope MetaAlloc meta = MetaAlloc((size_t sizeWords, size_t _) =>
			allocateElements!word(tempAlloc, sizeWords));
		cb(ptrTrustMe(meta));
	});
}

void testTempAlloc(ref Test test) {
	withTestMetaAlloc(test, (MetaAlloc* meta) {
		assertFreshMeta(*meta);

		withTempAlloc!void(meta, (ref Alloc temp) @trusted {
			allocateElements!ulong(temp, 1);
			assert(summarizeMemory(*meta).total.usedBytes == ulong.sizeof);
		});

		assertFreshMeta(*meta);
	});
}

pure void assertFreshMeta(in MetaAlloc meta) {
	MetaMemorySummary summary = summarizeMemory(meta);
	assert(summary.countFreeBlocks == 1);
	size_t overhead = 0x78;
	assert(summary.total == MemorySummary(0, 0, minFetchSizeWords * word.sizeof - overhead, overhead));
}

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
	withTestMetaAlloc(test, (MetaAlloc* meta) @trusted {
		AllocAndValue!(ubyte[])[100] allocs;
		size_t[100] sizes;
		bool[100] freed;

		// We'll create 100 allocators. Fill each with 'i'. Then free every other one.
		foreach (size_t i; 0 .. allocs.length) {
			sizes[i] = nextShort(random);
			allocs[i] = withAlloc!(ubyte[])(AllocKind.test, meta, (ref Alloc alloc) =>
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
			withAlloc!(ubyte[])(AllocKind.test, meta, (ref Alloc alloc) =>
				makeArray!ubyte(alloc, size, (size_t _) => cast(ubyte) i));
		}

		foreach (size_t i; 0 .. 100)
			if (!freed[i]) {
				assert(allocs[i].value.length == sizes[i]);
				assert(every!ubyte(allocs[i].value, (in ubyte x) => x == i));
			}
	});
}

@trusted void testFreeElements(ref Test test) {
	withTestMetaAlloc(test, (MetaAlloc* meta) @trusted {
		assertFreshMeta(*meta);

		Alloc* alloc = newAlloc(AllocKind.test, meta);

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

		assertFreshMeta(*meta);
	});
}
