module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange, range, TypeAst;
import frontend.parse.lexer :
	addDiag,
	curPos,
	getCurNameAndRange,
	Lexer,
	nextToken,
	peekExact,
	peekToken,
	range,
	takeNameAndRange,
	takeOrAddDiagExpected,
	Token,
	tryTake,
	tryTakeOperator,
	tryTakeToken;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.collection.arr : ArrWithSize, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
import util.collection.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, Operator, shortSymAlphaLiteralValue, Sym;
import util.util : todo;

immutable(ArrWithSize!TypeAst) tryParseTypeArgsForExpr(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.atLess)) {
		immutable ArrWithSize!TypeAst res = parseTypesWithCommas(alloc, allSymbols, lexer);
		takeTypeArgsEnd(alloc, lexer);
		return res;
	} else
		return emptyArrWithSize!TypeAst;
}

immutable(ArrWithSize!TypeAst) tryParseTypeArgsBracketed(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	if (tryTakeOperator(lexer, Operator.less)) {
		immutable ArrWithSize!TypeAst res = parseTypesWithCommas(alloc, allSymbols, lexer);
		takeTypeArgsEnd(alloc, lexer);
		return res;
	} else
		return emptyArrWithSize!TypeAst;
}

private void parseTypesWithCommas(Builder)(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	ref Builder output,
) {
	do {
		add(alloc, output, parseType(alloc, allSymbols, lexer));
	} while (tryTakeToken(lexer, Token.comma));

}

private immutable(ArrWithSize!TypeAst) parseTypesWithCommas(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	ArrWithSizeBuilder!TypeAst res;
	parseTypesWithCommas(alloc, allSymbols, lexer, res);
	return finishArrWithSize(alloc, res);
}

private immutable(ArrWithSize!TypeAst) tryParseTypeArgsAllowSpace(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
) {
	return peekToken(lexer, Token.name)
		? arrWithSizeLiteral(alloc, [parseType(alloc, allSymbols, lexer)])
		: tryParseTypeArgsBracketed(alloc, allSymbols, lexer);
}

immutable(TypeAst) parseType(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	return parseTypeSuffixes(alloc, allSymbols, lexer, parseTypeBeforeSuffixes(alloc, allSymbols, lexer));
}

private immutable(TypeAst) parseTypeBeforeSuffixes(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	switch (nextToken(lexer)) {
		case Token.name:
			immutable NameAndRange name = getCurNameAndRange(lexer, start);
			immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsAllowSpace(alloc, allSymbols, lexer);
			immutable RangeWithinFile rng = range(lexer, start);
			return immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
		case Token.act:
			return parseFunType(alloc, allSymbols, lexer, start, TypeAst.Fun.Kind.act);
		case Token.fun:
			return parseFunType(alloc, allSymbols, lexer, start, TypeAst.Fun.Kind.fun);
		case Token.ref_:
			return parseFunType(alloc, allSymbols, lexer, start, TypeAst.Fun.Kind.ref_);
		default:
			// unexpected type token
			return todo!(immutable TypeAst)("!");
	}
}

immutable(TypeAst) parseFunType(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer, immutable Pos start, immutable TypeAst.Fun.Kind kind) {
	ArrBuilder!TypeAst returnAndParamTypes;
	add(alloc, returnAndParamTypes, parseType(alloc, allSymbols, lexer));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (!tryTakeToken(lexer, Token.parenRight)) {
			parseTypesWithCommas(alloc, allSymbols, lexer, returnAndParamTypes);
			if (!tryTakeToken(lexer, Token.parenRight))
				todo!void("diagnostic -- missing closing paren");
		}
	} else
		addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
			immutable ParseDiag.FunctionTypeMissingParens()));
	return immutable TypeAst(immutable TypeAst.Fun(range(lexer, start), kind, finishArr(alloc, returnAndParamTypes)));
}

private immutable(TypeAst) parseTypeSuffixes(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable TypeAst ast,
) {
	immutable(TypeAst) doSuffix(immutable TypeAst inner, immutable TypeAst.Suffix.Kind kind) {
		return immutable TypeAst(allocate(alloc, immutable TypeAst.Suffix(kind, inner)));
	}

	immutable(TypeAst) handleSuffix(immutable TypeAst.Suffix.Kind kind) {
		return parseTypeSuffixes(alloc, allSymbols, lexer, doSuffix(ast, kind));
	}

	immutable(TypeAst) handleDoubleSuffix(immutable TypeAst.Suffix.Kind kind1, immutable TypeAst.Suffix.Kind kind2) {
		return parseTypeSuffixes(alloc, allSymbols, lexer, doSuffix(doSuffix(ast, kind1), kind2));
	}

	immutable(TypeAst) handleDictLike(immutable TypeAst.Dict.Kind kind) {
		immutable TypeAst inner = parseType(alloc, allSymbols, lexer);
		takeOrAddDiagExpected(alloc, lexer, ']', ParseDiag.Expected.Kind.closingBracket);
		return parseTypeSuffixes(alloc, allSymbols, lexer, immutable TypeAst(
			allocate(alloc, immutable TypeAst.Dict(kind, ast, inner))));
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


void takeTypeArgsEnd(ref Alloc alloc, ref Lexer lexer) {
	takeOrAddDiagExpected(alloc, lexer, '>', ParseDiag.Expected.Kind.typeArgsEnd);
}
