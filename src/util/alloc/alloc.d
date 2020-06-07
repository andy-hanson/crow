module util.alloc.alloc;

@safe @nogc pure nothrow:

import util.memory : myEmplace;

immutable(T) nu(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	T* memory = alloc.allocate(T.sizeof);
	myEmplace(memory, args);
}
