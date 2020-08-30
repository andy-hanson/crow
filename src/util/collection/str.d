module util.collection.str;

@safe @nogc pure nothrow:

import core.stdc.string : memcpy;

import util.bools : and, Bool, False, True;
import util.collection.arr : Arr, at, begin, empty, emptyArr, first, size;
import util.collection.arrUtil : rtail, slice, tail;
import util.collection.mutArr : MutArr;
import util.comparison : compareChar, compareOr, Comparison;
import util.util : todo;

alias CStr = immutable(char)*;
alias Str = Arr!char;
alias MutStr = MutArr!char;

immutable Str emptyStr = emptyArr!char;
immutable(NulTerminatedStr) emptyNulTerminatedStr() {
	return immutable NulTerminatedStr(strLiteral("\0"));
}

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

@trusted immutable(Str) strLiteral(immutable string s) {
	return immutable Str(s.ptr, s.length);
}

@trusted immutable(Str) strOfCStr(immutable CStr c) {
	return immutable Str(c, end(c) - c);
}

immutable(NulTerminatedStr) nulTerminatedStrOfCStr(immutable CStr c) {
	return immutable NulTerminatedStr(immutable Str(c, end(c) - c + 1));
}

struct NulTerminatedStr {
	@safe @nogc pure nothrow:
	immutable Str str;

	this(immutable Str s) immutable {
		str = s;
		assert(str.at(str.size - 1) == '\0');
	}
}

@trusted immutable(NulTerminatedStr) strToNulTerminatedStr(Alloc)(ref Alloc alloc, immutable Str s) {
	char* res = cast(char*) alloc.allocate(size(s) + 1);
	memcpy(res, s.begin, size(s));
	res[s.size] = '\0';
	return immutable NulTerminatedStr(immutable Str(cast(immutable) res, s.size + 1));
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, immutable Str s) {
	return strToNulTerminatedStr(alloc, s).asCStr;
}

@trusted immutable(Bool) strEqCStr(immutable Str a, immutable CStr b) {
	return *b == '\0'
		? Bool(a.size == 0)
		: Bool(
			a.size != 0 &&
			a.first == *b &&
			strEqCStr(a.tail, b + 1));
}

immutable(Bool) strEqLiteral(immutable Str a, immutable string b) {
	if (a.size == b.length) {
		foreach (immutable size_t i; 0..a.size)
			if (a.at(i) != b[i])
				return False;
		return True;
	} else
		return False;
}

immutable(Bool) strEq(immutable Str a, immutable Str b) {
	return Bool(a.size == b.size && (a.size == 0 || (a.at(0) == b.at(0) && strEq(a.tail, b.tail))));
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

immutable(Str) stripNulTerminator(immutable NulTerminatedStr a) {
	return a.str.rtail;
}

@trusted immutable(Str) copyStr(Alloc)(ref Alloc alloc, immutable Str s) {
	char* begin = cast(char*) alloc.allocate(char.sizeof * s.size);
	foreach (immutable size_t i; 0..s.size)
		begin[i] = s.at(i);
	return immutable Str(cast(immutable) begin, s.size);
}

immutable(NulTerminatedStr) copyNulTerminatedStr(Alloc)(ref Alloc alloc, immutable NulTerminatedStr s) {
	return immutable NulTerminatedStr(copyStr(alloc, s.str));
}

immutable(Bool) endsWith(immutable Str a, immutable Str b) {
	return Bool(a.size >= b.size &&
		strEq(a.slice(a.size - b.size, b.size), b));
}
