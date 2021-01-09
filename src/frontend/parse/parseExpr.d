module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	asIdentifier,
	BogusAst,
	CallAst,
	CreateArrAst,
	ExprAst,
	ExprAstKind,
	FunPtrAst,
	IdentifierAst,
	IfAst,
	isIdentifier,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	NameAndRange,
	SeqAst,
	ThenAst,
	TypeAst;
import frontend.parse.lexer :
	asAmpersandAndName,
	addDiag,
	addDiagAtChar,
	asLiteral,
	asNameAndRange,
	curChar,
	curPos,
	ExpressionToken,
	IndentDelta,
	isNameAndRange,
	Lexer,
	matchIndentDelta,
	range,
	skipUntilNewlineNoDiag,
	takeExpressionToken,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeNameAndRange,
	takeNewlineOrDedentAmount,
	takeOrAddDiagExpected,
	tryTake,
	tryTakeIndentOrDedent;
import frontend.parse.parseType : tryParseTypeArgBracketed, tryParseTypeArgsBracketed;
import model.parseDiag : ParseDiag;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, empty, emptyArr, only, toArr;
import util.collection.arrUtil : arrLiteral, exists, prepend;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : shortSymAlphaLiteral, symEq;
import util.types : u32;
import util.util : todo, unreachable, verify;

immutable(ExprAst) parseFunExprBody(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	if (takeIndentOrDiagTopLevel(alloc, lexer)) {
		immutable ExprAndDedent ed = parseStatementsAndExtraDedents(alloc, lexer, 1);
		verify(ed.dedents == 0); // Since we started at the root, can't dedent more
		return ed.expr;
	} else
		return bogusExpr(range(lexer, start));
}

private:

immutable(ExprAst) bogusExpr(immutable RangeWithinFile range) {
	return immutable ExprAst(range, immutable ExprAstKind(immutable BogusAst()));
}

immutable(Ptr!ExprAst) allocExpr(Alloc)(ref Alloc alloc, immutable ExprAst e) {
	return allocate(alloc, e);
}

struct ArgCtx {
	// Allow things like 'if', 'match', '\' that continue into an indented block.
	immutable Bool allowBlock;
	// In `a b: c d e`, we parse `a b (c d e) and not `(a b c) d e`, since `: turns on `allowCall`.
	immutable Bool allowCall;
}

struct ExprAndDedent {
	immutable ExprAst expr;
	immutable size_t dedents;
}

// dedent=none means we didn't see a newline.
// dedent=0 means a newline was parsed and is on the same indent level.
struct ExprAndMaybeDedent {
	immutable ExprAst expr;
	immutable Opt!size_t dedents;
}

struct OptExprAndDedent {
	immutable Opt!(Ptr!ExprAst) expr;
	immutable size_t dedents;
}

struct ArgsAndMaybeDedent {
	immutable Arr!ExprAst args;
	immutable Opt!size_t dedent;
}

immutable(ExprAndMaybeDedent) noDedent(immutable ExprAst e) {
	return immutable ExprAndMaybeDedent(e, none!size_t);
}

immutable(ExprAndMaybeDedent) toMaybeDedent(immutable ExprAndDedent a) {
	return immutable ExprAndMaybeDedent(a.expr, some(a.dedents));
}

immutable(ArgsAndMaybeDedent) parseArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
	immutable u32 curIndent,
) {
	if (!tryTake(lexer, ' '))
		return ArgsAndMaybeDedent(emptyArr!ExprAst, none!size_t);
	else {
		ArrBuilder!ExprAst builder;
		return parseArgsRecur(alloc, lexer, ctx, builder, curIndent);
	}
}

