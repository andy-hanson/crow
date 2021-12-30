module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralAst, LiteralIntOrNat, matchLiteralAst, NameAndRange, NameOrUnderscoreOrNone;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : arrOfRange, empty;
import util.col.arrBuilder : add, ArrBuilder;
import util.col.str : copyToSafeCStr, CStr, SafeCStr, safeCStr;
import util.col.tempStr : copyTempStrToString, pushToTempStr, TempStr;
import util.conv : safeIntFromUint, safeToUint;
import util.opt : force, has, none, Opt, optOr, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym :
	AllSymbols,
	Operator,
	shortSym,
	shortSymValue,
	SpecialSym,
	specialSymValue,
	Sym,
	symForOperator,
	symOfStrCrowIdentifier;
import util.util : drop, todo, unreachable, verify;

private enum IndentKind {
	tabs,
	spaces2,
	spaces4,
}

struct Lexer {
	private:
	Ptr!Alloc allocPtr;
	Ptr!AllSymbols allSymbolsPtr;
	Ptr!(ArrBuilder!DiagnosticWithinFile) diagnosticsBuilderPtr;
	immutable CStr sourceBegin;
	CStr ptr;
	immutable IndentKind indentKind;
	union {
		bool ignore;
		Cell!Sym curSym; // For Token.name
		Cell!Operator curOperator;
		Cell!LiteralAst curLiteral; // for Token.literal
	}
}

ref Alloc alloc(return scope ref Lexer lexer) {
	return lexer.allocPtr.deref();
}

ref AllSymbols allSymbols(return scope ref Lexer lexer) {
	return lexer.allSymbolsPtr.deref();
}

@trusted Lexer createLexer(
	Ptr!Alloc alloc,
	Ptr!AllSymbols allSymbols,
	Ptr!(ArrBuilder!DiagnosticWithinFile) diagnosticsBuilder,
	immutable SafeCStr source,
) {
	return Lexer(
		alloc,
		allSymbols,
		diagnosticsBuilder,
		source.ptr,
		source.ptr,
		detectIndentKind(source));
}

private immutable(char) curChar(ref const Lexer lexer) {
	return *lexer.ptr;
}

@trusted immutable(Pos) curPos(ref Lexer lexer) {
	// Ensure start is after any whitespace
	while (tryTakeChar(lexer, ' ')) {}
	return posOfPtr(lexer, lexer.ptr);
}

private immutable(Pos) posOfPtr(ref const Lexer lexer, immutable CStr ptr) {
	return safeToUint(ptr - lexer.sourceBegin);
}

void addDiag(ref Lexer lexer, immutable RangeWithinFile range, immutable ParseDiag diag) {
	add(lexer.alloc, lexer.diagnosticsBuilderPtr.deref(), immutable DiagnosticWithinFile(range, immutable Diag(diag)));
}

void addDiagAtChar(ref Lexer lexer, immutable ParseDiag diag) {
	immutable Pos a = curPos(lexer);
	addDiag(lexer, immutable RangeWithinFile(a, curChar(lexer) == '\0' ? a : a + 1), diag);
}

private void addDiagAtCurToken(ref Lexer lexer, immutable Pos start, immutable ParseDiag diag) {
	addDiag(lexer, range(lexer, start), diag);
}

void addDiagUnexpectedCurToken(ref Lexer lexer, immutable Pos start, immutable Token token) {
	immutable ParseDiag diag = () @trusted {
		switch (token) {
			case Token.invalid:
				return immutable ParseDiag(immutable ParseDiag.UnexpectedCharacter(*(lexer.ptr - 1)));
			case Token.operator:
				return immutable ParseDiag(immutable ParseDiag.UnexpectedOperator(getCurOperator(lexer)));
			default:
				return immutable ParseDiag(immutable ParseDiag.UnexpectedToken(token));
		}
	}();
	addDiagAtCurToken(lexer, start, diag);
}

// WARN: Caller should check for '\0'
private @system immutable(char) takeChar(ref Lexer lexer) {
	immutable char res = *lexer.ptr;
	lexer.ptr++;
	return res;
}

private @trusted immutable(bool) tryTakeChar(ref Lexer lexer, immutable char c) {
	if (*lexer.ptr == c) {
		lexer.ptr++;
		return true;
	} else
		return false;
}

private @trusted immutable(bool) tryTakeCStr(ref Lexer lexer, immutable CStr c) {
	CStr ptr2 = lexer.ptr;
	for (CStr cptr = c; *cptr != 0; cptr++) {
		if (*ptr2 != *cptr)
			return false;
		ptr2++;
	}
	lexer.ptr = ptr2;
	return true;
}

