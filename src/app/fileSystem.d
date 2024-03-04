module app.fileSystem;

@safe @nogc nothrow: // not pure

import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fclose, ferror, fflush, fgets, FILE, fopen, fread, fseek, ftell, fwrite, SEEK_END, SEEK_SET;
version (Windows) {} else {
	import core.stdc.stdio : posixStderr = stderr, posixStdin = stdin, posixStdout = stdout;
}
import core.stdc.string : strerror;
import std.conv : octal;

version (Windows) {
	import core.sys.windows.core :
		CloseHandle,
		CP_UTF8,
		CreatePipe,
		CreateProcessA,
		DeleteFileA,
		DWORD,
		ERROR_BROKEN_PIPE,
		ERROR_FILE_NOT_FOUND,
		ERROR_SHARING_VIOLATION,
		FormatMessageA,
		FORMAT_MESSAGE_FROM_SYSTEM,
		FORMAT_MESSAGE_IGNORE_INSERTS,
		GetExitCodeProcess,
		GetLastError,
		GetModuleFileNameA,
		GetModuleHandle,
		GetStdHandle,
		HANDLE,
		HANDLE_FLAG_INHERIT,
		HMODULE,
		INFINITE,
		LPCSTR,
		PROCESS_INFORMATION,
		ReadFile,
		SearchPathA,
		SECURITY_ATTRIBUTES,
		SetConsoleOutputCP,
		SetHandleInformation,
		Sleep,
		STARTF_USESTDHANDLES,
		STARTUPINFOA,
		STD_ERROR_HANDLE,
		STD_OUTPUT_HANDLE,
		WaitForSingleObject,
		WriteFile;
} else {
	import core.sys.posix.spawn : posix_spawn;
	import core.sys.posix.sys.wait : waitpid;
	import core.sys.posix.sys.stat : mkdir, pid_t;
	import core.sys.posix.unistd : getcwd, read, readlink, unlink, write;
}

import backend.writeToC : PathAndArgs;
import frontend.storage : ReadFileResult;
import model.diag : ReadFileDiag;
import model.lowModel : ExternLibrary, ExternLibraries;
import util.alloc.alloc : Alloc, allocateElements, TempAlloc;
import util.col.array : endPtr, exists, newArray;
import util.col.arrayBuilder : buildArray, Builder;
import util.conv : safeToInt, safeToUint;
import util.exitCode : ExitCode, okAnd, onError;
import util.memory : memset;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.string : CString, cString;
import util.symbol : alterExtension, Extension, Symbol;
import util.unicode : FileContent;
import util.union_ : TaggedUnion;
import util.uri :
	alterExtension,
	alterExtensionWithHex,
	asFilePath,
	baseName,
	cStringOfFilePath,
	FilePath,
	parent,
	parseFilePath,
	Uri,
	uriIsFile,
	withCStringOfFilePath;
import util.util : castImmutable, todo, typeAs;
import util.writer : withStackWriterImpure, withWriter, Writer, writeWithSeparatorAndFilter;

private enum OutPipe { stdout = 1, stderr = 2 }

private FILE* stdin() {
	version (Windows) {
		return __acrt_iob_func(0);
	} else {
		return posixStdin;
	}
}

@system CString readLineFromStdin(scope char[] buffer) {
	char* res = fgets(buffer.ptr, safeToInt(buffer.length), stdin);
	assert(res != null);
	return CString(castImmutable(res));
}

@system void readExactFromStdin(scope char[] buffer) {
	size_t n = fread(buffer.ptr, char.sizeof, buffer.length, stdin);
	assert(n == buffer.length);
}

@trusted ExitCode print(in string a) {
	writeLn(OutPipe.stdout, a);
	return ExitCode.ok;
}

ExitCode printCb(in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) =>
	withStackWriterImpure(cb, (in string x) => print(x));

@trusted ExitCode printError(in string a) {
	writeLn(OutPipe.stderr, a);
	return ExitCode.error;
}

ExitCode printErrorCb(in void delegate(scope ref Writer writer) @safe @nogc nothrow cb) =>
	withStackWriterImpure(cb, (in string x) => printError(x));

