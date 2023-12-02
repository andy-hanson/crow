module util.col.arrUtil;

import util.alloc.alloc : Alloc, allocateElements, freeElements;
import util.col.arr : empty, endPtr, ptrsRange, sizeEq;
import util.comparison : Comparer, Comparison;
import util.memory : copyToFrom, initMemory, initMemory_mut;
import util.opt : force, has, none, Opt, some;
import util.util : max;

@safe @nogc nothrow:

@trusted Out[] mapImpure(Out, In)(ref Alloc alloc, in In[] a, in Out delegate(in In) @safe @nogc nothrow cb) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i, ref In x; a)
		initMemory(&res[i], cb(x));
	return res;
}

pure:

@trusted T[] arrLiteral(T)(scope ref Alloc alloc, scope T[] values) {
	T[] res = allocateElements!T(alloc, values.length);
	foreach (size_t i, ref T x; values)
		initMemory!T(&res[i], x);
	return res;
}

@trusted Out[] fillArr_mut(Out)(ref Alloc alloc, size_t size, in Out delegate(size_t) @safe @nogc pure nothrow cb) {
	Out[] res = allocateElements!Out(alloc, size);
	foreach (size_t i; 0 .. size) {
		Out value = cb(i);
		initMemory_mut!Out(&res[i], value);
	}
	return res;
}

@trusted Opt!(Out[]) fillArrOrFail(Out)(
	ref Alloc alloc,
	size_t size,
	in Opt!Out delegate(size_t) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, size);
	foreach (size_t i; 0 .. size) {
		Opt!Out op = cb(i);
		if (has(op))
			initMemory(&res[i], force(op));
		else {
			freeElements(alloc, res);
			return none!(Out[]);
		}
	}
	return some(res);
}

