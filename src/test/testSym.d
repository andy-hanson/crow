module test.testSym;

@safe @nogc pure nothrow:

import util.alloc.stackAlloc : StackAlloc;
import util.collection.str : strLiteral, strEqLiteral;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe_mut;
import util.sym : AllSymbols, isLongSym, strOfSym, Sym, symEq, tryGetSymFromStr;
import util.util : verify;

void testSym() {
	alias Alloc = StackAlloc!("test", 1024);
	Alloc alloc;
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(ptrTrustMe_mut(alloc));

	immutable(Sym) getSym(immutable string a) {
		immutable Opt!Sym opt = tryGetSymFromStr(allSymbols, strLiteral(a));
		immutable Sym res = force(opt);
		verify(strEqLiteral(strOfSym(alloc, res), a));
		return res;
	}

	immutable Sym nat8 = getSym("nat8");
	verify(!isLongSym(nat8));

	immutable Opt!Sym invalid = tryGetSymFromStr(allSymbols, strLiteral("abc|def"));
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
}
