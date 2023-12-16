module interpret.fakeExtern;

@safe @nogc nothrow: // not pure

import lib.lsp.lspTypes : Pipe;
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
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.arrUtil : map;
import util.col.map : KeyValuePair, makeMap;
import util.col.mutArr : MutArr, mutArrIsEmpty, push, tempAsArr;
import util.memory : memmove, memset;
import util.opt : force, has, none, Opt, some;
import util.string : cString;
import util.sym : AllSymbols, Sym, sym;
import util.util : debugLog, todo, unreachable;

alias WriteCb = void delegate(Pipe, in string);

WriteCb unreachableWriteCb() =>
	(Pipe _, in string _1) => unreachable!void;

T withFakeExtern(T)(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	in WriteCb write,
	in T delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	scope Extern extern_ = Extern(
		(in ExternLibraries libraries, scope WriteError writeError) =>
			getAllFakeExternFuns(alloc, allSymbols, libraries, writeError),
		(in FunPtrInputs[] inputs) =>
			fakeSyntheticFunPtrs(alloc, inputs),
		(FunPtr ptr, in DynCallSig sig, in ulong[] args) =>
			callFakeExternFun(alloc, write, ptr.fn, sig, args));
	return cb(extern_);
}

pure FunPtr[] fakeSyntheticFunPtrs(ref Alloc alloc, in FunPtrInputs[] inputs) =>
	map(alloc, inputs, (ref FunPtrInputs x) =>
		FunPtr(x.operationPtr));

private:

Opt!ExternFunPtrsForAllLibraries getAllFakeExternFuns(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in ExternLibraries libraries,
	scope WriteError writeError,
) {
	MutArr!(immutable KeyValuePair!(Sym, Sym)) failures;
	ExternFunPtrsForAllLibraries res = makeMap!(Sym, ExternFunPtrsForLibrary, ExternLibrary)(
		alloc, libraries, (in ExternLibrary x) =>
			immutable KeyValuePair!(Sym, ExternFunPtrsForLibrary)(
				x.libraryName,
				fakeExternFunsForLibrary(alloc, failures, allSymbols, x)));
	foreach (KeyValuePair!(Sym, Sym) x; tempAsArr(failures)) {
		writeError(cString!"Could not load extern function ");
		writeSymToCb(writeError, allSymbols, x.value);
		writeError(cString!" from library ");
		writeSymToCb(writeError, allSymbols, x.key);
		writeError(cString!"\n");
	}
	return mutArrIsEmpty(failures) ? some(res) : none!ExternFunPtrsForAllLibraries;
}

@system ulong callFakeExternFun(
	ref Alloc alloc,
	in WriteCb writeCb,
	immutable void* ptr,
	in DynCallSig sig,
	in ulong[] args,
) {
	if (ptr == &free) {
		assert(args.length == 1);
		return 0;
	} else if (ptr == &malloc) {
		assert(args.length == 1);
		return cast(ulong) allocateBytes(alloc, cast(size_t) args[0]).ptr;
	} else if (ptr == &memmove) {
		assert(args.length == 3);
		return cast(ulong) memmove(cast(ubyte*) args[0], cast(const ubyte*) args[1], cast(size_t) args[2]);
	} else if (ptr == &memset) {
		assert(args.length == 3);
		return cast(ulong) memset(cast(ubyte*) args[0], cast(ubyte) args[1], cast(size_t) args[2]);
	} else if (ptr == &write) {
		assert(args.length == 3);
		int fd = cast(int) args[0];
		immutable char* buf = cast(immutable char*) args[1];
		size_t nBytes = cast(size_t) args[2];
		assert(fd == 1 || fd == 2);
		Pipe pipe = fd == 1 ? Pipe.stdout : Pipe.stderr;
		writeCb(pipe, buf[0 .. nBytes]);
		return nBytes;
	} else
		return syntheticCall(sig, cast(Operation*) ptr, (ref Stacks stacks) {
			dataPush(stacks, args);
		});
}

pure:

ExternFunPtrsForLibrary fakeExternFunsForLibrary(
	ref Alloc alloc,
	ref MutArr!(immutable KeyValuePair!(Sym, Sym)) failures,
	in AllSymbols allSymbols,
	in ExternLibrary lib,
) =>
	makeMap!(Sym, FunPtr, Sym)(alloc, lib.importNames, (in Sym importName) {
		Opt!FunPtr res = getFakeExternFun(lib.libraryName, importName);
		if (!has(res))
			push(alloc, failures, KeyValuePair!(Sym, Sym)(lib.libraryName, importName));
		return immutable KeyValuePair!(Sym, FunPtr)(importName, has(res) ? force(res) : FunPtr(null));
	});

Opt!FunPtr getFakeExternFun(Sym libraryName, Sym name) =>
	libraryName == sym!"c"
		? getFakeExternFunC(name)
		: none!FunPtr;

Opt!FunPtr getFakeExternFunC(Sym name) {
	switch (name.value) {
		case sym!"abort".value:
			return some(FunPtr(&abort));
		case sym!"clock_gettime".value:
			return some(FunPtr(&clockGetTime));
		case sym!"free".value:
			return some(FunPtr(&free));
		case sym!"nanosleep".value:
			return some(FunPtr(&nanosleep));
		case sym!"malloc".value:
			return some(FunPtr(&malloc));
		case sym!"memcpy".value:
		case sym!"memmove".value:
			return some(FunPtr(&memmove));
		case sym!"memset".value:
			return some(FunPtr(&memset));
		case sym!"write".value:
			return some(FunPtr(&write));
		case sym!"longjmp".value:
		case sym!"setjmp".value:
			// these are treated specially by the interpreter
			return some(FunPtr(&unreachable!void));
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
	assert(false);
}

int clockGetTime(int, const(void*)) =>
	todo!int("");

int nanosleep(const(void*), void*) =>
	todo!int("!");
