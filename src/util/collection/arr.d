module util.collection.arr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.ptr : Ptr;
import util.memory : overwriteMemory;
import util.types : Nat8, Nat32, Nat64;
import util.util : verify;

struct ArrWithSize(T) {
	ubyte* sizeAndBegin_;
	@disable this();
	@system immutable this(immutable ubyte* p) { sizeAndBegin_ = p; }
}

@trusted immutable(T[]) toArr(T)(ref immutable ArrWithSize!T a) {
	immutable T* begin = cast(immutable T*) (a.sizeAndBegin_ + size_t.sizeof);
	immutable size_t size = *(cast(immutable size_t*) a.sizeAndBegin_);
	return begin[0..size];
}

@trusted immutable(ArrWithSize!T) emptyArrWithSize(T)() {
	static immutable size_t zero = 0;
	return immutable ArrWithSize!T(cast(immutable ubyte*) &zero);
}

@system void freeArr(Alloc, T)(ref Alloc alloc, immutable T[] a) {
	alloc.freeBytes(cast(ubyte*) begin(a), size(a) * T.sizeof);
}

@trusted T[] castMutable(T)(immutable T[] a) {
	return cast(T[]) a;
}

@trusted immutable(T[]) castImmutable(T)(T[] a) {
	return cast(immutable) a;
}

@system immutable(T[]) arrOfRange(T)(immutable T* begin, immutable T* end) {
	verify(begin <= end);
	return begin[0..end - begin];
}

@system T[] arrOfRange_mut(T)(T* begin, T* end) {
	verify(begin <= end);
	return begin[0..end - begin];
}

@trusted immutable(T[]) emptyArr(T)() {
	immutable T* begin = null;
	return begin[0..0];
}

@trusted T[] emptyArr_mut(T)() {
	T* begin = null;
	return begin[0..0];
}

@system immutable(T*) begin(T)(immutable T[] a) {
	return a.ptr;
}
@system const(T*) begin(T)(const T[] a) {
	return a.ptr;
}
@system T* begin(T)(T[] a) {
	return a.ptr;
}

@system const(T*) end(T)(const T[] a) {
	return a.ptr + a.length;
}

immutable(Nat64) sizeNat(T)(const T[] a) {
	return immutable Nat64(a.length);
}

immutable(size_t) size(T)(const T[] a) {
	return a.length;
}

immutable(Bool) sizeEq(T, U)(const T[] a, const U[] b) {
	return immutable Bool(size(a) == size(b));
}

immutable(Bool) empty(T)(const T[] a) {
	return immutable Bool(size(a) == 0);
}

@trusted Ptr!T ptrAt(T)(return scope ref T[] a, immutable size_t index) {
	verify(index < size(a));
	return Ptr!T(&a[index]);
}

@trusted const(Ptr!T) ptrAt(T)(const T[] a, immutable size_t index) {
	verify(index < size(a));
	return const Ptr!T(&a[index]);
}

@trusted immutable(Ptr!T) ptrAt(T)(immutable T[] a, immutable size_t index) {
	verify(index < size(a));
	return immutable Ptr!T(&a[index]);
}
@trusted ref T at(T)(return scope T[] a, immutable size_t index) {
	verify(index < size(a));
	return a[index];
}
@trusted ref immutable(T) at(T)(ref immutable T[] a, immutable Nat8 index) {
	return at(a, index.raw());
}
@trusted ref immutable(T) at(T)(ref immutable T[] a, immutable Nat32 index) {
	return at(a, index.raw());
}

@trusted void setAt(T)(ref T[] a, immutable size_t index, T value) {
	verify(index < size(a));
	overwriteMemory(&a[index], value);
}

ref T first(T)(T[] a) {
	return at(a, 0);
}

ref immutable(T) only(T)(return scope ref immutable T[] a) {
	verify(size(a) == 1);
	return first(a);
}
ref const(T) only_const(T)(ref const T[] a) {
	verify(size(a) == 1);
	return first(a);
}

Ptr!T onlyPtr_mut(T)(ref T[] a) {
	verify(a.size == 1);
	return ptrAt(a, 0);
}

ref immutable(T) last(T)(ref immutable T[] a) {
	verify(size(a) != 0);
	return at(a, size(a) - 1);
}

@trusted PtrsRange!T ptrsRange(T)(ref immutable T[] a) {
	return PtrsRange!T(a.ptr, a.ptr + size(a));
}

private struct PtrsRange(T) {
	immutable(T)* begin;
	immutable(T)* end;

	bool empty() const {
		return begin >= end;
	}

	immutable(Ptr!T) front() const {
		return immutable Ptr!T(begin);
	}

	@trusted void popFront() {
		begin++;
	}
}
