module app.main;

@safe @nogc nothrow: // not pure

import app.dyncall : withRealExtern;
import app.fileSystem :
	getCwd,
	getPathToThisExecutable,
	spawnAndWait,
	stderr,
	withBuffer,
	withPathOrTemp,
	withReadOnlyStorage,
	writeFile;
import core.stdc.stdio : fprintf, printf;
version (Windows) {} else { import core.stdc.stdio : posixStderr = stderr; }

version (Windows) {
	import core.sys.windows.core : GetTickCount;
	import app.fileSystem : findPathToCl;
} else {
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
}
version (Windows) { } else {
	import backend.jit : jitAndRun;
}
import frontend.lang : cExtension, JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.extern_ : Extern;
import lib.cliParser : BuildOptions, CCompileOptions, Command, hasAnyOut, parseCommand, RunOptions;
import lib.compiler :
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	buildToLowProgram,
	compileAndDocument,
	DiagsAndResultStrs,
	DocumentResult,
	ExitCode,
	print,
	ProgramsAndFilesInfo,
	justTypeCheck;
import model.diag : isEmpty, isFatal;
import model.lowModel : ExternLibrary;
version(Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : prepend;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty;
import util.opt : force, has, none, Opt, some;
import util.path :
	AllPaths,
	childPath,
	Path,
	parentOrEmpty,
	PathsInfo,
	pathToSafeCStr,
	TempStrForPath,
	writePathPlain;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sym : AllSymbols, concatSyms, safeCStrOfSym, Sym, sym, writeSym;
import util.writer : finishWriterToSafeCStr, Writer;
import versionInfo : versionInfoForJIT;

@system extern(C) int main(int argc, CStr* argv) {
	size_t GB = 1024 * 1024 * 1024;
	size_t memorySizeWords = GB * 3 / 2 / ulong.sizeof;
	return withBuffer!(int, ulong)(memorySizeWords, (scope ulong[] mem) {
		Alloc alloc = Alloc(mem);
		AllSymbols allSymbols = AllSymbols(ptrTrustMe(alloc));
		AllPaths allPaths = AllPaths(ptrTrustMe(alloc), ptrTrustMe(allSymbols));
		ulong function() @safe @nogc pure nothrow getTimeNanosPure =
			cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
		scope Perf perf = Perf(() => getTimeNanosPure());
		int res = go(alloc, perf, allSymbols, allPaths, cast(SafeCStr[]) argv[1 .. argc]).value;
		if (perfEnabled)
			logPerf(perf);
		return res;
	});
}

private:

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
	version(Windows) {
		return (cast(ulong) GetTickCount()) * 1_000_000;
	} else {
		timespec time;
		clock_gettime(CLOCK_MONOTONIC, &time);
		return time.tv_sec * 1_000_000_000 + time.tv_nsec;
	}
}

ExitCode go(ref Alloc alloc, ref Perf perf, ref AllSymbols allSymbols, ref AllPaths allPaths, in SafeCStr[] args) {
	Path crowDir = getCrowDir(allPaths);
	Path includeDir = childPath(allPaths, crowDir, sym!"include");
	Path cwd = getCwd(allPaths);
	PathsInfo pathsInfo = PathsInfo(some(cwd));
	Command command = parseCommand(alloc, allSymbols, allPaths, cwd, args);
	ShowDiagOptions showDiagOptions = ShowDiagOptions(true);

	return command.matchImpure!ExitCode(
		(in Command.Build it) =>
			runBuild(alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, it.mainPath, it.options),
		(in Command.Document it) =>
			runDocument(alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, it.rootPaths),
		(in Command.Help it) =>
			help(it),
		(in Command.Print it) =>
			withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
				DiagsAndResultStrs printed = print(
					alloc,
					perf,
					// Just going with this arbitrarily. Only affects concrete-model priting.
					versionInfoForJIT(),
					allSymbols,
					allPaths,
					pathsInfo,
					storage,
					showDiagOptions,
					it.kind,
					it.mainPath);
				if (!safeCStrIsEmpty(printed.diagnostics)) printErr(printed.diagnostics);
				if (!safeCStrIsEmpty(printed.result)) print(printed.result);
				return safeCStrIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
			}),
		(in Command.Run run) =>
			withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) =>
				run.options.matchImpure!ExitCode(
					(in RunOptions.Interpret) =>
						withRealExtern(alloc, allSymbols, allPaths, (in Extern extern_) => buildAndInterpret(
							alloc,
							perf,
							allSymbols,
							allPaths,
							pathsInfo,
							storage,
							extern_,
							(in SafeCStr x) {
								printErr(x);
							},
							showDiagOptions,
							run.mainPath,
							getAllArgs(alloc, allPaths, storage, run.mainPath, run.programArgs))),
					(in RunOptions.Jit it) {
						version (Windows) {
							printErr(safeCStr!"'--jit' is not supported on Windows");
							return ExitCode.error;
						} else {
							return buildAndJit(
								alloc,
								perf,
								allSymbols,
								allPaths,
								pathsInfo,
								it.options,
								showDiagOptions,
								storage,
								run.mainPath,
								getAllArgs(alloc, allPaths, storage, run.mainPath, run.programArgs));
						}
					})),
		(in Command.Test it) {
			version(Test) {
				return test(alloc, it.name);
			} else
				return printErr(safeCStr!"Did not compile with tests");
		},
		(in Command.Version) =>
			printVersion());
}

