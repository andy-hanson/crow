module util.collection.mutArr;

@safe @nogc pure nothrow:

import std.traits : Unqual;

import core.stdc.string : memcpy;

import util.bools : Bool;
import util.collection.arr : Arr;
import util.memory : initMemory, overwriteMemory;
import util.opt : force, noneConst, noneMut, Opt, someConst, someMut;

struct MutArr(T) {
	private:
	T* begin_;
	size_t size_;
	size_t capacity_;
}

@system T* mutArrBegin(T)(ref MutArr!T a) {
	return a.begin_;
}

@trusted ref T mutArrAt(T)(ref MutArr!T a, immutable size_t index) {
	assert(index < a.size_);
	return a.begin_[index];
}
@trusted ref const(T) mutArrAt(T)(ref const MutArr!T a, immutable size_t index) {
	assert(index < a.size_);
	return a.begin_[index];
}

ref T mutArrFirst(T)(ref MutArr!T a) {
	return mutArrAt(a, 0);
}

immutable(size_t) mutArrSize(T)(ref const MutArr!T a) {
	return a.size_;
}

immutable(Bool) mutArrIsEmpty(T)(ref const MutArr!T a) {
	return Bool(a.size_ == 0);
}

@trusted void push(T, Alloc)(ref Alloc alloc, ref MutArr!T a, T value) {
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

@trusted Opt!T pop(T)(ref MutArr!T a) {
	if (a.size_ == 0)
		return noneMut!T;
	else {
		a.size_--;
		return someMut!T(a.begin_[a.size_]);
	}
}

T mustPop(T)(ref MutArr!T a) {
	Opt!T p = pop(a);
	return force(p);
}

@trusted const(Opt!T) peek(T)(ref MutArr!T m) {
	return mutArrIsEmpty(m)
		? noneConst!T
		: someConst(mustPeek(m));
}

@trusted ref const(T) mustPeek(T)(ref const MutArr!T m) {
	assert(m.size_ != 0);
	return m.begin_[m.size_ - 1];
}

@trusted ref T mustPeek_mut(T)(ref MutArr!T m) {
	assert(m.size_ != 0);
	return m.begin_[m.size_ - 1];
}

@trusted void setAt(T)(ref MutArr!T a, immutable size_t index, T value) {
	assert(index < a.size_);
	overwriteMemory(a.begin_ + index, value);
}

@trusted const(T[]) mutArrRange(T)(ref const MutArr!T a) {
	return a.begin_[0..a.size_];
}

@trusted T[] mutArrRangeMut(T)(ref MutArr!T a) {
	return a.begin_[0..a.size_];
}

@trusted immutable(Arr!T) moveToArr(T, Alloc)(ref Alloc alloc, ref MutArr!(immutable T) a) {
	immutable Arr!T res = immutable Arr!T(cast(immutable) a.begin_, a.size_);
	alloc.freePartial(cast(ubyte*) (a.begin_ + a.size_), T.sizeof * (a.capacity_ - a.size_));
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return res;
}

@trusted const(Arr!T) moveToArr_const(T, Alloc)(ref Alloc alloc, ref MutArr!T a) {
	const Arr!T res = const Arr!T(a.begin_, a.size_);
	alloc.freePartial(cast(ubyte*) (a.begin_ + a.size_), T.sizeof * (a.capacity_ - a.size_));
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return res;
}

@trusted ref const(T) last(T)(ref const MutArr!T a) {
	assert(a.size_ != 0);
	return a.begin_[a.size_ - 1];
}

@system MutArr!T newUninitializedMutArr(T, Alloc)(ref Alloc alloc, immutable size_t size) {
	return MutArr!T(cast(T*) alloc.allocate(T.sizeof * size), size, size);
}

const(Arr!T) tempAsArr(T)(ref const MutArr!T m) {
	return const Arr!T(m.begin_, m.size_);
}
Arr!T tempAsArr_mut(T)(ref MutArr!T m) {
	return Arr!T(m.begin_, m.size_);
}
