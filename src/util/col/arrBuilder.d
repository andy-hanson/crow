module util.col.arrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutArr : moveToArr, MutArr, mutArrClear, mutArrSize, push, pushAll, tempAsArr, tempAsArr_mut;
import util.col.sortUtil : sortInPlace;
import util.comparison : Comparer;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

void add(T)(ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void addAll(T)(ref Alloc alloc, ref ArrBuilder!T a, scope immutable T[] value) {
	pushAll(alloc, a.data, value);
}

void arrBuilderClear(T)(ref ArrBuilder!T a) {
	mutArrClear(a.data);
}

const(T[]) arrBuilderTempAsArr(T)(ref const ArrBuilder!T a) {
	return tempAsArr(a.data);
}

void arrBuilderSort(T)(ref ArrBuilder!T a, scope immutable Comparer!T compare) {
	sortInPlace!(immutable T)(tempAsArr_mut(a.data), compare);
}

immutable(T[]) finishArr_immutable(T)(ref Alloc alloc, ref ArrBuilder!(immutable T) a) {
	return moveToArr(alloc, a.data);
}

immutable(T[]) finishArr(T)(ref Alloc alloc, scope ref ArrBuilder!T a) {
	return moveToArr(alloc, a.data);
}

immutable(size_t) arrBuilderSize(T)(ref const ArrBuilder!T a) {
	return mutArrSize(a.data);
}
