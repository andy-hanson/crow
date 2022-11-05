module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.applyFn : fnWrapAddIntegral, fnWrapMulIntegral;
import interpret.bytecode :
	addByteCodeIndex,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	Operation,
	Operations,
	stackEntrySize,
	StackOffset,
	StackOffsetBytes,
	subtractByteCodeIndex;
import interpret.extern_ : DynCallType, DynCallSig, FunPtr;
import interpret.runBytecode :
	opBreak,
	opCall,
	opCallFunPtr,
	opCallFunPtrExtern,
	opDupBytes,
	opDupWords,
	opDupWordsVariable,
	opFnBinary,
	opFnUnary,
	opInterpreterBacktrace,
	opLongjmp,
	opPack,
	opPushValue64,
	opSet,
	opSetVariable,
	opJump,
	opJumpIfFalse,
	opReadBytesVariable,
	opReadNat8,
	opReadNat16,
	opReadNat32,
	opReadWords,
	opReadWordsVariable,
	opReturnData,
	opReturnDataVariable,
	opReturn,
	opSetjmp,
	opStackRef,
	opSwitch0ToN,
	opThreadLocalPtr,
	opWrite;
import model.model : EnumValue;
import model.typeLayout : Pack;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, backUp, finishArr;
import util.col.fullIndexDict : fullIndexDictOfArr;
import util.col.mutArr : moveToArr_mut, mustPop, MutArr, mutArrEnd, mutArrSize, push;
import util.memory : initMemory, overwriteMemory;
import util.util : divRoundUp, todo, verify;

struct ByteCodeWriter {
	private:
	Alloc* alloc;
	// NOTE: sometimes we will write operation arguments here and cast to Operation
	MutArr!Operation operations;
	ArrBuilder!ByteCodeSource sources; // parallel to operations
	size_t nextStackEntry = 0;
}

ByteCodeWriter newByteCodeWriter(Alloc* alloc) =>
	ByteCodeWriter(alloc);

struct StackEntry {
	immutable size_t entry;
}

struct StackEntries {
	immutable StackEntry start; // Index of first entry
	immutable size_t size; // Number of entries
}

immutable(StackEntry) stackEntriesEnd(immutable StackEntries a) =>
	immutable StackEntry(a.start.entry + a.size);

Operations finishOperations(
	ref ByteCodeWriter writer,
) =>
	Operations(
		moveToArr_mut!Operation(*writer.alloc, writer.operations),
		fullIndexDictOfArr!(ByteCodeIndex, ByteCodeSource)(finishArr(*writer.alloc, writer.sources)));

immutable(StackEntry) getNextStackEntry(ref const ByteCodeWriter writer) =>
	immutable StackEntry(writer.nextStackEntry);

void setNextStackEntry(ref ByteCodeWriter writer, immutable StackEntry entry) {
	writer.nextStackEntry = entry.entry;
}

void setStackEntryAfterParameters(ref ByteCodeWriter writer, immutable StackEntry entry) {
	verify(writer.nextStackEntry == 0);
	writer.nextStackEntry = entry.entry;
}

immutable(ByteCodeIndex) nextByteCodeIndex(ref const ByteCodeWriter writer) =>
	immutable ByteCodeIndex(mutArrSize(writer.operations));

// This special instruction returns instead of proceeding to the next operation.
// (Though in non-tail-recursive builds, all operations return.)
void writeBreak(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opBreak);
}

immutable(ByteCodeIndex) writeCallDelayed(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry stackEntryBeforeArgs,
	immutable size_t nEntriesForReturnType,
) {
	pushOperationFn(writer, source, &opCall);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushNat64(writer, source, 0);
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType;
	return fnAddress;
}

void fillDelayedCall(ref Operations operations, immutable ByteCodeIndex index, immutable Operation* definition) {
	operations.byteCode[index.index] = immutable Operation(definition);
}

void writeCallFunPtr(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	// This is before the fun-pointer arg, which should be the first
	immutable StackEntry stackEntryBeforeArgs,
	scope immutable DynCallSig sig,
) {
	verify(stackEntryBeforeArgs.entry == writer.nextStackEntry - sig.parameterTypes.length - 1);
	pushOperationFn(writer, source, &opCallFunPtr);
	writeCallFunPtrCommon(writer, source, sig);
	writer.nextStackEntry -= 1; // for the fun-pointer
	verify(writer.nextStackEntry == stackEntryBeforeArgs.entry + (sig.returnType == DynCallType.void_ ? 0 : 1));
}

