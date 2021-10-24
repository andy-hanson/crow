module concretize.allConstantsBuilder;

@safe @nogc pure nothrow:

import lower.lower : concreteFunWillBecomeNonExternLowFun;
import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	asInst,
	asRecord,
	body_,
	ConcreteFun,
	ConcreteStruct,
	ConcreteType,
	compareConcreteType,
	mustBeNonPointer,
	name,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant, constantEqual;
import util.alloc.alloc : Alloc;
import util.collection.arr : empty, only;
import util.collection.arrUtil : arrEqual, arrLiteral, findIndex_const, map, mapOp, map_mut;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push, tempAsArr;
import util.collection.mutDict : getOrAdd, MutDict, mustGetAt_mut, mutDictSize, tempPairs_mut, valuesArray;
import util.collection.str : compareStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe_mut;
import util.sym : compareSym, strOfSym, Sym;
import util.util : verify;

struct AllConstantsBuilder {
	private:
	@disable this(ref const AllConstantsBuilder);
	MutDict!(immutable string, immutable Constant.CString, compareStr) cStrings;
	MutDict!(immutable Sym, immutable Constant, compareSym) syms;
	MutArr!(immutable string) cStringValues;
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

immutable(AllConstantsConcrete) finishAllConstants(
	ref Alloc alloc,
	ref AllConstantsBuilder a,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
	immutable Ptr!ConcreteStruct arrNamedValFunPtrStruct,
	immutable Ptr!ConcreteStruct arrSymStruct,
) {
	immutable Constant allFuns = makeAllFuns(alloc, a, allConcreteFuns, arrNamedValFunPtrStruct);
	immutable Constant staticSyms = getConstantArr(alloc, a, arrSymStruct, valuesArray(alloc, a.syms));
	immutable ArrTypeAndConstantsConcrete[] arrs =
		map_mut(alloc, tempPairs_mut(a.arrs), (ref KeyValuePair!(immutable ConcreteType, ArrTypeAndConstants) pair) =>
			immutable ArrTypeAndConstantsConcrete(
				pair.value.arrType,
				pair.value.elementType,
				moveToArr!(immutable Constant[])(alloc, pair.value.constants)));
	immutable PointerTypeAndConstantsConcrete[] records =
		map_mut(
			alloc,
			tempPairs_mut(a.pointers),
			(ref KeyValuePair!(immutable Ptr!ConcreteStruct, PointerTypeAndConstants) pair) =>
				immutable PointerTypeAndConstantsConcrete(
					pair.key,
					moveToArr!(immutable Ptr!Constant)(alloc, pair.value.constants)));
	return immutable AllConstantsConcrete(moveToArr(alloc, a.cStringValues), allFuns, staticSyms, arrs, records);
}

private immutable(Constant) makeAllFuns(
	ref Alloc alloc,
	ref AllConstantsBuilder a,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
	immutable Ptr!ConcreteStruct arrNamedValFunPtrStruct,
) {
	return getConstantArr(
		alloc,
		a,
		arrNamedValFunPtrStruct,
		mapOp!Constant(alloc, allConcreteFuns, (ref immutable Ptr!ConcreteFun it) {
			immutable Opt!Sym name = name(it.deref());
			return has(name) && concreteFunWillBecomeNonExternLowFun(it)
				? some(immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [
					getConstantSym(alloc, a, force(name)),
					immutable Constant(immutable Constant.FunPtr(it))]))))
				: none!Constant;
		}));
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
immutable(Constant) getConstantPtr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct struct_,
	ref immutable Constant value,
) {
	Ptr!PointerTypeAndConstants d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.pointers, struct_, () =>
		PointerTypeAndConstants(mutDictSize(allConstants.pointers), MutArr!(immutable Ptr!Constant)())));
	return immutable Constant(immutable Constant.Pointer(d.typeIndex, findOrPush!(immutable Ptr!Constant)(
		alloc,
		d.constants,
		(ref immutable Ptr!Constant a) =>
			constantEqual(a, value),
		() =>
			allocate(alloc, value))));
}


immutable(Constant) getConstantArr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct arrStruct,
	immutable Constant[] elements,
) {
	if (empty(elements))
		return constantEmptyArr();
	else {
		immutable ConcreteType elementType = only(asInst(arrStruct.source).typeArgs);
		Ptr!ArrTypeAndConstants d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.arrs, elementType, () =>
			ArrTypeAndConstants(
				arrStruct,
				elementType,
				mutDictSize(allConstants.arrs), MutArr!(immutable Constant[])())));
		immutable size_t index = findOrPush!(immutable Constant[])(
			alloc,
			d.constants,
			(ref immutable Constant[] it) =>
				constantArrEqual(it, elements),
			() =>
				elements);
		return immutable Constant(immutable Constant.ArrConstant(d.typeIndex, index));
	}
}

private immutable(Constant) constantEmptyArr() {
	static immutable Constant[2] fields = [
		immutable Constant(immutable Constant.Integral(0)),
		immutable Constant(immutable Constant.Null())];
	return immutable Constant(immutable Constant.Record(fields));
}

immutable(Constant) getConstantStr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Ptr!ConcreteStruct strStruct,
	immutable string str,
) {
	immutable Constant[] chars = map!Constant(alloc, str, (ref immutable char it) =>
		constantChar(it));
	immutable Ptr!ConcreteStruct arrCharStruct = mustBeNonPointer(only(asRecord(body_(strStruct)).fields).type);
	immutable Constant arr = getConstantArr(alloc, allConstants, arrCharStruct, chars);
	return immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [arr])));
}

private immutable(Constant.CString) getConstantCStr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable string value,
) {
	return getOrAdd!(immutable string, immutable Constant.CString, compareStr)(
		alloc,
		allConstants.cStrings,
		value,
		() {
			immutable size_t index = mutArrSize(allConstants.cStringValues);
			verify(mutDictSize(allConstants.cStrings) == index);
			push(alloc, allConstants.cStringValues, value);
			return immutable Constant.CString(index);
		});
}

immutable(Constant) getConstantSym(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable Sym value,
) {
	return getOrAdd!(immutable Sym, immutable Constant, compareSym)(
		alloc,
		allConstants.syms,
		value,
		() {
			immutable Constant.CString c = getConstantCStr(alloc, allConstants, strOfSym(alloc, value));
			return immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [immutable Constant(c)])));
		});
}

private immutable(Constant) constantChar(immutable char a) {
	return immutable Constant(immutable Constant.Integral(a));
}

private:

immutable(bool) constantArrEqual(ref immutable Constant[] a, ref immutable Constant[] b) {
	return arrEqual!Constant(a, b, (ref immutable Constant x, ref immutable Constant y) =>
		constantEqual(x, y));
}

immutable(size_t) findOrPush(T)(
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

