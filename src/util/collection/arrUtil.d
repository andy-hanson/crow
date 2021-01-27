module util.collection.arrUtil;

import util.bools : Bool, False, True;
import util.collection.arr :
	Arr,
	arrOfD,
	ArrWithSize,
	at,
	begin,
	empty,
	first,
	ptrAt,
	ptrsRange,
	range,
	size,
	sizeEq,
	toArr;
import util.collection.mutArr : insert, moveToArr, mustPop, MutArr, mutArrAt, mutArrSize, push, setAt;
import util.comparison : compareOr, Comparer, compareSizeT, Comparison;
import util.memory : initMemory, initMemory_mut;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.util : max, verify;

@safe @nogc nothrow:

@trusted immutable(Arr!Out) mapImpure(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}

@system void zipImpureSystem(T, U)(
	immutable Arr!T a,
	immutable Arr!U b,
	scope void delegate(ref immutable T, ref immutable U) @nogc nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

pure:

immutable(ArrWithSize!T) arrWithSizeLiteral(T, Alloc)(ref Alloc alloc, scope immutable T[] values) {
	return mapWithSizeWithIndex(alloc, arrOfD(values), (immutable size_t, ref immutable T value) =>
		value);
}

@trusted immutable(Arr!T) arrLiteral(T, Alloc)(ref Alloc alloc, scope immutable T[] values) {
	T* ptr = cast(T*) alloc.allocateBytes(T.sizeof * values.length);
	foreach (immutable size_t i; 0..values.length)
		initMemory(ptr + i, values[i]);
	return immutable Arr!T(cast(immutable) ptr, values.length);
}

@system Arr!Out fillArrUninitialized(Out, Alloc)(ref Alloc alloc, immutable size_t size) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size);
	return Arr!Out(res, size);
}

@trusted immutable(Arr!Out) fillArr(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size);
	foreach (immutable size_t i; 0..size)
		initMemory(res + i, cb(i));
	return immutable Arr!Out(cast(immutable) res, size);
}

@trusted Arr!Out fillArr_mut(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope Out delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size);
	foreach (immutable size_t i; 0..size) {
		Out value = cb(i);
		initMemory_mut!Out(res + i, value);
	}
	return Arr!Out(res, size);
}

@trusted immutable(Opt!(Arr!Out)) fillArrOrFail(Out, Alloc)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Opt!Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size);
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

immutable(Bool) exists_const(T)(
	scope const Arr!T arr,
	scope immutable(Bool) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	foreach (ref const T x; range(arr))
		if (cb(x))
			return True;
	return False;
}

immutable(Bool) every(T)(
	scope ref immutable Arr!T arr,
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
	immutable Arr!T a,
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

immutable(Opt!size_t) findIndex_const(T)(
	const Arr!T a,
	scope immutable(Bool) delegate(ref const T) @safe @nogc pure nothrow cb,
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

immutable(Arr!T) copyArr(T, Alloc)(ref Alloc alloc, immutable Arr!T a) {
	return map(alloc, a, (ref immutable T it) => it);
}

@trusted immutable(Arr!Out) map(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}
@trusted immutable(Arr!Out) map_const(Out, In, Alloc)(
	ref Alloc alloc,
	const Arr!In a,
	scope immutable(Out) delegate(ref const In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}
@trusted immutable(Arr!Out) map_mut(Out, In, Alloc)(
	ref Alloc alloc,
	Arr!In a,
	scope immutable(Out) delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}
@trusted Arr!Out mapToMut(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope Out delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a)) {
		Out value = cb(at(a, i));
		initMemory_mut(res + i, value);
	}
	return Arr!Out(res, size(a));
}

@trusted immutable(Arr!Out) mapPtrs(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(ptrAt(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}

@trusted immutable(Arr!Out) mapWithOptFirst2(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst0,
	ref immutable Opt!Out optFirst1,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = (has(optFirst0) ? 1 : 0) + (has(optFirst1) ? 1 : 0);
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * (offset + size(a)));
	if (has(optFirst0))
		initMemory(res, force(optFirst0));
	if (has(optFirst1))
		initMemory(res + (has(optFirst0) ? 1 : 0), force(optFirst1));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + offset + i, cb(i, ptrAt(a, i)));
	return immutable Arr!Out(cast(immutable) res, offset + size(a));
}

@trusted immutable(Arr!Out) mapWithOptFirst(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = has(optFirst) ? 1 : 0;
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * (offset + size(a)));
	if (has(optFirst))
		initMemory(res, force(optFirst));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + offset + i, cb(i, ptrAt(a, i)));
	return immutable Arr!Out(cast(immutable) res, offset + size(a));
}

