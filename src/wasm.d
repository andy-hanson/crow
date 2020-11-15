@safe @nogc nothrow: // not pure

import frontend.ast : sexprOfAst;
import frontend.getTokens : tokensOfAst, sexprOfTokens, Token;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.showDiag : strOfParseDiag;
import model.parseDiag : ParseDiagnostic;
import util.alloc.globalAlloc : GlobalAlloc;
import util.collection.arr : Arr;
import util.collection.str : CStr, NulTerminatedStr, nulTerminatedStrOfCStr;
import util.ptr : ptrTrustMe_mut;
import util.sexpr : Sexpr, tataArr, tataNamedRecord, tataStr, writeSexprJSON;
import util.sourceRange : sexprOfRangeWithinFile;
import util.sym : AllSymbols;
import util.writer : finishWriterToCStr, Writer;

// seems to be the required entry point
extern(C) void _start() {}

extern(C) immutable(size_t) getBufferSize() {
	return bufferSize;
}

@system extern(C) char* getBuffer() {
	return buffer.ptr;
}

@system extern(C) void getTokens() {
	alias Alloc = GlobalAlloc!("getTokens");
	Alloc alloc;
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable CStr result = getTokensAndDiagnosticsJSON(alloc, str);
	writeResult(result);
}

@system extern(C) void getAst() {
	alias Alloc = GlobalAlloc!("getAst");
	Alloc alloc;
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	writeAstResult(alloc, ast);
}

private:

immutable(Sexpr) sexprOfParseDiagnostic(Alloc)(ref Alloc alloc, ref immutable ParseDiagnostic a) {
	return tataNamedRecord(
		alloc,
		"diagnostic",
		"range", sexprOfRangeWithinFile(alloc, a.range),
		"message", tataStr(strOfParseDiag(alloc, a.diag)));
}

immutable(CStr) getTokensAndDiagnosticsJSON(Alloc)(ref Alloc alloc, ref immutable NulTerminatedStr str) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	immutable Arr!Token tokens = tokensOfAst(alloc, ast.ast);
	immutable Sexpr sexpr = tataNamedRecord(
		alloc,
		"tkns-diags",
		"tokens", sexprOfTokens(alloc, tokens),
		"diags", tataArr(alloc, ast.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)));
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	return finishWriterToCStr(writer);
}

immutable size_t bufferSize = 1024 * 1024;
char[bufferSize] buffer;

//TODO: not trusted
@trusted void writeAstResult(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics ast) {
	immutable Sexpr sexpr = sexprOfAstAndParseDiagnostics(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	writeResult(finishWriterToCStr(writer));
}

immutable(Sexpr) sexprOfAstAndParseDiagnostics(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics a) {
	return tataNamedRecord(
		alloc,
		"ast-diags",
		"ast", sexprOfAst(alloc, a.ast),
		"diags", tataArr(alloc, a.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)));
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
