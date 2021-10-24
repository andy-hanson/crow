module interpret.allocTracker;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.arrUtil : exists_const;
import util.collection.dict : KeyValuePair;
import util.collection.mutDict : addToMutDict, mustDelete, MutDict, tempPairs;
import util.ptr : comparePtrRaw, contains, PtrRange;
import util.writer : Writer, writePtrRange, writeStatic;

struct AllocTracker {
	@safe @nogc pure nothrow:

	private:
	@disable this(ref const AllocTracker);
	MutDict!(const ubyte*, immutable size_t, comparePtrRaw!ubyte) allocations;
}

void markAlloced(ref Alloc alloc, ref AllocTracker a, const ubyte* ptr, immutable size_t size) {
	addToMutDict(alloc, a.allocations, ptr, size);
}

immutable(size_t) markFree(ref AllocTracker a, const ubyte* ptr) {
	return mustDelete(a.allocations, ptr);
}

immutable(bool) hasAllocedPtr(ref const AllocTracker a, ref const PtrRange range) {
	return exists_const!(KeyValuePair!(const ubyte*, immutable size_t))(
		tempPairs(a.allocations),
		(ref const KeyValuePair!(const ubyte*, immutable size_t) pair) =>
			ptrInRange(pair, range));
}

@trusted void writeMarkedAllocedRanges(ref Writer writer, ref const AllocTracker a) {
	bool first = true;
	foreach (ref const KeyValuePair!(const ubyte*, immutable size_t) pair; tempPairs(a.allocations)) {
		if (first)
			first = false;
		else
			writeStatic(writer, ", ");
		writePtrRange(writer, const PtrRange(pair.key, pair.key + pair.value));
	}
}

private:

@trusted immutable(bool) ptrInRange(
	ref const KeyValuePair!(const ubyte*, immutable size_t) pair,
	ref const PtrRange range,
) {
	return contains(const PtrRange(pair.key, pair.key + pair.value), range);
}
