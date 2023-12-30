module frontend.parse.lexToken;

@safe @nogc pure nothrow:

import frontend.parse.lexUtil : isDecimalDigit, startsWith, takeChar, tryGetAfterStartsWith, tryTakeChar, tryTakeChars;
import frontend.parse.lexWhitespace : DocCommentAndIndentDelta, IndentKind, skipBlankLinesAndGetIndentDelta;
import model.ast : LiteralFloatAst, LiteralIntAst, LiteralNatAst;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.opt : force, has, none, Opt, optOrDefault, some;
import util.string : CString, MutCString, SmallString, stringOfRange;
import util.symbol : AllSymbols, appendEquals, Symbol, symbol, symbolOfString;
import util.util : todo;

immutable struct DocCommentAndExtraDedents {
	SmallString docComment;
	uint extraDedents;
}

immutable struct TokenAndData {
	@safe @nogc pure nothrow:

	Token token;
	private:
	union {
		Symbol symbol = void; // For Token.name or Token.operator
		// For Token.newline or Token.EOF. WARN: The string is temporary.
		DocCommentAndExtraDedents docComment = void;
		LiteralFloatAst literalFloat = void; // for Token.literalFloat
		LiteralIntAst literalInt = void; // for Token.literalInt
		LiteralNatAst literalNat = void; // for Token.literalNat
		char unexpectedCharacter;
	}

	public:
	this(Token t, bool) {
		assert(!isSymbolToken(t) &&
			!isNewlineToken(t) &&
			t != Token.literalFloat &&
			t != Token.literalInt &&
			t != Token.literalNat);
		token = t;
	}
	this(Token t, Symbol s) {
		assert(isSymbolToken(t));
		token = t;
		symbol = s;
	}
	this(Token t, DocCommentAndExtraDedents d) {
		assert(isNewlineToken(t));
		token = t;
		docComment = d;
	}
	this(Token t, LiteralFloatAst l) {
		assert(t == Token.literalFloat);
		token = t;
		literalFloat = l;
	}
	this(Token t, LiteralIntAst l) {
		assert(t == Token.literalInt);
		token = t;
		literalInt = l;
	}
	this(Token t, LiteralNatAst l) {
		assert(t == Token.literalNat);
		token = t;
		literalNat = l;
	}
	this(Token t, char c) {
		assert(t == Token.unexpectedCharacter);
		token = t;
		unexpectedCharacter = c;
	}

	bool isSymbol() =>
		isSymbolToken(token);

	Symbol asSymbol() {
		assert(isSymbol);
		return symbol;
	}
	// WARN: The docComment string is temporary.
	@trusted DocCommentAndExtraDedents asDocComment() {
		assert(isNewlineToken(token));
		return docComment;
	}
	LiteralFloatAst asLiteralFloat() {
		assert(token == Token.literalFloat);
		return literalFloat;
	}
	LiteralIntAst asLiteralInt() {
		assert(token == Token.literalInt);
		return literalInt;
	}
	LiteralNatAst asLiteralNat() {
		assert(token == Token.literalNat);
		return literalNat;
	}
	char asUnexpectedCharacter() {
		assert(token == Token.unexpectedCharacter);
		return unexpectedCharacter;
	}
}

TokenAndData plainToken(Token a) =>
	TokenAndData(a, true);

enum Token {
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
	dot, // '.'. // '..' is Operator.range
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
	literalFloat, // Use getCurLiteralFloat
	literalInt, // Use getCurLiteralInt
	literalNat, // Use getCurLiteralNat
	loop, // 'loop'
	match, // 'match'
	mut, // 'mut'
	name, // Any non-keyword, non-operator name; use TokenAndData.asSymbol with this
	// Tokens for a name with '=' or ':=' on the end.
	nameOrOperatorColonEquals, // 'TokenAndData.asSymbol' does NOT include the ':='
	nameOrOperatorEquals, // 'TokenAndData.asSymbol' DOES include the '='
	// End of line followed by another line at lesser indentation.
	// There will be one of these tokens for each reduced indent level, followed by a 'newline' token.
	newlineDedent,
	// End of line followed by another line at 1 greater indent level.
	// Unlike 'newlineDedent', this is not followed by a 'newlineSameIndent' token.
	newlineIndent,
	// end of line followed by another line at the same indent level.
	newlineSameIndent,
	noStd, // 'no-std'
	operator, // Any operator; use TokenAndData.asSymbol with this
	parenLeft, // '('
	parenRight, // ')'
	question, // '?'
	questionEqual, // '?='
	quoteDouble, // '"'
	quoteDouble3, // '"""'
	quotedText, // Fake token to be the peek after the '"'
	record, // 'record'
	semicolon, // ';'
	spec, // 'spec'
	summon, // 'summon'
	test, // 'test'
	thread_local, // 'thread-local'
	throw_, // 'throw'
	trusted, // 'trusted'
	unexpectedCharacter, // Any unexpected character
	underscore, // '_'
	union_, // 'union'
	unless, // 'unless'
	unsafe, // 'unsafe'
	until, // 'until'
	while_, // 'while'
	with_, // 'with'
}

