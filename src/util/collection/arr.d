module util.collection.arr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.memory : myEmplace;

struct Arr(T) {
	private:
	T* begin_;
	immutable size_t size_;
}

immutable(Arr!T) arrOfRange(T)(immutable T* begin, immutable T* end) {
	assert(begin <= end);
	return immutable Arr!T(begin, end - begin);
}

immutable(Arr!T) emptyArr(T)() {
	return immutable Arr!T(null, 0);
}

@system immutable(T*) begin(T)(ref immutable Arr!T a) {
	return a.begin_;
}

immutable(size_t) size(T)(immutable Arr!T a) {
	return a.size_;
}

immutable(Bool) sizeEq(T, U)(ref immutable Arr!T a, ref immutable Arr!U b) {
	return Bool(a.size == b.size);
}

immutable(Bool) empty(T)(ref immutable Arr!T a) {
	return Bool(a.size == 0);
}

@trusted ref immutable(T) at(T)(ref immutable Arr!T a, immutable size_t index) {
	assert(index < a.size_);
	return a.begin_[index];
}

ref immutable(T) first(T)(ref immutable Arr!T a) {
	return a.at(0);
}

ref immutable(T) only(T)(ref immutable Arr!T a) {
	assert(a.size == 1);
	return a.first;
}

ref immutable(T) last(T)(ref immutable Arr!T a) {
	assert(a.size != 0);
	return a.at(a.size - 1);
}

@trusted immutable(Arr!T) slice(T)(ref immutable Arr!T a, immutable size_t begin, immutable size_t newSize) {
	assert(begin + newSize <= a.size_);
	return immutable Arr!T(a.begin_ + begin, newSize);
}

immutable(Arr!T) slice(T)(ref immutable Arr!T a, immutable size_t begin) {
	assert(begin <= a.size_);
	return a.slice(begin, a.size_ - begin);
}

immutable(Arr!T) tail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return a.slice(1);
}

immutable(Arr!T) rtail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return a.slice(0, a.size - 1);
}

@trusted immutable(T[]) range(T)(immutable Arr!T a) {
	return a.begin_[0..a.size_];
}
