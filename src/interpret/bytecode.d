module interpret.bytecode;

@safe @nogc nothrow: // not pure

import model.lowModel : LowFunIndex;
import util.alloc.alloc : Alloc;
import util.collection.arr : size;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictSize;
import util.repr : Repr, reprArr, reprHex, reprInt, reprNat, reprRecord, reprStr, reprSym;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : Int16, Nat8, Nat16, Nat32, Nat64, zero;
import util.sourceRange : FileIndex, Pos;
import util.util : verify;

T matchDebugOperationImpure(T)(
	ref immutable DebugOperation a,
	scope T delegate(ref immutable DebugOperation.AssertStackSize) @safe @nogc nothrow cbAssertStackSize,
	scope T delegate(ref immutable DebugOperation.AssertUnreachable) @safe @nogc nothrow cbAssertUnreachable,
) {
	final switch (a.kind_) {
		case DebugOperation.Kind.assertStackSize:
			return cbAssertStackSize(a.assertStackSize_);
		case DebugOperation.Kind.assertUnreachable:
			return cbAssertUnreachable(a.assertUnreachable_);
	}
}

@trusted T matchOperationImpure(T)(
	ref immutable Operation a,
	scope T delegate(ref immutable Operation.Call) @safe @nogc nothrow cbCall,
	scope T delegate(ref immutable Operation.CallFunPtr) @safe @nogc nothrow cbCallFunPtr,
	scope T delegate(ref immutable Operation.Debug) @safe @nogc nothrow cbDebug,
	scope T delegate(ref immutable Operation.Dup) @safe @nogc nothrow cbDup,
	scope T delegate(ref immutable Operation.Extern) @safe @nogc nothrow cbExtern,
	scope T delegate(ref immutable Operation.ExternDynCall) @safe @nogc nothrow cbExternDynCall,
	scope T delegate(ref immutable Operation.Fn) @safe @nogc nothrow cbFn,
	scope T delegate(ref immutable Operation.Jump) @safe @nogc nothrow cbJump,
	scope T delegate(ref immutable Operation.Pack) @safe @nogc nothrow cbPack,
	scope T delegate(ref immutable Operation.PushValue) @safe @nogc nothrow cbPushValue,
	scope T delegate(ref immutable Operation.Read) @safe @nogc nothrow cbRead,
	scope T delegate(ref immutable Operation.Remove) @safe @nogc nothrow cbRemove,
	scope T delegate(ref immutable Operation.Return) @safe @nogc nothrow cbReturn,
	scope T delegate(ref immutable Operation.StackRef) @safe @nogc nothrow cbStackRef,
	scope T delegate(ref immutable Operation.Switch0ToN) @safe @nogc nothrow cbSwitch0ToN,
	scope T delegate(ref immutable Operation.SwitchWithValues) @safe @nogc nothrow cbSwitchWithValues,
	scope T delegate(ref immutable Operation.Write) @safe @nogc nothrow cbWrite,
) {
	final switch (a.kind_) {
		case Operation.Kind.call:
			return cbCall(a.call_);
		case Operation.Kind.callFunPtr:
			return cbCallFunPtr(a.callFunPtr_);
		case Operation.Kind.debug_:
			return cbDebug(a.debug_);
		case Operation.Kind.dup:
			return cbDup(a.dup_);
		case Operation.Kind.extern_:
			return cbExtern(a.extern_);
		case Operation.Kind.externDynCall:
			return cbExternDynCall(a.externDynCall);
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
		case Operation.Kind.switch0ToN:
			return cbSwitch0ToN(a.switch0ToN);
		case Operation.Kind.switchWithValues:
			return cbSwitchWithValues(a.switchWithValues);
		case Operation.Kind.write:
			return cbWrite(a.write_);
	}
}

pure:

