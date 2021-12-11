module test.testInterpreter;

@safe @nogc nothrow: // not pure

import interpret.applyFn : fnWrapAddIntegral;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	FileToFuns,
	FunNameAndPos,
	initialOperationPointer,
	Operation;
import interpret.extern_ : Extern;
import interpret.fakeExtern : withFakeExtern;
import interpret.runBytecode : byteCode, Interpreter, nextByteCodeIndex, opCall, opStopInterpretation, withInterpreter;
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
	writeFnBinary,
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
import util.collection.arr : emptyArr;
import util.collection.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.collection.stack : stackBegin, pop, push;
import util.collection.str : SafeCStr;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForEmptyFile;
import util.memory : allocate;
import util.path : Path, PathAndStorageKind, rootPath, StorageKind;
import util.ptr : ptrTrustMe_mut;
import util.sourceRange : FileIndex, Pos;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : verify;

void testInterpreter(ref Test test) {
	testCall(test);
	testCallFunPtr(test);
	testDup(test);
	testRemoveOne(test);
	testRemoveMany(test);
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
	return finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());
}

immutable(FileToFuns) dummyFileToFuns() {
	static immutable FunNameAndPos[][] dummy = [[immutable FunNameAndPos(shortSymAlphaLiteral("a"), immutable Pos(0))]];
	return fullIndexDictOfArr!(FileIndex, FunNameAndPos[])(dummy);
}

void doInterpret(
	ref Test test,
	ref immutable ByteCode byteCode,
	scope void delegate(scope ref Interpreter, immutable(Operation)*) @system @nogc nothrow runInterpreter,
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
	withFakeExtern(test.alloc, (scope ref Extern extern_) @trusted {
		withInterpreter!void(
			test.dbg, test.alloc, extern_, lowProgram, byteCode, test.allPaths, filesInfo,
			(scope ref Interpreter interpreter) {
				runInterpreter(interpreter, initialOperationPointer(byteCode));
			});
		return immutable ExitCode(0);
	});
}

public @trusted void interpreterTest(
	ref Test test,
	scope void delegate(ref ByteCodeWriter, immutable ByteCodeSource source) @safe @nogc nothrow writeBytecode,
	scope void delegate(scope ref Interpreter, immutable(Operation)*) @system @nogc nothrow runInterpreter,
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
	writePushConstants(test.dbg, writer, source, [1, 2]);
	immutable ByteCodeIndex delayed = writeCallDelayed(writer, source, argsFirstStackEntry, 1);
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFnBinary!fnWrapAddIntegral(test.dbg, writer, source);
	writeReturn(test.dbg, writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, immutable(Operation)* operation) {
		operation = stepNAndExpect(test, interpreter, 2, [1, 2], operation);
		verify(operation.fn == &opCall);
		operation = stepAndExpect(test, interpreter, [1, 2], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		// opCall returns the first operation and moves nextOperation to the one after
		verify(operation == &byteCode.byteCode[fIndex.index]);
		verify(curByteCodeIndex(interpreter, operation) == fIndex);
		operation = stepAndExpect(test, interpreter, [3], operation); // +
		operation = stepAndExpect(test, interpreter, [3], operation); // return
		verify(curByteCodeIndex(interpreter, operation) == afterCall);
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
	writePushConstants(test.dbg, writer, source, [1, 2]);
	writeCallFunPtr(test.dbg, writer, source, argsFirstStackEntry, 1);
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFnBinary!fnWrapAddIntegral(test.dbg, writer, source);
	writeReturn(test.dbg, writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter interpreter, immutable(Operation)* operation) {
		operation = stepNAndExpect(
			test,
			interpreter,
			3,
			[fIndex.index, 1, 2],
			operation);
		// call-fun-ptr
		operation =stepAndExpect(test, interpreter, [1, 2], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		verify(curByteCodeIndex(interpreter, operation) == fIndex);
		operation = stepAndExpect(test, interpreter, [3], operation); // +
		operation = stepAndExpect(test, interpreter, [3], operation); // return
		verify(curByteCodeIndex(interpreter, operation) == afterCall);
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
	writePushConstant(test.dbg, writer, source, 0);
	immutable SwitchDelayed delayed = writeSwitch0ToNDelay(writer, source, 2);
	fillDelayedSwitchEntry(writer, delayed, 0);
	immutable ByteCodeIndex firstCase = nextByteCodeIndex(writer);
	writePushConstant(test.dbg, writer, source, 3);
	setNextStackEntry(writer, startStack);
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(test.dbg, writer, source);
	fillDelayedSwitchEntry(writer, delayed, 1);
	immutable ByteCodeIndex secondCase = nextByteCodeIndex(writer);
	writePushConstant(test.dbg, writer, source, 5);
	fillInJumpDelayed(writer, jumpIndex);
	immutable ByteCodeIndex bottom = nextByteCodeIndex(writer);
	writeReturn(test.dbg, writer, source);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter interpreter, immutable(Operation)* operation) {
		operation = stepAndExpect(test, interpreter, [0], operation);
		operation = stepAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter, operation) == firstCase);
		operation = stepAndExpect(test, interpreter, [3], operation); // push 3
		operation = stepAndExpect(test, interpreter, [3], operation); // jump
		verify(curByteCodeIndex(interpreter, operation) == bottom);
		stepExit(test, interpreter, operation);
	});

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, immutable(Operation)* operation) {
		// Manually change the value to '1' to test the other case.
		operation = stepAndExpect(test, interpreter, [0], operation);
		pop(interpreter.dataStack);
		push(interpreter.dataStack, 1);
		expectStack(test, interpreter, [1]);
		operation = stepAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter, operation) == secondCase);
		operation = stepAndExpect(test, interpreter, [5], operation);
		verify(curByteCodeIndex(interpreter, operation) == bottom);
		stepExit(test, interpreter, operation);
	});
}

