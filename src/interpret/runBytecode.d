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
	setReaderPtr;
import interpret.debugging : writeFunName;
import interpret.externAlloc : ExternAlloc;
import model.concreteModel : ConcreteFun, concreteFunRange;
import model.diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import model.lowModel : LowFunSource, LowProgram, matchLowFunSource;
import util.bools : False;
import util.dbg : log, logNoNewline;
import util.collection.arr : begin, freeArr, ptrAt, sizeNat;
import util.collection.arrUtil : mapWithFirst, zipSystem;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.collection.globalAllocatedStack :
	asTempArr,
	begin,
	clearStack,
	dup,
	GlobalAllocatedStack,
	isEmpty,
	peek,
	pop,
	popN,
	push,
	reduceStackSize,
	remove,
	setToArr,
	stackPtrRange,
	stackRef,
	stackSize,
	toArr;
import util.collection.str : CStr, freeCStr, strOfNulTerminatedStr, strToCStr;
import util.memory : allocate, overwriteMemory;
import util.opt : has;
import util.path : AbsolutePath, AllPaths, pathToCStr;
import util.ptr : contains, Ptr, PtrRange, ptrRangeOfArr, ptrTrustMe, ptrTrustMe_mut;
import util.repr : writeReprNoNewline;
import util.sourceRange : FileAndPos;
import util.types :
	decr,
	incr,
	i32OfU64Bits,
	Nat8,
	Nat16,
	Nat32,
	Nat64,
	safeIntFromNat64,
	safeSizeTFromI32,
	safeSizeTFromU64,
	u8,
	u16,
	u32,
	u64,
	zero;
import util.util : min, todo, unreachable, verify;
import util.writer : finishWriter, Writer, writeChar, writeHex, writePtrRange, writeStatic;

@trusted immutable(int) runBytecode(Debug, TempAlloc, PathAlloc, Extern)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
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

	ExternAlloc!Extern externAlloc = ExternAlloc!Extern(ptrTrustMe_mut(extern_));
	immutable CStr firstArg = pathToCStr(externAlloc, allPaths, executablePath);
	immutable CStr[] allArgs = mapWithFirst!(CStr, string)(externAlloc, firstArg, args, (ref immutable string arg) =>
		strToCStr(externAlloc, arg));

	push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
	// These need to be CStrs
	push(interpreter.dataStack, immutable Nat64(cast(immutable u64) begin(allArgs)));
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

	foreach (immutable CStr arg; allArgs)
		freeCStr(externAlloc, arg);
	freeArr(externAlloc, allArgs);
}

enum StepResult {
	continue_,
	exit,
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 4);
private alias ReturnStack = GlobalAllocatedStack!(immutable(u8)*, 1024);
// Gives start stack position of each function
private alias StackStartStack = GlobalAllocatedStack!(Nat16, 1024);

struct Interpreter(Extern) {
	@safe @nogc pure nothrow:
	@disable this(ref const Interpreter);

	@trusted this(Ptr!Extern e, immutable Ptr!LowProgram p, immutable Ptr!ByteCode b, immutable Ptr!FilesInfo f) {
		extern_ = e;
		lowProgram = p;
		byteCode = b;
		filesInfo = f;
		reader = newByteCodeReader(begin(byteCode.byteCode), byteCode.main.index);
	}

	Ptr!Extern extern_;
	immutable Ptr!LowProgram lowProgram;
	immutable Ptr!ByteCode byteCode;
	immutable Ptr!FilesInfo filesInfo;
	ByteCodeReader reader;
	DataStack dataStack;
	ReturnStack returnStack;
	// Parallel to return stack. Has the stack entry before the function's arguments.
	StackStartStack stackStartStack;
	// WARN: if adding any new mutable state here, make sure 'longjmp' still restores it
}

// WARN: Does not restore data. Just mean for setjmp/longjmp.
private struct InterpreterRestore {
	// This is the stack sizes and byte code index to be restored by longjmp
	immutable ByteCodeIndex nextByteCodeIndex;
	immutable Nat32 dataStackSize;
	immutable u8*[] restoreReturnStack;
	immutable Nat16[] restoreStackStartStack;
}

