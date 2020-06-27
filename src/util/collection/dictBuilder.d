module util.collection.dictBuilder;

@safe @nogc pure nothrow:

import util.collection.arr : Arr, at, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.mutArr : moveToArr, MutArr, mutArrSize;
import util.collection.dict : Dict, KeyValuePair;
import util.comparison : Comparison;

struct DictBuilder(K, V, alias cmp) {
	ArrBuilder!(KeyValuePair!(K, V)) builder;
}

void addToDict(Alloc, K, V, alias cmp)(
	ref DictBuilder!(K, V, cmp) db,
	ref Alloc alloc,
	immutable K key,
	immutable V value,
) {
	return db.builder.add(alloc, immutable KeyValuePair!(K, V)(key, value));
}

immutable(Dict!(K, V, cmp)) finishDict(Alloc, K, V, alias cmp)(
	ref DictBuilder!(K, V, cmp) db,
	ref Alloc alloc,
	scope void delegate(ref immutable K, ref immutable V, ref immutable V) @safe @nogc pure nothrow cbConflict,
) {
	Arr!(KeyValuePair!(K, V)) allPairs = db.builder.finishArr;
	MutArr!(KeyValuePair!(K, V)) res;
	foreach (immutable size_t i; 0..allPairs.size) {
		immutable KeyValuePair!(K, V) pair = allPairs.at(i);
		Bool isConflict = False;
		foreach (immutable size_t j; 0..res.mutArrSize) {
			immutable KeyValuePair!(K, V) resPair = res.mutArrAt(j);
			if (cmp(pair.key, resPair.key) == Comparison.equal) {
				cbConflict(pair.key, resPair.value, pair.value);
				isConflict = True;
				break;
			}
		}
		if (!isConflict)
			res.push(alloc, pair);
	}
	return immutable Dict!(K, V, cmp)(res.moveToArr);
}

immutable(Dict!(K, V, cmp)) finishDictShouldBeNoConflict(Alloc, K, V, alias cmp)(
	ref DictBuilder!(K, V, cmp) a,
	ref Alloc alloc,
) {
	immutable Arr!(KeyValuePair!(K, V)) allPairs = a.builder.finishArr(alloc);
	foreach (immutable size_t i; 0..allPairs.size)
		foreach (immutable size_t j; 0..i)
			assert(cmp(allPairs.at(i).key, allPairs.at(j).key) != Comparison.equal);
	return immutable Dict!(K, V, cmp)(allPairs);
}
