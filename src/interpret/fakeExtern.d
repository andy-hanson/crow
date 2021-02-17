module interpret.fakeExtern;

@safe @nogc pure nothrow:

import interpret.allocTracker : AllocTracker, hasAllocedPtr, markAlloced, markFree, writeMarkedAllocedRanges;
import interpret.bytecode : DynCallType, TimeSpec;
import util.alloc.alloc : allocateBytes, freeBytes;
import util.collection.mutArr : clear, moveToArr, MutArr, pushAll;
import util.collection.str : NulTerminatedStr;
import util.ptr : Ptr, PtrRange;
import util.types : Nat64;
import util.util : todo, verify;
import util.writer : Writer;

struct FakeExtern(Alloc) {
	@safe @nogc pure nothrow:

	@disable this(ref const FakeExtern);
	this(Ptr!Alloc a) { alloc = a; }

	private:
	Ptr!Alloc alloc;
	AllocTracker allocTracker;
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
	uint monoTime = 0;

	public:
	~this() {
		// TODO:
		// verify(mutDictIsEmpty(allocations));
		// (Need GC to work first..)
	}

	immutable(int) clockGetTime(immutable int clockId, Ptr!TimeSpec timespec) {
		if (clockId == 1) {
			timespec.deref() = immutable TimeSpec(monoTime, 0);
			monoTime++;
			return 0;
		} else
			return todo!int("!");
	}

	//TODO: not @trusted
	@trusted void free(ubyte* ptr) {
		immutable size_t size = markFree(allocTracker, ptr);
		freeBytes(alloc.deref(), ptr, size);
	}

	//TODO: not @trusted
	@trusted ubyte* malloc(immutable size_t size) {
		ubyte* ptr = allocateBytes(alloc.deref(), size);
		markAlloced(alloc.deref(), allocTracker, ptr, size);
		return ptr;
	}

	@trusted immutable(long) write(int fd, immutable char* buf, immutable size_t nBytes) {
		immutable char[] arr = buf[0 .. nBytes];
		verify(fd == 1 || fd == 2);
		pushAll!(char, Alloc)(alloc.deref(), fd == 1 ? stdout : stderr, arr);
		return nBytes;
	}

	immutable(string) moveStdout() {
		return moveToArr(alloc.deref(), stdout);
	}

	immutable(string) moveStderr() {
		return moveToArr(alloc.deref(), stderr);
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

	immutable(bool) hasMallocedPtr(ref const PtrRange range) const {
		return hasAllocedPtr(allocTracker, range);
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		writeMarkedAllocedRanges(writer, allocTracker);
	}

	immutable(Nat64) doDynCall(
		ref immutable NulTerminatedStr,
		immutable DynCallType,
		ref immutable Nat64[],
		ref immutable DynCallType[],
	) {
		return todo!(immutable Nat64)("not for fake");
	}
}

FakeExtern!Alloc newFakeExtern(Alloc)(Ptr!Alloc alloc) {
	return FakeExtern!Alloc(alloc);
}
