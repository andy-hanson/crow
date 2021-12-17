module util.sym;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrUtil : contains, every, findIndex;
import util.col.mutArr : MutArr, mutArrAt, mutArrSize, push;
import util.col.mutDict : addToMutDict, getAt_mut, mutDictSize, MutStringDict;
import util.col.str : copyToSafeCStr, CStr, eachChar, SafeCStr, safeCStr, strOfSafeCStr;
import util.conv : safeToSizeT;
import util.hash : Hasher, hashUlong;
import util.opt : force, has, Opt, none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.util : drop, unreachable, verify;
import util.writer : finishWriter, writeChar, writeStatic, Writer;

immutable(Opt!size_t) indexOfSym(ref immutable Sym[] a, immutable Sym value) {
	return findIndex!Sym(a, (ref immutable Sym it) => symEq(it, value));
}

immutable(bool) containsSym(ref immutable Sym[] a, immutable Sym b) {
	return contains(a, b, (ref immutable Sym a, ref immutable Sym b) => symEq(a, b));
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
		for (SpecialSym s = SpecialSym.min; s <= SpecialSym.max; s++)
			drop(addLargeString(this, strOfSpecial(s)));
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
	verify(!isSymOperator(a));
	immutable size_t oldSize = symSize(allSymbols, a);
	immutable size_t newSize = 4 + oldSize;

	//TODO: only do inside 'else'
	Writer writer = Writer(allSymbols.allocPtr);
	writeStatic(writer, "set-");
	writeSym(writer, allSymbols, a);
	immutable string str = finishWriter(writer);

	if (isShortSym(a) && newSize <= shortSymMaxChars) {
		immutable Sym res = prefixShortSymWithSet(a, oldSize);
		verify(symEq(symOfStr(allSymbols, str), res));
		return res;
	} else
		return getSymFromLongStr(allSymbols, str);
}

immutable(Sym) symOfStr(ref AllSymbols allSymbols, scope immutable string str) {
	immutable Sym res = canPackShortSym(str)
		? immutable Sym(packShortSym(str))
		: getSymFromLongStr(allSymbols, str);
	assertSym(allSymbols, res, str);
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
	range,
	shiftLeft,
	shiftRight,
	plus,
	minus,
	times,
	divide,
	exponent,
	not,
}

enum SpecialSym {
	clock_gettime,
	get_nprocs,
	pthread_condattr_destroy,
	pthread_condattr_init,
	pthread_condattr_setclock,
	pthread_cond_broadcast,
	pthread_cond_destroy,
	pthread_cond_init,
	pthread_create,
	pthread_join,
	pthread_mutexattr_destroy,
	pthread_mutexattr_init,
	pthread_mutex_destroy,
	pthread_mutex_init,
	pthread_mutex_lock,
	pthread_mutex_unlock,
	sched_yield,

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
	island_and_exclusion,

	underscore,
	force_sendable,
	flags_members,
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
		case Operator.concatEquals:
			return safeCStr!"~=";
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
		case Operator.exponent:
			return safeCStr!"**";
		case Operator.not:
			return safeCStr!"!";
	}
}

