module util.util;

@safe @nogc pure nothrow:

import std.meta : staticMap;

import util.opt : none, Opt, some;
import util.string : CString, cString;

version (WebAssembly) { } else {
	import core.stdc.stdio : fprintf;
	import app.fileSystem : stderr;
}

T typeAs(T)(T a) =>
	a;

ref T todo(T)(in immutable char* s) {
	debugLog(s);
	assert(0);
}

T min(T)(T a, T b) =>
	a < b ? a : b;

T max(T)(T a, T b) =>
	a > b ? a : b;

T clamp(T)(T a, T min, T max) {
	assert(min <= max);
	return a < min ? min : a > max ? max : a;
}

ulong abs(long a) =>
	a < 0 ? -a : a;

double abs(double a) =>
	a < 0 ? -a : a;

T roundUp(T)(T a, T b) {
	T res = roundUpRecur(a, b);
	assert(res >= a);
	assert(res % b == 0);
	return res;
}

//TODO: more efficient
private T roundUpRecur(T)(T a, T b) {
	assert(b != 0);
	return a % b == 0 ? a : roundUpRecur(a + 1, b);
}

T divRoundUp(T)(T a, T b) {
	assert(b != 0);
	T div = a / b;
	T mod = a % b;
	T res = div + (mod == 0 ? 0 : 1);
	assert(res * b >= a);
	return res;
}

bool isMultipleOf(T)(T a, T b) {
	assert(b != 0);
	return a % b == 0;
}

version (WebAssembly) {
	// WARN: 'message' must be heap allocated, not on stack
	extern(C) void debugLog(scope immutable char* message);
} else {
	void debugLog(in immutable char* message) {
		// Log to stderr because LSP uses stdout
		debug {
			fprintf(stderr, "debug log: %s\n", message);
		}
	}
}

T unreachable(T)() {
	assert(0);
}

E enumOfString(E)(in string a) {
	assertNormalEnum!E();
	final switch (a) {
		static foreach (size_t index, string member; __traits(allMembers, E)) {
			case member:
				return cast(E) index;
		}
	}
}

Opt!E optEnumOfString(E)(in string a) {
	assertNormalEnum!E();
	switch (a) {
		static foreach (size_t index, string member; __traits(allMembers, E)) {
			case member:
				return some(cast(E) index);
		}
		default:
			return none!E;
	}
}

string stringOfEnum(E)(E value) {
	assertNormalEnum!E();
	static immutable string[] strings = [staticMap!(stripUnderscore, __traits(allMembers, E))];
	return strings[value];
}

CString cStringOfEnum(E)(E value) {
	assertNormalEnum!E();
	static immutable CString[] strings =
		[staticMap!(cStringOfString, staticMap!(stripUnderscore, __traits(allMembers, E)))];
	return strings[value];
}

// Enum members must be 0 .. n
void assertNormalEnum(E)() {
	static assert(is(E == enum));
	static foreach (size_t i, string name; __traits(allMembers, E))
		static assert(__traits(getMember, E, name) == i);
}

private enum stripUnderscore(string s) =
	s[$ - 1] == '_' ? s[0 .. $ - 1] : s;

private enum cStringOfString(string s) =
	cString!(s ~ "\0");

@trusted T* ptrTrustMe(T)(scope ref T t) =>
	castNonScope(&t);

@trusted immutable(T*) castImmutable(T)(T* a) =>
	cast(immutable) a;

@trusted T* castMutable(T)(immutable T* a) =>
	cast(T*) a;

@trusted inout(T) castNonScope(T)(scope inout T x) {
	static if (is(T == P*, P)) {
		size_t res = cast(size_t) x;
		return cast(inout T) res;
	} else static if (is(T == P[], P)) {
		size_t res = cast(size_t) x.ptr;
		return (cast(inout P*) res)[0 .. x.length];
	} else
		return x;
}

@trusted ref inout(T) castNonScope_ref(T)(scope ref inout T x) =>
	*castNonScope(&x);
