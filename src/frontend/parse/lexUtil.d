module frontend.parse.lexUtil;

@safe @nogc pure nothrow:

import util.opt : none, Opt, some;
import util.string : CString, MutCString;
import util.util : castNonScope_ref;

bool isDecimalDigit(char c) =>
	'0' <= c && c <= '9';

Opt!uint charToHexNat(char a) =>
	isDecimalDigit(a)
		? some!uint(a - '0')
		: 'a' <= a && a <= 'f'
		? some!uint(10 + (a - 'a'))
		: 'A' <= a && a <= 'F'
		? some!uint(10 + (a - 'A'))
		: none!uint;

bool isWhitespace(char a) {
	switch (a) {
		case ' ':
		case '\t':
		case '\r':
		case '\n':
			return true;
		default:
			return false;
	}
}

char takeChar(scope ref MutCString ptr) {
	char res = *ptr;
	ptr++;
	return res;
}

bool tryTakeChar(scope ref MutCString ptr, char expected) {
	if (*ptr == expected) {
		ptr++;
		return true;
	} else
		return false;
}

bool startsWith(in CString a, in string chars) {
	MutCString ptr = a;
	return tryTakeChars(ptr, chars);
}

bool startsWithThenWhitespace(in CString a, in string chars) {
	MutCString ptr = a;
	return tryTakeChars(ptr, chars) && isWhitespace(*ptr);
}

Opt!CString tryGetAfterStartsWith(MutCString ptr, in string chars) =>
	tryTakeChars(ptr, chars) ? some!CString(ptr) : none!CString;

bool tryTakeChars(scope ref MutCString a, in string chars) {
	MutCString ptr = a;
	foreach (immutable char expected; chars) {
		if (*ptr != expected)
			return false;
		ptr++;
	}
	a = castNonScope_ref(ptr);
	return true;
}
