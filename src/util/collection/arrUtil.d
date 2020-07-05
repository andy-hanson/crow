module util.collection.arrUtil;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, begin, ptrAt, range, size, sizeEq;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push;
import util.comparison : Comparer, Comparison;
import util.memory : initMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.result : asFailure, asSuccess, fail, isSuccess, Result, success;
import util.util : todo;

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(ref Alloc alloc, immutable T value) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 1);
	initMemory(ptr, value);
	return immutable Arr!T(cast(immutable) ptr, 1);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 2);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	return immutable Arr!T(cast(immutable) ptr, 2);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 3);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	return immutable Arr!T(cast(immutable) ptr, 3);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 4);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	initMemory(ptr + 3, v3);
	return immutable Arr!T(cast(immutable) ptr, 4);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
	immutable T v4,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 5);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	initMemory(ptr + 3, v3);
	initMemory(ptr + 4, v4);
	return immutable Arr!T(cast(immutable) ptr, 5);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
	immutable T v4,
	immutable T v5,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 6);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	initMemory(ptr + 3, v3);
	initMemory(ptr + 4, v4);
	initMemory(ptr + 5, v5);
	return immutable Arr!T(cast(immutable) ptr, 6);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
	immutable T v4,
	immutable T v5,
	immutable T v6,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 7);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	initMemory(ptr + 3, v3);
	initMemory(ptr + 4, v4);
	initMemory(ptr + 5, v5);
	initMemory(ptr + 6, v6);
	return immutable Arr!T(cast(immutable) ptr, 7);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
	immutable T v4,
	immutable T v5,
	immutable T v6,
	immutable T v7,
	immutable T v8,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 9);
	initMemory(ptr + 0, v0);
	initMemory(ptr + 1, v1);
	initMemory(ptr + 2, v2);
	initMemory(ptr + 3, v3);
	initMemory(ptr + 4, v4);
	initMemory(ptr + 5, v5);
	initMemory(ptr + 6, v6);
	initMemory(ptr + 7, v7);
	initMemory(ptr + 8, v8);
	return immutable Arr!T(cast(immutable) ptr, 9);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(
	ref Alloc alloc,
	immutable T v0,
	immutable T v1,
	immutable T v2,
	immutable T v3,
	immutable T v4,
	immutable T v5,
	immutable T v6,
	immutable T v7,
	immutable T v8,
	immutable T v9,
	immutable T v10,
	immutable T v11,
	immutable T v12,
	immutable T v13,
	immutable T v14,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 15);
	initMemory(ptr +  0,  v0);
	initMemory(ptr +  1,  v1);
	initMemory(ptr +  2,  v2);
	initMemory(ptr +  3,  v3);
	initMemory(ptr +  4,  v4);
	initMemory(ptr +  5,  v5);
	initMemory(ptr +  6,  v6);
	initMemory(ptr +  7,  v7);
	initMemory(ptr +  8,  v8);
	initMemory(ptr +  9,  v9);
	initMemory(ptr + 10, v10);
	initMemory(ptr + 11, v11);
	initMemory(ptr + 12, v12);
	initMemory(ptr + 13, v13);
	initMemory(ptr + 14, v14);
	return immutable Arr!T(cast(immutable) ptr, 15);

}

immutable(Bool) exists(T)(
	scope ref immutable Arr!T arr,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr.range)
		if (cb(x))
			return True;
	return False;
}

immutable(Bool) contains(T)(
	scope ref immutable Arr!T arr,
	scope ref immutable T value,
	immutable(Bool) delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow equals,
) {
	return exists(arr, (ref immutable T v) =>
		equals(v, value));
}

immutable(Opt!T) find(T)(
	ref immutable Arr!T arr,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr.range)
		if (cb(x))
			return some!T(x);
	return none!T;
}

@trusted immutable(Arr!Out) map(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	return cast(immutable) mapToMut(alloc, a, cb);
}
@trusted Arr!Out mapToMut(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return Arr!Out(res, size(a));
}

@trusted immutable(Arr!Out) mapOp(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size(a));
	size_t resI = 0;
	foreach (immutable size_t i; 0..size(a)) {
		immutable Opt!Out o = cb(at(a, i));
		if (has(o)) {
			initMemory(res + resI, force(o));
			resI++;
		}
	}
	return immutable Arr!Out(cast(immutable) res, resI);
}

@trusted immutable(Opt!(Arr!Out)) mapOrNone(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * a.size);
	foreach (immutable size_t i; 0..size(a)) {
		immutable Opt!Out o = cb(at(a, i));
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Arr!Out);
	}
	return some(immutable Arr!Out(cast(immutable) res, size(a)));
}

