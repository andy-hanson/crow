module util.col.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.hashTable : getOrAdd, hasKey, mayAdd, mayDelete, MutHashTable;
import util.col.set : Set;
import util.opt : has, MutOpt;

struct MutSet(T) {
	@safe @nogc pure nothrow:
	private MutHashTable!(T, T, getKey) inner;

	MutSet!T move() {
		MutSet!T res = MutSet!T(inner);
		inner = MutHashTable!(T, T, getKey)();
		return res;
	}

	int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope =>
		inner.opApply(cb);
	int opApply(in int delegate(ref const T) @safe @nogc pure nothrow cb) scope const =>
		inner.opApply(cb);
}

private ref T getKey(T)(ref T x) => x;

bool mutSetHas(T)(in MutSet!T a, in T value) =>
	hasKey(a.inner, value);

bool mayAddToMutSet(T)(ref Alloc alloc, scope ref MutSet!T a, T value) =>
	mayAdd(alloc, a.inner, value);

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

void mustSetMustDelete(T)(scope ref MutSet!T a, T value) {
	bool ok = mutSetMayDelete!T(a, value);
	assert(ok);
}
