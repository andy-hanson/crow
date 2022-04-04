@safe @nogc nothrow: // not pure

import core.memory : pureFree, pureMalloc;
import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fclose, ferror, FILE, fopen, fprintf, fread, fseek, ftell, fwrite, printf, SEEK_END, SEEK_SET;
version (Windows) {} else { import core.stdc.stdio : posixStderr = stderr; }
import core.stdc.string : strerror;

version (Windows) {
	import core.sys.windows.core :
		CloseHandle,
		CreateDirectoryA,
		CreatePipe,
		CreateProcessA,
		DeleteFileA,
		DWORD,
		ERROR_BROKEN_PIPE,
		ERROR_NO_MORE_FILES,
		FILE_ATTRIBUTE_DIRECTORY,
		FindClose,
		FindFirstFileA,
		FindNextFileA,
		FormatMessageA,
		FORMAT_MESSAGE_FROM_SYSTEM,
		FORMAT_MESSAGE_IGNORE_INSERTS,
		GetExitCodeProcess,
		GetFileAttributesA,
		GetLastError,
		GetModuleFileNameA,
		GetModuleHandle,
		ERROR_PATH_NOT_FOUND,
		HANDLE,
		HANDLE_FLAG_INHERIT,
		HMODULE,
		INFINITE,
		INVALID_FILE_ATTRIBUTES,
		INVALID_HANDLE_VALUE,
		PROCESS_INFORMATION,
		ReadFile,
		RemoveDirectoryA,
		SearchPathA,
		SECURITY_ATTRIBUTES,
		SetHandleInformation,
		STARTF_USESTDHANDLES,
		STARTUPINFOA,
		WaitForSingleObject,
		WIN32_FIND_DATAA;
} else {
	import core.sys.posix.spawn : posix_spawn;
	import core.sys.posix.sys.wait : waitpid;
	import core.sys.posix.dirent : DIR, dirent, opendir, readdir;
	import core.sys.posix.sys.stat : mkdir, pid_t, S_IFDIR, S_IFMT, S_IRWXU, stat, stat_t;
	import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
	import core.sys.posix.unistd : getcwd, read, readlink, unlink;
}
version (Windows) { } else {
	import backend.jit : jitAndRun;
}
import frontend.lang : JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.applyFn : u64OfI32, u64OfI64;
import interpret.extern_ :
	DynCallType,
	DynCallSig,
	Extern,
	ExternFunPtrsForAllLibraries,
	ExternFunPtrsForLibrary,
	FunPtr,
	WriteError,
	writeSymToCb;
