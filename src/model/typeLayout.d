module model.typeLayout;

@safe @nogc pure nothrow:

import interpret.bytecode : Operation, stackEntrySize;
import model.concreteModel : TypeSize;
import model.lowModel :
	LowField,
	LowProgram,
	LowRecord,
	LowType,
	matchLowType,
	PrimitiveType,
	typeSize;
import util.collection.arr : size;
import util.collection.arrUtil : every, map;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : none, Opt, some;
import util.types : Nat8, Nat16;
import util.util : divRoundUp;

immutable(TypeSize) sizeOfType(ref immutable LowProgram program, immutable LowType t) {
	return matchLowType!(immutable TypeSize)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowType.PtrGc) =>
			ptrSize,
		(immutable LowType.PtrRaw) =>
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

immutable(Opt!(Operation.Pack)) optPack(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
	immutable LowType.Record type,
) {
	immutable LowRecord record = fullIndexDictGet(program.allRecords, type);

	if (every!LowField(record.fields, (ref immutable LowField field) => field.offset.raw() % 8 == 0))
		return none!(Operation.Pack);
	else {
		Nat8 inOffsetEntries = immutable Nat8(0);
		immutable Operation.Pack.Field[] fields = map!(Operation.Pack.Field)(
			tempAlloc,
			record.fields,
			(ref immutable LowField field) {
				immutable Nat16 fieldInOffsetBytes = inOffsetEntries.to16() * immutable Nat16(8);
				immutable Nat16 fieldSizeBytes = sizeOfType(program, field.type).size;
				inOffsetEntries += nStackEntriesForBytes(fieldSizeBytes);
				return immutable Operation.Pack.Field(fieldInOffsetBytes, field.offset, fieldSizeBytes);
			});
		immutable Nat8 outEntries = nStackEntriesForType(program, immutable LowType(type));
		return some(immutable Operation.Pack(inOffsetEntries, outEntries, fields));
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
