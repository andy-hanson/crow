module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.bytecode :
	addByteCodeIndex,
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	FileToFuns,
	FnOp,
	stackEntrySize,
	StackOffset,
	subtractByteCodeIndex;
import util.collection.byteWriter :
	ByteWriter,
	finishByteWriter,
	newByteWriter,
	nextByteIndex,
	bytePushU8 = pushU8,
	bytePushU16 = pushU16,
	bytePushU32 = pushU32,
	bytePushU64 = pushU64,
	writeU16,
	writeU32,
	writeU64;
import interpret.opcode : OpCode;
import util.collection.arr : Arr, begin, empty, range, size, sizeEq;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictOfArr;
import util.collection.mutArr : moveToArr, MutArr, mutArrRange, mutArrSize, push, pushAll, setAt;
import util.collection.str : Str;
import util.ptr : Ptr;
import util.sourceRange : FileAndPos, FileAndRange;
import util.util : divRoundUp, repeat, unreachable, verify;
import util.types : catU4U4, u8, u16, u32, u64, maxU32, safeSizeTToU8, safeSizeTToU32, safeU32ToU8, safeU32ToU16;

struct ByteCodeWriter(Alloc) {
	private:
	Ptr!Alloc alloc;
	ByteWriter!Alloc byteWriter;
	ArrBuilder!FileAndPos sources;
	MutArr!(immutable char) text;
	MutArr!(immutable ByteCodeIndexAndTextIndex) delayedTextPtrs;
	uint nextStackEntry = 0;
}

ByteCodeWriter!Alloc newByteCodeWriter(Alloc)(Ptr!Alloc alloc) {
	return ByteCodeWriter!Alloc(alloc, newByteWriter!Alloc(alloc));
}

private struct ByteCodeIndexAndTextIndex {
	immutable ByteCodeIndex byteCodeIndex;
	immutable uint textIndex;
}

struct StackEntry {
	immutable uint entry;
}

struct StackEntries {
	immutable StackEntry start; // Index of first entry
	immutable u8 size; // Number of entries
}

@trusted immutable(ByteCode) finishByteCode(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex mainIndex,
	immutable FileToFuns fileToFuns,
) {
	immutable Arr!char text = moveToArr(writer.alloc, writer.text);
	foreach (immutable ByteCodeIndexAndTextIndex indices; mutArrRange(writer.delayedTextPtrs))
		writeU64(writer.byteWriter, indices.byteCodeIndex.index, cast(u64) begin(text) + indices.textIndex);
	immutable Arr!u8 bytes = finishByteWriter(writer.byteWriter);
	immutable FullIndexDict!(ByteCodeIndex, FileAndPos) sources =
		fullIndexDictOfArr!(ByteCodeIndex, FileAndPos)(finishArr(writer.alloc, writer.sources));
	return immutable ByteCode(bytes, sources, fileToFuns, text, mainIndex);
}

immutable(StackEntry) getNextStackEntry(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return immutable StackEntry(writer.nextStackEntry);
}

void setNextStackEntry(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntry entry) {
	writer.nextStackEntry = entry.entry;
}

void setStackEntryAfterParameters(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntry entry) {
	verify(writer.nextStackEntry == 0);
	writer.nextStackEntry = entry.entry;
}

void assertStackEmpty(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	verify(writer.nextStackEntry == 0);
}

immutable(ByteCodeIndex) nextByteCodeIndex(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return immutable ByteCodeIndex(safeSizeTToU32(nextByteIndex(writer.byteWriter)));
}

private void fillDelayedU16(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeOffset offset,
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

void writeAssertStackSize(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
	pushOpcode(writer, source, OpCode.assertStackSize);
	pushU16(writer, source, safeU32ToU16(writer.nextStackEntry));
}

immutable(ByteCodeIndex) writeCallDelayed(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntry stackEntryBeforeArgs,
	immutable uint nEntriesForReturnType,
) {
	pushOpcode(writer, source, OpCode.call);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, 0);
	pushU8(writer, source, safeU32ToU8(writer.nextStackEntry - stackEntryBeforeArgs.entry));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType;
	return fnAddress;
}

void fillDelayedCall(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	fillDelayedU32(writer, index, value);
}

void writeCallFunPtr(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	// This is before the fun-ptr arg, which should be the first
	immutable StackEntry stackEntryBeforeArgs,
	immutable uint nEntriesForReturnType,
) {
	pushOpcode(writer, source, OpCode.callFunPtr);
	pushU8(writer, source, getStackOffsetTo(writer, stackEntryBeforeArgs));
	writer.nextStackEntry = stackEntryBeforeArgs.entry + nEntriesForReturnType;
}

immutable(u8) getStackOffsetTo(Alloc)(ref const ByteCodeWriter!Alloc writer, immutable StackEntry stackEntry) {
	verify(stackEntry.entry < getNextStackEntry(writer).entry);
	return safeU32ToU8(getNextStackEntry(writer).entry - 1 - stackEntry.entry);
}

