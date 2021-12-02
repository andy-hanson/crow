module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import frontend.showDiag : ShowDiagOptions;
import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	ByteCodeSource,
	ExternOp,
	initialOperationPointer,
	NextOperation,
	Operation;
import interpret.debugging : writeFunName;
import interpret.extern_ : DynCallType, Extern, TimeSpec;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowFunSource, LowProgram, matchLowFunSource;
import model.typeLayout : PackField;
import util.alloc.alloc : TempAlloc;
import util.alloc.rangeAlloc : RangeAlloc;
import util.dbg : log, logNoNewline, logSymNoNewline;
import util.collection.arr : at, begin, last, size, sizeNat;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.collection.globalAllocatedStack :
	asTempArr,
	clearStack,
	GlobalAllocatedStack,
	peek,
	pop,
	popN,
	push,
	pushUninitialized,
	remove,
	setToArr,
	setStackTop,
	stackEnd,
	stackIsEmpty,
	stackRef,
	stackSize,
	stackTop,
	toArr;
import util.collection.str : SafeCStr;
import util.dbg : Debug;
import util.memory : allocateMut, memcpy, memmove, memset, overwriteMemory;
import util.opt : has;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.repr : writeReprNoNewline;
import util.sourceRange : FileAndPos;
import util.sym : Sym;
import util.types : Int64, i32OfU64Bits, Nat64, safeIntFromNat64, safeSizeTFromU64, safeU32FromI32;
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
	return withInterpreter!(immutable int)(
		dbg, tempAlloc, extern_, lowProgram, byteCode, allPaths, filesInfo,
		(scope ref Interpreter interpreter) @trusted {
			push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
			push(interpreter.dataStack, immutable Nat64(cast(immutable ulong) begin(allArgs)));
			return withMeasureNoAlloc!(immutable int)(perf, PerfMeasure.run, () =>
				runBytecodeInner(interpreter));
		});
}

private @trusted immutable(int) runBytecodeInner(scope ref Interpreter interpreter) {
	immutable(Operation)* opPtr = initialOperationPointer(interpreter.byteCode);

	do {
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
	} while (opPtr.fn != &opStopInterpretation);

	immutable Nat64 returnCode = pop(interpreter.dataStack);
	verify(stackIsEmpty(interpreter.dataStack));
	return safeIntFromNat64(returnCode);
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 64);
private alias ReturnStack = GlobalAllocatedStack!(immutable(Operation)*, 1024 * 4);

@trusted immutable(T) withInterpreter(T)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref Extern extern_,
	scope ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref const AllPaths allPaths,
	ref immutable FilesInfo filesInfo,
	scope immutable(T) delegate(scope ref Interpreter) @safe @nogc nothrow cb,
) {
	scope Interpreter interpreter = Interpreter(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(tempAlloc),
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe_const(allPaths),
		ptrTrustMe(filesInfo));

	// Ensure the last 'return' returns to here
	push(interpreter.returnStack, operationOpStopInterpretation.ptr);

	static if (is(T == void))
		cb(interpreter);
	else
		immutable T res = cb(interpreter);

	clearStack(interpreter.dataStack);
	clearStack(interpreter.returnStack);

	static if (!is(T == void))
		return res;
}

struct Interpreter {
	@safe @nogc nothrow: // not pure

	@disable this(ref const Interpreter);

