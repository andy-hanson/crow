module util.symbol;

@safe @nogc pure nothrow:

import std.meta : staticMap;

import util.alloc.alloc : Alloc;
import util.col.array : lastIndexOf, only, small;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : mustAdd, MutMap, size;
import util.conv : safeToUint, safeToSizeT;
import util.hash : HashCode, hashUlong;
import util.opt : force, has, Opt, optOrDefault, none, some;
import util.string : copyString, CString, SmallString, smallString, stringsEqual;
import util.util : assertNormalEnum, castNonScope_ref, optEnumOfString, stringOfEnum, stripUnderscore;
import util.writer : makeStringWithWriter, withStackWriter, withWriter, writeEscapedChar, Writer;

immutable struct Symbol {
	@safe @nogc pure nothrow:
	// This is either:
	// * A short symbol, tagged with 'shortSymbolTag'
	// * An index into 'largeStrings'.
	uint value; // Public for 'switch'
	@disable this();
	private this(uint v) { value = v; }

	uint asUintForTaggedUnion() =>
		value;
	static Symbol fromUintForTaggedUnion(uint value) =>
		Symbol(value);

	HashCode hash() =>
		hashUlong(value);
}

struct AllSymbols {
	@safe @nogc pure nothrow:

	@trusted this(return scope Alloc* a) {
		allocPtr = a;
		foreach (string str; specialSymbols) {
			Opt!Symbol packed = tryPackShortSymbol(str);
			assert(!has(packed));
			cast(void) addLargeString(this, str);
		}
	}

	private:
	Alloc* allocPtr;
	MutMap!(SmallString, Symbol) largeStringToIndex;
	MutArr!SmallString largeStringFromIndex;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

// WARN: 'value' must have been allocated by a.alloc
private Symbol addLargeString(ref AllSymbols a, immutable string value) {
	size_t index = mutArrSize(a.largeStringFromIndex);
	assert(size(a.largeStringToIndex) == index);
	Symbol res = Symbol(safeToUint(index));
	SmallString small = smallString(value);
	mustAdd(a.alloc, a.largeStringToIndex, small, res);
	push(a.alloc, a.largeStringFromIndex, small);
	return res;
}

Symbol addExtension(scope ref AllSymbols allSymbols, Symbol a, Extension extension) {
	assert(extension != Extension.other);
	return extension == Extension.none
		? a
		: makeLongSymbol(allSymbols, (scope ref Writer writer) {
			writeSymbol(writer, allSymbols, a);
			writeExtension(writer, extension);
		});
}

Symbol alterExtension(scope ref AllSymbols allSymbols, Symbol a, Extension newExtension) =>
	alterExtensionCb(allSymbols, a, (scope ref Writer writer) {
		writeExtension(writer, newExtension);
	});

void writeExtension(scope ref Writer writer, Extension a) {
	if (a != Extension.none) {
		writer ~= '.';
		writer ~= stringOfEnum(a);
	}
}

private Symbol makeSymbol(
	scope ref AllSymbols allSymbols,
	in void delegate(scope ref Writer) @safe @nogc pure nothrow cb,
) =>
	withStackWriter!(0x1000, Symbol)((scope ref Alloc _, scope ref Writer writer) {
		cb(writer);
	}, (in string s) => symbolOfString(allSymbols, s));

Symbol alterExtensionCb(
	scope ref AllSymbols allSymbols,
	Symbol a,
	in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb,
) =>
	makeSymbol(allSymbols, (scope ref Writer writer) {
		bool on = true;
		eachCharInSymbol(allSymbols, a, (char x) {
			if (on) {
				if (x == '.')
					on = false;
				else
					writer ~= x;
			}
		});
		cb(writer);
	});

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
		string s = asLongSymbol(allSymbols, a);
		Opt!size_t lastDot = lastIndexOf(s, '.');
		if (has(lastDot)) {
			Opt!Extension res = optEnumOfString!Extension(s[force(lastDot) + 1 .. $]);
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
	return optOrDefault!Symbol(packed, () => getSymbolFromLongString(allSymbols, str));
}

void eachCharInSymbol(in AllSymbols allSymbols, Symbol a, in void delegate(char) @safe @nogc pure nothrow cb) {
	if (isShortSymbol(a))
		eachCharInShortSymbol(a, cb);
	else {
		assert(isLongSymbol(a));
		foreach (char x; asLongSymbol(castNonScope_ref(allSymbols), a))
			cb(x);
	}
}

uint symbolSize(in AllSymbols allSymbols, Symbol a) =>
	isShortSymbol(a)
		? shortSymbolSize(a)
		: safeToUint(asLongSymbol(allSymbols, a).length);

enum symbol(string name) = getSymbol(name);
private Symbol getSymbol(string name) {
	foreach (size_t i, string s; specialSymbols)
		if (stringsEqual(s, name))
			return Symbol(safeToUint(i));
	Opt!Symbol opt = tryPackShortSymbol(name);
	return force(opt);
}

string stringOfSymbol(ref Alloc alloc, return scope ref const AllSymbols allSymbols, Symbol a) =>
	isLongSymbol(a)
		? asLongSymbol(allSymbols, a)
		: makeStringWithWriter(alloc, (scope ref Writer writer) {
			writeSymbol(writer, allSymbols, a);
		});

CString cStringOfSymbol(ref Alloc alloc, return scope ref const AllSymbols allSymbols, Symbol a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeSymbol(writer, allSymbols, a);
	});

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
	static immutable Symbol[] symbols = [staticMap!(symbol, staticMap!(stripUnderscore, __traits(allMembers, E)))];
	return symbols[a];
}

