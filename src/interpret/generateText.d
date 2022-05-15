module interpret.generateText;

@safe @nogc pure nothrow:

import interpret.funToReferences : FunToReferences, registerTextReference;
import model.constant : Constant, matchConstant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asFunPtrType,
	asPrimitive,
	asPtrGcPointee,
	asRecordType,
	asUnionType,
	LowField,
	LowFunIndex,
	LowProgram,
	LowRecord,
	LowType,
	PointerTypeAndConstantsLow,
	PrimitiveType;
import model.typeLayout : sizeOfType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : castImmutable, empty, emptyArr;
import util.col.arrUtil : map, mapToMut, sum, zip;
import util.col.dict : mustGetAt;
import util.col.exactSizeArrBuilder :
	exactSizeArrBuilderAdd,
	add0Bytes,
	add16,
	add32,
	add64,
	add64TextPtr,
	addStringAndNulTerminate,
	ExactSizeArrBuilder,
	exactSizeArrBuilderCurSize,
	finish,
	newExactSizeArrBuilder,
	padTo;
import util.col.str : SafeCStr, safeCStrSize;
import util.conv : bitsOfFloat32, bitsOfFloat64;
import util.ptr : ptrTrustMe_mut;
import util.util : todo, unreachable, verify;

struct TextIndex {
	immutable size_t index;
}

struct TextAndInfo {
	ubyte[] text; // mutable since it contains function pointers that must be filled in later
	immutable TextInfo info;
}

struct TextInfo {
	immutable ubyte[] text; //NOTE: this is the same as the mutable one, immutable for convenience
	immutable size_t[] cStringIndexToTextIndex;
	immutable size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	immutable size_t[][] pointeeTypeIndexToIndexToTextIndex;
}

struct TextArrInfo {
	immutable size_t size;
	immutable ubyte* textPtr;
}

immutable(TextArrInfo) getTextInfoForArray(
	ref immutable TextInfo info,
	ref immutable AllConstantsLow allConstants,
	immutable Constant.ArrConstant a,
) {
	immutable size_t constantSize = allConstants.arrs[a.typeIndex].constants[a.index].length;
	immutable size_t textIndex = info.arrTypeIndexToConstantIndexToTextIndex[a.typeIndex][a.index];
	return immutable TextArrInfo(constantSize, &info.text[textIndex]);
}

immutable(ubyte*) getTextPointer(ref immutable TextInfo info, immutable Constant.Pointer a) {
	immutable size_t textIndex = info.pointeeTypeIndexToIndexToTextIndex[a.typeIndex][a.index];
	return &info.text[textIndex];
}

immutable(ubyte*) getTextPointerForCString(ref immutable TextInfo info, immutable Constant.CString a) {
	return &info.text[info.cStringIndexToTextIndex[a.index]];
}

// TODO: not @trusted
@trusted TextAndInfo generateText(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	scope immutable LowProgram* programPtr,
	scope immutable AllConstantsLow* allConstantsPtr,
	ref FunToReferences funToReferences,
) {
	ref immutable(AllConstantsLow) allConstants() { return *allConstantsPtr; }

	Ctx ctx = Ctx(
		programPtr,
		allConstantsPtr,
		// '1 +' because we add a dummy byte at 0
		newExactSizeArrBuilder!ubyte(alloc, 1 + getAllConstantsSize(*programPtr, allConstants)),
		ptrTrustMe_mut(funToReferences),
		emptyArr!size_t, // cStringIndexToTextIndex will be overwritten just below this
		mapToMut!(size_t[], ArrTypeAndConstantsLow)(
			alloc,
			allConstants.arrs,
			(ref immutable ArrTypeAndConstantsLow it) =>
				mapToMut(alloc, it.constants, (ref immutable Constant[]) => size_t(0))),
	 	mapToMut!(size_t[])(
			alloc,
			allConstants.pointers,
			(ref immutable PointerTypeAndConstantsLow it) =>
				mapToMut!(size_t, Constant)(alloc, it.constants, (scope ref immutable Constant) => size_t(0))));

	// Ensure 0 is not a valid text index
	exactSizeArrBuilderAdd(ctx.text, 0);

	ctx.cStringIndexToTextIndex = map!size_t(alloc, allConstants.cStrings, (ref immutable SafeCStr value) {
		immutable size_t textIndex = exactSizeArrBuilderCurSize(ctx.text);
		addStringAndNulTerminate(ctx.text, value);
		return textIndex;
	});

	foreach (immutable size_t arrTypeIndex; 0 .. allConstants.arrs.length) {
		scope immutable ArrTypeAndConstantsLow* typeAndConstants = &allConstants.arrs[arrTypeIndex];
		foreach (immutable size_t constantIndex, ref immutable Constant[] elements; typeAndConstants.constants)
			recurWriteArr(
				alloc,
				tempAlloc,
				ctx,
				arrTypeIndex,
				typeAndConstants.elementType,
				constantIndex,
				elements);
	}
	foreach (immutable size_t pointeeTypeIndex; 0 .. allConstants.pointers.length) {
		immutable PointerTypeAndConstantsLow* typeAndConstants = &allConstants.pointers[pointeeTypeIndex];
		foreach (immutable size_t constantIndex, immutable Constant pointee; typeAndConstants.constants)
			recurWritePointer(
				alloc,
				tempAlloc,
				ctx,
				pointeeTypeIndex,
				typeAndConstants.pointeeType,
				constantIndex,
				pointee);
	}
	ubyte[] text = castNonScope(finish(ctx.text));
	return TextAndInfo(
		text,
		immutable TextInfo(
			castImmutable(text),
			castNonScope(castImmutable(ctx.cStringIndexToTextIndex)),
			castNonScope(castImmutable(ctx.arrTypeIndexToConstantIndexToTextIndex)),
			castNonScope(castImmutable(ctx.pointeeTypeIndexToIndexToTextIndex))));
}

