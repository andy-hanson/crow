module test.testSymbol;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc : Alloc, withTempAlloc;
import util.symbol :
	AllSymbols,
	appendHexExtension,
	cStringOfSymbol,
	isShortSymbol,
	isLongSymbol,
	prependSet,
	Symbol,
	symbol,
	symbolOfString;

void testSymbol(ref Test test) {
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
	assert(isShortSymbol(nat8));

	Symbol operator = staticSymbol!"+";
	assert(operator == symbol!"+");
	assert(isLongSymbol(operator));

	Symbol shortSymbol = staticSymbol!"a9aa";
	assert(shortSymbol == staticSymbol!"a9aa");

	Symbol cStyle = staticSymbol!"C_Style";
	assert(isShortSymbol(cStyle));

	Symbol setA = prependSet(allSymbols, staticSymbol!"a");
	assert(setA == staticSymbol!"set-a");
	assert(isShortSymbol(setA));

	Symbol setAbcdefgh = prependSet(allSymbols, staticSymbol!"abcdefgh");
	assert(setAbcdefgh == staticSymbol!"set-abcdefgh");
	assert(isShortSymbol(setAbcdefgh));

	Symbol setAbcdefghi = prependSet(allSymbols, staticSymbol!"abcdefghi");
	assert(setAbcdefghi == nonStaticSymbol!"set-abcdefghi");
	assert(isLongSymbol(setAbcdefghi));

	Symbol mvSize = staticSymbol!"mv_size";
	assert(isShortSymbol(mvSize));
	Symbol setMvSize = prependSet(allSymbols, mvSize);
	assert(setMvSize == staticSymbol!"set-mv_size");
	assert(isShortSymbol(setMvSize));

	Symbol setN0 = prependSet(allSymbols, staticSymbol!"n0");
	assert(setN0 == staticSymbol!"set-n0");

	Symbol goodFood = appendHexExtension(allSymbols, staticSymbol!"good", [0xf0, 0x0d]);
	assert(goodFood == nonStaticSymbol!"good.f00d");
}
