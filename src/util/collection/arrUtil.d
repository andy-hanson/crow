module util.collection.arrUtil;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, range, size;
import util.memory : initMemory;
import util.opt : none, Opt, some;
import util.result : asFailure, asSuccess, fail, isSuccess, Result, success;

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(ref Alloc alloc, immutable T value) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 1);
	initMemory(ptr, value);
	return immutable Arr!T(cast(immutable) ptr, 1);
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
	scope immutable(Bool) delegate(scope ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr.range)
		if (cb(x))
			return True;
	return False;
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
	immutable Arr!In a,
	ref Alloc alloc,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * a.size);
	foreach (immutable size_t i; 0..a.size)
		initMemory(res + i, cb(a.at(i)));
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

@trusted immutable(Arr!T) prepend(T, Alloc)(ref Alloc alloc, immutable T a, immutable Arr!T b) {
	immutable size_t resSize = 1 + b.size;
	T* res = cast(T*) alloc.allocate(T.sizeof * resSize);
	initMemory(res + 0, a);
	foreach (immutable size_t i; 0..b.size)
		initMemory(res + 1 + i, b.at(i));
	return immutable Arr!T(cast(immutable) res, resSize);
}
