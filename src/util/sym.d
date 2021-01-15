module util.sym;

@safe @nogc pure nothrow:

import util.bools : Bool, False, not, True;
import util.collection.arr : Arr, at, empty, first, last, only, range, size;
import util.collection.arrUtil : contains, every, findIndex, slice, tail;
import util.collection.mutArr : last, MutArr, mutArrRange, push;
import util.collection.mutSet : addToMutSetOkIfPresent, MutSet;
import util.collection.str : CStr, Str, strEqCStr, strEqLiteral, strLiteral, strOfCStr, strToCStr;
import util.comparison : Comparison;
import util.opt : has, Opt, force, none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.types : u64;
import util.util : unreachable, verify;
import util.writer : finishWriter, writeChar, writeStatic, Writer;

immutable(Opt!size_t) indexOfSym(ref immutable Arr!Sym a, immutable Sym value) {
	return findIndex(a, (ref immutable Sym it) => symEq(it, value));
}

immutable(Bool) containsSym(ref immutable Arr!Sym a, immutable Sym b) {
	return contains(a, b, (ref immutable Sym a, ref immutable Sym b) => symEq(a, b));
}

immutable(Bool) isAlphaIdentifierStart(immutable char c) {
	return immutable Bool(('a' <= c && c <= 'z') || c == '?');
}

immutable(Bool) isDigit(immutable char c) {
	return immutable Bool('0' <= c && c <= '9');
}

immutable(Bool) isAlphaIdentifierContinue(immutable char c) {
	return immutable Bool(isAlphaIdentifierStart(c) || c == '-' || isDigit(c) || c == '?');
}

struct Sym {
	immutable u64 value;
}

struct AllSymbols(Alloc) {
	//TODO:PRIVATE
	Ptr!Alloc alloc;
	MutArr!(immutable CStr) largeStrings;
}

immutable(Sym) prependSet(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Sym a) {
	verify(!isSymOperator(a));
	immutable size_t oldSize = symSize(a);
	immutable size_t newSize = 4 + oldSize;

	//TODO: only do inside 'else'
	Writer!Alloc writer = Writer!Alloc(allSymbols.alloc);
	writeStatic(writer, "set-");
	writeSym(writer, a);
	immutable Str str = finishWriter(writer);

	if (newSize <= alphaIdentifierMaxChars) {
		immutable Sym res = prefixAlphaIdentifierWithSet(a, oldSize);
		immutable Opt!Sym op = tryGetSymFromStr(allSymbols, str);
		verify(symEq(force(op), res));
		return res;
	} else
		return getSymFromLongStr(allSymbols, str);
}

immutable(Opt!Sym) tryGetSymFromStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope ref immutable Str str) {
	return empty(str)
		? none!Sym
		: isAlphaIdentifier(str)
		? some(getSymFromAlphaIdentifier(allSymbols, str))
		: getSymFromOperator(allSymbols, str);
}

immutable(Sym) getSymFromAlphaIdentifier(Alloc)(ref AllSymbols!Alloc allSymbols, scope ref immutable Str str) {
	verify(isAlphaIdentifier(str));
	immutable Sym res = canPackAlphaIdentifier(str)
		? immutable Sym(packAlphaIdentifier(str))
		: getSymFromLongStr(allSymbols, str);
	assertSym(res, str);
	verify(!isSymOperator(res));
	return res;
}

private immutable(Bool) isAlphaIdentifier(ref immutable Str a) {
	if (empty(a))
		return True;
	else if (!isAlphaIdentifierStart(first(a)))
		return False;
	else {
		immutable Str t = tail(a);
		return every!char(t, (ref immutable char c) =>
			isAlphaIdentifierContinue(c));
	}
}

enum Operator {
	plus,
	minus,
	times,
	div,
	eq,
	notEq,
	less,
	lessEq,
	greater,
	greaterEq,
	compare,
}

immutable(Opt!Sym) getSymFromOperator(Alloc)(ref AllSymbols!Alloc allSymbols, scope ref immutable Str str) {
	immutable Opt!Operator op = operatorFromStr(str);
	if (has(op)) {
		immutable Sym res = symForOperator(force(op));
		assertSym(res, str);
		return some(res);
	} else
		return none!Sym;
}

immutable(Sym) symForOperator(immutable Operator a) {
	immutable Sym res = immutable Sym(((cast(immutable ulong) a) + 1) << 48);
	verify(isSymOperator(res));
	return res;
}

private immutable(Opt!Operator) operatorFromStr(scope ref immutable Str str) {
	if (size(str) == 1)
		switch (only(str)) {
			case '+':
				return some(Operator.plus);
			case '-':
				return some(Operator.minus);
			case '*':
				return some(Operator.times);
			case '/':
				return some(Operator.div);
			case '<':
				return some(Operator.less);
			case '>':
				return some(Operator.greater);
			default:
				return none!Operator;
		}
	else
		return strEqLiteral(str, "==")
			? some(Operator.eq)
			: strEqLiteral(str, "!=")
			? some(Operator.notEq)
			: strEqLiteral(str, "<=")
			? some(Operator.lessEq)
			: strEqLiteral(str, ">=")
			? some(Operator.greaterEq)
			: strEqLiteral(str, "<=>")
			? some(Operator.compare)
			: none!Operator;
}

