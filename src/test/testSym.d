module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.sym : AllSymbols, isShortSym, isLongSym, prependSet, safeCStrOfSym, Sym, sym, symOfStr;
import util.util : verify;

void testSym(ref Test test) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);

	immutable(Sym) staticSym(immutable string a)() {
		verify(sym!a == nonStaticSym!a);
		return sym!a;
	}

	immutable(Sym) nonStaticSym(immutable string a)() {
		immutable Sym res = symOfStr(allSymbols, a);
		verify(safeCStrEq(safeCStrOfSym(test.alloc, allSymbols, res), safeCStr!a));
		return res;
	}

	immutable Sym nat8 = staticSym!"nat8";
	verify(isShortSym(nat8));

	immutable Sym operator = staticSym!"+";
	verify(operator == sym!"+");
	verify(isLongSym(operator));

	immutable Sym shortSym = staticSym!"a9aa";
	verify(shortSym == staticSym!"a9aa");

	immutable Sym cStyle = staticSym!"C_Style";
	verify(isShortSym(cStyle));

	immutable Sym setA = prependSet(allSymbols, staticSym!"a");
	verify(setA == staticSym!"set-a");
	verify(isShortSym(setA));

	immutable Sym setAbcdefgh = prependSet(allSymbols, staticSym!"abcdefgh");
	verify(setAbcdefgh == staticSym!"set-abcdefgh");
	verify(isShortSym(setAbcdefgh));

	immutable Sym setAbcdefghi = prependSet(allSymbols, staticSym!"abcdefghi");
	verify(setAbcdefghi == nonStaticSym!"set-abcdefghi");
	verify(isLongSym(setAbcdefghi));

	immutable Sym mvSize = staticSym!"mv_size";
	verify(isShortSym(mvSize));
	immutable Sym setMvSize = prependSet(allSymbols, mvSize);
	verify(setMvSize == staticSym!"set-mv_size");
	verify(isShortSym(setMvSize));

	immutable Sym setN0 = prependSet(allSymbols, staticSym!"n0");
	verify(setN0 == staticSym!"set-n0");
}
