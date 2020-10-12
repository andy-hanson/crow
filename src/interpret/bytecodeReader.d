module interpret.bytecodeReader;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCode, FnOp, Operation, StackOffset;
import interpret.opcode : OpCode;
import util.collection.arr : Arr;
import util.ptr : Ptr;
import util.types : U4U4, u4u4OfU8, u8, u32, u64;

struct ByteCodeReader {
	immutable(OpCode)* ptr;
}

immutable(Operation) readOperation(ref ByteCodeReader reader) {
	immutable OpCode code = *reader.ptr;
	final switch (code) {
		case OpCode.call:
			return immutable Operation(immutable Operation.Call(readU32(reader)));
		case OpCode.callFunPtr:
			return immutable Operation(immutable Operation.CallFunPtr(readStackOffset(reader)));
		case OpCode.dup:
			return immutable Operation(immutable Operation.Dup(readStackOffset(reader)));
		case OpCode.dupPartial:
			immutable StackOffset offset = readStackOffset(reader);
			immutable U4U4 offsetAndSize = u4u4OfU8(readU8(reader));
			return immutable Operation(immutable Operation.DupPartial(offset, offsetAndSize.a, offsetAndSize.b));
		case OpCode.fn:
			return immutable Operation(immutable Operation.Fn(cast(immutable FnOp) readU8(reader)));
		case OpCode.jump:
			return immutable Operation(immutable Operation.Jump(readU8(reader)));
		case OpCode.pack:
			return immutable Operation(immutable Operation.Pack(readU8Array(reader, readU8(reader))));
		case OpCode.pushU32:
			return immutable Operation(immutable Operation.PushValue(readU32(reader)));
		case OpCode.pushU64:
			return immutable Operation(immutable Operation.PushValue(readU64(reader)));
		case OpCode.read:
			return immutable Operation(immutable Operation.Read(readU8(reader), readU8(reader)));
		case OpCode.remove:
			return immutable Operation(immutable Operation.Remove(readStackOffset(reader), readU8(reader)));
		case OpCode.return_:
			return immutable Operation(immutable Operation.Return());
		case OpCode.stackRef:
			return immutable Operation(immutable Operation.StackRef(readStackOffset(reader)));
		case OpCode.switch_:
			return immutable Operation(immutable Operation.Switch());
		case OpCode.write:
			return immutable Operation(immutable Operation.Write(readU8(reader), readU8(reader)));
	}
}

@trusted void readerJump(ref ByteCodeReader reader, immutable u8 jump) {
	reader.ptr += jump;
}

@trusted void readerSwitch(ref ByteCodeReader reader, immutable u64 value) {
	immutable u8 jump = *((cast(immutable u8*) reader.ptr) + value);
	readerJump(reader, jump);
}

private:

@trusted immutable(Arr!u8) readU8Array(ref ByteCodeReader reader, immutable u8 size) {
	immutable u8* ptr = cast(immutable u8*) reader.ptr;
	immutable Arr!u8 res = immutable Arr!u8(ptr, size);
	reader.ptr = cast(immutable OpCode*) (ptr + size);
	return res;
}

immutable(StackOffset) readStackOffset(ref ByteCodeReader reader) {
	return immutable StackOffset(readU8(reader));
}

@trusted immutable(u8) readU8(ref ByteCodeReader reader) {
	immutable(u8)* ptr = cast(immutable(u8)*) reader.ptr;
	immutable u8 res = *ptr;
	reader.ptr = cast(immutable(OpCode)*) ptr + 1;
	return res;
}

@trusted immutable(u32) readU32(ref ByteCodeReader reader) {
	immutable(u32)* ptr = cast(immutable(u32)*) reader.ptr;
	immutable u32 res = *ptr;
	reader.ptr = cast(immutable(OpCode)*) ptr + 1;
	return res;
}

@trusted immutable(u64) readU64(ref ByteCodeReader reader) {
	immutable(u64)* ptr = cast(immutable(u64)*) reader.ptr;
	immutable u64 res = *ptr;
	reader.ptr = cast(immutable(OpCode)*) ptr + 1;
	return res;
}
