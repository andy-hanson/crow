module test.testInterpreter;

@safe @nogc nothrow: // not pure

import diag : FilesInfo;
import model : AbsolutePathsGetter;
import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, FileToFuns, FnOp, FunNameAndPos;
import interpret.fakeExtern : FakeExtern, newFakeExtern;
import interpret.runBytecode :
	nextByteCodeIndex,
	Interpreter,
	reset,
	step,
	StepResult;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	fillDelayedCall,
	fillDelayedSwitchEntry,
	fillInJumpDelayed,
	finishByteCode,
	getNextStackEntry,
	nextByteCodeIndex,
	newByteCodeWriter,
	setNextStackEntry,
	StackEntries,
	StackEntry,
	writeCallDelayed,
	writeCallFunPtr,
	writeDupEntries,
	writeDupEntry,
	writeDupPartial,
	writeFn,
	writePack,
	writePushConstant,
	writePushConstants,
	writePushFunPtrDelayed,
	writeJumpDelayed,
	writeRead,
	writeRemove,
	writeReturn,
	writeStackRef,
	writeSwitchDelay,
	writeWrite;
import lower.lowExprHelpers : nat64Type;
import lowModel :
	ArrTypeAndConstantsLow,
	AllConstantsLow,
	LowExternPtrType,
	LowFun,
	LowFunBody,
	LowFunIndex,
	LowFunParamsKind,
	LowFunPtrType,
	LowFunSource,
	LowParam,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion,
	PointerTypeAndConstantsLow;
import test.testUtil : expectDataStack, expectReturnStack;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : False;
import util.collection.arr : Arr, arrOfD, emptyArr;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.globalAllocatedStack : begin, pop, push;
import util.collection.str : emptyStr, strLiteral;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.opt : none;
import util.path : Path, PathAndStorageKind, StorageKind;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileIndex, Pos;
import util.sym : shortSymAlphaLiteral;
import util.types : Nat8, Nat16, Nat32, Nat64, u8, u16, u32, u64;
import util.util : repeatImpure, verify;

void testInterpreter() {
	testCall();
	testCallFunPtr();
	testDup();
	testRemove();
	testDupPartial();
	testPack();
	testStackRef();
	testReadSubword();
	testReadWords();
	testSwitchAndJump();
	testWriteSubword();
	testWriteWords();
}

private:

alias Alloc = StackAlloc!("temp", 1024 * 1024);

immutable(ByteCode) makeByteCode(Alloc)(
	ref Alloc alloc,
	scope void delegate(
		ref ByteCodeWriter!Alloc,
		ref immutable ByteCodeSource source,
	) @safe @nogc pure nothrow writeBytecode,
) {
	ByteCodeWriter!Alloc writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	writeBytecode(writer, emptyByteCodeSource);
	return finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());
}

immutable(FileToFuns) dummyFileToFuns() {
	static immutable FunNameAndPos dummy = immutable FunNameAndPos(shortSymAlphaLiteral("a"), immutable Pos(0));
	static immutable Arr!FunNameAndPos dummyArr = immutable Arr!FunNameAndPos(&dummy, 1);
	return fullIndexDictOfArr!(FileIndex, Arr!FunNameAndPos)(
		immutable Arr!(Arr!FunNameAndPos)(&dummyArr, 1));
}

alias TestAlloc = StackAlloc!("test", 1024);
alias TestFakeExtern = FakeExtern!TestAlloc;

