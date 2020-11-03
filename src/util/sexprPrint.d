module util.sexprPrint;

@safe @nogc nothrow: // not pure

import util.alloc.mallocator : Mallocator;
import util.alloc.stackAlloc : SingleHeapAlloc;
import util.ptr : ptrTrustMe_mut;
import util.print : print;
import util.sexpr : Sexpr, writeSexpr, writeSexprJSON;
import util.writer : finishWriterToCStr, Writer;

enum PrintFormat {
	sexpr,
	json,
}

void printOutSexpr(immutable Sexpr a, immutable PrintFormat format) {
	Mallocator mallocator;
	alias StrAlloc = SingleHeapAlloc!(Mallocator, "printOutSexpr", 4 * 1024 * 1024);
	StrAlloc strAlloc = StrAlloc(ptrTrustMe_mut(mallocator));
	Writer!StrAlloc writer = Writer!StrAlloc(ptrTrustMe_mut(strAlloc));
	final switch (format) {
		case PrintFormat.sexpr:
			writeSexpr(writer, a);
			break;
		case PrintFormat.json:
			writeSexprJSON(writer, a);
			break;
	}
	print(finishWriterToCStr(writer));
}