	private:
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
	//TODO:PRIVATE
	public DataStack dataStack;
	public ReturnStack returnStack;
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
	ref const(AllPaths) allPaths() const return scope pure {
		return allPathsPtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const return scope pure {
		return filesInfoPtr.deref();
	}
}

//TODO:PRIVATE
public pure ref immutable(ByteCode) byteCode(return scope ref const Interpreter a) {
	return a.byteCodePtr.deref();
}

// WARN: Does not restore data. Just mean for setjmp/longjmp.
private struct InterpreterRestore {
	// This is the stack sizes and byte code index to be restored by longjmp
	immutable ByteCodeIndex nextByteCodeIndex;
	Nat64* dataStackTop;
	immutable Operation*[] restoreReturnStack;
}

private @system InterpreterRestore* createInterpreterRestore(ref Interpreter a, immutable Operation* cur) {
	InterpreterRestore value = InterpreterRestore(
		nextByteCodeIndex(a, cur),
		stackTop(a.dataStack),
		toArr(a.tempAlloc, a.returnStack));
	return allocateMut(a.tempAlloc, value).rawPtr();
}

private @system immutable(Operation*) applyInterpreterRestore(ref Interpreter a, InterpreterRestore restore) {
	setStackTop(a.dataStack, restore.dataStackTop);
	setToArr(a.returnStack, restore.restoreReturnStack);
	return &a.byteCode.byteCode[safeSizeTFromU64(restore.nextByteCodeIndex.index)];
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

private @trusted void showReturnStack(scope ref Writer writer, ref const Interpreter a, immutable(Operation)* cur) {
	writeStatic(writer, "call stack:");
	foreach (immutable Operation* ptr; asTempArr(a.returnStack)) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, a, cur);
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
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(concreteFunRange(it.deref()).fileIndex, source.pos);
			writeFileAndPos(writer, allPaths, showDiagOptions, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {},
	)(fullIndexDictGet(lowProgram.allFuns, source.fun).source);
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

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(scope ref const Interpreter a, immutable Operation* cur) {
	return byteCodeIndexOfPtr(a, cur);
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(
	ref const Interpreter a,
	immutable Operation* ptr,
) {
	return immutable ByteCodeIndex(ptr - begin(a.byteCode.byteCode));
}

private immutable(ByteCodeSource) nextSource(ref const Interpreter a, immutable Operation* cur) {
	return byteCodeSourceAtByteCodePtr(a, cur);
}

private immutable(NextOperation) getNextOperationAndDebug(ref Interpreter a, immutable Operation* cur) {
	immutable ByteCodeSource source = nextSource(a, cur);

	{
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		showStack(writer, a);
		showReturnStack(writer, a, cur);
		log(a.dbg, finishWriter(writer));
	}

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

	return immutable NextOperation(cur);
}

immutable(NextOperation) opAssertUnreachable(ref Interpreter a, immutable(Operation)* cur) {
	return unreachable!(immutable NextOperation)();
}

immutable(NextOperation) opRemove(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opRemove");
	immutable size_t offset = readStackOffset(cur);
	immutable size_t nEntries = readSizeT(cur);
	remove(a.dataStack, offset, nEntries);
	return nextOperation(a, cur);
}

immutable(NextOperation) opReturn(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opReturn");
	verify(!stackIsEmpty(a.returnStack));
	return nextOperation(a, pop(a.returnStack));
}

private immutable(Operation[8]) operationOpStopInterpretation = [
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
	immutable Operation(&opStopInterpretation),
];

immutable(NextOperation) opStopInterpretation(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opStopInterpretation");
	return immutable NextOperation(&operationOpStopInterpretation[0]);
}

@trusted immutable(NextOperation) opJumpIfFalse(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opJumpIfFalse");
	immutable ByteCodeOffsetUnsigned offset = immutable ByteCodeOffsetUnsigned(readSizeT(cur));
	immutable Nat64 value = pop(a.dataStack);
	if (value == immutable Nat64(0))
		cur += offset.offset;
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opSwitch0ToN(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opSwitch0T0N");
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(cur);
	immutable Nat64 value = pop(a.dataStack);
	immutable ByteCodeOffsetUnsigned offset = at(offsets, safeSizeTFromU64(value.raw()));
	return nextOperation(a, cur + offset.offset);
}

@trusted immutable(NextOperation) opStackRef(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opStackRef");
	immutable size_t offset = readStackOffset(cur);
	push(a.dataStack, immutable Nat64(cast(immutable ulong) stackRef(a.dataStack, offset)));
	return nextOperation(a, cur);
}

immutable(NextOperation) opReadWords(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadWords", offsetWords, sizeWords);
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

immutable(NextOperation) opReadWordsVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	immutable size_t sizeWords = readSizeT(cur);
	debug log(a.dbg, "opReadWordsVariable", offsetWords, sizeWords);
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

private @trusted immutable(NextOperation) opReadWordsCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	immutable Nat64* ptr = (cast(immutable Nat64*) pop(a.dataStack).raw()) + offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords)
		push(a.dataStack, ptr[i]);
	return nextOperation(a, cur);
}


@trusted immutable(NextOperation) opReadNat8(immutable size_t offsetBytes)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat8", offsetBytes);
	push(a.dataStack, immutable Nat64(*((cast(immutable ubyte*) pop(a.dataStack).raw()) + offsetBytes)));
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opReadNat16(immutable size_t offsetNat16s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat16", offsetNat16s);
	push(a.dataStack, immutable Nat64(*((cast(immutable ushort*) pop(a.dataStack).raw()) + offsetNat16s)));
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opReadNat32(immutable size_t offsetNat32s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat32", offsetNat32s);
	push(a.dataStack, immutable Nat64(*((cast(immutable uint*) pop(a.dataStack).raw()) + offsetNat32s)));
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opReadBytesVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);
	debug log(a.dbg, "opReadBytesVariable", offsetBytes, sizeBytes);
	immutable ubyte* ptr = (cast(immutable ubyte*) pop(a.dataStack).raw()) + offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opWrite(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opWrite");
	immutable size_t offset = readSizeT(cur);
	immutable size_t size = readSizeT(cur);
	if (size < 8) { //TODO:UNNECESSARY?
		verify(size != 0);
		immutable ulong value = pop(a.dataStack).raw();
		ubyte* ptr = cast(ubyte*) pop(a.dataStack).raw();
		writePartialBytes(ptr + offset, value, size);
	} else {
		immutable size_t sizeWords = divRoundUp(size, 8);
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords).raw();
		ubyte* src = cast(ubyte*) (stackEnd(a.dataStack) - sizeWords);
		ubyte* dest = destWithoutOffset + offset;
		memcpy(dest, src, size);
		popN(a.dataStack, sizeWords + 1);
	}
	return nextOperation(a, cur);
}

private @trusted void writePartialBytes(ubyte* ptr, immutable ulong value, immutable size_t size) {
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

immutable(NextOperation) opCall(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opCall");
	immutable ByteCodeIndex address = immutable ByteCodeIndex(readSizeT(cur));
	return callCommon(a, address, cur);
}

immutable(NextOperation) opCallFunPtr(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opCallFunPtr");
	immutable size_t parametersSize = readSizeT(cur);
	//TODO: handle a real function pointer being here?
	immutable ByteCodeIndex address = immutable ByteCodeIndex(
		safeSizeTFromU64(remove(a.dataStack, parametersSize).raw()));
	return callCommon(a, address, cur);
}

private immutable(NextOperation) callCommon(
	ref Interpreter a,
	immutable ByteCodeIndex address,
	immutable Operation* cur,
) {
	push(a.returnStack, cur);
	return nextOperation(a, &a.byteCode.byteCode[address.index]);
}

//TODO: not @trusted
@trusted immutable(NextOperation) opExtern(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opExtern");
	immutable ExternOp op = cast(ExternOp) readNat64(cur).raw();
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
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack).raw();
			cur = applyInterpreterRestore(a, **jmpBufPtr);
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
			overwriteMemory(jmpBufPtr, createInterpreterRestore(a, cur));
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
	return nextOperation(a, cur);
}

private @system immutable(size_t) backtrace(ref Interpreter a, void** res, immutable uint size) {
	immutable size_t resSize = min(stackSize(a.returnStack), size);
	foreach (immutable size_t i; 0 .. resSize)
		res[i] = cast(void*) byteCodeIndexOfPtr(a, peek(a.returnStack, i)).index;
	return resSize;
}

@trusted immutable(NextOperation) opExternDynCall(ref Interpreter a, immutable(Operation)* cur) {
	immutable Sym name = immutable Sym(readNat64(cur).raw());
	debug {
		logNoNewline(a.dbg, "opExternDynCall ");
		logSymNoNewline(a.dbg, name);
		log(a.dbg, "");
	}
	immutable DynCallType returnType = cast(immutable DynCallType) readNat64(cur).raw();
	scope immutable DynCallType[] parameterTypes = readArray!DynCallType(cur);
	scope immutable Nat64[] params = popN(a.dataStack, size(parameterTypes));
	immutable Nat64 value = a.extern_.doDynCall(name, returnType, params, parameterTypes);
	if (returnType != DynCallType.void_)
		push(a.dataStack, value);
	return nextOperation(a, cur);
}

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
private alias JmpBufTag = InterpreterRestore*;

immutable(NextOperation) opFnUnary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opFnUnary", __traits(identifier, cb));
	push(a.dataStack, cb(pop(a.dataStack).raw()));
	return nextOperation(a, cur);
}

immutable(NextOperation) opFnBinary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opFnBinary", __traits(identifier, cb));
	immutable ulong y = pop(a.dataStack).raw();
	immutable ulong x = pop(a.dataStack).raw();
	push(a.dataStack, cb(x, y));
	return nextOperation(a, cur);
}

private @trusted immutable(NextOperation) nextOperation(ref Interpreter a, immutable Operation* cur) {
	static if (false)
		return getNextOperationAndDebug(a, cur);
	version(TailRecursionAvialable) {
		return cur.fn(a, cur + 1);
	}
	return immutable NextOperation(cur);
}

private @trusted immutable(Operation) readOperation(scope ref immutable(Operation)* cur) {
	immutable Operation res = *cur;
	cur++;
	return res;
}

private immutable(size_t) readStackOffset(ref immutable(Operation)* cur) {
	return readSizeT(cur);
}

private immutable(Int64) readInt64(ref immutable(Operation)* cur) {
	return readOperation(cur).int64;
}

private @trusted immutable(Nat64) readNat64(ref immutable(Operation)* cur) {
	return readOperation(cur).nat64;
}

private @trusted immutable(size_t) readSizeT(ref immutable(Operation)* cur) {
	return safeSizeTFromU64(readNat64(cur).raw());
}

private @trusted immutable(T[]) readArray(T)(ref immutable(Operation)* cur) {
	immutable size_t size = readSizeT(cur);
	verify(size < 999); // sanity check
	immutable T* ptr = cast(immutable T*) cur;
	immutable T[] res = ptr[0 .. size];
	immutable(ubyte)* end = cast(immutable ubyte*) (ptr + size);
	while ((cast(size_t) end) % Operation.sizeof != 0) end++;
	verify((cast(size_t) cur) % Operation.sizeof == 0);
	verify((cast(size_t) end) % Operation.sizeof == 0);
	cur = cast(immutable Operation*) end;
	return res;
}

@trusted immutable(NextOperation) opJump(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opJump");
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt64(cur).raw());
	return nextOperation(a, cur + offset.offset);
}

