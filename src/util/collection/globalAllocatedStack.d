module util.collection.globalAllocatedStack;

@safe @nogc nothrow: // not pure (accesses global data)

import util.bools : Bool;
import util.collection.arr : Arr, range;
import util.types : u8, u64;
import util.util : verify;

struct GlobalAllocatedStack(T, size_t capacity) {
	@safe @nogc nothrow:

	~this() {
		verify(size == 0);
	}

	private:
	static T[capacity] values = void;
	static size_t size = 0;
}

@system const(T*) begin(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.values.ptr;
}

void clearStack(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	a.size = 0;
}

@trusted immutable(Arr!T) asTempArr(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return immutable Arr!T(cast(immutable) a.values.ptr, a.size);
}

immutable(Bool) isEmpty(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return immutable Bool(a.size == 0);
}

void push(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable T value) {
	verify(a.size != capacity);
	a.values[a.size] = value;
	a.size++;
}

void pushAll(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, scope immutable Arr!T values) {
	foreach (ref immutable T value; range(values))
		push(a, value);
}

immutable(T) peek(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	verify(offset < a.size);
	return a.values[a.size - 1 - offset];
}

// WARN: result is temporary!
@trusted immutable(Arr!u64) popN(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable size_t n) {
	verify(a.size >= n);
	a.size -= n;
	return immutable Arr!u64(cast(immutable) (a.values.ptr + a.size), n);
}

immutable(T) pop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	verify(a.size != 0);
	a.size--;
	return a.values[a.size];
}

void dup(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	push(a, peek(a, offset));
}

immutable(T) remove(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	immutable T res = peek(a, offset);
	remove(a, offset, 1);
	return res;
}

void remove(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable u8 offset, immutable u8 nEntries) {
	verify(nEntries != 0);
	verify(offset >= nEntries - 1);
	verify(offset < a.size);
	foreach (immutable size_t i; a.size - 1 - offset..a.size - nEntries)
		a.values[i] = a.values[i + nEntries];
	a.size -= nEntries;
}

T* stackRef(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	return &a.values[a.size - 1 - offset];
}
