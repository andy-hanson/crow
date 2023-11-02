module frontend.parse.lexUtil;

@safe @nogc pure nothrow:

bool isDecimalDigit(char c) =>
	'0' <= c && c <= '9';

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

@trusted bool tryTakeChar(scope ref immutable(char)* ptr, char expected) {
	if (*ptr == expected) {
		ptr++;
		return true;
	} else
		return false;
}

@trusted bool startsWith(immutable(char)* ptr, in string chars) {
	foreach (immutable char expected; chars) {
		if (*ptr != expected)
			return false;
		ptr++;
	}
	return true;
}

@trusted bool tryTakeChars(ref immutable(char)* ptr, in string chars) {
	if (startsWith(ptr, chars)) {
		ptr += chars.length;
		return true;
	} else
		return false;
}
