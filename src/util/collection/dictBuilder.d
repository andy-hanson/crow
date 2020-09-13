module util.collection.dictBuilder;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push;
import util.collection.dict : Dict, KeyValuePair;
import util.comparison : Comparison;
import util.util : verify;

struct DictBuilder(K, V, alias cmp) {
	ArrBuilder!(KeyValuePair!(K, V)) builder;
}

void addToDict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, cmp) db,
	immutable K key,
	immutable V value,
) {
	return add(alloc, db.builder, immutable KeyValuePair!(K, V)(key, value));
}

immutable(Dict!(K, V, cmp)) finishDict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, cmp) db,
	scope void delegate(ref immutable K, ref immutable V, ref immutable V) @safe @nogc pure nothrow cbConflict,
) {
	immutable Arr!(KeyValuePair!(K, V)) allPairs = finishArr(alloc, db.builder);
	MutArr!(immutable KeyValuePair!(K, V)) res;
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
			push(alloc, res, pair);
	}
	return immutable Dict!(K, V, cmp)(moveToArr!(KeyValuePair!(K, V), Alloc)(alloc, res));
}

immutable(Dict!(K, V, cmp)) finishDictShouldBeNoConflict(Alloc, K, V, alias cmp)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, cmp) a,
) {
	immutable Arr!(KeyValuePair!(K, V)) allPairs = finishArr(alloc, a.builder);
	foreach (immutable size_t i; 0..allPairs.size)
		foreach (immutable size_t j; 0..i)
			verify(cmp(allPairs.at(i).key, allPairs.at(j).key) != Comparison.equal);
	return immutable Dict!(K, V, cmp)(allPairs);
}
