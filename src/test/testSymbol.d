module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc : Alloc, withTempAlloc;
import util.symbol :
	AllSymbols, appendHexExtension, cStringOfSymbol, isShortSym, isLongSym, prependSet, Symbol, symbol, symbolOfString;

void testSym(ref Test test) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc alloc) @safe {
		scope AllSymbols allSymbols = AllSymbols(&alloc);
		return inner(test, allSymbols);
	});
}

private:

void inner(ref Test test, scope ref AllSymbols allSymbols) {
	Symbol staticSymbol(string a)() @safe {
		assert(symbol!a == nonStaticSymbol!a);
		return symbol!a;
	}

	Symbol nonStaticSymbol(string a)() @safe {
		Symbol res = symbolOfString(allSymbols, a);
		assert(cStringOfSymbol(test.alloc, allSymbols, res) == a);
		return res;
	}

	Symbol nat8 = staticSymbol!"nat8";
	assert(isShortSym(nat8));

	Symbol operator = staticSymbol!"+";
	assert(operator == symbol!"+");
	assert(isLongSym(operator));

	Symbol shortSym = staticSymbol!"a9aa";
	assert(shortSym == staticSymbol!"a9aa");

	Symbol cStyle = staticSymbol!"C_Style";
	assert(isShortSym(cStyle));

	Symbol setA = prependSet(allSymbols, staticSymbol!"a");
	assert(setA == staticSymbol!"set-a");
	assert(isShortSym(setA));

	Symbol setAbcdefgh = prependSet(allSymbols, staticSymbol!"abcdefgh");
	assert(setAbcdefgh == staticSymbol!"set-abcdefgh");
	assert(isShortSym(setAbcdefgh));

	Symbol setAbcdefghi = prependSet(allSymbols, staticSymbol!"abcdefghi");
	assert(setAbcdefghi == nonStaticSymbol!"set-abcdefghi");
	assert(isLongSym(setAbcdefghi));

	Symbol mvSize = staticSymbol!"mv_size";
	assert(isShortSym(mvSize));
	Symbol setMvSize = prependSet(allSymbols, mvSize);
	assert(setMvSize == staticSymbol!"set-mv_size");
	assert(isShortSym(setMvSize));

	Symbol setN0 = prependSet(allSymbols, staticSymbol!"n0");
	assert(setN0 == staticSymbol!"set-n0");

	Symbol goodFood = appendHexExtension(allSymbols, staticSymbol!"good", [0xf0, 0x0d]);
	assert(goodFood == nonStaticSymbol!"good.f00d");
}
