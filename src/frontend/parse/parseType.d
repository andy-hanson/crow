module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	curPos,
	getCurIndent,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	lookaheadNameOpenParen,
	range,
	rangeAtChar,
	rangeForCurToken,
	skipNewlinesIgnoreIndentation,
	skipUntilNewlineNoDiag,
	takeNextToken,
	Token,
	TokenAndData;
import frontend.parse.parseUtil :
	addDiagExpected,
	takeNameAndRangeAllowUnderscore,
	takeOrAddDiagExpectedToken,
	tryTakeNameAndRange,
	tryTakeOperator,
	tryTakeToken;
import model.ast : DestructureAst, NameAndRange, ParamsAst, TypeAst;
import model.model : FunKind;
import model.parseDiag : ParseDiag;
import util.col.array : emptySmallArray, only, SmallArray;
import util.col.arrayBuilder : Builder, buildSmallArray;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos;
import util.symbol : Symbol, symbol;

Opt!(TypeAst*) tryParseTypeArgForEnumOrFlags(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		TypeAst res = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return some(allocate(lexer.alloc, res));
	} else
		return none!(TypeAst*);
}

TypeAst parseTypeArgForVarDecl(ref Lexer lexer) {
	if (takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		TypeAst res = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return res;
	} else
		return TypeAst(TypeAst.Bogus(rangeAtChar(lexer)));
}

Opt!(TypeAst*) tryParseTypeArgForExpr(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.at)
		? some(allocate(lexer.alloc, parseTypeForTypedExpr(lexer)))
		: none!(TypeAst*);

private SmallArray!TypeAst parseTypesWithCommasThenClosingParen(ref Lexer lexer) =>
	buildSmallArray(lexer.alloc, (scope ref Builder!TypeAst out_) {
		parseTypesWithCommasThenClosingParen(lexer, out_);
	});

private void parseTypesWithCommasThenClosingParen(ref Lexer lexer, scope ref Builder!TypeAst res) {
	if (!tryTakeToken(lexer, Token.parenRight)) {
		do {
			res ~= parseType(lexer);
		} while (tryTakeToken(lexer, Token.comma));
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	}
}

TypeAst parseType(ref Lexer lexer) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.unnecessary));

TypeAst parseTypeForTypedExpr(ref Lexer lexer) =>
	parseTypeSuffixesNonName(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.necessary));

DestructureAst parseDestructureRequireParens(ref Lexer lexer) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (tryTakeToken(lexer, Token.parenRight))
			return DestructureAst(DestructureAst.Void(range(lexer, start)));
		else {
			DestructureAst res = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
			return res;
		}
	} else {
		NameAndRange name = takeNameAndRangeAllowUnderscore(lexer);
		Pos posForMut = curPos(lexer);
		Opt!Pos mut = tryTakeToken(lexer, Token.mut) ? some(posForMut) : none!Pos;
		Opt!(TypeAst*) type = () {
			switch (getPeekToken(lexer)) {
				case Token.arrowThen:
				case Token.colon:
				case Token.comma:
				case Token.equal:
				case Token.newlineDedent:
				case Token.newlineIndent:
				case Token.newlineSameIndent:
				case Token.parenRight:
				case Token.questionEqual:
					return none!(TypeAst*);
				default:
					return some(allocate(lexer.alloc, parseType(lexer)));
			}
		}();
		return DestructureAst(DestructureAst.Single(name, mut, type));
	}
}

DestructureAst parseDestructureNoRequireParens(ref Lexer lexer) {
	DestructureAst first = parseDestructureRequireParens(lexer);
	if (tryTakeToken(lexer, Token.comma)) {
		return DestructureAst(buildSmallArray!DestructureAst(lexer.alloc, (ref Builder!DestructureAst parts) {
			parts ~= first;
			do {
				parts ~= parseDestructureRequireParens(lexer);
			} while (tryTakeToken(lexer, Token.comma));
		}));
	} else
		return first;
}

ParamsAst parseParams(ref Lexer lexer) {
	uint indent = getCurIndent(lexer);
	if (!takeOrAddDiagExpectedToken(lexer, Token.parenLeft, ParseDiag.Expected.Kind.openParen)) {
		skipUntilNewlineNoDiag(lexer);
		return ParamsAst([]);
	} else
		return parseParamsAfterParenLeft(lexer, indent);
}

