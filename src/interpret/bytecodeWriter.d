module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.bytecode :
	addByteCodeIndex,
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	DynCallType,
	ExternOp,
	FileToFuns,
	FnOp,
	Operation,
	stackEntrySize,
	StackOffset,
	StackOffsetBytes,
	subtractByteCodeIndex;
import util.collection.byteWriter :
	ByteWriter,
	finishByteWriter,
	newByteWriter,
	nextByteIndex,
	pushBytes,
	bytePushInt16 = pushInt16,
	bytePushU8 = pushU8,
	bytePushU16 = pushU16,
	bytePushU32 = pushU32,
	bytePushU64 = pushU64,
	writeInt16,
	writeU16,
	writeU32;
import interpret.opcode : OpCode;
import util.collection.arr : sizeNat;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictOfArr;
import util.dbg : dbgLog = log;
import util.ptr : Ptr;
import util.sym : Sym;
import util.util : divRoundUp, repeat, verify;
import util.types : decr, incr, Int16, Nat8, Nat16, Nat32, Nat64, zero;
import util.writer : finishWriter, writeChar, writeNat, Writer, writeStatic;

struct ByteCodeWriter(Alloc) {
	private:
	Ptr!Alloc alloc;
	ByteWriter!Alloc byteWriter;
	ArrBuilder!ByteCodeSource sources;
	Nat16 nextStackEntry = immutable Nat16(0);
}

ByteCodeWriter!Alloc newByteCodeWriter(Alloc)(Ptr!Alloc alloc) {
	return ByteCodeWriter!Alloc(alloc, newByteWriter!Alloc(alloc));
}

struct StackEntry {
	immutable Nat16 entry;
}

struct StackEntries {
	immutable StackEntry start; // Index of first entry
	immutable Nat8 size; // Number of entries
}

@trusted immutable(ByteCode) finishByteCode(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ubyte[] text,
	immutable ByteCodeIndex mainIndex,
	immutable FileToFuns fileToFuns,
) {
	immutable ubyte[] bytes = finishByteWriter(writer.byteWriter);
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources =
		fullIndexDictOfArr!(ByteCodeIndex, ByteCodeSource)(finishArr(writer.alloc.deref(), writer.sources));
	return immutable ByteCode(bytes, sources, fileToFuns, text, mainIndex);
}

immutable(StackEntry) getNextStackEntry(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return immutable StackEntry(writer.nextStackEntry);
}

void setNextStackEntry(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntry entry) {
	writer.nextStackEntry = entry.entry;
}

void setStackEntryAfterParameters(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntry entry) {
	verify(zero(writer.nextStackEntry));
	writer.nextStackEntry = entry.entry;
}

immutable(ByteCodeIndex) nextByteCodeIndex(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return immutable ByteCodeIndex((immutable Nat64(nextByteIndex(writer.byteWriter))).to32());
}

private void fillDelayedU16(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeOffsetUnsigned offset,
) {
	writeU16(writer.byteWriter, index.index, offset.offset);
}

private void fillDelayedU32(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	writeU32(writer.byteWriter, index.index, value.index);
}

void writeAssertStackSize(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
) {
	log(dbg, writer, "write assert stack size");
	pushOpcode(writer, source, OpCode.assertStackSize);
	pushU16(writer, source, writer.nextStackEntry);
}

void writeAssertUnreachable(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
	pushOpcode(writer, source, OpCode.assertUnreachable);
}

immutable(ByteCodeIndex) writeCallDelayed(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntry stackEntryBeforeArgs,
	immutable Nat8 nEntriesForReturnType,
) {
	pushOpcode(writer, source, OpCode.call);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, immutable Nat32(0));
	pushU8(writer, source, (writer.nextStackEntry - stackEntryBeforeArgs.entry).to8());
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType.to16();
	return fnAddress;
}

void fillDelayedCall(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	fillDelayedU32(writer, index, value);
}

void writeCallFunPtr(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	// This is before the fun-ptr arg, which should be the first
	immutable StackEntry stackEntryBeforeArgs,
	immutable Nat8 nEntriesForReturnType,
) {
	log(dbg, writer, "write call fun-ptr");
	pushOpcode(writer, source, OpCode.callFunPtr);
	pushU8(writer, source, getStackOffsetTo(writer, stackEntryBeforeArgs));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType.to16();
}

