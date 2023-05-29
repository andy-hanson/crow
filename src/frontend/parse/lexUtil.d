module frontend.parse.lexUtil;

@safe @nogc pure nothrow:

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

@trusted bool tryTakeChars(ref immutable(char)* ptr, in string chars) {
	immutable(char)* ptr2 = ptr;
	foreach (immutable char expected; chars) {
		if (*ptr2 != expected)
			return false;
		ptr2++;
	}
	ptr = ptr2;
	return true;
}
