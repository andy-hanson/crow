module util.collection.mutArr;

@safe @nogc pure nothrow:

import core.stdc.string : memcpy;

import util.collection.arr : Arr;
import util.memory : myEmplace;

struct MutArr(T, Alloc) {
	private:
	Alloc alloc_;
	T* begin_;
	size_t size_;
	size_t capacity_;
}

@trusted void push(T, Alloc)(ref MutArr!(T, Alloc) a, T value) {
	if (a.size_ == a.capacity_) {
		immutable size_t newCapacity = a.size_ == 0 ? 2 : a.size_ * 2;
		T* newBegin = cast(T*) a.alloc_.allocate(newCapacity * T.sizeof);
		memcpy(cast(void*) newBegin, cast(void*) a.begin_, a.size_ * T.sizeof);
		a.alloc_.free(cast(byte*) a.begin_, a.size_ * T.sizeof);
		a.begin_ = newBegin;
		a.capacity_ = newCapacity;
	}

	myEmplace(a.begin_ + a.size_, value);
	a.size_++;
	assert(a.size_ <= a.capacity_);
}

@trusted void setAt(T, Alloc)(ref MutArr!(T, Alloc) a, immutable size_t index, T value) {
	assert(index < a.size_);
	a.begin_[index] = value;
}

@trusted const(T[]) range(T, Alloc)(ref const MutArr!(T, Alloc) a) {
	return a.begin_[0..a.size_];
}

immutable(Arr!T) moveToArr(T)(ref MutArr!(T, Alloc) a) {
	static assert(__traits(isPOD, T));
	Arr!T res = immutable Arr!T(cast(immutable) a.begin_, a.size_);
	a.allocator.freePartial(a.begin_ + a.size, capacity - a.size_);
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return res;
}

@trusted ref const(T) last(T, Alloc)(ref const MutArr!(T, Alloc) a) {
	assert(a.size_ != 0);
	return a.begin_[a.size_ - 1];
}

MutArr!(T, Alloc) newUninitializedMutArr(T, Alloc)(ref Alloc alloc, immutable size_t size) {
	return MutArr(alloc, alloc.allocate(T.sizeof * size), size, size);
}
