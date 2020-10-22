module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import core.stdc.stdio : printf;

import diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import interpret.applyFn : applyFn;
import interpret.bytecode :
	asCall,
	ByteCode,
	ByteCodeIndex,
	DebugOperation,
	isCall,
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
import interpret.opcode : OpCode;
import util.bools : Bool;
import util.collection.arr : Arr, at, begin, ptrAt, range, size;
import util.collection.arrUtil : lastWhere, zip;
import util.collection.fullIndexDict : fullIndexDictGet, fullIndexDictSize;
import util.collection.globalAllocatedStack :
	asTempArr,
	clearStack,
	dup,
	GlobalAllocatedStack,
	isEmpty,
	peek,
	pop,
	popN,
	push,
	remove,
	stackRef,
	stackSize;
import util.collection.str : Str;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndPos, FileIndex;
import util.sym : Sym;
import util.types : bottomNBytes, maxU64, safeIntFromU64, safeSizeTToU16, safeSizeTToU32, u8, u16, u32, u64;
import util.util : todo, unreachable, verify, verifyEq;

@trusted immutable(int) runBytecode(
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	immutable Arr!Str args,
) {
	Interpreter interpreter = newInterpreter(ptrTrustMe(byteCode), ptrTrustMe(filesInfo));
	push(interpreter.dataStack, size(args)); // TODO: this is an i32, add safety checks
	push(interpreter.dataStack, cast(immutable u64) begin(args));
	while (true) {
		final switch (step(interpreter)) {
			case StepResult.continue_:
				break;
			case StepResult.exit:
				immutable u64 returnCode = pop(interpreter.dataStack);
				verify(isEmpty(interpreter.dataStack));
				return safeIntFromU64(returnCode);
		}
	}
}

pure @trusted Interpreter newInterpreter(immutable Ptr!ByteCode byteCode, immutable Ptr!FilesInfo filesInfo) {
	return Interpreter(byteCode, filesInfo, newByteCodeReader(begin(byteCode.byteCode), byteCode.main.index));
}

enum StepResult {
	continue_,
	exit,
}

alias DataStack = GlobalAllocatedStack!(u64, 1024 * 4);
alias ReturnStack = GlobalAllocatedStack!(immutable(u8)*, 1024);
// Gives start stack position of each function
alias StackStartStack = GlobalAllocatedStack!(u16, 1024);

struct Interpreter {
	immutable Ptr!ByteCode byteCode;
	immutable Ptr!FilesInfo filesInfo;
	ByteCodeReader reader;
	DataStack dataStack;
	ReturnStack returnStack;
	// Parallel to return stack. Has the stack entry before the function's arguments.
	StackStartStack stackStartStack;
}

@trusted void reset(ref Interpreter a) {
	setReaderPtr(a.reader, begin(a.byteCode.byteCode));
	clearStack(a.dataStack);
	clearStack(a.returnStack);
	clearStack(a.stackStartStack);
}

void printStack(ref const Interpreter interpreter) {
	printDataArr(asTempArr(interpreter.dataStack));
}

@trusted void printDataArr(immutable Arr!u64 values) {
	printf("data:");
	foreach (ref immutable u64 value; range(values))
		printf(" %lu", value);
	printf("\n");
}

import util.alloc.stackAlloc : StackAlloc;
import util.sym : writeSym;
import util.writer : finishWriterToCStr, Writer, writeChar, writeStatic;

@trusted void printReturnStack(ref const Interpreter interpreter) {
	alias Alloc = StackAlloc!("printReturnStack", 1024);
	Alloc alloc;
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, "call stack:");
	foreach (immutable u8* ptr; range(asTempArr(interpreter.returnStack))) {
		writeChar(writer, ' ');
		writeFunNameAtByteCodePtr(writer, interpreter, ptr);
	}
	writeChar(writer, ' ');
	writeFunNameAtByteCodePtr(writer, interpreter, getReaderPtr(interpreter.reader));
	printf("%s\n", finishWriterToCStr(writer));
}

void writeFunNameAtByteCodePtr(Alloc)(ref Writer!Alloc writer, ref const Interpreter interpreter, immutable u8* ptr) {
	immutable Opt!Sym funName = getFunNameAtByteCodePtr(interpreter, ptr);
	if (has(funName))
		writeSym(writer, force(funName));
	else
		writeStatic(writer, "<generated>");
}

immutable(FileAndPos) fileAndPosAtIndex(ref const Interpreter interpreter, immutable ByteCodeIndex index) {
	return fullIndexDictGet(interpreter.byteCode.sources, index);
}