void testDup(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [55, 65, 75]);
			verifyStackEntry(writer, 3);
			writeDupEntry(test.dbg, writer, source, immutable StackEntry(0));
			verifyStackEntry(writer, 4);
			writeDupEntries(
				test.dbg,
				writer,
				source,
				immutable StackEntries(immutable StackEntry(2), 2));
			verifyStackEntry(writer, 6);
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			operation = stepNAndExpect(test, interpreter, 3, [55, 65, 75], operation);
			operation = stepAndExpect(test, interpreter, [55, 65, 75, 55], operation);
			operation = stepAndExpect(test, interpreter, [55, 65, 75, 55, 75, 55], operation);
			stepExit(test, interpreter, operation);
		});
}

void testRemoveOne(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [0, 1, 2]);
			writeRemove(
				test.dbg,
				writer,
				source,
				immutable StackEntries(immutable StackEntry(1), 1));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			operation = stepNAndExpect(test, interpreter, 3, [0, 1, 2], operation);
			operation = stepAndExpect(test, interpreter, [0, 2], operation);
			stepExit(test, interpreter, operation);
		});
}

void testRemoveMany(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [0, 1, 2, 3, 4]);
			writeRemove(test.dbg, writer, source, immutable StackEntries(immutable StackEntry(1), 2));
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			operation = stepNAndExpect(test, interpreter, 5, [0, 1, 2, 3, 4], operation);
			operation = stepAndExpect(test, interpreter, [0, 3, 4], operation);
			stepExit(test, interpreter, operation);
		});
}

void testDupPartial(ref Test test) {
	struct S {
		uint a;
		ushort b;
		ubyte c;
	}
	union U {
		S s;
		ulong n;
	}
	U u;
	u.s = immutable S(0x01234567, 0x89ab, 0xcd);
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [u.n]);
			writeDup(test.dbg, writer, source, immutable StackEntry(0), 0, 4);
			writeDup(test.dbg, writer, source, immutable StackEntry(0), 4, 2);
			writeDup(test.dbg, writer, source, immutable StackEntry(0), 6, 1);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			operation = stepAndExpect(test, interpreter, [u.n], operation);
			operation = stepAndExpect(test, interpreter, [u.n, 0x01234567], operation);
			operation = stepAndExpect(test, interpreter, [u.n, 0x01234567, 0x89ab], operation);
			operation = stepAndExpect(test, interpreter, [u.n, 0x01234567, 0x89ab, 0xcd], operation);
			stepExit(test, interpreter, operation);
		});
}

