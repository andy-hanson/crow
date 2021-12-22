@safe @nogc nothrow: // not pure

import frontend.ide.getTokens : reprTokens, Token;
import interpret.fakeExtern : FakeExternResult;
import lib.server :
	addOrChangeFile,
	deleteFile,
	getFile,
	getHover,
	getParseDiagnostics,
	getTokens,
	run,
	Server,
	StrParseDiagnostic;
import util.alloc.alloc : Alloc, allocateT;
import util.alloc.rangeAlloc : RangeAlloc;
import util.col.str : CStr, SafeCStr, strToCStr;
import util.dbg : Debug;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.path : StorageKind;
import util.perf : eachMeasure, Perf, PerfMeasureResult, withNullPerf;
import util.ptr : ptrTrustMe_mut;
import util.repr : Repr, jsonStrOfRepr, nameAndRepr, reprArr, reprNamedRecord, reprStr;
import util.sourceRange : Pos, reprRangeWithinFile;
import util.util : verify;
import util.writer : finishWriterToCStr, writeChar, writeNat, writeQuotedStr, Writer, writeStatic;

// seems to be the required entry point
extern(C) void _start() {}

extern(C) @system pure ubyte* memset(return scope ubyte* dest, immutable int c, immutable size_t n) {
	// Can't reuse implementation from util.memory due to
	// https://github.com/ldc-developers/ldc/issues/3843#issuecomment-999247519
	foreach (immutable size_t i; 0 .. n)
		dest[i] = cast(ubyte) c;
	return dest;
}

extern(C) @system pure int memcmp(scope const ubyte* s1, scope const ubyte* s2, immutable size_t n) {
	foreach (immutable size_t i; 0 .. n)
		if (s1[i] != s2[i])
			return s1[i] < s2[i] ? -1 : 1;
	return 0;
}

extern(C) @system pure void* memcpy(return scope ubyte* dest, scope const ubyte* src, immutable size_t n) {
	return utilMemcpy(dest, src, n);
}

extern(C) @system pure void* memmove(return scope ubyte* dest, scope const ubyte* src, immutable size_t n) {
	return utilMemmove(dest, src, n);
}

extern(C) immutable(size_t) getGlobalBufferSizeBytes() {
	return globalBuffer.length * globalBuffer[0].sizeof;
}

@system extern(C) ubyte* getGlobalBufferPtr() {
	return cast(ubyte*) globalBuffer.ptr;
}

@system extern(C) Server* newServer(
	ubyte* allocStart,
	immutable size_t allocLength,
) {
	RangeAlloc alloc = RangeAlloc(allocStart, allocLength);
	Server* ptr = allocateT!Server(alloc, 1);
	ptr.__ctor(alloc.move());
	return ptr;
}

@system extern(C) void addOrChangeFile(
	char* debugStart,
	immutable size_t debugLength,
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
	immutable char* contentStart,
	immutable size_t contentLength,
) {
	immutable string path = pathStart[0 .. pathLength];
	immutable string content = contentStart[0 .. contentLength];
	withWasmDebug!void(debugStart, debugLength, (scope ref Debug dbg) @trusted {
		addOrChangeFile(dbg, *server, storageKind, path, content);
	});
}

@system extern(C) void deleteFile(
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	deleteFile(*server, storageKind, pathStart[0 .. pathLength]);
}

@system extern(C) immutable(CStr) getFile(
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	return getFile(*server, storageKind, pathStart[0 .. pathLength]).ptr;
}

@system extern(C) immutable(CStr) getTokens(
	ubyte* resultStart, immutable size_t resultLength,
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart, immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	immutable Token[] tokens = withNullPerf!(immutable Token[], (scope ref Perf perf) =>
		getTokens(resultAlloc, perf, *server, storageKind, pathStart[0 .. pathLength]));
	immutable Repr repr = reprTokens(resultAlloc, tokens);
	return jsonStrOfRepr(resultAlloc, server.allSymbols, repr).ptr;
}

@system extern(C) immutable(CStr) getParseDiagnostics(
	ubyte* resultStart,
	immutable size_t resultLength,
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	immutable StrParseDiagnostic[] diags = withNullPerf!(immutable StrParseDiagnostic[], (scope ref Perf perf) =>
		getParseDiagnostics(resultAlloc, perf, *server, storageKind, pathStart[0 .. pathLength]));
	immutable Repr repr = reprParseDiagnostics(resultAlloc, diags);
	return jsonStrOfRepr(resultAlloc, server.allSymbols, repr).ptr;
}

