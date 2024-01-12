module util.col.array;

import util.alloc.alloc : Alloc, allocateElements, freeElements;
import util.comparison : Comparer, Comparison;
import util.conv : safeToUshort;
import util.memory : copyToFrom, initMemory;
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

// Like SmallArray but without implying that it's an array
struct PtrAndSmallNumber(T) {
	@safe @nogc pure nothrow:

	private ulong value;

	private this(ulong v) {
		value = v;
	}
	this(inout T* ptr, ushort number) inout {
		static assert(ushort.max == 0xffff);
		ulong val = cast(ulong) ptr;
		assert((val & 0xffff_0000_0000_0000) == 0);
		value = ((cast(ulong) number) << 48) | val;
	}

	ulong asTaggable() const =>
		value;
	static PtrAndSmallNumber!T fromTagged(ulong x) =>
		PtrAndSmallNumber!T(x);

	@trusted inout(T*) ptr() inout =>
		cast(inout T*) (value & 0x0000_ffff_ffff_ffff);

	ushort number() const =>
		(value & 0xffff_0000_0000_0000) >> 48;
}

struct MutSmallArray(T) {
	@safe @nogc pure nothrow:
	alias toArray this;

	private this(PtrAndSmallNumber!T v) {
		sizeAndBegin = v;
	}

	ulong asTaggable() const =>
		sizeAndBegin.asTaggable;
	static MutSmallArray!T fromTagged(ulong x) =>
		MutSmallArray!T(PtrAndSmallNumber!T.fromTagged(x));

	@trusted this(inout T[] values) inout {
		sizeAndBegin = inout PtrAndSmallNumber!T(values.ptr, safeToUshort(values.length));
	}

	@trusted inout(T[]) toArray() inout {
		size_t length = sizeAndBegin.number;
		assert(length < 0xffff); // sanity check
		return sizeAndBegin.ptr()[0 .. length];
	}

	private:
	PtrAndSmallNumber!T sizeAndBegin;
}
alias SmallArray(T) = immutable MutSmallArray!T;

template small(T) {
	static if (is(T == immutable)) {
		SmallArray!T small(T)(T[] values) =>
			SmallArray!T(values);
	} else {
		inout(MutSmallArray!T) small(T)(inout T[] values) =>
			SmallArray!T(values);
	}
}

SmallArray!T emptySmallArray(T)() =>
	// Don't use `SmallArray!T([])` because that can't be evaluated at compile time
	SmallArray!T(PtrAndSmallNumber!T(0));

@system inout(T[]) arrayOfRange(T)(inout T* begin, inout T* end) {
	assert(begin <= end);
	return begin[0 .. end - begin];
}

bool sizeEq(T, U)(in T[] a, in U[] b) =>
	a.length == b.length;

bool isEmpty(T)(in T[] a) =>
	a.length == 0;

ref inout(T) only(T)(scope inout T[] a) {
	assert(a.length == 1);
	return a[0];
}

ref inout(T[2]) only2(T)(return scope inout T[] a) {
	assert(a.length == 2);
	return a[0 .. 2];
}

@trusted T[] arrayOfSingle(T)(T* a) =>
	a[0 .. 1];

@system T* endPtr(T)(T[] a) =>
	a.ptr + a.length;

@system bool isPointerInRange(T)(in T[] xs, in T* x) =>
	xs.ptr <= x && x < endPtr(xs);

@trusted T[] newArray(T)(ref Alloc alloc, scope T[] values) {
	T[] res = allocateElements!T(alloc, values.length);
	foreach (size_t i, ref T x; values)
		initMemory!T(&res[i], x);
	return res;
}

SmallArray!T newSmallArray(T)(ref Alloc alloc, scope T[] values) =>
	small!T(newArray(alloc, values));

@trusted Out[] makeArray(Out)(ref Alloc alloc, size_t size, in Out delegate(size_t) @safe @nogc pure nothrow cb) {
	Out[] res = allocateElements!Out(alloc, size);
	foreach (size_t i; 0 .. size)
		initMemory(&res[i], cb(i));
	return res;
}

