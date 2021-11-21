module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.bytecode :
	addByteCodeIndex,
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	ExternOp,
	FileToFuns,
	FnOp,
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
	opDupWords,
	opExtern,
	opExternDynCall,
	opFn,
	opPack,
	opPushValue32,
	opPushValue64,
	opSet,
	opJump,
	opJumpIfFalse,
	opRead,
	opRemove,
	opReturn,
	opStackRef,
	opSwitch0ToN,
	opWrite;
import model.model : EnumValue;
import model.typeLayout : Pack;
import util.dbg : Debug;
import util.alloc.alloc : Alloc;
import util.collection.arr : empty, size, sizeNat;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictOfArr;
import util.collection.mutArr : moveToArr_mut, MutArr, mutArrEnd, mutArrPtrAt, mutArrSize, push, setAt;
import util.dbg : dbgLog = log;
import util.opt : force, has, none, Opt, some;
import util.memory : initMemory, overwriteMemory;
import util.ptr : Ptr;
import util.sym : Sym;
import util.util : divRoundUp, todo, verify;
import util.types : decr, incr, Int16, Nat8, Nat16, Nat32, Nat48, Nat64, NatN, zero;
import util.writer : finishWriter, writeNat, Writer, writeStatic;

struct ByteCodeWriter {
	private:
	Ptr!Alloc alloc;
	// NOTE: sometimes we will write operation arguments here and cast to Operation
	MutArr!(immutable Operation) operations;
	ArrBuilder!ByteCodeSource sources; // parallel to operations
	Nat16 nextStackEntry = immutable Nat16(0);
}

ByteCodeWriter newByteCodeWriter(Ptr!Alloc alloc) {
	return ByteCodeWriter(alloc);
}

struct StackEntry {
	immutable Nat16 entry;
}

struct StackEntries {
	immutable StackEntry start; // Index of first entry
	immutable Nat8 size; // Number of entries
}

immutable(StackEntry) stackEntriesEnd(immutable StackEntries a) {
	return immutable StackEntry(a.start.entry + a.size.to16());
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
	verify(zero(writer.nextStackEntry));
	writer.nextStackEntry = entry.entry;
}

immutable(ByteCodeIndex) nextByteCodeIndex(ref const ByteCodeWriter writer) {
	return immutable ByteCodeIndex((immutable Nat64(mutArrSize(writer.operations))).to32());
}

void writeAssertUnreachable(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperation(writer, source, &opAssertUnreachable);
}

immutable(ByteCodeIndex) writeCallDelayed(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry stackEntryBeforeArgs,
	immutable Nat8 nEntriesForReturnType,
) {
	pushOperation(writer, source, &opCall);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, immutable Nat32(0));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType.to16();
	return fnAddress;
}

@trusted void fillDelayedCall(
	ref ByteCodeWriter writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	setAt(writer.operations, index.index.raw(), cast(Operation) value.index.raw());
}

void writeCallFunPtr(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	// This is before the fun-ptr arg, which should be the first
	immutable StackEntry stackEntryBeforeArgs,
	immutable Nat8 nEntriesForReturnType,
) {
	log(dbg, writer, "write call fun-ptr");
	pushOperation(writer, source, &opCallFunPtr);
	pushU8(writer, source, getStackOffsetTo(writer, stackEntryBeforeArgs));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType.to16();
}

private immutable(Nat8) getStackOffsetTo(
	ref const ByteCodeWriter writer,
	immutable StackEntry stackEntry,
) {
	verify(stackEntry.entry < getNextStackEntry(writer).entry);
	return (decr(getNextStackEntry(writer).entry) - stackEntry.entry).to8();
}

private immutable(StackOffsetBytes) getStackOffsetBytes(
	ref const ByteCodeWriter writer,
	immutable StackEntry stackEntry,
	immutable Nat8 offsetBytes,
) {
	// stack entry offsets use 0 for the last entry,
	// but byte offsets use 0 for the next entry (thus 1 is the final byte of the last entry)
	return immutable StackOffsetBytes(
		incr(getStackOffsetTo(writer, stackEntry)).to16() * immutable Nat16(8) - offsetBytes.to16());
}

