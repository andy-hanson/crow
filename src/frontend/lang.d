module frontend.lang;

@safe @nogc pure nothrow:

import util.symbol : Symbol, symbol;

Symbol crowConfigBaseName() => symbol!"crow-config.json";

immutable struct JitOptions {
	OptimizationLevel optimization;
}

enum CVersion { c99, c11 }

immutable struct CCompileOptions {
	OptimizationLevel optimizationLevel;
	CVersion cVersion;
}

enum OptimizationLevel {
	none,
	o2,
}

size_t maxSpecDepth() => 8;