// Unlike 'print' this does *not* add a newline.
@system void writeToStdoutAndFlush(in string a) {
	writeString(OutPipe.stdout, a);
	flush(OutPipe.stdout);
}

private void flush(OutPipe pipe) {
	fflush(fileForPipe(pipe));
}

private FILE* fileForPipe(OutPipe pipe) {
	version (Windows) {
		return __acrt_iob_func(pipe);
	} else {
		final switch (pipe) {
			case OutPipe.stdout:
				return posixStdout;
			case OutPipe.stderr:
				return posixStderr;
		}
	}
}

private @system void writeString(OutPipe pipe, in string a) {
	version (Windows) {
		SetConsoleOutputCP(CP_UTF8);
		HANDLE console = GetStdHandle(() {
			final switch (pipe) {
				case OutPipe.stdout:
					return STD_OUTPUT_HANDLE;
				case OutPipe.stderr:
					return STD_ERROR_HANDLE;
			}
		}());
		DWORD written = 0;
		int ok = WriteFile(console, a.ptr, safeToUint(a.length), &written, null);
		assert(ok == 1);
		assert(written == a.length);
	} else {
		write(pipe, a.ptr, safeToUint(a.length));
	}
}

private @system void writeLn(OutPipe pipe, in string a) {
	writeString(pipe, a);
	writeString(pipe, "\n");
	flush(pipe);
}

private ExitCode removeFileIfExists(FilePath path) =>
	withCStringOfFilePath(path, (in CString cString) @trusted {
		version (Windows) {
			bool success = withRetry(() {
				int ok = DeleteFileA(cString.ptr);
				return ok == 1 || GetLastError() == ERROR_FILE_NOT_FOUND ? RetryResult.ok :
					GetLastError() == ERROR_SHARING_VIOLATION ? RetryResult.retry :
					RetryResult.error;
			});
		} else {
			bool success = () {
				final switch (unlink(cString.ptr)) {
					case 0:
						return true;
					case -1:
						return errno == ENOENT;
				}
			}();
		}
		return success ? ExitCode.ok : printErrorCb((scope ref Writer writer) {
			writer ~= "Error removing file ";
			writer ~= cString;
			writer ~= ": ";
			writeLastError(writer);
		});
	});

/**
This doesn't create the path, 'cb' should do that.
But if it is a temp path, this deletes it after the callback finishes.
*/
ExitCode withPathOrTemp(
	Opt!FilePath path,
	Uri tempBasePath,
	Extension extension,
	in ExitCode delegate(FilePath) @safe @nogc nothrow cb,
) =>
	has(path)
		? cb(force(path))
		: withTempPath(tempBasePath, extension, cb);

ExitCode withTempPath(Uri tempBasePath, Extension extension, in ExitCode delegate(FilePath) @safe @nogc nothrow cb) {
	if (uriIsFile(tempBasePath)) {
		ubyte[8] bytes = getRandomBytes();
		FilePath tempPath = alterExtensionWithHex(asFilePath(tempBasePath), bytes, extension);
		ExitCode exit = cb(tempPath);
		ExitCode exit2 = removeFileIfExists(tempPath);
		return okAnd(exit, () => exit2);
	} else
		return printErrorCb((scope ref Writer writer) {
			writer ~= "Don't know where to put temporary file near ";
			writer ~= tempBasePath;
			writer ~= " (since it is not a file path)";
		});
}

private @trusted ubyte[8] getRandomBytes() {
	version (Windows) {
		uint v0, v1;
		int err = rand_s(&v0) || rand_s(&v1);
		if (err != 0) todo!void("Error getting random bytes");
		return concat(bytesOfUint(v0), bytesOfUint(v1));
	} else {
		return getNRandomBytes!8();
	}
}

@trusted ubyte[n] getNRandomBytes(size_t n)() {
	version (Windows) {
		ubyte[n] res;
		assert(n % 8 == 0);
		for (size_t i = 0; i < n; i += 8) {
			foreach (size_t j, ubyte x; getRandomBytes())
				res[i + j] = x;
		}
		return res;
	} else {
		ubyte[n] out_;
		FILE* fd = fopen("/dev/urandom", "rb");
		if (fd == null)
			return todo!(ubyte[n])("missing /dev/urandom");
		scope(exit) fclose(fd);
		fread(out_.ptr, ubyte.sizeof, out_.length, fd);
		return out_;
	}
}