// WARN: 'get' operation does not delete the thing that was got from (unlike 'read')
void writeDupEntries(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntries entries,
) {
	foreach (immutable uint i; 0..entries.size)
		writeDupEntry(writer, source, immutable StackEntry(entries.start.entry + i));
}

void writeDupEntry(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntry entry,
) {
	pushOpcode(writer, source, OpCode.dup);
	pushU8(writer, source, getStackOffsetTo(writer, entry));
	writer.nextStackEntry++;
}

void writeDupPartial(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntry stackEntry,
	immutable u8 byteOffset,
	immutable u8 sizeBytes,
) {
	pushOpcode(writer, source, OpCode.dupPartial);
	pushU8(writer, source, getStackOffsetTo(writer, stackEntry));
	pushU8(writer, source, catU4U4(byteOffset, sizeBytes));
	writer.nextStackEntry += 1;
}

void writeRead(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u8 offset,
	immutable u8 size,
) {
	pushOpcode(writer, source, OpCode.read);
	pushU8(writer, source, offset);
	pushU8(writer, source, size);
	writer.nextStackEntry += divRoundUp(size, stackEntrySize) - 1;
}

void writeStackRef(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntry stackEntry,
	immutable u8 byteOffset = 0,
) {
	pushOpcode(writer, source, OpCode.stackRef);
	immutable StackOffset offset = immutable StackOffset(getStackOffsetTo(writer, stackEntry));
	pushU8(writer, source, offset.offset);
	writer.nextStackEntry += 1;

	if (byteOffset != 0) {
		writeAddConstantNat64(writer, source, byteOffset);
	}
}

void writeWrite(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u8 offset,
	immutable u8 size,
) {
	pushOpcode(writer, source, OpCode.write);
	pushU8(writer, source, offset);
	pushU8(writer, source, size);
	writer.nextStackEntry -= 1 + divRoundUp(size, stackEntrySize);
}

void writeAddConstantNat64(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u64 arg,
) {
	verify(arg != 0);
	writePushConstant(writer, source, arg);
	writeFn(writer, source, FnOp.wrapAddIntegral);
}

// Consume stack space without caring what's in it. Useful for unions.
void writePushEmptySpace(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable size_t nSpaces,
) {
	foreach (immutable size_t i; 0..nSpaces)
		writePushConstant(writer, source, 0);
}

void writePushConstants(Alloc, size_t n)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable size_t[n] values,
) {
	foreach (immutable size_t value; values)
		writePushConstant(writer, source, value);
}

void writePushConstant(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable size_t value,
) {
	if (value <= maxU32)
		writePushU32(writer, source, safeSizeTToU32(value));
	else
		writePushU64(writer, source, value);
}

void writePushConstantStr(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable Str value,
) {
	writePushU32(writer, source, safeSizeTToU32(size(value)));
	immutable ByteCodeIndex delayed = writePushU64Delayed(writer, source);
	immutable u32 textIndex = safeSizeTToU32(mutArrSize(writer.text));
	pushAll(writer.alloc, writer.text, value);
	//TODO: could use temp alloc
	push(writer.alloc, writer.delayedTextPtrs, immutable ByteCodeIndexAndTextIndex(delayed, textIndex));
}

private void writePushU32(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u32 value,
) {
	writePushU32Common(writer, source, value);
}

private void writePushU64(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u64 value,
) {
	pushOpcode(writer, source, OpCode.pushU64);
	pushU64(writer, source, value);
	writer.nextStackEntry++;
}

void writeReturn(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
	pushOpcode(writer, source, OpCode.return_);
}

immutable(ByteCodeIndex) writePushFunPtrDelayed(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
) {
	return writePushU32Common(writer, source, 0);
}

private immutable(ByteCodeIndex) writePushU32Common(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u32 value,
) {
	pushOpcode(writer, source, OpCode.pushU32);
	immutable ByteCodeIndex fnAddress = nextByteCodeIndex(writer);
	pushU32(writer, source, value);
	writer.nextStackEntry++;
	return fnAddress;
}

immutable(ByteCodeIndex) writePushU64Delayed(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
) {
	return writePushU64Common(writer, source, 0);
}

private immutable(ByteCodeIndex) writePushU64Common(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable u32 value,
) {
	pushOpcode(writer, source, OpCode.pushU64);
	immutable ByteCodeIndex address = nextByteCodeIndex(writer);
	pushU64(writer, source, value);
	writer.nextStackEntry++;
	return address;
}

void writeRemove(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable StackEntries entries,
) {
	if (entries.size != 0) {
		pushOpcode(writer, source, OpCode.remove);
		pushU8(writer, source, getStackOffsetTo(writer, entries.start));
		pushU8(writer, source, entries.size);
		writer.nextStackEntry -= entries.size;
	}
}