@system extern(C) immutable(CStr) getHover(
	ubyte* resultStart,
	immutable size_t resultLength,
	char* debugStart,
	immutable size_t debugLength,
	Server* server,
	immutable StorageKind storageKind,
	immutable char* pathStart,
	immutable size_t pathLength,
	immutable Pos pos,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	immutable string path = pathStart[0 .. pathLength];
	immutable string hover = withWasmDebug!(immutable string)(debugStart, debugLength, (scope ref Debug dbg) =>
		withNullPerf!(immutable string, (scope ref Perf perf) =>
			getHover(dbg, perf, resultAlloc, *server, storageKind, path, pos)));
	return strToCStr(resultAlloc, hover);
}

@system extern(C) immutable(CStr) run(
	ubyte* resultStart,
	immutable size_t resultLength,
	char* debugStart,
	immutable size_t debugLength,
	Server* server,
	immutable char* pathStart,
	immutable size_t pathLength,
) {
	RangeAlloc resultAlloc = RangeAlloc(resultStart, resultLength);
	scope immutable string path = pathStart[0 .. pathLength];
	immutable FakeExternResult result = withWasmDebug!(immutable FakeExternResult)(
		debugStart,
		debugLength,
		(scope ref Debug dbg) =>
			withWebPerf!(immutable FakeExternResult)((scope ref Perf perf) =>
				run(dbg, perf, resultAlloc, *server, path)));
	return writeRunResult(server.alloc, result);
}

// Not really pure, but JS doesn't know that
extern(C) pure immutable(ulong) getTimeNanos();
extern(C) void perfLog(
	immutable char* name,
	immutable ulong count,
	immutable ulong nanoseconds,
	immutable ulong bytesAllocated);

private:

immutable(T) withWebPerf(T)(
	scope immutable(T) delegate(scope ref Perf perf) @safe @nogc nothrow cb,
) {
	scope Perf perf = Perf(() => getTimeNanos());
	immutable T res = cb(perf);
	eachMeasure(perf, (immutable SafeCStr name, immutable PerfMeasureResult m) {
		perfLog(name.ptr, m.count, m.nanoseconds, m.bytesAllocated);
	});
	return res;
}

@system immutable(T) withWasmDebug(T)(
	char* begin,
	immutable size_t size,
	scope immutable(T) delegate(scope ref Debug) @system @nogc nothrow cb,
) {
	verify(size > 0);
	char* ptr = begin;
	const char* end = begin + size;
	scope void delegate(immutable char) @safe @nogc pure nothrow writeChar = (immutable char a) {
		ptr = trustedDebugWrite(ptr, a, begin, end);
	};
	scope Debug dbg = Debug(
		writeChar,
		(scope immutable string a) {
			foreach (immutable char c; a)
				writeChar(c);
			writeChar('\n');
		});
	return cb(dbg);
}

pure @trusted char* trustedDebugWrite(char* ptr, immutable char a, char* begin, const char* end) {
	if (!(begin <= ptr))
		assert(0);
	if (!(ptr < end))
		assert(0);
	*ptr = a;
	ptr++;
	if (ptr == end)
		ptr = begin;
	if (!(begin <= ptr))
		assert(0);
	if (!(ptr < end))
		assert(0);
	return ptr;
}

// declaring as ulong[] to ensure it's word aligned
// Almost 2GB (which is size limit for a global array)
ulong[2047 * 1024 * 1024 / ulong.sizeof] globalBuffer;

immutable(Repr) reprParseDiagnostics(ref Alloc alloc, ref immutable StrParseDiagnostic[] a) {
	return reprArr(alloc, a, (ref immutable StrParseDiagnostic it) =>
		reprNamedRecord(alloc, "diagnostic", [
			nameAndRepr("range", reprRangeWithinFile(alloc, it.range)),
			nameAndRepr("message", reprStr(it.message))]));
}

immutable(CStr) writeRunResult(ref Alloc alloc, ref immutable FakeExternResult result) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeStatic(writer, "{\"err\":");
	writeNat(writer, result.err.value);
	writeStatic(writer, ",\"stdout\":");
	writeQuotedStr(writer, result.stdout);
	writeStatic(writer, ",\"stderr\":");
	writeQuotedStr(writer, result.stderr);
	writeChar(writer, '}');
	return finishWriterToCStr(writer);
}
