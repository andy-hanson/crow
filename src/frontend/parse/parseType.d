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
import model.parseDiag : ParseDiag;
import util.col.arr : small;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral;
import util.memory : allocate;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : sym;
import util.util : todo;

immutable(Opt!(TypeAst*)) tryParseTypeArg(scope ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"<")) {
		immutable TypeAst res = parseType(lexer);
		takeTypeArgsEnd(lexer);
		return some(allocate(lexer.alloc, res));
	} else
		return none!(TypeAst*);
}

immutable(TypeAst[]) tryParseTypeArgsForExpr(scope ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.atLess)) {
		immutable TypeAst[] res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return [];
}

immutable(TypeAst[]) tryParseTypeArgsBracketed(scope ref Lexer lexer) {
	if (tryTakeOperator(lexer, sym!"<")) {
		immutable TypeAst[] res = parseTypesWithCommas(lexer);
		takeTypeArgsEnd(lexer);
		return res;
	} else
		return [];
}

private void parseTypesWithCommas(Builder)(scope ref Lexer lexer, ref Builder output) {
	do {
		add(lexer.alloc, output, parseType(lexer));
	} while (tryTakeToken(lexer, Token.comma));
}

private immutable(TypeAst[]) parseTypesWithCommas(scope ref Lexer lexer) {
	ArrBuilder!TypeAst res;
	parseTypesWithCommas(lexer, res);
	return finishArr(lexer.alloc, res);
}

private immutable(TypeAst[]) tryParseTypeArgsAllowSpaceNoTuple(
	scope ref Lexer lexer,
	immutable RequireBracket requireBracket,
) =>
	peekToken(lexer, Token.name)
		? arrLiteral(lexer.alloc, [parseType(lexer, requireBracket)])
		: tryParseTypeArgsBracketed(lexer);

private immutable(TypeAst[]) tryParseTypeArgsAllowSpace(scope ref Lexer lexer) =>
	peekToken(lexer, Token.parenLeft)
		? arrLiteral(lexer.alloc, [parseType(lexer, RequireBracket.no)])
		: tryParseTypeArgsAllowSpaceNoTuple(lexer, RequireBracket.no);

immutable(TypeAst) parseType(scope ref Lexer lexer) =>
	parseType(lexer, RequireBracket.no);

immutable(TypeAst) parseTypeNoTuple(scope ref Lexer lexer) =>
	parseType(lexer, RequireBracket.forTuple);

immutable(TypeAst) parseTypeRequireBracket(scope ref Lexer lexer) =>
	parseType(lexer, RequireBracket.yes);

private:

enum RequireBracket { no, forTuple, yes }

immutable(TypeAst) parseType(scope ref Lexer lexer, immutable RequireBracket requireBracket) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, requireBracket));

immutable(TypeAst) parseTypeBeforeSuffixes(scope ref Lexer lexer, immutable RequireBracket requireBracket) {
	immutable Pos start = curPos(lexer);
	immutable Token token = nextToken(lexer);
	switch (token) {
		case Token.name:
			immutable NameAndRange name = getCurNameAndRange(lexer, start);
			immutable TypeAst[] typeArgs = () {
				final switch (requireBracket) {
					case RequireBracket.no:
						return tryParseTypeArgsAllowSpace(lexer);
					case RequireBracket.forTuple:
						return tryParseTypeArgsAllowSpaceNoTuple(lexer, requireBracket);
					case RequireBracket.yes:
						return tryParseTypeArgsBracketed(lexer);
				}
			}();
			immutable RangeWithinFile rng = range(lexer, start);
			return immutable TypeAst(immutable TypeAst.InstStruct(rng, name, small(typeArgs)));
		case Token.parenLeft:
			return parseTupleType(lexer, start);
		case Token.act:
			return parseFunType(lexer, start, TypeAst.Fun.Kind.act);
		case Token.fun:
			return parseFunType(
				lexer,
				start,
				tryTakeOperator(lexer, sym!"*") ? TypeAst.Fun.Kind.funPointer : TypeAst.Fun.Kind.fun);
		case Token.ref_:
			return parseFunType(lexer, start, TypeAst.Fun.Kind.ref_);
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return bogusTypeAst(range(lexer, start));
	}
}

immutable(TypeAst) parseTupleType(scope ref Lexer lexer, immutable Pos start) {
	immutable TypeAst a = parseType(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.comma, ParseDiag.Expected.Kind.comma);
	immutable TypeAst b = parseType(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	return immutable TypeAst(allocate(lexer.alloc, immutable TypeAst.Tuple(a, b)));
}

immutable(TypeAst) parseFunType(scope ref Lexer lexer, immutable Pos start, immutable TypeAst.Fun.Kind kind) {
	ArrBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer, RequireBracket.forTuple));
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

immutable(TypeAst) parseTypeSuffixes(scope ref Lexer lexer, immutable TypeAst ast) {
	immutable(TypeAst) doSuffix(immutable TypeAst inner, immutable TypeAst.Suffix.Kind kind) =>
		immutable TypeAst(allocate(lexer.alloc, immutable TypeAst.Suffix(kind, inner)));

	immutable(TypeAst) handleSuffix(immutable TypeAst.Suffix.Kind kind) =>
		parseTypeSuffixes(lexer, doSuffix(ast, kind));

	immutable(TypeAst) handleDoubleSuffix(immutable TypeAst.Suffix.Kind kind1, immutable TypeAst.Suffix.Kind kind2) =>
		parseTypeSuffixes(lexer, doSuffix(doSuffix(ast, kind1), kind2));

	immutable(TypeAst) handleDictLike(immutable TypeAst.Dict.Kind kind) {
		immutable TypeAst inner = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return parseTypeSuffixes(lexer, immutable TypeAst(
			allocate(lexer.alloc, immutable TypeAst.Dict(kind, ast, inner))));
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