private:

T[] castNonScope(T)(scope T[] a) {
	return a;
}

struct Ctx {
	@safe @nogc pure nothrow:

	immutable LowProgram* programPtr;
	immutable AllConstantsLow* allConstantsPtr;
	ExactSizeArrBuilder!ubyte text;
	FunToReferences* funToReferencesPtr;
	immutable(size_t)[] cStringIndexToTextIndex;
	size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	size_t[][] pointeeTypeIndexToIndexToTextIndex;

	ref immutable(LowProgram) program() return scope const {
		return *programPtr;
	}

	ref immutable(AllConstantsLow) allConstants() return scope const {
		return *allConstantsPtr;
	}

	ref FunToReferences funToReferences() return scope {
		return *funToReferencesPtr;
	}
}

// Write out any constants that this points to.
void ensureConstant(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	scope immutable LowType t,
	ref immutable Constant c,
) {
	matchConstant!void(
		c,
		(ref immutable Constant.ArrConstant it) {
			immutable ArrTypeAndConstantsLow* arrs = &ctx.allConstants.arrs[it.typeIndex];
			verify(arrs.arrType == asRecordType(t));
			recurWriteArr(
				alloc,
				tempAlloc,
				ctx,
				it.typeIndex,
				arrs.elementType,
				it.index,
				arrs.constants[it.index]);
		},
		(immutable Constant.BoolConstant) {},
		(ref immutable Constant.CString) {
			// We wrote out all CStrings first, so no need to do anything here.
		},
		(immutable Constant.Float) {},
		(immutable Constant.FunPtr) {},
		(immutable Constant.Integral) {},
		(immutable Constant.Null) {},
		(immutable Constant.Pointer it) {
			immutable PointerTypeAndConstantsLow* ptrs = &ctx.allConstants.pointers[it.typeIndex];
			verify(ptrs.pointeeType == asPtrGcPointee(t));
			recurWritePointer(
				alloc, tempAlloc, ctx,
				it.typeIndex, ptrs.pointeeType, it.index, ptrs.constants[it.index]);
		},
		(ref immutable Constant.Record it) {
			immutable LowRecord record = ctx.program.allRecords[asRecordType(t)];
			zip!(LowField, Constant)(
				record.fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant arg) {
					ensureConstant(alloc, tempAlloc, ctx, field.type, arg);
				});
		},
		(ref immutable Constant.Union it) {
			ensureConstant(alloc, tempAlloc, ctx, unionMemberType(ctx.program, asUnionType(t), it.memberIndex), it.arg);
		},
		(immutable Constant.Void) {});
}

ref immutable(LowType) unionMemberType(
	ref immutable LowProgram program,
	immutable LowType.Union t,
	immutable size_t memberIndex,
) {
	return program.allUnions[t].members[memberIndex];
}

void recurWriteArr(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	immutable size_t arrTypeIndex,
	scope immutable LowType elementType,
	immutable size_t index, // constant index within the same type
	scope immutable Constant[] elements,
) {
	verify(!empty(elements));
	size_t[] indexToTextIndex = ctx.arrTypeIndexToConstantIndexToTextIndex[arrTypeIndex];
	if (indexToTextIndex[index] == 0) {
		foreach (ref immutable Constant it; elements)
			ensureConstant(alloc, tempAlloc, ctx, elementType, it);
		indexToTextIndex[index] = exactSizeArrBuilderCurSize(ctx.text);
		foreach (ref immutable Constant it; elements)
			writeConstant(alloc, tempAlloc, ctx, elementType, it);
	}
}

void recurWritePointer(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	immutable size_t pointeeTypeIndex,
	scope immutable LowType pointeeType,
	immutable size_t index,
	ref immutable Constant pointee,
) {
	size_t[] indexToTextIndex = ctx.pointeeTypeIndexToIndexToTextIndex[pointeeTypeIndex];
	if (indexToTextIndex[index] == 0) {
		ensureConstant(alloc, tempAlloc, ctx, pointeeType, pointee);
		indexToTextIndex[index] = exactSizeArrBuilderCurSize(ctx.text);
		writeConstant(alloc, tempAlloc, ctx, pointeeType, pointee);
	}
}