private immutable(InterpreterRestore*) createInterpreterRestore(Extern)(ref Interpreter!Extern a) {
	ExternAlloc!Extern externAlloc = ExternAlloc!Extern(ptrTrustMe_mut(a.extern_));
	immutable InterpreterRestore value = immutable InterpreterRestore(
		nextByteCodeIndex(a),
		stackSize(a.dataStack),
		toArr(externAlloc, a.returnStack),
		toArr(externAlloc, a.stackStartStack));
	return allocate(externAlloc, value).rawPtr();
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

private void showStack(Alloc, Extern)(ref Writer!Alloc writer, ref const Interpreter!Extern a) {
	immutable Nat64[] stack = asTempArr(a.dataStack);
	showDataArr(writer, stack);
}

@trusted void showDataArr(Alloc)(ref Writer!Alloc writer, scope ref immutable Nat64[] values) {
	writeStatic(writer, "data: ");
	foreach (immutable Nat64 value; values) {
		writeChar(writer, ' ');
		writeHex!Alloc(writer, value.raw());
	}
	writeChar(writer, '\n');
}

private @trusted void showReturnStack(Alloc, Extern)(ref Writer!Alloc writer, ref const Interpreter!Extern a) {
	writeStatic(writer, "call stack:");
	foreach (immutable u8* ptr; asTempArr(a.returnStack)) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, a, getReaderPtr(a.reader));
}

private void writeByteCodeSource(TempAlloc, Alloc, PathAlloc)(
	ref TempAlloc temp,
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions showDiagOptions,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	ref immutable ByteCodeSource source,
) {
	writeFunName(writer, lowProgram, source.fun);
	matchLowFunSource!void(
		fullIndexDictGet(lowProgram.allFuns, source.fun).source,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(concreteFunRange(it).fileIndex, source.pos);
			writeFileAndPos(temp, writer, allPaths, showDiagOptions, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {});
}

private void writeFunNameAtIndex(Alloc, Extern)(
	ref Writer!Alloc writer,
	ref const Interpreter!Extern interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, interpreter.lowProgram, byteCodeSourceAtIndex(interpreter, index).fun);
}

private void writeFunNameAtByteCodePtr(Alloc, Extern)(
	ref Writer!Alloc writer,
	ref const Interpreter!Extern interpreter,
	immutable u8* ptr,
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
	immutable u8* ptr,
) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(Extern)(ref const Interpreter!Extern a) {
	return byteCodeIndexOfPtr(a, getReaderPtr(a.reader));
}

