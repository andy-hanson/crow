module frontend.parseExpr;

@safe @nogc pure nothrow:

import frontend.ast :
	asCall,
	asIdentifier,
	BogusAst,
	CallAst,
	CreateArrAst,
	CreateRecordAst,
	CreateRecordMultiLineAst,
	ExprAst,
	ExprAstKind,
	IdentifierAst,
	isCall,
	isIdentifier,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	NameAndRange,
	RecordFieldSetAst,
	SeqAst,
	ThenAst,
	TypeAst,
	WhenAst;
import frontend.lexer :
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
import frontend.parseType : tryParseTypeArg, tryParseTypeArgs;
import model.parseDiag : ParseDiag;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, ArrWithSize, empty, emptyArr, only, size, toArr;
import util.collection.arrUtil : arrLiteral, exists, prepend;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, mapOption, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : shortSymAlphaLiteral, symEq;
import util.util : todo, unreachable, verify;

immutable(ExprAst) parseFunExprBody(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	if (takeIndentOrDiagTopLevel(alloc, lexer)) {
		immutable ExprAndDedent ed = parseStatementsAndExtraDedents(alloc, lexer);
		verify(ed.dedents == 0); // Since we started at the root, can't dedent more
		return ed.expr;
	} else {
		return bogusExpr(range(lexer, start));
	}
}

private:

immutable(ExprAst) bogusExpr(immutable RangeWithinFile range) {
	return immutable ExprAst(range, immutable ExprAstKind(immutable BogusAst()));
}

immutable(Ptr!ExprAst) allocExpr(Alloc)(ref Alloc alloc, immutable ExprAst e) {
	return allocate(alloc, e);
}

struct ArgCtx {
		// Allow things like 'match', 'when', '\' that continue into an indented block.
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

struct ArgsAndMaybeDedent {
	immutable Arr!ExprAst args;
	immutable Opt!size_t dedent;
}

immutable(ExprAndMaybeDedent) noDedent(immutable ExprAst e) {
	return immutable ExprAndMaybeDedent(e, none!size_t);
}

immutable(ArgsAndMaybeDedent) parseArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
) {
	if (!tryTake(lexer, ' '))
		return ArgsAndMaybeDedent(emptyArr!ExprAst, none!size_t);
	else {
		ArrBuilder!ExprAst builder;
		return parseArgsRecur(alloc, lexer, ctx, builder);
	}
}

immutable(ArgsAndMaybeDedent) parseArgsRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
	ref ArrBuilder!ExprAst args,
) {
	immutable ExprAndMaybeDedent ad = parseExprArg(alloc, lexer, ctx);
	add(alloc, args, ad.expr);
	return !ad.dedents.has && tryTake(lexer, ", ")
		? parseArgsRecur(alloc, lexer, ctx, args)
		: ArgsAndMaybeDedent(finishArr(alloc, args), ad.dedents);
}

