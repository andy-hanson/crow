module util.sexprPrint;

@safe @nogc nothrow: // not pure

import util.alloc.arena : Arena;
import util.ptr : ptrTrustMe_mut;
import util.print : print;
import util.sexpr : Sexpr, writeSexpr, writeSexprJSON;
import util.writer : finishWriterToCStr, Writer;

enum PrintFormat {
	sexpr,
	json,
}

void printOutSexpr(Alloc)(ref Alloc alloc, immutable Sexpr a, immutable PrintFormat format) {
	alias StrAlloc = Arena!(Alloc, "printOutSexpr");
	StrAlloc strAlloc = StrAlloc(ptrTrustMe_mut(alloc));
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
