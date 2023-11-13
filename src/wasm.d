@safe @nogc nothrow: // not pure

import frontend.ide.getReferences : jsonOfReferences;
import frontend.ide.getTokens : jsonOfTokens;
import frontend.showModel : ShowOptions;
import interpret.fakeExtern : Pipe;
import lib.server :
	allLoadingUris,
	allStorageUris,
	allUnknownUris,
	getDefinition,
	getFile,
	getHover,
	getReferences,
	getTokensAndParseDiagnostics,
	justParseEverything,
	run,
	Server,
	setCwd,
	setDiagOptions,
	setFile,
	setFileFromTemp,
	setIncludeDir,
	showDiagnostic,
	TokensAndParseDiagnostics,
	toUri,
	typeCheckAllKnownFiles,
	version_;
import model.diag : Diagnostic;
import model.model : Program;
import util.alloc.alloc : Alloc, allocateT;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : map;
import util.col.multiMap : groupBy, MultiMap, multiMapEach;
import util.col.str : CStr, SafeCStr;
import util.exitCode : ExitCode;
import util.json : field, jsonObject, Json, jsonToString, jsonList, jsonString;
import util.lineAndColumnGetter : LineAndCharacter, UriLineAndCharacter;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.opt : force, has, Opt;
import util.perf : eachMeasure, Perf, PerfMeasureResult, withNullPerf;
import util.sourceRange : jsonOfRangeWithinFile, UriAndRange;
import util.storage : asSafeCStr, FileContent, readFileIssueOfSym, ReadFileResult;
import util.sym : symOfSafeCStr;
import util.uri : parseUri, Uri, uriToString;

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

@system extern(C) Server* newServer(scope CStr includeDir, scope CStr cwd) {
	Alloc alloc = Alloc(serverBuffer);
	Server* server = allocateT!Server(alloc, 1);
	server.__ctor(alloc.move());
	setIncludeDir(*server, parseUri(server.allUris, SafeCStr(includeDir)));
	setCwd(*server, parseUri(server.allUris, SafeCStr(cwd)));
	setDiagOptions(*server, ShowOptions(false));
	return server;
}

extern(C) CStr version_(Server* server) {
	Alloc resultAlloc = Alloc(resultBuffer);
	return version_(resultAlloc, *server).ptr;
}

@system extern(C) void setFileSuccess(Server* server, scope CStr uri, scope CStr content) {
	setFileFromTemp(*server, toUri(*server, SafeCStr(uri)), SafeCStr(content));
}

@system extern(C) void setFileIssue(Server* server, scope CStr uri, scope CStr issue) {
	setFile(*server, toUri(*server, SafeCStr(uri)), ReadFileResult(
		readFileIssueOfSym(symOfSafeCStr(server.allSymbols, SafeCStr(issue)))));
}

@system extern(C) CStr getFile(Server* server, scope CStr uri) {
	Alloc resultAlloc = Alloc(resultBuffer);
	Opt!FileContent res = getFile(resultAlloc, *server, toUri(*server, SafeCStr(uri)));
	return has(res) ? asSafeCStr(force(res)).ptr : "";
}

@system extern(C) void searchImportsFromUri(Server* server, scope CStr uriCStr) {
	Alloc resultAlloc = Alloc(resultBuffer);
	Uri uri = toUri(*server, SafeCStr(uriCStr));
	withNullPerf!(void, (ref Perf perf) {
		justParseEverything(resultAlloc, perf, *server, [uri]);
	});
}

// These are just getters; call 'justParseEverything' first to search for URIs
@system extern(C) CStr allStorageUris(Server* server) {
	Alloc resultAlloc = Alloc(resultBuffer);
	return urisToJson(resultAlloc, *server, allStorageUris(resultAlloc, *server));
}
@system extern(C) CStr allUnknownUris(Server* server) {
	Alloc resultAlloc = Alloc(resultBuffer);
	return urisToJson(resultAlloc, *server, allUnknownUris(resultAlloc, *server));
}
@system extern(C) CStr allLoadingUris(Server* server) {
	Alloc resultAlloc = Alloc(resultBuffer);
	return urisToJson(resultAlloc, *server, allLoadingUris(resultAlloc, *server));
}

