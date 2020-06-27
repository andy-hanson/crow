module frontend.parseType;

@safe @nogc pure nothrow:

import frontend.ast : match, TypeAst;
import frontend.lexer : curPos, Lexer, range, take, takeName, throwAtChar, tryTake;

import parseDiag : ParseDiag;

import util.bools : Bool, False, True;
import util.collection.arr : Arr, empty;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : none, Opt, some;
import util.sourceRange : Pos, SourceRange;
import util.sym : Sym;
import util.util : todo;

immutable(Arr!TypeAst) tryParseTypeArgs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return tryParseTypeArgsWorker(alloc, lexer, True);
}

immutable(Opt!TypeAst) tryParseTypeArg(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (lexer.tryTake('<')) {
		immutable TypeAst res = parseTypeWorker(alloc, lexer, True);
		lexer.take('>');
		return some(res);
	} else
		return none!TypeAst;
}

immutable(TypeAst.InstStruct) parseStructType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable TypeAst t = parseType(alloc, lexer);
	return t.match(
		(ref immutable TypeAst.TypeParam) {
			return todo!(immutable TypeAst.InstStruct)("must be a struct");
		},
		(ref immutable TypeAst.InstStruct i) => i,
	);
}

immutable(TypeAst) parseType(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	return parseTypeWorker(alloc, lexer, False);
}

private:

immutable(Arr!TypeAst) tryParseTypeArgsWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isInner,
) {
	ArrBuilder!TypeAst res;
	// Require '<>' if parsing type args inside of type args.
	if (!isInner || lexer.tryTake('<')) {
		for (;;) {
			if (!isInner && !lexer.tryTake(' '))
				break;
			res.add(alloc, parseTypeWorker(alloc, lexer, True));
			if (isInner)
				lexer.take('>');
		}
	}
	return res.finishArr(alloc);
}

immutable(TypeAst) parseTypeWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Bool isInner,
) {
	immutable Pos start = lexer.curPos;
	immutable Bool isTypeParam = lexer.tryTake('?');
	immutable Sym name = lexer.takeName();
	immutable Arr!TypeAst typeArgs = tryParseTypeArgsWorker(alloc, lexer, isInner);
	if (isTypeParam && !typeArgs.empty)
		return lexer.throwAtChar!TypeAst(ParseDiag(ParseDiag.TypeParamCantHaveTypeArgs()));
	immutable SourceRange rng = lexer.range(start);
	return isTypeParam
		? TypeAst(TypeAst.TypeParam(rng, name))
		: TypeAst(TypeAst.InstStruct(rng, name, typeArgs));
}
