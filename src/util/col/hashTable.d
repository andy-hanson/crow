module util.col.hashTable;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements, freeElements;
import util.col.arr : empty, endPtr;
import util.col.arrUtil : fillArr_mut, mapToMut;
import util.col.map : Map;
import util.hash : getHash;
import util.memory : initMemory, overwriteMemory;
import util.opt : ConstOpt, force, has, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.col.str : strEq;
import util.util : drop, unreachable;

import core.stdc.stdio : printf;

// Intended for implementing other collections. Don't use directly.
// 'K' is be a subset of 'T' used for comparisons.
struct HashTable(T, K, alias getKey) {
	@safe @nogc pure nothrow:

	private:
	size_t size_;
	MutOpt!T[] values;

	public:
	Opt!T opIndex(in K key) immutable {
		Opt!size_t i = getIndex(this, key);
		return has(i) ? some!T(force(values[force(i)])) : none!T;
	}
	ConstOpt!T opIndex(in K key) const {
		Opt!size_t i = getIndex(this, key);
		return has(i) ? someConst!T(force(values[force(i)])) : noneMut!T;
	}
	MutOpt!T opIndex(in K key) {
		Opt!size_t i = getIndex(this, key);
		return has(i) ? someMut!T(force(values[force(i)])) : noneMut!T;
	}

	int opApply(in int delegate(ref immutable T) @safe @nogc pure nothrow cb) scope immutable {
		foreach (ref immutable MutOpt!T value; values)
			if (has(value)) {
				int res = cb(force(value));
				if (res != 0)
					return res;
			}
		return 0;
	}
	int opApply(in int delegate(ref const T) @safe @nogc pure nothrow cb) scope const {
		foreach (ref const MutOpt!T value; values)
			if (has(value)) {
				int res = cb(force(value));
				if (res != 0)
					return res;
			}
		return 0;
	}
	int opApply(in int delegate(ref T) @safe @nogc pure nothrow cb) scope {
		foreach (ref MutOpt!T value; values)
			if (has(value)) {
				int res = cb(force(value));
				if (res != 0)
					return res;
			}
		return 0;
	}
}

void clearAndKeepMemory(T, K, alias getKey)(scope ref HashTable!(T, K, getKey) a) {
	a.size_ = 0;
	foreach (ref MutOpt!T x; a.values)
		overwriteMemory(&x, noneMut!T);
}

@trusted void clearAndFreeMemory(T, K, alias getKey)(ref Alloc alloc, ref HashTable!(T, K, getKey) a) {
	a.size_ = 0;
	freeElements(alloc, a.values);
	a.values = [];
}

bool isEmpty(T, K, alias getKey)(in HashTable!(T, K, getKey) a) =>
	size(a) == 0;

size_t size(T, K, alias getKey)(in HashTable!(T, K, getKey) a) =>
	a.size_;

bool hasKey(T, K, alias getKey)(in HashTable!(T, K, getKey) a, in K key) =>
	has(getIndex(a, key));

ref inout(T) mustGet(T, K, alias getKey)(ref inout HashTable!(T, K, getKey) a, in K key) =>
	force(a.values[mustGetIndex(a, key)]);

struct ValueAndDidAdd(T) {
	T value;
	bool didAdd;
}

ValueAndDidAdd!(T) getOrAddAndDidAdd(T, K, alias getKey)(
	ref Alloc alloc,
	ref HashTable!(T, K, getKey) a,
	in K key,
	in T delegate() @safe @nogc pure nothrow cb,
) {
	size_t sizeBefore = a.size_;
	T res = getOrAdd(alloc, a, key, cb);
	return ValueAndDidAdd!T(res, a.size_ != sizeBefore);
}

void mayAdd(T, K, alias getKey)(ref Alloc alloc, scope ref HashTable!(T, K, getKey) a, T value) {
	getOrAdd(alloc, a, getKey(value), () => value);
}

ref T mustAdd(T, K, alias getKey)(ref Alloc alloc, return scope ref HashTable!(T, K, getKey) a, T value) {
	if (shouldExpandBeforeAdd(a))
		doExpand(alloc, a);
	assert(a.size_ < a.values.length);

	K key = getKey(value);
	size_t i = getHash!K(key).hashCode % a.values.length;
	while (true) {
		if (!has(a.values[i])) {
			a.size_++;
			overwriteMemory(&a.values[i], someMut!T(value));
			validate("after add", a);
			return force(a.values[i]);
		} else {
			assert(!eq!K(key, getKey(force(a.values[i]))));
			i = nextI(a, i);
		}
	}
}