@trusted Opt!(Out[]) makeArrayOrFail(Out)(
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

@trusted T[] fillArray(T)(ref Alloc alloc, size_t size, T value) =>
	makeArray(alloc, size, (size_t _) => value);

bool exists(T)(in T[] arr, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	has(findIndex!T(arr, cb));

bool every(T)(in T[] arr, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	everyWithIndex!T(arr, (size_t _, ref const T x) => cb(x));

bool everyWithIndex(T)(in T[] arr, in bool delegate(size_t, ref const T) @safe @nogc pure nothrow cb) {
	foreach (size_t i, ref const T x; arr)
		if (!cb(i, x))
			return false;
	return true;
}

bool allSame(Out, T)(in T[] arr, in Out delegate(in T) @safe @nogc pure nothrow cb) {
	if (isEmpty(arr))
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
	foreach (ref In x; a) {
		Opt!Out res = cb(&x);
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

SmallArray!T copyArray(T)(ref Alloc alloc, scope SmallArray!T a) =>
	small!T(copyArray(alloc, a.toArray));
T[] copyArray(T)(ref Alloc alloc, scope T[] a) =>
	map!(T, T)(alloc, a, (ref T x) => x);

@trusted Out[] map(Out, In)(
	ref Alloc alloc,
	scope In[] a,
	in Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i, ref In x; a)
		initMemory(&res[i], cb(x));
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

@system Out[] mapWithResultPointer(Out, In)(
	ref Alloc alloc,
	scope In[] a,
	in Out delegate(In*, Out*) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.length);
	foreach (size_t i; 0 .. a.length)
		initMemory(&res[i], cb(&a[i], &res[i]));
	return res[0 .. a.length];
}

Out[] mapPointersWithIndex(Out, In)(
	ref Alloc alloc,
	In[] a,
	in Out delegate(size_t, In*) @safe @nogc pure nothrow cb,
) =>
	mapPointers!(Out, In)(alloc, a, (In* x) @trusted => cb(x - a.ptr, x));

T[] concatenate(T)(ref Alloc alloc, T[] a, T[] b) =>
	isEmpty(a)
		? b
		: isEmpty(b)
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

bool zipEvery(T, U)(in T[] a, in U[] b, in bool delegate(ref const T, ref const U) @safe @nogc pure nothrow cb) {
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
	return makeArray(alloc, in0.length, (size_t i) =>
		cb(in0[i], in1[i]));
}

@trusted Out[] mapZipPtrFirst(Out, In0, In1)(
	ref Alloc alloc,
	In0[] in0,
	in In1[] in1,
	in Out delegate(In0*, in In1) @safe @nogc pure nothrow cb,
) {
	assert(sizeEq(in0, in1));
	return makeArray(alloc, in0.length, (size_t i) =>
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
	return makeArray(alloc, in0.length, (size_t i) =>
		cb(&in0[i], &in1[i], &in2[i]));
}

bool arraysCorrespond(T, U)(
	in T[] a,
	in U[] b,
	in bool delegate(ref const T, ref const U) @safe @nogc pure nothrow cb,
) =>
	sizeEq(a, b) && zipEvery!(T, U)(a, b, cb);

bool arraysEqual(T)(in T[] a, in T[] b) =>
	arraysCorrespond!(T, T)(a, b, (ref const T x, ref const T y) => x == y);

T fold(T, U)(T start, in U[] arr, in T delegate(T a, in U b) @safe @nogc pure nothrow cb) =>
	isEmpty(arr)
		? start
		: fold!(T, U)(cb(start, arr[0]), arr[1 .. $], cb);

Opt!T foldOrStop(T, U)(T start, in U[] arr, in Opt!T delegate(T a, ref U b) @safe @nogc pure nothrow cb) {
	if (isEmpty(arr))
		return some(start);
	else {
		Opt!T next = cb(start, arr[0]);
		return has(next) ? foldOrStop!(T, U)(force(next), arr[1 .. $], cb) : none!T;
	}
}

N max(N, T)(N start, in T[] a, in N delegate(in T) @safe @nogc pure nothrow cb) =>
	fold!(N, T)(start, a, (N curMax, in T x) => .max(curMax, cb(x)));

size_t sum(T)(in T[] a, in size_t delegate(in T) @safe @nogc pure nothrow cb) =>
	fold!(size_t, T)(0, a, (size_t l, in T t) =>
		size_t(l + cb(t)));

size_t indexOfMax(T, U)(in U[] a, in T delegate(size_t, in U) @safe @nogc pure nothrow cb, Comparer!T compare) =>
	indexOfMaxRecur!(T, U)(0, cb(0, a[0]), a, 1, cb, compare);

private size_t indexOfMaxRecur(T, U)(
	size_t indexOfMax,
	in T maxValue,
	in U[] a,
	size_t index,
	in immutable(T) delegate(size_t, in U) @safe @nogc pure nothrow cb,
	in Comparer!T compare,
) {
	if (index == a.length)
		return indexOfMax;
	else {
		T valueHere = cb(index, a[index]);
		return compare(valueHere, maxValue) == Comparison.greater
			// Using `index + 0` to avoid dscanner warning about 'index' not being the 0th parameter
			? indexOfMaxRecur!(T, U)(index + 0, valueHere, a, index + 1, cb, compare)
			: indexOfMaxRecur!(T, U)(indexOfMax, maxValue, a, index + 1, cb, compare);
	}
}

void eachPair(T)(in T[] a, in void delegate(in T, in T) @safe @nogc pure nothrow cb) {
	foreach (size_t i; 0 .. a.length)
		foreach (size_t j; i + 1 .. a.length)
			cb(a[i], a[j]);
}
