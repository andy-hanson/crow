module util.collection.mutSlice;

@safe @nogc pure nothrow:

import util.memory : overwriteMemory;
import util.util : verify;

struct MutSlice(T) {
	T* begin_;
	size_t size_;
}

immutable(size_t) mutSliceSize(T)(ref const MutSlice!T a) {
	return a.size_;
}

@trusted ref const(T) mutSliceAt(T)(return scope ref const MutSlice!T a, immutable size_t index) {
	verify(index < mutSliceSize(a));
	return a.begin_[index];
}

@trusted void mutSliceSetAt(T)(ref MutSlice!T a, immutable size_t index, immutable T value) {
	verify(index < mutSliceSize(a));
	overwriteMemory(a.begin_ + index, value);
}

@trusted MutSlice!T mutSlice(T)(MutSlice!T a, immutable size_t lo, immutable size_t newSize) {
	verify(lo + newSize <= mutSliceSize(a));
	return MutSlice!T(a.begin_ + lo, newSize);
}

MutSlice!T mutSlice(T)(MutSlice!T a, immutable size_t lo) {
	verify(lo <= mutSliceSize(a));
	return mutSlice(a, lo, mutSliceSize(a) - lo);
}

@trusted MutSlice!T newUninitializedMutSlice(T, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
) {
	return MutSlice!T(cast(T*) alloc.allocateBytes(T.sizeof * size), size);
}

@trusted const(T[]) mutSliceTempAsArr(T)(ref const MutSlice!T a) {
	return a.begin_[0..a.size_];
}

void mutSliceFill(T)(ref MutSlice!T a, immutable T value) {
	foreach (immutable size_t i; 0..mutSliceSize(a))
		mutSliceSetAt(a, i, value);
}
