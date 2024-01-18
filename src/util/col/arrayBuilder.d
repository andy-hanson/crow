module util.col.arrayBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.array : small, SmallArray;
import util.col.mutArr : asTemporaryArray, moveToArray, MutArr, mutArrIsEmpty, mutArrSize, mustPop, push, pushAll;
import util.col.sortUtil : sortInPlace;
import util.comparison : Comparer;

struct ArrayBuilder(T) {
	private MutArr!(immutable T) data;
}

struct ArrayBuilderWithAlloc(T) {
	private Alloc* allocPtr;
	private ArrayBuilder!T inner;

	private ref Alloc alloc() =>
		*allocPtr;

	void opOpAssign(string op)(in T x) scope if (op == "~") {
		add(alloc, inner, x);
	}
	void opOpAssign(string op)(in T[] xs) scope if (op == "~") {
		addAll!(immutable T)(alloc, inner, xs);
	}
}

immutable(SmallArray!T) smallFinish(T)(scope ref ArrayBuilderWithAlloc!T a) =>
	smallFinish(a.alloc, a.inner);

immutable(T[]) finish(T)(ref ArrayBuilderWithAlloc!T a) =>
	finish(a.alloc, a.inner);

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

const(T[]) asTemporaryArray(T)(ref const ArrayBuilder!T a) =>
	.asTemporaryArray(a.data);

void arrBuilderSort(T)(scope ref ArrayBuilder!T a, in Comparer!T compare) {
	sortInPlace!(immutable T)(asTemporaryArray(a), compare);
}

immutable(SmallArray!T) smallFinish(T)(ref Alloc alloc, scope ref ArrayBuilder!T a) =>
	small!T(finish(alloc, a));

immutable(T[]) finish(T)(ref Alloc alloc, scope ref ArrayBuilder!T a) =>
	moveToArray(alloc, a.data);

size_t arrBuilderSize(T)(in ArrayBuilder!T a) =>
	mutArrSize(a.data);

bool arrBuilderIsEmpty(T)(in ArrayBuilder!T a) =>
	mutArrIsEmpty(a.data);
