module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ExternOp,
	initialOperationPointer,
	NextOperation,
	Operation;
import interpret.debugInfo : InterpreterDebugInfo, printDebugInfo;
import interpret.extern_ : DoDynCall, DynCallType, DynCallSig, FunPtr;
import interpret.types : DataStack, ReturnStack;
import model.diag : FilesInfo; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowProgram;
import model.typeLayout : PackField;
import util.col.stack :
	peek,
	pop,
	popN,
	push,
	pushUninitialized,
	remove,
	setStackTop,
	stackBeforeTop,
	stackEnd,
	stackIsEmpty,
	stackRef,
	stackSize,
	stackTop;
import util.col.str : SafeCStr;
import util.conv : safeToSizeT;
import util.memory : memcpy, memmove, overwriteMemory;
import util.opt : has;
import util.path : AllPaths, PathsInfo;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_const;
import util.sym : AllSymbols;
import util.util : divRoundUp, drop, min, unreachable, verify;

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
		(scope ref Interpreter interpreter) {
			push(interpreter.dataStack, allArgs.length);
			push(interpreter.dataStack, cast(immutable ulong) allArgs.ptr);
			return withMeasureNoAlloc!(immutable int, () =>
				runBytecodeInner(interpreter, initialOperationPointer(byteCode))
			)(perf, PerfMeasure.run);
		});
}

private @system immutable(int) runBytecodeInner(scope ref Interpreter interpreter, immutable(Operation)* opPtr) {
	do {
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
	} while (opPtr.fn != &opStopInterpretation);

	immutable ulong returnCode = pop(interpreter.dataStack);
	verify(stackIsEmpty(interpreter.dataStack));
	return cast(int) returnCode;
}

@system immutable(T) withInterpreter(T)(
	scope DoDynCall doDynCall,
	scope ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable FilesInfo filesInfo,
	scope immutable(T) delegate(scope ref Interpreter) @system @nogc nothrow cb,
) {
	ulong[1024 * 64] dataStackStorage = void;
	immutable(Operation)*[1024 * 4] returnStackStorage = void;
	const InterpreterDebugInfo debugInfo = const InterpreterDebugInfo(
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe_const(allSymbols),
		ptrTrustMe_const(allPaths),
		ptrTrustMe(pathsInfo),
		ptrTrustMe(filesInfo));
	scope Interpreter interpreter = Interpreter(
		ptrTrustMe_const(debugInfo),
		doDynCall,
		DataStack(dataStackStorage),
		ReturnStack(returnStackStorage));

	// Ensure the last 'return' returns to here
	push(interpreter.returnStack, operationOpStopInterpretation.ptr);

	static if (is(T == void))
		cb(interpreter);
	else
		immutable T res = cb(interpreter);

	static if (!is(T == void))
		return res;
}

struct Interpreter {
	@safe @nogc nothrow: // not pure

	@disable this(ref const Interpreter);

	private:
	const Ptr!InterpreterDebugInfo debugInfoPtr;
	DoDynCall doDynCall;
	//TODO:PRIVATE
	public DataStack dataStack;
	public ReturnStack returnStack;
	InterpreterRestore curRestore;
	// WARN: if adding any new mutable state here, make sure 'longjmp' still restores it

	//TODO:KILL (should not need during interpretation)
	ref immutable(ByteCode) byteCode() const return scope pure {
		return debugInfo.byteCode;
	}

	ref const(InterpreterDebugInfo) debugInfo() const return scope pure {
		return debugInfoPtr.deref();
	}
}

// WARN: Does not restore data. Just meant for setjmp/longjmp.
private struct InterpreterRestore {
	// This is the stack sizes and byte code index to be restored by longjmp
	ulong* dataStackTop;
	// Needs to restore position to 'returnStackTop' then push 'returnStackPush'
	// (since the last entry may be different)
	immutable(Operation)** returnStackTop;
	immutable(Operation)* returnStackPush;
	immutable(Operation)* nextByteCode;
}

private @system InterpreterRestore* createInterpreterRestore(return ref Interpreter a, immutable Operation* cur) {
	a.curRestore = InterpreterRestore(stackTop(a.dataStack), stackBeforeTop(a.returnStack), peek(a.returnStack), cur);
	return &a.curRestore;
}

private @system immutable(Operation*) applyInterpreterRestore(ref Interpreter a, InterpreterRestore* restore) {
	verify(restore == &a.curRestore);
	setStackTop(a.dataStack, restore.dataStackTop);
	setStackTop(a.returnStack, restore.returnStackTop);
	push(a.returnStack, restore.returnStackPush);
	immutable Operation* res = restore.nextByteCode;
	a.curRestore = InterpreterRestore();
	return res;
}

private immutable(NextOperation) getNextOperationAndDebug(ref Interpreter a, immutable Operation* cur) {
	printDebugInfo(a.debugInfo, a.dataStack, a.returnStack, cur);
	return immutable NextOperation(cur);
}

