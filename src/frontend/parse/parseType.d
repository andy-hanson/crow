module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : range, TypeAst;
import frontend.parse.lexer :
	addDiag,
	addDiagExpected,
	addDiagUnexpectedCurToken,
	alloc,
	curPos,
	getCurNameAndRange,
	Lexer,
	nextToken,
	range,
	takeOrAddDiagExpectedToken,
	Token,
	tryTakeOperator,
	tryTakeToken;
import model.model : FunKind;
import model.parseDiag : ParseDiag;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos;
import util.sym : sym;
import util.util : todo;

Opt!(TypeAst*) tryParseTypeArgForEnumOrFlags(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenLeft)) {
		TypeAst res = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		return some(allocate(lexer.alloc, res));
	} else
		return none!(TypeAst*);
}

Opt!(TypeAst*) tryParseTypeArgForExpr(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.at)
		? some(allocate(lexer.alloc, parseTypeForTypedExpr(lexer)))
		: none!(TypeAst*);

private void parseTypesWithCommas(ref Lexer lexer, ref ArrBuilder!TypeAst output) {
	do {
		add(lexer.alloc, output, parseType(lexer));
	} while (tryTakeToken(lexer, Token.comma));
}

private TypeAst[] parseTypesWithCommas(ref Lexer lexer) {
	ArrBuilder!TypeAst res;
	parseTypesWithCommas(lexer, res);
	return finishArr(lexer.alloc, res);
}

TypeAst parseType(ref Lexer lexer) =>
	parseTypeSuffixes(lexer, parseTypeBeforeSuffixes(lexer));

TypeAst parseTypeForTypedExpr(ref Lexer lexer) =>
	parseTypeSuffixesNonName(lexer, parseTypeBeforeSuffixes(lexer));

private:

TypeAst parseTypeBeforeSuffixes(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Token token = nextToken(lexer);
	switch (token) {
		case Token.name:
			return TypeAst(getCurNameAndRange(lexer, start));
		case Token.parenLeft:
			return parseTupleType(lexer, start);
		case Token.act:
			return parseFunType(lexer, start, FunKind.act);
		case Token.fun:
			return parseFunType(lexer, start, tryTakeOperator(lexer, sym!"*") ? FunKind.pointer : FunKind.fun);
		case Token.ref_:
			return parseFunType(lexer, start, FunKind.ref_);
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return TypeAst(TypeAst.Bogus(range(lexer, start)));
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
	ArrBuilder!TypeAst returnAndParamTypes;
	add(lexer.alloc, returnAndParamTypes, parseType(lexer));
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (!tryTakeToken(lexer, Token.parenRight)) {
			parseTypesWithCommas(lexer, returnAndParamTypes);
			takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
		}
	} else
		addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.FunctionTypeMissingParens()));
	return TypeAst(allocate(lexer.alloc,
		TypeAst.Fun(range(lexer, start), kind, finishArr(lexer.alloc, returnAndParamTypes))));
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
	Pos namePos = curPos(lexer);
	return !has(res) && tryTakeToken(lexer, Token.name)
		? some(TypeAst(allocate(lexer.alloc, TypeAst.SuffixName(left, getCurNameAndRange(lexer, namePos)))))
		: res;
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
	Opt!TypeAst dictLike(TypeAst.Dict.Kind kind) {
		TypeAst key = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
		return some(TypeAst(allocate(lexer.alloc, TypeAst.Dict(kind, left, key))));
	}

	if (tryTakeToken(lexer, Token.question))
		return suffix(TypeAst.SuffixSpecial.Kind.option);
	else if (tryTakeToken(lexer, Token.bracketLeft))
		return tryTakeToken(lexer, Token.bracketRight)
			? suffix(TypeAst.SuffixSpecial.Kind.list)
			: dictLike(TypeAst.Dict.Kind.data);
	else if (tryTakeOperator(lexer, sym!"^"))
		return suffix(TypeAst.SuffixSpecial.Kind.future);
	else if (tryTakeOperator(lexer, sym!"*"))
		return suffix(TypeAst.SuffixSpecial.Kind.ptr);
	else if (tryTakeOperator(lexer, sym!"**"))
		return doubleSuffix(TypeAst.SuffixSpecial.Kind.ptr, TypeAst.SuffixSpecial.Kind.ptr);
	else if (tryTakeToken(lexer, Token.mut)) {
		if (tryTakeToken(lexer, Token.bracketLeft))
			return tryTakeToken(lexer, Token.bracketRight)
				? suffix(TypeAst.SuffixSpecial.Kind.mutList)
				: dictLike(TypeAst.Dict.Kind.mut);
		else if (tryTakeOperator(lexer, sym!"*"))
			return suffix(TypeAst.SuffixSpecial.Kind.mutPtr);
		else if (tryTakeOperator(lexer, sym!"**"))
			return doubleSuffix(TypeAst.SuffixSpecial.Kind.mutPtr, TypeAst.SuffixSpecial.Kind.ptr);
		else {
			addDiagExpected(lexer, ParseDiag.Expected.Kind.afterMut);
			return none!TypeAst;
		}
	} else
		return none!TypeAst;
}
