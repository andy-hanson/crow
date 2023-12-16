module app.fileSystem;

@safe @nogc nothrow: // not pure

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
import frontend.storage : FileContent, ReadFileResult;
import model.diag : ReadFileDiag;
import util.alloc.alloc : Alloc, allocateElements, TempAlloc;
import util.col.array : endPtr, newArray;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.exitCode : ExitCode;
import util.memory : memset;
import util.opt : force, has, Opt, some;
import util.string : CString, cStringSize;
import util.symbol : Symbol;
import util.uri :
	AllUris,
	alterExtensionWithHex,
	asFileUri,
	FileUri,
	isFileUri,
	parent,
	parseAbsoluteFilePathAsUri,
	fileUriToTempStr,
	TempStrForPath,
	Uri;
import util.util : todo;
import util.writer : withWriter, Writer;

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

private @trusted void removeFile(in AllUris allUris, FileUri uri) {
	TempStrForPath buf = void;
	CString cStr = fileUriToTempStr(buf, allUris, uri);
	version (Windows) {
		int res = DeleteFileA(cStr.ptr);
		if (!res) todo!void("error removing file");
	} else {
		final switch (unlink(cStr.ptr)) {
			case 0:
				break;
			case -1:
				todo!void("error removing file");
		}
	}
}

/**
This doesn't create the path, 'cb' should do that.
But if it is a temp path, this deletes it after the callback finishes.
*/
ExitCode withUriOrTemp(Symbol extension)(
	ref AllUris allUris,
	Opt!Uri uri,
	Uri tempBasePath,
	in ExitCode delegate(FileUri) @safe @nogc nothrow cb,
) {
	if (has(uri)) {
		if (!isFileUri(allUris, force(uri))) {
			todo!void("message: can't use non-file URI");
			return ExitCode.error;
		} else
			return cb(asFileUri(allUris, force(uri)));
	} else {
		if (isFileUri(allUris, tempBasePath)) {
			ubyte[8] bytes = getRandomBytes();
			FileUri tempUri = alterExtensionWithHex!extension(allUris, asFileUri(allUris, tempBasePath), bytes);
			scope(exit) removeFile(allUris, tempUri);
			return cb(tempUri);
		} else
			return todo!ExitCode("need another place to put temps");
	}
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

@trusted ReadFileResult tryReadFile(ref Alloc alloc, ref AllUris allUris, Uri uri) {
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

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted ExitCode spawnAndWait(
	ref TempAlloc tempAlloc,
	in AllUris allUris,
	in CString executablePath,
	in CString[] args,
) {
	version (Windows) {
		CString argsCStr = windowsArgsCStr(tempAlloc, executablePath, args);

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
			assert(resPid == pid);
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

private:

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
	@system ExitCode handleMkdirErr(int err, CString dir) {
		if (err != 0)
			fprintf(stderr, "Error making directory %s: %s\n", dir.ptr, strerror(errno));
		return ExitCode(err);
	}
}

version (Windows) {
	CString windowsArgsCStr(
		ref Alloc alloc,
		in CString executablePath,
		in CString[] args,
	) =>
		withWriter(tempAlloc, (scope ref Writer writer) {
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

@system immutable(char**) convertArgs(ref Alloc alloc, in CString executable, in CString[] args) {
	ArrayBuilder!(immutable char*) cArgs;
	add(alloc, cArgs, executable.ptr);
	foreach (CString arg; args)
		add(alloc, cArgs, arg.ptr);
	add(alloc, cArgs, null);
	return finish(alloc, cArgs).ptr;
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
		assert(size != 0 && size < buffer.length);
		fprintf(stderr, "%s: %.*s", description, size, buffer.ptr);
	}
}

version (Windows) {
	extern(C) FILE* __acrt_iob_func(uint);
}
