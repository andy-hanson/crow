module test.testInterpreter;

@safe @nogc nothrow: // not pure

import frontend.showModel : ShowCtx;
import frontend.storage : Storage;
import interpret.applyFn : fnWrapAddIntegral;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	FunPointerToOperationPointer,
	initialOperationPointer,
	Operation,
	Operations;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	fillDelayedCall,
	fillDelayedFunPointer,
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
	writeCallFunPointer,
	writeDup,
	writeDupEntries,
	writeDupEntry,
	writeFnBinary,
	writePack,
	writePushConstant,
	writePushConstants,
	writePushFunPointerDelayed,
	writeJumpDelayed,
	writeRead,
	writeRemove,
	writeReturn,
	writeStackRef,
	writeSwitch0ToNDelay,
	writeWrite;
import interpret.extern_ : DynCallType, DynCallSig, Extern, FunPointer, FunPointerInputs;
import interpret.fakeExtern : fakeSyntheticFunPointers, unreachableWriteCb, withFakeExtern;
import interpret.funToReferences :
	FunPointerTypeToDynCallSig, FunToReferences, initFunToReferences, registerFunPointerReference;
import interpret.runBytecode : opCall, stepUntilBreak, stepUntilExit, withInterpreter;
import interpret.stacks : dataBegin, dataPop, dataPush, Stacks;
import lower.lowExprHelpers : nat64Type;
import model.lowModel :
	AllConstantsLow,
	AllLowTypes,
	ConcreteFunToLowFunIndex,
	LowExternType,
	LowFun,
	LowFunBody,
	LowFunIndex,
	LowFunPointerType,
	LowFunSource,
	LowProgram,
	LowRecord,
	LowVar,
	LowVarIndex,
	LowType,
	LowUnion,
	PrimitiveType;
import model.model : VarKind;
import model.typeLayout : Pack, PackField;
import test.testUtil : expectDataStack, expectReturnStack, Test, withShowDiagCtxForTestImpure;
import util.alloc.alloc : Alloc;
import util.col.array : small;
import util.col.enumMap : EnumMap;
import util.col.fullIndexMap : emptyFullIndexMap, fullIndexMapOfArr;
import util.memory : allocate;
import util.sourceRange : Pos;
import util.symbol : symbol;
import util.util : castNonScope, castNonScope_ref, ptrTrustMe;
import versionInfo : OS, versionInfoForInterpret;

void testInterpreter(ref Test test) {
	testCall(test);
	testCallFunPointer(test);
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

ByteCode makeByteCode(
	ref Alloc alloc,
	in void delegate(ref ByteCodeWriter, ByteCodeSource source) @safe @nogc nothrow writeBytecode,
) {
	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe(alloc));
	writeBytecode(writer, emptyByteCodeSource);
	return dummyByteCode(finishOperations(writer));
}

ByteCode dummyByteCode(return scope Operations operations) =>
	ByteCode(
		operations,
		FunPointerToOperationPointer(),
		[],
		EnumMap!(VarKind, size_t)([0, 0]),
		ByteCodeIndex(0));

void doInterpret(
	ref Test test,
	in ByteCode byteCode,
	in void delegate(ref Stacks stacks, Operation*) @system @nogc nothrow runInterpreter,
) {
	LowFun[1] lowFun = [LowFun(
		LowFunSource(allocate(test.alloc, LowFunSource.Generated(symbol!"test", []))),
		nat64Type,
		[],
		LowFunBody(LowFunBody.Extern(symbol!"bogus")))];
	LowProgram lowProgram = LowProgram(
		versionInfoForInterpret(OS.linux),
		ConcreteFunToLowFunIndex(),
		AllConstantsLow([], [], []),
		emptyFullIndexMap!(LowVarIndex, LowVar),
		AllLowTypes(
			emptyFullIndexMap!(LowType.Extern, LowExternType),
			emptyFullIndexMap!(LowType.FunPointer, LowFunPointerType),
			emptyFullIndexMap!(LowType.Record, LowRecord),
			emptyFullIndexMap!(LowType.Union, LowUnion)),
		fullIndexMapOfArr!(LowFunIndex, LowFun)(lowFun),
		LowFunIndex(0),
		[]);
	withFakeExtern!void(test.alloc, unreachableWriteCb, (scope ref Extern extern_) {
		Storage storage = Storage(test.metaAlloc);
		withShowDiagCtxForTestImpure(test, storage, (in ShowCtx ctx) {
			withInterpreter!void(test.alloc, extern_.doDynCall, ctx, lowProgram, byteCode, (ref Stacks stacks) {
				runInterpreter(stacks, initialOperationPointer(byteCode));
			});
		});
	});
}

