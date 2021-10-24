module util.alloc.alloc;

import util.alloc.rangeAlloc : RangeAlloc;

alias Alloc = RangeAlloc;
alias TempAlloc = Alloc;

@nogc pure nothrow: // not @safe

ubyte* allocateBytes(ref Alloc alloc, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	return alloc.allocateBytesImpl(size);
}

void freeBytes(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesImpl(ptr, size);
}

void freeBytesPartial(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesPartialImpl(ptr, size);
}
