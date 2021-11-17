module interpret.bytecodeReader;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCodeIndex,
	ByteCodeOffset,
	ByteCodeOffsetUnsigned,
	DebugOperation,
	DynCallType,
	ExternOp,
	FnOp,
	Operation,
	StackOffset,
	StackOffsetBytes;
import interpret.opcode : OpCode;
import util.collection.arr : at;
import util.collection.arrUtil : findIndex;
import util.collection.byteReader :
	ByteReader,
	getPtr,
	readInt16,
	readArray,
	readArrayDoNotSkipBytes,
	readU8,
	readU16,
	readU32,
	readU48,
	readU64,
	setPtr,
	skipBytes;
import util.opt : force, has, Opt;
import util.sym : Sym;
import util.types : incr, Nat8, Nat16, Nat32, Nat64, safeSizeTFromU64;
import util.util : todo, unreachable;

struct ByteCodeReader {
	private:
	ByteReader reader;
}

@trusted ByteCodeReader newByteCodeReader(immutable ubyte* bytes, immutable Nat32 start) {
	return ByteCodeReader(ByteReader(bytes + start.raw()));
}

immutable(ubyte)* getReaderPtr(ref const ByteCodeReader reader) {
	return getPtr(reader.reader);
}

void setReaderPtr(ref ByteCodeReader reader, immutable ubyte* bytes) {
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
		case OpCode.dupBytes:
			return immutable Operation(
				immutable Operation.DupBytes(readStackOffsetBytes(reader), readU16(reader.reader)));
		case OpCode.dupWord:
			return immutable Operation(immutable Operation.DupWord(readStackOffset(reader)));
		case OpCode.dupWords:
			return immutable Operation(immutable Operation.DupWords(readStackOffset(reader), readU8(reader.reader)));
		case OpCode.extern_:
			return immutable Operation(immutable Operation.Extern(
				cast(immutable ExternOp) readU8(reader.reader).raw()));
		case OpCode.externDynCall:
			immutable Sym name = immutable Sym(readU64(reader.reader).raw());
			static assert(DynCallType.sizeof == Nat8.sizeof);
			immutable DynCallType returnType = cast(immutable DynCallType) readU8(reader.reader).raw();
			immutable DynCallType[] parameterTypes =
				readArray!DynCallType(reader.reader, readU8(reader.reader).raw());
			return immutable Operation(immutable Operation.ExternDynCall(name, returnType, parameterTypes));
		case OpCode.fn:
			return immutable Operation(immutable Operation.Fn(cast(immutable FnOp) readU8(reader.reader).raw()));
		case OpCode.jump:
			return immutable Operation(immutable Operation.Jump(immutable ByteCodeOffset(readInt16(reader.reader))));
		case OpCode.pack:
			immutable Nat8 inEntries = readU8(reader.reader);
			immutable Nat8 outEntries = readU8(reader.reader);
			immutable Nat8 nFields = readU8(reader.reader);
			return immutable Operation(immutable Operation.Pack(
				inEntries,
				outEntries,
				readArray!(Operation.Pack.Field)(reader.reader, nFields.raw())));
		case OpCode.pushU8:
			return immutable Operation(immutable Operation.PushValue(readU8(reader.reader).to64()));
		case OpCode.pushU16:
			return immutable Operation(immutable Operation.PushValue(readU16(reader.reader).to64()));
		case OpCode.pushU32:
			return immutable Operation(immutable Operation.PushValue(readU32(reader.reader).to64()));
		case OpCode.pushU48:
			return immutable Operation(immutable Operation.PushValue(readU48(reader.reader).to64()));
		case OpCode.pushU64:
			return immutable Operation(immutable Operation.PushValue(readU64(reader.reader)));
		case OpCode.read:
			return immutable Operation(immutable Operation.Read(readU16(reader.reader), readU16(reader.reader)));
		case OpCode.remove:
			return immutable Operation(immutable Operation.Remove(readStackOffset(reader), readU8(reader.reader)));
		case OpCode.return_:
			return immutable Operation(immutable Operation.Return());
		case OpCode.stackRef:
			return immutable Operation(immutable Operation.StackRef(readStackOffset(reader)));
		case OpCode.switch0ToN:
			immutable Nat16 size = readU16(reader.reader);
			immutable ByteCodeOffsetUnsigned[] offsets =
				readArrayDoNotSkipBytes!ByteCodeOffsetUnsigned(reader.reader, size.raw());
			return immutable Operation(immutable Operation.Switch0ToN(offsets));
		case OpCode.switchWithValues:
			immutable Nat16 size = readU16(reader.reader);
			immutable Nat64[] values = readArray!Nat64(reader.reader, size.raw());
			immutable ByteCodeOffsetUnsigned[] offsets =
				readArrayDoNotSkipBytes!ByteCodeOffsetUnsigned(reader.reader, size.raw());
			return immutable Operation(immutable Operation.SwitchWithValues(values, offsets));
		case OpCode.write:
			return immutable Operation(immutable Operation.Write(readU16(reader.reader), readU16(reader.reader)));
	}
}

@trusted void readerJump(ref ByteCodeReader reader, immutable ByteCodeOffset jump) {
	skipBytes(reader.reader, jump.offset.raw());
}

@trusted void readerSwitch(
	ref ByteCodeReader reader,
	immutable Nat64 value,
	immutable ByteCodeOffsetUnsigned[] offsets,
) {
	immutable ByteCodeOffsetUnsigned offset = at(offsets, safeSizeTFromU64(value.raw()));
	// Jump is relative to after value.
	immutable Nat16 fullOffset = (incr(value) * immutable Nat64(ByteCodeOffsetUnsigned.sizeof)).to16() + offset.offset;
	readerJump(reader, immutable ByteCodeOffset(fullOffset.toInt16()));
}

void readerSwitchWithValues(
	ref ByteCodeReader reader,
	immutable Nat64 value,
	immutable Nat64[] values,
	immutable ByteCodeOffsetUnsigned[] offsets,
) {
	immutable long valueLong = value.raw();
	immutable Opt!size_t index = findIndex!Nat64(values, (ref immutable Nat64 v) => v.raw() == valueLong);
	if (!has(index))
		todo!void("!");
	else
		readerSwitch(reader, immutable Nat64(force(index)), offsets);
}

private:

immutable(StackOffset) readStackOffset(ref ByteCodeReader reader) {
	return immutable StackOffset(readU8(reader.reader));
}

immutable(StackOffsetBytes) readStackOffsetBytes(ref ByteCodeReader reader) {
	return immutable StackOffsetBytes(readU16(reader.reader));
}
