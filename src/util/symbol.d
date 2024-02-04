module util.symbol;

@safe @nogc pure nothrow:

import std.meta : staticMap;

import util.alloc.alloc : Alloc;
import util.col.array : lastIndexOf, only;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : mustAdd, MutMap, size;
import util.col.mutMaxArr : asTemporaryArray, MutMaxArr, mutMaxArr;
import util.conv : safeToUint, safeToSizeT;
import util.hash : HashCode, hashUlong;
import util.opt : force, has, MutOpt, Opt, optOrDefault, none, noneMut, some, someMut;
import util.string : copyToCString, eachChar, CString, cStringSize, MutCString, stringsEqual, stringOfCString;
import util.util : assertNormalEnum, castNonScope_ref, optEnumOfString, stringOfEnum;
import util.writer : digitChar, withStackWriter, withWriter, writeEscapedChar, Writer;

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

Symbol addExtension(scope ref AllSymbols allSymbols, Symbol a, Extension extension) {
	assert(extension != Extension.other);
	return extension == Extension.none
		? a
		: makeLongSymbol(allSymbols, (scope ref Writer writer) {
			writeSymbol(writer, allSymbols, a);
			writer ~= '.';
			writer ~= stringOfEnum(extension);
		});
}

Symbol alterExtension(scope ref AllSymbols allSymbols, Symbol a, Extension extension) =>
	addExtension(allSymbols, removeExtension(allSymbols, a), extension);

// TODO:PERF This could be cached (with getExtension)
@trusted Symbol removeExtension(scope ref AllSymbols allSymbols, Symbol a) {
	char[0x100] buf = symbolAsTempBuffer!0x100(allSymbols, a);
	string str = stringOfCString(CString(cast(immutable) buf.ptr));
	Opt!size_t index = lastIndexOf(str, '.');
	return has(index) ? symbolOfString(allSymbols, str[0 .. force(index)]) : a;
}

enum Extension {
	c,
	crow,
	dll,
	exe,
	ilk,
	json,
	lib,
	none, // ""
	obj,
	other,
	pdb,
}

// TODO:PERF This could be cached (with removeExtension)
Extension getExtension(ref AllSymbols allSymbols, Symbol a) {
	if (isShortSymbol(a))
		// Since only a long symbol can have a '.'
		return Extension.none;
	else {
		MutCString s = asLongSymbol(allSymbols, a);
		MutOpt!MutCString lastDot = noneMut!MutCString;
		while (*s != '\0') {
			if (*s == '.')
				lastDot = someMut(s);
			s++;
		}
		if (has(lastDot)) {
			MutCString ext = force(lastDot);
			ext++;
			Opt!Extension res = optEnumOfString!Extension(stringOfCString(ext));
			return has(res)
				? (force(res) == Extension.none ? Extension.other : force(res))
				: Extension.other;
		} else
			return Extension.none;
	}
}

bool hasExtension(in AllSymbols allSymbols, Symbol a) {
	bool hasDot = false;
	eachCharInSymbol(allSymbols, a, (char x) {
		hasDot = hasDot || x == '.';
	});
	return hasDot;
}

Symbol prependSet(ref AllSymbols allSymbols, Symbol a) =>
	optOrDefault!Symbol(tryPrefixShortSymbolWithSet(a), () =>
		prependToLongString(allSymbols, "set-", a));

Symbol prependSetDeref(ref AllSymbols allSymbols, Symbol a) =>
	prependToLongString(allSymbols, "set-deref-", a);

Symbol appendEquals(ref AllSymbols allSymbols, Symbol a) =>
	appendToLongString(allSymbols, a, "=");

private Symbol prependToLongString(ref AllSymbols allSymbols, in string prepend, Symbol a) =>
	makeLongSymbol(allSymbols, (scope ref Writer writer) {
		writer ~= prepend;
		writeSymbol(writer, allSymbols, a);
	});

private Symbol appendToLongString(ref AllSymbols allSymbols, Symbol a, in string append) =>
	makeLongSymbol(allSymbols, (scope ref Writer writer) {
		writeSymbol(writer, allSymbols, a);
		writer ~= append;
	});

// Only use for things that can't possibly be short symbols (for exapmle, if they always have a '.')
private Symbol makeLongSymbol(
	scope ref AllSymbols allSymbols,
	in void delegate(scope ref Writer) @safe @nogc pure nothrow cb,
) =>
	withStackWriter!0x1000((scope ref Alloc _, scope ref Writer writer) {
		cb(writer);
	}, (in string x) => getSymbolFromLongString(allSymbols, x));

Symbol concatSymbolsWithDot(ref AllSymbols allSymbols, Symbol a, Symbol b) =>
	makeLongSymbol(allSymbols, (scope ref Writer writer) {
		writeSymbol(writer, allSymbols, a);
		writer ~= '.';
		writeSymbol(writer, allSymbols, b);
	});

Symbol addPrefixAndExtension(scope ref AllSymbols allSymbols, string prefix, Symbol b, string extension) =>
	makeLongSymbol(allSymbols, (scope ref Writer writer) {
		writer ~= prefix;
		writeSymbol(writer, allSymbols, b);
		writer ~= extension;
	});