public void interpreterTest(
	ref Test test,
	in void delegate(scope ref ByteCodeWriter, ByteCodeSource source) @safe @nogc nothrow writeBytecode,
	in void delegate(scope ref Stacks, Operation*) @system @nogc nothrow runInterpreter,
) {
	ByteCode byteCode = makeByteCode(test.alloc, writeBytecode);
	doInterpret(test, byteCode, runInterpreter);
}

ByteCodeSource emptyByteCodeSource() =>
	ByteCodeSource(LowFunIndex(0), Pos(0));

void testCall(ref Test test) {
	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
	ByteCodeSource source = emptyByteCodeSource;

	// Code is:
	// push 1, 2
	// call f
	// return
	// # f nat(a nat, b nat):
	// +
	// return

	StackEntry argsFirstStackEntry = getNextStackEntry(writer);
	writePushConstants(writer, source, [1, 2]);
	writeBreak(writer, source);

	ByteCodeIndex delayed = writeCallDelayed(writer, source, argsFirstStackEntry, 1);
	ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeBreak(writer, source);
	writeReturn(writer, source);
	ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeBreak(writer, source);
	writeFnBinary(writer, source, &fnWrapAddIntegral);
	writeReturn(writer, source);

	Operations operations = finishOperations(writer);
	fillDelayedCall(operations, delayed, &operations.byteCode[fIndex.index]);
	ByteCode byteCode = dummyByteCode(operations);

	doInterpret(test, byteCode, (ref Stacks stacks, Operation* operation) {
		stepUntilBreakAndExpect(test, stacks, [1, 2], operation);
		assert(operation.fn == &opCall);
		stepUntilBreakAndExpect(test, stacks, [1, 2], operation);
		expectReturnStack(test, byteCode, stacks, [afterCall]);
		// opCall returns the first operation and moves nextOperation to the one after.
		// + 1 because we are after the break.
		assert(operation == &byteCode.byteCode[fIndex.index + 1]);
		assert(curByteCodeIndex(byteCode, operation) == ByteCodeIndex(fIndex.index + 1));
		stepUntilBreakAndExpect(test, stacks, [3], operation); // return
		// + 1 because we are after the break.
		assert(curByteCodeIndex(byteCode, operation) == ByteCodeIndex(afterCall.index + 1));
		expectDataStack(test, stacks, [3]);
		expectReturnStack(test, byteCode, stacks, []);
		stepUntilExitAndExpect(test, stacks, [3], operation);
	});
}

void testCallFunPointer(ref Test test) {
	// Code is:
	// push address of 'f'
	// push 1, 2
	// call-fun-pointer
	// return
	// # f nat64(a nat64, b nat64):
	// +
	// return

	DynCallType[3] sigTypes = [
		DynCallType(PrimitiveType.nat64),
		DynCallType(PrimitiveType.nat64),
		DynCallType(PrimitiveType.nat64),
	];
	DynCallSig sig = DynCallSig(small!DynCallType(sigTypes));
	DynCallSig[1] sigsStorage = [castNonScope(sig)];
	FunPointerTypeToDynCallSig funPtrTypeToDynCallSig =
		castNonScope(fullIndexMapOfArr!(LowType.FunPointer, DynCallSig)(castNonScope(sigsStorage)));
	LowFunIndex funIndex = LowFunIndex(0);
	LowType.FunPointer funType = LowType.FunPointer(0);
	ByteCodeSource source = emptyByteCodeSource;

	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
	FunToReferences funToReferences = initFunToReferences(test.alloc, funPtrTypeToDynCallSig, 1);

	StackEntry argsFirstStackEntry = getNextStackEntry(writer);

	ByteCodeIndex delayed = writePushFunPointerDelayed(writer, source);
	registerFunPointerReference(test.alloc, funToReferences, funType, funIndex, delayed);

	writePushConstants(writer, source, [1, 2]);
	writeBreak(writer, source);
	writeCallFunPointer(writer, source, argsFirstStackEntry, castNonScope_ref(sig));
	ByteCodeIndex afterCall = nextByteCodeIndex(writer);
	writeBreak(writer, source);
	writeReturn(writer, source);
	ByteCodeIndex fIndex = nextByteCodeIndex(writer);

	// f:
	writeFnBinary(writer, source, &fnWrapAddIntegral);
	writeReturn(writer, source);

	Operations operations = finishOperations(writer);

	FunPointerInputs[1] inputs = [
		FunPointerInputs(funIndex, castNonScope(sig), &operations.byteCode[fIndex.index]),
	];
	FunPointer funPtr = fakeSyntheticFunPointers(test.alloc, castNonScope(inputs))[0];
	fillDelayedFunPointer(operations, delayed, funPtr);
	ByteCode byteCode = dummyByteCode(operations);

	doInterpret(test, byteCode, (ref Stacks stacks, Operation* operation) {
		stepUntilBreakAndExpect(test, stacks, [funPtr.asUlong, 1, 2], operation);
		stepUntilBreakAndExpect(test, stacks, [3], operation); // +
		assert(curByteCodeIndex(byteCode, operation) == ByteCodeIndex(afterCall.index + 1));
		expectReturnStack(test, byteCode, stacks, []);
		stepUntilExitAndExpect(test, stacks, [3], operation);
	});
}

