module util.col.dict;

@safe @nogc pure nothrow:

import util.col.mutDict : getAt_mut, hasKey_mut, mustGetAt_mut, MutDict, mutDictEach;
public import util.col.mutDict : KeyValuePair;
import util.opt : Opt;
import util.ptr : hashPtr, Ptr, ptrEquals;
import util.sym : hashSym, Sym, symEq;

struct Dict(K, V, alias equal, alias hash) {
	private immutable MutDict!(K, V, equal, hash) inner;
}

alias PtrDict(K, V) =
	Dict!(Ptr!K, V, ptrEquals!K, hashPtr!K);

alias SymDict(V) =
	Dict!(Sym, V, symEq, hashSym);

immutable(bool) hasKey(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a, const K key) {
	return hasKey_mut(a.inner, key);
}

@trusted immutable(Opt!V) getAt(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a, const K key) {
	return cast(immutable) getAt_mut(a.inner, key);
}

@trusted immutable(V) mustGetAt(K, V, alias equal, alias hash)(ref immutable Dict!(K, V, equal, hash) a, const K key) {
	return cast(immutable) mustGetAt_mut(a.inner, key);
}

void dictEach(K, V, alias equal, alias hash)(
	ref immutable Dict!(K, V, equal, hash) a,
	scope void delegate(immutable K, ref immutable V) @safe @nogc pure nothrow cb,
) {
	mutDictEach!(K, V, equal, hash)(a.inner, cb);
}
