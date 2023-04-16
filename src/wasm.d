@safe @nogc nothrow: // not pure

import frontend.ide.getTokens : jsonOfTokens, Token;
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
	StrParseDiagnostic,
	toPath;
import util.alloc.alloc : Alloc, allocateT;
import util.col.str : CStr, SafeCStr;
import util.json : field, jsonObject, Json, jsonToString, jsonList, jsonString;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.path : Path;
import util.perf : eachMeasure, Perf, PerfMeasureResult, withNullPerf;
import util.ptr : ptrTrustMe;
import util.sourceRange : Pos, jsonOfRangeWithinFile;
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

// Used for the server (and compiler allocation)
private ulong[900 * 1024 * 1024 / ulong.sizeof] serverBuffer;
// Used to pass strings in
private ulong[100 * 1024 * 1024 / ulong.sizeof] parameterBuffer;
// Used to pass strings out and for fake 'malloc' from 'callFakeExternFun'
private ulong[1000 * 1024 * 1024 / ulong.sizeof] resultBuffer;

@system extern(C) ubyte* getParameterBufferPointer() =>
	cast(ubyte*) parameterBuffer.ptr;

extern(C) size_t getParameterBufferSizeBytes() =>
	parameterBuffer.length * ulong.sizeof;

@system extern(C) Server* newServer() {
	Alloc alloc = Alloc(serverBuffer);
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

@system extern(C) CStr getTokens(Server* server, scope CStr pathPtr) {
	Path path = toPath(*server, SafeCStr(pathPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	Token[] tokens = withNullPerf!(Token[], (ref Perf perf) =>
		getTokens(resultAlloc, perf, *server, path));
	return jsonToString(resultAlloc, server.allSymbols, jsonOfTokens(resultAlloc, tokens)).ptr;
}

@system extern(C) CStr getParseDiagnostics(Server* server, scope CStr pathPtr) {
	Path path = toPath(*server, SafeCStr(pathPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	StrParseDiagnostic[] diags = withNullPerf!(StrParseDiagnostic[], (ref Perf perf) =>
		getParseDiagnostics(resultAlloc, perf, *server, path));
	return jsonToString(resultAlloc, server.allSymbols, jsonOfParseDiagnostics(resultAlloc, diags)).ptr;
}

@system extern(C) CStr getHover(Server* server, scope CStr pathPtr, Pos pos) {
	Path path = toPath(*server, SafeCStr(pathPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(CStr, (ref Perf perf) =>
		jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
			field!"hover"(getHover(perf, resultAlloc, *server, path, pos)),
		])).ptr);
}

@system extern(C) CStr run(Server* server, scope CStr pathPtr) {
	Path path = toPath(*server, SafeCStr(pathPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	FakeExternResult result = withWebPerf!FakeExternResult((scope ref Perf perf) =>
		run(perf, resultAlloc, *server, path));
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

Json jsonOfParseDiagnostics(ref Alloc alloc, scope StrParseDiagnostic[] a) =>
	jsonList!StrParseDiagnostic(alloc, a, (in StrParseDiagnostic it) =>
		jsonObject(alloc, [
			field!"range"(jsonOfRangeWithinFile(alloc, it.range)),
			field!"message"(jsonString(alloc, it.message))]));

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
