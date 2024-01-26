module app.fileSystem;

@safe @nogc nothrow: // not pure

import app.appUtil : printError;
import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fclose, ferror, FILE, fopen, fprintf, fread, fseek, ftell, fwrite, printf, SEEK_END, SEEK_SET;
version (Windows) {} else {
	import core.stdc.stdio : posixStderr = stderr, posixStdin = stdin, posixStdout = stdout;
}
import core.stdc.string : strerror;

version (Windows) {
	import core.sys.windows.core :
		CloseHandle,
		CreatePipe,
		CreateProcessA,
		DeleteFileA,
		DWORD,
		ERROR_BROKEN_PIPE,
		FormatMessageA,
		FORMAT_MESSAGE_FROM_SYSTEM,
		FORMAT_MESSAGE_IGNORE_INSERTS,
		GetExitCodeProcess,
		GetLastError,
		GetModuleFileNameA,
		GetModuleHandle,
		HANDLE,
		HANDLE_FLAG_INHERIT,
		HMODULE,
		INFINITE,
		PROCESS_INFORMATION,
		ReadFile,
		SearchPathA,
		SECURITY_ATTRIBUTES,
		SetHandleInformation,
		STARTF_USESTDHANDLES,
		STARTUPINFOA,
		WaitForSingleObject;
} else {
	import core.sys.posix.spawn : posix_spawn;
	import core.sys.posix.sys.wait : waitpid;
	import core.sys.posix.sys.stat : mkdir, pid_t, S_IRWXU;
	import core.sys.posix.unistd : getcwd, read, readlink, unlink;
}

import backend.writeToC : PathAndArgs;
import frontend.storage : FileContent, ReadFileResult;
import model.diag : ReadFileDiag;
import model.lowModel : ExternLibrary, ExternLibraries;
import util.alloc.alloc : Alloc, allocateElements, TempAlloc;
import util.col.array : endPtr, exists, newArray;
import util.col.arrayBuilder : buildArray, Builder;
import util.exitCode : ExitCode, okAnd;
import util.memory : memset;
import util.opt : force, has, none, Opt, some;
import util.string : CString, cString, cStringSize;
import util.symbol : AllSymbols, Extension;
import util.union_ : TaggedUnion;
import util.uri :
	AllUris,
	alterExtensionWithHex,
	asFileUri,
	cStringOfFileUri,
	FileUri,
	fileUriToTempStr,
	isFileUri,
	parent,
	parseAbsoluteFilePathAsUri,
	parseFileUri,
	TempStrForPath,
	Uri,
	writeFileUri;
import util.util : todo, typeAs;
import util.writer : withStackWriter, withWriter, Writer, writeWithSeparatorAndFilter;

FILE* stdin() {
	version (Windows) {
		return __acrt_iob_func(0);
	} else {
		return posixStdin;
	}
}

FILE* stdout() {
	version (Windows) {
		return __acrt_iob_func(1);
	} else {
		return posixStdout;
	}
}

FILE* stderr() {
	version (Windows) {
		return __acrt_iob_func(2);
	} else {
		return posixStderr;
	}
}

private @trusted ExitCode removeFile(in AllUris allUris, FileUri uri) {
	TempStrForPath buf = void;
	CString cString = fileUriToTempStr(buf, allUris, uri);
	version (Windows) {
		return DeleteFileA(cString.ptr)
			? ExitCode.ok
			: printErrorForFile("Error removing file", allUris, uri);
	} else {
		final switch (unlink(cString.ptr)) {
			case 0:
				return ExitCode.ok;
			case -1:
				return errno == ENOENT
					? ExitCode.ok
					: printErrorForFile("Error removing file", allUris, uri);
		}
	}
}

/**
This doesn't create the path, 'cb' should do that.
But if it is a temp path, this deletes it after the callback finishes.
*/
ExitCode withUriOrTemp(
	ref AllUris allUris,
	Opt!FileUri uri,
	Uri tempBasePath,
	Extension extension,
	in ExitCode delegate(FileUri) @safe @nogc nothrow cb,
) =>
	has(uri)
		? cb(force(uri))
		: withTempUri(allUris, tempBasePath, extension, cb);

