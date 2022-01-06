@safe @nogc nothrow: // not pure

import core.memory : pureFree, pureMalloc;
import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fprintf, printf, SEEK_END, SEEK_SET, stderr;
import core.stdc.string : strerror;
import core.sys.posix.fcntl : open, O_CREAT, O_RDONLY, O_TRUNC, O_WRONLY, pid_t;
import core.sys.posix.spawn : posix_spawn;
import core.sys.posix.sys.wait : waitpid;
import core.sys.posix.dirent : DIR, dirent, opendir, readdir;
import core.sys.posix.sys.stat : mkdir, S_IFDIR, S_IFMT, S_IRWXU, stat, stat_t;
import core.sys.posix.sys.types : off_t;
import core.sys.posix.time : clock_gettime, CLOCK_MONOTONIC, timespec;
import core.sys.posix.unistd : close, getcwd, lseek, read, readlink, unlink, posixWrite = write;

import backend.jit : jitAndRun;
import frontend.lang : crowExtension, JitOptions, OptimizationLevel;
import frontend.showDiag : ShowDiagOptions, strOfDiagnostics;
import interpret.applyFn : u64OfI32, u64OfI64;
import interpret.extern_ : DynCallType, Extern, TimeSpec;
import lib.cliParser :
	hasAnyOut,
	BuildOptions,
	CCompileOptions,
	Command,
	matchCommand,
	parseCommand,
	ProgramDirAndMain,
	ProgramDirAndRootPaths,
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
import model.model : AbsolutePathsGetter, getAbsolutePath, hasDiags;
version(Test) {
	import test.test : test;
}
import util.alloc.alloc : Alloc, TempAlloc;
import util.alloc.rangeAlloc : RangeAlloc;
import util.col.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.col.arrUtil : mapImpure, prepend, zipImpureSystem;
import util.col.str :
	catToSafeCStr,
	copyToSafeCStr,
	CStr,
	SafeCStr,
	safeCStr,
	safeCStrEq,
	safeCStrEqCat,
	safeCStrIsEmpty,
	safeCStrSize,
	strOfCStr,
	strOfSafeCStr;
import util.col.tempStr : asTempSafeCStr, copyTempStrToSafeCStr, length, pushToTempStr, setLength, TempStr;
import util.conv : bitsOfFloat64, float32OfBits, float64OfBits;
import util.opt : force, forceOrTodo, has, none, Opt, some;
import util.path :
	AbsolutePath,
	AllPaths,
	baseName,
	Path,
	PathAndStorageKind,
	pathParent,
	pathToSafeCStr,
	pathToTempStr,
	removeFirstPathComponentIf,
	rootPath,
	StorageKind,
	TempStrForPath;
import util.perf : eachMeasure, Perf, perfEnabled, PerfMeasure, PerfMeasureResult, withMeasure;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.readOnlyStorage : ReadOnlyStorage;
import util.sym : AllSymbols, shortSym, Sym, symAsTempBuffer, writeSym;
import util.util : castImmutableRef, todo, unreachable, verify;
import util.writer : finishWriterToSafeCStr, Writer, writeStatic;

@system extern(C) immutable(int) main(immutable size_t argc, immutable CStr* argv) {
	immutable size_t memorySizeBytes = 1536 * 1024 * 1024; // 1.5 GB
	ubyte* mem = cast(ubyte*) pureMalloc(memorySizeBytes);
	scope(exit) pureFree(mem);
	verify(mem != null);
	RangeAlloc alloc = RangeAlloc(mem, memorySizeBytes);
	immutable CommandLineArgs args = parseCommandLineArgs(alloc, argc, argv);
	immutable immutable(ulong) function() @safe @nogc pure nothrow getTimeNanosPure =
		cast(immutable(ulong) function() @safe @nogc pure nothrow) &getTimeNanos;
	scope Perf perf = Perf(() => getTimeNanosPure());
	immutable int res = go(alloc, perf, args).value;
	if (perfEnabled)
		logPerf(perf);
	return res;
}

private:

