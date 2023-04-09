module app.main;

@safe @nogc nothrow: // not pure

import app.dyncall : withRealExtern;
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
		GetTickCount,
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
import frontend.lang : cExtension, JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.extern_ : Extern;
import lib.cliParser : BuildOptions, CCompileOptions, Command, defaultExeExtension, hasAnyOut, parseCommand, RunOptions;
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
import model.lowModel : ExternLibrary;
version(Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : prepend;
import util.col.str : CStr, SafeCStr, safeCStr, safeCStrIsEmpty, safeCStrSize, strEq, strOfCStr;
import util.memory : memset;
import util.opt : force, has, none, Opt, some;
import util.path :
	AllPaths,
	alterExtension,
	baseName,
	childPath,
	Path,
	parent,
	parentOrEmpty,
	parsePath,
	PathsInfo,
	pathToSafeCStr,
	pathToTempStr,
	TempStrForPath,
	writePathPlain;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : ptrTrustMe;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage;
import util.sym : alterExtension, AllSymbols, concatSyms, safeCStrOfSym, Sym, sym, symOfStr, writeSym;
import util.util : todo, verify;
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
	Path tempDir = childPath(allPaths, crowDir, sym!"temp");
	ExitCode setupTempExitCode = setupTempDir(allSymbols, allPaths, tempDir);
	if (setupTempExitCode != ExitCode.ok)
		return printErr(safeCStr!"Failed to set up temporary directory\n");

	Path cwd = getCwd(allPaths);
	PathsInfo pathsInfo = PathsInfo(some(cwd));
	Command command = parseCommand(alloc, allSymbols, allPaths, cwd, args);
	ShowDiagOptions showDiagOptions = ShowDiagOptions(true);

	return command.matchImpure!ExitCode(
		(in Command.Build it) =>
			runBuild(alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, tempDir, it.mainPath, it.options),
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

SafeCStr[] getAllArgs(
	ref Alloc alloc,
	in AllPaths allPaths,
	in ReadOnlyStorage storage,
	Path main,
	in SafeCStr[] programArgs,
) =>
	prepend(alloc, pathToSafeCStr(alloc, allPaths, main), programArgs);

@trusted ExitCode setupTempDir(ref AllSymbols allSymbols, ref AllPaths allPaths, Path tempDir) {
	TempStrForPath dirPathBuf = void;
	CStr dirPath = pathToTempStr(dirPathBuf, allPaths, tempDir).ptr;
	version (Windows) {
		if (GetFileAttributesA(dirPath) == INVALID_FILE_ATTRIBUTES) {
			int ok = CreateDirectoryA(dirPath, null);
			if (!ok) {
				fprintf(stderr, "error creating directory %s\n", dirPath);
				return ExitCode.error;
			}
		} else {
			ExitCode err = clearDir(allSymbols, allPaths, tempDir);
			if (err != ExitCode.ok)
				return err;
		}
	} else {
		DIR* dir = opendir(dirPath);
		if (dir == null) {
			if (errno == ENOENT) {
				int err = mkdir(dirPath, S_IRWXU);
				if (err != 0) {
					fprintf(stderr, "error creating directory %s\n", dirPath);
					return ExitCode.error;
				}
			} else {
				fprintf(stderr, "error opening directory %s: error code %d\n", dirPath, errno);
				return ExitCode.error;
			}
		} else {
			ExitCode err = clearDirRecur(allSymbols, allPaths, tempDir, dir);
			if (err != ExitCode.ok)
				return err;
		}
	}
	return ExitCode.ok;
}

version (Windows) {
	@system ExitCode clearDir(ref AllSymbols allSymbols, ref AllPaths allPaths, Path dirPath) {
		TempStrForPath searchPathBuf = void;
		CStr searchPath = pathToTempStr(searchPathBuf, allPaths, childPath(allPaths, dirPath, sym!"*")).ptr;
		WIN32_FIND_DATAA fileData;
		HANDLE fileHandle = FindFirstFileA(searchPath, &fileData);
		if (fileHandle == INVALID_HANDLE_VALUE) {
			DWORD error = GetLastError();
			if (error != ERROR_PATH_NOT_FOUND) {
				printLastError(error, "clearing temp directory");
				return ExitCode.error;
			}
			return ExitCode.ok;
		} else {
			ExitCode err = clearDirRecur(allSymbols, allPaths, dirPath, fileHandle);
			int closeOk = FindClose(fileHandle);
			verify(cast(bool) closeOk);
			return err;
		}
	}

	@system ExitCode clearDirRecur(ref AllSymbols allSymbols, ref AllPaths allPaths, Path dirPath, HANDLE fileHandle) {
		WIN32_FIND_DATAA fileData;
		if (FindNextFileA(fileHandle, &fileData)) {
			string name = strOfCStr(cast(immutable) fileData.cFileName.ptr);
			if (!strEq(name, "..")) {
				Path child = childPath(allPaths, dirPath, symOfStr(allSymbols, name));
				TempStrForPath childBuf = void;
				CStr childCStr = pathToTempStr(childBuf, allPaths, child).ptr;
				if (fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
					ExitCode clearErr = clearDir(allSymbols, allPaths, child);
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
	@system ExitCode clearDirRecur(ref AllSymbols allSymbols, ref AllPaths allPaths, Path dirPath, DIR* dir) {
		immutable dirent* entry = cast(immutable) readdir(dir);
		if (entry == null)
			return ExitCode.ok;
		string entryName = strOfCStr(entry.d_name.ptr);
		if (!strEq(entryName, ".") && !strEq(entryName, "..")) {
			Path child = childPath(allPaths, dirPath, symOfStr(allSymbols, entryName));
			stat_t s;
			TempStrForPath buf = void;
			CStr childCStr = pathToTempStr(buf, allPaths, child).ptr;
			stat(childCStr, &s);
			if ((s.st_mode & S_IFMT) == S_IFDIR) {
				DIR* innerDir = opendir(childCStr);
				if (innerDir == null) {
					fprintf(stderr, "error opening directory %s (to delete contents)\n", childCStr);
					return ExitCode.error;
				}
				ExitCode err = clearDirRecur(allSymbols, allPaths, child, innerDir);
				if (err != ExitCode.ok)
					return err;
			} else {
				int err = unlink(childCStr);
				if (err != 0) {
					fprintf(stderr, "error removing %s\n", childCStr);
					return ExitCode.error;
				}
			}
		}
		return clearDirRecur(allSymbols, allPaths, dirPath, dir);
	}
}

@system ExitCode mkdirRecur(in AllPaths allPaths, Path dir) {
	version (Windows) {
		return todo!ExitCode("!");
	} else {
		TempStrForPath buf = void;
		CStr dirCStr = pathToTempStr(buf, allPaths, dir).ptr;
		int err = mkdir(dirCStr, S_IRWXU);
		if (err == ENOENT) {
			Opt!Path par = parent(allPaths, dir);
			if (has(par)) {
				ExitCode res = mkdirRecur(allPaths, force(par));
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
	@system ExitCode handleMkdirErr(int err, CStr dir) {
		if (err != 0)
			fprintf(stderr, "Error making directory %s: %s\n", dir, strerror(errno));
		return ExitCode(err);
	}
}

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

immutable struct RunBuildResult {
	ExitCode err;
	Opt!Path exePath;
}

ExitCode runBuild(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	Path includeDir,
	Path tempDir,
	Path mainPath,
	in BuildOptions options,
) =>
	hasAnyOut(options.out_)
		? runBuildInner(
			alloc, perf, allSymbols, allPaths, pathsInfo, includeDir, tempDir,
			mainPath, options, ExeKind.allowNoExe).err
		: withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
			Opt!SafeCStr error = justTypeCheck(
				alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, mainPath);
			return has(error) ? printErr(force(error)) : println(safeCStr!"OK");
		});

enum ExeKind { ensureExe, allowNoExe }
RunBuildResult runBuildInner(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in PathsInfo pathsInfo,
	Path includeDir,
	Path tempDir,
	Path mainPath,
	in BuildOptions options,
	ExeKind exeKind,
) {
	Sym name = baseName(allPaths, mainPath);
	Path cPath = has(options.out_.outC)
		? force(options.out_.outC)
		: childPath(allPaths, tempDir, alterExtension!cExtension(allSymbols, name));
	Opt!Path exePath = has(options.out_.outExecutable)
		? options.out_.outExecutable
		: exeKind == ExeKind.ensureExe
		? some(childPath(allPaths, tempDir, alterExtension!defaultExeExtension(allSymbols, name)))
		: none!Path;
	ExitCode err = buildToCAndCompile(
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
	return RunBuildResult(err, exePath);
}

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
	Path cPath,
	in Opt!Path exePath,
	in CCompileOptions cCompileOptions,
) =>
	withReadOnlyStorage!ExitCode(allPaths, includeDir, (in ReadOnlyStorage storage) {
		BuildToCResult result =
			buildToC(alloc, perf, allSymbols, allPaths, pathsInfo, storage, showDiagOptions, mainPath);
		if (safeCStrIsEmpty(result.diagnostics)) {
			ExitCode res = writeFile(allPaths, cPath, result.cSource);
			return res == ExitCode.ok && has(exePath)
				? compileC(
					alloc, perf, allSymbols, allPaths,
					cPath, force(exePath), result.externLibraries, cCompileOptions)
				: res;
		} else
			return printErr(result.diagnostics);
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
	return hasDiags(programs.program)
		? printErr(strOfDiagnostics(
			alloc,
			allSymbols,
			allPaths,
			pathsInfo,
			showDiagOptions,
			programs.program))
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

version (Windows) {
	@system ExitCode findPathToCl(ref TempStrForPath res) {
		int len = SearchPathA(null, "cl.exe", null, cast(uint) res.length, res.ptr, null);
		if (len == 0) {
			fprintf(stderr, "Could not find cl.exe on path. Be sure you are using a Native Tools Command Prompt.");
			return ExitCode.error;
		}
		return ExitCode.ok;
	}
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

T withReadOnlyStorage(T)(
	in AllPaths allPaths,
	Path includeDir,
	T delegate(in ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope ReadOnlyStorage storage = ReadOnlyStorage(
		includeDir,
		(
			Path path,
			in void delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
		) =>
			tryReadFile(allPaths, path, NulTerminate.no, cb),
		(
			Path path,
			in void delegate(in ReadFileResult!SafeCStr) @safe @nogc pure nothrow cb,
		) =>
			tryReadFile(allPaths, path, NulTerminate.yes, (in ReadFileResult!(ubyte[]) x) =>
				x.matchIn!void(
					(in immutable ubyte[] bytes) @trusted =>
						cb(ReadFileResult!SafeCStr(SafeCStr(cast(immutable char*) bytes.ptr))),
					(in ReadFileResult!(ubyte[]).NotFound) =>
						cb(ReadFileResult!SafeCStr(ReadFileResult!SafeCStr.NotFound())),
					(in ReadFileResult!(ubyte[]).Error) =>
						cb(ReadFileResult!SafeCStr(ReadFileResult!SafeCStr.Error())))));
	return cb(storage);
}

enum NulTerminate { no, yes }

@system Out withBuffer(Out, T)(size_t size, in Out delegate(scope T[]) @nogc nothrow cb) {
	static immutable size_t maxSizeOnStack = 0x100000 / T.sizeof;
	if (size <= maxSizeOnStack) {
		T[maxSizeOnStack] buf = void;
		return cb(buf[0 .. size]);
	} else {
		T* buf = cast(T*) pureMalloc(size * T.sizeof);
		verify(buf != null);
		scope(exit) pureFree(buf);
		return cb(buf[0 .. size]);
	}
}

@trusted void tryReadFile(
	in AllPaths allPaths,
	Path path,
	NulTerminate nulTerminate,
	in void delegate(in ReadFileResult!(ubyte[])) @safe @nogc pure nothrow cb,
) {
	TempStrForPath pathBuf = void;
	CStr pathCStr = pathToTempStr(pathBuf, allPaths, path).ptr;

	FILE* fd = fopen(pathCStr, "rb");
	if (fd == null)
		return cb(errno == ENOENT
			? ReadFileResult!(ubyte[])(ReadFileResult!(ubyte[]).NotFound())
			: ReadFileResult!(ubyte[])(ReadFileResult!(ubyte[]).Error()));
	scope(exit) fclose(fd);

	int err = fseek(fd, 0, SEEK_END);
	if (err) todo!void("!");

	long ftellResult = ftell(fd);
	if (ftellResult < 0)
		todo!void("ftell failed");
	size_t fileSize = cast(size_t) ftellResult;
	if (fileSize == 0) {
		if (nulTerminate) {
			static immutable ubyte[] bytes = [0];
			cb(ReadFileResult!(ubyte[])(bytes));
		} else
			cb(ReadFileResult!(ubyte[])([]));
	} else {
		withBuffer!(void, ubyte)(fileSize + (nulTerminate ? 1 : 0), (scope ubyte[] contentBuf) {
			// Go back to the beginning so we can read
			int err2 = fseek(fd, 0, SEEK_SET);
			verify(err2 == 0);

			size_t nBytesRead = fread(contentBuf.ptr, ubyte.sizeof, fileSize, fd);
			verify(nBytesRead == fileSize);
			if (ferror(fd))
				todo!void("error reading file");
			if (nulTerminate) contentBuf[nBytesRead] = '\0';

			cb(ReadFileResult!(ubyte[])(cast(immutable) contentBuf[0 .. nBytesRead + (nulTerminate ? 1 : 0)]));
		});
	}
}

@trusted ExitCode writeFile(in AllPaths allPaths, in Path path, in SafeCStr content) {
	FILE* fd = tryOpenFileForWrite(allPaths, path);
	if (fd == null)
		return ExitCode.error;
	else {
		scope(exit) fclose(fd);

		size_t size = safeCStrSize(content);
		long wroteBytes = fwrite(content.ptr, char.sizeof, size, fd);
		if (wroteBytes != size) {
			if (wroteBytes == -1)
				todo!void("writeFile failed");
			else
				todo!void("writeFile -- didn't write all the bytes?");
		}
		return ExitCode.ok;
	}
}

@system FILE* tryOpenFileForWrite(in AllPaths allPaths, in Path path) {
	TempStrForPath buf = void;
	CStr pathCStr = pathToTempStr(buf, allPaths, path).ptr;
	FILE* fd = fopen(pathCStr, "w");
	if (fd == null) {
		if (errno == ENOENT) {
			Opt!Path par = parent(allPaths, path);
			if (has(par)) {
				ExitCode res = mkdirRecur(allPaths, force(par));
				if (res == ExitCode.ok)
					return fopen(pathCStr, "w");
			}
		} else {
			fprintf(stderr, "Failed to write file %s: %s\n", pathCStr, strerror(errno));
		}
	}
	return fd;
}

version (Windows) {
	extern(C) char* _getcwd(char* buffer, int maxlen);
	extern(C) int _mkdir(scope const char*, immutable uint);

	alias getcwd = _getcwd;
	alias mkdir = _mkdir;
}

@trusted Path getCwd(ref AllPaths allPaths) {
	TempStrForPath res = void;
	const char* cwd = getcwd(res.ptr, res.length);
	return cwd == null
		? todo!Path("getcwd failed")
		: parsePath(allPaths, SafeCStr(cast(immutable) cwd));
}

Path getCrowDir(ref AllPaths allPaths) =>
	parentOrEmpty(allPaths, parentOrEmpty(allPaths, getPathToThisExecutable(allPaths)));

@trusted Path getPathToThisExecutable(ref AllPaths allPaths) {
	TempStrForPath res = void;
	version(Windows) {
		HMODULE mod = GetModuleHandle(null);
		verify(mod != null);
		DWORD size = GetModuleFileNameA(mod, res.ptr, res.length);
	} else {
		long size = readlink("/proc/self/exe", res.ptr, res.length);
	}
	verify(size > 0 && size < res.length);
	res[size] = '\0';
	return parsePath(allPaths, SafeCStr(cast(immutable) res.ptr));
}

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted ExitCode spawnAndWait(
	ref TempAlloc tempAlloc,
	in AllPaths allPaths,
	in SafeCStr executablePath,
	in SafeCStr[] args,
) {
	version (Windows) {
		CStr argsCStr = windowsArgsCStr(tempAlloc, executablePath, args);

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

		return ExitCode(exitCode);
	} else {
		pid_t pid;
		int spawnStatus = posix_spawn(
			&pid,
			executablePath.ptr,
			null,
			null,
			// https://stackoverflow.com/questions/50596439/can-string-literals-be-passed-in-posix-spawns-argv
			cast(char**) convertArgs(tempAlloc, executablePath, args),
			cast(char**) environ);
		if (spawnStatus == 0) {
			int waitStatus;
			int resPid = waitpid(pid, &waitStatus, 0);
			verify(resPid == pid);
			if (WIFEXITED(waitStatus))
				return ExitCode(WEXITSTATUS(waitStatus)); // only valid if WIFEXITED
			else {
				if (WIFSIGNALED(waitStatus))
					return todo!ExitCode("process exited with signal");
				else
					return todo!ExitCode("process exited non-normally");
			}
		} else
			return todo!ExitCode("posix_spawn failed");
	}
}

version (Windows) {
	CStr windowsArgsCStr(
		ref TempAlloc tempAlloc,
		in SafeCStr executablePath,
		in SafeCStr[] args,
	) {
		Writer writer = Writer(ptrTrustMe(tempAlloc));
		writer ~= '"';
		writer ~= executablePath;
		writer ~= '"';
		foreach (SafeCStr arg; args) {
			writer ~= ' ';
			writer ~= arg;
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

@system CStr* convertArgs(ref Alloc alloc, in SafeCStr executable, in SafeCStr[] args) {
	ArrBuilder!CStr cArgs;
	add(alloc, cArgs, executable.ptr);
	foreach (SafeCStr arg; args)
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
	@system void printLastError(int error, CStr description) {
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
