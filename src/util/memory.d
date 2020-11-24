module util.memory;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

@trusted void initMemory(T)(T* ptr, immutable T value) {
	// ptr may contain immutable members, so use memcpy to work around that.
	//memcpy(cast(void*) ptr, cast(const void*) &value, T.sizeof);
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}
@trusted void initMemory(T)(T* ptr, ref immutable T value) {
	// ptr may contain immutable members, so use memcpy to work around that.
	//memcpy(cast(void*) ptr, cast(const void*) &value, T.sizeof);
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@trusted void initMemory_mut(T)(T* ptr, ref T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@system void memcpy(ubyte* dest, const ubyte* src, immutable size_t length) {
	foreach (immutable size_t i; 0..length)
		dest[i] = src[i];
}

void overwriteMemory(T)(T* ptr, T value) {
	initMemory_mut!T(ptr, value);
}

immutable(Ptr!T) nu(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	return allocate(alloc, immutable T(args));
}

@trusted immutable(Ptr!T) allocate(T, Alloc)(ref Alloc alloc, immutable T value) {
	T* ptr = cast(T*) alloc.allocateBytes(T.sizeof);
	initMemory!T(ptr, value);
	return immutable Ptr!T(cast(immutable) ptr);
}

Ptr!T nuMut(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	return allocateMut(alloc, T(args));
}

private @trusted Ptr!T allocateMut(T, Alloc)(ref Alloc alloc, T value) {
	T* ptr = cast(T*) alloc.allocateBytes(T.sizeof);
	initMemory_mut!T(ptr, value);
	return Ptr!T(ptr);
}
