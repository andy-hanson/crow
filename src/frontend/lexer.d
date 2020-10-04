module frontend.lexer;

@safe @nogc pure nothrow:

import frontend.ast : LiteralAst, NameAndRange, rangeOfNameAndRange;

import parseDiag : ParseDiag, ParseDiagnostic;

import util.alloc.alloc : nu;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, arrOfRange, at, begin, empty, first, last, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : cat, rtail, slice;
import util.collection.str : copyStr, CStr, emptyStr, MutStr, NulTerminatedStr, Str, stripNulTerminator,  strLiteral;
import util.memory : initMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.result : fail, Result, success;
import util.sourceRange : Pos, SourceRange;
import util.sym :
	AllSymbols,
	getSymFromAlphaIdentifier,
	getSymFromOperator,
	isAlphaIdentifierStart,
	isAlphaIdentifierContinue,
	isDigit,
	isOperatorChar,
	shortSymAlphaLiteralValue,
	shortSymOperatorLiteral,
	Sym,
	symEq;
import util.types : i32, u32, Void, safeI32FromU32, safeSizeTToU32;
import util.util : todo, unreachable, verify;

enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer(SymAlloc) {
	private:
	Ptr!(AllSymbols!SymAlloc) allSymbols;
	ArrBuilder!ParseDiagnostic diags;
	immutable CStr sourceBegin;
	CStr ptr;
	immutable IndentKind indentKind;
	u32 indent;
}

@trusted Lexer!SymAlloc createLexer(Alloc, SymAlloc)(
	ref Alloc alloc,
	Ptr!(AllSymbols!SymAlloc) allSymbols,
	immutable NulTerminatedStr source,
) {
	// Note: We *are* relying on the nul terminator to stop the lexer.
	immutable Str str = source.stripNulTerminator;
	immutable Bool endsInBlankLine = last(str) == '\n';
	immutable Str useStr = endsInBlankLine ? str : rtail(cat!char(alloc, str, strLiteral("\n\0")));
	immutable u32 len = str.size.safeSizeTToU32;
	Lexer!SymAlloc lexer = Lexer!SymAlloc(
		allSymbols,
		ArrBuilder!ParseDiagnostic(),
		begin(useStr),
		begin(useStr),
		detectIndentKind(useStr),
		0);
	if (!endsInBlankLine)
		addDiag(alloc, lexer, immutable SourceRange(len - 1, len), immutable ParseDiag(
			immutable ParseDiag.MustEndInBlankLine()));
	return lexer;
}

immutable(char) curChar(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return *lexer.ptr;
}

immutable(Pos) curPos(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return posOfPtr(lexer, lexer.ptr);
}

immutable(Pos) posOfPtr(SymAlloc)(ref const Lexer!SymAlloc lexer, immutable CStr ptr) {
	return safeSizeTToU32(ptr - lexer.sourceBegin);
}

void addDiag(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable SourceRange range,
	immutable ParseDiag diag,
) {
	add(alloc, lexer.diags, immutable ParseDiagnostic(range, diag));
}

immutable(Arr!ParseDiagnostic) finishDiags(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return finishArr(alloc, lexer.diags);
}

void addDiagAtChar(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer, immutable ParseDiag diag) {
	immutable Pos a = lexer.curPos;
	addDiag(alloc, lexer, immutable SourceRange(a, lexer.curChar == '\0' ? a : a + 1), diag);
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

void takeOrAddDiag(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer, immutable char c) {
	if (!tryTake(lexer, c))
		addDiagUnexpected(alloc, lexer);
}

void skipShebang(SymAlloc)(ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, "#!"))
		skipRestOfLineAndNewline(lexer);
}