private immutable(Nat8) getStackOffsetTo(Alloc)(
	ref const ByteCodeWriter!Alloc writer,
	immutable StackEntry stackEntry,
) {
	verify(stackEntry.entry < getNextStackEntry(writer).entry);
	return (decr(getNextStackEntry(writer).entry) - stackEntry.entry).to8();
}

private immutable(StackOffsetBytes) getStackOffsetBytes(Alloc)(
	ref const ByteCodeWriter!Alloc writer,
	immutable StackEntry stackEntry,
	immutable Nat8 offsetBytes,
) {
	// stack entry offsets use 0 for the last entry,
	// but byte offsets use 0 for the next entry (thus 1 is the final byte of the last entry)
	return immutable StackOffsetBytes(
		incr(getStackOffsetTo(writer, stackEntry)).to16() * immutable Nat16(8) - offsetBytes.to16());
}

void writeDupEntries(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	verify(!zero(entries.size));
	verify(entries.start.entry + entries.size.to16() <= getNextStackEntry(writer).entry);
	writeDup(dbg, writer, source, entries.start, immutable Nat8(0), entries.size.to16() * immutable Nat16(8));
}

void writeDupEntry(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntry entry,
) {
	writeDup(dbg, writer, source, entry, immutable Nat8(0), immutable Nat16(8));
}

void writeDup(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntry start,
	immutable Nat8 offsetBytes,
	immutable Nat16 sizeBytes,
) {
	verify(!zero(sizeBytes));

	pushOpcode(writer, source, OpCode.dup);
	pushU16(writer, source, getStackOffsetBytes(writer, start, offsetBytes).offsetBytes);
	pushU16(writer, source, sizeBytes);

	writer.nextStackEntry += divRoundUp(sizeBytes, immutable Nat16(8));
}

void writeRead(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	log(dbg, writer, "write read");
	verify(!zero(size));
	pushOpcode(writer, source, OpCode.read);
	pushU16(writer, source, offset);
	pushU16(writer, source, size);
	writer.nextStackEntry += decr(divRoundUp(size, stackEntrySize));
}

void writeStackRef(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntry stackEntry,
	immutable Nat8 byteOffset = immutable Nat8(0),
) {
	log(dbg, writer, "write stack ref");
	pushOpcode(writer, source, OpCode.stackRef);
	immutable StackOffset offset = immutable StackOffset(getStackOffsetTo(writer, stackEntry));
	pushU8(writer, source, offset.offset);
	writer.nextStackEntry += 1;

	if (!zero(byteOffset)) {
		writeAddConstantNat64(dbg, writer, source, byteOffset.to64());
	}
}

void writeWrite(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	log(dbg, writer, "write write");
	verify(!zero(size));
	pushOpcode(writer, source, OpCode.write);
	pushU16(writer, source, offset);
	pushU16(writer, source, size);
	writer.nextStackEntry -= incr(divRoundUp(size, stackEntrySize));
}

void writeAddConstantNat64(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat64 arg,
) {
	verify(!zero(arg));
	writePushConstant(dbg, writer, source, arg);
	writeFn(dbg, writer, source, FnOp.wrapAddIntegral);
}

void writeMulConstantNat64(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat64 arg,
) {
	verify(!zero(arg) && arg != immutable Nat64(1));
	writePushConstant(dbg, writer, source, arg);
	writeFn(dbg, writer, source, FnOp.wrapMulIntegral);
}

// Consume stack space without caring what's in it. Useful for unions.
void writePushEmptySpace(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat16 nSpaces,
) {
	foreach (immutable ushort i; 0 .. nSpaces.raw())
		writePushConstant(dbg, writer, source, immutable Nat8(0));
}

void writePushConstants(Debug, Alloc, size_t n)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat64[n] values,
) {
	foreach (immutable Nat64 value; values)
		writePushConstant(dbg, writer, source, value);
}

void writePushConstant(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat8 value,
) {
	writePushConstant(dbg, writer, source, value.to32());
}

void writePushConstant(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat16 value,
) {
	writePushConstant(dbg, writer, source, value.to32());
}

void writePushConstant(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat32 value,
) {
	log(dbg, writer, "write push constant (32)");
	writePushU32(dbg, writer, source, value);
}

