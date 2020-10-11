module interpret.opcode;

@safe @nogc pure nothrow:

import util.types : u8;

// Implementation detail of bytecodeReader and bytecodeWriter
// Use one of those instead of using these directly.
// An Operation may map to multiple OpCodes to make the encoding more efficient.

enum OpCode : u8 {
	// args: u32 address
	call,

	// args: u8 stackOffsetOfFunPtr
	callFunPtr,

	// args: u8 offset
	dup,

	// args: u8 entryOffset, u4 byteOffset, u4 sizeBytes
	dupPartial,

	// args: FnOp fnOp
	// reads another byte and interprets as a FnOp
	fn,

	// args: u8 offset
	// (note: an offset of 0 still takes you to the next instruction)
	jump,

	// args: u32 value
	// Push a constant u32 value. (Takes up a full 64-bit stack entry)
	pushU32,

	// args: u64 value
	// Push a constant u64 value.
	pushU64,

	// args: u8 offset, u8 size
	read,

	// args: u8 offset, u8 nEntries
	remove,

	// args: none
	return_,

	// args: u8[nCases] offsets
	switch_,

	// args: u8 offset, u8 size
	write,
}
