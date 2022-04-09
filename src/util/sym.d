module util.sym;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrUtil : findIndex;
import util.col.mutArr : MutArr, mutArrAt, mutArrSize, push;
import util.col.mutDict : addToMutDict, getAt_mut, mutDictSize, MutStringDict;
import util.col.str : copyToSafeCStr, eachChar, SafeCStr, safeCStr, strOfSafeCStr;
import util.conv : safeToSizeT;
import util.hash : Hasher, hashUlong;
import util.opt : force, has, Opt, none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.util : drop, verify;
import util.writer : finishWriterToSafeCStr, writeChar, Writer;

immutable(Opt!size_t) indexOfSym(ref immutable Sym[] a, immutable Sym value) {
	return findIndex!Sym(a, (ref immutable Sym it) => symEq(it, value));
}

struct Sym {
	@safe @nogc pure nothrow:
	// This is either:
	// * A short symbol, tagged with 'shortSymTag'
	// * An index into 'largeStrings'.
	// The first members of 'largeStrings' match the members of the 'Operator' enum,
	// so an operator can cast to/from a Sym.
	// After that come SpecialSyms.
	immutable ulong value; // Public for 'switch'
	@disable this();
	// TODO:PRIVATE
	immutable this(immutable ulong v) { value = v; }
}

struct AllSymbols {
	@safe @nogc pure nothrow:

	this(Ptr!Alloc allocPtr_) {
		allocPtr = allocPtr_;
		static assert(Operator.min == 0 && SpecialSym.min == 0);
		for (Operator op = Operator.min; op <= Operator.max; op++)
			drop(addLargeString(this, strOfOperator(op)));
		for (SpecialSym s = SpecialSym.min; s <= SpecialSym.max; s++) {
			immutable SafeCStr str = strOfSpecial(s);
			debug {
				immutable Opt!Sym packed = tryPackShortSym(strOfSafeCStr(str));
				verify(!has(packed));
			}
			drop(addLargeString(this, str));
		}
	}

	private:
	Ptr!Alloc allocPtr;
	MutStringDict!(immutable Sym) largeStringToIndex;
	MutArr!(immutable SafeCStr) largeStringFromIndex;

	ref Alloc alloc() return scope {
		return allocPtr.deref();
	}
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

@trusted immutable(Sym) concatSymsWithDot(ref AllSymbols allSymbols, immutable Sym a, immutable Sym b) {
	char[0x100] temp = void;
	size_t i = 0;
	void push(immutable char c) {
		temp[i] = c;
		i++;
		verify(i <= temp.length);
	}
	eachCharInSym(allSymbols, a, (immutable char x) {
		push(x);
	});
	push('.');
	eachCharInSym(allSymbols, b, (immutable char x) {
		push(x);
	});
	return getSymFromLongStr(allSymbols, cast(immutable) temp[0 .. i]);
}

immutable(Sym) emptySym = shortSym("");

immutable(Sym) symOfStr(ref AllSymbols allSymbols, scope immutable string str) {
	immutable Opt!Sym packed = tryPackShortSym(str);
	return has(packed) ? force(packed) : getSymFromLongStr(allSymbols, str);
}

enum Operator {
	or2,
	and2,
	question2,
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
	tildeEquals,
	tilde2,
	tilde2Equals,
	range,
	shiftLeft,
	shiftRight,
	plus,
	minus,
	times,
	divide,
	modulo,
	exponent,
	not,
}

enum SpecialSym {
	// all below are hyphenated
	as_any_mut_ptr,
	init_constants,
	ptr_cast_from_extern,
	ptr_cast_to_extern,
	truncate_to_int64,
	unsafe_bit_shift_left,
	unsafe_bit_shift_right,
	unsafe_to_int8,
	unsafe_to_int16,
	unsafe_to_int32,
	unsafe_to_int64,
	unsafe_to_nat8,
	unsafe_to_nat16,
	unsafe_to_nat32,
	unsafe_to_nat64,

	call_with_ctx,

	force_sendable,
	flags_members,
	cur_exclusion,
	is_big_endian,
	is_single_threaded,

	dotNew,

	dotC,
	dotCrow,
	dotExe,
	dotJson,

