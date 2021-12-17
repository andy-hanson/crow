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
import util.col.fullIndexDict : fullIndexDictGet;
import util.col.stack :
	asTempArr,
	clearStack,
	peek,
	pop,
	popN,
	push,
	pushUninitialized,
	remove,
	setToArr,
	setStackTop,
	Stack,
	stackEnd,
	stackIsEmpty,
	stackRef,
	stackSize,
	stackTop,
	toArr;
import util.col.str : SafeCStr;
import util.conv : safeToSizeT;
import util.dbg : Debug;
import util.memory : allocateMut, memcpy, memmove, memset, overwriteMemory;
import util.opt : has;
import util.path : AllPaths;
import util.perf : Perf, PerfMeasure, withMeasureNoAlloc;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_const, ptrTrustMe_mut;
import util.repr : writeReprNoNewline;
import util.sourceRange : FileAndPos;
import util.sym : AllSymbols, Sym;
import util.util : divRoundUp, drop, min, unreachable, verify;
import util.writer : finishWriter, Writer, writeChar, writeHex, writeStatic;

@trusted immutable(int) runBytecode(
	scope ref Debug dbg,
	ref Perf perf,
	ref TempAlloc tempAlloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	scope ref Extern extern_,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	scope immutable SafeCStr[] allArgs,
) {
	return withInterpreter!(immutable int)(
		dbg, tempAlloc, extern_, lowProgram, byteCode, allSymbols, allPaths, filesInfo,
		(scope ref Interpreter interpreter) {
			push(interpreter.dataStack, allArgs.length);
			push(interpreter.dataStack, cast(immutable ulong) allArgs.ptr);
			return withMeasureNoAlloc!(immutable int, () =>
				runBytecodeInner(interpreter)
			)(perf, PerfMeasure.run);
		});
}

private @system immutable(int) runBytecodeInner(scope ref Interpreter interpreter) {
	immutable(Operation)* opPtr = initialOperationPointer(interpreter.byteCode);

	do {
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
		opPtr = opPtr.fn(interpreter, opPtr + 1).operationPtr;
	} while (opPtr.fn != &opStopInterpretation);

	immutable ulong returnCode = pop(interpreter.dataStack);
	verify(stackIsEmpty(interpreter.dataStack));
	return cast(int) returnCode;
}

alias DataStack = Stack!ulong;
private alias ReturnStack = Stack!(immutable(Operation)*);

