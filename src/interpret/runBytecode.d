module interpret.runBytecode;

@nogc nothrow: // not @safe, not pure

import interpret.bytecode :
	ByteCode, ByteCodeOffset, ByteCodeOffsetUnsigned, FunPtrToOperationPtr, initialOperationPointer, Operation;
import interpret.debugInfo : BacktraceEntry, fillBacktrace, InterpreterDebugInfo, printDebugInfo;
import interpret.extern_ : DoDynCall, DynCallType, DynCallSig, FunPtr;
import interpret.stacks :
	dataDupWords,
	dataEnd,
	dataPeek,
	dataPop,
	dataPopN,
	dataPush,
	dataPushUninitialized,
	dataRef,
	dataRemove,
	dataReturn,
	dataStackIsEmpty,
	dataTempAsArr,
	dataTop,
	returnPeek,
	returnPop,
	returnPush,
	returnStackIsEmpty,
	returnTempAsArrReverse,
	saveStacks,
	setReturnPeek,
	Stacks,
	withStacks;
import model.lowModel : LowProgram;
import model.model : Program;
import model.typeLayout : PackField;
import util.alloc.alloc : Alloc;
import util.col.str : SafeCStr;
import util.conv : safeToSizeT;
import util.memory : memcpy, memmove, overwriteMemory;
import util.opt : force, has, Opt;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : castNonScope_ref, ptrTrustMe;
import util.sym : AllSymbols;
import util.uri : AllUris, UrisInfo;
import util.util : debugLog, divRoundUp, drop, unreachable, verify;

@safe int runBytecode(
	scope ref Perf perf,
	ref Alloc alloc, // for thread locals
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in DoDynCall doDynCall,
	in Program program,
	in LowProgram lowProgram,
	in ByteCode byteCode,
	in SafeCStr[] allArgs,
) =>
	withInterpreter!int(
		alloc, doDynCall, program, lowProgram, byteCode, allSymbols, allUris, urisInfo,
		(ref Stacks stacks) {
			dataPush(stacks, allArgs.length);
			dataPush(stacks, cast(ulong) allArgs.ptr);
			return withMeasureNoAlloc!(int, () @trusted =>
				runBytecodeInner(stacks, initialOperationPointer(byteCode))
			)(perf, PerfMeasure.run);
		});

private int runBytecodeInner(ref Stacks stacks, Operation* operation) {
	stepUntilExit(stacks, operation);
	ulong returnCode = dataPop(stacks);
	verify(dataStackIsEmpty(stacks));
	verify(returnStackIsEmpty(stacks));
	return cast(int) returnCode;
}

ulong syntheticCall(
	in DynCallSig sig,
	Operation* operationPtr,
	in void delegate(ref Stacks stacks) @nogc nothrow cbPushArgs,
) =>
	withStacks!ulong((ref Stacks stacks) {
		returnPush(stacks, operationOpStopInterpretation.ptr);
		cbPushArgs(stacks);
		Operation* op = operationPtr;
		stepUntilExit(stacks, op);
		return sig.returnType == DynCallType.void_ ? 0 : dataPop(stacks);
	});

// This only works if you did 'returnPush(stacks, operationOpStopInterpretation.ptr);'
void stepUntilExit(ref Stacks stacks, ref Operation* operation) {
	setNext(stacks, operation);
	do {
		nextOperationPtr.fn(nextStacks.dataPtr, nextStacks.returnPtr, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks.dataPtr, nextStacks.returnPtr, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks.dataPtr, nextStacks.returnPtr, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks.dataPtr, nextStacks.returnPtr, nextOperationPtr + 1);
	} while (nextOperationPtr.fn != &opStopInterpretation);
	stacks = nextStacks;
	operation = nextOperationPtr;
}

// Actually steps until the operation after the break.
// This is designed to work the same whether 'nextOperation' is implemented with tail recursion or returns.
// In the tail-recursive case, the while loop should be redundant,
// since only an opBreak (or opStopInterpretation) instruction returns.
void stepUntilBreak(ref Stacks stacks, ref Operation* operation) {
	setNext(stacks, operation);
	do {
		verify(nextOperationPtr.fn != &opStopInterpretation);
		nextOperationPtr.fn(nextStacks.dataPtr, nextStacks.returnPtr, nextOperationPtr + 1);
	} while ((nextOperationPtr - 1).fn != &opBreak);
	stacks = nextStacks;
	operation = nextOperationPtr;
}