import lib.cliParser :
	BuildOptions,
	CCompileOptions,
	Command,
	defaultExeExtension,
	hasAnyOut,
	matchCommand,
	parseCommand,
	matchRunOptions,
	RunOptions;
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
import model.model : hasDiags;
import model.lowModel : ExternLibraries, ExternLibrary;
version(Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : emptyArr;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : mapImpure, prepend, zipImpureSystem;
import util.col.dict : KeyValuePair, makeDictFromKeys, SymDict, zipToDict;
import util.col.mutArr : MutArr, mutArrIsEmpty, mutArrRange, push, pushAll, tempAsArr;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty, safeCStrSize, strEq, strOfCStr;
import util.conv : bitsOfFloat64, float32OfBits, float64OfBits;
import util.memory : memset;
import util.opt : force, has, none, Opt, some;
import util.path :
	AllPaths,
	baseName,
	childPath,
	Path,
	PathAndExtension,
	parent,
	parentOrEmpty,
	parsePath,
	parsePathAndExtension,
	PathsInfo,
	pathToSafeCStr,
	pathToTempStr,
	TempStrForPath;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe_mut;
import util.readOnlyStorage : matchReadFileResult, ReadFileResult, ReadOnlyStorage;
import util.sym :
	AllSymbols,
	concatSyms,
	emptySym,
	hashSym,
	Operator,
	shortSym,
	shortSymValue,
	SpecialSym,
	Sym,
	symAsTempBuffer,
	symEq,
	symForOperator,
	symForSpecial,
	symOfStr,
	writeSym;
import util.util : castImmutableRef, todo, unreachable, verify;
import util.writer : finishWriterToSafeCStr, writeChar, Writer, writeSafeCStr, writeStatic;
import versionInfo : versionInfoForJIT;

@system extern(C) immutable(int) main(immutable size_t argc, immutable CStr* argv) {
	immutable size_t memorySizeBytes = 1536 * 1024 * 1024; // 1.5 GB
	ubyte* mem = cast(ubyte*) pureMalloc(memorySizeBytes);
	scope(exit) pureFree(mem);
	verify(mem != null);
	Alloc alloc = Alloc(mem, memorySizeBytes);
	AllSymbols allSymbols = AllSymbols(ptrTrustMe_mut(alloc));
	AllPaths allPaths = AllPaths(ptrTrustMe_mut(alloc), ptrTrustMe_mut(allSymbols));
	immutable CommandLineArgs args = parseCommandLineArgs(allPaths, argc, argv);
	immutable immutable(ulong) function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(immutable(ulong) function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	immutable int res = go(alloc, perf, allSymbols, allPaths, args).value;
	if (perfEnabled)
		logPerf(perf);
	return res;
}

private:

void logPerf(scope ref Perf perf) {
	eachMeasure(perf, (immutable SafeCStr name, immutable PerfMeasureResult m) @trusted {
		printf(
			"%s * %d took %llums and %lluKB\n",
			name.ptr,
			m.count,
			divRound(m.nanoseconds, 1_000_000),
			divRound(m.bytesAllocated, 1024));
	});
}

immutable(ulong) divRound(immutable ulong a, immutable ulong b) {
	immutable ulong div = a / b;
	immutable ulong rem = a % b;
	return div + (rem >= b / 2 ? 1 : 0);
}
static assert(divRound(15, 10) == 2);
static assert(divRound(14, 10) == 1);

@trusted immutable(ulong) getTimeNanos() {
	version(Windows) {
		return todo!(immutable ulong)("TODO");
	} else {
		timespec time;
		clock_gettime(CLOCK_MONOTONIC, &time);
		return time.tv_sec * 1_000_000_000 + time.tv_nsec;
	}
}

immutable(ExitCode) go(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable CommandLineArgs args,
) {
	immutable Path crowDir = parentOrEmpty(allPaths, parentOrEmpty(allPaths, args.pathToThisExecutable.path));
	immutable Path includeDir = childPath(allPaths, crowDir, shortSym("include"));
	immutable Path tempDir = childPath(allPaths, crowDir, shortSym("temp"));
	immutable ExitCode setupTempExitCode = setupTempDir(allSymbols, allPaths, tempDir);
	if (setupTempExitCode != ExitCode.ok)
		return printErr(safeCStr!"Failed to set up temporary directory\n");

	immutable Path cwd = getCwd(allPaths);
	immutable PathsInfo pathsInfo = immutable PathsInfo(some(cwd));
	immutable Command command = parseCommand(alloc, allPaths, cwd, args.args);
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(true);

	return matchCommand!(immutable ExitCode)(
		command,
		(ref immutable Command.Build it) =>
			runBuild(alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, tempDir, it.mainPath, it.options),
		(ref immutable Command.Document it) =>
			runDocument(alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, it.rootPaths),
		(ref immutable Command.Help it) =>
			help(it),
		(ref immutable Command.Print it) =>
			withReadOnlyStorage!(immutable ExitCode)(
				allPaths,
				includeDir,
				(scope ref immutable ReadOnlyStorage storage) {
					immutable DiagsAndResultStrs printed = print(
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
		(ref immutable Command.Run run) =>
			withReadOnlyStorage(
				allPaths,
				includeDir,
				(scope ref immutable ReadOnlyStorage storage) =>
					matchRunOptions!(immutable ExitCode)(
						run.options,
						(ref immutable RunOptions.Interpret) =>
							withRealExtern(alloc, allSymbols, allPaths, (scope ref Extern extern_) => buildAndInterpret(
								alloc,
								perf,
								allSymbols,
								allPaths,
								pathsInfo,
								storage,
								extern_,
								(scope immutable SafeCStr x) @safe {
									printErr(x);
								},
								showDiagOptions,
								run.mainPath,
								getAllArgs(alloc, allPaths, storage, run.mainPath, run.programArgs))),
						(ref immutable RunOptions.Jit it) {
							version (Windows) {
								return unreachable!(immutable ExitCode);
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
		(ref immutable Command.Test it) {
			version(Test) {
				return test(alloc, it.name);
			} else
				return printErr(safeCStr!"Did not compile with tests");
		},
		(ref immutable Command.Version) =>
			printVersion());
}

immutable(SafeCStr[]) getAllArgs(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	scope ref immutable ReadOnlyStorage storage,
	immutable Path main,
	immutable SafeCStr[] programArgs,
) {
	return prepend(alloc, pathToSafeCStr(alloc, allPaths, main, symForSpecial(SpecialSym.dotCrow)), programArgs);
}

@trusted immutable(ExitCode) setupTempDir(
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path tempDir,
) {
	TempStrForPath dirPathBuf = void;
	immutable CStr dirPath = pathToTempStr(dirPathBuf, allPaths, tempDir, emptySym).ptr;
	version (Windows) {
		if (GetFileAttributesA(dirPath) == INVALID_FILE_ATTRIBUTES) {
			immutable int ok = CreateDirectoryA(dirPath, null);
			if (!ok) {
				fprintf(stderr, "error creating directory %s\n", dirPath);
				return ExitCode.error;
			}
		} else {
			immutable ExitCode err = clearDir(allSymbols, allPaths, tempDir);
			if (err != ExitCode.ok)
				return err;
		}
	} else {
		DIR* dir = opendir(dirPath);
		if (dir == null) {
			if (errno == ENOENT) {
				immutable int err = mkdir(dirPath, S_IRWXU);
				if (err != 0) {
					fprintf(stderr, "error creating directory %s\n", dirPath);
					return ExitCode.error;
				}
			} else {
				fprintf(stderr, "error opening directory %s: error code %d\n", dirPath, errno);
				return ExitCode.error;
			}
		} else {
			immutable ExitCode err = clearDirRecur(allSymbols, allPaths, tempDir, dir);
			if (err != ExitCode.ok)
				return err;
		}
	}
	return ExitCode.ok;
}

version (Windows) {
	@system immutable(ExitCode) clearDir(
		ref AllSymbols allSymbols,
		ref AllPaths allPaths,
		immutable Path dirPath,
	) {
		TempStrForPath searchPathBuf = void;
		immutable CStr searchPath =
			pathToTempStr(searchPathBuf, allPaths, childPath(allPaths, dirPath, symForOperator(Operator.times))).ptr;
		WIN32_FIND_DATAA fileData;
		HANDLE fileHandle = FindFirstFileA(searchPath, &fileData);
		if (fileHandle == INVALID_HANDLE_VALUE) {
			immutable DWORD error = GetLastError();
			if (error != ERROR_PATH_NOT_FOUND) {
				printLastError(error, "clearing temp directory");
				return ExitCode.error;
			}
			return ExitCode.ok;
		} else {
			immutable ExitCode err = clearDirRecur(allSymbols, allPaths, dirPath, fileHandle);
			immutable int closeOk = FindClose(fileHandle);
			verify(cast(immutable bool) closeOk);
			return err;
		}
	}

	@system immutable(ExitCode) clearDirRecur(
		ref AllSymbols allSymbols,
		ref AllPaths allPaths,
		immutable Path dirPath,
		HANDLE fileHandle,
	) {
		WIN32_FIND_DATAA fileData;
		if (FindNextFileA(fileHandle, &fileData)) {
			immutable string name = strOfCStr(cast(immutable) fileData.cFileName.ptr);
			if (!strEq(name, "..")) {
				immutable Path child = childPath(allPaths, dirPath, symOfStr(allSymbols, name));
				TempStrForPath childBuf = void;
				immutable CStr childCStr = pathToTempStr(childBuf, allPaths, child).ptr;
				if (fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
					immutable ExitCode clearErr = clearDir(allSymbols, allPaths, child);
					if (clearErr != ExitCode.ok)
						return clearErr;
					if (!RemoveDirectoryA(childCStr)) {
						fprintf(stderr, "Error deleting directory %s\n", childCStr);
						return ExitCode.error;
					}
				} else {
					if (!DeleteFileA(childCStr)) {
						fprintf(stderr, "Error deleting file %s\n", childCStr);
						return ExitCode.error;
					}
				}
			}
			return clearDirRecur(allSymbols, allPaths, dirPath, fileHandle);
		} else {
			verify(GetLastError() == ERROR_NO_MORE_FILES);
			return ExitCode.ok;
		}
	}
} else {
	@system immutable(ExitCode) clearDirRecur(
		ref AllSymbols allSymbols,
		ref AllPaths allPaths,
		immutable Path dirPath,
		DIR* dir,
	) {
		immutable dirent* entry = cast(immutable) readdir(dir);
		if (entry == null)
			return ExitCode.ok;
		immutable string entryName = strOfCStr(entry.d_name.ptr);
		if (!strEq(entryName, ".") && !strEq(entryName, "..")) {
			immutable Path child = childPath(allPaths, dirPath, symOfStr(allSymbols, entryName));
			stat_t s;
			TempStrForPath buf = void;
			immutable CStr childCStr = pathToTempStr(buf, allPaths, child).ptr;
			stat(childCStr, &s);
			if ((s.st_mode & S_IFMT) == S_IFDIR) {
				DIR* innerDir = opendir(childCStr);
				if (innerDir == null) {
					fprintf(stderr, "error opening directory %s (to delete contents)\n", childCStr);
					return ExitCode.error;
				}
				immutable ExitCode err = clearDirRecur(allSymbols, allPaths, child, innerDir);
				if (err != ExitCode.ok)
					return err;
			} else {
				immutable int err = unlink(childCStr);
				if (err != 0) {
					fprintf(stderr, "error removing %s\n", childCStr);
					return ExitCode.error;
				}
			}
		}
		return clearDirRecur(allSymbols, allPaths, dirPath, dir);
	}
}

@system immutable(ExitCode) mkdirRecur(ref const AllPaths allPaths, immutable Path dir) {
	version (Windows) {
		return todo!(immutable ExitCode)("!");
	} else {
		TempStrForPath buf = void;
		immutable CStr dirCStr = pathToTempStr(buf, allPaths, dir).ptr;
		immutable int err = mkdir(dirCStr, S_IRWXU);
		if (err == ENOENT) {
			immutable Opt!Path par = parent(allPaths, dir);
			if (has(par)) {
				immutable ExitCode res = mkdirRecur(allPaths, force(par));
				return res == ExitCode.ok
					? handleMkdirErr(mkdir(dirCStr, S_IRWXU), dirCStr)
					: res;
			}
		}
		return handleMkdirErr(err, dirCStr);
	}
}

version (Windows) {
} else {
	@system immutable(ExitCode) handleMkdirErr(immutable int err, immutable char* dir) {
		if (err != 0)
			fprintf(stderr, "Error making directory %s: %s\n", dir, strerror(errno));
		return immutable ExitCode(err);
	}
}

@trusted immutable(ExitCode) printVersion() {
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

immutable(ExitCode) runDocument(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	immutable Path includeDir,
	immutable Path[] rootPaths,
) {
	return withReadOnlyStorage(allPaths, includeDir, (scope ref immutable ReadOnlyStorage storage) {
		immutable DocumentResult result =
			compileAndDocument(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, rootPaths);
		return safeCStrIsEmpty(result.diagnostics) ? println(result.document) : printErr(result.diagnostics);
	});
}

struct RunBuildResult {
	immutable ExitCode err;
	immutable Opt!PathAndExtension exePath;
}

immutable(ExitCode) runBuild(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	immutable Path includeDir,
	immutable Path tempDir,
	immutable Path mainPath,
	ref immutable BuildOptions options,
) {
	return hasAnyOut(options.out_)
		? runBuildInner(
			alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, tempDir,
			mainPath, options, ExeKind.allowNoExe).err
		: withReadOnlyStorage(allPaths, includeDir, (scope ref immutable ReadOnlyStorage storage) =>
			justTypeCheck(alloc, perf, allSymbols, allPaths, storage, mainPath));
}

enum ExeKind { ensureExe, allowNoExe }
immutable(RunBuildResult) runBuildInner(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	immutable Path includeDir,
	immutable Path tempDir,
	immutable Path mainPath,
	ref immutable BuildOptions options,
	immutable ExeKind exeKind,
) {
	immutable Sym name = baseName(allPaths, mainPath);
	immutable PathAndExtension cPath = has(options.out_.outC)
		? force(options.out_.outC)
		: immutable PathAndExtension(childPath(allPaths, tempDir, name), symForSpecial(SpecialSym.dotC));
	immutable Opt!PathAndExtension exePath = has(options.out_.outExecutable)
		? options.out_.outExecutable
		: exeKind == ExeKind.ensureExe
		? some(immutable PathAndExtension(childPath(allPaths, tempDir, name), defaultExeExtension))
		: none!PathAndExtension;
	immutable ExitCode err = buildToCAndCompile(
		alloc,
		perf,
		allSymbols,
		allPaths,
		pathsInfo,
		showDiagOptions,
		includeDir,
		mainPath,
		cPath,
		exePath,
		options.cCompileOptions);
	return immutable RunBuildResult(err, exePath);
}

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(true);

immutable(ExitCode) buildToCAndCompile(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable Path includeDir,
	immutable Path mainPath,
	immutable PathAndExtension cPath,
	immutable Opt!PathAndExtension exePath,
	ref immutable CCompileOptions cCompileOptions,
) {
	return withReadOnlyStorage(allPaths, includeDir, (scope ref immutable ReadOnlyStorage storage) {
		immutable BuildToCResult result =
			buildToC(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, mainPath);
		if (safeCStrIsEmpty(result.diagnostics)) {
			immutable ExitCode res = writeFile(allPaths, cPath, result.cSource);
			return res == ExitCode.ok && has(exePath)
				? compileC(
					alloc, perf, allSymbols, allPaths,
					cPath, force(exePath), result.externLibraries, cCompileOptions)
				: res;
		} else
			return printErr(result.diagnostics);
	});
}

version (Windows) { } else { immutable(ExitCode) buildAndJit(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable JitOptions jitOptions,
	ref immutable ShowDiagOptions showDiagOptions,
	scope ref immutable ReadOnlyStorage storage,
	immutable Path main,
	immutable SafeCStr[] programArgs,
) {
	immutable ProgramsAndFilesInfo programs =
		buildToLowProgram(alloc, perf, versionInfoForJIT(), allSymbols, allPaths, storage, main);
	return hasDiags(programs.program)
		? printErr(strOfDiagnostics(
			alloc,
			allSymbols,
			allPaths,
			pathsInfo,
			showDiagOptions,
			programs.program.filesInfo,
			programs.program.diagnostics))
		: immutable ExitCode(
			jitAndRun(alloc, perf, castImmutableRef(allSymbols), programs.lowProgram, jitOptions, programArgs));
} }

immutable(ExitCode) help(ref immutable Command.Help a) {
	println(a.helpText);
	final switch (a.kind) {
		case Command.Help.Kind.requested:
			return ExitCode.ok;
		case Command.Help.Kind.error:
			return ExitCode.error;
	}
}

immutable(SafeCStr[]) cCompilerArgs(ref immutable CCompileOptions options) {
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

@trusted immutable(ExitCode) compileC(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable PathAndExtension cPath,
	immutable PathAndExtension exePath,
	scope immutable ExternLibrary[] externLibraries,
	ref immutable CCompileOptions options,
) {
	immutable SafeCStr[] args = cCompileArgs(alloc, allSymbols, allPaths, cPath, exePath, externLibraries, options);
	version (Windows) {
		TempStrForPath clPath = void;
		immutable ExitCode clErr = findPathToCl(clPath);
		if (clErr != ExitCode.ok)
			return clErr;
		scope immutable SafeCStr executable = immutable SafeCStr(cast(immutable) clPath.ptr);
	} else {
		immutable SafeCStr executable = safeCStr!"/usr/bin/cc";
	}

	immutable int err = withMeasure!(immutable int, () =>
		spawnAndWait(alloc, allPaths, executable, args)
	)(alloc, perf, PerfMeasure.cCompile);
	return immutable ExitCode(err);
}

version (Windows) {
	@system immutable(ExitCode) findPathToCl(ref TempStrForPath res) {
		int len = SearchPathA(null, "cl.exe", null, cast(uint) res.length, res.ptr, null);
		if (len == 0) {
			fprintf(stderr, "Could not find cl.exe on path. Be sure you are using a Native Tools Command Prompt.");
			return ExitCode.error;
		}
		return ExitCode.ok;
	}
}

immutable(SafeCStr[]) cCompileArgs(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable PathAndExtension cPath,
	immutable PathAndExtension exePath,
	scope immutable ExternLibrary[] externLibraries,
	ref immutable CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, pathToSafeCStr(alloc, allPaths, cPath));
	version (Windows) {
		add(alloc, args, safeCStr!"/link");
	}
	foreach (immutable ExternLibrary x; externLibraries) {
		version (Windows) {
			if (has(x.configuredPath)) {
				immutable Sym xDotLib = concatSyms(allSymbols, [x.libraryName, symForSpecial(SpecialSym.dotLib)]);
				immutable Path libPath = childPath(allPaths, force(x.configuredPath), xDotLib);
				add(alloc, args, pathToSafeCStr(alloc, allPaths, libPath));
			}
		} else {
			if (has(x.configuredPath))
				todo!void("link to library at custom path on Posix");
			else {
				Writer writer = Writer(ptrTrustMe_mut(alloc));
				writeStatic(writer, "-l");
				writeSym(writer, allSymbols, x.libraryName);
				add(alloc, args, finishWriterToSafeCStr(writer));
			}
		}
	}
	version (Windows) {
		add(alloc, args, safeCStr!"/DEBUG");
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeStatic(writer, "/out:");
		writeSafeCStr(writer, pathToSafeCStr(alloc, allPaths, exePath));
		add(alloc, args, finishWriterToSafeCStr(writer));
	} else {
		addAll(alloc, args, [
			safeCStr!"-o",
			pathToSafeCStr(alloc, allPaths, exePath),
		]);
	}
	return finishArr(alloc, args);
}

@trusted immutable(ExitCode) print(scope immutable SafeCStr a) {
	printf("%s", a.ptr);
	return ExitCode.ok;
}

@trusted immutable(ExitCode) println(scope immutable SafeCStr a) {
	printf("%s\n", a.ptr);
	return ExitCode.ok;
}

@trusted immutable(ExitCode) printErr(scope immutable SafeCStr a) {
	fprintf(stderr, "%s", a.ptr);
	return ExitCode.error;
}

immutable(T) withReadOnlyStorage(T)(
	scope ref const AllPaths allPaths,
	immutable Path includeDir,
	immutable(T) delegate(scope ref immutable ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope immutable ReadOnlyStorage storage = immutable ReadOnlyStorage(
		includeDir,
		(
			immutable Path path,
			void delegate(immutable ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
		) =>
			tryReadFile(allPaths, path, emptySym, NulTerminate.no, cb),
		(
			immutable Path path,
			immutable Sym extension,
			void delegate(immutable ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) =>
			tryReadFile(allPaths, path, extension, NulTerminate.yes, (immutable ReadFileResult!(ubyte[]) x) =>
				matchReadFileResult!(void, ubyte[])(
					x,
					(immutable ubyte[] bytes) @trusted =>
						cb(immutable ReadFileResult!SafeCStr(immutable SafeCStr(cast(immutable char*) bytes.ptr))),
					(immutable(ReadFileResult!(ubyte[]).NotFound)) =>
						cb(immutable ReadFileResult!SafeCStr(immutable ReadFileResult!SafeCStr.NotFound())),
					(immutable(ReadFileResult!(ubyte[]).Error)) =>
						cb(immutable ReadFileResult!SafeCStr(immutable ReadFileResult!SafeCStr.Error())))));
	return cb(storage);
}

immutable(ExitCode) withRealExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	DCCallVM* dcVm = dcNewCallVM(0x1000);
	verify(dcVm != null);
	dcMode(dcVm, DC_CALL_C_DEFAULT);
	MutArr!(immutable DLLib*) allLibraries;
	scope Extern extern_ = Extern(
		(scope immutable ExternLibraries libraries, scope WriteError writeError) =>
			loadLibraries(alloc, allSymbols, allPaths, allLibraries, libraries, writeError),
		(FunPtr funPtr, scope immutable DynCallSig sig, scope immutable ulong[] parameters) =>
			dynamicCallFunPtr(funPtr, sig, parameters, dcVm));

	immutable ExitCode res = cb(extern_);

	foreach (immutable DLLib* lib; mutArrRange(allLibraries))
		dlFreeLibrary(lib);
	dcFree(dcVm);
	return res;
}

immutable(Opt!ExternFunPtrsForAllLibraries) loadLibraries(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	MutArr!(immutable DLLib*) allLibraries,
	scope immutable ExternLibraries libraries,
	scope WriteError writeError,
) {
	bool success = true;
	immutable DLLib*[] libs = mapImpure(alloc, libraries, (ref immutable ExternLibrary x) {
		immutable Opt!(DLLib*) lib = getLibrary(allSymbols, allPaths, x.libraryName, x.configuredPath, writeError);
		if (has(lib))
			return force(lib);
		else {
			success = false;
			return null;
		}
	});
	pushAll(alloc, allLibraries, libs);

	return success
		? loadLibrariesInner(alloc, allSymbols, libraries, libs, writeError)
		: none!ExternFunPtrsForAllLibraries;
}

immutable(Opt!(DLLib*)) getLibrary(
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Sym libraryName,
	immutable Opt!Path configuredPath,
	scope WriteError writeError,
) {
	immutable Sym fileName = dllOrSoName(allSymbols, libraryName);
	immutable Opt!(DLLib*) fromPath = has(configuredPath)
		? tryLoadLibraryFromPath(allPaths, childPath(allPaths, force(configuredPath), fileName))
		: none!(DLLib*);
	if (has(fromPath)) {
		return fromPath;
	} else {
		switch (libraryName.value) {
			case shortSymValue("c"):
			case shortSymValue("m"):
				version (Windows) {
					return loadLibraryFromName(safeCStr!"ucrtbase.dll", writeError);
				} else {
					return some!(DLLib*)(null);
				}
			default:
				return loadLibraryFromName(allSymbols, fileName, writeError);
		}
	}
}

immutable(Sym) dllOrSoName(ref AllSymbols allSymbols, immutable Sym libraryName) {
	version (Windows) {
		return concatSyms(allSymbols, [libraryName, symForSpecial(SpecialSym.dotDll)]);
	} else {
		return concatSyms(allSymbols, [shortSym("lib"), libraryName, symForSpecial(SpecialSym.dotSo)]);
	}
}

@trusted immutable(Opt!(DLLib*)) tryLoadLibraryFromPath(
	ref const AllPaths allPaths,
	immutable Path path,
) {
	TempStrForPath buf = void;
	immutable SafeCStr pathStr = pathToTempStr(buf, allPaths, path);
	immutable DLLib* res = dlLoadLibrary(pathStr.ptr);
	return res == null ? none!(DLLib*) : some!(DLLib*)(res);
}

@trusted immutable(Opt!(DLLib*)) loadLibraryFromName(
	ref const AllSymbols allSymbols,
	immutable Sym name,
	scope WriteError writeError,
) {
	char[256] buf = symAsTempBuffer!256(allSymbols, name);
	return loadLibraryFromName(immutable SafeCStr(cast(immutable) buf.ptr), writeError);
}

immutable(Opt!(DLLib*)) loadLibraryFromName(scope immutable SafeCStr name, scope WriteError writeError) {
	immutable DLLib* res = dlLoadLibrary(name.ptr);
	if (res == null) {
		// TODO: use a Diagnostic
		writeError(safeCStr!"Could not load library ");
		writeError(name);
		writeError(safeCStr!"\n");
		return none!(DLLib*);
	} else
		return some!(DLLib*)(res);
}

immutable(Opt!ExternFunPtrsForAllLibraries) loadLibrariesInner(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable ExternLibraries libraries,
	immutable DLLib*[] libs,
	scope WriteError writeError,
) {
	MutArr!(immutable KeyValuePair!(Sym, Sym)) failures;
	immutable ExternFunPtrsForAllLibraries res = zipToDict!(Sym, SymDict!FunPtr, symEq, hashSym, ExternLibrary, DLLib*)(
		alloc,
		libraries,
		libs,
		(ref immutable ExternLibrary x, ref immutable DLLib* lib) @safe @nogc nothrow {
			immutable ExternFunPtrsForLibrary funPtrs = makeDictFromKeys!(Sym, FunPtr, symEq, hashSym)(
				alloc,
				x.importNames,
				(immutable Sym importName) {
					immutable Opt!FunPtr p = getExternFunPtr(allSymbols, lib, importName);
					if (has(p))
						return force(p);
					else {
						push(alloc, failures, immutable KeyValuePair!(Sym , Sym)(x.libraryName, importName));
						return null;
					}
				});
			return immutable KeyValuePair!(Sym, ExternFunPtrsForLibrary)(x.libraryName, funPtrs);
		});
	foreach (immutable KeyValuePair!(Sym, Sym) x; tempAsArr(failures)) {
		writeError(safeCStr!"Could not load extern function ");
		writeSymToCb(writeError, allSymbols, x.value);
		writeError(safeCStr!" from library ");
		writeSymToCb(writeError, allSymbols, x.key);
		writeError(safeCStr!"\n");
	}
	return mutArrIsEmpty(failures) ? some(res) : none!ExternFunPtrsForAllLibraries;
}

@trusted pure immutable(Opt!FunPtr) getExternFunPtr(
	ref const AllSymbols allSymbols,
	immutable DLLib* library,
	immutable Sym name,
) {
	immutable char[256] nameBuffer = symAsTempBuffer!256(allSymbols, name);
	immutable CStr nameCStr = nameBuffer.ptr;
	DCpointer ptr = dlFindSymbol(library, nameCStr);
	return ptr == null ? none!FunPtr : some!FunPtr(cast(immutable) ptr);
}

@system immutable(ulong) dynamicCallFunPtr(
	immutable FunPtr funPtr,
	scope immutable DynCallSig sig,
	scope immutable ulong[] parameters,
	DCCallVM* dcVm,
) {
	DCpointer ptr = cast(DCpointer) funPtr;
	//printf("Gonna call %s\n", nameCStr);
	dcReset(dcVm);
	zipImpureSystem!(ulong, DynCallType)(
		parameters,
		sig.parameterTypes,
		(ref immutable ulong value, ref immutable DynCallType type) {
			final switch (type) {
				case DynCallType.bool_:
					dcArgBool(dcVm, cast(bool) value);
					break;
				case DynCallType.char8:
					todo!void("handle this type");
					break;
				case DynCallType.int8:
					todo!void("handle this type");
					break;
				case DynCallType.int16:
					dcArgShort(dcVm, cast(short) value);
					break;
				case DynCallType.int32:
					dcArgInt(dcVm, cast(int) value);
					break;
				case DynCallType.float32:
					dcArgFloat(dcVm, float32OfBits(cast(uint) value));
					break;
				case DynCallType.float64:
					dcArgDouble(dcVm, float64OfBits(value));
					break;
				case DynCallType.nat8:
					todo!void("handle this type");
					break;
				case DynCallType.nat16:
					todo!void("handle this type");
					break;
				case DynCallType.nat32:
					dcArgInt(dcVm, cast(uint) value);
					break;
				case DynCallType.int64:
				case DynCallType.nat64:
					dcArgLong(dcVm, value);
					break;
				case DynCallType.pointer:
					dcArgPointer(dcVm, cast(void*) value);
					break;
				case DynCallType.void_:
					unreachable!void();
			}
		});

	immutable ulong res = () {
		final switch (sig.returnType) {
			case DynCallType.bool_:
				return dcCallBool(dcVm, ptr);
			case DynCallType.char8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int16:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int32:
				return u64OfI32(dcCallInt(dcVm, ptr));
			case DynCallType.int64:
			case DynCallType.nat64:
				return u64OfI64(dcCallLong(dcVm, ptr));
			case DynCallType.float32:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.float64:
				return bitsOfFloat64(dcCallDouble(dcVm, ptr));
			case DynCallType.nat8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.nat16:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.nat32:
				return cast(uint) dcCallInt(dcVm, ptr);
			case DynCallType.pointer:
				return cast(size_t) dcCallPointer(dcVm, ptr);
			case DynCallType.void_:
				dcCallVoid(dcVm, ptr);
				return 0;
		}
	}();
	dcReset(dcVm);
	// printf("Did call %s\n", nameCStr);

	return res;
}

extern(C) {
	// dlfcn.h
	//void* dlopen(const char* file, int mode);
	//int dlclose(void* handle);
	//void* dlsym(void* handle, const char* name);
	//enum RTLD_LAZY = 1;

	// dyncall_types.h
	//alias DCvoid = void;
	alias DCbool = int;
	alias DCchar = char;
	//alias DCuchar = uchar;
	alias DCshort = short;
	//alias DCushort = ushort;
	alias DCint = int;
	//alias DCuint = uint;
	alias DClong = long;
	//alias DCulong = ulong;
	//typedef DC_LONG_LONG DClonglong;
	//typedef unsigned DC_LONG_LONG DCulonglong;
	alias DCfloat = float;
	alias DCdouble = double;
	alias DCpointer = void*;
	//alias DCstring = const char*;
	alias DCsize = size_t;

	// dyncall.h
	struct DCCallVM;

	enum DC_CALL_C_DEFAULT = 0;

	DCCallVM* dcNewCallVM(DCsize size);
	void dcFree(DCCallVM* vm);
	void dcReset(DCCallVM* vm);

	void dcMode(DCCallVM* vm, DCint mode);

	void dcArgBool (DCCallVM* vm, DCbool value);
	//void dcArgChar (DCCallVM* vm, DCchar value);
	void dcArgShort (DCCallVM* vm, DCshort value);
	void dcArgInt (DCCallVM* vm, DCint value);
	void dcArgLong (DCCallVM* vm, DClong value);
	//void dcArgLongLong (DCCallVM* vm, DClonglong value);
	void dcArgFloat (DCCallVM* vm, DCfloat value);
	void dcArgDouble (DCCallVM* vm, DCdouble value);
	void dcArgPointer (DCCallVM* vm, DCpointer value);
	// void dcArgStruct (DCCallVM* vm, DCstruct* s, DCpointer value);

	void dcCallVoid (DCCallVM* vm, DCpointer funcptr);
	DCbool dcCallBool (DCCallVM* vm, DCpointer funcptr);
	//DCchar dcCallChar (DCCallVM* vm, DCpointer funcptr);
	//DCshort dcCallShort (DCCallVM* vm, DCpointer funcptr);
	DCint dcCallInt (DCCallVM* vm, DCpointer funcptr);
	DClong dcCallLong (DCCallVM* vm, DCpointer funcptr);
	//DClonglong dcCallLongLong (DCCallVM* vm, DCpointer funcptr);
	//DCfloat dcCallFloat (DCCallVM* vm, DCpointer funcptr);
	DCdouble dcCallDouble (DCCallVM* vm, DCpointer funcptr);
	DCpointer dcCallPointer (DCCallVM* vm, DCpointer funcptr);
	// void dcCallStruct (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

	//DCint dcGetError (DCCallVM* vm);
}

extern(C) {
	// based on dyncall/dynload/dynload.h
	struct DLLib;
	immutable(DLLib*) dlLoadLibrary(scope const char* libpath);
	pure void dlFreeLibrary(immutable DLLib* pLib);
	pure void* dlFindSymbol(immutable DLLib* pLib, scope const char* pSymbolName);
}

enum NulTerminate { no, yes }

@system void withBufferPossiblyOnStack(immutable size_t maxSizeOnStack)(
	immutable size_t size,
	scope void delegate(scope ubyte*) @nogc nothrow cb,
) {
	if (size <= maxSizeOnStack) {
		ubyte[maxSizeOnStack] buf = void;
		cb(buf.ptr);
	} else {
		ubyte* buf = cast(ubyte*) pureMalloc(size);
		cb(buf);
		pureFree(buf);
	}
}

@trusted void tryReadFile(
	scope ref const AllPaths allPaths,
	immutable Path path,
	immutable Sym extension,
	immutable NulTerminate nulTerminate,
	scope void delegate(immutable ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
) {
	TempStrForPath pathBuf = void;
	immutable CStr pathCStr = pathToTempStr(pathBuf, allPaths, path, extension).ptr;

	FILE* fd = fopen(pathCStr, "rb");
	if (fd == null)
		return cb(errno == ENOENT
			? immutable ReadFileResult!(ubyte[])(immutable ReadFileResult!(ubyte[]).NotFound())
			: immutable ReadFileResult!(ubyte[])(immutable ReadFileResult!(ubyte[]).Error()));
	scope(exit) fclose(fd);

	immutable int err = fseek(fd, 0, SEEK_END);
	if (err) todo!void("!");

	immutable long ftellResult = ftell(fd);
	if (ftellResult < 0)
		todo!void("ftell failed");
	immutable size_t fileSize = cast(size_t) ftellResult;
	if (fileSize == 0) {
		if (nulTerminate) {
			static immutable ubyte[] bytes = [0];
			cb(immutable ReadFileResult!(ubyte[])(bytes));
		} else
			cb(immutable ReadFileResult!(ubyte[])(emptyArr!ubyte));
	} else {
		withBufferPossiblyOnStack!0x100000(fileSize + (nulTerminate ? 1 : 0), (scope ubyte* contentBuf) {
			// Go back to the beginning so we can read
			immutable int err2 = fseek(fd, 0, SEEK_SET);
			verify(err2 == 0);

			immutable size_t nBytesRead = fread(contentBuf, ubyte.sizeof, fileSize, fd);
			verify(nBytesRead == fileSize);
			if (ferror(fd))
				todo!void("error reading file");
			if (nulTerminate) contentBuf[nBytesRead] = '\0';

			return cb(immutable ReadFileResult!(ubyte[])(
				cast(immutable) contentBuf[0 .. nBytesRead + (nulTerminate ? 1 : 0)]));
		});
	}
}

@trusted immutable(ExitCode) writeFile(
	ref const AllPaths allPaths,
	immutable PathAndExtension path,
	scope immutable SafeCStr content,
) {
	FILE* fd = tryOpenFileForWrite(allPaths, path);
	if (fd == null)
		return ExitCode.error;
	else {
		scope(exit) fclose(fd);

		immutable size_t size = safeCStrSize(content);
		immutable long wroteBytes = fwrite(content.ptr, char.sizeof, size, fd);
		if (wroteBytes != size) {
			if (wroteBytes == -1)
				todo!void("writeFile failed");
			else
				todo!void("writeFile -- didn't write all the bytes?");
		}
		return ExitCode.ok;
	}
}

@system FILE* tryOpenFileForWrite(ref const AllPaths allPaths, immutable PathAndExtension path) {
	TempStrForPath buf = void;
	immutable CStr pathCStr = pathToTempStr(buf, allPaths, path).ptr;
	FILE* fd = fopen(pathCStr, "w");
	if (fd == null) {
		if (errno == ENOENT) {
			immutable Opt!Path par = parent(allPaths, path.path);
			if (has(par)) {
				immutable ExitCode res = mkdirRecur(allPaths, force(par));
				if (res == ExitCode.ok)
					return fopen(pathCStr, "w");
			}
		} else {
			fprintf(stderr, "Failed to write file %s: %s\n", pathCStr, strerror(errno));
		}
	}
	return fd;
}

struct CommandLineArgs {
	immutable PathAndExtension pathToThisExecutable;
	immutable SafeCStr[] args;
}

@trusted immutable(CommandLineArgs) parseCommandLineArgs(
	ref AllPaths allPaths,
	immutable size_t argc,
	immutable CStr* argv,
) {
	immutable SafeCStr[] allArgs = cast(immutable SafeCStr[]) argv[0 .. argc];
	// Take the tail because the first one is 'crow'
	return immutable CommandLineArgs(getPathToThisExecutable(allPaths), allArgs[1 .. $]);
}

version (Windows) {
	extern(C) char* _getcwd(char* buffer, int maxlen);
	extern(C) immutable(int) _mkdir(scope const char*, immutable uint);

	alias getcwd = _getcwd;
	alias mkdir = _mkdir;
}

@trusted immutable(Path) getCwd(ref AllPaths allPaths) {
	TempStrForPath res = void;
	const char* cwd = getcwd(res.ptr, res.length);
	return cwd == null
		? todo!(immutable Path)("getcwd failed")
		: parsePath(allPaths, immutable SafeCStr(cast(immutable) cwd));
}

@trusted immutable(PathAndExtension) getPathToThisExecutable(ref AllPaths allPaths) {
	TempStrForPath res = void;
	version(Windows) {
		HMODULE mod = GetModuleHandle(null);
		verify(mod != null);
		immutable DWORD size = GetModuleFileNameA(mod, res.ptr, res.length);
	} else {
		immutable long size = readlink("/proc/self/exe", res.ptr, res.length);
	}
	verify(size > 0 && size < res.length);
	return parsePathAndExtension(allPaths, immutable SafeCStr(cast(immutable) res.ptr));
}

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted immutable(int) spawnAndWait(
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	immutable SafeCStr executablePath,
	immutable SafeCStr[] args,
) {
	version (Windows) {
		immutable CStr argsCStr = windowsArgsCStr(tempAlloc, executablePath, args);

		HANDLE stdoutRead;
		HANDLE stdoutWrite;
		HANDLE stderrRead;
		HANDLE stderrWrite;
		SECURITY_ATTRIBUTES saAttr;
		saAttr.nLength = SECURITY_ATTRIBUTES.sizeof;
		saAttr.bInheritHandle = true;
		saAttr.lpSecurityDescriptor = null;

		if (!CreatePipe(&stdoutRead, &stdoutWrite, &saAttr, 0))
			todo!void("");
		if (!SetHandleInformation(stdoutRead, HANDLE_FLAG_INHERIT, 0))
			todo!void("");
		if (!CreatePipe(&stderrRead, &stderrWrite, &saAttr, 0))
			todo!void("");
		if (!SetHandleInformation(stderrRead, HANDLE_FLAG_INHERIT, 0))
			todo!void("");

		STARTUPINFOA startupInfo = void;
		memset(cast(ubyte*) &startupInfo, 0, STARTUPINFOA.sizeof);
		startupInfo.cb = STARTUPINFOA.sizeof;
		startupInfo.dwFlags = STARTF_USESTDHANDLES;
		startupInfo.hStdOutput = stdoutWrite;
		startupInfo.hStdError = stderrWrite;

		PROCESS_INFORMATION processInfo;
		memset(cast(ubyte*) &processInfo, 0, PROCESS_INFORMATION.sizeof);
		int ok = CreateProcessA(
			executablePath.ptr,
			// not sure why Windows makes this mutable
			cast(char*) argsCStr,
			null,
			null,
			true,
			0,
			null,
			null,
			&startupInfo,
			&processInfo);
		if (!ok) {
			printLastError(GetLastError(), "Spawning cl");
			return 1;
		}

		verifyOk(CloseHandle(stdoutWrite));
		verifyOk(CloseHandle(stderrWrite));

		char[0x10000] stdoutBuf = void;
		char[0x10000] stderrBuf = void;
		readFromPipe(stdoutBuf, stdoutRead);
		verifyOk(CloseHandle(stdoutRead));
		readFromPipe(stderrBuf, stderrRead);
		verifyOk(CloseHandle(stderrRead));

		WaitForSingleObject(processInfo.hProcess, INFINITE);

		DWORD exitCode;
		int ok2 = GetExitCodeProcess(processInfo.hProcess, &exitCode);
		if (!ok2)
			todo!void("");

		if (exitCode != 0) {
			fprintf(stderr, "Error invoking C compiler: %s\n", argsCStr);
			fprintf(stderr, "Exit code %d\n", exitCode);
			fprintf(stderr, "C compiler stderr: %s\n", stderrBuf.ptr);
			printf("C compiler stdout: %s\n", stdoutBuf.ptr);
		}

		verifyOk(CloseHandle(processInfo.hProcess));
		verifyOk(CloseHandle(processInfo.hThread));

		return exitCode;
	} else {
		pid_t pid;
		immutable int spawnStatus = posix_spawn(
			&pid,
			executablePath.ptr,
			null,
			null,
			// https://stackoverflow.com/questions/50596439/can-string-literals-be-passed-in-posix-spawns-argv
			cast(char**) convertArgs(tempAlloc, executablePath, args),
			cast(char**) environ);
		if (spawnStatus == 0) {
			int waitStatus;
			immutable int resPid = waitpid(pid, &waitStatus, 0);
			verify(resPid == pid);
			if (WIFEXITED(waitStatus))
				return WEXITSTATUS(waitStatus); // only valid if WIFEXITED
			else {
				if (WIFSIGNALED(waitStatus))
					return todo!int("process exited with signal");
				else
					return todo!int("process exited non-normally");
			}
		} else
			return todo!int("posix_spawn failed");
	}
}

version (Windows) {
	immutable(CStr) windowsArgsCStr(
		ref TempAlloc tempAlloc,
		immutable SafeCStr executablePath,
		scope immutable SafeCStr[] args,
	) {
		Writer writer = Writer(ptrTrustMe_mut(tempAlloc));
		writeChar(writer, '"');
		writeSafeCStr(writer, executablePath);
		writeChar(writer, '"');
		foreach (immutable SafeCStr arg; args) {
			writeChar(writer, ' ');
			writeSafeCStr(writer, arg);
		}
		return finishWriterToSafeCStr(writer).ptr;
	}
}

void verifyOk(int ok) {
	verify(ok == 1);
}

version (Windows) {
	@system void readFromPipe(ref char[0x10000] out_, HANDLE pipe) {
		readFromPipeRecur(out_.ptr, out_.ptr + out_.length, pipe);
	}

	@system void readFromPipeRecur(char* out_, char* outEnd, HANDLE pipe) {
		verify(out_ < outEnd);
		if (out_ + 1 == outEnd) {
			*out_ = '\0';
		} else {
			uint nRead;
			int ok = ReadFile(pipe, out_, cast(uint) (outEnd - out_ - 1), &nRead, null);
			if (ok) {
				readFromPipeRecur(out_ + nRead, outEnd, pipe);
			} else {
				int err = GetLastError();
				if (err == ERROR_BROKEN_PIPE) {
					*out_ = '\0';
				} else {
					printLastError(GetLastError(), "readFromPipe");
					todo!void("");
				}
			}
		}
	}
}

// Return should be const, but some posix functions aren't marked that way
@system immutable(CStr*) convertArgs(
	ref Alloc alloc,
	immutable SafeCStr executable,
	immutable SafeCStr[] args,
) {
	ArrBuilder!CStr cArgs;
	add(alloc, cArgs, executable.ptr);
	foreach (immutable SafeCStr arg; args)
		add(alloc, cArgs, arg.ptr);
	add(alloc, cArgs, null);
	return finishArr(alloc, cArgs).ptr;
}

// D doesn't declare this anywhere for some reason
extern(C) extern immutable char** environ;

// Copying from /usr/include/dmd/druntime/import/core/sys/posix/sys/wait.d
// to avoid linking to druntime
int __WTERMSIG( int status ) { return status & 0x7F; }
int WEXITSTATUS( int status ) { return ( status & 0xFF00 ) >> 8; }
bool WIFEXITED( int status ) { return __WTERMSIG( status ) == 0; }
bool WIFSIGNALED( int status )
{
	return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
}

version (Windows) {
	@system void printLastError(immutable int error, immutable char* description) {
		char[0x400] buffer;
		int size = FormatMessageA(
			FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			null,
			error,
			0,
			buffer.ptr,
			buffer.length,
			null);
		verify(size != 0 && size < buffer.length);
		fprintf(stderr, "%s: %.*s", description, size, buffer.ptr);
	}
}

FILE* stderr() {
	version (Windows) {
		return __acrt_iob_func(2);
	} else {
		return posixStderr;
	}
}
version (Windows) {
	extern(C) FILE* __acrt_iob_func(uint);
}
