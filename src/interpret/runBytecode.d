module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import interpret.bytecode :
	ByteCode, ByteCodeOffset, ByteCodeOffsetUnsigned, FunPtrToOperationPtr, initialOperationPointer, Operation;
import interpret.debugInfo : BacktraceEntry, fillBacktrace, InterpreterDebugInfo, printDebugInfo;
import interpret.extern_ : DoDynCall, DynCallType, DynCallSig, FunPtr;
import interpret.stacks :
	dataDupWord,
	dataDupWords,
	dataEnd,
	dataPeek,
	dataPop,
	dataPopN,
	dataPush,
	dataPushUninitialized,
	dataRef,
	dataRemove,
	dataRemoveN,
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
import model.diag : FilesInfo; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowProgram;
import model.typeLayout : PackField;
import util.col.str : SafeCStr;
import util.conv : safeToSizeT;
import util.memory : memcpy, memmove, overwriteMemory;
import util.opt : force, has, Opt;
import util.path : AllPaths, PathsInfo;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : nullPtr, Ptr, ptrTrustMe;
import util.sym : AllSymbols;
import util.util : divRoundUp, drop, unreachable, verify;

@trusted immutable(int) runBytecode(
	scope ref Perf perf,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	scope DoDynCall doDynCall,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	scope immutable SafeCStr[] allArgs,
) {
	return withInterpreter!(immutable int)(
		doDynCall, lowProgram, byteCode, allSymbols, allPaths, pathsInfo, filesInfo,
		(ref Stacks stacks) {
			dataPush(stacks, allArgs.length);
			dataPush(stacks, cast(immutable ulong) allArgs.ptr);
			return withMeasureNoAlloc!(immutable int, () =>
				runBytecodeInner(stacks, initialOperationPointer(byteCode))
			)(perf, PerfMeasure.run);
		});
}

private @system immutable(int) runBytecodeInner(ref Stacks stacks, immutable(Operation)* operation) {
	stepUntilExit(stacks, operation);
	immutable ulong returnCode = dataPop(stacks);
	verify(dataStackIsEmpty(stacks));
	verify(returnStackIsEmpty(stacks));
	return cast(int) returnCode;
}

@system immutable(ulong) syntheticCall(
	immutable DynCallSig sig,
	immutable Operation* operationPtr,
	scope void delegate(ref Stacks stacks) @nogc nothrow cbPushArgs,
) {
	return withStacks!(immutable ulong)((ref Stacks stacks) {
		returnPush(stacks, operationOpStopInterpretation.ptr);
		cbPushArgs(stacks);
		immutable(Operation)* op = operationPtr;
		stepUntilExit(stacks, op);
		return sig.returnType == DynCallType.void_ ? 0 : dataPop(stacks);
	});
}

// This only works if you did 'returnPush(stacks, operationOpStopInterpretation.ptr);'
@system void stepUntilExit(ref Stacks stacks, ref immutable(Operation)* operation) {
	setNext(stacks, operation);
	do {
		nextOperationPtr.fn(nextStacks, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks, nextOperationPtr + 1);
		nextOperationPtr.fn(nextStacks, nextOperationPtr + 1);
	} while (nextOperationPtr.fn != &opStopInterpretation);
	stacks = nextStacks;
	operation = nextOperationPtr;
}

// Actually steps until the operation after the break.
// This is designed to work the same whether 'nextOperation' is implemented with tail recursion or returns.
// In the tail-recursive case, the while loop should be redundant,
// since only an opBreak (or opStopInterpretation) instruction returns.
@system void stepUntilBreak(ref Stacks stacks, ref immutable(Operation)* operation) {
	do {
		verify(operation.fn != &opStopInterpretation);
		operation.fn(stacks, operation + 1);
		stacks = nextStacks;
		operation = nextOperationPtr;
	} while ((operation - 1).fn != &opBreak);
}

