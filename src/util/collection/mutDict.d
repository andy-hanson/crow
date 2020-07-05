module util.collection.mutDict;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.dict : KeyValuePair;
import util.collection.mutArr : MutArr, mutArrAt, mutArrIsEmpty, mutArrRange, mutArrRangeMut, mutArrSize, push;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;

struct MutDict(K, V, alias cmp) {
	MutArr!(KeyValuePair!(K, V)) pairs;
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
			pair.value = value;
			return;
		}
	push(alloc, d.pairs, immutable KeyValuePair!(K, V)(key, value));
}


void addToMutDict(Alloc, K, V, alias cmp)(ref Alloc alloc,  ref MutDict!(K, V, cmp) d, immutable K key, immutable V value) {
	immutable Bool has = d.hasKey_mut(key);
	assert(!has);
	push(alloc, d.pairs, immutable KeyValuePair!(K, V)(key, value));
}

V getOrAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) d,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(d.pairs))
		if (compare(pair.key, key) == Comparison.equal)
			return pair.value;
	V value = getValue();
	push(alloc, d.pairs, KeyValuePair!(K, V)(key, value));
	return value;
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
	assert(cmp(keyCopy, key) == Comparison.equal);
	immutable V value = getValue();
	d.pairs.push(alloc, KeyValuePair!(K, V)(key, value));
	return value;
}

immutable(Opt!V) tryDeleteAndGet(K, V, alias cmp)(ref MutDict!(K, V, cmp) d, immutable K key) {
	foreach (immutable size_t i; 0..d.pairs.mutArrSize) {
		immutable KeyValuePair!(K, V) pair = d.pairs.mutArrAt(i);
		if (cmp(pair.key, key) == Comparison.equal) {
			d.pairs.deleteAt(i);
			return some!V(pair.value);
		}
	}
	return none!V;
}

immutable(V) mustDelete(K, V, alias cmp)(ref MutDict!(K, V, cmp) d, immutable K key) {
	return tryDeleteAndGet(d, key).force;
}

immutable(Bool) mutDictIsEmpty(K, V, alias cmp)(ref MutDict!(K, V, cmp) d) {
	return d.pairs.mutArrIsEmpty;
}

