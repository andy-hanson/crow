module model.typeLayout;

@safe @nogc pure nothrow:

import interpret.bytecode : stackEntrySize;
import model.concreteModel : TypeSize;
import model.lowModel : AllLowTypes, LowField, LowProgram, LowPtrCombine, LowRecord, LowType, PrimitiveType, typeSize;
import util.col.array : every, map;
import util.opt : none, Opt, some;
import util.util : divRoundUp, isMultipleOf;

bool isEmptyType(in AllLowTypes types, in LowType a) =>
	typeSizeBytes(types, a) == 0;

size_t typeSizeBytes(in LowProgram program, in LowType a) =>
	typeSizeBytes(program.allTypes, a);
size_t typeSizeBytes(in AllLowTypes types, in LowType a) =>
	sizeOfType(types, a).sizeBytes;

TypeSize sizeOfType(in LowProgram program, in LowType a) =>
	sizeOfType(program.allTypes, a);
TypeSize sizeOfType(in AllLowTypes types, in LowType a) =>
	a.combinePointer.match!TypeSize(
		(LowType.Extern x) =>
			typeSize(types.allExternTypes[x]),
		(LowType.FunPointer) =>
			funPtrSize,
		(PrimitiveType it) =>
			primitiveSize(it),
		(LowPtrCombine) =>
			ptrSize,
		(LowType.Record index) =>
			typeSize(types.allRecords[index]),
		(LowType.Union index) =>
			typeSize(types.allUnions[index]));

size_t nStackEntriesForType(in LowProgram program, in LowType a) =>
	nStackEntriesForBytes(typeSizeBytes(program, a));

private size_t nStackEntriesForBytes(size_t bytes) =>
	divRoundUp(bytes, stackEntrySize);

immutable struct Pack {
	size_t inEntries;
	size_t outEntries;
	PackField[] fields;
}

immutable struct PackField {
	size_t inOffset;
	size_t outOffset;
	size_t size;
}

Opt!Pack optPack(TempAlloc)(ref TempAlloc tempAlloc, in LowProgram program, LowType.Record type) {
	LowRecord record = program.allRecords[type];
	if (every!LowField(record.fields, (in LowField field) => isMultipleOf(field.offset, 8)))
		return none!Pack;
	else {
		size_t inOffsetEntries = 0;
		PackField[] fields = map(tempAlloc, record.fields, (ref LowField field) {
			size_t fieldInOffsetBytes = inOffsetEntries * 8;
			size_t fieldSizeBytes = typeSizeBytes(program, field.type);
			inOffsetEntries += nStackEntriesForBytes(fieldSizeBytes);
			return PackField(fieldInOffsetBytes, field.offset, fieldSizeBytes);
		});
		size_t outEntries = nStackEntriesForType(program, LowType(type));
		return some(Pack(inOffsetEntries, outEntries, fields));
	}
}

private:

TypeSize ptrSize() =>
	TypeSize(8, 8);
TypeSize funPtrSize() =>
	ptrSize;

TypeSize primitiveSize(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.void_:
			return TypeSize(0, 1);
		case PrimitiveType.bool_:
		case PrimitiveType.char8:
		case PrimitiveType.int8:
		case PrimitiveType.nat8:
			return TypeSize(1, 1);
		case PrimitiveType.int16:
		case PrimitiveType.nat16:
			return TypeSize(2, 2);
		case PrimitiveType.char32:
		case PrimitiveType.float32:
		case PrimitiveType.int32:
		case PrimitiveType.nat32:
			return TypeSize(4, 4);
		case PrimitiveType.float64:
		case PrimitiveType.int64:
		case PrimitiveType.nat64:
			return TypeSize(8, 8);
	}
}
