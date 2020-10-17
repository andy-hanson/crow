module interpret.runBytecode;

@safe @nogc nothrow: // not pure

import diag : FilesInfo, writeFileAndPos; // TODO: FilesInfo probably belongs elsewhere
import interpret.bytecode : ByteCode, FnOp, matchOperationImpure, Operation, sexprOfOperation, StackOffset;
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
import util.collection.arr : at, begin, ptrAt;
import util.ptr : Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndPos;
import util.types : maxU64, safeIntFromU64, u8, u16, u32, u64;
import util.util : todo, unreachable, verify;

@trusted immutable(int) runBytecode(ref immutable ByteCode byteCode, ref immutable FilesInfo filesInfo) {
	Interpreter interpreter = Interpreter(ptrTrustMe(byteCode), ptrTrustMe(filesInfo), newByteCodeReader(begin(byteCode.byteCode)));
	while (true) {
		final switch (step(interpreter)) {
			case StepResult.continue_:
				break;
			case StepResult.exit:
				immutable u64 returnCode = interpreter.dataStack.pop();
				verify(interpreter.dataStack.isEmpty());
				return safeIntFromU64(returnCode);
		}
	}
}

//TODO:MOVE
struct GlobalAllocatedStack(T, size_t capacity) {
	@safe @nogc nothrow:

	static T[capacity] values = void;
	static size_t size = 0;

	immutable(Bool) isEmpty() const {
		return immutable Bool(size == 0);
	}

	void push(T value) {
		verify(size != capacity);
		values[size] = value;
		size++;
	}

	immutable(T) peek(immutable u8 offset) const {
		verify(offset + 1 < size);
		return values[size - 1 - offset];
	}

	void popN(immutable u8 n) {
		foreach (immutable size_t i; 0..n)
			pop();
	}

	immutable(T) pop() {
		verify(size != 0);
		size--;
		return values[size];
	}

	immutable(T) get(immutable u8 offset) const {
		verify(offset + 1 < size);
		return values[size - 1 - offset];
	}

	void dup(immutable u8 offset) {
		verify(offset < size);
		verify(size != capacity);
		values[size] = values[size - 1 - offset];
		size++;
	}

	immutable(T) remove(immutable u8 offset) {
		verify(offset + 1 < size);
		immutable T res = values[size - 1 - offset];
		remove(offset, 1);
		return res;
	}

	void remove(immutable u8 offset, immutable u8 nEntries) {
		verify(nEntries != 0);
		verify(offset <= nEntries);
		verify(offset + 1 + nEntries < size);
		foreach (immutable size_t i; size - 1 - offset..size - nEntries)
			values[i] = values[i + nEntries];
		size -= nEntries;
	}

	T* stackRef(immutable StackOffset offset) {
		return &values[size - 1 - offset.offset];
	}
}

private:

enum StepResult {
	continue_,
	exit,
}

alias DataStack = GlobalAllocatedStack!(u64, 1024 * 4);

struct Interpreter {
	immutable Ptr!ByteCode byteCode;
	immutable Ptr!FilesInfo filesInfo;
	ByteCodeReader reader;
	DataStack dataStack;
	GlobalAllocatedStack!(immutable(u8)*, 1024) returnStack;
}

@trusted ref immutable(FileAndPos) curSource(ref const Interpreter interpreter) {
	immutable size_t index = getReaderPtr(interpreter.reader) - begin(interpreter.byteCode.byteCode);
	return at(interpreter.byteCode.sources, index);
}

