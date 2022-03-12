module util.col.arr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeT;
import util.ptr : Ptr;
import util.memory : overwriteMemory;
import util.util : verify;

struct ArrWithSize(T) {
	ubyte* sizeAndBegin_;
	@disable this();
	@system immutable this(immutable ubyte* p) { sizeAndBegin_ = p; }
}

@trusted immutable(T[]) toArr(T)(return scope immutable ArrWithSize!T a) {
	immutable T* begin = cast(immutable T*) (a.sizeAndBegin_ + size_t.sizeof);
	immutable size_t size = *(cast(immutable size_t*) a.sizeAndBegin_);
	return begin[0 .. size];
}

@trusted immutable(ArrWithSize!T) emptyArrWithSize(T)() {
	static immutable size_t zero = 0;
	return immutable ArrWithSize!T(cast(immutable ubyte*) &zero);
}

@system void freeArr(T)(ref Alloc alloc, immutable T[] a) {
	freeT!T(alloc, cast(T*) a.ptr, a.length);
}

@trusted T[] castMutable(T)(immutable T[] a) {
	return cast(T[]) a;
}

@trusted immutable(T[]) castImmutable(T)(T[] a) {
	return cast(immutable) a;
}

@system immutable(T[]) arrOfRange(T)(immutable T* begin, immutable T* end) {
	verify(begin <= end);
	return begin[0 .. end - begin];
}

@system T[] arrOfRange_mut(T)(T* begin, T* end) {
	verify(begin <= end);
	return begin[0 .. end - begin];
}

@trusted immutable(T[]) emptyArr(T)() {
	immutable T* begin = null;
	return begin[0 .. 0];
}

@trusted T[] emptyArr_mut(T)() {
	T* begin = null;
	return begin[0 .. 0];
}

immutable(bool) sizeEq(T, U)(scope const T[] a, scope const U[] b) {
	return a.length == b.length;
}

immutable(bool) empty(T)(const T[] a) {
	return a.length == 0;
}

@trusted inout(Ptr!T) ptrAt(T)(return scope inout T[] a, immutable size_t index) {
	verify(index < a.length);
	return inout Ptr!T(&a[index]);
}

@trusted void setAt(T)(scope T[] a, immutable size_t index, T value) {
	verify(index < a.length);
	overwriteMemory(&a[index], value);
}

ref immutable(T) only(T)(return scope immutable T[] a) {
	verify(a.length == 1);
	return a[0];
}
ref const(T) only_const(T)(const T[] a) {
	verify(a.length == 1);
	return a[0];
}

immutable(Ptr!T) lastPtr(T)(immutable T[] a) {
	verify(a.length != 0);
	return ptrAt(a, a.length - 1);
}

@trusted PtrsRange!T ptrsRange(T)(immutable T[] a) {
	return PtrsRange!T(a.ptr, a.ptr + a.length);
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
