module model.typeLayout;

@safe @nogc pure nothrow:

import interpret.bytecode : stackEntrySize;
import model.concreteModel : TypeSize;
import model.lowModel :
	LowField,
	LowProgram,
	LowPtrCombine,
	LowRecord,
	LowType,
	matchLowTypeCombinePtr,
	PrimitiveType,
	typeSize;
import util.collection.arr : size;
import util.collection.arrUtil : every, map;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : none, Opt, some;
import util.types : Nat8, Nat16;
import util.util : divRoundUp;

immutable(TypeSize) sizeOfType(ref immutable LowProgram program, immutable LowType t) {
	return matchLowTypeCombinePtr!(immutable TypeSize)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowPtrCombine) =>
			ptrSize,
		(immutable LowType.Record index) =>
			typeSize(fullIndexDictGet(program.allRecords, index)),
		(immutable LowType.Union index) =>
			typeSize(fullIndexDictGet(program.allUnions, index)));
}

immutable(Nat8) nStackEntriesForType(ref immutable LowProgram program, immutable LowType t) {
	return nStackEntriesForBytes(sizeOfType(program, t).size);
}

private immutable(Nat8) nStackEntriesForBytes(immutable Nat16 bytes) {
	return divRoundUp(bytes, stackEntrySize).to8();
}

struct Pack {
	immutable Nat8 inEntries;
	immutable Nat8 outEntries;
	immutable PackField[] fields;
}

struct PackField {
	immutable Nat16 inOffset;
	immutable Nat16 outOffset;
	immutable Nat16 size;
}

immutable(Opt!Pack) optPack(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
	immutable LowType.Record type,
) {
	immutable LowRecord record = fullIndexDictGet(program.allRecords, type);

	if (every!LowField(record.fields, (ref immutable LowField field) => field.offset.raw() % 8 == 0))
		return none!Pack;
	else {
		Nat8 inOffsetEntries = immutable Nat8(0);
		immutable PackField[] fields = map!(PackField)(
			tempAlloc,
			record.fields,
			(ref immutable LowField field) {
				immutable Nat16 fieldInOffsetBytes = inOffsetEntries.to16() * immutable Nat16(8);
				immutable Nat16 fieldSizeBytes = sizeOfType(program, field.type).size;
				inOffsetEntries += nStackEntriesForBytes(fieldSizeBytes);
				return immutable PackField(fieldInOffsetBytes, field.offset, fieldSizeBytes);
			});
		immutable Nat8 outEntries = nStackEntriesForType(program, immutable LowType(type));
		return some(immutable Pack(inOffsetEntries, outEntries, fields));
	}
}

immutable TypeSize funPtrSize = ptrSize;

private:

immutable TypeSize ptrSize = immutable TypeSize(immutable Nat16(8), immutable Nat8(8));
immutable TypeSize externPtrSize = ptrSize;

immutable(TypeSize) primitiveSize(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.void_:
			return immutable TypeSize(immutable Nat16(0), immutable Nat8(1));
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.int8:
		case PrimitiveType.nat8:
			return immutable TypeSize(immutable Nat16(1), immutable Nat8(1));
		case PrimitiveType.int16:
		case PrimitiveType.nat16:
			return immutable TypeSize(immutable Nat16(2), immutable Nat8(2));
		case PrimitiveType.float32:
		case PrimitiveType.int32:
		case PrimitiveType.nat32:
			return immutable TypeSize(immutable Nat16(4), immutable Nat8(4));
		case PrimitiveType.float64:
		case PrimitiveType.int64:
		case PrimitiveType.nat64:
			return immutable TypeSize(immutable Nat16(8), immutable Nat8(8));
	}
}
