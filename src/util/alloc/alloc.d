module util.alloc.alloc;

@safe @nogc pure nothrow:

import util.memory : initMemory, myEmplace;
import util.ptr : Ptr;

@trusted immutable(Ptr!T) nu(T, Alloc, Args...)(ref Alloc alloc, Args args) {
	T* memory = cast(T*) alloc.allocate(T.sizeof);
	myEmplace(memory, args);
	return immutable Ptr!T(cast(immutable) memory);
}

@trusted immutable(Ptr!T) nu2(T, Alloc)(ref Alloc alloc, immutable T t) {
	T* memory = cast(T*) alloc.allocate(T.sizeof);
	initMemory(memory, t);
	return immutable Ptr!T(cast(immutable) memory);
}
