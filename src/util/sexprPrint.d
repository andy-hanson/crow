module util.sexprPrint;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc;
import util.collection.str : CStr;
import util.ptr : ptrTrustMe_mut;
import util.sexpr : Sexpr, writeSexpr;
import util.writer : finishWriterToCStr, Writer;

void printOutSexpr(immutable Sexpr a) {
	Mallocator mallocator;
	alias StrAlloc = SingleHeapAlloc!(Mallocator, "printOutSexpr", 4 * 1024 * 1024);
	StrAlloc strAlloc = StrAlloc(ptrTrustMe_mut(mallocator));
	Writer!StrAlloc writer = Writer!StrAlloc(ptrTrustMe_mut(strAlloc));
	writeSexpr(writer, a);
	printCStr(finishWriterToCStr(writer));
}

private:


@trusted void printCStr(immutable CStr a) {
	printf("%s\n", a);
}
