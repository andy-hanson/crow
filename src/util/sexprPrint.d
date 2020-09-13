module util.sexprPrint;

@safe @nogc nothrow: // not pure

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc;
import util.collection.str : CStr;
import util.ptr : ptrTrustMe_mut;
import util.print : print;
import util.sexpr : Sexpr, writeSexpr;
import util.writer : finishWriterToCStr, Writer;

void printOutSexpr(immutable Sexpr a) {
	Mallocator mallocator;
	alias StrAlloc = SingleHeapAlloc!(Mallocator, "printOutSexpr", 4 * 1024 * 1024);
	StrAlloc strAlloc = StrAlloc(ptrTrustMe_mut(mallocator));
	Writer!StrAlloc writer = Writer!StrAlloc(ptrTrustMe_mut(strAlloc));
	writeSexpr(writer, a);
	print(finishWriterToCStr(writer));
}
