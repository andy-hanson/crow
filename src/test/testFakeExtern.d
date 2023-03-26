module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ :
	DynCallType, DynCallSig, Extern, ExternFunPtrsForAllLibraries, ExternFunPtrsForLibrary, FunPtr;
import interpret.fakeExtern : FakeExternResult, FakeStdOutput, withFakeExtern;
import lib.compiler : ExitCode;
import model.lowModel : ExternLibrary;
import test.testUtil : Test;
import util.col.map : mustGetAt;
import util.col.str : CStr, SafeCStr, strEq;
import util.opt : force, none, Opt;
import util.path : Path;
import util.sym : Sym, sym;
import util.util : typeAs, unreachable, verify;

void testFakeExtern(ref Test test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(ref Test test) {
	withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput _) @trusted {
		Sym[2] exportNames = [sym!"free", sym!"malloc"];
		ExternLibrary[1] externLibraries = [ExternLibrary(sym!"c", none!Path, exportNames)];
		Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
			extern_.loadExternFunPtrs(externLibraries, (in SafeCStr _) =>
				unreachable!void());
		ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
		ExternFunPtrsForLibrary forCrow = mustGetAt(funPtrs, sym!"c");
		FunPtr free = mustGetAt(forCrow, sym!"free");
		FunPtr malloc = mustGetAt(forCrow, sym!"malloc");

		ulong[1] args8 = [8];
		DynCallType[2] mallocSigTypes = [DynCallType.pointer, DynCallType.nat64];
		scope DynCallSig mallocSig = DynCallSig(mallocSigTypes);
		ubyte* ptr1 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args8);
		ulong[1] args16 = [8];
		ubyte* ptr2 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args16);
		*ptr1 = 1;
		verify(*ptr1 == 1);
		verify(ptr2 == ptr1 + 8);
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
	FakeExternResult result =
		withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput _) @trusted {
			Sym[1] exportNames = [sym!"write"];
			ExternLibrary[1] externLibraries = [ExternLibrary(sym!"c", none!Path, exportNames)];
			Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
				extern_.loadExternFunPtrs(externLibraries, (in SafeCStr _) =>
					unreachable!void());
			ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
			ExternFunPtrsForLibrary forCrow = mustGetAt(funPtrs, sym!"c");
			FunPtr write = mustGetAt(forCrow, sym!"write");

			DynCallType[4] sigTypes = [DynCallType.pointer, DynCallType.int32, DynCallType.pointer, DynCallType.nat64];
			DynCallSig sig = DynCallSig(sigTypes);
			ulong[3] args1 = [1, cast(ulong) typeAs!CStr("gnarly"), 4];
			extern_.doDynCall(write, sig, args1);
			ulong[3] args2 = [2, cast(ulong) typeAs!CStr("tubular"), 2];
			extern_.doDynCall(write, sig, args2);
			ulong[3] args3 = [1, cast(ulong) typeAs!CStr("way cool"), 5];
			extern_.doDynCall(write, sig, args3);
			return ExitCode(42);
		});
	verify(result.err.value == 42);
	verify(strEq(result.stdout, "gnarway c"));
	verify(strEq(result.stderr, "tu"));
}