immutable(StepResult) step(ref Interpreter interpreter) {
	immutable Operation operation = readOperation(interpreter.reader);

	debug {
		import core.stdc.stdio : printf;
		import util.alloc.stackAlloc : StackAlloc;
		import util.print : print;
		import util.sexpr : writeSexpr;
		import util.writer : finishWriterToCStr, writeChar, Writer, writeStatic;

		alias TempAlloc = StackAlloc!("temp", 1024 * 4);
		TempAlloc temp;
		Writer!TempAlloc writer = Writer!TempAlloc(ptrTrustMe_mut(temp));
		writeStatic(writer, "STEP: ");
		writeFileAndPos!(TempAlloc, TempAlloc)(temp, writer, interpreter.filesInfo, curSource(interpreter));
		writeChar(writer, ' ');
		writeSexpr(writer, sexprOfOperation(temp, operation));
		writeChar(writer, '\n');
		print(finishWriterToCStr(writer));
	}

	return matchOperationImpure!(immutable StepResult)(
		operation,
		(ref immutable Operation.Call it) {
			call(interpreter, it.address);
			return StepResult.continue_;
		},
		(ref immutable Operation.CallFunPtr it) {
			call(interpreter, removeAtStackOffset(interpreter, it.stackOffsetOfFunPtr));
			return StepResult.continue_;
		},
		(ref immutable Operation.Dup it) {
			interpreter.dataStack.dup(it.offset.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.DupPartial it) {
			interpreter.dataStack.push(
				getBytes(interpreter.dataStack.get(it.entryOffset.offset), it.byteOffset, it.sizeBytes));
			return StepResult.continue_;
		},
		(ref immutable Operation.Fn it) {
			applyFn(interpreter, it.fnOp);
			return StepResult.continue_;
		},
		(ref immutable Operation.Jump it) {
			readerJump(interpreter.reader, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Pack it) {
			todo!void("PACK");
			return StepResult.continue_;
		},
		(ref immutable Operation.PushValue it) {
			interpreter.dataStack.push(it.value);
			return StepResult.continue_;
		},
		(ref immutable Operation.Read it) {
			read(interpreter.dataStack, it.offset, it.size);
			return StepResult.continue_;
		},
		(ref immutable Operation.Remove it) {
			interpreter.dataStack.remove(it.offset.offset, it.nEntries);
			return StepResult.continue_;
		},
		(ref immutable Operation.Return) {
			if (interpreter.returnStack.isEmpty())
				return StepResult.exit;
			else {
				setReaderPtr(interpreter.reader, interpreter.returnStack.pop());
				return StepResult.continue_;
			}
		},
		(ref immutable Operation.StackRef it) {
			pushStackRef(interpreter.dataStack, it.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.Switch) {
			readerSwitch(interpreter.reader, interpreter.dataStack.pop());
			return StepResult.continue_;
		},
		(ref immutable Operation.Write it) {
			write(interpreter.dataStack, it.offset, it.size);
			return StepResult.continue_;
		});
}

void pushStackRef(ref DataStack dataStack, immutable StackOffset offset) {
	dataStack.push(cast(immutable u64) dataStack.stackRef(offset));
}

@trusted void read(ref DataStack data, immutable u8 offset, immutable u8 size) {
	immutable u64* ptr = cast(immutable u64*) data.pop();
	if (size < 8) { //TODO: just have 2 different ops then
		data.push(readPartialBytes((cast(immutable u8*) ptr) + offset, size));
	} else {
		verify(size % 8 == 0);
		verify(offset % 8 == 0);
		foreach (immutable size_t i; 0..(size / 8))
			data.push((ptr + (offset / 8))[i]);
	}
}

@trusted void write(ref DataStack data, immutable u8 offset, immutable u8 size) {
	if (size < 8) { //TODO: just have 2 different ops then
		immutable u64 value = data.pop();
		u64* ptr = cast(u64*) data.pop();
		writePartialBytes((cast(u8*) ptr) + offset, value, size);
	} else {
		verify(size % 8 == 0);
		verify(offset % 8 == 0);
		immutable u8 sizeWords = size / 8;
		u64* ptr = (cast(u64*) data.peek(sizeWords)) + (offset / 8);
		foreach (immutable size_t i; 0..sizeWords)
			*ptr = data.peek(cast(immutable u8) (sizeWords - 1 - i));
		data.popN(sizeWords + 1);
	}
}

@trusted immutable(u64) readPartialBytes(immutable u8* ptr, immutable u8 size) {
	//TODO: Just have separate ops for separate sizes?
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
	//TODO: Just have separate ops for separate sizes?
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

void applyFn(ref Interpreter interpreter, immutable FnOp fn) {
	todo!void("!");
}

immutable(u64) getBytes(immutable u64 a, immutable u8 byteOffset, immutable u8 sizeBytes) {
	verify(byteOffset + sizeBytes <= 8);
	immutable u64 shift = 8 - sizeBytes - byteOffset;
	immutable u64 mask = maxU64 >> (8 - sizeBytes);
	return (a >> shift) & mask;
}

void call(ref Interpreter interpreter, immutable u64 address) {
	interpreter.returnStack.push(getReaderPtr(interpreter.reader));
	setReaderPtr(interpreter.reader, ptrAt(interpreter.byteCode.byteCode, address).rawPtr());
}

immutable(u64) removeAtStackOffset(ref Interpreter interpreter, immutable StackOffset offset) {
	return interpreter.dataStack.remove(offset.offset);
}