immutable(ArgsAndMaybeDedent) parseArgsRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
	ref ArrBuilder!ExprAst args,
	immutable u32 curIndent,
) {
	immutable ExprAndMaybeDedent ad = parseExprArg(alloc, lexer, ctx, curIndent);
	add(alloc, args, ad.expr);
	return !has(ad.dedents) && tryTake(lexer, ", ")
		? parseArgsRecur(alloc, lexer, ctx, args, curIndent)
		: ArgsAndMaybeDedent(finishArr(alloc, args), ad.dedents);
}

immutable(ExprAndDedent) parseLetOrThen(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable NameAndRange name,
	immutable Bool isArrow,
	immutable u32 curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(alloc, lexer, curIndent);
	immutable Ptr!ExprAst init = allocExpr(alloc, initAndDedent.expr);
	immutable ExprAndDedent thenAndDedent = () {
		if (initAndDedent.dedents != 0) {
			immutable RangeWithinFile range = range(lexer, start);
			addDiag(alloc, lexer, range, ParseDiag(ParseDiag.LetMustHaveThen()));
			return immutable ExprAndDedent(bogusExpr(range), initAndDedent.dedents - 1);
		} else
			return parseStatementsAndExtraDedents(alloc, lexer, curIndent);
	}();
	immutable Ptr!ExprAst then = allocExpr(alloc, thenAndDedent.expr);
	immutable ExprAstKind exprKind = isArrow
		? immutable ExprAstKind(immutable ThenAst(name, init, then))
		: immutable ExprAstKind(immutable LetAst(name, init, then));
	// Since we don't always expect a dedent here,
	// the dedent isn't *extra*, so increment to get the correct number of dedents.
	return ExprAndDedent(ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents + 1);
}

immutable(ExprAndMaybeDedent) parseCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ExprAst target,
	immutable Bool allowBlock,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable Bool tookDot = tryTake(lexer, '.');
	immutable NameAndRange funName = takeNameAndRange(alloc, lexer);
	immutable Bool tookColon = !tookDot && tryTake(lexer, ':');
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
	if (tookDot) {
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, funName, typeArgs, arrLiteral!ExprAst(alloc, [target]));
		return noDedent(immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else {
		immutable ArgsAndMaybeDedent args = parseArgs(alloc, lexer, ArgCtx(allowBlock, tookColon), curIndent);
		immutable ExprAstKind exprKind = immutable ExprAstKind(
			immutable CallAst(CallAst.Style.infix, funName, typeArgs, prepend(alloc, target, args.args)));
		return immutable ExprAndMaybeDedent(immutable ExprAst(range(lexer, start), exprKind), args.dedent);
	}
}

immutable(ExprAndMaybeDedent) parseCalls(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExprAndMaybeDedent ed,
	immutable Bool allowBlock,
	immutable u32 curIndent,
) {
	if (has(ed.dedents))
		return ed;
	else if (tryTake(lexer, ' '))
		return parseCalls(
			alloc,
			lexer,
			start,
			parseCall(alloc, lexer, ed.expr, allowBlock, curIndent),
			allowBlock,
			curIndent);
	else
		return ed;
}

immutable(Bool) someInOwnBody(
	ref immutable ExprAst body_,
	scope immutable(Bool) delegate(ref immutable ExprAst) @safe @nogc pure nothrow cb,
) {
	// Since this is only used checking for 'it' in a braced lambda, any multi-line ast is unreachable
	if (cb(body_))
		return True;

	immutable(Bool) recur(ref immutable ExprAst sub) {
		return someInOwnBody(sub, cb);
	}

	return matchExprAstKind!(immutable Bool)(
		body_.kind,
		(ref immutable(BogusAst)) => False,
		(ref immutable CallAst e) => exists!ExprAst(e.args, &recur),
		(ref immutable CreateArrAst e) => exists(e.args, &recur),
		(ref immutable(FunPtrAst)) => False,
		(ref immutable(IdentifierAst)) => False,
		(ref immutable(IfAst)) => unreachable!(immutable Bool),
		(ref immutable(LambdaAst)) => False,
		(ref immutable(LetAst)) => unreachable!(immutable Bool),
		(ref immutable(LiteralAst)) => False,
		(ref immutable(MatchAst)) => unreachable!(immutable Bool),
		(ref immutable(SeqAst)) => unreachable!(immutable Bool),
		(ref immutable(ThenAst)) => unreachable!(immutable Bool));
}

