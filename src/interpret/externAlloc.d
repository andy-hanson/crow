module interpret.externAlloc;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

struct ExternAlloc(Extern) {
	private Ptr!Extern extern_;

	@system ubyte* allocateBytes(immutable size_t nBytes) {
		return extern_.malloc(nBytes);
	}

	@system void freeBytes(ubyte* ptr, immutable size_t) {
		extern_.free(ptr);
	}
}
