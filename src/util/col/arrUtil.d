module util.col.arrUtil;

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty, ptrsRange, sizeEq;
import util.col.mutArr : mustPop, MutArr, mutArrSize;
import util.comparison : Comparer, Comparison;
import util.memory : initMemory, initMemory_mut;
import util.opt : force, has, none, Opt, some;
import util.util : max, verify;

@safe @nogc nothrow:

@trusted immutable(Out[]) mapImpure(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}

@trusted immutable(Opt!(Out[])) mapOrNoneImpure(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a) {
		immutable Opt!Out o = cb(x);
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Out[]);
	}
	return some!(Out[])(cast(immutable) res[0 .. a.length]);
}

@system void zipImpureSystem(T, U)(
	immutable T[] a,
	immutable U[] b,
	scope void delegate(ref immutable T, ref immutable U) @nogc nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

pure:

@trusted immutable(T[]) arrLiteral(T)(scope ref Alloc alloc, scope immutable T[] values) {
	T* ptr = allocateT!T(alloc, values.length);
	foreach (immutable size_t i; 0 .. values.length)
		initMemory(ptr + i, values[i]);
	return cast(immutable) ptr[0 .. values.length];
}

@system Out[] fillArrUninitialized(Out)(ref Alloc alloc, immutable size_t size) {
	return allocateT!Out(alloc, size)[0 .. size];
}
@trusted Out[] fillArr_mut(Out)(
	ref Alloc alloc,
	immutable size_t size,
	scope Out delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, size);
	foreach (immutable size_t i; 0 .. size) {
		Out value = cb(i);
		initMemory_mut!Out(res + i, value);
	}
	return res[0 .. size];
}

@trusted immutable(Opt!(Out[])) fillArrOrFail(Out)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Opt!Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, size);
	foreach (immutable size_t i; 0 .. size) {
		immutable Opt!Out op = cb(i);
		if (has(op))
			initMemory(res + i, force(op));
		else
			return none!(Out[]);
	}
	return some!(Out[])(cast(immutable) res[0 .. size]);
}

immutable(bool) exists(T)(
	scope immutable T[] arr,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr)
		if (cb(x))
			return true;
	return false;
}

immutable(bool) exists_const(T)(
	scope const T[] arr,
	scope immutable(bool) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	foreach (ref const T x; arr)
		if (cb(x))
			return true;
	return false;
}

immutable(bool) every(T)(
	scope immutable T[] arr,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr)
		if (!cb(x))
			return false;
	return true;
}

immutable(bool) everyWithIndex(T)(
	scope immutable T[] arr,
	scope immutable(bool) delegate(ref immutable T, immutable size_t) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; arr)
		if (!cb(x, i))
			return false;
	return true;
}

immutable(bool) contains(T)(scope immutable T[] xs, scope immutable T value) {
	foreach (immutable T x; xs)
		if (x == value)
			return true;
	return false;
}

immutable(Opt!size_t) findIndex(T)(
	scope immutable T[] a,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; a)
		if (cb(x))
			return some(i);
	return none!size_t;
}

immutable(Opt!size_t) findIndex_const(T)(
	const T[] a,
	scope immutable(bool) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i, ref immutable T x; a)
		if (cb(x))
			return some(i);
	return none!size_t;
}

immutable(Opt!T) find(T)(
	scope immutable T[] arr,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr)
		if (cb(x))
			return some(x);
	return none!T;
}

immutable(Opt!(T*)) findPtr(T)(
	immutable T[] arr,
	scope immutable(bool) delegate(immutable T*) @safe @nogc pure nothrow cb,
) {
	foreach (immutable T* x; ptrsRange(arr))
		if (cb(x))
			return some(x);
	return none!(T*);
}

immutable(T[]) copyArr(T)(ref Alloc alloc, scope immutable T[] a) {
	return map(alloc, a, (ref immutable T it) => it);
}

@trusted immutable(Out[]) makeArr(Out)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, size);
	foreach (immutable size_t i; 0 .. size)
		initMemory(res + i, cb(i));
	return cast(immutable) res[0 .. size];
}

