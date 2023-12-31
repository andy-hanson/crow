module app.main;

@safe @nogc nothrow: // not pure

import core.memory : pureMalloc;
import core.stdc.signal : raise;
import core.stdc.stdio : fflush, fprintf, printf, fgets, fread;
import core.stdc.stdlib : abort;
version (Windows) {
	import core.sys.windows.core : GetTickCount;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}

import app.appUtil : print, printError;
import app.backtrace : printBacktrace;
import app.dyncall : withRealExtern;
import app.fileSystem :
	ExitCodeOrSignal,
	getCwd,
	getPathToThisExecutable,
	Signal,
	spawnAndWait,
	stderr,
	stdin,
	stdout,
	tryReadFile,
	withUriOrTemp,
	writeFile;
import backend.cCompile : compileC;
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import frontend.lang : cExtension, JitOptions;
import frontend.showModel : ShowOptions;
import frontend.storage : asString, FileContent, FilesState;
import interpret.extern_ : Extern;
import lib.lsp.lspParse : parseLspInMessage;
import lib.lsp.lspToJson : jsonOfLspOutMessage;
import lib.lsp.lspTypes :
	LspInMessage,
	LspInNotification,
	LspOutAction,
	LspOutMessage,
	LspOutNotification,
	ReadFileResultParams,
	ReadFileResultType,
	SemanticTokensParams,
	TextDocumentIdentifier,
	UnknownUris;
import lib.cliParser :
	BuildOptions, BuildOut, Command, CommandKind, defaultExeExtension, hasAnyOut, parseCommand, PrintKind, RunOptions;
import lib.server :
	allUnknownUris,
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	buildToLowProgram,
	DiagsAndResultJson,
	DocumentResult,
	filesState,
	getDocumentation,
	handleLspMessage,
	getProgramForMain,
	perfStats,
	printAst,
	printConcreteModel,
	printIde,
	printLowModel,
	printModel,
	printTokens,
	Programs,
	Server,
	setCwd,
	setFile,
	setIncludeDir,
	setShowOptions,
	showDiagnostics,
	version_;
import model.diag : ReadFileDiag;
import model.model : hasAnyDiagnostics, ProgramWithMain;
import model.lowModel : ExternLibraries;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, AllocKind, newAlloc, withTempAllocImpure, word;
import util.col.array : prepend;
import util.col.mutQueue : enqueue, isEmpty, mustDequeue, MutQueue;
import util.exitCode : ExitCode, okAnd;
import util.json : Json, jsonToString;
import util.jsonParse : mustParseJson, mustParseUint, skipWhitespace;
import util.opt : force, has, none, MutOpt, Opt, some, someMut;
import util.perf : disablePerf, isEnabled, Perf, withNullPerf;
import util.perfReport : perfReport;
import util.sourceRange : UriLineAndColumn;
import util.string : CString, cString, cStringIsEmpty, cStringSize, mustStripPrefix, MutCString;
import util.symbol : AllSymbols, symbol;
import util.uri : AllUris, childUri, cStringOfFileUri, cStringOfUri, FileUri, Uri, parentOrEmpty, toUri;
import util.util : debugLog;
import versionInfo : versionInfoForJIT;

@system extern(C) int main(int argc, immutable char** argv) {
	ulong function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	Server server = Server((size_t sizeWords, size_t _) =>
		(cast(word*) pureMalloc(sizeWords * word.sizeof))[0 .. sizeWords]);
	Uri cwd = toUri(server.allUris, getCwd(server.allUris));
	setIncludeDir(&server, childUri(server.allUris, getCrowDir(server.allUris), symbol!"include"));
	setCwd(server, cwd);
	setShowOptions(server, ShowOptions(true));
	Alloc* alloc = newAlloc(AllocKind.main, server.metaAlloc);
	Command command = parseCommand(*alloc, server.allUris, cwd, cast(CString[]) argv[1 .. argc]);
	if (!command.options.perf)
		disablePerf(perf);
	int res = go(perf, *alloc, server, command.kind).value;
	if (isEnabled(perf)) {
		withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
			Json report = perfReport(alloc, perf, *server.metaAlloc, perfStats(alloc, server));
			printf("%s\n", jsonToString(alloc, server.allSymbols, report).ptr);
		});
	}
	return res;
}

private:

// Override the default '__assert' to print the backtrace
@trusted extern(C) noreturn __assert(immutable char* asserted, immutable char* file, uint lineNumber) {
	fprintf(stderr, "Assert failed: %s at %s line %u", asserted, file, lineNumber);
	printBacktrace();
	abort();
}

@trusted ExitCode runLsp(ref Server server) {
	withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
		fprintf(stderr, "Crow version %s\nRunning language server protocol\n", version_(alloc, server).ptr);
	});

	setShowOptions(server, ShowOptions(false));

	while (true) {
		// TODO: get this from specified trace level
		bool logLsp = false;
		//TODO: track perf for each message/response
		Opt!ExitCode stop = withNullPerf!(Opt!ExitCode, (scope ref Perf perf) =>
			withTempAllocImpure!(Opt!ExitCode)(server.metaAlloc, (ref Alloc alloc) =>
				handleOneMessageIn(perf, alloc, server, logLsp)));
		if (has(stop))
			return force(stop);
		else
			continue;
	}
}

Opt!ExitCode handleOneMessageIn(scope ref Perf perf, ref Alloc alloc, ref Server server, bool logLsp) {
	MutQueue!LspInMessage bufferedMessages;
	enqueue(alloc, bufferedMessages, readIn(alloc, server.allSymbols, server.allUris, logLsp));
	do {
		LspInMessage message = mustDequeue(bufferedMessages);
		LspOutAction action = handleLspMessage(perf, alloc, server, message);
		foreach (LspOutMessage outMessage; action.outMessages) {
			if (!server.lspState.supportsUnknownUris && isUnknownUris(outMessage)) {
				debugLog("Server will load unknown URIs itself (since client does not support them)");
				foreach (Uri uri; outMessage.as!LspOutNotification.as!UnknownUris.unknownUris)
					enqueue(alloc, bufferedMessages, LspInMessage(
						LspInNotification(readFileLocally(alloc, server.allUris, uri))));
			} else
				writeOut(
					alloc, server.allSymbols,
					jsonOfLspOutMessage(alloc, server.allUris, server.lineAndCharacterGetters, outMessage),
					logLsp);
		}
		if (has(action.exitCode))
			return action.exitCode;
	} while (!isEmpty(bufferedMessages));
	return none!ExitCode;
}

bool isUnknownUris(in LspOutMessage a) =>
	a.isA!LspOutNotification && a.as!LspOutNotification.isA!UnknownUris;

@trusted LspInMessage readIn(ref Alloc alloc, scope ref AllSymbols allSymbols, scope ref AllUris allUris, bool logLsp) {
	char[0x10000] buffer;
	immutable(char)* line0 = cast(immutable) fgets(buffer.ptr, buffer.length, stdin);
	assert(line0 != null);
	CString stripped = mustStripPrefix(CString(cast(immutable) line0), "Content-Length: ");
	uint contentLength = mustParseUint(stripped);
	assert(contentLength < buffer.length);

	MutCString line1 = MutCString(cast(immutable) fgets(buffer.ptr, buffer.length, stdin));
	assert(line1 != null);
	skipWhitespace(line1);
	assert(*line1 == '\0');

	size_t n = fread(buffer.ptr, char.sizeof, contentLength, stdin);
	assert(n == contentLength);
	buffer[n] = '\0';

	if (logLsp)
		fprintf(stderr, "LSP in: %s\n", buffer.ptr);

	return parseLspInMessage(alloc, allUris, mustParseJson(alloc, allSymbols, CString(cast(immutable) buffer.ptr)));
}

@trusted void writeOut(ref Alloc alloc, in AllSymbols allSymbols, in Json contentJson, bool logLsp) {
	CString content = jsonToString(alloc, allSymbols, contentJson);
	printf("Content-Length: %lu\r\n\r\n%s", cStringSize(content), content.ptr);
	if (logLsp)
		fprintf(stderr, "LSP out: %s\n", content.ptr);
	fflush(stdout);
}

void loadAllFiles(scope ref Perf perf, ref Server server, in Uri[] rootUris) {
	foreach (Uri uri; rootUris)
		loadSingleFile(perf, server, uri);
	loadUntilNoUnknownUris(perf, server);
}

