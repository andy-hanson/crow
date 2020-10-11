module interpret.bytecodeWriter;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCode, ByteCodeIndex, ByteCodeOffset, FnOp, stackEntrySize;
import interpret.opcode : OpCode;
import util.collection.arr : Arr, begin, size;
import util.collection.mutArr : moveToArr, MutArr, mutArrRange, mutArrSize, push, pushAll, setAt;
import util.collection.str : Str;
import util.ptr : Ptr;
import util.types : bottomU8OfU32, bottomU32OfU64, catU4U4, maxU32, safeSizeTToU32, safeU32ToU8, u8, u32, u64;
import util.util : divRoundUp, verify;

struct ByteCodeWriter(Alloc) {
	private:
	Ptr!Alloc alloc;
	MutArr!(immutable OpCode) code;
	MutArr!(immutable char) text;
	MutArr!(immutable ByteCodeIndexAndTextIndex) delayedTextPtrs;
	uint nextStackEntry = 0;
}

private struct ByteCodeIndexAndTextIndex {
	immutable ByteCodeIndex byteCodeIndex;
	immutable uint textIndex;
}

struct StackEntries {
	immutable uint start; // Index of first entry
	immutable u8 size; // Number of entries
}

@trusted immutable(ByteCode) finishByteCode(Alloc)(ref ByteCodeWriter!Alloc writer, immutable ByteCodeIndex mainIndex) {
	immutable Arr!char text = moveToArr(writer.alloc, writer.text);
	foreach (immutable ByteCodeIndexAndTextIndex idxs; mutArrRange(writer.delayedTextPtrs))
		writeU64(writer.code, idxs.byteCodeIndex.index, cast(u64) begin(text) + idxs.textIndex);
	return immutable ByteCode(moveToArr(writer.alloc, writer.code), text, mainIndex);
}

immutable(uint) getNextStackEntry(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return writer.nextStackEntry;
}

void setNextStackEntry(Alloc)(ref ByteCodeWriter!Alloc writer, immutable uint entry) {
	writer.nextStackEntry = entry;
}

void setStackEntryAfterParameters(Alloc)(ref ByteCodeWriter!Alloc writer, immutable uint entry) {
	verify(writer.nextStackEntry == 0);
	writer.nextStackEntry = entry;
}

void assertStackEmpty(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	verify(writer.nextStackEntry == 0);
}

//TODO: name 'nextByteCodeIndex'
immutable(ByteCodeIndex) curByteCodeIndex(Alloc)(ref const ByteCodeWriter!Alloc writer) {
	return immutable ByteCodeIndex(safeSizeTToU32(mutArrSize(writer.code)));
}

void fillDelayedU8(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeOffset offset,
) {
	writeU8(writer.code, index.index, offset.offset);
}

void fillDelayedU32(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable ByteCodeIndex index,
	immutable ByteCodeIndex value,
) {
	writeU32(writer.code, index.index, value.index);
}

immutable(ByteCodeIndex) writeCallDelayed(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable uint stackEntryBeforeArgs,
	immutable uint nEntriesForReturnType,
) {
	pushOpcode(writer, OpCode.call);
	immutable ByteCodeIndex fnAddress = curByteCodeIndex(writer);
	pushU32(writer.alloc, writer.code, 0);
	writer.nextStackEntry = stackEntryBeforeArgs + nEntriesForReturnType;
	return fnAddress;
}

void writeCallFunPtr(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	// This is before the fun-ptr arg, which should be the first
	immutable uint stackEntryBeforeArgs,
	immutable uint nEntriesForReturnType,
) {
	pushOpcode(writer, OpCode.callFunPtr);
	pushU8(writer.alloc, writer.code, safeU32ToU8(stackEntryBeforeArgs - 1 - getNextStackEntry(writer)));
	writer.nextStackEntry = stackEntryBeforeArgs + nEntriesForReturnType;
}

// WARN: 'get' operation does not delete the thing that was got from (unlike 'read')
void writeDup(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntries entries) {
	foreach (immutable uint i; 0..entries.size) {
		// curEntry is the *next* position on the stack.
		// Gets are relative to the current top of stack (0 reads from curEntry - 1).
		immutable uint stackEntry = entries.start + i;
		verify(stackEntry < writer.nextStackEntry);
		pushOpcode(writer, OpCode.dup);
		pushU8(writer.alloc, writer.code, safeU32ToU8(writer.nextStackEntry - 1 - stackEntry));
	}
	writer.nextStackEntry += entries.size;
}