void writeCallFunPtrExtern(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable FunPtr funPtr,
	scope immutable DynCallSig sig,
) {
	pushOperationFn(writer, source, &opCallFunPtrExtern);
	pushNat64(writer, source, cast(immutable ulong) funPtr.fn);
	writeCallFunPtrCommon(writer, source, sig);
}

private void writeCallFunPtrCommon(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope immutable DynCallSig sig,
) {
	writeArray!DynCallType(writer, source, sig.returnTypeAndParameterTypes);
	writer.nextStackEntry -= sig.parameterTypes.length;
	writer.nextStackEntry += (sig.returnType == DynCallType.void_ ? 0 : 1);
}

private immutable(size_t) getStackOffsetTo(
	ref const ByteCodeWriter writer,
	immutable StackEntry stackEntry,
) {
	verify(stackEntry.entry < getNextStackEntry(writer).entry);
	return getNextStackEntry(writer).entry - 1 - stackEntry.entry;
}

private immutable(StackOffsetBytes) getStackOffsetBytes(
	ref const ByteCodeWriter writer,
	immutable StackEntry stackEntry,
	immutable size_t offsetBytes,
) {
	// stack entry offsets use 0 for the last entry,
	// but byte offsets use 0 for the next entry (thus 1 is the final byte of the last entry)
	return immutable StackOffsetBytes((getStackOffsetTo(writer, stackEntry) + 1) * 8 - offsetBytes);
}

void writeDupEntries(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable StackEntries entries) {
	verify(entries.size != 0);
	verify(entries.start.entry + entries.size <= getNextStackEntry(writer).entry);
	writeDup(writer, source, entries.start, 0, entries.size * 8);
}

void writeDupEntry(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable StackEntry entry) {
	writeDup(writer, source, entry, 0, 8);
}

void writeDup(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry start,
	immutable size_t offsetBytes,
	immutable size_t sizeBytes,
) {
	verify(sizeBytes != 0);
	verify(offsetBytes < 8);

	if (offsetBytes == 0 && sizeBytes % 8 == 0) {
		writeDupWords(writer, source, getStackOffsetTo(writer, start), sizeBytes / 8);
	} else {
		pushOperationFn(writer, source, &opDupBytes);
		pushSizeT(writer, source, getStackOffsetBytes(writer, start, offsetBytes).offsetBytes);
		pushSizeT(writer, source, sizeBytes);
		writer.nextStackEntry += divRoundUp(sizeBytes, 8);
	}
}

private void writeDupWords(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	verify(sizeWords != 0);
	writer.nextStackEntry += sizeWords;

	static foreach (immutable size_t possibleSize; 1 .. 8)
		static foreach (immutable size_t possibleOffset; possibleSize - 1 .. 16)
			if (offsetWords == possibleOffset && sizeWords == possibleSize) {
				pushOperationFn(writer, source, &opDupWords!(possibleOffset, possibleSize));
				return;
			}

	pushOperationFn(writer, source, &opDupWordsVariable);
	pushSizeT(writer, source, offsetWords);
	pushSizeT(writer, source, sizeWords);
}

void writeSet(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable StackEntries entries) {
	if (entries.size != 0) {
		writeSetInner(writer, source, getStackOffsetTo(writer, entries.start), entries.size);
		writer.nextStackEntry -= entries.size;
	}
}

private void writeSetInner(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t size,
) {
	static foreach (immutable size_t possibleSize; 1 .. 8)
		static foreach (immutable size_t possibleOffset; possibleSize - 1 .. 16)
			if (offset == possibleOffset && size == possibleSize) {
				pushOperationFn(writer, source, &opSet!(possibleOffset, possibleSize));
				return;
			}

	pushOperationFn(writer, source, &opSetVariable);
	pushSizeT(writer, source, offset);
	pushSizeT(writer, source, size);
}

void writeRead(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t pointerOffsetBytes,
	immutable size_t nBytesToRead,
) {
	verify(nBytesToRead != 0);
	if (pointerOffsetBytes % 8 == 0 && nBytesToRead % 8 == 0)
		writeReadWords(writer, source, pointerOffsetBytes / 8, nBytesToRead / 8);
	else
		writeReadBytes(writer, source, pointerOffsetBytes, nBytesToRead);
	writer.nextStackEntry += divRoundUp(nBytesToRead, stackEntrySize) - 1;
}

private void writeReadWords(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t pointerOffsetWords,
	immutable size_t nWordsToRead,
) {
	verify(nWordsToRead != 0);

	static foreach (immutable size_t possiblePointerOffsetWords; 0 .. 8)
		static foreach (immutable size_t possibleNWordsToRead; 1 .. 4)
			if (pointerOffsetWords == possiblePointerOffsetWords && nWordsToRead == possibleNWordsToRead) {
				pushOperationFn(writer, source, &opReadWords!(possiblePointerOffsetWords, possibleNWordsToRead));
				return;
			}

	pushOperationFn(writer, source, &opReadWordsVariable);
	pushSizeT(writer, source, pointerOffsetWords);
	pushSizeT(writer, source, nWordsToRead);
}

