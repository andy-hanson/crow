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
import util.types : Nat64;
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

immutable(Nat64) nStackEntriesForType(ref immutable LowProgram program, immutable LowType t) {
	return nStackEntriesForBytes(immutable Nat64(sizeOfType(program, t).size));
}

private immutable(Nat64) nStackEntriesForBytes(immutable Nat64 bytes) {
	return divRoundUp(bytes, stackEntrySize);
}

struct Pack {
	immutable Nat64 inEntries;
	immutable Nat64 outEntries;
	immutable PackField[] fields;
}

struct PackField {
	immutable Nat64 inOffset;
	immutable Nat64 outOffset;
	immutable Nat64 size;
}

immutable(Opt!Pack) optPack(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
	immutable LowType.Record type,
) {
	immutable LowRecord record = fullIndexDictGet(program.allRecords, type);

	if (every!LowField(record.fields, (ref immutable LowField field) => field.offset % 8 == 0))
		return none!Pack;
	else {
		Nat64 inOffsetEntries = immutable Nat64(0);
		immutable PackField[] fields = map!(PackField)(tempAlloc, record.fields, (ref immutable LowField field) {
			immutable Nat64 fieldInOffsetBytes = inOffsetEntries * immutable Nat64(8);
			immutable Nat64 fieldSizeBytes = immutable Nat64(sizeOfType(program, field.type).size);
			inOffsetEntries += nStackEntriesForBytes(fieldSizeBytes);
			return immutable PackField(fieldInOffsetBytes, immutable Nat64(field.offset), fieldSizeBytes);
		});
		immutable Nat64 outEntries = nStackEntriesForType(program, immutable LowType(type));
		return some(immutable Pack(inOffsetEntries, outEntries, fields));
	}
}

immutable TypeSize funPtrSize = ptrSize;

private:

immutable TypeSize ptrSize = immutable TypeSize(8, 8);
immutable TypeSize externPtrSize = ptrSize;

immutable(TypeSize) primitiveSize(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.void_:
			return immutable TypeSize(0, 1);
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.int8:
		case PrimitiveType.nat8:
			return immutable TypeSize(1, 1);
		case PrimitiveType.int16:
		case PrimitiveType.nat16:
			return immutable TypeSize(2, 2);
		case PrimitiveType.float32:
		case PrimitiveType.int32:
		case PrimitiveType.nat32:
			return immutable TypeSize(4, 4);
		case PrimitiveType.float64:
		case PrimitiveType.int64:
		case PrimitiveType.nat64:
			return immutable TypeSize(8, 8);
	}
}
