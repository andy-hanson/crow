module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : bogusTypeAst, NameAndRange, range, TypeAst;
import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	alloc,
	curPos,
	getCurNameAndRange,
	Lexer,
	nextToken,
	peekToken,
	range,
	takeOrAddDiagExpectedToken,
	takeTypeArgsEnd,
	Token,
	tryTakeOperator,
	tryTakeToken;
import model.parseDiag : ParseDiag;
import util.collection.arr : ArrWithSize, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
import util.collection.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.memory : allocate;
import util.opt : nonePtr, OptPtr, somePtr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : Operator;
import util.util : todo;

immutable(OptPtr!TypeAst) tryParseTypeArg(ref Lexer lexer) {
	if (tryTakeOperator(lexer, Operator.less)) {
		immutable TypeAst res = parseType(lexer);
		takeTypeArgsEnd(lexer);
		return somePtr(allocate(lexer.alloc, res));
	} else
		return nonePtr!TypeAst;
}

immutable(ArrWithSize!TypeAst) tryParseTypeArgsForExpr(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.atLess)) {
		immutable ArrWithSize!TypeAst res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return emptyArrWithSize!TypeAst;
}

immutable(ArrWithSize!TypeAst) tryParseTypeArgsBracketed(ref Lexer lexer) {
	if (tryTakeOperator(lexer, Operator.less)) {
		immutable ArrWithSize!TypeAst res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return emptyArrWithSize!TypeAst;
}

private void parseTypesWithCommas(Builder)(ref Lexer lexer, ref Builder output) {
	do {
		add(lexer.alloc, output, parseType(lexer));
	} while (tryTakeToken(lexer, Token.comma));
}

private immutable(ArrWithSize!TypeAst) parseTypesWithCommas(ref Lexer lexer) {
	ArrWithSizeBuilder!TypeAst res;
	parseTypesWithCommas(lexer, res);
	return finishArrWithSize(lexer.alloc, res);
}

private immutable(ArrWithSize!TypeAst) tryParseTypeArgsAllowSpace(ref Lexer lexer) {
	return peekToken(lexer, Token.name)
		? arrWithSizeLiteral(lexer.alloc, [parseType(lexer)])
		: tryParseTypeArgsBracketed(lexer);
}

immutable(TypeAst) parseType(ref Lexer lexer) {
	return parseType(lexer, RequireBracket.no);
}

immutable(TypeAst) parseTypeRequireBracket(ref Lexer lexer) {
	return parseType(lexer, RequireBracket.yes);
}

private enum RequireBracket { no, yes }

private immutable(TypeAst) parseType(ref Lexer lexer, immutable RequireBracket requireBracket) {
	return parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, requireBracket));
}

private immutable(TypeAst) parseTypeBeforeSuffixes(ref Lexer lexer, immutable RequireBracket requireBracket) {
	immutable Pos start = curPos(lexer);
	immutable Token token = nextToken(lexer);
	switch (token) {
		case Token.name:
			immutable NameAndRange name = getCurNameAndRange(lexer, start);
			immutable ArrWithSize!TypeAst typeArgs = () {
				final switch (requireBracket) {
					case RequireBracket.no:
						return tryParseTypeArgsAllowSpace(lexer);
					case RequireBracket.yes:
						return tryParseTypeArgsBracketed(lexer);
				}
			}();
			immutable RangeWithinFile rng = range(lexer, start);
			return immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
		case Token.act:
			return parseFunType(lexer, start, TypeAst.Fun.Kind.act);
		case Token.fun:
			return parseFunType(lexer, start, TypeAst.Fun.Kind.fun);
		case Token.ref_:
			return parseFunType(lexer, start, TypeAst.Fun.Kind.ref_);
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return bogusTypeAst(range(lexer, start));
	}
}

private immutable(TypeAst) parseFunType(ref Lexer lexer, immutable Pos start, immutable TypeAst.Fun.Kind kind) {
	ArrBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (!tryTakeToken(lexer, Token.parenRight)) {
			parseTypesWithCommas(lexer, returnAndParamTypes);
			if (!tryTakeToken(lexer, Token.parenRight))
				todo!void("diagnostic -- missing closing paren");
		}
	} else
		addDiag(lexer, range(lexer, start), immutable ParseDiag(
			immutable ParseDiag.FunctionTypeMissingParens()));
	return immutable TypeAst(immutable TypeAst.Fun(
		range(lexer, start),
		kind,
		finishArr(lexer.alloc, returnAndParamTypes)));
}

private immutable(TypeAst) parseTypeSuffixes(ref Lexer lexer, immutable TypeAst ast) {
	immutable(TypeAst) doSuffix(immutable TypeAst inner, immutable TypeAst.Suffix.Kind kind) {
		return immutable TypeAst(allocate(lexer.alloc, immutable TypeAst.Suffix(kind, inner)));
	}

	immutable(TypeAst) handleSuffix(immutable TypeAst.Suffix.Kind kind) {
		return parseTypeSuffixes(lexer, doSuffix(ast, kind));
	}

	immutable(TypeAst) handleDoubleSuffix(immutable TypeAst.Suffix.Kind kind1, immutable TypeAst.Suffix.Kind kind2) {
		return parseTypeSuffixes(lexer, doSuffix(doSuffix(ast, kind1), kind2));
	}

	immutable(TypeAst) handleDictLike(immutable TypeAst.Dict.Kind kind) {
		immutable TypeAst inner = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return parseTypeSuffixes(lexer, immutable TypeAst(
			allocate(lexer.alloc, immutable TypeAst.Dict(kind, ast, inner))));
	}

	if (tryTakeToken(lexer, Token.question))
		return handleSuffix(TypeAst.Suffix.Kind.opt);
	else if (tryTakeToken(lexer, Token.bracketLeft)) {
		return tryTakeToken(lexer, Token.bracketRight)
			? handleSuffix(TypeAst.Suffix.Kind.arr)
			: handleDictLike(TypeAst.Dict.Kind.data);
	} else if (tryTakeOperator(lexer, Operator.times))
		return handleSuffix(TypeAst.Suffix.Kind.ptr);
	else if (tryTakeOperator(lexer, Operator.exponent))
		return handleDoubleSuffix(TypeAst.Suffix.Kind.ptr, TypeAst.Suffix.Kind.ptr);
	else if (tryTakeToken(lexer, Token.mut)) {
		if (tryTakeToken(lexer, Token.bracketLeft)) {
			return tryTakeToken(lexer, Token.bracketRight)
				? handleSuffix(TypeAst.Suffix.Kind.arrMut)
				: handleDictLike(TypeAst.Dict.Kind.mut);
		} else if (tryTakeOperator(lexer, Operator.times))
			return handleSuffix(TypeAst.Suffix.kind.ptrMut);
		else if (tryTakeOperator(lexer, Operator.exponent))
			return handleDoubleSuffix(TypeAst.Suffix.Kind.ptrMut, TypeAst.Suffix.Kind.ptr);
		else
			// Unexpected token after 'mut' -- should have been '*' or '['
			return todo!(immutable TypeAst)("!");
	} else
		return ast;
}
