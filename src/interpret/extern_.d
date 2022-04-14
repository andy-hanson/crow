module interpret.extern_;

@safe @nogc nothrow:

import model.lowModel : ExternLibraries;
import util.col.dict : SymDict;
import util.col.str : SafeCStr;
import util.opt : Opt;
import util.sym : AllSymbols, Sym, symAsTempBuffer;

struct Extern {
	// 'none' if anything failed to load
	immutable(Opt!ExternFunPtrsForAllLibraries) delegate(
		scope immutable ExternLibraries libraries,
		scope WriteError writeError,
	) @safe @nogc nothrow loadExternFunPtrs;
	immutable DoDynCall doDynCall;
}

alias DoDynCall = immutable(ulong) delegate(
	immutable(FunPtr) funPtr,
	scope immutable DynCallSig sig,
	scope immutable ulong[] parameters,
) @system @nogc nothrow;

alias WriteError = void delegate(scope immutable SafeCStr) @safe @nogc nothrow;

@trusted void writeSymToCb(scope WriteError writeError, ref const AllSymbols allSymbols, immutable Sym a) {
	immutable char[256] buf = symAsTempBuffer!256(allSymbols, a);
	writeError(immutable SafeCStr(buf.ptr));
}

alias ExternFunPtrsForAllLibraries = SymDict!(SymDict!FunPtr);
alias ExternFunPtrsForLibrary = SymDict!FunPtr;

alias FunPtr = immutable void*;

struct DynCallSig {
	@safe @nogc pure nothrow:

	immutable DynCallType[] returnTypeAndParameterTypes;

	immutable(DynCallType) returnType() scope immutable {
		return returnTypeAndParameterTypes[0];
	}

	immutable(DynCallType[]) parameterTypes() return scope immutable {
		return returnTypeAndParameterTypes[1 .. $];
	}
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
