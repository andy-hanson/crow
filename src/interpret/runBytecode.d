module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import frontend.showDiag : ShowDiagOptions;
import interpret.applyFn : applyFn;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	ExternOp,
	FnOp,
	initialOperationPointer,
	Operation,
	StackOffset;
import interpret.debugging : writeFunName;
import interpret.extern_ : DynCallType, Extern, TimeSpec;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowFunSource, LowProgram, matchLowFunSource;
import model.typeLayout : PackField;
import util.alloc.alloc : TempAlloc;
import util.alloc.rangeAlloc : RangeAlloc;
import util.dbg : log;
import util.collection.arr : at, begin, last, ptrAt, sizeNat;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.collection.globalAllocatedStack :
	asTempArr,
	begin,
	clearStack,
	end,
	GlobalAllocatedStack,
	isEmpty,
	peek,
	pop,
	popN,
	push,
	pushUninitialized,
	reduceStackSize,
	remove,
	setToArr,
	stackRef,
	stackSize,
	toArr;
import util.collection.str : SafeCStr;
import util.dbg : Debug;
import util.memory : allocate, memcpy, memmove, memset, overwriteMemory;
import util.opt : has;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.repr : writeReprNoNewline;
import util.sourceRange : FileAndPos;
import util.sym : Sym;
import util.types :
	incr,
	Int16,
	i32OfU64Bits,
	Nat8,
	Nat16,
	Nat32,
	Nat64,
	safeIntFromNat64,
	safeSizeTFromU64,
	safeU32FromI32;
import util.util : divRoundUp, drop, min, unreachable, verify;
import util.writer : finishWriter, Writer, writeChar, writeHex, writeStatic;

@trusted immutable(int) runBytecode(
	scope ref Debug dbg,
	ref Perf perf,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	scope ref Extern extern_,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	scope immutable SafeCStr[] allArgs,
) {
	Interpreter interpreter = Interpreter(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(tempAlloc),
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe_const(allPaths),
		ptrTrustMe(filesInfo));
	push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
	// These need to be CStrs
	push(interpreter.dataStack, immutable Nat64(cast(immutable ulong) begin(allArgs)));
	return withMeasureNoAlloc(perf, PerfMeasure.run, () =>
		runBytecodeInner(dbg, perf, tempAlloc, allPaths, interpreter));
}

private @trusted immutable(int) runBytecodeInner(
	scope ref Debug dbg,
	ref Perf perf,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	ref Interpreter interpreter,
) {
	Operation op = nextOperation(interpreter);
	do {
		op = cast(Operation) op(interpreter);
		op = cast(Operation) op(interpreter);
		op = cast(Operation) op(interpreter);
		op = cast(Operation) op(interpreter);
	} while (op != &opStopInterpretation);

	immutable Nat64 returnCode = pop(interpreter.dataStack);
	verify(isEmpty(interpreter.dataStack));
	return safeIntFromNat64(returnCode);
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 64);
private alias ReturnStack = GlobalAllocatedStack!(immutable(Operation)*, 1024 * 4);

struct Interpreter {
	@safe @nogc nothrow: // not pure

	@disable this(ref const Interpreter);

	@trusted this(
		Ptr!Debug dbg,
		Ptr!TempAlloc ta,
		Ptr!Extern e,
		immutable Ptr!LowProgram p,
		immutable Ptr!ByteCode b,
		const Ptr!AllPaths ap,
		immutable Ptr!FilesInfo f,
	) {
		debugPtr = dbg;
		tempAllocPtr = ta;
		externPtr = e;
		lowProgramPtr = p;
		byteCodePtr = b;
		allPathsPtr = ap;
		filesInfoPtr = f;
		nextOperation = initialOperationPointer(byteCode);
		dataStack = DataStack(true);
		returnStack = ReturnStack(true);
	}

	Ptr!Debug debugPtr;
	//TODO:KILL
	Ptr!TempAlloc tempAllocPtr;
	Ptr!Extern externPtr;
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!ByteCode byteCodePtr;
	const Ptr!AllPaths allPathsPtr;
	immutable Ptr!FilesInfo filesInfoPtr;
	immutable(Operation)* nextOperation;
	DataStack dataStack;
	ReturnStack returnStack;
	// WARN: if adding any new mutable state here, make sure 'longjmp' still restores it