void doInterpret(
	ref immutable ByteCode byteCode,
	scope void delegate(ref Interpreter!TestFakeExtern) @safe @nogc nothrow runInterpreter,
) {
	immutable Path emptyPath = immutable Path(none!(Ptr!Path), shortSymAlphaLiteral("test"));
	immutable PathAndStorageKind pk = immutable PathAndStorageKind(ptrTrustMe(emptyPath), StorageKind.global);
	TestAlloc alloc;
	immutable LineAndColumnGetter lcg = lineAndColumnGetterForEmptyFile(alloc);
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(
			immutable Arr!PathAndStorageKind(ptrTrustMe(pk).rawPtr(), 1)),
		immutable AbsolutePathsGetter(emptyStr, emptyStr),
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(
			immutable Arr!LineAndColumnGetter(ptrTrustMe(lcg).rawPtr(), 1)));
	immutable LowFun lowFun = immutable LowFun(
		immutable LowFunSource(immutable LowFunSource.Generated(shortSymAlphaLiteral("test"), none!LowType)),
		nat64Type,
		immutable LowFunParamsKind(False, False),
		emptyArr!LowParam,
		immutable LowFunBody(immutable LowFunBody.Extern(False, strLiteral("test"))));
	immutable LowProgram lowProgram = immutable LowProgram(
		immutable AllConstantsLow(emptyArr!ArrTypeAndConstantsLow, emptyArr!PointerTypeAndConstantsLow),
		emptyFullIndexDict!(LowType.ExternPtr, LowExternPtrType),
		emptyFullIndexDict!(LowType.FunPtr, LowFunPtrType),
		emptyFullIndexDict!(LowType.Record, LowRecord),
		emptyFullIndexDict!(LowType.Union, LowUnion),
		fullIndexDictOfArr!(LowFunIndex, LowFun)(immutable Arr!LowFun(ptrTrustMe(lowFun).rawPtr(), 1)),
		immutable LowFunIndex(0));
	TestFakeExtern extern_ = newFakeExtern(ptrTrustMe_mut(alloc));
	Interpreter!TestFakeExtern interpreter = Interpreter!TestFakeExtern(
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(filesInfo));
	runInterpreter(interpreter);
	reset(interpreter);
}

void doTest(
	scope void delegate(
		ref ByteCodeWriter!Alloc,
		ref immutable ByteCodeSource source,
	) @safe @nogc pure nothrow writeBytecode,
	scope void delegate(ref Interpreter!TestFakeExtern) @safe @nogc nothrow runInterpreter,
) {
	Alloc alloc;
	immutable ByteCode byteCode = makeByteCode(alloc, writeBytecode);
	doInterpret(byteCode, runInterpreter);
}

immutable ByteCodeSource emptyByteCodeSource = immutable ByteCodeSource(immutable LowFunIndex(0), immutable Pos(0));