@trusted immutable(NextOperation) opPack(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opPack");
	immutable size_t inEntries = readSizeT(cur);
	immutable size_t outEntries = readSizeT(cur);
	immutable PackField[] fields = readArray!PackField(cur);

	ubyte* base = cast(ubyte*) (stackEnd(a.dataStack) - inEntries);
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset.raw(), base + field.inOffset.raw(), safeSizeTFromU64(field.size.raw()));

	// drop extra entries
	drop(popN(a.dataStack, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + last(fields).outOffset.raw() + last(fields).size.raw();
	while (ptr < cast(ubyte*) stackEnd(a.dataStack)) {
		*ptr = 0;
		ptr++;
	}

	return nextOperation(a, cur);
}

immutable(NextOperation) opPushValue64(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opPushValue64");
	immutable Nat64 value = readNat64(cur);
	push(a.dataStack, value);
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opDupBytes(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupBytes");
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);

	const ubyte* ptr = (cast(const ubyte*) stackEnd(a.dataStack)) - offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

immutable(NextOperation) opDupWord(immutable size_t offsetWords)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupWord", offsetWords);
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

immutable(NextOperation) opDupWordVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	debug log(a.dbg, "opDupWordVariable", offsetWords);
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

@trusted immutable(NextOperation) opDupWords(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupWords");
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	const(Nat64)* ptr = stackTop(a.dataStack) - offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		push(a.dataStack, *ptr);
		ptr++;
	}
	return nextOperation(a, cur);
}

// Copies data from the top of the stack to write to something lower on the stack.
immutable(NextOperation) opSet(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opSet", offsetWords, sizeWords);
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

immutable(NextOperation) opSetVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	debug log(a.dbg, "opSetVariable", offsetWords, sizeWords);
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

private @trusted immutable(NextOperation) opSetCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	// Start at the end of the range and pop in reverse
	const Nat64* begin = stackTop(a.dataStack) - offsetWords;
	const(Nat64)* ptr = begin + sizeWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		ptr--;
		overwriteMemory(ptr, pop(a.dataStack));
	}
	verify(ptr == begin);
	return nextOperation(a, cur);
}

private @system void readNoCheck(ref DataStack dataStack, const ubyte* readFrom, immutable size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) stackEnd(dataStack);
	immutable size_t sizeWords = divRoundUp(sizeBytes, Nat64.sizeof);
	pushUninitialized(dataStack, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) stackEnd(dataStack)) {
		*endPtr = 0;
		endPtr++;
	}
}
