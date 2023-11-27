module util.col.mutMap;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements;
import util.col.arr : empty, endPtr;
import util.col.arrUtil : map;
import util.col.map : Map;
import util.hash : Hasher, hashSizeT, hashUbyte;
import util.memory : initMemory, overwriteMemory;
import util.opt : ConstOpt, force, has, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.ptr : hashPtr;
import util.col.str : strEq;
import util.util : drop, unreachable;

struct MutMap(K, V) {
	@safe @nogc pure nothrow:

	private:
	size_t size;
	MutOpt!(KeyValuePair!(K, V))[] pairs;

	public MutOpt!V opIndex(in immutable K key) {
		Opt!size_t i = getIndex(this, key);
		return has(i) ? someMut!V(force(pairs[force(i)]).value) : noneMut!V;
	}
	public ConstOpt!V opIndex(in immutable K key) const {
		Opt!size_t i = getIndex(this, key);
		return has(i) ? someConst!V(force(pairs[force(i)]).value) : noneMut!V;
	}
}

struct KeyValuePair(K, V) {
	K key;
	V value;
}

bool mutMapIsEmpty(K, V)(ref const MutMap!(K, V) a) =>
	a.size == 0;

size_t mutMapSize(K, V)(ref const MutMap!(K, V) a) =>
	a.size;

bool hasKey_mut(K, V)(ref const MutMap!(K, V) a, in K key) =>
	has(getIndex(a, key));

Opt!V getAt_mut(K, V)(ref const MutMap!(immutable K, immutable V) a, in immutable K key) {
	Opt!size_t i = getIndex(a, key);
	return has(i) ? some(force(a.pairs[force(i)]).value) : none!V;
}

private Opt!size_t getIndex(K, V)(in MutMap!(K, V) a, in immutable K key) {
	if (empty(a.pairs)) return none!size_t;

	assert(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return none!size_t;
		else if (eq!(immutable K)(key, force(a.pairs[i]).key))
			return some(i);
		else {
			i = nextI(a, i);
		}
	}
}

