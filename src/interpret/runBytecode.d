module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import frontend.showDiag : ShowDiagOptions;
import interpret.applyFn : applyFn;
import interpret.bytecode :
	asCall,
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	DebugOperation,
	DynCallType,
	isCall,
	ExternOp,
	matchDebugOperationImpure,
	matchOperationImpure,
	Operation,
	reprOperation,
	StackOffset,
	TimeSpec;
import interpret.bytecodeReader :
	ByteCodeReader,
	getReaderPtr,
	newByteCodeReader,
	readerJump,
	readOperation,
	readerSwitch,
	readerSwitchWithValues,
	setReaderPtr;
import interpret.debugging : writeFunName;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowFunSource, LowProgram, matchLowFunSource;
import util.alloc.alloc : Alloc, TempAlloc;
import util.dbg : log, logNoNewline;
import util.collection.arr : begin, freeArr, last, ptrAt, sizeNat;
import util.collection.arrUtil : mapWithFirst;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.collection.globalAllocatedStack :
	asTempArr,
	begin,
	clearStack,
	dup,
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
import util.collection.str : CStr, freeCStr, strToCStr;
import util.memory : allocate, memcpy, memmove, memset, overwriteMemory;
import util.opt : has;
import util.path : AbsolutePath, AllPaths, pathToCStr;
import util.ptr : contains, Ptr, PtrRange, ptrRangeOfArr, ptrTrustMe, ptrTrustMe_mut;
import util.repr : writeReprNoNewline;
import util.sourceRange : FileAndPos;
import util.sym : logSym;
import util.types :
	incr,
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

@trusted immutable(int) runBytecode(Debug, Extern)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	ref Extern extern_,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	ref immutable AbsolutePath executablePath,
	ref immutable string[] args,
) {
	Interpreter!Extern interpreter = Interpreter!Extern(
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(filesInfo));

	immutable CStr firstArg = pathToCStr(tempAlloc, allPaths, executablePath);
	immutable CStr[] allArgs = mapWithFirst!(CStr, string)(tempAlloc, firstArg, args, (ref immutable string arg) =>
		strToCStr(tempAlloc, arg));
	scope(exit) {
		foreach (immutable CStr arg; allArgs)
			freeCStr(tempAlloc, arg);
		freeArr(tempAlloc, allArgs);
	}

	push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
	// These need to be CStrs
	push(interpreter.dataStack, immutable Nat64(cast(immutable ulong) begin(allArgs)));
	for (;;) {
		final switch (step(dbg, tempAlloc, allPaths, interpreter)) {
			case StepResult.continue_:
				break;
			case StepResult.exit:
				immutable Nat64 returnCode = pop(interpreter.dataStack);
				verify(isEmpty(interpreter.dataStack));
				return safeIntFromNat64(returnCode);
		}
	}

}

enum StepResult {
	continue_,
	exit,
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 64);
private alias ReturnStack = GlobalAllocatedStack!(immutable(ubyte)*, 1024 * 4);
// Gives start stack position of each function
private alias StackStartStack = GlobalAllocatedStack!(Nat16, 1024 * 4);

struct Interpreter(Extern) {
	@safe @nogc nothrow: // not pure

	@disable this(ref const Interpreter);

	@trusted this(Ptr!Extern e, immutable Ptr!LowProgram p, immutable Ptr!ByteCode b, immutable Ptr!FilesInfo f) {
		externPtr = e;
		lowProgramPtr = p;
		byteCodePtr = b;
		filesInfoPtr = f;
		reader = newByteCodeReader(begin(byteCode.byteCode), byteCode.main.index);
		dataStack = DataStack(true);
		returnStack = ReturnStack(true);
		stackStartStack = StackStartStack(true);
	}

	Ptr!Extern externPtr;
	immutable Ptr!LowProgram lowProgramPtr;
	immutable Ptr!ByteCode byteCodePtr;
	immutable Ptr!FilesInfo filesInfoPtr;
	ByteCodeReader reader;
	DataStack dataStack;
	ReturnStack returnStack;
	// Parallel to return stack. Has the stack entry before the function's arguments.
	StackStartStack stackStartStack;
	// WARN: if adding any new mutable state here, make sure 'longjmp' still restores it

