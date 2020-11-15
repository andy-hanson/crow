module io.io;

@safe @nogc nothrow: // not pure

import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fprintf, printf, SEEK_END, SEEK_SET, stderr;
import core.stdc.string : strerror;
import core.sys.posix.fcntl : open, O_CREAT, O_RDONLY, O_TRUNC, O_WRONLY, pid_t;
import core.sys.posix.spawn : posix_spawn;
import core.sys.posix.sys.wait : waitpid;
import core.sys.posix.sys.types : off_t;
import core.sys.posix.unistd : close, getcwd, lseek, read, readlink, write;
import std.process : execvpe;

import util.collection.arr : Arr, arrOfRange, begin, range, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : cat, map, tail;
import util.collection.dict : KeyValuePair;
import util.collection.str :
	asCStr,
	copyNulTerminatedStr,
	copyStr,
	CStr,
	emptyNulTerminatedStr,
	NulTerminatedStr,
	nulTerminatedStrOfCStr,
	Str,
	strLiteral,
	strOfCStr,
	strToCStr;
import util.opt : none, Opt, some;
import util.path : AbsolutePath, pathToCStr;
import util.types : safeSizeTFromSSizeT, ssize_t;
import util.util : todo, verify;

@trusted immutable(T) tryReadFile(T, Alloc, TempAlloc)(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	immutable AbsolutePath path,
	scope immutable(T) delegate(ref immutable Opt!NulTerminatedStr) @safe @nogc nothrow cb,
) {
	immutable CStr pathCStr = pathToCStr(tempAlloc, path);

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

	immutable off_t fileSize = lseek(fd, 0, SEEK_END);
	if (fileSize == -1)
		return todo!T("lseek fialed");

	if (fileSize > 99_999)
		return todo!T("size suspiciously large");

	if (fileSize == 0) {
		immutable Opt!NulTerminatedStr s = some(emptyNulTerminatedStr);
		return cb(s);
	}

	// Go back to the beginning so we can read
	immutable off_t off = lseek(fd, 0, SEEK_SET);
	if (off == -1)
		return todo!T("lseek failed");

	verify(off == 0);

	immutable size_t contentSize = fileSize + 1;
	char* content = cast(char*) alloc.allocate(char.sizeof * contentSize); // + 1 for the '\0'
	scope (exit) alloc.free(cast(ubyte*) content, char.sizeof * contentSize);
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

@trusted void writeFileSync(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable AbsolutePath path,
	ref immutable Str content,
) {
	immutable int fd = tryOpen(tempAlloc, path, O_CREAT | O_WRONLY | O_TRUNC, 0b110_100_100);
	scope(exit) close(fd);

	immutable ssize_t wroteBytes = write(fd, content.begin, content.size);
	if (wroteBytes != content.size)
		if (wroteBytes == -1)
			todo!void("writeFile failed");
		else
			todo!void("writeFile -- didn't write all the bytes?");
}

alias Environ = Arr!(KeyValuePair!(Str, Str));

// Returns the child process' error code.
// WARN: A first arg will be prepended that is the executable path.
@trusted int spawnAndWaitSync(TempAlloc)(
	ref TempAlloc tempAlloc,
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ
) {
	immutable CStr executableCStr = pathToCStr(tempAlloc, executable);
	return spawnAndWaitSync(
		executableCStr,
		convertArgs(tempAlloc, executableCStr, args),
		convertEnviron(tempAlloc, environ));
}

// Replaces this process with the given executable.
// DOES NOT RETURN!
@trusted void replaceCurrentProcess(TempAlloc)(
	ref TempAlloc tempAlloc,
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ,
) {
	immutable CStr executableCStr = pathToCStr(tempAlloc, executable);
	immutable int err = execvpe(
		executableCStr,
		convertArgs(tempAlloc, executableCStr, args),
		convertEnviron(tempAlloc, environ));
	// 'execvpe' only returns if we failed to create the process (maybe executable does not exist?)
	verify(err == -1);
	fprintf(stderr, "Failed to launch %s: error %s\n", executableCStr, strerror(errno));
	todo!void("failed to launch");
}

struct CommandLineArgs {
	immutable Str pathToThisExecutable;
	immutable Arr!Str args;
	immutable Environ environ;
}

immutable(CommandLineArgs) parseCommandLineArgs(Alloc)(
	ref Alloc alloc,
	immutable size_t argc,
	immutable CStr* argv,
) {
	immutable Arr!CStr allArgs = immutable Arr!CStr(argv, argc);
	immutable Arr!Str args = map!(Str, CStr, Alloc)(alloc, allArgs, (ref immutable CStr a) => strOfCStr(a));
	// Take the tail because the first one is 'noze'
	return CommandLineArgs(getPathToThisExecutable(alloc), args.tail, getEnviron(alloc));
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

private:

@trusted immutable(Environ) getEnviron(Alloc)(ref Alloc alloc) {
	ArrBuilder!(KeyValuePair!(Str, Str)) res;
	for (immutable(char*)* env = cast(immutable) environ; *env != null; env++)
		add(alloc, res, parseEnvironEntry(*env));
	return finishArr(alloc, res);
}

@system int tryOpen(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable AbsolutePath path,
	immutable int flags,
	immutable int moreFlags,
) {
	immutable int fd = open(pathToCStr(tempAlloc, path), flags, moreFlags);
	if (fd == -1)
		todo!void("can't write to file");
	return fd;
}

immutable(Str) copyCStrToStr(Alloc)(ref Alloc alloc, immutable CStr begin) {
	return copyStr(alloc, strOfCStr(begin));
}

immutable(CStr) copyCStr(Alloc)(ref Alloc alloc, immutable CStr begin) {
	return copyNulTerminatedStr(alloc, nulTerminatedStrOfCStr(begin)).asCStr();
}

@system void printArgs(immutable CStr* args) {
	for (immutable(CStr)* arg = args; arg != null; arg++)
		printf("%s ", *arg);
}

@trusted immutable(int) spawnAndWaitSync(immutable CStr executablePath, immutable CStr* args, immutable CStr* environ) {
	// TODO: KILL (debugging)
	if (false) {
		printf("Executing: %s ", executablePath);
		printArgs(args);
		printf("\nEnviron: ");
		printArgs(environ);
		printf("\n");
	}

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

@system immutable(KeyValuePair!(Str, Str)) parseEnvironEntry(immutable CStr entry) {
	immutable(char)* keyEnd = entry;
	for (; *keyEnd != '='; keyEnd++)
		verify(*keyEnd != '\0');
	immutable Str key = arrOfRange(entry, keyEnd);
	// Skip the '='
	immutable CStr valueBegin = keyEnd + 1;
	immutable(char)* valueEnd = valueBegin;
	for (; *valueEnd != '\0'; valueEnd++) {}
	immutable Str value = arrOfRange(valueBegin, valueEnd);
	return immutable KeyValuePair!(Str, Str)(key, value);
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
	foreach (immutable Str arg; args.range)
		add(alloc, cArgs, strToCStr(alloc, arg));
	add(alloc, cArgs, null);
	return finishArr(alloc, cArgs).begin;
}

@system immutable(CStr*) convertEnviron(Alloc)(ref Alloc alloc, immutable Environ environ) {
	ArrBuilder!CStr cEnviron;
	foreach (ref immutable KeyValuePair!(Str, Str) pair; environ.range) {
		immutable NulTerminatedStr s = immutable NulTerminatedStr(cat(
			alloc,
			pair.key,
			strLiteral("="),
			pair.value,
			strLiteral("\0")));
		add(alloc, cEnviron, s.str.begin);
	}
	add(alloc, cEnviron, null);
	return finishArr(alloc, cEnviron).begin;
}

// D doesn't declare this anywhere for some reason
extern(C) int execvpe(const char *__file, const char ** __argv, const char ** __envp);
extern(C) extern immutable char** environ;

// Copying from /usr/include/dmd/druntime/import/core/sys/posix/sys/wait.d
// to avoid linking to druntime
int __WTERMSIG( int status ) { return status & 0x7F; }
int  WEXITSTATUS( int status )  { return ( status & 0xFF00 ) >> 8;   }
bool WIFEXITED( int status )    { return __WTERMSIG( status ) == 0;  }
bool WIFSIGNALED( int status )
{
	return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
}