immutable(bool) takeOrAddDiagExpectedToken(
	ref Lexer lexer,
	immutable Token token,
	immutable ParseDiag.Expected.Kind kind,
) {
	immutable bool res = tryTakeToken(lexer, token);
	if (!res)
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(kind)));
	return res;
}

void addDiagExpected(ref Lexer lexer, immutable ParseDiag.Expected.Kind kind) {
	addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(kind)));
}

immutable(bool) takeOrAddDiagExpectedOperator(
	ref Lexer lexer,
	immutable Operator operator,
	immutable ParseDiag.Expected.Kind kind,
) {
	immutable bool res = tryTakeOperator(lexer, operator);
	if (!res)
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(kind)));
	return res;
}

enum NewlineOrIndent {
	newline,
	indent,
}

immutable(NewlineOrIndent) takeNewlineOrIndent_topLevel(ref Lexer lexer) {
	if (!takeOrAddDiagExpectedToken(lexer, Token.newline, ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, 0);
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

immutable(bool) takeIndentOrDiagTopLevel(ref Lexer lexer) {
	return takeIndentOrFailGeneric!(immutable bool)(
		lexer,
		0,
		() => true,
		(immutable RangeWithinFile, immutable uint dedent) {
			verify(dedent == 0);
			return false;
		});
}

immutable(bool) tryTakeIndent(ref Lexer lexer, immutable uint curIndent) {
	//TODO: always have cur token handy, no need to back up
	immutable char* begin = lexer.ptr;
	if (nextToken(lexer) == Token.newline) {
		immutable IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		return matchIndentDelta!(immutable bool)(
			delta,
			(ref immutable IndentDelta.DedentOrSame dedent) {
				addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
				lexer.ptr = begin;
				return false;
			},
			(ref immutable IndentDelta.Indent) =>
				true);
	} else {
		lexer.ptr = begin;
		return false;
	}
}

immutable(T) takeIndentOrFailGeneric(T)(
	ref Lexer lexer,
	immutable uint curIndent,
	scope immutable(T) delegate() @safe @nogc pure nothrow cbIndent,
	scope immutable(T) delegate(immutable RangeWithinFile, immutable uint) @safe @nogc pure nothrow cbFail,
) {
	immutable Pos start = curPos(lexer);
	immutable IndentDelta delta = takeNewlineAndReturnIndentDelta(lexer, curIndent);
	return matchIndentDelta!(immutable T)(
		delta,
		(ref immutable IndentDelta.DedentOrSame dedent) {
			addDiag(
				lexer,
				immutable RangeWithinFile(start, start + 1),
				immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
			return cbFail(range(lexer, start), dedent.nDedents);
		},
		(ref immutable IndentDelta.Indent) {
			return cbIndent();
		});
}

private @trusted immutable(IndentDelta) takeNewlineAndReturnIndentDelta(ref Lexer lexer, immutable uint curIndent) {
	if (!tryTakeChar(lexer, '\n')) {
		//TODO: not always expecting indent..
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipRestOfLineAndNewline(lexer);
	}
	return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
}

void takeDedentFromIndent1(ref Lexer lexer) {
	immutable IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, 1);
	immutable bool success = matchIndentDelta!(immutable bool)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) =>
			it.nDedents == 1,
		(ref immutable IndentDelta.Indent) =>
			false);
	if (!success) {
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.dedent)));
		skipRestOfLineAndNewline(lexer);
		takeDedentFromIndent1(lexer);
	}
}

immutable(uint) takeNewlineOrDedentAmount(ref Lexer lexer, immutable uint curIndent) {
	// Must be at the end of a line
	if (!takeOrAddDiagExpectedToken(lexer, Token.newline, ParseDiag.Expected.Kind.endOfLine))
		skipRestOfLineAndNewline(lexer);
	immutable IndentDelta delta = skipBlankLinesAndGetIndentDelta(lexer, curIndent);
	return matchIndentDelta!(immutable uint)(
		delta,
		(ref immutable IndentDelta.DedentOrSame it) {
			return it.nDedents;
		},
		(ref immutable IndentDelta.Indent) {
			addDiagAtChar(lexer, immutable ParseDiag(
				immutable ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.indent)));
			skipUntilNewlineNoDiag(lexer);
			return takeNewlineOrDedentAmount(lexer, curIndent);
		});
}

enum NewlineOrDedent {
	newline,
	dedent,
}

