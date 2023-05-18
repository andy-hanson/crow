module util.jsonParse;

@safe @nogc pure nothrow:

import frontend.parse.lexWhitespace : isWhitespace;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.str : copyStr, CStr, SafeCStr;
import util.json : Json;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, symOfStr;

Opt!Json parseJson(ref Alloc alloc, ref AllSymbols allSymbols, in SafeCStr source) {
	immutable(char)* ptr = source.ptr;
	Opt!Json res = parseValue(alloc, allSymbols, ptr);
	skipWhitespace(ptr);
	return *ptr == '\0' ? res : none!Json;
}

private:

Opt!Json parseValue(ref Alloc alloc, ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	skipWhitespace(ptr);
	switch (next(ptr)) {
		case 'f':
			return tryTake(ptr, 'a') && tryTake(ptr, 'l') && tryTake(ptr, 's') && tryTake(ptr, 'e')
				? some(Json(false))
				: none!Json;
		case 't':
			return tryTake(ptr, 'r') && tryTake(ptr, 'u') && tryTake(ptr, 'e')
				? some(Json(true))
				: none!Json;
		case '"':
			return parseString(alloc, ptr);
		case '[':
			return parseArray(alloc, allSymbols, ptr);
		case '{':
			return parseObject(alloc, allSymbols, ptr);
		default:
			return none!Json;
	}
}

Opt!Json parseString(ref Alloc alloc, scope ref immutable(char)* ptr) {
	Opt!string res = parseStringTemp(ptr);
	return has(res) ? some(Json(copyStr(alloc, force(res)))) : none!Json;
}

@trusted Opt!string parseStringTemp(return scope ref immutable(char)* ptr) {
	CStr begin = ptr;
	//TODO: escaping
	while (true) {
		switch (next(ptr)) {
			case '\0':
			case '\r':
			case '\n':
				return none!string;
			case '"':
				return some(begin[0 .. (ptr - 1 - begin)]);
			default:
				break;
		}
	}
}

Opt!Json parseArray(ref Alloc alloc, ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	ArrBuilder!Json res;
	return parseArrayRecur(alloc, allSymbols, res, ptr);
}
Opt!Json parseArrayRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!Json res,
	scope ref immutable(char)* ptr,
) {
	if (tryTakePunctuation(ptr, ']'))
		return some(Json(finishArr(alloc, res)));
	else {
		Opt!Json value = parseValue(alloc, allSymbols, ptr);
		if (has(value)) {
			add(alloc, res, force(value));
			return tryTakePunctuation(ptr, ',')
				? parseArrayRecur(alloc, allSymbols, res, ptr)
				: tryTakePunctuation(ptr, ']')
				? some(Json(finishArr(alloc, res)))
				: none!Json;
		} else
			return none!Json;
	}
}

Opt!Json parseObject(ref Alloc alloc, ref AllSymbols allSymbols, scope ref immutable(char)* ptr) {
	ArrBuilder!(Json.ObjectField) res;
	return parseObjectRecur(alloc, allSymbols, res, ptr);
}

Opt!Json parseObjectRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!(Json.ObjectField) res,
	scope ref immutable(char)* ptr,
) {
	if (tryTakePunctuation(ptr, '"')) {
		Opt!string keyString = parseStringTemp(ptr);
		if (has(keyString) && tryTakePunctuation(ptr, ':')) {
			Opt!Json value = parseValue(alloc, allSymbols, ptr);
			if (has(value)) {
				add(alloc, res, Json.ObjectField(symOfStr(allSymbols, force(keyString)), force(value)));
				return tryTakePunctuation(ptr, ',')
					? parseObjectRecur(alloc, allSymbols, res, ptr)
					: tryTakePunctuation(ptr, '}')
					? some(Json(finishArr(alloc, res)))
					: none!Json;
			} else
				return none!Json;
		} else
			return none!Json;
	} else if (tryTakePunctuation(ptr, '}'))
		return some(Json(finishArr(alloc, res)));
	else
		return none!Json;
}

@trusted char next(scope ref immutable(char)* ptr) {
	char res = *ptr;
	ptr++;
	return res;
}

@trusted bool tryTake(scope ref immutable(char)* ptr, char expected) {
	if (*ptr == expected) {
		ptr++;
		return true;
	} else
		return false;
}

bool tryTakePunctuation(scope ref immutable(char)* ptr, char expected) {
	skipWhitespace(ptr);
	return tryTake(ptr, expected);
}

@trusted void skipWhitespace(scope ref immutable(char)* ptr) {
	while (isWhitespace(*ptr))
		ptr++;
}
