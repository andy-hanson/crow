module util.collection.globalAllocatedStack;

@safe @nogc nothrow: // not pure (accesses global data)

import util.bools : Bool;
import util.collection.arr : Arr, range;
import util.types : decr, Nat8, Nat32, Nat64, zero;
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

immutable(Nat32) stackSize(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return immutable Nat32(a.size);
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

immutable(T) peek(T, size_t capacity)(
	ref const GlobalAllocatedStack!(T, capacity) a,
	immutable Nat8 offset = immutable Nat8(0),
) {
	verify(offset.raw() < a.size);
	return a.values[a.size - 1 - offset.raw()];
}

// WARN: result is temporary!
@trusted immutable(Arr!Nat64) popN(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 n) {
	verify(a.size >= n.raw());
	a.size -= n.raw();
	return immutable Arr!Nat64(cast(immutable) (a.values.ptr + a.size), n.raw());
}

immutable(T) pop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	verify(a.size != 0);
	a.size--;
	return a.values[a.size];
}

void dup(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 offset) {
	debug {
		import core.stdc.stdio : printf;
		printf("GAS size: %u, peek %d\n", a.size, offset.raw());
	}
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
	foreach (immutable size_t i; a.size - 1 - offset.raw()..a.size - nEntries.raw())
		a.values[i] = a.values[i + nEntries.raw()];
	a.size -= nEntries.raw();
}

T* stackRef(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable Nat8 offset) {
	return &a.values[a.size - 1 - offset.raw()];
}