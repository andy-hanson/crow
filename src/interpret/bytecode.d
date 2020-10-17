module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.opcode : OpCode;
import util.collection.arr : Arr;
import util.collection.str : Str, strLiteral;
import util.sexpr : Sexpr, tataArr, tataNat, tataRecord, tataStr, tataSym;
import util.types : safeU32ToU16, u8, u16, u32, u64;
import util.sourceRange : FileAndPos;
import util.util : todo, verify;

@trusted T matchOperationImpure(T)(
	ref immutable Operation a,
	scope T delegate(ref immutable Operation.Call) @safe @nogc nothrow cbCall,
	scope T delegate(ref immutable Operation.CallFunPtr) @safe @nogc nothrow cbCallFunPtr,
	scope T delegate(ref immutable Operation.Dup) @safe @nogc nothrow cbDup,
	scope T delegate(ref immutable Operation.DupPartial) @safe @nogc nothrow cbDupPartial,
	scope T delegate(ref immutable Operation.Fn) @safe @nogc nothrow cbFn,
	scope T delegate(ref immutable Operation.Jump) @safe @nogc nothrow cbJump,
	scope T delegate(ref immutable Operation.Pack) @safe @nogc nothrow cbPack,
	scope T delegate(ref immutable Operation.PushValue) @safe @nogc nothrow cbPushValue,
	scope T delegate(ref immutable Operation.Read) @safe @nogc nothrow cbRead,
	scope T delegate(ref immutable Operation.Remove) @safe @nogc nothrow cbRemove,
	scope T delegate(ref immutable Operation.Return) @safe @nogc nothrow cbReturn,
	scope T delegate(ref immutable Operation.StackRef) @safe @nogc nothrow cbStackRef,
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
		case Operation.Kind.pack:
			return cbPack(a.pack_);
		case Operation.Kind.pushValue:
			return cbPushValue(a.pushValue_);
		case Operation.Kind.read:
			return cbRead(a.read_);
		case Operation.Kind.remove:
			return cbRemove(a.remove_);
		case Operation.Kind.return_:
			return cbReturn(a.return_);
		case Operation.Kind.stackRef_:
			return cbStackRef(a.stackRef_);
		case Operation.Kind.switch_:
			return cbSwitch(a.switch_);
		case Operation.Kind.write:
			return cbWrite(a.write_);
	}
}

pure:

@trusted T matchOperation(T)(
	ref immutable Operation a,
	scope T delegate(ref immutable Operation.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable Operation.CallFunPtr) @safe @nogc pure nothrow cbCallFunPtr,
	scope T delegate(ref immutable Operation.Dup) @safe @nogc pure nothrow cbDup,
	scope T delegate(ref immutable Operation.DupPartial) @safe @nogc pure nothrow cbDupPartial,
	scope T delegate(ref immutable Operation.Fn) @safe @nogc pure nothrow cbFn,
	scope T delegate(ref immutable Operation.Jump) @safe @nogc pure nothrow cbJump,
	scope T delegate(ref immutable Operation.Pack) @safe @nogc pure nothrow cbPack,
	scope T delegate(ref immutable Operation.PushValue) @safe @nogc pure nothrow cbPushValue,
	scope T delegate(ref immutable Operation.Read) @safe @nogc pure nothrow cbRead,
	scope T delegate(ref immutable Operation.Remove) @safe @nogc pure nothrow cbRemove,
	scope T delegate(ref immutable Operation.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(ref immutable Operation.StackRef) @safe @nogc pure nothrow cbStackRef,
	scope T delegate(ref immutable Operation.Switch) @safe @nogc pure nothrow cbSwitch,
	scope T delegate(ref immutable Operation.Write) @safe @nogc pure nothrow cbWrite,
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
		case Operation.Kind.pack:
			return cbPack(a.pack_);
		case Operation.Kind.pushValue:
			return cbPushValue(a.pushValue_);
		case Operation.Kind.read:
			return cbRead(a.read_);
		case Operation.Kind.remove:
			return cbRemove(a.remove_);
		case Operation.Kind.return_:
			return cbReturn(a.return_);
		case Operation.Kind.stackRef_:
			return cbStackRef(a.stackRef_);
		case Operation.Kind.switch_:
			return cbSwitch(a.switch_);
		case Operation.Kind.write:
			return cbWrite(a.write_);
	}
}