void testCall() {
	Alloc alloc;
	ByteCodeWriter!Alloc writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	immutable ByteCodeSource source = emptyByteCodeSource;

	// Code is:
	// push 1, 2
	// call f
	// return
	// # f nat(a nat, b nat):
	// +
	// return

	immutable StackEntry argsFirstStackEntry = getNextStackEntry(writer);
	writePushConstants(writer, source, [immutable Nat64(1), immutable Nat64(2)]);
	immutable ByteCodeIndex delayed = writeCallDelayed(writer, source, argsFirstStackEntry, immutable Nat8(1));
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFn(writer, source, FnOp.wrapAddIntegral);
	writeReturn(writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(byteCode, (ref Interpreter!TestFakeExtern interpreter) {
		stepNAndExpect(interpreter, 2, [immutable Nat64(1), immutable Nat64(2)]);
		stepAndExpect(interpreter, [immutable Nat64(1), immutable Nat64(2)]);
		expectReturnStack(interpreter, [afterCall]);
		verify(nextByteCodeIndex(interpreter) == fIndex);
		stepAndExpect(interpreter, [immutable Nat64(3)]); // +
		stepAndExpect(interpreter, [immutable Nat64(3)]); // return
		verify(nextByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(interpreter, []);
		stepExit(interpreter);
	});
}

void testCallFunPtr() {
	Alloc alloc;
	ByteCodeWriter!Alloc writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	immutable ByteCodeSource source = emptyByteCodeSource;

	// Code is:
	// push address of 'f'
	// push 1, 2
	// call-fun-ptr
	// return
	// # f nat(a nat, b nat):
	// +
	// return

	immutable StackEntry argsFirstStackEntry = getNextStackEntry(writer);
	immutable ByteCodeIndex delayed = writePushFunPtrDelayed(writer, source);
	writePushConstants(writer, source, [immutable Nat64(1), immutable Nat64(2)]);
	writeCallFunPtr(writer, source, argsFirstStackEntry, immutable Nat8(1));
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFn(writer, source, FnOp.wrapAddIntegral);
	writeReturn(writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(byteCode, (ref Interpreter!TestFakeExtern interpreter) {
		stepNAndExpect(interpreter, 3, [fIndex.index.to64(), immutable Nat64(1), immutable Nat64(2)]);
		stepAndExpect(interpreter, [immutable Nat64(1), immutable Nat64(2)]); // call-fun-ptr
		expectReturnStack(interpreter, [afterCall]);
		verify(nextByteCodeIndex(interpreter) == fIndex);
		stepAndExpect(interpreter, [immutable Nat64(3)]); // +
		stepAndExpect(interpreter, [immutable Nat64(3)]); // return
		verify(nextByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(interpreter, []);
		stepExit(interpreter);
	});
}

void testSwitchAndJump() {
	Alloc alloc;
	ByteCodeWriter!Alloc writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	immutable ByteCodeSource source = emptyByteCodeSource;

	// Code is:
	// switch (2 cases)
	// # case 0:
	// 3
	// jump bottom
	// # case 1:
	// 5
	// # bottom:
	// return

	//TODO: want to test both sides of the switch...
	immutable StackEntry startStack = getNextStackEntry(writer);
	writePushConstant(writer, source, immutable Nat64(0));
	immutable ByteCodeIndex delayed = writeSwitchDelay(writer, source, immutable Nat8(2));
	fillDelayedSwitchEntry(writer, delayed, immutable Nat8(0));
	immutable ByteCodeIndex firstCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, immutable Nat64(3));
	setNextStackEntry(writer, startStack);
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(writer, source);
	fillDelayedSwitchEntry(writer, delayed, immutable Nat8(1));
	immutable ByteCodeIndex secondCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, immutable Nat64(5));
	fillInJumpDelayed(writer, jumpIndex);
	immutable ByteCodeIndex bottom = nextByteCodeIndex(writer);
	writeReturn(writer, source);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(byteCode, (ref Interpreter!TestFakeExtern interpreter) {
		stepAndExpect(interpreter, [immutable Nat64(0)]);
		stepAndExpect(interpreter, []);
		verify(nextByteCodeIndex(interpreter) == firstCase);
		stepAndExpect(interpreter, [immutable Nat64(3)]); // push 3
		stepAndExpect(interpreter, [immutable Nat64(3)]); // jump
		verify(nextByteCodeIndex(interpreter) == bottom);
		stepExit(interpreter);

		// Manually change the value to '1' to test the other case.
		reset(interpreter);
		stepAndExpect(interpreter, [immutable Nat64(0)]);
		pop(interpreter.dataStack);
		push(interpreter.dataStack, immutable Nat64(1));
		expectStack(interpreter, [immutable Nat64(1)]);
		stepAndExpect(interpreter, []);
		verify(nextByteCodeIndex(interpreter) == secondCase);
		stepAndExpect(interpreter, [immutable Nat64(5)]);
		verify(nextByteCodeIndex(interpreter) == bottom);
		stepExit(interpreter);
	});
}

void testDup() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [immutable Nat64(55), immutable Nat64(65), immutable Nat64(75)]);
			verifyStackEntry(writer, 3);
			writeDupEntry(writer, source, immutable StackEntry(immutable Nat16(0)));
			verifyStackEntry(writer, 4);
			writeDupEntries(
				writer,
				source,
				immutable StackEntries(immutable StackEntry(immutable Nat16(2)), immutable Nat8(2)));
			verifyStackEntry(writer, 6);
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			stepNAndExpect(interpreter, 3, [immutable Nat64(55), immutable Nat64(65), immutable Nat64(75)]);
			stepAndExpect(interpreter, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
				immutable Nat64(55)]);
			stepAndExpect(interpreter, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
				immutable Nat64(55),
				immutable Nat64(75)]);
			stepAndExpect(interpreter, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
				immutable Nat64(55),
				immutable Nat64(75),
				immutable Nat64(55)]);
			stepExit(interpreter);
		});
}

