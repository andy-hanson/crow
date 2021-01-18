@safe @nogc nothrow: // not pure

import core.memory : pureFree, pureMalloc;
import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fprintf, printf, SEEK_END, SEEK_SET, stderr;
import core.stdc.string : strerror;
import core.sys.posix.fcntl : open, O_CREAT, O_RDONLY, O_TRUNC, O_WRONLY, pid_t;
import core.sys.posix.spawn : posix_spawn;
import core.sys.posix.sys.wait : waitpid;
import core.sys.posix.sys.types : off_t;
import core.sys.posix.time : clock_gettime, timespec;
import core.sys.posix.unistd : close, getcwd, lseek, read, readlink, posixWrite = write;
import std.process : execvpe;

import frontend.showDiag : ShowDiagOptions;
import interpret.allocTracker : AllocTracker;
import interpret.applyFn : nat64OfI32, nat64OfI64;
import interpret.bytecode : DynCallType, TimeSpec;
import lib.cliParser : Command, matchCommand, parseCommand, ProgramDirAndMain;
import lib.compiler :
	buildAndInterpret,
	buildToC,
	BuildToCResult,
	DiagsAndResultStrs,
	getAbsolutePathFromStorage,
	print;
import model.model : AbsolutePathsGetter;
import test.test : test;
import util.bools : Bool, True;
import util.collection.arr : Arr, begin, empty, range, size;
import util.collection.arrBuilder : add, addAll, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, cat, map, tail, zipImpureSystem;
import util.collection.str :
	asCStr,
	copyStr,
	CStr,
	copyToNulTerminatedStr,
	emptyNulTerminatedStr,
	emptyStr,
	NulTerminatedStr,
	Str,
	strEqLiteral,
	strLiteral,
	strOfCStr,
	strToCStr;
import util.opt : force, forceOrTodo, has, none, Opt, some;
import util.path :
	AbsolutePath,
	AllPaths,
	PathAndStorageKind,
	pathBaseName,
	pathParent,
	pathToCStr,
	pathToStr,
	rootPath,
	StorageKind,
	withExtension;
import util.ptr : Ptr, PtrRange, ptrTrustMe_mut;
import util.sym : AllSymbols, shortSymAlphaLiteral;
import util.types : Nat64, safeSizeTFromSSizeT, safeSizeTFromU64, safeU32FromI64, ssize_t;
import util.util : todo, unreachable, verify;
import util.writer : Writer;

extern(C) int main(immutable size_t argc, immutable CStr* argv) {
	Mallocator mallocator;
	immutable CommandLineArgs args = parseCommandLineArgs(mallocator, argc, argv);
	AllPaths!Mallocator allPaths = AllPaths!Mallocator(ptrTrustMe_mut(mallocator));
	AllSymbols!Mallocator allSymbols = AllSymbols!Mallocator(ptrTrustMe_mut(mallocator));
	return go(mallocator, allPaths, allSymbols, args);
}

private:

struct StdoutDebug {
	@safe @nogc pure nothrow:

	bool enabled() {
		return false;
	}

	void write(scope ref immutable Str a) {
		debug {
			printf("%.*s", cast(uint) size(a), begin(a));
		}
	}

	void writeChar(immutable char c) {
		debug {
			printf("%c", c);
		}
	}
}

immutable(int) go(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable CommandLineArgs args,
) {
	immutable Str nozeDir = getNozeDirectory(args.pathToThisExecutable);
	immutable Command command = parseCommand(alloc, allPaths, allSymbols, getCwd(alloc), args.args);
	immutable Str include = cat(alloc, nozeDir, strLiteral("/include"));
	immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(True);
	StdoutDebug dbg;

	return matchCommand!int(
		command,
		(ref immutable Command.Build it) {
			immutable Opt!AbsolutePath exePath =
				buildToCAndCompile(
					alloc,
					allPaths,
					allSymbols,
					showDiagOptions,
					it.programDirAndMain,
					include);
			return has(exePath) ? 0 : 1;
		},
		(ref immutable Command.Help it) =>
			help(it),
		(ref immutable Command.Print it) {
			RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
				ptrTrustMe_mut(allPaths),
				ptrTrustMe_mut(alloc),
				include,
				it.programDirAndMain.programDir);
			immutable DiagsAndResultStrs printed = print(
				alloc,
				allPaths,
				allSymbols,
				storage,
				showDiagOptions,
				it.kind,
				it.format,
				it.programDirAndMain.mainPath);
			if (!empty(printed.diagnostics)) printErr(printed.diagnostics);
			if (!empty(printed.result)) print(printed.result);
			return empty(printed.diagnostics) ? 0 : 1;
		},
		(ref immutable Command.Run it) {
			RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
				ptrTrustMe_mut(allPaths),
				ptrTrustMe_mut(alloc),
				include,
				it.build.programDirAndMain.programDir);
			if (it.interpret) {
				RealExtern extern_ = newRealExtern();
				return buildAndInterpret(
					dbg,
					alloc,
					allPaths,
					allSymbols,
					storage,
					extern_,
					showDiagOptions,
					it.build.programDirAndMain.mainPath,
					it.programArgs);
			} else {
				immutable Opt!AbsolutePath exePath = buildToCAndCompile(
					alloc,
					allPaths,
					allSymbols,
					showDiagOptions,
					it.build.programDirAndMain,
					include);
				if (!has(exePath))
					return 1;
				else {
					replaceCurrentProcess(alloc, allPaths, force(exePath), it.programArgs);
					return unreachable!int();
				}
			}
		},
		(ref immutable Command.Test it) =>
			test(dbg, alloc, it.name));
}

