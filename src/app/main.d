module app.main;

@safe @nogc nothrow: // not pure

import app.dyncall : withRealExtern;
import app.fileSystem :
	getCwd,
	getPathToThisExecutable,
	spawnAndWait,
	stderr,
	withBuffer,
	withUriOrTemp,
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
version (GccJitAvailable) {
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
version (Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : prepend;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty;
import util.opt : force, has, none, Opt, some;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe;
import util.readOnlyStorage : ReadOnlyStorage;
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
	UrisInfo,
	uriToSafeCStr,
	TempStrForPath,
	toUri,
	writeFileUri;
import util.util : todo;
import util.writer : finishWriterToSafeCStr, Writer;
import versionInfo : versionInfoForJIT;

@system extern(C) int main(int argc, CStr* argv) {
	size_t GB = 1024 * 1024 * 1024;
	size_t memorySizeWords = GB * 3 / 2 / ulong.sizeof;
	return withBuffer!(int, ulong)(memorySizeWords, (scope ulong[] mem) {
		Alloc alloc = Alloc(mem);
		AllSymbols allSymbols = AllSymbols(ptrTrustMe(alloc));
		AllUris allUris = AllUris(ptrTrustMe(alloc), ptrTrustMe(allSymbols));
		ulong function() @safe @nogc pure nothrow getTimeNanosPure =
			cast(ulong function() @safe @nogc pure nothrow) &getTimeNanos;
		scope Perf perf = Perf(() => getTimeNanosPure());
		int res = go(alloc, perf, allSymbols, allUris, cast(SafeCStr[]) argv[1 .. argc]).value;
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
	version (Windows) {
		return (cast(ulong) GetTickCount()) * 1_000_000;
	} else {
		timespec time;
		clock_gettime(CLOCK_MONOTONIC, &time);
		return time.tv_sec * 1_000_000_000 + time.tv_nsec;
	}
}

ExitCode go(ref Alloc alloc, ref Perf perf, ref AllSymbols allSymbols, ref AllUris allUris, in SafeCStr[] args) {
	Uri crowDir = getCrowDir(allUris);
	Uri includeDir = childUri(allUris, crowDir, sym!"include");
	Uri cwd = toUri(allUris, getCwd(allUris));
	UrisInfo urisInfo = UrisInfo(some(cwd));
	Command command = parseCommand(alloc, allSymbols, allUris, cwd, args);
	ShowDiagOptions showDiagOptions = ShowDiagOptions(true);

	return command.matchImpure!ExitCode(
		(in Command.Build x) =>
			runBuild(alloc, perf, allSymbols, allUris, urisInfo, includeDir, x.mainUri, x.options),
		(in Command.Document x) =>
			runDocument(alloc, perf, allSymbols, allUris, urisInfo, includeDir, x.rootUris),
		(in Command.Help x) =>
			help(x),
		(in Command.Print x) =>
			withReadOnlyStorage!ExitCode(allUris, includeDir, (in ReadOnlyStorage storage) {
				DiagsAndResultStrs printed = print(
					alloc,
					perf,
					// Just going with this arbitrarily. Only affects concrete-model priting.
					versionInfoForJIT(),
					allSymbols,
					allUris,
					urisInfo,
					storage,
					showDiagOptions,
					x.kind,
					x.mainUri);
				if (!safeCStrIsEmpty(printed.diagnostics)) printErr(printed.diagnostics);
				if (!safeCStrIsEmpty(printed.result)) print(printed.result);
				return safeCStrIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
			}),
		(in Command.Run run) =>
			withReadOnlyStorage!ExitCode(allUris, includeDir, (in ReadOnlyStorage storage) =>
				run.options.matchImpure!ExitCode(
					(in RunOptions.Interpret) =>
						withRealExtern(alloc, allSymbols, allUris, (in Extern extern_) => buildAndInterpret(
							alloc,
							perf,
							allSymbols,
							allUris,
							urisInfo,
							storage,
							extern_,
							(in SafeCStr x) {
								printErr(x);
							},
							showDiagOptions,
							run.mainUri,
							getAllArgs(alloc, allUris, storage, run.mainUri, run.programArgs))),
					(in RunOptions.Jit it) {
						version (GccJitAvailable) {
							return buildAndJit(
								alloc,
								perf,
								allSymbols,
								allUris,
								urisInfo,
								it.options,
								showDiagOptions,
								storage,
								run.mainUri,
								getAllArgs(alloc, allUris, storage, run.mainUri, run.programArgs));
						} else {
							printErr(safeCStr!"'--jit' is not supported on Windows");
							return ExitCode.error;
						}
					})),
		(in Command.Test it) {
			version (Test) {
				return test(alloc, it.name);
			} else
				return printErr(safeCStr!"Did not compile with tests");
		},
		(in Command.Version) =>
			printVersion());
}

Uri getCrowDir(ref AllUris allUris) =>
	parentOrEmpty(allUris, parentOrEmpty(allUris, toUri(allUris,getPathToThisExecutable(allUris))));

SafeCStr[] getAllArgs(
	ref Alloc alloc,
	in AllUris allUris,
	in ReadOnlyStorage storage,
	Uri main,
	in SafeCStr[] programArgs,
) =>
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

ExitCode runDocument(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in UrisInfo urisInfo,
	Uri includeDir,
	in Uri[] rootUris,
) =>
	withReadOnlyStorage!ExitCode(allUris, includeDir, (in ReadOnlyStorage storage) {
		DocumentResult result =
			compileAndDocument(alloc, perf, allSymbols, allUris, urisInfo, storage, showDiagOptions, rootUris);
		return safeCStrIsEmpty(result.diagnostics) ? println(result.document) : printErr(result.diagnostics);
	});

ExitCode runBuild(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in UrisInfo urisInfo,
	Uri includeDir,
	Uri mainUri,
	in BuildOptions options,
) =>
	hasAnyOut(options.out_)
		? buildToCAndCompile(
			alloc, perf, allSymbols, allUris, urisInfo, showDiagOptions, includeDir, mainUri, options)
		: withReadOnlyStorage!ExitCode(allUris, includeDir, (in ReadOnlyStorage storage) {
			Opt!SafeCStr error = justTypeCheck(
				alloc, perf, allSymbols, allUris, urisInfo, storage, showDiagOptions, mainUri);
			return has(error) ? printErr(force(error)) : println(safeCStr!"OK");
		});

ShowDiagOptions showDiagOptions() =>
	ShowDiagOptions(true);

ExitCode buildToCAndCompile(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions showDiagOptions,
	Uri includeDir,
	Uri mainUri,
	BuildOptions options,
) =>
	withReadOnlyStorage!ExitCode(allUris, includeDir, (in ReadOnlyStorage storage) {
		BuildToCResult result =
			buildToC(alloc, perf, allSymbols, allUris, urisInfo, storage, showDiagOptions, mainUri);
		if (!safeCStrIsEmpty(result.diagnostics))
			printErr(result.diagnostics);
		return withUriOrTemp!cExtension(allUris, options.out_.outC, mainUri, (FileUri cUri) {
			ExitCode res = writeFile(allUris, cUri, result.cSource);
			return res == ExitCode.ok && has(options.out_.outExecutable)
				? compileC(
					alloc, perf, allSymbols, allUris,
					cUri, force(options.out_.outExecutable), result.externLibraries, options.cCompileOptions)
				: res;
		});
	});

version (GccJitAvailable) { ExitCode buildAndJit(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in UrisInfo urisInfo,
	in JitOptions jitOptions,
	in ShowDiagOptions showDiagOptions,
	in ReadOnlyStorage storage,
	Uri main,
	in SafeCStr[] programArgs,
) {
	ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, perf, versionInfoForJIT(), allSymbols, allUris, storage, main);
	if (!isEmpty(programs.program.diagnostics))
		printErr(strOfDiagnostics(
			alloc,
			allSymbols,
			allUris,
			urisInfo,
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

	SafeCStr[] args = cCompileArgs(alloc, allSymbols, allUris, cPath, asFileUri(allUris, exePath), externLibraries, options);
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
