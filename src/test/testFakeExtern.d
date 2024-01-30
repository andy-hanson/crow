module test.testFakeExtern;

@safe @nogc nothrow: // not pure

import interpret.extern_ :
	doDynCall, DynCallType, DynCallSig, Extern, ExternPointersForAllLibraries, ExternPointersForLibrary, FunPointer;
import interpret.fakeExtern : unreachableWriteCb, withFakeExtern, WriteCb;
import interpret.stacks : dataPop, dataPush, Stacks, withStacks;
import lib.lsp.lspTypes : Pipe;
import model.lowModel : ExternLibrary, PrimitiveType;
import test.testUtil : Test;
import util.col.array : small;
import util.col.map : mustGet;
import util.col.mutArr : moveToArray, MutArr, pushAll;
import util.exitCode : ExitCode;
import util.opt : force, none, Opt;
import util.string : cString, stringsEqual;
import util.symbol : Symbol, symbol;
import util.uri : Uri;

void testFakeExtern(ref Test test) {
	testMallocAndFree(test);
	testWrite(test);
}

private:

@trusted void testMallocAndFree(ref Test test) {
	withFakeExtern(test.alloc, test.allSymbols, unreachableWriteCb, (scope ref Extern extern_) @trusted {
		Symbol[2] exportNames = [symbol!"free", symbol!"malloc"];
		ExternLibrary[1] externLibraries = [ExternLibrary(symbol!"c", none!Uri, exportNames)];
		Opt!ExternPointersForAllLibraries funPtrsOpt =
			extern_.loadExternPointers(externLibraries, (in string _) =>
				assert(false));
		ExternPointersForAllLibraries funPtrs = force(funPtrsOpt);
		ExternPointersForLibrary forCrow = mustGet(funPtrs, symbol!"c");
		FunPointer free = mustGet(forCrow, symbol!"free").asFunPointer;
		FunPointer malloc = mustGet(forCrow, symbol!"malloc").asFunPointer;

		DynCallType[2] mallocSigTypes = [DynCallType.pointer, DynCallType(PrimitiveType.nat64)];
		scope DynCallSig mallocSig = DynCallSig(small!DynCallType(mallocSigTypes));

		withStacks!void((scope ref Stacks stacks) @trusted {
			dataPush(stacks, 8);
			doDynCall(extern_.doDynCall, stacks, mallocSig, malloc);
			ubyte* ptr1 = cast(ubyte*) dataPop(stacks);

			dataPush(stacks, 16);
			doDynCall(extern_.doDynCall, stacks, mallocSig, malloc);
			ubyte* ptr2 = cast(ubyte*) dataPop(stacks);

			*ptr1 = 1;
			assert(*ptr1 == 1);
			assert(ptr2 != ptr1);

			DynCallType[2] freeSigTypes = [DynCallType(PrimitiveType.void_), DynCallType.pointer];
			scope DynCallSig freeSig = DynCallSig(small!DynCallType(freeSigTypes));
			dataPush(stacks, cast(ulong) ptr2);
			doDynCall(extern_.doDynCall, stacks, freeSig, free);
			dataPush(stacks, cast(ulong) ptr1);
			doDynCall(extern_.doDynCall, stacks, freeSig, free);
		});
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
			Symbol[1] exportNames = [symbol!"write"];
			ExternLibrary[1] externLibraries = [ExternLibrary(symbol!"c", none!Uri, exportNames)];
			Opt!ExternPointersForAllLibraries funPtrsOpt =
				extern_.loadExternPointers(externLibraries, (in string _) =>
					assert(false));
			ExternPointersForAllLibraries funPtrs = force(funPtrsOpt);
			ExternPointersForLibrary forCrow = mustGet(funPtrs, symbol!"c");
			FunPointer write = mustGet(forCrow, symbol!"write").asFunPointer;

			DynCallType[4] sigTypes = [
				DynCallType.pointer,
				DynCallType(PrimitiveType.int32),
				DynCallType.pointer,
				DynCallType(PrimitiveType.nat64),
			];
			DynCallSig sig = DynCallSig(small!DynCallType(sigTypes));

			withStacks!void((scope ref Stacks stacks) {
				dataPush(stacks, [1, cast(ulong) cString!"gnarly".ptr, 4]);
				doDynCall(extern_.doDynCall, stacks, sig, write);
				ulong res1 = dataPop(stacks);
				assert(res1 == 4);

				dataPush(stacks, [2, cast(ulong) cString!"tubular".ptr, 2]);
				doDynCall(extern_.doDynCall, stacks, sig, write);
				ulong res2 = dataPop(stacks);
				assert(res2 == 2);

				dataPush(stacks, [1, cast(ulong) cString!"way cool".ptr, 5]);
				doDynCall(extern_.doDynCall, stacks, sig, write);
				ulong res3 = dataPop(stacks);
				assert(res3 == 5);
			});
			return ExitCode(42);
		});
	assert(result.value == 42);
	assert(stringsEqual(moveToArray(test.alloc, stdout), "gnarway c"));
	assert(stringsEqual(moveToArray(test.alloc, stderr), "tu"));
}
