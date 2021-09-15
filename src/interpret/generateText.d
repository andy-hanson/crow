module interpret.generateText;

@safe @nogc pure nothrow:

import interpret.bytecode : Operation;
import model.constant : Constant, matchConstant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPrimitive,
	asPtrGc,
	asRecordType,
	asUnionType,
	LowField,
	LowProgram,
	LowRecord,
	LowType,
	lowTypeEqual,
	PointerTypeAndConstantsLow,
	PrimitiveType;
import model.typeLayout : optPack, sizeOfType;
import util.collection.arr : at, castImmutable, empty, ptrAt, setAt, size;
import util.collection.arrUtil : mapToMut, sum, zip;
import util.collection.exactSizeArrBuilder :
	exactSizeArrBuilderAdd,
	add0Bytes,
	add16,
	add32,
	add64,
	add64TextPtr,
	ExactSizeArrBuilder,
	exactSizeArrBuilderCurSize,
	finish,
	newExactSizeArrBuilder;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : has, Opt;
import util.ptr : Ptr, ptrTrustMe;
import util.types : bottomU8OfU64, bottomU16OfU64, bottomU32OfU64, Nat16, u32OfFloat32Bits, u64OfFloat64Bits;
import util.util : todo, unreachable, verify;

struct TextAndInfo {
	immutable ubyte[] text;
	immutable size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	immutable size_t[][] pointeeTypeIndexToIndexToTextIndex;
}

struct TextArrInfo {
	immutable size_t size;
	immutable ubyte* textPtr;
}

immutable(TextArrInfo) getTextInfoForArray(
	ref immutable TextAndInfo info,
	ref immutable AllConstantsLow allConstants,
	immutable Constant.ArrConstant a,
) {
	immutable size_t constantSize = size(at(at(allConstants.arrs, a.typeIndex).constants, a.index));
	immutable size_t textIndex = at(at(info.arrTypeIndexToConstantIndexToTextIndex, a.typeIndex), a.index);
	return immutable TextArrInfo(constantSize, ptrAt(info.text, textIndex).rawPtr());
}

immutable(ubyte*) getTextPointer(ref immutable TextAndInfo info, immutable Constant.Pointer a) {
	immutable size_t textIndex = at(at(info.pointeeTypeIndexToIndexToTextIndex, a.typeIndex), a.index);
	return ptrAt(info.text, textIndex).rawPtr();
}

immutable(TextAndInfo) generateText(Alloc, TempAlloc)(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref immutable LowProgram program,
	ref immutable AllConstantsLow allConstants,
) {
	Ctx ctx = Ctx(
		ptrTrustMe(program),
		ptrTrustMe(allConstants),
		// '1 +' because we add a dummy byte at 0
		newExactSizeArrBuilder!ubyte(alloc, 1 + getAllConstantsSize(program, allConstants)),
		mapToMut!(size_t[], ArrTypeAndConstantsLow, Alloc)(
			alloc,
			allConstants.arrs,
			(ref immutable ArrTypeAndConstantsLow it) =>
				mapToMut(alloc, it.constants, (ref immutable Constant[]) => size_t(0))),
	 	mapToMut!(size_t[])(
			alloc,
			allConstants.pointers,
			(ref immutable PointerTypeAndConstantsLow it) =>
				mapToMut!size_t(alloc, it.constants, (ref immutable Ptr!Constant) => size_t(0))));

	// Ensure 0 is not a valid text index
	exactSizeArrBuilderAdd(ctx.text, 0);

	foreach (immutable size_t arrTypeIndex; 0 .. size(allConstants.arrs)) {
		immutable Ptr!ArrTypeAndConstantsLow typeAndConstants = ptrAt(allConstants.arrs, arrTypeIndex);
		foreach (immutable size_t constantIndex; 0 .. size(typeAndConstants.constants))
			recurWriteArr(
				tempAlloc,
				ctx,
				arrTypeIndex,
				typeAndConstants.elementType,
				constantIndex,
				at(typeAndConstants.constants, constantIndex));
	}
	foreach (immutable size_t pointeeTypeIndex; 0 .. size(allConstants.pointers)) {
		immutable Ptr!PointerTypeAndConstantsLow typeAndConstants = ptrAt(allConstants.pointers, pointeeTypeIndex);
		foreach (immutable size_t constantIndex; 0 .. size(typeAndConstants.constants))
			recurWritePointer(
				tempAlloc,
				ctx,
				pointeeTypeIndex,
				typeAndConstants.pointeeType,
				constantIndex,
				at(typeAndConstants.constants, constantIndex));
	}

	return immutable TextAndInfo(
		castImmutable(finish(ctx.text)),
		castImmutable(ctx.arrTypeIndexToConstantIndexToTextIndex),
		castImmutable(ctx.pointeeTypeIndexToIndexToTextIndex));
}