ref const(V) mustGetAt_mut(K, V)(ref const MutMap!(K, V) a, in K key) {
	assert(!empty(a.pairs));
	assert(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (eq!K(key, force(a.pairs[i]).key))
			return force(a.pairs[i]).value;
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

void addToMutMap(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a, K key, V value) {
	size_t sizeBefore = a.size;
	drop(setInMap(alloc, a, key, value));
	assert(a.size == sizeBefore + 1);
}

ref KeyValuePair!(K, V) setInMap(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a, K key, V value) =>
	insertOrUpdate!(K, V)(alloc, a, key, () => value, (ref const(V)) => value);

struct ValueAndDidAdd(V) {
	V value;
	immutable bool didAdd;
}

ValueAndDidAdd!V getOrAddAndDidAdd(K, V)(
	ref Alloc alloc,
	ref MutMap!(K, V) a,
	scope K key,
	in V delegate() @safe @nogc pure nothrow getValue,
) {
	PairAndDidAdd!(K, V) res = getOrAddPairAndDidAdd!(K, V)(alloc, a, key, () =>
		KeyValuePair!(K, V)(key, getValue()));
	return ValueAndDidAdd!V(res.value, res.didAdd);
}

struct PairAndDidAdd(K, V) {
	K key;
	V value;
	immutable bool didAdd;
}

/*
Useful for when you want to allocate the key only if it is needed.
'getKey' must return a value equivalent to 'key'.
*/
PairAndDidAdd!(K, V) getOrAddPairAndDidAdd(K, V)(
	ref Alloc alloc,
	ref MutMap!(K, V) a,
	scope K key,
	in KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) {
	immutable size_t sizeBefore = a.size;
	KeyValuePair!(K, V) res = getOrAddPair(alloc, a, key, getPair);
	return PairAndDidAdd!(K, V)(res.key, res.value, a.size != sizeBefore);
}

ref V getOrAdd(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	K key,
	in V delegate() @safe @nogc pure nothrow getValue,
) =>
	getOrAddPair(alloc, a, key, () => KeyValuePair!(K, V)(key, getValue())).value;

ref KeyValuePair!(K, V) getOrAddPair(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	scope K key,
	in KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) {
	ensureNonEmptyCapacity(alloc, a);
	assert(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i])) {
			KeyValuePair!(K, V) pair = getPair();
			assert(pair.key == key);
			return addAt!(K, V)(alloc, a, i, pair);
		}
		else if (key == force(a.pairs[i]).key)
			return force(a.pairs[i]);
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

@trusted ref KeyValuePair!(K, V) insertOrUpdate(K, V)(
	ref Alloc alloc,
	return scope ref MutMap!(K, V) a,
	K key,
	in V delegate() @safe @nogc pure nothrow cbInsert,
	in V delegate(ref const V) @safe @nogc pure nothrow cbUpdate,
) {
	ensureNonEmptyCapacity(alloc, a);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return addAt!(K, V)(alloc, a, i, KeyValuePair!(K, V)(key, cbInsert()));
		else if (eq!K(key, force(a.pairs[i]).key)) {
			V* oldValuePtr = &force(a.pairs[i]).value;
			overwriteMemory(oldValuePtr, cbUpdate(*oldValuePtr));
			return force(a.pairs[i]);
		} else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

MutOpt!V mayDelete(K, V)(ref MutMap!(K, V) a, in K key) {
	Opt!size_t index = getIndex(a, key);
	return has(index) ? someMut(deleteAtIndex(a, force(index))) : noneMut!V;
}

V mustDelete(K, V)(ref MutMap!(K, V) a, in K key) {
	assert(a.pairs.length != 0);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return unreachable!(immutable V);
		else if (key == force(a.pairs[i]).key)
			return deleteAtIndex(a, i);
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

private V deleteAtIndex(K, V)(ref MutMap!(K, V) a, size_t i) {
	V res = force(a.pairs[i]).value;
	a.size--;
	fillHole(a, i, nextI(a, i));
	return res;
}

// When there is a hole, move anything there that would be closer to where it should be.
private void fillHole(K, V)(
	ref MutMap!(K, V) a,
	size_t holeI,
	size_t fromI,
) {
	while (has(a.pairs[fromI])) {
		immutable K key = force(a.pairs[fromI]).key;
		immutable size_t desiredI = getHash(key) % a.pairs.length;
		if (walkDistance(a, desiredI, holeI) < walkDistance(a, desiredI, fromI)) {
			overwriteMemory(&a.pairs[holeI], a.pairs[fromI]);
			holeI = fromI;
			fromI = nextI(a, fromI);
		} else
			fromI = nextI(a, fromI);
	}
	overwriteMemory(&a.pairs[holeI], noneMut!(KeyValuePair!(K, V)));
}

private immutable(size_t) nextI(K, V)(
	ref const MutMap!(K, V) a,
	immutable size_t i,
) {
	assert(a.size < a.pairs.length);
	immutable size_t res = i + 1;
	return res == a.pairs.length ? 0 : res;
}

private immutable(size_t) walkDistance(K, V)(
	ref const MutMap!(K, V) a,
	immutable size_t i0,
	immutable size_t i1,
) =>
	i0 <= i1
		? i1 - i0
		: a.pairs.length + i1 - i0;

private @trusted immutable(Out[]) mapToArr_const(Out, K, V)(
	ref Alloc alloc,
	in MutMap!(K, V) a,
	in immutable(Out) delegate(immutable K, ref const V) @safe @nogc pure nothrow cb,
) {
	Out[] res = allocateElements!Out(alloc, a.size);
	Out* cur = res.ptr;
	foreach (ref ConstOpt!(KeyValuePair!(K, V)) pair; a.pairs) {
		if (has(pair)) {
			initMemory(cur, cb(force(pair).key, force(pair).value));
			cur++;
		}
	}
	assert(cur == endPtr(res));
	return cast(immutable) res;
}
@trusted immutable(Out[]) mapToArr_mut(Out, K, V)(
	ref Alloc alloc,
	ref MutMap!(K, V) a,
	in immutable(Out) delegate(immutable K, ref V) @safe @nogc pure nothrow cb,
) =>
	mapToArr_const!(Out, K, V)(alloc, a, (immutable K k, ref const V v) =>
		cb(k, cast(V) v));

immutable(V[]) moveToValues(K, V)(ref Alloc alloc, ref MutMap!(immutable K, immutable V) a) {
	immutable V[] res = valuesArray(alloc, a);
	clear(a);
	return res;
}

@trusted immutable(Map!(K, V)) moveToMap(K, V)(
	ref Alloc alloc,
	ref MutMap!(immutable K, immutable V) a,
) {
	immutable Map!(K, V) res = immutable Map!(K, V)(cast(immutable) a);
	clear(a);
	return res;
}

private void clear(K, V)(scope ref MutMap!(K, V) a) {
	a.size = 0;
	a.pairs = [];
}

immutable(Map!(K, VOut)) mapToMap(K, VOut, VIn)(
	ref Alloc alloc,
	scope ref MutMap!(K, VIn) a,
	in immutable(VOut) delegate(ref VIn) @safe @nogc pure nothrow cb,
) {
	immutable MutOpt!(KeyValuePair!(immutable K, immutable VOut))[] outPairs =
		map!(MutOpt!(KeyValuePair!(immutable K, immutable VOut)), MutOpt!(KeyValuePair!(K, VIn)))(
			alloc, a.pairs, (ref MutOpt!(KeyValuePair!(K, VIn)) pair) =>
			has(pair)
				// TODO: do without casts...
				? cast(immutable) someMut(
					KeyValuePair!(immutable K, immutable VOut)(force(pair).key, cb(force(pair).value)))
				: cast(immutable) noneMut!(KeyValuePair!(immutable K, immutable VOut)));

	return immutable Map!(K, VOut)(immutable MutMap!(immutable K, immutable VOut)(a.size, outPairs));
}

immutable(V[]) valuesArray(K, V)(ref Alloc alloc, in MutMap!(K, V) a) =>
	mapToArr_const!(V, K, V)(alloc, a, (immutable(K), ref V v) => v);

void mutMapEach(K, V)(ref inout MutMap!(K, V) a, in void delegate(const K, ref inout V) @safe @nogc pure nothrow cb) {
	foreach (ref ConstOpt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}
void mutMapEach(K, V)(
	in immutable MutMap!(K, V) a,
	in void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable MutOpt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}
void mutMapEachIn(K, V)(
	in MutMap!(K, V) a,
	in void delegate(in K, in V) @safe @nogc pure nothrow cb,
) {
	foreach (scope ref ConstOpt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}
bool existsInMutMap(K, V)(
	in MutMap!(K, V) a,
	in bool delegate(in K, in V) @safe @nogc pure nothrow cb,
) {
	foreach (scope ref ConstOpt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair) && cb(force(pair).key, force(pair).value))
			return true;
	return false;
}

private:

void ensureNonEmptyCapacity(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a) {
	if (empty(a.pairs)) doExpand(alloc, a);
}

ref KeyValuePair!(K, V) addAt(K, V)(
	ref Alloc alloc,
	scope ref MutMap!(K, V) a,
	 size_t i,
	KeyValuePair!(K, V) pair,
) {
	if (shouldExpand(a)) {
		doExpand(alloc, a);
		return setInMap(alloc, a, pair.key, pair.value);
	} else {
		a.size++;
		overwriteMemory(&a.pairs[i], someMut(pair));
		return force(a.pairs[i]);
	}
}

immutable(bool) shouldExpand(K, V)(ref const MutMap!(K, V) a) =>
	a.size <= 8
		? a.size + 1 >= a.pairs.length
		: a.size * 9 / 8 >= a.pairs.length;

@trusted void doExpand(K, V)(ref Alloc alloc, scope ref MutMap!(K, V) a) {
	immutable size_t newSize = a.pairs.length < 2 ? 2 : a.pairs.length * 2;
	MutMap!(K, V) bigger = MutMap!(K, V)(0, allocateElements!(MutOpt!(KeyValuePair!(K, V)))(alloc, newSize));
	foreach (ref MutOpt!(KeyValuePair!(K, V)) pair; bigger.pairs)
		initMemory(&pair, noneMut!(KeyValuePair!(K, V)));
	foreach (ref MutOpt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			drop(setInMap!(K, V)(alloc, bigger, force(pair).key, force(pair).value));
	a.pairs = bigger.pairs;
}

bool eq(K)(in K a, in K b) {
	static if (is(K == string))
		return strEq(a, b);
	else
		return a == b;
}

ulong getHash(K)(in immutable K key) {
	Hasher hasher = Hasher();
	static if (is(K == P*, P)) {
		hashPtr(hasher, key);
	} else static if (is(K == string)) {
		foreach (immutable char c; key)
			hashUbyte(hasher, c);
	} else static if (is(K == size_t)) {
		hashSizeT(hasher, key);
	} else {
		key.hash(hasher);
	}
	return hasher.finish();
}