bool exists(T)(in T[] arr, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	has(findIndex!T(arr, cb));

bool every(T)(in T[] arr, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	everyWithIndex!T(arr, (size_t _, in T x) => cb(x));

bool everyWithIndex(T)(in T[] arr, in bool delegate(size_t, in T) @safe @nogc pure nothrow cb) {
	foreach (size_t i, ref const T x; arr)
		if (!cb(i, x))
			return false;
	return true;
}

bool allSame(Out, T)(in T[] arr, in Out delegate(in T) @safe @nogc pure nothrow cb) {
	if (empty(arr))
		return true;
	else {
		Out value = cb(arr[0]);
		foreach (ref const T x; arr[1 .. $])
			if (cb(x) != value)
				return false;
		return true;
	}
}

bool contains(T)(in T[] xs, in T value) =>
	exists!T(xs, (in T x) => x == value);

Opt!T find(T)(in T[] a, in bool delegate(in T) @safe @nogc pure nothrow cb) {
	foreach (ref const T x; a)
		if (cb(x))
			return some(x);
	return none!T;
}

Opt!size_t findIndex(T)(in T[] a, in bool delegate(in T) @safe @nogc pure nothrow cb) {
	foreach (size_t i, ref const T x; a)
		if (cb(x))
			return some(i);
	return none!size_t;
}

Opt!size_t indexOf(T)(in T[] xs, in T value) =>
	findIndex!T(xs, (in T x) => x == value);

Opt!size_t indexOfStartingAt(T)(in T[] xs, in T value, size_t start) {
	Opt!size_t indexFromStart = indexOf(xs[start .. $], value);
	return has(indexFromStart) ? some(force(indexFromStart) + start) : none!size_t;
}

@trusted Opt!size_t indexOfPointer(T)(in T[] xs, in T* pointer) {
	size_t res = pointer - xs.ptr;
	return 0 <= res && res < xs.length ? some(res) : none!size_t;
}

Opt!Out firstWithIndex(Out, In)(in In[] a, in Opt!Out delegate(size_t, In) @safe @nogc pure nothrow cb) {
	foreach (size_t index, In x; a) {
		Opt!Out res = cb(index, x);
		if (has(res))
			return res;
	}
	return none!Out;
}

Opt!Out first(Out, In)(in In[] a, in Opt!Out delegate(In) @safe @nogc pure nothrow cb) =>
	firstWithIndex!(Out, In)(a, (size_t _, In x) => cb(x));

Opt!Out firstPointer(Out, In)(In[] a, in Opt!Out delegate(In*) @safe @nogc pure nothrow cb) {
	foreach (In* x; ptrsRange(a)) {
		Opt!Out res = cb(x);
		if (has(res))
			return res;
	}
	return none!Out;
}

Opt!Out firstZip(Out, In0, In1)(in In0[] a, in In1[] b, in Opt!Out delegate(In0, In1) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	return firstWithIndex!(Out, In0)(a, (size_t i, In0 x) => cb(x, b[i]));
}

Opt!Out firstZipPointerFirst(Out, In0, In1)(
	In0[] a,
	in In1[] b,
	in Opt!Out delegate(In0*, In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	return firstWithIndex!(Out, In1)(b, (size_t i, In1 x) => cb(&a[i], x));
}

Opt!(T*) findPtr(T)(T[] arr, in bool delegate(in T) @safe @nogc pure nothrow cb) {
	foreach (T* x; ptrsRange!T(arr))
		if (cb(*x))
			return some(x);
	return none!(T*);
}

T[] copyArr(T)(ref Alloc alloc, scope T[] a) =>
	map!(T, T)(alloc, a, (ref T x) => x);

@trusted Out[] makeArr(Out)(ref Alloc alloc, size_t size, in Out delegate(size_t) @safe @nogc pure nothrow cb) {
	Out[] res = allocateElements!Out(alloc, size);
	foreach (size_t i; 0 .. size)
		initMemory(&res[i], cb(i));
	return res;
}

@trusted immutable(Out[]) map(Out, In)(
	ref Alloc alloc,
	scope In[] a,
	in immutable(Out) delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i, ref In x; a)
		initMemory(&res[i], cb(x));
	return cast(immutable) res;
}

@trusted Out[] mapToMut(Out, In)(ref Alloc alloc, scope In[] a, in Out delegate(ref In) @safe @nogc pure nothrow cb) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i, ref In x; a) {
		Out value = cb(x);
		initMemory_mut(&res[i], value);
	}
	return res;
}

@trusted Out[] mapWithFirst(Out, In)(
	ref Alloc alloc,
	Out first,
	in In[] a,
	in Out delegate(size_t, ref In) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, 1 + a.length);
	initMemory!Out(&res[0], first);
	foreach (size_t i, ref In x; a)
		initMemory!Out(&res[1 + i], cb(i, x));
	return res;
}

size_t count(T)(in T[] a, in bool delegate(in T) @safe @nogc pure nothrow cb) {
	size_t res = 0;
	foreach (ref T x; a)
		if (cb(x))
			res++;
	return res;
}

@trusted T[] filter(T)(ref Alloc alloc, in T[] a, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	mapOp!(T, T)(alloc, a, (ref T x) =>
		cb(x) ? some(x) : none!T);

@trusted Out[] mapOp(Out, In)(
	ref Alloc alloc,
	in In[] a,
	in Opt!Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	size_t outI = 0;
	foreach (ref In x; a) {
		Opt!Out o = cb(x);
		if (has(o)) {
			initMemory(&res[outI], force(o));
			outI++;
		}
	}
	freeElements(alloc, res[outI .. $]);
	return res[0 .. outI];
}

@trusted Opt!(Out[]) mapOrNone(Out, In)(
	ref Alloc alloc,
	in In[] a,
	in Opt!Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i, ref In x; a) {
		Opt!Out o = cb(x);
		if (has(o))
			initMemory(&res[i], force(o));
		else {
			freeElements(alloc, res);
			return none!(Out[]);
		}
	}
	return some(res);
}