private void writeReadBytes(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t pointerOffsetBytes,
	immutable size_t nBytesToRead,
) {
	switch (nBytesToRead) {
		case 1:
			static foreach (immutable size_t possibleOffsetNat8s; 0 .. 8)
				if (pointerOffsetBytes == possibleOffsetNat8s) {
					pushOperationFn(writer, source, &opReadNat8!possibleOffsetNat8s);
					return;
				}
			break;
		case 2:
			if (pointerOffsetBytes % 2 == 0) {
				immutable size_t offsetNat16s = pointerOffsetBytes / 2;
				static foreach (immutable size_t possibleOffsetNat16s; 0 .. 4)
					if (offsetNat16s == possibleOffsetNat16s) {
						pushOperationFn(writer, source, &opReadNat16!possibleOffsetNat16s);
						return;
					}
			}
			break;
		case 4:
			if (pointerOffsetBytes % 4 == 0) {
				immutable size_t offsetNat32s = pointerOffsetBytes / 2;
				static foreach (immutable size_t possibleOffsetNat32s; 0 .. 2)
					if (offsetNat32s == possibleOffsetNat32s) {
						pushOperationFn(writer, source, &opReadNat32!possibleOffsetNat32s);
						return;
					}
			}
			break;
		default:
			break;
	}

	pushOperationFn(writer, source, &opReadBytesVariable);
	pushSizeT(writer, source, pointerOffsetBytes);
	pushSizeT(writer, source, nBytesToRead);
}

void writeStackRef(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry stackEntry,
	immutable size_t byteOffset = 0,
) {
	pushOperationFn(writer, source, &opStackRef);
	immutable StackOffset offset = immutable StackOffset(getStackOffsetTo(writer, stackEntry));
	pushSizeT(writer, source, offset.offset);
	writer.nextStackEntry += 1;

	if (byteOffset != 0)
		writeAddConstantNat64(writer, source, byteOffset);
}

void writeThreadLocalPtr(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable size_t offset) {
	pushOperationFn(writer, source, &opThreadLocalPtr);
	pushSizeT(writer, source, offset);	
	writer.nextStackEntry += 1;
}

void writeWrite(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t size,
) {
	verify(size != 0);
	pushOperationFn(writer, source, &opWrite);
	pushSizeT(writer, source, offset);
	pushSizeT(writer, source, size);
	writer.nextStackEntry -= divRoundUp(size, stackEntrySize) + 1;
}

void writeAddConstantNat64(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ulong arg) {
	verify(arg != 0);
	writePushConstant(writer, source, arg);
	writeFnBinary!fnWrapAddIntegral(writer, source);
}

void writeMulConstantNat64(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ulong arg) {
	verify(arg != 0 && arg != 1);
	writePushConstant(writer, source, arg);
	writeFnBinary!fnWrapMulIntegral(writer, source);
}

// Consume stack space without caring what's in it. Useful for unions.
void writePushEmptySpace(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable size_t nSpaces) {
	foreach (immutable ulong i; 0 .. nSpaces)
		writePushConstant(writer, source, 0);
}

void writePushConstants(ref ByteCodeWriter writer, immutable ByteCodeSource source, scope immutable ulong[] values) {
	foreach (immutable ulong value; values)
		writePushConstant(writer, source, value);
}

void writePushConstant(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ulong value) {
	pushOperationFn(writer, source, &opPushValue64);
	pushNat64(writer, source, value);
	writer.nextStackEntry++;
}

void writePushConstantPointer(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ubyte* value) {
	writePushConstant(writer, source, cast(ulong) value);
}

void writeReturn(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opReturn);
}

immutable(ByteCodeIndex) writePushFunPtrDelayed(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
) {
	pushOperationFn(writer, source, &opPushValue64);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushNat64(writer, source, 0);
	writer.nextStackEntry++;
	return fnAddress;
}

void fillDelayedFunPtr(ref Operations operations, immutable ByteCodeIndex index, immutable FunPtr definition) {
	operations.byteCode[index.index] = immutable Operation(cast(immutable ulong) definition.fn);
}

void writeRemove(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable StackEntries entries) {
	if (entries.size != 0) {
		writeRemoveInner(
			writer,
			source,
			getStackOffsetTo(writer, entries.start),
			entries.size);
		writer.nextStackEntry -= entries.size;
	}
}

