module util.memory;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

@trusted void initMemory(T)(T* ptr, T value) {
	static assert(__traits(isPOD, T));
	// ptr may contain immutable members, so use memcpy to work around that.
	//memcpy(cast(void*) ptr, cast(const void*) &value, T.sizeof);
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@system void memcpy(ubyte* dest, const ubyte* src, immutable size_t length) {
	foreach (immutable size_t i; 0..length)
		dest[i] = src[i];
}

void overwriteMemory(T)(T* ptr, T value) {
	initMemory(ptr, value);
}

@trusted void myEmplace(T, Args...)(T* ptr, Args args) {
	static if (__traits(compiles, (*ptr).__ctor(args)))
		(*ptr).__ctor(args);
	else static if(Args.length == 1 && is(Args[0] == T))
		initMemory!T(ptr, args);
	else
		initMemory!T(ptr, immutable T(args));
}

@trusted void myEmplace_mut(T, Args...)(T* ptr, Args args) {
	static if (__traits(compiles, (*ptr).__ctor(args)))
		(*ptr).__ctor(args);
	else static if(Args.length == 1 && is(Args[0] == T))
		initMemory!T(ptr, args);
	else
		initMemory!T(ptr, T(args));
}

struct DelayInit(T) {
	private T* ptr_;

	@trusted immutable(Ptr!T) ptr() const {
		return immutable Ptr!T(cast(immutable) ptr_);
	}

	@trusted immutable(Ptr!T) finish(Args...)(Args args) {
		myEmplace(ptr_, args);
		return immutable Ptr!T(cast(immutable) ptr_);
	}
}

@trusted DelayInit!T delayInit(T, Alloc)(ref Alloc alloc) {
	return DelayInit!T(cast(T*) alloc.allocate(T.sizeof));
}

@trusted immutable(Ptr!T) nu(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof);
	myEmplace(ptr, args);
	return immutable Ptr!T(cast(immutable) ptr);
}

@trusted immutable(Ptr!T) allocate(T, Alloc)(ref Alloc alloc, immutable T value) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof);
	initMemory(ptr, value);
	return immutable Ptr!T(cast(immutable) ptr);
}

@trusted Ptr!T nuMut(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	T* ptr = cast(T*) alloc.allocate(T.sizeof);
	myEmplace_mut(ptr, args);
	return Ptr!T(ptr);
}
