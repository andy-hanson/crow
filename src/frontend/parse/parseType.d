module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	alloc,
	curPos,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	range,
	rangeAtChar,
	rangeForCurToken,
	takeNextToken,
	Token;
import frontend.parse.parseUtil :
	addDiagExpected, takeOrAddDiagExpectedToken, tryTakeNameAndRange, tryTakeOperator, tryTakeToken;
import model.ast : NameAndRange, range, TypeAst;
import model.model : FunKind;
import model.parseDiag : ParseDiag;
import util.col.array : only, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, smallFinish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos;
import util.symbol : symbol;

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

private SmallArray!TypeAst parseTypesWithCommasThenClosingParen(ref Lexer lexer) {
	ArrayBuilder!TypeAst res;
	parseTypesWithCommasThenClosingParen(lexer, res);
	return smallFinish(lexer.alloc, res);
}

private void parseTypesWithCommasThenClosingParen(ref Lexer lexer, scope ref ArrayBuilder!TypeAst res) {
	if (!tryTakeToken(lexer, Token.parenRight)) {
		do {
			add(lexer.alloc, res, parseType(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	}
}

TypeAst parseType(ref Lexer lexer) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.unnecessary));

TypeAst parseTypeForTypedExpr(ref Lexer lexer) =>
	parseTypeSuffixesNonName(lexer, parseTypeBeforeSuffixes(lexer, ParenthesesNecessary.necessary));

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
		case Token.act:
			takeNextToken(lexer);
			return parseFunType(lexer, start, FunKind.act);
		case Token.far:
			takeNextToken(lexer);
			return parseFunType(lexer, start, FunKind.far);
		case Token.fun:
			takeNextToken(lexer);
			return parseFunType(lexer, start, tryTakeOperator(lexer, symbol!"*") ? FunKind.pointer : FunKind.fun);
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

TypeAst parseFunType(ref Lexer lexer, Pos start, FunKind kind) {
	ArrayBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		parseTypesWithCommasThenClosingParen(lexer, returnAndParamTypes);
	} else
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.FunctionTypeMissingParens()));
	SmallArray!TypeAst types = smallFinish(lexer.alloc, returnAndParamTypes);
	return TypeAst(allocate(lexer.alloc, TypeAst.Fun(range(lexer, start), kind, types)));
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
		if (tryTakeToken(lexer, Token.bracketLeft))
			return tryTakeToken(lexer, Token.bracketRight)
				? suffix(TypeAst.SuffixSpecial.Kind.mutList)
				: mapLike(TypeAst.Map.Kind.mut);
		else if (tryTakeOperator(lexer, symbol!"*"))
			return suffix(TypeAst.SuffixSpecial.Kind.mutPtr);
		else if (tryTakeOperator(lexer, symbol!"**"))
			return doubleSuffix(TypeAst.SuffixSpecial.Kind.mutPtr, TypeAst.SuffixSpecial.Kind.ptr);
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.afterMut);
			return none!TypeAst;
		}
	} else
		return none!TypeAst;
}