@safe T withInterpreter(T)(
	ref Alloc alloc,
	in DoDynCall doDynCall_,
	in Program program,
	in LowProgram lowProgram,
	in ByteCode byteCode,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in T delegate(ref Stacks) @nogc nothrow cb,
) {
	InterpreterDebugInfo debugInfo = InterpreterDebugInfo(
		ptrTrustMe(program),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(allSymbols),
		ptrTrustMe(allUris),
		ptrTrustMe(urisInfo));
	setGlobals(InterpreterGlobals(
		ptrTrustMe(debugInfo),
		castNonScope_ref(byteCode).funPtrToOperationPtr,
		castNonScope_ref(doDynCall_)));
	return withStacks!T((scope ref Stacks stacks) @trusted {
		// Ensure the last 'return' returns to here
		returnPush(stacks, operationOpStopInterpretation.ptr);

		static if (is(T == void))
			cb(stacks);
		else
			T res = cb(stacks);

		debug {
			setGlobals(InterpreterGlobals(null, FunPtrToOperationPtr(), null));
		}

		static if (!is(T == void))
			return res;
	});
}

private void setNext(Stacks stacks, Operation* operationPtr) {
	nextStacks = stacks;
	nextOperationPtr = operationPtr;
}
private static Stacks nextStacks;
private static Operation* nextOperationPtr;

private const struct InterpreterGlobals {
	InterpreterDebugInfo* debugInfoPtr;
	FunPtrToOperationPtr funPtrToOperationPtr;
	DoDynCall doDynCall;
}
private __gshared InterpreterGlobals globals = void;

private @trusted void setGlobals(InterpreterGlobals value) {
	overwriteMemory(&globals, value);
}

private ref InterpreterDebugInfo debugInfo() =>
	*globals.debugInfoPtr;

pragma(inline, true):

private void operationWithoutNext(alias cb)(
	ulong* stacksData, Operation** stacksReturn, Operation* cur,
) {
	cb(Stacks(stacksData, stacksReturn), cur);
}

private void operation(alias cb)(
	ulong* stacksData,
	Operation** stacksReturn,
	Operation* cur,
) {
	Stacks stacks = Stacks(stacksData, stacksReturn);
	static if (false) {
		printDebugInfo(debugInfo, dataTempAsArr(stacks), returnTempAsArrReverse(stacks), cur - 1);
		debugLog(__traits(identifier, cb));
	}
	cb(stacks, cur);
	version (TailRecursionAvailable) {
		return cur.fn(stacks.dataPtr, stacks.returnPtr, cur + 1);
	} else {
		setNext(stacks, cur);
	}
}

alias opBreak = operationWithoutNext!opBreakInner;
private void opBreakInner(Stacks stacks, Operation* cur) {
	setNext(stacks, cur);
}

immutable Operation[8] operationOpStopInterpretation = [
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
	Operation(&opStopInterpretation),
];

private alias opStopInterpretation = operationWithoutNext!opStopInterpretationInner;
private void opStopInterpretationInner(Stacks stacks, Operation* cur) {
	setNext(stacks, &operationOpStopInterpretation[0]);
}

alias opReturnData(size_t offsetWords, size_t sizeWords) =
	operation!(opReturnDataInner!(offsetWords, sizeWords));
private void opReturnDataInner(size_t offsetWords, size_t sizeWords)(
	ref Stacks stacks, ref Operation* cur,
) {
	static assert(sizeWords <= offsetWords + 1);
	dataReturn(stacks, offsetWords, sizeWords);
}

alias opReturnDataVariable = operation!opReturnDataVariableInner;
private void opReturnDataVariableInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetWords = readStackOffset(cur);
	size_t sizeWords = readSizeT(cur);
	dataReturn(stacks, offsetWords, sizeWords);
}

alias opReturn = operation!opReturnInner;
private void opReturnInner(ref Stacks stacks, ref Operation* cur) {
	cur = returnPop(stacks);
}

alias opJumpIfFalse = operation!opJumpIfFalseInner;
private void opJumpIfFalseInner(ref Stacks stacks, ref Operation* cur) {
	ByteCodeOffsetUnsigned offset = ByteCodeOffsetUnsigned(readSizeT(cur));
	ulong value = dataPop(stacks);
	if (value == 0)
		cur += offset.offset;
}

alias opSwitch0ToN = operation!opSwitch0ToNInner;
private void opSwitch0ToNInner(ref Stacks stacks, ref Operation* cur) {
	ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(cur);
	ulong value = dataPop(stacks);
	ByteCodeOffsetUnsigned offset = offsets[safeToSizeT(value)];
	cur += offset.offset;
}

