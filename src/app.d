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
		SetLastError,
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
	import core.sys.posix.unistd : getcwd, read, readlink, unlink, posixWrite = write;
}
version (Windows) { } else {
	import backend.jit : jitAndRun;
}
import frontend.lang : JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.applyFn : u64OfI32, u64OfI64;
import interpret.extern_ : DynCallType, Extern;
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
version(Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : prepend, zipImpureSystem;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrEq, safeCStrIsEmpty, safeCStrSize, strEq, strOfCStr;
import util.col.tempStr : asTempSafeCStr, initializeTempStr, length, pushToTempStr, setLength, TempStr;
import util.conv : bitsOfFloat64, float32OfBits, float64OfBits;
import util.memory : memset;
import util.opt : force, forceOrTodo, has, none, Opt, some;
import util.path :
	AllPaths,
	baseName,
	childPath,
	Path,
	PathAndExtension,
	parent,
	parsePath,
	PathsInfo,
	pathToSafeCStr,
	pathToTempStr,
	TempStrForPath;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe_mut;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sym : AllSymbols, shortSym, Sym, symAsTempBuffer, writeSym;
import util.util : castImmutableRef, todo, unreachable, verify;
import util.writer : finishWriterToSafeCStr, Writer, writeSafeCStr, writeStatic;
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
	immutable Path crowDir = getCrowDirectory(allPaths, args.pathToThisExecutable);
	immutable Path includeDir = childPath(allPaths, crowDir, shortSym("include"));
	immutable Path tempDir = childPath(allPaths, crowDir, shortSym("temp"));
	immutable ExitCode setupTempExitCode = setupTempDir(allPaths, tempDir);
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
						(ref immutable RunOptions.Interpret) {
							return withRealExtern(alloc, allSymbols, (scope ref Extern extern_) => buildAndInterpret(
								alloc,
								perf,
								allSymbols,
								allPaths,
								pathsInfo,
								storage,
								extern_,
								showDiagOptions,
								run.mainPath,
								getAllArgs(alloc, allPaths, storage, run.mainPath, run.programArgs)));
						},
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
	return prepend(alloc, pathToSafeCStr(alloc, allPaths, main, safeCStr!".crow"), programArgs);
}

@trusted immutable(ExitCode) setupTempDir(ref const AllPaths allPaths, immutable Path tempDir) {
	TempStrForPath dirPath = pathToTempStr(allPaths, tempDir, safeCStr!"");
	immutable CStr dirPathCStr = asTempSafeCStr(dirPath).ptr;
	version (Windows) {
		if (GetFileAttributesA(dirPathCStr) == INVALID_FILE_ATTRIBUTES) {
			immutable int ok = CreateDirectoryA(dirPathCStr, null);
			if (!ok) {
				fprintf(stderr, "error creating directory %s\n", dirPathCStr);
				return ExitCode.error;
			}
		} else {
			immutable ExitCode err = clearDir(dirPath);
			if (err != ExitCode.ok)
				return err;
		}
	} else {
		DIR* dir = opendir(dirPathCStr);
		if (dir == null) {
			if (errno == ENOENT) {
				immutable int err = mkdir(dirPathCStr, S_IRWXU);
				if (err != 0) {
					fprintf(stderr, "error creating directory %s\n", dirPathCStr);
					return ExitCode.error;
				}
			} else {
				fprintf(stderr, "error opening directory %s: error code %d\n", dirPathCStr, errno);
				return ExitCode.error;
			}
		} else {
			immutable ExitCode err = clearDirRecur(dirPath, dir);
			if (err != ExitCode.ok)
				return err;
		}
	}
	return ExitCode.ok;
}

