module util.collection.globalAllocatedStack;

@safe @nogc nothrow: // not pure (accesses global data)

import util.bools : Bool;
import util.collection.arr : Arr;
import util.types : u8, u64;
import util.util : verify;

struct GlobalAllocatedStack(T, size_t capacity) {
	@safe @nogc nothrow:

	static T[capacity] values = void;
	static size_t size = 0;
}

immutable(Bool) isEmpty(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return immutable Bool(a.size == 0);
}

void push(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, T value) {
	verify(a.size != capacity);
	a.values[a.size] = value;
	a.size++;
}

immutable(T) peek(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	verify(offset + 1 < a.size);
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
	verify(offset <= nEntries);
	verify(offset + 1 + nEntries < a.size);
	foreach (immutable size_t i; a.size - 1 - offset..a.size - nEntries)
		a.values[i] = a.values[i + nEntries];
	a.size -= nEntries;
}

T* stackRef(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable u8 offset) {
	return &a.values[a.size - 1 - offset];
}
