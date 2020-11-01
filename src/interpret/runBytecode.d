module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import concreteModel : ConcreteFun, concreteFunRange, ConcreteFunSource, matchConcreteFunSource;
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
	FnOp,
	FunNameAndPos,
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
import interpret.opcode : OpCode;
import lowModel : LowFun, LowFunIndex, LowFunSource, LowProgram, matchLowFunSource;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, begin, end, freeArr, ptrAt, range, sizeNat;
import util.collection.arrUtil : lastWhere, mapWithFirst, zipSystem;
import util.collection.fullIndexDict : fullIndexDictGet, fullIndexDictSize;
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
	remove,
	stackPtrRange,
	stackRef,
	stackSize;
import util.collection.str : CStr, freeCStr, Str, strToCStr;
import util.opt : force, has, none, Opt, some;
import util.ptr : contains, Ptr, PtrRange, ptrRangeOfArr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileIndex, FileAndPos;
import util.sym : Sym;
import util.types : bottomNBytes, decr, incr, Nat8, Nat16, Nat32, Nat64, safeIntFromNat64, u8, u16, u32, u64, zero;
import util.util : todo, unreachable, verify;

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

	debug {
		import util.collection.arr : size;
		printf("executablePath is %.*s\n", cast(int) size(executablePath), begin(executablePath));
	}

	ExternAlloc!Extern externAlloc = ExternAlloc!Extern(ptrTrustMe_mut(extern_));
	immutable CStr firstArg = strToCStr(externAlloc, executablePath);
	immutable Arr!CStr allArgs = mapWithFirst!(CStr, Str)(externAlloc, firstArg, args, (ref immutable Str arg) =>
		strToCStr(externAlloc, arg));

	push(interpreter.dataStack, sizeNat(allArgs)); // TODO: this is an i32, add safety checks
	// These need to be CStrs
	push(interpreter.dataStack, immutable Nat64(cast(immutable u64) begin(allArgs)));
	while (true) {
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
alias ReturnStack = GlobalAllocatedStack!(immutable(u8)*, 1024);
// Gives start stack position of each function
alias StackStartStack = GlobalAllocatedStack!(Nat16, 1024);

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
}

@trusted void reset(Extern)(ref Interpreter!Extern a) {
	setReaderPtr(a.reader, begin(a.byteCode.byteCode));
	clearStack(a.dataStack);
	clearStack(a.returnStack);
	clearStack(a.stackStartStack);
}

void printStack(Extern)(ref const Interpreter!Extern a) {
	printDataArr(asTempArr(a.dataStack));
}

@trusted void printDataArr(immutable Arr!Nat64 values) {
	printf("data:");
	foreach (immutable Nat64 value; range(values))
		printf(" %lx", value.raw());
	printf("\n");
}

import util.alloc.stackAlloc : StackAlloc;
import util.sym : writeSym;
import util.writer : finishWriterToCStr, Writer, writeChar, writePtrRange, writeStatic;

