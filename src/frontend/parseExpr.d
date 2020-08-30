module frontend.parseExpr;

@safe @nogc pure nothrow:

import frontend.ast :
	asCall,
	asIdentifier,
	CallAst,
	CondAst,
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
	TypeAst;
import frontend.lexer :
	asLiteral,
	asNameAndRange,
	curPos,
	ExpressionToken,
	isNameAndRange,
	Lexer,
	range,
	take,
	takeExpressionToken,
	takeIndent,
	takeName,
	takeNameAndRange,
	takeNewlineOrDedentAmount,
	throwAtChar,
	throwDiag,
	tryTake,
	tryTakeElseIndent,
	tryTakeIndent,
	tryTakeIndentOrDedent;
import frontend.parseType : tryParseTypeArg, tryParseTypeArgs;

import parseDiag : ParseDiag;

import util.alloc.alloc : nu2;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, empty, emptyArr, only, size;
import util.collection.arrUtil : arrLiteral, exists, prepend;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, SourceRange;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.util : todo;
import util.verify : unreachable;

immutable(ExprAst) parseFunExprBody(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	lexer.takeIndent();
	immutable ExprAndDedent ed = parseStatementsAndDedent(alloc, lexer);
	assert(ed.dedents == 0);
	return ed.expr;
}

private:

immutable(Ptr!ExprAst) allocExpr(Alloc)(ref Alloc alloc, immutable ExprAst e) {
	return nu2(alloc, e);
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
	if (!lexer.tryTake(' '))
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
	return !ad.dedents.has && lexer.tryTake(", ")
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
	if (initAndDedent.dedents != 0)
		return lexer.throwDiag!ExprAndDedent(lexer.range(start), ParseDiag(ParseDiag.LetMustHaveThen()));
	else {
		immutable Ptr!ExprAst init = allocExpr(alloc, initAndDedent.expr);
		immutable ExprAndDedent thenAndDedent = parseStatementsAndDedent(alloc, lexer);
		immutable Ptr!ExprAst then = allocExpr(alloc, thenAndDedent.expr);
		immutable ExprAstKind exprKind = isArrow
			? ExprAstKind(ThenAst(LambdaAst.Param(name.range, name.name), init, then))
			: ExprAstKind(LetAst(name, init, then));
		// Since we don't always expect a dedent here,
		// the dedent isn't *extra*, so increment to get the correct number of dedents.
		return ExprAndDedent(ExprAst(lexer.range(start), exprKind), thenAndDedent.dedents + 1);
	}
}

immutable(ExprAndMaybeDedent) parseCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ExprAst target,
	immutable Bool allowBlock
) {
	immutable Pos start = lexer.curPos;
	if (lexer.tryTake('.')) {
		immutable Sym funName = lexer.takeName();
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		immutable CallAst call = CallAst(funName, typeArgs, arrLiteral!ExprAst(alloc, target));
		return noDedent(ExprAst(lexer.range(start), ExprAstKind(call)));
	} else {
		immutable Sym funName = lexer.takeName();
		immutable Bool colon = lexer.tryTake(':');
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		immutable ArgsAndMaybeDedent args = parseArgs(alloc, lexer, ArgCtx(allowBlock, colon));
		immutable ExprAstKind exprKind = ExprAstKind(
			CallAst(funName, typeArgs, prepend(alloc, target, args.args)));
		return ExprAndMaybeDedent(ExprAst(lexer.range(start), exprKind), args.dedent);
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
	else if (lexer.tryTake(" := ")) {
		immutable ExprAst expr = ed.expr;
		if (!expr.kind.isCall)
			todo!void("non-struct-field-access to left of ':='");
		immutable CallAst call = expr.kind.asCall;
		if (!call.typeArgs.empty)
			todo!void("RecordFieldSet should not have type args");
		if (call.args.size != 1)
			todo!void("RecordFieldSet should have exactly 1 arg");
		immutable Ptr!ExprAst target = allocExpr(alloc, call.args.only);
		immutable ExprAndMaybeDedent value = parseExprArg(alloc, lexer, ArgCtx(allowBlock, True));
		immutable RecordFieldSetAst rfs = RecordFieldSetAst(target, call.funName, allocExpr(alloc, value.expr));
		return ExprAndMaybeDedent(ExprAst(lexer.range(start), ExprAstKind(rfs)), value.dedents);
	} else if (lexer.tryTake(' '))
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
		(scope ref immutable CallAst e) => e.args.exists(&recur),
		(scope ref immutable CondAst) => unreachable!(immutable Bool),
		(scope ref immutable CreateArrAst e) => e.args.exists(&recur),
		(scope ref immutable CreateRecordAst e) => e.args.exists(&recur),
		(scope ref immutable CreateRecordMultiLineAst e) => unreachable!(immutable Bool),
		(scope ref immutable IdentifierAst) => False,
		(scope ref immutable LambdaAst) => False,
		(scope ref immutable LetAst) => unreachable!(immutable Bool),
		(scope ref immutable LiteralAst) => False,
		(scope ref immutable LiteralInnterAst) => unreachable!(immutable Bool),
		(scope ref immutable MatchAst) => unreachable!(immutable Bool),
		(scope ref immutable SeqAst) => unreachable!(immutable Bool),
		(scope ref immutable RecordFieldSetAst e) => immutable Bool(recur(e.target) || recur(e.value)),
		(scope ref immutable ThenAst) => unreachable!(immutable Bool),
	);
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
	immutable Pos start = lexer.curPos;
	if (lexer.tryTake('.')) {
		immutable Sym name = lexer.takeName();
		immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
		immutable CallAst call = CallAst(name, typeArgs, arrLiteral!ExprAst(alloc, initial));
		immutable ExprAst expr = ExprAst(lexer.range(start), ExprAstKind(call));
		return tryParseDots(alloc, lexer, expr);
	} else
		return initial;
}

