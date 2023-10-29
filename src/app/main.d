module app.main;

@safe @nogc nothrow: // not pure

import app.dyncall : withRealExtern;
import app.fileSystem :
	getCwd,
	getPathToThisExecutable,
	spawnAndWait,
	stderr,
	tryReadFile,
	withUriOrTemp,
	writeFile;
import core.stdc.stdio : fprintf, printf;
import core.stdc.stdlib : free, malloc;
version (Windows) {} else { import core.stdc.stdio : posixStderr = stderr; }

version (Windows) {
	import core.sys.windows.core : GetTickCount;
	import app.fileSystem : findPathToCl;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}
version (GccJitAvailable) {
	import backend.jit : jitAndRun;
}
import frontend.lang : cExtension, JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions;
import interpret.extern_ : Extern;
import lib.cliParser : BuildOptions, CCompileOptions, Command, hasAnyOut, parseCommand, PrintKind, RunOptions;
import lib.server :
	addOrChangeFile,
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
	printLowModel,
	printModel,
	printTokens,
	ProgramsAndFilesInfo,
	Server,
	setCwd,
	setDiagOptions,
	setIncludeDir,
	showDiagnostics;
import model.diag : diagnosticsIsEmpty, diagnosticsIsFatal;
import model.lowModel : ExternLibrary;
import model.model : Program;
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : prepend;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty;
import util.exitCode : ExitCode;
import util.json : jsonToString;
import util.opt : force, has, none;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, concatSyms, safeCStrOfSym, Sym, sym, writeSym;
import util.uri :
	AllUris,
	asFileUri,
	childFileUri,
	childUri,
	FileUri,
	fileUriToSafeCStr,
	isFileUri,
	Uri,
	parentOrEmpty,
	uriToSafeCStr,
	TempStrForPath,
	toUri,
	writeFileUri;
import util.util : todo, verify;
import util.writer : finishWriterToSafeCStr, Writer;
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
	Server server = Server(Alloc(mem));
	Uri cwd = toUri(server.allUris, getCwd(server.allUris));
	setCwd(server, cwd);
	setDiagOptions(server, ShowDiagOptions(true));
	Command command = parseCommand(
		server.alloc, server.allSymbols, server.allUris, cwd, cast(SafeCStr[]) argv[1 .. argc]);
	int res = go(perf, server, command).value;
	if (perfEnabled)
		logPerf(perf);
	return res;
}

private:

void loadAllFiles(ref Perf perf, ref Server server, in Uri[] rootUris) {
	Uri[] unknowns = rootUris;
	do {
		foreach (Uri uri; unknowns)
			loadSingleFile(server, uri);
		justParseEverything(server.alloc, perf, server, rootUris);
		unknowns = allUnknownUris(server.alloc, server);
	} while (!empty(unknowns));
}

void loadSingleFile(ref Server server, Uri uri) {
	addOrChangeFile(server, uri, tryReadFile(server.storage.alloc, server.allUris, uri));
}