ExitCode withTempUri(
	ref AllUris allUris,
	Uri tempBasePath,
	Extension extension,
	in ExitCode delegate(FileUri) @safe @nogc nothrow cb,
) {
	ubyte[8] bytes = getRandomBytes();
	FileUri tempUri = alterExtensionWithHex(allUris, asFileUri(allUris, tempBasePath), bytes, extension);
	ExitCode exit = cb(tempUri);
	ExitCode exit2 = removeFile(allUris, tempUri);
	return okAnd(exit, () => exit2);
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
		static assert(false); // TODO
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

@trusted Opt!FileUri findPathToCCompiler(scope ref AllUris allUris) {
	version (Windows) {
		TempStrForPath res = void;
		int len = SearchPathA(null, "cl.exe", null, cast(uint) res.length, res.ptr, null);
		if (len == 0) {
			fprintf(stderr, "Could not find cl.exe on path. Be sure you are using a Native Tools Command Prompt.");
			return none!CString;
		} else
			return some(parseFileUri(CString(cast(immutable) res.ptr)));
	} else
		return some(parseFileUri(allUris, cString!"/usr/bin/cc"));
}

@trusted ReadFileResult tryReadFile(ref Alloc alloc, scope ref AllUris allUris, Uri uri) {
	if (!isFileUri(allUris, uri))
		return ReadFileResult(ReadFileDiag.notFound);

	TempStrForPath pathBuf = void;
	FILE* fd = fopen(fileUriToTempStr(pathBuf, allUris, asFileUri(allUris, uri)).ptr, "rb");
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

@trusted ExitCode writeFile(in AllUris allUris, FileUri uri, in CString content) {
	FILE* fd = tryOpenFileForWrite(allUris, uri);
	if (fd == null)
		return ExitCode.error;
	else {
		scope(exit) fclose(fd);

		size_t size = cStringSize(content);
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

private @system FILE* tryOpenFileForWrite(in AllUris allUris, FileUri uri) {
	TempStrForPath buf = void;
	CString pathStr = fileUriToTempStr(buf, allUris, uri);
	FILE* fd = fopen(pathStr.ptr, "w");
	if (fd == null) {
		if (errno == ENOENT) {
			Opt!FileUri par = parent(allUris, uri);
			if (has(par)) {
				ExitCode res = mkdirRecur(allUris, force(par));
				if (res == ExitCode.ok)
					return fopen(pathStr.ptr, "w");
			}
		} else {
			fprintf(stderr, "Failed to write file %s: %s\n", pathStr.ptr, strerror(errno));
		}
	}
	return fd;
}

@trusted FileUri getCwd(ref AllUris allUris) {
	TempStrForPath res = void;
	const char* cwd = getcwd(res.ptr, res.length);
	return cwd == null
		? todo!FileUri("getcwd failed")
		: parseAbsoluteFilePathAsUri(allUris, CString(cast(immutable) cwd));
}

@trusted FileUri getPathToThisExecutable(ref AllUris allUris) {
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
	return parseAbsoluteFilePathAsUri(allUris, CString(cast(immutable) res.ptr));
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

ExitCode printSignalAndExit(ExitCodeOrSignal a) =>
	a.matchImpure!ExitCode(
		(in ExitCode x) =>
			x,
		(in Signal x) =>
			printError(withStackWriter((scope ref Alloc _, scope ref Writer writer) {
				writer ~= "Program exited with signal ";
				writer ~= x.signal;
			})));

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted ExitCodeOrSignal spawnAndWait(
	ref TempAlloc tempAlloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	in ExternLibraries externLibraries,
	in PathAndArgs pathAndArgs,
) {
	CString executablePath = cStringOfFileUri(tempAlloc, allUris, pathAndArgs.path);
	version (Windows) {
		CString argsCString = windowsArgsCString(tempAlloc, executablePath, pathAndArgs.args);

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
		static assert(false); // TODO: environment for extern libraries?
		int ok = CreateProcessA(
			executablePath.ptr,
			// not sure why Windows makes this mutable
			cast(char*) argsCString,
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
			return ExitCode.error;
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
			fprintf(stderr, "Error invoking C compiler: %s\n", argsCString);
			fprintf(stderr, "Exit code %d\n", exitCode);
			fprintf(stderr, "C compiler stderr: %s\n", stderrBuf.ptr);
			printf("C compiler stdout: %s\n", stdoutBuf.ptr);
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
			getEnvironForChildProcess(tempAlloc, allSymbols, allUris, externLibraries));
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

version (Windows) {} else {
	@system immutable(char**) getEnvironForChildProcess(
		ref Alloc alloc,
		scope ref AllSymbols allSymbols,
		scope ref AllUris allUris,
		in ExternLibraries externLibraries,
	) =>
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
							writeFileUri(writer, allUris, asFileUri(allUris, force(x.configuredDir)));
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

@system ExitCode mkdirRecur(in AllUris allUris, FileUri dir) {
	version (Windows) {
		return todo!ExitCode("!");
	} else {
		TempStrForPath buf = void;
		CString dirStr = fileUriToTempStr(buf, allUris, dir);
		int err = mkdir(dirStr.ptr, S_IRWXU);
		if (err == ENOENT) {
			Opt!FileUri par = parent(allUris, dir);
			if (has(par)) {
				ExitCode res = mkdirRecur(allUris, force(par));
				return res == ExitCode.ok
					? handleMkdirErr(mkdir(dirStr.ptr, S_IRWXU), dirStr)
					: res;
			}
		}
		return handleMkdirErr(err, dirStr);
	}
}

version (Windows) {
} else {
	@system ExitCode handleMkdirErr(int err, CString dir) =>
		err == 0 ? ExitCode.ok : printErrno("Error making directory", dir);

	@system ExitCode printErrno(string description, CString file) {
		fprintf(stderr, "%.*s %s: %s\n", cast(int) description.length, description.ptr, file.ptr, strerror(errno));
		return ExitCode.error;
	}
}

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
	@system void readFromPipe(ref char[0x10000] out_, HANDLE pipe) {
		readFromPipeRecur(out_.ptr, endPtr(out_), pipe);
	}

	@system void readFromPipeRecur(char* out_, char* outEnd, HANDLE pipe) {
		assert(out_ < outEnd);
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

version (Windows) {
	@system void printLastError(int error, CString description) {
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
		fprintf(stderr, "%s: %.*s", description, size, buffer.ptr);
	}
}

version (Windows) {
	extern(C) FILE* __acrt_iob_func(uint);
}

ExitCode printErrorForFile(string description, in AllUris allUris, FileUri uri) =>
	printError(withStackWriter((scope ref Alloc _, scope ref Writer writer) {
		writer ~= description;
		writeFileUri(writer, allUris, uri);
	}));
