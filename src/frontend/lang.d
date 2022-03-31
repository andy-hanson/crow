module frontend.lang;

@safe @nogc pure nothrow:

import util.sym : SpecialSym, Sym, symForSpecial;

immutable Sym crowExtension = symForSpecial(SpecialSym.dotCrow);

struct JitOptions {
	immutable OptimizationLevel optimization;
}

enum OptimizationLevel {
	none,
	o2,
}

immutable size_t maxClosureFields = 16;
immutable size_t maxParams = 16;
immutable size_t maxTypeParams = 16;