	ref Debug dbg() return scope {
		return debugPtr.deref();
	}
	//TODO:KILL
	ref TempAlloc tempAlloc() return scope pure {
		return tempAllocPtr.deref();
	}
	ref Extern extern_() return scope pure {
		return externPtr.deref();
	}
	ref immutable(LowProgram) lowProgram() const return scope pure {
		return lowProgramPtr.deref();
	}
	ref immutable(ByteCode) byteCode() const return scope pure {
		return byteCodePtr.deref();
	}
	ref const(AllPaths) allPaths() const return scope pure {
		return allPathsPtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const return scope pure {
		return filesInfoPtr.deref();
	}
}

// WARN: Does not restore data. Just mean for setjmp/longjmp.
private struct InterpreterRestore {
	// This is the stack sizes and byte code index to be restored by longjmp
	immutable ByteCodeIndex nextByteCodeIndex;
	immutable Nat32 dataStackSize;
	immutable Operation*[] restoreReturnStack;
}

private immutable(InterpreterRestore*) createInterpreterRestore(ref Interpreter a) {
	immutable InterpreterRestore value = immutable InterpreterRestore(
		nextByteCodeIndex(a),
		stackSize(a.dataStack),
		toArr(a.tempAlloc, a.returnStack));
	return allocate(a.tempAlloc, value).rawPtr();
}

private void applyInterpreterRestore(ref Interpreter a, ref immutable InterpreterRestore restore) {
	setNextByteCodeIndex(a, restore.nextByteCodeIndex);
	reduceStackSize(a.dataStack, restore.dataStackSize.raw());
	setToArr(a.returnStack, restore.restoreReturnStack);
}

@trusted void reset(ref Interpreter a) {
	a.nextOperation = initialOperationPointer(a.byteCode);
	clearStack(a.dataStack);
	clearStack(a.returnStack);
}

private void showStack(scope ref Writer writer, ref const Interpreter a) {
	immutable Nat64[] stack = asTempArr(a.dataStack);
	showDataArr(writer, stack);
}

@trusted void showDataArr(scope ref Writer writer, scope ref immutable Nat64[] values) {
	writeStatic(writer, "data: ");
	foreach (immutable Nat64 value; values) {
		writeChar(writer, ' ');
		writeHex(writer, value.raw());
	}
	writeChar(writer, '\n');
}

private @trusted void showReturnStack(scope ref Writer writer, ref const Interpreter a) {
	writeStatic(writer, "call stack:");
	foreach (immutable Operation* ptr; asTempArr(a.returnStack)) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, a, a.nextOperation);
}

private void writeByteCodeSource(
	scope ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	immutable ByteCodeSource source,
) {
	writeFunName(writer, lowProgram, source.fun);
	matchLowFunSource!void(
		fullIndexDictGet(lowProgram.allFuns, source.fun).source,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(concreteFunRange(it.deref()).fileIndex, source.pos);
			writeFileAndPos(writer, allPaths, showDiagOptions, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {});
}

private void writeFunNameAtIndex(
	ref Writer writer,
	ref const Interpreter interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, interpreter.lowProgram, byteCodeSourceAtIndex(interpreter, index).fun);
}

