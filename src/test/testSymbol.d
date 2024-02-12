module test.testSymbol;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.alloc.alloc : Alloc, withTempAlloc;
import util.symbol :
	AllSymbols,
	isShortSymbol,
	isLongSymbol,
	prependSet,
	stringOfSymbol,
	Symbol,
	symbol,
	symbolOfString,
	symbolSize;

void testSymbol(ref Test test) {
	withTempAlloc!void(test.metaAlloc, (ref Alloc alloc) @safe {
		scope AllSymbols allSymbols = AllSymbols(&alloc);
		return inner(test, allSymbols);
	});
}

private:

void inner(ref Test test, scope ref AllSymbols allSymbols) {
	Symbol staticSymbol(string a)() {
		Symbol res = symbol!a;
		assert(res == nonStaticSymbol(a));
		return res;
	}

	Symbol nonStaticSymbol(string a) {
		Symbol res = symbolOfString(allSymbols, a);
		assert(stringOfSymbol(test.alloc, allSymbols, res) == a);
		assert(symbolSize(allSymbols, res) == a.length);
		return res;
	}

	Symbol nat8 = staticSymbol!"nat8";
	assert(isShortSymbol(nat8));

	Symbol operator = staticSymbol!"+";
	assert(operator == symbol!"+");
	assert(isLongSymbol(operator));

	Symbol shortSymbol = staticSymbol!"a9aa";
	assert(shortSymbol == staticSymbol!"a9aa");

	Symbol cStyle = staticSymbol!"C_St";
	assert(isShortSymbol(cStyle));

	Symbol setA = prependSet(allSymbols, staticSymbol!"a");
	assert(setA == staticSymbol!"set-a");
	assert(isShortSymbol(setA));
	Symbol set = prependSet(allSymbols, staticSymbol!"");
	assert(set == staticSymbol!"set-");
	assert(isShortSymbol(set));

	Symbol setAbcdefgh = prependSet(allSymbols, staticSymbol!"ab");
	assert(setAbcdefgh == staticSymbol!"set-ab");
	assert(isShortSymbol(setAbcdefgh));

	Symbol setAbcdefghi = prependSet(allSymbols, staticSymbol!"abc");
	assert(setAbcdefghi == nonStaticSymbol("set-abc"));
	assert(isLongSymbol(setAbcdefghi));

	Symbol setN0 = prependSet(allSymbols, staticSymbol!"n0");
	assert(isLongSymbol(setN0));
	assert(setN0 == staticSymbol!"set-n0");
}
