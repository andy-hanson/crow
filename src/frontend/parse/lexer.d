module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralFloatAst, LiteralIntAst, LiteralNatAst, NameAndRange;
import frontend.parse.lexToken :
	lexInitialToken,
	lexToken,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeQuestionEquals,
	lookaheadWillTakeArrowAfterParenLeft,
	moveTokenData,
	takeStringPart,
	TokenData;
import frontend.parse.lexWhitespace :
	detectIndentKind, IndentDelta, IndentKind, skipSpacesAndComments, skipUntilNewline;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : cellGet;
import util.col.arrBuilder : add, ArrBuilder;
import util.col.str : copyToSafeCStr, CStr, SafeCStr;
import util.conv : safeToUint;
import util.opt : Opt, some;
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
	// Indent at 'ptr'
	uint curIndent; // This is the indent after 'nextToken'.
	immutable(char)* ptr; // This is after 'nextToken'.
	// This is the 'peek'
	Token prevToken = void;
	TokenData prevTokenData = void;
	Pos nextTokenPos = void; // Position at start of 'nextToken'
	Token nextToken = void;
	TokenData nextTokenData = void;
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
) {
	Lexer lexer = Lexer(alloc, allSymbols, diagnosticsBuilder, source.ptr, detectIndentKind(source), 0, source.ptr);
	lexer.nextToken = lexInitialToken(
		lexer.ptr, lexer.nextTokenData, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
			addDiagAtChar(lexer, x));
	return lexer;
}

Pos curPos(scope ref Lexer lexer) =>
	lexer.nextTokenPos;

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

public void skipRestOfLineAndNewline(ref Lexer lexer) {
	skipUntilNewlineNoDiag(lexer);
	Token token = takeNextToken(lexer); // This prepares the next token and returns the newline
	verify(isNewline(token));
}

void skipUntilNewlineNoDiag(ref Lexer lexer) {
	if (!isNewline(lexer.nextToken)) {
		skipUntilNewline(lexer.ptr);
		takeNextToken(lexer);
		verify(isNewline(lexer.nextToken));
	}
}

Token takeNextToken(ref Lexer lexer) {
	lexer.prevToken = lexer.nextToken;
	moveTokenData(lexer.nextToken, lexer.prevTokenData, lexer.nextTokenData);
	if (isQuote(lexer.prevToken)) {
		lexer.nextToken = Token.quotedText;
	} else {
		skipSpacesAndComments(lexer.ptr);
		lexer.nextTokenPos = safeToUint(lexer.ptr - lexer.sourceBegin);
		lexer.nextToken = lexToken(
			lexer.ptr, lexer.nextTokenData, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
				addDiagAtChar(lexer, x));
	}
	return lexer.prevToken;
}

private:

bool isNewline(Token a) =>
	a == Token.newline || a == Token.EOF;
bool isQuote(Token a) =>
	a == Token.quoteDouble || a == Token.quoteDouble3;

public Sym getCurSym(ref Lexer lexer) {
	verify(isSymToken(lexer.prevToken));
	return cellGet(lexer.prevTokenData.sym);
}

public Sym getPeekSym(ref Lexer lexer) {
	verify(isSymToken(lexer.nextToken));
	return cellGet(lexer.nextTokenData.sym);
}

bool isSymToken(Token a) =>
	a == Token.name || a == Token.operator;

public @trusted SafeCStr getCurDocComment(ref Lexer lexer) {
	verify(isNewline(lexer.prevToken));
	return copyToSafeCStr(lexer.alloc, cellGet(lexer.prevTokenData.indentDelta).docComment);
}

public @trusted IndentDelta getCurIndentDelta(ref Lexer lexer) {
	verify(isNewline(lexer.prevToken));
	return cellGet(lexer.prevTokenData.indentDelta).indentDelta;
}

public NameAndRange getCurNameAndRange(ref Lexer lexer, Pos start) =>
	immutable NameAndRange(start, getCurSym(lexer));

public LiteralFloatAst getCurLiteralFloat(ref Lexer lexer) {
	verify(lexer.prevToken == Token.literalFloat);
	return cellGet(lexer.prevTokenData.literalFloat);
}

public LiteralIntAst getCurLiteralInt(ref Lexer lexer) {
	verify(lexer.prevToken == Token.literalInt);
	return cellGet(lexer.prevTokenData.literalInt);
}

public LiteralNatAst getCurLiteralNat(ref Lexer lexer) {
	verify(lexer.prevToken == Token.literalNat);
	return cellGet(lexer.prevTokenData.literalNat);
}

public Token getPeekToken(ref Lexer lexer) =>
	lexer.nextToken;

RangeWithinFile range(ref Lexer lexer, CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeToUint(begin - lexer.sourceBegin));
}

public StringPart takeClosingBraceThenStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	if (lexer.nextToken != Token.braceRight)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.closeInterpolated)));
	return takeStringPartCommon(lexer, quoteKind);
}

public StringPart takeInitialStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	verify(lexer.nextToken == Token.quotedText);
	return takeStringPartCommon(lexer, quoteKind);
}

StringPart takeStringPartCommon(ref Lexer lexer, QuoteKind quoteKind) {
	StringPart res = takeStringPart(lexer.alloc, lexer.ptr, quoteKind, (ParseDiag x) => addDiagAtChar(lexer, x));
	takeNextToken(lexer);
	return res;
}

public @trusted Opt!EqualsOrThen lookaheadWillTakeEqualsOrThen(ref Lexer lexer) {
	switch (lexer.nextToken) {
		case Token.equal:
			return some(EqualsOrThen.equals);
		case Token.arrowThen:
			return some(EqualsOrThen.then);
		default:
			return .lookaheadWillTakeEqualsOrThen(lexer.ptr);
	}
}

public @trusted bool lookaheadWillTakeQuestionEquals(ref Lexer lexer) =>
	lexer.nextToken == Token.questionEqual || .lookaheadWillTakeQuestionEquals(lexer.ptr);

public bool lookaheadWillTakeLambda(in Lexer lexer) =>
	lexer.nextToken == Token.parenLeft && .lookaheadWillTakeArrowAfterParenLeft(lexer.ptr);