@system immutable(T) withInterpreter(T)(
	scope DoDynCall doDynCall_,
	scope ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable FilesInfo filesInfo,
	scope immutable(T) delegate(ref Stacks) @system @nogc nothrow cb,
) {
	immutable InterpreterDebugInfo debugInfo = const InterpreterDebugInfo(
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(cast(immutable) allSymbols),
		ptrTrustMe(cast(immutable) allPaths),
		ptrTrustMe(pathsInfo),
		ptrTrustMe(filesInfo));
	overwriteMemory(&globals, immutable InterpreterGlobals(
		ptrTrustMe(debugInfo), byteCode.funPtrToOperationPtr, doDynCall_));
	return withStacks!T((ref Stacks stacks) {
		// Ensure the last 'return' returns to here
		returnPush(stacks, operationOpStopInterpretation.ptr);

		static if (is(T == void))
			cb(stacks);
		else
			immutable T res = cb(stacks);

		debug {
			overwriteMemory(&globals, immutable InterpreterGlobals(
				nullPtr!InterpreterDebugInfo, FunPtrToOperationPtr(), null));
		}

		static if (!is(T == void))
			return res;
	});
}

private @system void setNext(Stacks stacks, immutable Operation* operationPtr) {
	nextStacks = stacks;
	nextOperationPtr = operationPtr;
}
private static Stacks nextStacks;
private static immutable(Operation)* nextOperationPtr;

// Use a struct to ensure we assign every global
private struct InterpreterGlobals {
	immutable Ptr!InterpreterDebugInfo debugInfoPtr;
	immutable FunPtrToOperationPtr funPtrToOperationPtr;
	immutable DoDynCall doDynCall;
}
private __gshared InterpreterGlobals globals = void;

private @system ref immutable(InterpreterDebugInfo) debugInfo() {
	return globals.debugInfoPtr.deref();
}

void opAssertUnreachable(Stacks, immutable Operation* cur) {
	unreachable!void();
}

@system void opBreak(Stacks stacks, immutable Operation* cur) {
	setNext(stacks, cur);
}

@system void opRemove(immutable size_t offset, immutable size_t nEntries)(
	Stacks stacks,
	immutable Operation* cur,
) {
	dataRemoveN(stacks, offset, nEntries);
	nextOperation(stacks, cur);
}

@system void opRemoveVariable(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offset = readStackOffset(cur);
	immutable size_t nEntries = readSizeT(cur);
	dataRemoveN(stacks, offset, nEntries);
	nextOperation(stacks, cur);
}

@system void opReturn(Stacks stacks, immutable(Operation)* cur) {
	verify(!returnStackIsEmpty(stacks));
	cur = returnPop(stacks);
	nextOperation(stacks, cur);
}

immutable(Operation[8]) operationOpStopInterpretation = [
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
];

private @system void opStopInterpretation(Stacks stacks, immutable(Operation)* cur) {
	setNext(stacks, &operationOpStopInterpretation[0]);
}

@system void opJumpIfFalse(Stacks stacks, immutable(Operation)* cur) {
	immutable ByteCodeOffsetUnsigned offset = immutable ByteCodeOffsetUnsigned(readSizeT(cur));
	immutable ulong value = dataPop(stacks);
	if (value == 0)
		cur += offset.offset;
	nextOperation(stacks, cur);
}

@system void opSwitch0ToN(Stacks stacks, immutable(Operation)* cur) {
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(cur);
	immutable ulong value = dataPop(stacks);
	immutable ByteCodeOffsetUnsigned offset = offsets[safeToSizeT(value)];
	cur += offset.offset;
	nextOperation(stacks, cur);
}

@system void opStackRef(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offset = readStackOffset(cur);
	dataPush(stacks, cast(immutable ulong) dataRef(stacks, offset));
	nextOperation(stacks, cur);
}