private immutable(SafeCStr) strOfSpecial(immutable SpecialSym a) {
	final switch (a) {
		case SpecialSym.clock_gettime:
			return safeCStr!"clock_gettime";
		case SpecialSym.get_nprocs:
			return safeCStr!"get_nprocs";
		case SpecialSym.pthread_condattr_destroy:
			return safeCStr!"pthread_condattr_destroy";
		case SpecialSym.pthread_condattr_init:
			return safeCStr!"pthread_condattr_init";
		case SpecialSym.pthread_condattr_setclock:
			return safeCStr!"pthread_condattr_setclock";
		case SpecialSym.pthread_cond_broadcast:
			return safeCStr!"pthread_cond_broadcast";
		case SpecialSym.pthread_cond_destroy:
			return safeCStr!"pthread_cond_destroy";
		case SpecialSym.pthread_cond_init:
			return safeCStr!"pthread_cond_init";
		case SpecialSym.pthread_create:
			return safeCStr!"pthread_create";
		case SpecialSym.pthread_join:
			return safeCStr!"pthread_join";
		case SpecialSym.pthread_mutexattr_destroy:
			return safeCStr!"pthread_mutexattr_destroy";
		case SpecialSym.pthread_mutexattr_init:
			return safeCStr!"pthread_mutexattr_init";
		case SpecialSym.pthread_mutex_destroy:
			return safeCStr!"pthread_mutex_destroy";
		case SpecialSym.pthread_mutex_init:
			return safeCStr!"pthread_mutex_init";
		case SpecialSym.pthread_mutex_lock:
			return safeCStr!"pthread_mutex_lock";
		case SpecialSym.pthread_mutex_unlock:
			return safeCStr!"pthread_mutex_unlock";
		case SpecialSym.sched_yield:
			return safeCStr!"sched_yield";

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
		case SpecialSym.island_and_exclusion:
			return safeCStr!"island-and-exclusion";

		case SpecialSym.underscore:
			return safeCStr!"_";
		case SpecialSym.force_sendable:
			return safeCStr!"force-sendable";
		case SpecialSym.flags_members:
			return safeCStr!"flags-members";
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
	verify(canPackShortSym(name));
	return immutable Sym(packShortSym(name));
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

immutable(string) strOfSym(ref Alloc alloc, ref const AllSymbols allSymbols, immutable Sym a) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeSym(writer, allSymbols, a);
	return finishWriter(writer);
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

immutable(size_t) writeSymAndGetSize(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym a) {
	size_t size = 0;
	eachCharInSym(allSymbols, a, (immutable char c) {
		writeChar(writer, c);
		size++;
	});
	return size;
}

void writeSym(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym a) {
	writeSymAndGetSize(writer, allSymbols, a);
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

immutable(bool) canPackChar5(immutable char c) {
	return ('a' <= c && c <= 'z') || c == '-' || ('0' <= c && c <= '3');
}

immutable(bool) canPackChar6(immutable char c) {
	return canPackChar5(c) || ('4' <= c && c <= '9') || c == '!';
}

immutable(ulong) packChar5(immutable char c) {
	// 0 means no character, so start at 1
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '3' ? 1 + 26 + 1 + c - '0' :
		unreachable!ulong;
}

immutable(ulong) packChar6(immutable char c) {
	return 'a' <= c && c <= 'z' ? 1 + c - 'a' :
		c == '-' ? 1 + 26 :
		'0' <= c && c <= '9' ? 1 + 26 + 1 + c - '0' :
		c == '!' ? 1 + 26 + 1 + 10 :
		unreachable!ulong;
}

immutable(char) unpackChar(immutable ulong n) {
	verify(n != 0);
	return n < 1 + 26 ? cast(char) ('a' + (n - 1)) :
		n == 1 + 26 ? '-' :
		n < 1 + 26 + 1 + 10 ? cast(char) ('0' + (n - 1 - 26 - 1)) :
		n == 1 + 26 + 1 + 10 ? '!' :
		unreachable!char;
}

// Bit to be set when the sym is short
immutable ulong shortSymTag = 0x8000000000000000;

immutable size_t shortSymMaxChars = 12;

immutable(bool) canPackShortSym(immutable string str) {
	return str.length > shortSymMaxChars
		? false
		: str.length <= 2
		? every!char(str, (ref immutable char c) => canPackChar6(c))
		: every!char(str[$ - 2 .. $], (ref immutable char c) => canPackChar6(c)) &&
			every!char(str[0 .. $ - 2], (ref immutable char c) => canPackChar5(c));
}

immutable ulong setPrefix =
	(packChar5('-') << (5 * 3)) |
	(packChar5('t') << (5 * 2)) |
	(packChar5('e') << (5 * 1)) |
	packChar5('s');

immutable(Sym) prefixShortSymWithSet(immutable Sym a, immutable size_t symSize) {
	verify(isShortSym(a));
	verify(symSize != 0);
	immutable ulong inputSizeBits = symSize == 1
		? 2 + 6
		: 2 + 2 * 6 + (symSize - 2) * 5;
	// If prepended to a symbol of size 1, the '-' should take up 6 bits.
	immutable ulong prefixSizeBits = symSize == 1 ? 6 + 5 * 3 : 5 * 4;
	immutable ulong prefixBits = setPrefix << (64 - inputSizeBits - prefixSizeBits);
	return immutable Sym(a.value | prefixBits);
}

immutable(ulong) packShortSym(immutable string str) {
	verify(canPackShortSym(str));

	ulong res = 0;
	foreach (immutable size_t i; 0 .. shortSymMaxChars) {
		immutable bool is6Bit = i < 2;
		immutable ulong value = () {
			if (i < str.length) {
				immutable char c = str[str.length - 1 - i];
				return is6Bit ? packChar6(c) : packChar5(c);
			} else
				return 0;
		}();
		res = res << (is6Bit ? 6 : 5);
		res |= value;
	}
	verify((res & shortSymTag) == 0);
	return res | shortSymTag;
}

void eachCharInShortSym(
	ulong p,
	scope void delegate(immutable char) @safe @nogc pure nothrow cb,
) {
	foreach (immutable size_t i; 0 .. 10) {
		immutable size_t c = p & 0b11111;
		if (c != 0)
			cb(unpackChar(c));
		p = p >> 5;
	}
	foreach (immutable size_t i; 0 .. 2) {
		immutable size_t c = p & 0b111111;
		if (c != 0)
			cb(unpackChar(c));
		p = p >> 6;
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

void assertSym(ref const AllSymbols allSymbols, immutable Sym sym, immutable string str) {
	//TODO:KILL
	size_t idx = 0;
	eachCharInSym(allSymbols, sym, (immutable char c) {
		immutable char expected = str[idx];
		idx = idx + 1;
		verify(c == expected);
	});
	verify(idx == str.length);
}

@trusted immutable(bool) strEqCStr(immutable string a, immutable CStr b) {
	return *b == '\0'
		? a.length == 0
		: a.length != 0 && a[0] == *b && strEqCStr(a[1 .. $], b + 1);
}