void writeDupPartial(Alloc)(
	ref ByteCodeWriter!Alloc writer,
	immutable u8 stackEntryOffset,
	immutable u8 byteOffset,
	immutable u8 sizeBytes,
) {
	pushOpcode(writer, OpCode.dupPartial);
	pushU8(writer.alloc, writer.code, safeU32ToU8(writer.nextStackEntry - 1 - stackEntryOffset));
	pushU8(writer.alloc, writer.code, catU4U4(byteOffset, sizeBytes));
	writer.nextStackEntry += 1;
}

void writeRead(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u8 offset, immutable u8 size) {
	pushOpcode(writer, OpCode.read);
	pushU8(writer.alloc, writer.code, offset);
	pushU8(writer.alloc, writer.code, size);
	writer.nextStackEntry -= 1;
	writer.nextStackEntry += divRoundUp(size, stackEntrySize);
}

void writeWrite(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u8 offset, immutable u8 size) {
	pushOpcode(writer, OpCode.write);
	pushU8(writer.alloc, writer.code, offset);
	pushU8(writer.alloc, writer.code, size);
	writer.nextStackEntry -= 1 + divRoundUp(size, stackEntrySize);
}

void writePushConstant(Alloc)(ref ByteCodeWriter!Alloc writer, immutable size_t value) {
	if (value <= maxU32) {
		writePushU32(writer, safeSizeTToU32(value));
	} else {
		writePushU64(writer, value);
	}
}

void writePushConstantStr(Alloc)(ref ByteCodeWriter!Alloc writer, immutable Str value) {
	pushOpcode(writer, OpCode.pushU32);
	pushU32(writer.alloc, writer.code, safeSizeTToU32(size(value)));
	pushOpcode(writer, OpCode.pushU64);
	immutable ByteCodeIndex delayed = writePushU64Delayed(writer);
	immutable u32 textIndex = safeSizeTToU32(mutArrSize(writer.text));
	pushAll(writer.alloc, writer.text, value);
	//TODO: could use temp alloc
	push(writer.alloc, writer.delayedTextPtrs, immutable ByteCodeIndexAndTextIndex(delayed, textIndex));
}

private void writePushU32(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u32 value) {
	writePushU32Common(writer, value);
}

private void writePushU64(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u64 value) {
	pushOpcode(writer, OpCode.pushU64);
	pushU64(writer.alloc, writer.code, value);
	writer.nextStackEntry++;
}

void writeReturn(Alloc)(ref ByteCodeWriter!Alloc writer) {
	pushOpcode(writer, OpCode.return_);
}

immutable(ByteCodeIndex) writePushU32Delayed(Alloc)(ref ByteCodeWriter!Alloc writer) {
	return writePushU32Common(writer, 0);
}

private immutable(ByteCodeIndex) writePushU32Common(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u32 value) {
	pushOpcode(writer, OpCode.pushU32);
	immutable ByteCodeIndex fnAddress = curByteCodeIndex(writer);
	pushU32(writer.alloc, writer.code, value);
	writer.nextStackEntry++;
	return fnAddress;
}

immutable(ByteCodeIndex) writePushU64Delayed(Alloc)(ref ByteCodeWriter!Alloc writer) {
	return writePushU64Common(writer, 0);
}

private immutable(ByteCodeIndex) writePushU64Common(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u32 value) {
	pushOpcode(writer, OpCode.pushU64);
	immutable ByteCodeIndex address = curByteCodeIndex(writer);
	pushU64(writer.alloc, writer.code, value);
	writer.nextStackEntry++;
	return address;
}

void writeRemove(Alloc)(ref ByteCodeWriter!Alloc writer, immutable StackEntries entries) {
	pushOpcode(writer, OpCode.remove);
	pushU8(writer.alloc, writer.code, safeU32ToU8(writer.nextStackEntry - entries.start));
	pushU8(writer.alloc, writer.code, entries.size);
	writer.nextStackEntry -= entries.size;
}

immutable(ByteCodeIndex) writeJumpDelayed(Alloc)(ref ByteCodeWriter!Alloc writer) {
	pushOpcode(writer, OpCode.jump);
	immutable ByteCodeIndex jumpOffsetIndex = curByteCodeIndex(writer);
	pushU8(writer.alloc, writer.code, 0);
	return jumpOffsetIndex;
}

void fillInJumpDelayed(Alloc)(ref ByteCodeWriter!Alloc writer, immutable ByteCodeIndex jumpIndex) {
	writeU8(writer.code, jumpIndex.index, safeU32ToU8(curByteCodeIndex(writer).index - 1 - jumpIndex.index));
}

immutable(ByteCodeIndex) writeSwitchDelay(Alloc)(ref ByteCodeWriter!Alloc writer, immutable size_t nCases) {
	pushOpcode(writer, OpCode.switch_);
	immutable ByteCodeIndex addresses = curByteCodeIndex(writer);
	foreach (immutable size_t i; 0..nCases)
		pushU8(writer.alloc, writer.code, 0);
	return addresses;
}