@trusted Out[] mapWithIndexAndConcatOne(Out, In)(
	ref Alloc alloc,
	In[] a,
	in Out delegate(size_t, ref In) @safe @nogc pure nothrow cb,
	Out concatOne,
) {
	Out[] res = allocateElements!Out(alloc, a.length + 1);
	foreach (size_t i, ref In x; a)
		initMemory!Out(&res[i], cb(i, x));
	initMemory!Out(&res[a.length], concatOne);
	return res;
}

Out[] mapWithIndex(Out, In)(
	ref Alloc alloc,
	in In[] a,
	in Out delegate(size_t, ref In) @safe @nogc pure nothrow cb,
) =>
	mapPointers!(Out, In)(alloc, a, (In* x) @trusted =>
		cb(x - a.ptr, *x));

@trusted Out[] mapPointers(Out, In)(
	ref Alloc alloc,
	In[] a,
	in Out delegate(In*) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i; 0 .. a.length)
		initMemory(&res[i], cb(&a[i]));
	return res[0 .. a.length];
}

Out[] mapPointersWithIndex(Out, In)(
	ref Alloc alloc,
	In[] a,
	in Out delegate(size_t, In*) @safe @nogc pure nothrow cb,
) =>
	mapPointers!(Out, In)(alloc, a, (In* x) @trusted => cb(x - a.ptr, x));

T[] concatenate(T)(ref Alloc alloc, T[] a, T[] b) =>
	empty(a)
		? b
		: empty(b)
		? a
		: concatenateIn!T(alloc, a, b);

@trusted T[] concatenateIn(T)(ref Alloc alloc, scope T[] a, scope T[] b) {
	T[] res = allocateElements!T(alloc, a.length + b.length);
	copyToFrom!T(res[0 .. a.length], a);
	copyToFrom!T(res[a.length .. $], b);
	return res;
}

T[] append(T)(scope ref Alloc alloc, scope T[] a, T b) =>
	concatenateIn!T(alloc, a, [b]);

T[] prepend(T)(scope ref Alloc alloc, T a, scope T[] b) =>
	concatenateIn!T(alloc, [a], b);

bool zipEvery(T, U)(in T[] a, in U[] b, in bool delegate(in T, in U) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length)
		if (!cb(a[i], b[i]))
			return false;
	return true;
}

Opt!Out zipFirst(Out, T, U)(
	T[] a,
	in U[] b,
	in Opt!Out delegate(T*, in U) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length) {
		Opt!Out res = cb(&a[i], b[i]);
		if (has(res))
			return res;
	}
	return none!Out;
}

void zipIn(T, U)(in T[] a, in U[] b, in void delegate(in T, in U) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

void zip(T, U)(scope T[] a, scope U[] b, in void delegate(ref T, ref U) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length)
		cb(a[i], b[i]);
}

void zipPointers(T, U)(T[] a, U[] b, in void delegate(T*, U*) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length)
		cb(&a[i], &b[i]);
}

void zipPtrFirst(T, U)(T[] a, scope U[] b, in void delegate(T*, ref U) @safe @nogc pure nothrow cb) {
	assert(sizeEq(a, b));
	foreach (size_t i; 0 .. a.length)
		cb(&a[i], b[i]);
}

@trusted Out[] mapZip(Out, In0, In1)(
	ref Alloc alloc,
	scope In0[] in0,
	scope In1[] in1,
	in Out delegate(ref In0, ref In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	return makeArr(alloc, in0.length, (size_t i) =>
		cb(in0[i], in1[i]));
}

@trusted Out[] mapZipPtrFirst(Out, In0, In1)(
	ref Alloc alloc,
	In0[] in0,
	in In1[] in1,
	in Out delegate(In0*, in In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	return makeArr(alloc, in0.length, (size_t i) =>
		cb(&in0[i], in1[i]));
}

@trusted Out[] mapZipPointers3(Out, In0, In1, In2)(
	ref Alloc alloc,
	In0[] in0,
	In1[] in1,
	In2[] in2,
	in Out delegate(In0*, In1*, In2*) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1) && sizeEq(in1, in2));
	return makeArr(alloc, in0.length, (size_t i) =>
		cb(&in0[i], &in1[i], &in2[i]));
}