@system void opReadWords(immutable size_t offsetWords, immutable size_t sizeWords)(
	Stacks stacks,
	immutable Operation* cur,
) {
	opReadWordsCommon(stacks, cur, offsetWords, sizeWords);
}

@system void opReadWordsVariable(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	immutable size_t sizeWords = readSizeT(cur);
	opReadWordsCommon(stacks, cur, offsetWords, sizeWords);
}

private @system void opReadWordsCommon(
	Stacks stacks,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	immutable ulong* ptr = (cast(immutable ulong*) dataPop(stacks)) + offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords)
		dataPush(stacks, ptr[i]);
	nextOperation(stacks, cur);
}

@system void opReadNat8(immutable size_t offsetBytes)(
	Stacks stacks,
	immutable Operation* cur,
) {
	dataPush(stacks, *((cast(immutable ubyte*) dataPop(stacks)) + offsetBytes));
	nextOperation(stacks, cur);
}

@system void opReadNat16(immutable size_t offsetNat16s)(
	Stacks stacks,
	immutable Operation* cur,
) {
	dataPush(stacks, *((cast(immutable ushort*) dataPop(stacks)) + offsetNat16s));
	nextOperation(stacks, cur);
}

@system void opReadNat32(immutable size_t offsetNat32s)(
	Stacks stacks,
	immutable Operation* cur,
) {
	dataPush(stacks, *((cast(immutable uint*) dataPop(stacks)) + offsetNat32s));
	nextOperation(stacks, cur);
}

@system void opReadBytesVariable(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);
	immutable ubyte* ptr = (cast(immutable ubyte*) dataPop(stacks)) + offsetBytes;
	readNoCheck(stacks, ptr, sizeBytes);
	nextOperation(stacks, cur);
}

@system void opWrite(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offset = readSizeT(cur);
	immutable size_t size = readSizeT(cur);
	if (size < 8) { //TODO:UNNECESSARY?
		verify(size != 0);
		immutable ulong value = dataPop(stacks);
		ubyte* ptr = cast(ubyte*) dataPop(stacks);
		writePartialBytes(ptr + offset, value, size);
	} else {
		immutable size_t sizeWords = divRoundUp(size, 8);
		ubyte* destWithoutOffset = cast(ubyte*) dataPeek(stacks, sizeWords);
		ubyte* src = cast(ubyte*) (dataEnd(stacks) - sizeWords);
		ubyte* dest = destWithoutOffset + offset;
		memcpy(dest, src, size);
		dataPopN(stacks, sizeWords + 1);
	}
	nextOperation(stacks, cur);
}

private @system void writePartialBytes(ubyte* ptr, immutable ulong value, immutable size_t size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			*(cast(ubyte*) ptr) = cast(immutable ubyte) value;
			break;
		case 2:
			*(cast(ushort*) ptr) = cast(immutable ushort) value;
			break;
		case 4:
			*(cast(uint*) ptr) = cast(immutable uint) value;
			break;
		default:
			unreachable!void();
			break;
	}
}

@system void opCall(Stacks stacks, immutable(Operation)* cur) {
	immutable Operation* op = readOperationPtr(cur);
	returnPush(stacks, cur);
	cur = op;
	nextOperation(stacks, cur);
}

@system void opCallFunPtr(Stacks stacks, immutable(Operation)* cur) {
	immutable DynCallSig sig = readDynCallSig(cur);
	immutable FunPtr funPtr = immutable FunPtr(cast(immutable void*) dataRemove(stacks, sig.parameterTypes.length));
	immutable Opt!(Operation*) operationPtr = globals.funPtrToOperationPtr[funPtr];
	if (has(operationPtr)) {
		returnPush(stacks, cur);
		cur = force(operationPtr);
	} else {
		scope immutable ulong[] params = dataPopN(stacks, sig.parameterTypes.length);
		// This is an extern FunPtr, but it might call back into a synthetic FunPtr
		saveStacks(stacks);
		immutable ulong value = globals.doDynCall(funPtr, sig, params);
		if (sig.returnType != DynCallType.void_)
			dataPush(stacks, value);
	}
	nextOperation(stacks, cur);
}

