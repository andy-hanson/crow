module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.lexString : takeStringPart;
import frontend.parse.lexToken :
	DocCommentAndExtraDedents,
	isNewlineToken,
	lexInitialToken,
	lexToken,
	lookaheadAs,
	lookaheadColon,
	lookaheadElifOrElse,
	lookaheadElse,
	lookaheadEqualsOrThen,
	lookaheadLambdaAfterParenLeft,
	lookaheadNew,
	lookaheadQuestionEquals,
	plainToken;
import frontend.parse.lexWhitespace :
	mayContinueOntoNextLine, detectIndentKind, IndentKind, skipSpacesAndComments, skipUntilNewline;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, Range;
import util.string : CString, MutCString;
import util.symbol : symbol;
import util.util : enumConvert;

public import frontend.parse.lexString : QuoteKind, StringPart;
public import frontend.parse.lexToken : ElifOrElseKeyword, EqualsOrThen, Token, TokenAndData;

struct Lexer {
	@safe @nogc pure nothrow:
	private:
	Alloc* allocPtr;
	immutable CString sourceBegin;
	immutable IndentKind indentKind;

	// Lexer state:
	// This is the indent at 'ptr', after 'nextToken'.
	uint curIndent;
	// This is after 'nextToken'.
	MutCString ptr;
	MutCString prevTokenEnd;
	ArrayBuilder!ParseDiagnostic diagnosticsBuilder;
	// Position at start of 'nextToken'.
	Pos nextTokenPos = void;
	Cell!TokenAndData nextToken = void;

	public:
	ref Alloc alloc() return scope =>
		*allocPtr;
}

@trusted Lexer createLexer(Alloc* alloc, CString source) {
	Lexer lexer = Lexer(alloc, source, detectIndentKind(source), 0, source, source);
	cellSet(lexer.nextToken,
		lexInitialToken(lexer.ptr, lexer.indentKind, lexer.curIndent, (CString start, ParseDiag x) =>
			addDiagFromPointer(lexer, start, x)));
	return lexer;
}

uint getCurIndent(in Lexer lexer) =>
	lexer.curIndent;

private void addDiagFromPointer(scope ref Lexer lexer, CString start, ParseDiag diag) {
	addDiag(lexer, Range(posOf(lexer, start), posOf(lexer, lexer.ptr)), diag);
}

Pos curPos(in Lexer lexer) =>
	lexer.nextTokenPos;

private Pos posOf(in Lexer lexer, in CString ptr) =>
	ptr - lexer.sourceBegin;

void addDiag(ref Lexer lexer, in Range range, ParseDiag diag) {
	add(lexer.alloc, lexer.diagnosticsBuilder, ParseDiagnostic(range, diag));
}

SmallArray!ParseDiagnostic finishDiagnostics(ref Lexer lexer) =>
	smallFinish(lexer.alloc, lexer.diagnosticsBuilder);

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
				MutCString ptr = lexer.ptr;
				ptr++;
				// Treat "\r\n" as one character
				return *ptr == '\n' ? pos + 2 : pos + 1;
			default:
				return pos + 1;
		}
	}();
	return Range(pos, nextPos);
}

void addDiagUnexpectedCurToken(ref Lexer lexer, Pos start, in TokenAndData token) {
	ParseDiag diag = () @trusted {
		switch (token.token) {
			case Token.unexpectedCharacter:
				return ParseDiag(ParseDiag.UnexpectedCharacter(token.asUnexpectedCharacter));
			case Token.operator:
				return ParseDiag(ParseDiag.UnexpectedOperator(token.asSymbol));
			default:
				return ParseDiag(ParseDiag.UnexpectedToken(token.token));
		}
	}();
	addDiag(lexer, rangeForCurToken(lexer, start), diag);
}

Range range(in Lexer lexer, Pos start) =>
	Range(start, posOf(lexer, lexer.prevTokenEnd));

Range rangeForCurToken(in Lexer lexer, Pos start) =>
	Range(start, posOf(lexer, lexer.ptr));

void skipUntilNewlineNoDiag(ref Lexer lexer) {
	if (!isNewlineToken(getPeekToken(lexer))) {
		skipUntilNewline(lexer.ptr);
		readNextToken(lexer);
		assert(isNewlineToken(getPeekToken(lexer)));
	}
}

/*
Since we've ignoring indentation, we need to set the final logical indent level
E.g., in:

f nat(
		x nat)
	x + 1

After the ')', we want to parse as if the previous indent level was 0 (which it was at the '(')
*/

void skipNewlinesIgnoreIndentation(ref Lexer lexer, uint indentLevel) {
	while (true) {
		switch (getPeekToken(lexer)) {
			case Token.newlineDedent:
			case Token.newlineIndent:
			case Token.newlineSameIndent:
				takeNextToken(lexer);
				continue;
			case Token.EOF:
				if (indentLevel != 0)
					cellSet(lexer.nextToken, TokenAndData(Token.newlineDedent, DocCommentAndExtraDedents()));
				lexer.curIndent = 0;
				return;
			default:
				lexer.curIndent = indentLevel;
				return;
		}
	}
}