immutable(NewlineOrDedent) takeNewlineOrSingleDedent(ref Lexer lexer) {
	switch (takeNewlineOrDedentAmount(lexer, 1)) {
		case 0:
			return NewlineOrDedent.newline;
		case 1:
			return NewlineOrDedent.dedent;
		default:
			return unreachable!NewlineOrDedent;
	}
}

immutable(RangeWithinFile) range(ref Lexer lexer, immutable Pos begin) {
	verify(begin <= curPos(lexer));
	return immutable RangeWithinFile(begin, curPos(lexer));
}

immutable(NameAndRange) takeNameAndRange(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.name))
		return immutable NameAndRange(start, getCurSym(lexer));
	else {
		addDiag(lexer, range(lexer, start), immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.name)));
		return immutable NameAndRange(start, shortSym("bogus"));
	}
}

immutable(Sym) takeName(ref Lexer lexer) {
	return takeNameAndRange(lexer).name;
}

immutable(Opt!NameAndRange) tryTakeNameOrOperatorAndRange(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	return tryTakeToken(lexer, Token.name)
		? some(immutable NameAndRange(start, getCurSym(lexer)))
		: tryTakeToken(lexer, Token.operator)
		? some(immutable NameAndRange(start, symForOperator(getCurOperator(lexer))))
		: none!NameAndRange;
}

immutable(Sym) takeNameOrOperator(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable Opt!NameAndRange res = tryTakeNameOrOperatorAndRange(lexer);
	if (has(res))
		return force(res).name;
	else {
		addDiag(lexer, range(lexer, start), immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.nameOrOperator)));
		return shortSym("bogus");
	}
}

immutable(NameOrUnderscoreOrNone) takeNameOrUnderscoreOrNone(ref Lexer lexer) {
	return tryTakeToken(lexer, Token.name)
		? immutable NameOrUnderscoreOrNone(getCurSym(lexer))
		: tryTakeToken(lexer, Token.underscore)
		? immutable NameOrUnderscoreOrNone(immutable NameOrUnderscoreOrNone.Underscore())
		: immutable NameOrUnderscoreOrNone(immutable NameOrUnderscoreOrNone.None());
}

immutable(string) takeQuotedStr(ref Lexer lexer) {
	if (takeOrAddDiagExpectedToken(lexer, Token.quoteDouble, ParseDiag.Expected.Kind.quoteDouble)) {
		immutable StringPart sp = takeStringPart(lexer, QuoteKind.double_);
		final switch (sp.after) {
			case StringPart.After.quote:
				return sp.text;
			case StringPart.After.lbrace:
				return todo!(immutable string)("!");
		}
	} else
		return "";
}

@trusted void skipUntilNewlineNoDiag(ref Lexer lexer) {
	while (*lexer.ptr != '\n' && *lexer.ptr != '\0')
		lexer.ptr++;
}

private:

@trusted immutable(SafeCStr) takeRestOfLineAndNewline(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	skipRestOfLineAndNewline(lexer);
	immutable char* end = lexer.ptr - 1;
	return copyToSafeCStr(lexer.alloc, arrOfRange(begin, end));
}