void testRemove() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [
				immutable Nat64(0), immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(4)]);
			writeRemove(
				writer,
				source,
				immutable StackEntries(immutable StackEntry(immutable Nat16(1)), immutable Nat8(2)));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			stepNAndExpect(interpreter, 5, [
				immutable Nat64(0),
				immutable Nat64(1),
				immutable Nat64(2),
				immutable Nat64(3),
				immutable Nat64(4)]);
			stepAndExpect(interpreter, [immutable Nat64(0), immutable Nat64(3), immutable Nat64(4)]);
			stepExit(interpreter);
		});
}

void testDupPartial() {
	struct S {
		Nat32 a;
		Nat16 b;
		Nat8 c;
	}
	union U {
		S s;
		Nat64 n;
	}
	U u;
	u.s = immutable S(immutable Nat32(0x01234567), immutable Nat16(0x89ab), immutable Nat8(0xcd));
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [u.n]);
			writeDupPartial(
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(0),
				immutable Nat8(4));
			writeDupPartial(
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(4),
				immutable Nat8(2));
			writeDupPartial(
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(6),
				immutable Nat8(1));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			stepAndExpect(interpreter, [u.n]);
			stepAndExpect(interpreter, [u.n, immutable Nat64(0x01234567)]);
			stepAndExpect(interpreter, [u.n, immutable Nat64(0x01234567), immutable Nat64(0x89ab)]);
			stepAndExpect(
				interpreter,
				[u.n, immutable Nat64(0x01234567), immutable Nat64(0x89ab), immutable Nat64(0xcd)]);
			stepExit(interpreter);
		});
}

void testPack() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [
				immutable Nat64(0x01234567),
				immutable Nat64(0x89ab),
				immutable Nat64(0xcd)]);
			immutable Nat8[3] a = [immutable Nat8(4), immutable Nat8(2), immutable Nat8(1)];
			writePack(writer, source, arrOfD(a));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			stepNAndExpect(interpreter, 3, [
				immutable Nat64(0x01234567),
				immutable Nat64(0x89ab),
				immutable Nat64(0xcd)]);
			struct S {
				Nat32 a;
				Nat16 b;
				Nat8 c;
			}
			union U {
				S s;
				Nat64 n;
			}
			U u;
			u.s = immutable S(immutable Nat32(0x01234567), immutable Nat16(0x89ab), immutable Nat8(0xcd));
			stepAndExpect(interpreter, [u.n]);
		});

}

void testStackRef() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(1)), immutable Nat8(4));
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			testStackRefInner(interpreter);
		});
}

@trusted void testStackRefInner(ref Interpreter!TestFakeExtern interpreter) {
	stepNAndExpect(interpreter, 2, [immutable Nat64(1), immutable Nat64(2)]);
	stepAndExpect(interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable u64) begin(interpreter.dataStack))]);
	stepAndExpect(interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable u64) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable u64) (begin(interpreter.dataStack) + 1)),
	]);
	stepAndExpect(interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable u64) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable u64) (begin(interpreter.dataStack) + 1)),
		immutable Nat64(4),
	]);
	stepAndExpect(interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable u64) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable u64) (cast(immutable u32*) begin(interpreter.dataStack) + 3)),
	]);
}

@trusted void testReadSubword() {
	struct S {
		u32 a;
		u16 b;
		u8 c;
		u8 d;
	}
	union U {
		S s;
		Nat64 value;
	}
	U u;
	u.s = immutable S(0x01234567, 0x89ab, 0xcd, 0xef);
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstant(writer, source, u.value);
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(writer, source, immutable Nat8(0), immutable Nat8(4));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(writer, source, immutable Nat8(4), immutable Nat8(2));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(writer, source, immutable Nat8(6), immutable Nat8(1));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			testReadSubwordInner(interpreter, u.value);
		});
}

@trusted void testReadSubwordInner(ref Interpreter!TestFakeExtern interpreter, immutable Nat64 value) {
	stepAndExpect(interpreter, [value]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable u64) begin(interpreter.dataStack));
	stepAndExpect(interpreter, [value, ptr]);
	stepAndExpect(interpreter, [value, immutable Nat64(0x01234567)]);
	stepAndExpect(interpreter, [value, immutable Nat64(0x01234567), ptr]);
	stepAndExpect(interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab)]);
	stepAndExpect(interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab), ptr]);
	stepAndExpect(interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab), immutable Nat64(0xcd)]);
	stepExit(interpreter);
}

