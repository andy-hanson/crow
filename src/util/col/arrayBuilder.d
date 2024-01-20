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

struct Builder(T) {
	private Alloc* allocPtr;
	private ArrayBuilder!T inner;

	private ref Alloc alloc() =>
		*allocPtr;

	void opOpAssign(string op)(in T x) scope if (op == "~") {
		add!T(alloc, inner, x);
	}
	void opOpAssign(string op)(in T[] xs) scope if (op == "~") {
		addAll!T(alloc, inner, xs);
	}
}

immutable(SmallArray!T) smallFinish(T)(scope ref Builder!T a) =>
	smallFinish(a.alloc, a.inner);

immutable(T[]) finish(T)(ref Builder!T a) =>
	finish(a.alloc, a.inner);

T[] buildArray(T)(ref Alloc alloc, in void delegate(scope ref Builder!T) @safe @nogc pure nothrow cb) {
	Builder!T res = Builder!T(&alloc);
	cb(res);
	return finish(res);
}

SmallArray!T buildSmallArray(T)(ref Alloc alloc, in void delegate(scope ref Builder!T) @safe @nogc pure nothrow cb) {
	Builder!T res = Builder!T(&alloc);
	cb(res);
	return smallFinish(res);
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
const(T[]) asTemporaryArray(T)(ref const Builder!T a) =>
	.asTemporaryArray(a.inner);

void arrBuilderSort(T)(scope ref ArrayBuilder!T a, in Comparer!T compare) {
	sortInPlace!(immutable T)(asTemporaryArray(a), compare);
}
void arrBuilderSort(T)(scope ref Builder!T a, in Comparer!T compare) {
	arrBuilderSort!T(a.inner, compare);
}

immutable(SmallArray!T) smallFinish(T)(ref Alloc alloc, scope ref ArrayBuilder!T a) =>
	small!T(finish(alloc, a));

immutable(T[]) finish(T)(ref Alloc alloc, scope ref ArrayBuilder!T a) =>
	moveToArray(alloc, a.data);

size_t arrBuilderSize(T)(in ArrayBuilder!T a) =>
	mutArrSize(a.data);

bool arrBuilderIsEmpty(T)(in ArrayBuilder!T a) =>
	mutArrIsEmpty(a.data);
