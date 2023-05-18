module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralFloatAst, LiteralIntAst, LiteralNatAst, NameAndRange;
import frontend.parse.lexToken :
	lexToken,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeQuestionEquals,
	lookaheadWillTakeArrowAfterParenLeft,
	takeStringPart,
	TokenData;
import frontend.parse.lexWhitespace :
	detectIndentKind,
	IndentDelta,
	IndentKind,
	skipBlankLinesAndGetDocComment,
	skipBlankLinesAndGetIndentDelta,
	skipRestOfLineAndNewline,
	skipUntilNewline,
	skipWhitespaceWithinLine,
	takeNewlineAndReturnIndentDelta;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : cellGet;
import util.col.arrBuilder : add, ArrBuilder;
import util.col.arrUtil : contains;
import util.col.str : copyToSafeCStr, CStr, SafeCStr;
import util.conv : safeToUint;
import util.opt : Opt;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : verify;

public import frontend.parse.lexToken : EqualsOrThen, QuoteKind, StringPart, Token;

struct Lexer {
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	ArrBuilder!DiagnosticWithinFile* diagnosticsBuilderPtr;
	immutable CStr sourceBegin;
	immutable IndentKind indentKind;

	// Lexer state:
	uint curIndent;
	immutable(char)* ptr;
	TokenData curTokenData = void;
}

ref Alloc alloc(return ref Lexer lexer) =>
	*lexer.allocPtr;

ref AllSymbols allSymbols(return ref Lexer lexer) =>
	*lexer.allSymbolsPtr;

@trusted Lexer createLexer(
	Alloc* alloc,
	AllSymbols* allSymbols,
	ArrBuilder!DiagnosticWithinFile* diagnosticsBuilder,
	SafeCStr source,
) =>
	Lexer(alloc, allSymbols, diagnosticsBuilder, source.ptr, detectIndentKind(source), 0, source.ptr);

@trusted Pos curPos(scope ref Lexer lexer) {
	skipWhitespaceWithinLine(lexer.ptr);
	return safeToUint(lexer.ptr - lexer.sourceBegin);
}

void addDiag(ref Lexer lexer, RangeWithinFile range, ParseDiag diag) {
	add(lexer.alloc, *lexer.diagnosticsBuilderPtr, DiagnosticWithinFile(range, Diag(diag)));
}

void addDiagAtChar(ref Lexer lexer, ParseDiag diag) {
	addDiag(lexer, rangeAtChar(lexer), diag);
}

RangeWithinFile rangeAtChar(scope ref Lexer lexer) {
	Pos pos = curPos(lexer);
	Pos nextPos = () @trusted {
		switch (*lexer.ptr) {
			case '\0':
				return pos;
			case '\r':
				// Treat "\r\n" as one character
				return *(lexer.ptr + 1) == '\n' ? pos + 2 : pos + 1;
			default:
				return pos + 1;
		}
	}();
	return RangeWithinFile(pos, nextPos);
}

void addDiagUnexpectedCurToken(ref Lexer lexer, Pos start, Token token) {
	ParseDiag diag = () @trusted {
		switch (token) {
			case Token.invalid:
				return ParseDiag(ParseDiag.UnexpectedCharacter(*(lexer.ptr - 1)));
			case Token.operator:
				return ParseDiag(ParseDiag.UnexpectedOperator(getCurSym(lexer)));
			default:
				return ParseDiag(ParseDiag.UnexpectedToken(token));
		}
	}();
	addDiag(lexer, range(lexer, start), diag);
}

RangeWithinFile range(ref Lexer lexer, Pos begin) {
	verify(begin <= curPos(lexer));
	return RangeWithinFile(begin, curPos(lexer));
}

public void skipRestOfLineAndNewline(ref Lexer lexer) =>
	.skipRestOfLineAndNewline(lexer.ptr);

void skipUntilNewlineNoDiag(ref Lexer lexer) {
	skipUntilNewline(lexer.ptr);
}

Token nextToken(ref Lexer lexer) =>
	lexToken(lexer.ptr, lexer.curTokenData, lexer.allSymbols);

private:

public Sym getCurSym(ref Lexer lexer) =>
	//TODO: assert that cur token is Token.name or Token.operator
	cellGet(lexer.curTokenData.sym);

public NameAndRange getCurNameAndRange(ref Lexer lexer, Pos start) =>
	immutable NameAndRange(start, getCurSym(lexer));

public LiteralFloatAst getCurLiteralFloat(ref Lexer lexer) =>
	cellGet(lexer.curTokenData.literalFloat);

public LiteralIntAst getCurLiteralInt(ref Lexer lexer) =>
	cellGet(lexer.curTokenData.literalInt);

public LiteralNatAst getCurLiteralNat(ref Lexer lexer) =>
	cellGet(lexer.curTokenData.literalNat);

public bool tryTakeToken(ref Lexer lexer, Token expected) =>
	tryTakeToken(lexer, [expected]);
bool tryTakeToken(ref Lexer lexer, in Token[] expected) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	Token actual = nextToken(lexer);
	if (contains(expected, actual))
		return true;
	else {
		lexer.ptr = before;
		return false;
	}
}

public bool tryTakeOperator(ref Lexer lexer, Sym expected) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	Token actual = nextToken(lexer);
	if (actual == Token.operator && getCurSym(lexer) == expected)
		return true;
	else {
		lexer.ptr = before;
		return false;
	}
}

public Token getPeekToken(ref Lexer lexer) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	Token res = nextToken(lexer);
	lexer.ptr = before;
	return res;
}

public bool peekToken(ref Lexer lexer, Token expected) =>
	getPeekToken(lexer) == expected;

RangeWithinFile range(ref Lexer lexer, CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeToUint(begin - lexer.sourceBegin));
}

public @trusted StringPart takeStringPart(ref Lexer lexer, QuoteKind quoteKind) =>
	.takeStringPart(lexer.alloc, lexer.ptr, quoteKind, (ParseDiag x) => addDiagAtChar(lexer, x));

public SafeCStr skipBlankLinesAndGetDocComment(ref Lexer lexer) =>
	copyToSafeCStr(lexer.alloc, .skipBlankLinesAndGetDocComment(lexer.ptr, (ParseDiag x) => addDiagAtChar(lexer, x)));

// Returns the change in indent (and updates the indent)
// Note: does nothing if not looking at a newline!
// NOTE: never returns a value > 1 as double-indent is always illegal.
public IndentDelta skipBlankLinesAndGetIndentDelta(ref Lexer lexer) =>
	.skipBlankLinesAndGetIndentDelta(lexer.ptr, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
		addDiagAtChar(lexer, x));

public IndentDelta takeNewlineAndReturnIndentDelta(ref Lexer lexer) =>
	.takeNewlineAndReturnIndentDelta(lexer.ptr, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
		addDiagAtChar(lexer, x));

public @trusted Opt!EqualsOrThen lookaheadWillTakeEqualsOrThen(ref Lexer lexer) =>
	.lookaheadWillTakeEqualsOrThen(lexer.ptr);

public @trusted bool lookaheadWillTakeQuestionEquals(ref Lexer lexer) =>
	.lookaheadWillTakeQuestionEquals(lexer.ptr);

public bool lookaheadWillTakeArrowAfterParenLeft(in Lexer lexer) =>
	.lookaheadWillTakeArrowAfterParenLeft(lexer.ptr);
