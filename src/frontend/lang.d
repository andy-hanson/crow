module frontend.lang;

@safe @nogc pure nothrow:

import util.collection.str : Str, strLiteral;

immutable(Str) nozeExtension() {
	return strLiteral(".nz");
}
