module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import interpret.bytecode : Operation;
import interpret.extern_ :
	DynCallSig,
	Extern,
	ExternFunPtrsForAllLibraries,
	ExternFunPtrsForLibrary,
	FunPtr,
	FunPtrInputs,
	WriteError,
	writeSymToCb;
import interpret.runBytecode : syntheticCall;
import interpret.stacks : dataPush, Stacks;
import lib.compiler : ExitCode;
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.arrUtil : map;
import util.col.dict : KeyValuePair, makeDict;
import util.col.mutArr : moveToArr, MutArr, mutArrIsEmpty, push, pushAll, tempAsArr;
import util.col.str : safeCStr;
import util.memory : memmove, memset;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, shortSym, shortSymValue, SpecialSym, specialSymValue, Sym;
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
		(scope immutable ExternLibraries libraries, scope WriteError writeError) =>
			getAllFakeExternFuns(alloc, allSymbols, libraries, writeError),
		(scope immutable FunPtrInputs[] inputs) =>
			fakeSyntheticFunPtrs(alloc, inputs),
		(immutable FunPtr ptr, scope immutable DynCallSig sig, scope immutable ulong[] args) =>
			callFakeExternFun(alloc, std, ptr.fn, sig, args));
	immutable ExitCode err = cb(extern_, std);
	return immutable FakeExternResult(err, moveToArr(alloc, std.stdout), moveToArr(alloc, std.stderr));
}

pure immutable(FunPtr[]) fakeSyntheticFunPtrs(ref Alloc alloc, scope immutable FunPtrInputs[] inputs) =>
	map(alloc, inputs, (ref immutable FunPtrInputs x) =>
		immutable FunPtr(x.operationPtr));

private:

immutable(Opt!ExternFunPtrsForAllLibraries) getAllFakeExternFuns(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable ExternLibraries libraries,
	scope WriteError writeError,
) {
	MutArr!(immutable KeyValuePair!(Sym, Sym)) failures;
	immutable ExternFunPtrsForAllLibraries res = makeDict!(Sym, ExternFunPtrsForLibrary, ExternLibrary)(
		alloc,
		libraries,
		(scope ref immutable ExternLibrary x) =>
			immutable KeyValuePair!(Sym, ExternFunPtrsForLibrary)(
				x.libraryName,
				fakeExternFunsForLibrary(alloc, failures, allSymbols, x)));
	foreach (immutable KeyValuePair!(Sym, Sym) x; tempAsArr(failures)) {
		writeError(safeCStr!"Could not load extern function ");
		writeSymToCb(writeError, allSymbols, x.value);
		writeError(safeCStr!" from library ");
		writeSymToCb(writeError, allSymbols, x.key);
		writeError(safeCStr!"\n");
	}
	return mutArrIsEmpty(failures) ? some(res) : none!ExternFunPtrsForAllLibraries;
}

@system immutable(ulong) callFakeExternFun(
	ref Alloc alloc,
	scope ref FakeStdOutput std,
	immutable void* ptr,
	scope immutable DynCallSig sig,
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
		return syntheticCall(sig, cast(immutable Operation*) ptr, (ref Stacks stacks) {
			dataPush(stacks, args);
		});
}

pure:

immutable(ExternFunPtrsForLibrary) fakeExternFunsForLibrary(
	ref Alloc alloc,
	ref MutArr!(immutable KeyValuePair!(Sym, Sym)) failures,
	ref const AllSymbols allSymbols,
	scope ref immutable ExternLibrary lib,
) =>
	makeDict!(Sym, FunPtr, Sym)(alloc, lib.importNames, (scope ref immutable Sym importName) {
		immutable Opt!FunPtr res = getFakeExternFun(lib.libraryName, importName);
		if (!has(res))
			push(alloc, failures, immutable KeyValuePair!(Sym, Sym)(lib.libraryName, importName));
		return immutable KeyValuePair!(Sym, FunPtr)(importName, has(res) ? force(res) : immutable FunPtr(null));
	});

immutable(Opt!FunPtr) getFakeExternFun(immutable Sym libraryName, immutable Sym name) =>
	libraryName == shortSym("c")
		? getFakeExternFunC(name)
		: none!FunPtr;

immutable(Opt!FunPtr) getFakeExternFunC(immutable Sym name) {
	switch (name.value) {
		case shortSymValue("abort"):
			return some!FunPtr(immutable FunPtr(&abort));
		case specialSymValue(SpecialSym.clock_gettime):
			return some!FunPtr(immutable FunPtr(&clockGetTime));
		case shortSymValue("free"):
			return some!FunPtr(immutable FunPtr(&free));
		case shortSymValue("nanosleep"):
			return some!FunPtr(immutable FunPtr(&nanosleep));
		case shortSymValue("malloc"):
			return some!FunPtr(immutable FunPtr(&malloc));
		case shortSymValue("memcpy"):
		case shortSymValue("memmove"):
			return some!FunPtr(immutable FunPtr(&memmove));
		case shortSymValue("memset"):
			return some!FunPtr(immutable FunPtr(&memset));
		case shortSymValue("write"):
			return some!FunPtr(immutable FunPtr(&write));
		case shortSymValue("longjmp"):
		case shortSymValue("setjmp"):
			// these are treated specially by the interpreter
			return some!FunPtr(immutable FunPtr(&unreachable!void));
		default:
			return none!FunPtr;
	}
}

// Just used as fake funtion pointers, actual implementation in callFakeExternFun
void free() {}
void malloc() {}
void write() {}

void abort() {
	debugLog("program aborted");
	verifyFail();
}

immutable(int) clockGetTime(immutable(int), const(void*)) =>
	todo!(immutable int)("");

immutable(int) nanosleep(const(void*), void*) =>
	todo!(immutable int)("!");
