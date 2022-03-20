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
import interpret.runBytecode :
	byteCode,
	Interpreter,
	nextByteCodeIndex,
	opBreak,
	opCall,
	opStopInterpretation,
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
	writeBreak,
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
import model.diag : FilesInfo, filesInfoForSingle;
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
import util.col.arr : emptyArr;
import util.col.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.col.stack : stackBegin, pop, push;
import util.col.str : SafeCStr;
import util.lineAndColumnGetter : lineAndColumnGetterForEmptyFile;
import util.memory : allocate;
import util.path : emptyPathsInfo, Path, PathsInfo, rootPath;
import util.ptr : ptrTrustMe_mut;
import util.sourceRange : FileIndex, Pos;
import util.sym : shortSym, Sym;
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
	static immutable FunNameAndPos[][] dummy = [[immutable FunNameAndPos(shortSym("a"), immutable Pos(0))]];
	return fullIndexDictOfArr!(FileIndex, FunNameAndPos[])(dummy);
}

void doInterpret(
	ref Test test,
	ref immutable ByteCode byteCode,
	scope void delegate(scope ref Interpreter, immutable(Operation)*) @system @nogc nothrow runInterpreter,
) {
	immutable Path emptyPath = rootPath(test.allPaths, shortSym("test"));
	immutable FilesInfo filesInfo = filesInfoForSingle(test.alloc,
		emptyPath,
		lineAndColumnGetterForEmptyFile(test.alloc));
	immutable LowFun[1] lowFun = [immutable LowFun(
		immutable LowFunSource(allocate(test.alloc, immutable LowFunSource.Generated(
			shortSym("test"), emptyArr!LowType))),
		nat64Type,
		immutable LowFunParamsKind(false, false),
		emptyArr!LowParam,
		immutable LowFunBody(immutable LowFunBody.Extern(false)))];
	immutable LowProgram lowProgram = immutable LowProgram(
		ConcreteFunToLowFunIndex(),
		immutable AllConstantsLow(
			emptyArr!SafeCStr,
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
	withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_) @trusted {
		immutable PathsInfo pathsInfo = emptyPathsInfo;
		withInterpreter!void(
			test.alloc, extern_, lowProgram, byteCode, test.allSymbols, test.allPaths, pathsInfo, filesInfo,
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
	writePushConstants(writer, source, [1, 2]);
	writeBreak(writer, source);

	immutable ByteCodeIndex delayed = writeCallDelayed(writer, source, argsFirstStackEntry, 1);
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeBreak(writer, source);
	writeReturn(writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeBreak(writer, source);
	writeFnBinary!fnWrapAddIntegral(writer, source);
	writeReturn(writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, immutable(Operation)* operation) {
		stepUntilBreakAndExpect(test, interpreter, [1, 2], operation);
		verify(operation.fn == &opCall);
		stepUntilBreakAndExpect(test, interpreter, [1, 2], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		// opCall returns the first operation and moves nextOperation to the one after.
		// + 1 because we are after the break.
		verify(operation == &byteCode.byteCode[fIndex.index + 1]);
		verify(curByteCodeIndex(interpreter, operation) == immutable ByteCodeIndex(fIndex.index + 1));
		stepUntilBreakAndExpect(test, interpreter, [3], operation); // return
		// + 1 because we are after the break.
		verify(curByteCodeIndex(interpreter, operation) == immutable ByteCodeIndex(afterCall.index + 1));
		expectReturnStack(test, interpreter, []);
		stepUntilExit(interpreter, operation);
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
	immutable ByteCodeIndex delayed = writePushFunPtrDelayed(writer, source);
	writePushConstants(writer, source, [1, 2]);
	writeBreak(writer, source);
	writeCallFunPtr(writer, source, argsFirstStackEntry, 1);
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeBreak(writer, source);
	writeReturn(writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeBreak(writer, source);
	writeFnBinary!fnWrapAddIntegral(writer, source);
	writeReturn(writer, source);

	fillDelayedCall(writer, delayed, fIndex);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter interpreter, immutable(Operation)* operation) {
		stepUntilBreakAndExpect(
			test,
			interpreter,
			[fIndex.index, 1, 2],
			operation);
		// call-fun-ptr
		stepUntilBreakAndExpect(test, interpreter, [1, 2], operation);
		expectReturnStack(test, interpreter, [afterCall]);
		verify(curByteCodeIndex(interpreter, operation) == immutable ByteCodeIndex(fIndex.index + 1));
		stepUntilBreakAndExpect(test, interpreter, [3], operation); // +
		verify(curByteCodeIndex(interpreter, operation) == immutable ByteCodeIndex(afterCall.index + 1));
		expectReturnStack(test, interpreter, []);
		stepUntilExit(interpreter, operation);
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
	writePushConstant(writer, source, 0);
	writeBreak(writer, source);
	immutable SwitchDelayed delayed = writeSwitch0ToNDelay(writer, source, 2);
	fillDelayedSwitchEntry(writer, delayed, 0);
	writeBreak(writer, source);
	immutable ByteCodeIndex firstCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, 3);
	writeBreak(writer, source);
	setNextStackEntry(writer, startStack);
	immutable ByteCodeIndex jumpIndex = writeJumpDelayed(writer, source);
	fillDelayedSwitchEntry(writer, delayed, 1);
	writeBreak(writer, source);
	immutable ByteCodeIndex secondCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, 5);
	fillInJumpDelayed(writer, jumpIndex);
	writeBreak(writer, source);
	immutable ByteCodeIndex bottom = nextByteCodeIndex(writer);
	writeReturn(writer, source);
	immutable ByteCode byteCode =
		finishByteCode(writer, emptyArr!ubyte, immutable ByteCodeIndex(0), dummyFileToFuns());

	doInterpret(test, byteCode, (ref Interpreter interpreter, immutable(Operation)* operation) {
		 stepUntilBreakAndExpect(test, interpreter, [0], operation);
		stepUntilBreakAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter, operation) == firstCase);
		stepUntilBreakAndExpect(test, interpreter, [3], operation); // push 3
		stepUntilBreakAndExpect(test, interpreter, [3], operation); // jump
		verify(curByteCodeIndex(interpreter, operation) == bottom);
		stepUntilExit(interpreter, operation);
	});

	doInterpret(test, byteCode, (scope ref Interpreter interpreter, immutable(Operation)* operation) {
		// Manually change the value to '1' to test the other case.
		stepUntilBreakAndExpect(test, interpreter, [0], operation);
		pop(interpreter.dataStack);
		push(interpreter.dataStack, 1);
		expectStack(test, interpreter, [1]);
		stepUntilBreakAndExpect(test, interpreter, [], operation);
		verify(curByteCodeIndex(interpreter, operation) == secondCase);
		stepUntilBreakAndExpect(test, interpreter, [5], operation);
		verify(curByteCodeIndex(interpreter, operation) == bottom);
		stepUntilExit(interpreter, operation);
	});
}

void testDup(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [55, 65, 75]);
			writeBreak(writer, source);
			verifyStackEntry(writer, 3);
			writeDupEntry(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			verifyStackEntry(writer, 4);
			writeDupEntries(writer, source, immutable StackEntries(immutable StackEntry(2), 2));
			writeBreak(writer, source);
			verifyStackEntry(writer, 6);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [55, 65, 75], operation);
			stepUntilBreakAndExpect(test, interpreter, [55, 65, 75, 55], operation);
			stepUntilBreakAndExpect(test, interpreter, [55, 65, 75, 55, 75, 55], operation);
			stepUntilExit(interpreter, operation);
		});
}

