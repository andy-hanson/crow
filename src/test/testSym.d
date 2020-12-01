module test.testSym;

@safe @nogc pure nothrow:

import test.testUtil : Test;
import util.collection.str : Str, strLiteral, strEqLiteral;
import util.opt : force, has, Opt;
import util.sym : AllSymbols, isLongSym, prependSet, strOfSym, Sym, symEq, tryGetSymFromStr;
import util.util : verify;

void testSym(Alloc)(ref Test!Alloc test) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(test.alloc);

	immutable(Sym) getSym(immutable string a) {
		immutable Str str = strLiteral(a);
		immutable Opt!Sym opt = tryGetSymFromStr(allSymbols, str);
		immutable Sym res = force(opt);
		verify(strEqLiteral(strOfSym(test.alloc, res), a));
		return res;
	}

	immutable Sym nat8 = getSym("nat8");
	verify(!isLongSym(nat8));

	immutable Str invalidStr = strLiteral("abc|def");
	immutable Opt!Sym invalid = tryGetSymFromStr(allSymbols, invalidStr);
	verify(!has(invalid));

	immutable Sym shortAlpha = getSym("abc-def-gh9?");
	verify(!isLongSym(shortAlpha));

	immutable Sym shortOperator = getSym("+-*/<>=!+-*/<>=");
	verify(!isLongSym(shortOperator));
	verify(!symEq(shortAlpha, shortOperator));

	immutable Sym longAlpha = getSym("a9aa");
	verify(isLongSym(longAlpha));
	verify(symEq(longAlpha, getSym("a9aa")));

	immutable Sym longOperator = getSym("+-*/<>=!+-*/<>=!");
	verify(isLongSym(longOperator));
	verify(symEq(longOperator, getSym("+-*/<>=!+-*/<>=!")));

	immutable Sym setA = prependSet(allSymbols, getSym("a"));
	verify(symEq(setA, getSym("set-a")));
	verify(!isLongSym(setA));

	immutable Sym setAbcdefgh = prependSet(allSymbols, getSym("abcdefgh"));
	verify(symEq(setAbcdefgh, getSym("set-abcdefgh")));
	verify(!isLongSym(setAbcdefgh));

	immutable Sym setAbcdefghi = prependSet(allSymbols, getSym("abcdefghi"));
	verify(symEq(setAbcdefghi, getSym("set-abcdefghi")));
	verify(isLongSym(setAbcdefghi));
}
