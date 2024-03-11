module util.col.tempSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : withTempArrayUninitialized;
import util.col.array : contains;
import util.memory : initMemory;

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
	withTempArrayUninitialized!(Out, Elem)(maxSize, (scope Elem[] storage) {
		TempSet!Elem set = TempSet!Elem(0, storage);
		return cb(set);
	});
