module util.col.mutSet;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.mutDict : keysArray, MutDict, setInDict;
import util.sym : hashSym, Sym, symEq;

private struct MutSet(T, alias equal, alias hash) {
	private MutDict!(T, Empty, equal, hash) inner;
}

private struct Empty {}

alias MutSymSet = MutSet!(immutable Sym, symEq, hashSym);

void addToMutSymSetOkIfPresent(	ref Alloc alloc, ref MutSymSet set, immutable Sym sym) {
	addToMutSetOkIfPresent!(immutable Sym, symEq, hashSym)(alloc, set, sym);
}

immutable(T[]) moveSetToArr(T, alias equal, alias hash)(ref Alloc alloc, ref MutSet!(immutable T, equal, hash) a) {
	return keysArray(alloc, a.inner);
}

void addToMutSetOkIfPresent(T, alias equal, alias hash)(
	ref Alloc alloc,
	ref MutSet!(T, equal, hash) a,
	immutable T value,
) {
	setInDict(alloc, a.inner, value, Empty());
}
