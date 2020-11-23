module interpret.allocTracker;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : range;
import util.collection.arrUtil : exists_const;
import util.collection.dict : KeyValuePair;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, tempPairs;
import util.ptr : comparePtrRaw, contains, PtrRange;
import util.writer : Writer, writePtrRange, writeStatic;

struct AllocTracker {
	@safe @nogc pure nothrow:

	@disable this(ref const AllocTracker);

	MutDict!(const ubyte*, immutable size_t, comparePtrRaw!ubyte) allocations;

	immutable(size_t) markFree(const ubyte* ptr) {
		return mustDelete(allocations, ptr);
	}

	void markAlloced(Alloc)(ref Alloc alloc, const ubyte* ptr, immutable size_t size) {
		addToMutDict(alloc, allocations, ptr, size);
	}

	immutable(Bool) hasAllocedPtr(ref const PtrRange range) const {
		return exists_const(tempPairs(allocations), (ref const KeyValuePair!(const ubyte*, immutable size_t) pair) =>
			ptrInRange(pair, range));
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		Bool first = True;
		foreach (ref const KeyValuePair!(const ubyte*, immutable size_t) pair; range(tempPairs(allocations))) {
			if (first)
				first = False;
			else
				writeStatic(writer, ", ");
			writePtrRange(writer, const PtrRange(pair.key, pair.key + pair.value));
		}
	}
}

private:

@trusted immutable(Bool) ptrInRange(
	ref const KeyValuePair!(const ubyte*, immutable size_t) pair,
	ref const PtrRange range,
) {
	return contains(const PtrRange(pair.key, pair.key + pair.value), range);
}