ref T getOrAdd(T, K, alias getKey)(
	ref Alloc alloc,
	return scope ref HashTable!(T, K, getKey) a,
	in K key,
	in T delegate() @safe @nogc pure nothrow cb,
) {
	Opt!size_t i = getIndex(a, key);
	if (has(i))
		return force(a.values[force(i)]);
	else {
		T value = cb();
		assert(getKey(value) == key);
		return mustAdd(alloc, a, value);
	}
}

ref T insertOrUpdate(T, K, alias getKey)(
	ref Alloc alloc,
	ref HashTable!(T, K, getKey) a,
	in K key,
	in T delegate() @safe @nogc pure nothrow cbInsert,
	in T delegate(ref T) @safe @nogc pure nothrow cbUpdate,
) {
	Opt!size_t i = getIndex(a, key);
	if (has(i)) {
		T newValue = cbUpdate(force(a.values[force(i)]));
		assert(getKey(newValue) == key);
		overwriteMemory(&a.values[force(i)], someMut(newValue));
		validate("after update", a);
		return force(a.values[force(i)]);
	} else {
		T value = cbInsert();
		assert(getKey(value) == key);
		return mustAdd(alloc, a, value);
	}
}

MutOpt!T mayDelete(T, K, alias getKey)(ref HashTable!(T, K, getKey) a, in K key) {
	Opt!size_t index = getIndex(a, key);
	return has(index) ? someMut(deleteAtIndex(a, force(index))) : noneMut!T;
}

T mustDelete(T, K, alias getKey)(ref HashTable!(T, K, getKey) a, in K key) =>
	deleteAtIndex(a, mustGetIndex(a, key));

MutOpt!T popArbitrary(T, K, alias getKey)(ref HashTable!(T, K, getKey) a) {
	foreach (size_t index, ref MutOpt!T x; a.values)
		if (has(x)) {
			T res = force(x);
			deleteAtIndex(a, index);
			return someMut(res);
		}
	return noneMut!T;
}

@trusted Out[] mapToArray(Out, T, K, alias getKey)(
	ref Alloc alloc,
	scope ref immutable HashTable!(T, K, getKey) a,
	in Out delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.size_);
	size_t i = 0;
	foreach (ref immutable T x; a) {
		initMemory(&res[i], cb(x));
		i++;
	}
	assert(i == res.length);
	return res;
}
@trusted Out[] mapToArray(Out, T, K, alias getKey)(
	ref Alloc alloc,
	scope ref const HashTable!(T, K, getKey) a,
	in Out delegate(ref const T) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.size_);
	size_t i = 0;
	foreach (ref const T x; a) {
		initMemory(&res[i], cb(x));
		i++;
	}
	assert(i == res.length);
	return res;
}
@trusted Out[] mapToArray(Out, T, K, alias getKey)(
	ref Alloc alloc,
	scope ref HashTable!(T, K, getKey) a,
	in Out delegate(ref T) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.size_);
	size_t i = 0;
	foreach (ref T x; a) {
		initMemory(&res[i], cb(x));
		i++;
	}
	assert(i == res.length);
	return res;
}

HashTable!(Out, K, getKeyOut) mapPreservingKeys(Out, alias getKeyOut, In, K, alias getKey)(
	ref Alloc alloc,
	scope ref HashTable!(In, K, getKey) a,
	in Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	MutOpt!Out[] outValues = mapToMut!(MutOpt!Out, MutOpt!In)(alloc, a.values, (ref MutOpt!In value) {
		if (has(value)) {
			Out out_ = cb(force(value));
			assert(eq!K(getKeyOut(out_), getKey(force(value))));
			return someMut(out_);
		} else
			return noneMut!Out;
	});
	return HashTable!(Out, K, getKeyOut)(a.size_, outValues);
}

private:

string typeName(T)() {
	static if (is(T == P*, P)) {
		static immutable string res = typeName!P ~ "*";
		return res;
	} else static if (is(T == immutable void))
		return "void";
	else static if (is(T == immutable string))
		return "string";
	else static if (is(T == ulong))
		return "ulong";
	else
		return __traits(identifier, T);
}

// Pointer is temporary (only valid until next operation)
T* getOrAddPtr(T, K, alias getKey)(
	ref Alloc alloc,
	return scope ref HashTable!(T, K, getKey) a,
	in K key,
	in T delegate() @safe @nogc pure nothrow cb,
) {
	Opt!size_t i = getIndex(a, key);
	if (has(i))
		return &a.values[force(i)];
	else {
		T value = cb();
		assert(getKey(value) == key);
		mustAdd(alloc, a, value);
	}
}

size_t mustGetIndex(T, K, alias getKey)(in HashTable!(T, K, getKey) a, in K key) {
	Opt!size_t res = getIndex(a, key);
	return force(res);
}

