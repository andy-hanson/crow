module frontend.lexer;

import core.sys.posix.setjmp : jmp_buf, longjmp, setjmp;

alias PureSetJmp = extern(C) int function(ref jmp_buf) @safe @nogc pure nothrow;
immutable PureSetJmp pureSetjmp =
	cast(PureSetJmp) &setjmp;

alias PureLongJmp = extern(C) void function(ref jmp_buf, int) @safe @nogc pure nothrow;
immutable PureLongJmp pureLongjmp =
	cast(PureLongJmp) &longjmp;

@safe @nogc pure nothrow:

import frontend.ast : LiteralAst, NameAndRange;

import parseDiag : ParseDiag, ParseDiagnostic;

import util.alloc.alloc : nu;
import util.bools : Bool, False, True;
import util.collection.arr : arrOfRange, at, begin, empty, first, last, size;
import util.collection.arrUtil : slice;
import util.collection.str : copyStr, CStr, MutStr, NulTerminatedStr, Str, stripNulTerminator;
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
import util.util : todo;
import util.verify : unreachable;

enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer(SymAlloc) {
	private:
	Ptr!(AllSymbols!SymAlloc) allSymbols;
	immutable CStr sourceBegin;
	CStr ptr;
	immutable IndentKind indentKind;
	u32 indent;
	public:
	jmp_buf jump_buffer = void;
	// Assigned when an exception is thrown
	ParseDiagnostic diagnostic_ = void;

	//TODO:KILL
	void debugPrint() {
		debug {
			import core.stdc.stdio : printf;
			printf("Pos is: %lu\n", (ptr - sourceBegin + 1));
		}
	}
}

@trusted Lexer!SymAlloc createLexer(SymAlloc)(
	Ptr!(AllSymbols!SymAlloc) allSymbols,
	immutable NulTerminatedStr source,
) {
	// Note: We *are* relying on the nul terminator to stop the lexer.
	immutable Str str = source.stripNulTerminator;
	immutable u32 len = str.size.safeSizeTToU32;
	if (!str.empty && str.last != '\n') {
		immutable ParseDiagnostic p = ParseDiagnostic(
			SourceRange(len - 1, len),
			ParseDiag(ParseDiag.MustEndInBlankLine()));
		todo!void("createLexer");
	}
	return Lexer!SymAlloc(
		allSymbols,
		str.begin,
		str.begin,
		str.detectIndentKind,
		0);
}

immutable(char) curChar(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return *lexer.ptr;
}

immutable(Pos) curPos(SymAlloc)(ref const Lexer!SymAlloc lexer) {
	return safeSizeTToU32(lexer.ptr - lexer.sourceBegin);
}

T throwDiag(T, SymAlloc)(ref Lexer!SymAlloc lexer, immutable ParseDiagnostic pd) {
	initMemory(&lexer.diagnostic_, pd);
	pureLongjmp(lexer.jump_buffer, 1);
	return unreachable!T;
}

T throwDiag(T, SymAlloc)(ref Lexer!SymAlloc lexer, immutable SourceRange range, immutable ParseDiag diag) {
	return throwDiag!(T, SymAlloc)(lexer, ParseDiagnostic(range, diag));
}

T throwDiag(T, SymAlloc)(ref Lexer!SymAlloc lexer, immutable ParseDiag diag) {
	immutable Pos a = lexer.curPos;
	return lexer.throwDiag!(T, SymAlloc)(SourceRange(a, lexer.curChar == '\0' ? a : a + 1), diag);
}

T throwAtChar(T, SymAlloc)(ref Lexer!SymAlloc lexer, immutable ParseDiag diag) {
	immutable Pos a = lexer.curPos;
	immutable SourceRange range = SourceRange(a, lexer.curChar == '\0' ? a : a + 1);
	return throwDiag!(T, SymAlloc)(lexer, range, diag);
}

