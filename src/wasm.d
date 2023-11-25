@safe @nogc nothrow: // not pure

import frontend.ide.getTokens : jsonOfTokens, Token;
import frontend.storage : asSafeCStr, FileContent, LineAndColumnGetters, ReadFileResult;
import interpret.fakeExtern : Pipe;
import lib.lsp.lspParse : parseLspInMessage;
import lib.lsp.lspToJson : jsonOfLspOutMessage;
import lib.lsp.lspTypes : LspInMessage, LspOutMessage, TextDocumentIdentifier, TextDocumentPositionParams;
import lib.server :
	getFile,
	getTokens,
	handleLspMessage,
	justParseEverything,
	LspOutAction,
	run,
	Server,
	setCwd,
	setFile,
	setIncludeDir,
	toUri,
	version_;
import model.diag : readFileDiagOfSym;
import util.alloc.alloc : Alloc, withStaticAlloc;
import util.col.arrUtil : map;
import util.col.str : CStr, SafeCStr;
import util.exitCode : ExitCode;
import util.json : field, jsonObject, Json, jsonToString, jsonList, jsonString, optionalField;
import util.jsonParse : mustParseJson;
import util.lineAndColumnGetter : LineAndCharacter;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.opt : force, has, Opt;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasureResult, perfTotal, withNullPerf;
import util.sym : symOfSafeCStr;
import util.uri : AllUris, parseUri, stringOfUri, Uri;

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
private ulong[900 * 1024 * 1024 / ulong.sizeof] serverBuffer = void;
// Used to pass strings in
private ulong[100 * 1024 * 1024 / ulong.sizeof] parameterBuffer = void;
// Used to pass strings out and for fake 'malloc' from 'callFakeExternFun'
private ulong[1000 * 1024 * 1024 / ulong.sizeof] resultBuffer = void;

// Currently only supports one server
private Server serverStorage = void;

@system extern(C) ubyte* getParameterBufferPointer() =>
	cast(ubyte*) parameterBuffer.ptr;

extern(C) size_t getParameterBufferSizeBytes() =>
	parameterBuffer.length * ulong.sizeof;

@system extern(C) Server* newServer(scope CStr includeDir, scope CStr cwd) {
	Server* server = &serverStorage;
	server.__ctor(serverBuffer);
	setIncludeDir(*server, parseUri(server.allUris, SafeCStr(includeDir)));
	setCwd(*server, parseUri(server.allUris, SafeCStr(cwd)));
	return server;
}

@system extern(C) CStr version_(Server* server) =>
	wasmCall!("version", CStr)((scope ref Perf _, ref Alloc resultAlloc) =>
		version_(resultAlloc, *server).ptr);

@system extern(C) void setFileSuccess(Server* server, scope CStr uri, scope CStr content) {
	SafeCStr uriStr = SafeCStr(uri);
	SafeCStr contentStr = SafeCStr(content);
	wasmCall!("setFileSuccess", void)((scope ref Perf perf, ref Alloc _) {
		setFile(perf, *server, toUri(*server, uriStr), ReadFileResult(FileContent(contentStr)));
	});
}

@system extern(C) void setFileIssue(Server* server, scope CStr uri, scope CStr issue) {
	SafeCStr uriStr = SafeCStr(uri);
	SafeCStr issueStr = SafeCStr(issue);
	wasmCall!("setFileIssue", void)((scope ref Perf perf, ref Alloc _) {
		setFile(perf, *server, toUri(*server, uriStr), ReadFileResult(
			readFileDiagOfSym(symOfSafeCStr(server.allSymbols, issueStr))));
	});
}

@system extern(C) CStr getFile(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getFile", CStr)((scope ref Perf _, ref Alloc _a) {
		Opt!FileContent res = getFile(*server, toUri(*server, uriStr));
		return has(res) ? asSafeCStr(force(res)).ptr : "";
	});
}

@system extern(C) void searchImportsFromUri(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("searchImportsFromUri", void)((scope ref Perf perf, ref Alloc resultAlloc) =>
		justParseEverything(perf, resultAlloc, *server, [toUri(*server, uriStr)]));
}

