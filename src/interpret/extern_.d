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

struct Extern {
	// 'none' if anything failed to load
	immutable(Opt!ExternFunPtrsForAllLibraries) delegate(
		scope immutable ExternLibraries libraries,
		scope WriteError writeError,
	) @safe @nogc nothrow loadExternFunPtrs;
	immutable MakeSyntheticFunPtrs makeSyntheticFunPtrs;
	immutable DoDynCall doDynCall;
}

struct FunPtrInputs {
	immutable LowFunIndex funIndex;
	immutable DynCallSig sig;
	immutable Operation* operationPtr;
}

alias MakeSyntheticFunPtrs =
	immutable(FunPtr[]) delegate(scope immutable FunPtrInputs[] inputs) @safe @nogc pure nothrow;

alias DoDynCall = immutable(ulong) delegate(
	immutable FunPtr,
	scope immutable DynCallSig,
	scope immutable ulong[] args,
) @system @nogc nothrow;

alias WriteError = void delegate(scope immutable SafeCStr) @safe @nogc nothrow;

@trusted void writeSymToCb(scope WriteError writeError, ref const AllSymbols allSymbols, immutable Sym a) {
	immutable char[256] buf = symAsTempBuffer!256(allSymbols, a);
	writeError(immutable SafeCStr(buf.ptr));
}

alias ExternFunPtrsForAllLibraries = Dict!(Sym, ExternFunPtrsForLibrary);
alias ExternFunPtrsForLibrary = Dict!(Sym, FunPtr);

struct FunPtr {
	@safe @nogc pure nothrow:

	immutable void* fn;

	void hash(ref Hasher hasher) scope const {
		hashPtr(hasher, fn);
	}
}

struct DynCallSig {
	@safe @nogc pure nothrow:

	immutable DynCallType[] returnTypeAndParameterTypes;

	immutable(DynCallType) returnType() scope immutable =>
		returnTypeAndParameterTypes[0];

	immutable(DynCallType[]) parameterTypes() return scope immutable =>
		returnTypeAndParameterTypes[1 .. $];
}

// These should all fit in a single stack entry (except 'void')
enum DynCallType : ubyte {
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
