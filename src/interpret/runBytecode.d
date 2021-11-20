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
	DynCallType,
	ExternOp,
	FnOp,
	Operation,
	StackOffset,
	TimeSpec;
import interpret.debugging : writeFunName;
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
	stackPtrRange,
	stackRef,
	stackSize,
	toArr;
import util.collection.str : SafeCStr;
import util.dbg : Debug;
import util.memory : allocate, memcpy, memmove, memset, overwriteMemory;
import util.opt : has;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : contains, Ptr, PtrRange, ptrRangeOfArr, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
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
import util.util : divRoundUp, drop, min, todo, unreachable, verify;
import util.writer : finishWriter, Writer, writeChar, writeHex, writePtrRange, writeStatic;

@trusted immutable(int) runBytecode(Extern)(
	scope ref Debug dbg,
	ref Perf perf,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	ref Extern extern_,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode!Extern byteCode,
	ref immutable FilesInfo filesInfo,
	immutable SafeCStr[] allArgs,
) {
	Interpreter!Extern interpreter = Interpreter!Extern(
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
		runBytecodeInner!Extern(dbg, perf, tempAlloc, allPaths, interpreter));
}

private @trusted immutable(int) runBytecodeInner(Extern)(
	scope ref Debug dbg,
	ref Perf perf,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	ref Interpreter!Extern interpreter,
) {
	Operation!Extern op = nextOperation(interpreter);
	do {
		op = cast(Operation!Extern) op(interpreter);
		op = cast(Operation!Extern) op(interpreter);
		op = cast(Operation!Extern) op(interpreter);
		op = cast(Operation!Extern) op(interpreter);
	} while (op != &opStopInterpretation!Extern);

	immutable Nat64 returnCode = pop(interpreter.dataStack);
	verify(isEmpty(interpreter.dataStack));
	return safeIntFromNat64(returnCode);
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 64);
private alias ReturnStack(Extern) = GlobalAllocatedStack!(immutable(Operation!Extern)*, 1024 * 4);

struct Interpreter(Extern) {
	@safe @nogc nothrow: // not pure

	@disable this(ref const Interpreter);

	@trusted this(
		Ptr!Debug dbg,
		Ptr!TempAlloc ta,
		Ptr!Extern e,
		immutable Ptr!LowProgram p,
		immutable Ptr!(ByteCode!Extern) b,
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
		nextOperation = begin(byteCode.byteCode) + byteCode.main.index.raw();
		dataStack = DataStack(true);
		returnStack = ReturnStack!Extern(true);
	}

	Ptr!Debug debugPtr;
	//TODO:KILL
	Ptr!TempAlloc tempAllocPtr;
	Ptr!Extern externPtr;
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!(ByteCode!Extern) byteCodePtr;
	const Ptr!AllPaths allPathsPtr;
	immutable Ptr!FilesInfo filesInfoPtr;
	immutable(Operation!Extern)* nextOperation;
	DataStack dataStack;
	ReturnStack!Extern returnStack;
	// WARN: if adding any new mutable state here, make sure 'longjmp' still restores it

