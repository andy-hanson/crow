module util.collection.str;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateBytes;
import util.collection.arr : freeArr;
import util.collection.arrUtil : cat4, tail;
import util.hash : Hasher, hashUbyte;
import util.memory : memcpy;
import util.opt : force, has, none, Opt, some;
import util.util : verify;

alias CStr = immutable(char)*;

// CStr type that definitely has '\0' at the end
// (Preferred to `string` as it is 8 bytes instead of 16)
struct SafeCStr {
	@safe @nogc pure nothrow:

	@system immutable this(immutable CStr p) {
		ptr = p;
	}

	immutable CStr ptr;
}

@trusted immutable(CStr) end(immutable CStr c) {
	immutable(char)* ptr = c;
	while (*ptr != '\0')
		ptr++;
	return ptr;
}

@trusted immutable(string) strOfCStr(immutable CStr c) {
	immutable size_t size = end(c) - c;
	return c[0 .. size];
}

@trusted immutable(SafeCStr) copyToSafeCStr(ref Alloc alloc, scope immutable string s) {
	char* res = cast(char*) allocateBytes(alloc, s.length + 1);
	static assert(ubyte.sizeof == char.sizeof);
	memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, s.length);
	res[s.length] = '\0';
	return immutable SafeCStr(cast(immutable) res);
}

immutable(CStr) strToCStr(ref Alloc alloc, scope immutable string s) {
	return copyToSafeCStr(alloc, s).ptr;
}

immutable(bool) strEq(immutable string a, immutable string b) {
	return a.length == b.length && (a.length == 0 || (a[0] == b[0] && strEq(tail(a), tail(b))));
}

@trusted immutable(string) copyStr(ref Alloc alloc, scope immutable string a) {
	char* begin = cast(char*) allocateBytes(alloc, char.sizeof * a.length);
	foreach (immutable size_t i, immutable char x; a)
		begin[i] = x;
	return cast(immutable) begin[0 .. a.length];
}

immutable(bool) startsWith(immutable string a, immutable string b) {
	return a.length >= b.length && strEq(a[0 .. b.length], b);
}

immutable(bool) startsWith(immutable SafeCStr a, immutable string b) {
	return startsWith(strOfSafeCStr(a), b);
}

immutable(bool) startsWith(immutable SafeCStr a, immutable SafeCStr b) {
	immutable Opt!SafeCStr rest = restIfStartsWith(a, b);
	return has(rest);
}

immutable(SafeCStr) catToSafeCStr(ref Alloc alloc, immutable string a, immutable string b) {
	return catToSafeCStr3(alloc, a, b, "");
}

@trusted immutable(SafeCStr) catToSafeCStr3(
	ref Alloc alloc,
	immutable string a,
	immutable string b,
	immutable string c,
) {
	return immutable SafeCStr(cat4(alloc, a, b, c, "\0").ptr);
}

@trusted immutable(SafeCStr) safeCStr(immutable char* content)() {
	return immutable SafeCStr(content);
}

@system void freeSafeCStr(ref Alloc alloc, immutable SafeCStr a) {
	immutable size_t size = end(a.ptr) - a.ptr;
	freeArr(alloc, a.ptr[0 .. size + 1]);
}

immutable(bool) isEmpty(immutable SafeCStr a) {
	return *a.ptr == '\0';
}

immutable(char) first(immutable SafeCStr a) {
	verify(!isEmpty(a));
	return *a.ptr;
}

@trusted immutable(SafeCStr) tail(immutable SafeCStr a) {
	verify(!isEmpty(a));
	return immutable SafeCStr(a.ptr + 1);
}

immutable(bool) safeCStrIsEmpty(immutable SafeCStr a) {
	return *a.ptr == '\0';
}

immutable(string) strOfSafeCStr(immutable SafeCStr a) {
	return strOfCStr(a.ptr);
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

void hashStr(ref Hasher hasher, immutable string a) {
	foreach (immutable char c; a)
		hashUbyte(hasher, c);
}
