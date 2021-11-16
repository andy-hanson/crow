module interpret.allocTracker;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, mutDictEach, mutDictExists;
import util.ptr : contains, hashPtrRaw, ptrEqualsRaw, PtrRange;
import util.writer : Writer, writePtrRange, writeStatic;

struct AllocTracker {
	@safe @nogc pure nothrow:

	private:
	@disable this(ref const AllocTracker);
	MutDict!(const ubyte*, immutable size_t, ptrEqualsRaw!ubyte, hashPtrRaw!ubyte) allocations;
}

void markAlloced(ref Alloc alloc, ref AllocTracker a, const ubyte* ptr, immutable size_t size) {
	addToMutDict(alloc, a.allocations, ptr, size);
}

immutable(size_t) markFree(ref AllocTracker a, const ubyte* ptr) {
	return mustDelete(a.allocations, ptr);
}

immutable(bool) hasAllocedPtr(ref const AllocTracker a, ref const PtrRange range) {
	return mutDictExists!(const ubyte*, immutable size_t, ptrEqualsRaw!ubyte, hashPtrRaw!ubyte)(
		a.allocations,
		(const ubyte* key, ref immutable size_t value) @trusted =>
			contains(const PtrRange(key, key + value), range));
}

@trusted void writeMarkedAllocedRanges(ref Writer writer, ref const AllocTracker a) {
	bool first = true;
	mutDictEach!(const ubyte*, immutable size_t, ptrEqualsRaw!ubyte, hashPtrRaw!ubyte)(
		a.allocations,
		(const ubyte* key, ref immutable size_t value) @trusted {
			if (first)
				first = false;
			else
				writeStatic(writer, ", ");
			writePtrRange(writer, const PtrRange(key, key + value));
		});
}
