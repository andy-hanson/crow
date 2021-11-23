module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.runBytecode : Interpreter;
import model.lowModel : LowFunIndex;
import util.collection.arr : begin, size;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.sym : Sym;
import util.types : Int64, Nat64, safeU64FromI64;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

// For perf, each operation reads the value of the next operation. Otherwise we'd be waiting on reading the poitner.
struct NextOperation {
	immutable(Operation)* operationPtr;
}

struct Operation {
	// TODO: these probaly shouldn't be @safe
	alias Fn = immutable(NextOperation) function(ref Interpreter, immutable(Operation)*) @safe @nogc nothrow;

	@safe @nogc pure nothrow:

	immutable this(immutable Fn a) { fn = a; }
	immutable this(immutable Int64 a) { int64 = a; }
	immutable this(immutable Nat64 a) { nat64 = a; }

	union {
		Fn fn;
		Int64 int64;
		Nat64 nat64;
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
		verify(size(byteCode) == fullIndexDictSize(sources));
	}
}

@trusted immutable(Operation*) initialOperationPointer(ref immutable ByteCode a) {
	return begin(a.byteCode) + a.main.index;
}

struct StackOffset {
	// In words.
	// 0 is the top entry on the stack, 1 is the one before that, etc.
	immutable Nat64 offset;
}
struct StackOffsetBytes {
	@safe @nogc pure nothrow:

	immutable Nat64 offsetBytes;

	immutable this(immutable Nat64 o) {
		offsetBytes = o;
		verify(offsetBytes > immutable Nat64(0));
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
		return immutable ByteCodeOffsetUnsigned(safeU64FromI64(offset));
	}
}

immutable Nat64 stackEntrySize = immutable Nat64(8);

enum ExternOp : ubyte {
	backtrace,
	clockGetTime,
	free,
	getNProcs,
	longjmp,
	malloc,
	memcpy,
	memmove,
	memset,
	pthreadCondattrDestroy,
	pthreadCondattrInit,
	pthreadCondattrSetClock,
	pthreadCondBroadcast,
	pthreadCondDestroy,
	pthreadCondInit,
	pthreadCreate,
	pthreadJoin,
	pthreadMutexattrDestroy,
	pthreadMutexattrInit,
	pthreadMutexDestroy,
	pthreadMutexInit,
	pthreadMutexLock,
	pthreadMutexUnlock,
	schedYield,
	setjmp,
	write,
}

// TODO:KILL (use functions directly)
enum FnOp : ubyte {
	addFloat32,
	addFloat64,
	bitwiseAnd,
	bitwiseNot,
	bitwiseOr,
	bitwiseXor,
	countOnesNat64,
	eqBits,
	eqFloat64,
	float64FromFloat32,
	float64FromInt64,
	float64FromNat64,
	intFromInt16,
	intFromInt32,
	isNanFloat32,
	isNanFloat64,
	lessFloat32,
	lessFloat64,
	lessInt8,
	lessInt16,
	lessInt32,
	lessInt64,
	lessNat,
	mulFloat64,
	subFloat64,
	truncateToInt64FromFloat64,
	unsafeBitShiftLeftNat64,
	unsafeBitShiftRightNat64,
	unsafeDivFloat32,
	unsafeDivFloat64,
	unsafeDivInt64,
	unsafeDivNat64,
	unsafeModNat64,
	// Works for all integral types. (Additional bits ignored)
	wrapAddIntegral,
	wrapMulIntegral,
	wrapSubIntegral,
}
