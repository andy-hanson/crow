module frontend.parse.parseUtil;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	allSymbols,
	curPos,
	getCurSym,
	getPeekToken,
	Lexer,
	range,
	skipBlankLinesAndGetIndentDelta,
	skipRestOfLineAndNewline,
	skipUntilNewlineNoDiag,
	takeNewlineAndReturnIndentDelta,
	Token,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.lexWhitespace : IndentDelta;
import model.parseDiag : ParseDiag;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : appendEquals, Sym, sym;
import util.util : drop, unreachable, verify;

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

void addDiagExpected(ref Lexer lexer, ParseDiag.Expected.Kind kind) {
	addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
}

bool takeOrAddDiagExpectedOperator(ref Lexer lexer, Sym operator, ParseDiag.Expected.Kind kind) {
	bool res = tryTakeOperator(lexer, operator);
	if (!res)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}

NameAndRange takeNameAndRange(ref Lexer lexer) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.name))
		return NameAndRange(start, getCurSym(lexer));
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
	tryTakeToken(lexer, Token.name)
		? some(getCurSym(lexer))
		: none!Sym;

Sym takeName(ref Lexer lexer) =>
	takeNameAndRange(lexer).name;

// Does not take the '=' in 'x='
Opt!NameAndRange tryTakeNameOrOperatorAndRangeNoAssignment(ref Lexer lexer) {
	Pos start = curPos(lexer);
	return tryTakeToken(lexer, Token.name) || tryTakeToken(lexer, Token.operator)
		? some(NameAndRange(start, getCurSym(lexer)))
		: none!NameAndRange;
}

// This can take names like 'x='
Sym takeNameOrOperator(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!NameAndRange res = tryTakeNameOrOperatorAndRangeNoAssignment(lexer);
	if (has(res)) {
		Sym name = force(res).name;
		return tryTakeToken(lexer, Token.equal)
			? appendEquals(lexer.allSymbols, name)
			: name;
	} else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.nameOrOperator)));
		return sym!"bogus";
	}
}

bool peekNewline(ref Lexer lexer) {
	Token token = getPeekToken(lexer);
	return token == Token.newline || token == Token.EOF;
}

enum NewlineOrDedent {
	newline,
	dedent,
}

NewlineOrDedent takeNewlineOrSingleDedent(ref Lexer lexer) =>
	toNewlineOrDedent(takeNewlineOrDedentAmount(lexer));

NewlineOrDedent toNewlineOrDedent(uint dedents) {
	switch (dedents) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

enum NewlineOrIndent {
	newline,
	indent,
}

NewlineOrIndent takeNewlineOrIndent_topLevel(ref Lexer lexer) {
	takeNewlineBeforeIndent(lexer);
	return skipBlankLinesAndGetIndentDelta(lexer).match!NewlineOrIndent(
		(IndentDelta.DedentOrSame dedent) {
			verify(dedent.nDedents == 0);
			return NewlineOrIndent.newline;
		},
		(IndentDelta.Indent) =>
			NewlineOrIndent.indent);
}

private void takeNewlineBeforeIndent(ref Lexer lexer) {
	if (!takeOrAddDiagExpectedToken(lexer, [Token.newline, Token.EOF], ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
}
void takeNewline_topLevel(ref Lexer lexer) {
	takeNewlineBeforeIndent(lexer);
}

bool takeIndentOrDiagTopLevel(ref Lexer lexer) =>
	takeIndentOrFailGeneric(lexer, () => true, (RangeWithinFile, uint dedent) {
		verify(dedent == 0);
		return false;
	});

void takeDedentFromIndent1(ref Lexer lexer) {
	bool success = skipBlankLinesAndGetIndentDelta(lexer).match!bool(
		(IndentDelta.DedentOrSame dedent) =>
			dedent.nDedents == 1,
		(IndentDelta.Indent) =>
			false);
	if (!success) {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.dedent)));
		skipRestOfLineAndNewline(lexer);
		takeDedentFromIndent1(lexer);
	}
}

uint takeNewlineOrDedentAmount(ref Lexer lexer) {
	takeNewlineBeforeIndent(lexer);
	return skipBlankLinesAndGetIndentDelta(lexer).match!uint(
		(IndentDelta.DedentOrSame dedent) =>
			dedent.nDedents,
		(IndentDelta.Indent) {
			addDiagAtChar(lexer, ParseDiag(ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipUntilNewlineNoDiag(lexer);
			return takeNewlineOrDedentAmount(lexer);
		});
}

T takeIndentOrFailGeneric(T)(
	ref Lexer lexer,
	in T delegate() @safe @nogc pure nothrow cbIndent,
	in T delegate(RangeWithinFile, uint) @safe @nogc pure nothrow cbFail,
) {
	Pos start = curPos(lexer);
	IndentDelta delta = takeNewlineAndReturnIndentDelta(lexer);
	return delta.match!T(
		(IndentDelta.DedentOrSame dedent) {
			addDiag(lexer, RangeWithinFile(start, start + 1), ParseDiag(
				ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return cbFail(range(lexer, start), dedent.nDedents);
		},
		(IndentDelta.Indent) =>
			cbIndent());
}

void skipNewlinesIgnoreIndentation(ref Lexer lexer) {
	while (tryTakeToken(lexer, Token.newline))
		drop(skipBlankLinesAndGetIndentDelta(lexer));
}
