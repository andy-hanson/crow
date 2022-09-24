module util.col.arr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, freeT;
import util.conv : safeToUshort;
import util.util : verify;

// Like SmallArray but without implying that it's an array
struct PtrAndSmallNumber(T) {
	@safe @nogc pure nothrow:

	private immutable ulong value;

	private immutable this(immutable ulong v) {
		value = v;
	}
	immutable this(immutable T* ptr, immutable ushort number) {
		value = encode(ptr, number);
	}

	private static immutable(ulong) encode(immutable T* ptr, immutable ushort number) {
		immutable ulong val = cast(immutable ulong) ptr;
		verify((val & 0xffff_0000_0000_0000) == 0);
		return ((cast(ulong) number) << 48) | val;
	}

	@system immutable(ulong) asUlong() immutable =>
		value;

	static immutable(PtrAndSmallNumber!T) decode(immutable ulong value) =>
		immutable PtrAndSmallNumber!T(value);

	@trusted immutable(T*) ptr() immutable =>
		cast(immutable T*) (value & 0x0000_ffff_ffff_ffff);

	immutable(ushort) number() immutable =>
		(value & 0xffff_0000_0000_0000) >> 48;
}

struct SmallArray(T) {
	@safe @nogc pure nothrow:
	alias toArray this;

	@disable this();
	private immutable this(immutable PtrAndSmallNumber!T v) {
		sizeAndBegin = v;
	}

	@system static immutable(ulong) encode(immutable T[] values) =>
		(immutable SmallArray!T(values)).sizeAndBegin.value;

	@system static immutable(T[]) decode(immutable ulong value) =>
		(immutable SmallArray!T(PtrAndSmallNumber!T.decode(value))).toArray();

	@trusted immutable this(immutable T[] values) {
		sizeAndBegin = immutable PtrAndSmallNumber!T(values.ptr, safeToUshort(values.length));
	}

	@property @trusted immutable(T[]) toArray() immutable {
		immutable size_t length = sizeAndBegin.number;
		verify(length < 0xffff); // sanity check
		return sizeAndBegin.ptr()[0 .. length];
	}

	private:
	immutable PtrAndSmallNumber!T sizeAndBegin;
}

immutable(SmallArray!T) small(T)(immutable T[] values) =>
	immutable SmallArray!T(values);

immutable(SmallArray!T) emptySmallArray(T)() =>
	small!T([]);

@system void freeArr(T)(ref Alloc alloc, immutable T[] a) {
	freeT!T(alloc, cast(T*) a.ptr, a.length);
}

@trusted T[] castMutable(T)(immutable T[] a) =>
	cast(T[]) a;

@trusted immutable(T[]) castImmutable(T)(T[] a) =>
	cast(immutable) a;

@system immutable(T[]) arrOfRange(T)(immutable T* begin, immutable T* end) {
	verify(begin <= end);
	return begin[0 .. end - begin];
}

@system T[] arrOfRange_mut(T)(T* begin, T* end) {
	verify(begin <= end);
	return begin[0 .. end - begin];
}

immutable(bool) sizeEq(T, U)(scope const T[] a, scope const U[] b) =>
	a.length == b.length;

immutable(bool) empty(T)(const T[] a) =>
	a.length == 0;

ref immutable(T) only(T)(return scope immutable T[] a) {
	verify(a.length == 1);
	return a[0];
}
ref const(T) only_const(T)(const T[] a) {
	verify(a.length == 1);
	return a[0];
}

@trusted PtrsRange!T ptrsRange(T)(immutable T[] a) =>
	PtrsRange!T(a.ptr, a.ptr + a.length);

private struct PtrsRange(T) {
	immutable(T)* begin;
	immutable(T)* end;

	bool empty() const =>
		begin >= end;

	immutable(T*) front() const =>
		begin;

	@trusted void popFront() {
		begin++;
	}
}
