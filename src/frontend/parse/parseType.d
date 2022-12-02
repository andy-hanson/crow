module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : bogusTypeAst, NameAndRange, range, TypeAst;
import frontend.parse.lexer :
	addDiag,
	addDiagExpected,
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
import model.model : FunKind;
import model.parseDiag : ParseDiag;
import util.col.arr : small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral;
import util.memory : allocate;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : sym;
import util.util : todo;

Opt!(TypeAst*) tryParseTypeArg(ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"<")) {
		TypeAst res = parseType(lexer);
		takeTypeArgsEnd(lexer);
		return some(allocate(lexer.alloc, res));
	} else
		return none!(TypeAst*);
}

TypeAst[] tryParseTypeArgsForExpr(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.atLess)) {
		TypeAst[] res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return [];
}

TypeAst[] tryParseTypeArgsBracketed(ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"<")) {
		TypeAst[] res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return [];
}

private void parseTypesWithCommas(Builder)(ref Lexer lexer, ref Builder output) {
	do {
		add(lexer.alloc, output, parseType(lexer));
	} while (tryTakeToken(lexer, Token.comma));
}

private TypeAst[] parseTypesWithCommas(ref Lexer lexer) {
	ArrBuilder!TypeAst res;
	parseTypesWithCommas(lexer, res);
	return finishArr(lexer.alloc, res);
}

private TypeAst[] tryParseTypeArgsAllowSpaceNoTuple(ref Lexer lexer, RequireBracket requireBracket) =>
	peekToken(lexer, Token.name)
		? arrLiteral(lexer.alloc, [parseType(lexer, requireBracket)])
		: tryParseTypeArgsBracketed(lexer);

private TypeAst[] tryParseTypeArgsAllowSpace(ref Lexer lexer) =>
	peekToken(lexer, Token.parenLeft)
		? arrLiteral(lexer.alloc, [parseType(lexer, RequireBracket.no)])
		: tryParseTypeArgsAllowSpaceNoTuple(lexer, RequireBracket.no);

TypeAst parseType(ref Lexer lexer) =>
	parseType(lexer, RequireBracket.no);

TypeAst parseTypeNoTuple(ref Lexer lexer) =>
	parseType(lexer, RequireBracket.forTuple);

TypeAst parseTypeRequireBracket(ref Lexer lexer) =>
	parseType(lexer, RequireBracket.yes);

private:

enum RequireBracket { no, forTuple, yes }

TypeAst parseType(ref Lexer lexer, RequireBracket requireBracket) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, requireBracket));

TypeAst parseTypeBeforeSuffixes(ref Lexer lexer, RequireBracket requireBracket) {
	Pos start = curPos(lexer);
	Token token = nextToken(lexer);
	switch (token) {
		case Token.name:
			NameAndRange name = getCurNameAndRange(lexer, start);
			TypeAst[] typeArgs = () {
				final switch (requireBracket) {
					case RequireBracket.no:
						return tryParseTypeArgsAllowSpace(lexer);
					case RequireBracket.forTuple:
						return tryParseTypeArgsAllowSpaceNoTuple(lexer, requireBracket);
					case RequireBracket.yes:
						return tryParseTypeArgsBracketed(lexer);
				}
			}();
			RangeWithinFile rng = range(lexer, start);
			return TypeAst(TypeAst.InstStruct(rng, name, small(typeArgs)));
		case Token.parenLeft:
			return parseTupleType(lexer, start);
		case Token.act:
			return parseFunType(lexer, start, FunKind.act);
		case Token.fun:
			return parseFunType(
				lexer,
				start,
				tryTakeOperator(lexer, sym!"*") ? FunKind.pointer : FunKind.fun);
		case Token.ref_:
			return parseFunType(lexer, start, FunKind.ref_);
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return bogusTypeAst(range(lexer, start));
	}
}

TypeAst parseTupleType(ref Lexer lexer, Pos start) {
	TypeAst a = parseType(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma);
	TypeAst b = parseType(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	return TypeAst(allocate(lexer.alloc, TypeAst.Tuple(a, b)));
}

TypeAst parseFunType(ref Lexer lexer, Pos start, FunKind kind) {
	ArrBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer, RequireBracket.forTuple));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (!tryTakeToken(lexer, Token.parenRight)) {
			parseTypesWithCommas(lexer, returnAndParamTypes);
			if (!tryTakeToken(lexer, Token.parenRight))
				todo!void("diagnostic -- missing closing paren");
		}
	} else
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.FunctionTypeMissingParens()));
	return TypeAst(TypeAst.Fun(range(lexer, start), kind, finishArr(lexer.alloc, returnAndParamTypes)));
}

TypeAst parseTypeSuffixes(ref Lexer lexer, TypeAst ast) {
	TypeAst doSuffix(TypeAst inner, TypeAst.Suffix.Kind kind) {
		return TypeAst(allocate(lexer.alloc, TypeAst.Suffix(kind, inner)));
	}
	TypeAst handleSuffix(TypeAst.Suffix.Kind kind) {
		return parseTypeSuffixes(lexer, doSuffix(ast, kind));
	}
	TypeAst handleDoubleSuffix(TypeAst.Suffix.Kind kind1, TypeAst.Suffix.Kind kind2) {
		return parseTypeSuffixes(lexer, doSuffix(doSuffix(ast, kind1), kind2));
	}
	TypeAst handleDictLike(TypeAst.Dict.Kind kind) {
		TypeAst inner = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return parseTypeSuffixes(lexer, TypeAst(allocate(lexer.alloc, TypeAst.Dict(kind, ast, inner))));
	}

	if (tryTakeToken(lexer, Token.question))
		return handleSuffix(TypeAst.Suffix.Kind.option);
	else if (tryTakeToken(lexer, Token.bracketLeft))
		return tryTakeToken(lexer, Token.bracketRight)
			? handleSuffix(TypeAst.Suffix.Kind.list)
			: handleDictLike(TypeAst.Dict.Kind.data);
	else if (tryTakeOperator(lexer, sym!"^"))
		return handleSuffix(TypeAst.Suffix.Kind.future);
	else if (tryTakeOperator(lexer, sym!"*"))
		return handleSuffix(TypeAst.Suffix.Kind.ptr);
	else if (tryTakeOperator(lexer, sym!"**"))
		return handleDoubleSuffix(TypeAst.Suffix.Kind.ptr, TypeAst.Suffix.Kind.ptr);
	else if (tryTakeToken(lexer, Token.mut)) {
		if (tryTakeToken(lexer, Token.bracketLeft))
			return tryTakeToken(lexer, Token.bracketRight)
				? handleSuffix(TypeAst.Suffix.Kind.mutList)
				: handleDictLike(TypeAst.Dict.Kind.mut);
		else if (tryTakeOperator(lexer, sym!"*"))
			return handleSuffix(TypeAst.Suffix.kind.mutPtr);
		else if (tryTakeOperator(lexer, sym!"**"))
			return handleDoubleSuffix(TypeAst.Suffix.Kind.mutPtr, TypeAst.Suffix.Kind.ptr);
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.afterMut);
			return ast;
		}
	} else
		return ast;
}