@trusted void testReadWords() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)]);
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(writer, source, immutable Nat8(8), immutable Nat8(16));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			testReadWordsInner(interpreter);
		});
}

@trusted void testReadWordsInner(ref Interpreter!TestFakeExtern interpreter) {
	stepNAndExpect(interpreter, 3, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable u64) begin(interpreter.dataStack));
	stepAndExpect(interpreter, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), ptr]);
	stepAndExpect(
		interpreter,
		[immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(2), immutable Nat64(3)]);
	stepExit(interpreter);
}

@trusted void testWriteSubword() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstant(writer, source, immutable Nat64(0));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(writer, source, immutable Nat8(0), immutable Nat8(4));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(writer, source, immutable Nat8(4), immutable Nat8(2));
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(writer, source, immutable Nat8(6), immutable Nat8(1));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			testWriteSubwordInner(interpreter);
		});
}

@trusted void testWriteSubwordInner(ref Interpreter!TestFakeExtern interpreter) {
	struct S {
		u32 a;
		u16 b;
		u8 c;
		u8 d;
	}
	union U {
		S s;
		Nat64 value;
	}
	immutable(Nat64) toNat(immutable S s) {
		U u;
		u.s = s;
		return u.value;
	}

	stepAndExpect(interpreter, [immutable Nat64(0)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable u64) begin(interpreter.dataStack));
	stepAndExpect(interpreter, [immutable Nat64(0), ptr]);
	stepAndExpect(interpreter, [immutable Nat64(0), ptr, immutable Nat64(0x0123456789abcdef)]);
	stepAndExpect(interpreter, [toNat(immutable S(0x89abcdef, 0, 0, 0))]);

	stepNAndExpect(interpreter, 2, [toNat(immutable S(0x89abcdef, 0, 0, 0)), ptr, immutable Nat64(0x0123456789abcdef)]);
	stepAndExpect(interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0, 0))]);

	stepNAndExpect(
		interpreter,
		2,
		[toNat(immutable S(0x89abcdef, 0xcdef, 0, 0)), ptr, immutable Nat64(0x0123456789abcdef)]);
	stepAndExpect(interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0xef, 0))]);

	stepExit(interpreter);
}

@trusted void testWriteWords() {
	doTest(
		(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
			writePushConstants(writer, source, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)]);
			writeStackRef(writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstants(writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeWrite(writer, source, immutable Nat8(8), immutable Nat8(16));
			writeReturn(writer, source);
		},
		(ref Interpreter!TestFakeExtern interpreter) {
			testWriteWordsInner(interpreter);
		});
}

@trusted void testWriteWordsInner(ref Interpreter!TestFakeExtern interpreter) {
	stepNAndExpect(interpreter, 3, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable u64) begin(interpreter.dataStack));
	stepAndExpect(interpreter, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0), ptr]);
	stepNAndExpect(
		interpreter,
		2,
		[immutable Nat64(0), immutable Nat64(0), immutable Nat64(0), ptr, immutable Nat64(1), immutable Nat64(2)]);
	stepAndExpect(interpreter, [immutable Nat64(0), immutable Nat64(1), immutable Nat64(2)]);
	stepExit(interpreter);
}

void stepNAndExpect(Extern)(ref Interpreter!Extern interpreter, immutable uint n, scope immutable Nat64[] expected) {
	repeatImpure(n, () { stepContinue(interpreter); });
	expectStack(interpreter, expected);
}

void stepAndExpect(Extern)(ref Interpreter!Extern interpreter, scope immutable Nat64[] expected) {
	stepNAndExpect(interpreter, 1, expected);
}

void verifyStackEntry(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u16 n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(immutable Nat16(n)));
}

void stepContinue(Extern)(ref Interpreter!Extern interpreter) {
	immutable StepResult result = step(interpreter);
	verify(result == StepResult.continue_);
}

void stepExit(Extern)(ref Interpreter!Extern interpreter) {
	immutable StepResult result = step(interpreter);
	verify(result == StepResult.exit);
}

void expectStack(Extern)(ref Interpreter!Extern interpreter, scope immutable Nat64[] expected) {
	expectDataStack(interpreter.dataStack, expected);
}
