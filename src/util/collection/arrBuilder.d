module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, ArrWithSize, begin, emptyArrWithSize, range, size;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrIsEmpty, mutArrSize, push, pushAll, tempAsArr;
import util.memory : initMemory;
import util.util : verify;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

ref immutable(T) arrBuilderAt(T)(ref ArrBuilder!T a, immutable size_t index) {
	return mutArrAt(a.data, index);
}

void add(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void addAll(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable Arr!T value) {
	pushAll(alloc, a.data, value);
}

immutable(Arr!T) finishArr_immutable(T, Alloc)(ref Alloc alloc, ref ArrBuilder!(immutable T) a) {
	return moveToArr(alloc, a.data);
}

immutable(Arr!T) finishArr(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a) {
	return moveToArr(alloc, a.data);
}

immutable(Bool) arrBuilderIsEmpty(T)(ref const ArrBuilder!T a) {
	return mutArrIsEmpty(a.data);
}

@trusted immutable(Arr!T) arrBuilderAsTempArr(T)(ref ArrBuilder!T a) {
	const Arr!(immutable T) arr = tempAsArr(a.data);
	return immutable Arr!T(begin(arr), size(arr));
}

immutable(size_t) arrBuilderSize(T)(ref ArrBuilder!T a) {
	return mutArrSize(a.data);
}

//TODO:MOVE?
struct ArrWithSizeBuilder(T) {
	private ubyte* data_ = null;
	private size_t size_ = 0;
	private size_t capacity_ = 0;
}

private @system T* begin(T)(ref ArrWithSizeBuilder!T a) {
	return cast(T*) (a.data_ + size_t.sizeof);
}

@trusted void add(T, Alloc)(ref Alloc alloc, ref ArrWithSizeBuilder!T a, immutable T value) {
	if (a.size_ == a.capacity_) {
		const ubyte* oldData = a.data_;
		a.capacity_ = a.capacity_ == 0 ? 4 : a.capacity_ * 2;
		a.data_ = alloc.allocate(size_t.sizeof + T.sizeof * a.capacity_);
		foreach (immutable size_t i; 0..a.size_)
			initMemory(begin(a) + i, (cast(immutable T*) (oldData + size_t.sizeof))[i]);
	}
	verify(a.size_ < a.capacity_);
	initMemory(begin(a) + a.size_, value);
	a.size_ += 1;
}

@trusted immutable(ArrWithSize!T) finishArr(T, Alloc)(ref Alloc alloc, ref ArrWithSizeBuilder!T a) {
	if (a.data_ == null)
		return emptyArrWithSize!T;
	else {
		alloc.freePartial(cast(ubyte*) (begin(a) + a.size_), a.capacity_ - a.size_);
		*(cast(size_t*) a.data_) = a.size_;
		return immutable ArrWithSize!T(cast(immutable) a.data_);
	}
}
