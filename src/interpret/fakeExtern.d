module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ : DynCallType, Extern, FunPtr;
import lib.compiler : ExitCode;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.mutArr : moveToArr, MutArr, pushAll;
import util.sym : AllSymbols, safeCStrOfSym, shortSymValue, SpecialSym, specialSymValue, Sym;
import util.util : debugLog, todo, verify, verifyFail;

struct FakeExternResult {
	immutable ExitCode err;
	immutable string stdout;
	immutable string stderr;
}

immutable(FakeExternResult) withFakeExtern(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
	scope Extern extern_ = Extern(
		(ubyte* ptr) {
			// TODO: free
		},
		(immutable size_t size) {
			return allocateBytes(alloc, size);
		},
		(immutable int fd, immutable char* buf, immutable size_t nBytes) {
			immutable char[] arr = buf[0 .. nBytes];
			verify(fd == 1 || fd == 2);
			pushAll!char(alloc, fd == 1 ? stdout : stderr, arr);
			return nBytes;
		},
		(immutable Sym name) =>
			getFakeExternFun(alloc, allSymbols, name),
		(FunPtr, immutable(DynCallType), scope immutable ulong[], scope immutable DynCallType[]) =>
			todo!(immutable ulong)("not for fake"));
	immutable ExitCode err = cb(extern_);
	return immutable FakeExternResult(err, moveToArr(alloc, stdout), moveToArr(alloc, stderr));
}

private:

immutable(FunPtr) getFakeExternFun(ref Alloc alloc, ref const AllSymbols allSymbols, immutable Sym name) {
	switch (name.value) {
		case shortSymValue("abort"):
			return cast(immutable FunPtr) &abort;
		case specialSymValue(SpecialSym.clock_gettime):
			return cast(immutable FunPtr) &clockGetTime;
		case shortSymValue("nanosleep"):
			return cast(immutable FunPtr) &nanosleep;
		default:
			debugLog("Can't call extern function from fake extern:");
			debugLog(safeCStrOfSym(alloc, allSymbols, name).ptr);
			return todo!FunPtr("not for fake");
	}
}

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
