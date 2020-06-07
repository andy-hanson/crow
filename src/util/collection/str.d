module util.collection.str;

@safe @nogc pure nothrow:

import core.stdc.string : memcpy;

import util.bools : and, Bool;
import util.collection.arr : Arr, at, begin, empty, first, size, tail;
import util.collection.mutArr : MutArr;
import util.comparison : compareChar, compareOr, Comparison;
import util.util : todo;

alias CStr = immutable char*;
alias Str = Arr!char;
alias MutStr(Alloc) = MutArr!(char, Alloc);

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

immutable(Str) strLiteral(immutable CStr c) {
	return immutable Str(c, end(c) - c);
}

struct NulTerminatedStr {
	@safe @nogc pure nothrow:
	immutable Str str;

	this(immutable Str s) {
		str = s;
		assert(str.at(str.size - 1) == '\0');
	}
}

@trusted immutable(NulTerminatedStr) strToNulTerminatedStr(Alloc)(ref Alloc alloc, immutable Str s) {
	char* res = cast(char*) alloc.allocate(s.size + 1);
	memcpy(res, s.begin, s.size);
	res[s.size] = '\0';
	return NulTerminatedStr(immutable Str(cast(immutable char*) res, s.size + 1));
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, immutable Str s) {
	return strToNulTerminatedStr(alloc, s).asCStr;
}

@trusted immutable(Bool) strEqLiteral(immutable Str a, immutable CStr b) {
	return *b == '\0'
		? Bool(a.size == 0)
		: and!(
			() => Bool(a.size != 0),
			() => Bool(a.first == *b),
			() => strEqLiteral(a.tail, b + 1));
}

//TODO:KILL?
immutable(Comparison) compareStr(immutable Str a, immutable Str b) {
	return a.empty
		? b.empty
			? Comparison.equal
			: Comparison.less
		: b.empty
			? Comparison.greater
			: compareOr(
				compareChar(a.first, b.first),
				() => compareStr(a.tail, b.tail));

}