void skipRestOfLineAndNewline(ref Lexer lexer) {
	skipUntilNewlineNoDiag(lexer);
	drop(tryTakeChar(lexer, '\n'));
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
@trusted immutable(IndentKind) detectIndentKind(immutable SafeCStr a) {
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
			immutable size_t n = ptr - a.ptr;
			// Only allowed amounts are 2 and 4.
			return n == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
		default:
			while (*ptr != '\0' && *ptr != '\n')
				ptr++;
			if (*ptr == '\n') ptr++;
			return detectIndentKind(immutable SafeCStr(ptr));
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
	atLess, // '!<'
	body, // 'body'
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
	data, // 'data'
	dot, // '.'
	// '..' is Operator.range
	dot3, // '...'
	elif, // 'elif'
	else_, // 'else'
	enum_, // 'enum'
	equal, // '='
	extern_, // 'extern'
	externPtr, // 'extern-ptr'
	EOF, // end of file
	export_, // 'export'
	flags, // 'flags'
	forceData, // 'force-data'
	forceSendable, // 'force-sendable'
	fun, // 'fun'
	global, // 'global'
	if_, // 'if'
	import_, // 'import'
	invalid, // invalid token (e.g. illegal character)
	literal, // Use getCurLiteral
	match, // 'match'
	mut, // 'mut'
	name, // Any non-keyword, non-operator name; use getCurSym with this
	newline, // end of line
	noCtx, // 'noctx'
	noStd, // 'no-std'
	operator, // Any operator; use getCurOperator with this
	parenLeft, // '('
	parenRight, // ')'
	question, // '?'
	questionEqual, // '?='
	quoteDouble, // '"'
	quoteDouble3, // '"""'
	record, // 'record'
	ref_, // 'ref'
	sendable, // 'sendable'
	spec, // 'spec'
	summon, // 'summon'
	test, // 'test'
	trusted, // 'trusted'
	underscore, // '_'
	union_, // 'union'
	unless, // 'unless'
	unsafe, // 'unsafe'
}

@trusted public immutable(Token) nextToken(ref Lexer lexer) {
	immutable char c = takeChar(lexer);
	switch (c) {
		case '\0':
			lexer.ptr--;
			return Token.EOF;
		case ' ':
			return nextToken(lexer);
		case '\n':
			return Token.newline;
		case '~':
			return operatorToken(lexer, tryTakeChar(lexer, '=') ? Operator.concatEquals : Operator.tilde);
		case '@':
			return tryTakeChar(lexer, '<')
				? Token.atLess
				: Token.invalid;
		case '!':
			return operatorToken(lexer, tryTakeChar(lexer, '=') ? Operator.notEqual : Operator.not);
		case '^':
			return operatorToken(lexer, Operator.xor1);
		case '&':
			return operatorToken(lexer, tryTakeChar(lexer, '&') ? Operator.and2 : Operator.and1);
		case '*':
			return operatorToken(lexer, tryTakeChar(lexer, '*') ? Operator.exponent : Operator.times);
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
				? literalToken(lexer, takeNumberAfterSign(lexer, some(Sign.minus)))
				: tryTakeChar(lexer, '>')
				? Token.arrowAccess
				: operatorToken(lexer, Operator.minus);
		case '=':
			return tryTakeChar(lexer, '>')
				? Token.arrowLambda
				: tryTakeChar(lexer, '=')
				? operatorToken(lexer, Operator.equal)
				: Token.equal;
		case '+':
			return isDigit(*lexer.ptr)
				? literalToken(lexer, takeNumberAfterSign(lexer, some(Sign.plus)))
				: operatorToken(lexer, Operator.plus);
		case '|':
			return operatorToken(lexer, tryTakeChar(lexer, '|') ? Operator.or2 : Operator.or1);
		case ':':
			return tryTakeChar(lexer, '=')
				? Token.colonEqual
				: tryTakeChar(lexer, ':')
				? Token.colon2
				: Token.colon;
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
					? tryTakeChar(lexer, '>') ? Operator.compare : Operator.lessOrEqual
					: tryTakeChar(lexer, '<')
					? Operator.shiftLeft
					: Operator.less);
		case '>':
			return operatorToken(lexer, tryTakeChar(lexer, '=')
				? Operator.greaterOrEqual
				: tryTakeChar(lexer, '>')
				? Operator.shiftRight
				: Operator.greater);
		case '.':
			return tryTakeChar(lexer, '.')
				? tryTakeChar(lexer, '.') ? Token.dot3 : operatorToken(lexer, Operator.range)
				: Token.dot;
		case '/':
			return operatorToken(lexer, Operator.divide);
		case '?':
			return tryTakeChar(lexer, '=')
				? Token.questionEqual
				: tryTakeChar(lexer, '?')
				? operatorToken(lexer, Operator.question2)
				: Token.question;
		default:
			if (isAlphaIdentifierStart(c)) {
				immutable string nameStr = takeNameRest(lexer, lexer.ptr - 1);
				immutable Sym name = symOfStrCrowIdentifier(lexer.allSymbols, nameStr);
				return tokenForSym(lexer, name);
			} else if (isDigit(c)) {
				backUp(lexer);
				return literalToken(lexer, takeNumberAfterSign(lexer, none!Sign));
			} else
				return Token.invalid;
	}
}

