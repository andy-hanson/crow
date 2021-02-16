module interpret.externAlloc;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

struct ExternAlloc(Extern) {
	private Ptr!Extern extern_;

	@system ubyte* allocateBytesImpl(immutable size_t nBytes) {
		return extern_.malloc(nBytes);
	}

	@system void freeBytesImpl(ubyte* ptr, immutable size_t) {
		extern_.free(ptr);
	}
}
