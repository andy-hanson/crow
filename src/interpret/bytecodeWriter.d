module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.applyFn : fnWrapAddIntegral, fnWrapMulIntegral;
import interpret.bytecode :
	addByteCodeIndex,
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	ExternOp,
	FileToFuns,
	Operation,
	stackEntrySize,
	StackOffset,
	StackOffsetBytes,
	subtractByteCodeIndex;
import interpret.extern_ : DynCallType;
import interpret.runBytecode :
	opAssertUnreachable,
	opCall,
	opCallFunPtr,
	opDupBytes,
	opDupWord,
	opDupWordVariable,
	opDupWords,
	opExtern,
	opExternDynCall,
	opFnBinary,
	opFnUnary,
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
	opRemove,
	opRemoveVariable,
	opReturn,
	opStackRef,
	opSwitch0ToN,
	opWrite;
import model.model : EnumValue;
import model.typeLayout : Pack;
import util.dbg : Debug;
import util.alloc.alloc : Alloc;
import util.collection.arr : empty;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictOfArr;
import util.collection.mutArr : moveToArr_mut, MutArr, mutArrEnd, mutArrPtrAt, mutArrSize, push, setAt;
import util.dbg : dbgLog = log;
import util.opt : force, has, none, Opt, some;
import util.memory : initMemory, overwriteMemory;
import util.ptr : Ptr;
import util.sym : Sym;
import util.util : divRoundUp, todo, verify;
import util.writer : finishWriter, writeNat, Writer, writeStatic;

struct ByteCodeWriter {
	private:
	Ptr!Alloc alloc;
	// NOTE: sometimes we will write operation arguments here and cast to Operation
	MutArr!(immutable Operation) operations;
	ArrBuilder!ByteCodeSource sources; // parallel to operations
	size_t nextStackEntry = 0;
}

ByteCodeWriter newByteCodeWriter(Ptr!Alloc alloc) {
	return ByteCodeWriter(alloc);
}

struct StackEntry {
	immutable size_t entry;
}

struct StackEntries {
	immutable StackEntry start; // Index of first entry
	immutable size_t size; // Number of entries
}

immutable(StackEntry) stackEntriesEnd(immutable StackEntries a) {
	return immutable StackEntry(a.start.entry + a.size);
}

@trusted immutable(ByteCode) finishByteCode(
	ref ByteCodeWriter writer,
	immutable ubyte[] text,
	immutable ByteCodeIndex mainIndex,
	immutable FileToFuns fileToFuns,
) {
	immutable Operation[] operations =
		moveToArr_mut!(immutable Operation)(writer.alloc.deref(), writer.operations);
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources =
		fullIndexDictOfArr!(ByteCodeIndex, ByteCodeSource)(finishArr(writer.alloc.deref(), writer.sources));
	return immutable ByteCode(operations, sources, fileToFuns, text, mainIndex);
}

immutable(StackEntry) getNextStackEntry(ref const ByteCodeWriter writer) {
	return immutable StackEntry(writer.nextStackEntry);
}

void setNextStackEntry(ref ByteCodeWriter writer, immutable StackEntry entry) {
	writer.nextStackEntry = entry.entry;
}

void setStackEntryAfterParameters(ref ByteCodeWriter writer, immutable StackEntry entry) {
	verify(writer.nextStackEntry == 0);
	writer.nextStackEntry = entry.entry;
}

immutable(ByteCodeIndex) nextByteCodeIndex(ref const ByteCodeWriter writer) {
	return immutable ByteCodeIndex(mutArrSize(writer.operations));
}

void writeAssertUnreachable(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opAssertUnreachable);
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

@trusted void fillDelayedCall(
	ref ByteCodeWriter writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	setAt(writer.operations, index.index, immutable Operation(immutable ulong(value.index)));
}

