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
import interpret.externOps : applyExternOp, Extern, newExtern;
import interpret.opcode : OpCode;
import lowModel : LowFun, LowFunIndex, LowFunSource, LowProgram, matchLowFunSource;
import util.bools : Bool;
import util.collection.arr : Arr, at, begin, ptrAt, range, sizeNat;
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
import util.sourceRange : FileIndex, FileAndPos;
import util.sym : Sym;
import util.types : bottomNBytes, decr, incr, Nat8, Nat16, Nat32, Nat64, safeIntFromNat64, u8, u16, u32, u64, zero;
import util.util : todo, unreachable, verify;

@trusted immutable(int) runBytecode(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram lowProgram,
	ref immutable ByteCode byteCode,
	ref immutable FilesInfo filesInfo,
	immutable Arr!Str args,
) {
	Interpreter!Alloc interpreter = newInterpreter(
		ptrTrustMe_mut(alloc),
		ptrTrustMe(lowProgram),
		ptrTrustMe(byteCode),
		ptrTrustMe(filesInfo));
	push(interpreter.dataStack, sizeNat(args)); // TODO: this is an i32, add safety checks
	push(interpreter.dataStack, immutable Nat64(cast(immutable u64) begin(args)));
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
}

pure @trusted Interpreter!Alloc newInterpreter(Alloc)(
	Ptr!Alloc alloc,
	immutable Ptr!LowProgram lowProgram,
	immutable Ptr!ByteCode byteCode,
	immutable Ptr!FilesInfo filesInfo,
) {
	return Interpreter!Alloc(
		lowProgram,
		byteCode,
		filesInfo,
		newByteCodeReader(begin(byteCode.byteCode), byteCode.main.index),
		newExtern(alloc));
}

enum StepResult {
	continue_,
	exit,
}

alias DataStack = GlobalAllocatedStack!(Nat64, 1024 * 4);
alias ReturnStack = GlobalAllocatedStack!(immutable(u8)*, 1024);
// Gives start stack position of each function
alias StackStartStack = GlobalAllocatedStack!(Nat16, 1024);

struct Interpreter(Alloc) {
	immutable Ptr!LowProgram lowProgram;
	immutable Ptr!ByteCode byteCode;
	immutable Ptr!FilesInfo filesInfo;
	ByteCodeReader reader;
	Extern!Alloc extern_;
	DataStack dataStack;
	ReturnStack returnStack;
	// Parallel to return stack. Has the stack entry before the function's arguments.
	StackStartStack stackStartStack;
}

@trusted void reset(Alloc)(ref Interpreter!Alloc a) {
	setReaderPtr(a.reader, begin(a.byteCode.byteCode));
	clearStack(a.dataStack);
	clearStack(a.returnStack);
	clearStack(a.stackStartStack);
}

void printStack(Alloc)(ref const Interpreter!Alloc interpreter) {
	printDataArr(asTempArr(interpreter.dataStack));
}

@trusted void printDataArr(immutable Arr!Nat64 values) {
	printf("data:");
	foreach (immutable Nat64 value; range(values))
		printf(" %lu", value.raw());
	printf("\n");
}

import util.alloc.stackAlloc : StackAlloc;
import util.sym : writeSym;
import util.writer : finishWriterToCStr, Writer, writeChar, writeStatic;

@trusted void printReturnStack(Alloc)(ref const Interpreter!Alloc interpreter) {
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

void writeByteCodeSource(TempAlloc, Alloc)(
	ref TempAlloc temp,
	ref Writer!Alloc writer,
	ref immutable LowProgram lowProgram,
	ref immutable FilesInfo filesInfo,
	ref immutable ByteCodeSource source,
) {
	matchLowFunSource!void(
		fullIndexDictGet(lowProgram.allFuns, source.fun).source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunSource(writer, it.source);
			immutable FileAndPos where = immutable FileAndPos(concreteFunRange(it).fileIndex, source.pos);
			writeFileAndPos!(TempAlloc, Alloc)(temp, writer, filesInfo, where);
		},
		(ref immutable LowFunSource.Generated) {
			writeStatic(writer, "<generated>");
		});
}

