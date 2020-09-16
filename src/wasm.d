@safe @nogc nothrow: // not pure

import frontend.parse : parseFile;
import frontend.ast : FileAst, sexprOfAst;
import parseDiag : ParseDiagnostic;
import util.alloc.globalAlloc : GlobalAlloc;
import util.collection.arr : Arr;
import util.collection.str : NulTerminatedStr, nulTerminatedStrOfCStr;
import util.ptr : ptrTrustMe_mut;
import util.result : matchResultImpure, Result;
import util.sexpr : Sexpr, writeSexprJSON;
import util.sym : AllSymbols;
import util.writer : finishWriterToCStr, Writer;

extern(C) immutable(size_t) getBufferSize() {
	return bufferSize;
}

@system extern(C) char* getBuffer() {
	return buffer.ptr;
}

@system extern(C) void getAst() {
	alias Alloc = GlobalAlloc!("getAst");
	Alloc alloc;
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable Result!(FileAst, Arr!ParseDiagnostic) rslt = parseFile(alloc, allSymbols, str);
	matchResultImpure!(void, FileAst, Arr!ParseDiagnostic)(
		rslt,
		(ref immutable FileAst ast) {
			writeAstResult(alloc, ast);
		},
		(ref immutable Arr!ParseDiagnostic) {
			writeEmptyResult();
		});
}

private:

immutable size_t bufferSize = 1024 * 1024;
char[bufferSize] buffer;

//TODO: not trusted
@trusted void writeAstResult(Alloc)(ref Alloc alloc, ref immutable FileAst ast) {
	immutable Sexpr astSexpr = sexprOfAst(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, astSexpr);
	writeResult(finishWriterToCStr(writer));
}

//TODO: not trusted
@trusted void writeEmptyResult() {
	writeResult("{}");
}

@system void writeResult(immutable(char)* str) {
	const char* end = buffer.ptr + buffer.length;
	for (char* ptr = buffer.ptr; ptr < end; ptr++) {
		immutable char c = *str;
		*ptr = c;
		if (c == '\0')
			break;
		str++;
	}
}

// seems to be the required entry point
extern(C) void _start() {}