bool isNewlineToken(Token a) {
	switch (a) {
		case Token.EOF:
		case Token.newlineDedent:
		case Token.newlineIndent:
		case Token.newlineSameIndent:
			return true;
		default:
			return false;
	}
}
bool isSymbolToken(Token a) {
	switch (a) {
		case Token.name:
		case Token.operator:
		case Token.nameOrOperatorEquals:
		case Token.nameOrOperatorColonEquals:
			return true;
		default:
			return false;
	}
}

TokenAndData lexInitialToken(
	ref MutCString ptr,
	ref AllSymbols allSymbols,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) =>
	newlineToken(ptr, Token.newlineSameIndent, indentKind, curIndent, addDiag);

/*
Advances 'ptr' to lex a single token.
Possibly writes to 'data' depending on the kind of token returned.
*/
TokenAndData lexToken(
	ref MutCString ptr,
	ref AllSymbols allSymbols,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) {
	if (*ptr == '\0')
		return newlineToken(ptr, Token.EOF, indentKind, curIndent, addDiag);

	CString start = ptr;
	char c = takeChar(ptr);
	switch (c) {
		case ' ':
		case '\t':
		case '\r':
		case '#':
			// handled by skipSpacesAndComments
			assert(false);
		case '\n':
			return newlineToken(ptr, Token.newlineSameIndent, indentKind, curIndent, addDiag);
		case '~':
			return operatorToken(ptr, allSymbols, tryTakeChar(ptr, '~') ? symbol!"~~" : symbol!"~");
		case '@':
			return plainToken(Token.at);
		case '!':
			return !startsWith(ptr, "==") && tryTakeChar(ptr, '=')
				? operatorToken(ptr, allSymbols, symbol!"!=")
				: plainToken(Token.bang);
		case '%':
			return operatorToken(ptr, allSymbols, symbol!"%");
		case '^':
			return operatorToken(ptr, allSymbols, symbol!"^");
		case '&':
			return operatorToken(ptr, allSymbols, tryTakeChar(ptr, '&') ? symbol!"&&" : symbol!"&");
		case '*':
			return operatorToken(ptr, allSymbols, tryTakeChar(ptr, '*') ? symbol!"**" : symbol!"*");
		case '(':
			return plainToken(Token.parenLeft);
		case ')':
			return plainToken(Token.parenRight);
		case '[':
			return plainToken(Token.bracketLeft);
		case '{':
			return plainToken(Token.braceLeft);
		case '}':
			return plainToken(Token.braceRight);
		case ']':
			return plainToken(Token.bracketRight);
		case '-':
			return isDecimalDigit(*ptr)
				? takeNumberAfterSign(ptr, some(Sign.minus))
				: tryTakeChar(ptr, '>')
				? plainToken(Token.arrowAccess)
				: operatorToken(ptr, allSymbols, symbol!"-");
		case '=':
			return tryTakeChar(ptr, '>')
				? plainToken(Token.arrowLambda)
				: tryTakeChar(ptr, '=')
				? operatorToken(ptr, allSymbols, symbol!"==")
				: plainToken(Token.equal);
		case '+':
			return isDecimalDigit(*ptr)
				? takeNumberAfterSign(ptr, some(Sign.plus))
				: operatorToken(ptr, allSymbols, symbol!"+");
		case '|':
			return operatorToken(ptr, allSymbols, tryTakeChar(ptr, '|') ? symbol!"||" : symbol!"|");
		case ':':
			return tryTakeChar(ptr, '=')
				? plainToken(Token.colonEqual)
				: tryTakeChar(ptr, ':')
				? plainToken(Token.colon2)
				: plainToken(Token.colon);
		case ';':
			return plainToken(Token.semicolon);
		case '"':
			return tryTakeChars(ptr, "\"\"")
				? plainToken(Token.quoteDouble3)
				: plainToken(Token.quoteDouble);
		case ',':
			return plainToken(Token.comma);
		case '<':
			return tryTakeChar(ptr, '-')
				? plainToken(Token.arrowThen)
				: operatorToken(ptr, allSymbols, tryTakeChar(ptr, '=')
					? tryTakeChar(ptr, '>') ? symbol!"<=>" : symbol!"<="
					: tryTakeChar(ptr, '<')
					? symbol!"<<"
					: symbol!"<");
		case '>':
			return operatorToken(ptr, allSymbols, tryTakeChar(ptr, '=')
				? symbol!">="
				: tryTakeChar(ptr, '>')
				? symbol!">>"
				: symbol!">");
		case '.':
			return tryTakeChar(ptr, '.')
				? tryTakeChar(ptr, '.') ? plainToken(Token.dot3) : operatorToken(ptr, allSymbols, symbol!"..")
				: plainToken(Token.dot);
		case '/':
			return operatorToken(ptr, allSymbols, symbol!"/");
		case '?':
			return tryTakeChar(ptr, '=')
				? plainToken(Token.questionEqual)
				: tryTakeChar(ptr, '?')
				? operatorToken(ptr, allSymbols, symbol!"??")
				: plainToken(Token.question);
		default:
			if (isAlphaIdentifierStart(c)) {
				string nameStr = takeNameRest(ptr, start);
				Symbol symbol = symbolOfString(allSymbols, nameStr);
				Token token = tokenForSymbol(symbol);
				return token == Token.name
					? nameLikeToken(ptr, allSymbols, symbol, Token.name)
					: plainToken(token);
			} else if (isDecimalDigit(c)) {
				ptr = start;
				return takeNumberAfterSign(ptr, none!Sign);
			} else
				return TokenAndData(Token.unexpectedCharacter, c);
	}
}