//TODO: should we align things?
immutable(size_t) getAllConstantsSize(ref immutable LowProgram program, ref immutable AllConstantsLow allConstants) {
	immutable size_t cStringsSize = sum(allConstants.cStrings, (ref immutable SafeCStr x) =>
		safeCStrSize(x) + 1);
	immutable size_t arrsSize = sum(allConstants.arrs, (ref immutable ArrTypeAndConstantsLow arrs) =>
		sizeOfType(program, arrs.elementType).size *
		sum(arrs.constants, (ref immutable Constant[] elements) => elements.length));
	immutable size_t pointersSize = sum(allConstants.pointers, (ref immutable PointerTypeAndConstantsLow pointers) =>
		sizeOfType(program, pointers.pointeeType).size * pointers.constants.length);
	return cStringsSize + arrsSize + pointersSize;
}

void writeConstant(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	scope immutable LowType type,
	ref immutable Constant constant,
) {
	immutable size_t sizeBefore = exactSizeArrBuilderCurSize(ctx.text);
	immutable size_t typeSize = sizeOfType(ctx.program, type).size;

	matchConstant!void(
		constant,
		(ref immutable Constant.ArrConstant it) {
			//TODO:DUP CODE (see getTextInfoForArray)
			immutable size_t constantSize = ctx.allConstants.arrs[it.typeIndex].constants[it.index].length;
			add64(ctx.text, constantSize);
			immutable size_t textIndex = ctx.arrTypeIndexToConstantIndexToTextIndex[it.typeIndex][it.index];
			add64TextPtr(ctx.text, textIndex);
		},
		(immutable Constant.BoolConstant it) {
			exactSizeArrBuilderAdd(ctx.text, it.value ? 1 : 0);
		},
		(ref immutable Constant.CString it) {
			add64TextPtr(ctx.text, ctx.cStringIndexToTextIndex[it.index]);
		},
		(immutable Constant.Float it) {
			switch (asPrimitive(type)) {
				case PrimitiveType.float32:
					add32(ctx.text, bitsOfFloat32(it.value));
					break;
				case PrimitiveType.float64:
					add64(ctx.text, bitsOfFloat64(it.value));
					break;
				default:
					unreachable!void();
					break;
			}
		},
		(immutable Constant.FunPtr it) {
			immutable LowFunIndex fun = mustGetAt(ctx.program.concreteFunToLowFunIndex, it.fun);
			registerTextReference(
				tempAlloc,
				ctx.funToReferences,
				asFunPtrType(type),
				fun,
				immutable TextIndex(exactSizeArrBuilderCurSize(ctx.text)));
			add64(ctx.text, 0);
		},
		(immutable Constant.Integral it) {
			final switch (asPrimitive(type)) {
				case PrimitiveType.bool_:
				case PrimitiveType.float32:
				case PrimitiveType.float64:
				case PrimitiveType.void_:
					unreachable!void();
					break;
				case PrimitiveType.char8:
				case PrimitiveType.int8:
				case PrimitiveType.nat8:
					exactSizeArrBuilderAdd(ctx.text, cast(ubyte) it.value);
					break;
				case PrimitiveType.int16:
				case PrimitiveType.nat16:
					add16(ctx.text, cast(ushort) it.value);
					break;
				case PrimitiveType.int32:
				case PrimitiveType.nat32:
					add32(ctx.text, cast(uint) it.value);
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
			immutable size_t textIndex = ctx.pointeeTypeIndexToIndexToTextIndex[it.typeIndex][it.index];
			add64TextPtr(ctx.text, textIndex);
		},
		(ref immutable Constant.Record it) {
			immutable LowType.Record recordType = asRecordType(type);
			immutable LowRecord record = ctx.program.allRecords[recordType];
			immutable size_t start = exactSizeArrBuilderCurSize(ctx.text);
			zip!(LowField, Constant)(
				record.fields,
				it.args,
				(ref immutable LowField field, ref immutable Constant fieldValue) {
					padTo(ctx.text, start + field.offset);
					writeConstant(alloc, tempAlloc, ctx, field.type, fieldValue);
				});
			padTo(ctx.text, start + typeSize);
		},
		(ref immutable Constant.Union it) {
			add64(ctx.text, it.memberIndex);
			immutable LowType memberType = unionMemberType(ctx.program, asUnionType(type), it.memberIndex);
			writeConstant(alloc, tempAlloc, ctx, memberType, it.arg);
			immutable size_t unionSize = sizeOfType(ctx.program, type).size;
			immutable size_t memberSize = sizeOfType(ctx.program, memberType).size;
			immutable size_t padding = unionSize - 8 - memberSize;
			add0Bytes(ctx.text, padding);
		},
		(immutable Constant.Void) {
			todo!void("write void"); // should only happen if there's a pointer to void..
		});

	immutable size_t sizeAfter = exactSizeArrBuilderCurSize(ctx.text);
	verify(typeSize == sizeAfter - sizeBefore);
}
