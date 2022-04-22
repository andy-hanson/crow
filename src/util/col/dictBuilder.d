module util.col.dictBuilder;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutDict : getOrAddAndDidAdd, moveToDict, MutDict, ValueAndDidAdd;
import util.col.dict : Dict;
import util.opt : has, none, Opt, some;
import util.ptr : hashPtr, Ptr, ptrEquals;
import util.sym : hashSym, Sym, symEq;
import util.util : verify;

struct DictBuilder(K, V, alias equal, alias hash) {
	@disable this(ref const DictBuilder);

	private:
	MutDict!(immutable K, immutable V, equal, hash) builder;
}

alias PtrDictBuilder(K, V) =
	DictBuilder!(Ptr!K, V, ptrEquals!K, hashPtr!K);

alias SymDictBuilder(V) =
	DictBuilder!(Sym, V, symEq, hashSym);

void mustAddToDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, equal, hash) a,
	immutable K key,
	immutable V value,
) {
	immutable Opt!V res = tryAddToDict(alloc, a, key, value);
	verify(!has(res));
}

// If there is already a value there, does nothing and returns it
immutable(Opt!V) tryAddToDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, equal, hash) a,
	immutable K key,
	immutable V value,
) {
	ValueAndDidAdd!(immutable V) v = getOrAddAndDidAdd(alloc, a.builder, key, () => value);
	return v.didAdd ? none!V : some!V(v.value);
}

immutable(Dict!(K, V, equal, hash)) finishDict(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	ref DictBuilder!(K, V, equal, hash) a,
) {
	return moveToDict!(K, V, equal, hash)(alloc, a.builder);
}