ReadFileResultParams readFileLocally(ref Alloc alloc, scope ref AllUris allUris, Uri uri) =>
	tryReadFile(alloc, allUris, uri).match!ReadFileResultParams(
		(FileContent x) =>
			ReadFileResultParams(uri, ReadFileResultType.ok, asString(x)),
		(ReadFileDiag x) {
			ReadFileResultType type = () {
					final switch (x) {
					case ReadFileDiag.unknown:
					case ReadFileDiag.loading:
						assert(false);
					case ReadFileDiag.notFound:
						return ReadFileResultType.notFound;
					case ReadFileDiag.error:
						return ReadFileResultType.error;
				}
			}();
			return ReadFileResultParams(uri, type, "");
		});

void loadUntilNoUnknownUris(scope ref Perf perf, ref Server server) {
	while (filesState(server) != FilesState.allLoaded) {
		withTempAllocImpure(server.metaAlloc, (ref Alloc alloc) {
			foreach (Uri uri; allUnknownUris(alloc, server))
				loadSingleFile(perf, server, uri);
		});
	}
}

void loadSingleFile(scope ref Perf perf, ref Server server, Uri uri) {
	withTempAllocImpure(server.metaAlloc, (ref Alloc alloc) {
		setFile(perf, server, uri, tryReadFile(alloc, server.allUris, uri));
	});
}

@trusted ulong getTimeNanos() {
	version (Windows) {
		return (cast(ulong) GetTickCount()) * 1_000_000;
	} else {
		timespec time;
		clock_gettime(CLOCK_MONOTONIC, &time);
		return time.tv_sec * 1_000_000_000 + time.tv_nsec;
	}
}

ExitCode go(scope ref Perf perf, ref Alloc alloc, ref Server server, in CommandKind command) =>
	command.matchImpure!ExitCode(
		(in CommandKind.Build x) =>
			build(perf, alloc, server, x.mainUri, x.options),
		(in CommandKind.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(perf, alloc, server, x.rootUris);
			return cStringIsEmpty(result.diagnostics) ? print(result.document) : printError(result.diagnostics);
		},
		(in CommandKind.Help x) =>
			help(x),
		(in CommandKind.Lsp) =>
			runLsp(server),
		(in CommandKind.Print x) =>
			doPrint(perf, alloc, server, x),
		(in CommandKind.Run x) =>
			run(perf, alloc, server, x),
		(in CommandKind.Test x) {
			version (Test) {
				return test(server.metaAlloc, x.names);
			} else
				return printError(cString!"Did not compile with tests");
		},
		(in CommandKind.Version) =>
			print(version_(alloc, server)));

ExitCode run(scope ref Perf perf, ref Alloc alloc, ref Server server, in CommandKind.Run run) {
	loadAllFiles(perf, server, [run.mainUri]);
	return run.options.matchImpure!ExitCode(
		(in RunOptions.Interpret) =>
			withRealExtern(
				*newAlloc(AllocKind.extern_, server.metaAlloc),
				server.allSymbols,
				server.allUris,
				(in Extern extern_) =>
					buildAndInterpret(
						perf,
						server,
						extern_,
						(in CString x) {
							printError(x);
						},
						run.mainUri,
						getAllArgs(alloc, server.allUris, run.mainUri, run.programArgs))),
		(in RunOptions.Jit x) {
			version (GccJitAvailable) {
				CString[] args = getAllArgs(alloc, server.allUris, run.mainUri, run.programArgs);
				return buildAndJit(perf, alloc, server, x.options, run.mainUri, args);
			} else {
				printError(cString!"'--jit' is not supported on Windows");
				return ExitCode.error;
			}
		},
		(in RunOptions.Aot x) =>
			buildAndRun(perf, alloc, server, run.mainUri, run.programArgs, x));
}

Uri getCrowDir(ref AllUris allUris) =>
	parentOrEmpty(allUris, parentOrEmpty(allUris, toUri(allUris, getPathToThisExecutable(allUris))));

CString[] getAllArgs(ref Alloc alloc, in AllUris allUris, Uri main, in CString[] programArgs) =>
	prepend(alloc, cStringOfUri(alloc, allUris, main), programArgs);

