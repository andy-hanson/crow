module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : strEq;
import util.opt : force, Opt;
import util.sym :
	AllSymbols,
	isShortSym,
	isLongSym,
	Operator,
	operatorForSym,
	prependSet,
	strOfSym,
	Sym,
	symEq,
	symForOperator,
	symOfStr;
import util.util : verify;

void testSym(ref Test test) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);

	immutable(Sym) getSym(immutable string a) {
		immutable Sym res = symOfStr(allSymbols, a);
		verify(strEq(strOfSym(test.alloc, allSymbols, res), a));
		return res;
	}

	immutable Sym nat8 = getSym("nat8");
	verify(isShortSym(nat8));

	immutable Sym shortSym = getSym("abc-def-gh64");
	verify(isShortSym(shortSym));

	immutable Sym operator = getSym("+");
	immutable Opt!Operator optOperator = operatorForSym(operator);
	verify(force(optOperator) == Operator.plus);
	verify(symEq(operator, symForOperator(Operator.plus)));
	verify(!symEq(shortSym, operator));

	immutable Sym longSym = getSym("a9aa");
	verify(isLongSym(longSym));
	verify(symEq(longSym, getSym("a9aa")));

	immutable Sym cStyle = getSym("C_STYLE");
	verify(isLongSym(cStyle));

	immutable Sym setA = prependSet(allSymbols, getSym("a"));
	verify(symEq(setA, getSym("set-a")));
	verify(isShortSym(setA));

	immutable Sym setAbcdefgh = prependSet(allSymbols, getSym("abcdefgh"));
	verify(symEq(setAbcdefgh, getSym("set-abcdefgh")));
	verify(isShortSym(setAbcdefgh));

	immutable Sym setAbcdefghi = prependSet(allSymbols, getSym("abcdefghi"));
	verify(symEq(setAbcdefghi, getSym("set-abcdefghi")));
	verify(isLongSym(setAbcdefghi));

	immutable Sym mvSize = getSym("mv_size");
	verify(isLongSym(mvSize));
	immutable Sym setMvSize = prependSet(allSymbols, mvSize);
	verify(symEq(setMvSize, getSym("set-mv_size")));
	verify(isLongSym(setMvSize));
}
