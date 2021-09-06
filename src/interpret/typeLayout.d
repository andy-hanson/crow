module interpret.typeLayout;

@safe @nogc pure nothrow:

import interpret.bytecode : stackEntrySize;
import model.lowModel : LowField, LowProgram, LowRecord, LowType, LowUnion, matchLowType, PrimitiveType;
import util.collection.arr : at, empty, size;
import util.collection.arrUtil : arrMax, map, mapOp;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictEach, fullIndexDictGet, fullIndexDictSize;
import util.collection.fullIndexDictBuilder :
	finishFullIndexDict,
	FullIndexDictBuilder,
	fullIndexDictBuilderAdd,
	fullIndexDictBuilderHas,
	fullIndexDictBuilderOptGet,
	newFullIndexDictBuilder;
import util.opt : force, has, none, Opt, some;
import util.types : Nat8, Nat16, zero;
import util.util : divRoundUp, drop, max, roundUp, verify;

// NOTE: we should lay out structs so that no primitive field straddles multiple stack entries.
struct TypeLayout {
	// All in bytes
	immutable FullIndexDict!(LowType.Record, TypeSize) recordSizes;
	immutable FullIndexDict!(LowType.Record, Nat16[]) fieldOffsets;
	immutable FullIndexDict!(LowType.Union, TypeSize) unionSizes;
}

struct TypeSize {
	immutable Nat16 size;
	immutable Nat8 alignment;
}

immutable(TypeSize) sizeOfType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
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
			fullIndexDictGet(typeLayout.recordSizes, index),
		(immutable LowType.Union index) =>
			fullIndexDictGet(typeLayout.unionSizes, index));
}

immutable(Nat8) nStackEntriesForType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
	return divRoundUp(sizeOfType(typeLayout, t).size, stackEntrySize).to8();
}

immutable(TypeLayout) layOutTypes(Alloc)(ref Alloc alloc, ref immutable LowProgram program) {
	TypeLayoutBuilder builder = TypeLayoutBuilder(
		newFullIndexDictBuilder!(LowType.Record, TypeSize)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Record, Nat16[])(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Union, TypeSize)(alloc, fullIndexDictSize(program.allUnions)));
	fullIndexDictEach!(LowType.Record, LowRecord)(
		program.allRecords,
		(immutable LowType.Record index, ref immutable LowRecord record) {
			if (!fullIndexDictBuilderHas(builder.recordSizes, index))
				drop(fillRecordSize!Alloc(alloc, program, index, record, builder));
		});
	fullIndexDictEach!(LowType.Union, LowUnion)(
		program.allUnions,
		(immutable LowType.Union index, ref immutable LowUnion union_) {
			if (!fullIndexDictBuilderHas(builder.unionSizes, index))
				drop(fillUnionSize!Alloc(alloc, program, index, union_, builder));
		});
	return immutable TypeLayout(
		finishFullIndexDict(builder.recordSizes),
		finishFullIndexDict(builder.recordFieldOffsets),
		finishFullIndexDict(builder.unionSizes));
}

// 'cbSingleField' is called for every field.
// While doing so, 'cbPack' is called after a group of fields that should be packed together.
void walkRecordFields(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
	ref immutable TypeLayout typeLayout,
	immutable LowType.Record type,
	scope void delegate(ref immutable Nat8[]) @safe @nogc pure nothrow cbPack,
	scope void delegate(
		immutable size_t,
		ref immutable LowType,
		immutable Nat16,
	) @safe @nogc pure nothrow cbSingleField,
) {
	immutable LowRecord record = fullIndexDictGet(program.allRecords, type);

	void maybePack(immutable Opt!size_t packStart, immutable size_t packEnd) {
		if (has(packStart)) {
			// TODO: could just write these to a MaxNat16[] when making in the first place
			// (instead of Opt!size_t packStart, have MaxArr!(size_t, 3))
			immutable Nat8[] fieldSizes = mapOp!Nat8(
				tempAlloc,
				record.fields[force(packStart) .. packEnd],
				(ref immutable LowField field) {
					immutable Nat8 size = sizeOfType(typeLayout, field.type).size.to8();
					return zero(size) ? none!Nat8 : some(size);
				});
			if (!empty(fieldSizes))
				cbPack(fieldSizes);
		}
	}

	void recur(immutable Opt!size_t packStart, immutable size_t fieldIndex) {
		if (fieldIndex == size(record.fields)) {
			maybePack(packStart, fieldIndex);
		} else {
			//TODO: use field offsets instead of getting size?
			immutable LowType fieldType = at(record.fields, fieldIndex).type;
			immutable Nat16 fieldSize = sizeOfType(typeLayout, fieldType).size;
			immutable Opt!size_t nextPackStart = () {
				if (fieldSize < immutable Nat16(8)) {
					return has(packStart) ? packStart : some(fieldIndex);
				} else {
					verify(fieldSize % immutable Nat16(8) == immutable Nat16(0));
					maybePack(packStart, fieldIndex);
					return none!size_t;
				}
			}();
			cbSingleField(fieldIndex, fieldType, fieldSize);
			recur(nextPackStart, fieldIndex + 1);
		}
	}

	recur(none!size_t, 0);
}