private immutable(string) strOfOperator(immutable Operator a) {
	final switch (a) {
		case Operator.plus:
			return "+";
		case Operator.minus:
			return "-";
		case Operator.times:
			return "*";
		case Operator.div:
			return "/";
		case Operator.eq:
			return "==";
		case Operator.notEq:
			return "!=";
		case Operator.less:
			return "<";
		case Operator.lessEq:
			return "<=";
		case Operator.greater:
			return ">";
		case Operator.greaterEq:
			return ">=";
		case Operator.compare:
			return "<=>";
	}
}

void eachCharInSym(immutable Sym a, scope void delegate(immutable char) @safe @nogc pure nothrow cb) {
	if (isShortAlphaSym(a))
		unpackShortAlphaIdentifier(a, cb);
	else if (isSymOperator(a)) {
		immutable Opt!Operator optOperator = operatorForSym(a);
		foreach (immutable char c; strOfOperator(force(optOperator)))
			cb(c);
	} else {
		verify(isLongAlphaSym(a));
		foreach (immutable char c; range(asLongAlphaSym(a)))
			cb(c);
	}
}

immutable(size_t) symSize(immutable Sym a) {
	size_t size = 0;
	a.eachCharInSym((immutable char) {
		size++;
	});
	return size;
}

immutable(Comparison) compareSym(immutable Sym a, immutable Sym b) {
	// We just need to be consistent, so just use the value
	return a.value < b.value
			? Comparison.less
		: a.value > b.value
			? Comparison.greater
			: Comparison.equal;
}

alias MutSymSet = MutSet!(immutable Sym, compareSym);

immutable(Bool) symEq(immutable Sym a, immutable Sym b) {
	return Bool(a.value == b.value);
}

immutable(Sym) shortSymAlphaLiteral(immutable string name) {
	verify(canPackAlphaIdentifier(strLiteral(name)));
	return Sym(packAlphaIdentifier(strLiteral(name)));
}

immutable(u64) shortSymAlphaLiteralValue(immutable string name) {
	return shortSymAlphaLiteral(name).value;
}

immutable(u64) operatorSymValue(immutable Operator a) {
	return symForOperator(a).value;
}

immutable(Bool) symEqLongAlphaLiteral(immutable Sym a, immutable string lit) {
	verify(!canPackAlphaIdentifier(strLiteral(lit)));
	return Bool(isLongAlphaSym(a) && strEqLiteral(asLongAlphaSym(a), lit));
}

immutable(Str) strOfSym(Alloc)(ref Alloc alloc, immutable Sym a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut!Alloc(alloc));
	writeSym(writer, a);
	return finishWriter(writer);
}

immutable(size_t) writeSymAndGetSize(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	size_t size = 0;
	eachCharInSym(a, (immutable char c) {
		writeChar(writer, c);
		size++;
	});
	return size;
}

void writeSym(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	writeSymAndGetSize(writer, a);
}

immutable(Bool) isSymOperator(immutable Sym a) {
	return immutable Bool(!isShortAlphaSym(a) && bitsOverlap(a.value, operatorBits));
}

immutable(Opt!Operator) operatorForSym(immutable Sym a) {
	if (isSymOperator(a)) {
		immutable Operator res = cast(immutable Operator) ((a.value >> 48) - 1);
		verify(res <= Operator.max);
		return some(res);
	} else
		return none!Operator;
}

void addToMutSymSetOkIfPresent(Alloc)(
	ref Alloc alloc,
	ref MutSymSet set,
	immutable Sym sym,
) {
	addToMutSetOkIfPresent!(immutable Sym, compareSym, Alloc)(alloc, set, sym);
}

private:

immutable(Bool) canPackAlphaChar5(immutable char c) {
	return immutable Bool(
		('a' <= c && c <= 'z') ||
		c == '-' ||
		('0' <= c && c <= '3'));
}

immutable(u64) packAlphaChar5(immutable char c) {
	// 0 means no character, so start at 1
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '3' ? 1 + 26 + 1 + c - '0' :
		unreachable!u64;
}

immutable(u64) packAlphaChar6(immutable char c) {
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '9' ? 1 + 26 + 1 + c - '0' :
		c == '?' ? 1 + 26 + 1 + 10 :
		unreachable!u64;
}

immutable(char) unpackAlphaChar(immutable u64 n) {
	verify(n != 0);
	return n < 1 + 26 ? cast(char) ('a' + (n - 1)) :
		n == 1 + 26 ? '-' :
		n < 1 + 26 + 1 + 10 ? cast(char) ('0' + (n - 1 - 26 - 1)) :
		n == 1 + 26 + 1 + 10 ? '?' :
		unreachable!char;
}