version (Windows) {
	@system immutable(ExitCode) clearDir(ref TempStrForPath dirPath) {
		immutable size_t oldLength = length(dirPath);
		pushToTempStr(dirPath, "/*");
		WIN32_FIND_DATAA fileData;
		HANDLE fileHandle = FindFirstFileA(asTempSafeCStr(dirPath).ptr, &fileData);
		setLength(dirPath, oldLength);
		if (fileHandle == INVALID_HANDLE_VALUE) {
			immutable DWORD error = GetLastError();
			if (error != ERROR_PATH_NOT_FOUND) {
				printLastError(error, "clearing temp directory");
				return ExitCode.error;
			}
			return ExitCode.ok;
		} else {
			immutable ExitCode err = clearDirRecur(dirPath, fileHandle);
			immutable int closeOk = FindClose(fileHandle);
			verify(cast(immutable bool) closeOk);
			return err;
		}
	}

	@system immutable(ExitCode) clearDirRecur(ref TempStrForPath dirPath, HANDLE fileHandle) {
		WIN32_FIND_DATAA fileData;
		if (FindNextFileA(fileHandle, &fileData)) {
			immutable string name = strOfCStr(cast(immutable) fileData.cFileName.ptr);
			if (!strEq(name, "..")) {
				immutable size_t oldLength = length(dirPath);
				pushToTempStr(dirPath, '/');
				pushToTempStr(dirPath, name);

				if (fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
					immutable ExitCode clearErr = clearDir(dirPath);
					if (clearErr != ExitCode.ok)
						return clearErr;
					if (!RemoveDirectoryA(asTempSafeCStr(dirPath).ptr)) {
						fprintf(stderr, "Error deleting directory %s\n", asTempSafeCStr(dirPath).ptr);
						return ExitCode.error;
					}
				} else {
					if (!DeleteFileA(asTempSafeCStr(dirPath).ptr)) {
						fprintf(stderr, "Error deleting file %s\n", asTempSafeCStr(dirPath).ptr);
						return ExitCode.error;
					}
				}

				setLength(dirPath, oldLength);
			}
			return clearDirRecur(dirPath, fileHandle);
		} else {
			verify(GetLastError() == ERROR_NO_MORE_FILES);
			return ExitCode.ok;
		}
	}
} else {
	@system immutable(ExitCode) clearDirRecur(ref TempStrForPath dirPath, DIR* dir) {
		immutable dirent* entry = cast(immutable) readdir(dir);
		if (entry == null)
			return ExitCode.ok;
		immutable SafeCStr entryName = immutable SafeCStr(entry.d_name.ptr);
		if (!safeCStrEq(entryName, ".") && !safeCStrEq(entryName, "..")) {
			immutable size_t oldLength = length(dirPath);
			pushToTempStr(dirPath, '/');
			pushToTempStr(dirPath, entryName);
			stat_t s;
			stat(asTempSafeCStr(dirPath).ptr, &s);
			if ((s.st_mode & S_IFMT) == S_IFDIR) {
				DIR* innerDir = opendir(asTempSafeCStr(dirPath).ptr);
				if (innerDir == null) {
					fprintf(stderr, "error opening directory %s (to delete contents)\n", asTempSafeCStr(dirPath).ptr);
					return ExitCode.error;
				}
				immutable ExitCode err = clearDirRecur(dirPath, innerDir);
				if (err != ExitCode.ok)
					return err;
			} else {
				immutable int err = unlink(asTempSafeCStr(dirPath).ptr);
				if (err != 0) {
					fprintf(stderr, "error removing %s\n", asTempSafeCStr(dirPath).ptr);
					return ExitCode.error;
				}
			}
			setLength(dirPath, oldLength);
		}
		return clearDirRecur(dirPath, dir);
	}
}

