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

extern(C) @system pure ubyte* memset(return scope ubyte* dest, int c, size_t n) {
	// Can't reuse implementation from util.memory due to
	// https://github.com/ldc-developers/ldc/issues/3843#issuecomment-999247519
	foreach (size_t i; 0 .. n)
		dest[i] = cast(ubyte) c;
	return dest;
}

extern(C) @system pure int memcmp(scope const ubyte* s1, scope const ubyte* s2, size_t n) {
	foreach (size_t i; 0 .. n)
		if (s1[i] != s2[i])
			return s1[i] < s2[i] ? -1 : 1;
	return 0;
}

extern(C) @system pure void* memcpy(return scope ubyte* dest, scope const ubyte* src, size_t n) =>
	utilMemcpy(dest, src, n);

extern(C) @system pure void* memmove(return scope ubyte* dest, scope const ubyte* src, size_t n) =>
	utilMemmove(dest, src, n);

extern(C) size_t getGlobalBufferSizeBytes() =>
	globalBuffer.length * globalBuffer[0].sizeof;

@system extern(C) ubyte* getGlobalBufferPtr() =>
	cast(ubyte*) globalBuffer.ptr;

@system extern(C) Server* newServer(ubyte* allocStart, size_t allocLength) {
	Alloc alloc = Alloc(allocStart, allocLength);
	Server* ptr = allocateT!Server(alloc, 1);
	ptr.__ctor(alloc.move());
	return ptr;
}

@system extern(C) void addOrChangeFile(Server* server, scope CStr path, scope CStr content) {
	addOrChangeFile(*server, SafeCStr(path), SafeCStr(content));
}

@system extern(C) void deleteFile(Server* server, scope CStr path) {
	deleteFile(*server, SafeCStr(path));
}

@system extern(C) CStr getFile(Server* server, scope CStr path) =>
	getFile(*server, SafeCStr(path)).ptr;

@system extern(C) CStr getTokens(ubyte* resultStart, size_t resultLength, Server* server, scope CStr path) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	SafeCStr safePath = SafeCStr(path);
	Token[] tokens = withNullPerf!(Token[], (ref Perf perf) =>
		getTokens(resultAlloc, perf, *server, safePath));
	Repr repr = reprTokens(resultAlloc, tokens);
	return jsonStrOfRepr(resultAlloc, server.allSymbols, repr).ptr;
}

@system extern(C) CStr getParseDiagnostics(ubyte* resultStart, size_t resultLength, Server* server, scope CStr path) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	SafeCStr safePath = SafeCStr(path);
	StrParseDiagnostic[] diags = withNullPerf!(StrParseDiagnostic[], (ref Perf perf) =>
		getParseDiagnostics(resultAlloc, perf, *server, safePath));
	return jsonStrOfRepr(resultAlloc, server.allSymbols, reprParseDiagnostics(resultAlloc, diags)).ptr;
}

@system extern(C) CStr getHover(ubyte* resultStart, size_t resultLength, Server* server, scope CStr path, Pos pos) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	SafeCStr safePath = SafeCStr(path);
	return withNullPerf!(SafeCStr, (ref Perf perf) =>
		getHover(perf, resultAlloc, *server, safePath, pos)).ptr;
}

@system extern(C) CStr run(ubyte* resultStart, size_t resultLength, Server* server, scope CStr path) {
	Alloc resultAlloc = Alloc(resultStart, resultLength);
	FakeExternResult result = withWebPerf!FakeExternResult((scope ref Perf perf) =>
		run(perf, resultAlloc, *server, SafeCStr(path)));
	return writeRunResult(server.alloc, result);
}

// Not really pure, but JS doesn't know that
extern(C) pure ulong getTimeNanos();
extern(C) void perfLog(scope CStr name, ulong count, ulong nanoseconds, ulong bytesAllocated);

private:

@system T withWebPerf(T)(in T delegate(scope ref Perf perf) @nogc nothrow cb) {
	scope Perf perf = Perf(() => getTimeNanos());
	T res = cb(perf);
	eachMeasure(perf, (in SafeCStr name, in PerfMeasureResult m) {
		perfLog(name.ptr, m.count, m.nanoseconds, m.bytesAllocated);
	});
	return res;
}

// declaring as ulong[] to ensure it's word aligned
// Almost 2GB (which is size limit for a global array)
ulong[2000 * 1024 * 1024 / ulong.sizeof] globalBuffer;

Repr reprParseDiagnostics(ref Alloc alloc, scope StrParseDiagnostic[] a) =>
	reprArr!StrParseDiagnostic(alloc, a, (in StrParseDiagnostic it) =>
		reprNamedRecord!"diagnostic"(alloc, [
			nameAndRepr!"range"(reprRangeWithinFile(alloc, it.range)),
			nameAndRepr!"message"(reprStr(alloc, it.message))]));

CStr writeRunResult(ref Alloc alloc, in FakeExternResult result) {
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
