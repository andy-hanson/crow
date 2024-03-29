module util.symbol;

@safe @nogc nothrow:

import std.meta : staticMap;

import util.alloc.alloc : Alloc, AllocKind, MetaAlloc, newAlloc;
import util.col.array : lastIndexOf, only, small;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : mustAdd, MutMap, size;
import util.conv : safeToUint;
import util.hash : HashCode, hashUlong;
import util.opt : force, has, Opt, optOrDefault, none, some;
import util.string : copyString, CString, SmallString, smallString, stringsEqual;
import util.unicode : mustUnicodeDecode;
import util.util : assertNormalEnum, optEnumOfString, stringOfEnum, stripUnderscore;
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

	void writeTo(scope ref Writer writer) {
		writeSymbolAndGetSize(writer, this);
	}

	int opApply(in int delegate(dchar) @safe @nogc pure nothrow cb) {
		if (isShortSymbol(this))
			return eachCharInShortSymbol(this, (char x) => cb(x));
		else {
			mustUnicodeDecode(asLongSymbol(this), (dchar x) {
				int res = cb(x);
				assert(res == 0);
			});
			return 0;
		}
	}

	int opApply(in int delegate(char) @safe @nogc pure nothrow cb) {
		if (isShortSymbol(this))
			return eachCharInShortSymbol(this, cb);
		else {
			foreach (char x; asLongSymbol(this)) {
				int res = cb(x);
				if (res != 0) return res;
			}
			return 0;
		}
	}
}

@trusted void initSymbols(MetaAlloc* metaAlloc) {
	symbolAlloc = newAlloc(AllocKind.symbol, metaAlloc);
	foreach (string str; specialSymbols) {
		Opt!Symbol packed = tryPackShortSymbol(str);
		assert(!has(packed));
		cast(void) addLargeString(str);
	}
}

private __gshared Alloc* symbolAlloc;
private __gshared MutMap!(SmallString, Symbol) largeStringToIndex;
private __gshared MutArr!SmallString largeStringFromIndex;

private @trusted pure Symbol getSymbolFromLongString(in string value) =>
	(cast(Symbol function(in string) @safe @nogc pure nothrow) &getSymbolFromLongString_impure)(value);
private @system Symbol getSymbolFromLongString_impure(in string str) {
	Opt!Symbol value = largeStringToIndex[smallString(str)];
	return has(value) ? force(value) : addLargeString(copyString(*symbolAlloc, str));
}

private @system Symbol addLargeString(string value) {
	size_t index = mutArrSize(largeStringFromIndex);
	assert(size(largeStringToIndex) == index);
	Symbol res = Symbol(safeToUint(index));
	SmallString small = smallString(value);
	mustAdd(*symbolAlloc, largeStringToIndex, small, res);
	push(*symbolAlloc, largeStringFromIndex, small);
	return res;
}

@trusted pure string asLongSymbol(Symbol a) =>
	(cast(string function(Symbol) @safe @nogc pure nothrow) &asLongSymbol_impure)(a);
private @system string asLongSymbol_impure(Symbol a) {
	assert(isLongSymbol(a));
	return largeStringFromIndex[a.value];
}

pure:

Symbol addExtension(Symbol a, Extension extension) {
	assert(extension != Extension.other);
	return extension == Extension.none
		? a
		: makeLongSymbol((scope ref Writer writer) {
			writer ~= a;
			writeExtension(writer, extension);
		});
}

Symbol alterExtension(Symbol a, Extension newExtension) =>
	alterExtensionCb(a, (scope ref Writer writer) {
		writeExtension(writer, newExtension);
	});

void writeExtension(scope ref Writer writer, Extension a) {
	if (a != Extension.none) {
		writer ~= '.';
		writer ~= stringOfEnum(a);
	}
}

private Symbol makeSymbol(in void delegate(scope ref Writer) @safe @nogc pure nothrow cb) =>
	withStackWriter!(0x1000, Symbol)((scope ref Alloc _, scope ref Writer writer) {
		cb(writer);
	}, (in string s) => symbolOfString(s));

