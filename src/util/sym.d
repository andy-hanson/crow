module util.sym;

@safe @nogc pure nothrow:

import util.bitUtils : bitsOverlap, getBitsShifted, singleBit;
import util.bools : Bool, False, not, True;
import util.collection.arr : at, empty, first, last, range, size;
import util.collection.arrUtil : every, slice, tail;
import util.collection.mutArr : last, MutArr, mutArrRange, push;
import util.collection.mutSet : addToMutSetOkIfPresent, MutSet;
import util.collection.str : CStr, Str, strEqCStr, strEqLiteral, strLiteral, strOfCStr, strToCStr;
import util.comparison : Comparison;
import util.opt : Opt, none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.types : u64;
import util.util : unreachable, verify;
import util.writer : finishWriter, writeChar, Writer;

immutable(Bool) isAlphaIdentifierStart(immutable char c) {
	return Bool('a' <= c && c <= 'z');
}

immutable(Bool) isDigit(immutable char c) {
	return Bool('0' <= c && c <= '9');
}

immutable(Bool) isOperatorChar(immutable char c) {
	switch (c) {
		case '+':
		case '-':
		case '*':
		case '/':
		case '<':
		case '>':
		case '=':
		case '!':
			return True;
		default:
			return False;
	}
}

immutable(Bool) isAlphaIdentifierContinue(immutable char c) {
	return immutable Bool(isAlphaIdentifierStart(c) || c == '-' || isDigit(c) || c == '?');
}

struct Sym {
	immutable u64 value;
}

struct AllSymbols(Alloc) {
	Ptr!Alloc alloc;
	MutArr!(immutable CStr) largeStrings;
}

immutable(Opt!Sym) tryGetSymFromStr(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	return empty(str)
		? none!Sym
		: isAlphaIdentifierStart(first(str)) && every(tail(str), (ref immutable char c) =>
			isAlphaIdentifierContinue(c))
		? some(getSymFromAlphaIdentifier(allSymbols, str))
		: every(str, (ref immutable char c) => isOperatorChar(c))
		? some(getSymFromOperator(allSymbols, str))
		: none!Sym;
}

immutable(Sym) getSymFromAlphaIdentifier(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	verify(isAlphaIdentifier(str));
	immutable Sym res = canPackAlphaIdentifier(str)
		? immutable Sym(packAlphaIdentifier(str))
		: getSymFromLongStr(allSymbols, str, False);
	assertSym(res, str);
	verify(!isSymOperator(res));
	return res;
}

private immutable(Bool) isAlphaIdentifier(ref immutable Str a) {
	return immutable Bool(
		empty(a) || (
		isAlphaIdentifierStart(first(a)) &&
		every(tail(a), (ref immutable char it) => isAlphaIdentifierContinue(it))));
}

immutable(Sym) getSymFromOperator(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	verify(isOperator(str));
	immutable Sym res = size(str) <= maxShortOperatorSize
		? immutable Sym(packOperator(str))
		: getSymFromLongStr(allSymbols, str, True);
	assertSym(res, str);
	verify(isSymOperator(res));
	return res;
}

private immutable(Bool) isOperator(ref immutable Str a) {
	return every(a, (ref immutable char it) => isOperatorChar(it));
}

