@safe @nogc nothrow: // not pure

import lib.lsp.lspParse : parseLspInMessage;
import lib.lsp.lspToJson : jsonOfLspOutAction;
import lib.lsp.lspTypes : LspInMessage, LspOutAction;
import lib.server : CbHandleUnknownUris, handleLspMessage, Server, setCwd, setIncludeDir;
import util.alloc.alloc : Alloc, FetchMemoryCb, withTempAlloc, withTempAllocImpure;
import util.col.str : CStr, SafeCStr;
import util.json : get, Json, jsonToString;
import util.jsonParse : mustParseJson;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.opt : none;
import util.perf : Perf, perfEnabled, PerfMeasure, PerfMeasureResult, PerfResult, perfResult, withNullPerf;
import util.uri : parseUri;
import util.util : safeCStrOfEnum;

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

private ulong[1024 * 1024 * 1024 / ulong.sizeof] serverBuffer = void;
// Currently only supports one server
private Server serverStorage = void;

// This just needs to be as big as the largest request sent to handleLspMessage.
private ubyte[1024 * 1024] parameterBuffer = void;
extern(C) ubyte* getParameterBufferPointer() => parameterBuffer.ptr;
extern(C) size_t getParameterBufferLength() => parameterBuffer.length;

// Like FetchMemoryCb but not pure
alias FetchMemoryCbImpure = ulong[] delegate(size_t sizeWords, size_t timesCalled) @system @nogc nothrow;

@system extern(C) Server* newServer(scope CStr paramsCStr) {
	Server* server = &serverStorage;
	FetchMemoryCbImpure fetchMemoryCb = (size_t sizeWords, size_t timesCalled) {
		assert(timesCalled == 0);
		return serverBuffer;
	};
	server.__ctor(cast(FetchMemoryCb) fetchMemoryCb);
	SafeCStr paramsStr = SafeCStr(paramsCStr);
	withTempAlloc!void(server.metaAlloc, (ref Alloc alloc) {
		Json params = mustParseJson(alloc, server.allSymbols, paramsStr);
		setIncludeDir(server, parseUri(server.allUris, get!"includeDir"(params).as!string));
		setCwd(*server, parseUri(server.allUris, get!"cwd"(params).as!string));
	});
	return server;
}

// Input and output are both temporary, should be parsed immediately
@system extern(C) CStr handleLspMessage(Server* server, scope CStr input) {
	SafeCStr inputStr = SafeCStr(input);
	return withWebPerf!(SafeCStr, (scope ref Perf perf) =>
		withTempAllocImpure!SafeCStr(server.metaAlloc, (ref Alloc resultAlloc) {
			Json inputJson = mustParseJson(resultAlloc, server.allSymbols, inputStr);
			LspInMessage inputMessage = parseLspInMessage(resultAlloc, server.allUris, inputJson);
			LspOutAction output = handleLspMessage(perf, resultAlloc, *server, inputMessage, none!CbHandleUnknownUris);
			Json outputJson = jsonOfLspOutAction(resultAlloc, server.allUris, server.lineAndColumnGetters, output);
			return jsonToString(resultAlloc, server.allSymbols, outputJson);
		})).ptr;
}

// Not really pure, but JS doesn't know that
extern(C) pure ulong getTimeNanos();
extern(C) void perfLogMeasure(scope CStr name, uint count, ulong nanoseconds, uint bytesAllocated);
extern(C) void perfLogFinish(scope CStr name, ulong totalNanoseconds);

private:

T withWebPerf(T, alias cb)() {
	if (perfEnabled) {
		scope Perf perf = Perf(() => getTimeNanos());
		static if (is(T == void)) {
			cb(perf);
		} else {
			T res = cb(perf);
		}
		PerfResult result = perfResult(perf);
		foreach (PerfMeasure measure, ref immutable PerfMeasureResult m; result.byMeasure)
			perfLogMeasure(safeCStrOfEnum(measure).ptr, m.count, m.nanoseconds, m.bytesAllocated);
		perfLogFinish("Total", result.totalNanoseconds);
		static if (!is(T == void)) {
			return res;
		}
	} else
		return withNullPerf!(T, cb);
}
