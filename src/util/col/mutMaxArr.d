module util.col.mutMaxArr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral;
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

	ref inout(T) opIndex(immutable size_t i) inout {
		verify(i < size_);
		return values[i];
	}

	private:
	size_t size_;
	T[maxSize] values = void;
}

void copyToFrom(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, ref const MutMaxArr!(maxSize, T) b) {
	a.size_ = b.size_;
	foreach (immutable size_t i, ref const T x; tempAsArr(b))
		overwriteMemory(&a.values[i], x);
}

immutable(T[]) toArray(size_t maxSize, T)(ref Alloc alloc, return scope ref MutMaxArr!(maxSize, T) a) =>
	arrLiteral!T(alloc, tempAsArr(a));

immutable(bool) isEmpty(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) =>
	a.size_ == 0;

immutable(bool) isFull(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) =>
	a.size_ == maxSize;

immutable(size_t) mutMaxArrSize(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) =>
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
	immutable size_t size,
	immutable T value,
) {
	a.size_ = size;
	foreach (immutable size_t i; 0 .. size)
		overwriteMemory(&a.values[i], value);
}
void fillMutMaxArr_mut(size_t maxSize, T)(
	ref MutMaxArr!(maxSize, T) a,
	immutable size_t size,
	scope T delegate() @safe @nogc pure nothrow cb,
) {
	a.size_ = size;
	foreach (immutable size_t i; 0 .. size)
		overwriteMemory(&a.values[i], cb());
}

void mapTo(size_t maxSize, Out, In)(
	ref MutMaxArr!(maxSize, Out) a,
	scope immutable In[] values,
	scope immutable(Out) delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	verify(values.length < maxSize);
	a.size_ = values.length;
	foreach (immutable size_t i; 0 .. values.length)
		overwriteMemory(&a.values[i], cb(values[i]));
}
void mapTo_mut(size_t maxSize, Out, In)(
	ref MutMaxArr!(maxSize, Out) a,
	scope immutable In[] values,
	scope Out delegate(ref immutable In) @safe @nogc pure nothrow cb,
) {
	verify(values.length < maxSize);
	a.size_ = values.length;
	foreach (immutable size_t i; 0 .. values.length)
		overwriteMemory(&a.values[i], cb(values[i]));
}

@trusted void push(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, T value) {
	overwriteMemory(pushUninitialized(a), value);
}

void pushIfUnderMaxSize(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, immutable T value) {
	if (a.size_ < maxSize)
		push(a, value);
}

void pushLeft(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, T value) {
	verify(a.size_ != maxSize);
	a.size_++;
	foreach_reverse (immutable size_t i; 1 .. a.size_)
		overwriteMemory(&a.values[i], a.values[i - 1]);
	overwriteMemory(&a.values[0], value);
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

ref const(T) only_const(size_t maxSize, T)(ref const MutMaxArr!(maxSize, T) a) {
	verify(a.size_ == 1);
	return a.values[0];
}

@trusted immutable(T[]) tempAsArr(size_t maxSize, T)(return scope ref const MutMaxArr!(maxSize, T) a) =>
	cast(immutable) tempAsArr_const(a);
@trusted T[] tempAsArr_mut(size_t maxSize, T)(return ref MutMaxArr!(maxSize, T) a) =>
	a.values.ptr[0 .. a.size_];
@trusted const(T[]) tempAsArr_const(size_t maxSize, T)(return scope ref const MutMaxArr!(maxSize, T) a) =>
	castNonScope(a.values[0 .. a.size_]);

@trusted void filterUnordered(size_t maxSize, T)(
	scope ref MutMaxArr!(maxSize, T) a,
	scope immutable(bool) delegate(ref T) @safe @nogc pure nothrow pred,
	scope void delegate(ref T, ref const T) @safe @nogc pure nothrow overwrite,
) {
	T* begin = a.values.ptr;
	T* newEnd = filterUnorderedRecur!T(begin, begin + a.size_, pred, overwrite);
	a.size_ = newEnd - begin;
}

private:

@system T* filterUnorderedRecur(T)(
	T* begin,
	T* end,
	scope immutable(bool) delegate(ref T) @safe @nogc pure nothrow pred,
	scope void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
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
	scope immutable(bool) delegate(ref T) @safe @nogc pure nothrow pred,
	scope void delegate(ref T, ref T) @safe @nogc pure nothrow overwrite,
) {
	if (begin + 1 == end)
		return begin;
	else if (pred(*(end - 1))) {
		overwrite(*begin, *(end - 1));
		return filterUnorderedRecur!T(begin + 1, end - 1, pred, overwrite);
	} else
		return filterUnorderedFillHole!T(begin, end - 1, pred, overwrite);
}
