module util.collection.mutMaxArr;

@safe @nogc pure nothrow:

import util.memory : overwriteMemory;
import util.util : verify;

struct MutMaxArr(size_t maxSize, T) {
	private:
	size_t size_;
	T[maxSize] values = void;
}

immutable(bool) isEmpty(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	return a.size_ == 0;
}

immutable(size_t) mutMaxArrSize(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	return a.size_;
}

@trusted MutMaxArr!(maxSize, T) mutMaxArr(size_t maxSize, T)() {
	return MutMaxArr!(maxSize, T)();
}

void push(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a, T value) {
	verify(a.size_ != maxSize);
	overwriteMemory(&a.values[a.size_], value);
	a.size_++;
}

T mustPop(size_t maxSize, T)(ref MutMaxArr!(maxSize, T) a) {
	verify(a.size_ != 0);
	a.size_--;
	return a.values[a.size_];
}

ref const(T) only_const(size_t maxSize, T)(ref const MutMaxArr!(maxSize, T) a) {
	verify(a.size_ == 1);
	return a.values[0];
}

@trusted T[] tempAsArr_mut(size_t maxSize, T)(return ref MutMaxArr!(maxSize, T) a) {
	return a.values[0 .. a.size_];
}
@trusted const(T[]) tempAsArr_const(size_t maxSize, T)(return ref const MutMaxArr!(maxSize, T) a) {
	return a.values[0 .. a.size_];
}

void filterUnordered(size_t maxSize, T)(
	ref MutMaxArr!(maxSize, T) a,
	scope immutable(bool) delegate(ref T) @safe @nogc pure nothrow pred,
) {
	size_t i = 0;
	while (i < a.size_) {
		if (pred(a.values[i]))
			i++;
		else {
			a.size_--;
			overwriteMemory(&a.values[i], a.values[a.size_]);
		}
	}
}
