module frontend.lang;

@safe @nogc pure nothrow:

import util.sym : Sym, sym;

Sym crowExtension() => sym!".crow";

immutable struct JitOptions {
	OptimizationLevel optimization;
}

enum OptimizationLevel {
	none,
	o2,
}

size_t maxClosureFields() => 16;
size_t maxSpecImpls() => 16;
size_t maxSpecDepth() => 8;
size_t maxTypeParams() => 16;