@trusted immutable(Arr!Out) mapWithIndex(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In, immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * a.size);
	foreach (immutable size_t i; 0..a.size)
		initMemory(res + i, cb(at(a, i), i));
	return immutable Arr!Out(cast(immutable) res, a.size);
}

@trusted immutable(Result!(Arr!OutSuccess, OutFailure)) mapOrFail(OutSuccess, OutFailure, In, Alloc)(
	immutable Arr!In inputs,
	ref Alloc alloc,
	scope immutable(Result!(OutSuccess, OutFailure)) delegate(ref immutable In) @safe @nogc pure nothrow cb
) {
	OutSuccess* res = cast(OutSuccess*) alloc.allocate(OutSuccess.sizeof * inputs.size);
	foreach (immutable size_t i; 0..inputs.size) {
		immutable Result!(OutSuccess, OutFailure) r = cb(inputs.at(i));
		if (r.isSuccess)
			initMemory(res + i, r.asSuccess);
		else {
			alloc.free(cast(ubyte*) res, OutSuccess.sizeof * inputs.size);
			return fail!(Arr!OutSuccess, OutFailure)(r.asFailure);
		}
	}
	return success!(Arr!OutSuccess, OutFailure)(immutable Arr!OutSuccess(cast(immutable) res, inputs.size));
}

@trusted immutable(Arr!T) cat(T, Alloc)(ref Alloc alloc, immutable Arr!T a, immutable Arr!T b) {
	immutable size_t resSize = a.size + b.size;
	T* res = cast(T*) alloc.allocate(T.sizeof * resSize);
	foreach (immutable size_t i; 0..a.size)
		initMemory(res + i, a.at(i));
	foreach (immutable size_t i; 0..b.size)
		initMemory(res + a.size + i, b.at(i));
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(Arr!T) cat(T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T a,
	immutable Arr!T b,
	immutable Arr!T c,
	immutable Arr!T d,
) {
	immutable size_t resSize = a.size + b.size + c.size + d.size;
	T* res = cast(T*) alloc.allocate(T.sizeof * resSize);
	foreach (immutable size_t i; 0..a.size)
		initMemory(res + i, a.at(i));
	foreach (immutable size_t i; 0..b.size)
		initMemory(res + a.size + i, b.at(i));
	foreach (immutable size_t i; 0..c.size)
		initMemory(res + a.size + b.size + i, c.at(i));
	foreach (immutable size_t i; 0..d.size)
		initMemory(res + a.size + b.size + c.size + i, d.at(i));
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(Arr!T) prepend(T, Alloc)(ref Alloc alloc, immutable T a, immutable Arr!T b) {
	immutable size_t resSize = 1 + b.size;
	T* res = cast(T*) alloc.allocate(T.sizeof * resSize);
	initMemory(res + 0, a);
	foreach (immutable size_t i; 0..b.size)
		initMemory(res + 1 + i, b.at(i));
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(Arr!T) slice(T)(ref immutable Arr!T a, immutable size_t begin, immutable size_t newSize) {
	assert(begin + newSize <= a.size);
	return immutable Arr!T(a.begin + begin, newSize);
}

immutable(Arr!T) slice(T)(ref immutable Arr!T a, immutable size_t begin) {
	assert(begin <= a.size);
	return a.slice(begin, a.size - begin);
}

immutable(Arr!T) sliceFromTo(T)(ref immutable Arr!T a, immutable size_t lo, immutable size_t hi) {
	assert(lo <= hi);
	return slice(a, lo, hi - lo);
}

immutable(Arr!T) tail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return a.slice(1);
}

immutable(Arr!T) rtail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return a.slice(0, a.size - 1);
}

immutable(Arr!T) sort(T, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!T a,
	scope immutable Comparer!T compare,
) {
	MutArr!(immutable T) res;

	void addSingle(ref immutable T x) {
		foreach (immutable size_t i; 0..mutArrSize(res)) {
			final switch (compare(x, mutArrAt(res, i))) {
				case Comparison.less:
					todo!void("insert here");
					return;
				case Comparison.equal:
				case Comparison.greater:
					break;
			}
		}
		// Greater than everything in the list -- add it to the end
		push(alloc, res, x);
	}

	foreach (ref immutable T x; a.range)
		addSingle(x);

	return moveToArr(alloc, res);
}

void zip(T, U)(
	ref immutable Arr!T a,
	ref immutable Arr!U b,
	scope void delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

void zipFirstMut(T, U)(
	ref Arr!T a,
	ref immutable Arr!U b,
	scope void delegate(ref T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

void zipMutPtrFirst(T, U)(
	ref Arr!T a,
	ref immutable Arr!U b,
	scope void delegate(Ptr!T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(ptrAt(a, i), at(b, i));
}