immutable(Str) getNozeDirectory(immutable Str pathToThisExecutable) {
	immutable Opt!Str parent = pathParent(pathToThisExecutable);
	return climbUpToNoze(forceOrTodo(parent));
}

immutable(Str) climbUpToNoze(immutable Str p) {
	immutable Opt!Str par = pathParent(p);
	immutable Opt!Str bn = pathBaseName(p);
	return strEqLiteral(bn.forceOrTodo, "noze")
		? p
		: has(par)
		? climbUpToNoze(force(par))
		: todo!Str("no 'noze' directory in path");
}

immutable(Opt!AbsolutePath) buildToCAndCompile(Alloc, PathAlloc, SymAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref AllSymbols!SymAlloc allSymbols,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable ProgramDirAndMain programDirAndMain,
	ref immutable Str include,
) {
	RealReadOnlyStorage!(PathAlloc, Alloc) storage = RealReadOnlyStorage!(PathAlloc, Alloc)(
		ptrTrustMe_mut(allPaths),
		ptrTrustMe_mut(alloc),
		include,
		programDirAndMain.programDir);
	immutable AbsolutePath cPath =
		getAbsolutePathFromStorage(alloc, storage, programDirAndMain.mainPath, strLiteral(".c"));
	immutable BuildToCResult result =
		buildToC(alloc, allPaths, allSymbols, storage, showDiagOptions, programDirAndMain.mainPath);
	if (empty(result.diagnostics)) {
		writeFileSync(alloc, allPaths, cPath, result.cSource);
		immutable AbsolutePath exePath = withExtension(cPath, emptyStr);
		compileC(alloc, allPaths, cPath, exePath, result.allExternLibraryNames);
		return some(exePath);
	} else {
		printErr(result.diagnostics);
		return none!AbsolutePath;
	}
}

immutable(int) help(ref immutable Command.Help a) {
	print(a.helpText);
	return a.isDueToCommandParseError ? 1 : 0;
}

void compileC(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath cPath,
	ref immutable AbsolutePath exePath,
	ref immutable Arr!Str allExternLibraryNames,
) {
	immutable AbsolutePath cCompiler =
		AbsolutePath(strLiteral("/usr/bin"), rootPath(allPaths, shortSymAlphaLiteral("cc")), emptyStr);
	ArrBuilder!Str args;
	addAll(alloc, args, arrLiteral!Str(alloc, [
		strLiteral("-Werror"),
		strLiteral("-Wextra"),
		strLiteral("-Wall"),
		strLiteral("-ansi"),
		strLiteral("-std=c11"),
		strLiteral("-Wno-unused-parameter"),
		strLiteral("-Wno-unused-but-set-variable"),
		strLiteral("-Wno-unused-variable"),
		strLiteral("-Wno-unused-value"),
		strLiteral("-Wno-builtin-declaration-mismatch"), //TODO:KILL?
		strLiteral("-pthread"),
	]));
	foreach (immutable Str it; range(allExternLibraryNames))
		add(alloc, args, cat(alloc, strLiteral("-l"), it));
	addAll(alloc, args, arrLiteral!Str(alloc, [
		// TODO: configurable whether we want debug or release
		strLiteral("-g"),
		pathToStr(alloc, allPaths, cPath),
		strLiteral("-o"),
		pathToStr(alloc, allPaths, exePath),
	]));
	immutable int err = spawnAndWaitSync(alloc, allPaths, cCompiler, finishArr(alloc, args));
	if (err != 0)
		todo!void("C compile error");
}