private void writeFunNameAtByteCodePtr(
	ref Writer writer,
	ref const Interpreter interpreter,
	immutable Operation* ptr,
) {
	writeFunNameAtIndex(writer, interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

private immutable(ByteCodeSource) byteCodeSourceAtIndex(
	ref const Interpreter a,
	immutable ByteCodeIndex index,
) {
	return fullIndexDictGet(a.byteCode.sources, index);
}

private immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(
	ref const Interpreter a,
	immutable Operation* ptr,
) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(ref const Interpreter a) {
	return byteCodeIndexOfPtr(a, a.nextOperation);
}

//TODO:KILL (use ptrs directly instead of ByteCodeIndex)
private void setNextByteCodeIndex(ref Interpreter a, immutable ByteCodeIndex index) {
	a.nextOperation = ptrAt!(immutable Operation)(a.byteCode.byteCode, index.index.raw()).rawPtr();
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(
	ref const Interpreter a,
	immutable Operation* ptr,
) {
	return immutable ByteCodeIndex((immutable Nat64(ptr - begin(a.byteCode.byteCode))).to32());
}

private immutable(ByteCodeSource) nextSource(ref const Interpreter a) {
	return byteCodeSourceAtByteCodePtr(a, a.nextOperation);
}

private immutable(Operation) getNextOperationAndDebug(ref Interpreter a) {
	immutable ByteCodeSource source = nextSource(a);

	{
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		showStack(writer, a);
		showReturnStack(writer, a);
		log(a.dbg, finishWriter(writer));
	}

	immutable Operation operation = nextOperation(a);

	{
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		writeStatic(writer, "STEP: ");
		immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
		writeByteCodeSource(writer, a.allPaths, showDiagOptions, a.lowProgram, a.filesInfo, source);
		//writeChar(writer, ' ');
		//writeReprNoNewline(writer, reprOperation(dbgAlloc, operation));
		//writeChar(writer, '\n');
		log(a.dbg, finishWriter(writer));
	}

	return operation;
}

immutable(Operation) opAssertUnreachable(ref Interpreter a) {
	return unreachable!(immutable Operation)();
}

immutable(Operation) opRemove(ref Interpreter a) {
	immutable StackOffset offset = readStackOffset(a);
	immutable Nat8 nEntries = readNat8(a);
	remove(a.dataStack, offset.offset, nEntries);
	return nextOperation(a);
}

immutable(Operation) opReturn(ref Interpreter a) {
	if (isEmpty(a.returnStack))
		return &opStopInterpretation;
	else {
		a.nextOperation = pop(a.returnStack);
		return nextOperation(a);
	}
}

immutable(Operation) opStopInterpretation(ref Interpreter a) {
	return &opStopInterpretation;
}

@trusted immutable(Operation) opSwitch0ToN(ref Interpreter a) {
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(a);
	immutable Nat64 value = pop(a.dataStack);
	immutable ByteCodeOffsetUnsigned offset = at(offsets, safeSizeTFromU64(value.raw()));
	a.nextOperation += offset.offset.raw();
	return nextOperation(a);
}

immutable(Operation) opStackRef(ref Interpreter a) {
	immutable StackOffset offset = readStackOffset(a);
	push(a.dataStack, immutable Nat64(cast(immutable ulong) stackRef(a.dataStack, offset.offset)));
	return nextOperation(a);
}

@trusted immutable(Operation) opRead(ref Interpreter a) {
	immutable Nat16 offset = readNat16(a);
	immutable Nat16 size = readNat16(a);
	immutable ubyte* ptr = cast(immutable ubyte*) pop(a.dataStack).raw();
	readNoCheck(a.dataStack, ptr + offset.raw(), size.raw());
	return nextOperation(a);
}

@trusted immutable(Operation) opWrite(ref Interpreter a) {
	immutable Nat16 offset = readNat16(a);
	immutable Nat16 size = readNat16(a);
	if (size < immutable Nat16(8)) { //TODO:UNNECESSARY?
		verify(size != immutable Nat16(0));
		immutable Nat64 value = pop(a.dataStack);
		ubyte* ptr = cast(ubyte*) pop(a.dataStack).raw();
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		immutable Nat16 sizeWords = divRoundUp(size, immutable Nat16(8));
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords.to8()).raw();
		ubyte* src = cast(ubyte*) (end(a.dataStack) - sizeWords.raw());
		ubyte* dest = destWithoutOffset + offset.raw();
		memcpy(dest, src, size.raw());
		popN(a.dataStack, incr(sizeWords).to8());
	}
	return nextOperation(a);
}

private @trusted void writePartialBytes(ubyte* ptr, immutable ulong value, immutable ushort size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			*(cast(ubyte*) ptr) = cast(immutable ubyte) value;
			break;
		case 2:
			*(cast(ushort*) ptr) = cast(immutable ushort) value;
			break;
		case 4:
			*(cast(uint*) ptr) = cast(immutable uint) value;
			break;
		default:
			unreachable!void();
			break;
	}
}

immutable(Operation) opCall(ref Interpreter a) {
	immutable ByteCodeIndex address = immutable ByteCodeIndex(readNat32(a));
	return callCommon(a, address);
}

immutable(Operation) opCallFunPtr(ref Interpreter a) {
	immutable Nat8 parametersSize = readNat8(a);
	//TODO: handle a real function pointer being here?
	immutable ByteCodeIndex address = immutable ByteCodeIndex(
		removeAtStackOffset(a, immutable StackOffset(parametersSize)).to32());
	return callCommon(a, address);
}

private immutable(Operation) callCommon(
	ref Interpreter a,
	immutable ByteCodeIndex address,
) {
	push(a.returnStack, a.nextOperation);
	setNextByteCodeIndex(a, address);
	return nextOperation(a);
}

private immutable(Nat64) removeAtStackOffset(ref Interpreter a, immutable StackOffset offset) {
	return remove(a.dataStack, offset.offset);
}

//TODO: not @trusted
@trusted immutable(Operation) opExtern(ref Interpreter a) {
	immutable ExternOp op = cast(ExternOp) readNat8(a).raw();
	final switch (op) {
		case ExternOp.backtrace:
			immutable int size = cast(int) pop(a.dataStack).to32().raw();
			void** array = cast(void**) pop(a.dataStack).raw();
			immutable size_t res = backtrace(a, array, safeU32FromI32(size));
			verify(res <= int.max);
			push(a.dataStack, immutable Nat64(res));
			break;
		case ExternOp.clockGetTime:
			Ptr!TimeSpec timespecPtr = Ptr!TimeSpec(cast(TimeSpec*) pop(a.dataStack).raw());
			immutable int clockId = i32OfU64Bits(pop(a.dataStack).raw());
			push(a.dataStack, immutable Nat64(cast(immutable ulong) a.extern_.clockGetTime(clockId, timespecPtr)));
			break;
		case ExternOp.free:
			a.extern_.free(cast(ubyte*) pop(a.dataStack).raw());
			break;
		case ExternOp.getNProcs:
			push(a.dataStack, immutable Nat64(1));
			break;
		case ExternOp.longjmp:
			immutable Nat64 val = pop(a.dataStack); // TODO: verify this is int32?
			const JmpBufTag* jmpBufPtr = cast(const JmpBufTag*) pop(a.dataStack).raw();
			applyInterpreterRestore(a, **jmpBufPtr);
			//TODO: freeInterpreterRestore
			push(a.dataStack, val);
			break;
		case ExternOp.malloc:
			immutable ulong nBytes = safeSizeTFromU64(pop(a.dataStack).raw());
			push(a.dataStack, immutable Nat64(cast(immutable ulong) a.extern_.malloc(nBytes)));
			break;
		case ExternOp.memcpy:
		case ExternOp.memmove:
			immutable size_t size = safeSizeTFromU64(pop(a.dataStack).raw());
			const ubyte* src = cast(ubyte*) pop(a.dataStack).raw();
			ubyte* dest = cast(ubyte*) pop(a.dataStack).raw();
			ubyte* res = memmove(dest, src, size);
			push(a.dataStack, immutable Nat64(cast(immutable ulong) res));
			break;
		case ExternOp.memset:
			immutable size_t size = safeSizeTFromU64(pop(a.dataStack).raw());
			immutable ubyte value = pop(a.dataStack).to8().raw();
			ubyte* begin = cast(ubyte*) pop(a.dataStack).raw();
			ubyte* res = memset(begin, value, size);
			push(a.dataStack, immutable Nat64(cast(immutable ulong) res));
			break;
		case ExternOp.pthreadCreate:
			unreachable!void();
			break;
		case ExternOp.pthreadJoin:
			unreachable!void();
			break;
		case ExternOp.pthreadCondattrDestroy:
		case ExternOp.pthreadCondattrInit:
		case ExternOp.pthreadCondBroadcast:
		case ExternOp.pthreadCondDestroy:
		case ExternOp.pthreadMutexattrDestroy:
		case ExternOp.pthreadMutexattrInit:
		case ExternOp.pthreadMutexDestroy:
		case ExternOp.pthreadMutexLock:
		case ExternOp.pthreadMutexUnlock:
			pop(a.dataStack);
			push(a.dataStack, immutable Nat64(0));
			break;
		case ExternOp.pthreadCondattrSetClock:
		case ExternOp.pthreadCondInit:
		case ExternOp.pthreadMutexInit:
			pop(a.dataStack);
			pop(a.dataStack);
			push(a.dataStack, immutable Nat64(0));
			break;
		case ExternOp.schedYield:
			push(a.dataStack, immutable Nat64(0));
			break;
		case ExternOp.setjmp:
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack).raw();
			overwriteMemory(jmpBufPtr, createInterpreterRestore(a));
			push(a.dataStack, immutable Nat64(0));
			break;
		case ExternOp.write:
			immutable size_t nBytes = safeSizeTFromU64(pop(a.dataStack).raw());
			immutable char* buf = cast(immutable char*) pop(a.dataStack).raw();
			immutable int fd = i32OfU64Bits(pop(a.dataStack).raw());
			immutable long res = a.extern_.write(fd, buf, nBytes);
			push(a.dataStack, immutable Nat64(res));
			break;
	}
	return nextOperation(a);
}