void testRemoveOne(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2]);
			writeBreak(writer, source);
			writeRemove(writer, source, immutable StackEntries(immutable StackEntry(1), 1));
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [0, 1, 2], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, 2], operation);
			stepUntilExit(interpreter, operation);
		});
}

void testRemoveMany(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2, 3, 4]);
			writeBreak(writer, source);
			writeRemove(writer, source, immutable StackEntries(immutable StackEntry(1), 2));
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [0, 1, 2, 3, 4], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, 3, 4], operation);
			stepUntilExit(interpreter, operation);
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
			writePushConstants(writer, source, [u.n]);
			writeBreak(writer, source);
			writeDup(writer, source, immutable StackEntry(0), 0, 4);
			writeBreak(writer, source);
			writeDup(writer, source, immutable StackEntry(0), 4, 2);
			writeBreak(writer, source);
			writeDup(writer, source, immutable StackEntry(0), 6, 1);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [u.n], operation);
			stepUntilBreakAndExpect(test, interpreter, [u.n, 0x01234567], operation);
			stepUntilBreakAndExpect(test, interpreter, [u.n, 0x01234567, 0x89ab], operation);
			stepUntilBreakAndExpect(test, interpreter, [u.n, 0x01234567, 0x89ab, 0xcd], operation);
			stepUntilExit(interpreter, operation);
		});
}

void testPack(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0x01234567, 0x89ab, 0xcd]);
			writeBreak(writer, source);
			scope immutable PackField[3] fields = [
				immutable PackField(0, 0, 4),
				immutable PackField(8, 4, 2),
				immutable PackField(16, 6, 1)];
			scope immutable Pack pack = immutable Pack(3, 1, fields);
			writePack(writer, source, pack);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [0x01234567, 0x89ab, 0xcd], operation);
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
			stepUntilBreakAndExpect(test, interpreter, [u.n], operation);
			stepUntilExit(interpreter, operation);
		});
}