	ref Debug dbg() {
		return debugPtr.deref();
	}
	//TODO:KILL
	ref TempAlloc tempAlloc() {
		return tempAllocPtr.deref();
	}
	ref inout(Extern) extern_() inout {
		return externPtr.deref();
	}
	ref immutable(LowProgram) lowProgram() const {
		return lowProgramPtr.deref();
	}
	ref immutable(ByteCode!Extern) byteCode() const {
		return byteCodePtr.deref();
	}
	ref const(AllPaths) allPaths() const {
		return allPathsPtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const {
		return filesInfoPtr.deref();
	}
}

// WARN: Does not restore data. Just mean for setjmp/longjmp.
private struct InterpreterRestore(Extern) {
	// This is the stack sizes and byte code index to be restored by longjmp
	immutable ByteCodeIndex nextByteCodeIndex;
	immutable Nat32 dataStackSize;
	immutable Operation!Extern*[] restoreReturnStack;
}

private immutable(InterpreterRestore!Extern*) createInterpreterRestore(Extern)(ref Interpreter!Extern a) {
	immutable InterpreterRestore!Extern value = immutable InterpreterRestore!Extern(
		nextByteCodeIndex(a),
		stackSize(a.dataStack),
		toArr(a.tempAlloc, a.returnStack));
	return allocate(a.tempAlloc, value).rawPtr();
}

private void applyInterpreterRestore(Extern)(
	ref Interpreter!Extern a,
	ref immutable InterpreterRestore!Extern restore,
) {
	setNextByteCodeIndex(a, restore.nextByteCodeIndex);
	reduceStackSize(a.dataStack, restore.dataStackSize.raw());
	setToArr(a.returnStack, restore.restoreReturnStack);
}

@trusted void reset(Extern)(ref Interpreter!Extern a) {
	setReaderPtr(a.reader, begin(a.byteCode.byteCode));
	clearStack(a.dataStack);
	clearStack(a.returnStack);
	clearStack(a.stackStartStack);
}

private void showStack(Extern)(scope ref Writer writer, ref const Interpreter!Extern a) {
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

private @trusted void showReturnStack(Extern)(ref Writer writer, ref const Interpreter!Extern a) {
	writeStatic(writer, "call stack:");
	foreach (immutable Operation!Extern* ptr; asTempArr(a.returnStack)) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr!Extern(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr!Extern(writer, a, a.nextOperation);
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

private void writeFunNameAtIndex(Extern)(
	ref Writer writer,
	ref const Interpreter!Extern interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, interpreter.lowProgram, byteCodeSourceAtIndex(interpreter, index).fun);
}

private void writeFunNameAtByteCodePtr(Extern)(
	ref Writer writer,
	ref const Interpreter!Extern interpreter,
	immutable Operation!Extern* ptr,
) {
	writeFunNameAtIndex!Extern(writer, interpreter, byteCodeIndexOfPtr!Extern(interpreter, ptr));
}

private immutable(ByteCodeSource) byteCodeSourceAtIndex(Extern)(
	ref const Interpreter!Extern a,
	immutable ByteCodeIndex index,
) {
	return fullIndexDictGet(a.byteCode.sources, index);
}

private immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(Extern)(
	ref const Interpreter!Extern a,
	immutable Operation!Extern* ptr,
) {
	return byteCodeSourceAtIndex!Extern(a, byteCodeIndexOfPtr!Extern(a, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(Extern)(ref const Interpreter!Extern a) {
	return byteCodeIndexOfPtr!Extern(a, a.nextOperation);
}

//TODO:KILL (use ptrs directly instead of ByteCodeIndex)
private void setNextByteCodeIndex(Extern)(ref Interpreter!Extern a, immutable ByteCodeIndex index) {
	a.nextOperation = ptrAt!(immutable Operation!Extern)(a.byteCode.byteCode, index.index.raw()).rawPtr();
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(Extern)(
	ref const Interpreter!Extern a,
	immutable Operation!Extern* ptr,
) {
	return immutable ByteCodeIndex((immutable Nat64(ptr - begin(a.byteCode.byteCode))).to32());
}

private immutable(ByteCodeSource) nextSource(Extern)(ref const Interpreter!Extern a) {
	return byteCodeSourceAtByteCodePtr!Extern(a, a.nextOperation);
}

private immutable(Operation!Extern) getNextOperationAndDebug(Extern)(ref Interpreter!Extern a) {
	immutable ByteCodeSource source = nextSource(a);

	{
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		showStack(writer, a);
		showReturnStack(writer, a);
		log(a.dbg, finishWriter(writer));
	}

	immutable Operation!Extern operation = nextOperation(a);

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

immutable(Operation!Extern) opAssertUnreachable(Extern)(ref Interpreter!Extern a) {
	return unreachable!(immutable Operation!Extern)();
}

immutable(Operation!Extern) opRemove(Extern)(ref Interpreter!Extern a) {
	immutable StackOffset offset = readStackOffset(a);
	immutable Nat8 nEntries = readNat8(a);
	remove(a.dataStack, offset.offset, nEntries);
	return nextOperation(a);
}

immutable(Operation!Extern) opReturn(Extern)(ref Interpreter!Extern a) {
	if (isEmpty(a.returnStack))
		return &opStopInterpretation!Extern;
	else {
		a.nextOperation = pop(a.returnStack);
		return nextOperation(a);
	}
}

private immutable(Operation!Extern) opStopInterpretation(Extern)(ref Interpreter!Extern a) {
	return &opStopInterpretation!Extern;
}

@trusted immutable(Operation!Extern) opSwitch0ToN(Extern)(ref Interpreter!Extern a) {
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(a);
	immutable Nat64 value = pop(a.dataStack);
	immutable ByteCodeOffsetUnsigned offset = at(offsets, safeSizeTFromU64(value.raw()));
	a.nextOperation += offset.offset.raw();
	return nextOperation(a);
}

immutable(Operation!Extern) opStackRef(Extern)(ref Interpreter!Extern a) {
	immutable StackOffset offset = readStackOffset(a);
	push(a.dataStack, immutable Nat64(cast(immutable ulong) stackRef(a.dataStack, offset.offset)));
	return nextOperation(a);
}

@trusted immutable(Operation!Extern) opRead(Extern)(ref Interpreter!Extern a) {
	immutable Nat16 offset = readNat16(a);
	immutable Nat16 size = readNat16(a);
	immutable ubyte* ptr = cast(immutable ubyte*) pop(a.dataStack).raw();
	checkPtr(a, ptr, offset, size);
	readNoCheck(a.dataStack, ptr + offset.raw(), size.raw());
	return nextOperation(a);
}

@system private void checkPtr(Extern)(
	ref const Interpreter!Extern a,
	const ubyte* ptrWithoutOffset,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	const ubyte* ptr = ptrWithoutOffset + offset.raw();
	const PtrRange ptrRange = const PtrRange(ptr, ptr + size.raw());
	if (!contains(stackPtrRange(a.dataStack), ptrRange)
		&& !a.extern_.hasMallocedPtr(ptrRange)
		&& !contains(ptrRangeOfArr(a.byteCode.text), ptrRange)) {
		// TODO: the pointer might have been returned by a 3rd-party library. We'd need to track those too.
		//debug {
		//	Writer writer = Writer(ptrTrustMe_mut(tempAlloc));
		//	writePtrRange(writer, ptrRange);
		//	writePtrRanges(writer, a);
		//	printf("accessing potentially invalid pointer: %s\n", finishWriterToCStr(writer));
		//}
		//todo!void("ptr not valid");
	}
}

@trusted immutable(Operation!Extern) opWrite(Extern)(ref Interpreter!Extern a) {
	immutable Nat16 offset = readNat16(a);
	immutable Nat16 size = readNat16(a);
	if (size < immutable Nat16(8)) { //TODO:UNNECESSARY?
		verify(size != immutable Nat16(0));
		immutable Nat64 value = pop(a.dataStack);
		ubyte* ptr = cast(ubyte*) pop(a.dataStack).raw();
		checkPtr(a, ptr, offset, size);
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		immutable Nat16 sizeWords = divRoundUp(size, immutable Nat16(8));
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords.to8()).raw();
		checkPtr(a, destWithoutOffset, offset, size);
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

immutable(Operation!Extern) opCall(Extern)(ref Interpreter!Extern a) {
	immutable ByteCodeIndex address = immutable ByteCodeIndex(readNat32(a));
	return callCommon(a, address);
}

immutable(Operation!Extern) opCallFunPtr(Extern)(ref Interpreter!Extern a) {
	immutable Nat8 parametersSize = readNat8(a);
	//TODO: handle a real function pointer being here?
	immutable ByteCodeIndex address = immutable ByteCodeIndex(
		removeAtStackOffset(a, immutable StackOffset(parametersSize)).to32());
	return callCommon(a, address);
}

private immutable(Operation!Extern) callCommon(Extern)(
	ref Interpreter!Extern a,
	immutable ByteCodeIndex address,
) {
	push(a.returnStack, a.nextOperation);
	setNextByteCodeIndex(a, address);
	return nextOperation(a);
}

private immutable(Nat64) removeAtStackOffset(Extern)(ref Interpreter!Extern a, immutable StackOffset offset) {
	return remove(a.dataStack, offset.offset);
}

//TODO: not @trusted
@trusted immutable(Operation!Extern) opExtern(Extern)(ref Interpreter!Extern a) {
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
			const JmpBufTag!Extern* jmpBufPtr = cast(const JmpBufTag!Extern*) pop(a.dataStack).raw();
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
			JmpBufTag!Extern* jmpBufPtr = cast(JmpBufTag!Extern*) pop(a.dataStack).raw();
			checkPtr(a, cast(const ubyte*) jmpBufPtr, immutable Nat16(0), immutable Nat16(JmpBufTag!Extern.sizeof));
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
immutable(Operation!Extern) opFn(Extern)(ref Interpreter!Extern a) {
	immutable FnOp fnOp = cast(immutable FnOp) readNat8(a).raw();
	applyFn(a.dataStack, fnOp);
	return nextOperation(a);
}

private @system immutable(size_t) backtrace(Extern)(ref Interpreter!Extern a, void** res, immutable uint size) {
	checkPtr(a, cast(const ubyte*) res, immutable Nat16(0), (immutable Nat64((void*).sizeof * size)).to16());
	immutable size_t resSize = min(stackSize(a.returnStack).raw(), size);
	foreach (immutable size_t i; 0 .. resSize)
		res[i] = cast(void*) byteCodeIndexOfPtr!Extern(a, a.returnStack.peek((immutable Nat64(i)).to8())).index.raw();
	return resSize;
}

immutable(Operation!Extern) opExternDynCall(Extern)(ref Interpreter!Extern a) {
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
private alias JmpBufTag(Extern) = immutable InterpreterRestore!Extern*;

private immutable(Operation!Extern) nextOperation(Extern)(ref Interpreter!Extern a) {
	return false ? getNextOperationAndDebug(a) : readOperation(a);
}

private @trusted immutable(Operation!Extern) readOperation(Extern)(ref Interpreter!Extern a) {
	immutable Operation!Extern res = *a.nextOperation;
	a.nextOperation++;
	return res;
}

private immutable(Nat8) readNat8(Extern)(ref Interpreter!Extern interpreter) {
	return immutable Nat8(cast(ubyte) readOperation!Extern(interpreter));
}

private immutable(StackOffset) readStackOffset(Extern)(ref Interpreter!Extern interpreter) {
	return immutable StackOffset(readNat8(interpreter));
}

private immutable(Nat16) readNat16(Extern)(ref Interpreter!Extern interpreter) {
	return immutable Nat16(cast(ushort) readOperation!Extern(interpreter));
}

private immutable(Int16) readInt16(Extern)(ref Interpreter!Extern interpreter) {
	return immutable Int16(cast(short) readOperation!Extern(interpreter));
}

private immutable(Nat32) readNat32(Extern)(ref Interpreter!Extern interpreter) {
	return immutable Nat32(cast(uint) readOperation!Extern(interpreter));
}

private immutable(Nat64) readNat64(Extern)(ref Interpreter!Extern interpreter) {
	return immutable Nat64(cast(ulong) readOperation!Extern(interpreter));
}

private @trusted immutable(T[]) readArray(T, Extern)(ref Interpreter!Extern interpreter) {
	immutable size_t size = safeSizeTFromU64(readNat64(interpreter).raw());
	verify(size < 999); // sanity check
	immutable T* ptr = cast(immutable T*) interpreter.nextOperation;
	immutable T[] res = ptr[0 .. size];
	immutable(ubyte)* end = cast(immutable ubyte*) (ptr + size);
	while ((cast(size_t) end) % Operation!Extern.sizeof != 0) end++;
	verify((cast(size_t) interpreter.nextOperation) % Operation!Extern.sizeof == 0);
	verify((cast(size_t) end) % Operation!Extern.sizeof == 0);
	interpreter.nextOperation = cast(immutable Operation!Extern*) end;
	return res;
}

@trusted immutable(Operation!Extern) opJump(Extern)(ref Interpreter!Extern a) {
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt16(a));
	a.nextOperation += offset.offset.raw();
	return nextOperation(a);
}

@trusted immutable(Operation!Extern) opPack(Extern)(ref Interpreter!Extern a) {
	immutable Nat8 inEntries = readNat8(a);
	immutable Nat8 outEntries = readNat8(a);
	immutable PackField[] fields = readArray!(PackField, Extern)(a);

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

immutable(Operation!Extern) opPushValue(Extern)(ref Interpreter!Extern a) {
	immutable Nat64 value = readNat64(a);
	push(a.dataStack, value);
	return nextOperation(a);
}

@trusted immutable(Operation!Extern) opDupBytes(Extern)(ref Interpreter!Extern a) {
	immutable Nat16 offsetBytes = readNat16(a);
	immutable Nat16 sizeBytes = readNat16(a);

	const ubyte* ptr = (cast(const ubyte*) end(a.dataStack)) - offsetBytes.raw();
	readNoCheck(a.dataStack, ptr, sizeBytes.raw());
	return nextOperation(a);
}

@trusted immutable(Operation!Extern) opDupWord(Extern)(ref Interpreter!Extern a) {
	immutable StackOffset offsetWords = readStackOffset(a);
	const Nat64* ptr = (cast(const Nat64*) end(a.dataStack)) - 1 - offsetWords.offset.raw();
	push(a.dataStack, *ptr);
	return nextOperation(a);
}

@trusted immutable(Operation!Extern) opDupWords(Extern)(ref Interpreter!Extern a) {
	immutable StackOffset offsetWords = readStackOffset(a);
	immutable Nat8 sizeWords = readNat8(a);
	const(Nat64)* ptr = (cast(const Nat64*) end(a.dataStack)) - 1 - offsetWords.offset.raw();
	foreach (immutable size_t i; 0 .. sizeWords.raw()) {
		push(a.dataStack, *ptr);
		ptr++;
	}
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
