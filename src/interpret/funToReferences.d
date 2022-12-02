module interpret.funToReferences;

@safe @nogc pure nothrow:

import interpret.bytecode : ByteCodeIndex;
import interpret.extern_ : DynCallSig;
import interpret.generateText : TextIndex;
import model.lowModel : LowFunIndex, LowType;
import util.alloc.alloc : TempAlloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.fullIndexDict : FullIndexDict, fullIndexDictEach_const, makeFullIndexDict_mut;
import util.memory : allocate;
import util.opt : force, has, MutOpt, none, some, someMut;
import util.ptr : castNonScope_ref;

struct FunToReferences {
	immutable FunPtrTypeToDynCallSig funPtrTypeToDynCallSig;
	private:
	FullIndexDict!(LowFunIndex, FunReferencesBuilder) inner;
}

alias FunPtrTypeToDynCallSig = immutable FullIndexDict!(LowType.FunPtr, DynCallSig);

void eachFunPtr(
	in FunToReferences a,
	in void delegate(LowFunIndex, DynCallSig) @safe @nogc pure nothrow cb,
) {
	fullIndexDictEach_const!(LowFunIndex, FunReferencesBuilder)(
		a.inner,
		(LowFunIndex index, ref const FunReferencesBuilder b) {
			if (has(b.ptrRefs))
				cb(index, force(b.ptrRefs).sig);
		});
}

immutable struct FunReferences {
	ByteCodeIndex[] calls;
	MutOpt!FunPtrReferences ptrRefs;
}
immutable struct FunPtrReferences {
	DynCallSig sig;
	ByteCodeIndex[] funPtrRefs;
	TextIndex[] textRefs;
}

FunToReferences initFunToReferences(
	ref TempAlloc tempAlloc,
	return scope FunPtrTypeToDynCallSig funPtrTypeToDynCallSig,
	size_t nLowFuns,
) =>
	FunToReferences(
		funPtrTypeToDynCallSig,
		makeFullIndexDict_mut!(LowFunIndex, FunReferencesBuilder)(tempAlloc, nLowFuns, (LowFunIndex _) =>
			FunReferencesBuilder()));

FunReferences finishAt(ref TempAlloc tempAlloc, ref FunToReferences a, LowFunIndex index) {
	ref FunReferencesBuilder builder() { return a.inner[index]; }
	ByteCodeIndex[] calls = finishArr(tempAlloc, builder.calls);
	if (has(builder.ptrRefs)) {
		FunPtrReferencesBuilder* ptrs = force(builder.ptrRefs);
		return FunReferences(
			calls,
			some(FunPtrReferences(
				ptrs.sig,
				finishArr(tempAlloc, ptrs.funPtrRefs),
				finishArr(tempAlloc, ptrs.textReferences))));
	} else
		return FunReferences(calls, none!FunPtrReferences);
}

void registerCall(ref TempAlloc tempAlloc, ref FunToReferences a, LowFunIndex callee, ByteCodeIndex caller) {
	add(tempAlloc, a.inner[callee].calls, caller);
}

void registerTextReference(
	ref TempAlloc tempAlloc,
	ref FunToReferences a,
	LowType.FunPtr type,
	LowFunIndex fun,
	TextIndex reference,
) {
	add(tempAlloc, ptrRefs(tempAlloc, a, type, fun).textReferences, reference);
}

void registerFunPtrReference(
	ref TempAlloc tempAlloc,
	scope ref FunToReferences a,
	in LowType.FunPtr type,
	LowFunIndex fun,
	ByteCodeIndex reference,
) {
	add(tempAlloc, ptrRefs(tempAlloc, a, type, fun).funPtrRefs, reference);
}

private:

ref FunPtrReferencesBuilder ptrRefs(
	ref TempAlloc tempAlloc,
	return scope ref FunToReferences a,
	in LowType.FunPtr type,
	LowFunIndex fun,
) {
	if (!has(a.inner[fun].ptrRefs))
		a.inner[fun].ptrRefs = someMut(allocate(tempAlloc, FunPtrReferencesBuilder(
			castNonScope_ref(a).funPtrTypeToDynCallSig[type])));
	return *force(a.inner[fun].ptrRefs);
}

struct FunReferencesBuilder {
	ArrBuilder!ByteCodeIndex calls;
	MutOpt!(FunPtrReferencesBuilder*) ptrRefs;
}

struct FunPtrReferencesBuilder {
	immutable DynCallSig sig;
	ArrBuilder!ByteCodeIndex funPtrRefs; // appearing as a fun-pointer directly in code
	ArrBuilder!TextIndex textReferences; // these are fun ptrs too, that appear in text
}
