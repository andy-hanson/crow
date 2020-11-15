module interpret.generateText;

@safe @nogc pure nothrow:

import interpret.typeLayout : sizeOfType, TypeLayout, walkRecordFields;
import model.constant : Constant, matchConstant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asNonFunPtrType,
	asPrimitive,
	asRecordType,
	LowField,
	LowProgram,
	LowRecord,
	LowType,
	lowTypeEqual,
	PointerTypeAndConstantsLow,
	PrimitiveType;
import util.collection.arr : Arr, arrOfRange, at, castImmutable, empty, ptrAt, range, setAt, size;
import util.collection.arrUtil : mapToMut, sum, zip;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.ptr : Ptr, ptrTrustMe;
import util.types : bottomU8OfU64, bottomU16OfU64, bottomU32OfU64, Nat8, u8, u16, u32, u64, zero;
import util.util : todo, unreachable, verify;

struct TextAndInfo {
	immutable Arr!ubyte text;
	immutable Arr!(Arr!size_t) arrTypeIndexToConstantIndexToTextIndex;
	immutable Arr!(Arr!size_t) pointeeTypeIndexToIndexToTextIndex;
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
	ref immutable TypeLayout typeLayout,
	ref immutable AllConstantsLow allConstants,
) {
	Ctx ctx = Ctx(
		ptrTrustMe(program),
		ptrTrustMe(allConstants),
		ptrTrustMe(typeLayout),
		// '1 +' because we add a dummy byte at 0
		newExactSizeArrBuilder!ubyte(alloc, 1 + getAllConstantsSize(typeLayout, allConstants)),
		mapToMut!(Arr!size_t, ArrTypeAndConstantsLow, Alloc)(
			alloc,
			allConstants.arrs,
			(ref immutable ArrTypeAndConstantsLow it) =>
				mapToMut(alloc, it.constants, (ref immutable Arr!Constant) => size_t(0))),
	 	mapToMut!(Arr!size_t)(
			alloc,
			allConstants.pointers,
			(ref immutable PointerTypeAndConstantsLow it) =>
				mapToMut!size_t(alloc, it.constants, (ref immutable Ptr!Constant) => size_t(0))));

	// Ensure 0 is not a valid text index
	add(ctx.text, 0);

	foreach (immutable size_t arrTypeIndex; 0..size(allConstants.arrs)) {
		immutable Ptr!ArrTypeAndConstantsLow typeAndConstants = ptrAt(allConstants.arrs, arrTypeIndex);
		foreach (immutable size_t constantIndex; 0..size(typeAndConstants.constants))
			recurWriteArr(
				tempAlloc,
				ctx,
				arrTypeIndex,
				typeAndConstants.elementType,
				constantIndex,
				at(typeAndConstants.constants, constantIndex));
	}
	foreach (immutable size_t pointeeTypeIndex; 0..size(allConstants.pointers)) {
		immutable Ptr!PointerTypeAndConstantsLow typeAndConstants = ptrAt(allConstants.pointers, pointeeTypeIndex);
		foreach (immutable size_t constantIndex; 0..size(typeAndConstants.constants))
			recurWritePointer(
				tempAlloc,
				ctx,
				pointeeTypeIndex,
				typeAndConstants.pointeeType,
				constantIndex,
				at(typeAndConstants.constants, constantIndex));
	}

	return immutable TextAndInfo(
		finish(ctx.text),
		castImmutable(ctx.arrTypeIndexToConstantIndexToTextIndex),
		castImmutable(ctx.pointeeTypeIndexToIndexToTextIndex));
}

private:

struct Ctx {
	immutable Ptr!LowProgram program;
	immutable Ptr!AllConstantsLow allConstants;
	immutable Ptr!TypeLayout typeLayout;
	ExactSizeArrBuilder!ubyte text;
	Arr!(Arr!size_t) arrTypeIndexToConstantIndexToTextIndex;
	Arr!(Arr!size_t) pointeeTypeIndexToIndexToTextIndex;
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
		(immutable Constant.Integral) {},
		(immutable Constant.Null) {},
		(immutable Constant.Pointer it) {
			immutable Ptr!PointerTypeAndConstantsLow ptrs = ptrAt(ctx.allConstants.pointers, it.typeIndex);
			verify(lowTypeEqual(ptrs.pointeeType, asNonFunPtrType(t).pointee));
			recurWritePointer(tempAlloc, ctx, it.typeIndex, ptrs.pointeeType, it.index, at(ptrs.constants, it.index));
		},
		(ref immutable Constant.Record it) {
			immutable LowRecord record = fullIndexDictGet(ctx.program.allRecords, asRecordType(t));
			zip(record.fields, it.args, (ref immutable LowField field, ref immutable Constant arg) {
				ensureConstant(tempAlloc, ctx, field.type, arg);
			});
		},
		(ref immutable Constant.Union) {
			todo!void("!");
		},
		(immutable Constant.Void) {});
}

