module test.testInterpreter;

@safe @nogc nothrow: // not pure

import interpret.applyFn : fnWrapAddIntegral;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	castImmutable,
	FileToFuns,
	FunNameAndPos,
	FunPtrToOperationPtr,
	initialOperationPointer,
	Operation,
	Operations;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	fillDelayedCall,
	fillDelayedFunPtr,
	fillDelayedSwitchEntry,
	fillInJumpDelayed,
	finishOperations,
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
import interpret.extern_ : DynCallType, DynCallSig, Extern, FunPtr, FunPtrInputs;
import interpret.fakeExtern : FakeStdOutput, fakeSyntheticFunPtrs, withFakeExtern;
import interpret.funToReferences :
	FunPtrTypeToDynCallSig, FunToReferences, initFunToReferences, registerFunPtrReference;
import interpret.runBytecode : opCall, stepUntilBreak, stepUntilExit, withInterpreter;
import interpret.stacks : dataBegin, dataPop, dataPush, Stacks;
import lib.compiler : ExitCode;
import lower.lowExprHelpers : nat64Type;
import model.diag : FilesInfo, filesInfoForSingle;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ConcreteFunToLowFunIndex,
	LowExternPtrType,
	LowFun,
	LowFunBody,
	LowFunIndex,
	LowFunParamsKind,
	LowFunPtrType,
	LowFunSource,
	LowProgram,
	LowRecord,
	LowType,
	LowUnion;
import model.typeLayout : Pack, PackField;
import test.testUtil : expectDataStack, expectReturnStack, Test;
import util.alloc.alloc : Alloc;
import util.col.arr : castImmutable;
import util.col.fullIndexDict : emptyFullIndexDict, fullIndexDictOfArr;
import util.lineAndColumnGetter : lineAndColumnGetterForEmptyFile;
import util.memory : allocate;
import util.path : emptyPathsInfo, Path, PathsInfo, rootPath;
import util.ptr : castImmutable, castNonScope, castNonScope_mut;
import util.sourceRange : FileIndex, Pos;
import util.sym : shortSym;
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
	ByteCodeWriter writer = newByteCodeWriter(castNonScope_mut(&alloc));
	writeBytecode(writer, emptyByteCodeSource);
	return dummyByteCode(castImmutable(finishOperations(writer)));
}

immutable(ByteCode) dummyByteCode(immutable Operations operations) {
	return immutable ByteCode(
		operations,
		immutable FunPtrToOperationPtr(),
		dummyFileToFuns(),
		[],
		immutable ByteCodeIndex(0));
}

immutable(FileToFuns) dummyFileToFuns() {
	static immutable FunNameAndPos[][] dummy = [[immutable FunNameAndPos(shortSym("a"), immutable Pos(0))]];
	return fullIndexDictOfArr!(FileIndex, FunNameAndPos[])(dummy);
}

void doInterpret(
	ref Test test,
	ref immutable ByteCode byteCode,
	scope void delegate(ref Stacks stacks, immutable(Operation)*) @system @nogc nothrow runInterpreter,
) {
	immutable Path emptyPath = rootPath(test.allPaths, shortSym("test"));
	immutable FilesInfo filesInfo = filesInfoForSingle(test.alloc,
		emptyPath,
		lineAndColumnGetterForEmptyFile(test.alloc));
	immutable LowFun[1] lowFun = [immutable LowFun(
		immutable LowFunSource(allocate(test.alloc, immutable LowFunSource.Generated(shortSym("test"), []))),
		nat64Type,
		immutable LowFunParamsKind(false, false),
		[],
		immutable LowFunBody(immutable LowFunBody.Extern(false, shortSym("bogus"))))];
	immutable LowProgram lowProgram = immutable LowProgram(
		ConcreteFunToLowFunIndex(),
		immutable AllConstantsLow([], [], []),
		immutable AllLowTypes(
			emptyFullIndexDict!(LowType.ExternPtr, LowExternPtrType),
			emptyFullIndexDict!(LowType.FunPtr, LowFunPtrType),
			emptyFullIndexDict!(LowType.Record, LowRecord),
			emptyFullIndexDict!(LowType.Union, LowUnion)),
		fullIndexDictOfArr!(LowFunIndex, LowFun)(lowFun),
		immutable LowFunIndex(0),
		[]);
	withFakeExtern(test.alloc, test.allSymbols, (scope ref Extern extern_, scope ref FakeStdOutput _) @trusted {
		immutable PathsInfo pathsInfo = emptyPathsInfo;
		withInterpreter!void(
			extern_.doDynCall, lowProgram, byteCode, test.allSymbols, test.allPaths, pathsInfo, filesInfo,
			(ref Stacks stacks) {
				runInterpreter(stacks, initialOperationPointer(byteCode));
			});
		return immutable ExitCode(0);
	});
}

