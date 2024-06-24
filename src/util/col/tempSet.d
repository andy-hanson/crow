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
	private:
	size_t size;
	T[] storage;
}

bool tryAdd(T)(scope ref TempSet!T a, T value) {
	if (contains(a.storage[0 .. a.size], value))
		return false;
	else {
		initMemory(&a.storage[a.size], value);
		a.size++;
		return true;
	}
}

@trusted Out withTempSet(Out, Elem)(
	size_t maxSize,
	in Out delegate(scope ref TempSet!Elem) @safe @nogc pure nothrow cb,
) =>
	withStackArrayUninitialized!(Out, Elem)(maxSize, (scope Elem[] storage) {
		TempSet!Elem set = TempSet!Elem(0, storage);
		return cb(set);
	});
