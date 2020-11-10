module interpret.generateText;

@safe @nogc pure nothrow:

import concreteModel : Constant, matchConstant;
import interpret.typeLayout : sizeOfType, TypeLayout;
import lowModel :
	AllConstantsLow,
	ArrTypeAndConstantsLow,
	asNonFunPtrType,
	asRecordType,
	LowField,
	LowProgram,
	LowType,
	PointerTypeAndConstantsLow;
import util.collection.arr : Arr, arrOfRange, at, size;
import util.collection.arrUtil : createArr, map, sum;
import util.collection.dict : Dict, KeyValuePair, mustGetAt_mut;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.ptr : Ptr;
import util.util : todo, verify;

void generateText(Alloc)(ref Alloc alloc, ref immutable TypeLayout typeLayout, ref immutable AllConstantsLow allConstants) {
	immutable size_t nArrs = size(allConstants.arrs);
	immutable size_t nPtrs = size(allConstants.pointers);

	Arr!(Arr!size_t) arrTypeIndexToIndexToTextIndex = map!(Arr!size_t)(
		alloc,
		allConstants.arrs,
		(ref immutable ArrTypeAndConstantsLow it) =>
			map!size_t(alloc, it.constants, (ref immutable Arr!Constant) => 0));
	Arr!(Arr!size_t) pointeeTypeIndexToIndexToTextIndex = map!(Arr!size_t)(
		alloc,
		allConstants.pointers,
		(ref immutable PointerTypeAndConstantsLow it) =>
			map!size_t(alloc, it.pointers, (ref immutable Ptr!Constant) => 0));

	//Arr!size_t arrToTextIndex = createArr!size_t(nArrs, (immutable size_t) => 0);
	//Arr!size_t ptrToTextIndex = createArr!size_t(nPtrs, (immutable size_t) => 0);

	// '1 +' because we add a dummy byte at 0
	ExactSizeArrBuilder!ubyte text = newExactSizeArrBuilder(alloc, 1 + getAllConstantsSize(typeLayout, allConstants));
	// Ensure 0 is not a valid text index
	add(alloc, text, 0);

	void ensureConstant(ref immutable LowType t, ref immutable Constant c) {
		matchConstant!void(
			c,
			(ref immutable Constant.ArrConstant it) {
				immutable ArrTypeAndConstantsLow arrs = at(allConstants.arrs, it.typeIndex);
				verify(arrs.arrType == asRecordType(t));
				recurAddArr(it.typeIndex, it.index, at(arrs.constants, it.index));
			},
			(immutable Constant.BoolConstant) {},
			(immutable Constant.Integral) {},
			(immutable Constant.Null) {},
			(immutable Constant.Pointer it) {
				immutable PointerTypeAndConstantsLow ptrs = at(allConstants.pointers, it.typeIndex);
				verify(lowTypeEqual(ptrs.pointeeType == asNonFunPtr(t).pointee));
				recurAddPointer(ptrs.pointeeType, it.index, at(ptrs.constants, it.index));
			},
			(ref immutable Constant.Record) {
				todo!void("!");
			},
			(ref immutable Constant.Union) {
				todo!void("!");
			});
	}

	void recurAddArr(
		immutable size_t arrTypeIndex,
		immutable size_t index, // constant index within the same type
		immutable Arr!Constant elements,
	) {
		Arr!size_t indexToTextIndex = at(arrTypeToIndexToTextIndex, arrTypeIndex);
		if (at(indexToTextIndex, index) == 0) {
			foreach (ref immutable Constant it; range(elements))
				ensureConstant(it);
			setAt(indexToTextIndex, index, arrBuilderSize(text));
			foreach (ref immutable Constant it; range(elements))
				writeConstant(alloc, text, it);
		}
	}

	void recurAddPointer(
		immutable LowType pointeeType,
		immutable size_t index,
		immutable Ptr!Constant pointee,
	) {
		Arr!size_t indexToTextIndex = mustGetAt_mut(pointeeTypeIndexToIndexToTextIndex, pointeeType);
		if (at(indexToTextIndex, index) == 0) {
			ensureConstant(pointee);
			setAt(indexToTextIndex, arrBuilderSize(text));
			writeConstant(alloc, text, it);
		}
	}

	todo!void("generateText");
}

private:

immutable(size_t) getAllConstantsSize(ref immutable TypeLayout typeLayout, ref immutable AllConstantsLow allConstants) {
	immutable size_t arrsSize = sum(allConstants.arrs, (ref immutable ArrTypeAndConstantsLow arrs) =>
		sizeOfType(typeLayout, arrs.elementType).raw() * sum(arrs.constants, (ref immutable Arr!Constant elements) => size(elements)));
	immutable size_t pointersSize = sum(allConstants.pointers, (ref immutable PointerTypeAndConstantsLow pointers) =>
		sizeOfType(typeLayout, pointers.pointeeType).raw() * size(pointers.constants));
	return arrsSize + pointersSize;
}

void writeConstant(Alloc)(ref Alloc alloc, ref ExactSizeArrBuilder!ubyte text, ref immutable LowType type, ref immutable Constant constant) {
	matchConstant(
		constant,
		(ref immutable Constant.ArrConstant) {
			todo!void("!");
		},
		(immutable Constant.BoolConstant) {
			todo!void("!");
		},
		(immutable Constant.Integral) {
			// how many bytes to write depends on the LowType
			todo!void("!");
		},
		(immutable Constant.Null) {
			todo!void("!");
		},
		(immutable Constant.Pointer) {
			// We should know where we wrote the pointee to
			todo!void("!");
		},
		(ref immutable Constant.Record) {
			// Remember to add padding!
			// Should generate the type layout first and pass it along to here
			todo!void("!");
		},
		(ref immutable Constant.Union) {
			todo!void("!");
		},
		(immutable Constant.Void) {
			todo!void("!"); // should only happen if there's a pointer to void..
		});
}

//TODO:MOVE
immutable(LowType) elementTypeFromArrType(ref immutable LowProgram program, ref immutable LowType t) {
	immutable Arr!LowField fields = fullIndexDictGet(program.allRecords, asRecordType(t)).fields;
	verify(size(fields) == 2);
	return asNonFunPtrType(at(fields, 1).type).pointee;
}

//TODO:MOVE
struct ExactSizeArrBuilder(T) {
	private:
	const T* begin;
	T* cur;
	const T* end;
}

immutable(size_t) exactSizeArrBuilderSize(T)(ref const ExactSizeArrBuilder!T a) {
	return a.end - a.begin;
}

ExactSizeArrBuilder!T newExactSizeArrBuilder(Alloc)(ref Alloc alloc, immutable size_t size) {
	T* begin = cast(T*) alloc.allocate(T.sizeof * size);
	return ExactSizeArrBuilder!T(begin, begin, begin + size);
}

void add(T)(ref ExactSizeArrBuilder!T a, immutable T value) {
	verify(a.cur < a.end);
	*a.cur = value;
	a.cur++;
}

immutable(Arr!T) finish(T)(ref ExactSizeArrBuilder!T a) {
	verify(a.cur == a.end);
	immutable Arr!T res = arrOfRange(a.begin, a.end);
	a.begin = null;
	a.cur = null;
	a.end = null;
	return res;
}