@system void opCallFunPtrExtern(Stacks stacks, immutable(Operation)* cur) {
	verify(FunPtr.sizeof <= ulong.sizeof);
	immutable FunPtr funPtr = immutable FunPtr(cast(immutable void*) readNat64(cur));
	immutable DynCallSig sig = readDynCallSig(cur);
	scope immutable ulong[] params = dataPopN(stacks, sig.parameterTypes.length);
	// This is an extern FunPtr, but it might call back into a synthetic FunPtr
	saveStacks(stacks);
	immutable ulong value = globals.doDynCall(funPtr, sig, params);
	if (sig.returnType != DynCallType.void_)
		dataPush(stacks, value);
	nextOperation(stacks, cur);
}

private @system immutable(DynCallSig) readDynCallSig(ref immutable(Operation)* cur) {
	return immutable DynCallSig(readArray!DynCallType(cur));
}

@system void opSetjmp(Stacks stacks, immutable(Operation)* cur) {
	FakeJmpBufTag* jmpBufPtr = cast(FakeJmpBufTag*) dataPop(stacks);
	*jmpBufPtr = FakeJmpBufTag(stacks.inner, returnPeek(stacks), cur);
	// The return from the setjmp is in the handler for 'longjmp'
	dataPush(stacks, 0);
	nextOperation(stacks, cur);
}

@system void opLongjmp(Stacks stacks, immutable(Operation)* cur) {
	immutable ulong val = dataPop(stacks);
	FakeJmpBufTag* jmpBufPtr = cast(FakeJmpBufTag*) dataPop(stacks);
	stacks.inner = jmpBufPtr.stacks;
	setReturnPeek(stacks, jmpBufPtr.returnPeek);
	cur = jmpBufPtr.nextOperationPtr;
	// return value of 'setjmp'
	dataPush(stacks, val);
	nextOperation(stacks, cur);
}

@system void opInterpreterBacktrace(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t skip = safeToSizeT(dataPop(stacks));
	immutable size_t max = safeToSizeT(dataPop(stacks));
	BacktraceEntry* out_ = cast(BacktraceEntry*) dataPop(stacks);
	BacktraceEntry* res = fillBacktrace(debugInfo, out_, max, skip, stacks);
	dataPush(stacks, cast(immutable size_t) res);
	nextOperation(stacks, cur);
}

private struct FakeJmpBufTag {
	Stacks.Inner stacks;
	immutable(Operation)* returnPeek;
	immutable(Operation)* nextOperationPtr;
}
// see setjmp.crow
static assert(FakeJmpBufTag.sizeof <= 288);

@system void opFnUnary(alias cb)(Stacks stacks, immutable(Operation)* cur) {
	dataPush(stacks, cb(dataPop(stacks)));
	nextOperation(stacks, cur);
}

@system void opFnBinary(alias cb)(Stacks stacks, immutable(Operation)* cur) {
	immutable ulong y = dataPop(stacks);
	immutable ulong x = dataPop(stacks);
	dataPush(stacks, cb(x, y));
	nextOperation(stacks, cur);
}

private @system void nextOperation(Stacks stacks, immutable Operation* cur) {
	static if (false)
		printDebugInfo(debugInfo, dataTempAsArr(stacks), returnTempAsArrReverse(stacks), cur);

	version(TailRecursionAvailable) {
		cur.fn(stacks, cur + 1);
	} else {
		setNext(stacks, cur);
	}
}

private @system immutable(Operation) readOperation(scope ref immutable(Operation)* cur) {
	immutable Operation res = *cur;
	cur++;
	return res;
}

private @system immutable(size_t) readStackOffset(ref immutable(Operation)* cur) {
	return readSizeT(cur);
}

