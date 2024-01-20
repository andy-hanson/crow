module util.symbol;

@safe @nogc pure nothrow:

import std.meta : staticMap;

import util.alloc.alloc : Alloc;
import util.col.array : only;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : mustAdd, MutMap, size;
import util.col.mutMaxArr : asTemporaryArray, clear, MutMaxArr, mutMaxArr;
import util.conv : safeToSizeT;
import util.hash : HashCode, hashUlong;
import util.opt : force, has, Opt, none, some;
import util.string : copyToCString, eachChar, CString, stringsEqual, stringOfCString;
import util.util : assertNormalEnum, castNonScope_ref;
import util.writer : digitChar, withWriter, writeEscapedChar, Writer;

immutable struct Symbol {
	@safe @nogc pure nothrow:
	// This is either:
	// * A short symbol, tagged with 'shortSymbolTag'
	// * An index into 'largeStrings'.
	ulong value; // Public for 'switch'
	@disable this();
	private this(ulong v) { value = v; }

	HashCode hash() =>
		hashUlong(value);
}

struct AllSymbols {
	@safe @nogc pure nothrow:

	@trusted this(return scope Alloc* a) {
		allocPtr = a;
		foreach (string s; specialSymbols) { {
			CString str = CString(s.ptr);
			debug {
				Opt!Symbol packed = tryPackShortSymbol(stringOfCString(str));
				assert(!has(packed));
			}
			cast(void) addLargeString(this, str);
		} }
	}

	private:
	Alloc* allocPtr;
	MutMap!(immutable string, Symbol) largeStringToIndex;
	MutArr!CString largeStringFromIndex;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

// WARN: 'value' must have been allocated by a.alloc
private Symbol addLargeString(ref AllSymbols a, CString value) {
	size_t index = mutArrSize(a.largeStringFromIndex);
	assert(size(a.largeStringToIndex) == index);
	Symbol res = Symbol(index);
	mustAdd(a.alloc, a.largeStringToIndex, stringOfCString(value), res);
	push(a.alloc, a.largeStringFromIndex, value);
	return res;
}

Symbol appendHexExtension(ref AllSymbols allSymbols, Symbol a, in ubyte[] bytes) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	eachCharInSymbol(allSymbols, a, (char x) {
		res ~= x;
	});
	res ~= '.';
	foreach (ubyte x; bytes) {
		res ~= digitChar(x / 16);
		res ~= digitChar(x % 16);
	}
	return symbolOfString(allSymbols, asTemporaryArray(res));
}

Symbol addExtension(Symbol extension)(ref AllSymbols allSymbols, Symbol a) {
	static if (extension == symbol!"")
		return a;
	else
		return appendToLongStr!extension(allSymbols, a);
}

Symbol alterExtension(Symbol extension)(ref AllSymbols allSymbols, Symbol a) =>
	addExtension!extension(allSymbols, removeExtension(allSymbols, a));

// TODO:PERF This could be cached (with getExtension)
Symbol removeExtension(ref AllSymbols allSymbols, Symbol a) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	bool hasDot = false;
	eachCharInSymbol(allSymbols, a, (char x) {
		if (!hasDot) {
			if (x == '.')
				hasDot = true;
			else
				res ~= x;
		}
	});
	return symbolOfString(allSymbols, asTemporaryArray(res));
}

// TODO:PERF This could be cached (with removeExtension)
Symbol getExtension(ref AllSymbols allSymbols, Symbol a) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	bool hasDot = false;
	eachCharInSymbol(allSymbols, a, (char x) {
		if (x == '.') {
			hasDot = true;
			clear(res);
		}
		if (hasDot)
			res ~= x;
	});
	return symbolOfString(allSymbols, asTemporaryArray(res));
}

bool hasExtension(in AllSymbols allSymbols, Symbol a) {
	bool hasDot = false;
	eachCharInSymbol(allSymbols, a, (char x) {
		hasDot = hasDot || x == '.';
	});
	return hasDot;
}

Symbol prependSet(ref AllSymbols allSymbols, Symbol a) {
	Opt!Symbol short_ = tryPrefixShortSymbolWithSet(a);
	return has(short_) ? force(short_) : prependToLongStr!"set-"(allSymbols, a);
}

Symbol prependSetDeref(ref AllSymbols allSymbols, Symbol a) {
	return prependToLongStr!"set-deref-"(allSymbols, a);
}

Symbol appendEquals(ref AllSymbols allSymbols, Symbol a) =>
	appendToLongStr!(symbol!"=")(allSymbols, a);