version (Windows) {
	private extern(C) int rand_s(uint* randomValue);
}

private ubyte[4] bytesOfUint(uint a) =>
	[cast(ubyte) (a >> 24), cast(ubyte) (a >> 16), cast(ubyte) (a >> 8), cast(ubyte) a];

private T[size0 + size1] concat(T, size_t size0, size_t size1)(in T[size0] a, in T[size1] b) {
	T[size0 + size1] res;
	foreach (size_t i; 0 .. size0)
		res[i] = a[i];
	foreach (size_t i; 0 .. size1)
		res[size0 + i] = b[i];
	return res;
}

private alias TempStrForPath = char[0x1000];

@trusted Opt!FilePath findPathToCCompiler() {
	version (Windows) {
		TempStrForPath res = void;
		int len = SearchPathA(null, "cl.exe", null, cast(uint) res.length, res.ptr, null);
		if (len == 0) {
			printError("Could not find cl.exe on path. Be sure you are using a Native Tools Command Prompt.");
			return none!FilePath;
		} else
			return some(parseFilePath(CString(cast(immutable) res.ptr)));
	} else
		return some(parseFilePath(cString!"/usr/bin/cc"));
}

@trusted ReadFileResult tryReadFile(ref Alloc alloc, Uri uri) {
	if (!uriIsFile(uri))
		return ReadFileResult(ReadFileDiag.notFound);

	FILE* fd = openFile(asFilePath(uri), "rb");
	if (fd == null)
		return errno == ENOENT
			? ReadFileResult(ReadFileDiag.notFound)
			: ReadFileResult(ReadFileDiag.error);
	scope(exit) fclose(fd);

	int err = fseek(fd, 0, SEEK_END);
	if (err) todo!void("!");

	long ftellResult = ftell(fd);
	if (ftellResult < 0)
		todo!void("ftell failed");
	size_t fileSize = cast(size_t) ftellResult;
	if (fileSize == 0)
		return ReadFileResult(FileContent(newArray!(immutable ubyte)(alloc, [0])));
	else {
		ubyte[] result = allocateElements!ubyte(alloc, fileSize + 1);

		// Go back to the beginning so we can read
		int err2 = fseek(fd, 0, SEEK_SET);
		assert(err2 == 0);

		size_t nBytesRead = fread(result.ptr, ubyte.sizeof, fileSize, fd);
		assert(nBytesRead == fileSize);
		if (ferror(fd))
			todo!void("error reading file");
		result[nBytesRead] = '\0';

		return ReadFileResult(FileContent(cast(immutable) result));
	}
}

private @system FILE* openFile(FilePath path, immutable char* flags) =>
	withCStringOfFilePath(path, (in CString x) @trusted =>
		fopen(x.ptr, flags));

@trusted ExitCode writeFile(FilePath path, in string content) {
	MutOpt!(FILE*) fd = tryOpenFileForWrite(path);
	if (has(fd)) {
		scope(exit) fclose(force(fd));

		long wroteBytes = fwrite(content.ptr, char.sizeof, content.length, force(fd));
		if (wroteBytes != content.length) {
			if (wroteBytes == -1)
				todo!void("writeFile failed");
			else
				todo!void("writeFile -- didn't write all the bytes?");
		}
		return ExitCode.ok;
	} else
		return ExitCode.error;
}

private @system MutOpt!(FILE*) tryOpenFileForWrite(FilePath path) {
	FILE* fd = openFile(path, "w");
	if (fd != null)
		return someMut(fd);
	else if (errno == ENOENT) {
		Opt!FilePath par = parent(path);
		if (has(par) && makeDirectoryAndParents(force(par)) == ExitCode.ok) {
			FILE* res = openFile(path, "w");
			return res == null ? noneMut!(FILE*) : someMut(res);
		} else
			return noneMut!(FILE*);
	} else {
		printErrorCb((scope ref Writer writer) {
			writer ~= "Failed to write file ";
			writer ~= path;
			writer ~= ": ";
			writeLastError(writer);
		});
		return noneMut!(FILE*);
	}
}

