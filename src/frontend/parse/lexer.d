module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralAst, NameAndRange, rangeOfNameAndRange;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.bools : Bool, False, True;
import util.collection.arr : arrOfRange, at, begin, empty, first, last, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : cat, rtail, slice;
import util.collection.str : copyStr, CStr, emptyStr, NulTerminatedStr, stripNulTerminator, strLiteral;
import util.opt : force, has, Opt, optOr;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym :
	AllSymbols,
	getSymFromAlphaIdentifier,
	getSymFromOperator,
	isAlphaIdentifierStart,
	isAlphaIdentifierContinue,
	isDigit,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym;
import util.types : safeI32FromU32, safeSizeTToU32;
import util.util : drop, todo, unreachable, verify;

private enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer(SymAlloc) {
	//TODO:PRIVATE
	Ptr!(AllSymbols!SymAlloc) allSymbols;
	private:
	ArrBuilder!ParseDiagnostic diags;
	immutable CStr sourceBegin;
	//TODO:PRIVATE
	public CStr ptr;
	immutable IndentKind indentKind;
}

@trusted Lexer!SymAlloc createLexer(Alloc, SymAlloc)(
	ref Alloc alloc,
	Ptr!(AllSymbols!SymAlloc) allSymbols,
	immutable NulTerminatedStr source,
) {
	// Note: We *are* relying on the nul terminator to stop the lexer.
	immutable string str = stripNulTerminator(source);
	immutable string useStr = !empty(str) && last(str) == '\n' ? str : rtail(cat!char(alloc, str, strLiteral("\n\0")));
	return Lexer!SymAlloc(
		allSymbols,
		ArrBuilder!ParseDiagnostic(),
		begin(useStr),
		begin(useStr),
		detectIndentKind(useStr));
}

immutable(char) curChar(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return *lexer.ptr;
}

immutable(Pos) curPos(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return posOfPtr(lexer, lexer.ptr);
}

private immutable(Pos) posOfPtr(SymAlloc)(ref const Lexer!SymAlloc lexer, immutable CStr ptr) {
	return safeSizeTToU32(ptr - lexer.sourceBegin);
}

void addDiag(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable RangeWithinFile range,
	immutable ParseDiag diag,
) {
	add(alloc, lexer.diags, immutable ParseDiagnostic(range, diag));
}

immutable(ParseDiagnostic[]) finishDiags(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return finishArr(alloc, lexer.diags);
}

void addDiagAtChar(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer, immutable ParseDiag diag) {
	immutable Pos a = curPos(lexer);
	addDiag(alloc, lexer, immutable RangeWithinFile(a, lexer.curChar == '\0' ? a : a + 1), diag);
}

void addDiagUnexpected(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.UnexpectedCharacter(curChar(lexer))));
}

@trusted immutable(Bool) tryTake(SymAlloc)(ref Lexer!SymAlloc lexer, immutable char c) {
	if (*lexer.ptr == c) {
		lexer.ptr++;
		return True;
	} else
		return False;
}

@trusted immutable(Bool) tryTake(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr c) {
	CStr ptr2 = lexer.ptr;
	for (CStr cptr = c; *cptr != 0; cptr++) {
		if (*ptr2 != *cptr)
			return False;
		ptr2++;
	}
	lexer.ptr = ptr2;
	return True;
}

immutable(Bool) takeOrAddDiagExpected(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable char c,
	immutable ParseDiag.Expected.Kind kind,
) {
	immutable Bool res = tryTake(lexer, c);
	if (!res)
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(kind)));
	return res;
}

immutable(Bool) takeOrAddDiagExpected(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable CStr c,
	immutable ParseDiag.Expected.Kind kind,
) {
	immutable Bool res = tryTake(lexer, c);
	if (!res)
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(kind)));
	return res;
}

void skipShebang(SymAlloc)(ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, "#!"))
		skipRestOfLineAndNewline(lexer);
}