void writePushConstant(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat64 value,
) {
	log(dbg, writer, "write push constant (64)");
	//TODO: optimize if the value is small
	//if (value <= Nat32.max.to64())
	//	writePushConstant(writer, source, value.to32());
	//else
	writePushU64(dbg, writer, source, value);
}

void writePushConstantPointer(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable ubyte* value,
) {
	writePushConstant(dbg, writer, source, immutable Nat64(cast(ulong) value));
}

private void writePushU32(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat32 value,
) {
	writePushU32Common(dbg, writer, source, value);
}

private void writePushU64(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat64 value,
) {
	log(dbg, writer, "write push U64");
	pushOpcode(writer, source, OpCode.pushU64);
	pushU64(writer, source, value);
	writer.nextStackEntry++;
}

void writeReturn(Debug, Alloc)(ref Debug dbg, ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
	log(dbg, writer, "write return");
	pushOpcode(writer, source, OpCode.return_);
}

immutable(ByteCodeIndex) writePushFunPtrDelayed(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
) {
	return writePushU32Common(dbg, writer, source, immutable Nat32(0));
}

private immutable(ByteCodeIndex) writePushU32Common(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat32 value,
) {
	log(dbg, writer, "write push u32 common");
	pushOpcode(writer, source, OpCode.pushU32);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, value);
	writer.nextStackEntry++;
	return fnAddress;
}

void writeRemove(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable StackEntries entries,
) {
	log(dbg, writer, "write remove");
	if (!zero(entries.size)) {
		pushOpcode(writer, source, OpCode.remove);
		pushU8(writer, source, getStackOffsetTo(writer, entries.start));
		pushU8(writer, source, entries.size);
		writer.nextStackEntry -= entries.size.to16();
	}
}

void writeJump(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable ByteCodeIndex target,
) {
	log(dbg, writer, "write jump");
	pushOpcode(writer, source, OpCode.jump);
	// We take the jump after having read the jump value
	pushInt16(writer, source, subtractByteCodeIndex(
		target,
		immutable ByteCodeIndex(nextByteCodeIndex(writer).index + immutable Nat32(Int16.sizeof))).offset);
}

immutable(ByteCodeIndex) writeJumpDelayed(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
) {
	log(dbg, writer, "write jump delayed");
	pushOpcode(writer, source, OpCode.jump);
	immutable ByteCodeIndex jumpOffsetIndex = nextByteCodeIndex(writer);
	pushInt16(writer, source, immutable Int16(0));
	return jumpOffsetIndex;
}

void fillInJumpDelayed(Alloc)(ref ByteCodeWriter!Alloc writer, immutable ByteCodeIndex jumpIndex) {
	writeInt16(writer.byteWriter, jumpIndex.index, getByteCodeOffsetForJumpToCurrent(writer, jumpIndex).offset);
}

private immutable(ByteCodeOffset) getByteCodeOffsetForJumpToCurrent(Alloc)(
	ref const ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex jumpIndex,
) {
	verify(jumpIndex.index < nextByteCodeIndex(writer).index);
	// We add the jump offset after having read the jump value
	immutable ByteCodeIndex jumpEnd = addByteCodeIndex(jumpIndex, immutable Nat32(ByteCodeOffset.sizeof));
	return subtractByteCodeIndex(nextByteCodeIndex(writer), jumpEnd);
}

void writePack(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	scope immutable Operation.Pack pack,
) {
	pushOpcode(writer, source, OpCode.pack);
	pushU8(writer, source, pack.inEntries);
	pushU8(writer, source, pack.outEntries);
	pushU8(writer, source, sizeNat(pack.fields).to8());
	foreach (immutable Operation.Pack.Field field; pack.fields)
		pushT!(Operation.Pack.Field)(writer, source, field);
	writer.nextStackEntry -= pack.inEntries.to16();
	writer.nextStackEntry += pack.outEntries.to16();
}

immutable(ByteCodeIndex) writeSwitchDelay(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Nat32 nCases,
) {
	pushOpcode(writer, source, OpCode.switch_);
	pushU32(writer, source, nCases);
	writer.nextStackEntry -= 1;
	immutable ByteCodeIndex addresses = nextByteCodeIndex(writer);
	foreach (immutable uint i; 0 .. nCases.raw()) {
		static assert(ByteCodeOffset.sizeof == Nat16.sizeof);
		pushU16(writer, source, immutable Nat16(0));
	}
	return addresses;
}

