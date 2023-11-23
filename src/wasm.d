@safe @nogc nothrow: // not pure

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import frontend.ide.getRename : jsonOfRename, Rename;
import frontend.ide.getReferences : jsonOfReferences;
import frontend.ide.getTokens : jsonOfTokens, Token;
import frontend.showDiag : sortedDiagnostics, sortedDiagnosticsForUri, UriAndDiagnostics;
import frontend.showModel : ShowOptions;
import frontend.storage : asSafeCStr, FileContent, ReadFileResult;
import interpret.fakeExtern : Pipe;
import lib.lsp.lspParse : parseChangeEvents;
import lib.server :
	allLoadingUris,
	allStorageUris,
	allUnknownUris,
	changeFile,
	getDefinition,
	getFile,
	getHover,
	getRename,
	getReferences,
	getTokens,
	justParseEverything,
	justTypeCheck,
	run,
	Server,
	setCwd,
	setDiagOptions,
	setFile,
	setIncludeDir,
	showDiag,
	toUri,
	typeCheckAllKnownFiles,
	version_;
import model.diag : Diagnostic, DiagnosticSeverity, readFileDiagOfSym;
import model.model : Program;
import util.alloc.alloc : Alloc, withStaticAlloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : map;
import util.col.str : CStr, eachSplit, SafeCStr, strOfSafeCStr;
import util.exitCode : ExitCode;
import util.json : field, jsonObject, Json, jsonToString, jsonList, jsonString;
import util.lineAndColumnGetter : LineAndCharacter, UriLineAndCharacter;
import util.memory : utilMemcpy = memcpy, utilMemmove = memmove;
import util.opt : force, has, Opt;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasureResult, perfTotal, withNullPerf;
import util.sourceRange : jsonOfRange, UriAndRange;
import util.sym : symOfSafeCStr;
import util.uri : parseUri, stringOfUri, Uri;

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
	setDiagOptions(*server, ShowOptions(false));
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

@system extern(C) void changeFile(Server* server, scope CStr uri, scope CStr changes) {
	SafeCStr uriStr = SafeCStr(uri);
	SafeCStr changesStr = SafeCStr(changes);
	wasmCall!("changeFile", void)((scope ref Perf perf, ref Alloc alloc) {
		changeFile(perf, *server, toUri(*server, uriStr), parseChangeEvents(alloc, server.allSymbols, changesStr));
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

// These are just getters; call 'justParseEverything' first to search for URIs
@system extern(C) CStr allStorageUris(Server* server) =>
	wasmCall!("allStorageUris", CStr)((scope ref Perf _, ref Alloc resultAlloc) =>
		urisToJson(resultAlloc, *server, allStorageUris(resultAlloc, *server)));

@system extern(C) CStr allUnknownUris(Server* server) =>
	wasmCall!("allUnknownUris", CStr)((scope ref Perf _, ref Alloc resultAlloc) =>
		urisToJson(resultAlloc, *server, allUnknownUris(resultAlloc, *server)));

@system extern(C) CStr allLoadingUris(Server* server) =>
	wasmCall!("allLoadingUris", CStr)((scope ref Perf _, ref Alloc resultAlloc) =>
		urisToJson(resultAlloc, *server, allLoadingUris(resultAlloc, *server)));

pure CStr urisToJson(ref Alloc alloc, in Server server, in Uri[] uris) =>
	jsonToString(alloc, server.allSymbols, jsonList(map(alloc, uris, (ref Uri x) =>
		jsonString(stringOfUri(alloc, server.allUris, x))))).ptr;

@system extern(C) CStr getTokens(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getTokens", CStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		Uri uri = toUri(*server, uriStr);
		Token[] res = getTokens(perf, resultAlloc, *server, uri);
		Json json = jsonOfTokens(resultAlloc, server.lineAndColumnGetters[uri], res);
		return jsonToString(resultAlloc, server.allSymbols, json).ptr;
	});
}


@system extern(C) CStr getAllDiagnostics(Server* server) =>
	wasmCall!("getAllDiagnostics", CStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		Program program = typeCheckAllKnownFiles(perf, resultAlloc, *server);
		return jsonToString(resultAlloc, server.allSymbols, jsonOfDiagnostics(resultAlloc, *server, program)).ptr;
	});

@system extern(C) CStr getDiagnosticsForUri(Server* server, scope CStr uriCStr, uint minSeverity) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getDiagnosticsForUri", CStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		Uri uri = toUri(*server, uriStr);
		Program program = justTypeCheck(perf, resultAlloc, *server, [uri]);
		Diagnostic[] diags = sortedDiagnosticsForUri(resultAlloc, program, uri, cast(DiagnosticSeverity) minSeverity);
		Json json = jsonOfDiagnostics(resultAlloc, *server, program, uri, diags);
		return jsonToString(resultAlloc, server.allSymbols, json).ptr;
	});
}

@system extern(C) CStr getDefinition(Server* server, scope CStr uriCStr, uint line, uint character) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getDefinition", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		UriLineAndCharacter where = toUriLineAndCharacter(*server, uriStr, line, character);
		UriAndRange[] res = getDefinition(perf, resultAlloc, *server, where);
		Json json = jsonOfReferences(resultAlloc, server.allUris, server.lineAndColumnGetters, res);
		return jsonToString(resultAlloc, server.allSymbols, json);
	}).ptr;
}

