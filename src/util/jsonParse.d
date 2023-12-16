module util.jsonParse;

@safe @nogc pure nothrow:

import frontend.parse.lexUtil : isDecimalDigit, isWhitespace, tryTakeChar, tryTakeChars;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.json : Json;
import util.opt : force, has, none, Opt, some;
import util.string : CString, stringOfCString;
import util.symbol : AllSymbols, symbolOfString;
import util.writer : withWriter, Writer;

Json mustParseJson(ref Alloc alloc, scope ref AllSymbols allSymbols, in CString source) {
	Opt!Json res = parseJson(alloc, allSymbols, source);
	return force(res);
}

Opt!Json parseJson(ref Alloc alloc, scope ref AllSymbols allSymbols, in CString source) {
	immutable(char)* ptr = source.ptr;
	Opt!Json res = parseValue(alloc, allSymbols, ptr);
	skipWhitespace(ptr);
	return *ptr == '\0' ? res : none!Json;
}

uint mustParseUint(CString s) {
	immutable(char)* ptr = s.ptr;
	skipWhitespace(ptr);
	Json res = parseNumber(0, ptr);
	skipWhitespace(ptr);
	assert(*ptr == '\0');
	return safeUintOfDouble(res.as!double);
}

uint asUint(in Json a) =>
	safeUintOfDouble(a.as!double);

private uint safeUintOfDouble(double a) {
	uint res = cast(int) a;
	assert((cast(double) res) == a);
	return res;
}

@trusted void skipWhitespace(scope ref immutable(char)* ptr) {
	while (isWhitespace(*ptr))
		ptr++;
}

private:

Opt!Json parseValue(ref Alloc alloc, scope ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	skipWhitespace(ptr);
	char x = next(ptr);
	switch (x) {
		case 'f':
			return tryTakeChars(ptr, "alse")
				? some(Json(false))
				: none!Json;
		case 't':
			return tryTakeChars(ptr, "rue")
				? some(Json(true))
				: none!Json;
		case '"':
			Opt!string string = parseString(alloc, ptr);
			return has(string) ? some(Json(force(string))) : none!Json;
		case '[':
			return parseArray(alloc, allSymbols, ptr);
		case '{':
			return parseObject(alloc, allSymbols, ptr);
		case '0': .. case '9':
			return some(parseNumber(x - '0', ptr));
		default:
			return none!Json;
	}
}

Json parseNumber(double value, scope ref immutable(char)* ptr) {
	// TODO: support floats?
	while (isDecimalDigit(*ptr))
		value = value * 10 + (next(ptr) - '0');
	return Json(value);
}

Opt!string parseString(ref Alloc alloc, scope ref immutable(char)* ptr) {
	bool ok = false;
	CString res = withWriter(alloc, (scope ref Writer writer) {
		//TODO: escaping
		while (true) {
			char x = next(ptr);
			switch (x) {
				case '\0':
				case '\r':
				case '\n':
					return;
				case '"':
					ok = true;
					return;
				case '\\':
					Opt!char esc = escapedChar(next(ptr));
					if (has(esc)) {
						writer ~= force(esc);
						break;
					} else
						return;
				default:
					writer ~= x;
					break;
			}
		}
	});
	return ok ? some(stringOfCString(res)) : none!string;
}

// TODO: share code with crow lexer?
Opt!char escapedChar(char escape) {
	switch (escape) {
		case '"':
			return some('"');
		case 'n':
			return some('\n');
		case 't':
			return some('\t');
		case '\\':
			return some('\\');
		default:
			return none!char;
	}
}


Opt!Json parseArray(ref Alloc alloc, scope ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	ArrayBuilder!Json res;
	return parseArrayRecur(alloc, allSymbols, res, ptr);
}
Opt!Json parseArrayRecur(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref ArrayBuilder!Json res,
	scope ref immutable(char)* ptr,
) {
	if (tryTakePunctuation(ptr, ']'))
		return some(Json(finish(alloc, res)));
	else {
		Opt!Json value = parseValue(alloc, allSymbols, ptr);
		if (has(value)) {
			add(alloc, res, force(value));
			return tryTakePunctuation(ptr, ',')
				? parseArrayRecur(alloc, allSymbols, res, ptr)
				: tryTakePunctuation(ptr, ']')
				? some(Json(finish(alloc, res)))
				: none!Json;
		} else
			return none!Json;
	}
}

Opt!Json parseObject(ref Alloc alloc, scope ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	ArrayBuilder!(Json.ObjectField) res;
	return parseObjectRecur(alloc, allSymbols, res, ptr);
}

Opt!Json parseObjectRecur(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref ArrayBuilder!(Json.ObjectField) res,
	scope ref immutable(char)* ptr,
) {
	if (tryTakePunctuation(ptr, '"')) {
		Opt!string keyString = parseString(alloc, ptr);
		if (has(keyString) && tryTakePunctuation(ptr, ':')) {
			Opt!Json value = parseValue(alloc, allSymbols, ptr);
			if (has(value)) {
				add(alloc, res, Json.ObjectField(symbolOfString(allSymbols, force(keyString)), force(value)));
				return tryTakePunctuation(ptr, ',')
					? parseObjectRecur(alloc, allSymbols, res, ptr)
					: tryTakePunctuation(ptr, '}')
					? some(Json(finish(alloc, res)))
					: none!Json;
			} else
				return none!Json;
		} else
			return none!Json;
	} else if (tryTakePunctuation(ptr, '}'))
		return some(Json(finish(alloc, res)));
	else
		return none!Json;
}

@trusted char next(scope ref immutable(char)* ptr) {
	char res = *ptr;
	ptr++;
	return res;
}

bool tryTakePunctuation(scope ref immutable(char)* ptr, char expected) {
	skipWhitespace(ptr);
	return tryTakeChar(ptr, expected);
}