private:

struct Ctx {
	immutable Ptr!LowProgram program;
	immutable Ptr!AllConstantsLow allConstants;
	ExactSizeArrBuilder!ubyte text;
	size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	size_t[][] pointeeTypeIndexToIndexToTextIndex;
}

// Write out any constants that this points to.
void ensureConstant(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	ref immutable LowType t,
	ref immutable Constant c,
) {
	matchConstant!void(
		c,
		(ref immutable Constant.ArrConstant it) {
			immutable Ptr!ArrTypeAndConstantsLow arrs = ptrAt(ctx.allConstants.arrs, it.typeIndex);
			verify(arrs.arrType == asRecordType(t));
			recurWriteArr(tempAlloc, ctx, it.typeIndex, arrs.elementType, it.index, at(arrs.constants, it.index));
		},
		(immutable Constant.BoolConstant) {},
		(immutable double) {},
		(immutable Constant.Integral) {},
		(immutable Constant.Null) {},
		(immutable Constant.Pointer it) {
			immutable Ptr!PointerTypeAndConstantsLow ptrs = ptrAt(ctx.allConstants.pointers, it.typeIndex);
			verify(lowTypeEqual(ptrs.pointeeType, asPtrGc(t).pointee));
			recurWritePointer(tempAlloc, ctx, it.typeIndex, ptrs.pointeeType, it.index, at(ptrs.constants, it.index));
		},
		(ref immutable Constant.Record it) {
			immutable LowRecord record = fullIndexDictGet(ctx.program.allRecords, asRecordType(t));
			zip!(LowField, Constant)(
				record.fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant arg) {
					ensureConstant(tempAlloc, ctx, field.type, arg);
				});
		},
		(ref immutable Constant.Union it) {
			ensureConstant(tempAlloc, ctx, unionMemberType(ctx.program, asUnionType(t), it.memberIndex), it.arg);
		},
		(immutable Constant.Void) {});
}

ref immutable(LowType) unionMemberType(
	ref immutable LowProgram program,
	immutable LowType.Union t,
	immutable ubyte memberIndex,
) {
	return at(fullIndexDictGet(program.allUnions, t).members, memberIndex);
}

void recurWriteArr(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	immutable size_t arrTypeIndex,
	immutable LowType elementType,
	immutable size_t index, // constant index within the same type
	immutable Constant[] elements,
) {
	verify(!empty(elements));
	size_t[] indexToTextIndex = at(ctx.arrTypeIndexToConstantIndexToTextIndex, arrTypeIndex);
	if (at(indexToTextIndex, index) == 0) {
		foreach (ref immutable Constant it; elements)
			ensureConstant(tempAlloc, ctx, elementType, it);
		setAt(indexToTextIndex, index, exactSizeArrBuilderCurSize(ctx.text));
		foreach (ref immutable Constant it; elements)
			writeConstant(tempAlloc, ctx, elementType, it);
	}
}

void recurWritePointer(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	immutable size_t pointeeTypeIndex,
	immutable LowType pointeeType,
	immutable size_t index,
	immutable Ptr!Constant pointee,
) {
	size_t[] indexToTextIndex = at(ctx.pointeeTypeIndexToIndexToTextIndex, pointeeTypeIndex);
	if (at(indexToTextIndex, index) == 0) {
		ensureConstant(tempAlloc, ctx, pointeeType, pointee);
		setAt(indexToTextIndex, index, exactSizeArrBuilderCurSize(ctx.text));
		writeConstant(tempAlloc, ctx, pointeeType, pointee);
	}
}