@trusted void print(immutable Str a) {
	printf("%.*s", cast(uint) size(a), begin(a));
}

void print(immutable string a) {
	print(strLiteral(a));
}

@trusted void printErr(immutable Str a) {
	fprintf(stderr, "%.*s", cast(uint) size(a), begin(a));
}

struct Mallocator {
	@safe @nogc pure nothrow:

	@disable this(ref const Mallocator);

	@trusted ubyte* allocateBytes(immutable size_t size) {
		ubyte* res = cast(ubyte*) pureMalloc(size);
		verify(res != null);
		return res;
	}

	@trusted void freeBytes(ubyte* ptr, immutable size_t) {
		pureFree(cast(void*) ptr);
	}

	@trusted void freeBytesPartial(ubyte* ptr, immutable size_t) {
	}
}

struct RealReadOnlyStorage(PathAlloc, Alloc) {
	@safe @nogc nothrow: // not pure

	immutable(AbsolutePathsGetter) absolutePathsGetter() const {
		return immutable AbsolutePathsGetter(include, user);
	}

	immutable(T) withFile(T)(
		ref immutable PathAndStorageKind pk,
		immutable Str extension,
		scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
	) {
		immutable Str root = () {
			final switch (pk.storageKind) {
				case StorageKind.global:
					return include;
				case StorageKind.local:
					return user;
			}
		}();
		immutable AbsolutePath ap = immutable AbsolutePath(root, pk.path, extension);
		return tryReadFile(tempAlloc, allPaths, ap, cb);
	}

	private:
	Ptr!(AllPaths!PathAlloc) allPaths;
	Ptr!Alloc tempAlloc;
	immutable Str include;
	immutable Str user;
}


RealExtern newRealExtern() {
	return RealExtern(true);
}

struct RealExtern {
	@safe @nogc nothrow: // not pure

	private:
	@disable this();
	@disable this(ref const RealExtern);

	Mallocator alloc;
	AllocTracker allocTracker;
	void* sdlHandle;
	DCCallVM* dcVm;

	this(bool) {
		// TODO: better way to find where it is (may depend on system)
		sdlHandle = dlopen("/usr/lib64/libSDL2-2.0.so.0", RTLD_LAZY);
		verify(sdlHandle != null);

		dcVm = dcNewCallVM(4096);
		verify(dcVm != null);
		dcMode(dcVm, DC_CALL_C_DEFAULT);
	}

	public:

	~this() {
		immutable int err = dlclose(sdlHandle);
		verify(err == 0);
		dcFree(dcVm);
	}

	@system immutable(int) clockGetTime(immutable int clockId, Ptr!TimeSpec tp) {
		return clock_gettime(clockId, cast(timespec*) tp.rawPtr());
	}

	@system pure void free(ubyte* ptr) {
		immutable size_t size = allocTracker.markFree(ptr);
		alloc.freeBytes(ptr, size);
	}

	@system pure ubyte* malloc(immutable size_t size) {
		ubyte* ptr = alloc.allocateBytes(size);
		allocTracker.markAlloced(alloc, ptr, size);
		return ptr;
	}

	@system immutable(long) write(int fd, immutable char* buf, immutable size_t nBytes) const {
		return posixWrite(fd, buf, nBytes);
	}

	immutable(size_t) getNProcs() const {
		// TODO: interpreter needs to support multiple threads
		return 1;
	}

	immutable(size_t) pthreadYield() const {
		// We don't support launching other threads, so do nothing
		return 0;
	}

	immutable(Bool) hasMallocedPtr(ref const PtrRange range) const {
		return allocTracker.hasAllocedPtr(range);
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		allocTracker.writeMallocedRanges!WriterAlloc(writer);
	}

