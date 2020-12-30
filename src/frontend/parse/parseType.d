module frontend.parse.parseType;

@safe @nogc pure nothrow:

import frontend.parse.ast : matchTypeAst, NameAndRange, range, TypeAst;
import frontend.parse.lexer : addDiag, curPos, Lexer, range, takeNameAndRange, takeOrAddDiagExpected, tryTake;
import model.parseDiag : ParseDiag;
import util.bools : Bool;
import util.collection.arr : Arr, ArrWithSize, at, empty, emptyArrWithSize, toArr;
import util.collection.arrBuilder : add, ArrWithSizeBuilder, finishArr;
import util.collection.arrUtil : arrWithSizeLiteral;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.util : todo;

immutable(TypeAst.InstStruct) parseTypeInstStruct(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable NameAndRange name = takeNameAndRange(alloc, lexer);
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
	return immutable TypeAst.InstStruct(range(lexer, start), name, typeArgs);
}

immutable(ArrWithSize!TypeAst) tryParseTypeArgsBracketed(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		ArrWithSizeBuilder!TypeAst res;
		do {
			add(alloc, res, parseType(alloc, lexer));
		} while (tryTake(lexer, ", "));
		takeTypeArgsEnd(alloc, lexer);
		return finishArr(alloc, res);
	} else
		return emptyArrWithSize!TypeAst;
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

immutable(TypeAst.InstStruct) parseStructType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable TypeAst t = parseType(alloc, lexer);
	return matchTypeAst(t,
		(ref immutable TypeAst.TypeParam) {
			return todo!(immutable TypeAst.InstStruct)("must be a struct");
		},
		(ref immutable TypeAst.InstStruct i) => i,
	);
}

immutable(TypeAst) parseType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable Bool isTypeParam = tryTake(lexer, '?');
	immutable NameAndRange name = takeNameAndRange(alloc, lexer);
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

void takeTypeArgsEnd(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	takeOrAddDiagExpected(alloc, lexer, '>', ParseDiag.Expected.Kind.typeArgsEnd);
}
