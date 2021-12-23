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
	concreteTypeEqual,
	hashConcreteType,
	mustBeNonPointer,
	name,
	PointerTypeAndConstantsConcrete;
import model.constant : Constant, constantEqual;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only;
import util.col.arrUtil : arrEqual, arrLiteral, findIndex_const, map, mapOp;
import util.col.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push, tempAsArr;
import util.col.mutDict :
	getOrAdd,
	mapToArr_mut,
	MutDict,
	mustGetAt_mut,
	mutDictSize,
	MutPtrDict,
	MutSafeCStrDict,
	MutSymDict,
	valuesArray;
import util.col.str : hashSafeCStr, SafeCStr, safeCStrEq;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : hashPtr, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sym : AllSymbols, hashSym, safeCStrOfSym, Sym, symEq;
import util.util : verify;

struct AllConstantsBuilder {
	private:
	@disable this(ref const AllConstantsBuilder);
	MutSafeCStrDict!(immutable Constant.CString) cStrings;
	MutSymDict!(immutable Constant) syms;
	MutArr!(immutable SafeCStr) cStringValues;
	MutDict!(immutable ConcreteType, ArrTypeAndConstants, concreteTypeEqual, hashConcreteType) arrs;
	MutPtrDict!(ConcreteStruct, PointerTypeAndConstants) pointers;
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
	ref const AllSymbols allSymbols,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
	immutable Ptr!ConcreteStruct arrNamedValFunPtrStruct,
	immutable Ptr!ConcreteStruct arrSymStruct,
) {
	immutable Constant allFuns = makeAllFuns(alloc, a, allSymbols, allConcreteFuns, arrNamedValFunPtrStruct);
	immutable Constant staticSyms = getConstantArr(alloc, a, arrSymStruct, valuesArray(alloc, a.syms));
	immutable ArrTypeAndConstantsConcrete[] arrs =
		mapToArr_mut!(
			ArrTypeAndConstantsConcrete,
			immutable ConcreteType,
			ArrTypeAndConstants,
			concreteTypeEqual,
			hashConcreteType,
		)(alloc, a.arrs, (immutable(ConcreteType), ref ArrTypeAndConstants value) =>
			immutable ArrTypeAndConstantsConcrete(
				value.arrType,
				value.elementType,
				moveToArr!(immutable Constant[])(alloc, value.constants)));
	immutable PointerTypeAndConstantsConcrete[] records =
		mapToArr_mut!(
			PointerTypeAndConstantsConcrete,
			immutable Ptr!ConcreteStruct,
			PointerTypeAndConstants,
			ptrEquals!ConcreteStruct,
			hashPtr!ConcreteStruct,
		)(alloc, a.pointers, (immutable Ptr!ConcreteStruct key, ref PointerTypeAndConstants value) =>
			immutable PointerTypeAndConstantsConcrete(
				key,
				moveToArr!(immutable Ptr!Constant)(alloc, value.constants)));
	return immutable AllConstantsConcrete(moveToArr(alloc, a.cStringValues), allFuns, staticSyms, arrs, records);
}

private immutable(Constant) makeAllFuns(
	ref Alloc alloc,
	ref AllConstantsBuilder a,
	ref const AllSymbols allSymbols,
	immutable Ptr!ConcreteFun[] allConcreteFuns,
	immutable Ptr!ConcreteStruct arrNamedValFunPtrStruct,
) {
	return getConstantArr(
		alloc,
		a,
		arrNamedValFunPtrStruct,
		mapOp!Constant(alloc, allConcreteFuns, (ref immutable Ptr!ConcreteFun it) {
			immutable Opt!Sym name = name(it.deref());
			return has(name) && concreteFunWillBecomeNonExternLowFun(it.deref())
				? some(immutable Constant(immutable Constant.Record(arrLiteral!Constant(alloc, [
					getConstantSym(alloc, a, allSymbols, force(name)),
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
	return mutArrAt(mustGetAt_mut(a.pointers, pointeeType).constants, pointer.index).deref();
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
	return immutable Constant(immutable Constant.Pointer(d.deref().typeIndex, findOrPush!(immutable Ptr!Constant)(
		alloc,
		d.deref().constants,
		(ref immutable Ptr!Constant a) =>
			constantEqual(a.deref(), value),
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
		immutable ConcreteType elementType = only(asInst(arrStruct.deref().source).typeArgs);
		Ptr!ArrTypeAndConstants d = ptrTrustMe_mut(getOrAdd(alloc, allConstants.arrs, elementType, () =>
			ArrTypeAndConstants(
				arrStruct,
				elementType,
				mutDictSize(allConstants.arrs), MutArr!(immutable Constant[])())));
		immutable size_t index = findOrPush!(immutable Constant[])(
			alloc,
			d.deref().constants,
			(ref immutable Constant[] it) =>
				constantArrEqual(it, elements),
			() =>
				elements);
		return immutable Constant(immutable Constant.ArrConstant(d.deref().typeIndex, index));
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
	ref immutable ConcreteStruct strStruct,
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
	immutable SafeCStr value,
) {
	return getOrAdd!(immutable SafeCStr, immutable Constant.CString, safeCStrEq, hashSafeCStr)(
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
	ref const AllSymbols allSymbols,
	immutable Sym value,
) {
	return getOrAdd!(immutable Sym, immutable Constant, symEq, hashSym)(
		alloc,
		allConstants.syms,
		value,
		() {
			immutable Constant.CString c =
				getConstantCStr(alloc, allConstants, safeCStrOfSym(alloc, allSymbols, value));
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

