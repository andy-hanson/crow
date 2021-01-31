module util.collection.str;

@safe @nogc pure nothrow:

import util.collection.arr : at, begin, first, freeArr, size;
import util.collection.arrUtil : cat, compareArr, rtail, tail;
import util.comparison : Comparison;
import util.memory : memcpy;
import util.util : verify;

alias CStr = immutable(char)*;

immutable(Comparison) compareStr(ref immutable string a, ref immutable string b) {
	return compareArr!char(a, b, (ref immutable char ca, ref immutable char cb) =>
		ca < cb ? Comparison.less : ca > cb ? Comparison.greater : Comparison.equal);
}

immutable string emptyStr = "";
immutable(NulTerminatedStr) emptyNulTerminatedStr() {
	return immutable NulTerminatedStr(strLiteral("\0"));
}

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

@system void freeCStr(Alloc)(ref Alloc alloc, immutable CStr c) {
	freeArr(alloc, nulTerminatedStrOfCStr(c).str);
}

@trusted immutable(string) strLiteral(immutable string s) {
	return s;
}

@trusted immutable(string) strOfCStr(immutable CStr c) {
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
	immutable string str;

	this(immutable string s) immutable {
		str = s;
		verify(at(str, size(str) - 1) == '\0');
	}
}

immutable(string) strOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return rtail(a.str);
}

@trusted immutable(NulTerminatedStr) copyToNulTerminatedStr(Alloc)(ref Alloc alloc, ref immutable string s) {
	char* res = cast(char*) alloc.allocateBytes(size(s) + 1);
	memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, size(s));
	res[size(s)] = '\0';
	return immutable NulTerminatedStr(cast(immutable) res[0..size(s) + 1]);
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

immutable(CStr) strToCStr(Alloc)(ref Alloc alloc, ref immutable string s) {
	return copyToNulTerminatedStr(alloc, s).asCStr;
}

@trusted immutable(bool) strEqCStr(immutable string a, immutable CStr b) {
	return *b == '\0'
		? size(a) == 0
		: size(a) != 0 && first(a) == *b && strEqCStr(tail(a), b + 1);
}

immutable(bool) strEqLiteral(immutable string a, immutable string b) {
	return strEq(a, strLiteral(b));
}

immutable(bool) strEq(immutable string a, immutable string b) {
	return size(a) == size(b) && (size(a) == 0 || (at(a, 0) == at(b, 0) && strEq(tail(a), tail(b))));
}

immutable(string) stripNulTerminator(immutable NulTerminatedStr a) {
	return rtail(a.str);
}

@trusted immutable(string) copyStr(Alloc)(ref Alloc alloc, immutable string s) {
	char* begin = cast(char*) alloc.allocateBytes(char.sizeof * size(s));
	foreach (immutable size_t i; 0..size(s))
		begin[i] = at(s, i);
	return cast(immutable) begin[0..size(s)];
}

immutable(bool) startsWith(immutable string a, immutable string b) {
	return size(a) >= size(b) && strEq(a[0..size(b)], b);
}

immutable(NulTerminatedStr) catToNulTerminatedStr(Alloc)(
	ref Alloc alloc,
	immutable string a,
	immutable string b,
) {
	return catToNulTerminatedStr(alloc, a, b, "");
}

immutable(NulTerminatedStr) catToNulTerminatedStr(Alloc)(
	ref Alloc alloc,
	immutable string a,
	immutable string b,
	immutable string c,
) {
	return immutable NulTerminatedStr(cat(alloc, a, b, c, "\0"));
}
