module frontend.lang;

@safe @nogc pure nothrow:

import util.symbol : Symbol, symbol;

Symbol crowConfigBaseName() => symbol!"crow-config.json";

immutable struct JitOptions {
	OptimizationLevel optimization;
}

enum CVersion { c99, c11 }

immutable struct CCompileOptions { // TODO: I think I can get rid of 'cVersion'? test with the newer c2m. This this would just be 'CompileOptions'
	OptimizationLevel optimizationLevel; // TODO: this could actually go in 'version_'. Then I wouldn't need CCompileOptions for anything.
	CVersion cVersion;
}

enum OptimizationLevel {
	none,
	o2,
}

size_t maxSpecDepth() => 8;