@trusted FilePath getCwd() {
	TempStrForPath res = void;
	const char* cwd = getcwd(res.ptr, res.length);
	return cwd == null
		? todo!FilePath("getcwd failed")
		: parseFilePath(CString(cast(immutable) cwd));
}

@trusted FilePath getPathToThisExecutable() {
	TempStrForPath res = void;
	version (Windows) {
		HMODULE mod = GetModuleHandle(null);
		assert(mod != null);
		DWORD size = GetModuleFileNameA(mod, res.ptr, res.length);
	} else {
		long size = readlink("/proc/self/exe", res.ptr, res.length);
	}
	assert(size > 0 && size < res.length);
	res[size] = '\0';
	return parseFilePath(CString(cast(immutable) res.ptr));
}

immutable struct Signal {
	@safe @nogc pure nothrow:

	int signal;

	uint asUintForTaggedUnion() =>
		cast(uint) signal;
	static Signal fromUintForTaggedUnion(uint a) =>
		Signal(cast(int) a);
}

immutable struct ExitCodeOrSignal {
	mixin TaggedUnion!(ExitCode, Signal);
}

private ExitCode printSignalAndExit(ExitCodeOrSignal a) =>
	a.matchImpure!ExitCode(
		(in ExitCode x) =>
			x,
		(in Signal x) =>
			printErrorCb((scope ref Writer writer) {
				writer ~= "Program exited with signal ";
				writer ~= x.signal;
			}));

ExitCode runCompiler(ref TempAlloc tempAlloc, in PathAndArgs pathAndArgs) =>
	// Extern library linker arguments are already in args
	printSignalAndExit(runCommon(tempAlloc, [], pathAndArgs, isCompile: true));

ExitCode cleanupCompile(FilePath cwd, FilePath cPath, FilePath exePath) {
	version (Windows) {
		removeFileIfExists(alterExtension(exePath, Extension.ilk));
		removeFileIfExists(alterExtension(exePath, Extension.pdb));
		Symbol objBaseName = alterExtension(baseName(cPath), Extension.obj);
		return removeFileIfExists(cwd / objBaseName);
	} else
		return ExitCode.ok;
}

ExitCodeOrSignal runProgram(ref TempAlloc tempAlloc, in ExternLibraries externLibraries, in PathAndArgs pathAndArgs) =>
	runCommon(tempAlloc, externLibraries, pathAndArgs, isCompile: false);

