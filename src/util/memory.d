module util.memory;

@safe @nogc pure nothrow:

@trusted void myEmplace(T, Args...)(T* ptr, Args args) {
	static if (__traits(compiles, (*ptr).__ctor(args)))
		(*ptr).__ctor(args);
	else static if(Args.length == 1 && is(Args[0] == T))
		initMemory!T(ptr, args);
	else
		initMemory!T(ptr, T(args));
}
