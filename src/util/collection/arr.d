module util.collection.arr;

@safe @nogc pure nothrow:

import util.memory : myEmplace;

struct Arr(T) {
	private:
	T* begin_;
	immutable size_t size_;
}

@trusted ref const(T) at(T)(ref const Arr!T a, immutable size_t index) {
	assert(index < a.size_);
	return a.begin_[index];
}

immutable(size_t) size(T)(const Arr!T a) {
	return a.size_;
}

ref const(T) first(T)(ref const Arr!T a) {
	return a.at(0);
}

ref const(T) last(T)(ref const Arr!T a) {
	assert(a.size != 0);
	return a.at(a.size - 1);
}

@trusted immutable(Arr!T) tail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return immutable Arr!T(a.begin_ + 1, a.size_ - 1);
}

@trusted immutable(T[]) range(T)(immutable Arr!T a) {
	return a.begin_[0..a.size_];
}
