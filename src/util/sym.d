module util.sym;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutMap : mustAdd, MutMap, size;
import util.col.mutMaxArr : clear, MutMaxArr, mutMaxArr, push, pushAll, tempAsArr;
import util.col.str : copyToSafeCStr, eachChar, SafeCStr, strEq, strOfSafeCStr;
import util.conv : safeToSizeT;
import util.hash : HashCode, hashUlong;
import util.opt : force, has, Opt, none, some;
import util.util : castNonScope_ref;
import util.writer : digitChar, withWriter, writeEscapedChar, Writer;

immutable struct Sym {
	@safe @nogc pure nothrow:
	// This is either:
	// * A short symbol, tagged with 'shortSymTag'
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
		foreach (string s; specialSyms) { {
			SafeCStr str = SafeCStr(s.ptr);
			debug {
				Opt!Sym packed = tryPackShortSym(strOfSafeCStr(str));
				assert(!has(packed));
			}
			cast(void) addLargeString(this, str);
		} }
	}

	private:
	Alloc* allocPtr;
	MutMap!(immutable string, Sym) largeStringToIndex;
	MutArr!SafeCStr largeStringFromIndex;

	ref inout(Alloc) alloc() return scope inout =>
		*allocPtr;
}

// WARN: 'value' must have been allocated by a.alloc
private Sym addLargeString(ref AllSymbols a, SafeCStr value) {
	size_t index = mutArrSize(a.largeStringFromIndex);
	assert(size(a.largeStringToIndex) == index);
	Sym res = Sym(index);
	mustAdd(a.alloc, a.largeStringToIndex, strOfSafeCStr(value), res);
	push(a.alloc, a.largeStringFromIndex, value);
	return res;
}

Sym appendHexExtension(ref AllSymbols allSymbols, Sym a, in ubyte[] bytes) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	eachCharInSym(allSymbols, a, (char x) {
		push(res, x);
	});
	push(res, '.');
	foreach (ubyte x; bytes)
		pushAll!(0x100, immutable char)(res, [digitChar(x / 16), digitChar(x % 16)]);
	return symOfStr(allSymbols, tempAsArr(res));
}

Sym addExtension(Sym extension)(ref AllSymbols allSymbols, Sym a) {
	static if (extension == sym!"")
		return a;
	else {
		return appendToLongStr!extension(allSymbols, a);
	}
}

Sym alterExtension(Sym extension)(ref AllSymbols allSymbols, Sym a) =>
	addExtension!extension(allSymbols, removeExtension(allSymbols, a));

// TODO:PERF This could be cached (with getExtension)
Sym removeExtension(ref AllSymbols allSymbols, Sym a) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	bool hasDot = false;
	eachCharInSym(allSymbols, a, (char x) {
		if (!hasDot) {
			if (x == '.') {
				hasDot = true;
			} else {
				push(res, x);
			}
		}
	});
	return symOfStr(allSymbols, tempAsArr(res));
}

// TODO:PERF This could be cached (with removeExtension)
Sym getExtension(ref AllSymbols allSymbols, Sym a) {
	MutMaxArr!(0x100, immutable char) res = mutMaxArr!(0x100, immutable char);
	bool hasDot = false;
	eachCharInSym(allSymbols, a, (char x) {
		if (x == '.') {
			hasDot = true;
			clear(res);
		}
		if (hasDot) {
			push(res, x);
		}
	});
	return symOfStr(allSymbols, tempAsArr(res));
}

bool hasExtension(in AllSymbols allSymbols, Sym a) {
	bool hasDot = false;
	eachCharInSym(allSymbols, a, (char x) {
		hasDot = hasDot || x == '.';
	});
	return hasDot;
}

Sym prependSet(ref AllSymbols allSymbols, Sym a) {
	Opt!Sym short_ = tryPrefixShortSymWithSet(a);
	return has(short_) ? force(short_) : prependToLongStr!"set-"(allSymbols, a);
}

Sym prependSetDeref(ref AllSymbols allSymbols, Sym a) {
	return prependToLongStr!"set-deref-"(allSymbols, a);
}

Sym appendEquals(ref AllSymbols allSymbols, Sym a) =>
	appendToLongStr!(sym!"=")(allSymbols, a);