Path getCrowDir(ref AllPaths allPaths) =>
	parentOrEmpty(allPaths, parentOrEmpty(allPaths, getPathToThisExecutable(allPaths)));

SafeCStr[] getAllArgs(
	ref Alloc alloc,
	in AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
	in SafeCStr[] programArgs,
) =>
	prepend(alloc, pathToSafeCStr(alloc, allPaths, main), programArgs);

@trusted ExitCode printVersion() {
	static immutable string date = import("date.txt")[0 .. "2020-02-02".length];
	static immutable string commitHash = import("commit-hash.txt")[0 .. 8];
	printf("%.*s (%.*s)", cast(int) date.length, date.ptr, cast(int) commitHash.length, commitHash.ptr);
	version(Debug) {
		printf(", debug build");
	}
	version(assert) {} else {
		printf(", assertions disabled");
	}
	version(TailRecursionAvailable) {} else {
		printf(", no tail calls");
	}
	printf("\n");
	return ExitCode.ok;
}

ExitCode runDocument(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	Path includeDir,
	in Path[] rootPaths,
) =>
	withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
		DocumentResult result =
			compileAndDocument(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, rootPaths);
		return safeCStrIsEmpty(result.diagnostics) ? println(result.document) : printErr(result.diagnostics);
	});

ExitCode runBuild(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	Path includeDir,
	Path mainPath,
	in BuildOptions options,
) =>
	hasAnyOut(options.out_)
		? buildToCAndCompile(
			alloc, perf, allSymbols, allPaths, pathsInfo, showDiagOptions, includeDir, mainPath, options)
		: withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
			Opt!SafeCStr error = justTypeCheck(
				alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, mainPath);
			return has(error) ? printErr(force(error)) : println(safeCStr!"OK");
		});

ShowDiagOptions showDiagOptions() =>
	ShowDiagOptions(true);

ExitCode buildToCAndCompile(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in ShowDiagOptions showDiagOptions,
	Path includeDir,
	Path mainPath,
	BuildOptions options,
) =>
	withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
		BuildToCResult result =
			buildToC(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, mainPath);
		if (!safeCStrIsEmpty(result.diagnostics))
			printErr(result.diagnostics);
		return withPathOrTemp!cExtension(allPaths, options.out_.outC, mainPath, (Path cPath) {
			ExitCode res = writeFile(allPaths, cPath, result.cSource);
			return res == ExitCode.ok && has(options.out_.outExecutable)
				? compileC(
					alloc, perf, allSymbols, allPaths,
					cPath, force(options.out_.outExecutable), result.externLibraries, options.cCompileOptions)
				: res;
		});
	});

version (Windows) { } else { ExitCode buildAndJit(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	in JitOptions jitOptions,
	in ShowDiagOptions showDiagOptions,
	in ReadOnlyStorage storage,
	Path main,
	in SafeCStr[] programArgs,
) {
	ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, perf, versionInfoForJIT(), allSymbols, allPaths, storage, main);
	if (!isEmpty(programs.program.diagnostics))
		printErr(strOfDiagnostics(
			alloc,
			allSymbols,
			allPaths,
			pathsInfo,
			showDiagOptions,
			programs.program));
	return isFatal(programs.program.diagnostics)
		? ExitCode.error
		: ExitCode(jitAndRun(alloc, perf, allSymbols, programs.lowProgram, jitOptions, programArgs));
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
			safeCStr!"/wd4098",
			safeCStr!"/wd4100",
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
	ref AllPaths allPaths,
	in Path cPath,
	in Path exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	SafeCStr[] args = cCompileArgs(alloc, allSymbols, allPaths, cPath, exePath, externLibraries, options);
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
		spawnAndWait(alloc, allPaths, executable, args)
	)(alloc, perf, PerfMeasure.cCompile);
}

SafeCStr[] cCompileArgs(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in Path cPath,
	in Path exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, pathToSafeCStr(alloc, allPaths, cPath));
	version (Windows) {
		add(alloc, args, safeCStr!"/link");
	}
	foreach (ExternLibrary x; externLibraries) {
		version (Windows) {
			Sym xDotLib = concatSyms(allSymbols, [x.libraryName, sym!".lib"]);
			if (has(x.configuredPath)) {
				Path path = childPath(allPaths, force(x.configuredPath), xDotLib);
				add(alloc, args, pathToSafeCStr(alloc, allPaths, path));
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
			if (has(x.configuredPath)) {
				Writer writer = Writer(ptrTrustMe(alloc));
				writer ~= "-L";
				writePathPlain(writer, allPaths, force(x.configuredPath));
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
		writePathPlain(writer, allPaths, exePath);
		add(alloc, args, finishWriterToSafeCStr(writer));
	} else {
		addAll(alloc, args, [
			safeCStr!"-o",
			pathToSafeCStr(alloc, allPaths, exePath),
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
