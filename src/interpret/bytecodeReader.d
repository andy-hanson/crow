module interpret.bytecodeReader;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCode, ByteCodeOffset, FnOp, Operation, StackOffset;
import interpret.opcode : OpCode;
import util.collection.byteReader :
	ByteReader,
	getPtr,
	readU8,
	readU8Array,
	readU16,
	readU32,
	readU64,
	setPtr,
	skipBytes;
import util.types : U4U4, u4u4OfU8, u8, u16, u32, u64;

struct ByteCodeReader {
	private:
	ByteReader reader;
}

ByteCodeReader newByteCodeReader(immutable u8* bytes) {
	return ByteCodeReader(ByteReader(bytes));
}

immutable(u8)* getReaderPtr(ref const ByteCodeReader reader) {
	return getPtr(reader.reader);
}

void setReaderPtr(ref ByteCodeReader reader, immutable u8* bytes) {
	setPtr(reader.reader, bytes);
}

immutable(Operation) readOperation(ref ByteCodeReader reader) {
	immutable OpCode code = cast(immutable OpCode) readU8(reader.reader);
	final switch (code) {
		case OpCode.call:
			return immutable Operation(immutable Operation.Call(readU32(reader.reader)));
		case OpCode.callFunPtr:
			return immutable Operation(immutable Operation.CallFunPtr(readStackOffset(reader)));
		case OpCode.dup:
			return immutable Operation(immutable Operation.Dup(readStackOffset(reader)));
		case OpCode.dupPartial:
			immutable StackOffset offset = readStackOffset(reader);
			immutable U4U4 offsetAndSize = u4u4OfU8(readU8(reader.reader));
			return immutable Operation(immutable Operation.DupPartial(offset, offsetAndSize.a, offsetAndSize.b));
		case OpCode.fn:
			return immutable Operation(immutable Operation.Fn(cast(immutable FnOp) readU8(reader.reader)));
		case OpCode.jump:
			return immutable Operation(immutable Operation.Jump(immutable ByteCodeOffset(readU16(reader.reader))));
		case OpCode.pack:
			return immutable Operation(immutable Operation.Pack(readU8Array(reader.reader, readU8(reader.reader))));
		case OpCode.pushU32:
			return immutable Operation(immutable Operation.PushValue(readU32(reader.reader)));
		case OpCode.pushU64:
			return immutable Operation(immutable Operation.PushValue(readU64(reader.reader)));
		case OpCode.read:
			return immutable Operation(immutable Operation.Read(readU8(reader.reader), readU8(reader.reader)));
		case OpCode.remove:
			return immutable Operation(immutable Operation.Remove(readStackOffset(reader), readU8(reader.reader)));
		case OpCode.return_:
			return immutable Operation(immutable Operation.Return());
		case OpCode.stackRef:
			return immutable Operation(immutable Operation.StackRef(readStackOffset(reader)));
		case OpCode.switch_:
			return immutable Operation(immutable Operation.Switch());
		case OpCode.write:
			return immutable Operation(immutable Operation.Write(readU8(reader.reader), readU8(reader.reader)));
	}
}

@trusted void readerJump(ref ByteCodeReader reader, immutable ByteCodeOffset jump) {
	skipBytes(reader.reader, jump.offset);
}

@trusted void readerSwitch(ref ByteCodeReader reader, immutable u64 value) {
	skipBytes(reader.reader, ByteCodeOffset.sizeof * value);
	immutable ByteCodeOffset offset = immutable ByteCodeOffset(readU16(reader.reader));
	readerJump(reader, offset);
}

private:

immutable(StackOffset) readStackOffset(ref ByteCodeReader reader) {
	return immutable StackOffset(readU8(reader.reader));
}