//TODO:KILL, use separate functions for each operation
immutable(Operation) opFn(ref Interpreter a) {
	immutable FnOp fnOp = cast(immutable FnOp) readNat8(a).raw();
	applyFn(a.dataStack, fnOp);
	return nextOperation(a);
}

private @system immutable(size_t) backtrace(ref Interpreter a, void** res, immutable uint size) {
	immutable size_t resSize = min(stackSize(a.returnStack).raw(), size);
	foreach (immutable size_t i; 0 .. resSize)
		res[i] = cast(void*) byteCodeIndexOfPtr(a, a.returnStack.peek((immutable Nat64(i)).to8())).index.raw();
	return resSize;
}

@trusted immutable(Operation) opExternDynCall(ref Interpreter a) {
	immutable Sym name = immutable Sym(readNat64(a).raw());
	immutable DynCallType returnType = cast(immutable DynCallType) readNat8(a).raw();
	scope immutable DynCallType[] parameterTypes = readArray!DynCallType(a);
	scope immutable Nat64[] params = popN(a.dataStack, sizeNat(parameterTypes).to8());
	immutable Nat64 value = a.extern_.doDynCall(name, returnType, params, parameterTypes);
	if (returnType != DynCallType.void_)
		push(a.dataStack, value);
	return nextOperation(a);
}

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
private alias JmpBufTag = immutable InterpreterRestore*;