private @trusted Symbol prependToLongStr(string prepend)(ref AllSymbols allSymbols, Symbol a) {
	char[0x100] temp = void;
	temp[0 .. prepend.length] = prepend;
	size_t i = prepend.length;
	eachCharInSymbol(allSymbols, a, (char x) {
		temp[i] = x;
		i++;
		assert(i <= temp.length);
	});
	return getSymbolFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

private @trusted Symbol appendToLongStr(Symbol append)(ref AllSymbols allSymbols, Symbol a) {
	char[0x100] temp = void;
	size_t i = 0;
	foreach (Symbol symbol; [a, append])
		eachCharInSymbol(allSymbols, symbol, (char x) {
			temp[i] = x;
			i++;
			assert(i <= temp.length);
		});
	return getSymbolFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

Symbol concatSymbolsWithDot(ref AllSymbols allSymbols, Symbol a, Symbol b) =>
	concatSymbols(allSymbols, [a, symbol!".", b]);

@trusted Symbol concatSymbols(ref AllSymbols allSymbols, scope Symbol[] symbols) {
	char[0x100] temp = void;
	size_t i = 0;
	foreach (Symbol s; symbols)
		eachCharInSymbol(allSymbols, s, (char x) {
			temp[i] = x;
			i++;
			assert(i <= temp.length);
		});
	return symbolOfString(allSymbols, cast(immutable) temp[0 .. i]);
}

Symbol symbolOfString(ref AllSymbols allSymbols, in string str) {
	Opt!Symbol packed = tryPackShortSymbol(str);
	return has(packed) ? force(packed) : getSymbolFromLongStr(allSymbols, str);
}

void eachCharInSymbol(in AllSymbols allSymbols, Symbol a, in void delegate(char) @safe @nogc pure nothrow cb) {
	if (isShortSymbol(a))
		eachCharInShortSymbol(a.value, cb);
	else {
		assert(isLongSymbol(a));
		eachChar(asLongSymbol(castNonScope_ref(allSymbols), a), cb);
	}
}

uint symbolSize(in AllSymbols allSymbols, Symbol a) {
	uint size = 0;
	eachCharInSymbol(allSymbols, a, (char) {
		size++;
	});
	return size;
}

enum symbol(string name) = getSymbol(name);
private Symbol getSymbol(string name) {
	foreach (size_t i, string s; specialSymbols)
		if (stringsEqual(s[0 .. $ - 1], name))
			return Symbol(i);
	Opt!Symbol opt = tryPackShortSymbol(name);
	return force(opt);
}

string stringOfSymbol(ref Alloc alloc, return scope ref const AllSymbols allSymbols, Symbol a) =>
	stringOfCString(cStringOfSymbol(alloc, allSymbols, a));

CString cStringOfSymbol(ref Alloc alloc, return scope ref const AllSymbols allSymbols, Symbol a) =>
	isLongSymbol(a)
		? asLongSymbol(allSymbols, a)
		: withWriter(alloc, (scope ref Writer writer) {
			writeSymbol(writer, allSymbols, a);
		});

char[bufferSize] symbolAsTempBuffer(size_t bufferSize)(in AllSymbols allSymbols, Symbol a) {
	char[bufferSize] res;
	assert(symbolSize(allSymbols, a) < bufferSize);
	size_t index;
	eachCharInSymbol(allSymbols, a, (char c) {
		res[index] = c;
		index++;
	});
	res[index] = '\0';
	return res;
}

size_t writeSymbolAndGetSize(scope ref Writer writer, in AllSymbols allSymbols, Symbol a) {
	size_t size = 0;
	eachCharInSymbol(allSymbols, a, (char c) {
		writer ~= c;
		size++;
	});
	return size;
}

void writeSymbol(scope ref Writer writer, in AllSymbols allSymbols, Symbol a) {
	writeSymbolAndGetSize(writer, allSymbols, a);
}

void writeQuotedSymbol(scope ref Writer writer, in AllSymbols allSymbols, Symbol a) {
	writer ~= '"';
	eachCharInSymbol(allSymbols, a, (char x) {
		writeEscapedChar(writer, x);
	});
	writer ~= '"';
}

Symbol symbolOfEnum(E)(E a) {
	assertNormalEnum!E();
	static immutable Symbol[] symbols = [staticMap!(symbol, __traits(allMembers, E))];
	return symbols[a];
}

private:

// Bit to be set when the symbol is short
ulong shortSymbolTag() =>
	0x8000000000000000;

size_t shortSymbolMaxChars() =>
	12;

ulong codeForLetter(char a) {
	assert('a' <= a && a <= 'z');
	return 1 + a - 'a';
}
char letterFromCode(ulong code) {
	assert(1 <= code && code <= 26);
	return cast(char) ('a' + (code - 1));
}
ulong codeForHyphen() => 27;
ulong codeForUnderscore() => 28;
ulong codeForNextIsCapitalLetter() => 29;
ulong codeForNextIsDigit() => 30;

ulong setPrefix() =>
	(codeForLetter('s') << (5 * (shortSymbolMaxChars - 1))) |
	(codeForLetter('e') << (5 * (shortSymbolMaxChars - 2))) |
	(codeForLetter('t') << (5 * (shortSymbolMaxChars - 3))) |
	(codeForHyphen << (5 * (shortSymbolMaxChars - 4)));

ulong setPrefixSizeBits() =>
	5 * 4;
ulong setPrefixLowerBitsMask() =>
	(1 << setPrefixSizeBits) - 1;
ulong setPrefixMask() =>
	setPrefixLowerBitsMask << (5 * 8);

Opt!Symbol tryPrefixShortSymbolWithSet(Symbol a) {
	if (isShortSymbol(a) && (a.value & setPrefixMask) == 0) {
		ulong shift = 0;
		ulong value = a.value;
		while (true) {
			ulong shifted = value << 5;
			if ((shifted & setPrefixMask) != 0)
				break;
			value = shifted;
			shift += 5;
		}
		return some(Symbol(shortSymbolTag | ((setPrefix | value) >> shift)));
	} else
		return none!Symbol;
}

Opt!Symbol tryPackShortSymbol(string str) {
	ulong res = 0;
	size_t len = 0;

	void push(ulong value) {
		res = res << 5;
		res |= value;
		len++;
	}

	foreach (char x; str) {
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
			return none!Symbol;
	}
	return len > shortSymbolMaxChars ? none!Symbol : some(Symbol(res | shortSymbolTag));
}

void eachCharInShortSymbol(ulong value, in void delegate(char) @safe @nogc pure nothrow cb) {
	ulong remaining = shortSymbolMaxChars;
	ulong take() {
		ulong res = (value >> 55) & 0b11111;
		value = value << 5;
		remaining--;
		return res;
	}

	while (remaining != 0) {
		assert(remaining < 999);
		ulong x = take();
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
					cb(cast(char) ('A' + take()));
					break;
				case codeForNextIsDigit:
					cb(cast(char) ('0' + take()));
					break;
			}
		}
	}
}