void writeDupEntries(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	verify(!zero(entries.size));
	verify(entries.start.entry + entries.size.to16() <= getNextStackEntry(writer).entry);
	writeDup(dbg, writer, source, entries.start, immutable Nat8(0), entries.size.to16() * immutable Nat16(8));
}

void writeDupEntry(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry entry,
) {
	writeDup(dbg, writer, source, entry, immutable Nat8(0), immutable Nat16(8));
}

void writeDup(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry start,
	immutable Nat8 offsetBytes,
	immutable Nat16 sizeBytes,
) {
	verify(!zero(sizeBytes));

	if (zero(offsetBytes) && zero(sizeBytes % immutable Nat16(8))) {
		immutable Nat8 sizeWords = (sizeBytes / immutable Nat16(8)).to8();
		immutable Nat8 offset = getStackOffsetTo(writer, start);
		if (sizeWords == immutable Nat8(1)) {
			pushOperation(writer, source, &opDupWord);
			pushU8(writer, source, offset);
		} else {
			pushOperation(writer, source, &opDupWords);
			pushU8(writer, source, offset);
			pushU8(writer, source, sizeWords);
		}
	} else {
		pushOperation(writer, source, &opDupBytes);
		pushU16(writer, source, getStackOffsetBytes(writer, start, offsetBytes).offsetBytes);
		pushU16(writer, source, sizeBytes);
	}

	writer.nextStackEntry += divRoundUp(sizeBytes, immutable Nat16(8));
}

void writeSet(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	pushOperation(writer, source, &opSet);
	pushU8(writer, source, getStackOffsetTo(writer, entries.start));
	pushU8(writer, source, entries.size);
	writer.nextStackEntry -= entries.size.to16();
}

void writeRead(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	log(dbg, writer, "write read");
	verify(!zero(size));
	pushOperation(writer, source, &opRead);
	pushU16(writer, source, offset);
	pushU16(writer, source, size);
	writer.nextStackEntry += decr(divRoundUp(size, stackEntrySize));
}

void writeStackRef(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable StackEntry stackEntry,
	immutable Nat8 byteOffset = immutable Nat8(0),
) {
	log(dbg, writer, "write stack ref");
	pushOperation(writer, source, &opStackRef);
	immutable StackOffset offset = immutable StackOffset(getStackOffsetTo(writer, stackEntry));
	pushU8(writer, source, offset.offset);
	writer.nextStackEntry += 1;

	if (!zero(byteOffset)) {
		writeAddConstantNat64(dbg, writer, source, byteOffset.to64());
	}
}

void writeWrite(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	log(dbg, writer, "write write");
	verify(!zero(size));
	pushOperation(writer, source, &opWrite);
	pushU16(writer, source, offset);
	pushU16(writer, source, size);
	writer.nextStackEntry -= incr(divRoundUp(size, stackEntrySize));
}

void writeAddConstantNat64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat64 arg,
) {
	verify(!zero(arg));
	writePushConstant(dbg, writer, source, arg);
	writeFn(dbg, writer, source, FnOp.wrapAddIntegral);
}

void writeMulConstantNat64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat64 arg,
) {
	verify(!zero(arg) && arg != immutable Nat64(1));
	writePushConstant(dbg, writer, source, arg);
	writeFn(dbg, writer, source, FnOp.wrapMulIntegral);
}

// Consume stack space without caring what's in it. Useful for unions.
void writePushEmptySpace(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat16 nSpaces,
) {
	foreach (immutable ushort i; 0 .. nSpaces.raw())
		writePushConstant(dbg, writer, source, immutable Nat8(0));
}

void writePushConstants(size_t n)(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat64[n] values,
) {
	foreach (immutable Nat64 value; values)
		writePushConstant(dbg, writer, source, value);
}

void writePushConstant(T, Debug)(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable NatN!T value,
) {
	static if (is(T == ulong))
		writePushConstant64(dbg, writer, source, value);
	else
		writePushConstant64(dbg, writer, source, value.to64());
}

