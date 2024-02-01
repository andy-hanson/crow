module frontend.parse.lexString;

@safe @nogc pure nothrow:

import frontend.parse.lexUtil : decodeHexDigit, takeChar, tryTakeChars;
import frontend.parse.lexWhitespace : AddDiag;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : Builder, finish;
import util.opt : force, has, none, Opt, optIf;
import util.string : CString, MutCString, stringOfRange;
import util.util : enumConvert;

immutable struct StringPart {
	string text;
	After after;

	enum After {
		quote,
		lbrace,
	}
}

enum QuoteKind {
	quoteDouble,
	quoteDouble3,
}

StringPart takeStringPart(
	ref Alloc alloc,
	return scope ref MutCString ptr,
	QuoteKind quoteKind,
	in AddDiag addDiag,
) {
	Builder!(immutable char) res = Builder!(immutable char)(&alloc);
	StringPart.After after = () @safe {
		while (true) {
			CString start = ptr;
			switch (*ptr) {
				case '"':
					ptr++;
					final switch (quoteKind) {
						case QuoteKind.quoteDouble:
							return StringPart.After.quote;
						case QuoteKind.quoteDouble3:
							if (tryTakeChars(ptr, "\"\""))
								return StringPart.After.quote;
							else
								res ~= '"';
							break;
					}
					break;
				case '{':
					ptr++;
					return StringPart.After.lbrace;
				case '\\':
					ptr++;
					takeStringEscape(res, start, ptr, addDiag);
					break;
				case '\r':
				case '\n':
					final switch (quoteKind) {
						case QuoteKind.quoteDouble:
							addDiag(start, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.quoteDouble)));
							return StringPart.After.quote;
						case QuoteKind.quoteDouble3:
							res ~= takeChar(ptr);
							break;
					}
					break;
				case '\0':
					addDiag(start, ParseDiag(ParseDiag.Expected(enumConvert!(ParseDiag.Expected.Kind)(quoteKind))));
					return StringPart.After.quote;
				default:
					res ~= takeChar(ptr);
			}
		}
	}();
	return StringPart(finish(res), after);
}

private:

void takeStringEscape(
	scope ref Builder!(immutable char) res,
	in CString start,
	scope ref MutCString ptr,
	in AddDiag addDiag,
) {
	switch (takeChar(ptr)) {
		case '\\':
			res ~= '\\';
			break;
		case '{':
			res ~= '{';
			break;
		case '0':
			res ~= '\0';
			break;
		case '"':
			res ~= '"';
			break;
		case 'n':
			res ~= '\n';
			break;
		case 'r':
			res ~= '\r';
			break;
		case 't':
			res ~= '\t';
			break;
		case 'u':
			takeUnicodeEscape(res, start, ptr, addDiag, 2);
			break;
		case 'U':
			takeUnicodeEscape(res, start, ptr, addDiag, 4);
			break;
		case 'x':
			takeUnicodeEscape(res, start, ptr, addDiag, 1);
			break;
		default:
			stringEscapeError(res, start, ptr, addDiag);
			break;
	}
}

void takeUnicodeEscape(
	scope ref Builder!(immutable char) res,
	in CString start,
	scope ref MutCString ptr,
	in AddDiag addDiag,
	size_t nBytes,
) {
	dchar fullChar = 0;
	foreach (size_t i; 0 .. nBytes) {
		Opt!char c = takeCharEscape(ptr);
		if (has(c))
			fullChar = (fullChar << 8) | force(c);
		else {
			stringEscapeError(res, start, ptr, addDiag);
			return;
		}
	}

	if (!encodeUTF8(res, fullChar))
		stringEscapeError(res, start, ptr, addDiag);
}

void stringEscapeError(
	scope ref Builder!(immutable char) res,
	in CString start,
	in CString ptr,
	in AddDiag addDiag,
) {
	addDiag(start, ParseDiag(ParseDiag.InvalidStringEscape(stringOfRange(start, ptr))));
	res ~= "�";
}

Opt!char takeCharEscape(scope ref MutCString ptr) {
	Opt!ubyte digit0 = tryTakeHexDigit(ptr);
	Opt!ubyte digit1 = has(digit0) ? tryTakeHexDigit(ptr) : none!ubyte;
	return optIf(has(digit0) && has(digit1), () =>
		safeToChar((force(digit0) << 4) | force(digit1)));
}

Opt!ubyte tryTakeHexDigit(ref MutCString ptr) {
	Opt!ubyte res = decodeHexDigit(*ptr);
	if (has(res))
		ptr++;
	return res;
}

bool encodeUTF8(scope ref Builder!(immutable char) res, dchar a) {
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

char safeToChar(dchar a) {
	assert(a <= char.max);
	return cast(char) a;
}
