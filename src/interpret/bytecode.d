module interpret.bytecode;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.collection.mutArr : moveToArr, MutArr, mutArrSize, push, setAt;
import util.ptr : Ptr;
import util.types : bottomU8OfU32, catU4U4, safeSizeTToU32, safeU32ToU8, u8, u32;
import util.util : divRoundUp, verify;

struct ByteCode {
	// NOTE: not every entry is an opcode
	immutable Arr!OpCode byteCode;
	immutable ByteCodeIndex main;
}

struct ByteCodeIndex {
	immutable u32 index;
}

struct ByteCodeOffset {
	immutable u8 offset;
}

immutable(u8) stackEntrySize = 8;

struct ByteCodeWriter(Alloc) {
	private:
	Ptr!Alloc alloc;
	MutArr!(immutable OpCode) code;
	uint nextStackEntry = 0;
}

immutable(ByteCode) finishByteCode(Alloc)(ref ByteCodeWriter!Alloc writer, immutable ByteCodeIndex mainIndex) {
	return immutable ByteCode(moveToArr(writer.alloc, writer.code), mainIndex);
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

void writePushU8(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u8 value) {
	pushOpcode(writer, OpCode.pushU8);
	pushU8(writer.alloc, writer.code, value);
	writer.nextStackEntry++;
}

void writePushU32(Alloc)(ref ByteCodeWriter!Alloc writer, immutable u32 value) {
	writePushU32Common(writer, value);
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
	writeU8(writer.code, jumpIndex.index, safeU32ToU8(curByteCodeIndex(writer).index - jumpIndex.index));
}

immutable(ByteCodeIndex) writeSwitchDelay(Alloc)(ref ByteCodeWriter!Alloc writer, immutable size_t nCases) {
	pushOpcode(writer, OpCode.switch_);
	immutable ByteCodeIndex addresses = curByteCodeIndex(writer);
	foreach (immutable size_t i; 0..nCases)
		pushU8(writer.alloc, writer.code, 0);
	return addresses;
}

struct StackEntries {
	immutable uint start; // Index of first entry
	immutable u8 size; // Number of entries
}

private:

//TODO:PRIVATE
enum OpCode : u8 {
	// args: u32 address
	// pushes current address onto the stack and goes to the new function's address
	call,

	// args: u8 offset
	// Gets a stack entry and duplicates it on the top of the stack.
	dup,

	// args: u8 entryOffset, u4 byteOffset, u4 sizeBytes
	// byteOffset + sizeBytes must be <= stackEntrySize
	dupPartial,

	jump,

	// args: u8 value
	pushU8,

	// args: u32 value
	// Push a literal u32 value. (Takes up a full 64-bit stack entry)
	pushU32,

	// args: u8 offset, u8 size
	// Pops a pointer off the stack and reads `size` bytes from ptr + offset
	read,

	// args: u8 offset, u8 nEntries
	// Removes the entries at the offset. Later entries are moved to there.
	remove,

	return_,

	// args: u8[nCases] offsets
	// This is a switch on the contiguous range from [0, nCases).
	// (Offsets are relative to the bytecode index of the first offset.
	// A 0th offset is needed because otherwise there's no way to know how many cases there are.)
	switch_,

	// args: u8 offset, u8 size
	// Pops a pointer, then pops divRoundUp(size, stackEntrySize) stack entries and writes them to ptr + offset
	write,
}

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

void writeU8(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u8 value) {
	setAt(code, index, cast(immutable OpCode) value);
}

void writeU32(ref MutArr!(immutable OpCode) code, immutable size_t index, immutable u32 value) {
	verify(index + 4 <= mutArrSize(code));
	eachByteOfU32(value, (immutable size_t valueIndex, immutable u8 valueByte) {
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
