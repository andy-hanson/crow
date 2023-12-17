module interpret.extern_;

@safe @nogc nothrow:

import interpret.bytecode : Operation;
import model.lowModel : ExternLibraries, LowFunIndex;
import util.col.map : Map;
import util.hash : HashCode, hashPtr;
import util.opt : Opt;
import util.string : CString;
import util.symbol : AllSymbols, Symbol, symbolAsTempBuffer;

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
alias WriteError = immutable void delegate(in CString) @safe @nogc nothrow;

@trusted void writeSymbolToCb(scope WriteError writeError, in AllSymbols allSymbols, Symbol a) {
	immutable char[256] buf = symbolAsTempBuffer!256(allSymbols, a);
	writeError(CString(buf.ptr));
}

alias ExternFunPtrsForAllLibraries = Map!(Symbol, ExternFunPtrsForLibrary);
alias ExternFunPtrsForLibrary = Map!(Symbol, FunPtr);

immutable struct FunPtr {
	@safe @nogc pure nothrow:

	void* fn;

	HashCode hash() scope =>
		hashPtr(fn);
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