immutable(size_t) getAllConstantsSize(ref immutable LowProgram program, ref immutable AllConstantsLow allConstants) {
	immutable size_t arrsSize = sum(allConstants.arrs, (ref immutable ArrTypeAndConstantsLow arrs) =>
		sizeOfType(program, arrs.elementType).size.raw() *
		sum(arrs.constants, (ref immutable Constant[] elements) => size(elements)));
	immutable size_t pointersSize = sum(allConstants.pointers, (ref immutable PointerTypeAndConstantsLow pointers) =>
		sizeOfType(program, pointers.pointeeType).size.raw() * size(pointers.constants));
	return arrsSize + pointersSize;
}

void writeConstant(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	ref immutable LowType type,
	ref immutable Constant constant,
) {
	matchConstant!void(
		constant,
		(ref immutable Constant.ArrConstant it) {
			//TODO:DUP CODE (see getTextInfoForArray)
			immutable size_t constantSize = size(at(at(ctx.allConstants.arrs, it.typeIndex).constants, it.index));
			add64(ctx.text, constantSize);
			immutable size_t textIndex = at(at(ctx.arrTypeIndexToConstantIndexToTextIndex, it.typeIndex), it.index);
			add64TextPtr(ctx.text, textIndex);
		},
		(immutable Constant.BoolConstant it) {
			exactSizeArrBuilderAdd(ctx.text, it.value ? 1 : 0);
		},
		(immutable double it) {
			switch (asPrimitive(type)) {
				case PrimitiveType.float32:
					add32(ctx.text, u32OfFloat32Bits(it).raw());
					break;
				case PrimitiveType.float64:
					add64(ctx.text, u64OfFloat64Bits(it).raw());
					break;
				default:
					unreachable!void();
					break;
			}
		},
		(immutable Constant.Integral it) {
			final switch (asPrimitive(type)) {
				case PrimitiveType.bool_:
				case PrimitiveType.float32:
				case PrimitiveType.float64:
				case PrimitiveType.void_:
					unreachable!void();
					break;
				case PrimitiveType.char_:
				case PrimitiveType.int8:
				case PrimitiveType.nat8:
					exactSizeArrBuilderAdd(ctx.text, bottomU8OfU64(it.value));
					break;
				case PrimitiveType.int16:
				case PrimitiveType.nat16:
					add16(ctx.text, bottomU16OfU64(it.value));
					break;
				case PrimitiveType.int32:
				case PrimitiveType.nat32:
					add32(ctx.text, bottomU32OfU64(it.value));
					break;
				case PrimitiveType.int64:
				case PrimitiveType.nat64:
					add64(ctx.text, it.value);
					break;
			}
		},
		(immutable Constant.Null) {
			todo!void("write null");
		},
		(immutable Constant.Pointer it) {
			// We should know where we wrote the pointee to
			immutable size_t textIndex = at(at(ctx.pointeeTypeIndexToIndexToTextIndex, it.typeIndex), it.index);
			add64TextPtr(ctx.text, textIndex);
		},
		(ref immutable Constant.Record it) {
			immutable LowType.Record recordType = asRecordType(type);
			immutable LowRecord record = fullIndexDictGet(ctx.program.allRecords, recordType);
			zip!(LowField, Constant)(
				record.fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant fieldValue) {
					writeConstant(tempAlloc, ctx, field.type, fieldValue);
				});
			immutable Opt!(Operation.Pack) pack = optPack(tempAlloc, ctx.program, recordType);
			if (has(pack))
				//TODO: we should be writing each constant at the appropriate offset, so no need to pack.
				todo!void("pack it");
		},
		(ref immutable Constant.Union it) {
			add64(ctx.text, it.memberIndex);
			immutable LowType memberType = unionMemberType(ctx.program, asUnionType(type), it.memberIndex);
			writeConstant(tempAlloc, ctx, memberType, it.arg);
			immutable Nat16 unionSize = sizeOfType(ctx.program, type).size;
			immutable Nat16 memberSize = sizeOfType(ctx.program, memberType).size;
			immutable Nat16 padding = unionSize - immutable Nat16(8) - memberSize;
			add0Bytes(ctx.text, padding.raw());
		},
		(immutable Constant.Void) {
			todo!void("write void"); // should only happen if there's a pointer to void..
		});
}
