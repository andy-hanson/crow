module interpret.realExtern;

@safe @nogc nothrow: // not pure

import core.sys.linux.sys.sysinfo : get_nprocs;
import core.sys.posix.unistd : posixUsleep = usleep, posixWrite = write;

import interpret.allocTracker : AllocTracker;
import util.alloc.mallocator : Mallocator;
import util.bools : Bool;
import util.collection.mutDict : mustDelete;
import util.ptr : PtrRange;
import util.writer : Writer;

// TODO: maybe use dlsym
// https://linux.die.net/man/3/dlsym

struct RealExtern {
	@safe @nogc nothrow: // not pure

	Mallocator alloc;
	AllocTracker allocTracker;

	// TODO: not trusted
	@trusted pure void free(ubyte* ptr) {
		immutable size_t size = allocTracker.markFree(ptr);
		alloc.free(ptr, size);
	}

	// TODO: not trusted
	@trusted pure ubyte* malloc(immutable size_t size) {
		ubyte* ptr = alloc.allocate(size);
		allocTracker.markAlloced(alloc, ptr, size);
		return ptr;
	}

	@system long write(int fd, immutable char* buf, immutable size_t nBytes) const {
		return posixWrite(fd, buf, nBytes);
	}

	immutable(size_t) getNProcs() const {
		// TODO: interpreter needs to support multiple threads
		return 1;
	}

	immutable(size_t) pthreadYield() const {
		// We don't support launching other threads, so do nothing
		return 0;
	}

	void usleep(immutable size_t microseconds) {
		posixUsleep(cast(uint) microseconds);
	}

	immutable(Bool) hasMallocedPtr(ref const PtrRange range) const {
		return allocTracker.hasAllocedPtr(range);
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		allocTracker.writeMallocedRanges!WriterAlloc(writer);
	}
}