immutable(Token) tokenForSym(ref Lexer lexer, immutable Sym a) {
	switch (a.value) {
		case shortSymValue("act"):
			return Token.act;
		case shortSymValue("alias"):
			return Token.alias_;
		case shortSymValue("as"):
			return Token.as;
		case shortSymValue("body"):
			return Token.body;
		case shortSymValue("builtin"):
			return Token.builtin;
		case shortSymValue("builtin-spec"):
			return Token.builtinSpec;
		case shortSymValue("data"):
			return Token.data;
		case shortSymValue("elif"):
			return Token.elif;
		case shortSymValue("else"):
			return Token.else_;
		case shortSymValue("enum"):
			return Token.enum_;
		case shortSymValue("export"):
			return Token.export_;
		case shortSymValue("extern"):
			return Token.extern_;
		case shortSymValue("extern-ptr"):
			return Token.externPtr;
		case shortSymValue("flags"):
			return Token.flags;
		case shortSymValue("force-data"):
			return Token.forceData;
		case shortSymValue("fun"):
			return Token.fun;
		case shortSymValue("global"):
			return Token.global;
		case shortSymValue("if"):
			return Token.if_;
		case shortSymValue("import"):
			return Token.import_;
		case shortSymValue("match"):
			return Token.match;
		case shortSymValue("mut"):
			return Token.mut;
		case shortSymValue("noctx"):
			return Token.noCtx;
		case shortSymValue("no-std"):
			return Token.noStd;
		case shortSymValue("record"):
			return Token.record;
		case shortSymValue("ref"):
			return Token.ref_;
		case shortSymValue("sendable"):
			return Token.sendable;
		case shortSymValue("spec"):
			return Token.spec;
		case shortSymValue("summon"):
			return Token.summon;
		case shortSymValue("test"):
			return Token.test;
		case shortSymValue("trusted"):
			return Token.trusted;
		case shortSymValue("unless"):
			return Token.unless;
		case shortSymValue("union"):
			return Token.union_;
		case shortSymValue("unsafe"):
			return Token.unsafe;
		case shortSymValue("_"):
			return Token.underscore;
		case specialSymValue(SpecialSym.force_sendable):
			return Token.forceSendable;
		default:
			return nameToken(lexer, a);
	}
}

immutable(Token) nameToken(ref Lexer lexer, immutable Sym a) {
	cellSet(lexer.curSym, a);
	return Token.name;
}

immutable(Token) operatorToken(ref Lexer lexer, immutable Operator a) {
	cellSet(lexer.curOperator, a);
	return Token.operator;
}

@trusted immutable(Token) literalToken(ref Lexer lexer, immutable LiteralAst a) {
	cellSet(lexer.curLiteral, a);
	return Token.literal;
}


public immutable(Sym) getCurSym(ref Lexer lexer) {
	//TODO: assert that cur token is Token.name
	return cellGet(lexer.curSym);
}

public immutable(NameAndRange) getCurNameAndRange(ref Lexer lexer, immutable Pos start) {
	return immutable NameAndRange(start, getCurSym(lexer));
}

public immutable(Operator) getCurOperator(ref Lexer lexer) {
	return cellGet(lexer.curOperator);
}

@trusted public immutable(LiteralAst) getCurLiteral(ref Lexer lexer) {
	//TODO: assert that cur token is Token.literal
	return cellGet(lexer.curLiteral);
}

public immutable(bool) tryTakeToken(ref Lexer lexer, immutable Token expected) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	immutable Token actual = nextToken(lexer);
	if (actual == expected)
		return true;
	else {
		lexer.ptr = before;
		return false;
	}
}

public immutable(bool) tryTakeOperator(ref Lexer lexer, immutable Operator expected) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	immutable Token actual = nextToken(lexer);
	if (actual == Token.operator && getCurOperator(lexer) == expected)
		return true;
	else {
		lexer.ptr = before;
		return false;
	}
}

public void takeTypeArgsEnd(ref Lexer lexer) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable Pos start = curPos(lexer);
	immutable char* before = lexer.ptr;
	immutable Token actual = nextToken(lexer);
	void fail() {
		lexer.ptr = before;
		addDiagAtCurToken(lexer, start, immutable ParseDiag(immutable ParseDiag.Expected(
			ParseDiag.Expected.Kind.typeArgsEnd)));
	}
	if (actual == Token.operator) {
		switch (getCurOperator(lexer)) {
			case Operator.greater:
				break;
			case Operator.shiftRight:
				backUp(lexer);
				break;
			default:
				fail();
				break;
		}
	} else
		fail();
}

public immutable(Token) getPeekToken(ref Lexer lexer) {
	//TODO: always have the next token ready, so we don't need to repeatedly lex the same token
	immutable char* before = lexer.ptr;
	immutable Token res = nextToken(lexer);
	lexer.ptr = before;
	return res;
}

public immutable(bool) peekToken(ref Lexer lexer, immutable Token expected) {
	return getPeekToken(lexer) == expected;
}

public immutable(bool) peekTokenExpression(ref Lexer lexer) {
	return isExpressionStartToken(getPeekToken(lexer));
}

