module util.col.arr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeT;
import util.ptr : Ptr;
import util.util : verify;

struct SmallArray(T) {
	@safe @nogc pure nothrow:
	alias toArray this;

	@disable this();

	@system static immutable(ulong) encode(immutable T[] values) {
		immutable ulong value = cast(immutable ulong) values.ptr;
		verify((values.length & 0xffff_ffff_ffff_0000) == 0);
		verify((value & 0xffff_0000_0000_0000) == 0);
		return (((cast(ulong) values.length) << 48) | value);
	}

	@system static immutable(T[]) decode(immutable ulong value) {
		immutable ulong highBits = value & 0xffff_0000_0000_0000;
		immutable ulong length = highBits >> 48;
		verify(length < 256); // sanity check
		immutable ulong lowBits = value & 0x0000_ffff_ffff_ffff;
		return (cast(immutable T*) lowBits)[0 .. length];
	}

	@trusted immutable this(immutable T[] values) {
		sizeAndBegin = encode(values);
	}

	@property @trusted immutable(T[]) toArray() immutable {
		return decode(sizeAndBegin);
	}

	private:
	immutable ulong sizeAndBegin;
}

immutable(SmallArray!T) small(T)(immutable T[] values) {
	return immutable SmallArray!T(values);
}

immutable(SmallArray!T) emptySmallArray(T)() {
	return small(emptyArr!T);
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
