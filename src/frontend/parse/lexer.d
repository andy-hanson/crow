module frontend.parse.lexer;

@safe @nogc pure nothrow:

import frontend.diagnosticsBuilder : addDiagnostic, DiagnosticsBuilder;
import frontend.parse.ast : LiteralAst, LiteralIntOrNat, matchLiteralAst, NameAndRange, NameOrUnderscoreOrNone;
import model.diag : Diag;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc, allocateBytes;
import util.cell : Cell, cellGet, cellSet;
import util.collection.arr : arrOfRange, at, begin, empty, first, last;
import util.collection.arrUtil : cat, rtail;
import util.collection.str :
	copyToSafeCStr,
	CStr,
	emptySafeCStr,
	NulTerminatedStr,
	SafeCStr,
	strOfNulTerminatedStr;
import util.conv : safeIntFromUint, safeToUint;
import util.opt : force, has, none, Opt, optOr, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange, FileIndex, Pos, RangeWithinFile;
import util.sym :
	AllSymbols,
	getSymFromAlphaIdentifier,
	isAlphaIdentifierStart,
	isAlphaIdentifierContinue,
	isDigit,
	Operator,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym,
	symForOperator,
	symOfStr;
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
	Ptr!DiagnosticsBuilder diagnosticsBuilderPtr;
	immutable FileIndex fileIndex;
	immutable Sym symUnderscore;
	immutable Sym symForceSendable;
	//TODO:PRIVATE
	public immutable CStr sourceBegin;
	//TODO:PRIVATE
	public CStr ptr;
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
	Ptr!DiagnosticsBuilder diagnosticsBuilder,
	immutable FileIndex fileIndex,
	immutable NulTerminatedStr source,
) {
	// Note: We *are* relying on the nul terminator to stop the lexer.
	immutable string str = strOfNulTerminatedStr(source);
	immutable string useStr = !empty(str) && last(str) == '\n' ? str : rtail(cat!char(alloc.deref(), str, "\n\0"));
	return Lexer(
		alloc,
		allSymbols,
		diagnosticsBuilder,
		fileIndex,
		getSymFromAlphaIdentifier(allSymbols.deref(), "_"),
		getSymFromAlphaIdentifier(allSymbols.deref(), "force-sendable"),
		begin(useStr),
		begin(useStr),
		detectIndentKind(useStr));
}

private immutable(char) curChar(ref const Lexer lexer) {
	return *lexer.ptr;
}

@trusted immutable(Pos) curPos(ref Lexer lexer) {
	// Ensure start is after any whitespace
	while (*lexer.ptr == ' ') lexer.ptr++;
	return posOfPtr(lexer, lexer.ptr);
}

private immutable(Pos) posOfPtr(ref const Lexer lexer, immutable CStr ptr) {
	return safeToUint(ptr - lexer.sourceBegin);
}

void addDiag(ref Lexer lexer, immutable RangeWithinFile range, immutable ParseDiag diag) {
	addDiagnostic(
		lexer.alloc,
		lexer.diagnosticsBuilderPtr.deref(),
		immutable FileAndRange(lexer.fileIndex, range),
		immutable Diag(diag));
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
	if (*lexer.ptr != '\n') {
		//TODO: not always expecting indent..
		addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(ParseDiag.Expected.Kind.indent)));
		skipUntilNewlineNoDiag(lexer);
	}
	verify(*lexer.ptr == '\n');
	lexer.ptr++;
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
		return immutable NameAndRange(start, shortSymAlphaLiteral("bogus"));
	}
}

immutable(Sym) takeName(ref Lexer lexer) {
	return takeNameAndRange(lexer).name;
}

immutable(NameAndRange) takeNameOrOperatorAndRange(ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.name))
		return immutable NameAndRange(start, getCurSym(lexer));
	else if (tryTakeToken(lexer, Token.operator)) {
		return immutable NameAndRange(start, symForOperator(getCurOperator(lexer)));
	} else {
		addDiag(lexer, range(lexer, start), immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.nameOrOperator)));
		return immutable NameAndRange(start, shortSymAlphaLiteral("bogus"));
	}
}

