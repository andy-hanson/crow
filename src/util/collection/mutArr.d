module util.collection.mutArr;

@safe @nogc pure nothrow:

import core.stdc.string : memcpy;

import util.memory : myEmplace;

struct MutArr(T, Allocator) {
	private:
	Allocator allocator;
	T* begin;
	immutable size_t size;
	immutable size_t capacity;
}

void push(T)(ref MutArr!T m, T value) {
	if (m.size == m.capacity) {
		immutable size_t newCapacity = m.size == 0 ? 2 : m.size * 2;
		T* newBegin = cast(T*) allocator.allocate(newCapacity * T.sizeof);
		memcpy(newBegin, m.begin, size * T.sizeof);
		allocator.free(m.begin, size * T.sizeof);
		m.begin = newBegin;
	}

	myEmplace(m.begin + m.size, value);
	m.size++;
	assert(size <= m.capacity);
}

T[] range(T)(ref const MutArr!T m) {
	return m.begin[0..m.size];
}
