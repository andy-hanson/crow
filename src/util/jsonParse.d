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
import util.util : verify;

// NOTE: doesn't support number since I don't use that anywhere
struct Json {
	@safe @nogc pure nothrow:

	immutable this(immutable bool a) { kind = Kind.boolean; boolean = a; }
	immutable this(immutable SafeCStr a) { kind = Kind.string_; string_ = a; }
	immutable this(return immutable Json[] a) { kind = Kind.array; array = a; }
	immutable this(return immutable KeyValuePair!(Sym, Json)[] a) { kind = Kind.object; object = a; }

	private:
	enum Kind { boolean, string_, array, object }
	immutable Kind kind;
	union {
		immutable bool boolean;
		immutable SafeCStr string_;
		immutable Json[] array;
		immutable KeyValuePair!(Sym, Json)[] object;
	}
}

immutable(bool) isObject(immutable Json a) {
	return a.kind == Json.Kind.object;
}

@trusted immutable(KeyValuePair!(Sym, Json)[]) asObject(immutable Json a) {
	verify(isObject(a));
	return a.object;
}

immutable(bool) isString(immutable Json a) {
	return a.kind == Json.Kind.string_;
}

@trusted immutable(SafeCStr) asString(immutable Json a) {
	verify(isString(a));
	return a.string_;
}

@trusted immutable(bool) jsonEqual(immutable Json a, immutable Json b) {
	if (a.kind == b.kind) {
		final switch (a.kind) {
			case Json.Kind.boolean:
				return a.boolean == b.boolean;
			case Json.Kind.string_:
				return safeCStrEq(a.string_, b.string_);
			case Json.Kind.array:
				return arrEqual!Json(a.array, b.array, (ref immutable Json x, ref immutable Json y) =>
					jsonEqual(x, y));
			case Json.Kind.object:
				return arrEqual!(KeyValuePair!(Sym, Json))(
					a.object,
					b.object,
					(ref immutable KeyValuePair!(Sym, Json) x, ref immutable KeyValuePair!(Sym, Json) y) =>
						x.key == y.key && jsonEqual(x.value, y.value));
		}
	} else
		return false;
}

@trusted immutable(T) matchJson(T)(
	immutable Json a,
	scope immutable(T) delegate(immutable bool) @safe @nogc pure nothrow cbBoolean,
	scope immutable(T) delegate(immutable SafeCStr) @safe @nogc pure nothrow cbString,
	scope immutable(T) delegate(immutable Json[]) @safe @nogc pure nothrow cbArray,
	scope immutable(T) delegate(immutable KeyValuePair!(Sym, Json)[]) @safe @nogc pure nothrow cbObject,
) {
	final switch (a.kind) {
		case Json.Kind.boolean:
			return cbBoolean(a.boolean);
		case Json.Kind.string_:
			return cbString(a.string_);
		case Json.Kind.array:
			return cbArray(a.array);
		case Json.Kind.object:
			return cbObject(a.object);
	}
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
			return some(begin[0 .. (ptr - 1 - begin)]);
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
