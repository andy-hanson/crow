module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.stacks : Stacks;
import model.lowModel : LowFunIndex;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.sym : Sym;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

struct Operation {
	alias Fn = void function(Stacks, immutable(Operation)*) @system @nogc nothrow;

	@safe @nogc pure nothrow:

	immutable this(immutable Fn a) { fn = a; }
	immutable this(immutable long a) { long_ = a; }
	immutable this(immutable ulong a) { ulong_ = a; }

	union {
		Fn fn;
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

	Operation[] byteCode;
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources; // parallel to byteCode
	immutable FileToFuns fileToFuns; // Look up in 'sources' first, then can find the corresponding function here
	immutable ubyte[] text;
	immutable ByteCodeIndex main;

	immutable this(
		immutable Operation[] bc,
		immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) s,
		immutable FileToFuns ff,
		immutable ubyte[] t,
		immutable ByteCodeIndex m,
	) {
		byteCode = bc;
		sources = s;
		fileToFuns = ff;
		text = t;
		main = m;
		verify(byteCode.length == fullIndexDictSize(sources));
	}
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

enum ExternOp : ubyte { backtrace, longjmp, setjmp }