Symbol toLowerCase(ref AllSymbols allSymbols, Symbol a) =>
	makeSymbol(allSymbols, (scope ref Writer writer) {
		eachCharInSymbol(allSymbols, a, (char x) {
			writer ~= toLowerCase(x);
		});
	});

// Only use for things that can't possibly be short symbols (for example, if they always have a '.')
private Symbol makeLongSymbol(
	scope ref AllSymbols allSymbols,
	in void delegate(scope ref Writer) @safe @nogc pure nothrow cb,
) =>
	withStackWriter!0x1000((scope ref Alloc _, scope ref Writer writer) {
		cb(writer);
	}, (in string x) => getSymbolFromLongString(allSymbols, x));

char toLowerCase(char a) =>
	'A' <= a && a <= 'Z'
		? cast(char) ('a' + (a - 'A'))
		: a;

private:

// Bit to be set when the symbol is short
uint shortSymbolTag() =>
	0x80000000;

size_t shortSymbolMaxChars() =>
	32 / shortSymbolBitsPerCode;

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

uint setPrefix() =>
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
	if (str.length <= shortSymbolMaxChars) {
		uint res = 0;
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
	} else
		return none!Symbol;
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

public @trusted string asLongSymbol(return scope ref const AllSymbols allSymbols, Symbol a) {
	assert(isLongSymbol(a));
	return allSymbols.largeStringFromIndex[safeToSizeT(a.value)];
}

Symbol getSymbolFromLongString(ref AllSymbols allSymbols, in string str) {
	Opt!Symbol value = allSymbols.largeStringToIndex[smallString(str)];
	return optOrDefault!Symbol(value, () => addLargeString(allSymbols, copyString(allSymbols.alloc, str)));
}

