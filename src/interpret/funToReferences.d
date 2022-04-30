module interpret.funToReferences;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCodeIndex;
import interpret.extern_ : DynCallSig;
import interpret.generateText : TextIndex;
import model.lowModel : LowFunIndex, LowType;
import util.alloc.alloc : TempAlloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictEach, makeFullIndexDict_mut;
import util.late : Late, lateGet, lateIsSet, lateSet;
import util.memory : allocateMut;
import util.opt : none, Opt, some;

struct FunToReferences {
	immutable FunPtrTypeToDynCallSig funPtrTypeToDynCallSig;
	private:
	FullIndexDict!(LowFunIndex, FunReferencesBuilder) inner;
}

alias FunPtrTypeToDynCallSig = FullIndexDict!(LowType.FunPtr, DynCallSig);

void eachFunPtr(
	scope ref const FunToReferences a,
	scope void delegate(immutable LowFunIndex, immutable DynCallSig) @safe @nogc pure nothrow cb,
) {
	fullIndexDictEach!(LowFunIndex, FunReferencesBuilder)(
		a.inner,
		(immutable LowFunIndex index, ref const FunReferencesBuilder b) {
			if (lateIsSet(b.ptrRefs))
				cb(index, lateGet(b.ptrRefs).sig);
		});
}

struct FunReferences {
	immutable ByteCodeIndex[] calls;
	immutable Opt!FunPtrReferences ptrRefs;
}
struct FunPtrReferences {
	immutable DynCallSig sig;
	immutable ByteCodeIndex[] funPtrRefs;
	immutable TextIndex[] textRefs;
}

FunToReferences initFunToReferences(
	ref TempAlloc tempAlloc,
	return scope immutable FunPtrTypeToDynCallSig funPtrTypeToDynCallSig,
	immutable size_t nLowFuns,
) {
	return FunToReferences(
		funPtrTypeToDynCallSig,
		makeFullIndexDict_mut!(LowFunIndex, FunReferencesBuilder)(tempAlloc, nLowFuns, (immutable(LowFunIndex)) =>
			FunReferencesBuilder()));
}

immutable(FunReferences) finishAt(
	ref TempAlloc tempAlloc,
	ref FunToReferences a,
	immutable LowFunIndex index,
) {
	ref FunReferencesBuilder builder() { return a.inner[index]; }
	immutable ByteCodeIndex[] calls = finishArr(tempAlloc, builder.calls);
	if (lateIsSet(builder.ptrRefs)) {
		FunPtrReferencesBuilder* ptrs = lateGet(builder.ptrRefs);
		return immutable FunReferences(
			calls,
			some(immutable FunPtrReferences(
				ptrs.sig,
				finishArr(tempAlloc, ptrs.funPtrRefs),
				finishArr(tempAlloc, ptrs.textReferences))));
	} else
		return immutable FunReferences(calls, none!FunPtrReferences);
}

void registerCall(
	ref TempAlloc tempAlloc,
	ref FunToReferences a,
	immutable LowFunIndex callee,
	immutable ByteCodeIndex caller,
) {
	add(tempAlloc, a.inner[callee].calls, caller);
}

void registerTextReference(
	ref TempAlloc tempAlloc,
	ref FunToReferences a,
	immutable LowType.FunPtr type,
	immutable LowFunIndex fun,
	immutable TextIndex reference,
) {
	add(tempAlloc, ptrRefs(tempAlloc, a, type, fun).textReferences, reference);
}

void registerFunPtrReference(
	ref TempAlloc tempAlloc,
	scope ref FunToReferences a,
	immutable LowType.FunPtr type,
	immutable LowFunIndex fun,
	immutable ByteCodeIndex reference,
) {
	add(tempAlloc, ptrRefs(tempAlloc, a, type, fun).funPtrRefs, reference);
}

private:

ref FunPtrReferencesBuilder ptrRefs(
	ref TempAlloc tempAlloc,
	return scope ref FunToReferences a,
	immutable LowType.FunPtr type,
	immutable LowFunIndex fun,
) {
	if (!lateIsSet(a.inner[fun].ptrRefs))
		lateSet(a.inner[fun].ptrRefs, allocateMut(tempAlloc, FunPtrReferencesBuilder(
			a.funPtrTypeToDynCallSig[type])));
	return *lateGet(a.inner[fun].ptrRefs);
}

struct FunReferencesBuilder {
	ArrBuilder!ByteCodeIndex calls;
	Late!(FunPtrReferencesBuilder*) ptrRefs;
}

struct FunPtrReferencesBuilder {
	immutable DynCallSig sig;
	ArrBuilder!ByteCodeIndex funPtrRefs; // appearing as a fun-ptr directly in code
	ArrBuilder!TextIndex textReferences; // these are fun ptrs too, that appear in text
}
