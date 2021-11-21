module test.testInterpreter;

@safe @nogc nothrow: // not pure

import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeSource, FileToFuns, FnOp, FunNameAndPos, Operation;
import interpret.extern_ : Extern;
import interpret.fakeExtern : withFakeExtern;
import interpret.runBytecode :
	Interpreter,
	nextByteCodeIndex,
	opCall,
	opStopInterpretation,
	readOperation,
	withInterpreter;
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
	SwitchDelayed,
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
import lib.compiler : ExitCode;
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
import model.typeLayout : Pack, PackField;
import test.testUtil : expectDataStack, expectReturnStack, Test;
import util.alloc.alloc : Alloc;
import util.collection.arr : at, emptyArr;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.globalAllocatedStack : begin, pop, push;
import util.collection.str : SafeCStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.memory : allocate;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.ptr : ptrTrustMe_mut;
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
	scope void delegate(ref ByteCodeWriter, immutable ByteCodeSource source) @safe @nogc nothrow writeBytecode,
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
	scope void delegate(scope ref Interpreter, Operation) @safe @nogc nothrow runInterpreter,
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
	withFakeExtern(test.alloc, (scope ref Extern extern_) {
		withInterpreter!void(
			test.dbg, test.alloc, extern_, lowProgram, byteCode, test.allPaths, filesInfo,
			(scope ref Interpreter interpreter) {
				runInterpreter(interpreter, readOperation(interpreter));
			});
		return immutable ExitCode(0);
	});
}

void doTest(
	ref Test test,
	scope void delegate(ref ByteCodeWriter, immutable ByteCodeSource source) @safe @nogc nothrow writeBytecode,
	scope void delegate(scope ref Interpreter, Operation) @safe @nogc nothrow runInterpreter,
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

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, Operation operation) {
		operation = stepNAndExpect(test, interpreter, 2, [immutable Nat64(1), immutable Nat64(2)], operation);
		verify(operation == &opCall);
		operation = stepAndExpect(test, interpreter, [immutable Nat64(1), immutable Nat64(2)], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		// opCall returns the first operation and moves nextOperation to the one after
		verify(at(byteCode.byteCode, fIndex.index) == operation);
		verify(curByteCodeIndex(interpreter) == fIndex);
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // +
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // return
		verify(curByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(test, interpreter, []);
		stepExit(test, interpreter, operation);
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

	doInterpret(test, byteCode, (ref Interpreter interpreter, Operation operation) {
		operation = stepNAndExpect(
			test,
			interpreter,
			3,
			[fIndex.index.to64(), immutable Nat64(1), immutable Nat64(2)],
			operation);
		// call-fun-ptr
		operation =stepAndExpect(test, interpreter, [immutable Nat64(1), immutable Nat64(2)], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		verify(curByteCodeIndex(interpreter) == fIndex);
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // +
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // return
		verify(curByteCodeIndex(interpreter) == afterCall);
		expectReturnStack(test, interpreter, []);
		stepExit(test, interpreter, operation);
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
	immutable SwitchDelayed delayed = writeSwitch0ToNDelay(writer, source, immutable Nat16(2));
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

	doInterpret(test, byteCode, (ref Interpreter interpreter, Operation operation) {
		operation = stepAndExpect(test, interpreter, [immutable Nat64(0)], operation);
		operation = stepAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter) == firstCase);
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // push 3
		operation = stepAndExpect(test, interpreter, [immutable Nat64(3)], operation); // jump
		verify(curByteCodeIndex(interpreter) == bottom);
		stepExit(test, interpreter, operation);
	});

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, Operation operation) {
		// Manually change the value to '1' to test the other case.
		operation = stepAndExpect(test, interpreter, [immutable Nat64(0)], operation);
		pop(interpreter.dataStack);
		push(interpreter.dataStack, immutable Nat64(1));
		expectStack(test, interpreter, [immutable Nat64(1)]);
		operation = stepAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter) == secondCase);
		operation = stepAndExpect(test, interpreter, [immutable Nat64(5)], operation);
		verify(curByteCodeIndex(interpreter) == bottom);
		stepExit(test, interpreter, operation);
	});
}

void testDup(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
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
		(ref Interpreter interpreter, Operation operation) {
			operation = stepNAndExpect(
				test,
				interpreter,
				3,
				[immutable Nat64(55), immutable Nat64(65), immutable Nat64(75)],
				operation);
			operation = stepAndExpect(
				test,
				interpreter,
				[immutable Nat64(55), immutable Nat64(65), immutable Nat64(75), immutable Nat64(55)],
				operation);
			operation = stepAndExpect(
				test,
				interpreter,
				[
					immutable Nat64(55),
					immutable Nat64(65),
					immutable Nat64(75),
					immutable Nat64(55),
					immutable Nat64(75),
					immutable Nat64(55),
				],
				operation);
			stepExit(test, interpreter, operation);
		});
}

