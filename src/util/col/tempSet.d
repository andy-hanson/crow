module util.col.tempSet;

@safe @nogc nothrow:

import util.alloc.stackAlloc : withStackArrayUninitialized, withStackArrayUninitialized_impure;
import util.col.array : contains;
import util.memory : initMemory;

@trusted Out withTempSetImpure(Out, Elem)(size_t maxSize, in Out delegate(scope ref TempSet!Elem) @safe @nogc nothrow cb) =>
	withStackArrayUninitialized_impure!(Out, Elem)(maxSize, (scope Elem[] storage) {
		TempSet!Elem set = TempSet!Elem(0, storage);
		return cb(set);
	});

pure:

struct TempSet(T) {
	@safe @nogc pure nothrow:
	private size_t size;
	private T[] storage;

	bool has(T value) => // TODO: inconsistent to have this instance and 'tryAdd' a function ......................................
		contains(storage[0 .. size], value);
}

bool tryAdd(T)(scope ref TempSet!T a, T value) {
	if (a.has(value))
		return false;
	else {
		mustAdd(a, value);
		return true;
	}
}

void mustAdd(T)(scope ref TempSet!T a, T value) {
	assert(!a.has(value));
	assert(a.size <= a.storage.length);
	initMemory(&a.storage[a.size], value);
	a.size++;
}

@trusted Out withTempSet(Out, Elem)(
	size_t maxSize,
	in Out delegate(scope ref TempSet!Elem) @safe @nogc pure nothrow cb,
) =>
	withStackArrayUninitialized!(Out, Elem)(maxSize, (scope Elem[] storage) {
		TempSet!Elem set = TempSet!Elem(0, storage);
		return cb(set);
	});
