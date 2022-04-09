module interpret.extern_;

@safe @nogc nothrow:

import util.sym : Sym;

struct Extern {
	immutable(FunPtr) delegate(immutable Sym name) @safe @nogc nothrow getExternFunPtr;
	immutable(ulong) delegate(
		immutable(FunPtr) funPtr,
		scope immutable DynCallSig sig,
		scope immutable ulong[] parameters,
	) @system @nogc nothrow doDynCall;
}

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
