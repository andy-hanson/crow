@safe @nogc nothrow: // not pure

import frontend.ast : sexprOfAst;
import frontend.getTokens : tokensOfAst, sexprOfTokens, Token;
import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.showDiag : ShowDiagOptions, strOfParseDiag;
import model.parseDiag : ParseDiagnostic;
import util.alloc.globalAlloc : globalAlloc, GlobalAlloc;
import util.bools : False;
import util.collection.arr : Arr, arrOfD, at, range, size;
import util.collection.str : NulTerminatedStr, nulTerminatedStrOfCStr, Str;
import util.ptr : ptrTrustMe_mut;
import util.sexpr : Sexpr, nameAndTata, tataArr, tataNamedRecord, tataStr, writeSexprJSON;
import util.sourceRange : sexprOfRangeWithinFile;
import util.sym : AllSymbols;
import util.util : min, verify;
import util.writer : finishWriter, Writer;
import wasmUtils : wasmRun;

// seems to be the required entry point
extern(C) void _start() {
}

extern(C) immutable(size_t) getBufferSize() {
	return buffer.length;
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

@system extern(C) void readDebugLog() {
	writeResult(arrOfD(cast(immutable) debugLogStorage));
}

@system extern(C) void run() {
	GlobalAlloc alloc = globalAlloc();
	WasmDebug dbg = wasmDebug();
	immutable Str result = wasmRun(dbg, alloc, cast(immutable) buffer.ptr);
	writeResult(result);
}

private:

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(False);

immutable(Sexpr) sexprOfParseDiagnostic(Alloc)(ref Alloc alloc, ref immutable ParseDiagnostic a) {
	return tataNamedRecord(alloc, "diagnostic", [
		nameAndTata("range", sexprOfRangeWithinFile(alloc, a.range)),
		nameAndTata("message", tataStr(strOfParseDiag(alloc, showDiagOptions, a.diag)))]);
}

immutable(Str) getTokensAndDiagnosticsJSON(Alloc)(ref Alloc alloc, ref immutable NulTerminatedStr str) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));
	immutable FileAstAndParseDiagnostics ast = parseFile(alloc, allSymbols, str);
	immutable Arr!Token tokens = tokensOfAst(alloc, ast.ast);
	immutable Sexpr sexpr = tataNamedRecord(alloc, "tkns-diags", [
		nameAndTata("tokens", sexprOfTokens(alloc, tokens)),
		nameAndTata("diags", tataArr(alloc, ast.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)))]);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	return finishWriter(writer);
}

char[1024 * 1024] buffer;

//TODO: not trusted
@trusted void writeAstResult(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics ast) {
	immutable Sexpr sexpr = sexprOfAstAndParseDiagnostics(alloc, ast);
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, sexpr);
	writeResult(finishWriter(writer));
}

immutable(Sexpr) sexprOfAstAndParseDiagnostics(Alloc)(ref Alloc alloc, ref immutable FileAstAndParseDiagnostics a) {
	return tataNamedRecord(alloc, "ast-diags", [
		nameAndTata("ast", sexprOfAst(alloc, a.ast)),
		nameAndTata("diags", tataArr(alloc, a.diagnostics, (ref immutable ParseDiagnostic it) =>
			sexprOfParseDiagnostic(alloc, it)))]);
}

@system void writeResult(immutable Str str) {
	immutable size_t bufferLength = buffer.length; // Using a variable to avoid dscanner warnings
	immutable size_t size = min(size(str), bufferLength - 1);
	foreach (immutable size_t i; 0..size)
		buffer[i] = at(str, i);
	buffer[size] = '\0';
}

struct WasmDebug {
	@safe @nogc pure nothrow:

	bool enabled() {
		// Enable this if there's a bug, but don't want it slowing things down otherwise
		return false;
	}

	void log(immutable Str s) {
		foreach (immutable char c; range(s))
			logChar(c);
		logChar('\n');
	}

	private:

	@disable this();
	@disable this(ref const WasmDebug);

	this(char* b, char* e) {
		verify(begin < end);
		begin = b;
		end = e;
		ptr = begin;
	}

	char* begin;
	char* end;
	char* ptr;

	@trusted void logChar(immutable char c) {
		if (!(begin <= ptr))
			assert(0);
		if (!(ptr < end))
			assert(0);
		*ptr = c;
		ptr++;
		if (ptr == end)
			ptr = begin;
		if (!(begin <= ptr))
			assert(0);
		if (!(ptr < end))
			assert(0);
	}
}

@trusted WasmDebug wasmDebug() {
	return WasmDebug(debugLogStorage.ptr, debugLogStorage.ptr + debugLogStorage.length);
}

char[8 * 1024 * 1024] debugLogStorage;
