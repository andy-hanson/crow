module frontend.parseType;

@safe @nogc pure nothrow:

import frontend.ast : matchTypeAst, NameAndRange, range, TypeAst;
import frontend.lexer : addDiag, addDiagAtChar, curPos, Lexer, range, takeNameAndRange, takeOrAddDiagExpected, tryTake;

import parseDiag : ParseDiag;

import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, at, empty, toArr;
import util.collection.arrBuilder : add, ArrWithSizeBuilder, finishArr;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, SourceRange;
import util.sym : Sym;
import util.util : todo;

immutable(ArrWithSize!TypeAst) tryParseTypeArgs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return tryParseTypeArgsWorker(alloc, lexer, True);
}

immutable(Opt!TypeAst) tryParseTypeArg(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, '<')) {
		immutable TypeAst res = parseTypeWorker(alloc, lexer, True);
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
	return parseTypeWorker(alloc, lexer, False);
}

void takeTypeArgsEnd(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	takeOrAddDiagExpected(alloc, lexer, '>', ParseDiag.Expected.Kind.typeArgsEnd);
}

private:

immutable(ArrWithSize!TypeAst) tryParseTypeArgsWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isInner,
) {
	ArrWithSizeBuilder!TypeAst res;
	// Require '<>' if parsing type args inside of type args.
	if (!isInner || tryTake(lexer, '<')) {
		for (;;) {
			if (!isInner && !tryTake(lexer, ' '))
				break;
			add(alloc, res, parseTypeWorker(alloc, lexer, True));
			if (isInner && !tryTake(lexer, ", "))
				break;
		}
		if (isInner)
			takeTypeArgsEnd(alloc, lexer);
	}
	return finishArr(alloc, res);
}

immutable(TypeAst) parseTypeWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isInner,
) {
	immutable Pos start = curPos(lexer);
	immutable Bool isTypeParam = tryTake(lexer, '?');
	immutable NameAndRange name = takeNameAndRange(alloc, lexer);
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsWorker(alloc, lexer, isInner);
	immutable Arr!TypeAst typeArgsArr = toArr(typeArgs);
	if (isTypeParam && !empty(typeArgsArr))
		addDiag(alloc, lexer, at(typeArgsArr, 0).range,
			immutable ParseDiag(immutable ParseDiag.TypeParamCantHaveTypeArgs()));
	immutable SourceRange rng = range(lexer, start);
	return isTypeParam
		? immutable TypeAst(immutable TypeAst.TypeParam(rng, name.name))
		: immutable TypeAst(immutable TypeAst.InstStruct(rng, name, typeArgs));
}
