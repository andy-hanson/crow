module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.runBytecode : Interpreter;
import model.lowModel : LowFunIndex;
import util.collection.arr : begin, size;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.sym : Sym;
import util.types : Int16, Nat8, Nat16, Nat32;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

// This returns another Operation
alias Operation = immutable(void*) function(ref Interpreter);

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
	return begin(a.byteCode) + a.main.index.raw();
}

struct StackOffset {
	// In words.
	// 0 is the top entry on the stack, 1 is the one before that, etc.
	immutable Nat8 offset;
}
struct StackOffsetBytes {
	@safe @nogc pure nothrow:

	immutable Nat16 offsetBytes;

	immutable this(immutable Nat16 o) {
		offsetBytes = o;
		verify(offsetBytes > immutable Nat16(0));
	}
}

struct ByteCodeIndex {
	immutable Nat32 index;
}

immutable(ByteCodeIndex) addByteCodeIndex(immutable ByteCodeIndex a, immutable Nat32 b) {
	return immutable ByteCodeIndex(a.index + b);
}

immutable(ByteCodeOffset) subtractByteCodeIndex(immutable ByteCodeIndex a, immutable ByteCodeIndex b) {
	return immutable ByteCodeOffset((a.index.toInt32() - b.index.toInt32()).to16());
}

struct ByteCodeOffsetUnsigned {
	immutable Nat16 offset;
}

struct ByteCodeOffset {
	@safe @nogc pure nothrow:

	immutable Int16 offset;

	immutable(ByteCodeOffsetUnsigned) unsigned() const {
		return immutable ByteCodeOffsetUnsigned(offset.unsigned());
	}
}

immutable Nat16 stackEntrySize = immutable Nat16(8);

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
