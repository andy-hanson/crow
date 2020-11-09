module concretize.allConstantsBuilder;

@safe @nogc pure nothrow:

import concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	ConcreteStruct,
	ConcreteType,
	Constant,
	compareConcreteType,
	constantEqual,
	matchConstant,
	PointerTypeAndConstantsConcrete;
import util.bools : Bool;
import util.comparison : Comparison;
import util.collection.arr : Arr, asImmutable, empty, size;
import util.collection.arrUtil : arrEqual, createArr, exists, findIndex_const, map, map_mut;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : last, moveToArr, MutArr, mutArrSize, push, tempAsArr;
import util.collection.mutDict : getOrAdd, MutDict, tempPairs_mut;
import util.collection.str : Str;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr;

struct AllConstantsBuilder {
	private:
	MutDict!(immutable ConcreteType, ArrTypeAndConstants, compareConcreteType) arrs;
	MutDict!(immutable Ptr!ConcreteStruct, MutArr!(immutable Ptr!Constant), comparePtr!ConcreteStruct) ptrs;
}

private struct ArrTypeAndConstants {
	immutable Ptr!ConcreteStruct arrType;
	immutable ConcreteType elementType;
	MutArr!(immutable Arr!Constant) constants;
}

immutable(AllConstantsConcrete) finishAllConstants(Alloc)(ref Alloc alloc, ref AllConstantsBuilder a) {
	immutable Arr!ArrTypeAndConstantsConcrete arrs =
		map_mut(alloc, tempPairs_mut(a.arrs), (ref KeyValuePair!(immutable ConcreteType, ArrTypeAndConstants) pair) =>
			immutable ArrTypeAndConstantsConcrete(
				pair.value.arrType,
				pair.value.elementType,
				asImmutable(moveToArr!(immutable Arr!Constant, Alloc)(alloc, pair.value.constants))));
	immutable Arr!PointerTypeAndConstantsConcrete records =
		map_mut(alloc, tempPairs_mut(a.ptrs), (ref KeyValuePair!(immutable Ptr!ConcreteStruct, MutArr!(immutable Ptr!Constant)) pair) =>
			immutable PointerTypeAndConstantsConcrete(pair.key, asImmutable(moveToArr!(immutable Ptr!Constant, Alloc)(alloc, pair.value))));
	return immutable AllConstantsConcrete(arrs, records);
}

immutable(Constant) getConstantPtr(Alloc)(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct struct_,
	ref immutable Constant value,
) {
	return immutable Constant(immutable Constant.Pointer(findOrPush!(immutable Ptr!Constant, Alloc)(
		alloc,
		getOrAdd(alloc, allConstants.ptrs, struct_, () =>
			MutArr!(immutable Ptr!Constant)()),
		(ref immutable Ptr!Constant a) =>
			constantEqual(a, value),
		() =>
			allocate(alloc, value))));
}

immutable(Constant) getConstantArr(Alloc)(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct arrStruct,
	ref immutable ConcreteType elementType,
	ref immutable Arr!Constant elements,
) {
	if (empty(elements))
		return immutable Constant(immutable Constant.ArrConstant(0, 0));
	else {
		immutable size_t index = findOrPush!(immutable Arr!Constant, Alloc)(
			alloc,
			getOrAdd(alloc, allConstants.arrs, elementType, () =>
				ArrTypeAndConstants(arrStruct, elementType, MutArr!(immutable Arr!Constant)())).constants,
			(ref immutable Arr!Constant it) =>
				constantArrEqual(it, elements),
			() =>
				elements);
		return immutable Constant(immutable Constant.ArrConstant(size(elements), index));
	}
}

immutable(Constant) getConstantStr(Alloc)(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct strStruct,
	ref immutable ConcreteType charType,
	ref immutable Str str,
) {
	immutable Arr!Constant chars = map(alloc, str, (ref immutable char c) =>
		immutable Constant(immutable Constant.Integral(c)));
	return getConstantArr(alloc, allConstants, strStruct, charType, chars);
}

private:

immutable(Bool) constantArrEqual(ref immutable Arr!Constant a, ref immutable Arr!Constant b) {
	return arrEqual(a, b, (ref immutable Constant x, ref immutable Constant y) =>
		constantEqual(x, y));
}

immutable(size_t) findOrPush(T, Alloc)(
	ref Alloc alloc,
	ref MutArr!T a,
	scope immutable(Bool) delegate(ref const T) @safe @nogc pure nothrow cbFind,
	scope immutable(T) delegate() @safe @nogc pure nothrow cbPush,
) {
	const Opt!size_t res = findIndex_const!T(tempAsArr(a), cbFind);
	if (has(res))
		return force(res);
	else {
		push(alloc, a, cbPush());
		return mutArrSize(a) - 1;
	}
}

