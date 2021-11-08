module util.memory;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes;
import util.ptr : Ptr;

@trusted void initMemory(T)(T* ptr, const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}
@trusted void initMemory(T)(T* ptr, ref const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@trusted void initMemory_mut(T)(T* ptr, ref T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@system ubyte* memcpy(return scope ubyte* dest, scope const ubyte* src, immutable size_t length) {
	foreach (immutable size_t i; 0 .. length)
		dest[i] = src[i];
	return dest;
}

@system ubyte* memmove(return scope ubyte* dest, scope const ubyte* src, immutable size_t length) {
	return memcpy(dest, src, length);
}

@system ubyte* memset(return scope ubyte* dest, immutable ubyte value, immutable size_t length) {
	foreach (immutable size_t i; 0 .. length)
		dest[i] = value;
	return dest;
}

void overwriteMemory(T)(T* ptr, T value) {
	initMemory_mut!T(ptr, value);
}

@trusted immutable(Ptr!T) allocate(T)(ref Alloc alloc, immutable T value) {
	T* ptr = cast(T*) allocateBytes(alloc, T.sizeof);
	initMemory!T(ptr, value);
	return immutable Ptr!T(cast(immutable) ptr);
}

@trusted Ptr!T allocateMut(T)(ref Alloc alloc, T value) {
	T* ptr = cast(T*) allocateBytes(alloc, T.sizeof);
	initMemory_mut!T(ptr, value);
	return Ptr!T(ptr);
}