void mustTakeToken(ref Lexer lexer, Token token) {
	Token actual = takeNextToken(lexer).token;
	assert(actual == token);
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

TokenAndData takeNextTokenMayContinueOntoNextLine(ref Lexer lexer) {
	mayContinueOntoNextLine(lexer.ptr);
	return takeNextToken(lexer);
}

private void readNextToken(ref Lexer lexer) {
	lexer.prevTokenEnd = lexer.ptr;
	skipSpacesAndComments(lexer.ptr, (CString _, string _2) {}, (CString start, ParseDiag x) =>
		addDiagFromPointer(lexer, start, x));
	lexer.nextTokenPos = posOf(lexer, lexer.ptr);
	cellSet(lexer.nextToken, lexToken(
		lexer.ptr, lexer.indentKind, lexer.curIndent, (CString start, ParseDiag x) =>
			addDiagFromPointer(lexer, start, x)));
}

TokenAndData getPeekTokenAndData(return scope ref const Lexer lexer) =>
	cellGet(lexer.nextToken);
Token getPeekToken(in Lexer lexer) =>
	getPeekTokenAndData(lexer).token;

private Range range(in Lexer lexer, CString begin) =>
	range(lexer, posOf(lexer, begin));

StringPart takeClosingBraceThenStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	if (getPeekToken(lexer) != Token.braceRight) {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.closeInterpolated)));
		skipUntilNewlineNoDiag(lexer);
		return StringPart("", StringPart.After.quote);
	} else
		return takeStringPartCommon(lexer, quoteKind);
}

StringPart takeInitialStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	assert(getPeekToken(lexer) == Token.quotedText);
	return takeStringPartCommon(lexer, quoteKind);
}

private StringPart takeStringPartCommon(ref Lexer lexer, QuoteKind quoteKind) {
	StringPart res = takeStringPart(lexer.alloc, lexer.ptr, quoteKind, (CString start, ParseDiag x) =>
		addDiagFromPointer(lexer, start, x));
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

bool lookaheadNewVisibility(in Lexer lexer) =>
	isVisibility(getPeekTokenAndData(lexer)) && lookaheadNew(lexer.ptr);

private bool isVisibility(in TokenAndData a) {
	if (a.token == Token.operator) {
		switch (a.asSymbol.value) {
			case symbol!"-".value:
			case symbol!"~".value:
			case symbol!"+".value:
				return true;
			default:
				return false;
		}
	} else
		return false;
}

bool lookaheadNameColon(in Lexer lexer) =>
	getPeekToken(lexer) == Token.name && lookaheadColon(lexer.ptr);

@trusted bool lookaheadQuestionEquals(in Lexer lexer) =>
	getPeekToken(lexer) == Token.questionEqual || .lookaheadQuestionEquals(lexer.ptr);

bool lookaheadLambda(in Lexer lexer) =>
	getPeekToken(lexer) == Token.parenLeft && .lookaheadLambdaAfterParenLeft(lexer.ptr);

bool lookaheadOpenParen(in Lexer lexer) =>
	*lexer.ptr == '(';

bool lookaheadOpenBracket(in Lexer lexer) =>
	*lexer.ptr == '[';

// Returns position of 'as'
Opt!Pos tryTakeNewlineThenAs(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent && lookaheadAs(lexer.ptr)) {
		mustTakeToken(lexer, Token.newlineSameIndent);
		Pos asPos = curPos(lexer);
		mustTakeToken(lexer, Token.as);
		return some(asPos);
	} else
		return none!Pos;
}

// Returns position of 'else'
Opt!Pos tryTakeNewlineThenElse(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent && lookaheadElse(lexer.ptr)) {
		mustTakeToken(lexer, Token.newlineSameIndent);
		Pos elsePos = curPos(lexer);
		mustTakeToken(lexer, Token.else_);
		return some(elsePos);
	} else
		return none!Pos;
}

Opt!ElifOrElseKeyword tryTakeNewlineThenElifOrElse(ref Lexer lexer) {
	if (getPeekToken(lexer) == Token.newlineSameIndent) {
		Opt!(ElifOrElseKeyword.Kind) kind = lookaheadElifOrElse(lexer.ptr);
		if (has(kind)) {
			mustTakeToken(lexer, Token.newlineSameIndent);
			Pos pos = curPos(lexer);
			mustTakeToken(lexer, enumConvert!Token(force(kind)));
			return some(ElifOrElseKeyword(force(kind), pos));
		} else
			return none!ElifOrElseKeyword;
	} else
		return none!ElifOrElseKeyword;
}
