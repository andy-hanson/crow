module interpret.extern_;

@safe @nogc nothrow:

import util.ptr : Ptr;
import util.sym : Sym;

struct Extern {
	immutable(int) delegate(immutable int clockId, Ptr!TimeSpec tp) @safe @nogc nothrow clockGetTime;
	void delegate(ubyte*) @system @nogc nothrow free;
	ubyte* delegate(immutable size_t) @system @nogc nothrow malloc;
	immutable(long) delegate(
		immutable int fd,
		immutable char* buf,
		immutable size_t nBytes,
	) @system @nogc nothrow write;
	immutable(ulong) delegate(
		immutable Sym name,
		immutable DynCallType returnType,
		scope immutable ulong[] parameters,
		scope immutable DynCallType[] parameterTypes,
	) @system @nogc nothrow doDynCall;
}

struct TimeSpec {
	long tv_sec;
	long tv_nsec;
}

// These should all fit in a single stack entry (except 'void')
enum DynCallType : ubyte {
	bool_,
	char_,
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