void testRemove(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [
				immutable Nat64(0), immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(4)]);
			writeRemove(
				test.dbg,
				writer,
				source,
				immutable StackEntries(immutable StackEntry(immutable Nat16(1)), immutable Nat8(2)));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, Operation operation) {
			operation = stepNAndExpect(
				test,
				interpreter,
				5,
				[immutable Nat64(0), immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(4)],
				operation);
			operation = stepAndExpect(
				test,
				interpreter,
				[immutable Nat64(0), immutable Nat64(3), immutable Nat64(4)],
				operation);
			stepExit(test, interpreter, operation);
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
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
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
		(scope ref Interpreter interpreter, Operation operation) {
			operation = stepAndExpect(test, interpreter, [u.n], operation);
			operation = stepAndExpect(test, interpreter, [u.n, immutable Nat64(0x01234567)], operation);
			operation = stepAndExpect(
				test,
				interpreter,
				[u.n, immutable Nat64(0x01234567), immutable Nat64(0x89ab)],
				operation);
			operation = stepAndExpect(
				test,
				interpreter,
				[u.n, immutable Nat64(0x01234567), immutable Nat64(0x89ab), immutable Nat64(0xcd)],
				operation);
			stepExit(test, interpreter, operation);
		});
}

void testPack(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [
				immutable Nat64(0x01234567),
				immutable Nat64(0x89ab),
				immutable Nat64(0xcd)]);
			scope immutable PackField[3] fields = [
				immutable PackField(immutable Nat16(0), immutable Nat16(0), immutable Nat16(4)),
				immutable PackField(immutable Nat16(8), immutable Nat16(4), immutable Nat16(2)),
				immutable PackField(immutable Nat16(16), immutable Nat16(6), immutable Nat16(1))];
			scope immutable Pack pack = immutable Pack(immutable Nat8(3), immutable Nat8(1), fields);
			writePack(test.dbg, writer, source, pack);
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, Operation operation) {
			operation = stepNAndExpect(
				test,
				interpreter,
				3,
				[immutable Nat64(0x01234567), immutable Nat64(0x89ab), immutable Nat64(0xcd)],
				operation);
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
			stepAndExpect(test, interpreter, [u.n], operation);
		});
}

void testStackRef(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(1)), immutable Nat8(4));
		},
		(scope ref Interpreter interpreter, Operation operation) {
			testStackRefInner(test, interpreter, operation);
		});
}

@trusted void testStackRefInner(ref Test test, scope ref Interpreter interpreter, Operation operation) {
	operation = stepNAndExpect(test, interpreter, 2, [immutable Nat64(1), immutable Nat64(2)], operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(1), immutable Nat64(2), immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack))],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[
			immutable Nat64(1),
			immutable Nat64(2),
			immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
			immutable Nat64(cast(immutable ulong) (begin(interpreter.dataStack) + 1)),
		],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[
			immutable Nat64(1),
			immutable Nat64(2),
			immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
			immutable Nat64(cast(immutable ulong) (begin(interpreter.dataStack) + 1)),
			immutable Nat64(4),
		],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[
			immutable Nat64(1),
			immutable Nat64(2),
			immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack)),
			immutable Nat64(cast(immutable ulong) (cast(immutable uint*) begin(interpreter.dataStack) + 3)),
		],
		operation);
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
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstant(test.dbg, writer, source, u.value);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(0), immutable Nat16(4));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(4), immutable Nat16(2));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(6), immutable Nat16(1));
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, Operation operation) {
			testReadSubwordInner(test, interpreter, u.value, operation);
		});
}

@trusted void testReadSubwordInner(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable Nat64 value,
	Operation operation,
) {
	operation = stepAndExpect(test, interpreter, [value], operation);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	operation = stepAndExpect(test, interpreter, [value, ptr], operation);
	operation = stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567)], operation);
	operation = stepAndExpect(test, interpreter, [value, immutable Nat64(0x01234567), ptr], operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[value, immutable Nat64(0x01234567), immutable Nat64(0x89ab)],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[value, immutable Nat64(0x01234567), immutable Nat64(0x89ab), ptr],
		operation);
	operation = stepAndExpect(
		test,
		interpreter, [value, immutable Nat64(0x01234567), immutable Nat64(0x89ab), immutable Nat64(0xcd)],
		operation);
	stepExit(test, interpreter, operation);
}

