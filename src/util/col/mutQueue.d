module util.col.mutQueue;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements, freeElements;
import util.memory : ensureMemoryClear, initMemory;

struct MutQueue(T) {
	@safe @nogc pure nothrow:

	private:
	T[] inner;
	size_t begin;
	size_t size;

	int opApply(in int delegate(T) @safe @nogc pure nothrow cb) {
		foreach (size_t i; 0 .. size) {
			int res = cb(inner[(begin + i) % inner.length]);
			if (res != 0)
				return res;
		}
		return 0;
	}
}

bool isEmpty(T)(in MutQueue!T a) =>
	a.size == 0;

@trusted void enqueue(T)(ref Alloc alloc, scope ref MutQueue!T a, T value) {
	if (a.size == a.inner.length) {
		size_t newCapacity = a.size == 0 ? 2 : a.size * 2;
		T[] newInner = allocateElements!T(alloc, newCapacity);
		size_t i = 0;
		foreach (T x; a) {
			initMemory(&newInner[i], x);
			i++;
		}
		freeElements(alloc, a.inner);
		a.inner = newInner;
		a.begin = 0;
	}

	assert(a.inner.length > a.size);
	size_t end = (a.begin + a.size) % a.inner.length;
	initMemory(&a.inner[end], value);
	a.size++;
}

@trusted T mustDequeue(T)(scope ref MutQueue!T a) {
	assert(!isEmpty(a));
	T res = a.inner[a.begin];
	ensureMemoryClear(&a.inner[a.begin]);
	a.begin++;
	if (a.begin == a.inner.length)
		a.begin = 0;
	a.size--;
	return res;
}