immutable(Sexpr) sexprOfOperation(Alloc)(ref Alloc alloc, ref immutable Operation a) {
	return matchOperation(
		a,
		(ref immutable Operation.Call it) =>
			tataRecord(alloc, "call", tataNat(it.address)),
		(ref immutable Operation.CallFunPtr it)  =>
			tataRecord(alloc, "call-ptr", tataNat(it.stackOffsetOfFunPtr.offset)),
		(ref immutable Operation.Dup it)  =>
			tataRecord(alloc, "dup", tataNat(it.offset.offset)),
		(ref immutable Operation.DupPartial it)  =>
			tataRecord(
				alloc,
				"dup-part",
				tataNat(it.entryOffset.offset),
				tataNat(it.byteOffset),
				tataNat(it.sizeBytes)),
		(ref immutable Operation.Fn it)  =>
			tataRecord(alloc, "fn", tataStr(strOfFnOp(it.fnOp))),
		(ref immutable Operation.Jump it)  =>
			tataRecord(alloc, "jump", tataNat(it.offset.offset)),
		(ref immutable Operation.Pack it)  =>
			tataRecord(alloc, "pack", tataArr(alloc, it.sizes, (ref immutable u8 size) => tataNat(size))),
		(ref immutable Operation.PushValue it)  =>
			tataRecord(alloc, "push-val", tataNat(it.value)),
		(ref immutable Operation.Read it)  =>
			tataRecord(alloc, "read", tataNat(it.offset), tataNat(it.size)),
		(ref immutable Operation.Remove it)  =>
			tataRecord(alloc, "remove", tataNat(it.offset.offset), tataNat(it.nEntries)),
		(ref immutable Operation.Return it)  =>
			tataSym("return"),
		(ref immutable Operation.StackRef it)  =>
			tataRecord(alloc, "stack-ref", tataNat(it.offset.offset)),
		(ref immutable Operation.Switch it) =>
			tataSym("switch"),
		(ref immutable Operation.Write it) =>
			tataRecord(alloc, "write", tataNat(it.offset), tataNat(it.offset)));
}

