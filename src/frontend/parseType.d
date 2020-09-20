module frontend.parseType;

@safe @nogc pure nothrow:

import frontend.ast : matchTypeAst, range, TypeAst;
import frontend.lexer : addDiag, addDiagAtChar, curPos, Lexer, range, takeName, takeOrAddDiagExpected, tryTake;

import parseDiag : ParseDiag;

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, SourceRange;
import util.sym : Sym;
import util.util : todo;

immutable(Arr!TypeAst) tryParseTypeArgs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
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

immutable(Arr!TypeAst) tryParseTypeArgsWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isInner,
) {
	ArrBuilder!TypeAst res;
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
	immutable Sym name = takeName(alloc, lexer);
	immutable Arr!TypeAst typeArgs = tryParseTypeArgsWorker(alloc, lexer, isInner);
	if (isTypeParam && !empty(typeArgs))
		addDiag(alloc, lexer, at(typeArgs, 0).range,
			immutable ParseDiag(immutable ParseDiag.TypeParamCantHaveTypeArgs()));
	immutable SourceRange rng = range(lexer, start);
	return isTypeParam
		? TypeAst(TypeAst.TypeParam(rng, name))
		: TypeAst(TypeAst.InstStruct(rng, name, typeArgs));
}
