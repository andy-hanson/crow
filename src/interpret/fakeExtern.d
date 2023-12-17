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
	writeSymbolToCb;
import interpret.runBytecode : syntheticCall;
import interpret.stacks : dataPush, Stacks;
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc, allocateBytes;
import util.col.array : map;
import util.col.map : KeyValuePair, makeMap;
import util.col.mutArr : MutArr, mutArrIsEmpty, push;
import util.memory : memmove, memset;
import util.opt : force, has, none, Opt, some;
import util.string : cString;
import util.symbol : AllSymbols, Symbol, symbol;
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
	MutArr!(immutable KeyValuePair!(Symbol, Symbol)) failures;
	ExternFunPtrsForAllLibraries res = makeMap!(Symbol, ExternFunPtrsForLibrary, ExternLibrary)(
		alloc, libraries, (in ExternLibrary x) =>
			immutable KeyValuePair!(Symbol, ExternFunPtrsForLibrary)(
				x.libraryName,
				fakeExternFunsForLibrary(alloc, failures, allSymbols, x)));
	foreach (immutable KeyValuePair!(Symbol, Symbol) x; failures) {
		writeError(cString!"Could not load extern function ");
		writeSymbolToCb(writeError, allSymbols, x.value);
		writeError(cString!" from library ");
		writeSymbolToCb(writeError, allSymbols, x.key);
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
	ref MutArr!(immutable KeyValuePair!(Symbol, Symbol)) failures,
	in AllSymbols allSymbols,
	in ExternLibrary lib,
) =>
	makeMap!(Symbol, FunPtr, Symbol)(alloc, lib.importNames, (in Symbol importName) {
		Opt!FunPtr res = getFakeExternFun(lib.libraryName, importName);
		if (!has(res))
			push(alloc, failures, KeyValuePair!(Symbol, Symbol)(lib.libraryName, importName));
		return immutable KeyValuePair!(Symbol, FunPtr)(importName, has(res) ? force(res) : FunPtr(null));
	});

Opt!FunPtr getFakeExternFun(Symbol libraryName, Symbol name) =>
	libraryName == symbol!"c"
		? getFakeExternFunC(name)
		: none!FunPtr;

Opt!FunPtr getFakeExternFunC(Symbol name) {
	switch (name.value) {
		case symbol!"abort".value:
			return some(FunPtr(&abort));
		case symbol!"clock_gettime".value:
			return some(FunPtr(&clockGetTime));
		case symbol!"free".value:
			return some(FunPtr(&free));
		case symbol!"nanosleep".value:
			return some(FunPtr(&nanosleep));
		case symbol!"malloc".value:
			return some(FunPtr(&malloc));
		case symbol!"memcpy".value:
		case symbol!"memmove".value:
			return some(FunPtr(&memmove));
		case symbol!"memset".value:
			return some(FunPtr(&memset));
		case symbol!"write".value:
			return some(FunPtr(&write));
		case symbol!"longjmp".value:
		case symbol!"setjmp".value:
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