void fillDelayedSwitchEntry(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex switchCasesIndex,
	immutable Nat32 switchEntry,
) {
	immutable ByteCodeIndex case_ =
		addByteCodeIndex(switchCasesIndex, switchEntry * immutable Nat32(ByteCodeOffset.sizeof));
	immutable ByteCodeIndex caseEnd = addByteCodeIndex(case_, immutable Nat32(ByteCodeOffset.sizeof));
	fillDelayedU16(
		writer,
		case_,
		subtractByteCodeIndex(nextByteCodeIndex(writer), caseEnd).unsigned());
}

void writeExtern(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable ExternOp op) {
	immutable int stackEffect = () {
		final switch (op) {
			case ExternOp.memcpy:
			case ExternOp.memmove:
			case ExternOp.memset:
			case ExternOp.pthreadCreate:
				return -3;
			case ExternOp.longjmp:
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
			case ExternOp.pthreadYield:
				return 1;
		}
	}();
	pushOpcode(writer, source, OpCode.extern_);
	pushU8(writer, source, immutable Nat8(op));
	writer.nextStackEntry += stackEffect;
}

void writeExternDynCall(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable Sym name,
	immutable DynCallType returnType,
	immutable DynCallType[] parameterTypes,
) {
	pushOpcode(writer, source, OpCode.externDynCall);
	pushU64(writer, source, immutable Nat64(name.value));
	pushU8(writer, source, immutable Nat8(returnType));
	pushU8(writer, source, sizeNat(parameterTypes).to8());
	foreach (immutable DynCallType t; parameterTypes) {
		verify(t != DynCallType.void_);
		pushU8(writer, source, immutable Nat8(t));
	}

	writer.nextStackEntry -= sizeNat(parameterTypes).to16();
	writer.nextStackEntry += returnType == DynCallType.void_ ? immutable Nat16(0) : immutable Nat16(1);
}

void writeFn(Debug, Alloc)(
	ref Debug dbg,
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable FnOp fn,
) {
	immutable int stackEffect = () {
		final switch (fn) {
			case FnOp.compareExchangeStrongBool:
				return -2;
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
			case FnOp.bitsNotNat64:
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
	pushOpcode(writer, source, OpCode.fn);
	pushU8(writer, source, immutable Nat8(fn));
	writer.nextStackEntry += stackEffect;
}

private void pushOpcode(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable ByteCodeSource source,
	immutable OpCode code,
) {
	pushU8(writer, source, immutable Nat8(code));
}

private void pushT(T, Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable T value) {
	pushBytes!T(writer.byteWriter, value);
	repeat(T.sizeof, () { pushSource(writer, source); });
}

void pushInt16(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable Int16 value) {
	bytePushInt16(writer.byteWriter, value);
	repeat(Int16.sizeof, () { pushSource(writer, source); });
}

void pushU8(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable Nat8 value) {
	bytePushU8(writer.byteWriter, value);
	pushSource(writer, source);
}

void pushU16(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable Nat16 value) {
	bytePushU16(writer.byteWriter, value);
	repeat(ushort.sizeof, () { pushSource(writer, source); });
}

void pushU32(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable Nat32 value) {
	bytePushU32(writer.byteWriter, value);
	repeat(uint.sizeof, () { pushSource(writer, source); });
}

void pushU64(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source, immutable Nat64 value) {
	bytePushU64(writer.byteWriter, value);
	repeat(ulong.sizeof, () { pushSource(writer, source); });
}

private void pushSource(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable ByteCodeSource source) {
	add(writer.alloc.deref(), writer.sources, source);
}

void log(Debug, Alloc)(ref Debug dbg, ref ByteCodeWriter!Alloc byteCodeWriter, immutable string message) {
	if (dbg.enabled()) {
		Writer!Alloc writer = Writer!Alloc(byteCodeWriter.alloc);
		writeStatic(writer, message);
		writeChar(writer, ' ');
		writeNat(writer, nextByteCodeIndex(byteCodeWriter).index.raw());
		dbgLog(dbg, finishWriter(writer));
	}
}
