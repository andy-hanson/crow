module app.main;

@safe @nogc nothrow: // not pure

import core.memory : pureMalloc;
import core.stdc.signal : raise;
import core.stdc.stdlib : abort;
version (Windows) {
	import core.sys.windows.core : GetTickCount;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}

import app.backtrace : writeBacktrace;
import app.command : BuildOptions, BuildOut, Command, CommandKind, RunOptions;
import app.dyncall : withRealExtern;
import app.fileSystem :
	cleanupCompile,
	ExitCodeOrSignal,
	findPathToCCompiler,
	getCwd,
	getPathToThisExecutable,
	print,
	printCb,
	printError,
	printErrorCb,
	Signal,
	readExactFromStdin,
	readLineFromStdin,
	runCompiler,
	runProgram,
	tryReadFile,
	withPathOrTemp,
	withTempPath,
	writeFile,
	writeFilesToDir,
	writeToStdoutAndFlush;
import app.parseCommand : defaultExecutableExtension, defaultExecutablePath, parseCommand;
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import backend.writeToC : PathAndArgs, WriteToCParams;
import frontend.showModel : ShowOptions;
import frontend.storage : FilesState;
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
	buildToJs,
	BuildToJsResult,
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
	ServerSettings,
	setFile,
	setServerSettings,
	setShowOptions,
	setupServer,
	showDiagnostics,
	version_;
import model.diag : ReadFileDiag;
import model.model : hasAnyDiagnostics;
import model.lowModel : ExternLibraries;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, AllocKind, newAlloc, withTempAllocImpure, word;
import util.col.array : isEmpty, prepend;
import util.col.mutQueue : enqueue, isEmpty, mustDequeue, MutQueue;
import util.exitCode : ExitCode, exitCodeCombine, okAnd;
import util.json : Json, jsonToString, writeJsonPretty;
import util.jsonParse : mustParseJson, mustParseUint, skipWhitespace;
import util.opt : force, has, none, MutOpt, Opt, optOrDefault, some, someMut;
import util.perf : disablePerf, isEnabled, Perf, PerfMeasure, withMeasure, withNullPerf;
import util.perfReport : perfReport;
import util.sourceRange : UriLineAndColumn;
import util.string : CString, mustStripPrefix, MutCString;
import util.symbol : Extension, symbol;
import util.unicode : FileContent;
import util.uri : baseName, cStringOfUriPreferRelative, FilePath, Uri, parentOrEmpty, rootFilePath, toUri;
import util.util : debugLog, todo;
import util.writer : debugLogWithWriter, makeStringWithWriter, Writer;
import versionInfo : getOS, OS, versionInfoForInterpret, versionInfoForJIT, VersionOptions;

@system extern(C) int main(int argc, immutable char** argv) {
	ulong function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	Server* server = setupServer((size_t sizeWords, size_t _) =>
		(cast(word*) pureMalloc(sizeWords * word.sizeof))[0 .. sizeWords]);
	FilePath cwd = getCwd();
	FilePath thisExecutable = getPathToThisExecutable();
	setServerSettings(server, ServerSettings(
		includeDir: toUri(getCrowIncludeDir(thisExecutable)),
		cwd: toUri(cwd),
		showOptions: ShowOptions(color: true)));
	Alloc* alloc = newAlloc(AllocKind.main, server.metaAlloc);
	Command command = parseCommand(*alloc, cwd, getOS(), cast(CString[]) argv[1 .. argc]);
	if (!command.options.perf)
		disablePerf(perf);
	int res = go(perf, *alloc, *server, cwd, thisExecutable, command.kind).value;
	if (isEnabled(perf)) {
		withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
			Json report = perfReport(alloc, perf, *server.metaAlloc, perfStats(alloc, *server));
			print(jsonToString(alloc, report));
		});
	}
	return res;
}

private:

version (Windows) {
	extern(C) noreturn _assert(immutable char* asserted, immutable char* file, uint lineNumber) =>
		assertFailed(asserted, file, lineNumber);
} else {
	extern(C) noreturn __assert(immutable char* asserted, immutable char* file, uint lineNumber) =>
		assertFailed(asserted, file, lineNumber);
}

