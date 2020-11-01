module interpret.fakeExtern;

@safe @nogc pure nothrow:

import interpret.allocTracker : AllocTracker;
import util.bools : Bool;
import util.collection.arr : Arr, asImmutable, range;
import util.collection.mutArr : clear, MutArr, pushAll, tempAsArr;
import util.collection.str : Str;
import util.ptr : Ptr, PtrRange;
import util.util : todo, verify;
import util.writer : Writer;

struct FakeExtern(Alloc) {
	@safe @nogc pure nothrow:

	private:
	Ptr!Alloc alloc;
	AllocTracker allocTracker;
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;

	public:
	~this() {
		// TODO:
		// verify(mutDictIsEmpty(allocations));
		// (Need GC to work first..)
	}

	//TODO: not @trusted
	@trusted void free(ubyte* ptr) {
		immutable size_t size = allocTracker.markFree(ptr);
		alloc.free(ptr, size);
	}

	//TODO: not @trusted
	@trusted ubyte* malloc(immutable size_t size) {
		ubyte* ptr = alloc.allocate(size);
		allocTracker.markAlloced(alloc, ptr, size);
		return ptr;
	}

	long write(int fd, immutable char* buf, immutable size_t nBytes) {
		immutable Arr!char arr = immutable Arr!char(buf, nBytes);
		verify(fd == 1 || fd == 2);
		pushAll!(char, Alloc)(alloc.deref(), fd == 1 ? stdout : stderr, arr);
		debug {
			import core.stdc.stdio : printf;
			printf("WROTE TO %d: %.*s\n", fd, cast(int) nBytes, buf);
		}
		return nBytes;
	}

	immutable(Str) getStdoutTemp() const {
		return asImmutable(tempAsArr(stdout));
	}

	immutable(Str) getStderrTemp() const {
		return asImmutable(tempAsArr(stderr));
	}

	void clearOutput() {
		clear(stdout);
		clear(stderr);
	}

	immutable(size_t) getNProcs() const {
		return 1;
	}

	immutable(size_t) pthreadYield() const {
		// We don't support launching other threads, so do nothing
		return 0;
	}

	void usleep(immutable size_t microseconds) {
		todo!void("usleep");
	}

	immutable(Bool) hasMallocedPtr(ref const PtrRange range) const {
		return allocTracker.hasAllocedPtr(range);
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		allocTracker.writeMallocedRanges(writer);
	}
}

FakeExtern!Alloc newFakeExtern(Alloc)(Ptr!Alloc alloc) {
	return FakeExtern!Alloc(alloc);
}