public @trusted void interpreterTest(
	ref Test test,
	scope void delegate(ref ByteCodeWriter, immutable ByteCodeSource source) @safe @nogc nothrow writeBytecode,
	scope void delegate(ref Stacks, immutable(Operation)*) @system @nogc nothrow runInterpreter,
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

	Operations operations = finishOperations(writer);
	fillDelayedCall(operations, delayed, castImmutable(&operations.byteCode[fIndex.index]));
	immutable ByteCode byteCode = dummyByteCode(castImmutable(operations));

	doInterpret(test, byteCode, (ref Stacks stacks, immutable(Operation)* operation) {
		stepUntilBreakAndExpect(test, stacks, [1, 2], operation);
		verify(operation.fn == &opCall);
		stepUntilBreakAndExpect(test, stacks, [1, 2], operation);
		expectReturnStack(test, byteCode, stacks, [afterCall]);
		// opCall returns the first operation and moves nextOperation to the one after.
		// + 1 because we are after the break.
		verify(operation == &byteCode.byteCode[fIndex.index + 1]);
		verify(curByteCodeIndex(byteCode, operation) == immutable ByteCodeIndex(fIndex.index + 1));
		stepUntilBreakAndExpect(test, stacks, [3], operation); // return
		// + 1 because we are after the break.
		verify(curByteCodeIndex(byteCode, operation) == immutable ByteCodeIndex(afterCall.index + 1));
		expectDataStack(test, stacks, [3]);
		expectReturnStack(test, byteCode, stacks, []);
		stepUntilExitAndExpect(test, stacks, [3], operation);
	});
}