void testPack(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [0x01234567, 0x89ab, 0xcd]);
			scope immutable PackField[3] fields = [
				immutable PackField(0, 0, 4),
				immutable PackField(8, 4, 2),
				immutable PackField(16, 6, 1)];
			scope immutable Pack pack = immutable Pack(3, 1, fields);
			writePack(test.dbg, writer, source, pack);
			writeReturn(test.dbg, writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			operation = stepNAndExpect(test, interpreter, 3, [0x01234567, 0x89ab, 0xcd], operation);
			struct S {
				uint a;
				ushort b;
				ubyte c;
			}
			union U {
				S s;
				ulong n;
			}
			U u;
			u.s = immutable S(0x01234567, 0x89ab, 0xcd);
			stepAndExpect(test, interpreter, [u.n], operation);
		});
}

void testStackRef(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [1, 2]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writeStackRef(test.dbg, writer, source, immutable StackEntry(1), 4);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			testStackRefInner(test, interpreter, operation);
		});
}

@trusted void testStackRefInner(ref Test test, scope ref Interpreter interpreter, immutable(Operation)* operation) {
	immutable ulong stack0 = cast(immutable ulong) stackBegin(interpreter.dataStack);
	immutable ulong stack1 = cast(immutable ulong) (stackBegin(interpreter.dataStack) + 1);
	immutable ulong stack3 = cast(immutable ulong) ((cast(immutable uint*) stackBegin(interpreter.dataStack)) + 3);

	operation = stepNAndExpect(test, interpreter, 2, [1, 2], operation);
	operation = stepAndExpect(test, interpreter, [1, 2, stack0], operation);
	operation = stepAndExpect(test, interpreter, [1, 2, stack0, stack1], operation);
	operation = stepAndExpect(test, interpreter, [1, 2, stack0, stack1, 4], operation);
	operation = stepAndExpect(test, interpreter, [1, 2, stack0, stack3], operation);
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
		ulong value;
	}
	U u;
	u.s = immutable S(0x01234567, 0x89ab, 0xcd, 0xef);
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstant(test.dbg, writer, source, u.value);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writeRead(test.dbg, writer, source, 0, 4);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writeRead(test.dbg, writer, source, 4, 2);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writeRead(test.dbg, writer, source, 6, 1);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			testReadSubwordInner(test, interpreter, u.value, operation);
		});
}

@trusted void testReadSubwordInner(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable ulong value,
	immutable(Operation)* operation,
) {
	operation = stepAndExpect(test, interpreter, [value], operation);
	immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
	operation = stepAndExpect(test, interpreter, [value, ptr], operation);
	operation = stepAndExpect(test, interpreter, [value, 0x01234567], operation);
	operation = stepAndExpect(test, interpreter, [value, 0x01234567, ptr], operation);
	operation = stepAndExpect(test, interpreter, [value, 0x01234567, 0x89ab], operation);
	operation = stepAndExpect(test, interpreter, [value, 0x01234567, 0x89ab, ptr], operation);
	operation = stepAndExpect(test, interpreter, [value, 0x01234567, 0x89ab, 0xcd], operation);
	stepExit(test, interpreter, operation);
}

@trusted void testReadWords(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [1, 2, 3]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writeRead(test.dbg, writer, source, 8, 16);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			testReadWordsInner(test, interpreter, operation);
		});
}

@trusted void testReadWordsInner(ref Test test, scope ref Interpreter interpreter, immutable(Operation)* operation) {
	operation = stepNAndExpect(test, interpreter, 3, [1, 2, 3], operation);
	immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
	operation = stepAndExpect(test, interpreter, [1, 2, 3, ptr], operation);
	operation = stepAndExpect(test, interpreter, [1, 2, 3, 2, 3], operation);
	stepExit(test, interpreter, operation);
}

