module app.main;

@safe @nogc nothrow: // not pure

import core.memory : pureMalloc;
import core.stdc.stdio : fflush, fprintf, printf, fgets, fread;
version (Windows) {
	import core.sys.windows.core : GetTickCount;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}

import app.appUtil : print, printError;
import app.dyncall : withRealExtern;
import app.fileSystem : getCwd, getPathToThisExecutable, stderr, stdin, stdout, tryReadFile, withUriOrTemp, writeFile;
import backend.cCompile : compileC;
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import frontend.lang : cExtension, JitOptions;
import frontend.showModel : ShowOptions;
import frontend.storage : FilesState;
import interpret.extern_ : Extern;
import lib.lsp.lspParse : parseLspInMessage;
import lib.lsp.lspToJson : jsonOfLspOutMessage;
import lib.lsp.lspTypes : LspInMessage, LspOutAction, LspOutMessage, SemanticTokensParams, TextDocumentIdentifier;
import lib.cliParser : BuildOptions, Command, CommandKind, hasAnyOut, parseCommand, PrintKind, RunOptions;
import lib.server :
	allUnknownUris,
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	buildToLowProgram,
	CbHandleUnknownUris,
	DiagsAndResultJson,
	DocumentResult,
	filesState,
	getDocumentation,
	handleLspMessage,
	getProgramForMain,
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
import model.model : hasAnyDiagnostics, Program;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, AllocKind, newAlloc, withTempAllocImpure, word;
import util.col.arrUtil : prepend;
import util.col.str : CStr, mustStripPrefix, SafeCStr, safeCStr, safeCStrIsEmpty, safeCStrSize;
import util.exitCode : ExitCode;
import util.json : Json, jsonToString;
import util.jsonParse : mustParseJson, mustParseUint, skipWhitespace;
import util.lineAndColumnGetter : UriLineAndColumn;
import util.opt : force, has, Opt, some;
import util.perf : disablePerf, isEnabled, Perf, withNullPerf;
import util.perfReport : perfReport;
import util.sym : AllSymbols, sym;
import util.uri : AllUris, childUri, FileUri, Uri, parentOrEmpty, safeCStrOfUri, toUri;
import versionInfo : versionInfoForJIT;

@system extern(C) int main(int argc, CStr* argv) {
	ulong function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	Server server = Server((size_t sizeWords, size_t _) =>
		(cast(word*) pureMalloc(sizeWords * word.sizeof))[0 .. sizeWords]);
	Uri cwd = toUri(server.allUris, getCwd(server.allUris));
	setIncludeDir(&server, childUri(server.allUris, getCrowDir(server.allUris), sym!"include"));
	setCwd(server, cwd);
	setShowOptions(server, ShowOptions(true));
	Alloc* alloc = newAlloc(AllocKind.main, server.metaAlloc);
	Command command = parseCommand(*alloc, server.allUris, cwd, cast(SafeCStr[]) argv[1 .. argc]);
	if (!command.options.perf)
		disablePerf(perf);
	int res = go(perf, *alloc, server, command.kind).value;
	if (isEnabled(perf)) {
		printf("%s\n", jsonToString(*alloc, server.allSymbols, perfReport(*alloc, perf, *server.metaAlloc)).ptr);
	}
	return res;
}

private:

@trusted ExitCode runLsp(ref Server server) {
	withTempAllocImpure!void(server.metaAlloc, (ref Alloc alloc) @trusted {
		fprintf(stderr, "Crow version %s\nRunning language server protocol\n", version_(alloc, server).ptr);
		fprintf(stderr, "Running language server protocol\n");
	});

	setShowOptions(server, ShowOptions(false));

	while (true) {
		//TODO: track perf for each message/response
		Opt!ExitCode stop = withNullPerf!(Opt!ExitCode, (scope ref Perf perf) =>
			withTempAllocImpure!(Opt!ExitCode)(server.metaAlloc, (ref Alloc alloc) {
				LspInMessage message = readIn(alloc, server.allSymbols, server.allUris);
				scope CbHandleUnknownUris dg = () {
					loadUntilNoUnknownUris(perf, server);
				};
				LspOutAction action = handleLspMessage(perf, alloc, server, message, some(dg));
				foreach (LspOutMessage outMessage; action.outMessages) {
					writeOut(alloc, server.allSymbols, jsonOfLspOutMessage(
						alloc, server.allUris, server.lineAndColumnGetters, outMessage));
				}
				return action.exitCode;
			}));
		if (has(stop))
			return force(stop);
		else
			continue;
	}
}