immutable(Bool) bodyUsesIt(ref immutable ExprAst body_) {
	return someInOwnBody(body_, (ref immutable ExprAst it) =>
		immutable Bool(
			isIdentifier(it.kind) &&
			symEq(asIdentifier(it.kind).name, shortSymAlphaLiteral("it"))));
}

immutable(ExprAst) tryParseDots(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref immutable ExprAst initial
) {
	immutable Pos start = curPos(lexer);
	if (tryTake(lexer, '.')) {
		immutable NameAndRange name = takeNameAndRange(alloc, lexer);
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, name, typeArgs, arrLiteral!ExprAst(alloc, [initial]));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(call));
		return tryParseDots(alloc, lexer, expr);
	} else
		return initial;
}

immutable(ExprAndDedent) parseMatch(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable u32 curIndent,
) {
	immutable Ptr!ExprAst matched = tryTake(lexer, ' ')
		? allocate(alloc, parseExprNoBlock(alloc, lexer))
		: allocate(alloc, immutable ExprAst(range(lexer, start), immutable ExprAstKind(immutable BogusAst())));
	immutable size_t dedentsAfterMatched = takeNewlineOrDedentAmount(alloc, lexer, curIndent);
	ArrBuilder!(MatchAst.CaseAst) cases;
	immutable size_t dedents = dedentsAfterMatched != 0
		? dedentsAfterMatched
		: parseMatchCases(alloc, lexer, cases, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable MatchAst(matched, finishArr(alloc, cases)))),
		dedents);
}

immutable(size_t) parseMatchCases(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!(MatchAst.CaseAst) cases,
	immutable u32 curIndent,
) {
	immutable Pos startCase = curPos(lexer);
	if (tryTake(lexer, "as ")) {
		immutable NameAndRange structName = takeNameAndRange(alloc, lexer);
		immutable Opt!NameAndRange localName = tryTake(lexer, ' ')
			? some(takeNameAndRange(alloc, lexer))
			: none!NameAndRange;
		immutable ExprAndDedent ed = takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
			parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1));
		add(alloc, cases, immutable MatchAst.CaseAst(
			range(lexer, startCase),
			structName,
			localName,
			allocExpr(alloc, ed.expr)));
		return ed.dedents == 0 ? parseMatchCases(alloc, lexer, cases, curIndent) : ed.dedents;
	} else
		return 0;
}

immutable(ExprAndMaybeDedent) parseMultiLineNewArr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Opt!TypeAst type,
	immutable u32 curIndent,
) {
	ArrBuilder!ExprAst args;
	for (;;) {
		// Each line must begin with ". "
		takeOrAddDiagExpected(alloc, lexer, ". ", ParseDiag.Expected.Kind.multiLineArrSeparator);
		immutable ExprAndDedent ed = parseExprNoLet(alloc, lexer, curIndent);
		add(alloc, args, ed.expr);
		if (ed.dedents != 0)
			return immutable ExprAndMaybeDedent(
				immutable ExprAst(
					range(lexer, start),
					immutable ExprAstKind(immutable CreateArrAst(allocateOpt(alloc, type), finishArr(alloc, args)))),
				some(ed.dedents - 1));
	}
}

//TODO:MOVE?
immutable(Opt!(Ptr!T)) allocateOpt(T, Alloc)(ref Alloc alloc, immutable Opt!T opt) {
	return mapOption(opt, (ref immutable T t) => allocate(alloc, t));
}

