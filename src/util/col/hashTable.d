module util.col.hashTable;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements, freeElements;
import util.col.arr : arrayOfRange, empty, endPtr;
import util.col.arrUtil : fillArray, map;
import util.hash : getHash;
import util.memory : initMemory, overwriteMemory;
import util.opt : ConstOpt, force, has, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.col.str : strEq;

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

bool mayAdd(T, K, alias getKey)(ref Alloc alloc, scope ref HashTable!(T, K, getKey) a, T value) =>
	getOrAddAndDidAdd(alloc, a, getKey(value), () => value).didAdd;

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

@trusted immutable(HashTable!(T, K, getKey)) moveToImmutable(T, K, alias getKey)(ref HashTable!(T, K, getKey) a) {
	immutable HashTable!(T, K, getKey) res = immutable HashTable!(T, K, getKey)(a.size_, cast(immutable) a.values);
	a.size_ = 0;
	a.values = [];
	return res;
}

@trusted T[] moveToArray(T, K, alias getKey)(ref Alloc alloc, ref HashTable!(T, K, getKey) a) {
	// Cleverly reuse the space in 'values'
	T* out_ = cast(T*) a.values;
	foreach (ref MutOpt!T x; a.values) {
		if (has(x)) {
			initMemory(out_, force(x));
			out_++;
		}
	}
	assert(out_ <= cast(T*) endPtr(a.values));
	T[] res = arrayOfRange(cast(T*) a.values, out_);
	T[] remaining = arrayOfRange(out_, cast(T*) endPtr(a.values));
	freeElements(alloc, remaining);
	a.size_ = 0;
	a.values = [];
	return res;
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

immutable(HashTable!(Out, K, getKeyOut)) mapPreservingKeys(Out, alias getKeyOut, In, K, alias getKey)(
	ref Alloc alloc,
	scope ref HashTable!(In, K, getKey) a,
	in Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	immutable MutOpt!Out[] outValues = map!(immutable MutOpt!Out, MutOpt!In)(alloc, a.values, (ref MutOpt!In value) {
		if (has(value)) {
			Out out_ = cb(force(value));
			assert(eq!K(getKeyOut(out_), getKey(force(value))));
			return cast(immutable) someMut!Out(out_);
		} else
			return cast(immutable) noneMut!Out;
	});
	return immutable HashTable!(Out, K, getKeyOut)(a.size_, outValues);
}

@trusted immutable(HashTable!(Out, K, getKeyOut)) mapAndMovePreservingKeys(Out, alias getKeyOut, In, K, alias getKey)(
	ref Alloc alloc,
	ref HashTable!(In, K, getKey) a,
	in Out delegate(ref In) @safe @nogc pure nothrow cb,
) {
	static assert(Out.sizeof <= In.sizeof);
	MutOpt!Out* out_ = cast(MutOpt!Out*) a.values.ptr;
	foreach (MutOpt!In x; a.values) {
		initMemory(out_, has(x) ? someMut!Out(cb(force(x))) : noneMut!Out);
		out_++;
	}
	immutable HashTable!(Out, K, getKeyOut) res = immutable HashTable!(Out, K, getKeyOut)(
		a.size_,
		cast(immutable) arrayOfRange!(MutOpt!Out)(cast(MutOpt!Out*) a.values.ptr, out_));
	MutOpt!In[] remaining = arrayOfRange(cast(MutOpt!In*) out_, endPtr(a.values));
	freeElements(alloc, remaining);
	a.size_ = 0;
	a.values = [];
	return res;
}

bool existsInHashTable(T, K, alias getKey)(
	in HashTable!(T, K, getKey) a,
	in bool delegate(in T) @safe @nogc pure nothrow cb,
) {
	foreach (ref const T x; a)
		if (cb(x))
			return true;
	return false;
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

size_t mustGetIndex(T, K, alias getKey)(in HashTable!(T, K, getKey) a, in K key) {
	Opt!size_t res = getIndex(a, key);
	return force(res);
}

Opt!size_t getIndex(T, K, alias getKey)(in HashTable!(T, K, getKey) a, in K key) {
	if (empty(a.values))
		return none!size_t;

	size_t startI = getHash!K(key).hashCode % a.values.length;
	size_t i = startI;
	while (true) {
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
	HashTable!(T, K, getKey) bigger = HashTable!(T, K, getKey)(0, fillArray!(MutOpt!T)(alloc, newCapacity, noneMut!T));
	foreach (ref T x; a)
		mustAdd(alloc, bigger, x);
	freeElements(alloc, a.values);
	a.values = bigger.values;
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

	return res;
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
