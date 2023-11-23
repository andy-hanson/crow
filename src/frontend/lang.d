module frontend.lang;

@safe @nogc pure nothrow:

import util.sym : Sym, sym;

Sym cExtension() => sym!".c";
Sym crowExtension() => sym!".crow";

Sym crowConfigBaseName() => sym!"crow-config.json";

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
