module frontend.lang;

@safe @nogc pure nothrow:

import util.sym : Sym, sym;

immutable Sym crowExtension = sym!".crow";

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
