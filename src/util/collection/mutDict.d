module util.collection.mutDict;

@safe @nogc pure nothrow:

import util.collection.arrUtil : map_mut;
import util.collection.dict : Dict, KeyValuePair;
import util.collection.mutArr :
	deleteAt,
	last,
	moveToArr_const,
	MutArr,
	mutArrAt,
	mutArrIsEmpty,
	mutArrRange,
	mutArrRangeMut,
	mutArrSize,
	push,
	tempAsArr,
	tempAsArr_mut;
import util.comparison : Comparison;
import util.memory : overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.util : unreachable, verify;

struct MutDict(K, V, alias cmp) {
	private:
	MutArr!(KeyValuePair!(K, V)) pairs;
}

immutable(V[]) valuesArray(K, V, alias cmp, Alloc)(ref Alloc alloc, ref MutDict!(K, V, cmp) a) {
	return map_mut!(V, KeyValuePair!(K, V), Alloc)(alloc, tempPairs_mut(a), (ref KeyValuePair!(K, V) pair) =>
		pair.value);
}

@trusted immutable(Dict!(K, V, cmp)) moveToDict(K, V, alias cmp, Alloc)(
	ref Alloc alloc,
	ref MutDict!(immutable K, immutable V, cmp) a,
) {
	const KeyValuePair!(immutable K, immutable V)[] pairs = moveToArr_const(alloc, a.pairs);
	return immutable Dict!(K, V, cmp)(cast(immutable KeyValuePair!(K, V)[]) pairs);
}

immutable(Dict!(K, VOut, cmp)) mapToDict(K, VOut, VIn, alias cmp, Alloc)(
	ref Alloc alloc,
	ref MutDict!(immutable K, VIn, cmp) a,
	scope immutable(VOut) delegate(ref VIn) @safe @nogc pure nothrow cb,
) {
	return immutable Dict!(K, VOut, cmp)(map_mut!(KeyValuePair!(K, VOut))(
		alloc,
		tempPairs_mut(a),
		(ref KeyValuePair!(immutable K, VIn) pair) =>
			immutable KeyValuePair!(K, VOut)(pair.key, cb(pair.value))));
}

KeyValuePair!(K, V)[] tempPairs_mut(K, V, alias cmp)(ref MutDict!(K, V, cmp) a) {
	return tempAsArr_mut(a.pairs);
}

const(KeyValuePair!(K, V)[]) tempPairs(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return tempAsArr(a.pairs);
}

const(Opt!V) getAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	foreach (ref const KeyValuePair!(K, V) pair; mutArrRange(a.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return some!V(pair.value);
	return none!V;
}

ref const(V) mustGetAt_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	foreach (ref const KeyValuePair!(K, V) pair; mutArrRange(a.pairs))
		if (cmp(pair.key, key) == Comparison.equal)
			return pair.value;
	unreachable!void(); // TODO: Can't return ref from unreachable?
	return mutArrAt(a.pairs, 0).value;
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
	immutable bool has = hasKey_mut(a, key);
	verify(!has);
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
}

struct ValueAndDidAdd(V) {
	V value;
	immutable bool didAdd;
}

ref V getOrAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	return scope ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (compare(pair.key, key) == Comparison.equal)
			return pair.value;
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, getValue()));
	return last(a.pairs).value;
}

void insertOrUpdate(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow cbInsert,
	scope V delegate(ref const V) @safe @nogc pure nothrow cbUpdate,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (compare(pair.key, key) == Comparison.equal) {
			overwriteMemory(&pair.value, cbUpdate(pair.value));
			return;
		}
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, cbInsert()));
}

ValueAndDidAdd!V getOrAddAndDidAdd(Alloc, K, V, alias compare)(
	ref Alloc alloc,
	ref MutDict!(K, V, compare) a,
	immutable K key,
	scope V delegate() @safe @nogc pure nothrow getValue,
) {
	foreach (ref KeyValuePair!(K, V) pair; mutArrRangeMut(a.pairs))
		if (compare(pair.key, key) == Comparison.equal)
			return ValueAndDidAdd!V(pair.value, false);
	V value = getValue();
	push(alloc, a.pairs, KeyValuePair!(K, V)(key, value));
	return ValueAndDidAdd!V(value, true);
}

private immutable(Opt!V) tryDeleteAndGet(K, V, alias cmp)(ref MutDict!(K, V, cmp) a, const K key) {
	foreach (immutable size_t i; 0 .. mutDictSize(a)) {
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

immutable(bool) mutDictIsEmpty(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return mutArrIsEmpty(a.pairs);
}

immutable(size_t) mutDictSize(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a) {
	return mutArrSize(a.pairs);
}

private:

immutable(bool) hasKey_mut(K, V, alias cmp)(ref const MutDict!(K, V, cmp) a, const K key) {
	immutable Opt!V opt = getAt_mut(a, key);
	return has(opt);
}
