module util.col.arrBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutArr : moveToArr, MutArr, mutArrClear, mutArrIsEmpty, mutArrSize, mustPop, push, pushAll, tempAsArr;
import util.col.sortUtil : sortInPlace;
import util.comparison : Comparer;

struct ArrBuilder(T) {
	private MutArr!(immutable T) data;
}

alias ArrBuilderCb(T) = void delegate(in T) @safe @nogc pure nothrow;

T[] buildArray(T)(ref Alloc alloc, in void delegate(in ArrBuilderCb!T) @safe @nogc pure nothrow cb) {
	ArrBuilder!T res;
	cb((in T x) {
		add(alloc, res, x);
	});
	return finishArr(alloc, res);
}

void add(T)(scope ref Alloc alloc, ref ArrBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void backUp(T)(ref ArrBuilder!T a) {
	mustPop(a.data);
}

void addAll(T)(ref Alloc alloc, ref ArrBuilder!(immutable T) a, in immutable T[] value) {
	pushAll(alloc, a.data, value);
}

void arrBuilderClear(T)(ref ArrBuilder!T a) {
	mutArrClear(a.data);
}

const(T[]) arrBuilderTempAsArr(T)(ref const ArrBuilder!T a) =>
	tempAsArr(a.data);

void arrBuilderSort(T)(scope ref ArrBuilder!T a, in Comparer!T compare) {
	sortInPlace!(immutable T)(tempAsArr(a.data), compare);
}

immutable(T[]) finishArr(T)(ref Alloc alloc, scope ref ArrBuilder!T a) =>
	moveToArr(alloc, a.data);

void consumeArr(T)(ref Alloc alloc, scope ref ArrBuilder!T a, in void delegate(T) @safe @nogc pure nothrow cb) {
	foreach (T x; arrBuilderTempAsArr(a))
		cb(x);
	arrBuilderClear(a);
}

size_t arrBuilderSize(T)(in ArrBuilder!T a) =>
	mutArrSize(a.data);

bool arrBuilderIsEmpty(T)(in ArrBuilder!T a) =>
	mutArrIsEmpty(a.data);
