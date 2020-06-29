module util.io;

@safe @nogc nothrow: // not pure

import core.stdc.errno : ENOENT, errno;
import core.stdc.stdio : fprintf, printf, SEEK_END, SEEK_SET, stderr;
import core.stdc.string : strerror;
import core.sys.posix.sys.stat : stat, stat_t;
import core.sys.posix.fcntl : open, O_CREAT, O_RDONLY, O_TRUNC, O_WRONLY, pid_t;
import core.sys.posix.spawn : posix_spawn;
import core.sys.posix.sys.wait : waitpid;
import core.sys.posix.sys.types : off_t;
import core.sys.posix.unistd : close, getcwd, lseek, read, readlink, write;
import std.process : execvpe;

import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, arrOfRange, begin, range, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : cat, map, tail;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : moveToArr, mutArrBegin, mutArrSize, newUninitializedMutArr, setAt;
import util.collection.str :
	asCStr,
	copyNulTerminatedStr,
	copyStr,
	CStr,
	emptyNulTerminatedStr,
	MutStr,
	NulTerminatedStr,
	nulTerminatedStrOfCStr,
	Str,
	strLiteral,
	strOfCStr,
	strToCStr;
import util.opt : none, Opt, some;
import util.path : AbsolutePath, parseAbsolutePath, pathToCStr;
import util.sym : AllSymbols;
import util.types : safeSizeTFromSSizeT, ssize_t;
import util.util : todo;

@trusted immutable(Bool) fileExists(immutable AbsolutePath path, immutable string extension) {
	StackAlloc temp;
	immutable CStr pathCStr = pathToCStr(temp, path, extension);
	stat_t s;
	immutable int res = stat(pathCStr, &s);
	if (res == 0)
		return True;
	else if (res == ENOENT)
		return False;
	else {
		fprintf(stderr, "fileExists of %s failed\n", pathCStr);
		return todo!Bool("fileExists failed");
	}
}

@trusted immutable(Opt!NulTerminatedStr) tryReadFile(Alloc)(
	ref Alloc alloc,
	immutable AbsolutePath path,
	immutable string extension,
) {
	alias Ret = immutable Opt!NulTerminatedStr;

	StackAlloc temp;
	immutable CStr pathCStr = pathToCStr(temp, path, extension);
	immutable int fd = open(pathCStr, O_RDONLY);
	if (fd == -1) {
		if (errno == ENOENT)
			return none!NulTerminatedStr;
		else {
			fprintf(stderr, "Failed to open file %s\n", pathCStr);
			return todo!Ret("fail");
		}
	}

	scope(exit) close(fd);

	immutable off_t fileSize = lseek(fd, 0, SEEK_END);
	if (fileSize == -1)
		return todo!Ret("lseek fialed");

	if (fileSize > 99999)
		return todo!Ret("size suspiciously large");

	if (fileSize == 0)
		return some!NulTerminatedStr(emptyNulTerminatedStr);

	// Go back to the beginning so we can read
	immutable off_t off = lseek(fd, 0, SEEK_SET);
	if (off == -1)
		return todo!Ret("lseek failed");

	assert(off == 0);

	MutStr res = newUninitializedMutArr!char(alloc, fileSize + 1); // + 1 for the '\0'
	immutable ssize_t nBytesRead = read(fd, res.mutArrBegin, fileSize);

	if (nBytesRead == -1)
		return todo!Ret("read failed");

	if (nBytesRead != fileSize)
		return todo!Ret("nBytesRead not right?");

	res.setAt(res.mutArrSize - 1, '\0');

	return some(immutable NulTerminatedStr(res.moveToArr(alloc)));
}

