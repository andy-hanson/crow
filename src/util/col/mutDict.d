module util.col.mutDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty, emptyArr_mut;
import util.col.arrUtil : map_mut;
import util.col.dict : Dict;
import util.hash : Hasher, hashSizeT, hashUbyte;
import util.memory : initMemory, overwriteMemory;
import util.opt : force, has, none, noneConst, Opt, some, someConst, someMut;
import util.ptr : hashPtr;
import util.col.str : strEq;
import util.util : drop, unreachable, verify;

struct MutDict(K, V) {
	private:
	size_t size;
	Opt!(KeyValuePair!(K, V))[] pairs;
}

struct KeyValuePair(K, V) {
	K key;
	V value;
}

immutable(bool) mutDictIsEmpty(K, V)(ref const MutDict!(K, V) a) {
	return a.size == 0;
}

immutable(size_t) mutDictSize(K, V)(ref const MutDict!(K, V) a) {
	return a.size;
}

immutable(bool) hasKey_mut(K, V)(ref const MutDict!(K, V) a, const K key) {
	immutable Opt!V value = getAt_mut(a, key);
	return has(value);
}

const(Opt!V) getAt_mut(K, V)(ref const MutDict!(K, V) a, const K key) {
	if (empty(a.pairs)) return none!V;

	verify(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return noneConst!V;
		else if (eq(key, force(a.pairs[i]).key))
			return someConst!V(cast(const V) force(a.pairs[i]).value);
		else {
			i = nextI(a, i);
		}
	}
}

