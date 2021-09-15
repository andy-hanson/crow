module interpret.opcode;

@safe @nogc pure nothrow:

// Implementation detail of bytecodeReader and bytecodeWriter
// Use one of those instead of using these directly.
// An Operation may map to multiple OpCodes to make the encoding more efficient.

enum OpCode : ubyte {
	// reserve small numbers since they can appear by accident
	reserved0,
	reserved1,
	reserved2,
	reserved3,

	// args: u16 size
	assertStackSize,

	// no args
	assertUnreachable,

	// args: u32 address
	call,

	// args: u8 stackOffsetOfFunPtr
	callFunPtr,

	// args: u16 stackOffsetBytes, u16 sizeBytes
	dup,

	extern_,
	externDynCall,

	// args: FnOp fnOp
	// reads another byte and interprets as a FnOp
	fn,

	// args: u16 offset
	// (note: an offset of 0 still takes you to the next instruction)
	jump,

	// args: u8 nToPack, u8[nToPack] sizes
	// Sum of sizes may be > 8 (to pack many at once)
	pack,

	// args: u8/u16/u32/u64 value
	// Push a constant u8/u16/u32/u64 value.
	// (Takes up a full 64-bit stack entry regardless of value size.)
	pushU8, pushU16, pushU32, pushU64,

	// args: u8 offset, u8 size
	read,

	// args: u8 offset, u8 nEntries
	remove,

	// args: none
	return_,

	// args: u8 stackOffset
	stackRef,

	// args: u16[nCases] offsets
	switch_,

	// args: u8 offset, u8 size
	write,
}
