module util.memory;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateUninitialized;

@trusted void initMemory(T)(T* ptr, const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}
@trusted void initMemory(T)(T* ptr, ref const T value) {
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@system ubyte* memcpy(return scope ubyte* dest, scope const ubyte* src, size_t length) =>
	memmove(dest, src, length);

@system ubyte* memmove(return scope ubyte* dest, scope const ubyte* src, size_t length) {
	if (dest < src) {
		foreach (size_t i; 0 .. length)
			dest[i] = src[i];
	} else {
		foreach_reverse (size_t i; 0 .. length)
			dest[i] = src[i];
	}
	return dest;
}

@system ubyte* memset(return scope ubyte* dest, ubyte value, size_t length) {
	foreach (size_t i; 0 .. length)
		dest[i] = value;
	return dest;
}

void overwriteMemory(T)(T* ptr, T value) {
	initMemory!T(ptr, value);
}

@trusted T* allocate(T)(scope ref Alloc alloc, T value) {
	T* ptr = allocateUninitialized!T(alloc);
	initMemory!T(ptr, value);
	return ptr;
}

@trusted void copyToFrom(T)(scope T[] dest, in T[] source) {
	assert(dest.length == source.length);
	cast(void) memcpy(cast(ubyte*) dest.ptr, cast(ubyte*) source.ptr, T.sizeof * dest.length);
}

// For clearing memory which should now be unused
@system void ensureMemoryClear(T)(T* ptr) {
	cast(void) memset(cast(ubyte*) ptr, 0xff, T.sizeof);
}
