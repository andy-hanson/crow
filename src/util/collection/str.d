module util.collection.str;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, at, begin, emptyArr, first, freeArr, size;
import util.collection.arrUtil : rtail, slice, tail;
import util.memory : memcpy;
import util.util : verify;

alias CStr = immutable(char)*;
alias Str = Arr!char;

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
	return immutable Str(s.ptr, s.length);
}

@trusted immutable(Str) strOfCStr(immutable CStr c) {
	return immutable Str(c, end(c) - c);
}

@trusted immutable(CStr) cStrOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return begin(a.str);
}

immutable(NulTerminatedStr) nulTerminatedStrOfCStr(immutable CStr c) {
	return immutable NulTerminatedStr(immutable Str(c, end(c) - c + 1));
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
	memcpy(cast(ubyte*) res, cast(ubyte*) begin(s), size(s));
	res[size(s)] = '\0';
	return immutable NulTerminatedStr(immutable Str(cast(immutable) res, s.size + 1));
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, ref immutable Str s) {
	return copyToNulTerminatedStr(alloc, s).asCStr;
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
	return strEq(a, strLiteral(b));
}

immutable(Bool) strEq(immutable Str a, immutable Str b) {
	return Bool(size(a) == size(b) && (size(a) == 0 || (at(a, 0) == at(b, 0) && strEq(tail(a), tail(b)))));
}

immutable(Str) stripNulTerminator(immutable NulTerminatedStr a) {
	return rtail(a.str);
}

@trusted immutable(Str) copyStr(Alloc)(ref Alloc alloc, immutable Str s) {
	char* begin = cast(char*) alloc.allocateBytes(char.sizeof * s.size);
	foreach (immutable size_t i; 0..s.size)
		begin[i] = at(s, i);
	return immutable Str(cast(immutable) begin, size(s));
}

immutable(Bool) endsWith(immutable Str a, immutable Str b) {
	return Bool(size(a) >= size(b) &&
		strEq(a.slice(size(a) - size(b), size(b)), b));
}
