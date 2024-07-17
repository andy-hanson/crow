module util.col.set;

@safe @nogc pure nothrow:

import util.col.mutSet : MutSet, mutSetHas;

immutable struct Set(T) {
	private MutSet!(T) inner;

	bool has(in T value) =>
		mutSetHas(inner, value);

	int opApply(in int delegate(ref immutable T) @safe @nogc pure nothrow cb) scope =>
		inner.opApply(cb);
}

@trusted Set!T moveToSet(T)(ref MutSet!T a) =>
	Set!T(cast(immutable) a.move());