//TODO: this is only called at base level, so dedenting should be impossible..
void skipBlankLines(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable IndentDelta i = skipLinesAndGetIndentDelta(alloc, lexer, 0);
	matchIndentDelta!void(
		i,
		(ref immutable IndentDelta.DedentOrSame it) {
			verify(it.nDedents == 0);
		},
		(ref immutable IndentDelta.Indent it) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipRestOfLineAndNewline(lexer);
			skipBlankLines(alloc, lexer);
		});
}

enum NewlineOrIndent {
	newline,
	indent,
}

immutable(NewlineOrIndent) takeNewlineOrIndent_topLevel(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (!takeOrAddDiagExpected(alloc, lexer, '\n', ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer, 0);
	return matchIndentDelta!(immutable NewlineOrIndent)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) {
			verify(it.nDedents == 0);
			return NewlineOrIndent.newline;
		},
		(ref immutable IndentDelta.Indent) {
			return NewlineOrIndent.indent;
		});
}

immutable(Bool) takeIndentOrDiagTopLevel(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return takeIndentOrFailGeneric!(immutable Bool)(
		alloc,
		lexer,
		0,
		() => True,
		(immutable RangeWithinFile, immutable uint dedent) {
			verify(dedent == 0);
			return False;
		});
}

immutable(Bool) takeIndentOrDiagTopLevelAfterNewline(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer, 0);
	return matchIndentDelta!(immutable Bool)(
		delta,
		(ref immutable IndentDelta.DedentOrSame dedent) {
			verify(dedent.nDedents == 0);
			addDiag(
				alloc,
				lexer,
				immutable RangeWithinFile(start, start + 1),
				immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return False;
		},
		(ref immutable IndentDelta.Indent) => True);
}

immutable(T) takeIndentOrFailGeneric(T, Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
	scope immutable(T) delegate() @safe @nogc pure nothrow cbIndent,
	scope immutable(T) delegate(immutable RangeWithinFile, immutable uint) @safe @nogc pure nothrow cbFail,
) {
	immutable Pos start = curPos(lexer);
	immutable IndentDelta delta = takeNewlineAndReturnIndentDelta(alloc, lexer, curIndent);
	return matchIndentDelta!(immutable T)(
		delta,
		(ref immutable IndentDelta.DedentOrSame dedent) {
			addDiag(
				alloc,
				lexer,
				immutable RangeWithinFile(start, start + 1),
				immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return cbFail(range(lexer, start), dedent.nDedents);
		},
		(ref immutable IndentDelta.Indent) {
			return cbIndent();
		});
}

private @trusted immutable(IndentDelta) takeNewlineAndReturnIndentDelta(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	if (*lexer.ptr != '\n') {
		//TODO: not always expecting indent..
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipUntilNewlineNoDiag(lexer);
	}
	verify(*lexer.ptr == '\n');
	lexer.ptr++;
	return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
}

void takeDedentFromIndent1(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer, 1);
	immutable Bool success = matchIndentDelta!(immutable Bool)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) => immutable Bool(it.nDedents == 1),
		(ref immutable IndentDelta.Indent) => False);
	if (!success) {
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.dedent)));
		skipRestOfLineAndNewline(lexer);
		takeDedentFromIndent1(alloc, lexer);
	}
}

immutable(NewlineOrIndent) tryTakeIndentAfterNewline_topLevel(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer, 0);
	return matchIndentDelta!(immutable NewlineOrIndent)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) {
			verify(it.nDedents == 0);
			return NewlineOrIndent.newline;
		},
		(ref immutable IndentDelta.Indent) =>
			NewlineOrIndent.indent);
}

immutable(uint) takeNewlineOrDedentAmount(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	// Must be at the end of a line
	if (!takeOrAddDiagExpected(alloc, lexer, '\n', ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
	return matchIndentDelta!(immutable uint)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) {
			return it.nDedents;
		},
		(ref immutable IndentDelta.Indent) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipUntilNewlineNoDiag(lexer);
			return takeNewlineOrDedentAmount(alloc, lexer, curIndent);
		});
}

