module util.memory;

@safe @nogc pure nothrow:

@trusted void initMemory(T)(T* ptr, T value) {
	static assert(__traits(isPOD, T));
	// ptr may contain immutable members, so use memcpy to work around that.
	//memcpy(cast(void*) ptr, cast(const void*) &value, T.sizeof);
	*(cast(byte[T.sizeof]*) ptr) = *(cast(const byte[T.sizeof]*) &value);
}

@trusted void myEmplace(T, Args...)(T* ptr, Args args) {
	static if (__traits(compiles, (*ptr).__ctor(args)))
		(*ptr).__ctor(args);
	else static if(Args.length == 1 && is(Args[0] == T))
		initMemory!T(ptr, args);
	else
		initMemory!T(ptr, immutable T(args));
}
