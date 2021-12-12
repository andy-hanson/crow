module util.collection.arrUtil;

import util.alloc.alloc : Alloc, allocateBytes, allocateT;
import util.collection.arr : ArrWithSize, empty, first, ptrAt, ptrsRange, sizeEq, toArr;
import util.collection.mutArr : mustPop, MutArr, mutArrAt, mutArrSize, setAt;
import util.comparison : Comparer, Comparison, ConstComparer;
import util.memory : initMemory, initMemory_mut, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : Ptr;
import util.util : max, verify;

@safe @nogc nothrow:

@trusted immutable(Out[]) mapImpure(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
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

immutable(ArrWithSize!T) arrWithSizeLiteral(T)(ref Alloc alloc, scope immutable T[] values) {
	return mapWithSizeWithIndex!(T, T)(alloc, values, (immutable size_t, scope ref immutable T value) =>
		value);
}

@trusted immutable(T[]) arrLiteral(T)(ref Alloc alloc, scope immutable T[] values) {
	T* ptr = allocateT!T(alloc, values.length);
	foreach (immutable size_t i; 0 .. values.length)
		initMemory(ptr + i, values[i]);
	return cast(immutable) ptr[0 .. values.length];
}

@system Out[] fillArrUninitialized(Out)(ref Alloc alloc, immutable size_t size) {
	return allocateT!Out(alloc, size)[0 .. size];
}

@trusted immutable(Out[]) fillArr(Out)(
	ref Alloc alloc,
	immutable size_t size,
	scope immutable(Out) delegate(immutable size_t) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, size);
	foreach (immutable size_t i; 0 .. size)
		initMemory(res + i, cb(i));
	return cast(immutable) res[0 .. size];
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

immutable(bool) contains(T)(
	scope ref immutable T[] arr,
	scope ref immutable T value,
	immutable(bool) delegate(ref immutable T, ref immutable T) @safe @nogc pure nothrow equals,
) {
	return exists!T(arr, (ref immutable T v) =>
		equals(v, value));
}

immutable(Opt!size_t) findIndex(T)(
	ref immutable T[] a,
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
	immutable T[] arr,
	scope immutable(bool) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable T x; arr)
		if (cb(x))
			return some(x);
	return none!T;
}
Opt!T find_mut(T)(
	T[] arr,
	scope immutable(bool) delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	foreach (ref T x; arr)
		if (cb(x))
			return someMut(x);
	return noneMut!T;
}

immutable(Opt!(Ptr!T)) findPtr(T)(
	immutable T[] arr,
	scope immutable(bool) delegate(immutable Ptr!T) @safe @nogc pure nothrow cb,
) {
	foreach (immutable Ptr!T x; ptrsRange(arr))
		if (cb(x))
			return some!(Ptr!T)(x);
	return none!(Ptr!T);
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
	const In[] a,
	scope immutable(Out) delegate(ref const In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref const In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}
@trusted immutable(Out[]) map_mut(Out, In)(
	ref Alloc alloc,
	In[] a,
	scope immutable(Out) delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref In x; a)
		initMemory(res + i, cb(x));
	return cast(immutable) res[0 .. a.length];
}
@trusted Out[] mapToMut(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope Out delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a) {
		Out value = cb(x);
		initMemory_mut(res + i, value);
	}
	return res[0 .. a.length];
}

@trusted immutable(Out[]) mapPtrs(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + i, cb(ptrAt(a, i)));
	return cast(immutable) res[0 .. a.length];
}

@trusted immutable(Out[]) mapWithOptFirst2(Out, In)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst0,
	ref immutable Opt!Out optFirst1,
	ref immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = (has(optFirst0) ? 1 : 0) + (has(optFirst1) ? 1 : 0);
	Out* res = allocateT!Out(alloc, (offset + a.length));
	if (has(optFirst0))
		initMemory(res, force(optFirst0));
	if (has(optFirst1))
		initMemory(res + (has(optFirst0) ? 1 : 0), force(optFirst1));
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + offset + i, cb(i, ptrAt(a, i)));
	return cast(immutable) res[0 .. offset + a.length];
}

