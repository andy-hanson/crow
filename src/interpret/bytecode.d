module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.opcode : OpCode;
import util.collection.arr : Arr;
import util.types : safeU32ToU8, u8, u32, u64;

T matchOperation(T)(
	ref immutable Operation a,
	scope T delegate(ref immutable Operation.Call) @safe @nogc nothrow cbCall,
	scope T delegate(ref immutable Operation.CallFunPtr) @safe @nogc nothrow cbCallFunPtr,
	scope T delegate(ref immutable Operation.Dup) @safe @nogc nothrow cbDup,
	scope T delegate(ref immutable Operation.DupPartial) @safe @nogc nothrow cbDupPartial,
	scope T delegate(ref immutable Operation.Fn) @safe @nogc nothrow cbFn,
	scope T delegate(ref immutable Operation.Jump) @safe @nogc nothrow cbJump,
	scope T delegate(ref immutable Operation.PushValue) @safe @nogc nothrow cbPushValue,
	scope T delegate(ref immutable Operation.Read) @safe @nogc nothrow cbRead,
	scope T delegate(ref immutable Operation.Remove) @safe @nogc nothrow cbRemove,
	scope T delegate(ref immutable Operation.Return) @safe @nogc nothrow cbReturn,
	scope T delegate(ref immutable Operation.Switch) @safe @nogc nothrow cbSwitch,
	scope T delegate(ref immutable Operation.Write) @safe @nogc nothrow cbWrite,
) {
	final switch (a.kind_) {
		case Operation.Kind.call:
			return cbCall(a.call_);
		case Operation.Kind.callFunPtr:
			return cbCallFunPtr(a.callFunPtr_);
		case Operation.Kind.dup:
			return cbDup(a.dup_);
		case Operation.Kind.dupPartial:
			return cbDupPartial(a.dupPartial_);
		case Operation.Kind.fn:
			return cbFn(a.fn_);
		case Operation.Kind.jump:
			return cbJump(a.jump_);
		case Operation.Kind.pushValue:
			return cbPushValue(a.pushValue_);
		case Operation.Kind.read:
			return cbRead(a.read_);
		case Operation.Kind.remove:
			return cbRemove(a.remove_);
		case Operation.Kind.return_:
			return cbReturn(a.return_);
		case Operation.Kind.switch_:
			return cbSwitch(a.switch_);
		case Operation.Kind.write:
			return cbWrite(a.write_);
	}
}

pure:

struct ByteCode {
	// NOTE: not every entry is an opcode
	immutable Arr!OpCode byteCode;
	immutable Arr!char text;
	immutable ByteCodeIndex main;
}

struct StackOffset {
	// 0 is the top entry on the stack, 1 is the one before that, etc.
	immutable u8 offset;
}

struct Operation {
	@safe @nogc pure nothrow:

	// pushes current address onto the function stack and goes to the new function's address
	struct Call {
		immutable u32 address;
	}

	// Removes a fun-ptr from the stack at the given offset and calls that
	struct CallFunPtr {
		immutable StackOffset stackOffsetOfFunPtr;
	}

	// Gets a stack entry and duplicates it on the top of the stack.
	struct Dup {
		immutable StackOffset offset; // Duplicates the stackentry at this offset to the top
	}

	// Like Dup, gets part of the bytes of a single stack entry.
	// byteOffset + sizeBytes must be <= stackEntrySize
	struct DupPartial {
		immutable StackOffset entryOffset;
		// Encoded as u4
		immutable u8 byteOffset;
		immutable u8 sizeBytes;
	}

	// Runs a special function (stack effect determined by the function)
	struct Fn {
		immutable FnOp fnOp;
	}

	// Jumps forward `offset` bytes. (Also adds 1 after reading any instruction, including 'jump'.)
	struct Jump {
		immutable u8 offset;
	}

	// Push the value onto the stack.
	struct PushValue {
		immutable u64 value;
	}

	// Pop a pointer off the stack, add 'offset', read 'size' bytes, and push to the stack.
	struct Read {
		immutable u8 offset;
		immutable u8 size;
	}

	// Remove entries from the stack, shifting higher entries down.
	struct Remove {
		immutable StackOffset offset;
		immutable u8 nEntries;
	}

	// Pop an address from the function stack and jump to there.
	struct Return {}

	// Pop a number off the stack, look it up in 'offsets', and jump forward that much.
	// Offsets are relative to the bytecode index of the first offset.
	// A 0th offset is needed because otherwise there's no way to know how many cases there are.
	struct Switch {
		// The reader can't return the offsets since it doesn't have a length
		// immutable Arr!u8 offsets;
	}

