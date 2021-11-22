module util.collection.globalAllocatedStack;

@safe @nogc nothrow:

import util.alloc.alloc : Alloc;
import util.collection.arr : at, size;
import util.collection.arrUtil : copyArr;
import util.types : decr, Nat8, Nat32, safeSizeTToU32, zero;
import util.util : verify;

struct GlobalAllocatedStack(T, size_t capacity) {
	@safe @nogc nothrow: // not pure

	@disable this();
	@disable this(ref const GlobalAllocatedStack);

	@trusted this(bool ignore) {
		verify(!oneExists);
		oneExists = true;
		top = initialTop;
	}

	@trusted ~this() {
		verify(top == initialTop);
		verify(oneExists);
		oneExists = false;
	}

	private:
	@system static T* initialTop() { return STORAGE.ptr - 1; }
	static T[capacity] STORAGE = void;
	static bool oneExists = false;
	// Last-pushed value
	T* top;
}

@trusted void clearStack(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	a.top = GlobalAllocatedStack!(T, capacity).initialTop;
}

@trusted immutable(bool) stackIsEmpty(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.top == GlobalAllocatedStack!(T, capacity).initialTop;
}

@trusted immutable(T[]) asTempArr(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return cast(immutable) GlobalAllocatedStack!(T, capacity).STORAGE[0 .. stackSize(a)];
}

@trusted immutable(size_t) stackSize(T, size_t capacity)(ref const GlobalAllocatedStack!(T, capacity) a) {
	return a.top - stackBegin!(T, capacity)(a);
}

immutable(T[]) toArr(T, size_t capacity)(ref Alloc alloc, ref const GlobalAllocatedStack!(T, capacity) a) {
	return copyArr(alloc, asTempArr(a));
}

void setToArr(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, scope immutable T[] arr) {
	clearStack(a);
	foreach (immutable T value; arr)
		push(a, value);
}

@system T* stackTop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	return a.top;
}

@system inout(T*) stackBegin(T, size_t capacity)(ref inout GlobalAllocatedStack!(T, capacity) a) {
	return cast(inout) GlobalAllocatedStack!(T, capacity).initialTop;
}

@system T* stackEnd(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	return stackTop(a) + 1;
}

@system void setStackTop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, T* top) {
	a.top = top;
}

@system void pushUninitialized(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable size_t n) {
	a.top += n;
}

@trusted void push(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable T value) {
	debug verify(a.top < GlobalAllocatedStack!(T, capacity).STORAGE.ptr + capacity - 1);
	a.top++;
	*a.top = value;
}

//TODO: not @trusted
@trusted immutable(T) peek(T, size_t capacity)(
	ref const GlobalAllocatedStack!(T, capacity) a,
	immutable size_t offset = 0,
) {
	return *(a.top - offset);
}

// WARN: result is temporary!
@trusted immutable(T[]) popN(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable size_t n) {
	a.top -= n;
	return cast(immutable) a.top[1 .. n + 1];
}

@trusted immutable(T) pop(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a) {
	immutable T res = *a.top;
	a.top--;
	return res;
}

immutable(T) remove(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable size_t offset) {
	immutable T res = peek(a, offset);
	remove(a, offset, 1);
	return res;
}

@trusted void remove(T, size_t capacity)(
	ref GlobalAllocatedStack!(T, capacity) a,
	immutable size_t offset,
	immutable size_t nEntries,
) {
	// For example, if offset = 0 and nEntries = 1, this pops the last element.
	verify(offset + 1 >= nEntries);
	T* outPtr = a.top - offset;
	T* inPtr = outPtr + nEntries;
	immutable size_t remaining = offset + 1 - nEntries;
	foreach (immutable size_t i; 0 .. remaining)
		outPtr[i] = inPtr[i];
	a.top -= nEntries;
}

@system T* stackRef(T, size_t capacity)(ref GlobalAllocatedStack!(T, capacity) a, immutable size_t offset) {
	return a.top - offset;
}
