module util.sym;

@safe @nogc pure nothrow:

import util.collection.arr : at, first, last, only, size;
import util.collection.arrUtil : contains, every, findIndex, tail;
import util.collection.mutArr : last, MutArr, mutArrRange, push;
import util.collection.mutSet : addToMutSetOkIfPresent, MutSet;
import util.collection.str : CStr, strEq, strOfCStr, strToCStr;
import util.comparison : Comparison;
import util.opt : has, Opt, force, none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.util : unreachable, verify;
import util.writer : finishWriter, writeChar, writeStatic, Writer;

immutable(Opt!size_t) indexOfSym(ref immutable Sym[] a, immutable Sym value) {
	return findIndex!Sym(a, (ref immutable Sym it) => symEq(it, value));
}

immutable(bool) containsSym(ref immutable Sym[] a, immutable Sym b) {
	return contains(a, b, (ref immutable Sym a, ref immutable Sym b) => symEq(a, b));
}

immutable(bool) isAlphaIdentifierStart(immutable char c) {
	return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';
}

immutable(bool) isDigit(immutable char c) {
	return '0' <= c && c <= '9';
}

immutable(bool) isAlphaIdentifierContinue(immutable char c) {
	//TODO: only last character should be '!'
	return isAlphaIdentifierStart(c) || c == '-' || isDigit(c) || c == '!';
}

struct Sym {
	@safe @nogc pure nothrow:
	immutable ulong value;
	@disable this();
	immutable this(immutable ulong v) { value = v; }
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
	immutable string str = finishWriter(writer);

	if (isShortAlphaSym(a) && newSize <= alphaIdentifierMaxChars) {
		immutable Sym res = prefixAlphaIdentifierWithSet(a, oldSize);
		verify(symEq(symOfStr(allSymbols, str), res));
		return res;
	} else
		return getSymFromLongStr(allSymbols, str);
}

immutable(Sym) symOfStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope immutable string str) {
	immutable Opt!Sym op = getSymFromOperator(allSymbols, str);
	return has(op) ? force(op) : getSymFromAlphaIdentifier(allSymbols, str);
}

immutable(Sym) getSymFromAlphaIdentifier(Alloc)(ref AllSymbols!Alloc allSymbols, scope immutable string str) {
	immutable Sym res = canPackAlphaIdentifier(str)
		? immutable Sym(packAlphaIdentifier(str))
		: getSymFromLongStr(allSymbols, str);
	assertSym(res, str);
	verify(!isSymOperator(res));
	return res;
}

enum Operator {
	concatEquals,
	or2,
	and2,
	equal,
	notEqual,
	less,
	lessOrEqual,
	greater,
	greaterOrEqual,
	compare,
	or1,
	xor1,
	and1,
	tilde,
	arrow,
	shiftLeft,
	shiftRight,
	plus,
	minus,
	times,
	divide,
	exponent,
	not,
}

