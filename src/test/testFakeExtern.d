module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ :
	DynCallType, DynCallSig, Extern, ExternFunPtrsForAllLibraries, ExternFunPtrsForLibrary, FunPtr;
import interpret.fakeExtern : unreachableWriteCb, withFakeExtern, WriteCb;
import lib.lsp.lspTypes : Pipe;
import model.lowModel : ExternLibrary;
import test.testUtil : Test;
import util.col.map : mustGet;
import util.col.mutArr : moveToArr, MutArr, pushAll;
import util.exitCode : ExitCode;
import util.opt : force, none, Opt;
import util.string : CString, cString, stringsEqual;
import util.sym : Sym, sym;
import util.uri : Uri;
import util.util : unreachable;

void testFakeExtern(ref Test test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(ref Test test) {
	withFakeExtern(test.alloc, test.allSymbols, unreachableWriteCb, (scope ref Extern extern_) @trusted {
		Sym[2] exportNames = [sym!"free", sym!"malloc"];
		ExternLibrary[1] externLibraries = [ExternLibrary(sym!"c", none!Uri, exportNames)];
		Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
			extern_.loadExternFunPtrs(externLibraries, (in CString _) =>
				unreachable!void());
		ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
		ExternFunPtrsForLibrary forCrow = mustGet(funPtrs, sym!"c");
		FunPtr free = mustGet(forCrow, sym!"free");
		FunPtr malloc = mustGet(forCrow, sym!"malloc");

		ulong[1] args8 = [8];
		DynCallType[2] mallocSigTypes = [DynCallType.pointer, DynCallType.nat64];
		scope DynCallSig mallocSig = DynCallSig(mallocSigTypes);
		ubyte* ptr1 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args8);
		ulong[1] args16 = [8];
		ubyte* ptr2 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args16);
		*ptr1 = 1;
		assert(*ptr1 == 1);
		assert(ptr2 != ptr1);
		DynCallType[2] freeSigTypes = [DynCallType.void_, DynCallType.pointer];
		scope DynCallSig freeSig = DynCallSig(freeSigTypes);
		ulong[1] freePtr2 = [cast(ulong) ptr2];
		extern_.doDynCall(free, freeSig, freePtr2);
		ulong[1] freePtr1 = [cast(ulong) ptr1];
		extern_.doDynCall(free, freeSig, freePtr1);
		return ExitCode(0);
	});
}

void testWrite(ref Test test) {
	MutArr!(immutable char) stdout;
	MutArr!(immutable char) stderr;
	scope WriteCb fakeWrite = (Pipe pipe, in string x) {
		final switch (pipe) {
			case Pipe.stdout:
				pushAll(test.alloc, stdout, x);
				break;
			case Pipe.stderr:
				pushAll(test.alloc, stderr, x);
				break;
		}
	};
	ExitCode result =
		withFakeExtern(test.alloc, test.allSymbols, fakeWrite, (scope ref Extern extern_) @trusted {
			Sym[1] exportNames = [sym!"write"];
			ExternLibrary[1] externLibraries = [ExternLibrary(sym!"c", none!Uri, exportNames)];
			Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
				extern_.loadExternFunPtrs(externLibraries, (in CString _) =>
					unreachable!void());
			ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
			ExternFunPtrsForLibrary forCrow = mustGet(funPtrs, sym!"c");
			FunPtr write = mustGet(forCrow, sym!"write");

			DynCallType[4] sigTypes = [DynCallType.pointer, DynCallType.int32, DynCallType.pointer, DynCallType.nat64];
			DynCallSig sig = DynCallSig(sigTypes);
			ulong[3] args1 = [1, cast(ulong) cString!"gnarly".ptr, 4];
			extern_.doDynCall(write, sig, args1);
			ulong[3] args2 = [2, cast(ulong) cString!"tubular".ptr, 2];
			extern_.doDynCall(write, sig, args2);
			ulong[3] args3 = [1, cast(ulong) cString!"way cool".ptr, 5];
			extern_.doDynCall(write, sig, args3);
			return ExitCode(42);
		});
	assert(result.value == 42);
	assert(stringsEqual(moveToArr(test.alloc, stdout), "gnarway c"));
	assert(stringsEqual(moveToArr(test.alloc, stderr), "tu"));
}
