module interpret.generateText;

@safe @nogc pure nothrow:

import interpret.funToReferences : FunToReferences, registerTextReference;
import model.constant : Constant;
import model.lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asPtrGcPointee,
	LowField,
	LowFunIndex,
	LowProgram,
	LowRecord,
	LowVar,
	LowVarIndex,
	LowType,
	PointerTypeAndConstantsLow,
	PrimitiveType;
import model.model : VarKind;
import model.typeLayout : nStackEntriesForType, typeSizeBytes;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : castImmutable, empty;
import util.col.arrUtil : map, sum, zip;
import util.col.map : mustGet;
import util.col.enumMap : EnumMap;
import util.col.exactSizeArrBuilder :
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
import util.col.fullIndexMap : FullIndexMap, mapFullIndexMap;
import util.col.str : SafeCStr, safeCStrSize;
import util.conv : bitsOfFloat32, bitsOfFloat64;
import util.util : castNonScope, ptrTrustMe, todo, unreachable;

immutable struct VarsInfo {
	// Thread-locals and globals offsets are in different buffers.
	// Vars can't take up a fraction of a word.
	FullIndexMap!(LowVarIndex, size_t) offsetsInWords;
	EnumMap!(VarKind, size_t) totalSizeWords;
}

VarsInfo generateVarsInfo(ref Alloc alloc, in LowProgram program) {
	EnumMap!(VarKind, size_t) curWords;
	immutable FullIndexMap!(LowVarIndex, size_t) offsetsInWords =
		mapFullIndexMap!(LowVarIndex, size_t, LowVar)(alloc, program.vars, (LowVarIndex _, in LowVar x) {
			size_t handle(VarKind kind) {
				size_t res = curWords[kind];
				curWords[kind] += nStackEntriesForType(program, x.type);
				return res;
			}
			final switch (x.kind) {
				case LowVar.Kind.externGlobal:
					// See 'writeVarPtr' -- we don't use VarsInfo for these
					return size_t.max;
				case LowVar.Kind.global:
					return handle(VarKind.global);
				case LowVar.Kind.threadLocal:
					return handle(VarKind.threadLocal);
			}
		});
	return VarsInfo(offsetsInWords, curWords);
}

immutable struct TextIndex {
	size_t index;
}

struct TextAndInfo {
	ubyte[] text; // mutable since it contains function pointers that must be filled in later
	immutable TextInfo info;
}

immutable struct TextInfo {
	ubyte[] text; //NOTE: this is the same as the mutable one, immutable for convenience
	size_t[] cStringIndexToTextIndex;
	size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	size_t[][] pointeeTypeIndexToIndexToTextIndex;
}

immutable struct TextArrInfo {
	size_t size;
	ubyte* textPtr;
}

TextArrInfo getTextInfoForArray(ref TextInfo info, in AllConstantsLow allConstants, Constant.ArrConstant a) {
	size_t constantSize = allConstants.arrs[a.typeIndex].constants[a.index].length;
	size_t textIndex = info.arrTypeIndexToConstantIndexToTextIndex[a.typeIndex][a.index];
	return TextArrInfo(constantSize, &info.text[textIndex]);
}

immutable(ubyte*) getTextPointer(ref TextInfo info, Constant.Pointer a) {
	size_t textIndex = info.pointeeTypeIndexToIndexToTextIndex[a.typeIndex][a.index];
	return &info.text[textIndex];
}

immutable(ubyte*) getTextPointerForCString(ref TextInfo info, Constant.CString a) =>
	&info.text[info.cStringIndexToTextIndex[a.index]];

TextAndInfo generateText(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	in LowProgram program,
	ref FunToReferences funToReferences,
) {
	Ctx ctx = Ctx(
		ptrTrustMe(program),
		// '1 +' because we add a dummy byte at 0
		newExactSizeArrBuilder!ubyte(alloc, 1 + getAllConstantsSize(program)),
		ptrTrustMe(funToReferences),
		[], // cStringIndexToTextIndex will be overwritten just below this
		map!(size_t[], ArrTypeAndConstantsLow)(
			alloc,
			program.allConstants.arrs,
			(ref ArrTypeAndConstantsLow it) =>
				map!(size_t, immutable Constant[])(alloc, it.constants, (ref Constant[]) => size_t(0))),
	 	map!(size_t[], PointerTypeAndConstantsLow)(
			alloc,
			program.allConstants.pointers,
			(ref PointerTypeAndConstantsLow x) =>
				map!(size_t, Constant)(alloc, x.constants, (ref Constant) => size_t(0))));

	// Ensure 0 is not a valid text index
	ctx.text ~= 0;

	ctx.cStringIndexToTextIndex = map(alloc, program.allConstants.cStrings, (ref SafeCStr value) {
		immutable size_t textIndex = exactSizeArrBuilderCurSize(ctx.text);
		addStringAndNulTerminate(ctx.text, value);
		return textIndex;
	});

	foreach (size_t arrTypeIndex; 0 .. program.allConstants.arrs.length) {
		scope ArrTypeAndConstantsLow* typeAndConstants = &program.allConstants.arrs[arrTypeIndex];
		foreach (size_t constantIndex, Constant[] elements; typeAndConstants.constants)
			recurWriteArr(
				alloc,
				tempAlloc,
				ctx,
				arrTypeIndex,
				typeAndConstants.elementType,
				constantIndex,
				elements);
	}
	foreach (size_t pointeeTypeIndex; 0 .. program.allConstants.pointers.length) {
		PointerTypeAndConstantsLow* typeAndConstants = &program.allConstants.pointers[pointeeTypeIndex];
		foreach (size_t constantIndex, Constant pointee; typeAndConstants.constants)
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
		TextInfo(
			castImmutable(text),
			castNonScope(ctx.cStringIndexToTextIndex),
			castNonScope(castImmutable(ctx.arrTypeIndexToConstantIndexToTextIndex)),
			castNonScope(castImmutable(ctx.pointeeTypeIndexToIndexToTextIndex))));
}

