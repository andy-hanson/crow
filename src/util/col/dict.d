module util.col.dict;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutDict :
	addToMutDict, getAt_mut, hasKey_mut, moveToDict, mustGetAt_mut, MutDict, mutDictEach, mutDictSize;
public import util.col.mutDict : KeyValuePair;
import util.opt : Opt;
import util.ptr : hashPtr, Ptr, ptrEquals;
import util.sym : hashSym, Sym, symEq;

struct Dict(K, V, alias equal, alias hash) {
	private immutable MutDict!(K, V, equal, hash) inner;

	@trusted immutable(Opt!V) opIndex(const K key) immutable {
		return cast(immutable) getAt_mut(inner, key);
	}
}

alias PtrDict(K, V) =
	Dict!(Ptr!K, V, ptrEquals!K, hashPtr!K);

alias SymDict(V) =
	Dict!(Sym, V, symEq, hashSym);

immutable(bool) hasKey(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a, const K key) {
	return hasKey_mut(a.inner, key);
}

@trusted immutable(V) mustGetAt(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a, const K key) {
	return cast(immutable) mustGetAt_mut(a.inner, key);
}

immutable(size_t) dictSize(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a) {
	return mutDictSize(a.inner);
}

void dictEach(K, V, alias equal, alias hash)(
	ref immutable Dict!(K, V, equal, hash) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	mutDictEach!(K, V, equal, hash)(a.inner, cb);
}

immutable(Dict!(K, V, equal, hash)) dictLiteral(K, V, alias equal, alias hash)(
	ref Alloc alloc,
	immutable K key,
	immutable V value,
) {
	MutDict!(immutable K, immutable V, equal, hash) res;
	addToMutDict(alloc, res, key, value);
	return moveToDict!(K, V, equal, hash)(alloc, res);
}

immutable(Dict!(K, VOut, equal, hash)) mapValues(K, VIn, VOut, alias equal, alias hash)(
	ref Alloc alloc,
	immutable Dict!(K, VIn, equal, hash) a,
	scope immutable(VOut) delegate(immutable K, ref immutable VIn) @safe @nogc pure nothrow cb,
) {
	MutDict!(immutable K, immutable VOut, equal, hash) res;
	dictEach!(K, VIn, equal, hash)(a, (immutable K key, ref immutable VIn value) {
		addToMutDict(alloc, res, key, cb(key, value));
	});
	return moveToDict!(K, VOut, equal, hash)(alloc, res);
}