@trusted immutable(Arr!Out) mapWithFirst(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Out first,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Out someFirst = some!Out(first);
	return mapWithOptFirst!(Out, In, Alloc)(alloc, someFirst, a, (immutable(size_t), immutable Ptr!In it) =>
		cb(it));
}

@trusted immutable(Arr!Out) mapWithFirst2(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Out first,
	immutable Out second,
	ref immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Out someFirst = some!Out(first);
	immutable Opt!Out someSecond = some!Out(second);
	return mapWithOptFirst2!(Out, In, Alloc)(
		alloc,
		someFirst,
		someSecond,
		a,
		(immutable size_t i, immutable Ptr!In it) =>
			cb(i, it));
}

@trusted immutable(Arr!Out) mapOp(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	return mapOpWithIndex!(Out, In, Alloc)(alloc, a, (immutable size_t, ref immutable In x) =>
		cb(x));
}

@trusted immutable(ArrWithSize!Out) mapOpWithSize(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	ubyte* res = alloc.allocateBytes(size_t.sizeof + Out.sizeof * size(a));
	Out* elements = cast(Out*) (res + size_t.sizeof);
	size_t resI = 0;
	foreach (immutable size_t i; 0..size(a)) {
		immutable Opt!Out o = cb(at(a, i));
		if (has(o)) {
			initMemory(elements + resI, force(o));
			resI++;
		}
	}
	*(cast(size_t*) res) = resI;
	return immutable ArrWithSize!Out(cast(immutable) res);
}

@trusted immutable(Arr!Out) mapOpWithIndex(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Opt!Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	size_t resI = 0;
	foreach (immutable size_t i; 0..size(a)) {
		immutable Opt!Out o = cb(i, at(a, i));
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
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
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
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a)) {
		immutable Opt!Out o = cb(at(a, i));
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Arr!Out);
	}
	return some(immutable Arr!Out(cast(immutable) res, size(a)));
}

@trusted immutable(Arr!Out) mapWithIndexAndConcatOne(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
	immutable Out concatOne,
) {
	immutable size_t outSize = size(a) + 1;
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * outSize);
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(i, at(a, i)));
	initMemory(res + size(a), concatOne);
	return immutable Arr!Out(cast(immutable) res, outSize);
}

@trusted immutable(Arr!Out) mapWithIndex(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(i, at(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}

@trusted immutable(ArrWithSize!Out) mapWithSizeWithIndex(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	ubyte* res = alloc.allocateBytes(size_t.sizeof + Out.sizeof * size(a));
	*(cast(size_t*) res) = size(a);
	Out* elements = cast(Out*) (res + size_t.sizeof);
	foreach (immutable size_t i; 0..size(a))
		initMemory(elements + i, cb(i, at(a, i)));
	return immutable ArrWithSize!Out(cast(immutable) res);
}

@trusted immutable(Arr!Out) mapPtrsWithIndex(Out, In, Alloc)(
	ref Alloc alloc,
	immutable Arr!In a,
	scope immutable(Out) delegate(immutable size_t, immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(a));
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, cb(i, ptrAt(a, i)));
	return immutable Arr!Out(cast(immutable) res, size(a));
}

@trusted immutable(Arr!Out) mapWithSoFar(Out, In, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In inputs,
	scope immutable(Out) delegate(
		ref immutable In,
		ref immutable Arr!Out,
		immutable size_t,
	) @safe @nogc pure nothrow cb
) {
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * size(inputs));
	foreach (immutable size_t i; 0..size(inputs)) {
		immutable Arr!Out soFar = immutable Arr!Out(cast(immutable) res, i);
		initMemory(res + i, cb(at(inputs, i), soFar, i));
	}
	return immutable Arr!Out(cast(immutable) res, size(inputs));
}

immutable(Acc) eachCat(Acc, T)(
	immutable Acc acc,
	ref immutable Arr!T a,
	ref immutable Arr!T b,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return each(each(acc, a, cb), b, cb);
}

private immutable(Acc) each(Acc, T)(
	immutable Acc acc,
	immutable Arr!T a,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a) ? acc : each!(Acc, T)(cb(acc, first(a)), tail(a), cb);
}

@trusted immutable(Arr!T) cat(T, Alloc)(ref Alloc alloc, immutable Arr!T a, immutable Arr!T b) {
	if (empty(a))
		return b;
	else if (empty(b))
		return a;
	else {
		immutable size_t resSize = size(a) + size(b);
		T* res = cast(T*) alloc.allocateBytes(T.sizeof * resSize);
		foreach (immutable size_t i; 0..size(a))
			initMemory(res + i, at(a, i));
		foreach (immutable size_t i; 0..size(b))
			initMemory(res + size(a) + i, at(b, i));
		return immutable Arr!T(cast(immutable) res, resSize);
	}
}