alias opStackRef = operation!opStackRefInner;
private void opStackRefInner(ref Stacks stacks, ref Operation* cur) {
	size_t offset = readStackOffset(cur);
	dataPush(stacks, cast(ulong) dataRef(stacks, offset));
}

alias opThreadLocalPtr = operation!opThreadLocalPtrInner;
private void opThreadLocalPtrInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetWords = readSizeT(cur);
	dataPush(stacks, cast(ulong) (threadLocalsStorage.ptr + offsetWords));
}
@safe pure size_t maxThreadLocalsSizeWords() =>
	256;
private static ulong[maxThreadLocalsSizeWords] threadLocalsStorage;

alias opReadWords(size_t pointerOffsetWords, size_t nWordsToRead) =
	operation!(opReadWordsInner!(pointerOffsetWords, nWordsToRead));
private void opReadWordsInner(size_t pointerOffsetWords, size_t nWordsToRead)(
	ref Stacks stacks, ref Operation* cur,
) {
	static assert(nWordsToRead != 0);
	opReadWordsCommon(stacks, cur, pointerOffsetWords, nWordsToRead);
}

alias opReadWordsVariable = operation!opReadWordsVariableInner;
private void opReadWordsVariableInner(ref Stacks stacks, ref Operation* cur) {
	size_t pointerOffsetWords = readSizeT(cur);
	size_t nWordsToRead = readSizeT(cur);
	opReadWordsCommon(stacks, cur, pointerOffsetWords, nWordsToRead);
}

private void opReadWordsCommon(ref Stacks stacks, ref Operation* cur, size_t pointerOffsetWords, size_t nWordsToRead) {
	debug verify(nWordsToRead != 0);
	immutable ulong* ptr = (cast(immutable ulong*) dataPop(stacks)) + pointerOffsetWords;
	foreach (size_t i; 0 .. nWordsToRead)
		dataPush(stacks, ptr[i]);
}

alias opReadNat8(size_t offsetBytes) = operation!(opReadNat8Inner!offsetBytes);
private void opReadNat8Inner(size_t offsetBytes)(ref Stacks stacks, ref Operation* cur) {
	dataPush(stacks, *((cast(immutable ubyte*) dataPop(stacks)) + offsetBytes));
}

alias opReadNat16(size_t offsetNat16s) = operation!(opReadNat16Inner!offsetNat16s);
private void opReadNat16Inner(size_t offsetNat16s)(ref Stacks stacks, ref Operation* cur) {
	dataPush(stacks, *((cast(immutable ushort*) dataPop(stacks)) + offsetNat16s));
}

alias opReadNat32(size_t offsetNat32s) = operation!(opReadNat32Inner!offsetNat32s);
private void opReadNat32Inner(size_t offsetNat32s)(ref Stacks stacks, ref Operation* cur) {
	dataPush(stacks, *((cast(immutable uint*) dataPop(stacks)) + offsetNat32s));
}

alias opReadBytesVariable = operation!opReadBytesVariableInner;
private void opReadBytesVariableInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetBytes = readSizeT(cur);
	size_t sizeBytes = readSizeT(cur);
	immutable ubyte* ptr = (cast(immutable ubyte*) dataPop(stacks)) + offsetBytes;
	readNoCheck(stacks, ptr, sizeBytes);
}

alias opWrite = operation!opWriteInner;
private void opWriteInner(ref Stacks stacks, ref Operation* cur) {
	size_t offset = readSizeT(cur);
	size_t size = readSizeT(cur);
	if (size < 8) { //TODO:UNNECESSARY?
		verify(size != 0);
		ulong value = dataPop(stacks);
		ubyte* ptr = cast(ubyte*) dataPop(stacks);
		writePartialBytes(ptr + offset, value, size);
	} else {
		size_t sizeWords = divRoundUp(size, 8);
		ubyte* destWithoutOffset = cast(ubyte*) dataPeek(stacks, sizeWords);
		ubyte* src = cast(ubyte*) (dataEnd(stacks) - sizeWords);
		ubyte* dest = destWithoutOffset + offset;
		memcpy(dest, src, size);
		dataPopN(stacks, sizeWords + 1);
	}
}

private void writePartialBytes(ubyte* ptr, ulong value, size_t size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			*(cast(ubyte*) ptr) = cast(ubyte) value;
			break;
		case 2:
			*(cast(ushort*) ptr) = cast(ushort) value;
			break;
		case 4:
			*(cast(uint*) ptr) = cast(uint) value;
			break;
		default:
			unreachable!void();
			break;
	}
}

