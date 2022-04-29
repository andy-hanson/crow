module util.memory;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateUninitialized;

@trusted void initMemory(T)(T* ptr, const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}
@trusted void initMemory(T)(T* ptr, ref const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@trusted void initMemory_mut(T)(T* ptr, scope ref T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@system ubyte* memcpy(return scope ubyte* dest, scope const ubyte* src, immutable size_t length) {
	return memmove(dest, src, length);
}

@system void memcpyWords(ulong* dest, scope const ulong* src, immutable size_t length) {
	foreach (immutable size_t i; 0 .. length)
		dest[i] = src[i];
}

@system ubyte* memmove(return scope ubyte* dest, scope const ubyte* src, immutable size_t length) {
	if (dest < src) {
		foreach (immutable size_t i; 0 .. length)
			dest[i] = src[i];
	} else {
		foreach_reverse (immutable size_t i; 0 .. length)
			dest[i] = src[i];
	}
	return dest;
}

@system ubyte* memset(return scope ubyte* dest, immutable ubyte value, immutable size_t length) {
	foreach (immutable size_t i; 0 .. length)
		dest[i] = value;
	return dest;
}

void overwriteMemory(T)(T* ptr, scope T value) {
	initMemory_mut!T(ptr, value);
}

@trusted immutable(T*) allocate(T)(scope ref Alloc alloc, immutable T value) {
	T* ptr = allocateUninitialized!T(alloc);
	initMemory!T(ptr, value);
	return cast(immutable) ptr;
}

@trusted T* allocateMut(T)(ref Alloc alloc, T value) {
	T* ptr = allocateUninitialized!T(alloc);
	initMemory_mut!T(ptr, value);
	return ptr;
}
