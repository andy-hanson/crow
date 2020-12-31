module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : NameAndRange, range, TypeAst;
import frontend.parse.lexer : addDiag, curPos, Lexer, range, takeNameAndRange, takeOrAddDiagExpected, tryTake;
import model.parseDiag : ParseDiag;
import util.bools : Bool;
import util.collection.arr : Arr, ArrWithSize, at, empty, emptyArrWithSize, toArr;
import util.collection.arrBuilder : add, ArrBuilder, ArrWithSizeBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
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
	return finishArr(alloc, res);
}

private immutable(ArrWithSize!TypeAst) tryParseTypeArgsAllowSpace(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	return tryTake(lexer, ' ')
		? arrWithSizeLiteral(alloc, [parseType(alloc, lexer)])
		: tryParseTypeArgsBracketed(alloc, lexer);
}

immutable(Opt!TypeAst) tryParseTypeArgBracketed(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		immutable TypeAst res = parseType(alloc, lexer);
		takeTypeArgsEnd(alloc, lexer);
		return some(res);
	} else
		return none!TypeAst;
}

immutable(TypeAst) parseType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable Bool isTypeParam = tryTake(lexer, '?');
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
			return immutable TypeAst(
				immutable TypeAst.Fun(range(lexer, start), force(funKind), finishArr(alloc, returnAndParamTypes)));
		} else
			return todo!(immutable TypeAst)("diagnostic -- function type missing parens");
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsAllowSpace(alloc, lexer);
		immutable Arr!TypeAst typeArgsArr = toArr(typeArgs);
		if (isTypeParam && !empty(typeArgsArr))
			addDiag(alloc, lexer, at(typeArgsArr, 0).range,
				immutable ParseDiag(immutable ParseDiag.TypeParamCantHaveTypeArgs()));
		immutable RangeWithinFile rng = range(lexer, start);
		return isTypeParam
			? immutable TypeAst(immutable TypeAst.TypeParam(rng, name.name))
			: immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
	}
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