alias opCall = operation!opCallInner;
private void opCallInner(ref Stacks stacks, ref Operation* cur) {
	Operation* op = readOperationPtr(cur);
	returnPush(stacks, cur);
	cur = op;
}

alias opCallFunPtr = operation!opCallFunPtrInner;
private void opCallFunPtrInner(ref Stacks stacks, ref Operation* cur) {
	DynCallSig sig = readDynCallSig(cur);
	FunPtr funPtr = FunPtr(cast(immutable void*) dataRemove(stacks, sig.parameterTypes.length));
	Opt!(Operation*) operationPtr = globals.funPtrToOperationPtr[funPtr];
	if (has(operationPtr)) {
		returnPush(stacks, cur);
		cur = force(operationPtr);
	} else {
		scope immutable ulong[] params = dataPopN(stacks, sig.parameterTypes.length);
		// This is an extern FunPtr, but it might call back into a synthetic FunPtr
		saveStacks(stacks);
		ulong value = globals.doDynCall(funPtr, sig, params);
		if (sig.returnType != DynCallType.void_)
			dataPush(stacks, value);
	}
}

alias opCallFunPtrExtern = operation!opCallFunPtrExternInner;
private void opCallFunPtrExternInner(ref Stacks stacks, ref Operation* cur) {
	verify(FunPtr.sizeof <= ulong.sizeof);
	FunPtr funPtr = FunPtr(cast(immutable void*) readNat64(cur));
	DynCallSig sig = readDynCallSig(cur);
	scope immutable ulong[] params = dataPopN(stacks, sig.parameterTypes.length);
	// This is an extern FunPtr, but it might call back into a synthetic FunPtr
	saveStacks(stacks);
	ulong value = globals.doDynCall(funPtr, sig, params);
	if (sig.returnType != DynCallType.void_)
		dataPush(stacks, value);
}

private DynCallSig readDynCallSig(ref Operation* cur) =>
	DynCallSig(readArray!DynCallType(cur));

alias opSetjmp = operation!opSetjmpInner;
private void opSetjmpInner(ref Stacks stacks, ref Operation* cur) {
	FakeJmpBufTag* jmpBufPtr = cast(FakeJmpBufTag*) dataPop(stacks);
	*jmpBufPtr = FakeJmpBufTag(stacks, returnPeek(stacks), cur);
	// The return from the setjmp is in the handler for 'longjmp'
	dataPush(stacks, 0);
}

alias opLongjmp = operation!opLongjmpInner;
private void opLongjmpInner(ref Stacks stacks, ref Operation* cur) {
	ulong val = dataPop(stacks);
	FakeJmpBufTag* jmpBufPtr = cast(FakeJmpBufTag*) dataPop(stacks);
	stacks = jmpBufPtr.stacks;
	setReturnPeek(stacks, jmpBufPtr.returnPeek);
	cur = jmpBufPtr.nextOperationPtr;
	// return value of 'setjmp'
	dataPush(stacks, val);
}

alias opInterpreterBacktrace = operation!opInterpreterBacktraceInner;
private void opInterpreterBacktraceInner(ref Stacks stacks, ref Operation* cur) {
	size_t skip = safeToSizeT(dataPop(stacks));
	size_t max = safeToSizeT(dataPop(stacks));
	BacktraceEntry* out_ = cast(BacktraceEntry*) dataPop(stacks);
	BacktraceEntry* res = fillBacktrace(debugInfo, out_, max, skip, stacks);
	dataPush(stacks, cast(size_t) res);
}

private struct FakeJmpBufTag {
	Stacks stacks;
	Operation* returnPeek;
	Operation* nextOperationPtr;
}
// see setjmp.crow
static assert(FakeJmpBufTag.sizeof <= 288);

alias opFnUnary(alias cb) = operation!(opFnUnaryInner!cb);
private void opFnUnaryInner(alias cb)(ref Stacks stacks, ref Operation* cur) {
	dataPush(stacks, cb(dataPop(stacks)));
}

alias opFnBinary(alias cb) = operation!(opFnBinaryInner!cb);
private void opFnBinaryInner(alias cb)(ref Stacks stacks, ref Operation* cur) {
	ulong y = dataPop(stacks);
	ulong x = dataPop(stacks);
	dataPush(stacks, cb(x, y));
}

private Operation readOperation(scope ref Operation* cur) {
	Operation res = *cur;
	cur++;
	return res;
}

private size_t readStackOffset(ref Operation* cur) =>
	readSizeT(cur);

private long readInt64(ref Operation* cur) =>
	readOperation(cur).long_;

private ulong readNat64(ref Operation* cur) =>
	readOperation(cur).ulong_;