immutable(ExprAndMaybeDedent) parseNewArrAfterArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Opt!TypeAst type,
	immutable ArgsAndMaybeDedent ad,
) {
	immutable ExprAstKind ast = immutable ExprAstKind(immutable CreateArrAst(allocateOpt(alloc, type), ad.args));
	return ExprAndMaybeDedent(ExprAst(range(lexer, start), ast), ad.dedent);
}

immutable(ExprAndMaybeDedent) parseNewArr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ArgCtx ctx,
	immutable u32 curIndent,
) {
	immutable Opt!TypeAst type = tryParseTypeArgBracketed(alloc, lexer);
	immutable Opt!IndentDelta opIndentOrDedent = ctx.allowCall
		? tryTakeIndentOrDedent(alloc, lexer, curIndent)
		: none!IndentDelta;
	if (has(opIndentOrDedent)) {
		return matchIndentDelta!(immutable ExprAndMaybeDedent)(
			force(opIndentOrDedent),
			(ref immutable IndentDelta.DedentOrSame it) {
				immutable ArgsAndMaybeDedent ad = immutable ArgsAndMaybeDedent(emptyArr!ExprAst, some(it.nDedents));
				return parseNewArrAfterArgs(alloc, lexer, start, type, ad);
			},
			(ref immutable IndentDelta.Indent) =>
				parseMultiLineNewArr(alloc, lexer, start, type, curIndent + 1));
	} else
		return parseNewArrAfterArgs(alloc, lexer, start, type, parseArgs(alloc, lexer, ctx, curIndent));
}

immutable(ExprAndDedent) parseIf(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable u32 curIndent,
) {
	if (!tryTake(lexer, ' '))
		return todo!(immutable ExprAndDedent)("!");
	return parseIfRecur(alloc, lexer, start, curIndent);
}

immutable(OptExprAndDedent) toOptExprAndDedent(Alloc)(ref Alloc alloc, immutable ExprAndDedent a) {
	return immutable OptExprAndDedent(some(allocate(alloc, a.expr)), a.dedents);
}

immutable(ExprAndDedent) parseIfRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable u32 curIndent,
) {
	immutable ExprAst condition = parseExprNoBlock(alloc, lexer);
	immutable ExprAndDedent thenAndDedent = takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
		parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1));
	immutable Pos elifStart = curPos(lexer);
	immutable OptExprAndDedent else_ = thenAndDedent.dedents != 0
		? immutable OptExprAndDedent(none!(Ptr!ExprAst), thenAndDedent.dedents)
		: tryTake(lexer, "elif ")
		? toOptExprAndDedent(alloc, parseIfRecur(alloc, lexer, elifStart, curIndent))
		: tryTake(lexer, "else")
		? toOptExprAndDedent(alloc, takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
			parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1)))
		: immutable OptExprAndDedent(none!(Ptr!ExprAst), 0);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable IfAst(
				allocate(alloc, condition),
				allocate(alloc, thenAndDedent.expr),
				else_.expr))),
		else_.dedents);
}

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
	scope immutable(ExprAndDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndDedent(
		alloc,
		lexer,
		curIndent,
		cbIndent,
		(immutable RangeWithinFile range, immutable size_t nDedents) =>
			immutable ExprAndDedent(bogusExpr(range), nDedents));
}

immutable(ExprAndMaybeDedent) takeIndentOrFail_ExprAndMaybeDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
	scope immutable(ExprAndMaybeDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndMaybeDedent(
		alloc,
		lexer,
		curIndent,
		cbIndent,
		(immutable RangeWithinFile range, immutable size_t nDedents) =>
			immutable ExprAndMaybeDedent(bogusExpr(range), some(nDedents)));
}