	ref inout(Extern) extern_() inout {
		return externPtr.deref();
	}
	ref immutable(LowProgram) lowProgram() const {
		return lowProgramPtr.deref();
	}
	ref immutable(ByteCode) byteCode() const {
		return byteCodePtr.deref();
	}
	ref immutable(FilesInfo) filesInfo() const {
		return filesInfoPtr.deref();
	}
}

// WARN: Does not restore data. Just mean for setjmp/longjmp.
private struct InterpreterRestore {
	// This is the stack sizes and byte code index to be restored by longjmp
	immutable ByteCodeIndex nextByteCodeIndex;
	immutable Nat32 dataStackSize;
	immutable ubyte*[] restoreReturnStack;
	immutable Nat16[] restoreStackStartStack;
}

private immutable(InterpreterRestore*) createInterpreterRestore(Extern)(
	ref Alloc alloc,
	ref Interpreter!Extern a,
) {
	immutable InterpreterRestore value = immutable InterpreterRestore(
		nextByteCodeIndex(a),
		stackSize(a.dataStack),
		toArr(alloc, a.returnStack),
		toArr(alloc, a.stackStartStack));
	return allocate(alloc, value).rawPtr();
}

private void applyInterpreterRestore(Extern)(ref Interpreter!Extern a, ref immutable InterpreterRestore restore) {
	setNextByteCodeIndex(a, restore.nextByteCodeIndex);
	reduceStackSize(a.dataStack, restore.dataStackSize.raw());
	setToArr(a.returnStack, restore.restoreReturnStack);
	setToArr(a.stackStartStack, restore.restoreStackStartStack);
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
	foreach (immutable ubyte* ptr; asTempArr(a.returnStack)) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, a, getReaderPtr(a.reader));
}