T throwUnexpected(T, SymAlloc)(ref Lexer!SymAlloc lexer) {
	return lexer.throwDiag!T(ParseDiag(ParseDiag.UnexpectedCharacter(lexer.curChar)));
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

void take(SymAlloc)(ref Lexer!SymAlloc lexer, immutable char c) {
	if (!lexer.tryTake(c))
		lexer.throwUnexpected!void;
}

void take(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr c) {
	if (!lexer.tryTake(c))
		lexer.throwUnexpected!void;
}

void skipShebang(SymAlloc)(ref Lexer!SymAlloc lexer) {
	if (lexer.tryTake("#!"))
		skipRestOfLine(lexer);
}

void skipBlankLines(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable int i = skipLinesAndGetIndentDelta(lexer);
	if (i != 0) lexer.throwUnexpected!void;
}

enum NewlineOrIndent {
	newline,
	indent,
}

immutable(Opt!NewlineOrIndent) tryTakeNewlineOrIndent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	if (lexer.tryTake('\n')) {
		immutable int delta = lexer.skipLinesAndGetIndentDelta();
		switch (delta) {
			case 0:
				return some(NewlineOrIndent.newline);
			case 1:
				return some(NewlineOrIndent.indent);
			default:
				return lexer.throwDiag!(Opt!NewlineOrIndent)(
					lexer.range(start),
					immutable ParseDiag(ParseDiag.UnexpectedDedent()));
		}
	} else
		return none!NewlineOrIndent;
}

immutable(NewlineOrIndent) takeNewlineOrIndent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable Opt!NewlineOrIndent op = lexer.tryTakeNewlineOrIndent;
	return op.has ? op.force : lexer.throwUnexpected!NewlineOrIndent;
}

void takeIndent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	lexer.take('\n');
	lexer.takeIndentAfterNewline();
}

void takeDedent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable int delta = lexer.skipLinesAndGetIndentDelta();
	if (delta != -1)
		lexer.throwAtChar!void(ParseDiag(ParseDiag.ExpectedDedent()));
}

immutable(Opt!int) tryTakeIndentOrDedent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	return lexer.curChar == '\n'
		? some!int(lexer.skipLinesAndGetIndentDelta())
		: none!int;
}

immutable(Bool) tryTakeIndent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable Bool res = Bool(lexer.curChar == '\n');
	if (res)
		lexer.takeIndent();
	return res;
}

NewlineOrIndent tryTakeIndentAfterNewline(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable int delta = skipLinesAndGetIndentDelta(lexer);
	switch (delta) {
		case 0:
			return NewlineOrIndent.newline;
		case 1:
			return NewlineOrIndent.indent;
		default:
			return todo!NewlineOrIndent("diagnostic");
	}
}

void takeIndentAfterNewline(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable int delta = skipLinesAndGetIndentDelta(lexer);
	if (delta != 1)
		throwAtChar!void(lexer, ParseDiag(ParseDiag.ExpectedIndent()));
}

immutable(size_t) takeNewlineOrDedentAmount(SymAlloc)(ref Lexer!SymAlloc lexer) {
	// Mut be at the end of a line
	lexer.take('\n');
	immutable int i = skipLinesAndGetIndentDelta(lexer);
	return i > 0
		? throwAtChar!size_t(lexer, ParseDiag(ParseDiag.UnexpectedIndent()))
		: -i;
}

enum NewlineOrDedent {
	newline,
	dedent,
}

immutable(NewlineOrDedent) takeNewlineOrSingleDedent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	assert(lexer.indent == 1);
	switch (lexer.takeNewlineOrDedentAmount()) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

immutable(SourceRange) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable Pos begin) {
	assert(begin < lexer.curPos);
	return SourceRange(begin, lexer.curPos);
}

immutable(T) throwOnReservedName(T, SymAlloc)(
	ref Lexer!SymAlloc lexer,
	immutable SourceRange range,
	immutable Sym name,
) {
	return lexer.throwDiag!T(range, ParseDiag(ParseDiag.ReservedName(name)));
}

struct SymAndIsReserved {
	immutable Sym sym;
	immutable SourceRange range;
	immutable Bool isReserved;
}

