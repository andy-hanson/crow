module util.collection.arrUtil;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, begin, empty, first, ptrAt, ptrsRange, range, size, sizeEq;
import util.collection.mutArr : moveToArr, mustPop, MutArr, mutArrAt, mutArrSize, push, setAt;
import util.comparison : compareOr, Comparer, compareSizeT, Comparison;
import util.memory : initMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.result : asFailure, asSuccess, fail, isSuccess, Result, success;
import util.util : max, todo;

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
	immutable T v15,
) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof * 16);
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
	initMemory(ptr + 15, v15);
	return immutable Arr!T(cast(immutable) ptr, 16);
}

@trusted immutable(Arr!Out) fillArr(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size);
	foreach (immutable size_t i; 0..size)
		initMemory(res + i, cb(i));
	return immutable Arr!Out(cast(immutable) res, size);
}

@trusted Arr!Out fillArr_mut(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope Out delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size);
	foreach (immutable size_t i; 0..size)
		initMemory(res + i, cb(i));
	return Arr!Out(res, size);
}

@trusted immutable(Opt!(Arr!Out)) fillArrOrFail(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Opt!Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size);
	foreach (immutable size_t i; 0..size) {
		immutable Opt!Out op = cb(i);
		if (has(op))
			initMemory(res + i, force(op));
		else
			return none!(Arr!Out);
	}
	return some(immutable Arr!Out(cast(immutable) res, size));
}

immutable(Bool) exists(T)(
	scope immutable Arr!T arr,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; range(arr))
		if (cb(x))
			return True;
	return False;
}

immutable(Bool) exists(T)(
	scope const Arr!T arr,
	scope immutable(Bool) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	foreach (ref const T x; range(arr))
		if (cb(x))
			return True;
	return False;
}

immutable(Bool) every(T)(
	immutable Arr!T arr,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; range(arr))
		if (!cb(x))
			return False;
	return True;
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
	ref immutable Arr!T a,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; range(a))
		if (cb(x))
			return some!T(x);
	return none!T;
}

immutable(Opt!size_t) findIndex(T)(
	ref immutable Arr!T a,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0..size(a))
		if (cb(at(a, i)))
			return some(i);
	return none!size_t;
}

immutable(Opt!(Ptr!T)) findPtr(T)(
	ref immutable Arr!T arr,
	scope immutable(Bool) delegate(immutable Ptr!T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable Ptr!T x; ptrsRange(arr))
		if (cb(x))
			return some!(Ptr!T)(x);
	return none!(Ptr!T);
}

@trusted immutable(Arr!Out) map(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	return cast(immutable) mapToMut(alloc, a, cb);
}
@trusted immutable(Arr!Out) map_const(Out, In, Alloc)(
	ref Alloc alloc,
	const Arr!In a,
	scope immutable(Out) delegate(ref const In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
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

@trusted immutable(Arr!Out) mapWithOptFirst2(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst0,
	ref immutable Opt!Out optFirst1,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = (has(optFirst0) ? 1 : 0) + (has(optFirst1) ? 1 : 0);
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * (offset + size(a)));
	if (has(optFirst0)) {
		initMemory(res, force(optFirst0));
	}
	if (has(optFirst1)) {
		initMemory(res + (has(optFirst0) ? 1 : 0), force(optFirst1));
	}
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + offset + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, offset + size(a));
}

@trusted immutable(Arr!Out) mapWithOptFirst(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Out opt2 = none!Out;
	return mapWithOptFirst2!(Out, In, Alloc)(alloc, optFirst, opt2, a, cb);
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
	immutable Arr!In a,
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
@trusted immutable(Opt!(Arr!Out)) mapOrNone_const(Out, In, Alloc)(
	ref Alloc alloc,
	ref const Arr!In a,
	scope immutable(Opt!Out) delegate(ref const In) @safe @nogc pure nothrow cb,
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
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * a.size);
	foreach (immutable size_t i; 0..a.size)
		initMemory(res + i, cb(i, at(a, i)));
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

@trusted immutable(Arr!T) slice(T)(immutable Arr!T a, immutable size_t begin, immutable size_t newSize) {
	assert(begin + newSize <= a.size);
	return immutable Arr!T(a.begin + begin, newSize);
}
@trusted const(Arr!T) slice(T)(const Arr!T a, immutable size_t begin, immutable size_t newSize) {
	assert(begin + newSize <= a.size);
	return const Arr!T(a.begin + begin, newSize);
}
@trusted Arr!T slice(T)(Arr!T a, immutable size_t begin, immutable size_t newSize) {
	assert(begin + newSize <= a.size);
	return Arr!T(a.begin + begin, newSize);
}

immutable(Arr!T) slice(T)(immutable Arr!T a, immutable size_t begin) {
	assert(begin <= a.size);
	return slice(a, begin, a.size - begin);
}
const(Arr!T) slice(T)(const Arr!T a, immutable size_t begin) {
	assert(begin <= a.size);
	return slice(a, begin, a.size - begin);
}
Arr!T slice(T)(Arr!T a, immutable size_t begin) {
	assert(begin <= a.size);
	return slice(a, begin, a.size - begin);
}

immutable(Arr!T) sliceFromTo(T)(ref immutable Arr!T a, immutable size_t lo, immutable size_t hi) {
	assert(lo <= hi);
	return slice(a, lo, hi - lo);
}

immutable(Arr!T) tail(T)(immutable Arr!T a) {
	assert(a.size != 0);
	return slice(a, 1);
}
const(Arr!T) tail(T)(const Arr!T a) {
	assert(a.size != 0);
	return slice(a, 1);
}
Arr!T tail(T)(Arr!T a) {
	assert(a.size != 0);
	return slice(a, 1);
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

@trusted immutable(Arr!Out) mapZip(Out, In0, In1, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope immutable(Out) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * sz);
	foreach (immutable size_t i; 0..sz)
		initMemory(res + i, cb(at(in0, i), at(in1, i)));
	return immutable Arr!Out(cast(immutable) res, sz);
}

@trusted immutable(Arr!Out) mapZipWithIndex(Out, In0, In1, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope immutable(Out) delegate(ref immutable In0, ref immutable In1, immutable size_t) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * sz);
	foreach (immutable size_t i; 0..sz)
		initMemory(res + i, cb(at(in0, i), at(in1, i), i));
	return immutable Arr!Out(cast(immutable) res, sz);
}