immutable(ExprAndMaybeDedent) parseMatch(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start
) {
	lexer.take(' ');
	immutable Ptr!ExprAst matched = allocExpr(alloc, parseExprNoBlock(alloc, lexer));
	lexer.takeIndent();

	ArrBuilder!(MatchAst.CaseAst) cases;
	immutable size_t matchDedents = () {
		for (;;) {
			immutable Pos startCase = lexer.curPos;
			immutable Sym structName = lexer.takeName();
			immutable Opt!NameAndRange localName = lexer.tryTakeIndent()
				? none!NameAndRange
				: () {
					lexer.take(' ');
					immutable NameAndRange local = lexer.takeNameAndRange();
					lexer.takeIndent();
					return some(local);
				}();
			immutable ExprAndDedent ed = parseStatementsAndDedent(alloc, lexer);
			add(alloc, cases, immutable MatchAst.CaseAst(
				lexer.range(startCase),
				structName,
				localName,
				allocExpr(alloc, ed.expr)));
			if (ed.dedents != 0)
				return ed.dedents - 1;
		}
	}();
	immutable MatchAst match = MatchAst(matched, finishArr(alloc, cases));
	return ExprAndMaybeDedent(
		ExprAst(lexer.range(start), ExprAstKind(match)),
		some(matchDedents));
}

immutable(ExprAndMaybeDedent) parseMultiLineNew(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Opt!TypeAst type,
) {
	ArrBuilder!(CreateRecordMultiLineAst.Line) lines;
	for (;;) {
		immutable NameAndRange name = lexer.takeNameAndRange();
		lexer.take(". ");
		immutable ExprAndDedent ed = parseExprNoLet(alloc, lexer);
		add(alloc, lines, immutable CreateRecordMultiLineAst.Line(name, ed.expr));
		if (ed.dedents != 0)
			return ExprAndMaybeDedent(
				ExprAst(lexer.range(start), ExprAstKind(CreateRecordMultiLineAst(type, finishArr(alloc, lines)))),
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
		lexer.take(". ");
		immutable ExprAndDedent ed = parseExprNoLet(alloc, lexer);
		add(alloc, args, ed.expr);
		if (ed.dedents != 0)
			return ExprAndMaybeDedent(
				ExprAst(lexer.range(start), ExprAstKind(CreateArrAst(type, finishArr(alloc, args)))),
				some(ed.dedents - 1));
	}
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
		? ExprAstKind(CreateArrAst(type, ad.args))
		: ExprAstKind(CreateRecordAst(type, ad.args));
	return ExprAndMaybeDedent(ExprAst(lexer.range(start), ast), ad.dedent);
}

immutable(ExprAndMaybeDedent) parseNewOrNewArr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable Bool isNewArr,
	immutable ArgCtx ctx,
) {
	immutable Opt!TypeAst type = tryParseTypeArg(alloc, lexer);
	immutable Opt!int opIndentOrDedent = ctx.allowCall ? lexer.tryTakeIndentOrDedent() : none!int;
	if (opIndentOrDedent.has) {
		immutable int indent = opIndentOrDedent.force;
		if (indent == 1)
			return isNewArr
				? parseMultiLineNewArr(alloc, lexer, start, type)
				: parseMultiLineNew(alloc, lexer, start, type);
		else {
			assert(indent <= 0);
			immutable ArgsAndMaybeDedent ad =
				ArgsAndMaybeDedent(emptyArr!ExprAst, some!size_t(-indent));
			return parseNewOrNewArrAfterArgs(alloc, lexer, start, isNewArr, type, ad);
		}
	} else
		return parseNewOrNewArrAfterArgs(alloc, lexer, start, isNewArr, type, parseArgs(alloc, lexer, ctx));
}