/*
'returnEntries' is where we want to return value to end up. (It is currently at the end of the stack)
*/
void writeReturnData(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable StackEntries returnEntries) {
	immutable StackEntry next = getNextStackEntry(writer);
	immutable StackEntry returnEnd = stackEntriesEnd(returnEntries);
	verify(stackEntriesEnd(returnEntries).entry <= next.entry);
	if (returnEnd != next) {
		immutable size_t offset = getStackOffsetTo(writer, returnEntries.start);
		writeReturnDataInner(writer, source, offset, returnEntries.size);
		verify(writer.nextStackEntry - (offset + 1) + returnEntries.size == returnEnd.entry);
		writer.nextStackEntry = returnEnd.entry;
	}
}

private void writeRemoveInner(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offsetWords,
	immutable size_t removedWords,
) {
	verify(removedWords <= offsetWords + 1);
	immutable size_t returnedWords = offsetWords + 1 - removedWords;
	writeReturnDataInner(writer, source, offsetWords, returnedWords);
}

private void writeReturnDataInner(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offsetWords,
	immutable size_t returnedWords,
) {
	verify(returnedWords <= offsetWords + 1);

	static foreach (immutable size_t possibleSize; 0 .. 8)
		static foreach (immutable size_t possibleOffset; possibleSize + 1 .. 16)
			if (offsetWords == possibleOffset && returnedWords == possibleSize) {
				pushOperationFn(writer, source, &opReturnData!(possibleOffset, possibleSize));
				return;
			}

	pushOperationFn(writer, source, &opReturnDataVariable);
	pushSizeT(writer, source, offsetWords);
	pushSizeT(writer, source, returnedWords);
}

void writeJump(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ByteCodeIndex target) {
	pushOperationFn(writer, source, &opJump);
	// We take the jump after having read the jump value
	static assert(ByteCodeIndex.sizeof <= Operation.sizeof);
	pushInt64(writer, source, subtractByteCodeIndex(
		target,
		immutable ByteCodeIndex(nextByteCodeIndex(writer).index + 1)).offset);
}

immutable(ByteCodeIndex) writeJumpDelayed(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opJump);
	immutable ByteCodeIndex jumpOffsetIndex = nextByteCodeIndex(writer);
	static assert(ByteCodeOffset.sizeof == long.sizeof);
	pushInt64(writer, source, 0);
	return jumpOffsetIndex;
}

@trusted void fillInJumpDelayed(ref ByteCodeWriter writer, immutable ByteCodeIndex jumpIndex) {
	if (jumpIndex.index == nextByteCodeIndex(writer).index) {
		todo!void("!"); // I think this will work, but don't have code testing it yet
		// This happens for a 'break' at the bottom of a loop.
		// Just back up to remove the jump.
		immutable Operation popped1 = popOperation(writer);
		verify(popped1.ulong_ == 0);
		immutable Operation popped0 = popOperation(writer);
		verify(popped0.fn == &opJump);
	} else {
		immutable ByteCodeOffset offset = getByteCodeOffsetForJumpToCurrent(writer, jumpIndex);
		writer.operations[jumpIndex.index] = immutable Operation(offset.offset);
	}
}

private immutable(ByteCodeOffset) getByteCodeOffsetForJumpToCurrent(
	ref const ByteCodeWriter writer,
	immutable ByteCodeIndex jumpIndex,
) {
	verify(jumpIndex.index < nextByteCodeIndex(writer).index);
	static assert(ByteCodeIndex.sizeof <= Operation.sizeof);
	// We add the jump offset after having read the jump value
	immutable ByteCodeIndex jumpEnd = addByteCodeIndex(jumpIndex, 1);
	return subtractByteCodeIndex(nextByteCodeIndex(writer), jumpEnd);
}

void writePack(ref ByteCodeWriter writer, immutable ByteCodeSource source, scope immutable Pack pack) {
	pushOperationFn(writer, source, &opPack);
	pushSizeT(writer, source, pack.inEntries);
	pushSizeT(writer, source, pack.outEntries);
	writeArray(writer, source, pack.fields);
	writer.nextStackEntry -= pack.inEntries;
	writer.nextStackEntry += pack.outEntries;
}

struct JumpIfFalseDelayed {
	immutable ByteCodeIndex offsetIndex;
}

immutable(JumpIfFalseDelayed) writeJumpIfFalseDelayed(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opJumpIfFalse);
	immutable ByteCodeIndex offsetIndex = nextByteCodeIndex(writer);
	pushNat64(writer, source, 0);
	writer.nextStackEntry -= 1;
	return immutable JumpIfFalseDelayed(offsetIndex);
}