ExitCode doPrint(scope ref Perf perf, ref Alloc alloc, ref Server server, in CommandKind.Print command) {
	Uri mainUri = command.mainUri;
	DiagsAndResultJson printed = command.kind.matchImpure!DiagsAndResultJson(
		(in PrintKind.Tokens) {
			loadSingleFile(perf, server, mainUri);
			return printTokens(alloc, server, SemanticTokensParams(TextDocumentIdentifier(mainUri)));
		},
		(in PrintKind.Ast) {
			loadSingleFile(perf, server, mainUri);
			return printAst(perf, alloc, server, mainUri);
		},
		(in PrintKind.Model) {
			loadAllFiles(perf, server, [mainUri]);
			return printModel(perf, alloc, server, mainUri);
		},
		(in PrintKind.ConcreteModel) {
			loadAllFiles(perf, server, [mainUri]);
			return printConcreteModel(perf, alloc, server, server.lineAndColumnGetters, versionInfoForJIT(), mainUri);
		},
		(in PrintKind.LowModel) {
			loadAllFiles(perf, server, [mainUri]);
			return printLowModel(perf, alloc, server, server.lineAndColumnGetters, versionInfoForJIT(), mainUri);
		},
		(in PrintKind.Ide x) {
			loadAllFiles(perf, server, [mainUri]);
			return printIde(perf, alloc, server, UriLineAndColumn(mainUri, x.lineAndColumn), x.kind);
		});
	if (!cStringIsEmpty(printed.diagnostics))
		printError(printed.diagnostics);
	print(jsonToString(alloc, server.allSymbols, printed.result));
	return cStringIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
}

ExitCode build(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri main, in BuildOptions options) {
	loadAllFiles(perf, server, [main]);
	if (hasAnyOut(options.out_))
		return withBuild(perf, alloc, server, main, options, () => ExitCode.ok);
	else {
		ProgramWithMain program = getProgramForMain(perf, alloc, server, main);
		return hasAnyDiagnostics(program)
			? printError(showDiagnostics(alloc, server, program.program))
			: print(cString!"OK");
	}
}

ExitCode buildAndRun(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in CString[] programArgs,
	in RunOptions.Aot options,
) {
	MutOpt!int signal;
	ExitCode exitCode = withUriOrTemp!defaultExeExtension(server.allUris, none!Uri, main, (FileUri exeUri) {
		BuildOptions buildOptions = BuildOptions(
			BuildOut(none!Uri, some(toUri(server.allUris, exeUri))),
			options.compileOptions);
		return withBuild(perf, alloc, server, main, buildOptions, () {
			ExitCodeOrSignal res = spawnAndWait(
				alloc, server.allUris, cStringOfFileUri(alloc, server.allUris, exeUri), programArgs);
			// Delay aborting with the signal so we can clean up temp files
			return res.match!ExitCode(
				(ExitCode x) =>
					x,
				(Signal x) {
					signal = someMut!int(x.signal);
					return ExitCode.error;
				});
		});
	});
	() @trusted {
		if (has(signal))
			raise(force(signal));
	}();
	return exitCode;
}

ExitCode withBuild(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in BuildOptions options,
	in ExitCode delegate() @safe @nogc nothrow cb,
) =>
	withBuildToC(perf, alloc, server, main, (CString cSource, ExternLibraries externLibraries) =>
		withUriOrTemp!cExtension(server.allUris, options.out_.outC, main, (FileUri cUri) =>
			okAnd(writeFile(server.allUris, cUri, cSource), () =>
				okAnd(
					has(options.out_.outExecutable)
						? compileC(
							perf, alloc, server.allSymbols, server.allUris,
							cUri, force(options.out_.outExecutable), externLibraries, options.cCompileOptions)
						: ExitCode.ok,
					cb))));

ExitCode withBuildToC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in ExitCode delegate(CString, ExternLibraries) @safe @nogc nothrow cb,
) {
	BuildToCResult result = buildToC(perf, alloc, server, main);
	if (!cStringIsEmpty(result.diagnostics))
		printError(result.diagnostics);
	if (result.hasFatalDiagnostics)
		return ExitCode.error;
	else
		return cb(result.cSource, result.externLibraries);
}

version (GccJitAvailable) { ExitCode buildAndJit(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in JitOptions jitOptions,
	Uri main,
	in CString[] programArgs,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForJIT(), main);
	if (hasAnyDiagnostics(programs.program))
		printError(showDiagnostics(alloc, server, programs.program));
	return has(programs.lowProgram)
		? ExitCode(jitAndRun(perf, alloc, server.allSymbols, force(programs.lowProgram), jitOptions, programArgs))
		: ExitCode.error;
} }

ExitCode help(in CommandKind.Help a) {
	print(a.helpText);
	return a.requested ? ExitCode.ok : ExitCode.error;
}