@trusted LspInMessage readIn(ref Alloc alloc, scope ref AllSymbols allSymbols, scope ref AllUris allUris) {
	char[0x10000] buffer;
	immutable(char)* line0 = cast(immutable) fgets(buffer.ptr, buffer.length, stdin);
	assert(line0 != null);
	SafeCStr stripped = mustStripPrefix(SafeCStr(cast(immutable) line0), "Content-Length: ");
	uint contentLength = mustParseUint(stripped);
	assert(contentLength < buffer.length);

	immutable(char)* line1 = cast(immutable) fgets(buffer.ptr, buffer.length, stdin);
	assert(line1 != null);
	skipWhitespace(line1);
	assert(*line1 == '\0');

	size_t n = fread(buffer.ptr, char.sizeof, contentLength, stdin);
	assert(n == contentLength);
	buffer[n] = '\0';

	return parseLspInMessage(alloc, allUris, mustParseJson(alloc, allSymbols, SafeCStr(cast(immutable) buffer.ptr)));
}

@trusted void writeOut(ref Alloc alloc, in AllSymbols allSymbols, in Json contentJson) {
	SafeCStr content = jsonToString(alloc, allSymbols, contentJson);
	printf("Content-Length: %lu\r\n\r\n%s", safeCStrSize(content), content.ptr);
	fflush(stdout);
}

void loadAllFiles(scope ref Perf perf, ref Server server, in Uri[] rootUris) {
	foreach (Uri uri; rootUris)
		loadSingleFile(perf, server, uri);
	loadUntilNoUnknownUris(perf, server);
}

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
			runBuild(perf, alloc, server, x.mainUri, x.options),
		(in CommandKind.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(perf, alloc, server, x.rootUris);
			return safeCStrIsEmpty(result.diagnostics) ? print(result.document) : printError(result.diagnostics);
		},
		(in CommandKind.Help x) =>
			help(x),
		(in CommandKind.Lsp) =>
			runLsp(server),
		(in CommandKind.Print x) =>
			doPrint(perf, alloc, server, x),
		(in CommandKind.Run run) {
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
								(in SafeCStr x) {
									printError(x);
								},
								run.mainUri,
								getAllArgs(alloc, server.allUris, run.mainUri, run.programArgs))),
				(in RunOptions.Jit x) {
					version (GccJitAvailable) {
						SafeCStr[] args = getAllArgs(alloc, server.allUris, run.mainUri, run.programArgs);
						return buildAndJit(perf, alloc, server, x.options, run.mainUri, args);
					} else {
						printError(safeCStr!"'--jit' is not supported on Windows");
						return ExitCode.error;
					}
				});
		},
		(in CommandKind.Test x) {
			version (Test) {
				return test(server.metaAlloc, x.names);
			} else
				return printError(safeCStr!"Did not compile with tests");
		},
		(in CommandKind.Version) =>
			print(version_(alloc, server)));

Uri getCrowDir(ref AllUris allUris) =>
	parentOrEmpty(allUris, parentOrEmpty(allUris, toUri(allUris, getPathToThisExecutable(allUris))));

SafeCStr[] getAllArgs(ref Alloc alloc, in AllUris allUris, Uri main, in SafeCStr[] programArgs) =>
	prepend(alloc, safeCStrOfUri(alloc, allUris, main), programArgs);

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
	if (!safeCStrIsEmpty(printed.diagnostics))
		printError(printed.diagnostics);
	print(jsonToString(alloc, server.allSymbols, printed.result));
	return safeCStrIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
}

ExitCode runBuild(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri main, in BuildOptions options) {
	loadAllFiles(perf, server, [main]);
	if (hasAnyOut(options.out_))
		return buildToCAndCompile(perf, alloc, server, main, options);
	else {
		Program program = getProgramForMain(perf, alloc, server, main);
		return hasAnyDiagnostics(program)
			? printError(showDiagnostics(alloc, server, program))
			: print(safeCStr!"OK");
	}
}

ExitCode buildToCAndCompile(scope ref Perf perf, ref Alloc alloc, ref Server server, Uri main, BuildOptions options) {
	loadAllFiles(perf, server, [main]);
	BuildToCResult result = buildToC(perf, alloc, server, main);
	if (!safeCStrIsEmpty(result.diagnostics))
		printError(result.diagnostics);
	return withUriOrTemp!cExtension(server.allUris, options.out_.outC, main, (FileUri cUri) {
		ExitCode res = writeFile(server.allUris, cUri, result.cSource);
		return res == ExitCode.ok && has(options.out_.outExecutable)
			? compileC(
				perf, alloc, server.allSymbols, server.allUris,
				cUri, force(options.out_.outExecutable), result.externLibraries, options.cCompileOptions)
			: res;
	});
}

version (GccJitAvailable) { ExitCode buildAndJit(
	scope ref Perf perf,
	ref Alloc alloc,
	ref Server server,
	in JitOptions jitOptions,
	Uri main,
	in SafeCStr[] programArgs,
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
