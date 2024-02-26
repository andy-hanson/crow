module util.unicode;

@safe @nogc pure nothrow:

import util.col.array : every, isEmpty;
import util.col.arrayBuilder : Builder;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, optIf, some;
import util.string : CString, cStringSize, done, next, StringIter, stringOfCString;
import util.util : todo;

import std.utf : decodeFront;

// File content that could be a string or binary.
// It always has a '\0' at the end just in case it's used as a string.
immutable struct FileContent {
	@safe @nogc pure nothrow:

	this(immutable ubyte[] a) {
		bytesWithNul = a;
		assert(bytesWithNul[$ - 1] == '\0');
	}
	@trusted this(CString a) { // TODO: is this ever actually used? ---------------------------------------------------------------
		static assert(char.sizeof == ubyte.sizeof);
		this((cast(immutable ubyte*) a.ptr)[0 .. cStringSize(a) + 1]);
	}

	static FileContent empty = FileContent([0]);

	immutable(ubyte[]) asBytes() return scope =>
		bytesWithNul[0 .. $ - 1];

	@system CString assumeUtf8() return scope =>
		CString(cast(immutable char*) bytesWithNul.ptr);

	// This ends with '\0'
	private ubyte[] bytesWithNul;
}

Opt!CString unicodeValidate(in FileContent utf8) {
	string str = cast(string) utf8.asBytes;
	StringIter iter = StringIter(str);
	while (!done(iter)) {
		Opt!dchar next = decodeOneUnicodeChar(iter);
		if (!has(next))
			return none!CString;
	}
	// TODO: UNIT TEST: Fails for early '\0' ------------------------------------------------------
	return optIf(iter.byteIndex(str) == str.length, () @trusted => utf8.assumeUtf8);
}

void mustUnicodeEncode(ref Builder!(immutable char) builder, in dchar[] a) {
	bool ok = tryUnicodeEncode(builder, a);
	assert(ok);
}
void mustUnicodeEncode(ref Builder!(immutable char) builder, in dchar a) {
	bool ok = tryUnicodeEncode(builder, a);
	assert(ok);
}

bool tryUnicodeEncode(scope ref Builder!(immutable char) res, in dchar[] a) =>
	every(a, (in dchar x) => tryUnicodeEncode(res, x));

void unicodeDecodeAssertNoError(in string utf8, in void delegate(dchar) @safe @nogc pure nothrow cb) {
	StringIter iter = StringIter(utf8);
	while (!done(iter)) {
		Opt!dchar next = decodeOneUnicodeChar(iter);
		cb(force(next));
	}
}

Opt!dchar decodeAsSingleUnicodeChar(string utf8) {
	StringIter iter = StringIter(utf8);
	Opt!dchar res = decodeOneUnicodeChar(iter);
	return done(iter) ? res : none!dchar;
}

uint characterIndexOfByteIndex(in string utf8, uint byteIndex) {
	uint res = 0;
	StringIter iter = StringIter(utf8);
	while (!done(iter) && iter.byteIndex(utf8) < byteIndex) {
		mustDecodeOneUnicodeChar(iter);
		res++;
	}
	return res;
}

uint byteIndexOfCharacterIndex(in string utf8, uint characterIndex) {
	uint res = 0;
	StringIter iter = StringIter(utf8);
	foreach (size_t i; 0 .. characterIndex) {
		if (!done(iter))
			mustDecodeOneUnicodeChar(iter);
	}
	return safeToUint(iter.byteIndex(utf8));
}

char safeToChar(dchar a) {
	assert(a <= char.max);
	return cast(char) a;
}

bool isValidUnicodeCharacter(dchar a) =>
    a < 0xD800 || (0xf000 <= a && a < 0x110000);

private:

dchar mustDecodeOneUnicodeChar(scope ref StringIter iter) {
	Opt!dchar res = decodeOneUnicodeChar(iter);
	return force(res);
}

// Returns 'none' if this is valid Unicode.
Opt!dchar decodeOneUnicodeChar(scope ref StringIter iter) { // TODO:SIMPLIFY -----------------------------------------------------------
	assert(!done(iter));
	ubyte fst = next(iter);
	if (fst < 0x80)
		return some!dchar(fst);

	if ((fst & 0b1100_0000) != 0b1100_0000)
		return none!dchar;

	dchar d = fst;
	fst <<= 1;

	foreach (int i; [1, 2, 3]) {
		if (done(iter))
			return none!dchar;
		char tmp = next(iter);
		if ((tmp & 0xC0) != 0x80)
			return none!dchar;
		
		d = (d << 6) | (tmp & 0x3f);
		fst <<= 1;
		if ((fst & 0x80) == 0) { // no more bytes
			uint[4] bitMask = [(1 << 7) - 1, (1 << 11) - 1, (1 << 16) - 1, (1 << 21) - 1];
			d &= bitMask[i];
			if ((d & ~bitMask[i - 1]) == 0)
				return none!dchar; // overlong, could have been encoded with i bytes
			
			if (i == 2) {
				if (!isValidUnicodeCharacter(d))
					return none!dchar;
			} else if (i == 3) {
				if (d > dchar.max) // TODO: isn't hthis impossible?
					return none!dchar;
			}

			return some(d);
		}
	}

	return none!dchar;
}

bool tryUnicodeEncode(scope ref Builder!(immutable char) res, dchar a) {
	if (a < 0x80) {
		res ~= safeToChar(a);
		return true;
	} else if (a < 0x800) {
		res ~= [safeToChar(0xc0 | (a >> 6)), safeToChar(0x80 | (a & 0x3f))];
		return true;
	} else if (a < 0x10000) {
		if (0xD800 <= a && a < 0xe000)
			return false;
		else {
			res ~= [
				safeToChar(0xe0 | (a >> 12)),
				safeToChar(0x80 | ((a >> 6) & 0x3f)),
				safeToChar(0x80 | (a & 0x3f)),
			];
			return true;
		}
	} else if (a < 0x110000) {
		res ~= [
			safeToChar(0xf0 | (a >> 18)),
			safeToChar(0x80 | ((a >> 12) & 0x3f)),
			safeToChar(0x80 | ((a >> 6) & 0x3f)),
			safeToChar(0x80 | (a & 0x3f))
		];
		return true;
	} else
		return false;
}
