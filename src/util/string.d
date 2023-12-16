module util.string;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.comparison : Comparison;
import util.col.array : append, arraysEqual, copyArray, isEmpty;
import util.hash : HashCode, hashString;

// Like 'immutable char*' but guaranteed to have a terminating '\0'
// (Preferred to `string` as it is 8 bytes instead of 16)
immutable struct CString {
	@safe @nogc pure nothrow:

	@disable this();
	@system this(immutable char* p) {
		ptr = p;
	}

	immutable char* ptr;

	bool opEquals(in string b) scope =>
		stringsEqual(stringOfCString(this), b);
	bool opEquals(in CString b) scope =>
		this == stringOfCString(b);

	HashCode hash() scope =>
		hashString(stringOfCString(this));
}

private @trusted immutable(char*) cstringEnd(immutable(char)* ptr) {
	while (*ptr != '\0')
		ptr++;
	return ptr;
}

@trusted CString copyToCString(ref Alloc alloc, in char[] s) =>
	isEmpty(s)
		? cString!""
		: CString(cast(immutable) append(alloc, s, '\0').ptr);

bool stringsEqual(in string a, in string b) =>
	arraysEqual(a, b);

@trusted CString cString(immutable char* content)() =>
	CString(content);

@trusted size_t cStringSize(in CString a) =>
	cstringEnd(a.ptr) - a.ptr;

bool cStringIsEmpty(CString a) =>
	*a.ptr == '\0';

@trusted string stringOfCString(return scope CString a) =>
	a.ptr[0 .. (cstringEnd(a.ptr) - a.ptr)];

string copyString(ref Alloc alloc, in string a) =>
	copyArray(alloc, a);

@trusted void eachChar(in CString a, in void delegate(char) @safe @nogc pure nothrow cb) {
	for (immutable(char)* p = a.ptr; *p != '\0'; p++)
		cb(*p);
}

@trusted Comparison compareCStringAlphabetically(in CString a, in CString b) =>
	cStringIsEmpty(a)
		? (cStringIsEmpty(b) ? Comparison.equal : Comparison.less)
		: cStringIsEmpty(b)
		? Comparison.greater
		: a.ptr[0] < b.ptr[0]
		? Comparison.less
		: a.ptr[0] > b.ptr[0]
		? Comparison.greater
		: compareCStringAlphabetically(CString(a.ptr + 1), CString(b.ptr + 1));

pure @trusted CString mustStripPrefix(CString a, string prefix) {
	immutable(char)* ptr = a.ptr;
	foreach (char c; prefix) {
		assert(*ptr == c);
		ptr++;
	}
	return CString(ptr);
}
