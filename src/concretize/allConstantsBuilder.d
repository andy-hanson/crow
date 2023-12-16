module concretize.allConstantsBuilder;

@safe @nogc pure nothrow:

import model.concreteModel :
	AllConstantsConcrete,
	ArrTypeAndConstantsConcrete,
	ConcreteStruct,
	ConcreteStructSource,
	ConcreteType,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant, constantZero;
import util.alloc.alloc : Alloc;
import util.col.array : arraysEqual, fillArray, findIndex, isEmpty, newArray, only;
import util.col.mutArr : moveToArr, MutArr, mutArrSize, push, tempAsArr;
import util.col.mutMap : getOrAdd, MutMap, size, values, valuesArray;
import util.memory : initMemory;
import util.opt : force, has, Opt;
import util.string : CString;
import util.symbol : AllSymbols, cStringOfSymbol, Symbol;
import util.util : ptrTrustMe;

struct AllConstantsBuilder {
	private:
	@disable this(ref const AllConstantsBuilder);
	MutMap!(CString, Constant.CString) cStrings;
	MutMap!(Symbol, Constant) syms;
	MutArr!CString cStringValues;
	MutMap!(ConcreteType, ArrTypeAndConstants) arrs;
	MutMap!(ConcreteStruct*, PointerTypeAndConstants) pointers;
}

private struct ArrTypeAndConstants {
	immutable ConcreteStruct* arrType;
	immutable ConcreteType elementType;
	immutable size_t typeIndex; // order this was inserted into 'arrs'
	MutArr!(immutable Constant[]) constants;
}

private struct PointerTypeAndConstants {
	immutable size_t typeIndex;
	MutArr!Constant constants;
}

AllConstantsConcrete finishAllConstants(
	ref Alloc alloc,
	scope ref AllConstantsBuilder a,
	ConcreteStruct* arrSymStruct,
) {
	Constant staticSymbols = getConstantArr(alloc, a, arrSymStruct, valuesArray(alloc, a.syms));

	ArrTypeAndConstantsConcrete[] arrays = fillArray!ArrTypeAndConstantsConcrete(
		alloc, size(a.arrs), ArrTypeAndConstantsConcrete(null));
	foreach (ArrTypeAndConstants x; values(a.arrs))
		initMemory(&arrays[x.typeIndex], ArrTypeAndConstantsConcrete(
			x.arrType,
			x.elementType,
			moveToArr!(immutable Constant[])(alloc, x.constants)));

	PointerTypeAndConstantsConcrete[] pointers = fillArray!PointerTypeAndConstantsConcrete(
		alloc, size(a.pointers), PointerTypeAndConstantsConcrete(null));
	foreach (ConcreteStruct* pointerType, PointerTypeAndConstants x; a.pointers)
		initMemory(&pointers[x.typeIndex], PointerTypeAndConstantsConcrete(pointerType, moveToArr(alloc, x.constants)));

	return AllConstantsConcrete(moveToArr(alloc, a.cStringValues), staticSymbols, arrays, pointers);
}

// TODO: this will be used when creating constant records by-ref.
Constant getConstantPtr(ref Alloc alloc, ref AllConstantsBuilder constants, ConcreteStruct* pointee, Constant value) {
	PointerTypeAndConstants* d = ptrTrustMe(getOrAdd(alloc, constants.pointers, pointee, () =>
		PointerTypeAndConstants(size(constants.pointers), MutArr!(immutable Constant)())));
	return Constant(Constant.Pointer(
		d.typeIndex,
		findOrPush!Constant(alloc, d.constants, (in Constant a) => a == value, () => value)));
}

Constant getConstantArr(
	ref Alloc alloc,
	scope ref AllConstantsBuilder allConstants,
	ConcreteStruct* arrStruct,
	// TODO:PERF take this 'in', only allocate if necessary.
	Constant[] elements,
) {
	if (isEmpty(elements))
		return constantEmptyArr();
	else {
		ConcreteType elementType = only(arrStruct.source.as!(ConcreteStructSource.Inst).typeArgs);
		ArrTypeAndConstants* d = ptrTrustMe(getOrAdd(alloc, allConstants.arrs, elementType, () =>
			ArrTypeAndConstants(
				arrStruct,
				elementType,
				size(allConstants.arrs), MutArr!(immutable Constant[])())));
		size_t index = findOrPush!(immutable Constant[])(
			alloc,
			d.constants,
			(in Constant[] it) => arraysEqual!Constant(it, elements),
			() => elements);
		return Constant(Constant.ArrConstant(d.typeIndex, index));
	}
}

private Constant constantEmptyArr() {
	static Constant[2] fields = [Constant(Constant.Integral(0)), constantZero];
	return Constant(Constant.Record(fields));
}

private Constant getConstantCStrForSym(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	ref const AllSymbols allSymbols,
	Symbol value,
) =>
	getConstantCStr(alloc, allConstants, cStringOfSymbol(alloc, allSymbols, value));

Constant getConstantCStr(ref Alloc alloc, ref AllConstantsBuilder allConstants, CString value) =>
	Constant(getOrAdd!(CString, Constant.CString)(
		alloc,
		allConstants.cStrings,
		value,
		() {
			size_t index = mutArrSize(allConstants.cStringValues);
			assert(size(allConstants.cStrings) == index);
			push(alloc, allConstants.cStringValues, value);
			return Constant.CString(index);
		}));

Constant getConstantSym(
	ref Alloc alloc,
	ref AllConstantsBuilder allConstants,
	ref const AllSymbols allSymbols,
	Symbol value,
) =>
	getOrAdd!(Symbol, Constant)(alloc, allConstants.syms, value, () =>
		Constant(Constant.Record(newArray!Constant(alloc, [
			getConstantCStrForSym(alloc, allConstants, allSymbols, value)]))));

private:

size_t findOrPush(T)(
	ref Alloc alloc,
	ref MutArr!T a,
	in bool delegate(in T) @safe @nogc pure nothrow cbFind,
	in T delegate() @safe @nogc pure nothrow cbPush,
) {
	Opt!size_t res = findIndex!T(tempAsArr(a), cbFind);
	if (has(res))
		return force(res);
	else {
		push(alloc, a, cbPush());
		return mutArrSize(a) - 1;
	}
}
