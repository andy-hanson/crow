module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ : DynCallSig, Extern, FunPtr;
import lib.compiler : ExitCode;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.mutArr : moveToArr, MutArr, pushAll;
import util.memory : memmove, memset;
import util.sym : AllSymbols, safeCStrOfSym, shortSymValue, SpecialSym, specialSymValue, Sym;
import util.util : debugLog, todo, unreachable, verify, verifyFail;

struct FakeExternResult {
	immutable ExitCode err;
	immutable string stdout;
	immutable string stderr;
}

struct FakeStdOutput {
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
}

immutable(FakeExternResult) withFakeExtern(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable(ExitCode) delegate(
		scope ref Extern,
		scope ref FakeStdOutput,
	) @safe @nogc nothrow cb,
) {
	scope FakeStdOutput std;
	scope Extern extern_ = Extern(
		(immutable Sym name) =>
			getFakeExternFun(alloc, allSymbols, name),
		(FunPtr ptr, scope immutable(DynCallSig), scope immutable ulong[] args) =>
			callFakeExternFun(alloc, std, ptr, args));
	immutable ExitCode err = cb(extern_, std);
	return immutable FakeExternResult(err, moveToArr(alloc, std.stdout), moveToArr(alloc, std.stderr));
}

private:

immutable(FunPtr) getFakeExternFun(ref Alloc alloc, ref const AllSymbols allSymbols, immutable Sym name) {
	switch (name.value) {
		case shortSymValue("abort"):
			return &abort;
		case specialSymValue(SpecialSym.clock_gettime):
			return &clockGetTime;
		case shortSymValue("free"):
			return &free;
		case shortSymValue("nanosleep"):
			return &nanosleep;
		case shortSymValue("malloc"):
			return &malloc;
		case shortSymValue("memcpy"):
		case shortSymValue("memmove"):
			return &memmove;
		case shortSymValue("memset"):
			return &memset;
		case shortSymValue("write"):
			return &write;
		default:
			debugLog("Can't call extern function from fake extern:");
			debugLog(safeCStrOfSym(alloc, allSymbols, name).ptr);
			return todo!(immutable FunPtr)("not for fake");
	}
}

@system immutable(ulong) callFakeExternFun(
	ref Alloc alloc,
	scope ref FakeStdOutput std,
	immutable FunPtr ptr,
	scope immutable ulong[] args,
) {
	if (ptr == &free) {
		verify(args.length == 1);
		return 0;
	} else if (ptr == &malloc) {
		verify(args.length == 1);
		return cast(immutable ulong) allocateBytes(alloc, cast(immutable size_t) args[0]);
	} else if (ptr == &memmove) {
		verify(args.length == 3);
		return cast(immutable ulong) memmove(
			cast(ubyte*) args[0],
			cast(const ubyte*) args[1],
			cast(immutable size_t) args[2]);
	} else if (ptr == &memset) {
		verify(args.length == 3);
		return cast(immutable ulong) memset(
			cast(ubyte*) args[0],
			cast(immutable ubyte) args[1],
			cast(immutable size_t) args[2]);
	} else if (ptr == &write) {
		verify(args.length == 3);
		immutable int fd = cast(immutable int) args[0];
		immutable char* buf = cast(immutable char*) args[1];
		immutable size_t nBytes = cast(immutable size_t) args[2];
		verify(fd == 1 || fd == 2);
		pushAll!char(alloc, fd == 1 ? std.stdout : std.stderr, buf[0 .. nBytes]);
		return nBytes;
	} else
		return unreachable!(immutable ulong)();
}

// Just used as fake funtion pointers, actual implementation in callFakeExternFun
void free() {}
void malloc() {}
void write() {}


void abort() {
	debugLog("program aborted");
	verifyFail();
}

immutable(int) clockGetTime(immutable(int), const(void*)) {
	return todo!(immutable int)("");
}

immutable(int) nanosleep(const(void*), void*) {
	return todo!(immutable int)("!");
}
