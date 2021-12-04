module frontend.lang;

@safe @nogc pure nothrow:

immutable(string) crowExtension() {
	return ".crow";
}

struct JitOptions {
	immutable OptimizationLevel optimization;
}

enum OptimizationLevel {
	none,
	o2,
}
