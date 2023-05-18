module frontend.parse.lexToken;

@safe @nogc pure nothrow:

import frontend.parse.ast : LiteralFloatAst, LiteralIntAst, LiteralNatAst;
import frontend.parse.lexWhitespace : skipRestOfLineAndNewline, tryTakeChar, tryTakeChars;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellSet;
import util.col.arr : arrOfRange;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : force, has, none, Opt, some;
import util.sym : AllSymbols, Sym, sym, symOfStr;
import util.util : drop, todo;

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

union TokenData {
	bool ignore;
	Cell!Sym sym; // For Token.name or Token.operator
	Cell!LiteralFloatAst literalFloat; // for Token.literalFloat
	Cell!LiteralIntAst literalInt; // for Token.literalInt
	Cell!LiteralNatAst literalNat; // for Token.literalNat
}

/*
Advances 'ptr' to lex a single token.
Possibly writes to 'data' depending on the kind of token returned.
*/
@trusted public Token lexToken(ref immutable(char)* ptr, ref TokenData data, ref AllSymbols allSymbols) {
	while (true) {
		char c = *ptr;
		ptr++;
		switch (c) {
			case '\0':
				ptr--;
				return Token.EOF;
			case ' ':
			case '\t':
				continue;
			case '#':
				skipRestOfLineAndNewline(ptr);
				return Token.newline;
			case '\r':
			case '\n':
				return Token.newline;
			case '~':
				return operatorToken(data, tryTakeChar(ptr, '~') ? sym!"~~" : sym!"~");
			case '@':
				return Token.at;
			case '!':
				return ptr[0 .. 2] != "==" && tryTakeChar(ptr, '=')
					? operatorToken(data, sym!"!=")
					: Token.bang;
			case '%':
				return operatorToken(data, sym!"%");
			case '^':
				return operatorToken(data, sym!"^");
			case '&':
				return operatorToken(data, tryTakeChar(ptr, '&') ? sym!"&&" : sym!"&");
			case '*':
				return operatorToken(data, tryTakeChar(ptr, '*') ? sym!"**" : sym!"*");
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
				return isDigit(*ptr)
					? takeNumberAfterSign(ptr, data, some(Sign.minus))
					: tryTakeChar(ptr, '>')
					? Token.arrowAccess
					: operatorToken(data, sym!"-");
			case '=':
				return tryTakeChar(ptr, '>')
					? Token.arrowLambda
					: tryTakeChar(ptr, '=')
					? operatorToken(data, sym!"==")
					: Token.equal;
			case '+':
				return isDigit(*ptr)
					? takeNumberAfterSign(ptr, data, some(Sign.plus))
					: operatorToken(data, sym!"+");
			case '|':
				return operatorToken(data, tryTakeChar(ptr, '|') ? sym!"||" : sym!"|");
			case ':':
				return tryTakeChar(ptr, '=')
					? Token.colonEqual
					: tryTakeChar(ptr, ':')
					? Token.colon2
					: Token.colon;
			case ';':
				return Token.semicolon;
			case '"':
				return tryTakeChars(ptr, "\"\"")
					? Token.quoteDouble3
					: Token.quoteDouble;
			case ',':
				return Token.comma;
			case '<':
				return tryTakeChar(ptr, '-')
					? Token.arrowThen
					: operatorToken(data, tryTakeChar(ptr, '=')
						? tryTakeChar(ptr, '>') ? sym!"<=>" : sym!"<="
						: tryTakeChar(ptr, '<')
						? sym!"<<"
						: sym!"<");
			case '>':
				return operatorToken(data, tryTakeChar(ptr, '=')
					? sym!">="
					: tryTakeChar(ptr, '>')
					? sym!">>"
					: sym!">");
			case '.':
				return tryTakeChar(ptr, '.')
					? tryTakeChar(ptr, '.') ? Token.dot3 : operatorToken(data, sym!"..")
					: Token.dot;
			case '/':
				return operatorToken(data, sym!"/");
			case '?':
				return tryTakeChar(ptr, '=')
					? Token.questionEqual
					: tryTakeChar(ptr, '?')
					? operatorToken(data, sym!"??")
					: Token.question;
			default:
				if (isAlphaIdentifierStart(c)) {
					string nameStr = takeNameRest(ptr, ptr - 1);
					return tokenForSym(symOfStr(allSymbols, nameStr), data);
				} else if (isDigit(c)) {
					ptr--;
					return takeNumberAfterSign(ptr, data, none!Sign);
				} else
					return Token.invalid;
		}
	}
}

private:

@trusted char takeChar(ref immutable(char)* ptr) {
	char res = *ptr;
	ptr++;
	return res;
}