private alias AddDiag = void delegate(ParseDiag) @safe @nogc pure nothrow;

enum EqualsOrThen { equals, then }
Opt!EqualsOrThen lookaheadEqualsOrThen(MutCString ptr) {
	if (startsWith(ptr, "<- "))
		return some(EqualsOrThen.then);
	while (true) {
		switch (*ptr) {
			case ' ':
				ptr++;
				if (startsWith(ptr, "= "))
					return some(EqualsOrThen.equals);
				else if (startsWith(ptr, "<- "))
					return some(EqualsOrThen.then);
				else
					break;
			// characters that appear in types
			default:
				if (!isTypeChar(*ptr))
					return none!EqualsOrThen;
				else {
					ptr++;
					break;
				}
		}
	}
}

bool lookaheadQuestionEquals(MutCString ptr) {
	while (true) {
		switch (*ptr) {
			case ' ':
				ptr++;
				if (startsWith(ptr, "?= "))
					return true;
				else
					break;
			default:
				// Destructure chars are same as type chars
				if (!isTypeChar(*ptr))
					return false;
				else {
					ptr++;
					break;
				}
		}
	}
}

bool lookaheadLambdaAfterParenLeft(MutCString ptr) {
	size_t openParens = 1;
	while (true) {
		switch (*ptr) {
			case '(':
				openParens++;
				break;
			case ')':
				openParens--;
				//TODO: allow more or less whitespace
				if (openParens == 0) {
					ptr++;
					return startsWith(ptr, " =>");
				} else
					break;
			default:
				if (!isTypeChar(*ptr))
					return false;
		}
		ptr++;
	}
}

private bool startsWithIdentifier(CString ptr, in string expected) {
	Opt!CString end = tryGetAfterStartsWith(ptr, expected);
	return has(end) && !isAlphaIdentifierContinue(*force(end));
}

bool lookaheadAs(CString ptr) =>
	startsWithIdentifier(ptr, "as");
bool lookaheadElse(CString ptr) =>
	startsWithIdentifier(ptr, "else");

enum ElifOrElse { elif, else_ }
Opt!ElifOrElse lookaheadElifOrElse(CString ptr) =>
	startsWithIdentifier(ptr, "elif")
		? some(ElifOrElse.elif)
		: startsWithIdentifier(ptr, "else")
		? some(ElifOrElse.else_)
		: none!ElifOrElse;

immutable struct StringPart {
	string text;
	After after;

	enum After {
		quote,
		lbrace,
	}
}

enum QuoteKind {
	double_,
	double3,
}

