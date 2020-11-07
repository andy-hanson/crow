module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import concreteModel : ConcreteFun, concreteFunRange;
import diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import interpret.applyFn : applyFn;
import interpret.bytecode :
	asCall,
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	DebugOperation,
	isCall,
	ExternOp,
	matchDebugOperationImpure,
	matchOperationImpure,
	Operation,
	sexprOfOperation,
	StackOffset;
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
import lowModel : LowFunSource, LowProgram, matchLowFunSource;
import util.alloc.stackAlloc : StackAlloc;
import util.bools : Bool, False;
import util.collection.arr : Arr, begin, freeArr, ptrAt, range, sizeNat;
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
import util.collection.str : CStr, freeCStr, Str, strToCStr;
import util.memory : allocate, overwriteMemory;
import util.opt : has;
import util.print : print;
import util.ptr : contains, Ptr, PtrRange, ptrRangeOfArr, ptrTrustMe, ptrTrustMe_mut;
import util.sexpr : writeSexprNoNewline;
import util.sourceRange : FileAndPos;
import util.types : decr, incr, Nat8, Nat16, Nat32, Nat64, safeIntFromNat64, u8, u16, u32, u64, zero;
import util.util : todo, unreachable, verify;
import util.writer : finishWriterToCStr, Writer, writeChar, writePtrRange, writeStatic;

@trusted immutable(int) runBytecode(Extern)(
	ref Extern extern_,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	immutable Str executablePath,
	immutable Arr!Str args,
) {
	Interpreter!Extern interpreter = newInterpreter(
		ptrTrustMe_mut(extern_),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(filesInfo));

	ExternAlloc!Extern externAlloc = ExternAlloc!Extern(ptrTrustMe_mut(extern_));
	immutable CStr firstArg = strToCStr(externAlloc, executablePath);
	immutable Arr!CStr allArgs = mapWithFirst!(CStr, Str)(externAlloc, firstArg, args, (ref immutable Str arg) =>
		strToCStr(externAlloc, arg));

	push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
	// These need to be CStrs
	push(interpreter.dataStack, immutable Nat64(cast(immutable u64) begin(allArgs)));
	for (;;) {
		final switch (step(interpreter)) {
			case StepResult.continue_:
				break;
			case StepResult.exit:
				immutable Nat64 returnCode = pop(interpreter.dataStack);
				verify(isEmpty(interpreter.dataStack));
				return safeIntFromNat64(returnCode);
		}
	}

	foreach (immutable CStr arg; range(allArgs))
		freeCStr(externAlloc, arg);
	freeArr(externAlloc, allArgs);
}

pure @trusted Interpreter!Extern newInterpreter(Extern)(
	Ptr!Extern extern_,
	immutable Ptr!LowProgram lowProgram,
	immutable Ptr!ByteCode byteCode,
	immutable Ptr!FilesInfo filesInfo,
) {
	return Interpreter!Extern(
		lowProgram,
		byteCode,
		filesInfo,
		newByteCodeReader(begin(byteCode.byteCode), byteCode.main.index),
		extern_);
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
	immutable Ptr!LowProgram lowProgram;
	immutable Ptr!ByteCode byteCode;
	immutable Ptr!FilesInfo filesInfo;
	ByteCodeReader reader;
	Extern extern_;
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
	immutable Arr!(immutable(u8)*) restoreReturnStack;
	immutable Arr!Nat16 restoreStackStartStack;
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

private void printStack(Extern)(ref const Interpreter!Extern a) {
	printDataArr(asTempArr(a.dataStack));
}

@trusted void printDataArr(immutable Arr!Nat64 values) {
	printf("data:");
	foreach (immutable Nat64 value; range(values))
		printf(" %lx", value.raw());
	printf("\n");
}

private @trusted void printReturnStack(Extern)(ref const Interpreter!Extern a) {
	alias Alloc = StackAlloc!("printReturnStack", 1024 * 8);
	Alloc alloc;
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, "call stack:");
	foreach (immutable u8* ptr; range(asTempArr(a.returnStack))) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, a, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, a, getReaderPtr(a.reader));
	printf("%s\n", finishWriterToCStr(writer));
}

