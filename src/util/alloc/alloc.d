module util.alloc.alloc;

@nogc pure nothrow: // not @safe

ubyte* allocateBytes(Alloc)(ref Alloc alloc, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	return alloc.allocateBytesImpl(size);
}

void freeBytes(Alloc)(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesImpl(ptr, size);
}

void freeBytesPartial(Alloc)(ref Alloc alloc, ubyte* ptr, immutable size_t size) {
	static assert(Alloc.stringof == "RangeAlloc");
	alloc.freeBytesPartialImpl(ptr, size);
}
