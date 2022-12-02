module util.col.dictBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutDict : getOrAddAndDidAdd, moveToDict, MutDict, ValueAndDidAdd;
import util.col.dict : Dict;
import util.opt : has, none, Opt, some;
import util.util : verify;

struct DictBuilder(K, V) {
	@disable this(ref const DictBuilder);

	private:
	MutDict!(immutable K, immutable V) builder;
}

void mustAddToDict(K, V)(ref Alloc alloc, ref DictBuilder!(K, V) a, immutable K key, immutable V value) {
	Opt!V res = tryAddToDict(alloc, a, key, value);
	verify(!has(res));
}

// If there is already a value there, does nothing and returns it
Opt!V tryAddToDict(K, V)(ref Alloc alloc, ref DictBuilder!(K, V) a, immutable K key, immutable V value) {
	ValueAndDidAdd!(immutable V) v = getOrAddAndDidAdd(alloc, a.builder, key, () => value);
	return v.didAdd ? none!V : some(v.value);
}

Dict!(K, V) finishDict(K, V)(
	ref Alloc alloc,
	ref DictBuilder!(K, V) a,
) =>
	moveToDict!(K, V)(alloc, a.builder);