@system immutable(ExitCode) mkdirRecur(ref const AllPaths allPaths, immutable Path dir) {
	version (Windows) {
		return todo!(immutable ExitCode)("!");
	} else {
		TempStrForPath path = pathToTempStr(allPaths, dir, safeCStr!"");
		immutable char* dirCStr = asTempSafeCStr(path).ptr;
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
		: immutable PathAndExtension(childPath(allPaths, tempDir, name), safeCStr!".c");
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

immutable(Path) getCrowDirectory(ref AllPaths allPaths, immutable Path pathToThisExecutable) {
	immutable Opt!Path bin = parent(allPaths, pathToThisExecutable);
	immutable Opt!Path res = parent(allPaths, forceOrTodo(bin));
	return forceOrTodo(res);
}

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
					cPath, force(exePath), result.allExternLibraryNames, cCompileOptions)
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
			safeCStr!"-pthread",
			safeCStr!"-lm",
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
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	immutable PathAndExtension cPath,
	immutable PathAndExtension exePath,
	immutable Sym[] allExternLibraryNames,
	ref immutable CCompileOptions options,
) {
	immutable SafeCStr[] args =
		cCompileArgs(alloc, allSymbols, allPaths, cPath, exePath, allExternLibraryNames, options);
	version (Windows) {
		TempStrForPath clPath = void;
		initializeTempStr(clPath);
		immutable ExitCode clErr = findPathToCl(clPath);
		if (clErr != ExitCode.ok)
			return clErr;
		scope immutable SafeCStr executable = asTempSafeCStr(clPath);
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
		int len = SearchPathA(null, "cl.exe", null, cast(uint) res.capacity, res.ptr, null);
		if (len == 0) {
			fprintf(stderr, "Could not find cl.exe on path. Be sure you are using a Native Tools Command Prompt.");
			return ExitCode.error;
		}
		return ExitCode.ok;
	}
}

immutable(SafeCStr[]) cCompileArgs(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	immutable PathAndExtension cPath,
	immutable PathAndExtension exePath,
	immutable Sym[] allExternLibraryNames,
	ref immutable CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, pathToSafeCStr(alloc, allPaths, cPath));
	version (Windows) {
		add(alloc, args, safeCStr!"/link");
	}
	foreach (immutable Sym it; allExternLibraryNames) {
		version (Windows) {
			//TODO
		} else {
			Writer writer = Writer(ptrTrustMe_mut(alloc));
			writeStatic(writer, "-l");
			writeSym(writer, allSymbols, it);
			add(alloc, args, finishWriterToSafeCStr(writer));
		}
	}
	version (Windows) {
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

@trusted immutable(ExitCode) print(immutable SafeCStr a) {
	printf("%s", a.ptr);
	return ExitCode.ok;
}

@trusted immutable(ExitCode) println(immutable SafeCStr a) {
	printf("%s\n", a.ptr);
	return ExitCode.ok;
}

@trusted immutable(ExitCode) printErr(immutable SafeCStr a) {
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
			immutable SafeCStr extension,
			void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
		) =>
			tryReadFile(allPaths, path, extension, cb));
	return cb(storage);
}

immutable(ExitCode) withRealExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	version (Windows) {
		//TODO: verify that paths exist... dlLoadLibrary doesn't do that for us
		DLLib*[3] libraries = [
			dlLoadLibrary("C:\\Windows\\System32\\kernel32.dll"),
			dlLoadLibrary("C:\\Windows\\System32\\ucrtbase.dll"),
			dlLoadLibrary("C:\\Windows\\System32\\ws2_32.dll"),
		];
	} else {
		// TODO: better way to find where it is (may depend on system)
		DLLib*[5] libraries = [
			dlLoadLibrary("/usr/lib64/libSDL2-2.0.so.0"),
			dlLoadLibrary("/usr/lib64/libGL.so"),
			dlLoadLibrary("/usr/lib64/libwebp.so"),
			dlLoadLibrary("/usr/lib64/libsodium.so"),
			dlLoadLibrary("/usr/lib64/liblmdb.so"),
		];
	}

	DCCallVM* dcVm = dcNewCallVM(0x1000);
	verify(dcVm != null);
	dcMode(dcVm, DC_CALL_C_DEFAULT);
	scope Extern extern_ = Extern(
		(ubyte* ptr) {
			pureFree(ptr);
		},
		(immutable size_t size) =>
			cast(ubyte*) pureMalloc(size),
		(immutable int fd, immutable char* buf, immutable size_t nBytes) {
			version (Windows) {
				// writeDiagsToExtern uses this
				verify(fd == 2);
				return fprintf(stderr, "%.*s", cast(int) nBytes, buf);
			} else {
				return posixWrite(fd, buf, nBytes);
			}
		},
		(
			immutable Sym name,
			immutable DynCallType returnType,
			scope immutable ulong[] parameters,
			scope immutable DynCallType[] parameterTypes,
		) => doDynCall(allSymbols, name, returnType, parameters, parameterTypes, dcVm, libraries));
	immutable ExitCode res = cb(extern_);

	foreach (DLLib* library; libraries)
		dlFreeLibrary(library);

	dcFree(dcVm);
	return res;
}