private @trusted T matchOperation(T)(
	ref immutable Operation a,
	scope T delegate(ref immutable Operation.Call) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable Operation.CallFunPtr) @safe @nogc pure nothrow cbCallFunPtr,
	scope T delegate(ref immutable Operation.Debug) @safe @nogc pure nothrow cbAssertStackSize,
	scope T delegate(ref immutable Operation.Dup) @safe @nogc pure nothrow cbDup,
	scope T delegate(ref immutable Operation.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable Operation.ExternDynCall) @safe @nogc pure nothrow cbExternDynCall,
	scope T delegate(ref immutable Operation.Fn) @safe @nogc pure nothrow cbFn,
	scope T delegate(ref immutable Operation.Jump) @safe @nogc pure nothrow cbJump,
	scope T delegate(ref immutable Operation.Pack) @safe @nogc pure nothrow cbPack,
	scope T delegate(ref immutable Operation.PushValue) @safe @nogc pure nothrow cbPushValue,
	scope T delegate(ref immutable Operation.Read) @safe @nogc pure nothrow cbRead,
	scope T delegate(ref immutable Operation.Remove) @safe @nogc pure nothrow cbRemove,
	scope T delegate(ref immutable Operation.Return) @safe @nogc pure nothrow cbReturn,
	scope T delegate(ref immutable Operation.StackRef) @safe @nogc pure nothrow cbStackRef,
	scope T delegate(ref immutable Operation.Switch0ToN) @safe @nogc pure nothrow cbSwitch0ToN,
	scope T delegate(ref immutable Operation.SwitchWithValues) @safe @nogc pure nothrow cbSwitchWithValues,
	scope T delegate(ref immutable Operation.Write) @safe @nogc pure nothrow cbWrite,
) {
	final switch (a.kind_) {
		case Operation.Kind.call:
			return cbCall(a.call_);
		case Operation.Kind.callFunPtr:
			return cbCallFunPtr(a.callFunPtr_);
		case Operation.Kind.debug_:
			return cbAssertStackSize(a.debug_);
		case Operation.Kind.dup:
			return cbDup(a.dup_);
		case Operation.Kind.extern_:
			return cbExtern(a.extern_);
		case Operation.Kind.externDynCall:
			return cbExternDynCall(a.externDynCall);
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
		case Operation.Kind.switch0ToN:
			return cbSwitch0ToN(a.switch0ToN);
		case Operation.Kind.switchWithValues:
			return cbSwitchWithValues(a.switchWithValues);
		case Operation.Kind.write:
			return cbWrite(a.write_);
	}
}

immutable(Repr) reprOperation(ref Alloc alloc, ref immutable Operation a) {
	return matchOperation(
		a,
		(ref immutable Operation.Call it) =>
			reprRecord(alloc, "call", [reprNat(it.address.index), reprNat(it.parametersSize)]),
		(ref immutable Operation.CallFunPtr it) =>
			reprRecord(alloc, "call-ptr", [reprNat(it.parametersSize)]),
		(ref immutable Operation.Debug it) =>
			reprRecord(alloc, "debug", [reprDebugOperation(alloc, it.debugOperation)]),
		(ref immutable Operation.Dup it) =>
			reprRecord(alloc, "dup", [
				reprNat(it.offsetBytes.offsetBytes),
				reprNat(it.sizeBytes)]),
		(ref immutable Operation.Extern it) =>
			reprRecord(alloc, "extern", [reprStr(strOfExternOp(it.op))]),
		(ref immutable Operation.ExternDynCall it) =>
			reprRecord(alloc, "extern-dyn", [
				reprSym(it.name),
				reprSym(symOfDynCallType(it.returnType)),
				reprArr(alloc, it.parameterTypes, (ref immutable DynCallType t) =>
					reprSym(symOfDynCallType(t)))]),
		(ref immutable Operation.Fn it) =>
			reprRecord(alloc, "fn", [reprStr(strOfFnOp(it.fnOp))]),
		(ref immutable Operation.Jump it) =>
			reprRecord(alloc, "jump", [reprInt(it.offset.offset)]),
		(ref immutable Operation.Pack it) =>
			reprRecord(alloc, "pack", [
				reprNat(it.inEntries),
				reprNat(it.outEntries),
				reprArr(alloc, it.fields, (ref immutable Operation.Pack.Field field) =>
					reprRecord(alloc, "field", [
						reprNat(field.inOffset),
						reprNat(field.outOffset),
						reprNat(field.size)]))]),
		(ref immutable Operation.PushValue it) =>
			reprRecord(alloc, "push-val", [reprHex(it.value)]),
		(ref immutable Operation.Read it) =>
			reprRecord(alloc, "read", [reprNat(it.offset), reprNat(it.size)]),
		(ref immutable Operation.Remove it) =>
			reprRecord(alloc, "remove", [reprNat(it.offset.offset), reprNat(it.nEntries)]),
		(ref immutable Operation.Return it) =>
			reprSym("return"),
		(ref immutable Operation.StackRef it) =>
			reprRecord(alloc, "stack-ref", [reprNat(it.offset.offset)]),
		(ref immutable Operation.Switch0ToN it) =>
			// TODO: more detail
			reprSym("switch-n"),
		(ref immutable Operation.SwitchWithValues it) =>
			// TODO: more detail
			reprSym("switch-v"),
		(ref immutable Operation.Write it) =>
			reprRecord(alloc, "write", [reprNat(it.offset), reprNat(it.size)]));
}

