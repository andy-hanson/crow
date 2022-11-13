module util.sym;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrUtil : findIndex;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutDict : addToMutDict, getAt_mut, MutDict, mutDictSize;
import util.col.str : copyToSafeCStr, eachChar, SafeCStr, strEq, strOfSafeCStr;
import util.hash : Hasher, hashUlong;
import util.opt : force, has, Opt, none, some;
import util.ptr : ptrTrustMe_mut;
import util.util : drop, verify;
import util.writer : finishWriterToSafeCStr, Writer;

immutable(Opt!size_t) indexOfSym(ref immutable Sym[] a, immutable Sym value) =>
	findIndex!Sym(a, (ref immutable Sym it) => it == value);

struct Sym {
	@safe @nogc pure nothrow:
	// This is either:
	// * A short symbol, tagged with 'shortSymTag'
	// * An index into 'largeStrings'.
	immutable ulong value; // Public for 'switch'
	@disable this();
	// TODO:PRIVATE
	immutable this(immutable ulong v) { value = v; }

	void hash(ref Hasher hasher) const {
		hashUlong(hasher, value);
	}
}

struct AllSymbols {
	@safe @nogc pure nothrow:

	@trusted this(Alloc* allocPtr_) {
		allocPtr = allocPtr_;
		foreach (immutable string s; specialSyms) { {
			immutable SafeCStr str = immutable SafeCStr(s.ptr);
			debug {
				immutable Opt!Sym packed = tryPackShortSym(strOfSafeCStr(str));
				verify(!has(packed));
			}
			drop(addLargeString(this, str));
		} }
	}

	private:
	Alloc* allocPtr;
	MutDict!(immutable string, immutable Sym) largeStringToIndex;
	MutArr!(immutable SafeCStr) largeStringFromIndex;

	ref Alloc alloc() return scope =>
		*allocPtr;
}

// WARN: 'value' must have been allocated by a.alloc
private immutable(Sym) addLargeString(ref AllSymbols a, immutable SafeCStr value) {
	immutable size_t index = mutArrSize(a.largeStringFromIndex);
	verify(mutDictSize(a.largeStringToIndex) == index);
	immutable Sym res = immutable Sym(index);
	addToMutDict(a.alloc, a.largeStringToIndex, strOfSafeCStr(value), res);
	push(a.alloc, a.largeStringFromIndex, value);
	return res;
}

immutable(Sym) prependSet(ref AllSymbols allSymbols, immutable Sym a) {
	immutable Opt!Sym short_ = tryPrefixShortSymWithSet(a);
	return has(short_) ? force(short_) : prependToLongStr!"set-"(allSymbols, a);
}

