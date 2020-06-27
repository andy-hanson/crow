module util.collection.mutArr;

@safe @nogc pure nothrow:

import core.stdc.string : memcpy;

import util.collection.arr : Arr;
import util.memory : initMemory;

struct MutArr(T) {
	private:
	T* begin_;
	size_t size_;
	size_t capacity_;
}

ref const(T) mutArrAt(T)(ref const MutArr!T a, immutable size_t index) {
	assert(index < a.size_);
	return a.begin[index];
}

immutable(size_t) mutArrSize(T)(ref const MutArr!T a) {
	return a.size_;
}

immutable(Bool) mutArrIsEmpty(T)(ref const MutArr!T a) {
	return a.size_ == 0;
}

@trusted void push(T, Alloc)(ref MutArr!T a, ref Alloc alloc, immutable T value) {
	if (a.size_ == a.capacity_) {
		immutable size_t newCapacity = a.size_ == 0 ? 2 : a.size_ * 2;
		T* newBegin = cast(T*) alloc.allocate(newCapacity * T.sizeof);
		memcpy(cast(void*) newBegin, cast(void*) a.begin_, a.size_ * T.sizeof);
		alloc.free(cast(ubyte*) a.begin_, a.size_ * T.sizeof);
		a.begin_ = newBegin;
		a.capacity_ = newCapacity;
	}

	initMemory(a.begin_ + a.size_, value);
	a.size_++;
	assert(a.size_ <= a.capacity_);
}

@trusted void setAt(T)(ref MutArr!T a, immutable size_t index, T value) {
	assert(index < a.size_);
	a.begin_[index] = value;
}

@trusted const(T[]) range(T)(ref const MutArr!T a) {
	return a.begin_[0..a.size_];
}

@trusted T[] rangeMut(T)(ref MutArr!T a) {
	return a.begin_[0..a.size_];
}

@trusted immutable(Arr!T) moveToArr(T, Alloc)(ref MutArr!T a, ref Alloc alloc) {
	static assert(__traits(isPOD, T));
	Arr!T res = Arr!T(a.begin_, a.size_);
	alloc.freePartial(cast(ubyte*) (a.begin_ + a.size_), T.sizeof * (a.capacity_ - a.size_));
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return cast(immutable) res;
}

@trusted ref const(T) last(T)(ref const MutArr!T a) {
	assert(a.size_ != 0);
	return a.begin_[a.size_ - 1];
}

@system MutArr!T newUninitializedMutArr(T, Alloc)(ref Alloc alloc, immutable size_t size) {
	return MutArr!T(cast(T*) alloc.allocate(T.sizeof * size), size, size);
}

ref const(Arr!T) tempAsArr(T)(ref const MutArr!T m) {
	return const Arr!T(m.begin, m.size);
}
