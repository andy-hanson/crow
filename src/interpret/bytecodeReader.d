module interpret.bytecodeReader;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	DebugOperation,
	ExternOp,
	FnOp,
	Operation,
	StackOffset;
import interpret.opcode : OpCode;
import util.collection.arr : Arr, at;
import util.collection.byteReader :
	ByteReader,
	getPtr,
	readInt16,
	readU8,
	readU8Array,
	readU16ArrayDoNotSkipBytes,
	readU16,
	readU32,
	readU64,
	setPtr,
	skipBytes;
import util.types : incr, Nat8, Nat16, Nat32, Nat64, U4U4, u4u4OfU8, u8, u16, u32, u64;
import util.util : unreachable;

struct ByteCodeReader {
	private:
	ByteReader reader;
}

@trusted ByteCodeReader newByteCodeReader(immutable u8* bytes, immutable Nat32 start) {
	return ByteCodeReader(ByteReader(bytes + start.raw()));
}

immutable(u8)* getReaderPtr(ref const ByteCodeReader reader) {
	return getPtr(reader.reader);
}

void setReaderPtr(ref ByteCodeReader reader, immutable u8* bytes) {
	setPtr(reader.reader, bytes);
}

@trusted immutable(Operation) readOperation(ref ByteCodeReader reader) {
	immutable OpCode code = cast(immutable OpCode) readU8(reader.reader).raw();
	final switch (code) {
		case OpCode.reserved0:
		case OpCode.reserved1:
		case OpCode.reserved2:
		case OpCode.reserved3:
			return unreachable!(immutable Operation)();
		case OpCode.assertStackSize:
			return immutable Operation(immutable Operation.Debug(
				immutable DebugOperation(immutable DebugOperation.AssertStackSize(readU16(reader.reader)))));
		case OpCode.assertUnreachable:
			return immutable Operation(immutable Operation.Debug(
				immutable DebugOperation(immutable DebugOperation.AssertUnreachable())));
		case OpCode.call:
			return immutable Operation(immutable Operation.Call(
				immutable ByteCodeIndex(readU32(reader.reader)),
				readU8(reader.reader)));
		case OpCode.callFunPtr:
			return immutable Operation(immutable Operation.CallFunPtr(readU8(reader.reader)));
		case OpCode.dup:
			return immutable Operation(immutable Operation.Dup(readStackOffset(reader)));
		case OpCode.dupPartial:
			immutable StackOffset offset = readStackOffset(reader);
			immutable U4U4 offsetAndSize = u4u4OfU8(readU8(reader.reader));
			return immutable Operation(immutable Operation.DupPartial(offset, offsetAndSize.a, offsetAndSize.b));
		case OpCode.extern_:
			return immutable Operation(immutable Operation.Extern(
				cast(immutable ExternOp) readU8(reader.reader).raw()));
		case OpCode.fn:
			return immutable Operation(immutable Operation.Fn(cast(immutable FnOp) readU8(reader.reader).raw()));
		case OpCode.jump:
			return immutable Operation(immutable Operation.Jump(immutable ByteCodeOffset(readInt16(reader.reader))));
		case OpCode.pack:
			return immutable Operation(
				immutable Operation.Pack(readU8Array(reader.reader, readU8(reader.reader).raw())));
		case OpCode.pushU32:
			return immutable Operation(immutable Operation.PushValue(readU32(reader.reader).to64()));
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
			immutable Nat8 size = readU8(reader.reader);
			immutable Arr!Nat16 offsets = readU16ArrayDoNotSkipBytes(reader.reader, size.raw());
			return immutable Operation(immutable Operation.Switch(cast(immutable Arr!ByteCodeOffsetUnsigned) offsets));
		case OpCode.write:
			return immutable Operation(immutable Operation.Write(readU8(reader.reader), readU8(reader.reader)));
	}
}

@trusted void readerJump(ref ByteCodeReader reader, immutable ByteCodeOffset jump) {
	skipBytes(reader.reader, jump.offset.raw());
}

@trusted void readerSwitch(
	ref ByteCodeReader reader,
	immutable Nat64 value,
	immutable Arr!ByteCodeOffsetUnsigned offsets,
) {
	immutable ByteCodeOffsetUnsigned offset = at(offsets, value.raw());
	// Jump is relative to after value.
	immutable Nat16 fullOffset = (incr(value) * immutable Nat64(ByteCodeOffsetUnsigned.sizeof)).to16() + offset.offset;
	readerJump(reader, immutable ByteCodeOffset(fullOffset.toInt16()));
}

private:

immutable(StackOffset) readStackOffset(ref ByteCodeReader reader) {
	return immutable StackOffset(readU8(reader.reader));
}