@trusted void fillDelayedJumpIfFalse(ref ByteCodeWriter writer, immutable JumpIfFalseDelayed delayed) {
	immutable ByteCodeOffsetUnsigned diff =
		subtractByteCodeIndex(
			nextByteCodeIndex(writer),
			// + 1 because jump is relative to after reading the offset
			addByteCodeIndex(delayed.offsetIndex, 1),
		).unsigned();
	static assert(ByteCodeOffsetUnsigned.sizeof <= Operation.sizeof);
	writer.operations[delayed.offsetIndex.index] = immutable Operation(diff.offset);
}

struct SwitchDelayed {
	immutable ByteCodeIndex firstCase;
	immutable ByteCodeIndex afterCases;
}

immutable(SwitchDelayed) writeSwitch0ToNDelay(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t nCases,
) {
	pushOperationFn(writer, source, &opSwitch0ToN);
	// + 1 because the array size takes up one entry
	immutable ByteCodeIndex addresses = addByteCodeIndex(nextByteCodeIndex(writer), 1);
	verify(nCases < emptyCases.length);
	writeArray!ByteCodeOffsetUnsigned(writer, source, emptyCases[0 .. nCases]);
	writer.nextStackEntry -= 1;
	return immutable SwitchDelayed(addresses, nextByteCodeIndex(writer));
}

private immutable ByteCodeOffsetUnsigned[64] emptyCases;

@trusted void fillDelayedSwitchEntry(
	ref ByteCodeWriter writer,
	immutable SwitchDelayed delayed,
	immutable size_t switchEntry,
) {
	ByteCodeOffsetUnsigned* start =
		cast(ByteCodeOffsetUnsigned*) &writer.operations[delayed.firstCase.index];
	immutable ByteCodeOffsetUnsigned diff =
		subtractByteCodeIndex(nextByteCodeIndex(writer), delayed.afterCases).unsigned();
	overwriteMemory(start + switchEntry, diff);
}

immutable(SwitchDelayed) writeSwitchWithValuesDelay(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource,
	immutable EnumValue[],
) {
	/*
	pushOperation(writer, source, &opSwitchWithValues);
	pushNat64(writer, source, sizeNat(values));
	foreach (immutable EnumValue value; values)
		pushNat64(writer, source, value.asUnsigned());
	writer.nextStackEntry -= 1;
	immutable ByteCodeIndex addresses = nextByteCodeIndex(writer);
	foreach (immutable size_t; 0 .. size(values)) {
		static assert(ByteCodeOffset.sizeof == Nat64.sizeof);
		pushNat64(writer, source, immutable Nat64(0));
	}
	return addresses;
	*/
	return todo!(immutable SwitchDelayed)("!");
}

void writeSetjmp(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opSetjmp);
}

void writeLongjmp(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opLongjmp);
	writer.nextStackEntry -= 2;
}

private @trusted void writeArray(T)(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope immutable T[] values,
) {
	pushSizeT(writer, source, values.length);
	if (!empty(values)) {
		immutable size_t nOperations = divRoundUp(values.length * T.sizeof, Operation.sizeof);
		foreach (immutable size_t i; 0 .. nOperations)
			pushOperation(writer, source, immutable Operation(immutable ulong(0)));
		T* outBegin = cast(T*) &writer.operations[mutArrSize(writer.operations) - nOperations];
		foreach (immutable size_t i, immutable T value; values)
			initMemory(outBegin + i, value);
		verify(outBegin + values.length <= cast(T*) mutArrEnd(writer.operations));
	}
}

void writeInterpreterBacktrace(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opInterpreterBacktrace);
	writer.nextStackEntry -= 2;
}

void writeFnBinary(alias fn)(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opFnBinary!fn);
	writer.nextStackEntry--;
}

void writeFnUnary(alias fn)(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opFnUnary!fn);
}

private void pushOperation(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Operation value) {
	push(*writer.alloc, writer.operations, value);
	add(*writer.alloc, writer.sources, source);
}

private immutable(Operation) popOperation(ref ByteCodeWriter writer) {
	immutable Operation res = mustPop(writer.operations);
	backUp(writer.sources);
	return res;
}

private void pushOperationFn(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Operation.Fn fn) {
	pushOperation(writer, source, immutable Operation(fn));
}

private void pushInt64(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable long value) {
	pushOperation(writer, source, immutable Operation(value));
}

private void pushNat64(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ulong value) {
	pushOperation(writer, source, immutable Operation(value));
}

private void pushSizeT(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable size_t value) {
	pushNat64(writer, source, value);
}