@system immutable(T) withInterpreter(T)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref Extern extern_,
	scope ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable FilesInfo filesInfo,
	scope immutable(T) delegate(scope ref Interpreter) @system @nogc nothrow cb,
) {
	scope Interpreter interpreter = Interpreter(
		ptrTrustMe_mut(dbg),
		ptrTrustMe_mut(tempAlloc),
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe_const(allSymbols),
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
		const Ptr!AllSymbols as,
		const Ptr!AllPaths ap,
		immutable Ptr!FilesInfo f,
	) {
		debugPtr = dbg;
		tempAllocPtr = ta;
		externPtr = e;
		lowProgramPtr = p;
		byteCodePtr = b;
		allSymbolsPtr = as;
		allPathsPtr = ap;
		filesInfoPtr = f;
		dataStack = DataStack(ta.deref(), 1024 * 64);
		returnStack = ReturnStack(ta.deref(), 1024 * 4);
	}

	Ptr!Debug debugPtr;
	//TODO:KILL
	Ptr!TempAlloc tempAllocPtr;
	Ptr!Extern externPtr;
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!ByteCode byteCodePtr;
	const Ptr!AllSymbols allSymbolsPtr;
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
	ref const(AllSymbols) allSymbols() const return scope pure {
		return allSymbolsPtr.deref();
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
	ulong* dataStackTop;
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
	return &a.byteCode.byteCode[safeToSizeT(restore.nextByteCodeIndex.index)];
}

private void showStack(scope ref Writer writer, ref const Interpreter a) {
	immutable ulong[] stack = asTempArr(a.dataStack);
	showDataArr(writer, stack);
}

void showDataArr(scope ref Writer writer, scope ref immutable ulong[] values) {
	writeStatic(writer, "data: ");
	foreach (immutable ulong value; values) {
		writeChar(writer, ' ');
		writeHex(writer, value);
	}
	writeChar(writer, '\n');
}

private void showReturnStack(scope ref Writer writer, ref const Interpreter a, immutable(Operation)* cur) {
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
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	immutable ByteCodeSource source,
) {
	writeFunName(writer, allSymbols, lowProgram, source.fun);
	matchLowFunSource!(
		void,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(
				concreteFunRange(it.deref(), allSymbols).fileIndex,
				source.pos);
			writeFileAndPos(writer, allPaths, showDiagOptions, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {},
	)(fullIndexDictGet(lowProgram.allFuns, source.fun).source);
}

private void writeFunNameAtIndex(
	scope ref Writer writer,
	ref const Interpreter interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(
		writer,
		interpreter.allSymbols,
		interpreter.lowProgram,
		byteCodeSourceAtIndex(interpreter, index).fun);
}

private void writeFunNameAtByteCodePtr(
	scope ref Writer writer,
	ref const Interpreter interpreter,
	immutable Operation* ptr,
) {
	writeFunNameAtIndex(writer, interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

private immutable(ByteCodeSource) byteCodeSourceAtIndex(ref const Interpreter a, immutable ByteCodeIndex index) {
	return fullIndexDictGet(a.byteCode.sources, index);
}

private immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(
	ref const Interpreter a,
	immutable Operation* ptr,
) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

immutable(ByteCodeIndex) nextByteCodeIndex(scope ref const Interpreter a, immutable Operation* cur) {
	return byteCodeIndexOfPtr(a, cur);
}

@trusted pure immutable(ByteCodeIndex) byteCodeIndexOfPtr(
	ref const Interpreter a,
	immutable Operation* ptr,
) {
	return immutable ByteCodeIndex(ptr - a.byteCode.byteCode.ptr);
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
		writeByteCodeSource(writer, a.allSymbols, a.allPaths, showDiagOptions, a.lowProgram, a.filesInfo, source);
		//writeChar(writer, ' ');
		//writeReprNoNewline(writer, reprOperation(dbgAlloc, operation));
		//writeChar(writer, '\n');
		log(a.dbg, finishWriter(writer));
	}

	return immutable NextOperation(cur);
}

immutable(NextOperation) opAssertUnreachable(ref Interpreter a, immutable Operation* cur) {
	return unreachable!(immutable NextOperation)();
}

@system immutable(NextOperation) opRemove(immutable size_t offset, immutable size_t nEntries)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opRemove", offset, nEntries);
	remove(a.dataStack, offset, nEntries);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opRemoveVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offset = readStackOffset(cur);
	immutable size_t nEntries = readSizeT(cur);
	debug log(a.dbg, "opRemoveVariable", offset, nEntries);
	remove(a.dataStack, offset, nEntries);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReturn(ref Interpreter a, immutable(Operation)* cur) {
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

@system immutable(NextOperation) opJumpIfFalse(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opJumpIfFalse");
	immutable ByteCodeOffsetUnsigned offset = immutable ByteCodeOffsetUnsigned(readSizeT(cur));
	immutable ulong value = pop(a.dataStack);
	if (value == 0)
		cur += offset.offset;
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opSwitch0ToN(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opSwitch0T0N");
	immutable ByteCodeOffsetUnsigned[] offsets = readArray!ByteCodeOffsetUnsigned(cur);
	immutable ulong value = pop(a.dataStack);
	immutable ByteCodeOffsetUnsigned offset = offsets[safeToSizeT(value)];
	return nextOperation(a, cur + offset.offset);
}

@system immutable(NextOperation) opStackRef(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opStackRef");
	immutable size_t offset = readStackOffset(cur);
	push(a.dataStack, cast(immutable ulong) stackRef(a.dataStack, offset));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadWords(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadWords", offsetWords, sizeWords);
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

@system immutable(NextOperation) opReadWordsVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	immutable size_t sizeWords = readSizeT(cur);
	debug log(a.dbg, "opReadWordsVariable", offsetWords, sizeWords);
	return opReadWordsCommon(a, cur, offsetWords, sizeWords);
}

private @system immutable(NextOperation) opReadWordsCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	immutable ulong* ptr = (cast(immutable ulong*) pop(a.dataStack)) + offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords)
		push(a.dataStack, ptr[i]);
	return nextOperation(a, cur);
}


@system immutable(NextOperation) opReadNat8(immutable size_t offsetBytes)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat8", offsetBytes);
	push(a.dataStack, *((cast(immutable ubyte*) pop(a.dataStack)) + offsetBytes));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadNat16(immutable size_t offsetNat16s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat16", offsetNat16s);
	push(a.dataStack, *((cast(immutable ushort*) pop(a.dataStack)) + offsetNat16s));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadNat32(immutable size_t offsetNat32s)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opReadNat32", offsetNat32s);
	push(a.dataStack, *((cast(immutable uint*) pop(a.dataStack)) + offsetNat32s));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opReadBytesVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);
	debug log(a.dbg, "opReadBytesVariable", offsetBytes, sizeBytes);
	immutable ubyte* ptr = (cast(immutable ubyte*) pop(a.dataStack)) + offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opWrite(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opWrite");
	immutable size_t offset = readSizeT(cur);
	immutable size_t size = readSizeT(cur);
	if (size < 8) { //TODO:UNNECESSARY?
		verify(size != 0);
		immutable ulong value = pop(a.dataStack);
		ubyte* ptr = cast(ubyte*) pop(a.dataStack);
		writePartialBytes(ptr + offset, value, size);
	} else {
		immutable size_t sizeWords = divRoundUp(size, 8);
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords);
		ubyte* src = cast(ubyte*) (stackEnd(a.dataStack) - sizeWords);
		ubyte* dest = destWithoutOffset + offset;
		memcpy(dest, src, size);
		popN(a.dataStack, sizeWords + 1);
	}
	return nextOperation(a, cur);
}

private @system void writePartialBytes(ubyte* ptr, immutable ulong value, immutable size_t size) {
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

@system immutable(NextOperation) opCall(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opCall");
	immutable ByteCodeIndex address = immutable ByteCodeIndex(readSizeT(cur));
	return callCommon(a, address, cur);
}

@system immutable(NextOperation) opCallFunPtr(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opCallFunPtr");
	immutable size_t parametersSize = readSizeT(cur);
	//TODO: handle a real function pointer being here?
	immutable ByteCodeIndex address = immutable ByteCodeIndex(safeToSizeT(remove(a.dataStack, parametersSize)));
	return callCommon(a, address, cur);
}

private @system immutable(NextOperation) callCommon(
	ref Interpreter a,
	immutable ByteCodeIndex address,
	immutable Operation* cur,
) {
	push(a.returnStack, cur);
	return nextOperation(a, &a.byteCode.byteCode[address.index]);
}

@system immutable(NextOperation) opExtern(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opExtern");
	immutable ExternOp op = cast(ExternOp) readNat64(cur);
	final switch (op) {
		case ExternOp.backtrace:
			immutable int size = cast(int) pop(a.dataStack);
			void** array = cast(void**) pop(a.dataStack);
			immutable size_t res = backtrace(a, array, cast(uint) size);
			verify(res <= int.max);
			push(a.dataStack, res);
			break;
		case ExternOp.clockGetTime:
			Ptr!TimeSpec timespecPtr = Ptr!TimeSpec(cast(TimeSpec*) pop(a.dataStack));
			immutable int clockId = cast(int) pop(a.dataStack);
			push(a.dataStack, cast(immutable ulong) a.extern_.clockGetTime(clockId, timespecPtr));
			break;
		case ExternOp.free:
			a.extern_.free(cast(ubyte*) pop(a.dataStack));
			break;
		case ExternOp.getNProcs:
			push(a.dataStack, 1);
			break;
		case ExternOp.longjmp:
			immutable ulong val = pop(a.dataStack); // TODO: verify this is int32?
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack);
			cur = applyInterpreterRestore(a, **jmpBufPtr);
			//TODO: freeInterpreterRestore
			push(a.dataStack, val);
			break;
		case ExternOp.malloc:
			immutable ulong nBytes = safeToSizeT(pop(a.dataStack));
			push(a.dataStack, cast(immutable ulong) a.extern_.malloc(nBytes));
			break;
		case ExternOp.memcpy:
		case ExternOp.memmove:
			immutable size_t size = safeToSizeT(pop(a.dataStack));
			const ubyte* src = cast(ubyte*) pop(a.dataStack);
			ubyte* dest = cast(ubyte*) pop(a.dataStack);
			ubyte* res = memmove(dest, src, size);
			push(a.dataStack, cast(immutable ulong) res);
			break;
		case ExternOp.memset:
			immutable size_t size = safeToSizeT(pop(a.dataStack));
			immutable ubyte value = cast(ubyte) pop(a.dataStack);
			ubyte* begin = cast(ubyte*) pop(a.dataStack);
			ubyte* res = memset(begin, value, size);
			push(a.dataStack, cast(immutable ulong) res);
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
			push(a.dataStack, 0);
			break;
		case ExternOp.pthreadCondattrSetClock:
		case ExternOp.pthreadCondInit:
		case ExternOp.pthreadMutexInit:
			pop(a.dataStack);
			pop(a.dataStack);
			push(a.dataStack, 0);
			break;
		case ExternOp.schedYield:
			push(a.dataStack, 0);
			break;
		case ExternOp.setjmp:
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack);
			overwriteMemory(jmpBufPtr, createInterpreterRestore(a, cur));
			push(a.dataStack, 0);
			break;
		case ExternOp.write:
			immutable size_t nBytes = safeToSizeT(pop(a.dataStack));
			immutable char* buf = cast(immutable char*) pop(a.dataStack);
			immutable int fd = cast(int) pop(a.dataStack);
			immutable long res = a.extern_.write(fd, buf, nBytes);
			push(a.dataStack, res);
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

@system immutable(NextOperation) opExternDynCall(ref Interpreter a, immutable(Operation)* cur) {
	immutable Sym name = immutable Sym(readNat64(cur));
	debug {
		logNoNewline(a.dbg, "opExternDynCall ");
		logSymNoNewline(a.dbg, a.allSymbols, name);
		log(a.dbg, "");
	}
	immutable DynCallType returnType = cast(immutable DynCallType) readNat64(cur);
	scope immutable DynCallType[] parameterTypes = readArray!DynCallType(cur);
	scope immutable ulong[] params = popN(a.dataStack, parameterTypes.length);
	immutable ulong value = a.extern_.doDynCall(name, returnType, params, parameterTypes);
	if (returnType != DynCallType.void_)
		push(a.dataStack, value);
	return nextOperation(a, cur);
}

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
private alias JmpBufTag = InterpreterRestore*;

@system immutable(NextOperation) opFnUnary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opFnUnary", __traits(identifier, cb));
	push(a.dataStack, cb(pop(a.dataStack)));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opFnBinary(alias cb)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opFnBinary", __traits(identifier, cb));
	immutable ulong y = pop(a.dataStack);
	immutable ulong x = pop(a.dataStack);
	push(a.dataStack, cb(x, y));
	return nextOperation(a, cur);
}

private @system immutable(NextOperation) nextOperation(ref Interpreter a, immutable Operation* cur) {
	static if (false)
		return getNextOperationAndDebug(a, cur);
	version(TailRecursionAvialable) {
		return cur.fn(a, cur + 1);
	}
	return immutable NextOperation(cur);
}

private @system immutable(Operation) readOperation(scope ref immutable(Operation)* cur) {
	immutable Operation res = *cur;
	cur++;
	return res;
}

private @system immutable(size_t) readStackOffset(ref immutable(Operation)* cur) {
	return readSizeT(cur);
}

private @system immutable(long) readInt64(ref immutable(Operation)* cur) {
	return readOperation(cur).long_;
}

private @system immutable(ulong) readNat64(ref immutable(Operation)* cur) {
	return readOperation(cur).ulong_;
}

private @system immutable(size_t) readSizeT(ref immutable(Operation)* cur) {
	return safeToSizeT(readNat64(cur));
}

private @system immutable(T[]) readArray(T)(ref immutable(Operation)* cur) {
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

@system immutable(NextOperation) opJump(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opJump");
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readInt64(cur));
	return nextOperation(a, cur + offset.offset);
}

@system immutable(NextOperation) opPack(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opPack");
	immutable size_t inEntries = readSizeT(cur);
	immutable size_t outEntries = readSizeT(cur);
	immutable PackField[] fields = readArray!PackField(cur);

	ubyte* base = cast(ubyte*) (stackEnd(a.dataStack) - inEntries);
	foreach (immutable PackField field; fields)
		memmove(base + field.outOffset, base + field.inOffset, safeToSizeT(field.size));

	// drop extra entries
	drop(popN(a.dataStack, inEntries - outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + fields[$ - 1].outOffset + fields[$ - 1].size;
	while (ptr < cast(ubyte*) stackEnd(a.dataStack)) {
		*ptr = 0;
		ptr++;
	}

	return nextOperation(a, cur);
}

@system immutable(NextOperation) opPushValue64(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opPushValue64");
	push(a.dataStack, readNat64(cur));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupBytes(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupBytes");
	immutable size_t offsetBytes = readSizeT(cur);
	immutable size_t sizeBytes = readSizeT(cur);

	const ubyte* ptr = (cast(const ubyte*) stackEnd(a.dataStack)) - offsetBytes;
	readNoCheck(a.dataStack, ptr, sizeBytes);
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWord(immutable size_t offsetWords)(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupWord", offsetWords);
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWordVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readSizeT(cur);
	debug log(a.dbg, "opDupWordVariable", offsetWords);
	push(a.dataStack, peek(a.dataStack, offsetWords));
	return nextOperation(a, cur);
}

@system immutable(NextOperation) opDupWords(ref Interpreter a, immutable(Operation)* cur) {
	debug log(a.dbg, "opDupWords");
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	const(ulong)* ptr = stackTop(a.dataStack) - offsetWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		push(a.dataStack, *ptr);
		ptr++;
	}
	return nextOperation(a, cur);
}

// Copies data from the top of the stack to write to something lower on the stack.
@system immutable(NextOperation) opSet(immutable size_t offsetWords, immutable size_t sizeWords)(
	ref Interpreter a,
	immutable Operation* cur,
) {
	debug log(a.dbg, "opSet", offsetWords, sizeWords);
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

@system immutable(NextOperation) opSetVariable(ref Interpreter a, immutable(Operation)* cur) {
	immutable size_t offsetWords = readStackOffset(cur);
	immutable size_t sizeWords = readSizeT(cur);
	debug log(a.dbg, "opSetVariable", offsetWords, sizeWords);
	return opSetCommon(a, cur, offsetWords, sizeWords);
}

private @system immutable(NextOperation) opSetCommon(
	ref Interpreter a,
	immutable Operation* cur,
	immutable size_t offsetWords,
	immutable size_t sizeWords,
) {
	// Start at the end of the range and pop in reverse
	const ulong* begin = stackTop(a.dataStack) - offsetWords;
	const(ulong)* ptr = begin + sizeWords;
	foreach (immutable size_t i; 0 .. sizeWords) {
		ptr--;
		overwriteMemory(ptr, pop(a.dataStack));
	}
	verify(ptr == begin);
	return nextOperation(a, cur);
}

private @system void readNoCheck(ref DataStack dataStack, const ubyte* readFrom, immutable size_t sizeBytes) {
	ubyte* outPtr = cast(ubyte*) stackEnd(dataStack);
	immutable size_t sizeWords = divRoundUp(sizeBytes, ulong.sizeof);
	pushUninitialized(dataStack, sizeWords);
	memcpy(outPtr, readFrom, sizeBytes);

	ubyte* endPtr = outPtr + sizeBytes;
	while (endPtr < cast(ubyte*) stackEnd(dataStack)) {
		*endPtr = 0;
		endPtr++;
	}
}
