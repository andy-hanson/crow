module util.collection.dictBuilder;

@safe @nogc pure nothrow:

import util.collection.arr : at, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.mutArr : moveToArr, MutArr, mutArrAt, mutArrSize, push;
import util.collection.dict : Dict, KeyValuePair;
import util.comparison : Comparison;
import util.util : verify;

struct DictBuilder(K, V, alias cmp) {
	@disable this(ref const DictBuilder!(K, V, cmp));

	private:
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
	immutable KeyValuePair!(K, V)[] allPairs = finishArr(alloc, db.builder);
	MutArr!(immutable KeyValuePair!(K, V)) res;
	foreach (immutable size_t i; 0 .. allPairs.size) {
		immutable KeyValuePair!(K, V) pair = at(allPairs, i);
		bool isConflict = false;
		foreach (immutable size_t j; 0 .. mutArrSize(res)) {
			immutable KeyValuePair!(K, V) resPair = mutArrAt(res, j);
			if (cmp(pair.key, resPair.key) == Comparison.equal) {
				cbConflict(pair.key, resPair.value, pair.value);
				isConflict = true;
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
	immutable KeyValuePair!(K, V)[] allPairs = finishArr(alloc, a.builder);
	foreach (immutable size_t i; 0 .. size(allPairs))
		foreach (immutable size_t j; 0 .. i)
			verify(cmp(at(allPairs, i).key, at(allPairs, j).key) != Comparison.equal);
	return immutable Dict!(K, V, cmp)(allPairs);
}
