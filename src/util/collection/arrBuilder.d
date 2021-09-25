module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : allocateBytes, freeBytesPartial;
import util.collection.arr : ArrWithSize, begin, emptyArrWithSize;
import util.collection.mutArr : moveToArr, MutArr, mutArrSize, push, pushAll;
import util.memory : initMemory;
import util.util : verify;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

void add(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void addAll(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a, scope immutable T[] value) {
	pushAll(alloc, a.data, value);
}

immutable(T[]) finishArr_immutable(T, Alloc)(ref Alloc alloc, ref ArrBuilder!(immutable T) a) {
	return moveToArr(alloc, a.data);
}

immutable(T[]) finishArr(T, Alloc)(ref Alloc alloc, ref ArrBuilder!T a) {
	return moveToArr(alloc, a.data);
}

immutable(size_t) arrBuilderSize(T)(ref const ArrBuilder!T a) {
	return mutArrSize(a.data);
}