	clock_gettime,
}

immutable(Sym) symForOperator(immutable Operator a) {
	return immutable Sym(a);
}

immutable(Sym) symForSpecial(immutable SpecialSym a) {
	return immutable Sym(Operator.max + 1 + a);
}

immutable(SafeCStr) strOfOperator(immutable Operator a) {
	final switch (a) {
		case Operator.or2:
			return safeCStr!"||";
		case Operator.and2:
			return safeCStr!"&&";
		case Operator.question2:
			return safeCStr!"??";
		case Operator.equal:
			return safeCStr!"==";
		case Operator.notEqual:
			return safeCStr!"!=";
		case Operator.less:
			return safeCStr!"<";
		case Operator.lessOrEqual:
			return safeCStr!"<=";
		case Operator.greater:
			return safeCStr!">";
		case Operator.greaterOrEqual:
			return safeCStr!">=";
		case Operator.compare:
			return safeCStr!"<=>";
		case Operator.or1:
			return safeCStr!"|";
		case Operator.xor1:
			return safeCStr!"^";
		case Operator.and1:
			return safeCStr!"&";
		case Operator.range:
			return safeCStr!"..";
		case Operator.tilde:
			return safeCStr!"~";
		case Operator.tildeEquals:
			return safeCStr!"~=";
		case Operator.tilde2:
			return safeCStr!"~~";
		case Operator.tilde2Equals:
			return safeCStr!"~~=";
		case Operator.shiftLeft:
			return safeCStr!"<<";
		case Operator.shiftRight:
			return safeCStr!">>";
		case Operator.plus:
			return safeCStr!"+";
		case Operator.minus:
			return safeCStr!"-";
		case Operator.times:
			return safeCStr!"*";
		case Operator.divide:
			return safeCStr!"/";
		case Operator.modulo:
			return safeCStr!"%";
		case Operator.exponent:
			return safeCStr!"**";
		case Operator.not:
			return safeCStr!"!";
	}
}

private immutable(SafeCStr) strOfSpecial(immutable SpecialSym a) {
	final switch (a) {
		case SpecialSym.as_any_mut_ptr:
			return safeCStr!"as-any-mut-ptr";
		case SpecialSym.init_constants:
			return safeCStr!"init-constants";
		case SpecialSym.ptr_cast_from_extern:
			return safeCStr!"ptr-cast-from-extern";
		case SpecialSym.ptr_cast_to_extern:
			return safeCStr!"ptr-cast-to-extern";
		case SpecialSym.truncate_to_int64:
			return safeCStr!"truncate-to-int64";
		case SpecialSym.unsafe_bit_shift_left:
			return safeCStr!"unsafe-bit-shift-left";
		case SpecialSym.unsafe_bit_shift_right:
			return safeCStr!"unsafe-bit-shift-right";
		case SpecialSym.unsafe_to_int8:
			return safeCStr!"unsafe-to-int8";
		case SpecialSym.unsafe_to_int16:
			return safeCStr!"unsafe-to-int16";
		case SpecialSym.unsafe_to_int32:
			return safeCStr!"unsafe-to-int32";
		case SpecialSym.unsafe_to_int64:
			return safeCStr!"unsafe-to-int64";
		case SpecialSym.unsafe_to_nat8:
			return safeCStr!"unsafe-to-nat8";
		case SpecialSym.unsafe_to_nat16:
			return safeCStr!"unsafe-to-nat16";
		case SpecialSym.unsafe_to_nat32:
			return safeCStr!"unsafe-to-nat32";
		case SpecialSym.unsafe_to_nat64:
			return safeCStr!"unsafe-to-nat64";

		case SpecialSym.call_with_ctx:
			return safeCStr!"call-with-ctx";

		case SpecialSym.force_sendable:
			return safeCStr!"force-sendable";
		case SpecialSym.flags_members:
			return safeCStr!"flags-members";
		case SpecialSym.cur_exclusion:
			return safeCStr!"cur-exclusion";
		case SpecialSym.is_big_endian:
			return safeCStr!"is-big-endian";
		case SpecialSym.is_single_threaded:
			return safeCStr!"is-single-threaded";

		case SpecialSym.dotNew:
			return safeCStr!".new";
		case SpecialSym.dotC:
			return safeCStr!".c";
		case SpecialSym.dotCrow:
			return safeCStr!".crow";
		case SpecialSym.dotExe:
			return safeCStr!".exe";
		case SpecialSym.dotJson:
			return safeCStr!".json";

		case SpecialSym.clock_gettime:
			return safeCStr!"clock_gettime";
	}
}

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

immutable(bool) symEq(immutable Sym a, immutable Sym b) {
	return a.value == b.value;
}

immutable(Sym) shortSym(immutable string name) {
	immutable Opt!Sym opt = tryPackShortSym(name);
	return force(opt);
}

immutable(ulong) shortSymValue(immutable string name) {
	return shortSym(name).value;
}

immutable(ulong) operatorSymValue(immutable Operator a) {
	return symForOperator(a).value;
}

immutable(ulong) specialSymValue(immutable SpecialSym a) {
	return symForSpecial(a).value;
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
		writeChar(writer, c);
		size++;
	});
	return size;
}

void writeSym(scope ref Writer writer, scope ref const AllSymbols allSymbols, immutable Sym a) {
	writeSymAndGetSize(writer, allSymbols, a);
}

void writeQuotedSym(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym a) {
	writeChar(writer, '"');
	writeSym(writer, allSymbols, a);
	writeChar(writer, '"');
}

immutable(bool) isSymOperator(immutable Sym a) {
	return a.value <= Operator.max;
}

immutable(Opt!Operator) operatorForSym(immutable Sym a) {
	if (isSymOperator(a)) {
		immutable Operator res = cast(immutable Operator) a.value;
		verify(res <= Operator.max);
		return some(res);
	} else
		return none!Operator;
}

void hashSym(ref Hasher hasher, immutable Sym a) {
	hashUlong(hasher, a.value);
}

private:

// Bit to be set when the sym is short
immutable ulong shortSymTag = 0x8000000000000000;

immutable size_t shortSymMaxChars = 12;

immutable(ulong) codeForLetter(immutable char a) {
	verify('a' <= a && a <= 'z');
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
public immutable(bool) isShortSym(immutable Sym a) {
	return (a.value & shortSymTag) != 0;
}

// Public for test only
public immutable(bool) isLongSym(immutable Sym a) {
	return !isShortSym(a);
}

@trusted immutable(SafeCStr) asLongSym(return scope ref const AllSymbols allSymbols, immutable Sym a) {
	verify(isLongSym(a));
	return mutArrAt(allSymbols.largeStringFromIndex, safeToSizeT(a.value));
}

immutable(Sym) getSymFromLongStr(ref AllSymbols allSymbols, scope immutable string str) {
	const Opt!(immutable Sym) value = getAt_mut(allSymbols.largeStringToIndex, str);
	return has(value) ? force(value) : addLargeString(allSymbols, copyToSafeCStr(allSymbols.alloc, str));
}
