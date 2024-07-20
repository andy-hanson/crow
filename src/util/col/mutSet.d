module util.col.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.hashTable : getOrAdd, hasKey, mayAdd, mayDelete, mustAdd, mustDelete, MutHashTable;
import util.opt : has, MutOpt;

struct MutSet(T) {
	@safe @nogc pure nothrow:
	private MutHashTable!(T, T, getKey) inner;

	MutSet!T move() {
		MutSet!T res = MutSet!T(inner);
		inner = MutHashTable!(T, T, getKey)();
		return res;
	}

	bool opBinaryRight(string op)(in T x) scope const if (op == "in") =>
		hasKey(inner, x);

	int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope =>
		inner.opApply(cb);
	int opApply(in int delegate(ref const T) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply(cb);
}

private ref T getKey(T)(ref T x) => x;

bool mayAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) =>
	mayAdd(alloc, a.inner, value);

void mustAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) {
	mustAdd(alloc, a.inner, value);
}

T getOrAddLazyAlloc(T)(
	ref Alloc alloc,
	ref MutSet!T a,
	in T value,
	in T delegate() @safe @nogc pure nothrow allocValue,
) =>
	getOrAdd!(T, T, getKey)(alloc, a.inner, value, () {
		T res = allocValue();
		assert(res == value);
		return res;
	});

bool mutSetMayDelete(T)(scope ref MutSet!T a, T value) {
	MutOpt!T deleted = mayDelete(a.inner, value);
	return has(deleted);
}

void mutSetMustDelete(T)(scope ref MutSet!T a, T value) {
	mustDelete(a.inner, value);
}
