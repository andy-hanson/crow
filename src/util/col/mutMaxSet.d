module util.col.mutMaxSet;

@safe @nogc pure nothrow:

import util.col.hashTable :
	deleteFromHashTableAtIndex, getIndexInHashTable, mayDeleteFromHashTable, mustAddToHashTableNoAlloc;
import util.opt : force, has, MutOpt, noneMut, Opt, someMut;
import util.util : castNonScope;

struct MutMaxSet(size_t capacity, T) {
	private:
	size_t size_ = 0;
	size_t lastPoppedArbitrary = 0;
	MutOpt!T[capacity] values;

	public:
	int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) {
		foreach (ref MutOpt!T value; values)
			if (has(value)) {
				int res = cb(force(value));
				if (res != 0)
					return res;
			}
		return 0;
	}
}

void clear(size_t capacity, T)(ref MutMaxSet!(capacity, T) a) {
	while (true) {
		MutOpt!T popped = popArbitrary(a);
		if (!has(popped))
			break;
	}
}

bool has(size_t capacity, T)(in MutMaxSet!(capacity, T) a, T value) {
	Opt!size_t res = getIndexInHashTable!(T, T, id)(castNonScope(a.values), value);
	return .has(res);
}

bool mayAdd(size_t capacity, T)(ref MutMaxSet!(capacity, T) a, T value) {
	if (has(a, value))
		return false;
	else {
		mustAdd(a, value);
		return true;
	}
}

void mustAdd(size_t capacity, T)(ref MutMaxSet!(capacity, T) a, T value) {
	assert(a.size_ < capacity);
	a.size_++;
	mustAddToHashTableNoAlloc!(T, T, id)(a.values, value);
}

bool mayDelete(size_t capacity, T)(ref MutMaxSet!(capacity, T) a, T value) {
	MutOpt!T res = mayDeleteFromHashTable!(T, T, id)(a.values, value);
	if (has(res))
		a.size_--;
	return has(res);
}

MutOpt!T popArbitrary(size_t capacity, T)(ref MutMaxSet!(capacity, T) a) {
	if (a.size_ == 0)
		return noneMut!T;
	else {
		foreach (size_t index; a.lastPoppedArbitrary .. a.values.length)
			if (has(a.values[index])) {
				T res = force(a.values[index]);
				deleteFromHashTableAtIndex!(T, T, id)(a.values, index);
				a.size_--;
				a.lastPoppedArbitrary = index;
				return someMut(res);
			}
		assert(a.lastPoppedArbitrary != 0);
		a.lastPoppedArbitrary = 0;
		return popArbitrary(a);
	}
}

private:

T id(T)(T a) =>
	a;
