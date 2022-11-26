module util.jsonParse;

@safe @nogc pure nothrow:

import frontend.parse.lexer : isWhitespace;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrEqual;
import util.col.dict : KeyValuePair;
import util.col.str : copyToSafeCStr, CStr, SafeCStr, safeCStrEq;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, Sym, symOfStr;
import util.union_ : Union;

// NOTE: doesn't support number since I don't use that anywhere
struct Json {
	@safe @nogc pure nothrow:

	alias Object = KeyValuePair!(Sym, Json)[];
	mixin Union!(immutable bool, immutable SafeCStr, immutable Json[], immutable Object);

	immutable(bool) opEquals(scope immutable Json b) scope immutable =>
		match!(immutable bool)(
			(immutable bool x) =>
				b.isA!bool && b.as!bool == x,
			(immutable SafeCStr x) =>
				b.isA!SafeCStr && safeCStrEq(b.as!SafeCStr, x),
			(immutable Json[] x) =>
				b.isA!(Json[]) && arrEqual!Json(x, b.as!(Json[]), (ref immutable Json x, ref immutable Json y) =>
					x == y),
			(immutable Object oa) =>
				b.isA!Object && arrEqual!(KeyValuePair!(Sym, Json))(
						oa,
						b.as!Object,
						(ref immutable KeyValuePair!(Sym, Json) x, ref immutable KeyValuePair!(Sym, Json) y) =>
							x.key == y.key && x.value == y.value));
}

immutable(Opt!Json) parseJson(ref Alloc alloc, ref AllSymbols allSymbols, immutable SafeCStr source) {
	CStr ptr = source.ptr;
	immutable Opt!Json res = parseValue(alloc, allSymbols, ptr);
	skipWhitespace(ptr);
	return *ptr == '\0' ? res : none!Json;
}

private:

immutable(Opt!Json) parseValue(ref Alloc alloc, ref AllSymbols allSymbols, ref CStr ptr) {
	skipWhitespace(ptr);
	switch (next(ptr)) {
		case 'f':
			return tryTake(ptr, 'a') && tryTake(ptr, 'l') && tryTake(ptr, 's') && tryTake(ptr, 'e')
				? some(immutable Json(false))
				: none!Json;
		case 't':
			return tryTake(ptr, 'r') && tryTake(ptr, 'u') && tryTake(ptr, 'e')
				? some(immutable Json(true))
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

immutable(Opt!Json) parseString(ref Alloc alloc, ref CStr ptr) {
	immutable Opt!string res = parseStringTemp(ptr);
	return has(res) ? some(immutable Json(copyToSafeCStr(alloc, force(res)))) : none!Json;
}

@trusted immutable(Opt!string) parseStringTemp(ref CStr ptr) {
	immutable CStr begin = ptr;
	return parseStringTempRecur(begin, ptr);
}
@system immutable(Opt!string) parseStringTempRecur(immutable CStr begin, ref CStr ptr) {
	//TODO: escaping
	switch (next(ptr)) {
		case '\0':
		case '\r':
		case '\n':
			return none!string;
		case '"':
			return some!string(begin[0 .. (ptr - 1 - begin)]);
		default:
			return parseStringTempRecur(begin, ptr);
	}
}

immutable(Opt!Json) parseArray(ref Alloc alloc, ref AllSymbols allSymbols, ref CStr ptr) {
	ArrBuilder!Json res;
	return parseArrayRecur(alloc, allSymbols, res, ptr);
}

immutable(Opt!Json) parseArrayRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!Json res,
	ref CStr ptr,
) {
	if (tryTakePunctuation(ptr, ']'))
		return some(immutable Json(finishArr(alloc, res)));
	else {
		immutable Opt!Json value = parseValue(alloc, allSymbols, ptr);
		if (has(value)) {
			add(alloc, res, force(value));
			return tryTakePunctuation(ptr, ',')
				? parseArrayRecur(alloc, allSymbols, res, ptr)
				: tryTakePunctuation(ptr, ']')
				? some(immutable Json(finishArr(alloc, res)))
				: none!Json;
		} else
			return none!Json;
	}
}

immutable(Opt!Json) parseObject(ref Alloc alloc, ref AllSymbols allSymbols, ref CStr ptr) {
	ArrBuilder!(KeyValuePair!(Sym, Json)) res;
	return parseObjectRecur(alloc, allSymbols, res, ptr);
}

immutable(Opt!Json) parseObjectRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref ArrBuilder!(KeyValuePair!(Sym, Json)) res,
	ref CStr ptr,
) {
	if (tryTakePunctuation(ptr, '"')) {
		immutable Opt!string keyString = parseStringTemp(ptr);
		if (has(keyString) && tryTakePunctuation(ptr, ':')) {
			immutable Opt!Json value = parseValue(alloc, allSymbols, ptr);
			if (has(value)) {
				add(alloc, res, immutable KeyValuePair!(Sym, Json)(
					symOfStr(allSymbols, force(keyString)),
					force(value)));
				return tryTakePunctuation(ptr, ',')
					? parseObjectRecur(alloc, allSymbols, res, ptr)
					: tryTakePunctuation(ptr, '}')
					? some(immutable Json(finishArr(alloc, res)))
					: none!Json;
			} else
				return none!Json;
		} else
			return none!Json;
	} else if (tryTakePunctuation(ptr, '}'))
		return some(immutable Json(finishArr(alloc, res)));
	else
		return none!Json;
}

@trusted immutable(char) next(ref CStr ptr) {
	immutable char res = *ptr;
	ptr++;
	return res;
}

@trusted immutable(bool) tryTake(ref CStr ptr, immutable char expected) {
	if (*ptr == expected) {
		ptr++;
		return true;
	} else
		return false;
}

immutable(bool) tryTakePunctuation(ref CStr ptr, immutable char expected) {
	skipWhitespace(ptr);
	return tryTake(ptr, expected);
}

@trusted void skipWhitespace(ref CStr ptr) {
	while (isWhitespace(*ptr))
		ptr++;
}