enum NewlineOrDedent {
	newline,
	dedent,
}

immutable(NewlineOrDedent) takeNewlineOrSingleDedent(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	switch (takeNewlineOrDedentAmount(alloc, lexer, 1)) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

immutable(RangeWithinFile) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable Pos begin) {
	verify(begin <= curPos(lexer));
	return immutable RangeWithinFile(begin, curPos(lexer));
}

void addDiagOnReservedName(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable NameAndRange name,
) {
	addDiag(alloc, lexer, rangeOfNameAndRange(name), immutable ParseDiag(immutable ParseDiag.ReservedName(name.name)));
}

struct SymAndIsReserved {
	immutable NameAndRange name;
	immutable Bool isReserved;
}

immutable(SymAndIsReserved) takeNameAllowReserved(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable StrAndIsOperator s = takeNameAsTempStr(alloc, lexer);
	if (s.isOperator) {
		immutable Opt!Sym op = getSymFromOperator(lexer.allSymbols.deref(), s.str);
		if (has(op))
			return immutable SymAndIsReserved(immutable NameAndRange(s.start, force(op)), False);
		else
			// diagnostic: invalid operator
			return todo!(immutable SymAndIsReserved)("!");
	} else {
		immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, s.str);
		return immutable SymAndIsReserved(immutable NameAndRange(s.start, name), isReservedName(name));
	}
}

immutable(NameAndRange) takeNameAndRange(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable SymAndIsReserved s = takeNameAllowReserved(alloc, lexer);
	if (s.isReserved)
		addDiagOnReservedName(alloc, lexer, s.name);
	return s.name;
}

immutable(Sym) takeName(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return takeNameAndRange(alloc, lexer).name;
}

immutable(string) takeQuotedStr(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	return takeOrAddDiagExpected(alloc, lexer, '"', ParseDiag.Expected.Kind.quote)
		? takeStringLiteralAfterQuote(lexer, alloc)
		: emptyStr;
}

@trusted void skipUntilNewlineNoDiag(SymAlloc)(ref Lexer!SymAlloc lexer) {
	while (*lexer.ptr != '\n') {
		assert(*lexer.ptr != '\0');
		lexer.ptr++;
	}
}

private:

@trusted void skipRestOfLineAndNewline(SymAlloc)(ref Lexer!SymAlloc lexer) {
	skipUntilNewlineNoDiag(lexer);
	lexer.ptr++;
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
immutable(IndentKind) detectIndentKind(immutable string str) {
	if (empty(str))
		// No indented lines, so it's irrelevant
		return IndentKind.tabs;
	else {
		immutable char c0 = first(str);
		if (c0 == '\t')
			return IndentKind.tabs;
		else if (c0 == ' ') {
			// Count spaces
			uint i = 0;
			for (; i < size(str); i++)
				if (at(str, i) != ' ')
					break;
			// Only allowed amounts are 2 and 4.
			return i == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
		} else {
			foreach (immutable size_t i; 0..size(str))
				if (at(str, i) == '\n')
					return detectIndentKind(slice(str, i + 1));
			return IndentKind.tabs;
		}
	}
}

//TODO:PRIVATE
public @trusted void backUp(SymAlloc)(ref Lexer!SymAlloc lexer) {
	lexer.ptr--;
}

public @trusted immutable(char) next(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable char res = *lexer.ptr;
	lexer.ptr++;
	return res;
}

immutable(RangeWithinFile) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeSizeTToU32(begin - lexer.sourceBegin));
}

public enum Sign {
	plus,
	minus,
}