void testSwitchAndJump(ref Test test) {
	ByteCodeWriter writer = newByteCodeWriter(test.allocPtr);
	ByteCodeSource source = emptyByteCodeSource;

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
	StackEntry startStack = getNextStackEntry(writer);
	writePushConstant(writer, source, 0);
	writeBreak(writer, source);
	SwitchDelayed delayed = writeSwitch0ToNDelay(writer, source, 2);
	fillDelayedSwitchEntry(writer, delayed, 0);
	writeBreak(writer, source);
	ByteCodeIndex firstCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, 3);
	writeBreak(writer, source);
	setNextStackEntry(writer, startStack);
	ByteCodeIndex jumpIndex = writeJumpDelayed(writer, source);
	fillDelayedSwitchEntry(writer, delayed, 1);
	writeBreak(writer, source);
	ByteCodeIndex secondCase = nextByteCodeIndex(writer);
	writePushConstant(writer, source, 5);
	fillInJumpDelayed(writer, jumpIndex);
	writeBreak(writer, source);
	ByteCodeIndex bottom = nextByteCodeIndex(writer);
	writeReturn(writer, source);
	ByteCode byteCode = dummyByteCode(finishOperations(writer));

	doInterpret(test, byteCode, (ref Stacks stacks, Operation* operation) {
		stepUntilBreakAndExpect(test, stacks, [0], operation);
		stepUntilBreakAndExpect(test, stacks, [], operation);
		assert(curByteCodeIndex(byteCode, operation) == firstCase);
		stepUntilBreakAndExpect(test, stacks, [3], operation); // push 3
		stepUntilBreakAndExpect(test, stacks, [3], operation); // jump
		assert(curByteCodeIndex(byteCode, operation) == bottom);
		stepUntilExitAndExpect(test, stacks, [3], operation);
	});

	doInterpret(test, byteCode, (ref Stacks stacks, Operation* operation) {
		// Manually change the value to '1' to test the other case.
		stepUntilBreakAndExpect(test, stacks, [0], operation);
		dataPop(stacks);
		dataPush(stacks, 1);
		expectDataStack(test, stacks, [1]);
		stepUntilBreakAndExpect(test, stacks, [], operation);
		assert(curByteCodeIndex(byteCode, operation) == secondCase);
		stepUntilBreakAndExpect(test, stacks, [5], operation);
		assert(curByteCodeIndex(byteCode, operation) == bottom);
		stepUntilExitAndExpect(test, stacks, [5], operation);
	});
}

void testDup(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [55, 65, 75]);
			writeBreak(writer, source);
			verifyStackEntry(writer, 3);
			writeDupEntry(writer, source, StackEntry(0));
			writeBreak(writer, source);
			verifyStackEntry(writer, 4);
			writeDupEntries(writer, source, StackEntries(StackEntry(2), 2));
			verifyStackEntry(writer, 6);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			stepUntilBreakAndExpect(test, stacks, [55, 65, 75], operation);
			stepUntilBreakAndExpect(test, stacks, [55, 65, 75, 55], operation);
			stepUntilExitAndExpect(test, stacks, [55, 65, 75, 55, 75, 55], operation);
		});
}

void testRemoveOne(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2]);
			writeBreak(writer, source);
			writeRemove(writer, source, StackEntries(StackEntry(1), 1));
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			stepUntilBreakAndExpect(test, stacks, [0, 1, 2], operation);
			stepUntilExitAndExpect(test, stacks, [0, 2], operation);
		});
}

void testRemoveMany(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [0, 1, 2, 3, 4]);
			writeBreak(writer, source);
			writeRemove(writer, source, StackEntries(StackEntry(1), 2));
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
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
	u.s = S(0x01234567, 0x89ab, 0xcd);
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [u.n]);
			writeBreak(writer, source);
			writeDup(writer, source, StackEntry(0), 0, 4);
			writeBreak(writer, source);
			writeDup(writer, source, StackEntry(0), 4, 2);
			writeBreak(writer, source);
			writeDup(writer, source, StackEntry(0), 6, 1);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			stepUntilBreakAndExpect(test, stacks, [u.n], operation);
			stepUntilBreakAndExpect(test, stacks, [u.n, 0x01234567], operation);
			stepUntilBreakAndExpect(test, stacks, [u.n, 0x01234567, 0x89ab], operation);
			stepUntilExitAndExpect(test, stacks, [u.n, 0x01234567, 0x89ab, 0xcd], operation);
		});
}