void writeCallFunPtr(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	// This is before the fun-ptr arg, which should be the first
	immutable StackEntry stackEntryBeforeArgs,
	immutable size_t nEntriesForReturnType,
) {
	log(dbg, writer, "write call fun-ptr");
	pushOperationFn(writer, source, &opCallFunPtr);
	pushSizeT(writer, source, getStackOffsetTo(writer, stackEntryBeforeArgs));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType;
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

void writeDupEntries(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	verify(entries.size != 0);
	verify(entries.start.entry + entries.size <= getNextStackEntry(writer).entry);
	writeDup(dbg, writer, source, entries.start, 0, entries.size * 8);
}

void writeDupEntry(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry entry,
) {
	writeDup(dbg, writer, source, entry, 0, 8);
}

void writeDup(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry start,
	immutable size_t offsetBytes,
	immutable size_t sizeBytes,
) {
	verify(sizeBytes != 0);
	verify(offsetBytes < 8);

	if (offsetBytes == 0 && sizeBytes % 8 == 0) {
		immutable size_t sizeWords = sizeBytes / 8;
		immutable size_t offset = getStackOffsetTo(writer, start);
		if (sizeWords == 1) {
			writeDupWord(writer, source, offset);
		} else {
			pushOperationFn(writer, source, &opDupWords);
			pushSizeT(writer, source, offset);
			pushSizeT(writer, source, sizeWords);
		}
	} else {
		pushOperationFn(writer, source, &opDupBytes);
		pushSizeT(writer, source, getStackOffsetBytes(writer, start, offsetBytes).offsetBytes);
		pushSizeT(writer, source, sizeBytes);
	}

	writer.nextStackEntry += divRoundUp(sizeBytes, 8);
}

private void writeDupWord(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable size_t offset) {
	static foreach (immutable size_t possibleOffset; 0 .. 8)
		if (offset == possibleOffset) {
			pushOperationFn(writer, source, &opDupWord!possibleOffset);
			return;
		}

	pushOperationFn(writer, source, &opDupWordVariable);
	pushSizeT(writer, source, offset);
}

void writeSet(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	writeSetInner(writer, source, getStackOffsetTo(writer, entries.start), entries.size);
	writer.nextStackEntry -= entries.size;
}

private void writeSetInner(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t size,
) {
	static foreach (immutable size_t possibleOffset; 0 .. 8)
		static foreach (immutable size_t possibleSize; 0 .. 4)
			if (offset == possibleOffset && size == possibleSize) {
				pushOperationFn(writer, source, &opSet!(possibleOffset, possibleSize));
				return;
			}

	pushOperationFn(writer, source, &opSetVariable);
	pushSizeT(writer, source, offset);
	pushSizeT(writer, source, size);
}

void writeRead(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t size,
) {
	log(dbg, writer, "write read");
	verify(size != 0);
	if (offset % 8 == 0 && size % 8 == 0)
		writeReadWords(writer, source, offset / 8, size / 8);
	else
		writeReadBytes(writer, source, offset, size);
	writer.nextStackEntry += divRoundUp(size, stackEntrySize) - 1;
}

private void writeReadWords(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	static foreach (immutable size_t possibleOffsetWords; 0 .. 8)
		static foreach (immutable size_t possibleSizeWords; 0 .. 4)
			if (offsetWords == possibleOffsetWords && sizeWords == possibleSizeWords) {
				pushOperationFn(writer, source, &opReadWords!(possibleOffsetWords, possibleSizeWords));
				return;
			}
	pushOperationFn(writer, source, &opReadWordsVariable);
	pushSizeT(writer, source, offsetWords);
	pushSizeT(writer, source, sizeWords);
}

private void writeReadBytes(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offsetBytes,
	immutable size_t sizeBytes,
) {
	switch (sizeBytes) {
		case 1:
			static foreach (immutable size_t possibleOffsetNat8s; 0 .. 8)
				if (offsetBytes == possibleOffsetNat8s) {
					pushOperationFn(writer, source, &opReadNat8!possibleOffsetNat8s);
					return;
				}
			break;
		case 2:
			if (offsetBytes % 2 == 0) {
				immutable size_t offsetNat16s = offsetBytes / 2;
				static foreach (immutable size_t possibleOffsetNat16s; 0 .. 4)
					if (offsetNat16s == possibleOffsetNat16s) {
						pushOperationFn(writer, source, &opReadNat16!possibleOffsetNat16s);
						return;
					}
			}
			break;
		case 4:
			if (offsetBytes % 4 == 0) {
				immutable size_t offsetNat32s = offsetBytes / 2;
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
	pushSizeT(writer, source, offsetBytes);
	pushSizeT(writer, source, sizeBytes);
}

void writeStackRef(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry stackEntry,
	immutable size_t byteOffset = 0,
) {
	log(dbg, writer, "write stack ref");
	pushOperationFn(writer, source, &opStackRef);
	immutable StackOffset offset = immutable StackOffset(getStackOffsetTo(writer, stackEntry));
	pushSizeT(writer, source, offset.offset);
	writer.nextStackEntry += 1;

	if (byteOffset != 0)
		writeAddConstantNat64(dbg, writer, source, byteOffset);
}

void writeWrite(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t size,
) {
	log(dbg, writer, "write write");
	verify(size != 0);
	pushOperationFn(writer, source, &opWrite);
	pushSizeT(writer, source, offset);
	pushSizeT(writer, source, size);
	writer.nextStackEntry -= divRoundUp(size, stackEntrySize) + 1;
}

void writeAddConstantNat64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ulong arg,
) {
	verify(arg != 0);
	writePushConstant(dbg, writer, source, arg);
	writeFnBinary!fnWrapAddIntegral(dbg, writer, source);
}

void writeMulConstantNat64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ulong arg,
) {
	verify(arg != 0 && arg != 1);
	writePushConstant(dbg, writer, source, arg);
	writeFnBinary!fnWrapMulIntegral(dbg, writer, source);
}

// Consume stack space without caring what's in it. Useful for unions.
void writePushEmptySpace(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t nSpaces,
) {
	foreach (immutable ulong i; 0 .. nSpaces)
		writePushConstant(dbg, writer, source, 0);
}

void writePushConstants(size_t n)(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ulong[n] values,
) {
	foreach (immutable ulong value; values)
		writePushConstant(dbg, writer, source, value);
}

void writePushConstant(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ulong value,
) {
	log(dbg, writer, "write push constant", value);
	pushOperationFn(writer, source, &opPushValue64);
	pushNat64(writer, source, value);
	writer.nextStackEntry++;
}

void writePushConstantPointer(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ubyte* value,
) {
	writePushConstant(dbg, writer, source, cast(ulong) value);
}

void writeReturn(scope ref Debug dbg, ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	log(dbg, writer, "write return");
	pushOperationFn(writer, source, &opReturn);
}

immutable(ByteCodeIndex) writePushFunPtrDelayed(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
) {
	log(dbg, writer, "write push fun ptr delayed common");
	pushOperationFn(writer, source, &opPushValue64);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushNat64(writer, source, 0);
	writer.nextStackEntry++;
	return fnAddress;
}

void writeRemove(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	log(dbg, writer, "write remove");
	if (entries.size != 0) {
		writeRemoveInner(
			writer,
			source,
			getStackOffsetTo(writer, entries.start),
			entries.size);
		writer.nextStackEntry -= entries.size;
	}
}

private void writeRemoveInner(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable size_t offset,
	immutable size_t nEntries,
) {
	static foreach (immutable size_t possibleOffset; 0 .. 4)
		static foreach (immutable size_t possibleNEntries; 0 .. 4)
			if (offset == possibleOffset && nEntries == possibleNEntries) {
				pushOperationFn(writer, source, &opRemove!(possibleOffset, possibleNEntries));
				return;
			}

	pushOperationFn(writer, source, &opRemoveVariable);
	pushSizeT(writer, source, offset);
	pushSizeT(writer, source, nEntries);
}

void writeJump(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ByteCodeIndex target,
) {
	log(dbg, writer, "write jump");
	pushOperationFn(writer, source, &opJump);
	// We take the jump after having read the jump value
	static assert(ByteCodeIndex.sizeof <= Operation.sizeof);
	pushInt64(writer, source, subtractByteCodeIndex(
		target,
		immutable ByteCodeIndex(nextByteCodeIndex(writer).index + 1)).offset);
}

immutable(ByteCodeIndex) writeJumpDelayed(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
) {
	log(dbg, writer, "write jump delayed");
	pushOperationFn(writer, source, &opJump);
	immutable ByteCodeIndex jumpOffsetIndex = nextByteCodeIndex(writer);
	static assert(ByteCodeOffset.sizeof == long.sizeof);
	pushInt64(writer, source, 0);
	return jumpOffsetIndex;
}

@trusted void fillInJumpDelayed(ref ByteCodeWriter writer, immutable ByteCodeIndex jumpIndex) {
	immutable ByteCodeOffset offset = getByteCodeOffsetForJumpToCurrent(writer, jumpIndex);
	setAt(writer.operations, jumpIndex.index, immutable Operation(offset.offset));
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

void writePack(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope immutable Pack pack,
) {
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
	setAt(writer.operations, delayed.offsetIndex.index, immutable Operation(diff.offset));
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
		cast(ByteCodeOffsetUnsigned*) mutArrPtrAt(writer.operations, delayed.firstCase.index);
	immutable ByteCodeOffsetUnsigned diff =
		subtractByteCodeIndex(nextByteCodeIndex(writer), delayed.afterCases).unsigned();
	overwriteMemory(start + switchEntry, diff);
}

immutable(SwitchDelayed) writeSwitchWithValuesDelay(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource,
	immutable EnumValue[],
) {
	return todo!(immutable SwitchDelayed)("!");
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
}

void writeExtern(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable ExternOp op) {
	immutable int stackEffect = () {
		final switch (op) {
			case ExternOp.pthreadCreate:
				return -3;
			case ExternOp.longjmp:
			case ExternOp.memcpy:
			case ExternOp.memmove:
			case ExternOp.memset:
			case ExternOp.write:
				return -2;
			case ExternOp.backtrace:
			case ExternOp.clockGetTime:
			case ExternOp.free:
			case ExternOp.pthreadCondattrSetClock:
			case ExternOp.pthreadCondInit:
			case ExternOp.pthreadJoin:
			case ExternOp.pthreadMutexInit:
				return -1;
			case ExternOp.malloc:
			case ExternOp.pthreadCondattrDestroy:
			case ExternOp.pthreadCondattrInit:
			case ExternOp.pthreadCondBroadcast:
			case ExternOp.pthreadCondDestroy:
			case ExternOp.pthreadMutexattrDestroy:
			case ExternOp.pthreadMutexattrInit:
			case ExternOp.pthreadMutexDestroy:
			case ExternOp.pthreadMutexLock:
			case ExternOp.pthreadMutexUnlock:
			case ExternOp.setjmp:
				return 0;
			case ExternOp.getNProcs:
			case ExternOp.schedYield:
				return 1;
		}
	}();
	pushOperationFn(writer, source, &opExtern);
	pushNat64(writer, source, op);
	writer.nextStackEntry += stackEffect;
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
		T* outBegin = cast(T*) mutArrPtrAt(writer.operations, mutArrSize(writer.operations) - nOperations);
		foreach (immutable size_t i, immutable T value; values)
			initMemory(outBegin + i, value);
		verify(outBegin + values.length <= cast(T*) mutArrEnd(writer.operations));
	}
}

void writeExternDynCall(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Sym name,
	immutable DynCallType returnType,
	scope immutable DynCallType[] parameterTypes,
) {
	pushOperationFn(writer, source, &opExternDynCall);
	pushNat64(writer, source, name.value);
	pushNat64(writer, source, returnType);
	writeArray!DynCallType(writer, source, parameterTypes);
	writer.nextStackEntry -= parameterTypes.length;
	writer.nextStackEntry += (returnType == DynCallType.void_ ? 0 : 1);
}

void writeFnBinary(alias fn)(scope ref Debug dbg, ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opFnBinary!fn);
	writer.nextStackEntry--;
}

void writeFnUnary(alias fn)(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperationFn(writer, source, &opFnUnary!fn);
}

private void pushOperation(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Operation value) {
	push(writer.alloc.deref(), writer.operations, value);
	add(writer.alloc.deref(), writer.sources, source);
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

void log(scope ref Debug dbg, ref ByteCodeWriter byteCodeWriter, immutable string message) {
	log(dbg, byteCodeWriter, message, none!ulong);
}

void log(
	scope ref Debug dbg,
	ref ByteCodeWriter byteCodeWriter,
	immutable string message,
	immutable ulong value,
) {
	log(dbg, byteCodeWriter, message, some(value));
}

void log(
	scope ref Debug dbg,
	ref ByteCodeWriter byteCodeWriter,
	immutable string message,
	immutable Opt!ulong value,
) {
	if (dbg.enabled()) {
		Writer writer = Writer(byteCodeWriter.alloc);
		writeStatic(writer, message);
		if (has(value)) {
			writeStatic(writer, " = ");
			writeNat(writer, force(value));
		}
		writeStatic(writer, " at bytecode offset ");
		writeNat(writer, nextByteCodeIndex(byteCodeWriter).index);
		dbgLog(dbg, finishWriter(writer));
	}
}
