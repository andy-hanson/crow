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
import app.command : BuildOptions, BuildOut, Command, CommandKind, RunOptions;
import app.dyncall : withRealExtern;
import app.fileSystem :
	cleanupCompile,
	ExitCodeOrSignal,
	findPathToCCompiler,
	getCwd,
	getPathToThisExecutable,
	Signal,
	runCompiler,
	runProgram,
	stderr,
	stdin,
	stdout,
	tryReadFile,
	withTempUri,
	withUriOrTemp,
	writeFile;
import app.parseCommand : parseCommand;
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import backend.writeToC : PathAndArgs, WriteToCParams;
import frontend.lang : JitOptions;
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
import lib.server :
	allUnknownUris,
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	buildToLowProgram,
	check,
	DiagsAndResultJson,
	DocumentResult,
	filesState,
	getDocumentation,
	handleLspMessage,
	perfStats,
	printAst,
	printConcreteModel,
	printIde,
	PrintKind,
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
import model.model : hasAnyDiagnostics;
import model.lowModel : ExternLibraries;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, AllocKind, newAlloc, withTempAllocImpure, word;
import util.col.array : prepend;
import util.col.mutQueue : enqueue, isEmpty, mustDequeue, MutQueue;
import util.exitCode : ExitCode, exitCodeCombine, okAnd;
import util.json : Json, jsonToString;
import util.jsonParse : mustParseJson, mustParseUint, skipWhitespace;
import util.opt : force, has, none, MutOpt, Opt, someMut;
import util.perf : disablePerf, isEnabled, Perf, PerfMeasure, withMeasure, withNullPerf;
import util.perfReport : perfReport;
import util.sourceRange : UriLineAndColumn;
import util.string : CString, cString, cStringIsEmpty, cStringSize, mustStripPrefix, MutCString;
import util.symbol : AllSymbols, Extension, symbol;
import util.uri : AllUris, childUri, cStringOfUri, FileUri, Uri, parentOrEmpty, toUri;
import util.util : debugLog;
import versionInfo : getOS, versionInfoForInterpret, versionInfoForJIT;

