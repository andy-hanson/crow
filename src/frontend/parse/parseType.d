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
import util.col.array : only;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos;
import util.symbol : symbol;
import util.util : todo;

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

private void parseTypesWithCommas(ref Lexer lexer, ref ArrayBuilder!TypeAst output) {
	do {
		add(lexer.alloc, output, parseType(lexer));
	} while (tryTakeToken(lexer, Token.comma));
}

private TypeAst[] parseTypesWithCommas(ref Lexer lexer) {
	ArrayBuilder!TypeAst res;
	parseTypesWithCommas(lexer, res);
	return finish(lexer.alloc, res);
}

TypeAst parseType(ref Lexer lexer) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer));

TypeAst parseTypeForTypedExpr(ref Lexer lexer) =>
	parseTypeSuffixesNonName(lexer, parseTypeBeforeSuffixes(lexer));

private:

TypeAst parseTypeBeforeSuffixes(ref Lexer lexer) {
	Pos start = curPos(lexer);
	switch (getPeekToken(lexer)) {
		case Token.name:
			return TypeAst(NameAndRange(start, takeNextToken(lexer).asSymbol));
		case Token.parenLeft:
			takeNextToken(lexer);
			return parseTupleType(lexer, start);
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

TypeAst parseTupleType(ref Lexer lexer, Pos start) {
	//TODO:PERF avoid allocating args for the 0/1 cases
	TypeAst[] args = parseTypesWithCommas(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
	switch (args.length) {
		case 0:
			return todo!TypeAst("diagnostic -- did you mean 'void'?");
		case 1:
			return only(args);
		default:
			return TypeAst(allocate(lexer.alloc, TypeAst.Tuple(range(lexer, start), args)));
	}
}

TypeAst parseFunType(ref Lexer lexer, Pos start, FunKind kind) {
	ArrayBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (!tryTakeToken(lexer, Token.parenRight)) {
			parseTypesWithCommas(lexer, returnAndParamTypes);
			takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		}
	} else
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.FunctionTypeMissingParens()));
	TypeAst[] types = finish(lexer.alloc, returnAndParamTypes);
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
	Opt!TypeAst suffix(TypeAst.SuffixSpecial.Kind kind) {
		return some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(left, suffixPos, kind))));
	}
	Opt!TypeAst doubleSuffix(TypeAst.SuffixSpecial.Kind kind1, TypeAst.SuffixSpecial.Kind kind2) {
		return some(TypeAst(
			allocate(lexer.alloc, TypeAst.SuffixSpecial(
				TypeAst(allocate(lexer.alloc, TypeAst.SuffixSpecial(left, suffixPos, kind2))),
				suffixPos + 1,
				kind1))));
	}
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