@trusted immutable(ulong) doDynCall(
	ref const AllSymbols allSymbols,
	immutable Sym name,
	immutable DynCallType returnType,
	scope immutable ulong[] parameters,
	scope immutable DynCallType[] parameterTypes,
	DCCallVM* dcVm,
	const DLLib*[] libraries,
) {
	immutable char[256] nameBuffer = symAsTempBuffer!256(allSymbols, name);
	immutable CStr nameCStr = nameBuffer.ptr;

	//printf("Gonna call %s\n", nameCStr);
	version (Windows) {
		immutable int prevErr = GetLastError();
	}
	DCpointer ptr = null;
	foreach (const DLLib* library; libraries) {
		if (ptr == null) {
			ptr = dlFindSymbol(library, nameCStr);
			debug if (false) {
				char[256] libName;
				int len = dlGetLibraryPath(library, libName.ptr, libName.length);
				verify(len > 0 && len < libName.length);
				libName[len] = '\0';
				printf("Is it in %s? %d\n", libName.ptr, ptr != null);
			}
		}
	}
	if (ptr == null) {
		printf("Could not find extern function %s\n", nameCStr);
	}
	verify(ptr != null);
	version (Windows) {
		SetLastError(prevErr);
	}

	dcReset(dcVm);
	zipImpureSystem!(ulong, DynCallType)(
		parameters,
		parameterTypes,
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
		final switch (returnType) {
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
	DLLib *dlLoadLibrary(const char* libpath);
	void dlFreeLibrary(DLLib* pLib);
	void* dlFindSymbol(const DLLib* pLib, const char* pSymbolName);
	int dlGetLibraryPath(const DLLib* pLib, char* sOut, int bufSize);
}

void tryReadFile(
	scope ref const AllPaths allPaths,
	immutable Path path,
	immutable SafeCStr extension,
	scope void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
) {
	TempStrForPath pathTempStr = pathToTempStr(allPaths, path, extension);
	return tryReadFileInner(asTempSafeCStr(pathTempStr), cb);
}

@trusted void tryReadFileInner(
	immutable SafeCStr path,
	scope void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
) {
	TempStr!0x100000 content = void;
	initializeTempStr(content);
	immutable CStr pathTempCStr = path.ptr;
	FILE* fd = fopen(pathTempCStr, "rb");
	if (fd == null) {
		if (errno == ENOENT) {
			return cb(none!SafeCStr);
		} else {
			fprintf(stderr, "Failed to open file %s\n", pathTempCStr);
			todo!void("fail");
		}
	}
	scope(exit) fclose(fd);

	immutable int err = fseek(fd, 0, SEEK_END);
	if (err) todo!void("!");

	immutable long ftellResult = ftell(fd);
	if (ftellResult < 0)
		todo!void("ftell failed");
	if (ftellResult > 99_999)
		todo!void("size suspiciously large");

	immutable size_t fileSize = cast(size_t) ftellResult;

	if (fileSize == 0)
		return cb(some(safeCStr!""));

	// Go back to the beginning so we can read
	immutable int err2 = fseek(fd, 0, SEEK_SET);
	verify(err2 == 0);

	verify(fileSize < content.capacity);
	immutable size_t nBytesRead = fread(content.ptr, char.sizeof, fileSize, fd);
	verify(nBytesRead == fileSize);
	if (ferror(fd))
		todo!void("error reading file");

	setLength(content, fileSize);
	return cb(some(asTempSafeCStr(content)));
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
		if (wroteBytes != size)
			if (wroteBytes == -1)
				todo!void("writeFile failed");
			else
				todo!void("writeFile -- didn't write all the bytes?");
		return ExitCode.ok;
	}
}

@system FILE* tryOpenFileForWrite(ref const AllPaths allPaths, immutable PathAndExtension path) {
	TempStrForPath temp = pathToTempStr(allPaths, path);
	FILE* fd = fopen(asTempSafeCStr(temp).ptr, "w");
	if (fd == null) {
		if (errno == ENOENT) {
			immutable Opt!Path par = parent(allPaths, path.path);
			if (has(par)) {
				immutable ExitCode res = mkdirRecur(allPaths, force(par));
				if (res == ExitCode.ok)
					return fopen(asTempSafeCStr(temp).ptr, "w");
			}
		} else {
			fprintf(stderr, "Failed to write file %s: %s\n", asTempSafeCStr(temp).ptr, strerror(errno));
		}
	}
	return fd;
}

struct CommandLineArgs {
	immutable Path pathToThisExecutable;
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
	initializeTempStr(res);
	version (Windows) {
		char* b = _getcwd(res.ptr, res.capacity);
		if (b != null)
			replaceBackslashWithSlash(b);
	} else {
		const char* b = getcwd(res.ptr, res.capacity);
	}
	if (b == null)
		return todo!(immutable Path)("getcwd failed");
	else {
		verify(b == res.ptr);
		return parsePath(allPaths, immutable SafeCStr(cast(immutable) res.ptr));
	}
}

@system void replaceBackslashWithSlash(char* a) {
	if (*a != '\0') {
		if (*a == '\\')
			*a = '/';
		replaceBackslashWithSlash(a + 1);
	}
}

@trusted immutable(Path) getPathToThisExecutable(ref AllPaths allPaths) {
	TempStrForPath res = void;
	initializeTempStr(res);
	version(Windows) {
		HMODULE mod = GetModuleHandle(null);
		verify(mod != null);
		immutable DWORD size = GetModuleFileNameA(mod, res.ptr, res.capacity);
		replaceBackslashWithSlash(buff.ptr);
	} else {
		immutable long size = readlink("/proc/self/exe", res.ptr, res.capacity);
	}
	verify(size > 0 && size < res.capacity);
	return parsePath(allPaths, immutable SafeCStr(cast(immutable) res.ptr));
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
		TempStr!0x1000 argsStr = void;
		initializeTempStr(argsStr);
		pushToTempStr(argsStr, '"');
		pushToTempStr(argsStr, executablePath);
		pushToTempStr(argsStr, '"');
		foreach (immutable SafeCStr arg; args) {
			pushToTempStr(argsStr, ' ');
			pushToTempStr(argsStr, arg);
		}

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
			cast(char*) asTempSafeCStr(argsStr).ptr,
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

		TempStr!0x10000 stdoutBuf = void;
		initializeTempStr(stdoutBuf);
		TempStr!0x10000 stderrBuf = void;
		initializeTempStr(stderrBuf);
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
			fprintf(stderr, "Error invoking C compiler: %s\n", asTempSafeCStr(argsStr).ptr);
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

void verifyOk(int ok) {
	verify(ok == 1);
}

version (Windows) {
	@system void readFromPipe(ref TempStr!0x10000 out_, HANDLE pipe) {
		readFromPipeRecur(out_.ptr, out_.ptr + out_.capacity, pipe);
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