void testCallFunPtr(ref Test test) {
	// Code is:
	// push address of 'f'
	// push 1, 2
	// call-fun-ptr
	// return
	// # f nat64(a nat64, b nat64):
	// +
	// return

	immutable DynCallType[3] sigTypes = [DynCallType.nat64, DynCallType.nat64, DynCallType.nat64];
	immutable DynCallSig sig = immutable DynCallSig(sigTypes);
	immutable DynCallSig[1] sigsStorage = [castNonScope(sig)];
	immutable FunPtrTypeToDynCallSig funPtrTypeToDynCallSig =
		castNonScope(fullIndexDictOfArr!(LowType.FunPtr, DynCallSig)(castNonScope(sigsStorage)));
	immutable LowFunIndex funIndex = immutable LowFunIndex(0);
	immutable LowType.FunPtr funType = immutable LowType.FunPtr(0);
	immutable ByteCodeSource source = emptyByteCodeSource;

	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
	FunToReferences funToReferences = initFunToReferences(test.alloc, funPtrTypeToDynCallSig, 1);

	immutable StackEntry argsFirstStackEntry = getNextStackEntry(writer);

	immutable ByteCodeIndex delayed = writePushFunPtrDelayed(writer, source);
	registerFunPtrReference(test.alloc, funToReferences, funType, funIndex, delayed);

	writePushConstants(writer, source, [1, 2]);
	writeBreak(writer, source);
	writeCallFunPtr(writer, source, argsFirstStackEntry, sig);
	immutable ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeBreak(writer, source);
	writeReturn(writer, source);
	immutable ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	// TODO: can't break inside a fun-ptr now..
	//writeBreak(writer, source);
	writeFnBinary!fnWrapAddIntegral(writer, source);
	writeReturn(writer, source);

	Operations operations = finishOperations(writer);

	immutable FunPtrInputs[1] inputs = [
		immutable FunPtrInputs(funIndex, castNonScope(sig), &castImmutable(operations.byteCode)[fIndex.index]),
	];
	immutable FunPtr funPtr = fakeSyntheticFunPtrs(test.alloc, castNonScope(inputs))[0];
	fillDelayedFunPtr(operations, delayed, funPtr);
	immutable ByteCode byteCode = dummyByteCode(castImmutable(operations));

	doInterpret(test, byteCode, (ref Stacks stacks, immutable(Operation)* operation) {
		stepUntilBreakAndExpect(
			test,
			stacks,
			[cast(ulong) funPtr.fn, 1, 2],
			operation);
		stepUntilBreakAndExpect(test, stacks, [3], operation); // +
		verify(curByteCodeIndex(byteCode, operation) == immutable ByteCodeIndex(afterCall.index + 1));
		expectReturnStack(test, byteCode, stacks, []);
		stepUntilExitAndExpect(test, stacks, [3], operation);
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
	immutable ByteCode byteCode = dummyByteCode(castImmutable(finishOperations(writer)));

	doInterpret(test, byteCode, (ref Stacks stacks, immutable(Operation)* operation) {
		stepUntilBreakAndExpect(test, stacks, [0], operation);
		stepUntilBreakAndExpect(test, stacks, [], operation);
		verify(curByteCodeIndex(byteCode, operation) == firstCase);
		stepUntilBreakAndExpect(test, stacks, [3], operation); // push 3
		stepUntilBreakAndExpect(test, stacks, [3], operation); // jump
		verify(curByteCodeIndex(byteCode, operation) == bottom);
		stepUntilExitAndExpect(test, stacks, [3], operation);
	});

	doInterpret(test, byteCode, (ref Stacks stacks, immutable(Operation)* operation) {
		// Manually change the value to '1' to test the other case.
		stepUntilBreakAndExpect(test, stacks, [0], operation);
		dataPop(stacks);
		dataPush(stacks, 1);
		expectDataStack(test, stacks, [1]);
		stepUntilBreakAndExpect(test, stacks, [], operation);
		verify(curByteCodeIndex(byteCode, operation) == secondCase);
		stepUntilBreakAndExpect(test, stacks, [5], operation);
		verify(curByteCodeIndex(byteCode, operation) == bottom);
		stepUntilExitAndExpect(test, stacks, [5], operation);
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
			verifyStackEntry(writer, 6);
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [55, 65, 75], operation);
			stepUntilBreakAndExpect(test, stacks, [55, 65, 75, 55], operation);
			stepUntilExitAndExpect(test, stacks, [55, 65, 75, 55, 75, 55], operation);
		});
}

void testRemoveOne(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2]);
			writeBreak(writer, source);
			writeRemove(writer, source, immutable StackEntries(immutable StackEntry(1), 1));
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [0, 1, 2], operation);
			stepUntilExitAndExpect(test, stacks, [0, 2], operation);
		});
}

