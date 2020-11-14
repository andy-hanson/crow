module interpret.typeLayout;

@safe @nogc pure nothrow:

import interpret.bytecode : stackEntrySize;
import model.lowModel : LowField, LowProgram, LowRecord, LowType, LowUnion, matchLowType, PrimitiveType;
import util.collection.arr : Arr, at, empty, size;
import util.collection.arrUtil : arrMax, map, mapOp, slice;
import util.collection.fullIndexDict : FullIndexDict, fullIndexDictEach, fullIndexDictGet, fullIndexDictSize;
import util.collection.fullIndexDictBuilder :
	finishFullIndexDict,
	FullIndexDictBuilder,
	fullIndexDictBuilderAdd,
	fullIndexDictBuilderHas,
	fullIndexDictBuilderOptGet,
	newFullIndexDictBuilder;
import util.opt : force, has, none, Opt, some;
import util.types : Nat8, zero;
import util.util : divRoundUp, roundUp, verify;

// NOTE: we should lay out structs so that no primitive field straddles multiple stack entries.
struct TypeLayout {
	// All in bytes
	immutable FullIndexDict!(LowType.Record, Nat8) recordSizes;
	immutable FullIndexDict!(LowType.Record, Arr!Nat8) fieldOffsets;
	immutable FullIndexDict!(LowType.Union, Nat8) unionSizes;
}

immutable(Nat8) sizeOfType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
	return matchLowType!(immutable Nat8)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable LowType.NonFunPtr) =>
			ptrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowType.Record index) =>
			fullIndexDictGet(typeLayout.recordSizes, index),
		(immutable LowType.Union index) =>
			fullIndexDictGet(typeLayout.unionSizes, index));
}

immutable(Nat8) nStackEntriesForType(ref immutable TypeLayout typeLayout, ref immutable LowType t) {
	return divRoundUp(sizeOfType(typeLayout, t), stackEntrySize);
}