@trusted immutable(Opt!(Arr!Out)) mapZipOrNone(Out, In0, In1, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope immutable(Opt!Out) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocate(Out.sizeof * sz);
	foreach (immutable size_t i; 0..sz) {
		immutable Opt!Out o = cb(at(in0, i), at(in1, i));
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Arr!Out);
	}
	return some(immutable Arr!Out(cast(immutable) res, sz));
}

immutable(Bool) zipSome(In0, In1)(
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope immutable(Bool) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	foreach (immutable size_t i; 0..size(in0))
		if (cb(at(in0, i), at(in1, i)))
			return True;
	return False;
}

void zipWithIndex(In0, In1)(
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope void delegate(ref immutable In0, ref immutable In1, immutable size_t) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	foreach (immutable size_t i; 0..size(in0))
		cb(at(in0, i), at(in1, i), i);
}

immutable(Bool) eachCorresponds(T, U)(
	immutable Arr!T a,
	immutable Arr!T b,
	scope immutable(Bool) delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		if (!cb(at(a, i), at(b, i)))
			return False;
	return True;
}

immutable(Comparison) compareArr(T)(
	ref immutable Arr!T a,
	ref immutable Arr!T b,
	Comparer!T compare,
) {
	return compareOr(
		compareSizeT(size(a), size(b)),
		() {
			foreach (immutable size_t i; 0..size(a)) {
				immutable Comparison c = compare(at(a, i), at(b, i));
				if (c != Comparison.equal)
					return c;
			}
			return Comparison.equal;
		});
}

immutable(T) fold(T, U)(
	immutable T start,
	immutable Arr!U arr,
	scope immutable(T) delegate(ref immutable T a, ref immutable U b) @safe @nogc pure nothrow cb,
) {
	return empty(arr)
		? start
		: fold!(T, U)(cb(start, first(arr)), tail(arr), cb);
}

immutable(size_t) arrMax(T)(
	immutable size_t start,
	immutable Arr!T a,
	scope immutable(size_t) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a)
		? start
		: arrMax(max(start, cb(first(a))), tail(a), cb);
}

immutable(size_t) sum(T)(
	immutable Arr!T a,
	scope immutable(size_t) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return fold!(size_t, T)(0, a, (ref immutable size_t l, ref immutable T t) =>
		l + cb(t));
}

immutable(Arr!T) filter(Alloc, T)(
	ref Alloc alloc,
	ref immutable Arr!T a,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow pred,
) {
	return mapOp!T(alloc, a, (ref immutable T t) =>
		pred(t) ? some!T(t) : none!T);
}

void filterUnordered(T)(
	ref MutArr!T a,
	scope immutable(Bool) delegate(ref T) @safe @nogc pure nothrow pred,
) {
	size_t i = 0;
	while (i < mutArrSize(a)) {
		immutable Bool b = pred(mutArrAt(a, i));
		if (b)
			i++;
		else if (i == mutArrSize(a) - 1)
			mustPop(a);
		else {
			T t = mustPop(a);
			setAt(a, i, t);
		}
	}
}

immutable(size_t) arrMaxIndex(T, U)(
	const Arr!U a,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	Comparer!T compare,
) {
	return arrMaxIndexRecur!(T, U)(0, cb(first(a), 0), a, 1, cb, compare);
}

immutable(size_t) arrMaxIndexRecur(T, U)(
	immutable size_t indexOfMax,
	immutable T maxValue,
	ref const Arr!U a,
	immutable size_t index,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	Comparer!T compare,
) {
	if (index == size(a))
		return indexOfMax;
	else {
		immutable T valueHere = cb(at(a, index), index);
		return compare(valueHere, maxValue) == Comparison.greater
			? arrMaxIndexRecur!(T, U)(index, valueHere, a, index + 1, cb, compare)
			: arrMaxIndexRecur!(T, U)(indexOfMax, maxValue, a, index + 1, cb, compare);
	}
}
