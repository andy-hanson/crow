module test.testSymbolSet;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.symbol : Symbol, symbol;
import util.symbolSet : emptySymbolSet, SymbolSet, symbolSet;

void testSymbolSet(ref Test test) {
	assert(symbol!"" !in emptySymbolSet);

	Symbol a = symbol!"a";
	Symbol b = symbol!"b";
	Symbol c = symbol!"c";

	SymbolSet setA = symbolSet(a);
	assert(a in setA);
	assert(b !in setA);

	SymbolSet setB = symbolSet(b);
	assert(b in setB);
	assert(a !in setB);

	SymbolSet setAB = setA | b;
	assert(a in setAB);
	assert(b in setAB);
	assert(c !in setAB);
	assert(setAB.containsAll(setA));
	assert(!setA.containsAll(setAB));

	assert((setB | a) == setAB);
	assert((setB | setA) == setAB);
}