void writeFn(Alloc)(ref ByteCodeWriter!Alloc writer, immutable FnOp fn) {
	pushOpcode(writer, OpCode.fn);
	pushU8(writer.alloc, writer.code, fn);
	immutable int stackEffect = () {
		final switch (fn) {
			case FnOp.addFloat64:
			case FnOp.addInt64OrNat64:
			case FnOp.bitShiftLeftInt32:
			case FnOp.bitShiftLeftNat32:
			case FnOp.bitShiftRightInt32:
			case FnOp.bitShiftRightNat32:
			case FnOp.bitwiseAnd:
			case FnOp.bitwiseOr:
			case FnOp.eqNat:
			case FnOp.lessFloat64:
			case FnOp.lessInt8:
			case FnOp.lessInt16:
			case FnOp.lessInt32:
			case FnOp.lessInt64:
			case FnOp.lessNat:
			case FnOp.mulFloat64:
			case FnOp.subFloat64:
			case FnOp.unsafeDivFloat64:
			case FnOp.unsafeDivInt64:
			case FnOp.unsafeDivNat64:
			case FnOp.unsafeModNat64:
			case FnOp.wrapAddInt16:
			case FnOp.wrapAddInt32:
			case FnOp.wrapAddInt64:
			case FnOp.wrapAddNat16:
			case FnOp.wrapAddNat32:
			case FnOp.wrapAddNat64:
			case FnOp.wrapMulInt16:
			case FnOp.wrapMulInt32:
			case FnOp.wrapMulInt64:
			case FnOp.wrapMulNat16:
			case FnOp.wrapMulNat32:
			case FnOp.wrapMulNat64:
			case FnOp.wrapSubInt16:
			case FnOp.wrapSubInt32:
			case FnOp.wrapSubInt64:
			case FnOp.wrapSubNat16:
			case FnOp.wrapSubNat32:
			case FnOp.wrapSubNat64:
				return -1;
			case FnOp.float64FromInt64:
			case FnOp.float64FromNat64:
			case FnOp.not:
			case FnOp.truncateToInt64FromFloat64:
				return 0;
			case FnOp.ptrToOrRefOfVal:
				return 1;
			case FnOp.hardFail:
				return 2; // string takes 2 stack entries
		}
	}();
	writer.nextStackEntry += stackEffect;
}

private:

void pushOpcode(Alloc)(ref ByteCodeWriter!Alloc writer, immutable OpCode code) {
	push(writer.alloc, writer.code, code);
}


void pushStackOffset(Alloc)(ref Alloc alloc, ref MutArr!(immutable OpCode) code, immutable u32 value) {
	pushU8(alloc, code, safeU32ToU8(value));
}

void pushU8(Alloc)(ref Alloc alloc, ref MutArr!(immutable OpCode) code, immutable u8 value) {
	push(alloc, code, cast(immutable OpCode) value);
}

void pushU32(Alloc)(ref Alloc alloc, ref MutArr!(immutable OpCode) code, immutable u32 value) {
	eachByteOfU32(value, (immutable size_t, immutable u8 valueByte) {
		pushU8(alloc, code, valueByte);
	});
}

void pushU64(Alloc)(ref Alloc alloc, ref MutArr!(immutable OpCode) code, immutable u64 value) {
	eachByteOfU64(value, (immutable size_t, immutable u8 valueByte) {
		pushU8(alloc, code, valueByte);
	});
}

void writeU8(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u8 value) {
	setAt(code, index, cast(immutable OpCode) value);
}

void writeU32(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u32 value) {
	eachByteOfU32(value, (immutable size_t valueIndex, immutable u8 valueByte) {
		writeU8(code, index + valueIndex, valueByte);
	});
}

void writeU64(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u64 value) {
	eachByteOfU64(value, (immutable size_t valueIndex, immutable u8 valueByte) {
		writeU8(code, index + valueIndex, valueByte);
	});
}

void eachByteOfU32(
	immutable u32 value,
	scope immutable(void) delegate(immutable size_t, immutable u8) @safe @nogc pure nothrow cb,
) {
	cb(0, bottomU8OfU32(value >> 24));
	cb(1, bottomU8OfU32(value >> 16));
	cb(2, bottomU8OfU32(value >> 8));
	cb(3, bottomU8OfU32(value));
}

void eachByteOfU64(
	immutable u64 value,
	scope immutable(void) delegate(immutable size_t, immutable u8) @safe @nogc pure nothrow cb,
) {
	eachByteOfU32(bottomU32OfU64(value >> 32), cb);
	eachByteOfU32(bottomU32OfU64(value), cb);
}