@trusted void printReturnStack(Extern)(ref const Interpreter!Extern a) {
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

void writeByteCodeSource(TempAlloc, Alloc)(
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

void writeFunNameAtIndex(Alloc, Extern)(
	ref Writer!Alloc writer,
	ref const Interpreter!Extern interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, interpreter.lowProgram, byteCodeSourceAtIndex(interpreter, index).fun);
}

void writeFunNameAtByteCodePtr(Alloc, Extern)(
	ref Writer!Alloc writer,
	ref const Interpreter!Extern interpreter,
	immutable u8* ptr,
) {
	writeFunNameAtIndex(writer, interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

immutable(ByteCodeSource) byteCodeSourceAtIndex(Extern)(ref const Interpreter!Extern a, immutable ByteCodeIndex index) {
	return fullIndexDictGet(a.byteCode.sources, index);
}

immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(Extern)(ref const Interpreter!Extern a, immutable u8* ptr) {
	return byteCodeSourceAtIndex(a, byteCodeIndexOfPtr(a, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(Extern)(ref const Interpreter!Extern a) {
	return byteCodeIndexOfPtr(a, getReaderPtr(a.reader));
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(Extern)(ref const Interpreter!Extern a, immutable u8* ptr) {
	return immutable ByteCodeIndex((immutable Nat64(ptr - begin(a.byteCode.byteCode))).to32());
}

immutable(ByteCodeSource) nextSource(Extern)(ref const Interpreter!Extern a) {
	return byteCodeSourceAtByteCodePtr(a, getReaderPtr(a.reader));
}

immutable Bool PRINT = False;

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
			import core.stdc.stdio : printf;
			import util.alloc.stackAlloc : StackAlloc;
			import util.print : print;
			import util.sexpr : writeSexprNoNewline;
			import util.sym : writeSym;
			import util.writer : finishWriterToCStr, writeChar, Writer, writeStatic;

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
			applyExternOp(a.extern_, a.dataStack, it.op);
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
			read(a.dataStack, a.extern_, a.byteCode, it.offset, it.size);
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
			write(a.dataStack, a.extern_, a.byteCode, it.offset, it.size);
			return StepResult.continue_;
		});
}

private:

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	push(dataStack, immutable Nat64(cast(immutable u64) stackRef(dataStack, offset.offset)));
}

@trusted void read(Extern)(
	ref DataStack data,
	ref const Extern extern_,
	ref immutable ByteCode byteCode,
	immutable Nat8 offset,
	immutable Nat8 size,
) {
	immutable u8* ptr = cast(immutable u8*) pop(data).raw();
	checkPtr!Extern(data, extern_, byteCode, ptr, offset, size);
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		push(data, readPartialBytes(ptr + offset.raw(), size.raw()));
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		foreach (immutable size_t i; 0..(size.raw() / 8))
			push(data, ((cast(immutable Nat64*) ptr) + (offset.raw() / 8))[i]);
	}
}

@system void checkPtr(Extern)(
	ref const DataStack data,
	ref const Extern extern_,
	ref immutable ByteCode byteCode,
	const u8* ptrWithoutOffset,
	immutable Nat8 offset,
	immutable Nat8 size,
) {
	const u8* ptr = ptrWithoutOffset + offset.raw();
	const PtrRange ptrRange = const PtrRange(ptr, ptr + size.raw());
	if (!contains(stackPtrRange(data), ptrRange)
		&& !extern_.hasMallocedPtr(ptrRange)
		&& !contains(ptrRangeOfArr(byteCode.text), ptrRange)) {
		debug {
			import util.print : print;
			alias Alloc = StackAlloc!("debug", 1024 * 8);
			Alloc alloc;
			Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
			writeStatic(writer, "want to access: ");
			writePtrRange(writer, ptrRange);
			writePtrRanges(writer, data, extern_, byteCode);
			print(finishWriterToCStr(writer));
		}
		todo!void("ptr not valid");
	}
}

@system void writePtrRanges(Alloc, Extern)(
	ref Writer!Alloc writer,
	ref const DataStack data,
	ref const Extern extern_,
	ref immutable ByteCode byteCode,
) {
	writeStatic(writer, "\ndata: ");
	writePtrRange(writer, stackPtrRange(data));
	writeStatic(writer, "\nmalloced:\n");
	extern_.writeMallocedRanges(writer);
	writeStatic(writer, "\ntext:\n");
	writePtrRange(writer, ptrRangeOfArr(byteCode.text));
	writeChar(writer, '\n');
}

@trusted void write(Extern)(
	ref DataStack data,
	ref const Extern extern_,
	ref immutable ByteCode byteCode,
	immutable Nat8 offset,
	immutable Nat8 size,
) {
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		immutable Nat64 value = pop(data);
		u8* ptr = cast(u8*) pop(data).raw();
		checkPtr(data, extern_, byteCode, ptr, offset, size);
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		immutable Nat8 sizeWords = size / immutable Nat8(8);
		Nat64* ptrWithoutOffset = (cast(Nat64*) peek(data, sizeWords).raw());
		checkPtr(data, extern_, byteCode, cast(const u8*) ptrWithoutOffset, offset, size);
		Nat64* ptr = ptrWithoutOffset + (offset.raw() / 8);
		foreach (immutable u8 i; 0..sizeWords.raw())
			ptr[i] = peek(data, decr(sizeWords) - immutable Nat8(i));
		popN(data, incr(sizeWords));
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
	setReaderPtr(a.reader, ptrAt(a.byteCode.byteCode, address.index.raw()).rawPtr());
}

immutable(Nat64) removeAtStackOffset(Extern)(ref Interpreter!Extern a, immutable StackOffset offset) {
	return remove(a.dataStack, offset.offset);
}

@trusted void applyExternOp(Extern)(ref Extern a, ref DataStack dataStack, immutable ExternOp op) {
	final switch (op) {
		case ExternOp.free:
			a.free(cast(u8*) pop(dataStack).raw());
			break;
		case ExternOp.getNProcs:
			push(dataStack, immutable Nat64(a.getNProcs()));
			break;
		case ExternOp.longjmp:
			todo!void("longjmp");
			break;
		case ExternOp.malloc:
			push(dataStack, immutable Nat64(cast(immutable size_t) a.malloc(pop(dataStack).raw())));
			break;
		case ExternOp.pthreadCreate:
			todo!void("pthread_create");
			break;
		case ExternOp.pthreadJoin:
			todo!void("pthread_join");
			break;
		case ExternOp.pthreadYield:
			push(dataStack, immutable Nat64(a.pthreadYield()));
			break;
		case ExternOp.setjmp:
			// TODO: this will be more complicated if longjmp is implemented.
			immutable Nat64 jmpBufPtr = pop(dataStack);
			push(dataStack, immutable Nat64(0));
			break;
		case ExternOp.usleep:
			a.usleep(pop(dataStack).raw());
			break;
		case ExternOp.write:
			immutable size_t nBytes = pop(dataStack).raw();
			immutable char* buf = cast(immutable char*) pop(dataStack).raw();
			immutable int fd = cast(int) pop(dataStack).to32().raw();
			immutable long res = a.write(fd, buf, nBytes);
			push(dataStack, immutable Nat64(res));
			break;
	}
}

pure: // TODO: many more are pure actually..

immutable(Nat64) bytesToBits(immutable Nat64 bytes) {
	return bytes * immutable Nat64(8);
}

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
