module util.col.mutMaxArr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.array : newArray, reverseInPlace;
import util.memory : overwriteMemory;
import util.util : castNonScope;

struct MutMaxArr(size_t maxSize, T) {
	// Current compilers will initialize 'values' even though it is marked '= void'.
	// See https://github.com/ldc-developers/ldc/issues/3249
	// To work around, you must call the function 'mutMaxArr' instead.
	@disable this();
	@disable this(ref const MutMaxArr);
	@disable void opAssign(ref const MutMaxArr);

	ref inout(T) opIndex(size_t i) inout {
		assert(i < size_);
		return values[i];
	}

	@trusted int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope {
		foreach (ref T x; values[0 .. size_]) {
			int i = cb(x);
			assert(i == 0);
		}
		return 0;
	}
	@trusted int opApply(in int delegate(ref const T) @safe @nogc pure nothrow cb) scope const {
		foreach (ref const T x; values[0 .. size_]) {
			int res = cb(x);
			if (res != 0)
				return res;
		}
		return 0;
	}

	T* ptr() =>
		values.ptr;


	@trusted void opOpAssign(string op : "~")(T value) scope {
		overwriteMemory(pushUninitialized(this), value);
	}

	void opOpAssign(string op : "~")(in T[] values) {
		foreach (T value; values)
			this ~= value;
	}

	private:
	size_t size_;
	T[maxSize] values = void;
}

@trusted MutMaxArr!(maxSize, T) mutMaxArr(size_t maxSize, T)() {
	MutMaxArr!(maxSize, T) res = void;
	initializeMutMaxArr(res);
	return res;
}

void initializeMutMaxArr(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	a.size_ = 0;
}

size_t size(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_;

// TODO: 'b' must be mutable if T is
void copyToFrom(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, ref const MutMaxArr!(maxSize, T) b) {
	a.size_ = b.size_;
	foreach (size_t i, ref const T x; asTemporaryArray(b))
		overwriteMemory(&a.values[i], x);
}

immutable(T[]) toArray(size_t maxSize, T)(ref Alloc alloc, scope ref MutMaxArr!(maxSize, T) a) =>
	newArray!T(alloc, asTemporaryArray(a));

bool isEmpty(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_ == 0;

bool isFull(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_ == maxSize;

size_t mutMaxArrSize(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_;

@system T* pushUninitialized(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	assert(a.size_ != maxSize);
	T* res = a.values.ptr + a.size_;
	a.size_++;
	return res;
}

void fillMutMaxArr(size_t maxSize, T)(
	ref MutMaxArr!(maxSize, T) a,
	size_t size,
	in T delegate(size_t) @safe @nogc pure nothrow cb,
) {
	a.size_ = size;
	foreach (size_t i; 0 .. size)
		overwriteMemory(&a.values[i], cb(i));
}

void mapTo(size_t maxSize, Out, In)(
	ref MutMaxArr!(maxSize, Out) a,
	scope In[] values,
	in Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	assert(values.length < maxSize);
	a.size_ = values.length;
	foreach (size_t i; 0 .. values.length)
		overwriteMemory(&a.values[i], cb(values[i]));
}

T mustPop(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	assert(a.size_ != 0);
	a.size_--;
	return a.values[a.size_];
}

void mustPopAndDrop(size_t maxSize, T)(scope ref MutMaxArr!(maxSize, T) a) {
	assert(a.size_ != 0);
	a.size_--;
}

ref inout(T) only(size_t maxSize, T)(scope ref inout MutMaxArr!(maxSize, T) a) {
	assert(a.size_ == 1);
	return a.values[0];
}

@trusted inout(T[]) asTemporaryArray(size_t maxSize, T)(return scope ref inout MutMaxArr!(maxSize, T) a) =>
	castNonScope(a.values[0 .. a.size_]);

void reverseInPlace(size_t maxSize, T)(return scope ref inout MutMaxArr!(maxSize, T) a) =>
	.reverseInPlace(asTemporaryArray(a));

void filterUnorderedButDontRemoveAll(size_t maxSize, T)(
	scope ref MutMaxArr!(maxSize, T) a,
	in bool delegate(ref T) @safe @nogc pure nothrow pred,
	in void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	T[] values = asTemporaryArray(a);
	MutMaxArr!(maxSize, size_t) keep = mutMaxArr!(maxSize, size_t);
	foreach (size_t i, ref T x; values) {
		if (pred(x))
			keep ~= i;
	}
	if (!isEmpty(keep)) {
		foreach (size_t outI, size_t inI; asTemporaryArray(keep))
			if (inI != outI)
				overwrite(values[outI], values[inI]);
		a.size_ = keep.size;
	}
}

@trusted void filterUnordered(size_t maxSize, T)(
	scope ref MutMaxArr!(maxSize, T) a,
	in bool delegate(ref T) @safe @nogc pure nothrow pred,
	in void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	T* begin = a.values.ptr;
	T* newEnd = filterUnorderedRecur!T(begin, begin + a.size_, pred, overwrite);
	a.size_ = newEnd - begin;
}

private:

@system T* filterUnorderedRecur(T)(
	T* begin,
	T* end,
	in bool delegate(ref T) @safe @nogc pure nothrow pred,
	in void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	assert(begin <= end);
	return begin == end
		? end
		: pred(*begin)
		? filterUnorderedRecur!T(begin + 1, end, pred, overwrite)
		: filterUnorderedFillHole!T(begin, end, pred, overwrite);
}

// 'pred' is false for 'begin', so fill the hole
@system T* filterUnorderedFillHole(T)(
	T* begin,
	T* end,
	in bool delegate(ref T) @safe @nogc pure nothrow pred,
	in void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	if (begin + 1 == end)
		return begin;
	else if (pred(*(end - 1))) {
		overwrite(*begin, *(end - 1));
		return filterUnorderedRecur!T(begin + 1, end - 1, pred, overwrite);
	} else
		return filterUnorderedFillHole!T(begin, end - 1, pred, overwrite);
}