//TODO: this is only called at base level, so dedenting should be impossible..
void skipBlankLines(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	verify(lexer.indent == 0);
	immutable IndentDelta i = skipLinesAndGetIndentDelta(alloc, lexer);
	matchIndentDelta(
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
	verify(lexer.indent == 0);
	if (!takeOrAddDiagExpected(alloc, lexer, '\n', ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer);
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
	verify(lexer.indent == 0);
	return takeIndentOrFailGeneric!(immutable Bool)(
		alloc,
		lexer,
		() => True,
		(immutable SourceRange, immutable size_t dedent) {
			verify(dedent == 0);
			return False;
		});
}

immutable(Bool) takeIndentOrDiagTopLevelAfterNewline(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	verify(lexer.indent == 0);
	immutable Pos start = curPos(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer);
	return matchIndentDelta!(immutable Bool)(
		delta,
		(ref immutable IndentDelta.DedentOrSame dedent) {
			verify(dedent.nDedents == 0);
			addDiag(
				alloc,
				lexer,
				immutable SourceRange(start, start + 1),
				immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return False;
		},
		(ref immutable IndentDelta.Indent) => True);
}

immutable(T) takeIndentOrFailGeneric(T, Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	scope immutable(T) delegate() @safe @nogc pure nothrow cbIndent,
	scope immutable(T) delegate(immutable SourceRange, immutable size_t) @safe @nogc pure nothrow cbFail,
) {
	immutable Pos start = curPos(lexer);
	immutable IndentDelta delta = takeNewlineAndReturnIndentDelta(alloc, lexer);
	return matchIndentDelta!(immutable T)(
		delta,
		(ref immutable IndentDelta.DedentOrSame dedent) {
			addDiag(
				alloc,
				lexer,
				immutable SourceRange(start, start + 1),
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
) {
	if (*lexer.ptr != '\n') {
		//TODO: not always expecting indent..
		addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipUntilNewlineNoDiag(lexer);
	}
	verify(*lexer.ptr == '\n');
	lexer.ptr++;
	return skipLinesAndGetIndentDelta(alloc, lexer);
}

private void skipToFirstNonIndentedLine(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	verify(lexer.indent == 1);
	immutable IndentDelta delta = skiplinesAndGetIndentDelta(alloc, lexer);

}

void takeDedentFromIndent1(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	verify(lexer.indent == 1);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer);
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

immutable(Opt!IndentDelta) tryTakeIndentOrDedent(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return curChar(lexer) == '\n'
		? some!IndentDelta(skipLinesAndGetIndentDelta(alloc, lexer))
		: none!IndentDelta;
}

immutable(NewlineOrIndent) tryTakeIndentAfterNewline_topLevel(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	verify(lexer.indent == 0);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer);
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

immutable(size_t) takeNewlineOrDedentAmount(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	// Must be at the end of a line
	if (!takeOrAddDiagExpected(alloc, lexer, '\n', ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipLinesAndGetIndentDelta(alloc, lexer);
	return matchIndentDelta!(immutable size_t)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) {
			return it.nDedents;
		},
		(ref immutable IndentDelta.Indent) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipUntilNewlineNoDiag(lexer);
			return takeNewlineOrDedentAmount(alloc, lexer);
		});
}

enum NewlineOrDedent {
	newline,
	dedent,
}

immutable(NewlineOrDedent) takeNewlineOrSingleDedent(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	verify(lexer.indent == 1);
	switch (takeNewlineOrDedentAmount(alloc, lexer)) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

immutable(SourceRange) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable Pos begin) {
	verify(begin <= lexer.curPos);
	return SourceRange(begin, lexer.curPos);
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
		immutable Sym op = getSymFromOperator(lexer.allSymbols.deref, s.str);
		return immutable SymAndIsReserved(immutable NameAndRange(s.start, op), op.symEq(shortSymOperatorLiteral("=")));
	} else {
		immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, s.str);
		return immutable SymAndIsReserved(immutable NameAndRange(s.start, name), name.isReservedName);
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

immutable(Str) takeNameAsStr(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	return copyStr(alloc, takeNameAsTempStr(lexer, str));
}

immutable(Str) takeQuotedStr(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	return takeOrAddDiagExpected(alloc, lexer, '"', ParseDiag.Expected.Kind.quote)
		? takeStringLiteralAfterQuote(lexer, alloc)
		: emptyStr;
}

struct ExpressionToken {
	@safe @nogc pure nothrow:
	enum Kind {
		else_,
		lambda,
		lbrace,
		literal,
		lparen,
		match,
		nameAndRange,
		new_,
		newArr,
		unexpected,
		when,
	}
	immutable Kind kind_;
	union {
		bool none_;
		immutable LiteralAst literal_;
		immutable NameAndRange nameAndRange_;
	}
	@trusted immutable this(immutable Kind kind) {
		none_ = true;
		kind_ = kind;
		verify(kind != Kind.literal && kind != Kind.nameAndRange);
	}
	@trusted immutable this(immutable LiteralAst a) { kind_ = Kind.literal; literal_ = a; }
	@trusted immutable this(immutable NameAndRange a) { kind_ = Kind.nameAndRange; nameAndRange_ = a; }
}

@trusted ref immutable(LiteralAst) asLiteral(return scope ref immutable ExpressionToken a) {
	verify(a.kind_ == ExpressionToken.Kind.literal);
	return a.literal_;
}

immutable(Bool) isNameAndRange(ref immutable ExpressionToken a) {
	return Bool(a.kind_ == ExpressionToken.Kind.nameAndRange);
}

@trusted ref immutable(NameAndRange) asNameAndRange(return scope ref immutable ExpressionToken a) {
	verify(a.isNameAndRange);
	return a.nameAndRange_;
}

immutable(ExpressionToken) takeExpressionToken(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	immutable Pos start = curPos(lexer);
	immutable char c = next(lexer);
	switch (c) {
		case '(':
			return immutable ExpressionToken(ExpressionToken.Kind.lparen);
		case '{':
			return immutable ExpressionToken(ExpressionToken.Kind.lbrace);
		case '\\':
			return immutable ExpressionToken(ExpressionToken.Kind.lambda);
		case '"':
			return immutable ExpressionToken(
				immutable LiteralAst(LiteralAst.Kind.string_, takeStringLiteralAfterQuote(lexer, alloc)));
		case '+':
		case '-':
			return isDigit(*lexer.ptr)
				? takeNumber(alloc, lexer, begin)
				: takeOperator(lexer, begin);
		default:
			if (isOperatorChar(c))
				return takeOperator(lexer, begin);
			else if (isAlphaIdentifierStart(c)) {
				immutable Str nameStr = takeNameRest(lexer, begin);
				immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, nameStr);
				if (name.isReservedName)
					switch (name.value) {
						case shortSymAlphaLiteralValue("else"):
							return immutable ExpressionToken(ExpressionToken.Kind.else_);
						case shortSymAlphaLiteralValue("match"):
							return immutable ExpressionToken(ExpressionToken.Kind.match);
						case shortSymAlphaLiteralValue("new"):
							return immutable ExpressionToken(ExpressionToken.Kind.new_);
						case shortSymAlphaLiteralValue("new-arr"):
							return immutable ExpressionToken(ExpressionToken.Kind.newArr);
						case shortSymAlphaLiteralValue("when"):
							return immutable ExpressionToken(ExpressionToken.Kind.when);
						default:
							addDiagOnReservedName(alloc, lexer, immutable NameAndRange(start, name));
							return immutable ExpressionToken(ExpressionToken.Kind.unexpected);
					}
				else
					return immutable ExpressionToken(immutable NameAndRange(start, name));
			} else if (isDigit(c))
				return takeNumber(alloc, lexer, begin);
			else {
				backUp(lexer);
				addDiagUnexpected(alloc, lexer);
				return immutable ExpressionToken(ExpressionToken.Kind.unexpected);
			}
	}
}

@trusted void skipUntilNewlineNoDiag(SymAlloc)(ref Lexer!SymAlloc lexer) {
	while (*lexer.ptr != '\n')
		lexer.ptr++;
}

@trusted void skipRestOfLineAndNewline(SymAlloc)(ref Lexer!SymAlloc lexer) {
	skipUntilNewlineNoDiag(lexer);
	lexer.ptr++;
}

private:

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
IndentKind detectIndentKind(immutable Str str) {
	if (str.empty)
		// No indented lines, so it's irrelevant
		return IndentKind.tabs;
	else {
		immutable char c0 = str.first;
		if (c0 == '\t')
			return IndentKind.tabs;
		else if (c0 == ' ') {
			// Count spaces
			size_t i = 0;
			for (; i < str.size; i++)
				if (str.at(i) != ' ')
					break;
			// Only allowed amounts are 2 and 4.
			return i == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
		} else {
			foreach (immutable size_t i; 0..str.size)
				if (str.at(i) == '\n')
					return detectIndentKind(str.slice(i + 1));
			return IndentKind.tabs;
		}
	}
}

@trusted void backUp(SymAlloc)(ref Lexer!SymAlloc lexer) {
	lexer.ptr--;
}

@trusted immutable(char) next(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable char res = *lexer.ptr;
	lexer.ptr++;
	return res;
}

immutable(SourceRange) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeSizeTToU32(begin - lexer.sourceBegin));
}

@trusted immutable(ExpressionToken) takeNumber(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable CStr begin,
) {
	while ((*lexer.ptr).isDigit || *lexer.ptr == '.') lexer.ptr++;
	immutable Str text = copyStr(alloc, arrOfRange(begin, lexer.ptr));
	return immutable ExpressionToken(immutable LiteralAst(LiteralAst.Kind.numeric, text));
}

@trusted immutable(Str) takeOperatorRest(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	while (isOperatorChar(*lexer.ptr))
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

immutable(ExpressionToken) takeOperator(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	immutable Str name = takeOperatorRest(lexer, begin);
	return immutable ExpressionToken(
		immutable NameAndRange(posOfPtr(lexer, begin),
		getSymFromOperator(lexer.allSymbols, name)));
}

immutable(size_t) toHexDigit(immutable char c) {
	if ('0' <= c && c <= '9')
		return c - '0';
	else if ('a' <= c && c <= 'f')
		return 10 + c - 'a';
	else
		return todo!size_t("parse diagnostic -- bad hex digit");
}

@trusted immutable(Str) takeStringLiteralAfterQuote(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
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
	char* res = cast(char*) alloc.allocate(char.sizeof * size);

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
						immutable size_t na = a.toHexDigit;
						immutable size_t nb = b.toHexDigit;
						return cast(char) (na * 16 + nb);
					case '"':
						return '"';
					case 'n':
						return '\n';
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
	return immutable Str(cast(immutable) res, size);
}

@trusted immutable(Str) takeNameRest(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*lexer.ptr == '?')
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

// Called after the newline
@trusted u32 takeIndentAmount(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (*lexer.ptr == '\t') lexer.ptr++;
		if (*lexer.ptr == ' ')
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(True)));
		immutable u32 res = (lexer.ptr - begin).safeSizeTToU32;
		return res;
	} else {
		immutable Pos start = curPos(lexer);
		while (*lexer.ptr == ' ')
			lexer.ptr++;
		if (*lexer.ptr == '\t')
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(False)));
		immutable u32 nSpaces = (lexer.ptr - begin).safeSizeTToU32;
		immutable u32 nSpacesPerIndent = lexer.indentKind == IndentKind.spaces2 ? 2 : 4;
		immutable u32 res = nSpaces / nSpacesPerIndent;
		if (res * nSpacesPerIndent != nSpaces)
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
		return res;
	}
}

