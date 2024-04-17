module util.col.set;

@safe @nogc pure nothrow:

import util.col.mutSet : MutSet, mutSetHas;

immutable struct Set(T) {
	private MutSet!(T) inner;

	bool has(in T value) =>
		mutSetHas(inner, value);
}