@system extern(C) int main(int argc, immutable char** argv) {
	ulong function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	Server server = Server((size_t sizeWords, size_t _) =>
		(cast(word*) pureMalloc(sizeWords * word.sizeof))[0 .. sizeWords]);
	FileUri cwd = getCwd(server.allUris);
	setIncludeDir(&server, childUri(server.allUris, getCrowDir(server.allUris), symbol!"include"));
	setCwd(server, toUri(server.allUris, cwd));
	setShowOptions(server, ShowOptions(true));
	Alloc* alloc = newAlloc(AllocKind.main, server.metaAlloc);
	Command command = parseCommand(*alloc, server.allUris, cwd, getOS(), cast(CString[]) argv[1 .. argc]);
	if (!command.options.perf)
		disablePerf(perf);
	int res = go(perf, *alloc, server, cwd, command.kind).value;
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
	printf("Content-Length: %llu\r\n\r\n%s", cStringSize(content), content.ptr);
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

ExitCode go(scope ref Perf perf, ref Alloc alloc, ref Server server, FileUri cwd, in CommandKind command) =>
	command.matchImpure!ExitCode(
		(in CommandKind.Build x) {
			loadAllFiles(perf, server, [x.mainUri]);
			return withBuild(perf, alloc, server, cwd, x.mainUri, x.options, (FileUri _, in ExternLibraries _2) =>
				ExitCode.ok);
		},
		(in CommandKind.Check x) {
			loadAllFiles(perf, server, x.rootUris);
			CString diags = check(perf, alloc, server, x.rootUris);
			return cStringIsEmpty(diags) ? print(cString!"OK") : printError(diags);
		},
		(in CommandKind.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(perf, alloc, server, x.rootUris);
			return cStringIsEmpty(result.diagnostics) ? print(result.document) : printError(result.diagnostics);
		},
		(in CommandKind.Help x) {
			print(x.helpText);
			return x.exitCode;
		},
		(in CommandKind.Lsp) =>
			runLsp(server),
		(in CommandKind.Print x) =>
			doPrint(perf, alloc, server, x),
		(in CommandKind.Run x) =>
			run(perf, alloc, server, cwd, x),
		(in CommandKind.Test x) {
			version (Test) {
				return test(server.metaAlloc, x.names);
			} else
				return printError(cString!"Did not compile with tests");
		},
		(in CommandKind.Version) =>
			print(version_(alloc, server)));

ExitCode run(scope ref Perf perf, ref Alloc alloc, ref Server server, FileUri cwd, in CommandKind.Run run) {
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
						none!(Uri[]),
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
			buildAndRun(perf, alloc, server, cwd, run.mainUri, run.programArgs, x));
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
			return printConcreteModel(
				perf, alloc, server, server.lineAndColumnGetters, versionInfoForInterpret(getOS()), mainUri);
		},
		(in PrintKind.LowModel) {
			loadAllFiles(perf, server, [mainUri]);
			return printLowModel(
				perf, alloc, server, server.lineAndColumnGetters, versionInfoForInterpret(getOS()), mainUri);
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

ExitCode buildAndRun(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FileUri cwd,
	Uri main,
	in CString[] programArgs,
	in RunOptions.Aot options,
) {
	MutOpt!int signal;
	ExitCode exitCode = withTempUri(server.allUris, main, options.defaultExeExtension, (FileUri exeUri) {
		BuildOptions buildOptions = BuildOptions(
			BuildOut(outC: none!FileUri, shouldBuildExecutable: true, outExecutable: exeUri),
			options.compileOptions);
		return withBuild(perf, alloc, server, cwd, main, buildOptions, (FileUri cUri, in ExternLibraries libs) {
			ExitCodeOrSignal res = runProgram(alloc, server.allUris, libs, PathAndArgs(exeUri, programArgs));
			// Doing this after 'runProgram' since that may use the '.pdb' file
			ExitCode cleanup = cleanupCompile(server.allUris, cwd, cUri, exeUri);
			// Delay aborting with the signal so we can clean up temp files
			return res.match!ExitCode(
				(ExitCode x) =>
					exitCodeCombine(x, cleanup),
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
	FileUri cwd,
	Uri main,
	in BuildOptions options,
	// WARN: the C file will be deleted by the time this is called
	in ExitCode delegate(FileUri cUri, in ExternLibraries) @safe @nogc nothrow cb,
) =>
	withUriOrTemp(server.allUris, options.out_.outC, main, Extension.c, (FileUri cUri) =>
		withBuildToC(perf, alloc, server, main, options, cUri, (in BuildToCResult result) =>
			okAnd(writeFile(server.allUris, cUri, result.writeToCResult.cSource), () =>
				okAnd(
					options.out_.shouldBuildExecutable
						? withMeasure!(ExitCode, () =>
							runCompiler(alloc, server.allUris, result.writeToCResult.compileCommand)
						)(perf, alloc, PerfMeasure.invokeCCompiler)
						: ExitCode.ok,
					() => cb(cUri, result.externLibraries)))));

ExitCode withBuildToC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in BuildOptions options,
	FileUri cUri,
	in ExitCode delegate(in BuildToCResult) @safe @nogc nothrow cb,
) {
	Opt!FileUri cCompiler = findPathToCCompiler(server.allUris);
	if (has(cCompiler)) {
		WriteToCParams params = WriteToCParams(
			force(cCompiler), cUri, options.out_.outExecutable, options.cCompileOptions);
		BuildToCResult result = buildToC(perf, alloc, server, getOS(), main, params);
		if (!cStringIsEmpty(result.diagnostics))
			printError(result.diagnostics);
		return result.hasFatalDiagnostics ? ExitCode.error : cb(result);
	} else
		return ExitCode.error;
}

version (GccJitAvailable) { ExitCode buildAndJit(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in JitOptions jitOptions,
	Uri main,
	in CString[] programArgs,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForJIT(getOS()), main);
	if (hasAnyDiagnostics(programs.program))
		printError(showDiagnostics(alloc, server, programs.program));
	return has(programs.lowProgram)
		? jitAndRun(
			perf, alloc, server.allSymbols, server.allUris, force(programs.lowProgram), jitOptions, programArgs)
		: ExitCode.error;
} }
