module util.col.arrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutArr : moveToArr, MutArr, mutArrClear, mutArrSize, mustPop, push, pushAll, tempAsArr;
import util.col.sortUtil : sortInPlace;
import util.comparison : Comparer;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

void add(T)(scope ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void backUp(T)(ref ArrBuilder!T a) {
	mustPop(a.data);
}

void addAll(T)(ref Alloc alloc, ref ArrBuilder!T a, scope immutable T[] value) {
	pushAll(alloc, a.data, value);
}

void arrBuilderClear(T)(ref ArrBuilder!T a) {
	mutArrClear(a.data);
}

const(T[]) arrBuilderTempAsArr(T)(ref const ArrBuilder!T a) =>
	tempAsArr(a.data);

void arrBuilderSort(T)(ref ArrBuilder!T a, scope immutable Comparer!T compare) {
	sortInPlace!(immutable T)(tempAsArr(a.data), compare);
}

immutable(T[]) finishArr_immutable(T)(ref Alloc alloc, ref ArrBuilder!(immutable T) a) =>
	moveToArr(alloc, a.data);

immutable(T[]) finishArr(T)(ref Alloc alloc, scope ref ArrBuilder!T a) =>
	moveToArr(alloc, a.data);

immutable(size_t) arrBuilderSize(T)(ref const ArrBuilder!T a) =>
	mutArrSize(a.data);
