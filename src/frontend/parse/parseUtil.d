module frontend.parse.parseUtil;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	alloc,
	curPos,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	range,
	skipUntilNewlineNoDiag,
	takeNextToken,
	Token,
	TokenAndData;
import frontend.parse.lexToken : isSymToken;
import model.parseDiag : ParseDiag;
import util.col.arrUtil : contains;
import util.col.str : copyToSafeCStr, SafeCStr, safeCStr;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : Sym, sym;
import util.util : unreachable, verify;

bool peekToken(ref Lexer lexer, Token expected) =>
	getPeekToken(lexer) == expected;
bool peekToken(ref Lexer lexer, in Token[] expected) =>
	contains(expected, getPeekToken(lexer));

bool tryTakeToken(ref Lexer lexer, Token expected) =>
	tryTakeToken(lexer, [expected]);
bool tryTakeToken(ref Lexer lexer, in Token[] expected) {
	if (contains(expected, getPeekToken(lexer))) {
		takeNextToken(lexer);
		return true;
	} else
		return false;
}

bool tryTakeOperator(ref Lexer lexer, Sym expected) =>
	tryTakeTokenIf(lexer, (TokenAndData x) =>
		x.token == Token.operator && x.asSym() == expected);

private bool tryTakeTokenIf(ref Lexer lexer, in bool delegate(TokenAndData) @safe @nogc pure nothrow cb) {
	Opt!bool res = tryTakeToken!bool(lexer, (TokenAndData x) => cb(x) ? some(true) : none!bool);
	return has(res);
}

Opt!T tryTakeToken(T)(ref Lexer lexer, in Opt!T delegate(TokenAndData) @safe @nogc pure nothrow cb) {
	TokenAndData peek = getPeekTokenAndData(lexer);
	Opt!T res = cb(peek);
	if (has(res))
		takeNextToken(lexer);
	return res;
}

bool takeOrAddDiagExpectedToken(ref Lexer lexer, Token token, ParseDiag.Expected.Kind kind) {
	bool res = tryTakeToken(lexer, token);
	if (!res)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}
bool takeOrAddDiagExpectedToken(ref Lexer lexer, in Token[] tokens, ParseDiag.Expected.Kind kind) {
	bool res = tryTakeToken(lexer, tokens);
	if (!res)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}
Opt!T takeOrAddDiagExpectedToken(T)(
	ref Lexer lexer,
	ParseDiag.Expected.Kind kind,
	in Opt!T delegate(TokenAndData) @safe @nogc pure nothrow cb,
) {
	Opt!T res = tryTakeToken!T(lexer, cb);
	if (!has(res))
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}

void addDiagExpected(ref Lexer lexer, ParseDiag.Expected.Kind kind) {
	addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
}

bool takeOrAddDiagExpectedOperator(ref Lexer lexer, Sym operator, ParseDiag.Expected.Kind kind) {
	bool res = tryTakeOperator(lexer, operator);
	if (!res)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}

Opt!NameAndRange tryTakeNameAndRange(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!Sym name = tryTakeName(lexer);
	return has(name)
		? some(NameAndRange(start, force(name)))
		: none!NameAndRange;
}

NameAndRange takeNameAndRange(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!NameAndRange name = tryTakeNameAndRange(lexer);
	if (has(name))
		return force(name);
	else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.name)));
		return NameAndRange(start, sym!"");
	}
}

NameAndRange takeNameAndRangeAllowUnderscore(ref Lexer lexer) {
	Pos start = curPos(lexer);
	return tryTakeToken(lexer, Token.underscore)
		? NameAndRange(start, sym!"_")
		: takeNameAndRange(lexer);
}

Opt!Sym tryTakeName(ref Lexer lexer) =>
	tryTakeToken!Sym(lexer, (TokenAndData x) =>
		x.token == Token.name ? some(x.asSym()) : none!Sym);

Sym takeName(ref Lexer lexer) =>
	takeNameAndRange(lexer).name;

NameAndRange takeNameOrOperator(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!Sym res = tryTakeToken!Sym(lexer, (TokenAndData x) =>
		isSymToken(x.token) && x.token != Token.nameOrOperatorColonEquals
			? some(x.asSym())
			: none!Sym);
	if (has(res))
		return NameAndRange(start, force(res));
	else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.nameOrOperator)));
		return NameAndRange(start, sym!"bogus");
	}
}

private immutable Token[] endOfLineTokensNotEOF =
	[Token.newlineDedent, Token.newlineIndent, Token.newlineSameIndent];
private immutable Token[] endOfLineTokens =
	[Token.newlineDedent, Token.newlineIndent, Token.newlineSameIndent, Token.EOF];

bool peekEndOfLine(ref Lexer lexer) =>
	peekToken(lexer, endOfLineTokens);

SafeCStr takeNewline_topLevel(ref Lexer lexer) {
	TokenAndData token = takeNextToken(lexer);
	if (token.token == Token.newlineSameIndent)
		return copyToSafeCStr(lexer.alloc, token.asDocComment().docComment);
	else {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.newline)));
		NewlineOrDedent nl = skipToNextNewlineOrDedent(lexer);
		verify(nl == NewlineOrDedent.newline);
		return safeCStr!"";
	}
}

void takeDedent(ref Lexer lexer) {
	if (!tryTakeToken(lexer, Token.newlineDedent)) {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.dedent)));
		while (skipToNextNewlineOrDedent(lexer) != NewlineOrDedent.dedent) {}
	}
}

enum NewlineOrDedent {
	newline,
	dedent,
}

NewlineOrDedent takeNewlineOrDedent(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.newlineSameIndent))
		return NewlineOrDedent.newline;
	else if (tryTakeToken(lexer, Token.newlineDedent))
		return NewlineOrDedent.dedent;
	else {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.newlineOrDedent)));
		return skipToNextNewlineOrDedent(lexer);
	}
}

private NewlineOrDedent skipToNextNewlineOrDedent(ref Lexer lexer) {
	uint dedentsNeeded = 0;
	while (true) {
		skipUntilNewlineNoDiag(lexer);
		switch (takeNextToken(lexer).token) {
			case Token.newlineDedent:
				if (dedentsNeeded == 0)
					return NewlineOrDedent.dedent;
				else
					dedentsNeeded -= 1;
				break;
			case Token.newlineSameIndent:
				if (dedentsNeeded == 0)
					return NewlineOrDedent.newline;
				break;
			case Token.EOF:
				verify(dedentsNeeded == 0);
				return NewlineOrDedent.newline;
			case Token.newlineIndent:
				dedentsNeeded += 1;
				break;
			default:
				return unreachable!NewlineOrDedent;
		}
	}
}

T takeIndentOrFailGeneric(T)(
	ref Lexer lexer,
	in T delegate() @safe @nogc pure nothrow cbIndent,
	in T delegate(RangeWithinFile) @safe @nogc pure nothrow cbFail,
) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.newlineIndent))
		return cbIndent();
	else {
		addDiag(lexer, RangeWithinFile(start, start + 1), ParseDiag(
			ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		return cbFail(range(lexer, start)); //TODO: the range is always empty!
	}
}

void skipNewlinesIgnoreIndentation(ref Lexer lexer) {
	while (tryTakeToken(lexer, endOfLineTokensNotEOF)) {}
}