immutable(ExprAndDedent) parseLetOrThen(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable NameAndRange name,
	immutable Bool isArrow,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(alloc, lexer);
	immutable Ptr!ExprAst init = allocExpr(alloc, initAndDedent.expr);
	immutable ExprAndDedent thenAndDedent = () {
		if (initAndDedent.dedents != 0) {
			immutable RangeWithinFile range = range(lexer, start);
			addDiag(alloc, lexer, range, ParseDiag(ParseDiag.LetMustHaveThen()));
			return immutable ExprAndDedent(bogusExpr(range), initAndDedent.dedents - 1);
		} else
			return parseStatementsAndExtraDedents(alloc, lexer);
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
	immutable Bool allowBlock
) {
	immutable Pos start = curPos(lexer);
	immutable Bool tookDot = tryTake(lexer, '.');
	immutable NameAndRange funName = takeNameAndRange(alloc, lexer);
	immutable Bool tookColon = !tookDot && tryTake(lexer, ':');
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
	if (tookDot) {
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, funName, typeArgs, arrLiteral!ExprAst(alloc, [target]));
		return noDedent(immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else {
		immutable ArgsAndMaybeDedent args = parseArgs(alloc, lexer, ArgCtx(allowBlock, tookColon));
		immutable ExprAstKind exprKind = immutable ExprAstKind(
			immutable CallAst(CallAst.Style.infix, funName, typeArgs, prepend(alloc, target, args.args)));
		return immutable ExprAndMaybeDedent(immutable ExprAst(range(lexer, start), exprKind), args.dedent);
	}
}

immutable(ExprAndMaybeDedent) parseCallsAndRecordFieldSets(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExprAndMaybeDedent ed,
	immutable Bool allowBlock
) {
	if (ed.dedents.has)
		return ed;
	else if (tryTake(lexer, " := ")) {
		immutable ExprAst expr = ed.expr;
		if (!expr.kind.isCall)
			todo!void("non-struct-field-access to left of ':='");
		immutable CallAst call = expr.kind.asCall;
		if (!empty(toArr(call.typeArgs)))
			todo!void("RecordFieldSet should not have type args");
		if (call.args.size != 1)
			todo!void("RecordFieldSet should have exactly 1 arg");
		immutable Ptr!ExprAst target = allocExpr(alloc, call.args.only);
		immutable ExprAndMaybeDedent value = parseExprArg(alloc, lexer, ArgCtx(allowBlock, True));
		immutable RecordFieldSetAst rfs = immutable RecordFieldSetAst(
			target, call.funName, allocExpr(alloc, value.expr));
		return immutable ExprAndMaybeDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(rfs)),
			value.dedents);
	} else if (tryTake(lexer, ' '))
		return parseCallsAndRecordFieldSets(
			alloc,
			lexer,
			start,
			parseCall(alloc, lexer, ed.expr, allowBlock),
			allowBlock);
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

	immutable(Bool) recur(scope ref immutable ExprAst sub) {
		return someInOwnBody(sub, cb);
	}

	return matchExprAstKind!(immutable Bool)(
		body_.kind,
		(ref immutable BogusAst) => False,
		(ref immutable CallAst e) => e.args.exists(&recur),
		(ref immutable CreateArrAst e) => e.args.exists(&recur),
		(ref immutable CreateRecordAst e) => e.args.exists(&recur),
		(ref immutable CreateRecordMultiLineAst e) => unreachable!(immutable Bool),
		(ref immutable IdentifierAst) => False,
		(ref immutable LambdaAst) => False,
		(ref immutable LetAst) => unreachable!(immutable Bool),
		(ref immutable LiteralAst) => False,
		(ref immutable LiteralInnterAst) => unreachable!(immutable Bool),
		(ref immutable MatchAst) => unreachable!(immutable Bool),
		(ref immutable SeqAst) => unreachable!(immutable Bool),
		(ref immutable RecordFieldSetAst e) => immutable Bool(recur(e.target) || recur(e.value)),
		(ref immutable ThenAst) => unreachable!(immutable Bool),
		(ref immutable CondAst) => unreachable!(immutable Bool));
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
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, name, typeArgs, arrLiteral!ExprAst(alloc, [initial]));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(call));
		return tryParseDots(alloc, lexer, expr);
	} else
		return initial;
}

immutable(ExprAndMaybeDedent) parseMatch(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start
) {
	immutable Opt!(Ptr!ExprAst) matched = tryTake(lexer, ' ')
		? some(allocExpr(alloc, parseExprNoBlock(alloc, lexer)))
		: none!(Ptr!ExprAst);
	return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, () {
		ArrBuilder!(MatchAst.CaseAst) cases;
		immutable size_t matchDedents = () {
			for (;;) {
				immutable Pos startCase = curPos(lexer);
				immutable NameAndRange structName = takeNameAndRange(alloc, lexer);
				immutable Opt!NameAndRange localName = tryTake(lexer, ' ')
					? some(takeNameAndRange(alloc, lexer))
					: none!NameAndRange;
				immutable ExprAndDedent ed = takeIndentOrFail_ExprAndDedent(alloc, lexer, () =>
					parseStatementsAndExtraDedents(alloc, lexer));
				add(alloc, cases, immutable MatchAst.CaseAst(
					range(lexer, startCase),
					structName,
					localName,
					allocExpr(alloc, ed.expr)));
				if (ed.dedents != 0)
					return ed.dedents - 1;
			}
		}();
		immutable MatchAst match = immutable MatchAst(matched, finishArr(alloc, cases));
		return immutable ExprAndMaybeDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(match)),
			some(matchDedents));
	});
}

immutable(ExprAndMaybeDedent) parseMultiLineNew(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Opt!TypeAst type,
) {
	ArrBuilder!(CreateRecordMultiLineAst.Line) lines;
	for (;;) {
		immutable NameAndRange name = takeNameAndRange(alloc, lexer);
		takeOrAddDiagExpected(alloc, lexer, ". ", ParseDiag.Expected.Kind.multiLineNewSeparator);
		immutable ExprAndDedent ed = parseExprNoLet(alloc, lexer);
		add(alloc, lines, immutable CreateRecordMultiLineAst.Line(name, ed.expr));
		if (ed.dedents != 0)
			return immutable ExprAndMaybeDedent(
				immutable ExprAst(
					range(lexer, start),
					immutable ExprAstKind(immutable CreateRecordMultiLineAst(
						allocateOpt(alloc, type),
						finishArr(alloc, lines)))),
				some(ed.dedents - 1));
	}
}