private void setNextByteCodeIndex(Extern)(ref Interpreter!Extern a, immutable ByteCodeIndex index) {
	setReaderPtr(a.reader, ptrAt(a.byteCode.byteCode, index.index.raw()).rawPtr());
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(Extern)(ref const Interpreter!Extern a, immutable u8* ptr) {
	return immutable ByteCodeIndex((immutable Nat64(ptr - begin(a.byteCode.byteCode))).to32());
}

private immutable(ByteCodeSource) nextSource(Extern)(ref const Interpreter!Extern a) {
	return byteCodeSourceAtByteCodePtr(a, getReaderPtr(a.reader));
}

immutable(StepResult) step(Debug, TempAlloc, PathAlloc, Extern)(
	ref Debug dbg,
	ref TempAlloc tempAlloc,
	ref const AllPaths!PathAlloc allPaths,
	ref Interpreter!Extern a,
) {
	immutable ByteCodeSource source = nextSource(a);
	if (dbg.enabled()) {
		Writer!TempAlloc writer = Writer!TempAlloc(ptrTrustMe_mut(tempAlloc));
		showStack(writer, a);
		showReturnStack(writer, a);
		log(dbg, finishWriter(writer));
	}
	immutable Operation operation = readOperation(a.reader);
	if (dbg.enabled()) {
		Writer!TempAlloc writer = Writer!TempAlloc(ptrTrustMe_mut(tempAlloc));
		writeStatic(writer, "STEP: ");
		immutable ShowDiagOptions showDiagOptions = immutable ShowDiagOptions(False);
		writeByteCodeSource(tempAlloc, writer, allPaths, showDiagOptions, a.lowProgram, a.filesInfo, source);
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
			dup(a.dataStack, it.offset.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.DupPartial it) {
			push(
				a.dataStack,
				getBytes(peek(a.dataStack, it.entryOffset.offset), it.byteOffset, it.sizeBytes));
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
			push(a.dataStack, pack(popN(a.dataStack, sizeNat(it.sizes).to8()), it.sizes));
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
		(ref immutable Operation.Switch it) {
			readerSwitch(a.reader, pop(a.dataStack), it.offsets);
			return StepResult.continue_;
		},
		(ref immutable Operation.Write it) {
			write(tempAlloc, a, it.offset, it.size);
			return StepResult.continue_;
		});
}

private:

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	push(dataStack, immutable Nat64(cast(immutable u64) stackRef(dataStack, offset.offset)));
}

@trusted void read(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	immutable u8* ptr = cast(immutable u8*) pop(a.dataStack).raw();
	checkPtr(tempAlloc, a, ptr, offset, size);
	if (size < immutable Nat16(8)) { //TODO: just have 2 different ops then
		push(a.dataStack, readPartialBytes(ptr + offset.raw(), size.raw()));
	} else {
		verify(zero(size % immutable Nat16(8)));
		verify(zero(offset % immutable Nat16(8)));
		foreach (immutable size_t i; 0..(size.raw() / 8))
			push(a.dataStack, ((cast(immutable Nat64*) ptr) + (offset.raw() / 8))[i]);
	}
}

@system void checkPtr(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref const Interpreter!Extern a,
	const u8* ptrWithoutOffset,
	immutable Nat16 offset,
	immutable Nat16 size,
) {
	const u8* ptr = ptrWithoutOffset + offset.raw();
	const PtrRange ptrRange = const PtrRange(ptr, ptr + size.raw());
	if (!contains(stackPtrRange(a.dataStack), ptrRange)
		&& !a.extern_.hasMallocedPtr(ptrRange)
		&& !contains(ptrRangeOfArr(a.byteCode.text), ptrRange)) {
		debug {
			Writer!TempAlloc writer = Writer!TempAlloc(ptrTrustMe_mut(tempAlloc));
			writeStatic(writer, "accessing potentially invalid pointer: ");
			writePtrRange(writer, ptrRange);
			writePtrRanges(writer, a);
			//print()
			finishWriter(writer);
		}
		//todo!void("ptr not valid");
	}
}

@system void writePtrRanges(Alloc, Extern)(ref Writer!Alloc writer, ref const Interpreter!Extern a) {
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
	if (size < immutable Nat16(8)) { //TODO: just have 2 different ops then
		immutable Nat64 value = pop(a.dataStack);
		u8* ptr = cast(u8*) pop(a.dataStack).raw();
		checkPtr(tempAlloc, a, ptr, offset, size);
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		verify(zero(size % immutable Nat16(8)));
		verify(zero(offset % immutable Nat16(8)));
		immutable Nat16 offsetWords = offset / immutable Nat16(8);
		immutable Nat16 sizeWords = size / immutable Nat16(8);
		Nat64* ptrWithoutOffset = (cast(Nat64*) peek(a.dataStack, sizeWords.to8()).raw());
		checkPtr(
			tempAlloc,
			a,
			cast(const u8*) ptrWithoutOffset,
			offsetWords * immutable Nat16(8),
			sizeWords * immutable Nat16(8));
		Nat64* ptr = ptrWithoutOffset + offsetWords.raw();
		foreach (immutable ushort i; 0..sizeWords.raw())
			ptr[i] = peek(a.dataStack, (decr(sizeWords) - immutable Nat16(i)).to8());
		popN(a.dataStack, incr(sizeWords).to8());
	}
}

@trusted immutable(Nat64) readPartialBytes(immutable u8* ptr, immutable ushort size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			return (*(cast(immutable Nat8*) ptr)).to64();
		case 2:
			return (*(cast(immutable Nat16*) ptr)).to64();
		case 4:
			return (*(cast(immutable Nat32*) ptr)).to64();
		default:
			return unreachable!(immutable Nat64);
	}
}

@trusted void writePartialBytes(u8* ptr, immutable u64 value, immutable ushort size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			*(cast(u8*) ptr) = cast(immutable u8) value;
			break;
		case 2:
			*(cast(u16*) ptr) = cast(immutable u16) value;
			break;
		case 4:
			*(cast(u32*) ptr) = cast(immutable u32) value;
			break;
		default:
			unreachable!void();
			break;
	}
}

