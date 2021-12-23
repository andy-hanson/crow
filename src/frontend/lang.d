module frontend.lang;

@safe @nogc pure nothrow:

import util.col.str : SafeCStr, safeCStr;

immutable(SafeCStr) crowExtension = safeCStr!".crow";

struct JitOptions {
	immutable OptimizationLevel optimization;
}

enum OptimizationLevel {
	none,
	o2,
}