@trusted immutable(Out[]) mapWithOptFirst(Out, In)(
	ref Alloc alloc,
	ref immutable Opt!Out optFirst,
	ref immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable size_t offset = has(optFirst) ? 1 : 0;
	Out* res = allocateT!Out(alloc, (offset + a.length));
	if (has(optFirst))
		initMemory(res, force(optFirst));
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + offset + i, cb(x));
	return cast(immutable) res[0 .. offset + a.length];
}

@trusted immutable(Out[]) mapWithFirst(Out, In)(
	ref Alloc alloc,
	immutable Out first,
	scope immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Out someFirst = some!Out(first);
	return mapWithOptFirst!(Out, In)(alloc, someFirst, a, (ref immutable In x) =>
		cb(x));
}

@trusted immutable(Out[]) mapWithFirst2(Out, In)(
	ref Alloc alloc,
	immutable Out first,
	immutable Out second,
	ref immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	immutable Opt!Out someFirst = some!Out(first);
	immutable Opt!Out someSecond = some!Out(second);
	return mapWithOptFirst2!(Out, In)(
		alloc,
		someFirst,
		someSecond,
		a,
		(immutable size_t i, immutable Ptr!In it) =>
			cb(i, it.deref()));
}

@trusted immutable(Out[]) mapOp(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	return mapOpWithIndex!(Out, In)(alloc, a, (immutable size_t, ref immutable In x) =>
		cb(x));
}

@trusted immutable(ArrWithSize!Out) mapOpWithSize(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Opt!Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	ubyte* res = allocateBytes(alloc, size_t.sizeof + Out.sizeof * a.length);
	Out* elements = cast(Out*) (res + size_t.sizeof);
	size_t resI = 0;
	foreach (ref immutable In x; a) {
		immutable Opt!Out o = cb(x);
		if (has(o)) {
			initMemory(elements + resI, force(o));
			resI++;
		}
	}
	*(cast(size_t*) res) = resI;
	return immutable ArrWithSize!Out(cast(immutable) res);
}

@trusted immutable(Out[]) mapOpWithIndex(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Opt!Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	size_t resI = 0;
	foreach (immutable size_t i, ref immutable In x; a) {
		immutable Opt!Out o = cb(i, x);
		if (has(o)) {
			initMemory(res + resI, force(o));
			resI++;
		}
	}
	return cast(immutable) res[0 .. resI];
}

@trusted immutable(Opt!(Out[])) mapOrNone(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
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
@trusted immutable(Opt!(Out[])) mapOrNone_const(Out, In)(
	ref Alloc alloc,
	ref const In[] a,
	scope immutable(Opt!Out) delegate(ref const In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref const In x; a) {
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
	immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	return cast(immutable) mapWithIndex_mut(alloc, a, cb);
}
@trusted Out[] mapWithIndex_mut(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope Out delegate(immutable size_t, ref immutable In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(res + i, cb(i, x));
	return res[0 .. a.length];
}


immutable(ArrWithSize!Out) mapWithSize(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	return mapWithSizeWithIndex!(Out, In)(alloc, a, (immutable(size_t), ref immutable In x) => cb(x));
}

@trusted immutable(ArrWithSize!Out) mapWithSizeWithIndex(Out, In)(
	ref Alloc alloc,
	scope immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, scope ref immutable In) @safe @nogc pure nothrow cb,
) {
	ubyte* res = allocateBytes(alloc, size_t.sizeof + Out.sizeof * a.length);
	*(cast(size_t*) res) = a.length;
	Out* elements = cast(Out*) (res + size_t.sizeof);
	foreach (immutable size_t i, ref immutable In x; a)
		initMemory(elements + i, cb(i, x));
	return immutable ArrWithSize!Out(cast(immutable) res);
}

@trusted immutable(Out[]) mapPtrsWithIndex(Out, In)(
	ref Alloc alloc,
	immutable In[] a,
	scope immutable(Out) delegate(immutable size_t, immutable Ptr!In) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.length);
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + i, cb(i, ptrAt(a, i)));
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
	ref immutable T[] a,
	ref immutable T[] b,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return each(each(acc, a, cb), b, cb);
}

