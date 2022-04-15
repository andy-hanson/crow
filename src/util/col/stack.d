module util.col.stack;

@safe @nogc pure nothrow:

import util.util : verify;

struct Stack(T) {
	@safe @nogc pure nothrow:

	@disable this();
	@disable this(ref const Stack);

	@trusted this(T[] storage) {
		begin = storage.ptr;
		top = begin - 1;
		debug {
			end = begin + storage.length;
		}
	}

	@trusted ~this() {
		debug {
			verify(top == begin - 1);
		}
	}

	private:
	// Last-pushed value
	T* top;
	T* begin;
	debug {
		T* end;
	}
}

@trusted void clearStack(T)(ref Stack!T a) {
	a.top = a.begin - 1;
}

@trusted immutable(bool) stackIsEmpty(T)(ref const Stack!T a) {
	return a.top == a.begin - 1;
}

@trusted immutable(T[]) asTempArr(T)(ref const Stack!T a) {
	return cast(immutable) a.begin[0 .. stackSize(a)];
}

@trusted immutable(size_t) stackSize(T)(ref const Stack!T a) {
	return stackEnd(a) - stackBegin(a);
}

@system inout(T*) stackTop(T)(ref inout Stack!T a) {
	return a.top;
}

@system inout(T*) stackBeforeTop(T)(ref inout Stack!T a) {
	verify(!stackIsEmpty(a));
	return stackTop(a) - 1;
}

@system inout(T*) stackBegin(T)(ref inout Stack!T a) {
	return a.begin;
}

@system inout(T*) stackEnd(T)(ref inout Stack!T a) {
	return stackTop(a) + 1;
}

@system void setStackTop(T)(ref Stack!T a, T* top) {
	a.top = top;
}

@system void pushUninitialized(T)(ref Stack!T a, immutable size_t n) {
	a.top += n;
}

@system void push(T)(ref Stack!T a, immutable T value) {
	debug verify(a.top < a.end - 1);
	a.top++;
	*a.top = value;
}

@system immutable(T) peek(T)(ref const Stack!T a, immutable size_t offset = 0) {
	return *(a.top - offset);
}

// WARN: result is temporary!
@system immutable(T[]) popN(T)(return ref Stack!T a, immutable size_t n) {
	a.top -= n;
	return cast(immutable) a.top[1 .. n + 1];
}

@system immutable(T) pop(T)(ref Stack!T a) {
	immutable T res = *a.top;
	a.top--;
	return res;
}

@system immutable(T) remove(T)(ref Stack!T a, immutable size_t offset) {
	immutable T res = peek(a, offset);
	remove(a, offset, 1);
	return res;
}

@system void remove(T)(ref Stack!T a, immutable size_t offset, immutable size_t nEntries) {
	// For example, if offset = 0 and nEntries = 1, this pops the last element.
	verify(offset + 1 >= nEntries);
	T* outPtr = a.top - offset;
	T* inPtr = outPtr + nEntries;
	immutable size_t remaining = offset + 1 - nEntries;
	foreach (immutable size_t i; 0 .. remaining)
		outPtr[i] = inPtr[i];
	a.top -= nEntries;
}

@system T* stackRef(T)(ref Stack!T a, immutable size_t offset) {
	return a.top - offset;
}