public @trusted immutable(LiteralAst) takeNumber(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Opt!Sign sign,
) {
	immutable ulong base = tryTake(lexer, "0x") ? 16 : 10;
	immutable LiteralAst.Nat n = takeNat(lexer, base);
	if (*lexer.ptr == '.' && isDigit(*(lexer.ptr + 1))) {
		lexer.ptr++;
		return immutable LiteralAst(takeFloat(lexer, optOr!Sign(sign, () => Sign.plus), n, base));
	} else if (has(sign))
		final switch (force(sign)) {
			case Sign.plus:
				return immutable LiteralAst(immutable LiteralAst.Int(n.value, immutable Bool(n.value > long.max)));
			case Sign.minus:
				return immutable LiteralAst(immutable LiteralAst.Int(
					-n.value,
					immutable Bool(n.value > (cast(ulong) long.max) + 1)));
		}
	else
		return immutable LiteralAst(n);
}

@system immutable(LiteralAst.Float) takeFloat(SymAlloc)(
	ref Lexer!SymAlloc lexer,
	immutable Sign sign,
	ref immutable LiteralAst.Nat natPart,
	immutable ulong base,
) {
	// TODO: improve accuracy
	const char *cur = lexer.ptr;
	immutable LiteralAst.Nat rest = takeNat(lexer, base);
	immutable Bool overflow = immutable Bool(natPart.overflow || rest.overflow);
	immutable ulong power = lexer.ptr - cur;
	immutable double divisor = pow(1.0, base, power);
	immutable double floatSign = () {
		final switch (sign) {
			case Sign.minus:
				return -1.0;
			case Sign.plus:
				return 1.0;
		}
	}();
	return immutable LiteralAst.Float(floatSign * (natPart.value + (rest.value / divisor)), overflow);
}

immutable(double) pow(immutable double acc, immutable double base, immutable ulong power) {
	return power == 0 ? acc : pow(acc * base, base, power - 1);
}

//TODO: overflow bug possible here
immutable(ulong) getDivisor(immutable ulong acc, immutable ulong a, immutable ulong base) {
	return acc < a ? getDivisor(acc * base, a, base) : acc;
}

@system immutable(LiteralAst.Nat) takeNat(SymAlloc)(ref Lexer!SymAlloc lexer, immutable ulong base) {
	return takeNatRecur(lexer, base, 0, False);
}

@system immutable(LiteralAst.Nat) takeNatRecur(SymAlloc)(
	ref Lexer!SymAlloc lexer,
	immutable ulong base,
	immutable ulong value,
	immutable Bool overflow,
) {
	immutable ulong digit = charToNat(*lexer.ptr);
	if (digit < base) {
		lexer.ptr++;
		immutable ulong newValue = value * base + digit;
		return takeNatRecur(lexer, base, newValue, immutable Bool(overflow || newValue / base != value));
	} else
		return immutable LiteralAst.Nat(value, overflow);
}

immutable(ulong) charToNat(immutable char c) {
	return '0' <= c && c <= '9'
		? c - '0'
		: 'a' <= c && c <= 'f'
		? 10 + (c - 'a')
		: ulong.max;
}

@trusted immutable(string) takeOperatorRest(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	while (isOperatorChar(*lexer.ptr))
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

// NOTE: this will allow taking invalid operators, then we'll issue a diagnostic for them
public immutable(Bool) isOperatorChar(immutable char c) {
	switch (c) {
		case '=':
		case '!':
		case '<':
		case '>':
		case '+':
		case '-':
		case '*':
		case '/':
		case '^':
		case '~':
			return True;
		default:
			return False;
	}
}

public immutable(NameAndRange) takeOperator(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable CStr begin,
) {
	immutable Pos start = posOfPtr(lexer, begin);
	immutable string name = takeOperatorRest(lexer, begin);
	immutable Opt!Sym op = getSymFromOperator(lexer.allSymbols, name);
	immutable Sym operator = () {
		if (has(op))
			return force(op);
		else {
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.InvalidName(copyStr(alloc, name))));
			return shortSymAlphaLiteral("bogus");
		}
	}();
	return immutable NameAndRange(start, operator);
}