immutable(ByteCodeIndex) writeJumpDelayed(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
	pushOpcode(writer, source, OpCode.jump);
	immutable ByteCodeIndex jumpOffsetIndex = nextByteCodeIndex(writer);
	pushU16(writer, source, 0);
	return jumpOffsetIndex;
}

void fillInJumpDelayed(Alloc)(ref ByteCodeWriter!Alloc writer, immutable ByteCodeIndex jumpIndex) {
	writeU16(writer.byteWriter, jumpIndex.index, getByteCodeOffsetForJump(writer, jumpIndex).offset);
}

private immutable(ByteCodeOffset) getByteCodeOffsetForJump(Alloc)(
	ref const ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex jumpIndex,
) {
	verify(jumpIndex.index < nextByteCodeIndex(writer).index);
	// We add the jump offset after having read the jump value
	immutable ByteCodeIndex jumpEnd = addByteCodeIndex(jumpIndex, ByteCodeOffset.sizeof);
	return subtractByteCodeIndex(nextByteCodeIndex(writer), jumpEnd);
}

void writePack(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable Arr!u8 sizes) {
	verify(!empty(sizes));
	pushOpcode(writer, source, OpCode.pack);
	pushU8(writer, source, safeSizeTToU8(size(sizes)));
	foreach (immutable u8 size; range(sizes))
		pushU8(writer, source, size);
	writer.nextStackEntry -= (size(sizes) - 1);
}

immutable(ByteCodeIndex) writeSwitchDelay(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable size_t nCases,
) {
	pushOpcode(writer, source, OpCode.switch_);
	writer.nextStackEntry -= 1;
	immutable ByteCodeIndex addresses = nextByteCodeIndex(writer);
	foreach (immutable size_t i; 0..nCases) {
		static assert(ByteCodeOffset.sizeof == 2);
		pushU16(writer, source, 0);
	}
	return addresses;
}

void fillDelayedSwitchEntry(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex switchCasesIndex,
	immutable u8 switchEntry,
) {
	immutable ByteCodeIndex case_ = addByteCodeIndex(switchCasesIndex, switchEntry * ByteCodeOffset.sizeof);
	immutable ByteCodeIndex caseEnd = addByteCodeIndex(case_, ByteCodeOffset.sizeof);
	fillDelayedU16(
		writer,
		case_,
		subtractByteCodeIndex(nextByteCodeIndex(writer), caseEnd));
}

void writeFn(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable FnOp fn) {
	immutable int stackEffect = () {
		final switch (fn) {
			case FnOp.compareExchangeStrongBool:
				return -2;
			case FnOp.addFloat64:
			case FnOp.bitwiseAnd:
			case FnOp.bitwiseOr:
			case FnOp.eqBits:
			case FnOp.free:
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
			case FnOp.unsafeDivFloat64:
			case FnOp.unsafeDivInt64:
			case FnOp.unsafeDivNat64:
			case FnOp.unsafeModNat64:
			case FnOp.wrapAddIntegral:
			case FnOp.wrapMulIntegral:
			case FnOp.wrapSubIntegral:
				return -1;
			case FnOp.float64FromInt64:
			case FnOp.float64FromNat64:
			case FnOp.intFromInt16:
			case FnOp.intFromInt32:
			case FnOp.malloc:
			case FnOp.not:
			case FnOp.truncateToInt64FromFloat64:
				return 0;
			case FnOp.hardFail:
				return unreachable!int(); // Use writeFnHardFail instead
		}
	}();
	writeFnCommon(writer, source, fn, stackEffect);
}

void writeFnHardFail(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable uint stackEntriesForReturnType,
) {
	writeFnCommon(writer, source, FnOp.hardFail, (cast(int) stackEntriesForReturnType) - 2);
}

private:

void writeFnCommon(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	ref immutable FileAndRange source,
	immutable FnOp fnOp,
	immutable int stackEffect,
) {
	pushOpcode(writer, source, OpCode.fn);
	pushU8(writer, source, fnOp);
	writer.nextStackEntry += stackEffect;
}

void pushOpcode(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable OpCode code) {
	pushU8(writer, source, code);
}

void pushU8(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable u8 value) {
	bytePushU8(writer.byteWriter, value);
	pushSource(writer, source);
}

void pushU16(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable u16 value) {
	bytePushU16(writer.byteWriter, value);
	repeat(u16.sizeof, () { pushSource(writer, source); });
}

void pushU32(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable u32 value) {
	bytePushU32(writer.byteWriter, value);
	repeat(u32.sizeof, () { pushSource(writer, source); });
}

void pushU64(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source, immutable u64 value) {
	bytePushU64(writer.byteWriter, value);
	repeat(u64.sizeof, () { pushSource(writer, source); });
}

void pushSource(Alloc)(ref ByteCodeWriter!Alloc writer, ref immutable FileAndRange source) {
	add(writer.alloc, writer.sources, immutable FileAndPos(source.fileIndex, source.range.start));
}