void writeFunNameAtIndex(WriterAlloc, InterpreterAlloc)(
	ref Writer!WriterAlloc writer,
	ref const Interpreter!InterpreterAlloc interpreter,
	immutable ByteCodeIndex index,
) {
	writeFunName(writer, interpreter.lowProgram, byteCodeSourceAtIndex(interpreter, index).fun);
}

void writeFunNameAtByteCodePtr(WriterAlloc, InterpreterAlloc)(
	ref Writer!WriterAlloc writer,
	ref const Interpreter!InterpreterAlloc interpreter,
	immutable u8* ptr,
) {
	writeFunNameAtIndex(writer, interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

void writeFunName(Alloc)(ref Writer!Alloc writer, ref immutable LowProgram lowProgram, immutable LowFunIndex fun) {
	matchLowFunSource!void(
		fullIndexDictGet(lowProgram.allFuns, fun).source,
		(immutable Ptr!ConcreteFun it) {
			writeConcreteFunSource(writer, it.source);
		},
		(ref immutable LowFunSource.Generated it) {
			writeSym(writer, it.name);
			writeStatic(writer, " (generated)");
		});
}

void writeConcreteFunSource(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteFunSource a) {
	todo!void("writeConcreteFunSource");
}

immutable(ByteCodeSource) byteCodeSourceAtIndex(Alloc)(
	ref const Interpreter!Alloc interpreter,
	immutable ByteCodeIndex index,
) {
	return fullIndexDictGet(interpreter.byteCode.sources, index);
}

immutable(ByteCodeSource) byteCodeSourceAtByteCodePtr(Alloc)(
	ref const Interpreter!Alloc interpreter,
	immutable u8* ptr,
) {
	return byteCodeSourceAtIndex(interpreter, byteCodeIndexOfPtr(interpreter, ptr));
}

@trusted immutable(ByteCodeIndex) nextByteCodeIndex(Alloc)(ref const Interpreter!Alloc interpreter) {
	return byteCodeIndexOfPtr(interpreter, getReaderPtr(interpreter.reader));
}

pure @trusted immutable(ByteCodeIndex) byteCodeIndexOfPtr(Alloc)(
	ref const Interpreter!Alloc interpreter,
	immutable u8* ptr,
) {
	immutable Nat64 index = immutable Nat64(ptr - begin(interpreter.byteCode.byteCode));
	return immutable ByteCodeIndex(index.to32());
}

immutable(ByteCodeSource) nextSource(Alloc)(ref const Interpreter!Alloc interpreter) {
	return byteCodeSourceAtByteCodePtr(interpreter, getReaderPtr(interpreter.reader));
}

immutable(StepResult) step(Alloc)(ref Interpreter!Alloc interpreter) {
	immutable ByteCodeSource source = nextSource(interpreter);
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
		writeByteCodeSource(temp, writer, interpreter.lowProgram, interpreter.filesInfo, source);
		writeChar(writer, ' ');
		writeSexprNoNewline(writer, sexprOfOperation(temp, operation));
		if (isCall(operation)) {
			immutable Operation.Call call = asCall(operation);
			writeStatic(writer, "(");
			writeFunNameAtIndex(writer, interpreter, call.address);
			writeChar(writer, ')');
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
			immutable ByteCodeIndex address = immutable ByteCodeIndex(
				removeAtStackOffset(interpreter, immutable StackOffset(it.parametersSize)).to32());
			call(interpreter, address, it.parametersSize);
			return StepResult.continue_;
		},
		(ref immutable Operation.Debug dbg) {
			matchDebugOperationImpure!void(
				dbg.debugOperation,
				(ref immutable DebugOperation.AssertStackSize it) {
					immutable Nat16 stackStart = isEmpty(interpreter.stackStartStack)
						? immutable Nat16(0)
						: peek(interpreter.stackStartStack);
					verify(stackSize(interpreter.dataStack) - stackStart.to32() == it.stackSize.to32());
				});
			return StepResult.continue_;
		},
		(ref immutable Operation.Dup it) {
			dup(interpreter.dataStack, it.offset.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.DupPartial it) {
			push(
				interpreter.dataStack,
				getBytes(peek(interpreter.dataStack, it.entryOffset.offset), it.byteOffset, it.sizeBytes));
			return StepResult.continue_;
		},
		(ref immutable Operation.Extern it) {
			applyExternOp(interpreter.extern_, interpreter.dataStack, it.op);
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
			push(interpreter.dataStack, pack(popN(interpreter.dataStack, sizeNat(it.sizes).to8()), it.sizes));
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
	push(dataStack, immutable Nat64(cast(immutable u64) stackRef(dataStack, offset.offset)));
}

@trusted void read(ref DataStack data, immutable Nat8 offset, immutable Nat8 size) {
	immutable u8* ptr = cast(immutable u8*) pop(data).raw();
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		push(data, readPartialBytes(ptr + offset.raw(), size.raw()));
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		foreach (immutable size_t i; 0..(size.raw() / 8))
			push(data, ((cast(immutable Nat64*) ptr) + (offset.raw() / 8))[i]);
	}
}

@trusted void write(ref DataStack data, immutable Nat8 offset, immutable Nat8 size) {
	if (size < immutable Nat8(8)) { //TODO: just have 2 different ops then
		immutable Nat64 value = pop(data);
		u8* ptr = cast(u8*) pop(data).raw();
		writePartialBytes(ptr + offset.raw(), value.raw(), size.raw());
	} else {
		verify(zero(size % immutable Nat8(8)));
		verify(zero(offset % immutable Nat8(8)));
		immutable Nat8 sizeWords = size / immutable Nat8(8);
		Nat64* ptr = (cast(Nat64*) peek(data, sizeWords).raw()) + (offset.raw() / 8);
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
immutable(Nat64) getBytes(immutable Nat64 a, immutable Nat8 byteOffset, immutable Nat8 sizeBytes) {
	verify(byteOffset + sizeBytes <= immutable Nat8(u64.sizeof));
	immutable Nat64 shift = bytesToBits((immutable Nat8(u64.sizeof) - sizeBytes - byteOffset).to64());
	immutable Nat64 mask = Nat64.max >> bytesToBits((immutable Nat8(u64.sizeof) - sizeBytes).to64());
	immutable Nat64 res = (a >> shift) & mask;
	debug {
		import core.stdc.stdio : printf;
		printf("getBytes(%lx, %x, %x)\n", a.raw(), byteOffset.raw(), sizeBytes.raw());
		printf("shift= %lx, mask = %lx, res = %lx\n", shift.raw(), mask.raw(), res.raw());
	}
	return res;
}

void call(Alloc)(ref Interpreter!Alloc interpreter, immutable ByteCodeIndex address, immutable Nat8 parametersSize) {
	push(interpreter.returnStack, getReaderPtr(interpreter.reader));
	push(interpreter.stackStartStack, (stackSize(interpreter.dataStack) - parametersSize.to32()).to16());
	setReaderPtr(interpreter.reader, ptrAt(interpreter.byteCode.byteCode, address.index.raw()).rawPtr());
}

immutable(Nat64) removeAtStackOffset(Alloc)(ref Interpreter!Alloc interpreter, immutable StackOffset offset) {
	return remove(interpreter.dataStack, offset.offset);
}

pure: // TODO: many more are pure actually..

immutable(Nat64) bytesToBits(immutable Nat64 bytes) {
	return bytes * immutable Nat64(8);
}

immutable(Nat64) pack(immutable Arr!Nat64 values, immutable Arr!Nat8 sizes) {
	Nat64 res = immutable Nat64(0);
	Nat64 totalSize = immutable Nat64(0);
	zip!(Nat64, Nat8)(values, sizes, (ref immutable Nat64 value, ref immutable Nat8 size) {
		res = (res << bytesToBits(size.to64())) | bottomNBytes(value, size);
		totalSize += size.to64();
	});
	verify(totalSize <= immutable Nat64(8));
	immutable Nat64 remainingBytes = immutable Nat64(8) - totalSize;
	return res << bytesToBits(remainingBytes);
}