//TODO:MOVE?
@trusted immutable(Nat64) getBytes(immutable Nat64 a, immutable Nat8 byteOffset, immutable Nat8 sizeBytes) {
	verify(byteOffset + sizeBytes <= immutable Nat8(u64.sizeof));
	return readPartialBytes((cast(immutable u8*) &a) + byteOffset.raw(), sizeBytes.raw());
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
			immutable size_t res = backtrace(tempAlloc, a, array, safeSizeTFromI32(size));
			verify(res <= int.max);
			push(a.dataStack, immutable Nat64(res));
			break;
		case ExternOp.clockGetTime:
			Ptr!TimeSpec timespecPtr = Ptr!TimeSpec(cast(TimeSpec*) pop(a.dataStack).raw());
			immutable int clockId = i32OfU64Bits(pop(a.dataStack).raw());
			push(a.dataStack, immutable Nat64(cast(immutable u64) a.extern_.clockGetTime(clockId, timespecPtr)));
			break;
		case ExternOp.free:
			a.extern_.free(cast(u8*) pop(a.dataStack).raw());
			break;
		case ExternOp.getNProcs:
			push(a.dataStack, immutable Nat64(a.extern_.getNProcs()));
			break;
		case ExternOp.longjmp:
			immutable Nat64 val = pop(a.dataStack); // TODO: verify this is int32?
			const JmpBufTag* jmpBufPtr = cast(const JmpBufTag*) pop(a.dataStack).raw();
			applyInterpreterRestore(a, **jmpBufPtr);
			push(a.dataStack, val);
			break;
		case ExternOp.malloc:
			immutable ulong nBytes = safeSizeTFromU64(pop(a.dataStack).raw());
			push(a.dataStack, immutable Nat64(cast(immutable u64) a.extern_.malloc(nBytes)));
			break;
		case ExternOp.memcpy:
		case ExternOp.memmove:
			immutable size_t size = safeSizeTFromU64(pop(a.dataStack).raw());
			const ubyte* src = cast(ubyte*) pop(a.dataStack).raw();
			ubyte* dest = cast(ubyte*) pop(a.dataStack).raw();
			foreach (immutable size_t i; 0..size)
				dest[i] = src[i];
			break;
		case ExternOp.memset:
			immutable size_t size = safeSizeTFromU64(pop(a.dataStack).raw());
			immutable ubyte value = pop(a.dataStack).to8().raw();
			ubyte* begin = cast(ubyte*) pop(a.dataStack).raw();
			foreach (immutable size_t i; 0..size)
				begin[i] = value;
			break;
		case ExternOp.pthreadCreate:
			todo!void("pthread_create");
			break;
		case ExternOp.pthreadJoin:
			todo!void("pthread_join");
			break;
		case ExternOp.pthreadYield:
			push(a.dataStack, immutable Nat64(a.extern_.pthreadYield()));
			break;
		case ExternOp.setjmp:
			JmpBufTag* jmpBufPtr = cast(JmpBufTag*) pop(a.dataStack).raw();
			checkPtr(tempAlloc, a, cast(const u8*) jmpBufPtr, immutable Nat16(0), immutable Nat16(JmpBufTag.sizeof));
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
}

@system immutable(size_t) backtrace(TempAlloc, Extern)(
	ref TempAlloc tempAlloc,
	ref Interpreter!Extern a,
	void** res,
	immutable size_t size,
) {
	checkPtr(
		tempAlloc,
		a,
		cast(const ubyte*) res,
		immutable Nat16(0),
		(immutable Nat64((void*).sizeof * size)).to16());
	immutable size_t resSize = min(stackSize(a.returnStack).raw(), size);
	foreach (immutable size_t i; 0..resSize)
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
		log(dbg, strOfNulTerminatedStr(op.name));
	}

	immutable Nat64[] params = popN(a.dataStack, sizeNat(op.parameterTypes).to8());
	immutable Nat64 value = a.extern_.doDynCall(op.name, op.returnType, params, op.parameterTypes);
	if (op.returnType != DynCallType.void_)
		push(a.dataStack, value);
}

pure: // TODO: many more are pure actually..

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
alias JmpBufTag = immutable InterpreterRestore*;

@trusted immutable(Nat64) pack(immutable Nat64[] values, immutable Nat8[] sizes) {
	u64 res;
	u8* bytePtr = cast(u8*) &res;
	Nat64 totalSize = immutable Nat64(0);
	zipSystem!(Nat64, Nat8)(values, sizes, (ref immutable Nat64 value, ref immutable Nat8 size) {
		//TODO: use a 'size' type
		if (size == immutable Nat8(1))
			*bytePtr = value.to8().raw();
		else if (size == immutable Nat8(2))
			*(cast(u16*) bytePtr) = value.to16().raw();
		else if (size == immutable Nat8(4))
			*(cast(u32*) bytePtr) = value.to32().raw();
		else
			unreachable!void();
		bytePtr += size.raw();
		totalSize += size.to64();
	});
	verify(totalSize <= immutable Nat64(8));
	return immutable Nat64(res);
}