@system extern(C) CStr getReferences(Server* server, scope CStr uriCStr, uint line, uint character, scope CStr roots) {
	SafeCStr uriSafe = SafeCStr(uriCStr);
	SafeCStr rootsSafe = SafeCStr(roots);
	return wasmCall!("getReferences", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		UriLineAndCharacter where = toUriLineAndCharacter(*server, uriSafe, line, character);
		Uri[] roots = toUris(resultAlloc, *server, rootsSafe);
		UriAndRange[] references = getReferences(perf, resultAlloc, *server, where, roots);
		return jsonToString(resultAlloc, server.allSymbols, jsonOfReferences(
			resultAlloc, server.allUris, server.lineAndColumnGetters, references));
	}).ptr;
}

@system extern(C) CStr getRename(
	Server* server,
	scope CStr uriCStr,
	uint line,
	uint character,
	scope CStr roots,
	scope CStr newNamePtr,
) {
	SafeCStr uriSafe = SafeCStr(uriCStr);
	SafeCStr rootsSafe = SafeCStr(roots);
	SafeCStr newName = SafeCStr(newNamePtr);
	return wasmCall!("getRename", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		UriLineAndCharacter where = toUriLineAndCharacter(*server, uriSafe, line, character);
		Uri[] roots = toUris(resultAlloc, *server, rootsSafe);
		Opt!Rename rename = getRename(perf, resultAlloc, *server, where, roots, strOfSafeCStr(newName));
		Json renameJson = jsonOfRename(resultAlloc, server.allUris, server.lineAndColumnGetters, rename);
		return jsonToString(resultAlloc, server.allSymbols, renameJson);
	}).ptr;
}

@system extern(C) CStr getHover(Server* server, scope CStr uriCStr, uint line, uint character) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCall!("getHover", SafeCStr)((scope ref Perf perf, ref Alloc resultAlloc) {
		SafeCStr hover = getHover(perf, resultAlloc, *server, toUriLineAndCharacter(*server, uriStr, line, character));
		return jsonToString(resultAlloc, server.allSymbols, jsonObject(resultAlloc, [field!"hover"(hover)]));
	}).ptr;
}

@system extern(C) int run(Server* server, scope CStr uriCStr) {
	SafeCStr uriStr = SafeCStr(uriCStr);
	return wasmCallImpure!("run", ExitCode)((scope ref Perf perf, ref Alloc resultAlloc) =>
		run(perf, resultAlloc, *server, toUri(*server, uriStr), (Pipe pipe, in string x) @trusted {
			write(pipe, x.ptr, x.length);
		})).value;
}

pure Uri[] toUris(ref Alloc alloc, scope ref Server server, SafeCStr uris) {
	ArrBuilder!Uri res;
	eachSplit(uris, '|', (in string x) {
		add(alloc, res, parseUri(server.allUris, x));
	});
	return finishArr(alloc, res);
}

pure UriLineAndCharacter toUriLineAndCharacter(scope ref Server server, SafeCStr uri, uint line, uint character) =>
	UriLineAndCharacter(toUri(server, uri), LineAndCharacter(line, character));

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

pure:

Json jsonOfDiagnostics(ref Alloc alloc, ref Server server, in Program program) =>
	jsonList!UriAndDiagnostics(alloc, sortedDiagnostics(alloc, server.allUris, program), (in UriAndDiagnostics diags) =>
		jsonObject(alloc, [
			field!"uri"(stringOfUri(alloc, server.allUris, diags.uri)),
			field!"diagnostics"(jsonList!Diagnostic(alloc, diags.diagnostics, (in Diagnostic x) =>
				jsonOfDiagnostic(alloc, server, program, diags.uri, x)))]));

Json jsonOfDiagnostics(ref Alloc alloc, ref Server server, in Program program, Uri uri, in Diagnostic[] diagnostics) =>
	jsonList!Diagnostic(alloc, diagnostics, (in Diagnostic x) =>
		jsonOfDiagnostic(alloc, server, program, uri, x));

Json jsonOfDiagnostic(ref Alloc alloc, scope ref Server server, in Program program, Uri uri, in Diagnostic a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, server.lineAndColumnGetters[uri], a.range)),
		field!"severity"(cast(uint) toLspDiagnosticSeverity(getDiagnosticSeverity(a.kind))),
		field!"message"(jsonString(alloc, showDiag(alloc, server, program, a.kind)))]);

enum LspDiagnosticSeverity {
	Error = 1,
	Warning = 2,
	Information = 3,
	Hint = 4,
}

LspDiagnosticSeverity toLspDiagnosticSeverity(DiagnosticSeverity a) {
	final switch (a) {
		case DiagnosticSeverity.unusedCode:
			return LspDiagnosticSeverity.Hint;
		case DiagnosticSeverity.checkWarning:
			return LspDiagnosticSeverity.Warning;
		case DiagnosticSeverity.checkError:
		case DiagnosticSeverity.nameNotFound:
		case DiagnosticSeverity.circularImport:
		case DiagnosticSeverity.commonMissing:
		case DiagnosticSeverity.parseError:
		case DiagnosticSeverity.readFile:
			return LspDiagnosticSeverity.Error;
	}
}