private @trusted Sym prependToLongStr(string prepend)(ref AllSymbols allSymbols, Sym a) {
	char[0x100] temp = void;
	temp[0 .. prepend.length] = prepend;
	size_t i = prepend.length;
	eachCharInSym(allSymbols, a, (char x) {
		temp[i] = x;
		i++;
		assert(i <= temp.length);
	});
	return getSymFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

private @trusted Sym appendToLongStr(Sym append)(ref AllSymbols allSymbols, Sym a) {
	char[0x100] temp = void;
	size_t i = 0;
	foreach (Sym sym; [a, append])
		eachCharInSym(allSymbols, sym, (char x) {
			temp[i] = x;
			i++;
			assert(i <= temp.length);
		});
	return getSymFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

Sym concatSymsWithDot(ref AllSymbols allSymbols, Sym a, Sym b) =>
	concatSyms(allSymbols, [a, sym!".", b]);

@trusted Sym concatSyms(ref AllSymbols allSymbols, scope Sym[] syms) {
	char[0x100] temp = void;
	size_t i = 0;
	foreach (Sym s; syms)
		eachCharInSym(allSymbols, s, (char x) {
			temp[i] = x;
			i++;
			assert(i <= temp.length);
		});
	return symOfStr(allSymbols, cast(immutable) temp[0 .. i]);
}

Sym symOfStr(ref AllSymbols allSymbols, in string str) {
	Opt!Sym packed = tryPackShortSym(str);
	return has(packed) ? force(packed) : getSymFromLongStr(allSymbols, str);
}

void eachCharInSym(in AllSymbols allSymbols, Sym a, in void delegate(char) @safe @nogc pure nothrow cb) {
	if (isShortSym(a))
		eachCharInShortSym(a.value, cb);
	else {
		assert(isLongSym(a));
		eachChar(asLongSym(castNonScope_ref(allSymbols), a), cb);
	}
}

uint symSize(in AllSymbols allSymbols, Sym a) {
	uint size = 0;
	eachCharInSym(allSymbols, a, (char) {
		size++;
	});
	return size;
}

enum sym(string name) = getSym(name);
private Sym getSym(string name) {
	foreach (size_t i, string s; specialSyms)
		if (strEq(s[0 .. $ - 1], name))
			return Sym(i);
	Opt!Sym opt = tryPackShortSym(name);
	return force(opt);
}

SafeCStr safeCStrOfSym(ref Alloc alloc, return scope ref const AllSymbols allSymbols, Sym a) =>
	isLongSym(a)
		? asLongSym(allSymbols, a)
		: withWriter(alloc, (scope ref Writer writer) {
			writeSym(writer, allSymbols, a);
		});

char[bufferSize] symAsTempBuffer(size_t bufferSize)(in AllSymbols allSymbols, Sym a) {
	char[bufferSize] res;
	assert(symSize(allSymbols, a) < bufferSize);
	size_t index;
	eachCharInSym(allSymbols, a, (char c) {
		res[index] = c;
		index++;
	});
	res[index] = '\0';
	return res;
}

size_t writeSymAndGetSize(scope ref Writer writer, in AllSymbols allSymbols, Sym a) {
	size_t size = 0;
	eachCharInSym(allSymbols, a, (char c) {
		writer ~= c;
		size++;
	});
	return size;
}

void writeSym(scope ref Writer writer, in AllSymbols allSymbols, Sym a) {
	writeSymAndGetSize(writer, allSymbols, a);
}

void writeQuotedSym(scope ref Writer writer, in AllSymbols allSymbols, Sym a) {
	writer ~= '"';
	eachCharInSym(allSymbols, a, (char x) {
		writeEscapedChar(writer, x);
	});
	writer ~= '"';
}

private:

// Bit to be set when the sym is short
ulong shortSymTag() =>
	0x8000000000000000;

size_t shortSymMaxChars() =>
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
	(codeForLetter('s') << (5 * (shortSymMaxChars - 1))) |
	(codeForLetter('e') << (5 * (shortSymMaxChars - 2))) |
	(codeForLetter('t') << (5 * (shortSymMaxChars - 3))) |
	(codeForHyphen << (5 * (shortSymMaxChars - 4)));

ulong setPrefixSizeBits() =>
	5 * 4;
ulong setPrefixLowerBitsMask() =>
	(1 << setPrefixSizeBits) - 1;
ulong setPrefixMask() =>
	setPrefixLowerBitsMask << (5 * 8);

Opt!Sym tryPrefixShortSymWithSet(Sym a) {
	if (isShortSym(a) && (a.value & setPrefixMask) == 0) {
		ulong shift = 0;
		ulong value = a.value;
		while (true) {
			ulong shifted = value << 5;
			if ((shifted & setPrefixMask) != 0)
				break;
			value = shifted;
			shift += 5;
		}
		return some(Sym(shortSymTag | ((setPrefix | value) >> shift)));
	} else
		return none!Sym;
}

Opt!Sym tryPackShortSym(string str) {
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
			return none!Sym;
	}
	return len > shortSymMaxChars ? none!Sym : some(Sym(res | shortSymTag));
}

void eachCharInShortSym(ulong value, in void delegate(char) @safe @nogc pure nothrow cb) {
	ulong remaining = shortSymMaxChars;
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
public bool isShortSym(Sym a) =>
	(a.value & shortSymTag) != 0;

// Public for test only
public bool isLongSym(Sym a) =>
	!isShortSym(a);

@trusted SafeCStr asLongSym(return scope ref const AllSymbols allSymbols, Sym a) {
	assert(isLongSym(a));
	return allSymbols.largeStringFromIndex[safeToSizeT(a.value)];
}

Sym getSymFromLongStr(ref AllSymbols allSymbols, in string str) {
	Opt!Sym value = allSymbols.largeStringToIndex[str];
	return has(value) ? force(value) : addLargeString(allSymbols, copyToSafeCStr(allSymbols.alloc, str));
}

immutable string[] specialSyms = [
	// Putting operator symbols in precedence order so `symPrecedence` from `parseExpr` can be efficient.
	// '-' can't be here because it's a short sym.
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
	"textDocument\0",
	"unloadedUris\0",
];