immutable(size_t) toHexDigit(immutable char c) {
	if ('0' <= c && c <= '9')
		return c - '0';
	else if ('a' <= c && c <= 'f')
		return 10 + c - 'a';
	else
		return todo!size_t("parse diagnostic -- bad hex digit");
}

public @trusted immutable(string) takeStringLiteralAfterQuote(Alloc, SymAlloc)(
	ref Lexer!SymAlloc lexer,
	ref Alloc alloc,
) {
	immutable CStr begin = lexer.ptr;
	size_t nEscapedCharacters = 0;
	// First get the max size
	while (*lexer.ptr != '"') {
		if (*lexer.ptr == '\\') {
			lexer.ptr++;
			nEscapedCharacters += (*lexer.ptr == 'x' ? 3 : 1);
		}
		lexer.ptr++;
	}

	immutable size_t size = (lexer.ptr - begin) - nEscapedCharacters;
	char* res = cast(char*) alloc.allocateBytes(char.sizeof * size);

	size_t outI = 0;
	lexer.ptr = begin;
	while (*lexer.ptr != '"') {
		if (*lexer.ptr == '\\') {
			lexer.ptr++;
			immutable char c = () {
				immutable char esc = *lexer.ptr;
				switch (esc) {
					case 'x':
						// Take two more
						lexer.ptr++;
						immutable char a = *lexer.ptr;
						lexer.ptr++;
						immutable char b = *lexer.ptr;
						immutable size_t na = toHexDigit(a);
						immutable size_t nb = toHexDigit(b);
						return cast(char) (na * 16 + nb);
					case '"':
						return '"';
					case 'n':
						return '\n';
					case 'r':
						return '\r';
					case 't':
						return '\t';
					case '0':
						return '\0';
					default:
						addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.InvalidStringEscape(esc)));
						return 'a';
				}
			}();
			res[outI] = c;
			outI++;
		} else {
			res[outI] = *lexer.ptr;
			outI++;
		}
		lexer.ptr++;
	}

	// Skip past the closing '"'
	lexer.ptr++;
	verify(outI == size);
	return cast(immutable) res[0..size];
}

public @trusted immutable(string) takeNameRest(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*lexer.ptr == '?' || *lexer.ptr == '!')
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

// Called after the newline
@trusted uint takeIndentAmount(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (*lexer.ptr == '\t') lexer.ptr++;
		if (*lexer.ptr == ' ')
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(True)));
		immutable uint res = (lexer.ptr - begin).safeSizeTToU32;
		return res;
	} else {
		immutable Pos start = curPos(lexer);
		while (*lexer.ptr == ' ')
			lexer.ptr++;
		if (*lexer.ptr == '\t')
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(False)));
		immutable uint nSpaces = (lexer.ptr - begin).safeSizeTToU32;
		immutable uint nSpacesPerIndent = lexer.indentKind == IndentKind.spaces2 ? 2 : 4;
		immutable uint res = nSpaces / nSpacesPerIndent;
		if (res * nSpacesPerIndent != nSpaces)
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
		return res;
	}
}

struct IndentDelta {
	@safe @nogc pure nothrow:

	struct DedentOrSame {
		immutable uint nDedents;
	}
	struct Indent {}
	enum Kind {
		dedentOrSame,
		indent,
	}
	private:
	immutable Kind kind;
	union {
		immutable DedentOrSame dedentOrSame_;
		immutable Indent indent_;
	}

	public:
	immutable this(immutable DedentOrSame a) { kind = Kind.dedentOrSame; dedentOrSame_ = a; }
	immutable this(immutable Indent a) { kind = Kind.indent; indent_ = a; }
}

@trusted T matchIndentDelta(T)(
	ref immutable IndentDelta a,
	scope T delegate(ref immutable IndentDelta.DedentOrSame) @safe @nogc pure nothrow cbDedentOrSame,
	scope T delegate(ref immutable IndentDelta.Indent) @safe @nogc pure nothrow cbIndent,
) {
	final switch (a.kind) {
		case IndentDelta.Kind.dedentOrSame:
			return cbDedentOrSame(a.dedentOrSame_);
		case IndentDelta.Kind.indent:
			return cbIndent(a.indent_);
	}
}