immutable(ExprAndMaybeDedent) parseLambda(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable u32 curIndent,
) {
	ArrBuilder!(LambdaAst.Param) parameters;
	Bool isFirst = True;
	while (curChar(lexer) != '\n') {
		immutable Bool success = () {
			if (isFirst) {
				isFirst = False;
				return True;
			} else
				return tryTake(lexer, ' ');
		}();
		if (success)
			add(alloc, parameters, takeNameAndRange(alloc, lexer));
		else {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.space)));
			skipUntilNewlineNoDiag(lexer);
		}
	}
	return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, curIndent, () {
		immutable ExprAndDedent bodyAndDedent = parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1);
		immutable LambdaAst lambda = LambdaAst(finishArr(alloc, parameters), allocExpr(alloc, bodyAndDedent.expr));
		return immutable ExprAndMaybeDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(lambda)),
			some!size_t(bodyAndDedent.dedents));
	});
}

immutable(ExprAndMaybeDedent) skipRestOfLineAndReturnBogusNoDiag(SymAlloc)(
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	skipUntilNewlineNoDiag(lexer);
	return noDedent(bogusExpr(range(lexer, start)));
}

immutable(ExprAndMaybeDedent) skipRestOfLineAndReturnBogus(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ParseDiag diag,
) {
	addDiag(alloc, lexer, range(lexer, start), diag);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

immutable(ExprAndMaybeDedent) parseExprBeforeCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
	immutable ArgCtx ctx,
	immutable u32 curIndent,
) {
	immutable(RangeWithinFile) getRange() {
		return range(lexer, start);
	}

	immutable(ExprAndMaybeDedent) blockNotAllowed(immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind kind) {
		return skipRestOfLineAndReturnBogus(
			alloc,
			lexer,
			start,
			immutable ParseDiag(immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx(kind)));
	}

	final switch (et.kind_) {
		case ExpressionToken.Kind.ampersandAndName:
			return noDedent(immutable ExprAst(
				getRange(),
				immutable ExprAstKind(immutable FunPtrAst(asAmpersandAndName(et).name))));
		case ExpressionToken.Kind.if_:
			return ctx.allowBlock
				? toMaybeDedent(parseIf(alloc, lexer, start, curIndent))
				: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.if_);
		case ExpressionToken.Kind.lambda:
			return ctx.allowBlock
				? parseLambda(alloc, lexer, start, curIndent)
				: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.lambda);
		case ExpressionToken.Kind.lbrace:
			immutable Ptr!ExprAst body_ = allocExpr(alloc, parseExprNoBlock(alloc, lexer));
			takeOrAddDiagExpected(alloc, lexer, '}', ParseDiag.Expected.Kind.closingBrace);
			immutable Arr!(LambdaAst.Param) params = bodyUsesIt(body_)
				? arrLiteral!(LambdaAst.Param)(alloc, [immutable LambdaAst.Param(start, shortSymAlphaLiteral("it"))])
				: emptyArr!(LambdaAst.Param);
			immutable ExprAst expr = immutable ExprAst(
				getRange(),
				immutable ExprAstKind(immutable LambdaAst(params, body_)));
			return noDedent(tryParseDots(alloc, lexer, expr));
		case ExpressionToken.Kind.literal:
			immutable ExprAst expr = immutable ExprAst(getRange(), immutable ExprAstKind(asLiteral(et)));
			return noDedent(tryParseDots(alloc, lexer, expr));
		case ExpressionToken.Kind.lparen:
			immutable ExprAst expr = parseExprNoBlock(alloc, lexer);
			takeOrAddDiagExpected(alloc, lexer, ')', ParseDiag.Expected.Kind.closingParen);
			return noDedent(tryParseDots(alloc, lexer, expr));
		case ExpressionToken.Kind.match:
			return ctx.allowBlock
				? toMaybeDedent(parseMatch(alloc, lexer, start, curIndent))
				: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match);
		case ExpressionToken.Kind.nameAndRange:
			immutable NameAndRange name = asNameAndRange(et);
			immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
			immutable Bool tookColon = tryTake(lexer, ':');
			if (tookColon) {
				// Prefix call `foo: bar, baz`
				immutable ArgsAndMaybeDedent ad = parseArgs(alloc, lexer, ctx, curIndent);
				immutable CallAst call = immutable CallAst(CallAst.Style.prefix, name, typeArgs, ad.args);
				return immutable ExprAndMaybeDedent(
					immutable ExprAst(getRange(), immutable ExprAstKind(call)),
					ad.dedent);
			} else if (!empty(toArr(typeArgs))) {
				return noDedent(immutable ExprAst(
					getRange(),
					immutable ExprAstKind(immutable CallAst(CallAst.Style.single, name, typeArgs, emptyArr!ExprAst))));
			} else {
				immutable ExprAst expr = immutable ExprAst(
					getRange(),
					immutable ExprAstKind(immutable IdentifierAst(name.name)));
				return noDedent(tryParseDots(alloc, lexer, expr));
			}
		case ExpressionToken.Kind.newArr:
			return parseNewArr(alloc, lexer, start, ctx, curIndent);
		case ExpressionToken.Kind.unexpected:
			return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
	}
}

