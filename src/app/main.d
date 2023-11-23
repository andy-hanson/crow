module app.main;

@safe @nogc nothrow: // not pure

import app.appUtil : print, printError;
import app.dyncall : withRealExtern;
import app.fileSystem : getCwd, getPathToThisExecutable, tryReadFile, withUriOrTemp, writeFile;
import core.stdc.stdio : printf;
import core.stdc.stdlib : free, malloc;

version (Windows) {
	import core.sys.windows.core : GetTickCount;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}
import backend.cCompile : compileC;
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import frontend.lang : cExtension, JitOptions;
import frontend.showModel : ShowOptions;
import interpret.extern_ : Extern;
import lib.cliParser : BuildOptions, Command, hasAnyOut, parseCommand, PrintKind, RunOptions;
import lib.server :
	allUnknownUris,
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	buildToLowProgram,
	DiagsAndResultJson,
	DocumentResult,
	getDocumentation,
	justParseEverything,
	justTypeCheck,
	printAst,
	printConcreteModel,
	printIde,
	printLowModel,
	printModel,
	printTokens,
	Programs,
	Server,
	setCwd,
	setDiagOptions,
	setFile,
	setIncludeDir,
	showDiagnostics,
	version_;
import model.model : hasAnyDiagnostics, Program;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, newAlloc, withTempAllocImpure;
import util.col.arr : empty;
import util.col.arrUtil : prepend;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty;
import util.exitCode : ExitCode;
import util.json : jsonToString;
import util.lineAndColumnGetter : UriLineAndColumn;
import util.opt : force, has;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasureResult, perfTotal;
import util.sym : sym;
import util.uri : AllUris, childUri, FileUri, Uri, parentOrEmpty, safeCStrOfUri, toUri;
import util.util : verify;
import versionInfo : versionInfoForJIT;

@system extern(C) int main(int argc, CStr* argv) {
	size_t GB = 1024 * 1024 * 1024;
	size_t memorySizeWords = GB * 3 / 2 / ulong.sizeof;
	ulong[] mem = (cast(ulong*) malloc(memorySizeWords * ulong.sizeof))[0 .. memorySizeWords];
	verify(mem.ptr != null);
	scope(exit) free(mem.ptr);

	ulong function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	Server server = Server(mem);
	Uri cwd = toUri(server.allUris, getCwd(server.allUris));
	setCwd(server, cwd);
	setDiagOptions(server, ShowOptions(true));
	Alloc alloc = newAlloc(server.metaAlloc);
	Command command = parseCommand(alloc, server.allSymbols, server.allUris, cwd, cast(SafeCStr[]) argv[1 .. argc]);
	int res = go(perf, alloc, server, command).value;
	if (perfEnabled)
		logPerf(perf);
	return res;
}

private:

void loadAllFiles(scope ref Perf perf, ref Server server, in Uri[] rootUris) {
	foreach (Uri uri; rootUris)
		loadSingleFile(perf, server, uri);
	while (true) {
		bool shouldBreak = withTempAllocImpure(server.metaAlloc, (ref Alloc alloc) {
			justParseEverything(perf, alloc, server, rootUris);
			Uri[] unknowns = allUnknownUris(alloc, server);
			foreach (Uri uri; unknowns)
				loadSingleFile(perf, server, uri);
			return empty(unknowns);
		});
		if (shouldBreak) break;
	}
}

void loadSingleFile(scope ref Perf perf, ref Server server, Uri uri) {
	withTempAllocImpure(server.metaAlloc, (ref Alloc alloc) {
		setFile(perf, server, uri, tryReadFile(alloc, server.allUris, uri));
	});
}

@trusted void logPerf(in Perf perf) {
	eachMeasure(perf, (in SafeCStr name, in PerfMeasureResult m) @trusted {
		printf(
			"%s * %d took %llums and %lluKB\n",
			name.ptr,
			m.count,
			divRound(m.nanoseconds, 1_000_000),
			divRound(m.bytesAllocated, 1024));
	});
	printf("Total: %llums", divRound(perfTotal(perf), 1_000_000));
}

ulong divRound(ulong a, ulong b) {
	ulong div = a / b;
	ulong rem = a % b;
	return div + (rem >= b / 2 ? 1 : 0);
}
static assert(divRound(15, 10) == 2);
static assert(divRound(14, 10) == 1);

@trusted ulong getTimeNanos() {
	version (Windows) {
		return (cast(ulong) GetTickCount()) * 1_000_000;
	} else {
		timespec time;
		clock_gettime(CLOCK_MONOTONIC, &time);
		return time.tv_sec * 1_000_000_000 + time.tv_nsec;
	}
}

ExitCode go(scope ref Perf perf, ref Alloc alloc, ref Server server, in Command command) {
	setIncludeDir(server, childUri(server.allUris, getCrowDir(server.allUris), sym!"include"));
	return command.matchImpure!ExitCode(
		(in Command.Build x) =>
			runBuild(perf, alloc, server, x.mainUri, x.options),
		(in Command.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(perf, alloc, server, x.rootUris);
			return safeCStrIsEmpty(result.diagnostics) ? print(result.document) : printError(result.diagnostics);
		},
		(in Command.Help x) =>
			help(x),
		(in Command.Print x) =>
			doPrint(perf, alloc, server, x),
		(in Command.Run run) {
			loadAllFiles(perf, server, [run.mainUri]);
			return run.options.matchImpure!ExitCode(
				(in RunOptions.Interpret) =>
					withRealExtern(alloc, server.allSymbols, server.allUris, (in Extern extern_) =>
						buildAndInterpret(
							perf,
							alloc,
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
		(in Command.Test it) {
			version (Test) {
				return test(server.metaAlloc, it.name);
			} else
				return printError(safeCStr!"Did not compile with tests");
		},
		(in Command.Version) =>
			print(version_(alloc, server)));
}

Uri getCrowDir(ref AllUris allUris) =>
	parentOrEmpty(allUris, parentOrEmpty(allUris, toUri(allUris, getPathToThisExecutable(allUris))));

SafeCStr[] getAllArgs(ref Alloc alloc, in AllUris allUris, Uri main, in SafeCStr[] programArgs) =>
	prepend(alloc, safeCStrOfUri(alloc, allUris, main), programArgs);

ExitCode doPrint(scope ref Perf perf, ref Alloc alloc, ref Server server, in Command.Print command) {
	Uri mainUri = command.mainUri;
	DiagsAndResultJson printed = command.kind.matchImpure!DiagsAndResultJson(
		(in PrintKind.Tokens) {
			loadSingleFile(perf, server, mainUri);
			return printTokens(perf, alloc, server, mainUri);
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
		Program program = justTypeCheck(perf, alloc, server, [main]);
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
	loadAllFiles(perf, server, [main]);
	Programs programs = buildToLowProgram(perf, alloc, server, versionInfoForJIT(), main);
	if (hasAnyDiagnostics(programs.program))
		printError(showDiagnostics(alloc, server, programs.program));
	return has(programs.lowProgram)
		? ExitCode(jitAndRun(perf, alloc, server.allSymbols, force(programs.lowProgram), jitOptions, programArgs))
		: ExitCode.error;
} }

ExitCode help(in Command.Help a) {
	print(a.helpText);
	final switch (a.kind) {
		case Command.Help.Kind.requested:
			return ExitCode.ok;
		case Command.Help.Kind.error:
			return ExitCode.error;
	}
}