private immutable(Operation) nextOperation(ref Interpreter a) {
	return false ? getNextOperationAndDebug(a) : readOperation(a);
}

@trusted immutable(Operation) readOperation(ref Interpreter a) {
	immutable Operation res = *a.nextOperation;
	a.nextOperation++;
	return res;
}

private immutable(Nat8) readNat8(ref Interpreter interpreter) {
	return immutable Nat8(cast(ubyte) readOperation(interpreter));
}

private immutable(StackOffset) readStackOffset(ref Interpreter interpreter) {
	return immutable StackOffset(readNat8(interpreter));
}

private immutable(Nat16) readNat16(ref Interpreter interpreter) {
	return immutable Nat16(cast(ushort) readOperation(interpreter));
}

private immutable(Int16) readInt16(ref Interpreter interpreter) {
	return immutable Int16(cast(short) readOperation(interpreter));
}

private immutable(Nat32) readNat32(ref Interpreter interpreter) {
	return immutable Nat32(cast(uint) readOperation(interpreter));
}

private immutable(Nat64) readNat64(ref Interpreter interpreter) {
	return immutable Nat64(cast(ulong) readOperation(interpreter));
}

private @trusted immutable(T[]) readArray(T)(ref Interpreter interpreter) {
	immutable size_t size = safeSizeTFromU64(readNat64(interpreter).raw());
	verify(size < 999); // sanity check
	immutable T* ptr = cast(immutable T*) interpreter.nextOperation;
	immutable T[] res = ptr[0 .. size];
	immutable(ubyte)* end = cast(immutable ubyte*) (ptr + size);
	while ((cast(size_t) end) % Operation.sizeof != 0) end++;
	verify((cast(size_t) interpreter.nextOperation) % Operation.sizeof == 0);
	verify((cast(size_t) end) % Operation.sizeof == 0);
	interpreter.nextOperation = cast(immutable Operation*) end;
	return res;
}

