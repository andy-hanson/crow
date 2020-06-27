module util.sym;

@safe @nogc pure nothrow:

import util.bitUtils : allBitsSet, bitsOverlap, getBitsShifted, singleBit;
import util.bools : and, Bool, False, not, True;
import util.collection.arr : at, first, last, range, size, tail;
import util.collection.mutArr : last, MutArr, push, range;
import util.collection.mutSet : MutSet;
import util.collection.str : CStr, Str, strEqCStr, strEqLiteral, strLiteral, strOfCStr, strToCStr;
import util.comparison : Comparison;
import util.types : u64;
import util.verify : unreachable, verify;
import util.writer : Writer;

struct Sym {
	// Short alpha identifier: packed representation, marked with shortAlphaIdentifierMarker
	// Short operator: even more packed representation (there are fewer operator chars), marked with shortOperatorMarker
	// Long alpha identifier: a CStr
	// Long operator: a CStr tagged with longOperatorMarker
	immutable u64 value;
}

struct AllSymbols(Alloc) {
	this(Alloc al) {
		alloc = al;
	}

	Alloc alloc;
	MutArr!(immutable CStr) largeStrings;
}

immutable(Sym) getSymFromAlphaIdentifier(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	immutable Sym res = str.size <= maxShortAlphaIdentifierSize
		? Sym(packAlphaIdentifier(str))
		: getSymFromLongStr(allSymbols, str, False);
	assertSym(res, str);
	return res;
}

immutable(Sym) getSymFromOperator(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	immutable Sym res = str.size <= maxShortOperatorSize
		? Sym(packOperator(str))
		: getSymFromLongStr(allSymbols, str, True);
	assertSym(res, str);
	return res;
}

void eachCharInSym(immutable Sym a, scope void delegate(immutable char) @safe @nogc pure nothrow cb) {
	if (isShortAlpha(a))
		unpackShortAlphaIdentifier!cb(a.value);
	else if (isShortOperator(a))
		unpackShortOperator!cb(a.value);
	else
		foreach (immutable char c; asLong(a).range)
			cb(c);
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
	assert(strLiteral(name).size <= maxShortAlphaIdentifierSize);
	return Sym(packAlphaIdentifier(strLiteral(name)));
}

immutable(u64) shortSymAlphaLiteralValue(immutable string name) {
	return shortSymAlphaLiteral(name).value;
}

immutable(Sym) shortSymOperatorLiteral(immutable string name) {
	assert(strLiteral(name).size <= maxShortOperatorSize);
	return Sym(packOperator(strLiteral(name)));
}

immutable(u64) shortSymOperatorLiteralValue(immutable string name) {
	return shortSymOperatorLiteral(name).value;
}

immutable(Bool) symEqLongAlphaLiteral(immutable Sym a, immutable string lit) {
	immutable Str str = strLiteral(lit);
	assert(str.size > maxShortAlphaIdentifierSize);
	return isLongSym(a).and(strEqLiteral(asLong(a), lit));
}

immutable(Bool) symEqLongOperatorLiteral(immutable Sym a, immutable string lit) {
	immutable Str str = strLiteral(lit);
	assert(str.size > maxShortOperatorSize);
	return and(
		isLongSym(a),
		strEqLiteral(asLong(a), lit));
}

immutable(Str) strOfSym(Alloc)(ref Alloc alloc, immutable Sym a) {
	Writer!Alloc writer = Writer!Alloc(alloc);
	writeSym(writer, a);
	return writer.finish;
}

immutable(size_t) writeSymAndGetSize(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	size_t size = 0;
	eachCharInSym!((immutable char c) {
		writer.writeChar(c);
		size++;
	})(a);
	return size;
}

immutable void writeSym(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	writeSymAndGetSize(writer, a);
}

immutable(CStr) symToCStr(Alloc)(ref Alloc alloc, immutable Sym a) {
	return strToCStr(alloc, strOfSym(alloc, a));
}

immutable(Bool) isSymOperator(immutable Sym a) {
	return bitsOverlap(a.value, shortOrLongOperatorMarker);
}

private:

immutable u64 bitsPerAlphaChar =6;
immutable u64 bitsPerOperatorChar = 4;

immutable(u64) packAlphaChar(immutable char c) {
	// We need 0 to tell us that the string is over, so never return that.
	immutable u64 res = 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		'0' <= c && c <= '9' ? 1 + 26 + c - '0' :
		c == '-' ? 1 + 26 + 10 :
		c == '?' ? 1 + 26 + 10 + 1 :
		unreachable!u64;
	assert(res < (1 << bitsPerAlphaChar));
	return res;
}

