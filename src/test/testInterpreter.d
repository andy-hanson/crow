module test.testInterpreter;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, FileToFuns, FnOp, FunNameAndPos, Operation;
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
	writeDup,
	writeDupEntries,
	writeDupEntry,
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
	writeSwitch0ToNDelay,
	writeWrite;
import lower.lowExprHelpers : nat64Type;
import model.diag : FilesInfo;
import model.model : AbsolutePathsGetter;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ArrTypeAndConstantsLow,
	ConcreteFunToLowFunIndex,
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
import test.testUtil : expectDataStack, expectReturnStack, Test;
import util.alloc.alloc : Alloc;
import util.collection.arr : emptyArr;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.globalAllocatedStack : begin, pop, push;
import util.collection.str : SafeCStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.memory : allocate;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.perf : Perf, withNullPerfImpure;
import util.ptr : ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileIndex, Pos;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : Nat8, Nat16, Nat32, Nat64;
import util.util : repeatImpure, verify;

void testInterpreter(ref Test test) {
	testCall(test);
	testCallFunPtr(test);
	testDup(test);
	testRemove(test);
	testDupPartial(test);
	testPack(test);
	testStackRef(test);
	testReadSubword(test);
	testReadWords(test);
	testSwitchAndJump(test);
	testWriteSubword(test);
	testWriteWords(test);
}

private:

immutable(ByteCode) makeByteCode(
	ref Alloc alloc,
	scope void delegate(
		ref ByteCodeWriter,
		ref immutable ByteCodeSource source,
	) @safe @nogc nothrow writeBytecode,
) {
	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe_mut(alloc));
	writeBytecode(writer, emptyByteCodeSource);
	return finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());
}

immutable(FileToFuns) dummyFileToFuns() {
	static immutable FunNameAndPos[][] dummy = [[immutable FunNameAndPos(shortSymAlphaLiteral("a"), immutable Pos(0))]];
	return fullIndexDictOfArr!(FileIndex, FunNameAndPos[])(dummy);
}

void doInterpret(
	ref Test test,
	ref immutable ByteCode byteCode,
	scope void delegate(ref Interpreter!(FakeExtern)) @safe @nogc nothrow runInterpreter,
) {
	immutable Path emptyPath = rootPath(test.allPaths, shortSymAlphaLiteral("test"));
	immutable PathAndStorageKind[1] pk = [immutable PathAndStorageKind(emptyPath, StorageKind.global)];
	immutable LineAndColumnGetter[1] lcg = [lineAndColumnGetterForEmptyFile(test.alloc)];
	immutable AbsolutePathsGetter emptyAbsolutePathsGetter =
		immutable AbsolutePathsGetter(immutable SafeCStr(""), immutable SafeCStr(""));
	immutable FilesInfo filesInfo = immutable FilesInfo(
		fullIndexDictOfArr!(FileIndex, PathAndStorageKind)(pk),
		emptyAbsolutePathsGetter,
		fullIndexDictOfArr!(FileIndex, LineAndColumnGetter)(lcg));
	immutable LowFun[1] lowFun = [immutable LowFun(
		immutable LowFunSource(allocate(test.alloc, immutable LowFunSource.Generated(
			shortSymAlphaLiteral("test"), emptyArr!LowType))),
		nat64Type,
		immutable LowFunParamsKind(false, false),
		emptyArr!LowParam,
		immutable LowFunBody(immutable LowFunBody.Extern(false)))];
	immutable LowProgram lowProgram = immutable LowProgram(
		ConcreteFunToLowFunIndex(),
		immutable AllConstantsLow(
			emptyArr!string,
			emptyArr!ArrTypeAndConstantsLow,
			emptyArr!PointerTypeAndConstantsLow),
		immutable AllLowTypes(
			emptyFullIndexDict!(LowType.ExternPtr, LowExternPtrType),
			emptyFullIndexDict!(LowType.FunPtr, LowFunPtrType),
			emptyFullIndexDict!(LowType.Record, LowRecord),
			emptyFullIndexDict!(LowType.Union, LowUnion)),
		fullIndexDictOfArr!(LowFunIndex, LowFun)(lowFun),
		immutable LowFunIndex(0),
		emptyArr!Sym);
	FakeExtern extern_ = newFakeExtern(test.allocPtr);
	Interpreter!FakeExtern interpreter = Interpreter!FakeExtern(
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(filesInfo));
	runInterpreter(interpreter);
	reset(interpreter);
}

void doTest(
	ref Test test,
	scope void delegate(
		ref ByteCodeWriter,
		ref immutable ByteCodeSource source,
	) @safe @nogc nothrow writeBytecode,
	scope void delegate(ref Interpreter!(FakeExtern)) @safe @nogc nothrow runInterpreter,
) {
	immutable ByteCode byteCode = makeByteCode(test.alloc, writeBytecode);
	doInterpret(test, byteCode, runInterpreter);
}

