module util.col.str;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateElements;
import util.comparison : Comparison;
import util.col.arr : empty;
import util.col.arrUtil : arrEqual, map;
import util.hash : Hasher, hashUbyte;
import util.memory : copyToFrom;

alias CStr = immutable char*;

// CStr type that definitely has '\0' at the end
// (Preferred to `string` as it is 8 bytes instead of 16)
immutable struct SafeCStr {
	@safe @nogc pure nothrow:

	@disable this();
	@system this(CStr p) {
		ptr = p;
	}

	CStr ptr;

	bool opEquals(in SafeCStr b) scope =>
		safeCStrEq(this, b);

	void hash(ref Hasher hasher) scope {
		eachChar(this, (char c) {
			hashUbyte(hasher, c);
		});
	}
}

@trusted CStr end(CStr c) {
	immutable(char)* ptr = c;
	while (*ptr != '\0')
		ptr++;
	return ptr;
}

@trusted SafeCStr copyToSafeCStr(ref Alloc alloc, in char[] s) {
	if (empty(s))
		return safeCStr!"";
	else {
		char[] res = allocateElements!char(alloc, s.length + 1);
		copyToFrom!char(res[0 .. $ - 1], s);
		res[$ - 1] = '\0';
		return SafeCStr(cast(immutable) res.ptr);
	}
}

bool strEq(string a, string b) =>
	arrEqual(a, b);

@trusted SafeCStr safeCStr(immutable char* content)() =>
	SafeCStr(content);

@trusted size_t safeCStrSize(in SafeCStr a) =>
	end(a.ptr) - a.ptr;

bool safeCStrIsEmpty(SafeCStr a) =>
	*a.ptr == '\0';

@trusted string strOfSafeCStr(return scope SafeCStr a) =>
	a.ptr[0 .. (end(a.ptr) - a.ptr)];

string copyStr(ref Alloc alloc, in string a) =>
	map!(char, immutable char)(alloc, a, (ref immutable char x) => x);

SafeCStr copySafeCStr(ref Alloc alloc, in SafeCStr a) =>
	copyToSafeCStr(alloc, strOfSafeCStr(a));

bool safeCStrEq(SafeCStr a, string b) =>
	strEq(strOfSafeCStr(a), b);

bool safeCStrEq(SafeCStr a, SafeCStr b) =>
	safeCStrEq(a, strOfSafeCStr(b));

@trusted void eachChar(in SafeCStr a, in void delegate(char) @safe @nogc pure nothrow cb) {
	for (immutable(char)* p = a.ptr; *p != '\0'; p++)
		cb(*p);
}

@trusted Comparison compareSafeCStrAlphabetically(in SafeCStr a, in SafeCStr b) =>
	safeCStrIsEmpty(a)
		? (safeCStrIsEmpty(b) ? Comparison.equal : Comparison.less)
		: safeCStrIsEmpty(b)
		? Comparison.greater
		: a.ptr[0] < b.ptr[0]
		? Comparison.less
		: a.ptr[0] > b.ptr[0]
		? Comparison.greater
		: compareSafeCStrAlphabetically(SafeCStr(a.ptr + 1), SafeCStr(b.ptr + 1));

@trusted void eachSplit(in SafeCStr a, char splitter, in void delegate(in string) @safe @nogc pure nothrow cb) {
	immutable(char)* ptr = a.ptr;
	while (*ptr != '\0') {
		immutable char* start = ptr;
		while (*ptr != splitter && *ptr != '\0')
			ptr++;
		cb(start[0 .. (ptr - start)]);
		if (*ptr == splitter)
			ptr++;
	}
}
