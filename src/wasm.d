@safe @nogc nothrow: // not pure

import frontend.ast : sexprOfAst;
import frontend.getTokens : tokensOfAst, sexprOfTokens, Token;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.showDiag : ShowDiagOptions, strOfParseDiag;
import model.parseDiag : ParseDiagnostic;
import util.alloc.globalAlloc : globalAlloc, GlobalAlloc;
import util.bools : False;
import util.collection.arr : Arr, at, size;
import util.collection.str : NulTerminatedStr, nulTerminatedStrOfCStr, Str;
import util.ptr : ptrTrustMe_mut;
import util.sexpr : Sexpr, tataArr, tataNamedRecord, tataStr, writeSexprJSON;
import util.sourceRange : sexprOfRangeWithinFile;
import util.sym : AllSymbols;
import util.util : verify;
import util.writer : finishWriter, Writer;
import wasmUtils : wasmRun;

// seems to be the required entry point
extern(C) void _start() {}

extern(C) immutable(size_t) getBufferSize() {
	return bufferSize;
}

@system extern(C) char* getBuffer() {
	return buffer.ptr;
}

@system extern(C) void getTokens() {
	GlobalAlloc alloc = globalAlloc();
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable Str result = getTokensAndDiagnosticsJSON(alloc, str);
	writeResult(result);
}

@system extern(C) void getAst() {
	GlobalAlloc alloc = globalAlloc();
	AllSymbols!GlobalAlloc allSymbols = AllSymbols!GlobalAlloc(ptrTrustMe_mut(alloc));
	immutable NulTerminatedStr str = nulTerminatedStrOfCStr(cast(immutable) buffer.ptr);
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	writeAstResult(alloc, ast);
}

@system extern(C) void run() {
	GlobalAlloc alloc = globalAlloc();
	immutable Str result = wasmRun(alloc, buffer.ptr);
	writeResult(result);
}

private:

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(False);

immutable(Sexpr) sexprOfParseDiagnostic(Alloc)(ref Alloc alloc, ref immutable ParseDiagnostic a) {
	return tataNamedRecord(
		alloc,
		"diagnostic",
		"range", sexprOfRangeWithinFile(alloc, a.range),
		"message", tataStr(strOfParseDiag(alloc, showDiagOptions, a.diag)));
}

immutable(Str) getTokensAndDiagnosticsJSON(Alloc)(ref Alloc alloc, ref immutable NulTerminatedStr str) {
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
	return finishWriter(writer);
}

immutable size_t bufferSize = 1024 * 1024;
char[bufferSize] buffer;

//TODO: not trusted
@trusted void writeAstResult(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics ast) {
	immutable Sexpr sexpr = sexprOfAstAndParseDiagnostics(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	writeResult(finishWriter(writer));
}

immutable(Sexpr) sexprOfAstAndParseDiagnostics(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics a) {
	return tataNamedRecord(
		alloc,
		"ast-diags",
		"ast", sexprOfAst(alloc, a.ast),
		"diags", tataArr(alloc, a.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)));
}

@system void writeResult(immutable Str str) {
	verify(size(str) < bufferSize);
	foreach (immutable size_t i; 0..size(str)) {
		buffer[i] = at(str, i);
	}
	buffer[size(str)] = '\0';
}