Opt!size_t getIndex(T, K, alias getKey)(in HashTable!(T, K, getKey) a, in K key) {
	if (empty(a.values))
		return none!size_t;

	size_t startI = getHash!K(key).hashCode % a.values.length;
	size_t i = startI;
	size_t nIters = 0;
	while (true) {
		nIters++;
		if (nIters >= 200) {
			debug {
				printf("LONG RUN AT INDEX %lu\n", i);
			}
			validate("before crash", a, true);
			assert(false);
		}
		if (!has(a.values[i]))
			return none!size_t;
		else if (eq!K(key, getKey(force(a.values[i]))))
			return some(i);
		else {
			i = nextI(a, i);
			if (i == startI)
				return none!size_t;
		}
	}
}

bool shouldExpandBeforeAdd(T, K, alias getKey)(in HashTable!(T, K, getKey) a) =>
	// For small maps, only expand if there is no empty space.
	// For large maps, aim to be 3/4 full.
	a.size_ <= 8
		? a.size_ == a.values.length
		: a.size_ * 4 / 3 >= a.values.length;

@trusted void doExpand(T, K, alias getKey)(ref Alloc alloc, scope ref HashTable!(T, K, getKey) a) {
	immutable size_t newCapacity = a.values.length < 2 ? 2 : a.values.length * 2;
	HashTable!(T, K, getKey) bigger = HashTable!(T, K, getKey)(
		0, fillArr_mut!(MutOpt!T)(alloc, newCapacity, (size_t _) => noneMut!T));
	foreach (ref T x; a)
		mustAdd(alloc, bigger, x);
	freeElements(alloc, a.values);
	a.values = bigger.values;
	validate("after expand", a);
}

T deleteAtIndex(T, K, alias getKey)(scope ref HashTable!(T, K, getKey) a, size_t i) {
	T res = force(a.values[i]);
	a.size_--;

	// When there is a hole, move values closer to where they should be.
	size_t holeI = i;
	overwriteMemory(&a.values[holeI], noneMut!T);
	size_t fromI = nextI(a, i);
	while (has(a.values[fromI])) {
		size_t desiredI = getHash!K(getKey(force(a.values[fromI]))).hashCode % a.values.length;
		if (walkDistance(a, desiredI, holeI) < walkDistance(a, desiredI, fromI)) {
			overwriteMemory(&a.values[holeI], a.values[fromI]);
			overwriteMemory(&a.values[fromI], noneMut!T);
			holeI = fromI;
		}
		fromI = nextI(a, fromI);
	}

	validate("after delete", a);
	return res;
}

//TODO:KILL (PERF)
void validate(T, K, alias getKey)(immutable char* desc, in HashTable!(T, K, getKey) a, bool alwaysLog = false) {
	//debug printf("top of validate: size is %lu, capacity is %lu\n",
	//	a.size_,
	//	a.values.length);
	size_t size = 0;
	foreach (size_t i, ref const MutOpt!T x; a.values) {
		if (has(x)) {
			const K key = getKey(force(x));
			size_t actualIndex = mustGetIndex(a, key);
			if (actualIndex != i) {
				debug {
					printf(
						"at index %lu, hash is %lu, hash index is %lu\n",
						i, getHash!K(key).hashCode, getHash!K(key).hashCode % a.values.length);
				}
				debug {
					printf("got index: %lu, expected: %lu\n",
						mustGetIndex(a, key),
						i);
					printf(
						"got pointer: %p, expected: %p\n",
						&mustGet(a, key),
						&force(x));
				}
			}
			assert(mustGetIndex(a, key) == i);
			assert(&mustGet(a, key) == &force(x));
			size++;
		}
	}
	debug {
		if (alwaysLog || a.size_ != size) {
			string s = typeName!K;
			printf("validate %p %s\n", &a, desc);
			printf("Map key type is %.*s\n", cast(int) s.length, s.ptr);
			string s2 = typeName!T;
			printf("Map type is %.*s\n", cast(int) s2.length, s2.ptr);		
			printf("Map capacity is %lu\n", a.values.length);
			foreach (size_t i, ref const MutOpt!T x; a.values) {
				printf("at %lu: ", i);
				if (has(x))
					printf("hash is %lx\n", getHash!K(getKey(force(x))).hashCode);
				else
					printf("nothing\n");
			}
		}
	}
	assert(a.size_ == size);
}

size_t nextI(T, K, alias getKey)(in HashTable!(T, K, getKey) a, size_t i) {
	size_t res = i + 1;
	return res == a.values.length ? 0 : res;
}

size_t walkDistance(T, K, alias getKey)(in HashTable!(T, K, getKey) a, size_t i0, size_t i1) =>
	i0 <= i1
		? i1 - i0
		: a.values.length + i1 - i0;

bool eq(K)(in K a, in K b) {
	static if (is(K == string))
		return strEq(a, b);
	else
		return a == b;
}