	// Pop divRoundUp(size, stackEntrySize) stack entries, then pop a pointer, then write to ptr + offset
	struct Write {
		immutable u8 offset;
		immutable u8 size;
	}

	private:
	enum Kind {
		call,
		callFunPtr,
		dup,
		dupPartial,
		fn,
		jump,
		pushValue,
		read,
		remove,
		return_,
		switch_,
		write,
	}
	immutable Kind kind_;
	union {
		immutable Call call_;
		immutable CallFunPtr callFunPtr_;
		immutable Dup dup_;
		immutable DupPartial dupPartial_;
		immutable Fn fn_;
		immutable Jump jump_;
		immutable PushValue pushValue_;
		immutable Read read_;
		immutable Remove remove_;
		immutable Return return_;
		immutable Switch switch_;
		immutable Write write_;
	}

	public:
	immutable this(immutable Call a) { kind_ = Kind.call; call_ = a; }
	immutable this(immutable CallFunPtr a) { kind_ = Kind.callFunPtr; callFunPtr_ = a; }
	immutable this(immutable Dup a) { kind_ = Kind.dup; dup_ = a; }
	immutable this(immutable DupPartial a) { kind_ = Kind.dupPartial; dupPartial_ = a; }
	immutable this(immutable Fn a) { kind_ = Kind.fn; fn_ = a; }
	immutable this(immutable Jump a) { kind_ = Kind.jump; jump_ = a; }
	immutable this(immutable PushValue a) { kind_ = Kind.pushValue; pushValue_ = a; }
	immutable this(immutable Read a) { kind_ = Kind.read; read_ = a; }
	immutable this(immutable Remove a) { kind_ = Kind.remove; remove_ = a; }
	immutable this(immutable Return a) { kind_ = Kind.return_; return_ = a; }
	@trusted immutable this(immutable Switch a) { kind_ = Kind.switch_; switch_ = a; }
	immutable this(immutable Write a) { kind_ = Kind.write; write_ = a; }
}

@trusted T matchTypeAst(T)(
	ref immutable TypeAst a,
	scope T delegate(ref immutable TypeAst.TypeParam) @safe @nogc pure nothrow cbTypeParam,
	scope T delegate(ref immutable TypeAst.InstStruct) @safe @nogc pure nothrow cbInstStruct
) {
	final switch (a.kind) {
		case TypeAst.Kind.typeParam:
			return cbTypeParam(a.typeParam);
		case TypeAst.Kind.instStruct:
			return cbInstStruct(a.instStruct);
	}
}


struct ByteCodeIndex {
	immutable u32 index;
}

immutable(ByteCodeIndex) addByteCodeIndex(immutable ByteCodeIndex a, immutable u32 b) {
	return immutable ByteCodeIndex(a.index + b);
}

immutable(ByteCodeOffset) subtractByteCodeIndex(immutable ByteCodeIndex a, immutable ByteCodeIndex b) {
	return immutable ByteCodeOffset(safeU32ToU8(a.index - b.index));
}

struct ByteCodeOffset {
	immutable u8 offset;
}

immutable(u8) stackEntrySize = 8;

struct StackEntries {
	immutable uint start; // Index of first entry
	immutable u8 size; // Number of entries
}

enum FnOp : u8 {
	addFloat64,
	addInt64OrNat64,
	bitShiftLeftInt32,
	bitShiftLeftNat32,
	bitShiftRightInt32,
	bitShiftRightNat32,
	bitwiseAnd,
	bitwiseOr,
	eqNat,
	float64FromInt64,
	float64FromNat64,
	hardFail,
	lessFloat64,
	lessInt8,
	lessInt16,
	lessInt32,
	lessInt64,
	lessNat,
	mulFloat64,
	not,
	ptrToOrRefOfVal,
	subFloat64,
	truncateToInt64FromFloat64,
	unsafeDivFloat64,
	unsafeDivInt64,
	unsafeDivNat64,
	unsafeModNat64,
	wrapAddInt16,
	wrapAddInt32,
	wrapAddInt64,
	wrapAddNat16,
	wrapAddNat32,
	wrapAddNat64,
	wrapMulInt16,
	wrapMulInt32,
	wrapMulInt64,
	wrapMulNat16,
	wrapMulNat32,
	wrapMulNat64,
	wrapSubInt16,
	wrapSubInt32,
	wrapSubInt64,
	wrapSubNat16,
	wrapSubNat32,
	wrapSubNat64,
}