immutable(SymAndIsReserved) takeNameAllowReserved(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable StrAndIsOperator s = takeNameAsTempStr(lexer);
	if (s.isOperator) {
		immutable Sym op = getSymFromOperator(lexer.allSymbols.deref, s.str);
		return SymAndIsReserved(op, s.range, op.symEq(shortSymOperatorLiteral("=")));
	} else {
		immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, s.str);
		return SymAndIsReserved(name, s.range, name.isReservedName);
	}
}

immutable(Sym) takeName(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable SymAndIsReserved s = lexer.takeNameAllowReserved;
	return s.isReserved
		? lexer.throwOnReservedName!Sym(s.range, s.sym)
		: s.sym;
}

immutable(Str) takeNameAsStr(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	return copyStr(alloc, lexer.takeNameAsTempStr.str);
}

immutable(NameAndRange) takeNameAndRange(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	immutable Sym name = lexer.takeName;
	return immutable NameAndRange(range(lexer, begin), name);
}

immutable(Str) takeQuotedStr(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	lexer.take('"');
	return takeStringLiteralAfterQuote(lexer, alloc);
}

struct ExpressionToken {
	@safe @nogc pure nothrow:
	enum Kind {
		lambda,
		lbrace,
		literal,
		lparen,
		match,
		nameAndRange,
		new_,
		newArr,
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
		assert(kind != Kind.literal && kind != Kind.nameAndRange);
	}
	@trusted immutable this(immutable LiteralAst a) { kind_ = Kind.literal; literal_ = a; }
	@trusted immutable this(immutable NameAndRange a) { kind_ = Kind.nameAndRange; nameAndRange_ = a; }
}

@trusted ref immutable(LiteralAst) asLiteral(return scope ref immutable ExpressionToken a) {
	assert(a.kind_ == ExpressionToken.Kind.literal);
	return a.literal_;
}

immutable(Bool) isNameAndRange(ref immutable ExpressionToken a) {
	return Bool(a.kind_ == ExpressionToken.Kind.nameAndRange);
}

@trusted ref immutable(NameAndRange) asNameAndRange(return scope ref immutable ExpressionToken a) {
	assert(a.isNameAndRange);
	return a.nameAndRange_;
}

immutable(ExpressionToken) takeExpressionToken(Alloc, SymAlloc)(ref Lexer!SymAlloc lexer, ref Alloc alloc) {
	immutable CStr begin = lexer.ptr;
	immutable char c = lexer.next();
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
				? lexer.takeNumber(alloc, begin)
				: lexer.takeOperator(begin);
		default:
			if (isOperatorChar(c))
				return lexer.takeOperator(begin);
			else if (isAlphaIdentifierStart(c)) {
				immutable Str nameStr = takeNameRest(lexer, begin);
				immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, nameStr);
				immutable SourceRange nameRange = range(lexer, begin);
				if (name.isReservedName)
					switch (name.value) {
						case shortSymAlphaLiteralValue("match"):
							return immutable ExpressionToken(ExpressionToken.Kind.match);
						case shortSymAlphaLiteralValue("new"):
							return immutable ExpressionToken(ExpressionToken.Kind.new_);
						case shortSymAlphaLiteralValue("new-arr"):
							return immutable ExpressionToken(ExpressionToken.Kind.newArr);
						case shortSymAlphaLiteralValue("when"):
							return immutable ExpressionToken(ExpressionToken.Kind.when);
						default:
							return lexer.throwOnReservedName!ExpressionToken(nameRange, name);
					}
				else
					return immutable ExpressionToken(NameAndRange(nameRange, name));
			} else if (c.isDigit)
				return lexer.takeNumber(alloc, begin);
			else
				return lexer.throwUnexpected!ExpressionToken;
	}
}