immutable ByteCodeSource emptyByteCodeSource = immutable ByteCodeSource(immutable LowFunIndex(0), immutable Pos(0));

void testCall(ref Test test) {
	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
	immutable ByteCodeSource source = emptyByteCodeSource;

	// Code is:
	// push 1, 2
	// call f
	// return
	// # f nat(a nat, b nat):
	// +
	// return

	immutable StackEntry argsFirstStackEntry = getNextStackEntry(writer);
	writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
	immutable ByteCodeIndex delayed = writeCallDelayed(writer, source, argsFirstStackEntry, immutable Nat8(1));
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFn(test.dbg, writer, source, FnOp.wrapAddIntegral);
	writeReturn(test.dbg, writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter!(FakeExtern) interpreter) {
		stepNAndExpect(test, interpreter, 2, [immutable Nat64(1), immutable Nat64(2)]);
		stepAndExpect(test, interpreter, [immutable Nat64(1), immutable Nat64(2)]);
		expectReturnStack(test, interpreter, [afterCall]);
		verify(nextByteCodeIndex(interpreter) == fIndex);
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // +
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // return
		verify(nextByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(test, interpreter, []);
		stepExit(test, interpreter);
	});
}

void testCallFunPtr(ref Test test) {
	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
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
	immutable ByteCodeIndex delayed = writePushFunPtrDelayed(test.dbg, writer, source);
	writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
	writeCallFunPtr(test.dbg, writer, source, argsFirstStackEntry, immutable Nat8(1));
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFn(test.dbg, writer, source, FnOp.wrapAddIntegral);
	writeReturn(test.dbg, writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter!(FakeExtern) interpreter) {
		stepNAndExpect(test, interpreter, 3, [fIndex.index.to64(), immutable Nat64(1), immutable Nat64(2)]);
		stepAndExpect(test, interpreter, [immutable Nat64(1), immutable Nat64(2)]); // call-fun-ptr
		expectReturnStack(test, interpreter, [afterCall]);
		verify(nextByteCodeIndex(interpreter) == fIndex);
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // +
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // return
		verify(nextByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(test, interpreter, []);
		stepExit(test, interpreter);
	});
}

void testSwitchAndJump(ref Test test) {
	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
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
	writePushConstant(test.dbg, writer, source, immutable Nat64(0));
	immutable ByteCodeIndex delayed = writeSwitch0ToNDelay(writer, source, immutable Nat16(2));
	fillDelayedSwitchEntry(writer, delayed, immutable Nat32(0));
	immutable ByteCodeIndex firstCase = nextByteCodeIndex(writer);
	writePushConstant(test.dbg, writer, source, immutable Nat64(3));
	setNextStackEntry(writer, startStack);
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(test.dbg, writer, source);
	fillDelayedSwitchEntry(writer, delayed, immutable Nat32(1));
	immutable ByteCodeIndex secondCase = nextByteCodeIndex(writer);
	writePushConstant(test.dbg, writer, source, immutable Nat64(5));
	fillInJumpDelayed(writer, jumpIndex);
	immutable ByteCodeIndex bottom = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(immutable Nat32(0)), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter!(FakeExtern) interpreter) {
		stepAndExpect(test, interpreter, [immutable Nat64(0)]);
		stepAndExpect(test, interpreter, []);
		verify(nextByteCodeIndex(interpreter) == firstCase);
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // push 3
		stepAndExpect(test, interpreter, [immutable Nat64(3)]); // jump
		verify(nextByteCodeIndex(interpreter) == bottom);
		stepExit(test, interpreter);

		// Manually change the value to '1' to test the other case.
		reset(interpreter);
		stepAndExpect(test, interpreter, [immutable Nat64(0)]);
		pop(interpreter.dataStack);
		push(interpreter.dataStack, immutable Nat64(1));
		expectStack(test, interpreter, [immutable Nat64(1)]);
		stepAndExpect(test, interpreter, []);
		verify(nextByteCodeIndex(interpreter) == secondCase);
		stepAndExpect(test, interpreter, [immutable Nat64(5)]);
		verify(nextByteCodeIndex(interpreter) == bottom);
		stepExit(test, interpreter);
	});
}