@trusted noreturn assertFailed(immutable char* asserted, immutable char* file, uint lineNumber) {
	printErrorCb((scope ref Writer writer) @trusted {
		writer ~= "Assert failed: ";
		writer ~= CString(asserted);
		writer ~= " at ";
		writer ~= CString(file);
		writer ~= " line ";
		writer ~= lineNumber;
		writeBacktrace(writer);
	});
	abort();
}

@trusted ExitCode runLsp(ref Server server, FilePath thisExecutable) {
	withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
		printErrorCb((scope ref Writer writer) {
			writer ~= version_(alloc, server, thisExecutable);
			writer ~= "\nRunning language server protocol";
		});
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
	enqueue(alloc, bufferedMessages, lspRead(alloc, logLsp));
	do {
		LspInMessage message = mustDequeue(bufferedMessages);
		LspOutAction action = handleLspMessage(perf, alloc, server, message);
		foreach (LspOutMessage outMessage; action.outMessages) {
			if (!server.lspState.supportsUnknownUris && isUnknownUris(outMessage)) {
				debugLog("Server will load unknown URIs itself (since client does not support them)");
				foreach (Uri uri; outMessage.as!LspOutNotification.as!UnknownUris.unknownUris)
					enqueue(alloc, bufferedMessages, LspInMessage(LspInNotification(readFileLocally(alloc, uri))));
			} else {
				lspWrite(alloc, jsonOfLspOutMessage(alloc, server.lineAndCharacterGetters, outMessage), logLsp);
			}
		}
		if (has(action.exitCode))
			return action.exitCode;
	} while (!isEmpty(bufferedMessages));
	return none!ExitCode;
}

bool isUnknownUris(in LspOutMessage a) =>
	a.isA!LspOutNotification && a.as!LspOutNotification.isA!UnknownUris;

@trusted LspInMessage lspRead(ref Alloc alloc, bool logLsp) {
	char[0x10000] buffer = void;
	CString line0 = readLineFromStdin(buffer);
	if (logLsp)
		debugLogWithWriter((scope ref Writer writer) @trusted {
			writer ~= "LSP header in: ";
			writer ~= line0;
		});
	CString stripped = mustStripPrefix(line0, "Content-Length: ");
	uint contentLength = mustParseUint(stripped);
	assert(contentLength < buffer.length);

	MutCString line1 = readLineFromStdin(buffer);
	skipWhitespace(line1);
	assert(*line1 == '\0');

	readExactFromStdin(buffer[0 .. contentLength]);
	buffer[contentLength] = '\0';

	if (logLsp)
		debugLogWithWriter((scope ref Writer writer) @trusted {
			writer ~= "LSP message in: ";
			writer ~= CString(cast(immutable) buffer.ptr);
		});

	return parseLspInMessage(alloc, mustParseJson(alloc, CString(cast(immutable) buffer.ptr)));
}

@trusted void lspWrite(ref Alloc alloc, in Json contentJson, bool logLsp) {
	string jsonString = jsonToString(alloc, contentJson);
	string message = makeStringWithWriter(alloc, (scope ref Writer writer) {
		writer ~= "Content-Length: ";
		writer ~= jsonString.length;
		writer ~= "\r\n\r\n";
		writer ~= contentJson;
	});
	writeToStdoutAndFlush(message);
	if (logLsp) {
		debugLogWithWriter((scope ref Writer writer) {
			writer ~= "LSP out:";
			writer ~= message;
		});
	}
}

void loadAllFiles(scope ref Perf perf, ref Server server, in Uri[] rootUris) {
	foreach (Uri uri; rootUris)
		loadSingleFile(perf, server, uri);
	loadUntilNoUnknownUris(perf, server);
}

