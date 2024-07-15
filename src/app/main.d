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
import app.command : BuildOptions, Command, CommandKind, RunOptions, SingleBuildOutput;
import app.dyncall : withRealExtern;
import app.fileSystem :
	cleanupCompile,
	findPathToCCompiler,
	getCwd,
	getPathToThisExecutable,
	print,
	printCb,
	printError,
	printErrorCb,
	readExactFromStdin,
	readLineFromStdin,
	runCompiler,
	runNodeJsProgram,
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
import backend.js.translateToJs : TranslateToJsResult;
import backend.writeToC : PathAndArgs, WriteToCParams;
import document.document : documentModules;
import frontend.lang : CCompileOptions;
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
	buildToLowProgram,
	DiagsAndResultJson,
	DocumentResult,
	filesState,
	getProgramForMain,
	getProgramForRoots,
	handleLspMessage,
	jsonForPrintIde,
	jsonOfConcreteModel,
	jsonOfLowModel,
	jsonOfModel,
	perfStats,
	printAst,
	PrintKind,
	printTokens,
	Server,
	ServerSettings,
	setFile,
	setServerSettings,
	setShowOptions,
	setupServer,
	showDiagnostics,
	version_;
import model.diag : ReadFileDiag;
import model.model : hasAnyDiagnostics, hasFatalDiagnostics, Program, ProgramWithMain;
import model.lowModel : ExternLibraries, LowProgram;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, AllocKind, newAlloc, withTempAllocImpure, word;
import util.col.array : find, isEmpty, newArray, prepend;
import util.col.mutQueue : enqueue, isEmpty, mustDequeue, MutQueue;
import util.exitCode : ExitCode, exitCodeCombine, ExitCodeOrSignal, okAnd, Signal;
import util.json : Json, jsonToString, writeJsonPretty;
import util.jsonParse : mustParseJson, mustParseUint, skipWhitespace;
import util.opt : force, has, none, MutOpt, Opt, optIf, optOrDefault, some, someMut;
import util.perf : disablePerf, isEnabled, Perf, PerfMeasure, withMeasure, withNullPerf;
import util.perfReport : perfReport;
import util.sourceRange : UriLineAndColumn;
import util.string : CString, mustStripPrefix, MutCString;
import util.symbol : Extension, symbol;
import util.unicode : FileContent;
import util.uri :
	baseName, concatFilePathAndPath, cStringOfUriPreferRelative, FilePath, Uri, parentOrEmpty, rootFilePath, toUri;
import util.util : debugLog, todo;
import util.writer : debugLogWithWriter, makeStringWithWriter, Writer;
import versionInfo :
	getOS, OS, versionInfoForInterpret, versionInfoForJIT, VersionInfo, VersionOptions, versionOptionsForJs;

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
	ExitCodeOrSignal res = go(perf, *alloc, *server, cwd, thisExecutable, command.kind);
	if (isEnabled(perf)) {
		withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
			printJson(alloc, perfReport(alloc, perf, *server.metaAlloc, perfStats(alloc, *server)));
		});
	}
	return res.matchImpure!int(
		(in ExitCode x) =>
			x.value,
		(in Signal x) @trusted =>
			raise(x.signal));
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

ExitCodeOrSignal go(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	FilePath thisExecutable,
	in CommandKind command,
) =>
	command.matchImpure!ExitCodeOrSignal(
		(in CommandKind.Build x) {
			loadAllFiles(perf, server, [x.mainUri]);
			return withProgramForMain(perf, alloc, server, x.mainUri, (ref ProgramWithMain program) =>
				withBuild(perf, alloc, server, cwd, x.options, program, (FilePath _, in ExternLibraries _2) =>
					ExitCodeOrSignal.ok));
		},
		(in CommandKind.Check x) {
			loadAllFiles(perf, server, x.rootUris);
			return withProgramForRoots(perf, alloc, server, x.rootUris, (ref Program _) =>
				ExitCodeOrSignal(print("OK")));
		},
		(in CommandKind.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			return withProgramForRoots(perf, alloc, server, x.rootUris, (ref Program program) =>
				printJson(alloc, documentModules(alloc, program, x.rootUris)));
		},
		(in CommandKind.Help x) {
			print(x.helpText);
			return ExitCodeOrSignal(x.exitCode);
		},
		(in CommandKind.Lsp) =>
			ExitCodeOrSignal(runLsp(server, thisExecutable)),
		(in CommandKind.Print x) =>
			doPrint(perf, alloc, server, x),
		(in CommandKind.Run x) =>
			run(perf, alloc, server, cwd, x),
		(in CommandKind.Test x) {
			version (Test)
				return ExitCodeOrSignal(test(server.metaAlloc, x.names));
			else
				return ExitCodeOrSignal(printError("Did not compile with tests"));
		},
		(in CommandKind.Version) =>
			ExitCodeOrSignal(printCb((scope ref Writer writer) {
				writeJsonPretty(writer, version_(alloc, server, thisExecutable), 0);
			})));