private:

struct Ctx {
	@safe @nogc pure nothrow:

	immutable LowProgram* programPtr;
	ExactSizeArrBuilder!ubyte text;
	FunToReferences* funToReferencesPtr;
	immutable(size_t)[] cStringIndexToTextIndex;
	size_t[][] arrTypeIndexToConstantIndexToTextIndex;
	size_t[][] pointeeTypeIndexToIndexToTextIndex;

	ref LowProgram program() return scope const =>
		*programPtr;

	ref FunToReferences funToReferences() return scope =>
		*funToReferencesPtr;
}

// Write out any constants that this points to.
void ensureConstant(ref Alloc alloc, ref TempAlloc tempAlloc, ref Ctx ctx, in LowType t, in Constant c) {
	c.matchIn!void(
		(in Constant.ArrConstant it) {
			ArrTypeAndConstantsLow* arrs = &ctx.program.allConstants.arrs[it.typeIndex];
			assert(arrs.arrType == t.as!(LowType.Record));
			recurWriteArr(
				alloc,
				tempAlloc,
				ctx,
				it.typeIndex,
				arrs.elementType,
				it.index,
				arrs.constants[it.index]);
		},
		(in Constant.CString) {
			// We wrote out all CStrings first, so no need to do anything here.
		},
		(in Constant.Float) {},
		(in Constant.FunPtr) {},
		(in Constant.Integral) {},
		(in Constant.Pointer it) {
			PointerTypeAndConstantsLow* ptrs = &ctx.program.allConstants.pointers[it.typeIndex];
			assert(ptrs.pointeeType == asPtrGcPointee(t));
			recurWritePointer(
				alloc, tempAlloc, ctx,
				it.typeIndex, ptrs.pointeeType, it.index, ptrs.constants[it.index]);
		},
		(in Constant.Record x) {
			LowRecord record = ctx.program.allRecords[t.as!(LowType.Record)];
			zip!(LowField, Constant)(record.fields, x.args, (ref LowField field, ref Constant arg) {
				ensureConstant(alloc, tempAlloc, ctx, field.type, arg);
			});
		},
		(in Constant.Union x) {
			ensureConstant(
				alloc,
				tempAlloc,
				ctx,
				unionMemberType(ctx.program, t.as!(LowType.Union), x.memberIndex),
				x.arg);
		},
		(in Constant.Zero) {});
}

ref LowType unionMemberType(ref LowProgram program, LowType.Union t, size_t memberIndex) =>
	program.allUnions[t].members[memberIndex];

void recurWriteArr(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	size_t arrTypeIndex,
	in LowType elementType,
	size_t index, // constant index within the same type
	in Constant[] elements,
) {
	assert(!empty(elements));
	size_t[] indexToTextIndex = ctx.arrTypeIndexToConstantIndexToTextIndex[arrTypeIndex];
	if (indexToTextIndex[index] == 0) {
		foreach (Constant it; elements)
			ensureConstant(alloc, tempAlloc, ctx, elementType, it);
		indexToTextIndex[index] = exactSizeArrBuilderCurSize(ctx.text);
		foreach (Constant it; elements)
			writeConstant(alloc, tempAlloc, ctx, elementType, it);
	}
}

void recurWritePointer(
	ref Alloc alloc,
	ref TempAlloc tempAlloc,
	ref Ctx ctx,
	size_t pointeeTypeIndex,
	in LowType pointeeType,
	size_t index,
	in Constant pointee,
) {
	size_t[] indexToTextIndex = ctx.pointeeTypeIndexToIndexToTextIndex[pointeeTypeIndex];
	if (indexToTextIndex[index] == 0) {
		ensureConstant(alloc, tempAlloc, ctx, pointeeType, pointee);
		indexToTextIndex[index] = exactSizeArrBuilderCurSize(ctx.text);
		writeConstant(alloc, tempAlloc, ctx, pointeeType, pointee);
	}
}

