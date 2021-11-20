module interpret.bytecode;

@safe @nogc nothrow: // not pure

import interpret.runBytecode : Interpreter;
import model.lowModel : LowFunIndex;
import util.collection.arr : size;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.sym : Sym;
import util.types : Int16, Nat8, Nat16, Nat32;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

// This returns another Operation!Extern
alias Operation(Extern) = immutable(void*) function(ref Interpreter!Extern);

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

struct ByteCode(Extern) {
	@safe @nogc pure nothrow:

	Operation!Extern[] byteCode;
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources; // parallel to byteCode
	immutable FileToFuns fileToFuns; // Look up in 'sources' first, then can find the corresponding function here
	immutable ubyte[] text;
	immutable ByteCodeIndex main;

	immutable this(
		immutable Operation!Extern[] bc,
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
		verify(size!(immutable Operation!Extern)(byteCode) == fullIndexDictSize(sources));
	}
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

// These should all fit in a single stack entry (except 'void')
enum DynCallType : ubyte {
	bool_,
	char_,
	int8,
	int16,
	int32,
	int64,
	float32,
	float64,
	nat8,
	nat16,
	nat32,
	nat64,
	pointer,
	void_,
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

// Used by clockGetTime
struct TimeSpec {
	long tv_sec;
	long tv_nsec;
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
