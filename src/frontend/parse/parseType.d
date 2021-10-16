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
import util.collection.arr : ArrWithSize, emptyArrWithSize;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
import util.collection.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : shortSymAlphaLiteralValue, Sym;
import util.util : todo;

immutable(TypeAst.InstStruct) parseTypeInstStruct(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable NameAndRange name = takeNameAndRange(alloc, lexer);
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
	return immutable TypeAst.InstStruct(range(lexer, start), name, typeArgs);
}

immutable(ArrWithSize!TypeAst) tryParseTypeArgsBracketed(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		immutable ArrWithSize!TypeAst res = parseTypesWithCommas(alloc, lexer);
		takeTypeArgsEnd(alloc, lexer);
		return res;
	} else
		return emptyArrWithSize!TypeAst;
}

private void parseTypesWithCommas(Alloc, SymAlloc, Builder)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref Builder output,
) {
	do {
		add(alloc, output, parseType(alloc, lexer));
	} while (tryTake(lexer, ", "));

}

private immutable(ArrWithSize!TypeAst) parseTypesWithCommas(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	ArrWithSizeBuilder!TypeAst res;
	parseTypesWithCommas(alloc, lexer, res);
	return finishArrWithSize(alloc, res);
}

private immutable(ArrWithSize!TypeAst) tryParseTypeArgsAllowSpace(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	return !peekExact(lexer, " mut[") &&
		!peekExact(lexer, " mut*") &&
		!peekExact(lexer, " <- ") &&
		!peekExact(lexer, " = ") &&
		tryTake(lexer, ' ')
		? arrWithSizeLiteral(alloc, [parseType(alloc, lexer)])
		: tryParseTypeArgsBracketed(alloc, lexer);
}

immutable(TypeAst) parseType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return parseTypeSuffixes(alloc, lexer, parseTypeBeforeSuffixes(alloc, lexer));
}

private immutable(TypeAst) parseTypeBeforeSuffixes(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable NameAndRange name = takeNameAndRange(alloc, lexer);
	immutable Opt!(TypeAst.Fun.Kind) funKind = funKindFromName(name.name);
	if (has(funKind) && tryTake(lexer, ' ')) {
		ArrBuilder!TypeAst returnAndParamTypes;
		add(alloc, returnAndParamTypes, parseType(alloc, lexer));
		if (tryTake(lexer, '(')) {
			if (!tryTake(lexer, ')')) {
				parseTypesWithCommas(alloc, lexer, returnAndParamTypes);
				if (!tryTake(lexer, ')'))
					todo!void("diagnostic -- missing closing paren");
			}
		} else
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.FunctionTypeMissingParens()));
		return immutable TypeAst(
			immutable TypeAst.Fun(range(lexer, start), force(funKind), finishArr(alloc, returnAndParamTypes)));
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsAllowSpace(alloc, lexer);
		immutable RangeWithinFile rng = range(lexer, start);
		return immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
	}
}

private immutable(TypeAst) parseTypeSuffixes(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable TypeAst ast,
) {
	immutable Opt!(TypeAst.Suffix.Kind) suffix = tryTakeTypeSuffix(lexer);
	if (has(suffix))
		return parseTypeSuffixes(alloc, lexer, immutable TypeAst(
			immutable TypeAst.Suffix(force(suffix), allocate(alloc, ast))));
	else {
		immutable Opt!(TypeAst.Dict.Kind) dictKind = tryTakeDictKind(lexer);
		if (has(dictKind)) {
			immutable TypeAst inner = parseType(alloc, lexer);
			takeOrAddDiagExpected(alloc, lexer, ']', ParseDiag.Expected.Kind.closingBracket);
			return parseTypeSuffixes(alloc, lexer, immutable TypeAst(
				immutable TypeAst.Dict(force(dictKind), allocate(alloc, ast), allocate(alloc, inner))));
		} else
			return ast;
	}
}

private immutable(Opt!(TypeAst.Suffix.Kind)) tryTakeTypeSuffix(SymAlloc)(ref Lexer!SymAlloc lexer) {
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

private immutable(Opt!(TypeAst.Dict.Kind)) tryTakeDictKind(SymAlloc)(ref Lexer!SymAlloc lexer) {
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

void takeTypeArgsEnd(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	takeOrAddDiagExpected(alloc, lexer, '>', ParseDiag.Expected.Kind.typeArgsEnd);
}
