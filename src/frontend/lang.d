module frontend.lang;

@safe @nogc pure nothrow:

import util.symbol : Symbol, symbol;

Symbol crowConfigBaseName() => symbol!"crow-config.json";

immutable struct JitOptions {
	OptimizationLevel optimization;
}

immutable struct CCompileOptions {
	OptimizationLevel optimizationLevel;
}

enum OptimizationLevel {
	none,
	o2,
}

size_t maxClosureFields() => 16;
size_t maxSpecImpls() => 32;
size_t maxSpecDepth() => 8;
size_t maxTypeParams() => 10;
size_t maxTupleSize() => 9;
