module util.col.mutDict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty, emptyArr_mut;
import util.col.arrUtil : map_mut;
import util.col.dict : Dict;
import util.col.str : strEq, hashStr;
import util.hash : Hasher;
import util.memory : initMemory, overwriteMemory;
import util.opt : force, has, none, noneConst, Opt, some, someConst, someMut;
import util.ptr : hashPtr, Ptr, ptrEquals;
import util.sym : hashSym, Sym, symEq;
import util.util : unreachable, verify;

struct MutDict(K, V, alias equal, alias hash) {
	private:
	size_t size;
	Opt!(KeyValuePair!(K, V))[] pairs;
}

alias MutPtrDict(K, V) =
	MutDict!(immutable Ptr!K, V, ptrEquals!K, hashPtr!K);

alias MutStringDict(V) =
	MutDict!(immutable string, V, strEq, hashStr);

alias MutSymDict(V) =
	MutDict!(immutable Sym, V, symEq, hashSym);

struct KeyValuePair(K, V) {
	K key;
	V value;
}

immutable(bool) mutDictIsEmpty(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a) {
	return a.size == 0;
}

immutable(size_t) mutDictSize(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a) {
	return a.size;
}

immutable(bool) hasKey_mut(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a, const K key) {
	return has(getAt_mut(a, key));
}