private @trusted immutable(Sym) prependToLongStr(immutable string prepend)(ref AllSymbols allSymbols, immutable Sym a) {
	char[0x100] temp = void;
	temp[0 .. prepend.length] = prepend;
	size_t i = prepend.length;
	eachCharInSym(allSymbols, a, (immutable char x) {
		temp[i] = x;
		i++;
		verify(i <= temp.length);
	});
	return getSymFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

immutable(Sym) concatSymsWithDot(ref AllSymbols allSymbols, immutable Sym a, immutable Sym b) =>
	concatSyms(allSymbols, [a, sym!".", b]);

@trusted immutable(Sym) concatSyms(ref AllSymbols allSymbols, scope immutable Sym[] syms) {
	char[0x100] temp = void;
	size_t i = 0;
	foreach (immutable Sym s; syms)
		eachCharInSym(allSymbols, s, (immutable char x) {
			temp[i] = x;
			i++;
			verify(i <= temp.length);
		});
	return symOfStr(allSymbols, cast(immutable) temp[0 .. i]);
}

immutable(Sym) symOfStr(ref AllSymbols allSymbols, scope immutable string str) {
	immutable Opt!Sym packed = tryPackShortSym(str);
	return has(packed) ? force(packed) : getSymFromLongStr(allSymbols, str);
}

immutable(Sym) symOfSafeCStr(ref AllSymbols allSymbols, scope immutable SafeCStr a) =>
	symOfStr(allSymbols, strOfSafeCStr(a));

void eachCharInSym(
	scope ref const AllSymbols allSymbols,
	immutable Sym a,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	if (isShortSym(a))
		eachCharInShortSym(a.value, cb);
	else {
		verify(isLongSym(a));
		eachChar(asLongSym(allSymbols, a), cb);
	}
}

immutable(uint) symSize(ref const AllSymbols allSymbols, immutable Sym a) {
	uint size = 0;
	eachCharInSym(allSymbols, a, (immutable char) {
		size++;
	});
	return size;
}

immutable(Sym) sym(immutable string name) = specialSym(name);

private @trusted immutable(Sym) specialSym(immutable string name) {
	foreach (immutable size_t i, immutable string s; specialSyms)
		if (strEq(s[0 .. $ - 1], name))
			return immutable Sym(i);
	return shortSym(name);
}

private immutable(Sym) shortSym(immutable string name) {
	immutable Opt!Sym opt = tryPackShortSym(name);
	return force(opt);
}

immutable(SafeCStr) safeCStrOfSym(ref Alloc alloc, ref const AllSymbols allSymbols, immutable Sym a) {
	if (isLongSym(a))
		return asLongSym(allSymbols, a);
	else {
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeSym(writer, allSymbols, a);
		return finishWriterToSafeCStr(writer);
	}
}

immutable(char[bufferSize]) symAsTempBuffer(size_t bufferSize)(ref const AllSymbols allSymbols, immutable Sym a) {
	char[bufferSize] res;
	verify(symSize(allSymbols, a) < bufferSize);
	size_t index;
	eachCharInSym(allSymbols, a, (immutable char c) {
		res[index] = c;
		index++;
	});
	res[index] = '\0';
	return res;
}

immutable(size_t) writeSymAndGetSize(scope ref Writer writer, scope ref const AllSymbols allSymbols, immutable Sym a) {
	size_t size = 0;
	eachCharInSym(allSymbols, a, (immutable char c) {
		writer ~= c;
		size++;
	});
	return size;
}

void writeSym(scope ref Writer writer, scope ref const AllSymbols allSymbols, immutable Sym a) {
	writeSymAndGetSize(writer, allSymbols, a);
}

void writeQuotedSym(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym a) {
	writer ~= '"';
	writeSym(writer, allSymbols, a);
	writer ~= '"';
}

private:

// Bit to be set when the sym is short
immutable ulong shortSymTag = 0x8000000000000000;

immutable size_t shortSymMaxChars = 12;

immutable(ulong) codeForLetter(immutable char a) {
	verify!"codeForLetter"('a' <= a && a <= 'z');
	return 1 + a - 'a';
}
immutable(char) letterFromCode(immutable ulong code) {
	verify(1 <= code && code <= 26);
	return cast(immutable char) ('a' + (code - 1));
}
immutable ulong codeForHyphen = 27;
immutable ulong codeForUnderscore = 28;
immutable ulong codeForNextIsCapitalLetter = 29;
immutable ulong codeForNextIsDigit = 30;

immutable ulong setPrefix =
	(codeForLetter('s') << (5 * (shortSymMaxChars - 1))) |
	(codeForLetter('e') << (5 * (shortSymMaxChars - 2))) |
	(codeForLetter('t') << (5 * (shortSymMaxChars - 3))) |
	(codeForHyphen << (5 * (shortSymMaxChars - 4)));

immutable ulong setPrefixSizeBits = 5 * 4;
immutable ulong setPrefixLowerBitsMask = (1 << setPrefixSizeBits) - 1;
immutable ulong setPrefixMask = setPrefixLowerBitsMask << (5 * 8);

immutable(Opt!Sym) tryPrefixShortSymWithSet(immutable Sym a) {
	if (isShortSym(a) && (a.value & setPrefixMask) == 0) {
		ulong shift = 0;
		ulong value = a.value;
		while (true) {
			immutable ulong shifted = value << 5;
			if ((shifted & setPrefixMask) != 0)
				break;
			value = shifted;
			shift += 5;
		}
		return some(immutable Sym(shortSymTag | ((setPrefix | value) >> shift)));
	} else
		return none!Sym;
}

immutable(Opt!Sym) tryPackShortSym(immutable string str) {
	ulong res = 0;
	size_t len = 0;

	void push(immutable ulong value) {
		res = res << 5;
		res |= value;
		len++;
	}

	foreach (immutable char x; str) {
		if ('a' <= x && x <= 'z')
			push(codeForLetter(x));
		else if (x == '-')
			push(codeForHyphen);
		else if (x == '_')
			push(codeForUnderscore);
		else if ('0' <= x && x <= '9') {
			push(codeForNextIsDigit);
			push(x - '0');
		} else if ('A' <= x && x <= 'Z') {
			push(codeForNextIsCapitalLetter);
			push(x - 'A');
		} else
			return none!Sym;
	}
	return len > shortSymMaxChars ? none!Sym : some(immutable Sym(res | shortSymTag));
}

void eachCharInShortSym(
	ulong value,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	ulong remaining = shortSymMaxChars;
	immutable(ulong) take() {
		immutable ulong res = (value >> 55) & 0b11111;
		value = value << 5;
		remaining--;
		return res;
	}

	while (remaining != 0) {
		verify(remaining < 999);
		immutable ulong x = take();
		if (x < 27) {
			if (x != 0)
				cb(letterFromCode(x));
		} else {
			final switch (x) {
				case codeForHyphen:
					cb('-');
					break;
				case codeForUnderscore:
					cb('_');
					break;
				case codeForNextIsCapitalLetter:
					cb(cast(immutable char) ('A' + take()));
					break;
				case codeForNextIsDigit:
					cb(cast(immutable char) ('0' + take()));
					break;
			}
		}
	}
}

// Public for test only
public immutable(bool) isShortSym(immutable Sym a) =>
	(a.value & shortSymTag) != 0;

// Public for test only
public immutable(bool) isLongSym(immutable Sym a) =>
	!isShortSym(a);

@trusted immutable(SafeCStr) asLongSym(return scope ref const AllSymbols allSymbols, immutable Sym a) {
	verify(isLongSym(a));
	return allSymbols.largeStringFromIndex[a.value];
}

immutable(Sym) getSymFromLongStr(ref AllSymbols allSymbols, scope immutable string str) {
	const Opt!(immutable Sym) value = getAt_mut(allSymbols.largeStringToIndex, str);
	return has(value) ? force(value) : addLargeString(allSymbols, copyToSafeCStr(allSymbols.alloc, str));
}

immutable string[] specialSyms = [
	// Putting operator symbols in precedence order so `symPrecedence` from `parseExpr` can be efficient.
	// '-' can't be here because it's a short sym.
	"||\0",
	"&&\0",
	"??\0",
	"==\0",
	"!=\0",
	"<\0",
	"<=\0",
	">\0",
	">=\0",
	"<=>\0",
	"|\0",
	"^\0",
	"&\0",
	"~\0",
	"~=\0",
	"~~\0",
	"~~=\0",
	"..\0",
	"<<\0",
	">>\0",
	"+\0",
	"*\0",
	"/\0",
	"%\0",
	"**\0",
	"!\0",

	".\0",
	".c\0",
	".crow\0",
	".dll\0",
	".exe\0",
	".json\0",
	".lib\0",
	".new\0",
	".so\0",
	"as-any-mut-pointer\0",
	"begin-pointer\0",
	"call-fun-pointer\0",
	"call-with-ctx\0",
	"clock_gettime\0",
	"concrete-model\0",
	"const-pointer\0",
	"cur-exclusion\0",
	"exception-low-level\0",
	"extern-pointer\0",
	"extern-pointers\0",
	"flags-members\0",
	"force-sendable\0",
	"fun-pointer0\0",
	"fun-pointer1\0",
	"fun-pointer2\0",
	"fun-pointer3\0",
	"fun-pointer4\0",
	"fun-pointer5\0",
	"fun-pointer6\0",
	"fun-pointer7\0",
	"fun-pointer8\0",
	"fun-pointer9\0",
	"init-constants\0",
	"interpreter-backtrace\0",
	"is-big-endian\0",
	"is-interpreted\0",
	"is-single-threaded\0",
	"line-and-column-getter\0",
	"loop-continue\0",
	"pointer-cast-from-extern\0",
	"pointer-cast-to-extern\0",
	"static-symbols\0",
	"to-mut-pointer\0",
	"truncate-to-int64\0",
	"unsafe-bit-shift-left\0",
	"unsafe-bit-shift-right\0",
	"unsafe-to-int8\0",
	"unsafe-to-int16\0",
	"unsafe-to-int32\0",
	"unsafe-to-int64\0",
	"unsafe-to-nat8\0",
	"unsafe-to-nat16\0",
	"unsafe-to-nat32\0",
	"unsafe-to-nat64\0",
];
