module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.lexToken :
	isNewlineToken,
	isQuoteToken,
	lexInitialToken,
	lexToken,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeQuestionEquals,
	lookaheadWillTakeArrowAfterParenLeft,
	plainToken,
	takeStringPart;
import frontend.parse.lexWhitespace : detectIndentKind, IndentKind, skipSpacesAndComments, skipUntilNewline;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arrBuilder : add, ArrBuilder;
import util.col.str : CStr, SafeCStr;
import util.conv : safeToUint;
import util.opt : Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols;
import util.util : verify;

public import frontend.parse.lexToken : EqualsOrThen, QuoteKind, StringPart, Token, TokenAndData;
public import frontend.parse.lexWhitespace : IndentDelta;

struct Lexer {
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	ArrBuilder!DiagnosticWithinFile* diagnosticsBuilderPtr;
	immutable CStr sourceBegin;
	immutable IndentKind indentKind;

	// Lexer state:
	// This is the indent at 'ptr', after 'nextToken'.
	uint curIndent;
	// This is after 'nextToken'.
	immutable(char)* ptr;
	// Position at start of 'nextToken'.
	Pos nextTokenPos = void;
	Cell!TokenAndData nextToken = void;
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
	cellSet(lexer.nextToken,
		lexInitialToken(lexer.ptr, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
			addDiagAtChar(lexer, x)));
	return lexer;
}

Pos curPos(in Lexer lexer) =>
	lexer.nextTokenPos;

void addDiag(ref Lexer lexer, RangeWithinFile range, ParseDiag diag) {
	add(lexer.alloc, *lexer.diagnosticsBuilderPtr, DiagnosticWithinFile(range, Diag(diag)));
}

void addDiagAtChar(ref Lexer lexer, ParseDiag diag) {
	addDiag(lexer, rangeAtChar(lexer), diag);
}

RangeWithinFile rangeAtChar(in Lexer lexer) {
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

void addDiagUnexpectedCurToken(ref Lexer lexer, Pos start, TokenAndData token) {
	ParseDiag diag = () @trusted {
		switch (token.token) {
			case Token.invalid:
				return ParseDiag(ParseDiag.UnexpectedCharacter(*(lexer.ptr - 1)));
			case Token.operator:
				return ParseDiag(ParseDiag.UnexpectedOperator(token.asSym()));
			default:
				return ParseDiag(ParseDiag.UnexpectedToken(token.token));
		}
	}();
	addDiag(lexer, range(lexer, start), diag);
}

RangeWithinFile range(in Lexer lexer, Pos begin) {
	verify(begin <= curPos(lexer));
	return RangeWithinFile(begin, curPos(lexer));
}

void skipUntilNewlineNoDiag(ref Lexer lexer) {
	if (!isNewlineToken(getPeekToken(lexer))) {
		skipUntilNewline(lexer.ptr);
		readNextToken(lexer);
		verify(isNewlineToken(getPeekToken(lexer)));
	}
}

TokenAndData takeNextToken(ref Lexer lexer) {
	TokenAndData res = cellGet(lexer.nextToken);
	if (isQuoteToken(res.token))
		cellSet(lexer.nextToken, plainToken(Token.quotedText));
	else
		readNextToken(lexer);
	return res;
}

private void readNextToken(ref Lexer lexer) {
	skipSpacesAndComments(lexer.ptr);
	lexer.nextTokenPos = safeToUint(lexer.ptr - lexer.sourceBegin);
	cellSet(lexer.nextToken, lexToken(lexer.ptr, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
			addDiagAtChar(lexer, x)));
}

TokenAndData getPeekTokenAndData(return scope ref const Lexer lexer) =>
	cellGet(lexer.nextToken);
Token getPeekToken(in Lexer lexer) =>
	getPeekTokenAndData(lexer).token;

private RangeWithinFile range(in Lexer lexer, CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeToUint(begin - lexer.sourceBegin));
}

StringPart takeClosingBraceThenStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	if (getPeekToken(lexer) != Token.braceRight)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.closeInterpolated)));
	return takeStringPartCommon(lexer, quoteKind);
}

StringPart takeInitialStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	verify(getPeekToken(lexer) == Token.quotedText);
	return takeStringPartCommon(lexer, quoteKind);
}

private StringPart takeStringPartCommon(ref Lexer lexer, QuoteKind quoteKind) {
	StringPart res = takeStringPart(lexer.alloc, lexer.ptr, quoteKind, (ParseDiag x) => addDiagAtChar(lexer, x));
	takeNextToken(lexer);
	return res;
}

@trusted Opt!EqualsOrThen lookaheadWillTakeEqualsOrThen(in Lexer lexer) {
	switch (getPeekToken(lexer)) {
		case Token.equal:
			return some(EqualsOrThen.equals);
		case Token.arrowThen:
			return some(EqualsOrThen.then);
		default:
			return .lookaheadWillTakeEqualsOrThen(lexer.ptr);
	}
}

@trusted bool lookaheadWillTakeQuestionEquals(in Lexer lexer) =>
	getPeekToken(lexer) == Token.questionEqual || .lookaheadWillTakeQuestionEquals(lexer.ptr);

bool lookaheadWillTakeLambda(in Lexer lexer) =>
	getPeekToken(lexer) == Token.parenLeft && .lookaheadWillTakeArrowAfterParenLeft(lexer.ptr);