//TODO: should we align things?
size_t getAllConstantsSize(in LowProgram program) {
	size_t cStringsSize = sum!SafeCStr(program.allConstants.cStrings, (in SafeCStr x) =>
		safeCStrSize(x) + 1);
	size_t arrsSize = sum!ArrTypeAndConstantsLow(program.allConstants.arrs, (in ArrTypeAndConstantsLow arrs) =>
		typeSizeBytes(program, arrs.elementType) *
		sum!(immutable Constant[])(arrs.constants, (in Constant[] elements) => elements.length));
	size_t pointersSize =
		sum!PointerTypeAndConstantsLow(program.allConstants.pointers, (in PointerTypeAndConstantsLow pointers) =>
			typeSizeBytes(program, pointers.pointeeType) * pointers.constants.length);
	return cStringsSize + arrsSize + pointersSize;
}

void writeConstant(ref Alloc alloc, ref TempAlloc tempAlloc, ref Ctx ctx, in LowType type, in Constant constant) {
	size_t sizeBefore = exactSizeArrBuilderCurSize(ctx.text);
	size_t typeSize = typeSizeBytes(ctx.program, type);

	constant.matchIn!void(
		(in Constant.ArrConstant x) {
			//TODO:DUP CODE (see getTextInfoForArray)
			size_t constantSize = ctx.program.allConstants.arrs[x.typeIndex].constants[x.index].length;
			add64(ctx.text, constantSize);
			size_t textIndex = ctx.arrTypeIndexToConstantIndexToTextIndex[x.typeIndex][x.index];
			add64TextPtr(ctx.text, textIndex);
		},
		(in Constant.CString x) {
			add64TextPtr(ctx.text, ctx.cStringIndexToTextIndex[x.index]);
		},
		(in Constant.Float x) {
			switch (type.as!PrimitiveType) {
				case PrimitiveType.float32:
					add32(ctx.text, bitsOfFloat32(x.value));
					break;
				case PrimitiveType.float64:
					add64(ctx.text, bitsOfFloat64(x.value));
					break;
				default:
					unreachable!void();
					break;
			}
		},
		(in Constant.FunPtr x) {
			LowFunIndex fun = mustGet(ctx.program.concreteFunToLowFunIndex, x.fun);
			registerTextReference(
				tempAlloc,
				ctx.funToReferences,
				type.as!(LowType.FunPtr),
				fun,
				TextIndex(exactSizeArrBuilderCurSize(ctx.text)));
			add64(ctx.text, 0);
		},
		(in Constant.Integral x) {
			final switch (type.as!PrimitiveType) {
				case PrimitiveType.float32:
				case PrimitiveType.float64:
				case PrimitiveType.void_:
					unreachable!void();
					break;
				case PrimitiveType.bool_:
				case PrimitiveType.char8:
				case PrimitiveType.int8:
				case PrimitiveType.nat8:
					ctx.text ~= cast(ubyte) x.value;
					break;
				case PrimitiveType.int16:
				case PrimitiveType.nat16:
					add16(ctx.text, cast(ushort) x.value);
					break;
				case PrimitiveType.int32:
				case PrimitiveType.nat32:
					add32(ctx.text, cast(uint) x.value);
					break;
				case PrimitiveType.int64:
				case PrimitiveType.nat64:
					add64(ctx.text, x.value);
					break;
			}
		},
		(in Constant.Pointer x) {
			size_t textIndex = ctx.pointeeTypeIndexToIndexToTextIndex[x.typeIndex][x.index];
			add64TextPtr(ctx.text, textIndex);
		},
		(in Constant.Record x) {
			LowRecord record = ctx.program.allRecords[type.as!(LowType.Record)];
			size_t start = exactSizeArrBuilderCurSize(ctx.text);
			zip!(LowField, Constant)(record.fields, x.args, (ref LowField field, ref Constant fieldValue) {
				padTo(ctx.text, start + field.offset);
				writeConstant(alloc, tempAlloc, ctx, field.type, fieldValue);
			});
			padTo(ctx.text, start + typeSize);
		},
		(in Constant.Union x) {
			add64(ctx.text, x.memberIndex);
			LowType memberType = unionMemberType(ctx.program, type.as!(LowType.Union), x.memberIndex);
			writeConstant(alloc, tempAlloc, ctx, memberType, x.arg);
			size_t unionSize = typeSizeBytes(ctx.program, type);
			size_t memberSize = typeSizeBytes(ctx.program, memberType);
			size_t padding = unionSize - 8 - memberSize;
			add0Bytes(ctx.text, padding);
		},
		(in Constant.Zero) {
			todo!void("!");
		});

	size_t sizeAfter = exactSizeArrBuilderCurSize(ctx.text);
	assert(typeSize == sizeAfter - sizeBefore);
}
