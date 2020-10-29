module interpret.fakeExtern;

@safe @nogc pure nothrow:

import interpret.bytecode : ExternOp;
import interpret.runBytecode : DataStack;
import util.collection.arr : Arr, asImmutable;
import util.collection.mutArr : clear, MutArr, pushAll, tempAsArr;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, mutDictIsEmpty;
import util.collection.str : Str;
import util.ptr : comparePtrRaw, Ptr;
import util.types : u8;
import util.util : todo, verify;

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

	void free(u8* ptr) {
		immutable size_t size = mustDelete!(u8*, immutable size_t, comparePtrRaw!u8)(allocations, ptr);
		alloc.free(ptr, size);
	}

	u8* malloc(immutable size_t size) {
		u8* ptr = alloc.allocate(size);
		addToMutDict(alloc, allocations, ptr, size);
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
		return todo!(immutable size_t)("only 1 proc, so shouldn't be called");
	}

	void usleep(immutable size_t microseconds) {
		todo!void("usleep");
	}
}

FakeExtern!Alloc newFakeExtern(Alloc)(Ptr!Alloc alloc) {
	return FakeExtern!Alloc(alloc);
}

private:

