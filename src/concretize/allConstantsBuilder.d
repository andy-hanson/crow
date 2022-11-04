module concretize.allConstantsBuilder;

@safe @nogc pure nothrow:

import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	asInst,
	ConcreteStruct,
	ConcreteType,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant, constantEqual;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrUtil : arrEqual, arrLiteral, findIndex_const;
import util.col.mutArr : moveToArr, MutArr, mutArrSize, push, tempAsArr;
import util.col.mutDict : getOrAdd, mapToArr_mut, mustGetAt_mut, MutDict, mutDictSize, valuesArray;
import util.col.str : SafeCStr;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe_mut;
import util.sym : AllSymbols, safeCStrOfSym, Sym;
import util.util : verify;

struct AllConstantsBuilder {
	private:
	@disable this(ref const AllConstantsBuilder);
	MutDict!(immutable SafeCStr, immutable Constant.CString) cStrings;
	MutDict!(immutable Sym, immutable Constant) syms;
	MutArr!(immutable SafeCStr) cStringValues;
	MutDict!(immutable ConcreteType, ArrTypeAndConstants) arrs;
	MutDict!(immutable ConcreteStruct*, PointerTypeAndConstants) pointers;
}

private struct ArrTypeAndConstants {
	immutable ConcreteStruct* arrType;
	immutable ConcreteType elementType;
	immutable size_t typeIndex; // order this was inserted into 'arrs'
	MutArr!(immutable Constant[]) constants;
}

private struct PointerTypeAndConstants {
	immutable size_t typeIndex;
	MutArr!(immutable Constant) constants;
}

immutable(AllConstantsConcrete) finishAllConstants(
	ref Alloc alloc,
	scope ref AllConstantsBuilder a,
	ref const AllSymbols allSymbols,
	immutable ConcreteStruct* arrSymStruct,
) {
	immutable Constant staticSymbols = getConstantArr(alloc, a, arrSymStruct, valuesArray(alloc, a.syms));
	immutable ArrTypeAndConstantsConcrete[] arrs =
		mapToArr_mut!(ArrTypeAndConstantsConcrete, immutable ConcreteType, ArrTypeAndConstants)(
			alloc,
			a.arrs,
			(immutable(ConcreteType), ref ArrTypeAndConstants value) =>
				immutable ArrTypeAndConstantsConcrete(
					value.arrType,
					value.elementType,
					moveToArr!(immutable Constant[])(alloc, value.constants)));
	immutable PointerTypeAndConstantsConcrete[] records =
		mapToArr_mut!(
			PointerTypeAndConstantsConcrete,
			immutable ConcreteStruct*,
			PointerTypeAndConstants,
		)(alloc, a.pointers, (immutable ConcreteStruct* key, ref PointerTypeAndConstants value) =>
			immutable PointerTypeAndConstantsConcrete(
				key,
				moveToArr(alloc, value.constants)));
	return immutable AllConstantsConcrete(moveToArr(alloc, a.cStringValues), staticSymbols, arrs, records);
}

ref immutable(Constant) derefConstantPointer(
	return scope ref AllConstantsBuilder a,
	ref immutable Constant.Pointer pointer,
	immutable ConcreteStruct* pointeeType,
) {
	verify(mustGetAt_mut(a.pointers, pointeeType).typeIndex == pointer.typeIndex);
	return mustGetAt_mut(a.pointers, pointeeType).constants[pointer.index];
}

// TODO: this will be used when creating constant records by-ref.
immutable(Constant) getConstantPtr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable ConcreteStruct* pointee,
	ref immutable Constant value,
) {
	PointerTypeAndConstants* d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.pointers, pointee, () =>
		PointerTypeAndConstants(mutDictSize(allConstants.pointers), MutArr!(immutable Constant)())));
	return immutable Constant(immutable Constant.Pointer(d.typeIndex, findOrPush!(immutable Constant)(
		alloc,
		d.constants,
		(ref immutable Constant a) => constantEqual(a, value),
		() => value)));
}

immutable(Constant) getConstantArr(
	ref Alloc alloc,
	scope ref AllConstantsBuilder allConstants,
	immutable ConcreteStruct* arrStruct,
	immutable Constant[] elements,
) {
	if (empty(elements))
		return constantEmptyArr();
	else {
		immutable ConcreteType elementType = only(asInst(arrStruct.source).typeArgs);
		ArrTypeAndConstants* d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.arrs, elementType, () =>
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

private immutable(Constant) getConstantCStrForSym(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	ref const AllSymbols allSymbols,
	immutable Sym value,
) =>
	getConstantCStr(alloc, allConstants, safeCStrOfSym(alloc, allSymbols, value));

immutable(Constant) getConstantCStr(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	immutable SafeCStr value,
) =>
	immutable Constant(getOrAdd!(immutable SafeCStr, immutable Constant.CString)(
		alloc,
		allConstants.cStrings,
		value,
		() {
			immutable size_t index = mutArrSize(allConstants.cStringValues);
			verify(mutDictSize(allConstants.cStrings) == index);
			push(alloc, allConstants.cStringValues, value);
			return immutable Constant.CString(index);
		}));

immutable(Constant) getConstantSym(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	ref const AllSymbols allSymbols,
	immutable Sym value,
) =>
	getOrAdd!(immutable Sym, immutable Constant)(alloc, allConstants.syms, value, () =>
		immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [
			getConstantCStrForSym(alloc, allConstants, allSymbols, value)]))));

private:

immutable(bool) constantArrEqual(ref immutable Constant[] a, ref immutable Constant[] b) =>
	arrEqual!Constant(a, b, (ref immutable Constant x, ref immutable Constant y) =>
		constantEqual(x, y));

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

