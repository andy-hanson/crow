module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.lexToken :
	DocCommentAndExtraDedents,
	isNewlineToken,
	lexInitialToken,
	lexToken,
	lookaheadAs,
	lookaheadElifOrElse,
	lookaheadElse,
	lookaheadEqualsOrThen,
	lookaheadLambdaAfterParenLeft,
	lookaheadQuestionEquals,
	plainToken,
	takeStringPart;
import frontend.parse.lexWhitespace : detectIndentKind, IndentKind, skipSpacesAndComments, skipUntilNewline;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, Range;
import util.string : CString;
import util.symbol : AllSymbols;

public import frontend.parse.lexToken : ElifOrElse, EqualsOrThen, QuoteKind, StringPart, Token, TokenAndData;

struct Lexer {
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	immutable CString sourceBegin;
	immutable IndentKind indentKind;

	// Lexer state:
	// This is the indent at 'ptr', after 'nextToken'.
	uint curIndent;
	// This is after 'nextToken'.
	immutable(char)* ptr;
	immutable(char)* prevTokenEnd;
	ArrBuilder!ParseDiagnostic diagnosticsBuilder;
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
	CString source,
) {
	Lexer lexer = Lexer(alloc, allSymbols, source, detectIndentKind(source), 0, source.ptr, source.ptr);
	cellSet(lexer.nextToken,
		lexInitialToken(lexer.ptr, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
			addDiagAtChar(lexer, x)));
	return lexer;
}

Pos curPos(in Lexer lexer) =>
	lexer.nextTokenPos;

private Pos posOf(in Lexer lexer, in immutable char* ptr) =>
	safeToUint(ptr - lexer.sourceBegin.ptr);

void addDiag(ref Lexer lexer, in Range range, ParseDiag diag) {
	add(lexer.alloc, lexer.diagnosticsBuilder, ParseDiagnostic(range, diag));
}

ParseDiagnostic[] finishDiagnostics(ref Lexer lexer) =>
	finishArr(lexer.alloc, lexer.diagnosticsBuilder);

void addDiagAtChar(ref Lexer lexer, ParseDiag diag) {
	addDiag(lexer, rangeAtChar(lexer), diag);
}

Range rangeAtChar(in Lexer lexer) {
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
	return Range(pos, nextPos);
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
	addDiag(lexer, rangeEnsureAtLeastOne(lexer, start), diag);
}

Range rangeEnsureAtLeastOne(in Lexer lexer, Pos begin) {
	Range res = range(lexer, begin);
	return res.end == res.start ? Range(res.start, res.end + 1) : res;
}

Range range(in Lexer lexer, Pos begin) =>
	Range(begin, posOf(lexer, lexer.prevTokenEnd));

void skipUntilNewlineNoDiag(ref Lexer lexer) {
	if (!isNewlineToken(getPeekToken(lexer))) {
		skipUntilNewline(lexer.ptr);
		readNextToken(lexer);
		assert(isNewlineToken(getPeekToken(lexer)));
	}
}

TokenAndData takeNextToken(ref Lexer lexer) {
	TokenAndData res = cellGet(lexer.nextToken);
	switch (res.token) {
		case Token.newlineDedent:
			DocCommentAndExtraDedents dc = res.asDocComment();
			cellSet(lexer.nextToken, TokenAndData(
				dc.extraDedents == 0 ? Token.newlineSameIndent : Token.newlineDedent,
				DocCommentAndExtraDedents(dc.docComment, dc.extraDedents == 0 ? 0 : dc.extraDedents - 1)));
			break;
		case Token.quoteDouble:
		case Token.quoteDouble3:
			cellSet(lexer.nextToken, plainToken(Token.quotedText));
			break;
		default:
			readNextToken(lexer);
			break;
	}
	return res;
}

private void readNextToken(ref Lexer lexer) {
	lexer.prevTokenEnd = lexer.ptr;
	skipSpacesAndComments(lexer.ptr);
	lexer.nextTokenPos = posOf(lexer, lexer.ptr);
	cellSet(lexer.nextToken, lexToken(lexer.ptr, lexer.allSymbols, lexer.indentKind, lexer.curIndent, (ParseDiag x) =>
		addDiagAtChar(lexer, x)));
}

TokenAndData getPeekTokenAndData(return scope ref const Lexer lexer) =>
	cellGet(lexer.nextToken);
Token getPeekToken(in Lexer lexer) =>
	getPeekTokenAndData(lexer).token;

private Range range(in Lexer lexer, CString begin) =>
	range(lexer, posOf(lexer, begin.ptr));

StringPart takeClosingBraceThenStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	if (getPeekToken(lexer) != Token.braceRight)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.closeInterpolated)));
	return takeStringPartCommon(lexer, quoteKind);
}

StringPart takeInitialStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	assert(getPeekToken(lexer) == Token.quotedText);
	return takeStringPartCommon(lexer, quoteKind);
}

private StringPart takeStringPartCommon(ref Lexer lexer, QuoteKind quoteKind) {
	StringPart res = takeStringPart(lexer.alloc, lexer.ptr, quoteKind, (ParseDiag x) => addDiagAtChar(lexer, x));
	// Don't skip newline token (which is a parse error)
	if (!isNewlineToken(getPeekToken(lexer)))
		takeNextToken(lexer);
	return res;
}

@trusted Opt!EqualsOrThen lookaheadEqualsOrThen(in Lexer lexer) {
	switch (getPeekToken(lexer)) {
		case Token.equal:
			return some(EqualsOrThen.equals);
		case Token.arrowThen:
			return some(EqualsOrThen.then);
		default:
			return .lookaheadEqualsOrThen(lexer.ptr);
	}
}

@trusted bool lookaheadQuestionEquals(in Lexer lexer) =>
	getPeekToken(lexer) == Token.questionEqual || .lookaheadQuestionEquals(lexer.ptr);

bool lookaheadLambda(in Lexer lexer) =>
	getPeekToken(lexer) == Token.parenLeft && .lookaheadLambdaAfterParenLeft(lexer.ptr);

bool tryTakeNewlineThenAs(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent && .lookaheadAs(lexer.ptr)) {
		TokenAndData a = takeNextToken(lexer);
		assert(a.token == Token.newlineSameIndent);
		TokenAndData b = takeNextToken(lexer);
		assert(b.token == Token.as);
		return true;
	} else
		return false;
}

bool tryTakeNewlineThenElse(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent && lookaheadElse(lexer.ptr)) {
		TokenAndData a = takeNextToken(lexer);
		assert(a.token == Token.newlineSameIndent);
		TokenAndData b = takeNextToken(lexer);
		assert(b.token == Token.else_);
		return true;
	} else
		return false;
}

Opt!ElifOrElse tryTakeNewlineThenElifOrElse(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent) {
		Opt!ElifOrElse res = lookaheadElifOrElse(lexer.ptr);
		if (has(res)) {
			TokenAndData a = takeNextToken(lexer);
			assert(a.token == Token.newlineSameIndent);
			TokenAndData b = takeNextToken(lexer);
			assert(b.token == elifOrElseToken(force(res)));
		}
		return res;
	} else
		return none!ElifOrElse;
}

private Token elifOrElseToken(ElifOrElse a) {
	final switch (a) {
		case ElifOrElse.elif:
			return Token.elif;
		case ElifOrElse.else_:
			return Token.else_;
	}
}