@trusted immutable(Operation) opJump(ref Interpreter a) {
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt16(a));
	a.nextOperation += offset.offset.raw();
	return nextOperation(a);
}

@trusted immutable(Operation) opPack(ref Interpreter a) {
	immutable Nat8 inEntries = readNat8(a);
	immutable Nat8 outEntries = readNat8(a);
	immutable PackField[] fields = readArray!PackField(a);

	ubyte* base = cast(ubyte*) (end(a.dataStack) - inEntries.raw());
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset.raw(), base + field.inOffset.raw(), field.size.raw());

	// drop extra entries
	drop(popN(a.dataStack, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + last(fields).outOffset.raw() + last(fields).size.raw();
	while (ptr < cast(ubyte*) end(a.dataStack)) {
		*ptr = 0;
		ptr++;
	}

	return nextOperation(a);
}

immutable(Operation) opPushValue(ref Interpreter a) {
	immutable Nat64 value = readNat64(a);
	push(a.dataStack, value);
	return nextOperation(a);
}

@trusted immutable(Operation) opDupBytes(ref Interpreter a) {
	immutable Nat16 offsetBytes = readNat16(a);
	immutable Nat16 sizeBytes = readNat16(a);

	const ubyte* ptr = (cast(const ubyte*) end(a.dataStack)) - offsetBytes.raw();
	readNoCheck(a.dataStack, ptr, sizeBytes.raw());
	return nextOperation(a);
}

@trusted immutable(Operation) opDupWord(ref Interpreter a) {
	immutable StackOffset offsetWords = readStackOffset(a);
	const Nat64* ptr = (cast(const Nat64*) end(a.dataStack)) - 1 - offsetWords.offset.raw();
	push(a.dataStack, *ptr);
	return nextOperation(a);
}

@trusted immutable(Operation) opDupWords(ref Interpreter a) {
	immutable StackOffset offsetWords = readStackOffset(a);
	immutable Nat8 sizeWords = readNat8(a);
	const(Nat64)* ptr = (cast(const Nat64*) end(a.dataStack)) - 1 - offsetWords.offset.raw();
	foreach (immutable size_t i; 0 .. sizeWords.raw()) {
		push(a.dataStack, *ptr);
		ptr++;
	}
	return nextOperation(a);
}

// Copies data from the top of the stack to write to something lower on the stack.
@trusted immutable(Operation) opSet(ref Interpreter a) {
	immutable StackOffset offsetWords = readStackOffset(a);
	immutable Nat8 sizeWords = readNat8(a);
	// Start at the end of the range and pop in reverse
	const Nat64* begin = (cast(const Nat64*) end(a.dataStack)) - 1 - offsetWords.offset.raw();
	const(Nat64)* ptr = begin + sizeWords.raw();
	foreach (immutable size_t i; 0 .. sizeWords.raw()) {
		ptr--;
		overwriteMemory(ptr, pop(a.dataStack));
	}
	verify(ptr == begin);
	return nextOperation(a);
}

private @system void readNoCheck(ref DataStack dataStack, const ubyte* readFrom, immutable size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) end(dataStack);
	immutable size_t sizeWords = divRoundUp(sizeBytes, 8);
	pushUninitialized(dataStack, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) end(dataStack)) {
		*endPtr = 0;
		endPtr++;
	}
}