private immutable(Sym) symOfDynCallType(immutable DynCallType a) {
	return shortSymAlphaLiteral(() {
		final switch (a) {
			case DynCallType.bool_:
				return "bool";
			case DynCallType.char_:
				return "char";
			case DynCallType.int8:
				return "int-8";
			case DynCallType.int16:
				return "int-16";
			case DynCallType.int32:
				return "int-32";
			case DynCallType.int64:
				return "int-64";
			case DynCallType.float32:
				return "float-32";
			case DynCallType.float64:
				return "float-64";
			case DynCallType.nat8:
				return "nat-8";
			case DynCallType.nat16:
				return "nat-16";
			case DynCallType.nat32:
				return "nat-32";
			case DynCallType.nat64:
				return "nat-64";
			case DynCallType.pointer:
				return "pointer";
			case DynCallType.void_:
				return "void";
		}
	}());
}

private immutable(Repr) reprDebugOperation(ref Alloc alloc, ref immutable DebugOperation a) {
	return matchDebugOperation(
		a,
		(ref immutable DebugOperation.AssertStackSize it) =>
			reprRecord(alloc, "assertstck", [reprNat(it.stackSize)]),
		(ref immutable DebugOperation.AssertUnreachable it) =>
			reprSym("unreachabl"));
}

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

	immutable ubyte[] byteCode;
	immutable FullIndexDict!(ByteCodeIndex, ByteCodeSource) sources; // parallel to byteCode
	immutable FileToFuns fileToFuns; // Look up in 'sources' first, then can find the corresponding function here
	immutable ubyte[] text;
	immutable ByteCodeIndex main;

	immutable this(
		immutable ubyte[] bc,
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

struct StackOffset {
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

struct DebugOperation {
	@safe @nogc pure nothrow:

	struct AssertStackSize {
		immutable Nat16 stackSize;
	}

	struct AssertUnreachable {}

	immutable this(immutable AssertStackSize a) { kind_ = Kind.assertStackSize; assertStackSize_ = a; }
	immutable this(immutable AssertUnreachable a) { kind_ = Kind.assertUnreachable; assertUnreachable_ = a; }

	private:
	enum Kind {
		assertStackSize,
		assertUnreachable,
	}
	immutable Kind kind_;
	union {
		immutable AssertStackSize assertStackSize_;
		immutable AssertUnreachable assertUnreachable_;
	}
}

private T matchDebugOperation(T)(
	ref immutable DebugOperation a,
	scope T delegate(ref immutable DebugOperation.AssertStackSize) @safe @nogc pure nothrow cbAssertStackSize,
	scope T delegate(ref immutable DebugOperation.AssertUnreachable) @safe @nogc pure nothrow cbAssertUnreachable,
) {
	final switch (a.kind_) {
		case DebugOperation.Kind.assertStackSize:
			return cbAssertStackSize(a.assertStackSize_);
		case DebugOperation.Kind.assertUnreachable:
			return cbAssertUnreachable(a.assertUnreachable_);
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

struct Operation {
	@safe @nogc pure nothrow:

	// pushes current address onto the function stack and goes to the new function's address
	struct Call {
		immutable ByteCodeIndex address;
		immutable Nat8 parametersSize; // For debugging -- how big the parameters are (in stack entries)
	}

	// Removes a fun-ptr from the stack at the given offset and calls that
	struct CallFunPtr {
		immutable Nat8 parametersSize; // Need this to get the fun-ptr
	}

	struct Debug {
		immutable DebugOperation debugOperation;
	}

	// Gets a stack entry and duplicates it on the top of the stack.
	struct Dup {
		@safe @nogc pure nothrow:

		immutable StackOffsetBytes offsetBytes;
		immutable Nat16 sizeBytes;

		immutable this(immutable StackOffsetBytes so, immutable Nat16 sb) {
			offsetBytes = so;
			sizeBytes = sb;
			verify(sizeBytes > immutable Nat16(0));
		}
	}

	struct Extern {
		immutable ExternOp op;
	}

	struct ExternDynCall {
		immutable Sym name;
		immutable DynCallType returnType;
		immutable DynCallType[] parameterTypes;
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
		struct Field {
			immutable Nat16 inOffset;
			immutable Nat16 outOffset;
			immutable Nat16 size;
		}

		immutable Nat8 inEntries;
		immutable Nat8 outEntries;
		immutable Field[] fields;
	}

	// Push the value onto the stack.
	struct PushValue {
		immutable Nat64 value;
	}

	// Pop a pointer off the stack, add 'offset', read 'size' bytes, and push to the stack.
	struct Read {
		immutable Nat16 offset;
		immutable Nat16 size;
	}

	// Remove entries from the stack, shifting higher entries down.
	struct Remove {
		immutable StackOffset offset;
		immutable Nat8 nEntries;
	}

	// Pop an address from the function stack and jump to there.
	struct Return {}

	struct StackRef {
		immutable StackOffset offset;
	}

	// Pop a number off the stack, look it up in 'offsets', and jump forward that much.
	// Offsets are relative to the bytecode index of the first offset.
	// A 0th offset is needed because otherwise there's no way to know how many cases there are.
	struct Switch0ToN {
		// The reader can't return the offsets since it doesn't have a length
		immutable ByteCodeOffsetUnsigned[] offsets;
	}

	struct SwitchWithValues {
		immutable Nat64[] values;
		immutable ByteCodeOffsetUnsigned[] offsets;
	}

	// Pop divRoundUp(size, stackEntrySize) stack entries, then pop a pointer, then write to ptr + offset
	struct Write {
		@safe @nogc pure nothrow:

		immutable Nat16 offset;
		immutable Nat16 size;

		immutable this(immutable Nat16 o, immutable Nat16 s) {
			offset = o;
			size = s;
			verify(!zero(size));
		}
	}

	private:
	enum Kind {
		call,
		callFunPtr,
		debug_,
		dup,
		extern_,
		externDynCall,
		fn,
		jump,
		pack,
		pushValue,
		read,
		remove,
		return_,
		stackRef_,
		switch0ToN,
		switchWithValues,
		write,
	}
	immutable Kind kind_;
	union {
		immutable Call call_;
		immutable CallFunPtr callFunPtr_;
		immutable Debug debug_;
		immutable Dup dup_;
		immutable Extern extern_;
		immutable ExternDynCall externDynCall;
		immutable Fn fn_;
		immutable Jump jump_;
		immutable Pack pack_;
		immutable PushValue pushValue_;
		immutable Read read_;
		immutable Remove remove_;
		immutable Return return_;
		immutable StackRef stackRef_;
		immutable Switch0ToN switch0ToN;
		immutable SwitchWithValues switchWithValues;
		immutable Write write_;
	}

	public:
	immutable this(immutable Call a) { kind_ = Kind.call; call_ = a; }
	immutable this(immutable CallFunPtr a) { kind_ = Kind.callFunPtr; callFunPtr_ = a; }
	immutable this(immutable Debug a) { kind_ = Kind.debug_; debug_ = a; }
	immutable this(immutable Dup a) { kind_ = Kind.dup; dup_ = a; }
	immutable this(immutable Extern a) { kind_ = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable ExternDynCall a) { kind_ = Kind.externDynCall; externDynCall = a; }
	immutable this(immutable Fn a) { kind_ = Kind.fn; fn_ = a; }
	immutable this(immutable Jump a) { kind_ = Kind.jump; jump_ = a; }
	@trusted immutable this(immutable Pack a) { kind_ = Kind.pack; pack_ = a; }
	immutable this(immutable PushValue a) { kind_ = Kind.pushValue; pushValue_ = a; }
	immutable this(immutable Read a) { kind_ = Kind.read; read_ = a; }
	immutable this(immutable Remove a) { kind_ = Kind.remove; remove_ = a; }
	immutable this(immutable Return a) { kind_ = Kind.return_; return_ = a; }
	immutable this(immutable StackRef a) { kind_ = Kind.stackRef_; stackRef_ = a; }
	@trusted immutable this(immutable Switch0ToN a) { kind_ = Kind.switch0ToN; switch0ToN = a; }
	@trusted immutable this(immutable SwitchWithValues a) { kind_ = Kind.switchWithValues; switchWithValues = a; }
	immutable this(immutable Write a) { kind_ = Kind.write; write_ = a; }
}

immutable(bool) isCall(ref immutable Operation op) {
	return op.kind_ == Operation.Kind.call;
}

immutable(Operation.Call) asCall(ref immutable Operation op) {
	verify(isCall(op));
	return op.call_;
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

private immutable(string) strOfExternOp(immutable ExternOp op) {
	final switch (op) {
		case ExternOp.backtrace:
			return "backtrace";
		case ExternOp.clockGetTime:
			return "clock_gettime";
		case ExternOp.free:
			return "free";
		case ExternOp.getNProcs:
			return "get_nprocs";
		case ExternOp.longjmp:
			return "longjmp";
		case ExternOp.malloc:
			return "malloc";
		case ExternOp.memcpy:
			return "memcpy";
		case ExternOp.memmove:
			return "memmove";
		case ExternOp.memset:
			return "memset";
		case ExternOp.pthreadCondattrDestroy:
			return "pthread_condattr_destroy";
		case ExternOp.pthreadCondattrInit:
			return "pthread_condattr_init";
		case ExternOp.pthreadCondattrSetClock:
			return "pthread_condattr_setclock";
		case ExternOp.pthreadCondBroadcast:
			return "pthread_cond_broadcast";
		case ExternOp.pthreadCondDestroy:
			return "pthread_cond_destroy";
		case ExternOp.pthreadCondInit:
			return "pthread_cond_init";
		case ExternOp.pthreadCreate:
			return "pthread_create";
		case ExternOp.pthreadJoin:
			return "pthread_join";
		case ExternOp.pthreadMutexattrDestroy:
			return "pthread_mutexattr_destroy";
		case ExternOp.pthreadMutexattrInit:
			return "pthread_mutexattr_init";
		case ExternOp.pthreadMutexDestroy:
			return "pthread_mutex_destroy";
		case ExternOp.pthreadMutexInit:
			return "pthread_mutex_init";
		case ExternOp.pthreadMutexLock:
			return "pthread_mutex_lock";
		case ExternOp.pthreadMutexUnlock:
			return "pthread_mutex_unlock";
		case ExternOp.schedYield:
			return "sched_yield";
		case ExternOp.setjmp:
			return "setjmp";
		case ExternOp.write:
			return "write";
	}
}

private immutable(string) strOfFnOp(immutable FnOp fnOp) {
	final switch (fnOp) {
		case FnOp.addFloat32:
			return "add-float-32";
		case FnOp.addFloat64:
			return "add-float-64";
		case FnOp.bitwiseNot:
			return "bitwise-not";
		case FnOp.bitwiseAnd:
			return "bitwise-and";
		case FnOp.bitwiseOr:
			return "bitwise-or";
		case FnOp.bitwiseXor:
			return "bitwise-xor";
		case FnOp.countOnesNat64:
			return "count-ones (nat-64)";
		case FnOp.eqBits:
			return "== (integrals / pointers)";
		case FnOp.eqFloat64:
			return "== (float-64)";
		case FnOp.float64FromFloat32:
			return "float-64-from-float-32";
		case FnOp.float64FromInt64:
			return "float-64-from-int-64";
		case FnOp.float64FromNat64:
			return "float-64-from-nat-64";
		case FnOp.intFromInt16:
			return "to-int (from int-16)";
		case FnOp.intFromInt32:
			return "to-int (from int-32)";
		case FnOp.isNanFloat32:
			return "nan? (float-32)";
		case FnOp.isNanFloat64:
			return "nan? (float-64)";
		case FnOp.lessFloat32:
			return "< (float-32)";
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
		case FnOp.mulFloat64:
			return "* (float-64)";
		case FnOp.subFloat64:
			return "- (float-64)";
		case FnOp.truncateToInt64FromFloat64:
			return "truncate-to-int-64-from-float-64";
		case FnOp.unsafeBitShiftLeftNat64:
			return "unsafe-bit-shift-left (nat-64)";
		case FnOp.unsafeBitShiftRightNat64:
			return "unsafe-bit-shift-right (nat-64)";
		case FnOp.unsafeDivFloat32:
			return "unsafe-div (float-32)";
		case FnOp.unsafeDivFloat64:
			return "unsafe-div (float-64)";
		case FnOp.unsafeDivInt64:
			return "unsafe-div (int-64)";
		case FnOp.unsafeDivNat64:
			return "unsafe-div (nat-64)";
		case FnOp.unsafeModNat64:
			return "unsafe-mod (nat-64)";
		case FnOp.wrapAddIntegral:
			return "wrap-add-integral";
		case FnOp.wrapMulIntegral:
			return "wrap-mul-integral";
		case FnOp.wrapSubIntegral:
			return "wrap-sub-integral";
	}
}