	@trusted immutable(Nat64) doDynCall(
		ref immutable NulTerminatedStr name,
		immutable DynCallType returnType,
		ref immutable Arr!Nat64 parameters,
		ref immutable Arr!DynCallType parameterTypes,
	) {
		// TODO: don't just get everything from SDL...
		DCpointer ptr = dlsym(sdlHandle, asCStr(name));
		verify(ptr != null);

		dcReset(dcVm);
		zipImpureSystem!(Nat64, DynCallType)(
			parameters,
			parameterTypes,
			(ref immutable Nat64 value, ref immutable DynCallType type) {
				final switch (type) {
					case DynCallType.bool_:
						todo!void("handle this type");
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
						dcArgInt(dcVm, cast(int) value.raw());
						break;
					case DynCallType.float32:
						todo!void("handle this type");
						break;
					case DynCallType.float64:
						todo!void("handle this type");
						break;
					case DynCallType.nat8:
						todo!void("handle this type");
						break;
					case DynCallType.nat16:
						todo!void("handle this type");
						break;
					case DynCallType.nat32:
						dcArgInt(dcVm, cast(uint) value.raw());
						break;
					case DynCallType.int64:
					case DynCallType.nat64:
						dcArgLong(dcVm, value.raw());
						break;
					case DynCallType.pointer:
						dcArgPointer(dcVm, cast(void*) value.raw());
						break;
					case DynCallType.void_:
						unreachable!void();
				}
			});

		immutable Nat64 res = () {
			final switch (returnType) {
				case DynCallType.bool_:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.char_:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int8:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int16:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int32:
					return nat64OfI32(dcCallInt(dcVm, ptr));
				case DynCallType.int64:
					return nat64OfI64(dcCallLong(dcVm, ptr));
				case DynCallType.float32:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.float64:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat8:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat16:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat32:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat64:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.pointer:
					return immutable Nat64(cast(size_t) dcCallPointer(dcVm, ptr));
				case DynCallType.void_:
					dcCallVoid(dcVm, ptr);
					return immutable Nat64(0);
			}
		}();
		dcReset(dcVm);
		return res;
	}
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

	//void dcArgBool (DCCallVM* vm, DCbool value);
	//void dcArgChar (DCCallVM* vm, DCchar value);
	//void dcArgShort (DCCallVM* vm, DCshort value);
	void dcArgInt (DCCallVM* vm, DCint value);
	void dcArgLong (DCCallVM* vm, DClong value);
	//void dcArgLongLong (DCCallVM* vm, DClonglong value);
	//void dcArgFloat (DCCallVM* vm, DCfloat value);
	//void dcArgDouble (DCCallVM* vm, DCdouble value);
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
	//DCdouble dcCallDouble (DCCallVM* vm, DCpointer funcptr);
	DCpointer dcCallPointer (DCCallVM* vm, DCpointer funcptr);
	// void dcCallStruct (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

	//DCint dcGetError (DCCallVM* vm);
}

//extern void *dlopen (const char *__file, int __mode) __THROWNL;

@trusted immutable(T) tryReadFile(T, TempAlloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable AbsolutePath path,
	scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
) {
	immutable CStr pathCStr = pathToCStr(tempAlloc, allPaths, path);

	immutable int fd = open(pathCStr, O_RDONLY);
	if (fd == -1) {
		if (errno == ENOENT) {
			immutable Opt!NulTerminatedStr n = none!NulTerminatedStr;
			return cb(n);
		} else {
			fprintf(stderr, "Failed to open file %s\n", pathCStr);
			return todo!T("fail");
		}
	}

	scope(exit) close(fd);

	immutable off_t fileSizeOff = lseek(fd, 0, SEEK_END);
	if (fileSizeOff == -1)
		return todo!T("lseek fialed");

	if (fileSizeOff > 99_999)
		return todo!T("size suspiciously large");

	immutable uint fileSize = safeU32FromI64(fileSizeOff);

	if (fileSize == 0) {
		immutable Opt!NulTerminatedStr s = some(emptyNulTerminatedStr);
		return cb(s);
	}

	// Go back to the beginning so we can read
	immutable off_t off = lseek(fd, 0, SEEK_SET);
	if (off == -1)
		return todo!T("lseek failed");

	verify(off == 0);

	immutable size_t contentSize = safeSizeTFromU64(fileSize + 1);
	char* content = cast(char*) tempAlloc.allocateBytes(char.sizeof * contentSize); // + 1 for the '\0'
	scope (exit) tempAlloc.freeBytes(cast(ubyte*) content, char.sizeof * contentSize);
	immutable ssize_t nBytesRead = read(fd, content, fileSize);

	if (nBytesRead == -1)
		return todo!T("read failed");

	if (nBytesRead != fileSize)
		return todo!T("nBytesRead not right?");

	content[fileSize] = '\0';

	immutable Opt!NulTerminatedStr s =
		some(immutable NulTerminatedStr(immutable Str(cast(immutable) content, contentSize)));
	return cb(s);
}