@trusted void testReadWords(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writeRead(test.dbg, writer, source, immutable Nat16(8), immutable Nat16(16));
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, Operation operation) {
			testReadWordsInner(test, interpreter, operation);
		});
}

@trusted void testReadWordsInner(ref Test test, scope ref Interpreter interpreter, Operation operation) {
	operation = stepNAndExpect(
		test,
		interpreter,
		3,
		[immutable Nat64(1), immutable Nat64(2), immutable Nat64(3)],
		operation);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), ptr],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(1), immutable Nat64(2), immutable Nat64(3), immutable Nat64(2), immutable Nat64(3)],
		operation);
	stepExit(test, interpreter, operation);
}

@trusted void testWriteSubword(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
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
		(scope ref Interpreter interpreter, Operation operation) {
			testWriteSubwordInner(test, interpreter, operation);
		});
}

@trusted void testWriteSubwordInner(ref Test test, scope ref Interpreter interpreter, Operation operation) {
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

	operation = stepAndExpect(test, interpreter, [immutable Nat64(0)], operation);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	operation = stepAndExpect(test, interpreter, [immutable Nat64(0), ptr], operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(0), ptr, immutable Nat64(0x0123456789abcdef)],
		operation);
	operation = stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0, 0, 0))], operation);

	operation = stepNAndExpect(
		test,
		interpreter,
		2,
		[toNat(immutable S(0x89abcdef, 0, 0, 0)), ptr, immutable Nat64(0x0123456789abcdef)],
		operation);
	operation = stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0, 0))], operation);

	operation = stepNAndExpect(
		test,
		interpreter,
		2,
		[toNat(immutable S(0x89abcdef, 0xcdef, 0, 0)), ptr, immutable Nat64(0x0123456789abcdef)],
		operation);
	operation = stepAndExpect(test, interpreter, [toNat(immutable S(0x89abcdef, 0xcdef, 0xef, 0))], operation);

	stepExit(test, interpreter, operation);
}

@trusted void testWriteWords(ref Test test) {
	doTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(immutable Nat16(0)));
			writePushConstants(test.dbg, writer, source, [immutable Nat64(1), immutable Nat64(2)]);
			writeWrite(test.dbg, writer, source, immutable Nat16(8), immutable Nat16(16));
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, Operation operation) {
			testWriteWordsInner(test, interpreter, operation);
		});
}

@trusted void testWriteWordsInner(ref Test test, scope ref Interpreter interpreter, Operation operation) {
	operation = stepNAndExpect(
		test,
		interpreter,
		3,
		[immutable Nat64(0), immutable Nat64(0), immutable Nat64(0)],
		operation);
	immutable Nat64 ptr = immutable Nat64(cast(immutable ulong) begin(interpreter.dataStack));
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(0), immutable Nat64(0), immutable Nat64(0), ptr],
		operation);
	operation = stepNAndExpect(
		test,
		interpreter,
		2,
		[immutable Nat64(0), immutable Nat64(0), immutable Nat64(0), ptr, immutable Nat64(1), immutable Nat64(2)],
		operation);
	operation = stepAndExpect(
		test,
		interpreter,
		[immutable Nat64(0), immutable Nat64(1), immutable Nat64(2)],
		operation);
	stepExit(test, interpreter, operation);
}

immutable(Operation) stepNAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable uint n,
	scope immutable Nat64[] expected,
	Operation operation,
) {
	repeatImpure(n, () {
		operation = stepContinue(test, interpreter, operation);
	});
	expectStack(test, interpreter, expected);
	return operation;
}

immutable(Operation) stepAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	scope immutable Nat64[] expected,
	immutable Operation operation,
) {
	return stepNAndExpect(test, interpreter, 1, expected, operation);
}

void verifyStackEntry(ref ByteCodeWriter writer, immutable ushort n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(immutable Nat16(n)));
}

@trusted immutable(Operation) stepContinue(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable Operation operation,
) {
	immutable Operation nextOperation = cast(immutable Operation) operation(interpreter);
	verify(nextOperation != &opStopInterpretation);
	return nextOperation;
}

@trusted void stepExit(ref Test test, scope ref Interpreter interpreter, immutable Operation operation) {
	immutable Operation nextOperation = cast(immutable Operation) operation(interpreter);
	verify(nextOperation == &opStopInterpretation);
}

void expectStack(ref Test test, scope ref Interpreter interpreter, scope immutable Nat64[] expected) {
	expectDataStack(test, interpreter.dataStack, expected);
}

immutable(ByteCodeIndex) curByteCodeIndex(scope ref Interpreter a) {
	return immutable ByteCodeIndex(nextByteCodeIndex(a).index - immutable Nat32(1));
}
