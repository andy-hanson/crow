module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange, range, TypeAst;
import frontend.parse.lexer :
	addDiag,
	curPos,
	Lexer,
	peekExact,
	range,
	takeNameAndRange,
	takeOrAddDiagExpected,
	tryTake;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.collection.arr : ArrWithSize, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
import util.collection.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, shortSymAlphaLiteralValue, Sym;
import util.util : todo;

immutable(ArrWithSize!TypeAst) tryParseTypeArgsBracketed(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	if (tryTake(lexer, '<')) {
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
	} while (tryTake(lexer, ", "));

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
	return !peekExact(lexer, " mut[") &&
		!peekExact(lexer, " mut*") &&
		!peekExact(lexer, " <- ") &&
		!peekExact(lexer, " = ") &&
		tryTake(lexer, ' ')
		? arrWithSizeLiteral(alloc, [parseType(alloc, allSymbols, lexer)])
		: tryParseTypeArgsBracketed(alloc, allSymbols, lexer);
}

immutable(TypeAst) parseType(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	return parseTypeSuffixes(alloc, allSymbols, lexer, parseTypeBeforeSuffixes(alloc, allSymbols, lexer));
}

private immutable(TypeAst) parseTypeBeforeSuffixes(ref Alloc alloc, ref AllSymbols allSymbols, ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	immutable NameAndRange name = takeNameAndRange(alloc, allSymbols, lexer);
	immutable Opt!(TypeAst.Fun.Kind) funKind = funKindFromName(name.name);
	if (has(funKind) && tryTake(lexer, ' ')) {
		ArrBuilder!TypeAst returnAndParamTypes;
		add(alloc, returnAndParamTypes, parseType(alloc, allSymbols, lexer));
		if (tryTake(lexer, '(')) {
			if (!tryTake(lexer, ')')) {
				parseTypesWithCommas(alloc, allSymbols, lexer, returnAndParamTypes);
				if (!tryTake(lexer, ')'))
					todo!void("diagnostic -- missing closing paren");
			}
		} else
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.FunctionTypeMissingParens()));
		return immutable TypeAst(
			immutable TypeAst.Fun(range(lexer, start), force(funKind), finishArr(alloc, returnAndParamTypes)));
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsAllowSpace(alloc, allSymbols, lexer);
		immutable RangeWithinFile rng = range(lexer, start);
		return immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
	}
}

private immutable(TypeAst) parseTypeSuffixes(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref Lexer lexer,
	immutable TypeAst ast,
) {
	immutable Opt!(TypeAst.Suffix.Kind) suffix = tryTakeTypeSuffix(lexer);
	if (has(suffix))
		return parseTypeSuffixes(alloc, allSymbols, lexer, immutable TypeAst(
			allocate(alloc, immutable TypeAst.Suffix(force(suffix), ast))));
	else {
		immutable Opt!(TypeAst.Dict.Kind) dictKind = tryTakeDictKind(lexer);
		if (has(dictKind)) {
			immutable TypeAst inner = parseType(alloc, allSymbols, lexer);
			takeOrAddDiagExpected(alloc, lexer, ']', ParseDiag.Expected.Kind.closingBracket);
			return parseTypeSuffixes(alloc, allSymbols, lexer, immutable TypeAst(
				allocate(alloc, immutable TypeAst.Dict(force(dictKind), ast, inner))));
		} else
			return ast;
	}
}

private immutable(Opt!(TypeAst.Suffix.Kind)) tryTakeTypeSuffix(ref Lexer lexer) {
	return tryTake(lexer, '?')
		? some(TypeAst.Suffix.Kind.opt)
		: tryTake(lexer, "[]")
		? some(TypeAst.Suffix.Kind.arr)
		: tryTake(lexer, " mut[]")
		? some(TypeAst.Suffix.Kind.arrMut)
		: tryTake(lexer, "*")
		? some(TypeAst.Suffix.Kind.ptr)
		: tryTake(lexer, " mut*")
		? some(TypeAst.Suffix.Kind.ptrMut)
		: none!(TypeAst.Suffix.Kind);
}

private immutable(Opt!(TypeAst.Dict.Kind)) tryTakeDictKind(ref Lexer lexer) {
	return tryTake(lexer, '[')
		? some(TypeAst.Dict.Kind.data)
		: tryTake(lexer, " mut[")
		? some(TypeAst.Dict.Kind.mut)
		: none!(TypeAst.Dict.Kind);
}

private immutable(Opt!(TypeAst.Fun.Kind)) funKindFromName(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("act"):
			return some(TypeAst.Fun.Kind.act);
		case shortSymAlphaLiteralValue("fun"):
			return some(TypeAst.Fun.Kind.fun);
		case shortSymAlphaLiteralValue("ref"):
			return some(TypeAst.Fun.Kind.ref_);
		default:
			return none!(TypeAst.Fun.Kind);
	}
}

void takeTypeArgsEnd(ref Alloc alloc, ref Lexer lexer) {
	takeOrAddDiagExpected(alloc, lexer, '>', ParseDiag.Expected.Kind.typeArgsEnd);
}
