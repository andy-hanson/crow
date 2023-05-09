module util.col.str;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty, freeArr;
import util.col.arrUtil : arrEqual, map;
import util.hash : Hasher, hashUbyte;
import util.memory : memcpy;

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
		char* res = allocateT!char(alloc, s.length + 1);
		static assert(ubyte.sizeof == char.sizeof);
		memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, s.length);
		res[s.length] = '\0';
		return SafeCStr(cast(immutable) res);
	}
}

bool strEq(string a, string b) =>
	arrEqual(a, b);

@trusted SafeCStr safeCStr(immutable char* content)() =>
	SafeCStr(content);

@trusted size_t safeCStrSize(in SafeCStr a) =>
	end(a.ptr) - a.ptr;

@system void freeSafeCStr(ref Alloc alloc, SafeCStr a) {
	// + 1 to free the '\0' too
	freeArr(alloc, a.ptr[0 .. safeCStrSize(a) + 1]);
}

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
