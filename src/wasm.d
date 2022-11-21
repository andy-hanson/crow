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
import util.col.str : CStr, SafeCStr;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.perf : eachMeasure, Perf, PerfMeasureResult, withNullPerf;
import util.ptr : ptrTrustMe;
import util.repr : Repr, jsonStrOfRepr, nameAndRepr, reprArr, reprNamedRecord, reprStr;
import util.sourceRange : Pos, reprRangeWithinFile;
import util.writer : finishWriterToCStr, writeQuotedStr, Writer;

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

extern(C) @system pure void* memcpy(return scope ubyte* dest, scope const ubyte* src, immutable size_t n) =>
	utilMemcpy(dest, src, n);

extern(C) @system pure void* memmove(return scope ubyte* dest, scope const ubyte* src, immutable size_t n) =>
	utilMemmove(dest, src, n);

extern(C) immutable(size_t) getGlobalBufferSizeBytes() =>
	globalBuffer.length * globalBuffer[0].sizeof;

@system extern(C) ubyte* getGlobalBufferPtr() =>
	cast(ubyte*) globalBuffer.ptr;

@system extern(C) Server* newServer(ubyte* allocStart, immutable size_t allocLength) {
	Alloc alloc = Alloc(allocStart, allocLength);
	Server* ptr = allocateT!Server(alloc, 1);
	ptr.__ctor(alloc.move());
	return ptr;
}

@system extern(C) void addOrChangeFile(Server* server, scope immutable CStr path, scope immutable CStr content) {
	addOrChangeFile(*server, immutable SafeCStr(path), immutable SafeCStr(content));
}

@system extern(C) void deleteFile(Server* server, scope immutable CStr path) {
	deleteFile(*server, immutable SafeCStr(path));
}

@system extern(C) immutable(CStr) getFile(Server* server, scope immutable CStr path) =>
	getFile(*server, immutable SafeCStr(path)).ptr;

@system extern(C) immutable(CStr) getTokens(
	ubyte* resultStart, immutable size_t resultLength,
	Server* server,
	scope immutable CStr path,
) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	immutable SafeCStr safePath = immutable SafeCStr(path);
	immutable Token[] tokens = withNullPerf!(immutable Token[], (ref Perf perf) =>
		getTokens(resultAlloc, perf, *server, safePath));
	immutable Repr repr = reprTokens(resultAlloc, tokens);
	return jsonStrOfRepr(resultAlloc, server.allSymbols, repr).ptr;
}

@system extern(C) immutable(CStr) getParseDiagnostics(
	ubyte* resultStart,
	immutable size_t resultLength,
	Server* server,
	scope immutable CStr path,
) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	immutable SafeCStr safePath = immutable SafeCStr(path);
	immutable StrParseDiagnostic[] diags = withNullPerf!(immutable StrParseDiagnostic[], (ref Perf perf) =>
		getParseDiagnostics(resultAlloc, perf, *server, safePath));
	immutable Repr repr = reprParseDiagnostics(resultAlloc, diags);
	return jsonStrOfRepr(resultAlloc, server.allSymbols, repr).ptr;
}

@system extern(C) immutable(CStr) getHover(
	ubyte* resultStart,
	immutable size_t resultLength,
	Server* server,
	scope immutable CStr path,
	immutable Pos pos,
) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	immutable SafeCStr safePath = immutable SafeCStr(path);
	return withNullPerf!(immutable SafeCStr, (ref Perf perf) =>
		getHover(perf, resultAlloc, *server, safePath, pos)).ptr;
}

@system extern(C) immutable(CStr) run(
	ubyte* resultStart,
	immutable size_t resultLength,
	Server* server,
	scope immutable CStr path,
) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	immutable FakeExternResult result = withWebPerf!(immutable FakeExternResult)((scope ref Perf perf) =>
		run(perf, resultAlloc, *server, immutable SafeCStr(path)));
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

@system immutable(T) withWebPerf(T)(
	scope immutable(T) delegate(scope ref Perf perf) @nogc nothrow cb,
) {
	scope Perf perf = Perf(() => getTimeNanos());
	immutable T res = cb(perf);
	eachMeasure(perf, (immutable SafeCStr name, immutable PerfMeasureResult m) {
		perfLog(name.ptr, m.count, m.nanoseconds, m.bytesAllocated);
	});
	return res;
}

// declaring as ulong[] to ensure it's word aligned
// Almost 2GB (which is size limit for a global array)
ulong[2000 * 1024 * 1024 / ulong.sizeof] globalBuffer;

immutable(Repr) reprParseDiagnostics(ref Alloc alloc, ref immutable StrParseDiagnostic[] a) =>
	reprArr(alloc, a, (ref immutable StrParseDiagnostic it) =>
		reprNamedRecord!"diagnostic"(alloc, [
			nameAndRepr!"range"(reprRangeWithinFile(alloc, it.range)),
			nameAndRepr!"message"(reprStr(it.message))]));

immutable(CStr) writeRunResult(ref Alloc alloc, ref immutable FakeExternResult result) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writer ~= "{\"err\":";
	writer ~= result.err.value;
	writer ~= ",\"stdout\":";
	writeQuotedStr(writer, result.stdout);
	writer ~= ",\"stderr\":";
	writeQuotedStr(writer, result.stderr);
	writer ~= '}';
	return finishWriterToCStr(writer);
}