@trusted immutable(Arr!T) cat(T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T a,
	immutable Arr!T b,
	immutable Arr!T c,
	immutable Arr!T d,
) {
	immutable size_t resSize = size(a) + size(b) + size(c) + size(d);
	T* res = cast(T*) alloc.allocateBytes(T.sizeof * resSize);
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, at(a, i));
	foreach (immutable size_t i; 0..size(b))
		initMemory(res + size(a) + i, at(b, i));
	foreach (immutable size_t i; 0..size(c))
		initMemory(res + size(a) + size(b) + i, at(c, i));
	foreach (immutable size_t i; 0..size(d))
		initMemory(res + size(a) + size(b) + size(c) + i, at(d, i));
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(ArrWithSize!T) append(T, Alloc)(ref Alloc alloc, immutable ArrWithSize!T a, immutable T b) {
	immutable Arr!T aArr = toArr(a);
	immutable size_t resSize = size(aArr) + 1;
	ubyte* res = alloc.allocateBytes(size_t.sizeof + T.sizeof * resSize);
	*(cast(size_t*) res) = resSize;
	T* elements = cast(T*) (res + size_t.sizeof);
	foreach (immutable size_t i; 0..size(aArr))
		initMemory(elements + i, at(aArr, i));
	initMemory(elements + size(aArr), b);
	return immutable ArrWithSize!T(cast(immutable) res);
}

@trusted immutable(Arr!T) append(T, Alloc)(ref Alloc alloc, immutable Arr!T a, immutable T b) {
	immutable size_t resSize = size(a) + 1;
	T* res = cast(T*) alloc.allocateBytes(T.sizeof * resSize);
	foreach (immutable size_t i; 0..size(a))
		initMemory(res + i, at(a, i));
	initMemory(res + size(a), b);
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(ArrWithSize!T) prepend(T, Alloc)(ref Alloc alloc, immutable T a, immutable ArrWithSize!T b) {
	immutable Arr!T bArr = toArr(b);
	immutable size_t resSize = 1 + size(bArr);
	ubyte* res = alloc.allocateBytes(size_t.sizeof + T.sizeof * resSize);
	*(cast(size_t*) res) = resSize;
	T* elements = cast(T*) (res + size_t.sizeof);
	initMemory(elements + 0, a);
	foreach (immutable size_t i; 0..size(bArr))
		initMemory(elements + 1 + i, at(bArr, i));
	return immutable ArrWithSize!T(cast(immutable) res);
}

@trusted immutable(Arr!T) prepend(T, Alloc)(ref Alloc alloc, immutable T a, immutable Arr!T b) {
	immutable size_t resSize = 1 + size(b);
	T* res = cast(T*) alloc.allocateBytes(T.sizeof * resSize);
	initMemory(res + 0, a);
	foreach (immutable size_t i; 0..size(b))
		initMemory(res + 1 + i, at(b, i));
	return immutable Arr!T(cast(immutable) res, resSize);
}

@trusted immutable(Arr!T) slice(T)(immutable Arr!T a, immutable size_t begin, immutable size_t newSize) {
	verify(begin + newSize <= size(a));
	return immutable Arr!T(a.begin + begin, newSize);
}
@trusted const(Arr!T) slice(T)(const Arr!T a, immutable size_t begin, immutable size_t newSize) {
	verify(begin + newSize <= size(a));
	return const Arr!T(a.begin + begin, newSize);
}
@trusted Arr!T slice(T)(Arr!T a, immutable size_t begin, immutable size_t newSize) {
	verify(begin + newSize <= size(a));
	return Arr!T(a.begin + begin, newSize);
}

immutable(Arr!T) slice(T)(immutable Arr!T a, immutable size_t begin) {
	verify(begin <= size(a));
	return slice(a, begin, size(a) - begin);
}
const(Arr!T) slice(T)(const Arr!T a, immutable size_t begin) {
	verify(begin <= size(a));
	return slice(a, begin, size(a) - begin);
}
Arr!T slice(T)(Arr!T a, immutable size_t begin) {
	verify(begin <= size(a));
	return slice(a, begin, size(a) - begin);
}

immutable(Arr!T) sliceFromTo(T)(ref immutable Arr!T a, immutable size_t lo, immutable size_t hi) {
	verify(lo <= hi);
	verify(hi <= size(a));
	return slice(a, lo, hi - lo);
}

immutable(Arr!T) tail(T)(return scope ref immutable Arr!T a) {
	verify(size(a) != 0);
	return slice(a, 1);
}
const(Arr!T) tail(T)(const Arr!T a) {
	verify(size(a) != 0);
	return slice(a, 1);
}
Arr!T tail(T)(Arr!T a) {
	verify(size(a) != 0);
	return slice(a, 1);
}

immutable(Arr!T) rtail(T)(immutable Arr!T a) {
	verify(size(a) != 0);
	return slice(a, 0, size(a) - 1);
}

//TODO:PERF More efficient than bubble sort..
immutable(Arr!T) sort(T, Alloc)(
	ref Alloc alloc,
	scope ref immutable Arr!T a,
	scope immutable Comparer!T compare,
) {
	MutArr!(immutable T) res;

	void addOne(ref immutable T x) {
		foreach (immutable size_t i; 0..mutArrSize(res)) {
			final switch (compare(x, mutArrAt(res, i))) {
				case Comparison.less:
					insert!(immutable T, Alloc)(alloc, res, i, x);
					return;
				case Comparison.equal:
				case Comparison.greater:
					break;
			}
		}
		push(alloc, res, x);
	}

	foreach (ref immutable T x; range(a))
		addOne(x);

	return moveToArr(alloc, res);
}

void zip(T, U)(
	immutable Arr!T a,
	immutable Arr!U b,
	scope void delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

void zip(T, U, V)(
	immutable Arr!T a,
	immutable Arr!U b,
	immutable Arr!V c,
	scope void delegate(ref immutable T, ref immutable U, ref immutable V) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b) && sizeEq(b, c));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i), at(c, i));
}