// Returns the change in indent (and updates the indent)
// Note: does nothing if not looking at a newline!
// NOTE: never returns a value > 1 as double-indent is always illegal.
immutable(IndentDelta) skipLinesAndGetIndentDelta(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	// comment / region counts as a blank line no matter its indent level.
	immutable uint newIndent = takeIndentAmount(alloc, lexer);

	if (tryTake(lexer, '\n'))
		return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
	else if (tryTake(lexer, "###\n")) {
		skipBlockComment(alloc, lexer);
		return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
	} else if (tryTake(lexer, '#')) {
		skipRestOfLineAndNewline(lexer);
		return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
	} else if (tryTake(lexer, "region ")) {
		skipRestOfLineAndNewline(lexer);
		return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
	} else {
		// If we got here, we're looking at a non-empty line (or EOF)
		immutable int delta = safeI32FromU32(newIndent) - safeI32FromU32(curIndent);
		if (delta > 1) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentTooMuch()));
			skipRestOfLineAndNewline(lexer);
			return skipLinesAndGetIndentDelta(alloc, lexer, curIndent);
		} else
			return delta == 1
				? immutable IndentDelta(immutable IndentDelta.Indent())
				: immutable IndentDelta(immutable IndentDelta.DedentOrSame(-delta));
	}
}

void skipBlockComment(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	skipRestOfLineAndNewline(lexer);
	drop(takeIndentAmount(alloc, lexer));
	if (!tryTake(lexer, "###\n"))
		skipBlockComment(alloc, lexer);
}

struct StrAndIsOperator {
	immutable string str;
	immutable Pos start;
	immutable Bool isOperator;
}

@trusted immutable(StrAndIsOperator) takeNameAsTempStr(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	immutable Pos start = curPos(lexer);
	if (isOperatorChar(*lexer.ptr)) {
		lexer.ptr++;
		immutable string op = takeOperatorRest(lexer, begin);
		return immutable StrAndIsOperator(op, start, True);
	} else if (isAlphaIdentifierStart(*lexer.ptr)) {
		lexer.ptr++;
		immutable string name = takeNameRest(lexer, begin);
		return immutable StrAndIsOperator(name, start, False);
	} else {
		while (*lexer.ptr != ' ' && *lexer.ptr != '\n')
			lexer.ptr++;
		// Copy since it's used in a diag
		immutable string s = copyStr(alloc, arrOfRange(begin, lexer.ptr));
		addDiag(alloc, lexer, range(lexer, begin), immutable ParseDiag(
			immutable ParseDiag.InvalidName(s)));
		return immutable StrAndIsOperator(strLiteral(""), start, False);
	}
}

public immutable(Bool) isReservedName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("alias"):
		case shortSymAlphaLiteralValue("builtin"):
		case shortSymAlphaLiteralValue("elif"):
		case shortSymAlphaLiteralValue("else"):
		case shortSymAlphaLiteralValue("export"):
		case shortSymAlphaLiteralValue("extern"):
		case shortSymAlphaLiteralValue("extern-ptr"):
		case shortSymAlphaLiteralValue("global"):
		case shortSymAlphaLiteralValue("if"):
		case shortSymAlphaLiteralValue("import"):
		case shortSymAlphaLiteralValue("match"):
		case shortSymAlphaLiteralValue("mut"):
		case shortSymAlphaLiteralValue("noctx"):
		case shortSymAlphaLiteralValue("record"):
		case shortSymAlphaLiteralValue("sendable"):
		case shortSymAlphaLiteralValue("spec"):
		case shortSymAlphaLiteralValue("summon"):
		case shortSymAlphaLiteralValue("trusted"):
		case shortSymAlphaLiteralValue("union"):
		case shortSymAlphaLiteralValue("unsafe"):
			return True;
		default:
			return False;
	}
}
