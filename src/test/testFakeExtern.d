module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ :
	DynCallType, DynCallSig, Extern, ExternFunPtrsForAllLibraries, ExternFunPtrsForLibrary, FunPtr;
import interpret.fakeExtern : FakeExternResult, FakeStdOutput, withFakeExtern;
import lib.compiler : ExitCode;
import model.lowModel : ExternLibrary;
import test.testUtil : Test;
import util.col.dict : mustGetAt;
import util.col.str : SafeCStr, strEq;
import util.opt : force, none, Opt;
import util.path : Path;
import util.sym : Sym, sym;
import util.util : unreachable, verify;

void testFakeExtern(ref Test test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(ref Test test) {
	withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput _) @trusted {
		immutable Sym[2] exportNames = [sym!"free", sym!"malloc"];
		immutable ExternLibrary[1] externLibraries = [immutable ExternLibrary(sym!"c", none!Path, exportNames)];
		immutable Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
			extern_.loadExternFunPtrs(externLibraries, (scope immutable(SafeCStr)) =>
				unreachable!void());
		immutable ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
		immutable ExternFunPtrsForLibrary forCrow = mustGetAt(funPtrs, sym!"c");
		immutable FunPtr free = mustGetAt(forCrow, sym!"free");
		immutable FunPtr malloc = mustGetAt(forCrow, sym!"malloc");

		immutable ulong[1] args8 = [8];
		immutable DynCallType[2] mallocSigTypes = [DynCallType.pointer, DynCallType.nat64];
		scope immutable DynCallSig mallocSig = immutable DynCallSig(mallocSigTypes);
		ubyte* ptr1 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args8);
		immutable ulong[1] args16 = [8];
		ubyte* ptr2 = cast(ubyte*) extern_.doDynCall(malloc, mallocSig, args16);
		*ptr1 = 1;
		verify(*ptr1 == 1);
		verify(ptr2 == ptr1 + 8);
		immutable DynCallType[2] freeSigTypes = [DynCallType.void_, DynCallType.pointer];
		scope immutable DynCallSig freeSig = immutable DynCallSig(freeSigTypes);
		immutable ulong[1] freePtr2 = [cast(immutable ulong) ptr2];
		extern_.doDynCall(free, freeSig, freePtr2);
		immutable ulong[1] freePtr1 = [cast(immutable ulong) ptr1];
		extern_.doDynCall(free, freeSig, freePtr1);
		return immutable ExitCode(0);
	});
}

void testWrite(ref Test test) {
	immutable FakeExternResult result =
		withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput _) @trusted {
			immutable Sym[1] exportNames = [sym!"write"];
			immutable ExternLibrary[1] externLibraries = [
				immutable ExternLibrary(sym!"c", none!Path, exportNames),
			];
			immutable Opt!ExternFunPtrsForAllLibraries funPtrsOpt =
				extern_.loadExternFunPtrs(externLibraries, (scope immutable(SafeCStr)) =>
					unreachable!void());
			immutable ExternFunPtrsForAllLibraries funPtrs = force(funPtrsOpt);
			immutable ExternFunPtrsForLibrary forCrow = mustGetAt(funPtrs, sym!"c");
			immutable FunPtr write = mustGetAt(forCrow, sym!"write");

			immutable DynCallType[4] sigTypes =
				[DynCallType.pointer, DynCallType.int32, DynCallType.pointer, DynCallType.nat64];
			immutable DynCallSig sig = immutable DynCallSig(sigTypes);
			immutable ulong[3] args1 = [1, cast(immutable ulong) cast(immutable char*) "gnarly", 4];
			extern_.doDynCall(write, sig, args1);
			immutable ulong[3] args2 = [2, cast(immutable ulong) cast(immutable char*) "tubular", 2];
			extern_.doDynCall(write, sig, args2);
			immutable ulong[3] args3 = [1, cast(immutable ulong) cast(immutable char*) "way cool", 5];
			extern_.doDynCall(write, sig, args3);
			return immutable ExitCode(42);
		});
	verify(result.err.value == 42);
	verify(strEq(result.stdout, "gnarway c"));
	verify(strEq(result.stderr, "tu"));
}