Symbol alterExtensionCb(Symbol a, in void delegate(scope ref Writer writer) @safe @nogc pure nothrow cb) =>
	makeSymbol((scope ref Writer writer) {
		size_t index = 0;
		size_t lastDot = size_t.max;
		foreach (char x; a) {
			if (x == '.')
				lastDot = index;
			index++;
		}

		index = 0;
		foreach (char x; a) {
			if (index < lastDot)
				writer ~= x;
			index++;
		}
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

Extension getExtension(Symbol a) {
	if (isShortSymbol(a))
		// Since only a long symbol can have a '.'
		return Extension.none;
	else {
		string s = asLongSymbol(a);
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

bool hasExtension(Symbol a) {
	bool hasDot = false;
	foreach (char x; a)
		hasDot = hasDot || x == '.';
	return hasDot;
}

Symbol prependSet(Symbol a) =>
	optOrDefault!Symbol(tryPrefixShortSymbolWithSet(a), () =>
		prependToLongString("set-", a));

Symbol prependSetDeref(Symbol a) =>
	prependToLongString("set-deref-", a);

Symbol appendEquals(Symbol a) =>
	appendToLongString(a, "=");

private Symbol prependToLongString(in string prepend, Symbol a) =>
	makeLongSymbol((scope ref Writer writer) {
		writer ~= prepend;
		writer ~= a;
	});

private Symbol appendToLongString(Symbol a, in string append) =>
	makeLongSymbol((scope ref Writer writer) {
		writer ~= a;
		writer ~= append;
	});

Symbol concatSymbolsWithDot(Symbol a, Symbol b) =>
	makeLongSymbol((scope ref Writer writer) {
		writer ~= a;
		writer ~= '.';
		writer ~= b;
	});

Symbol addPrefixAndExtension(string prefix, Symbol b, string extension) =>
	makeLongSymbol((scope ref Writer writer) {
		writer ~= prefix;
		writer ~= b;
		writer ~= extension;
	});

Symbol symbolOfString(in string str) {
	Opt!Symbol packed = tryPackShortSymbol(str);
	return optOrDefault!Symbol(packed, () => getSymbolFromLongString(str));
}

uint symbolSize(Symbol a) =>
	isShortSymbol(a) ? shortSymbolSize(a) : safeToUint(asLongSymbol(a).length);

enum symbol(string name) = getSymbol(name);
private Symbol getSymbol(string name) {
	foreach (size_t i, string s; specialSymbols)
		if (stringsEqual(s, name))
			return Symbol(safeToUint(i));
	Opt!Symbol opt = tryPackShortSymbol(name);
	return force(opt);
}

string stringOfSymbol(ref Alloc alloc, Symbol a) =>
	isLongSymbol(a)
		? asLongSymbol(a)
		: makeStringWithWriter(alloc, (scope ref Writer writer) {
			writer ~= a;
		});

CString cStringOfSymbol(ref Alloc alloc, Symbol a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writer ~= a;
	});

size_t writeSymbolAndGetSize(scope ref Writer writer, Symbol a) {
	size_t size = 0;
	foreach (char c; a) {
		writer ~= c;
		size++;
	}
	return size;
}

void writeQuotedSymbol(scope ref Writer writer, Symbol a) {
	writer ~= '"';
	foreach (char x; a)
		writeEscapedChar(writer, x);
	writer ~= '"';
}

Symbol symbolOfEnum(E)(E a) {
	assertNormalEnum!E();
	static immutable Symbol[] symbols = [staticMap!(symbol, staticMap!(stripUnderscore, __traits(allMembers, E)))];
	return symbols[a];
}

Symbol toLowerCase(Symbol a) =>
	makeSymbol((scope ref Writer writer) {
		foreach (char x; a)
			writer ~= toLowerCase(x);
	});

// Only use for things that can't possibly be short symbols (for example, if they always have a '.')
private Symbol makeLongSymbol(in void delegate(scope ref Writer) @safe @nogc pure nothrow cb) =>
	withStackWriter!0x1000((scope ref Alloc _, scope ref Writer writer) {
		cb(writer);
	}, (in string x) => getSymbolFromLongString(x));

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

int eachCharInShortSymbol(Symbol a, in int delegate(char) @safe @nogc pure nothrow cb) {
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
		int res = () {
			switch (code) {
				case 0:
					return 0;
				case codeForHyphen:
					return cb('-');
				case codeForUnderscore:
					return cb('_');
				case codeForNextIsCapitalLetter:
					return cb(cast(char) ('A' + take()));
				case codeForNextIsDigit:
					return cb(cast(char) ('0' + take()));
				default:
					return cb(letterFromCode(code));
			}
		}();
		if (res != 0)
			return res;
	}
	return 0;
}

// Public for test only
public bool isShortSymbol(Symbol a) =>
	(a.value & shortSymbolTag) != 0;

// Public for test only
public bool isLongSymbol(Symbol a) =>
	!isShortSymbol(a);

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
	"bool-low-level",
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
	"is-abort-on-throw",
	"is-big-endian",
	"is-interpreted",
	"is-single-threaded",
	"is-stack-trace-enabled",
	"loop-continue",
	"mutAllocated",
	"number-low-level",
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
	"symbol-low-level",
	"to-mut-pointer",
	"trust-as-string",
	"unsafe-bit-shift-left",
	"unsafe-bit-shift-right",

	// from perf
	"buildToLowProgram",
	"gccCreateProgram",
	"generateBytecode",
	"instantiateFun",
	"instantiateSpec",
	"instantiateStruct",
	"integralValues",
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
	"all-tests",
	"anonymous",
	"as-const",
	"atan2f",
	"atomic-bool",
	"bootstrap",
	"builtin",
	"built-on",
	"byAlloc",
	"byMeasure",
	"capabilities",
	"case-exprs",
	"case-values",
	"changes",
	"char32",
	"character",
	"checkCall",
	"closure",
	"closure-ref",
	"collection",
	"comment",
	"commit-hash",
	"compare",
	"comparison",
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
	"d-compiler",
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
	"first-keyword",
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
	"has-assertions",
	"if-kind",
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
	"interpreter-uses-tail-calls",
	"is-debug-build",
	"is-less",
	"is-signed",
	"is-wasm",
	"is-windows",
	"keyword",
	"keyword-pos",
	"library-name",
	"library-names",
	"literal",
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
	"second-keyword",
	"set-deref",
	"set-n0",
	"severity",
	"shared-list",
	"shared-map",
	"size-bytes",
	"size-of",
	"spec-impls",
	"specInsts",
	"static_",
	"storage",
	"structInsts",
	"structs",
	"subscript",
	"suffix-pos",
	"supports-jit",
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
	"variadic",
	"var-kind",
	"visibility",
	"with-block",
	"wrap-add",
	"wrap-mul",
	"wrap-sub",
];