@trusted immutable(Out[]) map(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}
@trusted immutable(Out[]) map_const(Out, In)(
	ref Alloc alloc,
	scope const In[] a,
	scope immutable(Out) delegate(ref const In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref const In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}
@trusted immutable(Out[]) map_mut(Out, In)(
	ref Alloc alloc,
	scope In[] a,
	scope immutable(Out) delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}
@trusted Out[] mapToMut(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope Out delegate(scope ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a) {
		Out value = cb(x);
		initMemory_mut(res + i, value);
	}
	return res[0 .. a.length];
}

@trusted immutable(Out[]) mapPtrsWithOptFirst(Out, In)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst,
	immutable In[] a,
	scope immutable(Out) delegate(immutable In*) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = has(optFirst) ? 1 : 0;
	Out* res = allocateT!Out(alloc, offset + a.length);
	if (has(optFirst))
		initMemory(res, force(optFirst));
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + offset + i, cb(&a[i]));
	return cast(immutable) res[0 .. offset + a.length];
}

@trusted immutable(Out[]) mapWithFirst(Out, In)(
	ref Alloc alloc,
	immutable Out first,
	scope immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, 1 + a.length);
	initMemory(res, first);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + 1 + i, cb(i, x));
	return cast(immutable) res[0 .. 1 + a.length];
}

@trusted immutable(Out[]) mapOp(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	Out* resOut = res;
	foreach (ref immutable In x; a) {
		immutable Opt!Out o = cb(x);
		if (has(o)) {
			initMemory(resOut, force(o));
			resOut++;
		}
	}
	return cast(immutable) res[0 .. (resOut - res)];
}

@trusted immutable(Opt!(Out[])) mapOrNone(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a) {
		immutable Opt!Out o = cb(x);
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Out[]);
	}
	return some!(Out[])(cast(immutable) res[0 .. a.length]);
}

@trusted immutable(Out[]) mapWithIndexAndConcatOne(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
	immutable Out concatOne,
) {
	immutable size_t outSize = a.length + 1;
	Out* res = allocateT!Out(alloc, outSize);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(i, x));
	initMemory(res + a.length, concatOne);
	return cast(immutable) res[0 .. outSize];
}

@trusted immutable(Out[]) mapWithIndex(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(i, x));
	return cast(immutable) res[0 .. a.length];
}
@trusted immutable(Out[]) mapWithIndex_scope(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, scope ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(i, x));
	return cast(immutable) res[0 .. a.length];
}
@trusted Out[] mapWithIndex_mut(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope Out delegate(immutable size_t, scope ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(i, x));
	return res[0 .. a.length];
}

@trusted immutable(Out[]) mapPtrsWithIndex(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, immutable In*) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + i, cb(i, &a[i]));
	return cast(immutable) res[0 .. a.length];
}

@trusted immutable(Out[]) mapWithSoFar(Out, In)(
	ref Alloc alloc,
	scope immutable In[] inputs,
	scope immutable(Out) delegate(
		ref immutable In,
		ref immutable Out[],
		immutable size_t,
	) @safe @nogc pure nothrow cb
) {
	Out* res = allocateT!Out(alloc, inputs.length);
	foreach (immutable size_t i, ref immutable In input; inputs) {
		immutable Out[] soFar = cast(immutable) res[0 .. i];
		initMemory(res + i, cb(input, soFar, i));
	}
	return cast(immutable) res[0 .. inputs.length];
}

immutable(Acc) eachCat(Acc, T)(
	immutable Acc acc,
	scope immutable T[] a,
	scope immutable T[] b,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return each(each(acc, a, cb), b, cb);
}

private immutable(Acc) each(Acc, T)(
	immutable Acc acc,
	scope immutable T[] a,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a) ? acc : each!(Acc, T)(cb(acc, a[0]), a[1 .. $], cb);
}

@trusted immutable(T[]) cat(T)(ref Alloc alloc, immutable T[] a, immutable T[] b) {
	if (empty(a))
		return b;
	else if (empty(b))
		return a;
	else {
		immutable size_t resSize = a.length + b.length;
		T* res = allocateT!T(alloc, resSize);
		foreach (immutable size_t i, ref immutable T x; a)
			initMemory(res + i, x);
		foreach (immutable size_t i, ref immutable T x; b)
			initMemory(res + a.length + i, x);
		return cast(immutable) res[0 .. resSize];
	}
}

