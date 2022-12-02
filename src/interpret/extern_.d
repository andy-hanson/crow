module interpret.extern_;

@safe @nogc nothrow:

import interpret.bytecode : Operation;
import model.lowModel : ExternLibraries, LowFunIndex;
import util.col.dict : Dict;
import util.col.str : SafeCStr;
import util.hash : Hasher;
import util.opt : Opt;
import util.ptr : hashPtr;
import util.sym : AllSymbols, Sym, symAsTempBuffer;

immutable struct Extern {
	// 'none' if anything failed to load
	Opt!ExternFunPtrsForAllLibraries delegate(
		in ExternLibraries libraries,
		scope WriteError writeError,
	) @safe @nogc nothrow loadExternFunPtrs;
	MakeSyntheticFunPtrs makeSyntheticFunPtrs;
	DoDynCall doDynCall;
}

immutable struct FunPtrInputs {
	LowFunIndex funIndex;
	DynCallSig sig;
	Operation* operationPtr;
}

alias MakeSyntheticFunPtrs = immutable FunPtr[] delegate(in FunPtrInputs[] inputs) @safe @nogc pure nothrow;
alias DoDynCall = immutable ulong delegate(FunPtr, in DynCallSig, in ulong[] args) @system @nogc nothrow;
alias WriteError = immutable void delegate(in SafeCStr) @safe @nogc nothrow;

@trusted void writeSymToCb(scope WriteError writeError, in AllSymbols allSymbols, Sym a) {
	immutable char[256] buf = symAsTempBuffer!256(allSymbols, a);
	writeError(SafeCStr(buf.ptr));
}

alias ExternFunPtrsForAllLibraries = Dict!(Sym, ExternFunPtrsForLibrary);
alias ExternFunPtrsForLibrary = Dict!(Sym, FunPtr);

immutable struct FunPtr {
	@safe @nogc pure nothrow:

	void* fn;

	void hash(ref Hasher hasher) scope {
		hashPtr(hasher, fn);
	}
}

immutable struct DynCallSig {
	@safe @nogc pure nothrow:

	DynCallType[] returnTypeAndParameterTypes;

	DynCallType returnType() scope =>
		returnTypeAndParameterTypes[0];

	DynCallType[] parameterTypes() return scope =>
		returnTypeAndParameterTypes[1 .. $];
}

// These should all fit in a single stack entry (except 'void')
alias DynCallType = immutable DynCallType_;
private enum DynCallType_ : ubyte {
	bool_,
	char8,
	int8,
	int16,
	int32,
	int64,
	float32,
	float64,
	nat8,
	nat16,
	nat32,
	nat64,
	pointer,
	void_,
}