immutable string[] specialSymbols = [
	// Putting operator symbols in precedence order so `symbolPrecedence` from `parseExpr` can be efficient.
	// '-' can't be here because it's a short symbol.
	"||",
	"&&",
	"??",
	"=",
	"==",
	"!=",
	"<",
	"<=",
	">",
	">=",
	"<=>",
	"|",
	"^",
	"&",
	"~",
	"~=",
	"~~",
	"~~=",
	"..",
	"<<",
	">>",
	"+",
	"*",
	"/",
	"%",
	"**",
	"!",

	// from names in Crow code
	"as-any-mut-pointer",
	"as-fun-pointer",
	"begin-pointer",
	"call-fun-pointer",
	"create-record",
	"clock_gettime",
	"concrete-model",
	"const-pointer",
	"crow-config.json",
	"exception-low-level",
	"extern-pointer",
	"extern-pointers",
	"field-pointer",
	"file://",
	"flags-members",
	"has-non-public-fields",
	"init-constants",
	"interpreter-backtrace",
	"is-big-endian",
	"is-interpreted",
	"is-single-threaded",
	"loop-continue",
	"mutAllocated",
	"parseDiagnostics",
	"pointer-cast-from-extern",
	"pointer-cast-to-extern",
	"pointer-to-field",
	"pointer-to-local",
	"reference-equal",
	"reference-kind",
	"set-subscript",
	"shared-of-mut-lambda",
	"static-symbols",
	"suffix-special",
	"to-mut-pointer",
	"unsafe-bit-shift-left",
	"unsafe-bit-shift-right",

	// from perf
	"buildToLowProgram",
	"gccCreateProgram",
	"generateBytecode",
	"instantiateFun",
	"instantiateSpec",
	"instantiateStruct",
	"invokeCCompiler",
	"onFileChanged",
	"storageFileInfo",

	// from names in compiled code
	"__builtin_popcountl",

	// from compile
	"vc140.pdb",

	// from LSP
	"contentChanges",
	"definitionProvider",
	"diagnosticsOnlyForUris",
	"hoverProvider",
	"initializationOptions",
	"referencesProvider",
	"renameProvider",
	"semanticTokensProvider",
	"textDocument",
	"textDocumentSync",
	"tokenModifiers",
	"unloadedUris",

	// Below are needed when using 32 bit instead of 64 bit symbols
	"abstract",
	"aliases",
	"alignment",
	"allInsts",
	"allSymbols",
	"allUris",
	"all-tests",
	"anonymous",
	"as-const",
	"as-string",
	"atan2f",
	"atomic-bool",
	"bootstrap",
	"builtin",
	"byAlloc",
	"byMeasure",
	"capabilities",
	"changes",
	"character",
	"checkCall",
	"closure",
	"closure-ref",
	"collection",
	"comment",
	"concretize",
	"condition",
	"constant",
	"containing",
	"content",
	"contents",
	"continue",
	"countAllocs",
	"countBlocks",
	"count-ones",
	"default",
	"definition",
	"destruct",
	"destructure",
	"diagnostics",
	"enum-members",
	"exitCode",
	"exports",
	"expr-kind",
	"extern_",
	"field-index",
	"file-type",
	"float32",
	"float64",
	"for-break",
	"force-ctx",
	"force-shared",
	"for-loop",
	"freeBlocks",
	"frontend",
	"fun-data",
	"fun-kind",
	"fun-name",
	"fun-pointers",
	"fun-util",
	"funInsts",
	"fun-mut",
	"fun-pointer",
	"fun-shared",
	"function",
	"fut-expr",
	"gccCompile",
	"gccJit",
	"generated",
	"import-kind",
	"imports",
	"include",
	"includeDir",
	"int16",
	"int32",
	"int64",
	"interface",
	"interpolate",
	"interpreter",
	"is-less",
	"is-wasm",
	"is-windows",
	"keyword",
	"keywordPos",
	"library-name",
	"library-names",
	"longjmp",
	"loop-break",
	"lspState",
	"mallocs",
	"mark-arr",
	"mark-ctx",
	"mark-visit",
	"matched",
	"member-index",
	"member-name",
	"members",
	"memmove",
	"message",
	"messages",
	"modifiers",
	"modules",
	"mutability",
	"mut-list",
	"mut-map",
	"mut-pointer",
	"nanosleep",
	"nat16",
	"nat32",
	"nat64",
	"newName",
	"newText",
	"new-void",
	"n-parents",
	"nominal",
	"ok-if-unused",
	"operation",
	"overflow",
	"overhead",
	"param0",
	"param1",
	"param2",
	"param3",
	"param4",
	"param5",
	"param6",
	"param7",
	"param8",
	"param9",
	"param-types",
	"parents",
	"parseFile",
	"pointee",
	"pointer",
	"pointer-cast",
	"position",
	"private",
	"pthread",
	"question-pos",
	"records",
	"refKeys",
	"refPairs",
	"return-type",
	"rt-main",
	"severity",
	"set-deref",
	"set-n0",
	"shared-list",
	"shared-map",
	"size-bytes",
	"size-of",
	"spec-impls",
	"specInsts",
	"storage",
	"structInsts",
	"structs",
	"subscript",
	"suffix-pos",
	"thread-local",
	"throw-impl",
	"tokenTypes",
	"truncate-to",
	"trusted",
	"tuple2",
	"tuple3",
	"tuple4",
	"tuple5",
	"tuple6",
	"tuple7",
	"tuple8",
	"tuple9",
	"type-arg",
	"type-args",
	"type-index",
	"type-params",
	"unknownUris",
	"unsafe-add",
	"unsafe-div",
	"unsafe-mod",
	"unsafe-mul",
	"unsafe-sub",
	"unsafe-to",
	"updates",
	"user-main",
	"re-exports",
	"static_",
	"variadic",
	"var-kind",
	"visibility",
	"with-block",
	"wrap-add",
	"wrap-mul",
	"wrap-sub",
];
