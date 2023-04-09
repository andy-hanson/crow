module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.sym : AllSymbols, appendHexExtension, isShortSym, isLongSym, prependSet, safeCStrOfSym, Sym, sym, symOfStr;
import util.util : verify;

void testSym(ref Test test) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);

	Sym staticSym(string a)() {
		verify(sym!a == nonStaticSym!a);
		return sym!a;
	}

	Sym nonStaticSym(string a)() {
		Sym res = symOfStr(allSymbols, a);
		verify(safeCStrEq(safeCStrOfSym(test.alloc, allSymbols, res), safeCStr!a));
		return res;
	}

	Sym nat8 = staticSym!"nat8";
	verify(isShortSym(nat8));

	Sym operator = staticSym!"+";
	verify(operator == sym!"+");
	verify(isLongSym(operator));

	Sym shortSym = staticSym!"a9aa";
	verify(shortSym == staticSym!"a9aa");

	Sym cStyle = staticSym!"C_Style";
	verify(isShortSym(cStyle));

	Sym setA = prependSet(allSymbols, staticSym!"a");
	verify(setA == staticSym!"set-a");
	verify(isShortSym(setA));

	Sym setAbcdefgh = prependSet(allSymbols, staticSym!"abcdefgh");
	verify(setAbcdefgh == staticSym!"set-abcdefgh");
	verify(isShortSym(setAbcdefgh));

	Sym setAbcdefghi = prependSet(allSymbols, staticSym!"abcdefghi");
	verify(setAbcdefghi == nonStaticSym!"set-abcdefghi");
	verify(isLongSym(setAbcdefghi));

	Sym mvSize = staticSym!"mv_size";
	verify(isShortSym(mvSize));
	Sym setMvSize = prependSet(allSymbols, mvSize);
	verify(setMvSize == staticSym!"set-mv_size");
	verify(isShortSym(setMvSize));

	Sym setN0 = prependSet(allSymbols, staticSym!"n0");
	verify(setN0 == staticSym!"set-n0");

	Sym goodFood = appendHexExtension(allSymbols, staticSym!"good", [0xf0, 0x0d]);
	verify(goodFood == nonStaticSym!"good.f00d");
}