void logPerf(scope ref Perf perf) {
	eachMeasure(perf, (immutable SafeCStr name, immutable PerfMeasureResult m) @trusted {
		printf(
			"%s * %d took %llums and %lluMB\n",
			name.ptr,
			m.count,
			divRound(m.nanoseconds, 1_000_000),
			divRound(m.bytesAllocated, 1024 * 1024));
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
	timespec time;
	clock_gettime(CLOCK_MONOTONIC, &time);
	return time.tv_sec * 1_000_000_000 + time.tv_nsec;
}

immutable(ExitCode) go(ref Alloc alloc, ref Perf perf, ref immutable CommandLineArgs args) {
	AllSymbols allSymbols = AllSymbols(ptrTrustMe_mut(alloc));
	AllPaths allPaths = AllPaths(ptrTrustMe_mut(alloc), ptrTrustMe_mut(allSymbols));
	immutable SafeCStr crowDir = getCrowDirectory(alloc, args.pathToThisExecutable);
	immutable SafeCStr includeDir = getIncludeDirectory(alloc, crowDir);
	immutable Opt!SafeCStr optTempDir = setupTempDir(alloc, allPaths, crowDir);
	if (!has(optTempDir))
		return ExitCode.error;
	immutable SafeCStr tempDir = force(optTempDir);

	immutable SafeCStr cwd = getCwd(alloc);
	immutable Command command = parseCommand(alloc, allPaths, cwd, args.args);
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(true);

	return matchCommand!(immutable ExitCode)(
		command,
		(ref immutable Command.Build it) =>
			runBuild(alloc, perf, allSymbols, allPaths, cwd, includeDir, tempDir, it.programDirAndMain, it.options),
		(ref immutable Command.Document it) =>
			runDocument(alloc, perf, allSymbols, allPaths, cwd, includeDir, it.programDirAndRootPaths),
		(ref immutable Command.Help it) =>
			help(it),
		(ref immutable Command.Print it) =>
			withReadOnlyStorage!(immutable ExitCode)(
				allPaths,
				cwd,
				includeDir,
				it.programDirAndMain.programDir,
				(scope ref immutable ReadOnlyStorage storage) {
					immutable DiagsAndResultStrs printed = print(
						alloc,
						perf,
						allSymbols,
						allPaths,
						storage,
						showDiagOptions,
						it.kind,
						it.format,
						getRootPath(allPaths, includeDir, it.programDirAndMain));
					if (!safeCStrIsEmpty(printed.diagnostics)) printErr(printed.diagnostics);
					if (!safeCStrIsEmpty(printed.result)) print(printed.result);
					return safeCStrIsEmpty(printed.diagnostics) ? ExitCode.ok : ExitCode.error;
			}),
		(ref immutable Command.Run run) =>
			withReadOnlyStorage(
				allPaths,
				cwd,
				includeDir,
				run.programDirAndMain.programDir,
				(scope ref immutable ReadOnlyStorage storage) =>
					matchRunOptions!(immutable ExitCode)(
						run.options,
						(ref immutable RunOptions.Interpret) {
							immutable PathAndStorageKind main =
								getRootPath(allPaths, includeDir, run.programDirAndMain);
							return withRealExtern(alloc, allSymbols, (scope ref Extern extern_) => buildAndInterpret(
								alloc,
								perf,
								allSymbols,
								allPaths,
								storage,
								extern_,
								showDiagOptions,
								main,
								getAllArgs(alloc, allPaths, storage, main, run.programArgs)));
						},
						(ref immutable RunOptions.Jit it) {
							immutable PathAndStorageKind main =
								getRootPath(allPaths, includeDir, run.programDirAndMain);
							return buildAndJit(
								alloc,
								perf,
								allSymbols,
								allPaths,
								it.options,
								showDiagOptions,
								storage,
								main,
								getAllArgs(alloc, allPaths, storage, main, run.programArgs));
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
	ref AllPaths allPaths,
	scope ref immutable ReadOnlyStorage storage,
	immutable PathAndStorageKind main,
	immutable SafeCStr[] programArgs,
) {
	scope immutable AbsolutePath mainAbsolutePath = getAbsolutePath(storage.absolutePathsGetter, main, crowExtension);
	return prepend(alloc, pathToSafeCStr(alloc, allPaths, mainAbsolutePath), programArgs);
}

@trusted immutable(Opt!SafeCStr) setupTempDir(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable SafeCStr crowDir,
) {
	TempStr!0x1000 dirPath;
	pushToTempStr(dirPath, crowDir);
	pushToTempStr(dirPath, "/temp");
	DIR* dir = opendir(asTempSafeCStr(dirPath).ptr);
	if (dir == null) {
		if (errno == ENOENT) {
			immutable int err = mkdir(asTempSafeCStr(dirPath).ptr, S_IRWXU);
			if (err != 0) {
				fprintf(stderr, "error creating directory %s\n", asTempSafeCStr(dirPath).ptr);
				return none!SafeCStr;
			}
		} else {
			fprintf(stderr, "error opening directory %s: error code %d\n", asTempSafeCStr(dirPath).ptr, errno);
			return none!SafeCStr;
		}
	} else {
		immutable bool success = rmdirRecur(dirPath, dir);
		if (!success) return none!SafeCStr;
	}
	return some(copyTempStrToSafeCStr(alloc, dirPath));
}

@system immutable(bool) rmdirRecur(ref TempStr!0x1000 dirPath, DIR* dir) {
	immutable dirent* entry = cast(immutable) readdir(dir);
	if (entry == null)
		return true;
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
				return false;
			}
			immutable bool success = rmdirRecur(dirPath, innerDir);
			if (!success) return false;
		} else {
			immutable int err = unlink(asTempSafeCStr(dirPath).ptr);
			if (err != 0) {
				fprintf(stderr, "error removing %s\n", asTempSafeCStr(dirPath).ptr);
				return false;
			}
		}
		setLength(dirPath, oldLength);
	}
	return rmdirRecur(dirPath, dir);
}

@system immutable(ExitCode) mkdirRecur(immutable string dir) {
	TempStrForPath path;
	pushToTempStr(path, dir);
	immutable char* dirCStr = asTempSafeCStr(path).ptr;
	immutable int err = mkdir(dirCStr, S_IRWXU);
	if (err == ENOENT) {
		immutable Opt!string par = pathParent(dir);
		if (has(par)) {
			immutable ExitCode res = mkdirRecur(force(par));
			return res == ExitCode.ok
				? handleMkdirErr(mkdir(dirCStr, S_IRWXU), dirCStr)
				: res;
		}
	}
	return handleMkdirErr(err, dirCStr);
}

@system immutable(ExitCode) handleMkdirErr(immutable int err, immutable char* dir) {
	if (err != 0)
		fprintf(stderr, "Error making directory %s: %s\n", dir, strerror(errno));
	return immutable ExitCode(err);
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
	immutable SafeCStr cwd,
	immutable SafeCStr includeDir,
	ref immutable ProgramDirAndRootPaths programDirAndRootPaths,
) {
	return withReadOnlyStorage!(immutable ExitCode)(
		allPaths,
		cwd,
		includeDir,
		programDirAndRootPaths.programDir,
		(scope ref immutable ReadOnlyStorage storage) {
			immutable DocumentResult result = compileAndDocument(
				alloc, perf, allSymbols, allPaths, storage, showDiagOptions,
				getRootPaths(alloc, allPaths, includeDir, programDirAndRootPaths));
			return safeCStrIsEmpty(result.diagnostics) ? println(result.document) : printErr(result.diagnostics);
		});
}

struct RunBuildResult {
	immutable ExitCode err;
	immutable Opt!AbsolutePath exePath;
}

immutable(ExitCode) runBuild(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable SafeCStr cwd,
	immutable SafeCStr includeDir,
	immutable SafeCStr tempDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable BuildOptions options,
) {
	return hasAnyOut(options.out_)
		? runBuildInner(
			alloc, perf, allSymbols, allPaths, cwd, includeDir, tempDir,
			programDirAndMain, options, ExeKind.allowNoExe).err
		: withReadOnlyStorage!(immutable ExitCode)(
			allPaths,
			cwd,
			includeDir,
			programDirAndMain.programDir,
			(scope ref immutable ReadOnlyStorage storage) =>
				justTypeCheck(
					alloc, perf, allSymbols, allPaths, storage, getRootPath(allPaths, includeDir, programDirAndMain)));
}

enum ExeKind { ensureExe, allowNoExe }
immutable(RunBuildResult) runBuildInner(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable SafeCStr cwd,
	immutable SafeCStr includeDir,
	immutable SafeCStr tempDir,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable BuildOptions options,
	immutable ExeKind exeKind,
) {
	immutable Sym name = baseName(allPaths, programDirAndMain.mainPath);
	immutable AbsolutePath cPath = has(options.out_.outC)
		? force(options.out_.outC)
		: immutable AbsolutePath(tempDir, rootPath(allPaths, name), safeCStr!".c");
	immutable Opt!AbsolutePath exePath = has(options.out_.outExecutable)
		? options.out_.outExecutable
		: exeKind == ExeKind.ensureExe
		? some(immutable AbsolutePath(tempDir, rootPath(allPaths, name), safeCStr!""))
		: none!AbsolutePath;
	immutable ExitCode err = buildToCAndCompile(
		alloc,
		perf,
		allSymbols,
		allPaths,
		showDiagOptions,
		cwd,
		programDirAndMain,
		includeDir,
		cPath,
		exePath,
		options.cCompileOptions);
	return immutable RunBuildResult(err, exePath);
}

immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(true);

immutable(SafeCStr) getIncludeDirectory(ref Alloc alloc, immutable SafeCStr crowDir) {
	return catToSafeCStr(alloc, strOfSafeCStr(crowDir), "/include");
}

immutable(SafeCStr) getCrowDirectory(ref Alloc alloc, immutable SafeCStr pathToThisExecutable) {
	immutable Opt!string parent = pathParent(strOfSafeCStr(pathToThisExecutable));
	immutable Opt!string res = pathParent(forceOrTodo(parent));
	if (has(res))
		return copyToSafeCStr(alloc, force(res));
	else
		return todo!(immutable SafeCStr)("!");
}

immutable(ExitCode) buildToCAndCompile(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable ShowDiagOptions showDiagOptions,
	immutable SafeCStr cwd,
	ref immutable ProgramDirAndMain programDirAndMain,
	immutable SafeCStr includeDir,
	immutable AbsolutePath cPath,
	immutable Opt!AbsolutePath exePath,
	ref immutable CCompileOptions cCompileOptions,
) {
	return withReadOnlyStorage!(immutable ExitCode)(
		allPaths,
		cwd,
		includeDir,
		programDirAndMain.programDir,
		(scope ref immutable ReadOnlyStorage storage) {
			immutable BuildToCResult result = buildToC(
				alloc, perf, allSymbols, allPaths, storage, showDiagOptions,
				getRootPath(allPaths, includeDir, programDirAndMain));
			if (safeCStrIsEmpty(result.diagnostics)) {
				immutable ExitCode res = writeFile(pathToSafeCStr(alloc, allPaths, cPath), result.cSource);
				return res == ExitCode.ok && has(exePath)
					? compileC(
						alloc, perf, allSymbols, allPaths,
						cPath, force(exePath), result.allExternLibraryNames, cCompileOptions)
					: res;
			} else
				return printErr(result.diagnostics);
		});
}

immutable(ExitCode) buildAndJit(
	ref Alloc alloc,
	ref Perf perf,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	ref immutable JitOptions jitOptions,
	ref immutable ShowDiagOptions showDiagOptions,
	scope ref immutable ReadOnlyStorage storage,
	immutable PathAndStorageKind main,
	immutable SafeCStr[] programArgs,
) {
	immutable ProgramsAndFilesInfo programs = buildToLowProgram(alloc, perf, allSymbols, allPaths, storage, main);
	return hasDiags(programs.program)
		? printErr(strOfDiagnostics(
			alloc,
			allSymbols,
			allPaths,
			showDiagOptions,
			programs.program.filesInfo,
			programs.program.diagnostics))
		: immutable ExitCode(
			jitAndRun(alloc, perf, castImmutableRef(allSymbols), programs.lowProgram, jitOptions, programArgs));
}

immutable(PathAndStorageKind[]) getRootPaths(
	ref Alloc alloc,
	ref AllPaths allPaths,
	immutable SafeCStr includeDir,
	immutable ProgramDirAndRootPaths programDirAndRootPaths,
) {
	return mapImpure(alloc, programDirAndRootPaths.rootPaths, (ref immutable Path path) =>
		getRootPath(allPaths, includeDir, immutable ProgramDirAndMain(programDirAndRootPaths.programDir, path)));
}

immutable(PathAndStorageKind) getRootPath(
	ref AllPaths allPaths,
	immutable SafeCStr includeDir,
	immutable ProgramDirAndMain programDirAndMain,
) {
	// Detect if we're building something already in 'include'
	if (safeCStrEqCat(includeDir, programDirAndMain.programDir, "/include")) {
		immutable Opt!Path withoutInclude =
			removeFirstPathComponentIf(allPaths, programDirAndMain.mainPath, shortSym("include"));
		if (has(withoutInclude))
			return immutable PathAndStorageKind(force(withoutInclude), StorageKind.global);
	}

	return immutable PathAndStorageKind(
		programDirAndMain.mainPath,
		safeCStrEq(includeDir, programDirAndMain.programDir) ? StorageKind.global : StorageKind.local);
}

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
	static immutable SafeCStr[] optimizedArgs = [
		safeCStr!"-Werror",
		safeCStr!"-Wextra",
		safeCStr!"-Wall",
		safeCStr!"-ansi",
		safeCStr!"-std=c11",
		safeCStr!"-Wno-maybe-uninitialized",
		safeCStr!"-Wno-unused-parameter",
		safeCStr!"-Wno-unused-but-set-variable",
		safeCStr!"-Wno-unused-variable",
		safeCStr!"-Wno-unused-value",
		safeCStr!"-Wno-builtin-declaration-mismatch",
		safeCStr!"-pthread",
		safeCStr!"-lm",
		safeCStr!"-Ofast",
	];
	static immutable SafeCStr[] regularArgs = optimizedArgs[0 .. $ - 1];
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
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	immutable Sym[] allExternLibraryNames,
	ref immutable CCompileOptions options,
) {
	immutable SafeCStr[] args =
		cCompileArgs(alloc, allSymbols, allPaths, cPath, exePath, allExternLibraryNames, options);
	// if (true) {
	// 	printf("/usr/bin/cc");
	// 	foreach (immutable string arg; args) {
	// 		printf(" %.*s", cast(int) size(arg), arg.ptr);
	// 	}
	// 	printf("\n");
	// }
	immutable int err = withMeasure!(immutable int, () =>
		spawnAndWait(alloc, allPaths, "/usr/bin/cc", args)
	)(alloc, perf, PerfMeasure.cCompile);
	return immutable ExitCode(err);
}

immutable(SafeCStr[]) cCompileArgs(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	immutable Sym[] allExternLibraryNames,
	ref immutable CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	foreach (immutable Sym it; allExternLibraryNames) {
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeStatic(writer, "-l");
		writeSym(writer, allSymbols, it);
		add(alloc, args, finishWriterToSafeCStr(writer));
	}
	addAll(alloc, args, [
		// TODO: configurable whether we want debug or release
		safeCStr!"-g",
		pathToSafeCStr(alloc, allPaths, cPath),
		safeCStr!"-o",
		pathToSafeCStr(alloc, allPaths, exePath),
	]);
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
	immutable SafeCStr cwd,
	immutable SafeCStr include,
	immutable SafeCStr user,
	immutable(T) delegate(scope ref immutable ReadOnlyStorage) @safe @nogc nothrow cb,
) {
	scope immutable ReadOnlyStorage storage = immutable ReadOnlyStorage(
		immutable AbsolutePathsGetter(cwd, include, user),
		(
			immutable PathAndStorageKind pk,
			immutable SafeCStr extension,
			void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
		) {
			immutable SafeCStr root = () {
				final switch (pk.storageKind) {
					case StorageKind.global:
						return include;
					case StorageKind.local:
						return user;
				}
			}();
			return tryReadFile(allPaths, immutable AbsolutePath(root, pk.path, extension), cb);
		});
	return cb(storage);
}

immutable(ExitCode) withRealExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	//TODO: use gccjit instead of dyncall?
	// TODO: better way to find where it is (may depend on system)
	void* sdlHandle = dlopen("/usr/lib64/libSDL2-2.0.so.0", RTLD_LAZY);
	verify(sdlHandle != null);
	//libEGL.so instead?
	void* glHandle = dlopen("/usr/lib64/libGL.so", RTLD_LAZY);
	verify(glHandle != null);
	void* webpHandle = dlopen("/usr/lib64/libwebp.so", RTLD_LAZY);
	verify(webpHandle != null);
	void* sodiumHandle = dlopen("/usr/lib64/libsodium.so", RTLD_LAZY);
	verify(sodiumHandle != null);
	void* lmdbHandle = dlopen("/usr/lib64/liblmdb.so", RTLD_LAZY);
	verify(lmdbHandle != null);
	DCCallVM* dcVm = dcNewCallVM(4096);
	verify(dcVm != null);
	dcMode(dcVm, DC_CALL_C_DEFAULT);
	scope Extern extern_ = Extern(
		(immutable int clockId, Ptr!TimeSpec timeSpec) @trusted =>
			clock_gettime(clockId, cast(timespec*) timeSpec.rawPtr()),
		(ubyte* ptr) {
			pureFree(ptr);
		},
		(immutable size_t size) =>
			cast(ubyte*) pureMalloc(size),
		(immutable int fd, immutable char* buf, immutable size_t nBytes) =>
			posixWrite(fd, buf, nBytes),
		(
			immutable Sym name,
			immutable DynCallType returnType,
			scope immutable ulong[] parameters,
			scope immutable DynCallType[] parameterTypes,
		) => doDynCall(
			allSymbols, name, returnType, parameters, parameterTypes,
			dcVm, sdlHandle, glHandle, webpHandle, sodiumHandle, lmdbHandle));
	immutable ExitCode res = cb(extern_);
	immutable int err = dlclose(sdlHandle) ||
		dlclose(glHandle) ||
		dlclose(webpHandle) ||
		dlclose(sodiumHandle) ||
		dlclose(lmdbHandle);
	verify(err == 0);
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
	void* sdlHandle,
	void* glHandle,
	void* webpHandle,
	void* sodiumHandle,
	void* lmdbHandle,
) {
	immutable char[32] nameBuffer = symAsTempBuffer!32(allSymbols, name);
	immutable CStr nameCStr = nameBuffer.ptr;
	// TODO: don't just get everything from SDL/GL... use the library from the extern declaration!
	DCpointer ptr = dlsym(sdlHandle, nameCStr);
	if (ptr == null) ptr = dlsym(glHandle, nameCStr);
	if (ptr == null) ptr = dlsym(webpHandle, nameCStr);
	if (ptr == null) ptr = dlsym(sodiumHandle, nameCStr);
	if (ptr == null) ptr = dlsym(lmdbHandle, nameCStr);
	if (ptr == null) printf("Can't load symbol %s\n", nameCStr);
	//printf("Gonna call %s\n", nameCStr);
	verify(ptr != null);

	dcReset(dcVm);
	zipImpureSystem!(ulong, DynCallType)(
		parameters,
		parameterTypes,
		(ref immutable ulong value, ref immutable DynCallType type) {
			final switch (type) {
				case DynCallType.bool_:
					dcArgBool(dcVm, cast(bool) value);
					break;
				case DynCallType.char_:
					todo!void("handle this type");
					break;
				case DynCallType.int8:
					todo!void("handle this type");
					break;
				case DynCallType.int16:
					todo!void("handle this type");
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
				return todo!(immutable ulong)("handle this type");
			case DynCallType.char_:
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
	//printf("Did call %s\n", nameCStr);
	return res;
}

extern(C) {
	// dlfcn.h
	void* dlopen(const char* file, int mode);
	int dlclose(void* handle);
	void* dlsym(void* handle, const char* name);
	enum RTLD_LAZY = 1;

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
	//void dcArgShort (DCCallVM* vm, DCshort value);
	void dcArgInt (DCCallVM* vm, DCint value);
	void dcArgLong (DCCallVM* vm, DClong value);
	//void dcArgLongLong (DCCallVM* vm, DClonglong value);
	void dcArgFloat (DCCallVM* vm, DCfloat value);
	void dcArgDouble (DCCallVM* vm, DCdouble value);
	void dcArgPointer (DCCallVM* vm, DCpointer value);
	// void dcArgStruct (DCCallVM* vm, DCstruct* s, DCpointer value);

	void dcCallVoid (DCCallVM* vm, DCpointer funcptr);
	//DCbool dcCallBool (DCCallVM* vm, DCpointer funcptr);
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

//extern void *dlopen (const char *__file, int __mode) __THROWNL;

@trusted void tryReadFile(
	scope ref const AllPaths allPaths,
	immutable AbsolutePath path,
	scope void delegate(immutable Opt!SafeCStr) @safe @nogc pure nothrow cb,
) {
	TempStrForPath pathTempStr = pathToTempStr(allPaths, path);
	immutable int fd = open(asTempSafeCStr(pathTempStr).ptr, O_RDONLY);
	if (fd == -1) {
		if (errno == ENOENT) {
			return cb(none!SafeCStr);
		} else {
			fprintf(stderr, "Failed to open file %s\n", asTempSafeCStr(pathTempStr).ptr);
			todo!void("fail");
		}
	}
	scope(exit) close(fd);

	immutable off_t fileSizeOff = lseek(fd, 0, SEEK_END);
	if (fileSizeOff < 0)
		todo!void("lseek failed");

	if (fileSizeOff > 99_999)
		todo!void("size suspiciously large");

	immutable uint fileSize = cast(uint) fileSizeOff;

	if (fileSize == 0)
		return cb(some(safeCStr!""));

	// Go back to the beginning so we can read
	immutable off_t off = lseek(fd, 0, SEEK_SET);
	if (off == -1)
		todo!void("lseek failed");

	verify(off == 0);

	TempStr!0x100000 content;
	verify(fileSize < content.capacity);
	immutable long nBytesRead = read(fd, content.ptr, fileSize);
	if (nBytesRead != fileSize) {
		if (nBytesRead == -1)
			todo!void("read failed");
		else
			todo!void("nBytesRead not right?");
	}

	setLength(content, nBytesRead);
	return cb(some(asTempSafeCStr(content)));
}

@trusted immutable(ExitCode) writeFile(immutable SafeCStr path, immutable SafeCStr content) {
	immutable int fd = tryOpenFile(path);
	if (fd == -1) {
		fprintf(stderr, "Failed to write file %s: %s\n", path.ptr, strerror(errno));
		return ExitCode.error;
	} else {
		scope(exit) close(fd);

		immutable size_t size = safeCStrSize(content);
		immutable long wroteBytes = posixWrite(fd, content.ptr, size);
		if (wroteBytes != size)
			if (wroteBytes == -1)
				todo!void("writeFile failed");
			else
				todo!void("writeFile -- didn't write all the bytes?");
		return ExitCode.ok;
	}
}

@system immutable(int) tryOpenFile(immutable SafeCStr path) {
	immutable int fd = open(path.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0b110_100_100);
	if (fd == -1 && errno == ENOENT) {
		immutable Opt!string par = pathParent(strOfSafeCStr(path));
		if (has(par)) {
			immutable ExitCode res = mkdirRecur(force(par));
			if (res == ExitCode.ok)
				return open(path.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0b110_100_100);
		}
	}
	return fd;
}

struct CommandLineArgs {
	immutable SafeCStr pathToThisExecutable;
	immutable SafeCStr[] args;
}

@trusted immutable(CommandLineArgs) parseCommandLineArgs(
	ref Alloc alloc,
	immutable size_t argc,
	immutable CStr* argv,
) {
	immutable SafeCStr[] allArgs = cast(immutable SafeCStr[]) argv[0 .. argc];
	// Take the tail because the first one is 'crow'
	return immutable CommandLineArgs(getPathToThisExecutable(alloc), allArgs[1 .. $]);
}

@trusted immutable(SafeCStr) getCwd(ref Alloc alloc) {
	char[maxPathSize] buff;
	char* b = getcwd(buff.ptr, maxPathSize);
	if (b == null)
		return todo!(immutable SafeCStr)("getcwd failed");
	else {
		verify(b == buff.ptr);
		return copyCStrToSafeCStr(alloc, cast(immutable) buff.ptr);
	}
}

immutable(SafeCStr) copyCStrToSafeCStr(ref Alloc alloc, immutable CStr begin) {
	return copyToSafeCStr(alloc, strOfCStr(begin));
}

immutable size_t maxPathSize = 0x1000;

@trusted immutable(SafeCStr) getPathToThisExecutable(ref Alloc alloc) {
	char[maxPathSize] buff;
	immutable long size = readlink("/proc/self/exe", buff.ptr, maxPathSize);
	if (size < 0)
		todo!void("posix error");
	return copyToSafeCStr(alloc, cast(immutable) buff.ptr[0 .. size]);
}

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted immutable(int) spawnAndWait(
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	immutable CStr executablePath,
	immutable SafeCStr[] args,
) {
	pid_t pid;
	immutable int spawnStatus = posix_spawn(
		&pid,
		executablePath,
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

// Return should be const, but some posix functions aren't marked that way
@system immutable(CStr*) convertArgs(
	ref Alloc alloc,
	immutable CStr executable,
	immutable SafeCStr[] args,
) {
	ArrBuilder!CStr cArgs;
	add(alloc, cArgs, executable);
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