private void writeByteCodeSource(
	scope ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	ref immutable ByteCodeSource source,
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
	immutable ubyte* ptr,
) {
	writeFunNameAtIndex(writer, interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

private immutable(ByteCodeSource) byteCodeSourceAtIndex(Extern)(
	ref const Interpreter!Extern a,
	immutable ByteCodeIndex index,
) {
	return fullIndexDictGet(a.byteCode.sources, index);
}

private immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(Extern)(
	ref const Interpreter!Extern a,
	immutable ubyte* ptr,
) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(Extern)(ref const Interpreter!Extern a) {
	return byteCodeIndexOfPtr(a, getReaderPtr(a.reader));
}

private void setNextByteCodeIndex(Extern)(ref Interpreter!Extern a, immutable ByteCodeIndex index) {
	setReaderPtr(a.reader, ptrAt(a.byteCode.byteCode, index.index.raw()).rawPtr());
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(Extern)(
	ref const Interpreter!Extern a,
	immutable ubyte* ptr,
) {
	return immutable ByteCodeIndex((immutable Nat64(ptr - begin(a.byteCode.byteCode))).to32());
}

private immutable(ByteCodeSource) nextSource(Extern)(ref const Interpreter!Extern a) {
	return byteCodeSourceAtByteCodePtr(a, getReaderPtr(a.reader));
}

immutable(StepResult) step(Debug, Extern)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref const AllPaths allPaths,
	ref Interpreter!Extern a,
) {
	immutable ByteCodeSource source = nextSource(a);
	if (dbg.enabled()) {
		import util.alloc.rangeAlloc : RangeAlloc;
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		showStack(writer, a);
		showReturnStack(writer, a);
		log(dbg, finishWriter(writer));
	}
	immutable Operation operation = readOperation(a.reader);
	if (dbg.enabled()) {
		import util.alloc.rangeAlloc : RangeAlloc;
		ubyte[10_000] mem;
		scope RangeAlloc dbgAlloc = RangeAlloc(&mem[0], mem.length);
		scope Writer writer = Writer(ptrTrustMe_mut(dbgAlloc));
		writeStatic(writer, "STEP: ");
		immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(false);
		writeByteCodeSource(writer, allPaths, showDiagOptions, a.lowProgram, a.filesInfo, source);
		writeChar(writer, ' ');
		writeReprNoNewline(writer, reprOperation(tempAlloc, operation));
		if (isCall(operation)) {
			immutable Operation.Call call = asCall(operation);
			writeStatic(writer, "(");
			writeFunNameAtIndex(writer, a, call.address);
			writeChar(writer, ')');
		}
		writeChar(writer, '\n');
		log(dbg, finishWriter(writer));
	}

	return matchOperationImpure!(immutable StepResult)(
		operation,
		(ref immutable Operation.Call it) {
			call(a, it.address, it.parametersSize);
			return StepResult.continue_;
		},
		(ref immutable Operation.CallFunPtr it) {
			//TODO: handle a real function pointer being here?
			immutable ByteCodeIndex address = immutable ByteCodeIndex(
				removeAtStackOffset(a, immutable StackOffset(it.parametersSize)).to32());
			call(a, address, it.parametersSize);
			return StepResult.continue_;
		},
		(ref immutable Operation.Debug dbg) {
			matchDebugOperationImpure!void(
				dbg.debugOperation,
				(ref immutable DebugOperation.AssertStackSize it) {
					immutable Nat16 stackStart = isEmpty(a.stackStartStack)
						? immutable Nat16(0)
						: peek(a.stackStartStack);
					immutable Nat32 actualStackSize = stackSize(a.dataStack) - stackStart.to32();
					verify(actualStackSize == it.stackSize.to32());
				},
				(ref immutable DebugOperation.AssertUnreachable) {
					unreachable!void();
				});
			return StepResult.continue_;
		},
		(ref immutable Operation.Dup it) {
			dup(a.dataStack, it);
			return StepResult.continue_;
		},
		(ref immutable Operation.Extern it) {
			applyExternOp(tempAlloc, a, it.op);
			return StepResult.continue_;
		},
		(ref immutable Operation.ExternDynCall it) {
			applyExternDynCall(dbg, a, it);
			return StepResult.continue_;
		},
		(ref immutable Operation.Fn it) {
			applyFn(dbg, a.dataStack, it.fnOp);
			return StepResult.continue_;
		},
		(ref immutable Operation.Jump it) {
			readerJump(a.reader, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Pack it) {
			// NOTE: popped is temporary, but we'll use each entry before it's overwritten
			pack(a.dataStack, it);
			return StepResult.continue_;
		},
		(ref immutable Operation.PushValue it) {
			push(a.dataStack, it.value);
			return StepResult.continue_;
		},
		(ref immutable Operation.Read it) {
			read(tempAlloc, a, it.offset, it.size);
			return StepResult.continue_;
		},
		(ref immutable Operation.Remove it) {
			remove(a.dataStack, it.offset.offset, it.nEntries);
			return StepResult.continue_;
		},
		(ref immutable Operation.Return) {
			if (isEmpty(a.returnStack))
				return StepResult.exit;
			else {
				setReaderPtr(a.reader, pop(a.returnStack));
				pop(a.stackStartStack);
				return StepResult.continue_;
			}
		},
		(ref immutable Operation.StackRef it) {
			pushStackRef(a.dataStack, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Switch0ToN it) {
			readerSwitch(a.reader, pop(a.dataStack), it.offsets);
			return StepResult.continue_;
		},
		(ref immutable Operation.SwitchWithValues it) {
			readerSwitchWithValues(a.reader, pop(a.dataStack), it.values, it.offsets);
			return StepResult.continue_;
		},
		(ref immutable Operation.Write it) {
			write(tempAlloc, a, it.offset, it.size);
			return StepResult.continue_;
		});
}

private:

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	push(dataStack, immutable Nat64(cast(immutable ulong) stackRef(dataStack, offset.offset)));
}

@trusted void read(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	immutable ubyte* ptr = cast(immutable ubyte*) pop(a.dataStack).raw();
	checkPtr(tempAlloc, a, ptr, offset, size);
	readNoCheck(a.dataStack, ptr + offset.raw(), size.raw());
}

@system void checkPtr(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
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

@system void writePtrRanges(Extern)(ref Writer writer, ref const Interpreter!Extern a) {
	writeStatic(writer, "\ndata: ");
	writePtrRange(writer, stackPtrRange(a.dataStack));
	writeStatic(writer, "\nmalloced:\n");
	a.extern_.writeMallocedRanges(writer);
	writeStatic(writer, "\ntext:\n");
	writePtrRange(writer, ptrRangeOfArr(a.byteCode.text));
	writeChar(writer, '\n');
}

@trusted void write(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	if (size < immutable Nat16(8)) { //TODO:UNNECESSARY?
		verify(size != immutable Nat16(0));
		immutable Nat64 value = pop(a.dataStack);
		ubyte* ptr = cast(ubyte*) pop(a.dataStack).raw();
		checkPtr(tempAlloc, a, ptr, offset, size);
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		immutable Nat16 sizeWords = divRoundUp(size, immutable Nat16(8));
		ubyte* destWithoutOffset = cast(ubyte*) peek(a.dataStack, sizeWords.to8()).raw();
		checkPtr(tempAlloc, a, destWithoutOffset, offset, size);
		ubyte* src = cast(ubyte*) (end(a.dataStack) - sizeWords.raw());
		ubyte* dest = destWithoutOffset + offset.raw();
		memcpy(dest, src, size.raw());
		popN(a.dataStack, incr(sizeWords).to8());
	}
}

@trusted void writePartialBytes(ubyte* ptr, immutable ulong value, immutable ushort size) {
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

void call(Extern)(ref Interpreter!Extern a, immutable ByteCodeIndex address, immutable Nat8 parametersSize) {
	push(a.returnStack, getReaderPtr(a.reader));
	push(a.stackStartStack, (stackSize(a.dataStack) - parametersSize.to32()).to16());
	setNextByteCodeIndex(a, address);
}

immutable(Nat64) removeAtStackOffset(Extern)(ref Interpreter!Extern a, immutable StackOffset offset) {
	return remove(a.dataStack, offset.offset);
}

//TODO: not @trusted
@trusted void applyExternOp(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	immutable ExternOp op,
) {
	final switch (op) {
		case ExternOp.backtrace:
			immutable int size = cast(int) pop(a.dataStack).to32().raw();
			void** array = cast(void**) pop(a.dataStack).raw();
			immutable size_t res = backtrace(tempAlloc, a, array, safeU32FromI32(size));
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
			checkPtr(tempAlloc, a, cast(const ubyte*) jmpBufPtr, immutable Nat16(0), immutable Nat16(JmpBufTag.sizeof));
			overwriteMemory(jmpBufPtr, createInterpreterRestore(tempAlloc, a));
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
}

@system immutable(size_t) backtrace(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	void** res,
	immutable uint size,
) {
	checkPtr(
		tempAlloc,
		a,
		cast(const ubyte*) res,
		immutable Nat16(0),
		(immutable Nat64((void*).sizeof * size)).to16());
	immutable size_t resSize = min(stackSize(a.returnStack).raw(), size);
	foreach (immutable size_t i; 0 .. resSize)
		res[i] = cast(void*) byteCodeIndexOfPtr(a, a.returnStack.peek((immutable Nat64(i)).to8())).index.raw();
	return resSize;
}

void applyExternDynCall(Debug, Extern)(
	ref Debug dbg,
	ref Interpreter!Extern a,
	ref immutable Operation.ExternDynCall op,
) {
	if (dbg.enabled()) {
		logNoNewline(dbg, "Running extern function ");
		logSym(dbg, op.name);
	}

	immutable Nat64[] params = popN(a.dataStack, sizeNat(op.parameterTypes).to8());
	immutable Nat64 value = a.extern_.doDynCall(op.name, op.returnType, params, op.parameterTypes);
	if (op.returnType != DynCallType.void_)
		push(a.dataStack, value);
}

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
alias JmpBufTag = immutable InterpreterRestore*;

@trusted void pack(ref DataStack dataStack, scope immutable Operation.Pack pack) {
	ubyte* base = cast(ubyte*) (end(dataStack) - pack.inEntries.raw());
	foreach (immutable Operation.Pack.Field field; pack.fields)
		memmove(base + field.outOffset.raw(), base + field.inOffset.raw(), field.size.raw());

	// drop extra entries
	drop(popN(dataStack, pack.inEntries - pack.outEntries));

	// fill remaining bytes with 0
	ubyte* ptr = base + last(pack.fields).outOffset.raw() + last(pack.fields).size.raw();
	while (ptr < cast(ubyte*) end(dataStack)) {
		*ptr = 0;
		ptr++;
	}
}

@trusted void dup(ref DataStack dataStack, scope immutable Operation.Dup dup) {
	const ubyte* ptr = (cast(const ubyte*) end(dataStack)) - dup.offsetBytes.offsetBytes.raw();
	readNoCheck(dataStack, ptr, dup.sizeBytes.raw());
}

@system void readNoCheck(ref DataStack dataStack, const ubyte* readFrom, immutable size_t sizeBytes) {
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
