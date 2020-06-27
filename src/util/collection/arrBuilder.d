module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.collection.mutArr : moveToArr, MutArr, push;

struct ArrBuilder(T) {
	private MutArr!T data;
}

void add(T, Alloc)(ref ArrBuilder!T a, ref Alloc alloc, immutable T value) {
	a.data.push!(T, Alloc)(alloc, value);
}

immutable(Arr!T) finishArr(T, Alloc)(ref ArrBuilder!T a, ref Alloc alloc) {
	return a.data.moveToArr(alloc);
}