@trusted void writeFileSync(immutable AbsolutePath path, immutable string extension, immutable Str content) {
	immutable int fd = tryOpen(path, extension, O_CREAT | O_WRONLY | O_TRUNC, 0b110100100);
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
@trusted int spawnAndWaitSync(
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ
) {
	StackAlloc temp;
	immutable CStr executableCStr = pathToCStr(temp, executable, "");
	return spawnAndWaitSync(
		executableCStr,
		convertArgs(temp, executableCStr, args),
		convertEnviron(temp, environ));
}

// Replaces this process with the given executable.
// DOES NOT RETURN!
@trusted void replaceCurrentProcess(
	immutable AbsolutePath executable,
	immutable Arr!Str args,
	immutable Environ environ,
) {
	StackAlloc temp;
	immutable CStr executableCStr = pathToCStr(temp, executable, "");
	immutable int err = execvpe(
		executableCStr,
		convertArgs(temp, executableCStr, args),
		convertEnviron(temp, environ));
	// 'execvpe' only returns if we failed to create the process (maybe executable does not exist?)
	assert(err == -1);
	fprintf(stderr, "Failed to launch %s: error %s\n", executableCStr, strerror(errno));
	todo!void("failed to launch");
}

struct CommandLineArgs {
	immutable AbsolutePath pathToThisExecutable;
	immutable Arr!Str args;
	immutable Environ environ;
}

immutable(CommandLineArgs) parseCommandLineArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
	immutable size_t argc,
	immutable CStr* argv,
) {
	immutable Arr!CStr allArgs = immutable Arr!CStr(argv, argc);
	immutable Arr!Str args = map!(Str, CStr, Alloc)(alloc, allArgs, (ref immutable CStr a) => strOfCStr(a));
	// Take the tail because the first one is 'noze'
	return CommandLineArgs(getPathToThisExecutable(alloc, allSymbols), args.tail, getEnviron(alloc));
}

@trusted immutable(AbsolutePath) getCwd(Alloc, SymAlloc)(ref Alloc alloc, ref AllSymbols!SymAlloc allSymbols) {
	char[maxPathSize] buff;
	char* b = getcwd(buff.ptr, maxPathSize);
	if (b == null)
		return todo!AbsolutePath("getcwd failed");
	else {
		assert(b == buff.ptr);
		return parseAbsolutePath(alloc, allSymbols, copyCStrToStr(alloc, cast(immutable) buff.ptr));
	}
}

@trusted immutable(Environ) getEnviron(Alloc)(ref Alloc alloc) {
	ArrBuilder!(KeyValuePair!(Str, Str)) res;
	for (immutable(char*)* env = environ; *env != null; env++)
		res.add(alloc, parseEnvironEntry(*env));
	return res.finishArr(alloc);
}

private:

@system int tryOpen(immutable AbsolutePath path, immutable string extension, immutable int flags, immutable int moreFlags) {
	StackAlloc temp;
	immutable int fd = open(pathToCStr(temp, path, extension), flags, moreFlags);
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
		assert(resPid == pid);
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
		assert(*keyEnd != '\0');
	immutable Str key = arrOfRange(entry, keyEnd);
	// Skip the '='
	immutable CStr valueBegin = keyEnd + 1;
	immutable(char)* valueEnd = valueBegin;
	for (; *valueEnd != '\0'; valueEnd++) {}
	immutable Str value = arrOfRange(valueBegin, valueEnd);
	return immutable KeyValuePair!(Str, Str)(key, value);
}

immutable size_t maxPathSize = 1024;

@trusted immutable(AbsolutePath) getPathToThisExecutable(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref AllSymbols!SymAlloc allSymbols,
) {
	char[maxPathSize] buff;
	immutable ssize_t size = readlink("/proc/self/exe", buff.ptr, maxPathSize);
	if (size < 0)
		todo!void("posix error");
	return parseAbsolutePath(alloc, allSymbols, copyStr(alloc, immutable Str(cast(immutable) buff.ptr, safeSizeTFromSSizeT(size))));
}

// Return should be const, but some posix functions aren't marked that way
@system immutable(CStr*) convertArgs(Alloc)(ref Alloc alloc, immutable CStr executableCStr, immutable Arr!Str args) {
	ArrBuilder!CStr cArgs;
	// Make a mutable copy
	immutable CStr executableCopy = copyCStr(alloc, executableCStr);
	cArgs.add(alloc, executableCopy);
	foreach (immutable Str arg; args.range)
		cArgs.add(alloc, strToCStr(alloc, arg));
	cArgs.add(alloc, null);
	return cArgs.finishArr(alloc).begin;
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
		cEnviron.add(alloc, s.str.begin);
	}
	cEnviron.add(alloc, null);
	return cEnviron.finishArr(alloc).begin;
}

// D doesn't declare this anywhere for some reason
extern(C) int execvpe(const char *__file, const char ** __argv, const char ** __envp);
immutable char** environ;

// Copying from /usr/include/dmd/druntime/import/core/sys/posix/sys/wait.d
// to avoid linking to druntime
int __WTERMSIG( int status ) { return status & 0x7F; }
int  WEXITSTATUS( int status )  { return ( status & 0xFF00 ) >> 8;   }
bool WIFEXITED( int status )    { return __WTERMSIG( status ) == 0;  }
bool WIFSIGNALED( int status )
{
	return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
}