void logPerf(in Perf perf) {
	eachMeasure(perf, (in SafeCStr name, in PerfMeasureResult m) @trusted {
		printf(
			"%s * %d took %llums and %lluKB\n",
			name.ptr,
			m.count,
			divRound(m.nanoseconds, 1_000_000),
			divRound(m.bytesAllocated, 1024));
	});
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

ExitCode go(ref Perf perf, ref Server server, in Command command) {
	setIncludeDir(server, childUri(server.allUris, getCrowDir(server.allUris), sym!"include"));
	return command.matchImpure!ExitCode(
		(in Command.Build x) =>
			runBuild(perf, server, x.mainUri, x.options),
		(in Command.Document x) {
			loadAllFiles(perf, server, x.rootUris);
			DocumentResult result = getDocumentation(server.alloc, perf, server, x.rootUris);
			return safeCStrIsEmpty(result.diagnostics) ? println(result.document) : printErr(result.diagnostics);
		},
		(in Command.Help x) =>
			help(x),
		(in Command.Print x) {
			DiagsAndResultJson printed = () {
				final switch (x.kind) {
					case PrintKind.tokens:
						loadSingleFile(server, x.mainUri);
						return printTokens(server.alloc, perf, server, x.mainUri);
					case PrintKind.ast:
						loadSingleFile(server, x.mainUri);
						return printAst(server.alloc, perf, server, x.mainUri);
					case PrintKind.model:
						loadAllFiles(perf, server, [x.mainUri]);
						return printModel(server.alloc, perf, server, x.mainUri);
					case PrintKind.concreteModel:
						loadAllFiles(perf, server, [x.mainUri]);
						return printConcreteModel(server.alloc, perf, server, versionInfoForJIT(), x.mainUri);
					case PrintKind.lowModel:
						loadAllFiles(perf, server, [x.mainUri]);
						return printLowModel(server.alloc, perf, server, versionInfoForJIT(), x.mainUri);
				}
			}();
			if (!safeCStrIsEmpty(printed.diagnostics))
				printErr(printed.diagnostics);
			print(jsonToString(server.alloc, server.allSymbols, printed.result));
			return safeCStrIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
		},
		(in Command.Run run) {
			loadAllFiles(perf, server, [run.mainUri]);
			return run.options.matchImpure!ExitCode(
				(in RunOptions.Interpret) =>
					withRealExtern(server.alloc, server.allSymbols, server.allUris, (in Extern extern_) =>
						buildAndInterpret(
							server.alloc,
							perf,
							server,
							extern_,
							(in SafeCStr x) {
								printErr(x);
							},
							run.mainUri,
							getAllArgs(server.alloc, server.allUris, run.mainUri, run.programArgs))),
				(in RunOptions.Jit x) {
					version (GccJitAvailable) {
						return buildAndJit(
							perf,
							server,
							x.options,
							run.mainUri,
							getAllArgs(server.alloc, server.allUris, run.mainUri, run.programArgs));
					} else {
						printErr(safeCStr!"'--jit' is not supported on Windows");
						return ExitCode.error;
					}
				});
		},
		(in Command.Test it) {
			version (Test) {
				return test(server.alloc, it.name);
			} else
				return printErr(safeCStr!"Did not compile with tests");
		},
		(in Command.Version) =>
			printVersion());
}

Uri getCrowDir(ref AllUris allUris) =>
	parentOrEmpty(allUris, parentOrEmpty(allUris, toUri(allUris, getPathToThisExecutable(allUris))));

SafeCStr[] getAllArgs(ref Alloc alloc, in AllUris allUris, Uri main, in SafeCStr[] programArgs) =>
	prepend(alloc, uriToSafeCStr(alloc, allUris, main), programArgs);

@trusted ExitCode printVersion() {
	static immutable string date = import("date.txt")[0 .. "2020-02-02".length];
	static immutable string commitHash = import("commit-hash.txt")[0 .. 8];
	printf("%.*s (%.*s)", cast(int) date.length, date.ptr, cast(int) commitHash.length, commitHash.ptr);
	version (Debug) {
		printf(", debug build");
	}
	version (assert) {} else {
		printf(", assertions disabled");
	}
	version (TailRecursionAvailable) {} else {
		printf(", no tail calls");
	}
	version (GccJitEnabled) {} else {
		printf(", does not support '--jit'");
	}
	printf(", built with %s\n", dCompilerName);
	return ExitCode.ok;
}

immutable(char*) dCompilerName() {
	version (DigitalMars) {
		return "DMD";
	} else version (GNU) {
		return "GDC";
	} else version (LDC) {
		return "LDC";
	} else {
		static assert(false);
	}
}

ExitCode runBuild(ref Perf perf, ref Server server, Uri main, in BuildOptions options) {
	loadAllFiles(perf, server, [main]);
	if (hasAnyOut(options.out_))
		return buildToCAndCompile(perf, server, main, options);
	else {
		Program program = justTypeCheck(server.alloc, perf, server, [main]);
		return diagnosticsIsEmpty(program.diagnostics)
			? println(safeCStr!"OK")
			: printErr(showDiagnostics(server.alloc, server, program));
	}
}

ExitCode buildToCAndCompile(ref Perf perf, ref Server server, Uri main, BuildOptions options) {
	loadAllFiles(perf, server, [main]);
	BuildToCResult result = buildToC(server.alloc, perf, server, main);
	if (!safeCStrIsEmpty(result.diagnostics))
		printErr(result.diagnostics);
	return withUriOrTemp!cExtension(server.allUris, options.out_.outC, main, (FileUri cUri) {
		ExitCode res = writeFile(server.allUris, cUri, result.cSource);
		return res == ExitCode.ok && has(options.out_.outExecutable)
			? compileC(
				server.alloc, perf, server.allSymbols, server.allUris,
				cUri, force(options.out_.outExecutable), result.externLibraries, options.cCompileOptions)
			: res;
	});
}

version (GccJitAvailable) { ExitCode buildAndJit(
	ref Perf perf,
	ref Server server,
	in JitOptions jitOptions,
	Uri main,
	in SafeCStr[] programArgs,
) {
	loadAllFiles(perf, server, [main]);
	ProgramsAndFilesInfo programs = buildToLowProgram(server.alloc, perf, server, versionInfoForJIT(), main);
	if (!diagnosticsIsEmpty(programs.program.diagnostics))
		printErr(showDiagnostics(server.alloc, server, programs.program));
	return diagnosticsIsFatal(programs.program.diagnostics)
		? ExitCode.error
		: ExitCode(jitAndRun(server.alloc, perf, server.allSymbols, programs.lowProgram, jitOptions, programArgs));
} }

ExitCode help(in Command.Help a) {
	println(a.helpText);
	final switch (a.kind) {
		case Command.Help.Kind.requested:
			return ExitCode.ok;
		case Command.Help.Kind.error:
			return ExitCode.error;
	}
}

SafeCStr[] cCompilerArgs(in CCompileOptions options) {
	version (Windows) {
		static immutable SafeCStr[] optimizedArgs = [
			safeCStr!"/Zi",
			safeCStr!"/std:c17",
			safeCStr!"/Wall",
			safeCStr!"/wd4034",
			safeCStr!"/wd4098",
			safeCStr!"/wd4100",
			safeCStr!"/wd4295",
			safeCStr!"/wd4820",
			safeCStr!"/WX",
			safeCStr!"/O2",
		];
		static immutable SafeCStr[] regularArgs = optimizedArgs[0 .. $ - 1];
	} else {
		static immutable SafeCStr[] optimizedArgs = [
			safeCStr!"-Werror",
			safeCStr!"-Wextra",
			safeCStr!"-Wall",
			safeCStr!"-ansi",
			safeCStr!"-std=c17",
			safeCStr!"-Wno-maybe-uninitialized",
			safeCStr!"-Wno-missing-field-initializers",
			safeCStr!"-Wno-unused-function",
			safeCStr!"-Wno-unused-parameter",
			safeCStr!"-Wno-unused-but-set-variable",
			safeCStr!"-Wno-unused-variable",
			safeCStr!"-Wno-unused-value",
			safeCStr!"-Wno-builtin-declaration-mismatch",
			safeCStr!"-Wno-address-of-packed-member",
			safeCStr!"-Ofast",
		];
		static immutable SafeCStr[] regularArgs = optimizedArgs[0 .. $ - 1] ~ [safeCStr!"-g"];
	}
	final switch (options.optimizationLevel) {
		case OptimizationLevel.none:
			return regularArgs;
		case OptimizationLevel.o2:
			return optimizedArgs;
	}
}

@trusted ExitCode compileC(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in FileUri cPath,
	in Uri exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	if (!isFileUri(allUris, exePath)) {
		fprintf(stderr, "Can't compile to non-file path\n");
		return ExitCode.error;
	}

	SafeCStr[] args = cCompileArgs(
		alloc, allSymbols, allUris, cPath, asFileUri(allUris, exePath), externLibraries, options);
	version (Windows) {
		TempStrForPath clPath = void;
		ExitCode clErr = findPathToCl(clPath);
		if (clErr != ExitCode.ok)
			return clErr;
		scope SafeCStr executable = SafeCStr(cast(immutable) clPath.ptr);
	} else {
		scope SafeCStr executable = safeCStr!"/usr/bin/cc";
	}
	return withMeasure!(ExitCode, () =>
		spawnAndWait(alloc, allUris, executable, args)
	)(alloc, perf, PerfMeasure.cCompile);
}

SafeCStr[] cCompileArgs(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in FileUri cPath,
	in FileUri exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, fileUriToSafeCStr(alloc, allUris, cPath));
	version (Windows) {
		add(alloc, args, safeCStr!"/link");
	}
	foreach (ExternLibrary x; externLibraries) {
		version (Windows) {
			Sym xDotLib = concatSyms(allSymbols, [x.libraryName, sym!".lib"]);
			if (has(x.configuredDir)) {
				FileUri path = childFileUri(allUris, force(x.configuredDir), xDotLib);
				add(alloc, args, fileUriToSafeCStr(alloc, allUris, path));
			} else
				switch (x.libraryName.value) {
					case sym!"c".value:
					case sym!"m".value:
						break;
					default:
						add(alloc, args, safeCStrOfSym(alloc, allSymbols, xDotLib));
						break;
				}
		} else {
			if (has(x.configuredDir)) {
				Writer writer = Writer(ptrTrustMe(alloc));
				writer ~= "-L";
				if (!isFileUri(allUris, force(x.configuredDir)))
					todo!void("diagnostic: can't link to non-file");
				writeFileUri(writer, allUris, asFileUri(allUris, force(x.configuredDir)));
				add(alloc, args, finishWriterToSafeCStr(writer));
			}

			Writer writer = Writer(ptrTrustMe(alloc));
			writer ~= "-l";
			writeSym(writer, allSymbols, x.libraryName);
			add(alloc, args, finishWriterToSafeCStr(writer));
		}
	}
	version (Windows) {
		add(alloc, args, safeCStr!"/DEBUG");
		Writer writer = Writer(ptrTrustMe(alloc));
		writer ~= "/out:";
		writeFileUri(writer, allUris, exePath);
		add(alloc, args, finishWriterToSafeCStr(writer));
	} else {
		add(alloc, args, safeCStr!"-lm");
		addAll(alloc, args, [
			safeCStr!"-o",
			fileUriToSafeCStr(alloc, allUris, exePath),
		]);
	}
	return finishArr(alloc, args);
}

@trusted ExitCode print(in SafeCStr a) {
	printf("%s", a.ptr);
	return ExitCode.ok;
}

@trusted ExitCode println(in SafeCStr a) {
	printf("%s\n", a.ptr);
	return ExitCode.ok;
}

@trusted ExitCode printErr(in SafeCStr a) {
	fprintf(stderr, "%s", a.ptr);
	return ExitCode.error;
}