immutable(NextOperation) opAssertUnreachable(ref Interpreter a, immutable Operation* cur) {
	return unreachable!(immutable NextOperation)();
}

immutable(NextOperation) opBreak(ref Interpreter a, immutable Operation* cur) {
	return immutable NextOperation(cur);
}

@system immutable(NextOperation) opRemove(immutable size_t offset, immutable size_t nEntries)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	remove(a.dataStack, offset, nEntries);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opRemoveVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offset = readStackOffset(cur);
	immutable size_t nEntries = readSizeT(cur);
	remove(a.dataStack, offset, nEntries);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReturn(ref Interpreter a, immutable(Operation)* cur) {
	verify(!stackIsEmpty(a.returnStack));
	return nextOperation(a, pop(a.returnStack));
}

private immutable(Operation[8]) operationOpStopInterpretation = [
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
];

immutable(NextOperation) opStopInterpretation(ref Interpreter a, immutable(Operation)* cur) {
	return immutable NextOperation(&operationOpStopInterpretation[0]);
}

@system immutable(NextOperation) opJumpIfFalse(ref Interpreter a, immutable(Operation)* cur) {
	immutable ByteCodeOffsetUnsigned offset = immutable ByteCodeOffsetUnsigned(readSizeT(cur));
	immutable ulong value = pop(a.dataStack);
	if (value == 0)
		cur += offset.offset;
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opSwitch0ToN(ref Interpreter a, immutable(Operation)* cur) {
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(cur);
	immutable ulong value = pop(a.dataStack);
	immutable ByteCodeOffsetUnsigned offset = offsets[safeToSizeT(value)];
	return nextOperation(a, cur + offset.offset);
}

@system immutable(NextOperation) opStackRef(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offset = readStackOffset(cur);
	push(a.dataStack, cast(immutable ulong) stackRef(a.dataStack, offset));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadWords(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

@system immutable(NextOperation) opReadWordsVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	immutable size_t sizeWords = readSizeT(cur);
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

private @system immutable(NextOperation) opReadWordsCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	immutable ulong* ptr = (cast(immutable ulong*) pop(a.dataStack)) + offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords)
		push(a.dataStack, ptr[i]);
	return nextOperation(a, cur);
}


@system immutable(NextOperation) opReadNat8(immutable size_t offsetBytes)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	push(a.dataStack, *((cast(immutable ubyte*) pop(a.dataStack)) + offsetBytes));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadNat16(immutable size_t offsetNat16s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	push(a.dataStack, *((cast(immutable ushort*) pop(a.dataStack)) + offsetNat16s));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadNat32(immutable size_t offsetNat32s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	push(a.dataStack, *((cast(immutable uint*) pop(a.dataStack)) + offsetNat32s));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadBytesVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);
	immutable ubyte* ptr = (cast(immutable ubyte*) pop(a.dataStack)) + offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opWrite(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offset = readSizeT(cur);
	immutable size_t size = readSizeT(cur);
	if (size < 8) { //TODO:UNNECESSARY?
		verify(size != 0);
		immutable ulong value = pop(a.dataStack);
		ubyte* ptr = cast(ubyte*) pop(a.dataStack);
		writePartialBytes(ptr + offset, value, size);
	} else {
		immutable size_t sizeWords = divRoundUp(size, 8);
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords);
		ubyte* src = cast(ubyte*) (stackEnd(a.dataStack) - sizeWords);
		ubyte* dest = destWithoutOffset + offset;
		memcpy(dest, src, size);
		popN(a.dataStack, sizeWords + 1);
	}
	return nextOperation(a, cur);
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

@system immutable(NextOperation) opCall(ref Interpreter a, immutable(Operation)* cur) {
	immutable ByteCodeIndex address = immutable ByteCodeIndex(readSizeT(cur));
	return callCommon(a, address, cur);
}

@system immutable(NextOperation) opCallFunPtr(ref Interpreter a, immutable(Operation)* cur) {
	immutable DynCallSig sig = readDynCallSig(cur);
	immutable ulong funPtr = remove(a.dataStack, sig.parameterTypes.length);
	immutable ByteCodeIndex address = immutable ByteCodeIndex(safeToSizeT(funPtr));
	return address.index < a.byteCode.byteCode.length
		? callCommon(a, address, cur)
		: opCallFunPtrCommon(a, cur, cast(immutable FunPtr) funPtr, sig);
}

@system immutable(NextOperation) opCallFunPtrExtern(ref Interpreter a, immutable(Operation)* cur) {
	verify(FunPtr.sizeof <= ulong.sizeof);
	immutable FunPtr funPtr = cast(FunPtr) readNat64(cur);
	immutable DynCallSig sig = readDynCallSig(cur);
	return opCallFunPtrCommon(a, cur, funPtr, sig);
}

private @system immutable(DynCallSig) readDynCallSig(ref immutable(Operation)* cur) {
	return immutable DynCallSig(readArray!DynCallType(cur));
}

private @system immutable(NextOperation) opCallFunPtrCommon(
	ref Interpreter a,
	immutable(Operation)* cur,
	immutable FunPtr funPtr,
	scope immutable DynCallSig sig,
) {
	scope immutable ulong[] params = popN(a.dataStack, sig.parameterTypes.length);
	immutable ulong value = a.doDynCall(funPtr, sig, params);
	if (sig.returnType != DynCallType.void_)
		push(a.dataStack, value);
	return nextOperation(a, cur);
}

private @system immutable(NextOperation) callCommon(
	ref Interpreter a,
	immutable ByteCodeIndex address,
	immutable Operation* cur,
) {
	push(a.returnStack, cur);
	return nextOperation(a, &a.byteCode.byteCode[address.index]);
}

@system immutable(NextOperation) opExtern(ref Interpreter a, immutable(Operation)* cur) {
	immutable ExternOp op = cast(ExternOp) readNat64(cur);
	final switch (op) {
		case ExternOp.backtrace:
			immutable int size = cast(int) pop(a.dataStack);
			void** array = cast(void**) pop(a.dataStack);
			immutable size_t res = backtrace(a, array, cast(uint) size);
			verify(res <= int.max);
			push(a.dataStack, res);
			break;
		case ExternOp.longjmp:
			immutable ulong val = pop(a.dataStack); // TODO: verify this is int32?
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack);
			cur = applyInterpreterRestore(a, *jmpBufPtr);
			//TODO: freeInterpreterRestore
			push(a.dataStack, val);
			break;
		case ExternOp.setjmp:
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack);
			overwriteMemory(jmpBufPtr, createInterpreterRestore(a, cur));
			push(a.dataStack, 0);
			break;
	}
	return nextOperation(a, cur);
}