immutable(ExprAndMaybeDedent) parseWhenLoop(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	if (lexer.tryTakeElseIndent()) {
		immutable ExprAndDedent elseAndDedent = parseStatementsAndDedent(alloc, lexer);
		if (elseAndDedent.dedents == 0)
			todo!void("can't have any case after 'else'");
		return ExprAndMaybeDedent(elseAndDedent.expr, some!size_t(elseAndDedent.dedents - 1));
	} else {
		immutable ExprAst condition = parseExprNoBlock(alloc, lexer);
		lexer.takeIndent();
		immutable ExprAndDedent thenAndDedent = parseStatementsAndDedent(alloc, lexer);
		if (thenAndDedent.dedents != 0)
			return throwAtChar!ExprAndMaybeDedent(lexer, ParseDiag(ParseDiag.WhenMustHaveElse()));
		immutable ExprAndMaybeDedent elseAndDedent = parseWhenLoop(alloc, lexer, start);
		immutable CondAst cond = CondAst(
			allocExpr(alloc, condition),
			allocExpr(alloc, thenAndDedent.expr),
			allocExpr(alloc, elseAndDedent.expr));
		return ExprAndMaybeDedent(
			ExprAst(lexer.range(start), ExprAstKind(cond)),
			elseAndDedent.dedents);
	}
}

immutable(ExprAndMaybeDedent) parseWhen(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	lexer.takeIndent();
	return parseWhenLoop(alloc, lexer, start);
}

immutable(ExprAndMaybeDedent) parseLambda(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
) {
	ArrBuilder!(LambdaAst.Param) parameters;
	Bool isFirst = True;
	while (!lexer.tryTakeIndent()) {
		if (isFirst)
			isFirst = False;
		else
			lexer.take(' ');
		immutable NameAndRange nr = lexer.takeNameAndRange();
		add(alloc, parameters, LambdaAst.Param(nr.range, nr.name));
	}
	immutable ExprAndDedent bodyAndDedent = parseStatementsAndDedent(alloc, lexer);
	immutable LambdaAst lambda = LambdaAst(finishArr(alloc, parameters), allocExpr(alloc, bodyAndDedent.expr));
	return ExprAndMaybeDedent(
		ExprAst(lexer.range(start), ExprAstKind(lambda)),
		some!size_t(bodyAndDedent.dedents));
}

