module util.col.arrayBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutArr : moveToArr, MutArr, mutArrIsEmpty, mutArrSize, mustPop, push, pushAll, tempAsArr;
import util.col.sortUtil : sortInPlace;
import util.comparison : Comparer;

struct ArrayBuilder(T) {
	private MutArr!(immutable T) data;
}

alias ArrBuilderCb(T) = void delegate(in T) @safe @nogc pure nothrow;

T[] buildArray(T)(ref Alloc alloc, in void delegate(in ArrBuilderCb!T) @safe @nogc pure nothrow cb) {
	ArrayBuilder!T res;
	cb((in T x) {
		add(alloc, res, x);
	});
	return finish(alloc, res);
}

void add(T)(scope ref Alloc alloc, ref ArrayBuilder!T a, immutable T value) {
	push(alloc, a.data, value);
}

void backUp(T)(ref ArrayBuilder!T a) {
	mustPop(a.data);
}

void addAll(T)(ref Alloc alloc, ref ArrayBuilder!(immutable T) a, in immutable T[] value) {
	pushAll(alloc, a.data, value);
}

const(T[]) arrBuilderTempAsArr(T)(ref const ArrayBuilder!T a) =>
	tempAsArr(a.data);

void arrBuilderSort(T)(scope ref ArrayBuilder!T a, in Comparer!T compare) {
	sortInPlace!(immutable T)(tempAsArr(a.data), compare);
}

immutable(T[]) finish(T)(ref Alloc alloc, scope ref ArrayBuilder!T a) =>
	moveToArr(alloc, a.data);

size_t arrBuilderSize(T)(in ArrayBuilder!T a) =>
	mutArrSize(a.data);

bool arrBuilderIsEmpty(T)(in ArrayBuilder!T a) =>
	mutArrIsEmpty(a.data);