// Public for test only
public bool isShortSymbol(Symbol a) =>
	(a.value & shortSymbolTag) != 0;

// Public for test only
public bool isLongSymbol(Symbol a) =>
	!isShortSymbol(a);

@trusted CString asLongSymbol(return scope ref const AllSymbols allSymbols, Symbol a) {
	assert(isLongSymbol(a));
	return allSymbols.largeStringFromIndex[safeToSizeT(a.value)];
}

Symbol getSymbolFromLongStr(ref AllSymbols allSymbols, in string str) {
	Opt!Symbol value = allSymbols.largeStringToIndex[str];
	return has(value) ? force(value) : addLargeString(allSymbols, copyToCString(allSymbols.alloc, str));
}

immutable string[] specialSymbols = [
	// Putting operator symbols in precedence order so `symbolPrecedence` from `parseExpr` can be efficient.
	// '-' can't be here because it's a short symbol.
	"||\0",
	"&&\0",
	"??\0",
	"=\0",
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
	"+new\0",
	"~new\0",
	".so\0",
	"as-any-mut-pointer\0",
	"as-fun-pointer\0",
	"begin-pointer\0",
	"call-fun-pointer\0",
	"create-record\0",
	"clock_gettime\0",
	"concrete-model\0",
	"const-pointer\0",
	"crow-config.json\0",
	"cur-exclusion\0",
	"exception-low-level\0",
	"extern-pointer\0",
	"extern-pointers\0",
	"field-pointer\0",
	"file://\0",
	"flags-members\0",
	"has-non-public-fields\0",
	"init-constants\0",
	"interpreter-backtrace\0",
	"is-big-endian\0",
	"is-interpreted\0",
	"is-single-threaded\0",
	"loop-continue\0",
	"mutAllocated\0",
	"parseDiagnostics\0",
	"pointer-cast-from-extern\0",
	"pointer-cast-to-extern\0",
	"pointer-to-field\0",
	"pointer-to-local\0",
	"reference-equal\0",
	"reference-kind\0",
	"set-subscript\0",
	"static-symbols\0",
	"suffix-special\0",
	"to-mut-pointer\0",
	"unsafe-bit-shift-left\0",
	"unsafe-bit-shift-right\0",

	"contentChanges\0",
	"definitionProvider\0",
	"diagnosticsOnlyForUris\0",
	"hoverProvider\0",
	"initializationOptions\0",
	"referencesProvider\0",
	"renameProvider\0",
	"semanticTokensProvider\0",
	"textDocument\0",
	"textDocumentSync\0",
	"tokenModifiers\0",
	"unloadedUris\0",
];