private void writeByteCodeSource(TempAlloc, Alloc)(
	ref TempAlloc temp,
	ref Writer!Alloc writer,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	ref immutable ByteCodeSource source,
) {
	writeFunName(writer, lowProgram, source.fun);
	matchLowFunSource!void(
		fullIndexDictGet(lowProgram.allFuns, source.fun).source,
		(immutable Ptr!ConcreteFun it) {
			immutable FileAndPos where = immutable FileAndPos(concreteFunRange(it).fileIndex, source.pos);
			writeFileAndPos!(TempAlloc, Alloc)(temp, writer, filesInfo, where);
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

immutable(StepResult) step(Extern)(ref Interpreter!Extern a) {
	immutable ByteCodeSource source = nextSource(a);
	if (PRINT) {
		debug {
			printf("\n");
			printStack(a);
			printReturnStack(a);
		}
	}
	immutable Operation operation = readOperation(a.reader);
	if (PRINT) {
		debug {
			alias TempAlloc = StackAlloc!("temp", 1024 * 4);
			TempAlloc temp;
			Writer!TempAlloc writer = Writer!TempAlloc(ptrTrustMe_mut(temp));
			writeStatic(writer, "STEP: ");
			writeByteCodeSource(temp, writer, a.lowProgram, a.filesInfo, source);
			writeChar(writer, ' ');
			writeSexprNoNewline(writer, sexprOfOperation(temp, operation));
			if (isCall(operation)) {
				immutable Operation.Call call = asCall(operation);
				writeStatic(writer, "(");
				writeFunNameAtIndex(writer, a, call.address);
				writeChar(writer, ')');
			}
			writeChar(writer, '\n');
			print(finishWriterToCStr(writer));
		}
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
					debug {
						if (actualStackSize != it.stackSize.to32()) {
							printf(
								"actual stack size: %u, expected stack size: %u\n",
								actualStackSize.raw(), it.stackSize.raw());
						}
					}
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
			applyExternOp(a, it.op);
			return StepResult.continue_;
		},
		(ref immutable Operation.Fn it) {
			applyFn(a.dataStack, it.fnOp);
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
			read(a, it.offset, it.size);
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
			write(a, it.offset, it.size);
			return StepResult.continue_;
		});
}

private:

immutable Bool PRINT = False;

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	push(dataStack, immutable Nat64(cast(immutable u64) stackRef(dataStack, offset.offset)));
}

@trusted void read(Extern)(ref Interpreter!Extern a, immutable Nat8 offset, immutable Nat8 size) {
	immutable u8* ptr = cast(immutable u8*) pop(a.dataStack).raw();
	checkPtr(a, ptr, offset, size);
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		push(a.dataStack, readPartialBytes(ptr + offset.raw(), size.raw()));
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		foreach (immutable size_t i; 0..(size.raw() / 8))
			push(a.dataStack, ((cast(immutable Nat64*) ptr) + (offset.raw() / 8))[i]);
	}
}

@system void checkPtr(Extern)(
	ref const Interpreter!Extern a,
	const u8* ptrWithoutOffset,
	immutable Nat8 offset,
	immutable Nat8 size,
) {
	const u8* ptr = ptrWithoutOffset + offset.raw();
	const PtrRange ptrRange = const PtrRange(ptr, ptr + size.raw());
	if (!contains(stackPtrRange(a.dataStack), ptrRange)
		&& !a.extern_.hasMallocedPtr(ptrRange)
		&& !contains(ptrRangeOfArr(a.byteCode.text), ptrRange)) {
		debug {
			import util.print : print;
			alias Alloc = StackAlloc!("debug", 1024 * 8);
			Alloc alloc;
			Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
			writeStatic(writer, "want to access: ");
			writePtrRange(writer, ptrRange);
			writePtrRanges(writer, a);
			print(finishWriterToCStr(writer));
		}
		todo!void("ptr not valid");
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

@trusted void write(Extern)(ref Interpreter!Extern a, immutable Nat8 offset, immutable Nat8 size) {
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		immutable Nat64 value = pop(a.dataStack);
		u8* ptr = cast(u8*) pop(a.dataStack).raw();
		checkPtr(a, ptr, offset, size);
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		immutable Nat8 offsetWords = offset / immutable Nat8(8);
		immutable Nat8 sizeWords = size / immutable Nat8(8);
		Nat64* ptrWithoutOffset = (cast(Nat64*) peek(a.dataStack, sizeWords).raw());
		checkPtr(a, cast(const u8*) ptrWithoutOffset, offsetWords * immutable Nat8(8), sizeWords * immutable Nat8(8));
		Nat64* ptr = ptrWithoutOffset + offsetWords.raw();
		foreach (immutable u8 i; 0..sizeWords.raw())
			ptr[i] = peek(a.dataStack, decr(sizeWords) - immutable Nat8(i));
		popN(a.dataStack, incr(sizeWords));
	}
}

@trusted immutable(Nat64) readPartialBytes(immutable u8* ptr, immutable u8 size) {
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

@trusted void writePartialBytes(u8* ptr, immutable u64 value, immutable u8 size) {
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

@trusted void applyExternOp(Extern)(ref Interpreter!Extern a, immutable ExternOp op) {
	final switch (op) {
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
			push(a.dataStack, immutable Nat64(cast(immutable size_t) a.extern_.malloc(pop(a.dataStack).raw())));
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
			checkPtr(a, cast(const u8*) jmpBufPtr, immutable Nat8(0), immutable Nat8(JmpBufTag.sizeof));
			overwriteMemory(jmpBufPtr, createInterpreterRestore(a));
			push(a.dataStack, immutable Nat64(0));
			break;
		case ExternOp.usleep:
			a.extern_.usleep(pop(a.dataStack).raw());
			break;
		case ExternOp.write:
			immutable size_t nBytes = pop(a.dataStack).raw();
			immutable char* buf = cast(immutable char*) pop(a.dataStack).raw();
			immutable int fd = cast(int) pop(a.dataStack).to32().raw();
			immutable long res = a.extern_.write(fd, buf, nBytes);
			push(a.dataStack, immutable Nat64(res));
			break;
	}
}

pure: // TODO: many more are pure actually..

// This isn't the structure the posix jmp-buf-tag has, but it fits inside it
alias JmpBufTag = immutable InterpreterRestore*;

@trusted immutable(Nat64) pack(immutable Arr!Nat64 values, immutable Arr!Nat8 sizes) {
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