private immutable(Acc) each(Acc, T)(
	immutable Acc acc,
	immutable T[] a,
	scope immutable(Acc) delegate(immutable Acc, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a) ? acc : each!(Acc, T)(cb(acc, first(a)), tail(a), cb);
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

@trusted immutable(T[]) cat4(T)(
	ref Alloc alloc,
	immutable T[] a,
	immutable T[] b,
	immutable T[] c,
	immutable T[] d,
) {
	immutable size_t resSize = a.length + b.length + c.length + d.length;
	T* res = allocateT!T(alloc, resSize);
	foreach (immutable size_t i, ref immutable T x; a)
		initMemory(res + i, x);
	foreach (immutable size_t i, ref immutable T x; b)
		initMemory(res + a.length + i, x);
	foreach (immutable size_t i, ref immutable T x; c)
		initMemory(res + a.length + b.length + i, x);
	foreach (immutable size_t i, ref immutable T x; d)
		initMemory(res + a.length + b.length + c.length + i, x);
	return cast(immutable) res[0 .. resSize];
}

@trusted immutable(ArrWithSize!T) append(T)(ref Alloc alloc, immutable ArrWithSize!T a, immutable T b) {
	immutable T[] aArr = toArr(a);
	immutable size_t resSize = aArr.length + 1;
	ubyte* res = allocateBytes(alloc, size_t.sizeof + T.sizeof * resSize);
	*(cast(size_t*) res) = resSize;
	T* elements = cast(T*) (res + size_t.sizeof);
	foreach (immutable size_t i; 0 .. aArr.length)
		initMemory(elements + i, aArr[i]);
	initMemory(elements + aArr.length, b);
	return immutable ArrWithSize!T(cast(immutable) res);
}

@trusted immutable(T[]) append(T)(ref Alloc alloc, immutable T[] a, immutable T b) {
	immutable size_t resSize = a.length + 1;
	T* res = allocateT!T(alloc, resSize);
	foreach (immutable size_t i; 0 .. a.length)
		initMemory(res + i, at(a, i));
	initMemory(res + a.length, b);
	return immutable T[](cast(immutable) res, resSize);
}

@trusted immutable(ArrWithSize!T) prepend(T)(ref Alloc alloc, immutable T a, immutable ArrWithSize!T b) {
	immutable T[] bArr = toArr(b);
	immutable size_t resSize = 1 + bArr.length;
	ubyte* res = allocateBytes(alloc, size_t.sizeof + T.sizeof * resSize);
	*(cast(size_t*) res) = resSize;
	T* elements = cast(T*) (res + size_t.sizeof);
	initMemory(elements + 0, a);
	foreach (immutable size_t i, ref immutable T x; bArr)
		initMemory(elements + 1 + i, x);
	return immutable ArrWithSize!T(cast(immutable) res);
}

@trusted immutable(T[]) prepend(T)(ref Alloc alloc, immutable T a, immutable T[] b) {
	immutable size_t resSize = 1 + b.length;
	T* res = allocateT!T(alloc, resSize);
	initMemory(res + 0, a);
	foreach (immutable size_t i, ref immutable T x; b)
		initMemory(res + 1 + i, x);
	return cast(immutable) res[0 .. resSize];
}

immutable(T[]) tail(T)(return scope ref immutable T[] a) {
	verify(a.length != 0);
	return a[1 .. $];
}
const(T[]) tail(T)(const T[] a) {
	verify(a.length != 0);
	return a[1 .. $];
}
T[] tail(T)(T[] a) {
	verify(a.length != 0);
	return a[1 .. $];
}

//TODO:PERF More efficient than bubble sort..
void sortInPlace(T)(scope T[] a, scope immutable ConstComparer!T compare) {
	immutable size_t n = a.length; // avoiding dscanner warning `Avoid subtracting from '.length' as it may be unsigned`
	if (n > 1) {
		size_t lastNonSorted = 0;
		foreach (immutable size_t i; 0 .. n - 1) {
			final switch (compare(a[i], a[i + 1])) {
				case Comparison.less:
				case Comparison.equal:
					break;
				case Comparison.greater:
					swap(a, i, i + 1);
					lastNonSorted = i + 1;
					break;
			}
		}
		sortInPlace!T(a[0 .. lastNonSorted], compare);
	}
}

private void swap(T)(scope T[] a, immutable size_t i, immutable size_t j) {
	T tmp = a[i];
	overwriteMemory(&a[i], a[j]);
	overwriteMemory(&a[j], tmp);
}

void zip(T, U)(
	immutable T[] a,
	immutable U[] b,
	scope void delegate(ref immutable T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

void zip(T, U, V)(
	immutable T[] a,
	immutable U[] b,
	immutable V[] c,
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
	scope void delegate(Ptr!T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(ptrAt(a, i), b[i]);
}

void zipPtrFirst(T, U)(
	immutable T[] a,
	immutable U[] b,
	scope void delegate(immutable Ptr!T, ref immutable U) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(a, b));
	foreach (immutable size_t i; 0 .. a.length)
		cb(ptrAt(a, i), b[i]);
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
	scope immutable(Out) delegate(immutable Ptr!In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = in0.length;
	Out* res = allocateT!Out(alloc, sz);
	foreach (immutable size_t i; 0 .. sz)
		initMemory(res + i, cb(ptrAt(in0, i), in1[i]));
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


@trusted immutable(Opt!(Out[])) mapZipOrNone(Out, In0, In1)(
	ref Alloc alloc,
	ref immutable In0[] in0,
	ref immutable In1[] in1,
	scope immutable(Opt!Out) delegate(ref immutable In0, ref immutable In1) @safe @nogc pure nothrow cb,
) {
	verify(sizeEq(in0, in1));
	immutable size_t sz = in0.length;
	Out* res = allocateT!Out(alloc, sz);
	foreach (immutable size_t i; 0 .. sz) {
		immutable Opt!Out o = cb(in0[i], in1[i]);
		if (has(o))
			initMemory(res + i, force(o));
		else
			return none!(Out[]);
	}
	return some!(Out[])(cast(immutable) res[0 .. sz]);
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

immutable(T) fold(T, U)(
	immutable T start,
	scope immutable U[] arr,
	scope immutable(T) delegate(immutable T a, ref immutable U b) @safe @nogc pure nothrow cb,
) {
	return empty(arr)
		? start
		: fold!(T, U)(cb(start, first(arr)), tail(arr), cb);
}

immutable(Opt!T) foldOrStop(T, U)(
	immutable T start,
	immutable U[] arr,
	scope immutable(Opt!T) delegate(immutable T a, ref immutable U b) @safe @nogc pure nothrow cb,
) {
	if (empty(arr))
		return some(start);
	else {
		immutable Opt!T next = cb(start, first(arr));
		return has(next) ? foldOrStop!(T, U)(force(next), tail(arr), cb) : none!T;
	}
}

immutable(N) arrMax(N, T)(
	immutable N start,
	immutable T[] a,
	scope immutable(N) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return empty(a)
		? start
		: arrMax!(N, T)(max(start, cb(first(a))), tail(a), cb);
}

immutable(size_t) sum(T)(
	immutable T[] a,
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
		immutable bool b = pred(mutArrAt(a, i));
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
	const U[] a,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	Comparer!T compare,
) {
	return arrMaxIndexRecur!(T, U)(0, cb(first(a), 0), a, 1, cb, compare);
}

private immutable(size_t) arrMaxIndexRecur(T, U)(
	immutable size_t indexOfMax,
	immutable T maxValue,
	ref const U[] a,
	immutable size_t index,
	scope immutable(T) delegate(ref const U, immutable size_t) @safe @nogc pure nothrow cb,
	Comparer!T compare,
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