private void writePushConstant64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat64 value,
) {
	if (value <= Nat8.max.to64()) {
		log(dbg, writer, "write push constant (8bit)", value);
		writePushU8(dbg, writer, source, value.to8());
	} else if (value <= Nat16.max.to64()) {
		log(dbg, writer, "write push constant (16bit)", value);
		writePushU16(dbg, writer, source, value.to16());
	} else if (value <= Nat32.max.to64()) {
		log(dbg, writer, "write push constant (32bit)", value);
		writePushU32(dbg, writer, source, value.to32());
	} else if (value <= Nat48.max.to64()) {
		log(dbg, writer, "write push constant (48bit)", value);
		writePushU48(dbg, writer, source, value.to48());
	} else {
		log(dbg, writer, "write push constant (64bit)", value);
		writePushU64(dbg, writer, source, value);
	}
}

void writePushConstantPointer(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ubyte* value,
) {
	writePushConstant(dbg, writer, source, immutable Nat64(cast(ulong) value));
}

private void writePushU8(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat8 value,
) {
	writePushU64(dbg, writer, source, value.to64());
}

private void writePushU16(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat16 value,
) {
	writePushU64(dbg, writer, source, value.to64());
}

private void writePushU32(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat32 value,
) {
	writePushU64(dbg, writer, source, value.to64());
}

private void writePushU48(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat48 value,
) {
	writePushU64(dbg, writer, source, value.to64());
}

private void writePushU64(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat64 value,
) {
	log(dbg, writer, "write push U64");
	pushOperation(writer, source, &opPushValue64);
	pushU64(writer, source, value);
	writer.nextStackEntry++;
}

void writeReturn(scope ref Debug dbg, ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	log(dbg, writer, "write return");
	pushOperation(writer, source, &opReturn);
}

immutable(ByteCodeIndex) writePushFunPtrDelayed(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
) {
	log(dbg, writer, "write push u32 common");
	pushOperation(writer, source, &opPushValue32);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, immutable Nat32(0));
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
	if (!zero(entries.size)) {
		pushOperation(writer, source, &opRemove);
		pushU8(writer, source, getStackOffsetTo(writer, entries.start));
		pushU8(writer, source, entries.size);
		writer.nextStackEntry -= entries.size.to16();
	}
}

void writeJump(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable ByteCodeIndex target,
) {
	log(dbg, writer, "write jump");
	pushOperation(writer, source, &opJump);
	// We take the jump after having read the jump value
	static assert(ByteCodeIndex.sizeof <= Operation.sizeof);
	pushInt16(writer, source, subtractByteCodeIndex(
		target,
		immutable ByteCodeIndex(nextByteCodeIndex(writer).index + immutable Nat32(1))).offset);
}

immutable(ByteCodeIndex) writeJumpDelayed(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
) {
	log(dbg, writer, "write jump delayed");
	pushOperation(writer, source, &opJump);
	immutable ByteCodeIndex jumpOffsetIndex = nextByteCodeIndex(writer);
	static assert(ByteCodeOffset.sizeof == Int16.sizeof);
	pushInt16(writer, source, immutable Int16(0));
	return jumpOffsetIndex;
}

@trusted void fillInJumpDelayed(ref ByteCodeWriter writer, immutable ByteCodeIndex jumpIndex) {
	immutable ByteCodeOffset offset = getByteCodeOffsetForJumpToCurrent(writer, jumpIndex);
	setAt(writer.operations, jumpIndex.index.raw(), cast(Operation) offset.offset.raw());
}

private immutable(ByteCodeOffset) getByteCodeOffsetForJumpToCurrent(
	ref const ByteCodeWriter writer,
	immutable ByteCodeIndex jumpIndex,
) {
	verify(jumpIndex.index < nextByteCodeIndex(writer).index);
	static assert(ByteCodeIndex.sizeof <= Operation.sizeof);
	// We add the jump offset after having read the jump value
	immutable ByteCodeIndex jumpEnd = addByteCodeIndex(jumpIndex, immutable Nat32(1));
	return subtractByteCodeIndex(nextByteCodeIndex(writer), jumpEnd);
}

void writePack(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope immutable Pack pack,
) {
	pushOperation(writer, source, &opPack);
	pushU8(writer, source, pack.inEntries);
	pushU8(writer, source, pack.outEntries);
	writeArray(writer, source, pack.fields);
	writer.nextStackEntry -= pack.inEntries.to16();
	writer.nextStackEntry += pack.outEntries.to16();
}