ReadFileResultParams readFileLocally(ref Alloc alloc, Uri uri) =>
	tryReadFile(alloc, uri).match!ReadFileResultParams(
		(FileContent x) =>
			ReadFileResultParams(uri, ReadFileResultType.ok, x.asBytes),
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
			return ReadFileResultParams(uri, type, []);
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
		setFile(perf, server, uri, tryReadFile(alloc, uri));
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

ExitCode go(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	FilePath thisExecutable,
	in CommandKind command,
) =>
	command.matchImpure!ExitCode(
		(in CommandKind.Build x) {
			loadAllFiles(perf, server, [x.mainUri]);
			return withBuild(perf, alloc, server, cwd, x.mainUri, x.options, (FilePath _, in ExternLibraries _2) =>
				ExitCode.ok);
		},
		(in CommandKind.Check x) {
			loadAllFiles(perf, server, x.rootUris);
			string diags = check(perf, alloc, server, x.rootUris);
			return isEmpty(diags) ? print("OK") : printError(diags);
		},
		(in CommandKind.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(perf, alloc, server, x.rootUris);
			return isEmpty(result.diagnostics) ? print(result.document) : printError(result.diagnostics);
		},
		(in CommandKind.Help x) {
			print(x.helpText);
			return x.exitCode;
		},
		(in CommandKind.Lsp) =>
			runLsp(server, thisExecutable),
		(in CommandKind.Print x) =>
			doPrint(perf, alloc, server, x),
		(in CommandKind.Run x) =>
			run(perf, alloc, server, cwd, x),
		(in CommandKind.Test x) {
			version (Test)
				return test(server.metaAlloc, x.names);
			else
				return printError("Did not compile with tests");
		},
		(in CommandKind.Version) =>
			printCb((scope ref Writer writer) {
				writeJsonPretty(writer, version_(alloc, server, thisExecutable), 0);
			}));

ExitCode run(scope ref Perf perf, ref Alloc alloc, ref Server server, FilePath cwd, in CommandKind.Run run) {
	loadAllFiles(perf, server, [run.mainUri]);
	return run.options.matchImpure!ExitCode(
		(in RunOptions.Interpret x) =>
			withRealExtern(*newAlloc(AllocKind.extern_, server.metaAlloc), (in Extern extern_) =>
				buildAndInterpret(
					perf, server, extern_,
					(in string x) { printError(x); },
					run.mainUri, x.version_, none!(Uri[]),
					getAllArgs(alloc, server, run))),
		(in RunOptions.Jit x) {
			version (GccJitAvailable) {
				CString[] args = getAllArgs(alloc, server, run);
				return buildAndJit(perf, alloc, server, x, run.mainUri, args);
			} else {
				printError("This build does not support '--jit'");
				return ExitCode.error;
			}
		},
		(in RunOptions.Aot x) =>
			buildAndRun(perf, alloc, server, cwd, run.mainUri, run.programArgs, x));
}

FilePath getCrowIncludeDir(FilePath thisExecutable) {
	FilePath thisDir = parentOrEmpty(thisExecutable);
	FilePath thisDirDir = parentOrEmpty(thisDir);
	version (Windows) {
		assert(baseName(thisDirDir) == symbol!"crow");
		return thisDirDir / symbol!"include";
	} else {
		FilePath usr = rootFilePath(symbol!"usr");
		return thisDir == usr / symbol!"bin"
			? usr / symbol!"include" / symbol!"crow"
			: thisDir == usr / symbol!"local" / symbol!"bin"
			? usr / symbol!"local" / symbol!"include" / symbol!"crow"
			: () {
				assert(baseName(thisDirDir) == symbol!"crow");
				return thisDirDir / symbol!"include";
			}();
	}
}

CString[] getAllArgs(ref Alloc alloc, in Server server, in CommandKind.Run run) =>
	prepend!CString(alloc, cStringOfUriPreferRelative(alloc, server.urisInfo, run.mainUri), run.programArgs);

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
				perf, alloc, server, server.lineAndColumnGetters,
				versionInfoForInterpret(getOS(), VersionOptions()),
				mainUri);
		},
		(in PrintKind.LowModel) {
			loadAllFiles(perf, server, [mainUri]);
			return printLowModel(
				perf, alloc, server, server.lineAndColumnGetters,
				versionInfoForInterpret(getOS(), VersionOptions()),
				mainUri);
		},
		(in PrintKind.Ide x) {
			loadAllFiles(perf, server, [mainUri]);
			return printIde(perf, alloc, server, UriLineAndColumn(mainUri, x.lineAndColumn), x.kind);
		});
	if (!isEmpty(printed.diagnostics))
		printError(printed.diagnostics);
	print(jsonToString(alloc, printed.result));
	return isEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
}

