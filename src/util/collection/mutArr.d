module util.collection.mutArr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes, freeBytes, freeBytesPartial;
import util.memory : initMemory_mut, memcpy, overwriteMemory;
import util.opt : force, noneConst, noneMut, Opt, someConst, someMut;
import util.util : verify;

struct MutArr(T) {
	private:
	T* begin_;
	size_t size_;
	size_t capacity_;
}

@system MutArr!T newUninitializedMutArr(T)(ref Alloc alloc, immutable size_t size) {
	return MutArr!T(cast(T*) allocateBytes(alloc, T.sizeof * size), size, size);
}

@system T* mutArrPtrAt(T)(ref MutArr!T a, immutable size_t index) {
	verify(index < a.size_);
	return a.begin_ + index;
}

@trusted ref T mutArrAt(T)(ref MutArr!T a, immutable size_t index) {
	verify(index < a.size_);
	return a.begin_[index];
}
@trusted ref const(T) mutArrAt(T)(ref const MutArr!T a, immutable size_t index) {
	verify(index < a.size_);
	return a.begin_[index];
}

immutable(size_t) mutArrSize(T)(ref const MutArr!T a) {
	return a.size_;
}

immutable(bool) mutArrIsEmpty(T)(ref const MutArr!T a) {
	return a.size_ == 0;
}

void insert(T)(ref Alloc alloc, ref MutArr!T a, immutable size_t pos, T value) {
	push(alloc, a, value); // pushed value is arbitrary, we're about to overwrite it
	foreach_reverse (immutable size_t i; pos + 1 .. mutArrSize(a))
		setAt(a, i, mutArrAt(a, i - 1));
	setAt(a, pos, value);
}

@trusted void push(T)(ref Alloc alloc, scope ref MutArr!T a, T value) {
	if (a.size_ == a.capacity_) {
		immutable size_t newCapacity = a.size_ == 0 ? 2 : a.size_ * 2;
		T* newBegin = cast(T*) allocateBytes(alloc, newCapacity * T.sizeof);
		memcpy(cast(ubyte*) newBegin, cast(ubyte*) a.begin_, a.size_ * T.sizeof);
		freeBytes(alloc, cast(ubyte*) a.begin_, a.size_ * T.sizeof);
		a.begin_ = newBegin;
		a.capacity_ = newCapacity;
	}

	initMemory_mut!T(a.begin_ + a.size_, value);
	a.size_++;
	verify(a.size_ <= a.capacity_);
}

void pushAll(T)(ref Alloc alloc, ref MutArr!(immutable T) a, scope immutable T[] values) {
	foreach (ref immutable T value; values)
		push(alloc, a, value);
}

@trusted Opt!T pop(T)(ref MutArr!T a) {
	if (a.size_ == 0)
		return noneMut!T;
	else {
		a.size_--;
		return someMut!T(a.begin_[a.size_]);
	}
}

void clear(T)(ref MutArr!T a) {
	a.size_ = 0;
}

T mustPop(T)(ref MutArr!T a) {
	Opt!T p = pop(a);
	return force(p);
}

@trusted const(Opt!T) peek(T)(ref MutArr!T a) {
	return mutArrIsEmpty(a)
		? noneConst!T
		: someConst(a.begin_[a.size_ - 1]);
}

@trusted ref T mustPeek_mut(T)(ref MutArr!T a) {
	verify(a.size_ != 0);
	return a.begin_[a.size_ - 1];
}

@trusted void setAt(T)(ref MutArr!T a, immutable size_t index, T value) {
	verify(index < a.size_);
	overwriteMemory(a.begin_ + index, value);
}

@trusted const(T[]) mutArrRange(T)(ref const MutArr!T a) {
	return a.begin_[0 .. a.size_];
}

@trusted T[] mutArrRangeMut(T)(ref MutArr!T a) {
	return a.begin_[0 .. a.size_];
}

@trusted immutable(T[]) moveToArr(T)(ref Alloc alloc, ref MutArr!(immutable T) a) {
	immutable T[] res = cast(immutable) a.begin_[0 .. a.size_];
	freeBytesPartial(alloc, cast(ubyte*) (a.begin_ + a.size_), T.sizeof * (a.capacity_ - a.size_));
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return res;
}

@trusted ref T last(T)(ref MutArr!T a) {
	verify(a.size_ != 0);
	return a.begin_[a.size_ - 1];
}

@trusted const(T[]) tempAsArr(T)(ref const MutArr!T a) {
	return a.begin_[0 .. a.size_];
}
@trusted T[] tempAsArr_mut(T)(ref MutArr!T a) {
	return a.begin_[0 .. a.size_];
}
