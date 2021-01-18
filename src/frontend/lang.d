module frontend.lang;

@safe @nogc pure nothrow:

import util.collection.str : Str, strLiteral;

immutable(Str) crowExtension() {
	return strLiteral(".crow");
}
