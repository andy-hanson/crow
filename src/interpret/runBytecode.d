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
import util.collection.arr : Arr, at, begin, ptrAt, size;
import util.collection.arrUtil : zip;
import util.collection.globalAllocatedStack : dup, GlobalAllocatedStack, isEmpty, peek, pop, popN, push, remove, stackRef;
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
				immutable u64 returnCode = pop(interpreter.dataStack);
				verify(isEmpty(interpreter.dataStack));
				return safeIntFromU64(returnCode);
		}
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
			dup(interpreter.dataStack, it.offset.offset);
			return StepResult.continue_;
		},
		(ref immutable Operation.DupPartial it) {
			push(interpreter.dataStack,
				getBytes(peek(interpreter.dataStack, it.entryOffset.offset), it.byteOffset, it.sizeBytes));
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
			*ptr = peek(data, cast(immutable u8) (sizeWords - 1 - i));
		popN(data, sizeWords + 1);
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
	final switch (fn) {
		case FnOp.addFloat64:
		case FnOp.addInt64OrNat64:
		case FnOp.bitShiftLeftInt32:
		case FnOp.bitShiftLeftNat32:
		case FnOp.bitShiftRightInt32:
		case FnOp.bitShiftRightNat32:
		case FnOp.bitwiseAnd:
		case FnOp.bitwiseOr:
		case FnOp.compareExchangeStrong:
		case FnOp.eqNat:
		case FnOp.float64FromInt64:
		case FnOp.float64FromNat64:
		case FnOp.hardFail:
		case FnOp.lessFloat64:
		case FnOp.lessInt8:
		case FnOp.lessInt16:
		case FnOp.lessInt32:
		case FnOp.lessInt64:
		case FnOp.lessNat:
		case FnOp.malloc:
		case FnOp.mulFloat64:
		case FnOp.not:
		case FnOp.ptrToOrRefOfVal:
		case FnOp.subFloat64:
		case FnOp.truncateToInt64FromFloat64:
		case FnOp.unsafeDivFloat64:
		case FnOp.unsafeDivInt64:
		case FnOp.unsafeDivNat64:
		case FnOp.unsafeModNat64:
		case FnOp.wrapAddInt16:
		case FnOp.wrapAddInt32:
		case FnOp.wrapAddInt64:
		case FnOp.wrapAddNat16:
		case FnOp.wrapAddNat32:
			todo!void("!");
			break;
		case FnOp.wrapAddNat64:
			immutable u64 a = pop(interpreter.dataStack);
			immutable u64 b = pop(interpreter.dataStack);
			push(interpreter.dataStack, a + b);
			break;
		case FnOp.wrapMulInt16:
		case FnOp.wrapMulInt32:
		case FnOp.wrapMulInt64:
		case FnOp.wrapMulNat16:
		case FnOp.wrapMulNat32:
		case FnOp.wrapMulNat64:
		case FnOp.wrapSubInt16:
		case FnOp.wrapSubInt32:
		case FnOp.wrapSubInt64:
		case FnOp.wrapSubNat16:
		case FnOp.wrapSubNat32:
		case FnOp.wrapSubNat64:
			todo!void("!");
			break;
	}
}

immutable(u64) getBytes(immutable u64 a, immutable u8 byteOffset, immutable u8 sizeBytes) {
	verify(byteOffset + sizeBytes <= 8);
	immutable u64 shift = 8 - sizeBytes - byteOffset;
	immutable u64 mask = maxU64 >> (8 - sizeBytes);
	return (a >> shift) & mask;
}

void call(ref Interpreter interpreter, immutable u64 address) {
	push(interpreter.returnStack, getReaderPtr(interpreter.reader));
	setReaderPtr(interpreter.reader, ptrAt(interpreter.byteCode.byteCode, address).rawPtr());
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
	});
	verify(totalSize <= 8);
	immutable u64 remainingBytes = 8 - totalSize;
	return res << (remainingBytes * 8);
}

//TODO:MOVE
immutable(u64) bottomNBytes(immutable u64 value, immutable u8 n) {
	return value & ((1 << (n * 8)) - 1);
}