@system void zipSystem(T, U)(
	immutable Arr!T a,
	immutable Arr!U b,
	scope void delegate(ref immutable T, ref immutable U) @system @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

void zipFirstMut(T, U)(
	ref Arr!T a,
	ref immutable Arr!U b,
	scope void delegate(ref T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(at(a, i), at(b, i));
}

void zipMutPtrFirst(T, U)(
	ref Arr!T a,
	ref immutable Arr!U b,
	scope void delegate(Ptr!T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(ptrAt(a, i), at(b, i));
}

void zipPtrFirst(T, U)(
	immutable Arr!T a,
	immutable Arr!U b,
	scope void delegate(immutable Ptr!T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		cb(ptrAt(a, i), at(b, i));
}

@trusted immutable(Arr!Out) mapZip(Out, In0, In1, Alloc)(
	ref Alloc alloc,
	ref immutable Arr!In0 in0,
	ref immutable Arr!In1 in1,
	scope immutable(Out) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * sz);
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
	verify(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * sz);
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
	verify(sizeEq(in0, in1));
	immutable size_t sz = size(in0);
	Out* res = cast(Out*) alloc.allocateBytes(Out.sizeof * sz);
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
	verify(sizeEq(in0, in1));
	foreach (immutable size_t i; 0..size(in0))
		if (cb(at(in0, i), at(in1, i)))
			return True;
	return False;
}

immutable(Bool) eachCorresponds(T, U)(
	immutable Arr!T a,
	immutable Arr!U b,
	scope immutable(Bool) delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0..size(a))
		if (!cb(at(a, i), at(b, i)))
			return False;
	return True;
}

immutable(Bool) arrEqual(T)(
	scope ref immutable Arr!T a,
	scope ref immutable Arr!T b,
	scope immutable(Bool) delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow elementEqual,
) {
	return immutable Bool(sizeEq(a, b) && eachCorresponds(a, b, elementEqual));
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

immutable(N) arrMax(N, T)(
	immutable N start,
	immutable Arr!T a,
	scope immutable(N) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a)
		? start
		: arrMax!(N, T)(max(start, cb(first(a))), tail(a), cb);
}

immutable(size_t) sum(T)(
	immutable Arr!T a,
	scope immutable(size_t) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return fold!(size_t, T)(0, a, (ref immutable size_t l, ref immutable T t) =>
		l + cb(t));
}

immutable(size_t) count(T)(
	ref immutable Arr!T a,
	scope immutable(Bool) delegate(ref immutable T) @safe @nogc pure nothrow pred,
) {
	return sum(a, (ref immutable T it) =>
		immutable size_t(pred(it) ? 1 : 0));
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

private immutable(size_t) arrMaxIndexRecur(T, U)(
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
			// Using `index + 0` to avoid dscanner warning about 'index' not being the 0th parameter
			? arrMaxIndexRecur!(T, U)(index + 0, valueHere, a, index + 1, cb, compare)
			: arrMaxIndexRecur!(T, U)(indexOfMax, maxValue, a, index + 1, cb, compare);
	}
}