void eachCharInSym(immutable Sym a, scope void delegate(immutable char) @safe @nogc pure nothrow cb) {
	if (isLongSym(a))
		foreach (immutable char c; asLong(a).range)
			cb(c);
	else if (isSymOperator(a))
		unpackShortOperator(a.value, cb);
	else
		unpackShortAlphaIdentifier(a.value, cb);
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

immutable(Sym) shortSymOperatorLiteral(immutable string name) {
	verify(size(strLiteral(name)) <= maxShortOperatorSize);
	return Sym(packOperator(strLiteral(name)));
}

immutable(u64) shortSymOperatorLiteralValue(immutable string name) {
	return shortSymOperatorLiteral(name).value;
}

immutable(Bool) symEqLongAlphaLiteral(immutable Sym a, immutable string lit) {
	verify(!canPackAlphaIdentifier(strLiteral(lit)));
	return Bool(isLongSym(a) && strEqLiteral(asLong(a), lit));
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
	return bitsOverlap(a.value, operatorMarker);
}

void addToMutSymSetOkIfPresent(Alloc)(
	ref Alloc alloc,
	ref MutSymSet set,
	immutable Sym sym,
) {
	addToMutSetOkIfPresent!(immutable Sym, compareSym, Alloc)(alloc, set, sym);
}

private:

immutable u64 bitsPerOperatorChar = 4;

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

immutable(u64) packOperatorChar(immutable char c) {
	immutable u64 res =
		c == '+' ? 1 :
		c == '-' ? 2 :
		c == '*' ? 3 :
		c == '/' ? 4 :
		c == '<' ? 5 :
		c == '>' ? 6 :
		c == '=' ? 7 :
		c == '!' ? 8 :
		unreachable!u64;
	verify(res < (1 << bitsPerOperatorChar));
	return res;
}

immutable(char) unpackOperatorChar(immutable u64 n) {
	return n == 1 ? '+' :
		n == 2 ? '-' :
		n == 3 ? '*' :
		n == 4 ? '/' :
		n == 5 ? '<' :
		n == 6 ? '>' :
		n == 7 ? '=' :
		n == 8 ? '!' :
		unreachable!char;
}

// We represent a short string by converting each char to 6 bits,
// and shifting left by 6 * the char's index.
// Note this puts the encoded characters "backwards" as char 0 is rightmost.

// Short strings leave the top 2 bits untouched.
immutable u64 shortStringAvailableBits = 64 - 2;
// Bit to be set when the sym is short
immutable u64 shortMarker = 0x8000000000000000;
// Bit to be set when the sym is an operator
immutable u64 operatorMarker = 0x4000000000000000;

immutable u64 maxShortOperatorSize = shortStringAvailableBits / bitsPerOperatorChar;
immutable u64 shortOperatorMarker = shortMarker | operatorMarker;

immutable u64 highestPossibleOperatorBit = singleBit(bitsPerOperatorChar * (maxShortOperatorSize - 1));
static assert((shortOperatorMarker & highestPossibleOperatorBit) == 0, "1");

immutable(Bool) canPackAlphaIdentifier(immutable Str str) {
	return immutable Bool(
		size(str) <= 12 &&
		(size(str) <= 2 || every(slice(str, 0, size(str) - 2), (ref immutable char c) =>
			canPackAlphaChar5(c))));
}

immutable(u64) packAlphaIdentifier(immutable Str str) {
	verify(canPackAlphaIdentifier(str));

	// We store chars in reverse, the last chars are in the highest bits.
	// Represenation is:
	// 2 6 6 5 5 5 5 5 5 5 5 5 5

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
	verify((res & shortMarker) == 0);
	return res | shortMarker;
}

immutable(u64) packOperator(immutable Str str) {
	verify(size(str) <= maxShortOperatorSize);
	u64 res = 0;
	foreach (immutable u64 i; 0..size(str))
		res |= packOperatorChar(str.at(i)) << (bitsPerOperatorChar * i);
	verify((res & shortOperatorMarker) == 0);
	return res | shortOperatorMarker;
}

void unpackShortAlphaIdentifier(
	immutable u64 packedStr,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	verify((packedStr & shortMarker) == shortMarker);
	u64 p = packedStr;
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

void unpackShortOperator(
	immutable u64 packedStr,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	verify((packedStr & shortOperatorMarker) == shortOperatorMarker);
	foreach (immutable u64 i; 0..maxShortOperatorSize) {
		immutable u64 packedChar = getBitsShifted(packedStr, bitsPerOperatorChar * i, bitsPerOperatorChar);
		if (packedChar == 0)
			break;
		cb(unpackOperatorChar(packedChar));
	}
}

// Exposed for testing only
public immutable(Bool) isLongSym(immutable Sym a) {
	return not(bitsOverlap(a.value, shortMarker));
}

@trusted immutable(Str) asLong(immutable Sym a) {
	verify(isLongSym(a));
	immutable u64 value = a.value & ~operatorMarker;
	return strOfCStr(cast(immutable CStr) value);
}

immutable(CStr) getOrAddLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	foreach (immutable CStr s; mutArrRange(allSymbols.largeStrings))
		if (strEqCStr(str, s))
			return s;
	push(allSymbols.alloc, allSymbols.largeStrings, strToCStr(allSymbols.alloc, str));
	return allSymbols.largeStrings.last;
}

immutable(Sym) getSymFromLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str, immutable Bool isOperator) {
	immutable CStr cstr = getOrAddLongStr(allSymbols, str);
	immutable u64 marker = isOperator ? operatorMarker : 0;
	immutable u64 res = (cast(immutable u64) cstr) | marker;
	verify((res & shortMarker) == 0);
	return Sym(res);
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
