module util.string;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.comparison : compareArrays, compareChar, Comparison;
import util.col.array : append, arrayOfRange, arraysEqual, copyArray, emptySmallArray, isEmpty, small, SmallArray;
import util.conv : safeToUint;
import util.hash : HashCode, hashString;

alias SmallString = SmallArray!(immutable char);
alias smallString = small!(immutable char);
SmallString emptySmallString() =>
	emptySmallArray!(immutable char);

// Like 'immutable char*' but guaranteed to have a terminating '\0'
// (Preferred to `string` as it is 8 bytes instead of 16)
struct MutCString {
	@safe @nogc pure nothrow:

	@disable this();
	@system this(immutable char* p) inout {
		assert(p != null);
		ptr = p;
	}

	char opUnary(string op : "*")() scope const =>
		*ptr;
	// Unsafe since this does not check bounds
	@system CString jumpTo(uint n) immutable =>
		inout MutCString(ptr + n);

	@system ptrdiff_t opCmp(in MutCString b) scope const =>
		ptr - b.ptr;

	@trusted void opUnary(string op : "++")() {
		assert(*ptr != '\0');
		ptr++;
	}

	uint opBinary(string op : "-")(in MutCString b) scope const =>
		safeToUint(ptr - b.ptr);

	immutable(char)* ptr;

	bool opEquals(in string b) scope const =>
		stringsEqual(stringOfCString(this), b);
	bool opEquals(in CString b) scope const =>
		this == stringOfCString(b);

	HashCode hash() scope const =>
		hashString(stringOfCString(this));
}

alias CString = immutable MutCString;

@trusted immutable(ubyte[]) bytesOfString(return scope string a) {
	static assert(char.sizeof == ubyte.sizeof);
	return cast(ubyte[]) a;
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

@trusted string stringOfRange(CString begin, CString end) =>
	arrayOfRange(begin.ptr, end.ptr);

@trusted string stringOfCString(return scope CString a) =>
	a.ptr[0 .. (cstringEnd(a.ptr) - a.ptr)];

string copyString(ref Alloc alloc, in string a) =>
	copyArray(alloc, a);

@trusted void eachChar(in CString a, in void delegate(char) @safe @nogc pure nothrow cb) {
	for (immutable(char)* p = a.ptr; *p != '\0'; p++)
		cb(*p);
}

@trusted Comparison compareStringsAlphabetically(in string a, in string b) =>
	compareArrays!char(a, b, (in char x, in char y) => compareChar(x, y));

pure @trusted CString mustStripPrefix(CString a, string prefix) {
	immutable(char)* ptr = a.ptr;
	foreach (char c; prefix) {
		assert(*ptr == c);
		ptr++;
	}
	return CString(ptr);
}