void testDup(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
			]);
			verifyStackEntry(writer, 3);
			writeDupEntry(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			verifyStackEntry(writer, 4);
			writeDupEntries(
				test.dbg,
				writer,
				source,
				immutable StackEntries(immutable StackEntry(immutable Nat16(2)), immutable Nat8(2)));
			verifyStackEntry(writer, 6);
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			stepNAndExpect(test, interpreter, 3, [immutable Nat64(55), immutable Nat64(65), immutable Nat64(75)]);
			stepAndExpect(test, interpreter, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
				immutable Nat64(55)]);
			stepAndExpect(test, interpreter, [
				immutable Nat64(55),
				immutable Nat64(65),
				immutable Nat64(75),
				immutable Nat64(55),
				immutable Nat64(75),
				immutable Nat64(55)]);
			stepExit(test, interpreter);
		});
}

void testRemove(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [
				immutable Nat64(0), immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(4)]);
			writeRemove(
				test.dbg,
				writer,
				source,
				immutable StackEntries(immutable StackEntry(immutable Nat16(1)), immutable Nat8(2)));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			stepNAndExpect(test, interpreter, 5, [
				immutable Nat64(0),
				immutable Nat64(1),
				immutable Nat64(2),
				immutable Nat64(3),
				immutable Nat64(4)]);
			stepAndExpect(test, interpreter, [immutable Nat64(0), immutable Nat64(3), immutable Nat64(4)]);
			stepExit(test, interpreter);
		});
}

void testDupPartial(ref Test test) {
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
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [u.n]);
			writeDup(
				test.dbg,
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(0),
				immutable Nat16(4));
			writeDup(
				test.dbg,
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(4),
				immutable Nat16(2));
			writeDup(
				test.dbg,
				writer,
				source,
				immutable StackEntry(immutable Nat16(0)),
				immutable Nat8(6),
				immutable Nat16(1));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			stepAndExpect(test, interpreter, [u.n]);
			stepAndExpect(test, interpreter, [u.n, immutable Nat64(0x01234567)]);
			stepAndExpect(test, interpreter, [u.n, immutable Nat64(0x01234567), immutable Nat64(0x89ab)]);
			stepAndExpect(test, interpreter, [
				u.n,
				immutable Nat64(0x01234567),
				immutable Nat64(0x89ab),
				immutable Nat64(0xcd)]);
			stepExit(test, interpreter);
		});
}

void testPack(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [
				immutable Nat64(0x01234567),
				immutable Nat64(0x89ab),
				immutable Nat64(0xcd)]);
			scope immutable Operation.Pack.Field[3] fields = [
				immutable Operation.Pack.Field(immutable Nat16(0), immutable Nat16(0), immutable Nat16(4)),
				immutable Operation.Pack.Field(immutable Nat16(8), immutable Nat16(4), immutable Nat16(2)),
				immutable Operation.Pack.Field(immutable Nat16(16), immutable Nat16(6), immutable Nat16(1))];
			scope immutable Operation.Pack pack =
				immutable Operation.Pack(immutable Nat8(3), immutable Nat8(1), fields);
			writePack(test.dbg, writer, source, pack);
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			stepNAndExpect(test, interpreter, 3, [
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
			stepAndExpect(test, interpreter, [u.n]);
		});
}

void testStackRef(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(1)), immutable Nat8(4));
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			testStackRefInner(test, interpreter);
		});
}

@trusted void testStackRefInner(
	ref Test test,
	ref Interpreter!(FakeExtern) interpreter,
) {
	stepNAndExpect(test, interpreter, 2, [immutable Nat64(1), immutable Nat64(2)]);
	stepAndExpect(test, interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack))]);
	stepAndExpect(test, interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable ulong) (begin(interpreter.dataStack) + 1)),
	]);
	stepAndExpect(test, interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable ulong) (begin(interpreter.dataStack) + 1)),
		immutable Nat64(4),
	]);
	stepAndExpect(test, interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
		immutable Nat64(cast(immutable ulong) (cast(immutable uint*) begin(interpreter.dataStack) + 3)),
	]);
}

@trusted void testReadSubword(ref Test test) {
	struct S {
		uint a;
		ushort b;
		ubyte c;
		ubyte d;
	}
	union U {
		S s;
		Nat64 value;
	}
	U u;
	u.s = immutable S(0x01234567, 0x89ab, 0xcd, 0xef);
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstant(test.dbg, writer, source, u.value);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(0), immutable Nat16(4));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(4), immutable Nat16(2));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(6), immutable Nat16(1));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			testReadSubwordInner(test, interpreter, u.value);
		});
}

@trusted void testReadSubwordInner(
	ref Test test,
	ref Interpreter!(FakeExtern) interpreter,
	immutable Nat64 value,
) {
	stepAndExpect(test, interpreter, [value]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	stepAndExpect(test, interpreter, [value, ptr]);
	stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567)]);
	stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567), ptr]);
	stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab)]);
	stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab), ptr]);
	stepAndExpect(test, interpreter, [
		value,
		immutable Nat64(0x01234567),
		immutable Nat64(0x89ab),
		immutable Nat64(0xcd)]);
	stepExit(test, interpreter);
}

