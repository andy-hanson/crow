module interpret.extern_;

@safe @nogc nothrow:

import util.sym : Sym;

struct Extern {
	void delegate(ubyte*) @system @nogc nothrow free;
	ubyte* delegate(immutable size_t) @system @nogc nothrow malloc;
	immutable(long) delegate(
		immutable int fd,
		immutable char* buf,
		immutable size_t nBytes,
	) @system @nogc nothrow write;
	immutable(FunPtr) delegate(immutable Sym name) @safe @nogc nothrow getExternFunPtr;
	immutable(ulong) delegate(
		immutable(FunPtr) funPtr,
		immutable DynCallType returnType,
		scope immutable ulong[] parameters,
		scope immutable DynCallType[] parameterTypes,
	) @system @nogc nothrow doDynCall;
}

alias FunPtr = immutable void*;

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