bool arrsCorrespond(T, U)(in T[] a, in U[] b, in bool delegate(in T, in U) @safe @nogc pure nothrow cb) =>
	sizeEq(a, b) && zipEvery!(T, U)(a, b, cb);

bool arrEqual(T)(in T[] a, in T[] b) =>
	arrsCorrespond!(T, T)(a, b, (in T x, in T y) => x == y);

private immutable struct MapAndFoldResult(Out, State) {
	Out[] output;
	State state;
}

immutable struct MapAndFold(Out, State) {
	Out output;
	State state;
}

@trusted MapAndFoldResult!(Out, State) mapAndFold(Out, State, In)(
	ref Alloc alloc,
	State start,
	in In[] a,
	in MapAndFold!(Out, State) delegate(in In, State) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	State endState = mapAndFoldRecur!(Out, State, In)(res.ptr, start, a.ptr, endPtr(a), cb);
	return MapAndFoldResult!(Out, State)(res, endState);
}

private @system State mapAndFoldRecur(Out, State, In)(
	Out* res,
	State state,
	in In* curIn,
	in In* endIn,
	in MapAndFold!(Out, State) delegate(in In, State) @safe @nogc pure nothrow cb,
) {
	if (curIn != endIn) {
		MapAndFold!(Out, State) mf = cb(*curIn, state);
		initMemory(res, mf.output);
		return mapAndFoldRecur!(Out, State, In)(res + 1, mf.state, curIn + 1, endIn, cb);
	} else
		return state;
}

T fold(T, U)(T start, in U[] arr, in T delegate(T a, in U b) @safe @nogc pure nothrow cb) =>
	empty(arr)
		? start
		: fold!(T, U)(cb(start, arr[0]), arr[1 .. $], cb);

Opt!T foldOrStop(T, U)(T start, in U[] arr, in Opt!T delegate(T a, ref U b) @safe @nogc pure nothrow cb) {
	if (empty(arr))
		return some(start);
	else {
		Opt!T next = cb(start, arr[0]);
		return has(next) ? foldOrStop!(T, U)(force(next), arr[1 .. $], cb) : none!T;
	}
}

N arrMax(N, T)(N start, in T[] a, in N delegate(in T) @safe @nogc pure nothrow cb) =>
	fold!(N, T)(start, a, (N curMax, in T x) => max(curMax, cb(x)));

size_t sum(T)(in T[] a, in size_t delegate(in T) @safe @nogc pure nothrow cb) =>
	fold!(size_t, T)(0, a, (size_t l, in T t) =>
		size_t(l + cb(t)));

size_t arrMaxIndex(T, U)(in U[] a, in T delegate(in U, size_t) @safe @nogc pure nothrow cb, Comparer!T compare) =>
	arrMaxIndexRecur!(T, U)(0, cb(a[0], 0), a, 1, cb, compare);

private size_t arrMaxIndexRecur(T, U)(
	size_t indexOfMax,
	in T maxValue,
	in U[] a,
	size_t index,
	in immutable(T) delegate(in U, size_t) @safe @nogc pure nothrow cb,
	in Comparer!T compare,
) {
	if (index == a.length)
		return indexOfMax;
	else {
		T valueHere = cb(a[index], index);
		return compare(valueHere, maxValue) == Comparison.greater
			// Using `index + 0` to avoid dscanner warning about 'index' not being the 0th parameter
			? arrMaxIndexRecur!(T, U)(index + 0, valueHere, a, index + 1, cb, compare)
			: arrMaxIndexRecur!(T, U)(indexOfMax, maxValue, a, index + 1, cb, compare);
	}
}

void eachPair(T)(in T[] a, in void delegate(in T, in T) @safe @nogc pure nothrow cb) {
	foreach (size_t i; 0 .. a.length)
		foreach (size_t j; i + 1 .. a.length)
			cb(a[i], a[j]);
}