ExitCodeOrSignal run(scope ref Perf perf, ref Alloc alloc, ref Server server, FilePath cwd, in CommandKind.Run run) {
	loadAllFiles(perf, server, [run.mainUri]);
	return withProgramForMain(perf, alloc, server, run.mainUri, (ref ProgramWithMain program) =>
		run.options.matchImpure!ExitCodeOrSignal( // TODO: all branches should be using 'withProgramForMain', so extract that to here!
			(in RunOptions.Aot x) =>
				buildAndRun(perf, alloc, server, cwd, program, run.programArgs, x),
			(in RunOptions.Interpret x) =>
				withRealExtern(*newAlloc(AllocKind.extern_, server.metaAlloc), (in Extern extern_) =>
					buildAndInterpret(
						perf, server, extern_,
						(in string x) { printError(x); },
						program, x.version_, none!(Uri[]),
						getAllArgs(alloc, server, run))),
			(in RunOptions.Jit x) {
				version (GccJitAvailable)
					return ExitCodeOrSignal(buildAndJit(perf, alloc, server, x, program, getAllArgs(alloc, server, run)));
				else
					return ExitCodeOrSignal(printError("This build does not support '--jit'"));
			},
			(in RunOptions.NodeJs) =>
				buildAndRunNode(perf, alloc, server, cwd, program, run.programArgs))); // TODO: 'buildAndRunNode' could be part of 'buildAndRun'?
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

ExitCodeOrSignal doPrint(scope ref Perf perf, ref Alloc alloc, ref Server server, in CommandKind.Print command) {
	Uri mainUri = command.mainUri;
	return command.kind.matchImpure!ExitCodeOrSignal(
		(in PrintKind.Tokens) {
			loadSingleFile(perf, server, mainUri);
			return printDiagsAndJson(alloc, printTokens(alloc, server, SemanticTokensParams(TextDocumentIdentifier(mainUri))));
		},
		(in PrintKind.Ast) {
			loadSingleFile(perf, server, mainUri);
			return printDiagsAndJson(alloc, printAst(perf, alloc, server, mainUri));
		},
		(in PrintKind.Model) {
			loadAllFiles(perf, server, [mainUri]); // TODO: maybe the withProgram functions should do the loadAllFiles ...................................
			return withProgramForRoots(perf, alloc, server, [mainUri], (ref Program program) =>
				printJson(alloc, jsonOfModel(perf, alloc, server, program, mainUri)));
		},
		(in PrintKind.ConcreteModel) {
			loadAllFiles(perf, server, [mainUri]);
			return withProgramForMain(perf, alloc, server, mainUri, (ref ProgramWithMain program) =>
				printJson(alloc, jsonOfConcreteModel(
					perf, alloc, server, server.lineAndColumnGetters,
					versionInfoForInterpret(getOS(), VersionOptions()),
					program)));
		},
		(in PrintKind.LowModel) {
			loadAllFiles(perf, server, [mainUri]);
			return withProgramForMain(perf, alloc, server, mainUri, (ref ProgramWithMain program) =>
				printJson(alloc, jsonOfLowModel(
					perf, alloc, server, server.lineAndColumnGetters,
					versionInfoForInterpret(getOS(), VersionOptions()),
					program)));
		},
		(in PrintKind.Ide x) {
			loadAllFiles(perf, server, [mainUri]);
			return withProgramForRoots(perf, alloc, server, [mainUri], (ref Program program) =>
				printJson(alloc, jsonForPrintIde(perf, alloc, server, program, UriLineAndColumn(mainUri, x.lineAndColumn), x.kind)));
		});
}

ExitCodeOrSignal buildAndRun(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	ref ProgramWithMain program,
	in CString[] programArgs,
	in RunOptions.Aot options,
) =>
	withTempPath(program.mainUri, defaultExecutableExtension(getOS()), (FilePath exePath) {
		scope SingleBuildOutput[] outputs = [SingleBuildOutput(SingleBuildOutput.Kind.executable, exePath)];
		scope BuildOptions buildOptions = BuildOptions(options.version_, outputs, options.compileOptions);
		return withBuild(perf, alloc, server, cwd, buildOptions, program, (FilePath cPath, in ExternLibraries libs) {
			ExitCodeOrSignal res = runProgram(alloc, libs, PathAndArgs(exePath, programArgs));
			// Doing this after 'runProgram' since that may use the '.pdb' file
			ExitCode cleanup = cleanupCompile(cwd, cPath, exePath);
			// Delay aborting with the signal so we can clean up temp files
			return exitCodeCombine(res, cleanup);
		});
	});

ExitCodeOrSignal buildAndRunNode(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	ref ProgramWithMain program,
	in CString[] programArgs,
) =>
	withTempPath(program.mainUri, Extension.none, (FilePath dir) {
		scope SingleBuildOutput[] outputs = [SingleBuildOutput(SingleBuildOutput.Kind.nodeJs, dir)];
		scope BuildOptions buildOptions = BuildOptions(versionOptionsForJs, outputs, CCompileOptions());
		return withBuild(perf, alloc, server, cwd, buildOptions, program, (FilePath mainJs, in ExternLibraries _) =>
			runNodeJsProgram(alloc, PathAndArgs(mainJs, programArgs)));
	});

ExitCodeOrSignal withBuild(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	FilePath cwd,
	in BuildOptions options,
	ref ProgramWithMain program,
	// WARN: the C file will be deleted by the time this is called
	in ExitCodeOrSignal delegate(FilePath cPath, in ExternLibraries) @safe @nogc nothrow cb,
) {
	Opt!FilePath findPath(SingleBuildOutput.Kind kind) {
		Opt!SingleBuildOutput s = find!SingleBuildOutput(options.out_, (in SingleBuildOutput x) => x.kind == kind);
		return optIf(has(s), () => force(s).path);
	}

	// TODO: we should support building multiple things (while only doing frontend once!) -------------------------------------------------------------------
	Opt!FilePath c = findPath(SingleBuildOutput.Kind.c);
	Opt!FilePath exe = findPath(SingleBuildOutput.Kind.executable);
	Opt!FilePath js = findPath(SingleBuildOutput.Kind.js);
	Opt!FilePath nodeJs = findPath(SingleBuildOutput.Kind.nodeJs);

	if (has(js) || has(nodeJs)) {
		if (has(c) || has(exe))
			todo!void("TODO: support both JS and other build"); // ----------------------------------------------------------------
		if (has(js) && has(nodeJs))
			todo!void("Support both JS output"); // -------------------------------------------------------------------------------
		FilePath out_ = optOrDefault!FilePath(js, () => force(nodeJs));
		TranslateToJsResult result = buildToJs(perf, alloc, server, program, getOS(), isNodeJs: has(nodeJs));
		return okAnd(
			ExitCodeOrSignal(writeFilesToDir(out_, result.outputFiles)),
			() => cb(concatFilePathAndPath(out_, result.mainJs), []));
	} else
		return withPathOrTemp(c, program.mainUri, Extension.c, (FilePath cPath) =>
			withBuildToC(
				perf, alloc, server, exe, cPath, options.cCompileOptions, options.version_, program,
				(in BuildToCResult result) =>
					okAnd(
						ExitCodeOrSignal(writeFile(cPath, result.writeToCResult.cSource)),
						() => ExitCodeOrSignal(has(exe)
							? withMeasure!(ExitCode, () =>
								runCompiler(alloc, result.writeToCResult.compileCommand)
							)(perf, alloc, PerfMeasure.invokeCCompiler)
							: ExitCode.ok),
						() => cb(cPath, result.externLibraries))));
}

ExitCodeOrSignal withProgramForMain(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Uri main,
	in ExitCodeOrSignal delegate(ref ProgramWithMain) @safe @nogc nothrow cb,
) {
	ProgramWithMain program = getProgramForMain(perf, alloc, server, main);
	if (hasAnyDiagnostics(program))
		printError(showDiagnostics(alloc, server, program.program));
	return hasFatalDiagnostics(program) ? ExitCodeOrSignal.error : cb(program);
}
ExitCodeOrSignal withProgramForRoots(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in Uri[] roots,
	in ExitCodeOrSignal delegate(ref Program) @safe @nogc nothrow cb,
) {
	Program program = getProgramForRoots(perf, alloc, server, roots);
	if (hasAnyDiagnostics(program))
		printError(showDiagnostics(alloc, server, program));
	return hasFatalDiagnostics(program) ? ExitCodeOrSignal.error : cb(program);
}

ExitCodeOrSignal withBuildToC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	Opt!FilePath exe,
	FilePath cPath,
	in CCompileOptions cCompileOptions,
	in VersionOptions version_,
	ref ProgramWithMain program,
	in ExitCodeOrSignal delegate(in BuildToCResult) @safe @nogc nothrow cb,
) {
	Opt!FilePath cCompiler = findPathToCCompiler();
	if (has(cCompiler)) {
		OS os = getOS();
		WriteToCParams params = WriteToCParams(
			force(cCompiler), cPath,
			optOrDefault!FilePath(exe, () => defaultExecutablePath(cPath, os)),
			cCompileOptions);
		BuildToCResult result = buildToC(perf, alloc, server, os, version_, params, program);
		return cb(result);
	} else
		return ExitCodeOrSignal.error;
}

version (GccJitAvailable) ExitCode buildAndJit( // TODO: should I move this to server.d? _-------------------------------------------------------------
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in RunOptions.Jit options,
	ref ProgramWithMain program,
	in CString[] programArgs,
) {
	assert(!hasFatalDiagnostics(program));
	LowProgram lowProgram = buildToLowProgram(perf, alloc, server, versionInfoForJIT(getOS(), options.version_), program);
	return jitAndRun(perf, alloc, lowProgram, options.options, programArgs);
}

ExitCodeOrSignal printDiagsAndJson(ref Alloc alloc, in DiagsAndResultJson a) {
	if (!isEmpty(a.diagnostics))
		printError(a.diagnostics);
	return printJson(alloc, a.result);
}

ExitCodeOrSignal printJson(ref Alloc alloc, in Json json) =>
	ExitCodeOrSignal(print(jsonToString(alloc, json)));