const(Opt!V) getAt_mut(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a, const K key) {
	if (empty(a.pairs)) return none!V;

	verify(a.size < a.pairs.length);
	size_t i = getHash!(K, hash)(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return noneConst!V;
		else if (equal(key, force(a.pairs[i]).key))
			return someConst!V(force(a.pairs[i]).value);
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

ref const(V) mustGetAt_mut(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a, const K key) {
	verify(!empty(a.pairs));
	verify(a.size < a.pairs.length);
	size_t i = getHash!(K, hash)(key) % a.pairs.length;
	while (true) {
		if (equal(key, force(a.pairs[i]).key))
			return force(a.pairs[i]).value;
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

void addToMutDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	scope ref MutDict!(K, V, equal, hash) a,
	K key,
	V value,
) {
	immutable size_t sizeBefore = a.size;
	setInDict(alloc, a, key, value);
	verify(a.size == sizeBefore + 1);
}

ref V setInDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	scope ref MutDict!(K, V, equal, hash) a,
	K key,
	V value,
) {
	return insertOrUpdate!(K, V, equal, hash)(alloc, a, key, () => value, (ref const(V)) => value);
}

struct ValueAndDidAdd(V) {
	V value;
	immutable bool didAdd;
}

ValueAndDidAdd!V getOrAddAndDidAdd(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref MutDict!(K, V, equal, hash) a,
	K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	immutable size_t sizeBefore = a.size;
	V res = getOrAdd(alloc, a, key, getValue);
	return ValueAndDidAdd!V(res, a.size != sizeBefore);
}

ref V getOrAdd(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	return scope ref MutDict!(K, V, equal, hash) a,
	K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	ensureNonEmptyCapacity(alloc, a);
	verify(a.size < a.pairs.length);
	size_t i = getHash!(K, hash)(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return addAt!(K, V, equal, hash)(alloc, a, i, key, getValue());
		else if (equal(key, force(a.pairs[i]).key))
			return force(a.pairs[i]).value;
		else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

@trusted ref V insertOrUpdate(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	return scope ref MutDict!(K, V, equal, hash) a,
	K key,
	scope V delegate() @safe @nogc pure nothrow cbInsert,
	scope V delegate(ref const V) @safe @nogc pure nothrow cbUpdate,
) {
	ensureNonEmptyCapacity(alloc, a);
	size_t i = getHash!(K, hash)(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i]))
			return addAt!(K, V, equal, hash)(alloc, a, i, key, cbInsert());
		else if (equal(key, force(a.pairs[i]).key)) {
			V* oldValuePtr = &force(a.pairs[i]).value;
			overwriteMemory(oldValuePtr, cbUpdate(*oldValuePtr));
			return *oldValuePtr;
		} else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

immutable(V) mustDelete(K, V, alias equal, alias hash)(ref MutDict!(K, V, equal, hash) a, K key) {
	verify(a.pairs.length != 0);
	size_t i = getHash!(K, hash)(key) % a.pairs.length;
	while (true) {
		if (!has(a.pairs[i])) {
			return unreachable!(immutable V);
		} else if (equal(key, force(a.pairs[i]).key)) {
			immutable V res = force(a.pairs[i]).value;
			a.size--;
			removeAndShiftLeft(a, i);
			return res;
		} else {
			i++;
			if (i == a.pairs.length) i = 0;
		}
	}
}

// Opening a gap means that things that were previously moved to the right must move left.
private void removeAndShiftLeft(K, V, alias equal, alias hash)(ref MutDict!(K, V, equal, hash) a, size_t i) {
	overwriteMemory(&a.pairs[i], none!(KeyValuePair!(K, V)));
	// Avoid dscanner warning `Avoid subtracting from '.length' as it may be unsigned`
	immutable size_t n = a.pairs.length;
	verify(n != 0);
	immutable size_t j = i == n - 1 ? 0 : i + 1;
	if (has(a.pairs[j])) {
		K key = force(a.pairs[j]).key;
		immutable size_t desiredI = getHash!(K, hash)(key) % n;
		if (desiredI != j) {
			overwriteMemory(&a.pairs[i], a.pairs[j]);
			removeAndShiftLeft(a, j);
		}
	}
}

@trusted immutable(Out[]) mapToArr_mut(Out, K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref MutDict!(K, V, equal, hash) a,
	scope immutable(Out) delegate(immutable K, ref V) @safe @nogc pure nothrow cb,
) {
	Out* res = allocateT!Out(alloc, a.size);
	Out* cur = res;
	foreach (ref Opt!(KeyValuePair!(K, V)) pair; a.pairs) {
		if (has(pair)) {
			initMemory(cur, cb(force(pair).key, force(pair).value));
			cur++;
		}
	}
	verify(cur == res + a.size);
	return cast(immutable) res[0 .. a.size];
}
private @trusted immutable(Out[]) mapToArr_const(Out, K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref const MutDict!(K, V, equal, hash) a,
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

@trusted immutable(Dict!(K, V, equal, hash)) moveToDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref MutDict!(immutable K, immutable V, equal, hash) a,
) {
	immutable Dict!(K, V, equal, hash) res = immutable Dict!(K, V, equal, hash)(
		cast(immutable MutDict!(K, V, equal, hash)) a);
	a.size = 0;
	a.pairs = emptyArr_mut!(Opt!(KeyValuePair!(immutable K, immutable V)));
	return res;
}

immutable(Dict!(K, VOut, equal, hash)) mapToDict(K, VOut, VIn, alias equal, alias hash)(
	ref Alloc alloc,
	ref MutDict!(immutable K, VIn, equal, hash) a,
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
	return immutable Dict!(K, VOut, equal, hash)(immutable MutDict!(K, VOut, equal, hash)(a.size, outPairs));
}

immutable(K[]) keysArray(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref const MutDict!(K, V, equal, hash) a,
) {
	return mapToArr_const!(K, K, V, equal, hash)(alloc, a, (immutable K k, ref V) => k);
}

immutable(V[]) valuesArray(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref const MutDict!(K, V, equal, hash) a,
) {
	return mapToArr_const!(V, K, V, equal, hash)(alloc, a, (immutable(K), ref V v) => v);
}

void mutDictEach(K, V, alias equal, alias hash)(
	ref const MutDict!(K, V, equal, hash) a,
	scope void delegate(const K, ref const V) @safe @nogc pure nothrow cb,
) {
	foreach (ref const Opt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}
void mutDictEach(K, V, alias equal, alias hash)(
	ref immutable MutDict!(K, V, equal, hash) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	foreach (ref immutable Opt!(KeyValuePair!(K, V)) pair; a.pairs)
		if (has(pair))
			cb(force(pair).key, force(pair).value);
}

private:

void ensureNonEmptyCapacity(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	scope ref MutDict!(K, V, equal, hash) a,
) {
	if (empty(a.pairs)) doExpand(alloc, a);
}

ref V addAt(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	scope ref MutDict!(K, V, equal, hash) a,
	immutable size_t i,
	K key,
	V value,
) {
	if (shouldExpand(a)) {
		doExpand(alloc, a);
		return setInDict(alloc, a, key, value);
	} else {
		a.size++;
		overwriteMemory(&a.pairs[i], someMut!(KeyValuePair!(K, V))(KeyValuePair!(K, V)(key, value)));
		return force(a.pairs[i]).value;
	}
}

immutable(bool) shouldExpand(K, V, alias equal, alias hash)(ref const MutDict!(K, V, equal, hash) a) {
	return a.size <= 8
		? a.size + 1 >= a.pairs.length
		: a.size * 9 / 8 >= a.pairs.length;
}

@trusted void doExpand(K, V, alias equal, alias hash)(ref Alloc alloc, scope ref MutDict!(K, V, equal, hash) a) {
	immutable size_t newSize = a.pairs.length < 2 ? 2 : a.pairs.length * 2;
	// Make a bigger one
	Opt!(KeyValuePair!(K, V))* newPairs = allocateT!(Opt!(KeyValuePair!(K, V)))(alloc, newSize);
	MutDict!(K, V, equal, hash) bigger = MutDict!(K, V, equal, hash)(0, newPairs[0 .. newSize]);
	foreach (ref Opt!(KeyValuePair!(K, V)) pair; a.pairs) {
		if (has(pair))
			setInDict!(K, V, equal, hash)(alloc, bigger, force(pair).key, force(pair).value);
	}
	a.pairs = bigger.pairs;
}

immutable(ulong) getHash(K, alias hash)(const K key) {
	Hasher hasher = Hasher();
	hash(hasher, key);
	return hasher.finish();
}