public struct IndentDelta {
	@safe @nogc pure nothrow:

	struct DedentOrSame {
		immutable size_t nDedents;
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

public @trusted T matchIndentDelta(T)(
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
immutable(IndentDelta) skipLinesAndGetIndentDelta(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	// comment / region counts as a blank line no matter its indent level.
	immutable u32 newIndent = takeIndentAmount(alloc, lexer);

	if (tryTake(lexer, '\n'))
		return skipLinesAndGetIndentDelta(alloc, lexer);
	else if (tryTake(lexer, '|')) {
		skipRestOfLineAndNewline(lexer);
		return skipLinesAndGetIndentDelta(alloc, lexer);
	} else if (tryTake(lexer, "region ")) {
		skipRestOfLineAndNewline(lexer);
		return skipLinesAndGetIndentDelta(alloc, lexer);
	} else {
		// If we got here, we're looking at a non-empty line (or EOF)
		immutable i32 delta = safeI32FromU32(newIndent) - safeI32FromU32(lexer.indent);
		if (delta > 1) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(immutable ParseDiag.IndentTooMuch()));
			skipRestOfLineAndNewline(lexer);
			return skipLinesAndGetIndentDelta(alloc, lexer);
		} else {
			lexer.indent = newIndent;
			return delta == 1
				? immutable IndentDelta(immutable IndentDelta.Indent())
				: immutable IndentDelta(immutable IndentDelta.DedentOrSame(-delta));
		}
	}
}

struct StrAndIsOperator {
	immutable Str str;
	immutable Pos start;
	immutable Bool isOperator;
}

@trusted immutable(StrAndIsOperator) takeNameAsTempStr(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	immutable Pos start = curPos(lexer);
	if (isOperatorChar(*lexer.ptr)) {
		lexer.ptr++;
		immutable Str op = takeOperatorRest(lexer, begin);
		return immutable StrAndIsOperator(op, start, True);
	} else if (isAlphaIdentifierStart(*lexer.ptr)) {
		lexer.ptr++;
		immutable Str name = takeNameRest(lexer, begin);
		return immutable StrAndIsOperator(name, start, False);
	} else {
		while (*lexer.ptr != ' ' && *lexer.ptr != '\n')
			lexer.ptr++;
		// Copy since it's used in a diag
		immutable Str s = copyStr(alloc, arrOfRange(begin, lexer.ptr));
		addDiag(alloc, lexer, range(lexer, begin), immutable ParseDiag(
			immutable ParseDiag.InvalidName(s)));
		return immutable StrAndIsOperator(strLiteral("bogus"), start, False);
	}
}

immutable(Bool) isReservedName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("alias"):
		case shortSymAlphaLiteralValue("builtin"):
		case shortSymAlphaLiteralValue("else"):
		case shortSymAlphaLiteralValue("export"):
		case shortSymAlphaLiteralValue("extern"):
		case shortSymAlphaLiteralValue("extern-ptr"):
		case shortSymAlphaLiteralValue("global"):
		case shortSymAlphaLiteralValue("import"):
		case shortSymAlphaLiteralValue("match"):
		case shortSymAlphaLiteralValue("mut"):
		case shortSymAlphaLiteralValue("new"):
		case shortSymAlphaLiteralValue("new-actor"):
		case shortSymAlphaLiteralValue("new-arr"):
		case shortSymAlphaLiteralValue("noctx"):
		case shortSymAlphaLiteralValue("record"):
		case shortSymAlphaLiteralValue("sendable"):
		case shortSymAlphaLiteralValue("spec"):
		case shortSymAlphaLiteralValue("summon"):
		case shortSymAlphaLiteralValue("trusted"):
		case shortSymAlphaLiteralValue("union"):
		case shortSymAlphaLiteralValue("unsafe"):
		case shortSymAlphaLiteralValue("when"):
			return True;
		default:
			return False;
	}
}