// Whether a token may start an expression
immutable(bool) isExpressionStartToken(immutable Token a) {
	final switch (a) {
		case Token.act:
		case Token.alias_:
		case Token.arrowAccess:
		case Token.arrowLambda:
		case Token.arrowThen:
		case Token.as:
		case Token.atLess:
		case Token.body:
		case Token.builtin:
		case Token.builtinSpec:
		case Token.braceLeft:
		case Token.braceRight:
		case Token.bracketRight:
		case Token.colon:
		case Token.colon2:
		case Token.colonEqual:
		case Token.comma:
		case Token.data:
		case Token.dot:
		case Token.dot3:
		case Token.elif:
		case Token.else_:
		case Token.enum_:
		case Token.equal:
		case Token.export_:
		case Token.extern_:
		case Token.externPtr:
		case Token.EOF:
		case Token.flags:
		case Token.forceData:
		case Token.forceSendable:
		case Token.fun:
		case Token.global:
		case Token.import_:
		case Token.invalid:
		case Token.mut:
		case Token.newline:
		case Token.noCtx:
		case Token.noStd:
		case Token.parenRight:
		case Token.question:
		case Token.questionEqual:
		case Token.record:
		case Token.ref_:
		case Token.sendable:
		case Token.spec:
		case Token.summon:
		case Token.test:
		case Token.trusted:
		case Token.underscore:
		case Token.union_:
		case Token.unsafe:
			return false;
		case Token.bracketLeft:
		case Token.if_:
		case Token.literal:
		case Token.match:
		case Token.name:
		case Token.operator:
		case Token.parenLeft:
		case Token.quoteDouble:
		case Token.quoteDouble3:
		case Token.unless:
			return true;
	}
}

immutable(RangeWithinFile) range(ref Lexer lexer, immutable CStr begin) {
	verify(begin >= lexer.sourceBegin);
	return range(lexer, safeToUint(begin - lexer.sourceBegin));
}

enum Sign {
	plus,
	minus,
}

public @trusted immutable(LiteralIntOrNat) takeIntOrNat(ref Lexer lexer) {
	while (tryTakeChar(lexer, ' ')) {}
	immutable Opt!Sign sign = tryTakeChar(lexer, '+')
		? some(Sign.plus)
		: tryTakeChar(lexer, '-')
		? some(Sign.minus)
		: none!Sign;
	immutable LiteralAst res = takeNumberAfterSign(lexer, sign);
	return matchLiteralAst!(
		LiteralIntOrNat,
		(immutable LiteralAst.Float) => todo!(immutable LiteralIntOrNat)("no float in enum"),
		(immutable LiteralAst.Int i) => immutable LiteralIntOrNat(i),
		(immutable LiteralAst.Nat n) => immutable LiteralIntOrNat(n),
		(immutable(string)) => unreachable!(immutable LiteralIntOrNat),
	)(res);
}

@trusted immutable(LiteralAst) takeNumberAfterSign(ref Lexer lexer, immutable Opt!Sign sign) {
	immutable ulong base = tryTakeCStr(lexer, "0x")
		? 16
		: tryTakeCStr(lexer, "0o")
		? 8
		: tryTakeCStr(lexer, "0b")
		? 2
		: 10;
	immutable LiteralAst.Nat n = takeNat(lexer, base);
	if (*lexer.ptr == '.' && isDigit(*(lexer.ptr + 1))) {
		lexer.ptr++;
		return immutable LiteralAst(takeFloat(lexer, optOr!Sign(sign, () => Sign.plus), n, base));
	} else if (has(sign))
		final switch (force(sign)) {
			case Sign.plus:
				return immutable LiteralAst(immutable LiteralAst.Int(n.value, n.value > long.max));
			case Sign.minus:
				return immutable LiteralAst(immutable LiteralAst.Int(-n.value, n.value > (cast(ulong) long.max) + 1));
		}
	else
		return immutable LiteralAst(n);
}

@system immutable(LiteralAst.Float) takeFloat(
	ref Lexer lexer,
	immutable Sign sign,
	ref immutable LiteralAst.Nat natPart,
	immutable ulong base,
) {
	// TODO: improve accuracy
	const char *cur = lexer.ptr;
	immutable LiteralAst.Nat rest = takeNat(lexer, base);
	immutable bool overflow = natPart.overflow || rest.overflow;
	immutable ulong power = lexer.ptr - cur;
	immutable double multiplier = pow(1.0, 1.0 / base, power);
	immutable double floatSign = () {
		final switch (sign) {
			case Sign.minus:
				return -1.0;
			case Sign.plus:
				return 1.0;
		}
	}();
	immutable double f = floatSign * (natPart.value + (rest.value * multiplier));
	return immutable LiteralAst.Float(f, overflow);
}

immutable(double) pow(immutable double acc, immutable double base, immutable ulong power) {
	return power == 0 ? acc : pow(acc * base, base, power - 1);
}

