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
	Opt!ExternPointersForAllLibraries delegate(
		in ExternLibraries libraries,
		scope WriteError writeError,
	) @safe @nogc nothrow loadExternPointers;
	MakeSyntheticFunPointers makeSyntheticFunPointers;
	DoDynCall doDynCall;
}

immutable struct FunPointerInputs {
	LowFunIndex funIndex;
	DynCallSig sig;
	Operation* operationPtr;
}

alias MakeSyntheticFunPointers = immutable FunPointer[] delegate(in FunPointerInputs[] inputs) @safe @nogc pure nothrow;
alias DoDynCall = immutable ulong delegate(FunPointer, in DynCallSig, in ulong[] args) @system @nogc nothrow;
alias WriteError = immutable void delegate(in CString) @safe @nogc nothrow;

@trusted void writeSymbolToCb(scope WriteError writeError, in AllSymbols allSymbols, Symbol a) {
	immutable char[256] buf = symbolAsTempBuffer!256(allSymbols, a);
	writeError(CString(buf.ptr));
}

alias ExternPointersForAllLibraries = Map!(Symbol, ExternPointersForLibrary);
alias ExternPointersForLibrary = Map!(Symbol, ExternPointer);

immutable struct FunPointer {
	@safe @nogc pure nothrow:

	void* pointer;

	HashCode hash() scope =>
		hashPtr(pointer);

	ulong asUlong() =>
		cast(ulong) pointer;

	ExternPointer asExternPointer() =>
		ExternPointer(pointer);
}

// May be a function or variable pointer
immutable struct ExternPointer {
	@safe @nogc pure nothrow:

	void* pointer;

	HashCode hash() scope =>
		hashPtr(pointer);

	ulong asUlong() =>
		cast(ulong) pointer;

	FunPointer asFunPointer() =>
		FunPointer(pointer);
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
