module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc : Alloc, withTempAlloc;
import util.col.str : safeCStr, safeCStrEq;
import util.sym : AllSymbols, appendHexExtension, isShortSym, isLongSym, prependSet, safeCStrOfSym, Sym, sym, symOfStr;

void testSym(ref Test test) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc alloc) @safe {
		scope AllSymbols allSymbols = AllSymbols(&alloc);
		return inner(test, allSymbols);
	});
}

private:

void inner(ref Test test, scope ref AllSymbols allSymbols) {
	Sym staticSym(string a)() @safe {
		assert(sym!a == nonStaticSym!a);
		return sym!a;
	}

	Sym nonStaticSym(string a)() @safe {
		Sym res = symOfStr(allSymbols, a);
		assert(safeCStrEq(safeCStrOfSym(test.alloc, allSymbols, res), safeCStr!a));
		return res;
	}

	Sym nat8 = staticSym!"nat8";
	assert(isShortSym(nat8));

	Sym operator = staticSym!"+";
	assert(operator == sym!"+");
	assert(isLongSym(operator));

	Sym shortSym = staticSym!"a9aa";
	assert(shortSym == staticSym!"a9aa");

	Sym cStyle = staticSym!"C_Style";
	assert(isShortSym(cStyle));

	Sym setA = prependSet(allSymbols, staticSym!"a");
	assert(setA == staticSym!"set-a");
	assert(isShortSym(setA));

	Sym setAbcdefgh = prependSet(allSymbols, staticSym!"abcdefgh");
	assert(setAbcdefgh == staticSym!"set-abcdefgh");
	assert(isShortSym(setAbcdefgh));

	Sym setAbcdefghi = prependSet(allSymbols, staticSym!"abcdefghi");
	assert(setAbcdefghi == nonStaticSym!"set-abcdefghi");
	assert(isLongSym(setAbcdefghi));

	Sym mvSize = staticSym!"mv_size";
	assert(isShortSym(mvSize));
	Sym setMvSize = prependSet(allSymbols, mvSize);
	assert(setMvSize == staticSym!"set-mv_size");
	assert(isShortSym(setMvSize));

	Sym setN0 = prependSet(allSymbols, staticSym!"n0");
	assert(setN0 == staticSym!"set-n0");

	Sym goodFood = appendHexExtension(allSymbols, staticSym!"good", [0xf0, 0x0d]);
	assert(goodFood == nonStaticSym!"good.f00d");
}
