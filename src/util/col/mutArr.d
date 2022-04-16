module util.col.mutArr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT, freeT, freeTPartial;
import util.conv : safeToSizeT;
import util.memory : initMemory_mut, memcpy, overwriteMemory;
import util.util : verify;

struct MutArr(T) {
	private:
	T* begin_;
	size_t size_;
	size_t capacity_;

	public:
	@trusted void opIndexAssign(T value, immutable ulong index) {
		verify(index < size_);
		overwriteMemory(begin_ + safeToSizeT(index), value);
	}
}

@system T* mutArrPtrAt(T)(ref MutArr!T a, immutable size_t index) {
	verify(index < a.size_);
	return a.begin_ + index;
}
static if (!is(size_t == ulong)) {
	@system T* mutArrPtrAt(T)(ref MutArr!T a, immutable ulong index) {
		return mutArrPtrAt(a, safeToSizeT(index));
	}
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

@system T* mutArrEnd(T)(ref MutArr!T a) {
	return a.begin_ + a.size_;
}

@trusted void push(T)(scope ref Alloc alloc, scope ref MutArr!T a, T value) {
	if (a.size_ == a.capacity_) {
		immutable size_t newCapacity = a.size_ == 0 ? 2 : a.size_ * 2;
		T* newBegin = allocateT!T(alloc, newCapacity);
		memcpy(cast(ubyte*) newBegin, cast(ubyte*) a.begin_, a.size_ * T.sizeof);
		freeT(alloc, a.begin_, a.size_);
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

void mutArrClear(T)(ref MutArr!T a) {
	a.size_ = 0;
}

@trusted T mustPop(T)(ref MutArr!T a) {
	verify(a.size_ != 0);
	a.size_--;
	return a.begin_[a.size_];
}

@trusted const(T[]) mutArrRange(T)(ref const MutArr!T a) {
	return a.begin_[0 .. a.size_];
}

@trusted immutable(T[]) moveToArr(T)(ref Alloc alloc, scope ref MutArr!(immutable T) a) {
	return cast(immutable) moveToArr_mut(alloc, a);
}
@trusted T[] moveToArr_mut(T)(ref Alloc alloc, ref MutArr!T a) {
	T[] res = a.begin_[0 .. a.size_];
	freeTPartial(alloc, a.begin_ + a.size_, a.capacity_ - a.size_);
	a.begin_ = null;
	a.size_ = 0;
	a.capacity_ = 0;
	return res;
}

@trusted const(T[]) tempAsArr(T)(ref const MutArr!T a) {
	return a.begin_[0 .. a.size_];
}
@trusted T[] tempAsArr_mut(T)(ref MutArr!T a) {
	return a.begin_[0 .. a.size_];
}
