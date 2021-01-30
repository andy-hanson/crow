@safe @nogc nothrow: // not pure

import frontend.ide.getTokens : reprTokens, Token;
import lib.server :
	addOrChangeFile,
	deleteFile,
	getFile,
	getHover,
	getParseDiagnostics,
	getTokens,
	run,
	RunResult,
	Server,
	StrParseDiagnostic;
import util.alloc.rangeAlloc : RangeAlloc;
import util.bools : Bool, False;
import util.collection.arr : Arr, size;
import util.collection.str : CStr, Str, strToCStr;
import util.path : StorageKind;
import util.ptr : ptrTrustMe_mut;
import util.repr : Repr, jsonStrOfRepr, nameAndRepr, reprArr, reprNamedRecord, reprStr;
import util.sourceRange : Pos, reprRangeWithinFile;
import util.util : verify;
import util.writer : finishWriterToCStr, writeChar, writeNat, writeQuotedStr, Writer, writeStatic;

// seems to be the required entry point
extern(C) void _start() {}

extern(C) immutable(size_t) getGlobalBufferSize() {
	return globalBuffer.length;
}

@system extern(C) ubyte* getGlobalBufferPtr() {
	return globalBuffer.ptr;
}

@system extern(C) Server!RangeAlloc* newServer(
	ubyte* allocStart,
	immutable size_t allocLength,
) {
	RangeAlloc alloc = RangeAlloc(allocStart, allocLength);
	Server!RangeAlloc* ptr = cast(Server!RangeAlloc*) alloc.allocateBytes((Server!RangeAlloc).sizeof);
	ptr.__ctor(alloc.move());
	return ptr;
}

@system extern(C) void addOrChangeFile(
	char* debugStart,
	immutable size_t debugLength,
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
	immutable char* contentStart,
	immutable size_t contentLength,
) {
	WasmDebug dbg = WasmDebug(debugStart, debugLength);
	immutable Str path = pathStart[0..pathLength];
	immutable Str content = contentStart[0..contentLength];
	addOrChangeFile(dbg, *server, storageKind, path, content);
}

@system extern(C) void deleteFile(
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	deleteFile(*server, storageKind, pathStart[0..pathLength]);
}

@system extern(C) immutable(CStr) getFile(
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	return getFile(*server, storageKind, pathStart[0..pathLength]);
}

@system extern(C) immutable(CStr) getTokens(
	ubyte* resultStart, immutable size_t resultLength,
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart, immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	immutable Arr!Token tokens = getTokens(resultAlloc, *server, storageKind, pathStart[0..pathLength]);
	immutable Repr repr = reprTokens(resultAlloc, tokens);
	return jsonStrOfRepr(resultAlloc, repr);
}

@system extern(C) immutable(CStr) getParseDiagnostics(
	ubyte* resultStart,
	immutable size_t resultLength,
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	immutable Arr!StrParseDiagnostic diags =
		getParseDiagnostics(resultAlloc, *server, storageKind, pathStart[0..pathLength]);
	immutable Repr repr = reprParseDiagnostics(resultAlloc, diags);
	return jsonStrOfRepr(resultAlloc, repr);
}

@system extern(C) immutable(CStr) getHover(
	ubyte* resultStart,
	immutable size_t resultLength,
	char* debugStart,
	immutable size_t debugLength,
	Server!RangeAlloc* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
	immutable Pos pos,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	WasmDebug dbg = WasmDebug(debugStart, debugLength);
	immutable Str path = pathStart[0..pathLength];
	immutable Str hover = getHover(dbg, resultAlloc, *server, storageKind, path, pos);
	return strToCStr(resultAlloc, hover);
}

@system extern(C) immutable(CStr) run(
	ubyte* resultStart,
	immutable size_t resultLength,
	char* debugStart,
	immutable size_t debugLength,
	Server!RangeAlloc* server,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	WasmDebug dbg = WasmDebug(debugStart, debugLength);
	immutable RunResult result = run(dbg, resultAlloc, *server, pathStart[0..pathLength]);
	return writeRunResult(server.alloc, result);
}

private:

ubyte[1024 * 1024 * 1024] globalBuffer;

immutable(Repr) reprParseDiagnostics(Alloc)(ref Alloc alloc, ref immutable Arr!StrParseDiagnostic a) {
	return reprArr(alloc, a, (ref immutable StrParseDiagnostic it) =>
		reprNamedRecord(alloc, "diagnostic", [
			nameAndRepr("range", reprRangeWithinFile(alloc, it.range)),
			nameAndRepr("message", reprStr(it.message))]));
}

struct WasmDebug {
	@safe @nogc pure nothrow:

	immutable(Bool) enabled() {
		// Enable this if there's a bug, but don't want it slowing things down otherwise
		return False;
	}

	void write(scope ref immutable Str a) {
		foreach (immutable char c; a)
			writeChar(c);
		writeChar('\n');
	}

	@trusted void writeChar(immutable char c) {
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

	private:

	@disable this();
	@disable this(ref const WasmDebug);

	@trusted this(char* b, immutable size_t size) {
		verify(size > 0);
		begin = b;
		end = b + size;
		ptr = begin;
	}

	char* begin;
	char* end;
	char* ptr;
}

immutable(CStr) writeRunResult(Alloc)(ref Alloc alloc, ref immutable RunResult result) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, "{\"err\":");
	writeNat(writer, result.err);
	writeStatic(writer, ",\"stdout\":");
	writeQuotedStr(writer, result.stdout);
	writeStatic(writer, ",\"stderr\":");
	writeQuotedStr(writer, result.stderr);
	writeChar(writer, '}');
	return finishWriterToCStr(writer);
}