void testRemoveMany(ref Test test) {
	interpreterTest(
		test,
		(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2, 3, 4]);
			writeBreak(writer, source);
			writeRemove(writer, source, immutable StackEntries(immutable StackEntry(1), 2));
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [0, 1, 2, 3, 4], operation);
			stepUntilExitAndExpect(test, stacks, [0, 3, 4], operation);
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
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [u.n], operation);
			stepUntilBreakAndExpect(test, stacks, [u.n, 0x01234567], operation);
			stepUntilBreakAndExpect(test, stacks, [u.n, 0x01234567, 0x89ab], operation);
			stepUntilExitAndExpect(test, stacks, [u.n, 0x01234567, 0x89ab, 0xcd], operation);
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
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [0x01234567, 0x89ab, 0xcd], operation);
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
			stepUntilExitAndExpect(test, stacks, [u.n], operation);
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
		(ref Stacks stacks, immutable(Operation)* operation) {
			immutable ulong stack0 = cast(immutable ulong) dataBegin(stacks);
			immutable ulong stack3 =
				cast(immutable ulong) ((cast(immutable uint*) dataBegin(stacks)) + 3);
			stepUntilBreakAndExpect(test, stacks, [1, 2], operation);
			stepUntilBreakAndExpect(test, stacks, [1, 2, stack0], operation);
			stepUntilBreakAndExpect(test, stacks, [1, 2, stack0, stack3], operation);
			stepUntilExitAndExpect(test, stacks, [1, 2, stack0, stack3], operation);
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
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			immutable ulong value = u.value;
			stepUntilBreakAndExpect(test, stacks, [value], operation);
			immutable ulong ptr = cast(immutable ulong) dataBegin(stacks);
			stepUntilBreakAndExpect(test, stacks, [value, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [value, 0x01234567], operation);
			stepUntilBreakAndExpect(test, stacks, [value, 0x01234567, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [value, 0x01234567, 0x89ab], operation);
			stepUntilBreakAndExpect(test, stacks, [value, 0x01234567, 0x89ab, ptr], operation);
			stepUntilExitAndExpect(test, stacks, [value, 0x01234567, 0x89ab, 0xcd], operation);
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
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [1, 2, 3], operation);
			immutable ulong ptr = cast(immutable ulong) dataBegin(stacks);
			stepUntilBreakAndExpect(test, stacks, [1, 2, 3, ptr], operation);
			stepUntilExitAndExpect(test, stacks, [1, 2, 3, 2, 3], operation);
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

			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			immutable ulong ptr = cast(immutable ulong) dataBegin(stacks);

			stepUntilBreakAndExpect(test, stacks, [0], operation);
			stepUntilBreakAndExpect(test, stacks, [0, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [0, ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, stacks, [toUlong(immutable S(0x89abcdef, 0, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, stacks, [toUlong(immutable S(0x89abcdef, 0, 0, 0)), ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, stacks, [toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, stacks,
				[toUlong(immutable S(0x89abcdef, 0xcdef, 0, 0)), ptr, 0x0123456789abcdef],
				operation);
			stepUntilExitAndExpect(test, stacks, [toUlong(immutable S(0x89abcdef, 0xcdef, 0xef, 0))], operation);
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
			writeReturn(writer, source);
		},
		(ref Stacks stacks, immutable(Operation)* operation) {
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0], operation);
			immutable ulong ptr = cast(immutable ulong) dataBegin(stacks);
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0, ptr, 1, 2], operation);
			stepUntilExitAndExpect(test, stacks, [0, 1, 2], operation);
		});
}

@system void stepUntilBreakAndExpect(
	ref Test test,
	ref Stacks stacks,
	scope immutable ulong[] expected,
	ref immutable(Operation)* operation,
) {
	stepUntilBreak(stacks, operation);
	expectDataStack(test, stacks, expected);
}

void verifyStackEntry(ref ByteCodeWriter writer, immutable size_t n) {
	verify(getNextStackEntry(writer) == immutable StackEntry(n));
}

public @trusted void stepUntilExitAndExpect(
	ref Test test,
	ref Stacks stacks,
	scope immutable ulong[] expected,
	ref immutable(Operation)* operation,
) {
	stepUntilExit(stacks, operation);
	expectDataStack(test, stacks, expected);
	foreach (immutable size_t i; 0 .. expected.length)
		dataPop(stacks);
}

@trusted immutable(ByteCodeIndex) curByteCodeIndex(scope ref immutable ByteCode a, immutable Operation* operation) {
	return immutable ByteCodeIndex(operation - a.byteCode.ptr);
}