Symbol symbolOfString(ref AllSymbols allSymbols, in string str) {
	Opt!Symbol packed = tryPackShortSymbol(str);
	return has(packed) ? force(packed) : getSymbolFromLongString(allSymbols, str);
}

void eachCharInSymbol(in AllSymbols allSymbols, Symbol a, in void delegate(char) @safe @nogc pure nothrow cb) {
	if (isShortSymbol(a))
		eachCharInShortSymbol(a, cb);
	else {
		assert(isLongSymbol(a));
		eachChar(asLongSymbol(castNonScope_ref(allSymbols), a), cb);
	}
}

uint symbolSize(in AllSymbols allSymbols, Symbol a) =>
	isShortSymbol(a)
		? shortSymbolSize(a)
		: safeToUint(cStringSize(asLongSymbol(allSymbols, a)));

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

Symbol toLowerCase(ref AllSymbols allSymbols, Symbol a) =>
	withStackWriter!0x1000((scope ref Alloc _, scope ref Writer writer) {
		eachCharInSymbol(allSymbols, a, (char x) {
			writer ~= toLowerCase(x);
		});
	}, (in string x) => symbolOfString(allSymbols, x));
char toLowerCase(char a) =>
	'A' <= a && a <= 'Z'
		? cast(char) ('a' + (a - 'A'))
		: a;

private:

// Bit to be set when the symbol is short
ulong shortSymbolTag() =>
	0x8000000000000000;

size_t shortSymbolMaxChars() =>
	12;

ubyte codeForLetter(char a) {
	assert('a' <= a && a <= 'z');
	return cast(ubyte) (1 + a - 'a');
}
char letterFromCode(ubyte code) {
	assert(1 <= code && code <= 26);
	return cast(char) ('a' + (code - 1));
}
ubyte codeForHyphen() => 27;
ubyte codeForUnderscore() => 28;
ubyte codeForNextIsCapitalLetter() => 29;
ubyte codeForNextIsDigit() => 30;

ubyte shortSymbolBitsPerCode() => 5;

ulong setPrefix() =>
	(codeForLetter('s') << (shortSymbolBitsPerCode * 3)) |
	(codeForLetter('e') << (shortSymbolBitsPerCode * 2)) |
	(codeForLetter('t') << (shortSymbolBitsPerCode * 1)) |
	codeForHyphen;

Opt!Symbol tryPrefixShortSymbolWithSet(Symbol a) {
	if (isShortSymbol(a)) {
		uint size = shortSymbolCodeCount(a);
		return size <= (shortSymbolMaxChars - "set-".length)
			? some(Symbol(a.value | (setPrefix << (size * shortSymbolBitsPerCode))))
			: none!Symbol;
	} else
		return none!Symbol;
}

uint shortSymbolCodeCount(in Symbol a) {
	uint res;
	eachShortSymbolCodeReverse(a, (ubyte _) {
		res++;
	});
	return res;
}

uint shortSymbolSize(in Symbol a) {
	uint res;
	eachShortSymbolCodeReverse(a, (ubyte code) {
		switch (code) {
			case codeForNextIsCapitalLetter:
			case codeForNextIsDigit:
				break;
			default:
				res++;
		}
	});
	return res;
}

void eachShortSymbolCodeReverse(in Symbol a, in void delegate(ubyte code) @safe @nogc pure nothrow cb) {
	assert(isShortSymbol(a));
	ulong value = a.value & ~shortSymbolTag;
	while (value != 0) {
		cb(value & 0b11111);
		value >>= shortSymbolBitsPerCode;
	}
}

Opt!Symbol tryPackShortSymbol(in string str) {
	ulong res = 0;
	size_t len = 0;

	void push(ulong value) {
		res = res << shortSymbolBitsPerCode;
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

void eachCharInShortSymbol(Symbol a, in void delegate(char) @safe @nogc pure nothrow cb) {
	assert(isShortSymbol(a));
	ulong value = a.value;
	ulong remaining = shortSymbolMaxChars;
	ubyte take() {
		ubyte res = (value >> (shortSymbolBitsPerCode * (shortSymbolMaxChars - 1))) & 0b11111;
		value = value << shortSymbolBitsPerCode;
		remaining--;
		return res;
	}

	while (remaining != 0) {
		ubyte code = take();
		switch (code) {
			case 0:
				break;
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
			default:
				cb(letterFromCode(code));
				break;
		}
	}
}

// Public for test only
public bool isShortSymbol(Symbol a) =>
	(a.value & shortSymbolTag) != 0;

// Public for test only
public bool isLongSymbol(Symbol a) =>
	!isShortSymbol(a);

public @trusted CString asLongSymbol(return scope ref const AllSymbols allSymbols, Symbol a) {
	assert(isLongSymbol(a));
	return allSymbols.largeStringFromIndex[safeToSizeT(a.value)];
}

Symbol getSymbolFromLongString(ref AllSymbols allSymbols, in string str) {
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

	// from names in Crow code
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

	// from perf
	"buildToLowProgram\0",
	"gccCreateProgram\0",
	"generateBytecode\0",
	"instantiateFun\0",
	"instantiateSpec\0",
	"instantiateStruct\0",
	"invokeCCompiler\0",
	"onFileChanged\0",
	"storageFileInfo\0",

	// from names in compiled code
	"__builtin_popcountl\0",

	// from compile
	"vc140.pdb\0",

	// from LSP
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