immutable(ExprAndMaybeDedent) parseExprWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
	immutable ArgCtx ctx,
	immutable u32 curIndent,
) {
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(alloc, lexer, start, et, ctx, curIndent);
	return ctx.allowCall ? parseCalls(alloc, lexer, start, ed, ctx.allowBlock, curIndent) : ed;
}

// This eats an expression, but does not eat any newlines.
immutable(ExprAst) parseExprNoBlock(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable ExpressionToken et = takeExpressionToken(alloc, lexer);
	return parseExprNoBlock(alloc, lexer, start, et);
}

immutable(ExprAst) parseExprNoBlock(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref immutable ExpressionToken et,
) {
	// curIndent doesn't matter since we don't allow to take a block
	immutable ExprAndMaybeDedent ed = parseExprWorker(alloc, lexer, start, et, ArgCtx(False, True), 0);
	// We set allowBlock to false, so not allowed to take newlines, so can't have dedents.
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprArg(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable ExpressionToken et = takeExpressionToken(alloc, lexer);
	return parseExprWorker(alloc, lexer, start, et, ctx, curIndent);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
	immutable u32 curIndent,
) {
	immutable ExprAndMaybeDedent e = parseExprWorker(alloc, lexer, start, et, ArgCtx(True, True), curIndent);
	immutable size_t dedents = has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(alloc, lexer, curIndent);
	return ExprAndDedent(e.expr, dedents);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	return parseExprNoLet(alloc, lexer, start, takeExpressionToken(alloc, lexer), curIndent);
}

immutable(ExprAndDedent) parseSingleStatementLine(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable ExpressionToken et = takeExpressionToken(alloc, lexer);
	if (isNameAndRange(et)) {
		immutable Opt!Bool isThen = tryTake(lexer, " = ")
			? some(False)
			: tryTake(lexer, " <- ")
			? some(True)
			: none!Bool;
		if (has(isThen))
			return parseLetOrThen(alloc, lexer, start, asNameAndRange(et), force(isThen), curIndent);
	}
	return parseExprNoLet(alloc, lexer, start, et, curIndent);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndExtraDedents(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer, curIndent);
	return parseStatementsAndExtraDedentsRecur(alloc, lexer, start, ed.expr, curIndent, ed.dedents);
}

immutable(ExprAndDedent) parseStatementsAndExtraDedentsRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExprAst expr,
	immutable u32 curIndent,
	immutable size_t dedents,
) {
	if (dedents == 0) {
		immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer, curIndent);
		immutable SeqAst seq = immutable SeqAst(allocExpr(alloc, expr), allocExpr(alloc, ed.expr));
		return parseStatementsAndExtraDedentsRecur(
			alloc,
			lexer,
			start,
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(seq)),
			curIndent,
			ed.dedents);
	} else
		return immutable ExprAndDedent(expr, dedents - 1);
}