CStr urisToJson(ref Alloc alloc, in Server server, in Uri[] uris) =>
	jsonToString(alloc, server.allSymbols, jsonList(map(alloc, uris, (ref Uri x) =>
		jsonString(uriToString(alloc, server.allUris, x))))).ptr;

@system extern(C) CStr getTokensAndParseDiagnostics(Server* server, scope CStr uriPtr) {
	Uri uri = toUri(*server, SafeCStr(uriPtr));
	Alloc resultAlloc = Alloc(resultBuffer);
	TokensAndParseDiagnostics res = withNullPerf!(TokensAndParseDiagnostics, (ref Perf perf) =>
		getTokensAndParseDiagnostics(resultAlloc, perf, *server, uri));
	return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
		field!"tokens"(jsonOfTokens(resultAlloc, server.lineAndColumnGetters[uri], res.tokens)),
		field!"parse-diagnostics"(jsonOfDiagnostics(resultAlloc, *server, res.programForDiagnostics))])).ptr;
}

@system extern(C) CStr getAllDiagnostics(Server* server) {
	Alloc resultAlloc = Alloc(resultBuffer);
	Program program = withNullPerf!(Program, (ref Perf perf) =>
		typeCheckAllKnownFiles(resultAlloc, perf, *server));
	return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [
		field!"diagnostics"(jsonOfDiagnostics(resultAlloc, *server, program))])).ptr;
}

@system extern(C) CStr getDefinition(Server* server, scope CStr uriPtr, uint line, uint character) {
	UriLineAndCharacter where = toUriLineAndCharacter(*server, SafeCStr(uriPtr), line, character);
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(SafeCStr, (ref Perf perf) {
		UriAndRange[] res = getDefinition(perf, resultAlloc, *server, where);
		Json json = jsonOfReferences(resultAlloc, server.allUris, server.lineAndColumnGetters, res);
		return jsonToString(resultAlloc, server.allSymbols, json);
	}).ptr;
}

@system extern(C) CStr getReferences(Server* server, scope CStr uriPtr, uint line, uint character) {
	UriLineAndCharacter where = toUriLineAndCharacter(*server, SafeCStr(uriPtr), line, character);
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(SafeCStr, (ref Perf perf) {
		UriAndRange[] references = getReferences(perf, resultAlloc, *server, where);
		return jsonToString(resultAlloc, server.allSymbols, jsonOfReferences(
			resultAlloc, server.allUris, server.lineAndColumnGetters, references));
	}).ptr;
}

@system extern(C) CStr getHover(Server* server, scope CStr uriPtr, uint line, uint character) {
	UriLineAndCharacter where = toUriLineAndCharacter(*server, SafeCStr(uriPtr), line, character);
	Alloc resultAlloc = Alloc(resultBuffer);
	return withNullPerf!(SafeCStr, (ref Perf perf) {
		SafeCStr hover = getHover(perf, resultAlloc, *server, where);
		return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [field!"hover"(hover)]));
	}).ptr;
}

UriLineAndCharacter toUriLineAndCharacter(scope ref Server server, SafeCStr uri, uint line, uint character) =>
	UriLineAndCharacter(toUri(server, uri), LineAndCharacter(line, character));

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

pure:

Json jsonOfDiagnostics(ref Alloc alloc, ref Server server, in Program program) {
	MultiMap!(Uri, Diagnostic) grouped =
		groupBy!(Uri, Diagnostic)(alloc, program.diagnostics.diags, (in Diagnostic x) =>
			x.where.uri);

	ArrBuilder!Json res;
	multiMapEach!(Uri, Diagnostic)(grouped, (Uri uri, in Diagnostic[] diags) {
		add(alloc, res, jsonObject(alloc, [
			field!"uri"(uriToString(alloc, server.allUris, uri)),
			field!"diagnostics"(jsonList!Diagnostic(alloc, diags, (in Diagnostic x) =>
				jsonOfDiagnostic(alloc, server, program, x)))]));
	});
	return jsonList(finishArr(alloc, res));
}

Json jsonOfDiagnostic(ref Alloc alloc, ref Server server, in Program program, in Diagnostic a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, server.lineAndColumnGetters, a.where)),
		field!"message"(jsonString(alloc, showDiagnostic(alloc, server, program, a)))]);