Token operatorToken(ref TokenData data, Sym a) {
	cellSet(data.sym, a);
	return Token.operator;
}

Token tokenForSym(Sym a, ref TokenData data) {
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
			cellSet(data.sym, a);
			return Token.name;
	}
}

enum Sign {
	plus,
	minus,
}

@trusted Token takeNumberAfterSign(ref immutable(char)* ptr, ref TokenData data, Opt!Sign sign) {
	ulong base = tryTakeChars(ptr, "0x")
		? 16
		: tryTakeChars(ptr, "0o")
		? 8
		: tryTakeChars(ptr, "0b")
		? 2
		: 10;
	LiteralNatAst n = takeNat(ptr, base);
	if (*ptr == '.' && isDigit(*(ptr + 1))) {
		ptr++;
		return takeFloat(ptr, data, has(sign) ? force(sign) : Sign.plus, n, base);
	} else if (has(sign)) {
		LiteralIntAst intAst = () {
			final switch (force(sign)) {
				case Sign.plus:
					return LiteralIntAst(n.value, n.value > long.max);
				case Sign.minus:
					return LiteralIntAst(-n.value, n.value > (cast(ulong) long.max) + 1);
			}
		}();
		cellSet(data.literalInt, intAst);
		return Token.literalInt;
	} else {
		cellSet(data.literalNat, n);
		return Token.literalNat;
	}
}

@system Token takeFloat(ref immutable(char)* ptr, ref TokenData data, Sign sign, LiteralNatAst natPart, ulong base) {
	// TODO: improve accuracy
	const char *cur = ptr;
	LiteralNatAst rest = takeNat(ptr, base);
	bool overflow = natPart.overflow || rest.overflow;
	ulong power = ptr - cur;
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
	cellSet(data.literalFloat, LiteralFloatAst(f, overflow));
	return Token.literalFloat;
}

double pow(double acc, double base, ulong power) =>
	power == 0 ? acc : pow(acc * base, base, power - 1);

//TODO: overflow bug possible here
ulong getDivisor(ulong acc, ulong a, ulong base) =>
	acc < a ? getDivisor(acc * base, a, base) : acc;

@system LiteralNatAst takeNat(ref immutable(char)* ptr, ulong base) {
	ulong value = 0;
	bool overflow = false;
	while (true) {
		ulong digit = charToNat(*ptr);
		if (digit < base) {
			ptr++;
			ulong newValue = value * base + digit;
			drop(tryTakeChar(ptr, '_'));
			overflow = overflow || newValue / base != value;
			value = newValue;
		} else
			break;
	}
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

@trusted string takeNameRest(ref immutable(char)* ptr, immutable char* begin) {
	while (isAlphaIdentifierContinue(*ptr))
		ptr++;
	if (*(ptr - 1) == '-')
		ptr--;
	return arrOfRange(begin, ptr);
}

bool isAlphaIdentifierStart(char c) =>
	('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || c == '_';

bool isDigit(char c) =>
	'0' <= c && c <= '9';

bool isAlphaIdentifierContinue(char c) =>
	isAlphaIdentifierStart(c) || c == '-' || isDigit(c);

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

alias AddDiag = void delegate(ParseDiag) @safe @nogc pure nothrow;

public enum EqualsOrThen { equals, then }
public @trusted Opt!EqualsOrThen lookaheadWillTakeEqualsOrThen(immutable(char)* ptr) {
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

public @trusted bool lookaheadWillTakeQuestionEquals(immutable(char)* ptr) {
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

public @trusted bool lookaheadWillTakeArrowAfterParenLeft(immutable(char)* ptr) {
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

public StringPart takeStringPart(
	ref Alloc alloc,
	return scope ref immutable(char)* ptr,
	QuoteKind quoteKind,
	in AddDiag addDiag,
) {
	ArrBuilder!char res;
	StringPart.After after = () {
		while (true) {
			char x = takeChar(ptr);
			switch(x) {
				case '"':
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
				case '\r':
				case '\n':
					final switch (quoteKind) {
						case QuoteKind.double_:
							addDiag(ParseDiag(ParseDiag.Expected(ParseDiag.Expected.Kind.quoteDouble)));
							return StringPart.After.quote;
						case QuoteKind.double3:
							add(alloc, res, x);
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
				case '{':
					return StringPart.After.lbrace;
				case '\\':
					char escapeCode = takeChar(ptr);
					char escaped = () {
						switch (escapeCode) {
							case 'x':
								size_t digit0 = toHexDigit(takeChar(ptr));
								size_t digit1 = toHexDigit(takeChar(ptr));
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
				default:
					add(alloc, res, x);
			}
		}
	}();
	return StringPart(finishArr(alloc, res), after);
}