immutable(Opt!Sym) getSymFromOperator(Alloc)(ref AllSymbols!Alloc allSymbols, scope immutable string str) {
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

private immutable(Opt!Operator) operatorFromStr(scope immutable string str) {
	if (size(str) == 1)
		switch (only(str)) {
			case '<':
				return some(Operator.less);
			case '>':
				return some(Operator.greater);
			case '&':
				return some(Operator.and1);
			case '|':
				return some(Operator.or1);
			case '+':
				return some(Operator.plus);
			case '-':
				return some(Operator.minus);
			case '~':
				return some(Operator.tilde);
			case '*':
				return some(Operator.times);
			case '/':
				return some(Operator.divide);
			case '^':
				return some(Operator.xor1);
			case '!':
				return some(Operator.not);
			default:
				return none!Operator;
		}
	else
		return strEq(str, "&&")
			? some(Operator.and2)
			: strEq(str, "||")
			? some(Operator.or2)
			: strEq(str, "~=")
			? some(Operator.concatEquals)
			: strEq(str, "==")
			? some(Operator.equal)
			: strEq(str, "!=")
			? some(Operator.notEqual)
			: strEq(str, "<=")
			? some(Operator.lessOrEqual)
			: strEq(str, ">=")
			? some(Operator.greaterOrEqual)
			: strEq(str, "<=>")
			? some(Operator.compare)
			: strEq(str, "->")
			? some(Operator.arrow)
			: strEq(str, "<<")
			? some(Operator.shiftLeft)
			: strEq(str, ">>")
			? some(Operator.shiftRight)
			: strEq(str, "**")
			? some(Operator.exponent)
			: none!Operator;
}

private immutable(string) strOfOperator(immutable Operator a) {
	final switch (a) {
		case Operator.or2:
			return "||";
		case Operator.and2:
			return "&&";
		case Operator.concatEquals:
			return "~=";
		case Operator.equal:
			return "==";
		case Operator.notEqual:
			return "!=";
		case Operator.less:
			return "<";
		case Operator.lessOrEqual:
			return "<=";
		case Operator.greater:
			return ">";
		case Operator.greaterOrEqual:
			return ">=";
		case Operator.compare:
			return "<=>";
		case Operator.or1:
			return "|";
		case Operator.xor1:
			return "^";
		case Operator.and1:
			return "&";
		case Operator.arrow:
			return "->";
		case Operator.tilde:
			return "~";
		case Operator.shiftLeft:
			return "<<";
		case Operator.shiftRight:
			return ">>";
		case Operator.plus:
			return "+";
		case Operator.minus:
			return "-";
		case Operator.times:
			return "*";
		case Operator.divide:
			return "/";
		case Operator.exponent:
			return "**";
		case Operator.not:
			return "!";
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
		foreach (immutable char c; asLongAlphaSym(a))
			cb(c);
	}
}

immutable(size_t) symSize(immutable Sym a) {
	size_t size = 0;
	eachCharInSym(a, (immutable char) {
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

immutable(bool) symEq(immutable Sym a, immutable Sym b) {
	return a.value == b.value;
}

immutable(Sym) shortSymAlphaLiteral(immutable string name) {
	verify(canPackAlphaIdentifier(name));
	return immutable Sym(packAlphaIdentifier(name));
}

immutable(ulong) shortSymAlphaLiteralValue(immutable string name) {
	return shortSymAlphaLiteral(name).value;
}

immutable(ulong) operatorSymValue(immutable Operator a) {
	return symForOperator(a).value;
}

immutable(bool) symEqLongAlphaLiteral(immutable Sym a, immutable string lit) {
	verify(!canPackAlphaIdentifier(lit));
	return isLongAlphaSym(a) && strEq(asLongAlphaSym(a), lit);
}

immutable(string) strOfSym(Alloc)(ref Alloc alloc, immutable Sym a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut!Alloc(alloc));
	writeSym(writer, a);
	return finishWriter(writer);
}

immutable(char[bufferSize]) symAsTempBuffer(size_t bufferSize)(immutable Sym a) {
	char[bufferSize] res;
	verify(symSize(a) < bufferSize);
	size_t index;
	eachCharInSym(a, (immutable char c) {
		res[index] = c;
		index++;
	});
	res[index] = '\0';
	return res;
}

immutable(size_t) writeSymAndGetSize(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	size_t size = 0;
	eachCharInSym(a, (immutable char c) {
		writeChar(writer, c);
		size++;
	});
	return size;
}

void logSym(Debug)(ref Debug dbg, immutable Sym a) {
	eachCharInSym(a, (immutable char c) {
		dbg.writeChar(c);
	});
}

void writeSym(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	writeSymAndGetSize(writer, a);
}

immutable(bool) isSymOperator(immutable Sym a) {
	return !isShortAlphaSym(a) && bitsOverlap(a.value, operatorBits);
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

immutable(bool) canPackAlphaChar5(immutable char c) {
	return ('a' <= c && c <= 'z') || c == '-' || ('0' <= c && c <= '3');
}

immutable(bool) canPackAlphaChar6(immutable char c) {
	return canPackAlphaChar5(c) || ('4' <= c && c <= '9') || c == '!';
}

immutable(ulong) packAlphaChar5(immutable char c) {
	// 0 means no character, so start at 1
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '3' ? 1 + 26 + 1 + c - '0' :
		unreachable!ulong;
}

immutable(ulong) packAlphaChar6(immutable char c) {
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '9' ? 1 + 26 + 1 + c - '0' :
		c == '!' ? 1 + 26 + 1 + 10 :
		unreachable!ulong;
}

immutable(char) unpackAlphaChar(immutable ulong n) {
	verify(n != 0);
	return n < 1 + 26 ? cast(char) ('a' + (n - 1)) :
		n == 1 + 26 ? '-' :
		n < 1 + 26 + 1 + 10 ? cast(char) ('0' + (n - 1 - 26 - 1)) :
		n == 1 + 26 + 1 + 10 ? '!' :
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
immutable ulong shortAlphaSymMarker = 0x8000000000000000;
// shortAlphaSymMarker is not set, we'll be looking at an operator if these bits are set.
immutable ulong operatorBits = 0x7fff000000000000;

immutable size_t alphaIdentifierMaxChars = 12;

immutable(bool) canPackAlphaIdentifier(immutable string str) {
	return size(str) > alphaIdentifierMaxChars
		? false
		: size(str) <= 2
		? every!char(str, (ref immutable char c) => canPackAlphaChar6(c))
		: every!char(str[$ - 2 .. $], (ref immutable char c) => canPackAlphaChar6(c)) &&
			every!char(str[0 .. $ - 2], (ref immutable char c) => canPackAlphaChar5(c));
}

immutable ulong setPrefix =
	(packAlphaChar5('-') << (5 * 3)) |
	(packAlphaChar5('t') << (5 * 2)) |
	(packAlphaChar5('e') << (5 * 1)) |
	packAlphaChar5('s');

immutable(Sym) prefixAlphaIdentifierWithSet(immutable Sym a, immutable size_t symSize) {
	verify(isShortAlphaSym(a));
	verify(symSize != 0);
	immutable ulong inputSizeBits = symSize == 1
		? 2 + 6
		: 2 + 2 * 6 + (symSize - 2) * 5;
	// If prepended to a symbol of size 1, the '-' should take up 6 bits.
	immutable ulong prefixSizeBits = symSize == 1 ? 6 + 5 * 3 : 5 * 4;
	immutable ulong prefixBits = setPrefix << (64 - inputSizeBits - prefixSizeBits);
	return immutable Sym(a.value | prefixBits);
}

immutable(ulong) packAlphaIdentifier(immutable string str) {
	verify(canPackAlphaIdentifier(str));

	ulong res = 0;
	foreach (immutable size_t i; 0 .. 12) {
		immutable bool is6Bit = i < 2;
		immutable ulong value = () {
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
	ulong p = sym.value;
	foreach (immutable size_t i; 0 .. 10) {
		immutable size_t c = p & 0b11111;
		if (c != 0)
			cb(unpackAlphaChar(c));
		p = p >> 5;
	}
	foreach (immutable size_t i; 0 .. 2) {
		immutable size_t c = p & 0b111111;
		if (c != 0)
			cb(unpackAlphaChar(c));
		p = p >> 6;
	}
}

// Public for test only
public immutable(bool) isShortAlphaSym(immutable Sym a) {
	return bitsOverlap(a.value, shortAlphaSymMarker);
}

// Public for test only
public immutable(bool) isLongAlphaSym(immutable Sym a) {
	return !bitsOverlap(a.value, shortAlphaSymMarker | operatorBits);
}

@trusted immutable(string) asLongAlphaSym(immutable Sym a) {
	verify(isLongAlphaSym(a));
	return strOfCStr(cast(immutable CStr) a.value);
}

immutable(CStr) getOrAddLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope immutable string str) {
	foreach (immutable CStr s; mutArrRange(allSymbols.largeStrings))
		if (strEqCStr(str, s))
			return s;
	push(allSymbols.alloc.deref(), allSymbols.largeStrings, strToCStr(allSymbols.alloc.deref(), str));
	return allSymbols.largeStrings.last;
}

immutable(Sym) getSymFromLongStr(Alloc)(ref AllSymbols!Alloc allSymbols, scope immutable string str) {
	immutable CStr cstr = getOrAddLongStr(allSymbols, str);
	immutable Sym res = immutable Sym(cast(immutable ulong) cstr);
	verify(isLongAlphaSym(res));
	return res;
}

void assertSym(immutable Sym sym, immutable string str) {
	//TODO:KILL
	size_t idx = 0;
	eachCharInSym(sym, (immutable char c) {
		immutable char expected = at(str, idx++);
		verify(c == expected);
	});
	verify(idx == size(str));
}

immutable(bool) bitsOverlap(immutable ulong a, immutable ulong b) {
	return (a & b) != 0;
}

@trusted immutable(bool) strEqCStr(immutable string a, immutable CStr b) {
	return *b == '\0'
		? size(a) == 0
		: size(a) != 0 && first(a) == *b && strEqCStr(tail(a), b + 1);
}