private @trusted ExitCodeOrSignal runCommon(
	ref TempAlloc tempAlloc,
	in ExternLibraries externLibraries,
	in PathAndArgs pathAndArgs,
	bool isCompile,
) {
	CString executablePath = cStringOfFilePath(tempAlloc, pathAndArgs.path);
	version (Windows) {
		CString argsCString = windowsArgsCString(tempAlloc, executablePath, pathAndArgs.args);

		foreach (ExternLibrary x; externLibraries) {
			if (has(x.configuredDir)) {
				bool ok = withCStringOfFilePath(asFilePath(force(x.configuredDir)), (in CString x) =>
					SetDllDirectoryA(x.ptr));
				assert(ok);
			}
		}

		HANDLE stdoutRead;
		HANDLE stdoutWrite;
		HANDLE stderrRead;
		HANDLE stderrWrite;
		char[0x10000] stdoutBuf = void;
		char[0x10000] stderrBuf = void;

		if (isCompile) {
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
		}

		STARTUPINFOA startupInfo = void;
		memset(cast(ubyte*) &startupInfo, 0, STARTUPINFOA.sizeof);
		startupInfo.cb = STARTUPINFOA.sizeof;
		if (isCompile) {
			startupInfo.dwFlags = STARTF_USESTDHANDLES;
			startupInfo.hStdOutput = stdoutWrite;
			startupInfo.hStdError = stderrWrite;
		}

		PROCESS_INFORMATION processInfo;
		memset(cast(ubyte*) &processInfo, 0, PROCESS_INFORMATION.sizeof);
		int ok = CreateProcessA(
			executablePath.ptr,
			// not sure why Windows makes this mutable
			cast(char*) argsCString.ptr,
			null,
			null,
			true,
			0,
			null,
			null,
			&startupInfo,
			&processInfo);
		if (!ok) {
			printErrorCb((scope ref Writer writer) {
				writer ~= "Error spawning ";
				writer ~= argsCString;
				writer ~= '\n';
				writeLastError(writer);
			});
			return ExitCodeOrSignal(ExitCode.error);
		}

		if (isCompile) {
			verifyOk(CloseHandle(stdoutWrite));
			verifyOk(CloseHandle(stderrWrite));

			readFromPipe(stdoutBuf, stdoutRead);
			verifyOk(CloseHandle(stdoutRead));
			readFromPipe(stderrBuf, stderrRead);
			verifyOk(CloseHandle(stderrRead));
		}

		WaitForSingleObject(processInfo.hProcess, INFINITE);

		DWORD exitCode;
		int ok2 = GetExitCodeProcess(processInfo.hProcess, &exitCode);
		assert(ok2 == 1);

		if (isCompile && exitCode != 0) {
			printErrorCb((scope ref Writer writer) @trusted {
				writer ~= "Error running ";
				writer ~= argsCString;
				writer ~= "\nExit code ";
				writer ~= exitCode;
				writer ~= "\nStderr: ";
				writer ~= CString(castImmutable(stderrBuf.ptr));
				writer ~= "\nStdout: ";
				writer ~= CString(castImmutable(stdoutBuf.ptr));
			});
		}

		verifyOk(CloseHandle(processInfo.hProcess));
		verifyOk(CloseHandle(processInfo.hThread));

		return ExitCodeOrSignal(ExitCode(exitCode));
	} else {
		pid_t pid;
		int spawnStatus = posix_spawn(
			&pid,
			executablePath.ptr,
			null,
			null,
			// https://stackoverflow.com/questions/50596439/can-string-literals-be-passed-in-posix-spawns-argv
			cast(char**) convertArgs(tempAlloc, executablePath, pathAndArgs.args),
			getEnvironForChildProcess(tempAlloc, externLibraries));
		if (spawnStatus == 0) {
			int waitStatus;
			int resPid = waitpid(pid, &waitStatus, 0);
			assert(resPid == pid);
			if (WIFEXITED(waitStatus))
				return ExitCodeOrSignal(ExitCode(WEXITSTATUS(waitStatus))); // only valid if WIFEXITED
			else if (WIFSIGNALED(waitStatus))
				return ExitCodeOrSignal(Signal(__WTERMSIG(waitStatus)));
			else
				return todo!ExitCodeOrSignal("process exited non-normally");
		} else
			return todo!ExitCodeOrSignal("posix_spawn failed");
	}
}

private:

version (Windows) {
	enum RetryResult { ok, error, retry }
	@system bool withRetry(in RetryResult delegate() @nogc nothrow cb) {
		final switch (cb()) {
			case RetryResult.ok:
				return true;
			case RetryResult.error:
				return false;
			case RetryResult.retry:
				Sleep(10);
				return cb() == RetryResult.ok;
		}
	}

	extern(C) bool SetDllDirectoryA(scope LPCSTR);
}

version (Windows) {} else {
	@system pure immutable(char**) getEnvironForChildProcess(ref Alloc alloc, in ExternLibraries externLibraries) =>
		exists!ExternLibrary(externLibraries, (in ExternLibrary x) => has(x.configuredDir))
			? buildArray!(immutable char*)(alloc, (scope ref Builder!(immutable char*) res) @trusted {
				immutable(char*)* cur = __environ;
				while (*cur != null) {
					res ~= *cur;
					cur++;
				}

				res ~= withWriter(alloc, (scope ref Writer writer) {
					writer ~= "LD_LIBRARY_PATH=";
					writeWithSeparatorAndFilter!ExternLibrary(
						writer,
						externLibraries,
						";",
						(in ExternLibrary x) => has(x.configuredDir),
						(in ExternLibrary x) {
							writer ~= '/';
							writer ~= asFilePath(force(x.configuredDir));
						});
				}).ptr;

				res ~= typeAs!(immutable char*)(null);
			}).ptr
			: __environ;
}