immutable(ExprAndMaybeDedent) parseExprBeforeCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
	immutable ArgCtx ctx,
) {
	immutable(SourceRange) getRange() {
		return lexer.range(start);
	}

	void checkBlockAllowed() {
		if (!ctx.allowBlock)
			throwAtChar!void(lexer, ParseDiag(ParseDiag.MatchWhenNewMayNotAppearInsideArg()));
	}

	alias Kind = ExpressionToken.Kind;
	final switch (et.kind_) {
		case Kind.lambda:
			checkBlockAllowed();
			return parseLambda(alloc, lexer, start);
		case Kind.lbrace:
			immutable Ptr!ExprAst body_ = allocExpr(alloc, parseExprNoBlock(alloc, lexer));
			lexer.take('}');
			immutable SourceRange range = getRange();
			immutable Arr!(LambdaAst.Param) params = bodyUsesIt(body_)
				? arrLiteral!(LambdaAst.Param)(alloc, LambdaAst.Param(range, shortSymAlphaLiteral("it")))
				: emptyArr!(LambdaAst.Param);
			immutable ExprAst expr = ExprAst(range, ExprAstKind(LambdaAst(params, body_)));
			return noDedent(tryParseDots(alloc, lexer, expr));
		case Kind.literal:
			immutable LiteralAst literal = et.asLiteral;
			immutable ExprAst expr = ExprAst(getRange(), ExprAstKind(literal));
			return noDedent(tryParseDots(alloc, lexer, expr));
		case Kind.lparen:
			immutable ExprAst expr = parseExprNoBlock(alloc, lexer);
			lexer.take(')');
			return noDedent(tryParseDots(alloc, lexer, expr));
		case Kind.match:
			checkBlockAllowed();
			return parseMatch(alloc, lexer, start);
		case Kind.nameAndRange:
			immutable Sym name = et.asNameAndRange.name;
			immutable Arr!TypeAst typeArgs = tryParseTypeArgs(alloc, lexer);
			immutable Bool tookColon = lexer.tryTake(':');
			if (tookColon) {
				// Prefix call `foo: bar, baz`
				immutable ArgsAndMaybeDedent ad = parseArgs(alloc, lexer, ctx);
				immutable CallAst call = CallAst(name, typeArgs, ad.args);
				return ExprAndMaybeDedent(ExprAst(getRange(), ExprAstKind(call)), ad.dedent);
			} else if (!typeArgs.empty) {
				return noDedent(
					ExprAst(getRange(), ExprAstKind(CallAst(name, typeArgs, emptyArr!ExprAst))));
			} else {
				immutable ExprAst expr = ExprAst(getRange(), ExprAstKind(IdentifierAst(name)));
				return noDedent(tryParseDots(alloc, lexer, expr));
			}
		case Kind.new_:
		case Kind.newArr:
			return parseNewOrNewArr(alloc, lexer, start, Bool(et.kind_ == Kind.newArr), ctx);
		case Kind.when:
			checkBlockAllowed();
			return parseWhen(alloc, lexer, start);
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
	immutable Pos start = lexer.curPos;
	immutable ExpressionToken et = lexer.takeExpressionToken(alloc);
	immutable ExprAndMaybeDedent ed = parseExprWorker(alloc, lexer, start, et, ArgCtx(False, True));
	// We set allowBlock to false, so not allowed to take newlines, so can't have dedents.
	assert(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprArg(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
) {
	immutable Pos start = lexer.curPos;
	immutable ExpressionToken et = lexer.takeExpressionToken(alloc);
	return parseExprWorker(alloc, lexer, start, et, ctx);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExpressionToken et,
) {
	immutable ExprAndMaybeDedent e = parseExprWorker(alloc, lexer, start, et, ArgCtx(True, True));
	immutable size_t dedents = e.dedents.has ? e.dedents.force : lexer.takeNewlineOrDedentAmount();
	return ExprAndDedent(e.expr, dedents);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	return parseExprNoLet(alloc, lexer, start, lexer.takeExpressionToken(alloc));
}

immutable(ExprAndDedent) parseSingleStatementLine(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	immutable ExpressionToken et = lexer.takeExpressionToken(alloc);
	if (et.isNameAndRange) {
		immutable NameAndRange nr = et.asNameAndRange;
		immutable Opt!Bool isThen = lexer.tryTake(" = ")
			? some(False)
			: lexer.tryTake(" <- ")
			? some(True)
			: none!Bool;
		if (isThen.has)
			return parseLetOrThen(alloc, lexer, start, nr, isThen.force);
	}
	return parseExprNoLet(alloc, lexer, start, et);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndDedent(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable Pos start = lexer.curPos;
	immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer);
	return parseStatementsAndDedentRecur(alloc, lexer, start, ed.expr, ed.dedents);
}


immutable(ExprAndDedent) parseStatementsAndDedentRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ExprAst expr,
	immutable size_t dedents,
) {
	if (dedents == 0) {
		immutable ExprAndDedent ed = parseSingleStatementLine(alloc, lexer);
		immutable SeqAst seq = SeqAst(allocExpr(alloc, expr), allocExpr(alloc, ed.expr));
		return parseStatementsAndDedentRecur(
			alloc,
			lexer,
			start,
			ExprAst(lexer.range(start), ExprAstKind(seq)),
			ed.dedents);
	} else
		return ExprAndDedent(expr, dedents - 1);
}

