module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, begin, range, size;
import util.collection.mutArr : tempAsArr, moveToArr, MutArr, mutArrAt, mutArrIsEmpty, mutArrSize, push;
import util.memory : initMemory;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

ref immutable(T) arrBuilderAt(T)(ref ArrBuilder!T a,immutable size_t index) {
	return mutArrAt(a.data, index);
}

void add(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
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