void testPack(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [0x01234567, 0x89ab, 0xcd]);
			writeBreak(writer, source);
			PackField[3] fields = [
				PackField(0, 0, 4),
				PackField(8, 4, 2),
				PackField(16, 6, 1)];
			scope Pack pack = Pack(3, 1, fields);
			writePack(writer, source, pack);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
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
			u.s = S(0x01234567, 0x89ab, 0xcd);
			stepUntilExitAndExpect(test, stacks, [u.n], operation);
		});
}

void testStackRef(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [1, 2]);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(1), 4);
			writeBreak(writer, source);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			ulong stack0 = cast(ulong) dataBegin(stacks);
			ulong stack3 = cast(ulong) ((cast(immutable uint*) dataBegin(stacks)) + 3);
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
	u.s = S(0x01234567, 0x89ab, 0xcd, 0xef);
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstant(writer, source, u.value);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 0, 4);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 4, 2);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 6, 1);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			ulong value = u.value;
			stepUntilBreakAndExpect(test, stacks, [value], operation);
			ulong ptr = cast(ulong) dataBegin(stacks);
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
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [1, 2, 3]);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writeRead(writer, source, 8, 16);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			stepUntilBreakAndExpect(test, stacks, [1, 2, 3], operation);
			ulong ptr = cast(ulong) dataBegin(stacks);
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
	ulong toUlong(S s) {
		U u;
		u.s = s;
		return u.value;
	}

	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstant(writer, source, 0);
			writeBreak(writer, source);

			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);

			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 0, 4);
			writeBreak(writer, source);

			writeStackRef(writer, source, StackEntry(0));
			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 4, 2);
			writeBreak(writer, source);

			writeStackRef(writer, source, StackEntry(0));
			writePushConstant(writer, source, 0x0123456789abcdef);
			writeBreak(writer, source);

			writeWrite(writer, source, 6, 1);

			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			ulong ptr = cast(ulong) dataBegin(stacks);

			stepUntilBreakAndExpect(test, stacks, [0], operation);
			stepUntilBreakAndExpect(test, stacks, [0, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [0, ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, stacks, [toUlong(S(0x89abcdef, 0, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, stacks, [toUlong(S(0x89abcdef, 0, 0, 0)), ptr, 0x0123456789abcdef], operation);
			stepUntilBreakAndExpect(test, stacks, [toUlong(S(0x89abcdef, 0xcdef, 0, 0))], operation);

			stepUntilBreakAndExpect(
				test, stacks,
				[toUlong(S(0x89abcdef, 0xcdef, 0, 0)), ptr, 0x0123456789abcdef],
				operation);
			stepUntilExitAndExpect(test, stacks, [toUlong(S(0x89abcdef, 0xcdef, 0xef, 0))], operation);
		});
}

@trusted void testWriteWords(ref Test test) {
	interpreterTest(
		test,
		(scope ref ByteCodeWriter writer, ByteCodeSource source) {
			writePushConstants(writer, source, [0, 0, 0]);
			writeBreak(writer, source);
			writeStackRef(writer, source, StackEntry(0));
			writeBreak(writer, source);
			writePushConstants(writer, source, [1, 2]);
			writeBreak(writer, source);
			writeWrite(writer, source, 8, 16);
			writeReturn(writer, source);
		},
		(scope ref Stacks stacks, Operation* operation) {
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0], operation);
			ulong ptr = cast(ulong) dataBegin(stacks);
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0, ptr], operation);
			stepUntilBreakAndExpect(test, stacks, [0, 0, 0, ptr, 1, 2], operation);
			stepUntilExitAndExpect(test, stacks, [0, 1, 2], operation);
		});
}

@system void stepUntilBreakAndExpect(
	ref Test test,
	ref Stacks stacks,
	in immutable ulong[] expected,
	ref Operation* operation,
) {
	stepUntilBreak(stacks, operation);
	expectDataStack(test, stacks, expected);
}

void verifyStackEntry(in ByteCodeWriter writer, size_t n) {
	assert(getNextStackEntry(writer) == StackEntry(n));
}

public @trusted void stepUntilExitAndExpect(
	ref Test test,
	ref Stacks stacks,
	in immutable ulong[] expected,
	ref Operation* operation,
) {
	stepUntilExit(stacks, operation);
	expectDataStack(test, stacks, expected);
	foreach (size_t i; 0 .. expected.length)
		dataPop(stacks);
}

@trusted ByteCodeIndex curByteCodeIndex(in ByteCode a, Operation* operation) =>
	ByteCodeIndex(operation - a.byteCode.ptr);