StringPart takeStringPart(
	ref Alloc alloc,
	return scope ref MutCString ptr,
	QuoteKind quoteKind,
	in AddDiag addDiag,
) {
	ArrayBuilder!char res;
	StringPart.After after = () {
		while (true) {
			switch (*ptr) {
				case '"':
					ptr++;
					final switch (quoteKind) {
						case QuoteKind.double_:
							return StringPart.After.quote;
						case QuoteKind.double3:
							if (tryTakeChars(ptr, "\"\""))
								return StringPart.After.quote;
							else
								add(alloc, res, '"');
							break;
					}
					break;
				case '{':
					ptr++;
					return StringPart.After.lbrace;
				case '\\':
					ptr++;
					char escapeCode = takeChar(ptr);
					char escaped = () {
						switch (escapeCode) {
							case 'x':
								ulong digit0 = charToNat(takeChar(ptr));
								ulong digit1 = charToNat(takeChar(ptr));
								if (digit0 == ulong.max || digit1 == ulong.max)
									todo!void("bad hex digit");
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
								addDiag(ParseDiag(ParseDiag.InvalidStringEscape(escapeCode)));
								return 'a';
						}
					}();
					add(alloc, res, escaped);
					break;
				case '\r':
				case '\n':
					final switch (quoteKind) {
						case QuoteKind.double_:
							addDiag(ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.quoteDouble)));
							return StringPart.After.quote;
						case QuoteKind.double3:
							add(alloc, res, takeChar(ptr));
							break;
					}
					break;
				case '\0':
					addDiag(ParseDiag(ParseDiag.Expected(() {
						final switch (quoteKind) {
							case QuoteKind.double_:
								return ParseDiag.Expected.Kind.quoteDouble;
							case QuoteKind.double3:
								return ParseDiag.Expected.Kind.quoteDouble3;
						}
					}())));
					return StringPart.After.quote;
				default:
					add(alloc, res, takeChar(ptr));
			}
		}
	}();
	return StringPart(finish(alloc, res), after);
}

private:

TokenAndData newlineToken(
	ref MutCString ptr,
	Token newlineOrEOF,
	IndentKind indentKind,
	ref uint curIndent,
	in AddDiag addDiag,
) {
	DocCommentAndIndentDelta x = skipBlankLinesAndGetIndentDelta(ptr, indentKind, curIndent, addDiag);
	Token token = x.indentDelta == 0 ? newlineOrEOF : x.indentDelta < 0 ? Token.newlineDedent : Token.newlineIndent;
	uint extraDedents = token == Token.newlineDedent ? -x.indentDelta - 1 : 0;
	return TokenAndData(token, DocCommentAndExtraDedents(x.docComment, extraDedents));
}

TokenAndData operatorToken(scope ref MutCString ptr, ref AllSymbols allSymbols, Symbol a) =>
	nameLikeToken(ptr, allSymbols, a, Token.operator);

TokenAndData nameLikeToken(scope ref MutCString ptr, ref AllSymbols allSymbols, Symbol a, Token regularToken) =>
	!startsWith(ptr, "==") && tryTakeChar(ptr, '=')
		? TokenAndData(Token.nameOrOperatorEquals, appendEquals(allSymbols, a))
		: TokenAndData(tryTakeChars(ptr, ":=") ? Token.nameOrOperatorColonEquals : regularToken, a);