immutable(Sym) takeNameOrOperator(ref Lexer lexer) {
	return takeNameOrOperatorAndRange(lexer).name;
}

immutable(NameOrUnderscoreOrNone) takeNameOrUnderscoreOrNone(ref Lexer lexer) {
	return tryTakeToken(lexer, Token.name)
		? immutable NameOrUnderscoreOrNone(getCurSym(lexer))
		: tryTakeToken(lexer, Token.underscore)
		? immutable NameOrUnderscoreOrNone(immutable NameOrUnderscoreOrNone.Underscore())
		: immutable NameOrUnderscoreOrNone(immutable NameOrUnderscoreOrNone.None());
}

immutable(string) takeQuotedStr(ref Lexer lexer) {
	if (takeOrAddDiagExpectedToken(lexer, Token.quoteDouble, ParseDiag.Expected.Kind.quote)) {
		immutable StringPart sp = takeStringPartAfterDoubleQuote(lexer);
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
	while (*lexer.ptr != '\n') {
		assert(*lexer.ptr != '\0');
		lexer.ptr++;
	}
}

private:

@trusted immutable(SafeCStr) takeRestOfLineAndNewline(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	skipRestOfLineAndNewline(lexer);
	immutable char* end = lexer.ptr - 1;
	return copyToSafeCStr(lexer.alloc, arrOfRange(begin, end));
}

@trusted void skipRestOfLineAndNewline(ref Lexer lexer) {
	skipUntilNewlineNoDiag(lexer);
	lexer.ptr++;
}

// Note: Not issuing any diagnostics here. We'll fail later if we detect the wrong indent kind.
immutable(IndentKind) detectIndentKind(immutable string str) {
	if (empty(str))
		// No indented lines, so it's irrelevant
		return IndentKind.tabs;
	else {
		immutable char c0 = first(str);
		if (c0 == '\t')
			return IndentKind.tabs;
		else if (c0 == ' ') {
			// Count spaces
			uint i = 0;
			for (; i < str.length; i++)
				if (at(str, i) != ' ')
					break;
			// Only allowed amounts are 2 and 4.
			return i == 2 ? IndentKind.spaces2 : IndentKind.spaces4;
		} else {
			foreach (immutable size_t i; 0 .. str.length)
				if (at(str, i) == '\n')
					return detectIndentKind(str[i + 1 .. $]);
			return IndentKind.tabs;
		}
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
	quoteSingle, // "'"
	record, // 'record'
	ref_, // 'ref'
	sendable, // 'sendable'
	spec, // 'spec'
	summon, // 'summon'
	test, // 'test'
	trusted, // 'trusted'
	underscore, // '_'
	union_, // 'union'
	unsafe, // 'unsafe'
}

@trusted public immutable(Token) nextToken(ref Lexer lexer) {
	immutable char c = *lexer.ptr;
	lexer.ptr++;
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
		case '\'':
			return Token.quoteSingle;
		case '"':
			return Token.quoteDouble;
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
			return tryTakeChar(lexer, '=') ? Token.questionEqual : Token.question;
		default:
			if (isAlphaIdentifierStart(c)) {
				immutable string nameStr = takeNameRest(lexer, lexer.ptr - 1);
				immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, nameStr);
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
		case shortSymAlphaLiteralValue("act"):
			return Token.act;
		case shortSymAlphaLiteralValue("alias"):
			return Token.alias_;
		case shortSymAlphaLiteralValue("as"):
			return Token.as;
		case shortSymAlphaLiteralValue("body"):
			return Token.body;
		case shortSymAlphaLiteralValue("builtin"):
			return Token.builtin;
		case shortSymAlphaLiteralValue("builtin-spec"):
			return Token.builtinSpec;
		case shortSymAlphaLiteralValue("data"):
			return Token.data;
		case shortSymAlphaLiteralValue("elif"):
			return Token.elif;
		case shortSymAlphaLiteralValue("else"):
			return Token.else_;
		case shortSymAlphaLiteralValue("enum"):
			return Token.enum_;
		case shortSymAlphaLiteralValue("export"):
			return Token.export_;
		case shortSymAlphaLiteralValue("extern"):
			return Token.extern_;
		case shortSymAlphaLiteralValue("extern-ptr"):
			return Token.externPtr;
		case shortSymAlphaLiteralValue("flags"):
			return Token.flags;
		case shortSymAlphaLiteralValue("force-data"):
			return Token.forceData;
		case shortSymAlphaLiteralValue("fun"):
			return Token.fun;
		case shortSymAlphaLiteralValue("global"):
			return Token.global;
		case shortSymAlphaLiteralValue("if"):
			return Token.if_;
		case shortSymAlphaLiteralValue("import"):
			return Token.import_;
		case shortSymAlphaLiteralValue("match"):
			return Token.match;
		case shortSymAlphaLiteralValue("mut"):
			return Token.mut;
		case shortSymAlphaLiteralValue("noctx"):
			return Token.noCtx;
		case shortSymAlphaLiteralValue("no-std"):
			return Token.noStd;
		case shortSymAlphaLiteralValue("record"):
			return Token.record;
		case shortSymAlphaLiteralValue("ref"):
			return Token.ref_;
		case shortSymAlphaLiteralValue("sendable"):
			return Token.sendable;
		case shortSymAlphaLiteralValue("spec"):
			return Token.spec;
		case shortSymAlphaLiteralValue("summon"):
			return Token.summon;
		case shortSymAlphaLiteralValue("test"):
			return Token.test;
		case shortSymAlphaLiteralValue("trusted"):
			return Token.trusted;
		case shortSymAlphaLiteralValue("union"):
			return Token.union_;
		case shortSymAlphaLiteralValue("unsafe"):
			return Token.unsafe;
		default:
			return a == lexer.symUnderscore
				? Token.underscore
				: a == lexer.symForceSendable
				? Token.forceSendable
				: nameToken(lexer, a);
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
		case Token.quoteSingle:
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
		(immutable(Sym)) => unreachable!(immutable LiteralIntOrNat),
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

immutable(bool) allowedStringPartCharacter(immutable char c, immutable char endQuote) {
	switch (c) {
		case '\n':
		case '\0':
		case '{':
		case endQuote:
			return false;
		default:
			return true;
	}
}

public immutable(Sym) takeSymbolLiteral(ref Lexer lexer) {
	immutable StringPart part = takeStringPart(lexer, '\'');
	final switch (part.after) {
		case StringPart.After.quote:
			return symOfStr(lexer.allSymbols, part.text);
		case StringPart.After.lbrace:
			// Diagnostic: '{' should be escaped to avoid confusion with interpolation
			return todo!(immutable Sym)("!");
	}
}

public immutable(StringPart) takeStringPartAfterDoubleQuote(ref Lexer lexer) {
	return takeStringPart(lexer, '"');
}

@trusted immutable(StringPart) takeStringPart(ref Lexer lexer, immutable char endQuote) {
	immutable CStr begin = lexer.ptr;
	size_t nEscapedCharacters = 0;
	// First get the max size
	while (allowedStringPartCharacter(*lexer.ptr, endQuote)) {
		if (*lexer.ptr == '\\') {
			lexer.ptr++;
			nEscapedCharacters++;
			if (*lexer.ptr == 'x') {
				lexer.ptr++;
				if (allowedStringPartCharacter(*lexer.ptr, endQuote)) {
					lexer.ptr++;
					nEscapedCharacters++;
					if (allowedStringPartCharacter(*lexer.ptr, endQuote)) {
						lexer.ptr++;
						nEscapedCharacters++;
					}
				}
			} else {
				lexer.ptr++;
			}
		} else {
			lexer.ptr++;
		}
	}

	immutable size_t size = (lexer.ptr - begin) - nEscapedCharacters;
	char* res = cast(char*) allocateBytes(lexer.alloc, char.sizeof * size);

	size_t outI = 0;
	lexer.ptr = begin;
	while (allowedStringPartCharacter(*lexer.ptr, endQuote)) {
		if (*lexer.ptr == '\\') {
			lexer.ptr++;
			immutable char c = () {
				immutable char esc = *lexer.ptr;
				switch (esc) {
					case 'x':
						// Take two more
						lexer.ptr++;
						immutable char a = *lexer.ptr;
						lexer.ptr++;
						immutable char b = *lexer.ptr;
						immutable size_t na = toHexDigit(a);
						immutable size_t nb = toHexDigit(b);
						return cast(char) (na * 16 + nb);
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
					case endQuote:
						return endQuote;
					default:
						addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.InvalidStringEscape(esc)));
						return 'a';
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

	immutable StringPart.After after = () {
		switch (*lexer.ptr) {
			case '{':
				return StringPart.After.lbrace;
			case endQuote:
				return StringPart.After.quote;
			default:
				return unreachable!(immutable StringPart.After);
		}
	}();
	lexer.ptr++;
	verify(outI == size);
	return immutable StringPart(cast(immutable) res[0 .. size], after);
}

@trusted immutable(string) takeNameRest(ref Lexer lexer, immutable CStr begin) {
	while (isAlphaIdentifierContinue(*lexer.ptr))
		lexer.ptr++;
	if (*(lexer.ptr - 1) == '-')
		lexer.ptr--;
	else if (*lexer.ptr == '!')
		lexer.ptr++;
	return arrOfRange(begin, lexer.ptr);
}

// Called after the newline
@trusted uint takeIndentAmount(ref Lexer lexer) {
	immutable CStr begin = lexer.ptr;
	if (lexer.indentKind == IndentKind.tabs) {
		while (*lexer.ptr == '\t') lexer.ptr++;
		if (*lexer.ptr == ' ')
			addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.IndentWrongCharacter(true)));
		return safeToUint(lexer.ptr - begin);
	} else {
		immutable Pos start = curPos(lexer);
		while (*lexer.ptr == ' ')
			lexer.ptr++;
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
	return skipBlankLinesAndGetDocCommentRecur(lexer, emptySafeCStr);
}

immutable(SafeCStr) skipBlankLinesAndGetDocCommentRecur(ref Lexer lexer, immutable SafeCStr comment) {
	if (tryTakeChar(lexer, '\n'))
		return skipBlankLinesAndGetDocCommentRecur(lexer, emptySafeCStr);
	else if (tryTakeCStr(lexer, "###\n"))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeBlockComment(lexer));
	else if (tryTakeChar(lexer, '#'))
		return skipBlankLinesAndGetDocCommentRecur(lexer, takeRestOfLineAndNewline(lexer));
	else if (tryTakeCStr(lexer, "region ")) {
		skipRestOfLineAndNewline(lexer);
		return skipBlankLinesAndGetDocCommentRecur(lexer, emptySafeCStr);
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
			skipBlockComment(lexer);
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

@trusted immutable(SafeCStr) takeBlockComment(ref Lexer lexer) {
	immutable char* begin = lexer.ptr;
	skipBlockComment(lexer);
	immutable char* end = lexer.ptr - "\n###\n".length;
	return copyToSafeCStr(lexer.alloc, arrOfRange(begin, end));
}

void skipBlockComment(ref Lexer lexer) {
	skipRestOfLineAndNewline(lexer);
	drop(takeIndentAmount(lexer));
	if (!tryTakeCStr(lexer, "###\n"))
		skipBlockComment(lexer);
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
