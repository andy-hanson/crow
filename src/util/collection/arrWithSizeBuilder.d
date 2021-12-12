module util.collection.arrWithSizeBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes, freeBytesPartial;
import util.collection.arr : ArrWithSize, emptyArrWithSize;
import util.memory : initMemory;
import util.util : verify;

struct ArrWithSizeBuilder(T) {
	private:
	ubyte* data_ = null;
	size_t size_ = 0;
	size_t capacity_ = 0;
}

private @system T* begin(T)(ref ArrWithSizeBuilder!T a) {
	return cast(T*) (a.data_ + size_t.sizeof);
}
private @system const(T*) begin(T)(ref const ArrWithSizeBuilder!T a) {
	return cast(const T*) (a.data_ + size_t.sizeof);
}

@trusted void add(T)(ref Alloc alloc, ref ArrWithSizeBuilder!T a, immutable T value) {
	if (a.size_ == a.capacity_) {
		const ubyte* oldData = a.data_;
		a.capacity_ = a.capacity_ == 0 ? 4 : a.capacity_ * 2;
		a.data_ = allocateBytes(alloc, size_t.sizeof + T.sizeof * a.capacity_);
		foreach (immutable size_t i; 0 .. a.size_)
			initMemory(begin(a) + i, (cast(immutable T*) (oldData + size_t.sizeof))[i]);
	}
	verify(a.size_ < a.capacity_);
	initMemory(begin(a) + a.size_, value);
	a.size_ += 1;
}

immutable(bool) arrWithSizeBuilderIsEmpty(T)(ref const ArrWithSizeBuilder!T a) {
	return a.size_ == 0;
}

@trusted immutable(ArrWithSize!T) finishArrWithSize(T)(ref Alloc alloc, ref ArrWithSizeBuilder!T a) {
	if (a.data_ == null)
		return emptyArrWithSize!T;
	else {
		freeBytesPartial(alloc, cast(ubyte*) (begin(a) + a.size_), a.capacity_ - a.size_);
		*(cast(size_t*) a.data_) = a.size_;
		return immutable ArrWithSize!T(cast(immutable) a.data_);
	}
}