private @system immutable(size_t) backtrace(ref Interpreter a, void** res, immutable uint size) {
	immutable size_t resSize = min(stackSize(a.returnStack), size);
	foreach (immutable size_t i; 0 .. resSize)
		res[i] = cast(void*) (peek(a.returnStack, i) - a.byteCode.byteCode.ptr);
	return resSize;
}

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
private alias JmpBufTag = InterpreterRestore*;

@system immutable(NextOperation) opFnUnary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	push(a.dataStack, cb(pop(a.dataStack)));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opFnBinary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	immutable ulong y = pop(a.dataStack);
	immutable ulong x = pop(a.dataStack);
	push(a.dataStack, cb(x, y));
	return nextOperation(a, cur);
}

private @system immutable(NextOperation) nextOperation(ref Interpreter a, immutable Operation* cur) {
	static if (false)
		return getNextOperationAndDebug(a, cur);
	version(TailRecursionAvailable) {
		return cur.fn(a, cur + 1);
	} else {
		return immutable NextOperation(cur);
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

@system immutable(NextOperation) opJump(ref Interpreter a, immutable(Operation)* cur) {
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt64(cur));
	return nextOperation(a, cur + offset.offset);
}

@system immutable(NextOperation) opPack(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t inEntries = readSizeT(cur);
	immutable size_t outEntries = readSizeT(cur);
	immutable PackField[] fields = readArray!PackField(cur);

	ubyte* base = cast(ubyte*) (stackEnd(a.dataStack) - inEntries);
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset, base + field.inOffset, safeToSizeT(field.size));

	// drop extra entries
	drop(popN(a.dataStack, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + fields[$ - 1].outOffset + fields[$ - 1].size;
	while (ptr < cast(ubyte*) stackEnd(a.dataStack)) {
		*ptr = 0;
		ptr++;
	}

	return nextOperation(a, cur);
}

@system immutable(NextOperation) opPushValue64(ref Interpreter a, immutable(Operation)* cur) {
	push(a.dataStack, readNat64(cur));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupBytes(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);

	const ubyte* ptr = (cast(const ubyte*) stackEnd(a.dataStack)) - offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWord(immutable size_t offsetWords)(ref Interpreter a, immutable(Operation)* cur) {
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWordVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWords(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	const(ulong)* ptr = stackTop(a.dataStack) - offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		push(a.dataStack, *ptr);
		ptr++;
	}
	return nextOperation(a, cur);
}

// Copies data from the top of the stack to write to something lower on the stack.
@system immutable(NextOperation) opSet(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

@system immutable(NextOperation) opSetVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

private @system immutable(NextOperation) opSetCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	// Start at the end of the range and pop in reverse
	const ulong* begin = stackTop(a.dataStack) - offsetWords;
	const(ulong)* ptr = begin + sizeWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		ptr--;
		overwriteMemory(ptr, pop(a.dataStack));
	}
	verify(ptr == begin);
	return nextOperation(a, cur);
}

private @system void readNoCheck(ref DataStack dataStack, const ubyte* readFrom, immutable size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) stackEnd(dataStack);
	immutable size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	pushUninitialized(dataStack, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) stackEnd(dataStack)) {
		*endPtr = 0;
		endPtr++;
	}
}
