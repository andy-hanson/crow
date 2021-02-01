module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : strEq;
import util.opt : force, has, Opt;
import util.sym :
	AllSymbols,
	isShortAlphaSym,
	isLongAlphaSym,
	Operator,
	operatorForSym,
	prependSet,
	strOfSym,
	Sym,
	symEq,
	symForOperator,
	tryGetSymFromStr;
import util.util : verify;

void testSym(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(test.alloc);

	immutable(Sym) getSym(immutable string a) {
		immutable Opt!Sym opt = tryGetSymFromStr(allSymbols, a);
		immutable Sym res = force(opt);
		verify(strEq(strOfSym(test.alloc, res), a));
		return res;
	}

	immutable Sym nat8 = getSym("nat8");
	verify(isShortAlphaSym(nat8));

	immutable Opt!Sym invalid = tryGetSymFromStr(allSymbols, "abc|def");
	verify(!has(invalid));

	immutable Sym shortAlpha = getSym("abc-def-gh9?");
	verify(isShortAlphaSym(shortAlpha));

	immutable Sym operator = getSym("+");
	immutable Opt!Operator optOperator = operatorForSym(operator);
	verify(force(optOperator) == Operator.plus);
	verify(symEq(operator, symForOperator(Operator.plus)));
	verify(!symEq(shortAlpha, operator));

	immutable Opt!Sym invalidOperator = tryGetSymFromStr(allSymbols, "+=");
	verify(!has(invalidOperator));

	immutable Sym longAlpha = getSym("a9aa");
	verify(isLongAlphaSym(longAlpha));
	verify(symEq(longAlpha, getSym("a9aa")));

	immutable Sym setA = prependSet(allSymbols, getSym("a"));
	verify(symEq(setA, getSym("set-a")));
	verify(isShortAlphaSym(setA));

	immutable Sym setAbcdefgh = prependSet(allSymbols, getSym("abcdefgh"));
	verify(symEq(setAbcdefgh, getSym("set-abcdefgh")));
	verify(isShortAlphaSym(setAbcdefgh));

	immutable Sym setAbcdefghi = prependSet(allSymbols, getSym("abcdefghi"));
	verify(symEq(setAbcdefghi, getSym("set-abcdefghi")));
	verify(isLongAlphaSym(setAbcdefghi));
}
