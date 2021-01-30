module util.collection.str;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : at, begin, emptyArr, first, freeArr, size;
import util.collection.arrUtil : compareArr, rtail, tail;
import util.comparison : Comparison;
import util.memory : memcpy;
import util.util : verify;

alias CStr = immutable(char)*;
alias Str = string;

immutable(Comparison) compareStr(ref immutable Str a, ref immutable Str b) {
	return compareArr!char(a, b, (ref immutable char ca, ref immutable char cb) =>
		ca < cb ? Comparison.less : ca > cb ? Comparison.greater : Comparison.equal);
}

immutable Str emptyStr = emptyArr!char;
immutable(NulTerminatedStr) emptyNulTerminatedStr() {
	return immutable NulTerminatedStr(strLiteral("\0"));
}

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

@system void freeCStr(Alloc)(ref Alloc alloc, immutable CStr c) {
	freeArr(alloc, nulTerminatedStrOfCStr(c).str);
}

@trusted immutable(Str) strLiteral(immutable string s) {
	return s;
}

@trusted immutable(Str) strOfCStr(immutable CStr c) {
	immutable size_t size = end(c) - c;
	return c[0..size];
}

@trusted immutable(CStr) cStrOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return begin(a.str);
}

@trusted immutable(NulTerminatedStr) nulTerminatedStrOfCStr(immutable CStr c) {
	immutable size_t size = end(c) - c;
	return immutable NulTerminatedStr(c[0..size + 1]);
}

struct NulTerminatedStr {
	@safe @nogc pure nothrow:
	immutable Str str;

	this(immutable Str s) immutable {
		str = s;
		verify(at(str, size(str) - 1) == '\0');
	}
}

immutable(Str) strOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return rtail(a.str);
}

@trusted immutable(NulTerminatedStr) copyToNulTerminatedStr(Alloc)(ref Alloc alloc, ref immutable Str s) {
	char* res = cast(char*) alloc.allocateBytes(size(s) + 1);
	memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, size(s));
	res[size(s)] = '\0';
	return immutable NulTerminatedStr(cast(immutable) res[0..size(s) + 1]);
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, ref immutable Str s) {
	return copyToNulTerminatedStr(alloc, s).asCStr;
}

@trusted immutable(Bool) strEqCStr(immutable Str a, immutable CStr b) {
	return *b == '\0'
		? Bool(size(a) == 0)
		: Bool(
			size(a) != 0 &&
			first(a) == *b &&
			strEqCStr(tail(a), b + 1));
}

immutable(Bool) strEqLiteral(immutable Str a, immutable string b) {
	return strEq(a, strLiteral(b));
}

immutable(Bool) strEq(immutable Str a, immutable Str b) {
	return Bool(size(a) == size(b) && (size(a) == 0 || (at(a, 0) == at(b, 0) && strEq(tail(a), tail(b)))));
}

immutable(Str) stripNulTerminator(immutable NulTerminatedStr a) {
	return rtail(a.str);
}

@trusted immutable(Str) copyStr(Alloc)(ref Alloc alloc, immutable Str s) {
	char* begin = cast(char*) alloc.allocateBytes(char.sizeof * size(s));
	foreach (immutable size_t i; 0..size(s))
		begin[i] = at(s, i);
	return cast(immutable) begin[0..size(s)];
}