immutable(Bool) tryTakeElseIndent(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable Bool res = lexer.tryTake("else\n");
	if (res)
		lexer.takeIndentAfterNewline();
	return res;
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

@trusted immutable(char) next(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable char res = *lexer.ptr;
	lexer.ptr++;
	return res;
}

immutable(SourceRange) range(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	assert(begin >= lexer.sourceBegin);
	return lexer.range(safeSizeTToU32(begin - lexer.sourceBegin));
}

@trusted immutable(ExpressionToken) takeNumber(Alloc, SymAlloc)(
	ref Lexer!SymAlloc lexer,
	ref Alloc alloc,
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
	immutable Str name = lexer.takeOperatorRest(begin);
	return ExpressionToken(NameAndRange(lexer.range(begin), lexer.allSymbols.getSymFromOperator(name)));
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
				switch (*lexer.ptr) {
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
						return lexer.throwUnexpected!char;
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
	assert(outI == size);
	return immutable Str(cast(immutable) res, size);
}

@trusted immutable(Str) takeNameRest(SymAlloc)(ref Lexer!SymAlloc lexer, immutable CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*lexer.ptr == '?')
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

@trusted void skipRestOfLine(SymAlloc)(ref Lexer!SymAlloc lexer) {
	while (*lexer.ptr != '\n')
		lexer.ptr++;
	lexer.ptr++;
}

@trusted u32 takeIndentAmount(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (*lexer.ptr == '\t') lexer.ptr++;
		if (*lexer.ptr == ' ')
			lexer.throwAtChar!(void, SymAlloc)(ParseDiag(ParseDiag.IndentWrongCharacter(True)));
		immutable u32 res = (lexer.ptr - begin).safeSizeTToU32;
		return res;
	} else {
		immutable Pos start = lexer.curPos;
		while (*lexer.ptr == ' ')
			lexer.ptr++;
		if (*lexer.ptr == '\t')
			lexer.throwAtChar!(void, SymAlloc)(ParseDiag(ParseDiag.IndentWrongCharacter(False)));
		immutable u32 nSpaces = (lexer.ptr - begin).safeSizeTToU32;
		immutable u32 nSpacesPerIndent = lexer.indentKind == IndentKind.spaces2 ? 2 : 4;
		immutable u32 res = nSpaces / nSpacesPerIndent;
		if (res * nSpacesPerIndent != nSpaces)
			lexer.throwDiag!(void, SymAlloc)(
				lexer.range(start),
				immutable ParseDiag(immutable ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
		return res;
	}
}

// Returns the change in indent (and updates the indent)
// Note: does nothing if not looking at a newline!
// NOTE: never returns a value > 1 as double-indent is always illegal.
i32 skipLinesAndGetIndentDelta(SymAlloc)(ref Lexer!SymAlloc lexer) {
	// comment / region counts as a blank line no matter its indent level.
	immutable u32 newIndent = takeIndentAmount(lexer);

	if (tryTake(lexer, '\n'))
		return skipLinesAndGetIndentDelta(lexer);
	else if (lexer.tryTake('|')) {
		lexer.skipRestOfLine();
		return lexer.skipLinesAndGetIndentDelta();
	} else if (lexer.tryTake("region ")) {
		lexer.skipRestOfLine();
		return lexer.skipLinesAndGetIndentDelta();
	} else {
		// If we got here, we're looking at a non-empty line (or EOF)
		immutable i32 res = safeI32FromU32(newIndent) - safeI32FromU32(lexer.indent);
		if (res > 1)
			todo!void("too much indent");
		lexer.indent = newIndent;
		return res;
	}
}

struct StrAndIsOperator {
	immutable Str str;
	immutable SourceRange range;
	immutable Bool isOperator;
}

@trusted immutable(StrAndIsOperator) takeNameAsTempStr(SymAlloc)(ref Lexer!SymAlloc lexer) {
	immutable CStr begin = lexer.ptr;
	if (isOperatorChar(*lexer.ptr)) {
		lexer.ptr++;
		immutable Str op = takeOperatorRest(lexer, begin);
		return StrAndIsOperator(op, lexer.range(begin), True);
	} else if (isAlphaIdentifierStart(*lexer.ptr)) {
		lexer.ptr++;
		immutable Str name = takeNameRest(lexer, begin);
		return StrAndIsOperator(name, lexer.range(begin), False);
	} else
		return lexer.throwUnexpected!StrAndIsOperator;
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
