module util.collection.globalAllocatedStack;

@safe @nogc nothrow: // not pure (accesses global data)

import util.collection.arr : at, size;
import util.collection.arrUtil : copyArr;
import util.ptr : PtrRange;
import util.types : decr, Nat8, Nat32, Nat64, safeSizeTToU32, zero;
import util.util : verify;

struct GlobalAllocatedStack(T, size_t capacity) {
	@safe @nogc nothrow:

	~this() {
		verify(zero(size));
	}

	private:
	static T[capacity] values = void;
	static uint size = 0;
}

@system const(T*) begin(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.values.ptr;
}

@system const(T*) end(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.values.ptr + a.size;
}

@system const(PtrRange) stackPtrRange(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return const PtrRange(cast(const ubyte*) a.values.ptr, cast(const ubyte*) (a.values.ptr + a.size));
}

immutable(Nat32) stackSize(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return immutable Nat32(a.size);
}

void reduceStackSize(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable uint newSize) {
	verify(newSize <= a.size);
	a.size = newSize;
}

void clearStack(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	a.size = 0;
}

@trusted immutable(T[]) asTempArr(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return cast(immutable) a.values[0 .. a.size];
}

immutable(T[]) toArr(Alloc, T, size_t capacity)(ref Alloc alloc, ref const GlobalAllocatedStack!(T, capacity) a) {
	return copyArr(alloc, asTempArr(a));
}

void setToArr(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable T[] arr) {
	verify(size(arr) < capacity);
	foreach (immutable size_t i; 0 .. size(arr))
		a.values[i] = at(arr, i);
	a.size = safeSizeTToU32(size(arr));
}

immutable(bool) isEmpty(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.size == 0;
}

void push(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable T value) {
	verify(a.size != capacity);
	a.values[a.size] = value;
	a.size++;
}

void pushAll(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, scope immutable T[] values) {
	foreach (ref immutable T value; values)
		push(a, value);
}

immutable(T) peek(T, size_t capacity)(
	ref const GlobalAllocatedStack!(T, capacity) a,
	immutable Nat8 offset = immutable Nat8(0),
) {
	verify(offset.raw() < a.size);
	return a.values[a.size - 1 - offset.raw()];
}

// WARN: result is temporary!
@trusted immutable(Nat64[]) popN(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 n) {
	verify(a.size >= n.raw());
	a.size -= n.raw();
	return cast(immutable) a.values[a.size .. a.size + n.raw()];
}

immutable(T) pop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	verify(a.size != 0);
	a.size--;
	return a.values[a.size];
}

void dup(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 offset) {
	push(a, peek(a, offset));
}

immutable(T) remove(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 offset) {
	immutable T res = peek(a, offset);
	remove(a, offset, immutable Nat8(1));
	return res;
}

void remove(T, size_t capacity)(
	ref GlobalAllocatedStack!(T, capacity) a,
	immutable Nat8 offset,
	immutable Nat8 nEntries,
) {
	verify(!zero(nEntries));
	verify(offset >= decr(nEntries));
	verify(offset.raw() < a.size);
	foreach (immutable size_t i; a.size - 1 - offset.raw() .. a.size - nEntries.raw())
		a.values[i] = a.values[i + nEntries.raw()];
	a.size -= nEntries.raw();
}

T* stackRef(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 offset) {
	return &a.values[a.size - 1 - offset.raw()];
}