@trusted void writeFileSync(TempAlloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
	ref immutable Str content,
) {
	immutable int fd = tryOpen(tempAlloc, allPaths, path, O_CREAT | O_WRONLY | O_TRUNC, 0b110_100_100);
	scope(exit) close(fd);

	immutable ssize_t wroteBytes = posixWrite(fd, content.begin, size(content));
	if (wroteBytes != size(content))
		if (wroteBytes == -1)
			todo!void("writeFile failed");
		else
			todo!void("writeFile -- didn't write all the bytes?");
}

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted int spawnAndWaitSync(TempAlloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable AbsolutePath executable,
	immutable Arr!Str args,
) {
	immutable CStr executableCStr = pathToCStr(tempAlloc, allPaths, executable);
	return spawnAndWaitSync(executableCStr, convertArgs(tempAlloc, executableCStr, args));
}

// Replaces this process with the given executable.
// DOES NOT RETURN!
@trusted void replaceCurrentProcess(TempAlloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	immutable AbsolutePath executable,
	immutable Arr!Str args,
) {
	immutable CStr executableCStr = pathToCStr(tempAlloc, allPaths, executable);
	immutable int err = execvpe(executableCStr, convertArgs(tempAlloc, executableCStr, args), environ);
	// 'execvpe' only returns if we failed to create the process (maybe executable does not exist?)
	verify(err == -1);
	fprintf(stderr, "Failed to launch %s: error %s\n", executableCStr, strerror(errno));
	todo!void("failed to launch");
}

struct CommandLineArgs {
	immutable Str pathToThisExecutable;
	immutable Arr!Str args;
}

immutable(CommandLineArgs) parseCommandLineArgs(Alloc)(
	ref Alloc alloc,
	immutable size_t argc,
	immutable CStr* argv,
) {
	immutable Arr!CStr allArgs = immutable Arr!CStr(argv, argc);
	immutable Arr!Str args = map!(Str, CStr, Alloc)(alloc, allArgs, (ref immutable CStr a) => strOfCStr(a));
	// Take the tail because the first one is 'noze'
	return immutable CommandLineArgs(getPathToThisExecutable(alloc), args.tail);
}

@trusted immutable(Str) getCwd(Alloc)(ref Alloc alloc) {
	char[maxPathSize] buff;
	char* b = getcwd(buff.ptr, maxPathSize);
	if (b == null)
		return todo!Str("getcwd failed");
	else {
		verify(b == buff.ptr);
		return copyCStrToStr(alloc, cast(immutable) buff.ptr);
	}
}

@system int tryOpen(TempAlloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable AbsolutePath path,
	immutable int flags,
	immutable int moreFlags,
) {
	immutable int fd = open(pathToCStr(tempAlloc, allPaths, path), flags, moreFlags);
	if (fd == -1)
		todo!void("can't write to file");
	return fd;
}

immutable(Str) copyCStrToStr(Alloc)(ref Alloc alloc, immutable CStr begin) {
	return copyStr(alloc, strOfCStr(begin));
}

immutable(CStr) copyCStr(Alloc)(ref Alloc alloc, immutable CStr begin) {
	immutable Str str = strOfCStr(begin);
	return copyToNulTerminatedStr!Alloc(alloc, str).asCStr();
}

@trusted immutable(int) spawnAndWaitSync(immutable CStr executablePath, immutable CStr* args) {
	pid_t pid;
	immutable int spawnStatus = posix_spawn(
		&pid,
		executablePath,
		null,
		null,
		// https://stackoverflow.com/questions/50596439/can-string-literals-be-passed-in-posix-spawns-argv
		cast(char**) args,
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

immutable size_t maxPathSize = 1024;

@trusted immutable(Str) getPathToThisExecutable(Alloc)(ref Alloc alloc) {
	char[maxPathSize] buff;
	immutable ssize_t size = readlink("/proc/self/exe", buff.ptr, maxPathSize);
	if (size < 0)
		todo!void("posix error");
	return copyStr(alloc, immutable Str(cast(immutable) buff.ptr, safeSizeTFromSSizeT(size)));
}

// Return should be const, but some posix functions aren't marked that way
@system immutable(CStr*) convertArgs(Alloc)(ref Alloc alloc, immutable CStr executableCStr, immutable Arr!Str args) {
	ArrBuilder!CStr cArgs;
	// Make a mutable copy
	immutable CStr executableCopy = copyCStr(alloc, executableCStr);
	add(alloc, cArgs, executableCopy);
	foreach (immutable Str arg; range(args))
		add(alloc, cArgs, strToCStr(alloc, arg));
	add(alloc, cArgs, null);
	return finishArr(alloc, cArgs).begin;
}

// D doesn't declare this anywhere for some reason
extern(C) int execvpe(const char *__file, const char ** __argv, const char ** __envp);
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