// == SYMBOL REPRESENTATION ==
// If the first bit is 1, this is a short alpya sym.
//	We store chars in reverse, the last chars are in the highest bits.
//	Represenation starts with 2 unused bits, then 2 6-bit chars, then 10 5-bit chars (TODO: only need 1...)
//	2 6 6 5 5 5 5 5 5 5 5 5 5
//	e.g.:
//	0 a h p l a 0 0 0 0 0 0 0
// If the first bit is 0, this is an operator or pointer.
//	If an operator: We store (operator + 1) << 48
//		(since pointers don't use these upper bits, and + 1 is to ensure at least one of operatorBits is set.)
//	If alpha: we store a pointer to a nul-terminated string.

// Bit to be set when the sym is short
immutable u64 shortAlphaSymMarker = 0x8000000000000000;
// shortAlphaSymMarker is not set, we'll be looking at an operator if these bits are set.
immutable u64 operatorBits = 0x7fff000000000000;

immutable size_t alphaIdentifierMaxChars = 12;

immutable(Bool) canPackAlphaIdentifier(immutable Str str) {
	if (size(str) > alphaIdentifierMaxChars)
		return False;
	else if (size(str) <= 2)
		return True;
	else {
		immutable Str after2 = slice(str, 0, size(str) - 2);
		return every(after2, (ref immutable char c) =>
			canPackAlphaChar5(c));
	}
}

immutable u64 setPrefix =
	(packAlphaChar5('-') << (5 * 3)) |
	(packAlphaChar5('t') << (5 * 2)) |
	(packAlphaChar5('e') << (5 * 1)) |
	packAlphaChar5('s');

immutable(Sym) prefixAlphaIdentifierWithSet(immutable Sym a, immutable size_t symSize) {
	verify(symSize != 0);
	immutable u64 inputSizeBits = symSize == 1
		? 2 + 6
		: 2 + 2 * 6 + (symSize - 2) * 5;
	// If prepended to a symbol of size 1, the '-' should take up 6 bits.
	immutable u64 prefixSizeBits = symSize == 1 ? 6 + 5 * 3 : 5 * 4;
	immutable u64 prefixBits = setPrefix << (64 - inputSizeBits - prefixSizeBits);
	return immutable Sym(a.value | prefixBits);
}

immutable(u64) packAlphaIdentifier(immutable Str str) {
	verify(canPackAlphaIdentifier(str));

	u64 res = 0;
	foreach (immutable size_t i; 0..12) {
		immutable Bool is6Bit = i < 2;
		immutable u64 value = () {
			if (i < size(str)) {
				immutable char c = at(str, size(str) - 1 - i);
				return is6Bit ? packAlphaChar6(c) : packAlphaChar5(c);
			} else
				return 0;
		}();
		res = res << (is6Bit ? 6 : 5);
		res |= value;
	}
	verify((res & shortAlphaSymMarker) == 0);
	return res | shortAlphaSymMarker;
}

void unpackShortAlphaIdentifier(
	immutable Sym sym,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	verify(isShortAlphaSym(sym));
	u64 p = sym.value;
	foreach (immutable size_t i; 0..10) {
		immutable size_t c = p & 0b11111;
		if (c != 0)
			cb(unpackAlphaChar(c));
		p = p >> 5;
	}
	foreach (immutable size_t i; 0..2) {
		immutable size_t c = p & 0b111111;
		if (c != 0)
			cb(unpackAlphaChar(c));
		p = p >> 6;
	}
}

// Public for test only
public immutable(Bool) isShortAlphaSym(immutable Sym a) {
	return bitsOverlap(a.value, shortAlphaSymMarker);
}

// Public for test only
public immutable(Bool) isLongAlphaSym(immutable Sym a) {
	return not(bitsOverlap(a.value, shortAlphaSymMarker | operatorBits));
}

@trusted immutable(Str) asLongAlphaSym(immutable Sym a) {
	verify(isLongAlphaSym(a));
	return strOfCStr(cast(immutable CStr) a.value);
}

immutable(CStr) getOrAddLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope ref immutable Str str) {
	foreach (immutable CStr s; mutArrRange(allSymbols.largeStrings))
		if (strEqCStr(str, s))
			return s;
	push(allSymbols.alloc, allSymbols.largeStrings, strToCStr(allSymbols.alloc, str));
	return allSymbols.largeStrings.last;
}

immutable(Sym) getSymFromLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope ref immutable Str str) {
	immutable CStr cstr = getOrAddLongStr(allSymbols, str);
	immutable Sym res = immutable Sym(cast(immutable u64) cstr);
	verify(isLongAlphaSym(res));
	return res;
}

void assertSym(immutable Sym sym, immutable Str str) {
	//TODO:KILL
	size_t idx = 0;
	eachCharInSym(sym, (immutable char c) {
		immutable char expected = at(str, idx++);
		verify(c == expected);
	});
	verify(idx == size(str));
}

immutable(Bool) bitsOverlap(immutable u64 a, immutable u64 b) {
	return Bool((a & b) != 0);
}