pure CStr urisToJson(ref Alloc alloc, in Server server, in Uri[] uris) =>
	jsonToString(alloc, server.allSymbols, jsonList(map(alloc, uris, (ref Uri x) =>
		jsonString(stringOfUri(alloc, server.allUris, x))))).ptr;

@system extern(C) CStr getTokens(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getTokens", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		Uri uri = toUri(*server, uriStr);
		Token[] res = getTokens(perf, resultAlloc, *server, uri);
		Json json = jsonOfTokens(resultAlloc, server.lineAndColumnGetters[uri], res);
		return jsonToString(resultAlloc, server.allSymbols, json);
	}).ptr;
}

@system extern(C) CStr handleLspMessage(Server* server, scope CStr input) {
	SafeCStr inputStr = SafeCStr(input);
	return wasmCall!("handleLspMessage", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		Json inputJson = mustParseJson(resultAlloc, server.allSymbols, inputStr);
		LspInMessage inputMessage = parseLspInMessage(resultAlloc, server.allUris, inputJson);
		LspOutAction output = handleLspMessage(perf, resultAlloc, *server, inputMessage);
		Json outputJson = jsonOfLspOutAction(resultAlloc, server.allUris, server.lineAndColumnGetters, output);
		return jsonToString(resultAlloc, server.allSymbols, outputJson);
	}).ptr;
}

pure Json jsonOfLspOutAction(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, in LspOutAction a) =>
	jsonObject(alloc, [
		field!"messages"(jsonList(map(alloc, a.outMessages, (ref LspOutMessage x) =>
			jsonOfLspOutMessage(alloc, allUris, lcg, x)))),
		optionalField!("exitCode", ExitCode)(a.exitCode, (in ExitCode x) =>
			Json(x.value))]);

@system extern(C) int run(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCallImpure!("run", ExitCode)((scope ref Perf perf, ref Alloc resultAlloc) =>
		run(perf, resultAlloc, *server, toUri(*server, uriStr), (Pipe pipe, in string x) @trusted {
			write(pipe, x.ptr, x.length);
		})).value;
}

pure TextDocumentPositionParams toTextDocumentPositionParams(
	scope ref Server server,
	in SafeCStr uri,
	uint line,
	uint character,
) =>
	TextDocumentPositionParams(TextDocumentIdentifier(toUri(server, uri)), LineAndCharacter(line, character));

extern(C) void write(Pipe pipe, scope immutable char* begin, size_t length);

// Not really pure, but JS doesn't know that
extern(C) pure ulong getTimeNanos();
extern(C) void perfLogMeasure(scope CStr name, uint count, ulong nanoseconds, uint bytesAllocated);
extern(C) void perfLogFinish(scope CStr name, ulong totalNanoseconds);

private:

T wasmCall(CStr name, T)(in T delegate(scope ref Perf, ref Alloc) @safe @nogc pure nothrow cb) =>
	wasmCallAlias!(name, T, cb)();
T wasmCallImpure(CStr name, T)(in T delegate(scope ref Perf, ref Alloc) @safe @nogc nothrow cb) =>
	wasmCallAlias!(name, T, cb)();

T wasmCallAlias(CStr name, T, alias cb)() =>
	withWebPerfAlias!(name, T, (scope ref Perf perf) @trusted =>
		withStaticAlloc!(T, (ref Alloc resultAlloc) =>
			cb(perf, resultAlloc)
		)(resultBuffer));

T withWebPerfAlias(CStr name, T, alias cb)() {
	if (perfEnabled) {
		scope Perf perf = Perf(() => getTimeNanos());
		static if (is(T == void)) {
			cb(perf);
		} else {
			T res = cb(perf);
		}
		eachMeasure(perf, (in SafeCStr name, in PerfMeasureResult m) {
			perfLogMeasure(name.ptr, m.count, m.nanoseconds, m.bytesAllocated);
		});
		perfLogFinish(name, perfTotal(perf));
		static if (!is(T == void)) {
			return res;
		}
	} else
		return withNullPerf!(T, cb);
}
