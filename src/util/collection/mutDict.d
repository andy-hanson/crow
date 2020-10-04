module util.collection.mutDict;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr;
import util.collection.arrUtil : map_const;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr :
	deleteAt,
	moveToArr_const,
	MutArr,
	mutArrAt,
	mutArrIsEmpty,
	mutArrRange,
	mutArrRangeMut,
	mutArrSize,
	push;
import util.comparison : Comparison;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.util : verify;

struct MutDict(K, V, alias cmp) {
	private:
	MutArr!(KeyValuePair!(K, V)) pairs;
}

immutable(Arr!V) moveMutDictToValues(Alloc, K, V, alias cmp)(ref Alloc alloc, ref MutDict!(K, immutable V, cmp) a) {
	const Arr!(KeyValuePair!(K, immutable V)) pairs = moveToArr_const(alloc, a.pairs);
	return map_const(alloc, pairs, (ref const KeyValuePair!(K, immutable V) pair) =>
		pair.value);
}

const(Opt!V) getAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) d, immutable K key) {
	foreach (ref const KeyValuePair!(K, V) pair; mutArrRange(d.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return some!V(pair.value);
	return none!V;
}

immutable(Bool) hasKey_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) d, immutable K key) {
	immutable Opt!V opt = d.getAt_mut(key);
	return opt.has;
}

immutable(V) mustGetAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) d, immutable K key) {
	immutable Opt!V opt = d.getAt_mut(key);
	return opt.force;
}

void setInDict(Alloc, K, V, alias cmp)(ref Alloc alloc, ref MutDict!(K, V, cmp) d, immutable K key, immutable V value) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(d.pairs))
		if (cmp(pair.key, key) == Comparison.equal) {
			overwriteMemory(&pair.value, value);
			return;
		}
	push(alloc, d.pairs, KeyValuePair!(K, V)(key, value));
}


void addToMutDict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref MutDict!(K, V, cmp) d,
	immutable K key,
	immutable V value,
) {
	immutable Bool has = d.hasKey_mut(key);
	verify(!has);
	push(alloc, d.pairs, KeyValuePair!(K, V)(key, value));
}

immutable(Bool) tryAddToMutDict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref MutDict!(K, V, cmp) d,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	return getOrAddAndDidAdd(alloc, d, key, getValue).didAdd;
}

struct ValueAndDidAdd(V) {
	V value;
	immutable Bool didAdd;
}

V getOrAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) d,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	return getOrAddAndDidAdd(alloc, d, key, getValue).value;
}

ValueAndDidAdd!V getOrAddAndDidAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) d,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(d.pairs))
		if (compare(pair.key, key) == Comparison.equal)
			return ValueAndDidAdd!V(pair.value, False);
	V value = getValue();
	push(alloc, d.pairs, KeyValuePair!(K, V)(key, value));
	return ValueAndDidAdd!V(value, True);
}

// Like getOrAdd, but the key is allowed to be temporary; if we need to add we'll make a copy then
immutable(V) getOrAddAndCopyKey(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref MutDict!(K, V, cmp) d,
	immutable K key,
	scope immutable(K) delegate() @safe @nogc pure nothrow getKeyCopy,
	scope immutable(V) delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref const KeyValuePair!(K, V) pair; mutArrRange(d.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return pair.value;
	immutable K keyCopy = getKeyCopy();
	verify(cmp(keyCopy, key) == Comparison.equal);
	immutable V value = getValue();
	d.pairs.push(alloc, KeyValuePair!(K, V)(key, value));
	return value;
}

immutable(Opt!V) tryDeleteAndGet(K, V, alias cmp)(ref MutDict!(K, V, cmp) d, immutable K key) {
	foreach (immutable size_t i; 0..d.pairs.mutArrSize) {
		immutable KeyValuePair!(K, V) pair = d.pairs.mutArrAt(i);
		if (cmp(pair.key, key) == Comparison.equal) {
			deleteAt(d.pairs, i);
			return some!V(pair.value);
		}
	}
	return none!V;
}

immutable(V) mustDelete(K, V, alias cmp)(ref MutDict!(K, V, cmp) d, immutable K key) {
	immutable Opt!V op = tryDeleteAndGet(d, key);
	return force(op);
}

immutable(Bool) mutDictIsEmpty(K, V, alias cmp)(ref MutDict!(K, V, cmp) d) {
	return d.pairs.mutArrIsEmpty;
}