private ParamsAst parseParamsAfterParenLeft(ref Lexer lexer, uint indentLevel) {
	if (tryTakeToken(lexer, Token.parenRight))
		return ParamsAst(emptySmallArray!DestructureAst);
	else if (tryTakeToken(lexer, Token.dot3)) {
		DestructureAst param = parseDestructureRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return ParamsAst(allocate(lexer.alloc, ParamsAst.Varargs(param)));
	} else
		return ParamsAst(buildSmallArray!DestructureAst(lexer.alloc, (scope ref Builder!DestructureAst res) {
			while (true) {
				skipNewlinesIgnoreIndentation(lexer, indentLevel);
				res ~= parseDestructureRequireParens(lexer);
				if (tryTakeToken(lexer, Token.parenRight))
					break;
				if (!takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma)) {
					skipUntilNewlineNoDiag(lexer);
					break;
				}
				// allow trailing comma
				skipNewlinesIgnoreIndentation(lexer, indentLevel);
				if (tryTakeToken(lexer, Token.parenRight))
					break;
			}
		}));
}

private:

enum ParenthesesNecessary { unnecessary, necessary }

TypeAst parseTypeBeforeSuffixes(ref Lexer lexer, ParenthesesNecessary parens) {
	Pos start = curPos(lexer);
	switch (getPeekToken(lexer)) {
		case Token.name:
			return TypeAst(NameAndRange(start, takeNextToken(lexer).asSymbol));
		case Token.parenLeft:
			takeNextToken(lexer);
			return parseTupleType(lexer, start, parens);
		default:
			addDiagUnexpectedCurToken(lexer, start, getPeekTokenAndData(lexer));
			return TypeAst(TypeAst.Bogus(rangeForCurToken(lexer, start)));
	}
}

TypeAst parseTupleType(ref Lexer lexer, Pos start, ParenthesesNecessary parens) {
	SmallArray!TypeAst args = parseTypesWithCommasThenClosingParen(lexer);
	switch (args.length) {
		case 0:
			addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.TypeEmptyParens()));
			return TypeAst(TypeAst.Bogus());
		case 1:
			if (parens != ParenthesesNecessary.necessary)
				addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.TypeUnnecessaryParens()));
			return only(args);
		default:
			return TypeAst(TypeAst.Tuple(range(lexer, start), args));
	}
}

TypeAst parseTypeSuffixes(ref Lexer lexer, TypeAst left) {
	Opt!TypeAst suffix = parseTypeSuffix(lexer, left);
	return has(suffix) ? parseTypeSuffixes(lexer, force(suffix)) : left;
}

TypeAst parseTypeSuffixesNonName(ref Lexer lexer, TypeAst left) {
	Opt!TypeAst suffix = parseTypeSuffixNonName(lexer, left);
	return has(suffix) ? parseTypeSuffixesNonName(lexer, force(suffix)) : left;
}

Opt!TypeAst parseTypeSuffix(ref Lexer lexer, TypeAst left) {
	Opt!TypeAst res = parseTypeSuffixNonName(lexer, left);
	if (has(res))
		return res;
	else {
		Opt!NameAndRange name = tryTakeNameAndRange(lexer);
		return has(name)
			? some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixName(left, force(name)))))
			: none!TypeAst;
	}
}