@trusted void testReadWords(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(8), immutable Nat16(16));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			testReadWordsInner(test, interpreter);
		});
}

@trusted void testReadWordsInner(
	ref Test test,
	ref Interpreter!(FakeExtern) interpreter,
) {
	stepNAndExpect(test, interpreter, 3, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	stepAndExpect(test, interpreter, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), ptr]);
	stepAndExpect(test, interpreter, [
		immutable Nat64(1),
		immutable Nat64(2),
		immutable Nat64(3),
		immutable Nat64(2),
		immutable Nat64(3)]);
	stepExit(test, interpreter);
}

@trusted void testWriteSubword(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstant(test.dbg, writer, source, immutable Nat64(0));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(test.dbg, writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(test.dbg, writer, source, immutable Nat16(0), immutable Nat16(4));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(test.dbg, writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(test.dbg, writer, source, immutable Nat16(4), immutable Nat16(2));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstant(test.dbg, writer, source, immutable Nat64(0x0123456789abcdef));
			writeWrite(test.dbg, writer, source, immutable Nat16(6), immutable Nat16(1));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			testWriteSubwordInner(test, interpreter);
		});
}

@trusted void testWriteSubwordInner(
	ref Test test,
	ref Interpreter!(FakeExtern) interpreter,
) {
	struct S {
		uint a;
		ushort b;
		ubyte c;
		ubyte d;
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

	stepAndExpect(test, interpreter, [immutable Nat64(0)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	stepAndExpect(test, interpreter, [immutable Nat64(0), ptr]);
	stepAndExpect(test, interpreter, [immutable Nat64(0), ptr, immutable Nat64(0x0123456789abcdef)]);
	stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0, 0, 0))]);

	stepNAndExpect(test, interpreter, 2, [
		toNat(immutable S(0x89abcdef, 0, 0, 0)),
		ptr,
		immutable Nat64(0x0123456789abcdef,
	)]);
	stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0, 0))]);

	stepNAndExpect(test, interpreter, 2, [
		toNat(immutable S(0x89abcdef, 0xcdef, 0, 0)),
		ptr,
		immutable Nat64(0x0123456789abcdef)]);
	stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0xef, 0))]);

	stepExit(test, interpreter);
}

@trusted void testWriteWords(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, ref immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeWrite(test.dbg, writer, source, immutable Nat16(8), immutable Nat16(16));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter!(FakeExtern) interpreter) {
			testWriteWordsInner(test, interpreter);
		});
}

@trusted void testWriteWordsInner(
	ref Test test,
	ref Interpreter!(FakeExtern) interpreter,
) {
	stepNAndExpect(test, interpreter, 3, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)]);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	stepAndExpect(test, interpreter, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0), ptr]);
	stepNAndExpect(test, interpreter, 2, [
		immutable Nat64(0),
		immutable Nat64(0),
		immutable Nat64(0),
		ptr,
		immutable Nat64(1),
		immutable Nat64(2)]);
	stepAndExpect(test, interpreter, [immutable Nat64(0), immutable Nat64(1), immutable Nat64(2)]);
	stepExit(test, interpreter);
}

void stepNAndExpect(Extern)(
	ref Test test,
	ref Interpreter!Extern interpreter,
	immutable uint n,
	scope immutable Nat64[] expected,
) {
	repeatImpure(n, () { stepContinue(test, interpreter); });
	expectStack(test, interpreter, expected);
}

void stepAndExpect(Extern)(
	ref Test test,
	ref Interpreter!Extern interpreter,
	scope immutable Nat64[] expected,
) {
	stepNAndExpect(test, interpreter, 1, expected);
}

void verifyStackEntry(ref ByteCodeWriter writer, immutable ushort n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(immutable Nat16(n)));
}

void stepContinue(Extern)(ref Test test, ref Interpreter!Extern interpreter) {
	immutable StepResult result = withNullPerfImpure!(immutable StepResult)((scope ref Perf perf) @safe =>
		step(test.dbg, perf, test.alloc, test.allPaths, interpreter));
	verify(result == StepResult.continue_);
}

void stepExit(Extern)(ref Test test, ref Interpreter!Extern interpreter) {
	immutable StepResult result = withNullPerfImpure!(immutable StepResult)((scope ref Perf perf) =>
		step(test.dbg, perf, test.alloc, test.allPaths, interpreter));
	verify(result == StepResult.exit);
}

void expectStack(Extern)(
	ref Test test,
	ref Interpreter!Extern interpreter,
	scope immutable Nat64[] expected,
) {
	expectDataStack(test, interpreter.dataStack, expected);
}