version (Windows) {
	extern(C) char* _getcwd(char* buffer, int maxlen);
	extern(C) int _mkdir(scope const char*, immutable uint);

	alias getcwd = _getcwd;
	alias mkdir = _mkdir;
}

ExitCode makeDirectoryAndParents(FilePath dir) =>
	onError(makeDirectoryNoPrintErrors(dir), () {
		Opt!FilePath par = parent(dir);
		return errno == ENOENT && has(par)
			? okAnd(makeDirectoryAndParents(force(par)), () => makeDirectory(dir))
			: logMakeDirectoryError(dir);
	});

ExitCode makeDirectory(FilePath dir) =>
	onError(makeDirectoryNoPrintErrors(dir), () => logMakeDirectoryError(dir));

ExitCode logMakeDirectoryError(FilePath dir) =>
	printErrorCb((scope ref Writer writer) {
		writer ~= "Error making directory ";
		writer ~= dir;
		writer ~= ": ";
		writeLastError(writer);
	});

ExitCode makeDirectoryNoPrintErrors(FilePath dir) =>
	withCStringOfFilePath(dir, (in CString x) @trusted =>
		mkdir(x.ptr, octal!"700") == 0 ? ExitCode.ok : ExitCode.error);

version (Windows) {
	CString windowsArgsCString(ref Alloc alloc, in CString executablePath, in CString[] args) =>
		withWriter(alloc, (scope ref Writer writer) {
			writer ~= '"';
			writer ~= executablePath;
			writer ~= '"';
			foreach (CString arg; args) {
				writer ~= ' ';
				writer ~= arg;
			}
		});
}

void verifyOk(int ok) {
	assert(ok == 1);
}

version (Windows) {
	@system ExitCode readFromPipe(ref char[0x10000] outBuf, HANDLE pipe) {
		char* out_ = outBuf.ptr;
		char* outEnd = endPtr(outBuf);
		while (out_ + 1 != outEnd) {
			assert(out_ < outEnd);
			uint nRead;
			if (ReadFile(pipe, out_, cast(uint) (outEnd - out_ - 1), &nRead, null) == 1) {
				out_ += nRead;
				continue;
			} else if (GetLastError() == ERROR_BROKEN_PIPE)
				break;
			else
				return printErrorCb((scope ref Writer writer) {
					writer ~= "Error in readFromPipe: ";
					writeLastError(writer);
				});
		}
		*out_ = '\0';
		return ExitCode.ok;
	}
}

@system immutable(char**) convertArgs(ref Alloc alloc, in CString executable, in CString[] args) =>
	buildArray!(immutable char*)(alloc, (scope ref Builder!(immutable char*) res) {
		res ~= executable.ptr;
		foreach (CString arg; args)
			res ~= arg.ptr;
		res ~= typeAs!(immutable char*)(null);
	}).ptr;

extern(C) immutable char** __environ;

// Copying from /usr/include/dmd/druntime/import/core/sys/posix/sys/wait.d
// to avoid linking to druntime
int __WTERMSIG( int status ) { return status & 0x7F; }
int WEXITSTATUS( int status ) { return ( status & 0xFF00 ) >> 8; }
bool WIFEXITED( int status ) { return __WTERMSIG( status ) == 0; }
bool WIFSIGNALED( int status )
{
	return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
}

@trusted void writeLastError(scope ref Writer writer) {
	version (Windows) {
		DWORD error = GetLastError();
		writer ~= "Windows error ";
		writer ~= error;
		writer ~= ": ";

		char[0x400] buffer;
		int size = FormatMessageA(
			FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			null,
			error,
			0,
			buffer.ptr,
			buffer.length,
			null);
		assert(size != 0 && size < buffer.length);
		writer ~= castImmutable(buffer[0 .. size]);
	} else {
		writer ~= "Posix error ";
		writer ~= errno;
		writer ~= ": ";
		writer ~= CString(cast(immutable) strerror(errno));
	}
}

version (Windows) {
	extern(C) FILE* __acrt_iob_func(uint);
}
