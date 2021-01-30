module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : ArrWithSize, begin, emptyArrWithSize;
import util.collection.mutArr : moveToArr, MutArr, mutArrIsEmpty, mutArrSize, push, pushAll;
import util.memory : initMemory;
import util.util : verify;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

void add(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void addAll(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable T[] value) {
	pushAll(alloc, a.data, value);
}

immutable(T[]) finishArr_immutable(T, Alloc)(ref Alloc alloc, ref ArrBuilder!(immutable T) a) {
	return moveToArr(alloc, a.data);
}

immutable(T[]) finishArr(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a) {
	return moveToArr(alloc, a.data);
}

immutable(Bool) arrBuilderIsEmpty(T)(ref const ArrBuilder!T a) {
	return mutArrIsEmpty(a.data);
}

immutable(size_t) arrBuilderSize(T)(ref const ArrBuilder!T a) {
	return mutArrSize(a.data);
}

//TODO:MOVE?
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

@trusted void add(T, Alloc)(ref Alloc alloc, ref ArrWithSizeBuilder!T a, immutable T value) {
	if (a.size_ == a.capacity_) {
		const ubyte* oldData = a.data_;
		a.capacity_ = a.capacity_ == 0 ? 4 : a.capacity_ * 2;
		a.data_ = alloc.allocateBytes(size_t.sizeof + T.sizeof * a.capacity_);
		foreach (immutable size_t i; 0..a.size_)
			initMemory(begin(a) + i, (cast(immutable T*) (oldData + size_t.sizeof))[i]);
	}
	verify(a.size_ < a.capacity_);
	initMemory(begin(a) + a.size_, value);
	a.size_ += 1;
}

immutable(size_t) arrWithSizeBuilderSize(T)(ref const ArrWithSizeBuilder!T a) {
	return a.size_;
}

@trusted immutable(T[]) arrWithSizeBuilderAsTempArr(T)(ref const ArrWithSizeBuilder!T a) {
	return cast(immutable) begin(a)[0..a.size_];
}

@trusted immutable(ArrWithSize!T) finishArr(T, Alloc)(ref Alloc alloc, ref ArrWithSizeBuilder!T a) {
	if (a.data_ == null)
		return emptyArrWithSize!T;
	else {
		alloc.freeBytesPartial(cast(ubyte*) (begin(a) + a.size_), a.capacity_ - a.size_);
		*(cast(size_t*) a.data_) = a.size_;
		return immutable ArrWithSize!T(cast(immutable) a.data_);
	}
}