struct ByteCode {
	immutable Arr!u8 byteCode;
	immutable Arr!FileAndPos sources; // parallel to byteCode
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
		immutable ByteCodeOffset offset;
	}

	struct Pack {
		immutable Arr!u8 sizes;
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

	struct StackRef {
		immutable StackOffset offset;
	}

	// Pop a number off the stack, look it up in 'offsets', and jump forward that much.
	// Offsets are relative to the bytecode index of the first offset.
	// A 0th offset is needed because otherwise there's no way to know how many cases there are.
	struct Switch {
		// The reader can't return the offsets since it doesn't have a length
		// immutable Arr!u16 offsets;
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
		pack,
		pushValue,
		read,
		remove,
		return_,
		stackRef_,
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
		immutable Pack pack_;
		immutable PushValue pushValue_;
		immutable Read read_;
		immutable Remove remove_;
		immutable Return return_;
		immutable StackRef stackRef_;
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
	@trusted immutable this(immutable Pack a) { kind_ = Kind.pack; pack_ = a; }
	immutable this(immutable PushValue a) { kind_ = Kind.pushValue; pushValue_ = a; }
	immutable this(immutable Read a) { kind_ = Kind.read; read_ = a; }
	immutable this(immutable Remove a) { kind_ = Kind.remove; remove_ = a; }
	immutable this(immutable Return a) { kind_ = Kind.return_; return_ = a; }
	immutable this(immutable StackRef a) { kind_ = Kind.stackRef_; stackRef_ = a; }
	immutable this(immutable Switch a) { kind_ = Kind.switch_; switch_ = a; }
	immutable this(immutable Write a) { kind_ = Kind.write; write_ = a; }
}

struct ByteCodeIndex {
	immutable u32 index;
}

immutable(ByteCodeIndex) addByteCodeIndex(immutable ByteCodeIndex a, immutable u32 b) {
	return immutable ByteCodeIndex(a.index + b);
}

immutable(ByteCodeOffset) subtractByteCodeIndex(immutable ByteCodeIndex a, immutable ByteCodeIndex b) {
	verify(a.index >= b.index);
	return immutable ByteCodeOffset(safeU32ToU16(a.index - b.index));
}

struct ByteCodeOffset {
	immutable u16 offset;
}

immutable(u8) stackEntrySize = 8;

enum FnOp : u8 {
	addFloat64,
	addInt64OrNat64,
	bitShiftLeftInt32,
	bitShiftLeftNat32,
	bitShiftRightInt32,
	bitShiftRightNat32,
	bitwiseAnd,
	bitwiseOr,
	compareExchangeStrong,
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
	malloc,
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

immutable(Str) strOfFnOp(immutable FnOp fnOp) {
	return strLiteral(() { final switch (fnOp) {
		case FnOp.addFloat64:
			return "add-float-64";
		case FnOp.addInt64OrNat64:
			return "add-int-64-or-nat-64";
		case FnOp.bitShiftLeftInt32:
			return "bit-shift-left-int-32";
		case FnOp.bitShiftLeftNat32:
			return "bit-shift-left-nat-32";
		case FnOp.bitShiftRightInt32:
			return "bit-shift-right-int-32";
		case FnOp.bitShiftRightNat32:
			return "bit-shift-right-nat-32";
		case FnOp.bitwiseAnd:
			return "bitwise-and";
		case FnOp.bitwiseOr:
			return "bitwise-or";
		case FnOp.compareExchangeStrong:
			return "compare-exchange-strong";
		case FnOp.eqNat:
			return "== (nat)";
		case FnOp.float64FromInt64:
			return "float-64-from-int-64";
		case FnOp.float64FromNat64:
			return "float-64-from-nat-64";
		case FnOp.hardFail:
			return "hard-fail";
		case FnOp.lessFloat64:
			return "< (float-64)";
		case FnOp.lessInt8:
			return "< (int-8)";
		case FnOp.lessInt16:
			return "< (int-16)";
		case FnOp.lessInt32:
			return "< (int-32)";
		case FnOp.lessInt64:
			return "< (int-64)";
		case FnOp.lessNat:
			return "< (nat)";
		case FnOp.malloc:
			return "malloc";
		case FnOp.mulFloat64:
			return "* (float-64)";
		case FnOp.not:
			return "not";
		case FnOp.ptrToOrRefOfVal:
			return "ptr-to or ref-of-val";
		case FnOp.subFloat64:
			return "- (float-64)";
		case FnOp.truncateToInt64FromFloat64:
			return "truncate-to-int-64-from-float-64";
		case FnOp.unsafeDivFloat64:
			return "unsafe-div (float-64)";
		case FnOp.unsafeDivInt64:
			return "unsafe-div (int-64)";
		case FnOp.unsafeDivNat64:
			return "unsafe-div (nat-64)";
		case FnOp.unsafeModNat64:
			return "unsafe-mod (nat-64)";
		case FnOp.wrapAddInt16:
			return "wrap-add (int-16)";
		case FnOp.wrapAddInt32:
			return "wrap-add (int-32)";
		case FnOp.wrapAddInt64:
			return "wrap-add (int-64)";
		case FnOp.wrapAddNat16:
			return "wrap-add (nat-16)";
		case FnOp.wrapAddNat32:
			return "wrap-add (nat-32)";
		case FnOp.wrapAddNat64:
			return "wrap-add (nat-64)";
		case FnOp.wrapMulInt16:
			return "wrap-mul (int-16)";
		case FnOp.wrapMulInt32:
			return "wrap-mul (int-32)";
		case FnOp.wrapMulInt64:
			return "wrap-mul (int-64)";
		case FnOp.wrapMulNat16:
			return "wrap-mul (nat-16)";
		case FnOp.wrapMulNat32:
			return "wrap-mul (nat-32)";
		case FnOp.wrapMulNat64:
			return "wrap-mul (nat-64)";
		case FnOp.wrapSubInt16:
			return "wrap-sub (int-16)";
		case FnOp.wrapSubInt32:
			return "wrap-sub (int-32)";
		case FnOp.wrapSubInt64:
			return "wrap-sub (int-64)";
		case FnOp.wrapSubNat16:
			return "wrap-sub (nat-16)";
		case FnOp.wrapSubNat32:
			return "wrap-sub (nat-32)";
		case FnOp.wrapSubNat64:
			return "wrap-sub (nat-64)";
	} }());
}