void recurWriteArr(TempAlloc)(
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	immutable size_t arrTypeIndex,
	immutable LowType elementType,
	immutable size_t index, // constant index within the same type
	immutable Arr!Constant elements,
) {
	verify(!empty(elements));
	Arr!size_t indexToTextIndex = at(ctx.arrTypeIndexToConstantIndexToTextIndex, arrTypeIndex);
	if (at(indexToTextIndex, index) == 0) {
		foreach (ref immutable Constant it; range(elements))
			ensureConstant(tempAlloc, ctx, elementType, it);
		setAt(indexToTextIndex, index, exactSizeArrBuilderCurSize(ctx.text));
		foreach (ref immutable Constant it; range(elements))
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
	Arr!size_t indexToTextIndex = at(ctx.pointeeTypeIndexToIndexToTextIndex, pointeeTypeIndex);
	if (at(indexToTextIndex, index) == 0) {
		ensureConstant(tempAlloc, ctx, pointeeType, pointee);
		setAt(indexToTextIndex, index, exactSizeArrBuilderCurSize(ctx.text));
		writeConstant(tempAlloc, ctx, pointeeType, pointee);
	}
}

immutable(size_t) getAllConstantsSize(ref immutable TypeLayout typeLayout, ref immutable AllConstantsLow allConstants) {
	immutable size_t arrsSize = sum(allConstants.arrs, (ref immutable ArrTypeAndConstantsLow arrs) =>
		sizeOfType(typeLayout, arrs.elementType).raw() *
		sum(arrs.constants, (ref immutable Arr!Constant elements) => size(elements)));
	immutable size_t pointersSize = sum(allConstants.pointers, (ref immutable PointerTypeAndConstantsLow pointers) =>
		sizeOfType(typeLayout, pointers.pointeeType).raw() * size(pointers.constants));
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
			add(ctx.text, it.value ? 1 : 0);
		},
		(immutable Constant.Integral it) {
			final switch (asPrimitive(type)) {
				case PrimitiveType.bool_:
				case PrimitiveType.float64:
				case PrimitiveType.void_:
					unreachable!void();
					break;
				case PrimitiveType.char_:
				case PrimitiveType.int8:
				case PrimitiveType.nat8:
					add(ctx.text, bottomU8OfU64(it.value));
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
			todo!void("!");
		},
		(immutable Constant.Pointer it) {
			// We should know where we wrote the pointee to
			immutable size_t textIndex = at(at(ctx.pointeeTypeIndexToIndexToTextIndex, it.typeIndex), it.index);
			add64TextPtr(ctx.text, textIndex);
		},
		(ref immutable Constant.Record it) {
			walkRecordFields(
				tempAlloc,
				ctx.program,
				ctx.typeLayout,
				asRecordType(type),
				(ref immutable Arr!Nat8) {
					todo!void("pack it");
				},
				(immutable size_t fieldIndex, ref immutable LowType fieldType, immutable Nat8 fieldSize) {
					verify(zero(fieldSize % immutable Nat8(8))); // TODO: 'size' type so don't need this assertion
					writeConstant(tempAlloc, ctx, fieldType, at(it.args, fieldIndex));
				});
		},
		(ref immutable Constant.Union) {
			todo!void("!");
		},
		(immutable Constant.Void) {
			todo!void("!"); // should only happen if there's a pointer to void..
		});
}

//TODO:MOVE
struct ExactSizeArrBuilder(T) {
	private:
	const(T)* begin;
	T* cur;
	const(T)* end;
}

immutable(size_t) exactSizeArrBuilderCurSize(T)(ref const ExactSizeArrBuilder!T a) {
	return a.cur - a.begin;
}

@trusted ExactSizeArrBuilder!T newExactSizeArrBuilder(T, Alloc)(ref Alloc alloc, immutable size_t size) {
	T* begin = cast(T*) alloc.allocate(T.sizeof * size);
	return ExactSizeArrBuilder!T(begin, begin, begin + size);
}

@trusted void add(T)(ref ExactSizeArrBuilder!T a, immutable T value) {
	verify(a.cur < a.end);
	*a.cur = value;
	a.cur++;
}

@trusted void add16(ref ExactSizeArrBuilder!ubyte a, immutable u16 value) {
	verify(a.cur + 2 <= a.end);
	u16* ptr = cast(u16*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add32(ref ExactSizeArrBuilder!ubyte a, immutable u32 value) {
	verify(a.cur + 4 <= a.end);
	u32* ptr = cast(u32*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add64(ref ExactSizeArrBuilder!ubyte a, immutable u64 value) {
	verify(a.cur + 8 <= a.end);
	u64* ptr = cast(u64*) a.cur;
	*ptr = value;
	a.cur = cast(u8*) (ptr + 1);
}

@trusted void add64TextPtr(ref ExactSizeArrBuilder!ubyte a, immutable size_t textIndex) {
	add64(a, cast(immutable u64) (a.begin + textIndex));
}

@trusted immutable(Arr!T) finish(T)(ref ExactSizeArrBuilder!T a) {
	verify(a.cur == a.end);
	immutable Arr!T res = arrOfRange(cast(immutable) a.begin, cast(immutable) a.end);
	a.begin = null;
	a.cur = null;
	a.end = null;
	return res;
}