private size_t readSizeT(ref Operation* cur) =>
	safeToSizeT(readNat64(cur));

private Operation* readOperationPtr(ref Operation* cur) =>
	cast(Operation*) readSizeT(cur);

private immutable(T[]) readArray(T)(ref Operation* cur) {
	size_t size = readSizeT(cur);
	verify(size < 999); // sanity check
	immutable T* ptr = cast(immutable T*) cur;
	immutable T[] res = ptr[0 .. size];
	immutable(ubyte)* end = cast(immutable ubyte*) (ptr + size);
	while ((cast(size_t) end) % Operation.sizeof != 0) end++;
	verify((cast(size_t) cur) % Operation.sizeof == 0);
	verify((cast(size_t) end) % Operation.sizeof == 0);
	cur = cast(Operation*) end;
	return res;
}

alias opJump = operation!opJumpInner;
private void opJumpInner(ref Stacks stacks, ref Operation* cur) {
	ByteCodeOffset offset = ByteCodeOffset(readInt64(cur));
	cur += offset.offset;
}

alias opPack = operation!opPackInner;
private void opPackInner(ref Stacks stacks, ref Operation* cur) {
	size_t inEntries = readSizeT(cur);
	size_t outEntries = readSizeT(cur);
	PackField[] fields = readArray!PackField(cur);

	ubyte* base = cast(ubyte*) (dataEnd(stacks) - inEntries);
	foreach (PackField field; fields)
		memmove(base + field.outOffset, base + field.inOffset, safeToSizeT(field.size));

	// drop extra entries
	drop(dataPopN(stacks, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + fields[$ - 1].outOffset + fields[$ - 1].size;
	while (ptr < cast(ubyte*) dataEnd(stacks)) {
		*ptr = 0;
		ptr++;
	}
}

alias opPushValue64 = operation!opPushInner;
private void opPushInner(ref Stacks stacks, ref Operation* cur) {
	dataPush(stacks, readNat64(cur));
}

alias opDupBytes = operation!opDupBytesInner;
private void opDupBytesInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetBytes = readSizeT(cur);
	size_t sizeBytes = readSizeT(cur);
	const ubyte* ptr = (cast(const ubyte*) dataEnd(stacks)) - offsetBytes;
	readNoCheck(stacks, ptr, sizeBytes);
}

alias opDupWords(size_t offsetWords, size_t sizeWords) =
	operation!(opDupWordsInner!(offsetWords, sizeWords));
private void opDupWordsInner(size_t offsetWords, size_t sizeWords)(ref Stacks stacks, ref Operation* cur) {
	static assert(sizeWords <= offsetWords + 1);
	dataDupWords(stacks, offsetWords, sizeWords);
}

alias opDupWordsVariable = operation!opDupWordsVariableInner;
private void opDupWordsVariableInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetWords = readStackOffset(cur);
	size_t sizeWords = readSizeT(cur);
	dataDupWords(stacks, offsetWords, sizeWords);
}

// Copies data from the top of the stack to write to something lower on the stack.
alias opSet(size_t offsetWords, size_t sizeWords) = operation!(opSetInner!(offsetWords, sizeWords));
private void opSetInner(size_t offsetWords, size_t sizeWords)(
	ref Stacks stacks, ref Operation* cur,
) {
	static assert(sizeWords != 0);
	static assert(sizeWords <= offsetWords + 1);
	opSetCommon(stacks, cur, offsetWords, sizeWords);
}

alias opSetVariable = operation!opSetVariableInner;
private void opSetVariableInner(ref Stacks stacks, ref Operation* cur) {
	size_t offsetWords = readStackOffset(cur);
	size_t sizeWords = readSizeT(cur);
	opSetCommon(stacks, cur, offsetWords, sizeWords);
}

private void opSetCommon(ref Stacks stacks, ref Operation* cur, size_t offsetWords, size_t sizeWords) {
	debug verify(sizeWords != 0);
	debug verify(sizeWords <= offsetWords + 1);
	// Start at the end of the range and pop in reverse
	ulong* begin = dataTop(stacks) - offsetWords;
	ulong* ptr = begin + sizeWords;
	foreach (size_t i; 0 .. sizeWords) {
		ptr--;
		*ptr = dataPop(stacks);
	}
	verify(ptr == begin);
}

private void readNoCheck(ref Stacks stacks, const ubyte* readFrom, size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) dataEnd(stacks);
	size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	dataPushUninitialized(stacks, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) dataEnd(stacks)) {
		*endPtr = 0;
		endPtr++;
	}
}
