module util.collection.mutDict;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr :
	deleteAt,
	MutArr,
	mutArrAt,
	mutArrIsEmpty,
	mutArrRange,
	mutArrRangeMut,
	mutArrSize,
	push,
	tempAsArr;
import util.comparison : Comparison;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.util : verify;

struct MutDict(K, V, alias cmp) {
	private:
	MutArr!(KeyValuePair!(K, V)) pairs;
}

const(Arr!(KeyValuePair!(K, V))) tempPairs(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return tempAsArr(a.pairs);
}

const(Opt!V) getAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	foreach (ref const KeyValuePair!(K, V) pair; mutArrRange(a.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return some!V(pair.value);
	return none!V;
}

immutable(V) mustGetAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	immutable Opt!V opt = getAt_mut(a, key);
	return opt.force;
}

void setInDict(Alloc, K, V, alias cmp)(ref Alloc alloc, ref MutDict!(K, V, cmp) a, immutable K key, immutable V value) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (cmp(pair.key, key) == Comparison.equal) {
			overwriteMemory(&pair.value, value);
			return;
		}
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
}

void addToMutDict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref MutDict!(K, V, cmp) a,
	K key,
	V value,
) {
	immutable Bool has = hasKey_mut(a, key);
	verify(!has);
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
}

struct ValueAndDidAdd(V) {
	V value;
	immutable Bool didAdd;
}

V getOrAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	return getOrAddAndDidAdd(alloc, a, key, getValue).value;
}

V insertOrUpdate(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow cbInsert,
	scope V delegate(ref const V) @safe @nogc pure nothrow cbUpdate,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (compare(pair.key, key) == Comparison.equal) {
			overwriteMemory(&pair.value, cbUpdate(pair.value));
			return pair.value;
		}
	V value = cbInsert();
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
	return value;
}

ValueAndDidAdd!V getOrAddAndDidAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (compare(pair.key, key) == Comparison.equal)
			return ValueAndDidAdd!V(pair.value, False);
	V value = getValue();
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
	return ValueAndDidAdd!V(value, True);
}

private immutable(Opt!V) tryDeleteAndGet(K, V, alias cmp)(ref MutDict!(K, V, cmp) a, const K key) {
	foreach (immutable size_t i; 0..mutDictSize(a)) {
		const KeyValuePair!(K, V) pair = mutArrAt(a.pairs, i);
		if (cmp(pair.key, key) == Comparison.equal) {
			deleteAt(a.pairs, i);
			return some!V(pair.value);
		}
	}
	return none!V;
}

immutable(V) mustDelete(K, V, alias cmp)(ref MutDict!(K, V, cmp) a, const K key) {
	immutable Opt!V op = tryDeleteAndGet(a, key);
	return force(op);
}

immutable(Bool) mutDictIsEmpty(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return mutArrIsEmpty(a.pairs);
}

private:

immutable(Bool) hasKey_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	immutable Opt!V opt = getAt_mut(a, key);
	return has(opt);
}

immutable(size_t) mutDictSize(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return mutArrSize(a.pairs);
}
