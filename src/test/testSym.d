module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.col.str : safeCStr, safeCStrEq;
import util.opt : force, Opt;
import util.sym :
	AllSymbols,
	isShortSym,
	isLongSym,
	Operator,
	operatorForSym,
	prependSet,
	safeCStrOfSym,
	Sym,
	symForOperator,
	symOfStr;
import util.util : verify;

void testSym(ref Test test) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);

	immutable(Sym) getSym(immutable string a)() {
		immutable Sym res = symOfStr(allSymbols, a);
		verify(safeCStrEq(safeCStrOfSym(test.alloc, allSymbols, res), safeCStr!a));
		return res;
	}

	immutable Sym nat8 = getSym!"nat8";
	verify(isShortSym(nat8));

	immutable Sym operator = getSym!"+";
	immutable Opt!Operator optOperator = operatorForSym(operator);
	verify(force(optOperator) == Operator.plus);
	verify(operator == symForOperator(Operator.plus));

	immutable Sym shortSym = getSym!"a9aa";
	verify(shortSym == getSym!"a9aa");

	immutable Sym cStyle = getSym!"C_Style";
	verify(isShortSym(cStyle));

	immutable Sym setA = prependSet(allSymbols, getSym!"a");
	verify(setA == getSym!"set-a");
	verify(isShortSym(setA));

	immutable Sym setAbcdefgh = prependSet(allSymbols, getSym!"abcdefgh");
	verify(setAbcdefgh == getSym!"set-abcdefgh");
	verify(isShortSym(setAbcdefgh));

	immutable Sym setAbcdefghi = prependSet(allSymbols, getSym!"abcdefghi");
	verify(setAbcdefghi == getSym!"set-abcdefghi");
	verify(isLongSym(setAbcdefghi));

	immutable Sym mvSize = getSym!"mv_size";
	verify(isShortSym(mvSize));
	immutable Sym setMvSize = prependSet(allSymbols, mvSize);
	verify(setMvSize == getSym!"set-mv_size");
	verify(isShortSym(setMvSize));

	immutable Sym setN0 = prependSet(allSymbols, getSym!"n0");
	verify(setN0 == getSym!"set-n0");
}