immutable(ExprAndMaybeDedent) parseMultiLineNewArr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Opt!TypeAst type,
) {
	ArrBuilder!ExprAst args;
	for (;;) {
		// Each line must begin with ". "
		takeOrAddDiagExpected(alloc, lexer, ". ", ParseDiag.Expected.Kind.multiLineArrSeparator);
		immutable ExprAndDedent ed = parseExprNoLet(alloc, lexer);
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

immutable(ExprAndMaybeDedent) parseNewOrNewArrAfterArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Bool isNewArr,
	immutable Opt!TypeAst type,
	immutable ArgsAndMaybeDedent ad,
) {
	immutable ExprAstKind ast = isNewArr
		? immutable ExprAstKind(immutable CreateArrAst(allocateOpt(alloc, type), ad.args))
		: immutable ExprAstKind(immutable CreateRecordAst(allocateOpt(alloc, type), ad.args));
	return ExprAndMaybeDedent(ExprAst(range(lexer, start), ast), ad.dedent);
}

immutable(ExprAndMaybeDedent) parseNewOrNewArr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Bool isNewArr,
	immutable ArgCtx ctx,
) {
	immutable Opt!TypeAst type = tryParseTypeArg(alloc, lexer);
	immutable Opt!IndentDelta opIndentOrDedent = ctx.allowCall ? tryTakeIndentOrDedent(alloc, lexer) : none!IndentDelta;
	if (has(opIndentOrDedent)) {
		return matchIndentDelta!(immutable ExprAndMaybeDedent)(
			force(opIndentOrDedent),
			(ref immutable IndentDelta.DedentOrSame it) {
				immutable ArgsAndMaybeDedent ad = immutable ArgsAndMaybeDedent(emptyArr!ExprAst, some(it.nDedents));
				return parseNewOrNewArrAfterArgs(alloc, lexer, start, isNewArr, type, ad);
			},
			(ref immutable IndentDelta.Indent) {
				return isNewArr
					? parseMultiLineNewArr(alloc, lexer, start, type)
					: parseMultiLineNew(alloc, lexer, start, type);
			});
	} else
		return parseNewOrNewArrAfterArgs(alloc, lexer, start, isNewArr, type, parseArgs(alloc, lexer, ctx));
}

immutable(ExprAndMaybeDedent) parseWhenLoop(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref ArrBuilder!(WhenAst.Case) cases,
) {
	immutable Pos conditionStart = curPos(lexer);
	immutable ExpressionToken token = takeExpressionToken(alloc, lexer);
	if (token.kind_ == ExpressionToken.Kind.else_)
		return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, () {
			immutable ExprAndDedent elseAndDedent = parseStatementsAndExtraDedents(alloc, lexer);
			if (elseAndDedent.dedents == 0)
				todo!void("can't have any case after 'else'");
			immutable WhenAst when = immutable WhenAst(
				finishArr(alloc, cases),
				some(allocExpr(alloc, elseAndDedent.expr)));
			return immutable ExprAndMaybeDedent(
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(when)),
				some!size_t(elseAndDedent.dedents - 1));
		});
	else {
		immutable ExprAst condition = parseExprNoBlock(alloc, lexer, conditionStart, token);
		return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, () {
			immutable ExprAndDedent thenAndDedent = parseStatementsAndExtraDedents(alloc, lexer);
			if (thenAndDedent.dedents != 0) {
				addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(immutable ParseDiag.WhenMustHaveElse()));
				immutable WhenAst when = immutable WhenAst(finishArr(alloc, cases), none!(Ptr!ExprAst));
				return immutable ExprAndMaybeDedent(
					immutable ExprAst(range(lexer, start), immutable ExprAstKind(when)),
					some!size_t(thenAndDedent.dedents - 1));
			} else {
				add(alloc, cases, immutable WhenAst.Case(
					allocExpr(alloc, condition),
					allocExpr(alloc, thenAndDedent.expr)));
				return parseWhenLoop(alloc, lexer, start, cases);
			}
		});
	}
}

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	scope immutable(ExprAndDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndDedent(
		alloc, lexer, cbIndent,
		(immutable RangeWithinFile range, immutable size_t nDedents) =>
			immutable ExprAndDedent(bogusExpr(range), nDedents));
}

immutable(ExprAndMaybeDedent) takeIndentOrFail_ExprAndMaybeDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	scope immutable(ExprAndMaybeDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndMaybeDedent(
		alloc, lexer, cbIndent,
		(immutable RangeWithinFile range, immutable size_t nDedents) =>
			immutable ExprAndMaybeDedent(bogusExpr(range), some(nDedents)));
}

