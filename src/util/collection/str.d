module util.collection.str;

@safe @nogc pure nothrow:

import util.bools : and, Bool;
import util.collection.arr : Arr, at, first, size, tail;
import util.util : todo;

alias CStr = immutable char*;

alias Str = Arr!char;

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

immutable(Str) strLiteral(immutable CStr c) {
	return immutable Str(c, end(c) - c);
}

struct NulTerminatedStr {
	immutable Str str;

	this(immutable Str s) {
		str = s;
		assert(str.at(str.size - 1) == '\0');
	}
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, immutable Str s) {
	return todo;
}

@trusted immutable(Bool) strEqLiteral(immutable Str a, immutable CStr b) {
	return *b == '\0'
		? Bool(a.size == 0)
		: and!(
			() => Bool(a.size != 0),
			() => Bool(a.first == *b),
			() => strEqLiteral(a.tail, b + 1));
}