@trusted void testWriteSubword(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstant(test.dbg, writer, source, 0);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writePushConstant(test.dbg, writer, source, 0x0123456789abcdef);
			writeWrite(test.dbg, writer, source, 0, 4);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writePushConstant(test.dbg, writer, source, 0x0123456789abcdef);
			writeWrite(test.dbg, writer, source, 4, 2);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writePushConstant(test.dbg, writer, source, 0x0123456789abcdef);
			writeWrite(test.dbg, writer, source, 6, 1);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			testWriteSubwordInner(test, interpreter, operation);
		});
}

@trusted void testWriteSubwordInner(ref Test test, scope ref Interpreter interpreter, immutable(Operation)* operation) {
	struct S {
		uint a;
		ushort b;
		ubyte c;
		ubyte d;
	}
	union U {
		S s;
		ulong value;
	}
	immutable(ulong) toUlong(immutable S s) {
		U u;
		u.s = s;
		return u.value;
	}

	operation = stepAndExpect(test, interpreter, [0], operation);
	immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
	operation = stepAndExpect(test, interpreter, [0, ptr], operation);
	operation = stepAndExpect(test, interpreter, [0, ptr, 0x0123456789abcdef], operation);
	operation = stepAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0, 0, 0))], operation);

	operation = stepNAndExpect(
		test, interpreter, 2, [toUlong(immutable S(0x89abcdef, 0, 0, 0)), ptr, 0x0123456789abcdef], operation);
	operation = stepAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0))], operation);

	operation = stepNAndExpect(
		test, interpreter, 2, [toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0)), ptr, 0x0123456789abcdef], operation);
	operation = stepAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0xcdef, 0xef, 0))], operation);

	stepExit(test, interpreter, operation);
}

@trusted void testWriteWords(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(test.dbg, writer, source, [0, 0, 0]);
			writeStackRef(test.dbg, writer, source, immutable StackEntry(0));
			writePushConstants(test.dbg, writer, source, [1, 2]);
			writeWrite(test.dbg, writer, source, 8, 16);
			writeReturn(test.dbg, writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			testWriteWordsInner(test, interpreter, operation);
		});
}

@trusted void testWriteWordsInner(ref Test test, scope ref Interpreter interpreter, immutable(Operation)* operation) {
	operation = stepNAndExpect(test, interpreter, 3, [0, 0, 0], operation);
	immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
	operation = stepAndExpect(test, interpreter, [0, 0, 0, ptr], operation);
	operation = stepNAndExpect(test, interpreter, 2, [0, 0, 0, ptr, 1, 2], operation);
	operation = stepAndExpect(test, interpreter, [0, 1, 2], operation);
	stepExit(test, interpreter, operation);
}

immutable(Operation*) stepNAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable uint n,
	scope immutable ulong[] expected,
	immutable(Operation)* operation,
) {
	foreach (immutable uint i; 0 .. n)
		operation = stepContinue(test, interpreter, operation);
	expectStack(test, interpreter, expected);
	return operation;
}

public immutable(Operation*) stepAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	scope immutable ulong[] expected,
	immutable(Operation)* operation,
) {
	return stepNAndExpect(test, interpreter, 1, expected, operation);
}

void verifyStackEntry(ref ByteCodeWriter writer, immutable size_t n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(n));
}

@trusted immutable(Operation*) stepContinue(
	ref Test test,
	scope ref Interpreter interpreter,
	immutable Operation* operation,
) {
	immutable Operation* nextOperation = operation.fn(interpreter, operation + 1).operationPtr;
	verify(nextOperation.fn != &opStopInterpretation);
	return nextOperation;
}

public @trusted void stepExit(ref Test test, scope ref Interpreter interpreter, immutable Operation* operation) {
	immutable Operation* nextOperation = operation.fn(interpreter, operation).operationPtr;
	verify(nextOperation.fn == &opStopInterpretation);
}

void expectStack(ref Test test, scope ref Interpreter interpreter, scope immutable ulong[] expected) {
	expectDataStack(test, interpreter.dataStack, expected);
}

immutable(ByteCodeIndex) curByteCodeIndex(scope ref Interpreter a, immutable Operation* operation) {
	return immutable ByteCodeIndex(nextByteCodeIndex(a, operation).index);
}