void testStackRef(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [1, 2]);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(1), 4);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			immutable ulong stack0 = cast(immutable ulong) stackBegin(interpreter.dataStack);
			immutable ulong stack3 =
				cast(immutable ulong) ((cast(immutable uint*) stackBegin(interpreter.dataStack)) + 3);

			stepUntilBreakAndExpect(test, interpreter, [1, 2], operation);
			stepUntilBreakAndExpect(test, interpreter, [1, 2, stack0], operation);
			stepUntilBreakAndExpect(test, interpreter, [1, 2, stack0, stack3], operation);
			stepUntilExit(interpreter, operation);
		});
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
			writePushConstant(writer, source, u.value);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 0, 4);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 4, 2);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 6, 1);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			immutable ulong value = u.value;
			stepUntilBreakAndExpect(test, interpreter, [value], operation);
			immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
			stepUntilBreakAndExpect(test, interpreter, [value, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [value, 0x01234567], operation);
			stepUntilBreakAndExpect(test, interpreter, [value, 0x01234567, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [value, 0x01234567, 0x89ab], operation);
			stepUntilBreakAndExpect(test, interpreter, [value, 0x01234567, 0x89ab, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [value, 0x01234567, 0x89ab, 0xcd], operation);
			stepUntilExit(interpreter, operation);
		});
}

@trusted void testReadWords(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [1, 2, 3]);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 8, 16);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [1, 2, 3], operation);
			immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
			stepUntilBreakAndExpect(test, interpreter, [1, 2, 3, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [1, 2, 3, 2, 3], operation);
			stepUntilExit(interpreter, operation);
		});
}

@trusted void testWriteSubword(ref Test test) {
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

	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstant(writer, source, 0);
			writeBreak(writer, source);

			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);

			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 0, 4);
			writeBreak(writer, source);

			writeStackRef(writer, source, immutable StackEntry(0));
			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 4, 2);
			writeBreak(writer, source);

			writeStackRef(writer, source, immutable StackEntry(0));
			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 6, 1);
			writeBreak(writer, source);

			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);

			stepUntilBreakAndExpect(test, interpreter, [0], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, interpreter, [toUlong(immutable S(0x89abcdef, 0, 0, 0)), ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, interpreter,
				[toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0)), ptr, 0x0123456789abcdef],
				operation);
			stepUntilBreakAndExpect(test, interpreter, [toUlong(immutable S(0x89abcdef, 0xcdef, 0xef, 0))], operation);
			stepUntilExit(interpreter, operation);
		});
}

@trusted void testWriteWords(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0, 0, 0]);
			writeBreak(writer, source);
			writeStackRef(writer, source, immutable StackEntry(0));
			writeBreak(writer, source);
			writePushConstants(writer, source, [1, 2]);
			writeBreak(writer, source);
			writeWrite(writer, source, 8, 16);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Interpreter interpreter, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, interpreter, [0, 0, 0], operation);
			immutable ulong ptr = cast(immutable ulong) stackBegin(interpreter.dataStack);
			stepUntilBreakAndExpect(test, interpreter, [0, 0, 0, ptr], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, 0, 0, ptr, 1, 2], operation);
			stepUntilBreakAndExpect(test, interpreter, [0, 1, 2], operation);
			stepUntilExit(interpreter, operation);
		});
}

void stepUntilBreakAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	scope immutable ulong[] expected,
	ref immutable(Operation)* operation,
) {
	stepUntilBreak(interpreter, operation);
	expectStack(test, interpreter, expected);
}

void verifyStackEntry(ref ByteCodeWriter writer, immutable size_t n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(n));
}

// Actually steps until the operation after the break.
// This is designed to work the same whether 'nextOperation' is implemented with tail recursion or returns.
// In the tail-recursive case, the while loop should be redundant,
// since only an opBreak (or opStopInterpretation) instruction returns.
@trusted void stepUntilBreak(scope ref Interpreter interpreter, ref immutable(Operation)* operation) {
	do {
		verify(operation.fn != &opStopInterpretation);
		operation = operation.fn(interpreter, operation + 1).operationPtr;
	} while ((operation - 1).fn != &opBreak);
}

@trusted void stepUntilExit(scope ref Interpreter interpreter, ref immutable(Operation)* operation) {
	while (operation.fn != &opStopInterpretation)
		operation = operation.fn(interpreter, operation + 1).operationPtr;
}

public @trusted void stepUntilExitAndExpect(
	ref Test test,
	scope ref Interpreter interpreter,
	scope immutable ulong[] expected,
	ref immutable(Operation)* operation,
) {
	stepUntilExit(interpreter, operation);
	expectStack(test, interpreter, expected);
}

void expectStack(ref Test test, scope ref Interpreter interpreter, scope immutable ulong[] expected) {
	expectDataStack(test, interpreter.dataStack, expected);
}

immutable(ByteCodeIndex) curByteCodeIndex(scope ref Interpreter a, immutable Operation* operation) {
	return immutable ByteCodeIndex(nextByteCodeIndex(a, operation).index);
}
