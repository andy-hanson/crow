module interpret.fakeExtern;

@safe @nogc pure nothrow:

import interpret.bytecode : ExternOp;
import interpret.runBytecode : DataStack;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, asImmutable, range;
import util.collection.arrUtil : exists;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : clear, MutArr, pushAll, tempAsArr;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, mutDictIsEmpty, tempPairs;
import util.collection.str : Str;
import util.ptr : comparePtrRaw, contains, Ptr, PtrRange;
import util.types : u8;
import util.util : todo, verify;
import util.writer : writePtrRange, Writer, writeStatic;

struct FakeExtern(Alloc) {
	@safe @nogc pure nothrow:

	private:
	Ptr!Alloc alloc;
	MutDict!(u8*, immutable size_t, comparePtrRaw!u8) allocations;
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;

	public:
	~this() {
		verify(mutDictIsEmpty(allocations));
	}

	//TODO: not @trusted
	@trusted void free(u8* ptr) {
		immutable size_t size = mustDelete!(u8*, immutable size_t, comparePtrRaw!u8)(allocations, ptr);
		alloc.free(ptr, size);
		debug {
			import core.stdc.stdio : printf;
			printf("freed %p-%p\n", ptr, ptr + size);
		}
	}

	//TODO: not @trusted
	@trusted u8* malloc(immutable size_t size) {
		u8* ptr = alloc.allocate(size);
		addToMutDict(alloc, allocations, ptr, size);
		debug {
			import core.stdc.stdio : printf;
			printf("malloced %p-%p\n", ptr, ptr + size);
		}
		return ptr;
	}

	long write(int fd, immutable char* buf, immutable size_t nBytes) {
		immutable Arr!char arr = immutable Arr!char(buf, nBytes);
		verify(fd == 1 || fd == 2);
		pushAll!(char, Alloc)(alloc.deref(), fd == 1 ? stdout : stderr, arr);
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
		return exists(tempPairs(allocations), (ref const KeyValuePair!(u8*, immutable size_t) pair) =>
			ptrInRange(pair, range));
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		Bool first = True;
		foreach (ref const KeyValuePair!(u8*, immutable size_t) pair; range(tempPairs(allocations))) {
			if (first)
				first = False;
			else
				writeStatic(writer, ", ");
			writePtrRange(writer, const PtrRange(pair.key, pair.key + pair.value));
		}
	}
}

FakeExtern!Alloc newFakeExtern(Alloc)(Ptr!Alloc alloc) {
	return FakeExtern!Alloc(alloc);
}

private:

@trusted immutable(Bool) ptrInRange(ref const KeyValuePair!(u8*, immutable size_t) pair, ref const PtrRange range) {
	return contains(const PtrRange(pair.key, pair.key + pair.value), range);
}