struct JumpIfFalseDelayed {
	immutable ByteCodeIndex offsetIndex;
}

immutable(JumpIfFalseDelayed) writeJumpIfFalseDelayed(ref ByteCodeWriter writer, immutable ByteCodeSource source) {
	pushOperation(writer, source, &opJumpIfFalse);
	immutable ByteCodeIndex offsetIndex = nextByteCodeIndex(writer);
	pushU16(writer, source, (immutable ByteCodeOffsetUnsigned(immutable Nat16(0))).offset);
	writer.nextStackEntry -= 1;
	return immutable JumpIfFalseDelayed(offsetIndex);
}

@trusted void fillDelayedJumpIfFalse(ref ByteCodeWriter writer, immutable JumpIfFalseDelayed delayed) {
	immutable ByteCodeOffsetUnsigned diff =
		subtractByteCodeIndex(
			nextByteCodeIndex(writer),
			// + 1 because jump is relative to after reading the offset
			addByteCodeIndex(delayed.offsetIndex, immutable Nat32(1)),
		).unsigned();
	static assert(ByteCodeOffsetUnsigned.sizeof <= Operation.sizeof);
	setAt(writer.operations, delayed.offsetIndex.index.raw(), cast(immutable Operation) diff.offset.raw());
}

struct SwitchDelayed {
	immutable ByteCodeIndex firstCase;
	immutable ByteCodeIndex afterCases;
}

immutable(SwitchDelayed) writeSwitch0ToNDelay(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Nat16 nCases,
) {
	pushOperation(writer, source, &opSwitch0ToN);
	// + 1 because the array size takes up one entry
	immutable ByteCodeIndex addresses = addByteCodeIndex(nextByteCodeIndex(writer), immutable Nat32(1));
	verify(nCases.raw() < emptyCases.length);
	writeArray!ByteCodeOffsetUnsigned(writer, source, emptyCases[0 .. nCases.raw()]);
	writer.nextStackEntry -= 1;
	return immutable SwitchDelayed(addresses, nextByteCodeIndex(writer));
}

private immutable ByteCodeOffsetUnsigned[64] emptyCases;

@trusted void fillDelayedSwitchEntry(
	ref ByteCodeWriter writer,
	immutable SwitchDelayed delayed,
	immutable Nat32 switchEntry,
) {
	ByteCodeOffsetUnsigned* start =
		cast(ByteCodeOffsetUnsigned*) mutArrPtrAt(writer.operations, delayed.firstCase.index.raw());
	immutable ByteCodeOffsetUnsigned diff =
		subtractByteCodeIndex(nextByteCodeIndex(writer), delayed.afterCases).unsigned();
	overwriteMemory(start + switchEntry.raw(), diff);
}

