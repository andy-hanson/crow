module util.collection.arrBuilder;

@safe @nogc pure nothrow:

import util.collection.mutArr : moveToArr, MutArr, push;

struct ArrBuilder(T, Alloc) {
	private MutArr!(T, Alloc) data;
}

void push(T, Alloc)(ref ArrBuilder!(T, Alloc) a, T t) {
	a.data.push(t);
}

Arr!T finish(T)(ref ArrBuilder!(T, Alloc) a) {
	return data.moveToArr();
}

