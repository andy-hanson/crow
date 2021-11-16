module util.alloc.alloc;

import util.alloc.rangeAlloc : RangeAlloc;

alias Alloc = RangeAlloc;
alias TempAlloc = Alloc;

@nogc pure nothrow: // not @safe

size_t curBytes(ref Alloc alloc) {
	return alloc.cur - alloc.end;
}

ubyte* allocateBytes(ref Alloc alloc, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	return alloc.allocateBytesImpl(size);
}

T* allocateT(T)(ref Alloc alloc, immutable size_t size) {
	return cast(T*) allocateBytes(alloc, T.sizeof * size);
}

void freeBytes(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesImpl(ptr, size);
}

void freeBytesPartial(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesPartialImpl(ptr, size);
}