private @system immutable(long) readInt64(ref immutable(Operation)* cur) {
	return readOperation(cur).long_;
}

private @system immutable(ulong) readNat64(ref immutable(Operation)* cur) {
	return readOperation(cur).ulong_;
}

private @system immutable(size_t) readSizeT(ref immutable(Operation)* cur) {
	return safeToSizeT(readNat64(cur));
}

private @system immutable(Operation*) readOperationPtr(ref immutable(Operation)* cur) {
	return cast(immutable Operation*) readSizeT(cur);
}

private @system immutable(T[]) readArray(T)(ref immutable(Operation)* cur) {
	immutable size_t size = readSizeT(cur);
	verify(size < 999); // sanity check
	immutable T* ptr = cast(immutable T*) cur;
	immutable T[] res = ptr[0 .. size];
	immutable(ubyte)* end = cast(immutable ubyte*) (ptr + size);
	while ((cast(size_t) end) % Operation.sizeof != 0) end++;
	verify((cast(size_t) cur) % Operation.sizeof == 0);
	verify((cast(size_t) end) % Operation.sizeof == 0);
	cur = cast(immutable Operation*) end;
	return res;
}

@system void opJump(Stacks stacks, immutable(Operation)* cur) {
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt64(cur));
	cur += offset.offset;
	nextOperation(stacks, cur);
}

@system void opPack(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t inEntries = readSizeT(cur);
	immutable size_t outEntries = readSizeT(cur);
	immutable PackField[] fields = readArray!PackField(cur);

	ubyte* base = cast(ubyte*) (dataEnd(stacks) - inEntries);
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset, base + field.inOffset, safeToSizeT(field.size));

	// drop extra entries
	drop(dataPopN(stacks, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + fields[$ - 1].outOffset + fields[$ - 1].size;
	while (ptr < cast(ubyte*) dataEnd(stacks)) {
		*ptr = 0;
		ptr++;
	}

	nextOperation(stacks, cur);
}

@system void opPushValue64(Stacks stacks, immutable(Operation)* cur) {
	dataPush(stacks, readNat64(cur));
	nextOperation(stacks, cur);
}

@system void opDupBytes(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);

	const ubyte* ptr = (cast(const ubyte*) dataEnd(stacks)) - offsetBytes;
	readNoCheck(stacks, ptr, sizeBytes);
	nextOperation(stacks, cur);
}

@system void opDupWord(immutable size_t offsetWords)(Stacks stacks, immutable(Operation)* cur) {
	dataDupWord(stacks, offsetWords);
	nextOperation(stacks, cur);
}

@system void opDupWordVariable(Stacks stacks, immutable(Operation)* cur) {
	dataDupWord(stacks, readSizeT(cur));
	nextOperation(stacks, cur);
}

@system void opDupWords(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	dataDupWords(stacks, offsetWords, sizeWords);
	nextOperation(stacks, cur);
}

// Copies data from the top of the stack to write to something lower on the stack.
@system void opSet(immutable size_t offsetWords, immutable size_t sizeWords)(
	Stacks stacks,
	immutable Operation* cur,
) {
	opSetCommon(stacks, cur, offsetWords, sizeWords);
}

@system void opSetVariable(Stacks stacks, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	opSetCommon(stacks, cur, offsetWords, sizeWords);
}

private @system void opSetCommon(
	Stacks stacks,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	// Start at the end of the range and pop in reverse
	const ulong* begin = dataTop(stacks) - offsetWords;
	const(ulong)* ptr = begin + sizeWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		ptr--;
		overwriteMemory(ptr, dataPop(stacks));
	}
	verify(ptr == begin);
	nextOperation(stacks, cur);
}

private @system void readNoCheck(ref Stacks stacks, const ubyte* readFrom, immutable size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) dataEnd(stacks);
	immutable size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	dataPushUninitialized(stacks, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) dataEnd(stacks)) {
		*endPtr = 0;
		endPtr++;
	}
}
