module util.col.arr;

@safe @nogc pure nothrow:

import util.conv : safeToUshort;

// Like SmallArray but without implying that it's an array
immutable struct PtrAndSmallNumber(T) {
	@safe @nogc pure nothrow:

	private ulong value;

	private this(ulong v) {
		value = v;
	}
	this(immutable T* ptr, ushort number) {
		static assert(ushort.max == 0xffff);
		ulong val = cast(ulong) ptr;
		assert((val & 0xffff_0000_0000_0000) == 0);
		value = ((cast(ulong) number) << 48) | val;
	}

	ulong asTaggable() =>
		value;
	static PtrAndSmallNumber!T fromTagged(ulong x) =>
		PtrAndSmallNumber!T(x);

	@trusted immutable(T*) ptr() =>
		cast(immutable T*) (value & 0x0000_ffff_ffff_ffff);

	ushort number() =>
		(value & 0xffff_0000_0000_0000) >> 48;
}

immutable struct SmallArray(T) {
	@safe @nogc pure nothrow:
	alias toArray this;

	@disable this();
	private this(PtrAndSmallNumber!T v) {
		sizeAndBegin = v;
	}

	ulong asTaggable() =>
		sizeAndBegin.asTaggable;
	static SmallArray!T fromTagged(ulong x) =>
		SmallArray!T(PtrAndSmallNumber!T.fromTagged(x));

	@trusted this(immutable T[] values) {
		sizeAndBegin = PtrAndSmallNumber!T(values.ptr, safeToUshort(values.length));
	}

	@trusted immutable(T[]) toArray() {
		size_t length = sizeAndBegin.number;
		assert(length < 0xffff); // sanity check
		return sizeAndBegin.ptr()[0 .. length];
	}

	private:
	PtrAndSmallNumber!T sizeAndBegin;
}

SmallArray!(immutable T) small(T)(immutable T[] values) =>
	SmallArray!(immutable T)(values);

SmallArray!T emptySmallArray(T)() =>
	small!T([]);

@trusted T[] castMutable(T)(immutable T[] a) =>
	cast(T[]) a;

@trusted immutable(T[]) castImmutable(T)(T[] a) =>
	cast(immutable) a;

@system inout(T[]) arrayOfRange(T)(inout T* begin, inout T* end) {
	assert(begin <= end);
	return begin[0 .. end - begin];
}

bool sizeEq(T, U)(in T[] a, in U[] b) =>
	a.length == b.length;

bool empty(T)(in T[] a) =>
	a.length == 0;

ref inout(T) only(T)(return scope inout T[] a) {
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

@trusted PtrsRange!T ptrsRange(T)(T[] a) =>
	PtrsRange!T(a.ptr, endPtr(a));

private struct PtrsRange(T) {
	T* begin;
	T* end;

	bool empty() const =>
		begin >= end;

	inout(T*) front() inout =>
		begin;

	@trusted void popFront() {
		begin++;
	}
}