immutable(FileAndPos) fileAndPosAtPtr(ref const Interpreter interpreter, immutable u8* ptr) {
	return fileAndPosAtIndex(interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

immutable(Opt!Sym) getFunNameAtByteCodePtr(ref const Interpreter interpreter, immutable u8* ptr) {
	return getFunNameAtIndex(interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

immutable(Opt!Sym) getFunNameAtIndex(ref const Interpreter interpreter, immutable ByteCodeIndex index) {
	immutable FileAndPos fileAndPos = fileAndPosAtIndex(interpreter, index);
	if (fileAndPos.fileIndex == FileIndex.none)
		return none!Sym;
	else {
		immutable Arr!FunNameAndPos funs = fullIndexDictGet(interpreter.byteCode.fileToFuns, fileAndPos.fileIndex);
		immutable Opt!FunNameAndPos opt = lastWhere(funs, (ref immutable FunNameAndPos fp) =>
			immutable Bool(fp.pos <= fileAndPos.pos));
		return some(force(opt).funName);
	}
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(ref const Interpreter interpreter) {
	return byteCodeIndexOfPtr(interpreter, getReaderPtr(interpreter.reader));
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(ref const Interpreter interpreter, immutable u8* ptr) {
	return immutable ByteCodeIndex(safeSizeTToU32(ptr - begin(interpreter.byteCode.byteCode)));
}

immutable(FileAndPos) nextSource(ref const Interpreter interpreter) {
	return fileAndPosAtPtr(interpreter, getReaderPtr(interpreter.reader));
}

immutable(StepResult) step(ref Interpreter interpreter) {
	immutable FileAndPos source = nextSource(interpreter);
	debug {
		printf("\n");
		printStack(interpreter);
		printReturnStack(interpreter);
	}
	immutable Operation operation = readOperation(interpreter.reader);
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
		writeFileAndPos!(TempAlloc, TempAlloc)(temp, writer, interpreter.filesInfo, source);
		writeChar(writer, ' ');
		writeSexprNoNewline(writer, sexprOfOperation(temp, operation));
		if (isCall(operation)) {
			immutable Operation.Call call = asCall(operation);
			immutable Opt!Sym funName = getFunNameAtIndex(interpreter, call.address);
			if (has(funName)) {
				writeStatic(writer, " (");
				writeSym(writer, force(funName));
				writeChar(writer, ')');
			}
		}
		writeChar(writer, '\n');
		print(finishWriterToCStr(writer));
	}

	return matchOperationImpure!(immutable StepResult)(
		operation,
		(ref immutable Operation.Call it) {
			call(interpreter, it.address, it.parametersSize);
			return StepResult.continue_;
		},
		(ref immutable Operation.CallFunPtr it) {
			call(
				interpreter,
				immutable ByteCodeIndex(safeSizeTToU32(
					removeAtStackOffset(interpreter, immutable StackOffset(it.parametersSize)))),
				it.parametersSize);
			return StepResult.continue_;
		},
		(ref immutable Operation.Debug dbg) {
			matchDebugOperationImpure!void(
				dbg.debugOperation,
				(ref immutable DebugOperation.AssertStackSize it) {
					immutable u16 stackStart = isEmpty(interpreter.stackStartStack)
						? 0
						: peek(interpreter.stackStartStack);
					verifyEq(stackSize(interpreter.dataStack) - stackStart, it.stackSize);
				});
			return StepResult.continue_;
		},
		(ref immutable Operation.Dup it) {
			dup(interpreter.dataStack, it.offset.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.DupPartial it) {
			push(interpreter.dataStack,
				getBytes(peek(interpreter.dataStack, it.entryOffset.offset), it.byteOffset, it.sizeBytes));
			return StepResult.continue_;
		},
		(ref immutable Operation.Fn it) {
			applyFn(interpreter.dataStack, it.fnOp);
			return StepResult.continue_;
		},
		(ref immutable Operation.Jump it) {
			readerJump(interpreter.reader, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Pack it) {
			push(interpreter.dataStack, pack(popN(interpreter.dataStack, size(it.sizes)), it.sizes));
			return StepResult.continue_;
		},
		(ref immutable Operation.PushValue it) {
			push(interpreter.dataStack, it.value);
			return StepResult.continue_;
		},
		(ref immutable Operation.Read it) {
			read(interpreter.dataStack, it.offset, it.size);
			return StepResult.continue_;
		},
		(ref immutable Operation.Remove it) {
			remove(interpreter.dataStack, it.offset.offset, it.nEntries);
			return StepResult.continue_;
		},
		(ref immutable Operation.Return) {
			if (isEmpty(interpreter.returnStack))
				return StepResult.exit;
			else {
				setReaderPtr(interpreter.reader, pop(interpreter.returnStack));
				pop(interpreter.stackStartStack);
				return StepResult.continue_;
			}
		},
		(ref immutable Operation.StackRef it) {
			pushStackRef(interpreter.dataStack, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Switch) {
			readerSwitch(interpreter.reader, pop(interpreter.dataStack));
			return StepResult.continue_;
		},
		(ref immutable Operation.Write it) {
			write(interpreter.dataStack, it.offset, it.size);
			return StepResult.continue_;
		});
}

private:

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	push(dataStack, cast(immutable u64) stackRef(dataStack, offset.offset));
}

@trusted void read(ref DataStack data, immutable u8 offset, immutable u8 size) {
	immutable u64* ptr = cast(immutable u64*) pop(data);
	if (size < 8) { //TODO: just have 2 different ops then
		push(data, readPartialBytes((cast(immutable u8*) ptr) + offset, size));
	} else {
		verify(size % 8 == 0);
		verify(offset % 8 == 0);
		foreach (immutable size_t i; 0..(size / 8))
			push(data, (ptr + (offset / 8))[i]);
	}
}

@trusted void write(ref DataStack data, immutable u8 offset, immutable u8 size) {
	if (size < 8) { //TODO: just have 2 different ops then
		immutable u64 value = pop(data);
		u64* ptr = cast(u64*) pop(data);
		writePartialBytes((cast(u8*) ptr) + offset, value, size);
	} else {
		verify(size % 8 == 0);
		verify(offset % 8 == 0);
		immutable u8 sizeWords = size / 8;
		u64* ptr = (cast(u64*) peek(data, sizeWords)) + (offset / 8);
		foreach (immutable size_t i; 0..sizeWords)
			ptr[i] = peek(data, cast(immutable u8) (sizeWords - 1 - i));
		popN(data, sizeWords + 1);
	}
}

@trusted immutable(u64) readPartialBytes(immutable u8* ptr, immutable u8 size) {
	//TODO: Just have separate ops for separate sizes
	switch (size) {
		case 1:
			return *(cast(immutable u8*) ptr);
		case 2:
			return *(cast(immutable u16*) ptr);
		case 4:
			return *(cast(immutable u32*) ptr);
		default:
			return unreachable!(immutable u64);
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

immutable(u64) getBytes(immutable u64 a, immutable u8 byteOffset, immutable u8 sizeBytes) {
	verify(byteOffset + sizeBytes <= u64.sizeof);
	immutable u64 shift = bytesToBits(u64.sizeof - sizeBytes - byteOffset);
	immutable u64 mask = maxU64 >> bytesToBits(8 - sizeBytes);
	immutable u64 res = (a >> shift) & mask;
	return res;
}

immutable(u64) bytesToBits(immutable u64 bytes) {
	return bytes * 8;
}

void call(ref Interpreter interpreter, immutable ByteCodeIndex address, immutable u16 parametersSize) {
	push(interpreter.returnStack, getReaderPtr(interpreter.reader));
	push(interpreter.stackStartStack, safeSizeTToU16(stackSize(interpreter.dataStack) - parametersSize));
	setReaderPtr(interpreter.reader, ptrAt(interpreter.byteCode.byteCode, address.index).rawPtr());
}

immutable(u64) removeAtStackOffset(ref Interpreter interpreter, immutable StackOffset offset) {
	return remove(interpreter.dataStack, offset.offset);
}

pure: // TODO: many more are pure actually..

immutable(u64) pack(immutable Arr!u64 values, immutable Arr!u8 sizes) {
	u64 res = 0;
	u64 totalSize = 0;
	zip!(u64, u8)(values, sizes, (ref immutable u64 value, ref immutable u8 size) {
		res = (res << (size * 8)) | bottomNBytes(value, size);
		totalSize += size;
		debug {
			printf("after step: value=%lu, size=%d, res=%lu, totalSize=%lu\n", value, size, res, totalSize);
		}
	});
	verify(totalSize <= 8);
	immutable u64 remainingBytes = 8 - totalSize;
	immutable u64 r = res << (remainingBytes * 8);
	debug {
		printf("PACK | res=%lu, totalSize=%lu, remainingBytes=%lu, r=%lu\n",
			res, totalSize, remainingBytes, r);
	}
	return r;
}