immutable(SwitchDelayed) writeSwitchWithValuesDelay(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource,
	immutable EnumValue[],
) {
	return todo!(immutable SwitchDelayed)("!");
	/*
	pushOperation(writer, source, &opSwitchWithValues);
	pushU16(writer, source, sizeNat(values).to16());
	foreach (immutable EnumValue value; values)
		pushU64(writer, source, value.asUnsigned());
	writer.nextStackEntry -= 1;
	immutable ByteCodeIndex addresses = nextByteCodeIndex(writer);
	foreach (immutable size_t; 0 .. size(values)) {
		static assert(ByteCodeOffset.sizeof == Nat16.sizeof);
		pushU16(writer, source, immutable Nat16(0));
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
	pushOperation(writer, source, &opExtern);
	pushU8(writer, source, immutable Nat8(op));
	writer.nextStackEntry += stackEffect;
}

private @trusted void writeArray(T)(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope immutable T[] values,
) {
	pushU32(writer, source, sizeNat(values).to32());
	if (!empty(values)) {
		immutable size_t nOperations = divRoundUp(values.length * T.sizeof, Operation.sizeof);
		foreach (immutable size_t i; 0 .. nOperations)
			pushOperation(writer, source, null);
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
	pushOperation(writer, source, &opExternDynCall);
	pushU64(writer, source, immutable Nat64(name.value));
	pushU8(writer, source, immutable Nat8(returnType));
	writeArray!DynCallType(writer, source, parameterTypes);
	writer.nextStackEntry -= sizeNat(parameterTypes).to16();
	writer.nextStackEntry += returnType == DynCallType.void_ ? immutable Nat16(0) : immutable Nat16(1);
}

void writeFn(
	scope ref Debug dbg,
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable FnOp fn,
) {
	immutable int stackEffect = () {
		final switch (fn) {
			case FnOp.addFloat32:
			case FnOp.addFloat64:
			case FnOp.bitwiseAnd:
			case FnOp.bitwiseOr:
			case FnOp.bitwiseXor:
			case FnOp.eqBits:
			case FnOp.eqFloat64:
			case FnOp.lessFloat32:
			case FnOp.lessFloat64:
			case FnOp.lessInt8:
			case FnOp.lessInt16:
			case FnOp.lessInt32:
			case FnOp.lessInt64:
			case FnOp.lessNat:
			case FnOp.mulFloat64:
			case FnOp.subFloat64:
			case FnOp.unsafeBitShiftLeftNat64:
			case FnOp.unsafeBitShiftRightNat64:
			case FnOp.unsafeDivFloat32:
			case FnOp.unsafeDivFloat64:
			case FnOp.unsafeDivInt64:
			case FnOp.unsafeDivNat64:
			case FnOp.unsafeModNat64:
			case FnOp.wrapAddIntegral:
			case FnOp.wrapMulIntegral:
			case FnOp.wrapSubIntegral:
				return -1;
			case FnOp.bitwiseNot:
			case FnOp.countOnesNat64:
			case FnOp.float64FromFloat32:
			case FnOp.float64FromInt64:
			case FnOp.float64FromNat64:
			case FnOp.intFromInt16:
			case FnOp.intFromInt32:
			case FnOp.isNanFloat32:
			case FnOp.isNanFloat64:
			case FnOp.truncateToInt64FromFloat64:
				return 0;
		}
	}();
	pushOperation(writer, source, &opFn);
	pushU8(writer, source, immutable Nat8(fn));
	writer.nextStackEntry += stackEffect;
}

private void pushOperation(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	Operation value,
) {
	push(writer.alloc.deref(), writer.operations, value);
	add(writer.alloc.deref(), writer.sources, source);
}

private @trusted void pushT(T)(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable T value) {
	static if(T.sizeof <= Operation.sizeof) {
		pushOperation(writer, source, cast(Operation) value.raw());
	} else {
		static assert(T.sizeof == 8 && Operation.sizeof == 4);
		pushOperation(writer, source, cast(immutable Operation) 0);
		pushOperation(writer, source, cast(immutable Operation) 0);
		T* ptr = cast(T*) mutArrPtrAt(writer.operations, mutArrSize(writer.operations) - 2);
		overwriteMemory(ptr, value);
	}
}

private void pushU64(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Nat64 value) {
	pushT(writer, source, value);
}

private void pushInt16(
	ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	immutable Int16 value,
) {
	pushT(writer, source, value);
}

private void pushU8(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Nat8 value) {
	pushT(writer, source, value);
}

private void pushU16(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Nat16 value) {
	pushT(writer, source, value);
}

private void pushU32(ref ByteCodeWriter writer, immutable ByteCodeSource source, immutable Nat32 value) {
	pushT(writer, source, value);
}

void log(scope ref Debug dbg, ref ByteCodeWriter byteCodeWriter, immutable string message) {
	log(dbg, byteCodeWriter, message, none!Nat64);
}

void log(
	scope ref Debug dbg,
	ref ByteCodeWriter byteCodeWriter,
	immutable string message,
	immutable Nat64 value,
) {
	log(dbg, byteCodeWriter, message, some!Nat64(value));
}

void log(
	scope ref Debug dbg,
	ref ByteCodeWriter byteCodeWriter,
	immutable string message,
	immutable Opt!Nat64 value,
) {
	if (dbg.enabled()) {
		Writer writer = Writer(byteCodeWriter.alloc);
		writeStatic(writer, message);
		if (has(value)) {
			writeStatic(writer, " = ");
			writeNat(writer, force(value));
		}
		writeStatic(writer, " at bytecode offset ");
		writeNat(writer, nextByteCodeIndex(byteCodeWriter).index.raw());
		dbgLog(dbg, finishWriter(writer));
	}
}
