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
import util.util : divRoundUp;

immutable(TypeSize) sizeOfType(ref immutable LowProgram program, immutable LowType a) {
	return matchLowTypeCombinePtr!(
		immutable TypeSize,
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
			typeSize(fullIndexDictGet(program.allUnions, index)),
	)(a);
}

immutable(size_t) nStackEntriesForType(ref immutable LowProgram program, immutable LowType a) {
	return nStackEntriesForBytes(sizeOfType(program, a).size);
}

private immutable(size_t) nStackEntriesForBytes(immutable size_t bytes) {
	return divRoundUp(bytes, stackEntrySize);
}

struct Pack {
	immutable size_t inEntries;
	immutable size_t outEntries;
	immutable PackField[] fields;
}

struct PackField {
	immutable size_t inOffset;
	immutable size_t outOffset;
	immutable size_t size;
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
		size_t inOffsetEntries = 0;
		immutable PackField[] fields = map!(PackField)(tempAlloc, record.fields, (ref immutable LowField field) {
			immutable size_t fieldInOffsetBytes = inOffsetEntries * 8;
			immutable size_t fieldSizeBytes = sizeOfType(program, field.type).size;
			inOffsetEntries += nStackEntriesForBytes(fieldSizeBytes);
			return immutable PackField(fieldInOffsetBytes, field.offset, fieldSizeBytes);
		});
		immutable size_t outEntries = nStackEntriesForType(program, immutable LowType(type));
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
