module util.col.mutMaxArr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral, exists;
import util.memory : overwriteMemory;
import util.ptr : castNonScope;
import util.util : verify;

struct MutMaxArr(size_t maxSize, T) {
	// Current compilers will initialize 'values' even though it is marked '= void'.
	// See https://github.com/ldc-developers/ldc/issues/3249
	// To work around, you must call the function 'mutMaxArr' instead.
	@disable this();
	@disable this(ref const MutMaxArr);
	@disable void opAssign(ref const MutMaxArr);

	ref inout(T) opIndex(size_t i) inout {
		verify(i < size_);
		return values[i];
	}

	// TODO: not @trusted (values[0 .. size_] should work)
	@trusted int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope {
		foreach (scope ref T x; values.ptr[0 .. size_]) {
			int i = cb(x);
			verify(i == 0);
		}
		return 0;
	}

	private:
	size_t size_;
	T[maxSize] values = void;
}

size_t size(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_;

void clear(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	a.size_ = 0;
}

// TODO: 'b' must be mutable if T is
void copyToFrom(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, ref const MutMaxArr!(maxSize, T) b) {
	a.size_ = b.size_;
	foreach (size_t i, ref const T x; tempAsArr(b))
		overwriteMemory(&a.values[i], x);
}

immutable(T[]) toArray(size_t maxSize, T)(ref Alloc alloc, scope ref MutMaxArr!(maxSize, T) a) =>
	arrLiteral!T(alloc, tempAsArr(a));

bool isEmpty(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_ == 0;

bool isFull(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_ == maxSize;

size_t mutMaxArrSize(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a) =>
	a.size_;

void initializeMutMaxArr(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	a.size_ = 0;
}

@trusted MutMaxArr!(maxSize, T) mutMaxArr(size_t maxSize, T)() {
	MutMaxArr!(maxSize, T) res = void;
	initializeMutMaxArr(res);
	return res;
}

@system T* pushUninitialized(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	verify(a.size_ != maxSize);
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
	verify(values.length < maxSize);
	a.size_ = values.length;
	foreach (size_t i; 0 .. values.length)
		overwriteMemory(&a.values[i], cb(values[i]));
}

@trusted void push(size_t maxSize, T)(scope ref MutMaxArr!(maxSize, T) a, T value) {
	overwriteMemory(pushUninitialized(a), value);
}

void pushIfUnderMaxSize(size_t maxSize, T)(scope ref MutMaxArr!(maxSize, T) a, immutable T value) {
	if (a.size_ < maxSize)
		push(a, value);
}

ref inout(T) mustPeek(size_t maxSize, T)(ref inout MutMaxArr!(maxSize, T) a) {
	verify(a.size_ != 0);
	return a.values[a.size_ - 1];
}

T mustPop(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	verify(a.size_ != 0);
	a.size_--;
	return a.values[a.size_];
}

ref inout(T) only(size_t maxSize, T)(ref inout MutMaxArr!(maxSize, T) a) {
	verify(a.size_ == 1);
	return a.values[0];
}

@trusted inout(T[]) tempAsArr(size_t maxSize, T)(return scope ref inout MutMaxArr!(maxSize, T) a) =>
	castNonScope(a.values[0 .. a.size_]);

bool exists(size_t maxSize, T)(in MutMaxArr!(maxSize, T) a, in bool delegate(in T) @safe @nogc pure nothrow cb) =>
	.exists!T(tempAsArr(a), cb);

void filterUnorderedButDontRemoveAll(size_t maxSize, T)(
	scope ref MutMaxArr!(maxSize, T) a,
	in bool delegate(ref T) @safe @nogc pure nothrow pred,
	in void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	MutMaxArr!(maxSize, size_t) keep = mutMaxArr!(maxSize, size_t);
	foreach (size_t i, ref T x; tempAsArr(a)) {
		if (pred(x))
			push(keep, i);
	}
	if (!isEmpty(keep)) {
		foreach (size_t outI, size_t inI; tempAsArr(keep))
			if (inI != outI)
				overwrite(a.values[outI], a.values[inI]);
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
	verify(begin <= end);
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