ref const(V) mustGetAt_mut(K, V)(ref const MutDict!(K, V) a, const K key) {
	verify(!empty(a.pairs));
	verify(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (eq(key, force(a.pairs[i]).key))
			return force(a.pairs[i]).value;
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

void addToMutDict(K, V)(
	ref Alloc alloc,
	scope ref MutDict!(K, V) a,
	K key,
	V value,
) {
	immutable size_t sizeBefore = a.size;
	drop(setInDict(alloc, a, key, value));
	verify(a.size == sizeBefore + 1);
}

ref KeyValuePair!(K, V) setInDict(K, V)(
	ref Alloc alloc,
	scope ref MutDict!(K, V) a,
	K key,
	V value,
) {
	return insertOrUpdate!(K, V)(alloc, a, key, () => value, (ref const(V)) => value);
}

struct ValueAndDidAdd(V) {
	V value;
	immutable bool didAdd;
}

ValueAndDidAdd!V getOrAddAndDidAdd(K, V)(
	ref Alloc alloc,
	ref MutDict!(K, V) a,
	scope K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
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
	ref MutDict!(K, V) a,
	scope K key,
	scope KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) {
	immutable size_t sizeBefore = a.size;
	KeyValuePair!(K, V) res = getOrAddPair(alloc, a, key, getPair);
	return PairAndDidAdd!(K, V)(res.key, res.value, a.size != sizeBefore);
}

ref V getOrAdd(K, V)(
	ref Alloc alloc,
	return scope ref MutDict!(K, V) a,
	K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	return getOrAddPair(alloc, a, key, () => KeyValuePair!(K, V)(key, getValue())).value;
}

ref KeyValuePair!(K, V) getOrAddPair(K, V)(
	ref Alloc alloc,
	return scope ref MutDict!(K, V) a,
	scope K key,
	scope KeyValuePair!(K, V) delegate() @safe @nogc pure nothrow getPair,
) {
	ensureNonEmptyCapacity(alloc, a);
	verify(a.size < a.pairs.length);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i])) {
			KeyValuePair!(K, V) pair = getPair();
			verify(pair.key == key);
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
	return scope ref MutDict!(K, V) a,
	K key,
	scope V delegate() @safe @nogc pure nothrow cbInsert,
	scope V delegate(ref const V) @safe @nogc pure nothrow cbUpdate,
) {
	ensureNonEmptyCapacity(alloc, a);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return addAt!(K, V)(alloc, a, i, KeyValuePair!(K, V)(key, cbInsert()));
		else if (eq(key, force(a.pairs[i]).key)) {
			V* oldValuePtr = &force(a.pairs[i]).value;
			overwriteMemory(oldValuePtr, cbUpdate(*oldValuePtr));
			return force(a.pairs[i]);
		} else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

immutable(V) mustDelete(K, V)(ref MutDict!(K, V) a, K key) {
	verify(a.pairs.length != 0);
	size_t i = getHash(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return unreachable!(immutable V);
		else if (key == force(a.pairs[i]).key) {
			immutable V res = force(a.pairs[i]).value;
			a.size--;
			fillHole(a, i, nextI(a, i));
			return res;
		} else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

// When there is a hole, move anything there that would be closer to where it should be.
private void fillHole(K, V)(
	ref MutDict!(K, V) a,
	immutable size_t holeI,
	immutable size_t i,
) {
	if (has(a.pairs[i])) {
		immutable K key = force(a.pairs[i]).key;
		immutable size_t desiredI = getHash(key) % a.pairs.length;
		if (walkDistance(a, desiredI, holeI) < walkDistance(a, desiredI, i)) {
			overwriteMemory(&a.pairs[holeI], a.pairs[i]);
			fillHole(a, i, nextI(a, i));
		} else
			fillHole(a, holeI, nextI(a, i));
	} else {
		overwriteMemory(&a.pairs[holeI], none!(KeyValuePair!(K, V)));
	}
}

private immutable(size_t) nextI(K, V)(
	ref const MutDict!(K, V) a,
	immutable size_t i,
) {
	verify(a.size < a.pairs.length);
	immutable size_t res = i + 1;
	return res == a.pairs.length ? 0 : res;
}

private immutable(size_t) walkDistance(K, V)(
	ref const MutDict!(K, V) a,
	immutable size_t i0,
	immutable size_t i1,
) {
	return i0 <= i1
		? i1 - i0
		: a.pairs.length + i1 - i0;
}

private @trusted immutable(Out[]) mapToArr_const(Out, K, V)(
	ref Alloc alloc,
	scope ref const MutDict!(K, V) a,
	scope immutable(Out) delegate(immutable K, ref const V) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.size);
	Out* cur = res;
	foreach (ref const Opt!(KeyValuePair!(K, V)) pair; a.pairs) {
		if (has(pair)) {
			initMemory(cur, cb(force(pair).key, force(pair).value));
			cur++;
		}
	}
	verify(cur == res + a.size);
	return cast(immutable) res[0 .. a.size];
}
@trusted immutable(Out[]) mapToArr_mut(Out, K, V)(
	ref Alloc alloc,
	ref MutDict!(K, V) a,
	scope immutable(Out) delegate(immutable K, ref V) @safe @nogc pure nothrow cb,
) {
	return mapToArr_const!(Out, K, V)(alloc, a, (immutable K k, ref const V v) =>
		cb(k, cast(V) v));
}

@trusted immutable(Dict!(K, V)) moveToDict(K, V)(
	ref Alloc alloc,
	ref MutDict!(immutable K, immutable V) a,
) {
	immutable Dict!(K, V) res = immutable Dict!(K, V)(
		cast(immutable MutDict!(K, V)) a);
	a.size = 0;
	a.pairs = emptyArr_mut!(Opt!(KeyValuePair!(immutable K, immutable V)));
	return res;
}

immutable(Dict!(K, VOut)) mapToDict(K, VOut, VIn)(
	ref Alloc alloc,
	scope ref MutDict!(immutable K, VIn) a,
	scope immutable(VOut) delegate(ref VIn) @safe @nogc pure nothrow cb,
) {
	immutable Opt!(KeyValuePair!(K, VOut))[] outPairs =
		map_mut!(Opt!(KeyValuePair!(K, VOut)), Opt!(KeyValuePair!(immutable K, VIn)))(
			alloc,
			a.pairs,
			(ref Opt!(KeyValuePair!(immutable K, VIn)) pair) =>
				has(pair)
					? some(immutable KeyValuePair!(K, VOut)(force(pair).key, cb(force(pair).value)))
					: none!(KeyValuePair!(K, VOut)));
	return immutable Dict!(K, VOut)(immutable MutDict!(K, VOut)(a.size, outPairs));
}

immutable(V[]) valuesArray(K, V)(
	ref Alloc alloc,
	scope ref const MutDict!(K, V) a,
) {
	return mapToArr_const!(V, K, V)(alloc, a, (immutable(K), ref V v) => v);
}

void mutDictEach(K, V)(
	scope ref const MutDict!(K, V) a,
	scope void delegate(const K, ref const V) @safe @nogc pure nothrow cb,
) {
	foreach (ref const Opt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}
void mutDictEach(K, V)(
	ref immutable MutDict!(K, V) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable Opt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}

private:

void ensureNonEmptyCapacity(K, V)(
	ref Alloc alloc,
	scope ref MutDict!(K, V) a,
) {
	if (empty(a.pairs)) doExpand(alloc, a);
}

ref KeyValuePair!(K, V) addAt(K, V)(
	ref Alloc alloc,
	scope ref MutDict!(K, V) a,
	immutable size_t i,
	KeyValuePair!(K, V) pair,
) {
	if (shouldExpand(a)) {
		doExpand(alloc, a);
		return setInDict(alloc, a, pair.key, pair.value);
	} else {
		a.size++;
		overwriteMemory(&a.pairs[i], someMut(pair));
		return force(a.pairs[i]);
	}
}

immutable(bool) shouldExpand(K, V)(ref const MutDict!(K, V) a) {
	return a.size <= 8
		? a.size + 1 >= a.pairs.length
		: a.size * 9 / 8 >= a.pairs.length;
}

@trusted void doExpand(K, V)(ref Alloc alloc, scope ref MutDict!(K, V) a) {
	immutable size_t newSize = a.pairs.length < 2 ? 2 : a.pairs.length * 2;
	Opt!(KeyValuePair!(K, V))* newPairs = allocateT!(Opt!(KeyValuePair!(K, V)))(alloc, newSize);
	MutDict!(K, V) bigger = MutDict!(K, V)(0, newPairs[0 .. newSize]);
	foreach (ref Opt!(KeyValuePair!(K, V)) pair; bigger.pairs)
		initMemory(&pair, none!(KeyValuePair!(K, V)));
	foreach (ref Opt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			drop(setInDict!(K, V)(alloc, bigger, force(pair).key, force(pair).value));
	a.pairs = bigger.pairs;
}

immutable(bool) eq(K)(scope K a, scope K b) {
	static if (is(K == string))
		return strEq(a, b);
	else
		return a == b;
}

immutable(ulong) getHash(K)(scope K key) {
	Hasher hasher = Hasher();
	static if (is(K == P*, P)) {
		hashPtr(hasher, key);
	} else static if (is(K == string)) {
		foreach (immutable char c; key)
			hashUbyte(hasher, c);
	} else static if (is(K == immutable size_t)) {
		hashSizeT(hasher, key);
	} else {
		key.hash(hasher);
	}
	return hasher.finish();
}