immutable(TypeLayout) layOutTypes(Alloc)(ref Alloc alloc, ref immutable LowProgram program) {
	TypeLayoutBuilder builder = TypeLayoutBuilder(
		newFullIndexDictBuilder!(LowType.Record, Nat8)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Record, Arr!Nat8)(alloc, fullIndexDictSize(program.allRecords)),
		newFullIndexDictBuilder!(LowType.Union, Nat8)(alloc, fullIndexDictSize(program.allUnions)));
	fullIndexDictEach(program.allRecords, (immutable LowType.Record index, ref immutable LowRecord record) {
		if (!fullIndexDictBuilderHas(builder.recordSizes, index))
			fillRecordSize!Alloc(alloc, program, index, record, builder);
	});
	fullIndexDictEach(program.allUnions, (immutable LowType.Union index, ref immutable LowUnion union_) {
		if (!fullIndexDictBuilderHas(builder.unionSizes, index))
			fillUnionSize!Alloc(alloc, program, index, union_, builder);
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
	scope void delegate(ref immutable Arr!Nat8) @safe @nogc pure nothrow cbPack,
	scope void delegate(immutable size_t, ref immutable LowType, immutable Nat8) @safe @nogc pure nothrow cbSingleField,
) {
	immutable LowRecord record = fullIndexDictGet(program.allRecords, type);

	void maybePack(immutable Opt!size_t packStart, immutable size_t packEnd) {
		if (has(packStart)) {
			// TODO: could just write these to a MaxArr!Nat8 when making in the first place
			// (instead of Opt!size_t packStart, have MaxArr!(size_t, 3))
			immutable Arr!Nat8 fieldSizes = mapOp(
				tempAlloc,
				slice(record.fields, force(packStart), packEnd - force(packStart)),
				(ref immutable LowField field) {
					immutable Nat8 size = sizeOfType(typeLayout, field.type);
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
			immutable Nat8 fieldSize = sizeOfType(typeLayout, fieldType);
			immutable Opt!size_t nextPackStart = () {
				if (fieldSize < immutable Nat8(8)) {
					return has(packStart) ? packStart : some(fieldIndex);
				} else {
					verify(fieldSize % immutable Nat8(8) == immutable Nat8(0));
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
	FullIndexDictBuilder!(LowType.Record, Nat8) recordSizes;
	FullIndexDictBuilder!(LowType.Record, Arr!Nat8) recordFieldOffsets;
	FullIndexDictBuilder!(LowType.Union, Nat8) unionSizes;
}

immutable Nat8 fieldBoundary = immutable Nat8(8);

immutable(Nat8) fillRecordSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Record index,
	ref immutable LowRecord record,
	ref TypeLayoutBuilder builder,
) {
	//debug {
	//	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	//	immutable LowType t = immutable LowType(index);
	//	writeStatic(writer, "fillRecordSize ");
	//	writeType(writer, program, t);
	//	writeStatic(writer, ": ");
	//}

	Nat8 offset = immutable Nat8(0);
	immutable Arr!Nat8 fieldOffsets = map(alloc, record.fields, (ref immutable LowField field) {
		immutable Nat8 fieldSize = sizeOfType(alloc, program, field.type, builder);
		// If field would stretch across a boundary, move offset up to the next boundary
		immutable Nat8 mod = offset % fieldBoundary;
		if (!zero(mod) && mod + fieldSize > fieldBoundary) {
			offset = roundUp(offset, fieldBoundary);
		}
		immutable Nat8 res = offset;
		offset += fieldSize;
		//debug {
		//	writeStatic(writer, ", ");
		//	writeFieldName(writer, field);
		//	writeStatic(writer, ": ");
		//	writeNat(writer, res.raw());
		//}
		return res;
	});
	immutable Nat8 size = offset <= immutable Nat8(8) ? offset : roundUp(offset, immutable Nat8(8));
	fullIndexDictBuilderAdd(builder.recordSizes, index, size);
	fullIndexDictBuilderAdd(builder.recordFieldOffsets, index, fieldOffsets);

	//debug {
	//	writeStatic(writer, ", full size: ");
	//	writeNat(writer, size.raw());
	//	import core.stdc.stdio : printf;
	//	printf("%s\n", finishWriterToCStr(writer));
	//}
	return size;
}

immutable(Nat8) fillUnionSize(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	immutable LowType.Union index,
	ref immutable LowUnion union_,
	ref TypeLayoutBuilder builder,
) {
	immutable Nat8 maxMemberSize = arrMax(immutable Nat8(0), union_.members, (ref immutable LowType t) =>
		sizeOfType(alloc, program, t, builder));
	immutable Nat8 size = unionKindSize + roundUp(maxMemberSize, unionKindSize);
	fullIndexDictBuilderAdd(builder.unionSizes, index, size);
	return size;
}

immutable Nat8 externPtrSize = immutable Nat8((void*).sizeof);
immutable Nat8 ptrSize = immutable Nat8((void*).sizeof);
immutable Nat8 funPtrSize = immutable Nat8(4);
immutable Nat8 unionKindSize = immutable Nat8(8);

immutable(Nat8) sizeOfType(Alloc)(
	ref Alloc alloc,
	ref immutable LowProgram program,
	ref immutable LowType t,
	ref TypeLayoutBuilder builder,
) {
	return matchLowType!(immutable Nat8)(
		t,
		(immutable LowType.ExternPtr) =>
			externPtrSize,
		(immutable LowType.FunPtr) =>
			funPtrSize,
		(immutable LowType.NonFunPtr) =>
			ptrSize,
		(immutable PrimitiveType it) =>
			primitiveSize(it),
		(immutable LowType.Record index) {
			immutable Opt!Nat8 size = fullIndexDictBuilderOptGet(builder.recordSizes, index);
			return has(size)
				? force(size)
				: fillRecordSize(alloc, program, index, fullIndexDictGet(program.allRecords, index), builder);
		},
		(immutable LowType.Union index) {
			immutable Opt!Nat8 size = fullIndexDictBuilderOptGet(builder.unionSizes, index);
			return has(size)
				? force(size)
				: fillUnionSize(alloc, program, index, fullIndexDictGet(program.allUnions, index), builder);
		});
}

immutable(Nat8) primitiveSize(immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.void_:
			return immutable Nat8(0);
		case PrimitiveType.bool_:
		case PrimitiveType.char_:
		case PrimitiveType.int8:
		case PrimitiveType.nat8:
			return immutable Nat8(1);
		case PrimitiveType.int16:
		case PrimitiveType.nat16:
			return immutable Nat8(2);
		case PrimitiveType.int32:
		case PrimitiveType.nat32:
			return immutable Nat8(4);
		case PrimitiveType.float64:
		case PrimitiveType.int64:
		case PrimitiveType.nat64:
			return immutable Nat8(8);
	}
}
