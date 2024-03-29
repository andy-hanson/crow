module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.extern_ : DynCallSig, FunPointer;
import model.lowModel : LowFunIndex;
import model.model : VarKind;
import util.col.map : Map;
import util.col.enumMap : EnumMap;
import util.col.fullIndexMap : FullIndexMap;
import util.sourceRange : Pos;

immutable struct Operation {
	alias Fn = immutable void function(
		ulong* stacksData,
		Operation** stacksReturn,
		Operation* cur,
	) @system @nogc nothrow;

	@safe @nogc pure nothrow:

	this(Fn a) { fn = a; }
	this(Operation* a) { operationPtr = a; }
	this(long a) { long_ = a; }
	this(ulong a) { ulong_ = a; }
	this(DynCallSig a) { sig = a; }
	this(FunPointer a) { funPointer = a; }

	union {
		Fn fn;
		Operation* operationPtr;
		long long_;
		ulong ulong_;
		DynCallSig sig;
		FunPointer funPointer;
	}
}
static assert(Operation.sizeof == ulong.sizeof);

pure:

immutable struct ByteCodeSource {
	LowFunIndex fun;
	Pos pos;
}

immutable struct ByteCode {
	@safe @nogc pure nothrow:

	Operations operations;
	FunPointerToOperationPointer funPointerToOperationPointer;
	ubyte[] text;
	EnumMap!(VarKind, size_t) varsSizeWords;
	ByteCodeIndex main;

	Operation[] byteCode() return scope =>
		operations.byteCode;
	FullIndexMap!(ByteCodeIndex, ByteCodeSource) sources() return scope =>
		operations.sources;
}

alias FunPointerToOperationPointer = Map!(FunPointer, immutable Operation*);

immutable struct Operations {
	Operation[] byteCode;
	FullIndexMap!(ByteCodeIndex, ByteCodeSource) sources; // parallel to byteCode
}

@trusted Operation* initialOperationPointer(return scope ref immutable ByteCode a) =>
	a.byteCode.ptr + a.main.index;

immutable struct StackOffset {
	// In words.
	// 0 is the top entry on the stack, 1 is the one before that, etc.
	size_t offset;
}
immutable struct StackOffsetBytes {
	@safe @nogc pure nothrow:

	size_t offsetBytes;

	this(size_t o) {
		offsetBytes = o;
		assert(offsetBytes > 0);
	}
}

immutable struct ByteCodeIndex {
	size_t index;
}

ByteCodeIndex addByteCodeIndex(ByteCodeIndex a, size_t b) =>
	ByteCodeIndex(a.index + b);

ByteCodeOffset subtractByteCodeIndex(ByteCodeIndex a, ByteCodeIndex b) =>
	ByteCodeOffset((cast(long) a.index) - (cast(long) b.index));

immutable struct ByteCodeOffsetUnsigned {
	ulong offset;
}

immutable struct ByteCodeOffset {
	@safe @nogc pure nothrow:

	long offset;

	ByteCodeOffsetUnsigned unsigned() =>
		ByteCodeOffsetUnsigned(cast(ulong) offset);
}

size_t stackEntrySize() =>
	8;
