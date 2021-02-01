module concretize.allConstantsBuilder;

@safe @nogc pure nothrow:

import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	ConcreteStruct,
	ConcreteType,
	compareConcreteType,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant, constantEqual;
import util.collection.arr : empty;
import util.collection.arrUtil : arrEqual, findIndex_const, map, map_mut;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push, tempAsArr;
import util.collection.mutDict : getOrAdd, MutDict, mustGetAt_mut, mutDictSize, tempPairs_mut;
import util.memory : allocate;
import util.opt : force, has, Opt;
import util.ptr : comparePtr, Ptr, ptrTrustMe_mut;
import util.util : verify;

struct AllConstantsBuilder {
	private:
	MutDict!(immutable ConcreteType, ArrTypeAndConstants, compareConcreteType) arrs;
	MutDict!(immutable Ptr!ConcreteStruct, PointerTypeAndConstants, comparePtr!ConcreteStruct) pointers;
}

private struct ArrTypeAndConstants {
	immutable Ptr!ConcreteStruct arrType;
	immutable ConcreteType elementType;
	immutable size_t typeIndex; // order this was inserted into 'arrs'
	MutArr!(immutable Constant[]) constants;
}

private struct PointerTypeAndConstants {
	immutable size_t typeIndex;
	MutArr!(immutable Ptr!Constant) constants;
}

immutable(AllConstantsConcrete) finishAllConstants(Alloc)(ref Alloc alloc, ref AllConstantsBuilder a) {
	immutable ArrTypeAndConstantsConcrete[] arrs =
		map_mut(alloc, tempPairs_mut(a.arrs), (ref KeyValuePair!(immutable ConcreteType, ArrTypeAndConstants) pair) =>
			immutable ArrTypeAndConstantsConcrete(
				pair.value.arrType,
				pair.value.elementType,
				moveToArr!(immutable Constant[], Alloc)(alloc, pair.value.constants)));
	immutable PointerTypeAndConstantsConcrete[] records =
		map_mut(
			alloc,
			tempPairs_mut(a.pointers),
			(ref KeyValuePair!(immutable Ptr!ConcreteStruct, PointerTypeAndConstants) pair) =>
				immutable PointerTypeAndConstantsConcrete(
					pair.key,
					moveToArr!(immutable Ptr!Constant, Alloc)(alloc, pair.value.constants)));
	return immutable AllConstantsConcrete(arrs, records);
}

ref immutable(Constant) derefConstantPointer(
	ref AllConstantsBuilder a,
	ref immutable Constant.Pointer pointer,
	immutable Ptr!ConcreteStruct pointeeType,
) {
	verify(mustGetAt_mut(a.pointers, pointeeType).typeIndex == pointer.typeIndex);
	return mutArrAt(mustGetAt_mut(a.pointers, pointeeType).constants, pointer.index);
}

// TODO: this will be used when creating constant records by-ref.
immutable(Constant) getConstantPtr(Alloc)(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct struct_,
	ref immutable Constant value,
) {
	Ptr!PointerTypeAndConstants d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.pointers, struct_, () =>
		PointerTypeAndConstants(mutDictSize(allConstants.pointers), MutArr!(immutable Ptr!Constant)())));
	return immutable Constant(immutable Constant.Pointer(d.typeIndex, findOrPush!(immutable Ptr!Constant, Alloc)(
		alloc,
		d.constants,
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
	ref immutable Constant[] elements,
) {
	if (empty(elements))
		return constantEmptyArr();
	else {
		Ptr!ArrTypeAndConstants d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.arrs, elementType, () =>
			ArrTypeAndConstants(
				arrStruct,
				elementType,
				mutDictSize(allConstants.arrs), MutArr!(immutable Constant[])())));
		immutable size_t index = findOrPush!(immutable Constant[], Alloc)(
			alloc,
			d.constants,
			(ref immutable Constant[] it) =>
				constantArrEqual(it, elements),
			() =>
				elements);
		return immutable Constant(immutable Constant.ArrConstant(d.typeIndex, index));
	}
}

immutable(Constant) constantEmptyArr() {
	static immutable Constant[2] fields = [
		immutable Constant(immutable Constant.Integral(0)),
		immutable Constant(immutable Constant.Null())];
	return immutable Constant(immutable Constant.Record(fields));
}

immutable(Constant) getConstantStr(Alloc)(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct strStruct,
	ref immutable ConcreteType charType,
	immutable string str,
) {
	immutable Constant[] chars = map(alloc, str, (ref immutable char c) =>
		immutable Constant(immutable Constant.Integral(c)));
	return getConstantArr(alloc, allConstants, strStruct, charType, chars);
}

private:

immutable(bool) constantArrEqual(ref immutable Constant[] a, ref immutable Constant[] b) {
	return arrEqual!Constant(a, b, (ref immutable Constant x, ref immutable Constant y) =>
		constantEqual(x, y));
}

immutable(size_t) findOrPush(T, Alloc)(
	ref Alloc alloc,
	ref MutArr!T a,
	scope immutable(bool) delegate(ref const T) @safe @nogc pure nothrow cbFind,
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