Token tokenForSymbol(Symbol a) {
	switch (a.value) {
		case symbol!"act".value:
			return Token.act;
		case symbol!"alias".value:
			return Token.alias_;
		case symbol!"as".value:
			return Token.as;
		case symbol!"assert".value:
			return Token.assert_;
		case symbol!"bare".value:
			return Token.bare;
		case symbol!"break".value:
			return Token.break_;
		case symbol!"builtin".value:
			return Token.builtin;
		case symbol!"builtin-spec".value:
			return Token.builtinSpec;
		case symbol!"continue".value:
			return Token.continue_;
		case symbol!"elif".value:
			return Token.elif;
		case symbol!"else".value:
			return Token.else_;
		case symbol!"enum".value:
			return Token.enum_;
		case symbol!"export".value:
			return Token.export_;
		case symbol!"extern".value:
			return Token.extern_;
		case symbol!"far".value:
			return Token.far;
		case symbol!"flags".value:
			return Token.flags;
		case symbol!"for".value:
			return Token.for_;
		case symbol!"forbid".value:
			return Token.forbid;
		case symbol!"force-ctx".value:
			return Token.forceCtx;
		case symbol!"fun".value:
			return Token.fun;
		case symbol!"global".value:
			return Token.global;
		case symbol!"if".value:
			return Token.if_;
		case symbol!"import".value:
			return Token.import_;
		case symbol!"loop".value:
			return Token.loop;
		case symbol!"match".value:
			return Token.match;
		case symbol!"mut".value:
			return Token.mut;
		case symbol!"no-std".value:
			return Token.noStd;
		case symbol!"record".value:
			return Token.record;
		case symbol!"spec".value:
			return Token.spec;
		case symbol!"summon".value:
			return Token.summon;
		case symbol!"test".value:
			return Token.test;
		case symbol!"thread-local".value:
			return Token.thread_local;
		case symbol!"throw".value:
			return Token.throw_;
		case symbol!"trusted".value:
			return Token.trusted;
		case symbol!"unless".value:
			return Token.unless;
		case symbol!"union".value:
			return Token.union_;
		case symbol!"unsafe".value:
			return Token.unsafe;
		case symbol!"until".value:
			return Token.until;
		case symbol!"while".value:
			return Token.while_;
		case symbol!"with".value:
			return Token.with_;
		case symbol!"_".value:
			return Token.underscore;
		default:
			return Token.name;
	}
}

enum Sign {
	plus,
	minus,
}

TokenAndData takeNumberAfterSign(ref MutCString ptr, Opt!Sign sign) {
	ulong base = tryTakeChars(ptr, "0x")
		? 16
		: tryTakeChars(ptr, "0o")
		? 8
		: tryTakeChars(ptr, "0b")
		? 2
		: 10;
	LiteralNatAst n = takeNat(ptr, base);
	if (peekDecimalPoint(ptr)) {
		ptr++;
		return takeFloat(ptr, optOrDefault!Sign(sign, () => Sign.plus), n, base);
	} else if (has(sign))
		return TokenAndData(Token.literalInt, () {
			final switch (force(sign)) {
				case Sign.plus:
					return LiteralIntAst(n.value, n.value > long.max);
				case Sign.minus:
					return LiteralIntAst(-n.value, n.value > (cast(ulong) long.max) + 1);
			}
		}());
	else
		return TokenAndData(Token.literalNat, n);
}

bool peekDecimalPoint(MutCString ptr) {
	if (*ptr == '.') {
		ptr++;
		return isDecimalDigit(*ptr);
	} else
		return false;
}


TokenAndData takeFloat(ref MutCString ptr, Sign sign, LiteralNatAst natPart, ulong base) {
	// TODO: improve accuracy
	MutCString afterDecimalPoint = ptr;
	LiteralNatAst rest = takeNat(ptr, base);
	bool overflow = natPart.overflow || rest.overflow;
	ulong power = ptr - afterDecimalPoint;
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
	return TokenAndData(Token.literalFloat, LiteralFloatAst(f, overflow));
}

double pow(double acc, double base, ulong power) =>
	power == 0 ? acc : pow(acc * base, base, power - 1);

//TODO: overflow bug possible here
ulong getDivisor(ulong acc, ulong a, ulong base) =>
	acc < a ? getDivisor(acc * base, a, base) : acc;

public LiteralNatAst takeNat(ref MutCString ptr, ulong base) {
	ulong value = 0;
	bool overflow = false;
	while (true) {
		ulong digit = charToNat(*ptr);
		if (digit < base) {
			ptr++;
			ulong newValue = value * base + digit;
			tryTakeChar(ptr, '_');
			overflow = overflow || newValue / base != value;
			value = newValue;
		} else
			break;
	}
	return LiteralNatAst(value, overflow);
}

ulong charToNat(char a) =>
	isDecimalDigit(a)
		? a - '0'
		: 'a' <= a && a <= 'f'
		? 10 + (a - 'a')
		: 'A' <= a && a <= 'F'
		? 10 + (a - 'A')
		: ulong.max;

string takeNameRest(ref MutCString ptr, CString begin) {
	MutCString lastNonHyphen = begin;
	while (isAlphaIdentifierContinue(*ptr)) {
		if (*ptr != '-') lastNonHyphen = ptr;
		ptr++;
	}
	ptr = lastNonHyphen;
	ptr++;
	return stringOfRange(begin, ptr);
}

bool isAlphaIdentifierStart(char c) =>
	('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';

bool isAlphaIdentifierContinue(char c) =>
	isAlphaIdentifierStart(c) || c == '-' || isDecimalDigit(c);

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
