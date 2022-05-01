module util.col.str;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty, freeArr;
import util.hash : Hasher, hashUbyte;
import util.memory : memcpy;

alias CStr = immutable(char)*;

// CStr type that definitely has '\0' at the end
// (Preferred to `string` as it is 8 bytes instead of 16)
struct SafeCStr {
	@safe @nogc pure nothrow:

	@disable this();
	@system immutable this(immutable CStr p) {
		ptr = p;
	}

	immutable CStr ptr;

	immutable(bool) opEquals(scope immutable SafeCStr b) scope immutable {
		return safeCStrEq(this, b);
	}

	void hash(ref Hasher hasher) scope immutable {
		eachChar(this, (immutable char c) {
			hashUbyte(hasher, c);
		});
	}
}

@trusted immutable(CStr) end(immutable CStr c) {
	immutable(char)* ptr = c;
	while (*ptr != '\0')
		ptr++;
	return ptr;
}

@trusted immutable(string) strOfCStr(return scope immutable CStr c) {
	immutable size_t size = end(c) - c;
	return c[0 .. size];
}

@trusted immutable(SafeCStr) copyToSafeCStr(ref Alloc alloc, scope const char[] s) {
	if (empty(s))
		return safeCStr!"";
	else {
		char* res = allocateT!char(alloc, s.length + 1);
		static assert(ubyte.sizeof == char.sizeof);
		memcpy(cast(ubyte*) res, cast(ubyte*) s.ptr, s.length);
		res[s.length] = '\0';
		return immutable SafeCStr(cast(immutable) res);
	}
}

immutable(bool) strEq(immutable string a, immutable string b) {
	return a.length == b.length && (a.length == 0 || (a[0] == b[0] && strEq(a[1 .. $], b[1 .. $])));
}

@trusted immutable(SafeCStr) safeCStr(immutable char* content)() {
	return immutable SafeCStr(content);
}

@trusted immutable(size_t) safeCStrSize(immutable SafeCStr a) {
	return end(a.ptr) - a.ptr;
}

@system void freeSafeCStr(ref Alloc alloc, immutable SafeCStr a) {
	// + 1 to free the '\0' too
	freeArr(alloc, a.ptr[0 .. safeCStrSize(a) + 1]);
}

immutable(bool) safeCStrIsEmpty(immutable SafeCStr a) {
	return *a.ptr == '\0';
}

immutable(string) strOfSafeCStr(return scope immutable SafeCStr a) {
	return strOfCStr(a.ptr);
}

immutable(SafeCStr) copySafeCStr(ref Alloc alloc, scope immutable SafeCStr a) {
	return copyToSafeCStr(alloc, strOfSafeCStr(a));
}

immutable(bool) safeCStrEq(immutable SafeCStr a, immutable string b) {
	return strEq(strOfSafeCStr(a), b);
}

immutable(bool) safeCStrEq(immutable SafeCStr a, immutable SafeCStr b) {
	return safeCStrEq(a, strOfSafeCStr(b));
}

@trusted void eachChar(scope immutable SafeCStr a, scope void delegate(immutable char) @safe @nogc pure nothrow cb) {
	for (immutable(char)* p = a.ptr; *p != '\0'; p++)
		cb(*p);
}