@trusted immutable(T[]) append(T)(scope ref Alloc alloc, immutable T[] a, immutable T b) {
	immutable size_t resSize = a.length + 1;
	T* res = allocateT!T(alloc, resSize);
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + i, a[i]);
	initMemory(res + a.length, b);
	return (cast(immutable) res)[0 .. resSize];
}

@trusted immutable(T[]) prepend(T)(scope ref Alloc alloc, immutable T a, scope immutable T[] b) {
	immutable size_t resSize = 1 + b.length;
	T* res = allocateT!T(alloc, resSize);
	initMemory(res + 0, a);
	foreach (immutable size_t i, ref immutable T x; b)
		initMemory(res + 1 + i, x);
	return cast(immutable) res[0 .. resSize];
}

void zip(T, U)(
	scope immutable T[] a,
	scope immutable U[] b,
	scope void delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

void zip(T, U, V)(
	scope immutable T[] a,
	scope immutable U[] b,
	scope immutable V[] c,
	scope void delegate(ref immutable T, ref immutable U, ref immutable V) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b) && sizeEq(b, c));
	foreach (immutable size_t i; 0 .. a.length)
		cb(at(a, i), at(b, i), at(c, i));
}

void zipFirstMut(T, U)(
	ref T[] a,
	ref immutable U[] b,
	scope void delegate(ref T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

void zipMutPtrFirst(T, U)(
	ref T[] a,
	ref immutable U[] b,
	scope void delegate(T*, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(&a[i], b[i]);
}

void zipPtrFirst(T, U)(
	immutable T[] a,
	immutable U[] b,
	scope void delegate(immutable T*, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(&a[i], b[i]);
}

@trusted immutable(Out[]) mapZip(Out, In0, In1)(
	ref Alloc alloc,
	ref immutable In0[] in0,
	ref immutable In1[] in1,
	scope immutable(Out) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = in0.length;
	Out* res = allocateT!Out(alloc, sz);
	foreach (immutable size_t i; 0 .. sz)
		initMemory(res + i, cb(in0[i], in1[i]));
	return cast(immutable) res[0 .. sz];
}

@trusted immutable(Out[]) mapZipPtrFirst(Out, In0, In1)(
	ref Alloc alloc,
	ref immutable In0[] in0,
	ref immutable In1[] in1,
	scope immutable(Out) delegate(immutable In0*, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = in0.length;
	Out* res = allocateT!Out(alloc, sz);
	foreach (immutable size_t i; 0 .. sz)
		initMemory(res + i, cb(&in0[i], in1[i]));
	return cast(immutable) res[0 .. sz];
}

@trusted immutable(Out[]) mapZipWithIndex(Out, In0, In1)(
	ref Alloc alloc,
	ref immutable In0[] in0,
	ref immutable In1[] in1,
	scope immutable(Out) delegate(ref immutable In0, ref immutable In1, immutable size_t) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = in0.length;
	Out* res = allocateT!Out(alloc, sz);
	foreach (immutable size_t i; 0 .. sz)
		initMemory(res + i, cb(in0[i], in1[i], i));
	return cast(immutable) res[0 .. sz];
}

immutable(bool) eachCorresponds(T, U)(
	immutable T[] a,
	immutable U[] b,
	scope immutable(bool) delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		if (!cb(a[i], b[i]))
			return false;
	return true;
}

immutable(bool) arrsCorrespond(T, U)(
	scope immutable T[] a,
	scope immutable U[] b,
	scope immutable(bool) delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow elementsCorrespond,
) {
	return sizeEq(a, b) && eachCorresponds!(T, U)(a, b, elementsCorrespond);
}

immutable(bool) arrEqual(T)(
	scope immutable T[] a,
	scope immutable T[] b,
	scope immutable(bool) delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow elementEqual,
) {
	return arrsCorrespond!(T, T)(a, b, elementEqual);
}

private struct MapAndFoldResult(Out, State) {
	immutable Out[] output;
	immutable State state;
}

struct MapAndFold(Out, State) {
	immutable Out output;
	immutable State state;
}

@trusted immutable(MapAndFoldResult!(Out, State)) mapAndFold(Out, State, In)(
	ref Alloc alloc,
	immutable State start,
	scope immutable In[] a,
	scope immutable(MapAndFold!(Out, State)) delegate(ref immutable In, immutable State) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	immutable State endState = mapAndFoldRecur!(Out, State, In)(res, start, a.ptr, a.ptr + a.length, cb);
	return immutable MapAndFoldResult!(Out, State)(cast(immutable) res[0 .. a.length], endState);
}

private @system immutable(State) mapAndFoldRecur(Out, State, In)(
	Out* res,
	immutable State state,
	immutable In* curIn,
	immutable In* endIn,
	scope immutable(MapAndFold!(Out, State)) delegate(ref immutable In, immutable State) @safe @nogc pure nothrow cb,
) {
	if (curIn != endIn) {
		immutable MapAndFold!(Out, State) mf = cb(*curIn, state);
		initMemory(res, mf.output);
		return mapAndFoldRecur(res + 1, mf.state, curIn + 1, endIn, cb);
	} else
		return state;
}

immutable(T) reduce(T)(
	scope immutable T[] values,
	scope immutable(T) delegate(immutable T, immutable T) @safe @nogc pure nothrow cb,
) {
	return fold(values[0], values[1 .. $], (immutable T a, ref immutable T b) =>
		cb(a, b));
}

immutable(T) fold(T, U)(
	immutable T start,
	scope immutable U[] arr,
	scope immutable(T) delegate(immutable T a, ref immutable U b) @safe @nogc pure nothrow cb,
) {
	return empty(arr)
		? start
		: fold!(T, U)(cb(start, arr[0]), arr[1 .. $], cb);
}

immutable(Opt!T) foldOrStop(T, U)(
	immutable T start,
	scope immutable U[] arr,
	scope immutable(Opt!T) delegate(immutable T a, ref immutable U b) @safe @nogc pure nothrow cb,
) {
	if (empty(arr))
		return some(start);
	else {
		immutable Opt!T next = cb(start, arr[0]);
		return has(next) ? foldOrStop!(T, U)(force(next), arr[1 .. $], cb) : none!T;
	}
}

immutable(N) arrMax(N, T)(
	immutable N start,
	scope immutable T[] a,
	scope immutable(N) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a)
		? start
		: arrMax!(N, T)(max(start, cb(a[0])), a[1 .. $], cb);
}

immutable(size_t) sum(T)(
	scope immutable T[] a,
	scope immutable(size_t) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return fold!(size_t, T)(0, a, (immutable size_t l, ref immutable T t) =>
		l + cb(t));
}

immutable(size_t) count(T)(
	ref immutable T[] a,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow pred,
) {
	return sum(a, (ref immutable T it) =>
		immutable size_t(pred(it) ? 1 : 0));
}

void filterUnordered(T)(
	ref MutArr!T a,
	scope immutable(bool) delegate(ref T) @safe @nogc pure nothrow pred,
) {
	size_t i = 0;
	while (i < mutArrSize(a)) {
		immutable bool b = pred(a[i]);
		if (b)
			i++;
		else if (i == mutArrSize(a) - 1)
			mustPop(a);
		else {
			a[i] = mustPop(a);
		}
	}
}

immutable(size_t) arrMaxIndex(T, U)(
	const U[] a,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	Comparer!T compare,
) {
	return arrMaxIndexRecur!(T, U)(0, cb(a[0], 0), a, 1, cb, compare);
}

private immutable(size_t) arrMaxIndexRecur(T, U)(
	immutable size_t indexOfMax,
	immutable T maxValue,
	ref const U[] a,
	immutable size_t index,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	scope immutable Comparer!T compare,
) {
	if (index == a.length)
		return indexOfMax;
	else {
		immutable T valueHere = cb(a[index], index);
		return compare(valueHere, maxValue) == Comparison.greater
			// Using `index + 0` to avoid dscanner warning about 'index' not being the 0th parameter
			? arrMaxIndexRecur!(T, U)(index + 0, valueHere, a, index + 1, cb, compare)
			: arrMaxIndexRecur!(T, U)(indexOfMax, maxValue, a, index + 1, cb, compare);
	}
}

void eachPair(T)(
	immutable T[] a,
	scope void delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. a.length)
		foreach (immutable size_t j; i + 1 .. a.length)
			cb(a[i], a[j]);
}