//TODO: overflow bug possible here
immutable(ulong) getDivisor(immutable ulong acc, immutable ulong a, immutable ulong base) {
	return acc < a ? getDivisor(acc * base, a, base) : acc;
}

@system immutable(LiteralAst.Nat) takeNat(ref Lexer lexer, immutable ulong base) {
	return takeNatRecur(lexer, base, 0, false);
}

@system immutable(LiteralAst.Nat) takeNatRecur(
	ref Lexer lexer,
	immutable ulong base,
	immutable ulong value,
	immutable bool overflow,
) {
	immutable ulong digit = charToNat(*lexer.ptr);
	if (digit < base) {
		lexer.ptr++;
		immutable ulong newValue = value * base + digit;
		drop(tryTakeChar(lexer, '_'));
		return takeNatRecur(lexer, base, newValue, overflow || newValue / base != value);
	} else
		return immutable LiteralAst.Nat(value, overflow);
}

immutable(ulong) charToNat(immutable char c) {
	return '0' <= c && c <= '9'
		? c - '0'
		: 'a' <= c && c <= 'f'
		? 10 + (c - 'a')
		: 'A' <= c && c <= 'F'
		? 10 + (c - 'A')
		: ulong.max;
}

immutable(size_t) toHexDigit(immutable char c) {
	if ('0' <= c && c <= '9')
		return c - '0';
	else if ('a' <= c && c <= 'f')
		return 10 + c - 'a';
	else
		return todo!size_t("parse diagnostic -- bad hex digit");
}

public struct StringPart {
	immutable string text;
	immutable After after;

	enum After {
		quote,
		lbrace,
	}
}

public enum QuoteKind {
	double_,
	double3,
}

public @trusted immutable(StringPart) takeStringPart(ref Lexer lexer, immutable QuoteKind quoteKind) {
	TempStr!0x10000 res;
	immutable StringPart.After after = () {
		while (true) {
			immutable char x = takeChar(lexer);
			switch(x) {
				case '"':
					final switch (quoteKind) {
						case QuoteKind.double_:
							return StringPart.After.quote;
						case QuoteKind.double3:
							if (tryTakeCStr(lexer, "\"\""))
								return StringPart.After.quote;
							else
								pushToTempStr(res, '"');
							break;
					}
					break;
				case '\n':
					final switch (quoteKind) {
						case QuoteKind.double_:
							addDiagExpected(lexer, ParseDiag.Expected.Kind.quoteDouble);
							return StringPart.After.quote;
						case QuoteKind.double3:
							pushToTempStr(res, '\n');
							break;
					}
					break;
				case '\0':
					immutable ParseDiag.Expected.Kind expected = () {
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
					immutable char escapeCode = takeChar(lexer);
					immutable char escaped = () {
						switch (escapeCode) {
							case 'x':
								immutable size_t digit0 = toHexDigit(takeChar(lexer));
								immutable size_t digit1 = toHexDigit(takeChar(lexer));
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
								addDiagAtChar(lexer, immutable ParseDiag(
									immutable ParseDiag.InvalidStringEscape(escapeCode)));
								return 'a';
						}
					}();
					pushToTempStr(res, escaped);
					break;
				default:
					pushToTempStr(res, x);
			}
		}
	}();
	return immutable StringPart(copyTempStrToString(lexer.alloc, res), after);
}

@trusted immutable(string) takeNameRest(ref Lexer lexer, immutable CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*(lexer.ptr - 1) == '-')
		lexer.ptr--;
	return arrOfRange(begin, lexer.ptr);
}

// Called after the newline
@trusted uint takeIndentAmount(ref Lexer lexer) {
	immutable CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (tryTakeChar(lexer, '\t')) {}
		if (*lexer.ptr == ' ')
			addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(true)));
		return safeToUint(lexer.ptr - begin);
	} else {
		immutable Pos start = curPos(lexer);
		while (tryTakeChar(lexer, ' ')) {}
		if (*lexer.ptr == '\t')
			addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(false)));
		immutable uint nSpaces = safeToUint(lexer.ptr - begin);
		immutable uint nSpacesPerIndent = lexer.indentKind == IndentKind.spaces2 ? 2 : 4;
		immutable uint res = nSpaces / nSpacesPerIndent;
		if (res * nSpacesPerIndent != nSpaces)
			addDiag(lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.IndentNotDivisible(nSpaces, nSpacesPerIndent)));
		return res;
	}
}

struct IndentDelta {
	@safe @nogc pure nothrow:

