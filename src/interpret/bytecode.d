module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.extern_ : FunPtr, funPtrEquals, hashFunPtr;
import model.lowModel : LowFunIndex;
import util.col.arr : castImmutable;
import util.col.dict : Dict;
import util.col.fullIndexDict : FullIndexDict;
import util.sym : Sym;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

struct Operation {
	alias Fn = void function(
		ulong* stacksData,
		immutable(Operation)** stacksReturn,
		immutable(Operation)* cur,
	) @system @nogc nothrow;

	@safe @nogc pure nothrow:

	immutable this(immutable Fn a) { fn = a; }
	immutable this(immutable(Operation)* a) { operationPtr = a; }
	immutable this(immutable long a) { long_ = a; }
	immutable this(immutable ulong a) { ulong_ = a; }

	union {
		Fn fn;
		immutable(Operation)* operationPtr;
		long long_;
		ulong ulong_;
	}
}

pure:

//TODO:MOVE
struct FunNameAndPos {
	immutable Sym funName;
	immutable Pos pos;
}

alias FileToFuns = FullIndexDict!(FileIndex, FunNameAndPos[]);

struct ByteCodeSource {
	immutable LowFunIndex fun;
	immutable Pos pos;
}

struct ByteCode {
	@safe @nogc pure nothrow:

	immutable Operations operations;
	immutable FunPtrToOperationPtr funPtrToOperationPtr;
	immutable FileToFuns fileToFuns; // Look up in 'sources' first, then can find the corresponding function here
	immutable ubyte[] text;
	immutable ByteCodeIndex main;

	immutable(Operation[]) byteCode() immutable { return operations.byteCode; }
	immutable(FullIndexDict!(ByteCodeIndex, ByteCodeSource)) sources() immutable { return operations.sources; }
}

alias FunPtrToOperationPtr = immutable Dict!(FunPtr, Operation*, funPtrEquals, hashFunPtr);

struct Operations {
	Operation[] byteCode;
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources; // parallel to byteCode
}
immutable(Operations) castImmutable(Operations a) {
	return immutable Operations(castImmutable(a.byteCode), a.sources);
}

@trusted immutable(Operation*) initialOperationPointer(return scope ref immutable ByteCode a) {
	return a.byteCode.ptr + a.main.index;
}

struct StackOffset {
	// In words.
	// 0 is the top entry on the stack, 1 is the one before that, etc.
	immutable size_t offset;
}
struct StackOffsetBytes {
	@safe @nogc pure nothrow:

	immutable size_t offsetBytes;

	immutable this(immutable size_t o) {
		offsetBytes = o;
		verify(offsetBytes > 0);
	}
}

struct ByteCodeIndex {
	immutable size_t index;
}

immutable(ByteCodeIndex) addByteCodeIndex(immutable ByteCodeIndex a, immutable size_t b) {
	return immutable ByteCodeIndex(a.index + b);
}

immutable(ByteCodeOffset) subtractByteCodeIndex(immutable ByteCodeIndex a, immutable ByteCodeIndex b) {
	return immutable ByteCodeOffset((cast(long) a.index) - (cast(long) b.index));
}

struct ByteCodeOffsetUnsigned {
	immutable ulong offset;
}

struct ByteCodeOffset {
	@safe @nogc pure nothrow:

	immutable long offset;

	immutable(ByteCodeOffsetUnsigned) unsigned() const {
		return immutable ByteCodeOffsetUnsigned(cast(ulong) offset);
	}
}

immutable size_t stackEntrySize = 8;