Opt!TypeAst parseTypeSuffixNonName(ref Lexer lexer, TypeAst left) {
	Pos suffixPos = curPos(lexer);
	Opt!TypeAst suffix(TypeAst.SuffixSpecial.Kind kind) =>
		some(TypeAst(TypeAst.SuffixSpecial(allocate(lexer.alloc, left), suffixPos, kind)));
	Opt!TypeAst doubleSuffix(TypeAst.SuffixSpecial.Kind kind1, TypeAst.SuffixSpecial.Kind kind2) =>
		some(TypeAst(TypeAst.SuffixSpecial(
			allocate(lexer.alloc, TypeAst(TypeAst.SuffixSpecial(allocate(lexer.alloc, left), suffixPos, kind2))),
			suffixPos + 1,
			kind1)));
	Opt!TypeAst mapLike(TypeAst.Map.Kind kind) {
		TypeAst key = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return some(TypeAst(allocate(lexer.alloc, TypeAst.Map(kind, [key, left]))));
	}

	if (tryTakeToken(lexer, Token.question))
		return suffix(TypeAst.SuffixSpecial.Kind.option);
	else if (tryTakeToken(lexer, Token.bracketLeft))
		return tryTakeToken(lexer, Token.bracketRight)
			? suffix(TypeAst.SuffixSpecial.Kind.list)
			: mapLike(TypeAst.Map.Kind.data);
	else if (tryTakeOperator(lexer, symbol!"^"))
		return suffix(TypeAst.SuffixSpecial.Kind.future);
	else if (tryTakeOperator(lexer, symbol!"*"))
		return suffix(TypeAst.SuffixSpecial.Kind.ptr);
	else if (tryTakeOperator(lexer, symbol!"**"))
		return doubleSuffix(TypeAst.SuffixSpecial.Kind.ptr, TypeAst.SuffixSpecial.Kind.ptr);
	else if (tryTakeToken(lexer, Token.mut)) {
		BeforeParen beforeParen = beforeParen(lexer);
		if (tryTakeToken(lexer, Token.bracketLeft))
			return tryTakeToken(lexer, Token.bracketRight)
				? suffix(TypeAst.SuffixSpecial.Kind.mutList)
				: mapLike(TypeAst.Map.Kind.mut);
		else if (tryTakeToken(lexer, Token.parenLeft))
			return some(parseFunType(lexer, left, beforeParen, FunKind.mut));
		else if (tryTakeOperator(lexer, symbol!"*"))
			return suffix(TypeAst.SuffixSpecial.Kind.mutPtr);
		else if (tryTakeOperator(lexer, symbol!"**"))
			return doubleSuffix(TypeAst.SuffixSpecial.Kind.mutPtr, TypeAst.SuffixSpecial.Kind.ptr);
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.afterMut);
			return none!TypeAst;
		}
	} else if (tryTakeToken(lexer, Token.far)) {
		BeforeParen beforeParen = beforeParen(lexer);
		if (tryTakeToken(lexer, Token.parenLeft))
			return some(parseFunType(lexer, left, beforeParen, FunKind.far));
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.openParen);
			return none!TypeAst;
		}
	} else if (tryTakeToken(lexer, Token.function_)) {
		BeforeParen beforeParen = beforeParen(lexer);
		if (tryTakeToken(lexer, Token.parenLeft))
			return some(parseFunType(lexer, left, beforeParen, FunKind.function_));
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.openParen);
			return none!TypeAst;
		}
	} else {
		Opt!BeforeParen afterData = tryTakeNameOpenParen(lexer, symbol!"data");
		if (has(afterData))
			return some(parseFunType(lexer, left, force(afterData), FunKind.data));
		else {
			Opt!BeforeParen afterShared = tryTakeNameOpenParen(lexer, symbol!"shared");
			if (has(afterShared))
				return some(parseFunType(lexer, left, force(afterShared), FunKind.shared_));
			else
				return none!TypeAst;
		}
	}
}

struct BeforeParen {
	uint indent;
	Pos pos;
}

BeforeParen beforeParen(scope ref Lexer lexer) =>
	BeforeParen(getCurIndent(lexer), curPos(lexer));

// Returns position before '('
Opt!BeforeParen tryTakeNameOpenParen(scope ref Lexer lexer, Symbol name) {
	if (lookaheadNameOpenParen(lexer, name)) {
		TokenAndData x = takeNextToken(lexer);
		assert(x.token == Token.name && x.asSymbol == name);
		BeforeParen res = beforeParen(lexer);
		bool paren = tryTakeToken(lexer, Token.parenLeft);
		assert(paren);
		return some(res);
	} else
		return none!BeforeParen;
}

TypeAst parseFunType(ref Lexer lexer, TypeAst returnType, BeforeParen beforeParen, FunKind kind) {
	ParamsAst params = parseParamsAfterParenLeft(lexer, beforeParen.indent);
	return TypeAst(allocate(lexer.alloc, TypeAst.Fun(returnType, kind, range(lexer, beforeParen.pos), params)));
}
