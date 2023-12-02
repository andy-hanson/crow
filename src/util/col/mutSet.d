module util.col.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.hashTable : clearAndKeepMemory, HashTable, hasKey, mayAdd, mayDelete, mustAdd, mustDelete, popArbitrary;
import util.opt : has, MutOpt;

struct MutSet(T) {
	private HashTable!(T, T, getKey) inner;

	int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope =>
		inner.opApply(cb);
	int opApply(in int delegate(ref const T) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply(cb);
}

private ref T getKey(T)(ref T x) => x;

void mutSetClearAndKeepMemory(T)(scope ref MutSet!T a) {
	clearAndKeepMemory(a.inner);
}

bool mutSetHas(T)(in MutSet!T a, in T value) =>
	hasKey(a.inner, value);

MutOpt!T mutSetPopArbitrary(T)(ref MutSet!T a) =>
	popArbitrary(a.inner);

void mayAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) {
	mayAdd(alloc, a.inner, value);
}

void mustAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) {
	mustAdd(alloc, a.inner, value);
}

bool mutSetMayDelete(T)(scope ref MutSet!T a, T value) {
	MutOpt!T deleted = mayDelete(a.inner, value);
	return has(deleted);
}

void mutSetMustDelete(T)(scope ref MutSet!T a, T value) {
	mustDelete(a.inner, value);
}