immutable(char) unpackAlphaChar(immutable u64 n) {
	assert(n != 0);
	return n < 1 + 26 ? cast(char) ('a' + (n - 1)) :
		n < 1 + 26 + 10 ? cast(char) ('0' + (n - 1 - 26)) :
		n == 1 + 26 + 10 ? '-' :
		n == 1 + 26 + 10 + 1 ? '?' :
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
	assert(res < (1 << bitsPerOperatorChar));
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

// Short strings leave the top 3 bits untouched.
immutable u64 shortStringAvailableBits = 64 - 3;
immutable u64 maxShortAlphaIdentifierSize = shortStringAvailableBits / bitsPerAlphaChar;
// Bit to be set when the sym is short
immutable u64 shortAlphaOrOperatorMarker = 0x8000000000000000;
// Bit to be set when the sym is alpha
// (NOTE: this is redundant as alpha == not operator
immutable u64 shortOrLongAlphaMarker     = 0x4000000000000000;
// Bit to be set when the sym is an operator
immutable u64 shortOrLongOperatorMarker  = 0x2000000000000000;
// 8 = b1000
immutable u64 shortAlphaIdentifierMarker = shortAlphaOrOperatorMarker | shortOrLongAlphaMarker;

immutable u64 maxShortOperatorSize = shortStringAvailableBits / bitsPerOperatorChar;
immutable u64 shortOperatorMarker = shortAlphaOrOperatorMarker | shortOrLongOperatorMarker;

immutable u64 highestPossibleAlphaBit = singleBit(bitsPerAlphaChar * (maxShortAlphaIdentifierSize - 1));
static assert((shortAlphaIdentifierMarker & highestPossibleAlphaBit) == 0, "!");

immutable u64 highestPossibleOperatorBit = singleBit(bitsPerOperatorChar * (maxShortOperatorSize - 1));
static assert((shortOperatorMarker & highestPossibleOperatorBit) == 0, "1");

immutable(u64) packAlphaIdentifier(immutable Str str) {
	assert(str.size <= maxShortAlphaIdentifierSize);
	u64 res = 0;
	foreach (immutable u64 i; 0..str.size)
		res |= packAlphaChar(str.at(i)) << (bitsPerAlphaChar * i);
	assert((res & shortAlphaIdentifierMarker) == 0);
	return res | shortAlphaIdentifierMarker;
}

immutable(u64) packOperator(immutable Str str) {
	assert(str.size <= maxShortOperatorSize);
	u64 res = 0;
	foreach (immutable u64 i; 0..str.size)
		res |= packOperatorChar(str.at(i)) << (bitsPerOperatorChar * i);
	assert((res & shortOperatorMarker) == 0);
	return res | shortOperatorMarker;
}

void unpackShortAlphaIdentifier(alias cb)(immutable u64 packedStr) {
	assert((packedStr & shortAlphaIdentifierMarker) == shortAlphaIdentifierMarker);
	foreach (immutable u64 i; 0..maxShortAlphaIdentifierSize) {
		immutable u64 packedChar = getBitsShifted(packedStr, bitsPerAlphaChar * i, bitsPerAlphaChar);
		if (packedChar == 0)
			break;
		cb(unpackAlphaChar(packedChar));
	}
}

void unpackShortOperator(alias cb)(immutable u64 packedStr) {
	assert((packedStr & shortOperatorMarker) == shortOperatorMarker);
	foreach (immutable u64 i; 0..maxShortOperatorSize) {
		immutable u64 packedChar = getBitsShifted(packedStr, bitsPerOperatorChar * i, bitsPerOperatorChar);
		if (packedChar == 0)
			break;
		cb(unpackOperatorChar(packedChar));
	}
}

immutable(Bool) isLongSym(immutable Sym a) {
	return bitsOverlap(a.value, shortAlphaOrOperatorMarker).not;
}

@trusted immutable(Str) asLong(immutable Sym a) {
	verify(isLongSym(a));
	immutable u64 value = a.value & ~(shortOrLongAlphaMarker | shortOrLongOperatorMarker);
	return strOfCStr(cast(immutable CStr) value);
}

immutable(Bool) isShortAlpha(immutable Sym a) {
	return allBitsSet(a.value, shortAlphaIdentifierMarker);
}

immutable(Bool) isShortOperator(immutable Sym a) {
	return allBitsSet(a.value, shortOperatorMarker);
}

immutable(CStr) getOrAddLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str) {
	foreach (immutable CStr s; allSymbols.largeStrings.range)
		if (strEqCStr(str, s))
			return s;
	allSymbols.largeStrings.push(allSymbols.alloc, strToCStr(allSymbols.alloc, str));
	return allSymbols.largeStrings.last;
}

immutable(Sym) getSymFromLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, immutable Str str, immutable Bool isOperator) {
	immutable CStr cstr = getOrAddLongStr(allSymbols, str);
	immutable u64 marker = isOperator ? shortOrLongOperatorMarker : shortOrLongAlphaMarker;
	immutable u64 res = (cast(immutable u64) cstr) | marker;
	assert((res & shortAlphaOrOperatorMarker) == 0);
	return Sym(res);
}

void assertSym(immutable Sym sym, immutable Str str) {
	//TODO:KILL
	size_t idx = 0;
	sym.eachCharInSym((immutable char c) {
		immutable char expected = at(str, idx++);
		assert(c == expected);
	});
	assert(idx == str.size);
}

