module util.collection.str;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes;
import util.collection.arr : at, begin, size;
import util.collection.arrUtil : cat, compareArr, rtail, tail;
import util.comparison : Comparison;
import util.memory : memcpy;
import util.opt : force, has, none, Opt, some;
import util.util : verify;

alias CStr = immutable(char)*;

immutable(Comparison) compareStr(immutable string a, immutable string b) {
	return compareArr!char(a, b, (ref immutable char ca, ref immutable char cb) =>
		ca < cb ? Comparison.less : ca > cb ? Comparison.greater : Comparison.equal);
}

immutable(NulTerminatedStr) emptyNulTerminatedStr() {
	return immutable NulTerminatedStr("\0");
}

@trusted private immutable(CStr) end(immutable CStr c) {
	return *c == '\0' ? c : end(c + 1);
}

@trusted immutable(string) strOfCStr(immutable CStr c) {
	immutable size_t size = end(c) - c;
	return c[0 .. size];
}

@trusted immutable(CStr) cStrOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return begin(a.str);
}

@trusted immutable(NulTerminatedStr) nulTerminatedStrOfCStr(immutable CStr c) {
	immutable size_t size = end(c) - c;
	return immutable NulTerminatedStr(c[0 .. size + 1]);
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

@trusted immutable(NulTerminatedStr) copyToNulTerminatedStr(ref Alloc alloc, scope immutable string s) {
	char* res = cast(char*) allocateBytes(alloc, size(s) + 1);
	memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, size(s));
	res[size(s)] = '\0';
	return immutable NulTerminatedStr(cast(immutable) res[0 .. size(s) + 1]);
}

@trusted immutable(CStr) asCStr(immutable NulTerminatedStr s) {
	return s.str.begin;
}

@trusted immutable(SafeCStr) asSafeCStr(immutable NulTerminatedStr s) {
	return immutable SafeCStr(s.str.begin);
}

immutable(CStr) strToCStr(ref Alloc alloc, scope immutable string s) {
	return copyToNulTerminatedStr(alloc, s).asCStr;
}

immutable(bool) strEq(immutable string a, immutable string b) {
	return size(a) == size(b) && (size(a) == 0 || (at(a, 0) == at(b, 0) && strEq(tail(a), tail(b))));
}

@trusted immutable(string) copyStr(ref Alloc alloc, scope immutable string s) {
	char* begin = cast(char*) allocateBytes(alloc, char.sizeof * size(s));
	foreach (immutable size_t i; 0 .. size(s))
		begin[i] = at(s, i);
	return cast(immutable) begin[0 .. size(s)];
}

immutable(bool) startsWith(immutable string a, immutable string b) {
	return size(a) >= size(b) && strEq(a[0 .. size(b)], b);
}

immutable(bool) startsWith(immutable SafeCStr a, immutable string b) {
	return startsWith(strOfSafeCStr(a), b);
}

immutable(bool) startsWith(immutable SafeCStr a, immutable SafeCStr b) {
	immutable Opt!SafeCStr rest = restIfStartsWith(a, b);
	return has(rest);
}

immutable(SafeCStr) catToSafeCStr(ref Alloc alloc, immutable string a, immutable string b) {
	return asSafeCStr(catToNulTerminatedStr(alloc, a, b));
}

immutable(NulTerminatedStr) catToNulTerminatedStr(
	ref Alloc alloc,
	immutable string a,
	immutable string b,
) {
	return catToNulTerminatedStr(alloc, a, b, "");
}

immutable(SafeCStr) catToSafeCStr(ref Alloc alloc, immutable string a, immutable string b, immutable string c) {
	return asSafeCStr(catToNulTerminatedStr(alloc, a, b, c));
}

immutable(NulTerminatedStr) catToNulTerminatedStr(
	ref Alloc alloc,
	immutable string a,
	immutable string b,
	immutable string c,
) {
	return immutable NulTerminatedStr(cat(alloc, a, b, c, "\0"));
}

// CStr type that definitely has '\0' at the end
// (Preferred to `string` as it is 8 bytes instead of 16)
struct SafeCStr {
	//TODO:private:
	immutable CStr inner;
}

immutable(bool) isEmpty(immutable SafeCStr a) {
	return *a.inner == '\0';
}

immutable(char) first(immutable SafeCStr a) {
	verify(!isEmpty(a));
	return *a.inner;
}

@trusted immutable(SafeCStr) tail(immutable SafeCStr a) {
	verify(!isEmpty(a));
	return immutable SafeCStr(a.inner + 1);
}

immutable SafeCStr emptySafeCStr = immutable SafeCStr("");

immutable(bool) safeCStrIsEmpty(immutable SafeCStr a) {
	return *a.inner == '\0';
}

private immutable(SafeCStr) safeCStrOfNulTerminatedStr(immutable NulTerminatedStr a) {
	return immutable SafeCStr(asCStr(a));
}

immutable(SafeCStr) copyToSafeCStr(ref Alloc alloc, immutable string a) {
	return safeCStrOfNulTerminatedStr(copyToNulTerminatedStr(alloc, a));
}

immutable(string) strOfSafeCStr(immutable SafeCStr a) {
	return strOfCStr(a.inner);
}

immutable(SafeCStr) copySafeCStr(ref Alloc alloc, immutable SafeCStr a) {
	return copyToSafeCStr(alloc, strOfSafeCStr(a));
}

immutable(bool) safeCStrEq(immutable SafeCStr a, immutable string b) {
	return strEq(strOfSafeCStr(a), b);
}

immutable(bool) safeCStrEq(immutable SafeCStr a, immutable SafeCStr b) {
	return safeCStrEq(a, strOfSafeCStr(b));
}

immutable(bool) safeCStrEqCat(immutable SafeCStr a, immutable SafeCStr b1, immutable string b2) {
	immutable Opt!SafeCStr rest = restIfStartsWith(a, b1);
	return has(rest) && safeCStrEq(force(rest), b2);
}

private immutable(Opt!SafeCStr) restIfStartsWith(immutable SafeCStr a, immutable SafeCStr b) {
	return isEmpty(b)
		? some(a)
		: !isEmpty(a) && first(a) == first(b)
		? restIfStartsWith(tail(a), tail(b))
		: none!SafeCStr;
}