ExitCode buildAndRun(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	Uri main,
	in CString[] programArgs,
	in RunOptions.Aot options,
) {
	MutOpt!int signal;
	ExitCode exitCode = withTempPath(main, defaultExecutableExtension(getOS()), (FilePath exePath) {
		BuildOptions buildOptions = BuildOptions(options.version_, BuildOut(outExecutable: some(exePath)), options.compileOptions);
		return withBuild(perf, alloc, server, cwd, main, buildOptions, (FilePath cPath, in ExternLibraries libs) {
			ExitCodeOrSignal res = runProgram(alloc, libs, PathAndArgs(exePath, programArgs));
			// Doing this after 'runProgram' since that may use the '.pdb' file
			ExitCode cleanup = cleanupCompile(cwd, cPath, exePath);
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
	FilePath cwd,
	Uri main,
	in BuildOptions options,
	// WARN: the C file will be deleted by the time this is called
	in ExitCode delegate(FilePath cPath, in ExternLibraries) @safe @nogc nothrow cb,
) {
	if (has(options.out_.js) || has(options.out_.nodeJs)) {
		if (has(options.out_.outC) || has(options.out_.outExecutable))
			todo!void("TODO: support both JS and other build"); // ----------------------------------------------------------------
		if (has(options.out_.js) && has(options.out_.nodeJs))
			todo!void("Support both JS output"); // -------------------------------------------------------------------------------
		FilePath out_ = optOrDefault!FilePath(options.out_.js, () => force(options.out_.nodeJs));
		BuildToJsResult result = buildToJs(perf, alloc, server, getOS(), main, isNodeJs: has(options.out_.nodeJs));
		if (!isEmpty(result.diagnostics))
			printError(result.diagnostics);
		return result.hasFatalDiagnostics
			? ExitCode.error
			: writeFilesToDir(out_, result.result.outputFiles);
	} else
		return withPathOrTemp(options.out_.outC, main, Extension.c, (FilePath cPath) =>
			withBuildToC(perf, alloc, server, main, options, cPath, (in BuildToCResult result) =>
				okAnd(writeFile(cPath, result.writeToCResult.cSource), () =>
					okAnd(
						has(options.out_.outExecutable)
							? withMeasure!(ExitCode, () =>
								runCompiler(alloc, result.writeToCResult.compileCommand)
							)(perf, alloc, PerfMeasure.invokeCCompiler)
							: ExitCode.ok,
						() => cb(cPath, result.externLibraries)))));
}

ExitCode withBuildToC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in BuildOptions options,
	FilePath cPath,
	in ExitCode delegate(in BuildToCResult) @safe @nogc nothrow cb,
) {
	Opt!FilePath cCompiler = findPathToCCompiler();
	if (has(cCompiler)) {
		OS os = getOS();
		WriteToCParams params = WriteToCParams(
			force(cCompiler), cPath,
			optOrDefault!FilePath(options.out_.outExecutable, () => defaultExecutablePath(cPath, os)),
			options.cCompileOptions);
		BuildToCResult result = buildToC(perf, alloc, server, os, main, options.version_, params);
		if (!isEmpty(result.diagnostics))
			printError(result.diagnostics);
		return result.hasFatalDiagnostics ? ExitCode.error : cb(result);
	} else
		return ExitCode.error;
}

version (GccJitAvailable) ExitCode buildAndJit(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in RunOptions.Jit options,
	Uri main,
	in CString[] programArgs,
) {
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForJIT(getOS(), options.version_), main);
	if (hasAnyDiagnostics(programs.program))
		printError(showDiagnostics(alloc, server, programs.program));
	return has(programs.lowProgram)
		? jitAndRun(perf, alloc, force(programs.lowProgram), options.options, programArgs)
		: ExitCode.error;
}