immutable(ExprAndMaybeDedent) parseWhen(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, () {
		ArrBuilder!(WhenAst.Case) cases;
		return parseWhenLoop(alloc, lexer, start, cases);
	});
}

immutable(ExprAndMaybeDedent) parseLambda(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
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
	return takeIndentOrFail_ExprAndMaybeDedent(alloc, lexer, () {
		immutable ExprAndDedent bodyAndDedent = parseStatementsAndExtraDedents(alloc, lexer);
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
		case ExpressionToken.Kind.else_:
			addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
				immutable ParseDiag.Unexpected(ParseDiag.Unexpected.Kind.else_)));
			return noDedent(bogusExpr(range(lexer, start)));
		case ExpressionToken.Kind.lambda:
			return ctx.allowBlock
				? parseLambda(alloc, lexer, start)
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
			immutable LiteralAst literal = et.asLiteral;
			immutable ExprAst expr = immutable ExprAst(getRange(), immutable ExprAstKind(literal));
			return noDedent(tryParseDots(alloc, lexer, expr));
		case ExpressionToken.Kind.lparen:
			immutable ExprAst expr = parseExprNoBlock(alloc, lexer);
			takeOrAddDiagExpected(alloc, lexer, ')', ParseDiag.Expected.Kind.closingParen);
			return noDedent(tryParseDots(alloc, lexer, expr));
		case ExpressionToken.Kind.match:
			return ctx.allowBlock
				? parseMatch(alloc, lexer, start)
				: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match);
		case ExpressionToken.Kind.nameAndRange:
			immutable NameAndRange name = asNameAndRange(et);
			immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
			immutable Bool tookColon = tryTake(lexer, ':');
			if (tookColon) {
				// Prefix call `foo: bar, baz`
				immutable ArgsAndMaybeDedent ad = parseArgs(alloc, lexer, ctx);
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
		case ExpressionToken.Kind.new_:
		case ExpressionToken.Kind.newArr:
			return parseNewOrNewArr(alloc, lexer, start, Bool(et.kind_ == ExpressionToken.Kind.newArr), ctx);
		case ExpressionToken.Kind.unexpected:
			return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
		case ExpressionToken.Kind.when:
			return ctx.allowBlock
				? parseWhen(alloc, lexer, start)
				: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.when);
	}
}

immutable(ExprAndMaybeDedent) parseExprWorker(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
	immutable ArgCtx ctx,
) {
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(alloc, lexer, start, et, ctx);
	return ctx.allowCall ? parseCallsAndRecordFieldSets(alloc, lexer, start, ed, ctx.allowBlock) : ed;
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
	immutable ExprAndMaybeDedent ed = parseExprWorker(alloc, lexer, start, et, ArgCtx(False, True));
	// We set allowBlock to false, so not allowed to take newlines, so can't have dedents.
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprArg(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
) {
	immutable Pos start = curPos(lexer);
	immutable ExpressionToken et = takeExpressionToken(alloc, lexer);
	return parseExprWorker(alloc, lexer, start, et, ctx);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
) {
	immutable ExprAndMaybeDedent e = parseExprWorker(alloc, lexer, start, et, ArgCtx(True, True));
	immutable size_t dedents = e.dedents.has ? e.dedents.force : takeNewlineOrDedentAmount(alloc, lexer);
	return ExprAndDedent(e.expr, dedents);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	return parseExprNoLet(alloc, lexer, start, takeExpressionToken(alloc, lexer));
}

immutable(ExprAndDedent) parseSingleStatementLine(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable ExpressionToken et = takeExpressionToken(alloc, lexer);
	if (et.isNameAndRange) {
		immutable NameAndRange nr = et.asNameAndRange;
		immutable Opt!Bool isThen = tryTake(lexer, " = ")
			? some(False)
			: tryTake(lexer, " <- ")
			? some(True)
			: none!Bool;
		if (isThen.has)
			return parseLetOrThen(alloc, lexer, start, nr, isThen.force);
	}
	return parseExprNoLet(alloc, lexer, start, et);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndExtraDedents(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer);
	return parseStatementsAndExtraDedentsRecur(alloc, lexer, start, ed.expr, ed.dedents);
}

immutable(ExprAndDedent) parseStatementsAndExtraDedentsRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExprAst expr,
	immutable size_t dedents,
) {
	if (dedents == 0) {
		immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer);
		immutable SeqAst seq = immutable SeqAst(allocExpr(alloc, expr), allocExpr(alloc, ed.expr));
		return parseStatementsAndExtraDedentsRecur(
			alloc,
			lexer,
			start,
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(seq)),
			ed.dedents);
	} else
		return immutable ExprAndDedent(expr, dedents - 1);
}