private:

struct TypeLayoutBuilder {
	FullIndexDictBuilder!(LowType.Record, TypeSize) recordSizes;
	FullIndexDictBuilder!(LowType.Record, Nat16[]) recordFieldOffsets;
	FullIndexDictBuilder!(LowType.Union, TypeSize) unionSizes;
}

immutable Nat16 fieldBoundary = immutable Nat16(8);

immutable(TypeSize) fillRecordSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Record index,
	ref immutable LowRecord record,
	ref TypeLayoutBuilder builder,
) {
	Nat16 maxFieldSize = immutable Nat16(1);
	Nat8 maxFieldAlignment = immutable Nat8(1);
	Nat16 offset = immutable Nat16(0);
	immutable Nat16[] fieldOffsets = map(alloc, record.fields, (ref immutable LowField field) {
		immutable TypeSize fieldSize = sizeOfType(alloc, program, field.type, builder);
		maxFieldSize = max(maxFieldSize, fieldSize.size);
		maxFieldAlignment = max(maxFieldAlignment, fieldSize.alignment);
		// If field would stretch across a boundary, move offset up to the next boundary
		immutable Nat16 mod = offset % fieldBoundary;
		if (!record.packed && !zero(mod) && mod + fieldSize.size > fieldBoundary)
			offset = roundUp(offset, fieldBoundary);
		immutable Nat16 res = offset;
		offset += fieldSize.size;
		return res;
	});
	immutable Nat16 size = offset <= immutable Nat16(8) || record.packed
		? offset
		: roundUp(offset, maxFieldAlignment.to16());
	immutable TypeSize typeSize = immutable TypeSize(size, maxFieldAlignment);
	fullIndexDictBuilderAdd(builder.recordSizes, index, typeSize);
	fullIndexDictBuilderAdd(builder.recordFieldOffsets, index, fieldOffsets);
	return typeSize;
}

immutable(TypeSize) fillUnionSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Union index,
	ref immutable LowUnion union_,
	ref TypeLayoutBuilder builder,
) {
	immutable Nat16 maxMemberSize = arrMax(immutable Nat16(0), union_.members, (ref immutable LowType t) =>
		sizeOfType(alloc, program, t, builder).size);
	immutable TypeSize size = immutable TypeSize(
		unionKindSize.size + roundUp(maxMemberSize, unionKindSize.size),
		// Since the union kind is 8 bytes, that's the alignment
		immutable Nat8(8));
	fullIndexDictBuilderAdd(builder.unionSizes, index, size);
	return size;
}

immutable TypeSize ptrSize = immutable TypeSize(immutable Nat16(8), immutable Nat8(8));
immutable TypeSize externPtrSize = ptrSize;
immutable TypeSize funPtrSize = ptrSize;
// TODO: could be smaller...
immutable TypeSize unionKindSize = ptrSize;

immutable(TypeSize) sizeOfType(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	ref immutable LowType t,
	ref TypeLayoutBuilder builder,
) {
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
		(immutable LowType.Record index) {
			immutable Opt!TypeSize size = fullIndexDictBuilderOptGet(builder.recordSizes, index);
			return has(size)
				? force(size)
				: fillRecordSize(alloc, program, index, fullIndexDictGet(program.allRecords, index), builder);
		},
		(immutable LowType.Union index) {
			immutable Opt!TypeSize size = fullIndexDictBuilderOptGet(builder.unionSizes, index);
			return has(size)
				? force(size)
				: fillUnionSize(alloc, program, index, fullIndexDictGet(program.allUnions, index), builder);
		});
}

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
