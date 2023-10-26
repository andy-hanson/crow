@safe @nogc nothrow: // not pure

import frontend.ide.getDefinition : Definition, jsonOfDefinition;
import frontend.ide.getTokens : jsonOfTokens;
import interpret.fakeExtern : Pipe;
import lib.compiler : ExitCode;
import lib.server :
	addOrChangeFile,
	deleteFile,
	getDefinition,
	getFile,
	getHover,
	getTokensAndParseDiagnostics,
	run,
	Server,
	StrParseDiagnostic,
	TokensAndParseDiagnostics,
	toUri;
import util.alloc.alloc : Alloc, allocateT;
import util.col.str : CStr, SafeCStr;
import util.json : field, jsonObject, Json, jsonToString, jsonList, jsonString, optionalField;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.opt : force, has, Opt;
import util.perf : eachMeasure, Perf, PerfMeasureResult, withNullPerf;
import util.sourceRange : Pos, jsonOfRangeWithinFile;
import util.uri : Uri;

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

@system extern(C) Server* newServer(scope CStr includeDir) {
	Alloc alloc = Alloc(serverBuffer);
	Server* ptr = allocateT!Server(alloc, 1);
	ptr.__ctor(alloc.move(), SafeCStr(includeDir));
	return ptr;
}

@system extern(C) void addOrChangeFile(Server* server, scope CStr uri, scope CStr content) {
	addOrChangeFile(*server, toUri(*server, SafeCStr(uri)), SafeCStr(content));
}

@system extern(C) void deleteFile(Server* server, scope CStr uri) {
	deleteFile(*server, toUri(*server, SafeCStr(uri)));
}

@system extern(C) CStr getFile(Server* server, scope CStr uri) =>
	getFile(*server, toUri(*server, SafeCStr(uri))).ptr;

@system extern(C) CStr getTokensAndParseDiagnostics(Server* server, scope CStr uriPtr) {
	Uri uri = toUri(*server, SafeCStr(uriPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	TokensAndParseDiagnostics res = withNullPerf!(TokensAndParseDiagnostics, (ref Perf perf) =>
		getTokensAndParseDiagnostics(resultAlloc, perf, *server, uri));
	return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
		field!"tokens"(jsonOfTokens(resultAlloc, res.tokens)),
		field!"parse-diagnostics"(jsonOfParseDiagnostics(resultAlloc, res.parseDiagnostics))])).ptr;
}

@system extern(C) CStr getDefinition(Server* server, scope CStr uriPtr, Pos pos) {
	Uri uri = toUri(*server, SafeCStr(uriPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(SafeCStr, (ref Perf perf) {
		Opt!Definition res = getDefinition(perf, resultAlloc, *server, uri, pos);
		return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
			optionalField!"definition"(has(res), () =>
				jsonOfDefinition(resultAlloc, server.allUris, force(res)))
		]));
	}).ptr;
}

@system extern(C) CStr getHover(Server* server, scope CStr uriPtr, Pos pos) {
	Uri uri = toUri(*server, SafeCStr(uriPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(CStr, (ref Perf perf) =>
		jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
			field!"hover"(getHover(perf, resultAlloc, *server, uri, pos)),
		])).ptr);
}

@system extern(C) int run(Server* server, scope CStr uriPtr) {
	Uri uri = toUri(*server, SafeCStr(uriPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	return withWebPerf!ExitCode((scope ref Perf perf) =>
		run(perf, resultAlloc, *server, uri, (Pipe pipe, in string x) @trusted {
			write(pipe, x.ptr, x.length);
		})).value;
}

extern(C) void write(Pipe pipe, scope immutable char* begin, size_t length);

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
