module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralFloatAst, LiteralIntAst, LiteralNatAst, NameAndRange;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : arrOfRange, empty;
import util.col.arrBuilder : add, ArrBuilder;
import util.col.arrUtil : contains;
import util.col.str : copyStr, copyToSafeCStr, CStr, SafeCStr, safeCStr;
import util.conv : safeIntFromUint, safeToUint;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, appendEquals, concatSymsWithDot, Sym, sym, symOfStr;
import util.union_ : Union;
import util.util : drop, todo, unreachable, verify;

private enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer {
	private:
	Alloc* allocPtr;
	AllSymbols* allSymbolsPtr;
	ArrBuilder!DiagnosticWithinFile* diagnosticsBuilderPtr;
	CStr sourceBegin;
	immutable(char)* ptr;
	immutable IndentKind indentKind;
	union {
		bool ignore;
		Cell!Sym curSym; // For Token.name
		Cell!Sym curOperator;
		Cell!LiteralFloatAst curLiteralFloat; // for Token.literalFloat
		Cell!LiteralIntAst curLiteralInt; // for Token.literalInt
		Cell!LiteralNatAst curLiteralNat; // for Token.literalNat
	}
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
	Lexer(
		alloc,
		allSymbols,
		diagnosticsBuilder,
		source.ptr,
		source.ptr,
		detectIndentKind(source));

private @trusted char prevChar(in Lexer lexer) =>
	*(lexer.ptr - 1);

private char curChar(in Lexer lexer) =>
	*lexer.ptr;

@trusted Pos curPos(scope ref Lexer lexer) {
	// Ensure start is after any whitespace
	while (tryTakeChar(lexer, ' ') || tryTakeChar(lexer, '\t') || tryTakeChar(lexer, '\r')) {}
	return posOfPtr(lexer, lexer.ptr);
}

private Pos posOfPtr(in Lexer lexer, in CStr ptr) =>
	safeToUint(ptr - lexer.sourceBegin);

void addDiag(ref Lexer lexer, RangeWithinFile range, ParseDiag diag) {
	add(lexer.alloc, *lexer.diagnosticsBuilderPtr, DiagnosticWithinFile(range, Diag(diag)));
}

void addDiagAtChar(ref Lexer lexer, ParseDiag diag) {
	addDiag(lexer, rangeAtChar(lexer), diag);
}

RangeWithinFile rangeAtChar(scope ref Lexer lexer) {
	Pos pos = curPos(lexer);
	Pos nextPos = () @trusted {
		switch (curChar(lexer)) {
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

private void addDiagAtCurToken(ref Lexer lexer, Pos start, ParseDiag diag) {
	addDiag(lexer, range(lexer, start), diag);
}

void addDiagUnexpectedCurToken(ref Lexer lexer, Pos start, Token token) {
	ParseDiag diag = () {
		switch (token) {
			case Token.invalid:
				return ParseDiag(ParseDiag.UnexpectedCharacter(prevChar(lexer)));
			case Token.operator:
				return ParseDiag(ParseDiag.UnexpectedOperator(getCurOperator(lexer)));
			default:
				return ParseDiag(ParseDiag.UnexpectedToken(token));
		}
	}();
	addDiagAtCurToken(lexer, start, diag);
}

// WARN: Caller should check for '\0'
private @system char takeChar(ref Lexer lexer) {
	char res = *lexer.ptr;
	lexer.ptr++;
	return res;
}

private @trusted bool tryTakeChar(ref Lexer lexer, char c) {
	if (*lexer.ptr == c) {
		lexer.ptr++;
		return true;
	} else
		return false;
}

private @trusted bool tryTakeCStr(ref Lexer lexer, CStr c) {
	immutable(char)* ptr2 = lexer.ptr;
	for (immutable(char)* cptr = c; *cptr != 0; cptr++) {
		if (*ptr2 != *cptr)
			return false;
		ptr2++;
	}
	lexer.ptr = ptr2;
	return true;
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

void addDiagExpected(ref Lexer lexer, ParseDiag.Expected.Kind kind) {
	addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
}

bool takeOrAddDiagExpectedOperator(ref Lexer lexer, Sym operator, ParseDiag.Expected.Kind kind) {
	bool res = tryTakeOperator(lexer, operator);
	if (!res)
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(kind)));
	return res;
}

enum NewlineOrIndent {
	newline,
	indent,
}

NewlineOrIndent takeNewlineOrIndent_topLevel(ref Lexer lexer) {
	takeNewlineBeforeIndent(lexer);
	return takeNewlineOrIndentAfterEOL(lexer);
}

private NewlineOrIndent takeNewlineOrIndentAfterEOL(ref Lexer lexer) {
	IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, 0);
	return delta.match!NewlineOrIndent(
		(IndentDelta.DedentOrSame dedent) {
			verify(dedent.nDedents == 0);
			return NewlineOrIndent.newline;
		},
		(IndentDelta.Indent) =>
			NewlineOrIndent.indent);
}

bool takeIndentOrDiagTopLevel(ref Lexer lexer) =>
	takeIndentOrFailGeneric(lexer, 0, () => true, (RangeWithinFile, uint dedent) {
		verify(dedent == 0);
		return false;
	});

bool tryTakeIndent(ref Lexer lexer, uint curIndent) {
	//TODO: always have cur token handy, no need to back up
	immutable char* begin = lexer.ptr;
	if (nextToken(lexer) == Token.newline) {
		IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		return delta.match!bool(
			(IndentDelta.DedentOrSame) {
				addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
				lexer.ptr = begin;
				return false;
			},
			(IndentDelta.Indent) =>
				true);
	} else {
		lexer.ptr = begin;
		return false;
	}
}

T takeIndentOrFailGeneric(T)(
	ref Lexer lexer,
	uint curIndent,
	in T delegate() @safe @nogc pure nothrow cbIndent,
	in T delegate(RangeWithinFile, uint) @safe @nogc pure nothrow cbFail,
) {
	Pos start = curPos(lexer);
	IndentDelta delta = takeNewlineAndReturnIndentDelta(lexer, curIndent);
	return delta.match!T(
		(IndentDelta.DedentOrSame dedent) {
			addDiag(lexer, RangeWithinFile(start, start + 1), ParseDiag(
				ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return cbFail(range(lexer, start), dedent.nDedents);
		},
		(IndentDelta.Indent) =>
			cbIndent());
}

private void takeNewlineBeforeIndent(ref Lexer lexer) {
	if (!takeOrAddDiagExpectedToken(lexer, [Token.newline, Token.EOF], ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
}
void takeNewline_topLevel(ref Lexer lexer) {
	takeNewlineBeforeIndent(lexer);
}

private @trusted IndentDelta takeNewlineAndReturnIndentDelta(ref Lexer lexer, uint curIndent) {
	skipSpacesAndComments(lexer);
	if (!tryTakeNewline(lexer)) {
		//TODO: not always expecting indent..
		addDiagAtChar(lexer, ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipRestOfLineAndNewline(lexer);
	}
	return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
}

void takeDedentFromIndent1(ref Lexer lexer) {
	IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, 1);
	bool success = delta.match!bool(
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

uint takeNewlineOrDedentAmount(ref Lexer lexer, uint curIndent) {
	takeNewlineBeforeIndent(lexer);
	IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, curIndent);
	return delta.match!uint(
		(IndentDelta.DedentOrSame dedent) =>
			dedent.nDedents,
		(IndentDelta.Indent) {
			addDiagAtChar(lexer, ParseDiag(ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipUntilNewlineNoDiag(lexer);
			return takeNewlineOrDedentAmount(lexer, curIndent);
		});
}

enum NewlineOrDedent {
	newline,
	dedent,
}

NewlineOrDedent takeNewlineOrSingleDedent(ref Lexer lexer) {
	switch (takeNewlineOrDedentAmount(lexer, 1)) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

RangeWithinFile range(ref Lexer lexer, Pos begin) {
	verify(begin <= curPos(lexer));
	return RangeWithinFile(begin, curPos(lexer));
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

Sym takePathComponent(ref Lexer lexer) =>
	takePathComponentRest(lexer, takeName(lexer));
private Sym takePathComponentRest(ref Lexer lexer, Sym cur) {
	if (tryTakeToken(lexer, Token.dot)) {
		Sym extension = takeName(lexer);
		return takePathComponentRest(lexer, concatSymsWithDot(lexer.allSymbols, cur, extension));
	} else
		return cur;
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
	return tryTakeToken(lexer, Token.name)
		? some(NameAndRange(start, getCurSym(lexer)))
		: tryTakeToken(lexer, Token.operator)
		? some(NameAndRange(start, getCurOperator(lexer)))
		: none!NameAndRange;
}

// This can take names like 'x='
Sym takeNameOrOperator(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!NameAndRange res = tryTakeNameOrOperatorAndRangeNoAssignment(lexer);
	if (has(res)) {
		Sym name = force(res).name;
		return tryTakeChar(lexer, '=')
			? appendEquals(lexer.allSymbols, name)
			: name;
	} else {
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.nameOrOperator)));
		return sym!"bogus";
	}
}

@trusted void skipUntilNewlineNoDiag(ref Lexer lexer) {
	while (!isNewlineChar(*lexer.ptr) && *lexer.ptr != '\0')
		lexer.ptr++;
}

void skipNewlinesIgnoreIndentation(ref Lexer lexer) {
	while (tryTakeToken(lexer, Token.newline))
		drop(skipBlankLinesAndGetIndentDelta(lexer, 0));
}

private:

@trusted SafeCStr takeRestOfLineAndNewline(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	skipRestOfLineAndNewline(lexer);
	immutable char* end = lexer.ptr - 1;
	return copyToSafeCStr(lexer.alloc, arrOfRange(begin, end));
}

void skipRestOfLineAndNewline(ref Lexer lexer) {
	skipUntilNewlineNoDiag(lexer);
	drop(tryTakeNewline(lexer));
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
@trusted IndentKind detectIndentKind(SafeCStr a) {
	immutable(char)* ptr = a.ptr;
	switch (*ptr) {
		case '\0':
			// No indented lines, so it's irrelevant
			return IndentKind.tabs;
		case '\t':
			return IndentKind.tabs;
		case ' ':
			// Count spaces
			do { ptr++; } while (*ptr == ' ');
			size_t n = ptr - a.ptr;
			// Only allowed amounts are 2 and 4.
			return n == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
		default:
			while (*ptr != '\0' && !isNewlineChar(*ptr))
				ptr++;
			if (isNewlineChar(*ptr))
				ptr++;
			return detectIndentKind(SafeCStr(ptr));
	}
}

@trusted void backUp(ref Lexer lexer) {
	lexer.ptr--;
}

public enum Token {
	act, // 'act'
	alias_, // 'alias'
	arrowAccess, // '->'
	arrowLambda, // '=>'
	arrowThen, // '<-'
	as, // 'as'
	assert_, // 'assert'
	at, // '@'
	bang, // '!'
	bare, // 'bare'
	break_, // 'break'
	builtin, // 'builtin'
	builtinSpec, // 'builtin-spec'
	braceLeft, // '{'
	braceRight, // '}'
	bracketLeft, // '['
	bracketRight, // ']'
	colon, // ':'
	colon2, // '::'
	colonEqual, // ':='
	comma, // ','
	continue_, // 'continue'
	dot, // '.'
	// '..' is Operator.range
	dot3, // '...'
	elif, // 'elif'
	else_, // 'else'
	enum_, // 'enum'
	equal, // '='
	extern_, // 'extern'
	EOF, // end of file
	export_, // 'export'
	far, // 'far'
	flags, // 'flags'
	for_, // 'for'
	forbid, // 'forbid'
	forceCtx, // 'force-ctx'
	fun, // 'fun'
	global, // 'global'
	if_, // 'if'
	import_, // 'import'
	invalid, // invalid token (e.g. illegal character)
	literalFloat, // Use getCurLiteralFloat
	literalInt, // Use getCurLiteralInt
	literalNat, // Use getCurLiteralNat
	loop, // 'loop'
	match, // 'match'
	mut, // 'mut'
	name, // Any non-keyword, non-operator name; use getCurSym with this
	newline, // end of line
	noStd, // 'no-std'
	operator, // Any operator; use getCurOperator with this
	parenLeft, // '('
	parenRight, // ')'
	question, // '?'
	questionEqual, // '?='
	quoteDouble, // '"'
	quoteDouble3, // '"""'
	record, // 'record'
	semicolon, // ';'
	spec, // 'spec'
	summon, // 'summon'
	test, // 'test'
	thread_local, // 'thread-local'
	throw_, // 'throw'
	trusted, // 'trusted'
	underscore, // '_'
	union_, // 'union'
	unless, // 'unless'
	unsafe, // 'unsafe'
	until, // 'until'
	while_, // 'while'
	with_, // 'with'
}

void skipSpacesAndComments(ref Lexer lexer) {
	while (true) {
		switch (*lexer.ptr) {
			case ' ':
			case '\t':
				continue;
			case '#':
				skipUntilNewlineNoDiag(lexer);
				return;
			default:
				return;
		}
	}
}

@trusted public Token nextToken(ref Lexer lexer) {
	char c = takeChar(lexer);
	switch (c) {
		case '\0':
			lexer.ptr--;
			return Token.EOF;
		case ' ':
		case '\t':
			return nextToken(lexer);
		case '#':
			skipRestOfLineAndNewline(lexer);
			return Token.newline;
		case '\r':
		case '\n':
			return Token.newline;
		case '~':
			return operatorToken(lexer, tryTakeChar(lexer, '~') ? sym!"~~" : sym!"~");
		case '@':
			return Token.at;
		case '!':
			return lexer.ptr[0 .. 2] != "==" && tryTakeChar(lexer, '=')
				? operatorToken(lexer, sym!"!=")
				: Token.bang;
		case '%':
			return operatorToken(lexer, sym!"%");
		case '^':
			return operatorToken(lexer, sym!"^");
		case '&':
			return operatorToken(lexer, tryTakeChar(lexer, '&') ? sym!"&&" : sym!"&");
		case '*':
			return operatorToken(lexer, tryTakeChar(lexer, '*') ? sym!"**" : sym!"*");
		case '(':
			return Token.parenLeft;
		case ')':
			return Token.parenRight;
		case '[':
			return Token.bracketLeft;
		case '{':
			return Token.braceLeft;
		case '}':
			return Token.braceRight;
		case ']':
			return Token.bracketRight;
		case '-':
			return isDigit(*lexer.ptr)
				? takeNumberAfterSign(lexer, some(Sign.minus))
				: tryTakeChar(lexer, '>')
				? Token.arrowAccess
				: operatorToken(lexer, sym!"-");
		case '=':
			return tryTakeChar(lexer, '>')
				? Token.arrowLambda
				: tryTakeChar(lexer, '=')
				? operatorToken(lexer, sym!"==")
				: Token.equal;
		case '+':
			return isDigit(*lexer.ptr)
				? takeNumberAfterSign(lexer, some(Sign.plus))
				: operatorToken(lexer, sym!"+");
		case '|':
			return operatorToken(lexer, tryTakeChar(lexer, '|') ? sym!"||" : sym!"|");
		case ':':
			return tryTakeChar(lexer, '=')
				? Token.colonEqual
				: tryTakeChar(lexer, ':')
				? Token.colon2
				: Token.colon;
		case ';':
			return Token.semicolon;
		case '"':
			return tryTakeCStr(lexer, "\"\"")
				? Token.quoteDouble3
				: Token.quoteDouble;
		case ',':
			return Token.comma;
		case '<':
			return tryTakeChar(lexer, '-')
				? Token.arrowThen
				: operatorToken(lexer, tryTakeChar(lexer, '=')
					? tryTakeChar(lexer, '>') ? sym!"<=>" : sym!"<="
					: tryTakeChar(lexer, '<')
					? sym!"<<"
					: sym!"<");
		case '>':
			return operatorToken(lexer, tryTakeChar(lexer, '=')
				? sym!">="
				: tryTakeChar(lexer, '>')
				? sym!">>"
				: sym!">");
		case '.':
			return tryTakeChar(lexer, '.')
				? tryTakeChar(lexer, '.') ? Token.dot3 : operatorToken(lexer, sym!"..")
				: Token.dot;
		case '/':
			return operatorToken(lexer, sym!"/");
		case '?':
			return tryTakeChar(lexer, '=')
				? Token.questionEqual
				: tryTakeChar(lexer, '?')
				? operatorToken(lexer, sym!"??")
				: Token.question;
		default:
			if (isAlphaIdentifierStart(c)) {
				string nameStr = takeNameRest(lexer, lexer.ptr - 1);
				return tokenForSym(lexer, symOfStr(lexer.allSymbols, nameStr));
			} else if (isDigit(c)) {
				backUp(lexer);
				return takeNumberAfterSign(lexer, none!Sign);
			} else
				return Token.invalid;
	}
}

Token tokenForSym(ref Lexer lexer, Sym a) {
	switch (a.value) {
		case sym!"act".value:
			return Token.act;
		case sym!"alias".value:
			return Token.alias_;
		case sym!"as".value:
			return Token.as;
		case sym!"assert".value:
			return Token.assert_;
		case sym!"bare".value:
			return Token.bare;
		case sym!"break".value:
			return Token.break_;
		case sym!"builtin".value:
			return Token.builtin;
		case sym!"builtin-spec".value:
			return Token.builtinSpec;
		case sym!"continue".value:
			return Token.continue_;
		case sym!"elif".value:
			return Token.elif;
		case sym!"else".value:
			return Token.else_;
		case sym!"enum".value:
			return Token.enum_;
		case sym!"export".value:
			return Token.export_;
		case sym!"extern".value:
			return Token.extern_;
		case sym!"far".value:
			return Token.far;
		case sym!"flags".value:
			return Token.flags;
		case sym!"for".value:
			return Token.for_;
		case sym!"forbid".value:
			return Token.forbid;
		case sym!"force-ctx".value:
			return Token.forceCtx;
		case sym!"fun".value:
			return Token.fun;
		case sym!"global".value:
			return Token.global;
		case sym!"if".value:
			return Token.if_;
		case sym!"import".value:
			return Token.import_;
		case sym!"loop".value:
			return Token.loop;
		case sym!"match".value:
			return Token.match;
		case sym!"mut".value:
			return Token.mut;
		case sym!"no-std".value:
			return Token.noStd;
		case sym!"record".value:
			return Token.record;
		case sym!"spec".value:
			return Token.spec;
		case sym!"summon".value:
			return Token.summon;
		case sym!"test".value:
			return Token.test;
		case sym!"thread-local".value:
			return Token.thread_local;
		case sym!"throw".value:
			return Token.throw_;
		case sym!"trusted".value:
			return Token.trusted;
		case sym!"unless".value:
			return Token.unless;
		case sym!"union".value:
			return Token.union_;
		case sym!"unsafe".value:
			return Token.unsafe;
		case sym!"until".value:
			return Token.until;
		case sym!"while".value:
			return Token.while_;
		case sym!"with".value:
			return Token.with_;
		case sym!"_".value:
			return Token.underscore;
		default:
			return nameToken(lexer, a);
	}
}

Token nameToken(ref Lexer lexer, Sym a) {
	cellSet(lexer.curSym, a);
	return Token.name;
}

Token operatorToken(ref Lexer lexer, Sym a) {
	cellSet(lexer.curOperator, a);
	return Token.operator;
}

public Sym getCurSym(ref Lexer lexer) =>
	//TODO: assert that cur token is Token.name
	cellGet(lexer.curSym);

public NameAndRange getCurNameAndRange(ref Lexer lexer, Pos start) =>
	immutable NameAndRange(start, getCurSym(lexer));

public Sym getCurOperator(ref Lexer lexer) =>
	cellGet(lexer.curOperator);

public LiteralFloatAst getCurLiteralFloat(ref Lexer lexer) =>
	cellGet(lexer.curLiteralFloat);

public LiteralIntAst getCurLiteralInt(ref Lexer lexer) =>
	cellGet(lexer.curLiteralInt);

public LiteralNatAst getCurLiteralNat(ref Lexer lexer) =>
	cellGet(lexer.curLiteralNat);

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
	if (actual == Token.operator && getCurOperator(lexer) == expected)
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

public bool peekTokenExpression(ref Lexer lexer) =>
	isExpressionStartToken(getPeekToken(lexer));

// Whether a token may start an expression
bool isExpressionStartToken(Token a) {
	final switch (a) {
		case Token.act:
		case Token.alias_:
		case Token.arrowAccess:
		case Token.arrowLambda:
		case Token.arrowThen:
		case Token.as:
		case Token.at:
		case Token.bare:
		case Token.builtin:
		case Token.builtinSpec:
		case Token.braceLeft:
		case Token.braceRight:
		case Token.bracketRight:
		case Token.colon:
		case Token.colon2:
		case Token.colonEqual:
		case Token.comma:
		case Token.dot:
		case Token.dot3:
		case Token.elif:
		case Token.else_:
		case Token.enum_:
		case Token.equal:
		case Token.export_:
		case Token.extern_:
		case Token.EOF:
		case Token.far:
		case Token.flags:
		case Token.forceCtx:
		case Token.fun:
		case Token.global:
		case Token.import_:
		case Token.invalid:
		case Token.mut:
		case Token.newline:
		case Token.noStd:
		case Token.parenRight:
		case Token.question:
		case Token.questionEqual:
		case Token.record:
		case Token.semicolon:
		case Token.spec:
		case Token.summon:
		case Token.test:
		case Token.thread_local:
		case Token.union_:
		case Token.unsafe:
			return false;
		case Token.assert_:
		case Token.bang:
		case Token.bracketLeft:
		case Token.break_:
		case Token.continue_:
		case Token.forbid:
		case Token.if_:
		case Token.for_:
		case Token.literalFloat:
		case Token.literalInt:
		case Token.literalNat:
		case Token.loop:
		case Token.match:
		case Token.name:
		case Token.operator:
		case Token.parenLeft:
		case Token.quoteDouble:
		case Token.quoteDouble3:
		case Token.throw_:
		case Token.trusted:
		case Token.underscore:
		case Token.unless:
		case Token.until:
		case Token.with_:
		case Token.while_:
			return true;
	}
}

RangeWithinFile range(ref Lexer lexer, CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeToUint(begin - lexer.sourceBegin));
}

enum Sign {
	plus,
	minus,
}

@trusted Token takeNumberAfterSign(ref Lexer lexer, Opt!Sign sign) {
	ulong base = tryTakeCStr(lexer, "0x")
		? 16
		: tryTakeCStr(lexer, "0o")
		? 8
		: tryTakeCStr(lexer, "0b")
		? 2
		: 10;
	LiteralNatAst n = takeNat(lexer, base);
	if (*lexer.ptr == '.' && isDigit(*(lexer.ptr + 1))) {
		lexer.ptr++;
		return takeFloat(lexer, has(sign) ? force(sign) : Sign.plus, n, base);
	} else if (has(sign)) {
		LiteralIntAst intAst = () {
			final switch (force(sign)) {
				case Sign.plus:
					return LiteralIntAst(n.value, n.value > long.max);
				case Sign.minus:
					return LiteralIntAst(-n.value, n.value > (cast(ulong) long.max) + 1);
			}
		}();
		cellSet(lexer.curLiteralInt, intAst);
		return Token.literalInt;
	} else {
		cellSet(lexer.curLiteralNat, n);
		return Token.literalNat;
	}
}

@system Token takeFloat(ref Lexer lexer, Sign sign, ref LiteralNatAst natPart, ulong base) {
	// TODO: improve accuracy
	const char *cur = lexer.ptr;
	LiteralNatAst rest = takeNat(lexer, base);
	bool overflow = natPart.overflow || rest.overflow;
	ulong power = lexer.ptr - cur;
	double multiplier = pow(1.0, 1.0 / base, power);
	double floatSign = () {
		final switch (sign) {
			case Sign.minus:
				return -1.0;
			case Sign.plus:
				return 1.0;
		}
	}();
	double f = floatSign * (natPart.value + (rest.value * multiplier));
	cellSet(lexer.curLiteralFloat, LiteralFloatAst(f, overflow));
	return Token.literalFloat;
}

double pow(double acc, double base, ulong power) =>
	power == 0 ? acc : pow(acc * base, base, power - 1);

//TODO: overflow bug possible here
ulong getDivisor(ulong acc, ulong a, ulong base) =>
	acc < a ? getDivisor(acc * base, a, base) : acc;

@system LiteralNatAst takeNat(ref Lexer lexer, ulong base) =>
	takeNatRecur(lexer, base, 0, false);

@system LiteralNatAst takeNatRecur(ref Lexer lexer, ulong base, ulong value, bool overflow) {
	ulong digit = charToNat(*lexer.ptr);
	if (digit < base) {
		lexer.ptr++;
		ulong newValue = value * base + digit;
		drop(tryTakeChar(lexer, '_'));
		return takeNatRecur(lexer, base, newValue, overflow || newValue / base != value);
	} else
		return LiteralNatAst(value, overflow);
}

ulong charToNat(char c) =>
	'0' <= c && c <= '9'
		? c - '0'
		: 'a' <= c && c <= 'f'
		? 10 + (c - 'a')
		: 'A' <= c && c <= 'F'
		? 10 + (c - 'A')
		: ulong.max;

size_t toHexDigit(char c) {
	if ('0' <= c && c <= '9')
		return c - '0';
	else if ('a' <= c && c <= 'f')
		return 10 + c - 'a';
	else
		return todo!size_t("parse diagnostic -- bad hex digit");
}

public immutable struct StringPart {
	string text;
	After after;

	enum After {
		quote,
		lbrace,
	}
}

public enum QuoteKind {
	double_,
	double3,
}

public @trusted StringPart takeStringPart(ref Lexer lexer, QuoteKind quoteKind) {
	char[0x10000] res = void;
	size_t i = 0;
	void push(char c) {
		res[i] = c;
		i++;
	}
	StringPart.After after = () {
		while (true) {
			char x = takeChar(lexer);
			switch(x) {
				case '"':
					final switch (quoteKind) {
						case QuoteKind.double_:
							return StringPart.After.quote;
						case QuoteKind.double3:
							if (tryTakeCStr(lexer, "\"\""))
								return StringPart.After.quote;
							else
								push('"');
							break;
					}
					break;
				case '\r':
				case '\n':
					final switch (quoteKind) {
						case QuoteKind.double_:
							addDiagExpected(lexer, ParseDiag.Expected.Kind.quoteDouble);
							return StringPart.After.quote;
						case QuoteKind.double3:
							push(x);
							break;
					}
					break;
				case '\0':
					ParseDiag.Expected.Kind expected = () {
						final switch (quoteKind) {
							case QuoteKind.double_:
								return ParseDiag.Expected.Kind.quoteDouble;
							case QuoteKind.double3:
								return ParseDiag.Expected.Kind.quoteDouble3;
						}
					}();
					addDiagExpected(lexer, expected);
					return StringPart.After.quote;
				case '{':
					return StringPart.After.lbrace;
				case '\\':
					char escapeCode = takeChar(lexer);
					char escaped = () {
						switch (escapeCode) {
							case 'x':
								size_t digit0 = toHexDigit(takeChar(lexer));
								size_t digit1 = toHexDigit(takeChar(lexer));
								return cast(char) (digit0 * 16 + digit1);
							case 'n':
								return '\n';
							case 'r':
								return '\r';
							case 't':
								return '\t';
							case '\\':
								return '\\';
							case '{':
								return '{';
							case '0':
								return '\0';
							case '"':
								return '"';
							default:
								addDiagAtChar(lexer, ParseDiag(ParseDiag.InvalidStringEscape(escapeCode)));
								return 'a';
						}
					}();
					push(escaped);
					break;
				default:
					push(x);
			}
		}
	}();
	return StringPart(copyStr(lexer.alloc, cast(immutable) res[0 .. i]), after);
}

@trusted string takeNameRest(ref Lexer lexer, CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*(lexer.ptr - 1) == '-')
		lexer.ptr--;
	return arrOfRange(begin, lexer.ptr);
}

// Called after the newline
@trusted uint takeIndentAmount(ref Lexer lexer) {
	CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (tryTakeChar(lexer, '\t')) {}
		if (*lexer.ptr == ' ')
			addDiagAtChar(lexer, ParseDiag(ParseDiag.IndentWrongCharacter(true)));
		return safeToUint(lexer.ptr - begin);
	} else {
		Pos start = curPos(lexer);
		while (tryTakeChar(lexer, ' ')) {}
		if (*lexer.ptr == '\t')
			addDiagAtChar(lexer, ParseDiag(ParseDiag.IndentWrongCharacter(false)));
		uint nSpaces = safeToUint(lexer.ptr - begin);
		uint nSpacesPerIndent = lexer.indentKind == IndentKind.spaces2 ? 2 : 4;
		uint res = nSpaces / nSpacesPerIndent;
		if (res * nSpacesPerIndent != nSpaces)
			addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
		return res;
	}
}

immutable struct IndentDelta {
	immutable struct DedentOrSame {
		uint nDedents;
	}
	immutable struct Indent {}

	mixin Union!(DedentOrSame, Indent);
}

public SafeCStr skipBlankLinesAndGetDocComment(ref Lexer lexer) =>
	skipBlankLinesAndGetDocCommentRecur(lexer, safeCStr!"");

SafeCStr skipBlankLinesAndGetDocCommentRecur(ref Lexer lexer, SafeCStr comment) {
	if (tryTakeNewline(lexer))
		return skipBlankLinesAndGetDocCommentRecur(lexer, comment);
	else if (tryTakeTripleHashThenNewline(lexer))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeRestOfBlockComment(lexer));
	else if (tryTakeChar(lexer, '#'))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeRestOfLineAndNewline(lexer));
	else if (tryTakeCStr(lexer, "region ") || tryTakeCStr(lexer, "subregion ")) {
		skipRestOfLineAndNewline(lexer);
		return skipBlankLinesAndGetDocCommentRecur(lexer, safeCStr!"");
	} else
		return comment;
}

// Returns the change in indent (and updates the indent)
// Note: does nothing if not looking at a newline!
// NOTE: never returns a value > 1 as double-indent is always illegal.
IndentDelta skipBlankLinesAndGetIndentDelta(ref Lexer lexer, uint curIndent) {
	// comment / region counts as a blank line no matter its indent level.
	uint newIndent = takeIndentAmount(lexer);
	if (tryTakeNewline(lexer))
		// Ignore lines that are just whitespace
		return skipBlankLinesAndGetIndentDelta(lexer, curIndent);

	// For indent == 0, we'll try taking any comments as doc comments
	if (newIndent != 0) {
		// Comments can mean a dedent
		if (tryTakeTripleHashThenNewline(lexer)) {
			drop(skipRestOfBlockComment(lexer));
			return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		} else if (tryTakeChar(lexer, '#')) {
			skipRestOfLineAndNewline(lexer);
			return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		}
	}

	// If we got here, we're looking at a non-empty line (or EOF)
	int delta = safeIntFromUint(newIndent) - safeIntFromUint(curIndent);
	if (delta > 1) {
		addDiagAtChar(lexer, ParseDiag(ParseDiag.IndentTooMuch()));
		skipRestOfLineAndNewline(lexer);
		return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
	} else
		return delta == 1
			? IndentDelta(IndentDelta.Indent())
			: IndentDelta(IndentDelta.DedentOrSame(-delta));
}

bool isNewlineChar(char c) =>
	c == '\r' || c == '\n';

bool tryTakeNewline(ref Lexer lexer) =>
	tryTakeChar(lexer, '\r') || tryTakeChar(lexer, '\n');

bool tryTakeTripleHashThenNewline(ref Lexer lexer) =>
	tryTakeCStr(lexer, "###\r") || tryTakeCStr(lexer, "###\n");

@trusted SafeCStr takeRestOfBlockComment(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	immutable char* end = skipRestOfBlockComment(lexer);
	return copyToSafeCStr(lexer.alloc, stripWhitespace(arrOfRange(begin, end)));
}

string stripWhitespace(string a) =>
	stripWhitespaceRight(stripWhitespaceLeft(a));

string stripWhitespaceLeft(string a) =>
	empty(a) || !isWhitespace(a[0]) ? a : stripWhitespaceLeft(a[1 .. $]);

string stripWhitespaceRight(string a) =>
	empty(a) || !isWhitespace(a[$ - 1]) ? a : stripWhitespaceRight(a[0 .. $ - 1]);

public bool isWhitespace(char a) {
	switch (a) {
		case ' ':
		case '\t':
		case '\r':
		case '\n':
			return true;
		default:
			return false;
	}
}

@trusted immutable(char*) skipRestOfBlockComment(ref Lexer lexer) {
	skipRestOfLineAndNewline(lexer);
	while (tryTakeChar(lexer, '\t') || tryTakeChar(lexer, ' ')) {}
	immutable char* end = lexer.ptr;
	if (tryTakeTripleHashThenNewline(lexer))
		return end;
	else if (*lexer.ptr == '\0') {
		addDiagExpected(lexer, ParseDiag.Expected.Kind.blockCommentEnd);
		return end;
	} else
		return skipRestOfBlockComment(lexer);
}

public enum EqualsOrThen { equals, then }
public @trusted Opt!EqualsOrThen lookaheadWillTakeEqualsOrThen(ref Lexer lexer) {
	immutable(char)* ptr = lexer.ptr;
	if (ptr[0] == '<' && ptr[1] == '-' && ptr[2] == ' ')
		return some(EqualsOrThen.then);
	while (true) {
		switch (*ptr) {
			case ' ':
				if (ptr[1] == '=' && ptr[2] == ' ')
					return some(EqualsOrThen.equals);
				else if (ptr[1] == '<' && ptr[2] == '-' && ptr[3] == ' ')
					return some(EqualsOrThen.then);
				break;
			// characters that appear in types
			default:
				if (!isTypeChar(*ptr))
					return none!EqualsOrThen;
				break;
		}
		ptr++;
	}
}

public @trusted bool lookaheadWillTakeQuestionEquals(ref Lexer lexer) {
	immutable(char)* ptr = lexer.ptr;
	while (true) {
		switch (*ptr) {
			case ' ':
				if (ptr[1] == '?' && ptr[2] == '=' && ptr[3] == ' ')
					return true;
				break;
			default:
				// Destructure chars are same as type chars
				if (!isTypeChar(*ptr))
					return false;
				break;
		}
		ptr++;
	}
}

bool isTypeChar(char c) {
	switch (c) {
		case ' ':
		case ',':
		case '?':
		case '^':
		case '*':
		case '[':
		case ']':
		case '(':
		case ')':
			return true;
		default:
			return isAlphaIdentifierContinue(c);
	}
}

public @trusted bool lookaheadWillTakeArrowAfterParenLeft(ref Lexer lexer) {
	immutable(char)* ptr = lexer.ptr;
	size_t openParens = 0;
	while (true) {
		switch (*ptr) {
			case '(':
				openParens++;
				break;
			case ')':
				openParens--;
				//TODO: allow more or less whitespace
				if (openParens == 0)
					return ptr[1] == ' ' && ptr[2] == '=' && ptr[3] == '>';
				break;
			default:
				if (!isTypeChar(*ptr))
					return false;
		}
		ptr++;
	}
}

bool isAlphaIdentifierStart(char c) =>
	('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';

bool isDigit(char c) =>
	'0' <= c && c <= '9';

bool isAlphaIdentifierContinue(char c) =>
	isAlphaIdentifierStart(c) || c == '-' || isDigit(c);