	struct DedentOrSame {
		immutable uint nDedents;
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

@trusted T matchIndentDelta(T)(
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

public immutable(SafeCStr) skipBlankLinesAndGetDocComment(ref Lexer lexer) {
	return skipBlankLinesAndGetDocCommentRecur(lexer, safeCStr!"");
}

immutable(SafeCStr) skipBlankLinesAndGetDocCommentRecur(ref Lexer lexer, immutable SafeCStr comment) {
	if (tryTakeChar(lexer, '\n'))
		return skipBlankLinesAndGetDocCommentRecur(lexer, safeCStr!"");
	else if (tryTakeCStr(lexer, "###\n"))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeRestOfBlockComment(lexer));
	else if (tryTakeChar(lexer, '#'))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeRestOfLineAndNewline(lexer));
	else if (tryTakeCStr(lexer, "region ")) {
		skipRestOfLineAndNewline(lexer);
		return skipBlankLinesAndGetDocCommentRecur(lexer, safeCStr!"");
	} else
		return comment;
}

// Returns the change in indent (and updates the indent)
// Note: does nothing if not looking at a newline!
// NOTE: never returns a value > 1 as double-indent is always illegal.
immutable(IndentDelta) skipBlankLinesAndGetIndentDelta(ref Lexer lexer, immutable uint curIndent) {
	// comment / region counts as a blank line no matter its indent level.
	immutable uint newIndent = takeIndentAmount(lexer);
	if (tryTakeChar(lexer, '\n'))
		// Ignore lines that are just whitespace
		return skipBlankLinesAndGetIndentDelta(lexer, curIndent);

	// For indent == 0, we'll try taking any comments as doc comments
	if (newIndent != 0) {
		// Comments can mean a dedent
		if (tryTakeCStr(lexer, "###\n")) {
			skipRestOfBlockComment(lexer);
			return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		} else if (tryTakeChar(lexer, '#')) {
			skipRestOfLineAndNewline(lexer);
			return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
		}
	}

	// If we got here, we're looking at a non-empty line (or EOF)
	immutable int delta = safeIntFromUint(newIndent) - safeIntFromUint(curIndent);
	if (delta > 1) {
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.IndentTooMuch()));
		skipRestOfLineAndNewline(lexer);
		return skipBlankLinesAndGetIndentDelta(lexer, curIndent);
	} else
		return delta == 1
			? immutable IndentDelta(immutable IndentDelta.Indent())
			: immutable IndentDelta(immutable IndentDelta.DedentOrSame(-delta));
}

@trusted immutable(SafeCStr) takeRestOfBlockComment(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	skipRestOfBlockComment(lexer);
	immutable char* end = lexer.ptr - "\n###\n".length;
	return copyToSafeCStr(lexer.alloc, arrOfRange(begin, end));
}

@trusted void skipRestOfBlockComment(ref Lexer lexer) {
	skipRestOfLineAndNewline(lexer);
	while (tryTakeChar(lexer, '\t') || tryTakeChar(lexer, ' ')) {}
	if (!tryTakeCStr(lexer, "###\n")) {
		if (*lexer.ptr == '\0')
			addDiagExpected(lexer, ParseDiag.Expected.Kind.blockCommentEnd);
		else
			skipRestOfBlockComment(lexer);
	}
}

public @trusted immutable(bool) lookaheadWillTakeEqualsOrThen(ref Lexer lexer) {
	immutable(char)* ptr = lexer.ptr;
	while (true) {
		switch (*ptr) {
			case ' ':
				if ((ptr[1] == '=' && ptr[2] == ' ') || (ptr[1] == '<' && ptr[2] == '-' && ptr[3] == ' '))
					return true;
				break;
			// characters that appear in typse
			case '<':
			case '>':
			case ',':
			case '?':
			case '*':
			case '[':
			case ']':
			case '(':
			case ')':
				break;
			default:
				if (!isAlphaIdentifierContinue(*ptr))
					return false;
				break;
		}
		ptr++;
	}
}

public @trusted immutable(bool) lookaheadWillTakeArrow(ref Lexer lexer) {
	immutable(char)* ptr = lexer.ptr;
	while (true) {
		switch (*ptr) {
			case '(':
				// Arrow function parameters never have '(' in them
				return false;
			case ')':
				return ptr[1] == ' ' && ptr[2] == '=' && ptr[3] == '>';
			case '\n':
			case '\0':
				return false;
			default:
				break;
		}
		ptr++;
	}
}

immutable(bool) isAlphaIdentifierStart(immutable char c) {
	return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';
}

immutable(bool) isDigit(immutable char c) {
	return '0' <= c && c <= '9';
}

immutable(bool) isAlphaIdentifierContinue(immutable char c) {
	return isAlphaIdentifierStart(c) || c == '-' || isDigit(c);
}
