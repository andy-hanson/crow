module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	asCall,
	asIdentifier,
	BogusAst,
	CallAst,
	CreateArrAst,
	ExprAst,
	ExprAstKind,
	FunPtrAst,
	IdentifierAst,
	IfAst,
	isCall,
	isIdentifier,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	NameAndRange,
	ParenthesizedAst,
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
	Lexer,
	range,
	skipUntilNewlineNoDiag,
	takeExpressionToken,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeNameAndRange,
	takeNewlineOrDedentAmount,
	takeOrAddDiagExpected,
	tryTake;
import frontend.parse.parseType : tryParseTypeArgsBracketed;
import model.parseDiag : EqLikeKind, ParseDiag;
import util.bools : Bool, False, True;
import util.collection.arr :
	Arr,
	ArrWithSize,
	castMutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	last,
	only,
	setLast,
	toArr;
import util.collection.arrUtil : append, arrLiteral, exists, prepend;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : Operator, operatorForSym, prependSet, shortSymAlphaLiteral, Sym, symEq;
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

immutable(Arr!ExprAst) parseSubscriptArgs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, ']'))
		return emptyArr!ExprAst;
	else {
		ArrBuilder!ExprAst builder;
		immutable ArgCtx argCtx = immutable ArgCtx(False, True);
		immutable ArgsAndMaybeDedent res = parseArgsRecur(alloc, lexer, argCtx, builder, 0);
		verify(!has(res.dedent));
		if (!tryTake(lexer, ']'))
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingBracket)));
		return res.args;
	}
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
	ref immutable ExprAst before,
	immutable EqLikeKind kind,
	immutable u32 curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(alloc, lexer, curIndent);
	immutable ExprAst init = initAndDedent.expr;
	if (kind == EqLikeKind.mutEquals) {
		struct FromBefore {
			immutable Sym name;
			immutable Arr!ExprAst args;
			immutable ArrWithSize!TypeAst typeArgs;
			immutable CallAst.Style style;
		}
		immutable FromBefore fromBefore = () {
			if (isIdentifier(before.kind))
				return immutable FromBefore(
					asIdentifier(before.kind).name,
					emptyArr!ExprAst,
					emptyArrWithSize!TypeAst,
					CallAst.Style.setSingle);
			else if (isCall(before.kind)) {
				immutable CallAst beforeCall = asCall(before.kind);
				immutable CallAst.Style style = () {
					final switch (beforeCall.style) {
						case CallAst.Style.dot:
							return CallAst.Style.setDot;
						case CallAst.Style.single:
							return CallAst.Style.setSingle;
						case CallAst.Style.subscript:
							return CallAst.Style.setSubscript;
						case CallAst.Style.infix:
						case CallAst.Style.prefix:
						case CallAst.Style.setDot:
						case CallAst.Style.setSingle:
						case CallAst.Style.setSubscript:
							// We did parseExprBeforeCall before this, which can't parse any of these
							return unreachable!(immutable CallAst.Style)();
					}
				}();
				return immutable FromBefore(beforeCall.funNameName, beforeCall.args, beforeCall.typeArgs, style);
			} else
				return todo!(immutable FromBefore)("not settable");
		}();
		immutable ExprAst call = immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable CallAst(
				fromBefore.style,
				// TODO: range is wrong..
				immutable NameAndRange(before.range.start, prependSet(lexer.allSymbols, fromBefore.name)),
				fromBefore.typeArgs,
				append(alloc, fromBefore.args, init))));
		return immutable ExprAndDedent(call, initAndDedent.dedents);
	} else {
		immutable ExprAndDedent thenAndDedent = () {
			if (initAndDedent.dedents != 0) {
				immutable RangeWithinFile range = range(lexer, start);
				addDiag(alloc, lexer, range, ParseDiag(ParseDiag.LetMustHaveThen()));
				return immutable ExprAndDedent(bogusExpr(range), initAndDedent.dedents - 1);
			} else
				return parseStatementsAndExtraDedents(alloc, lexer, curIndent);
		}();

		immutable ExprAstKind exprKind = () {
			if (isIdentifier(before.kind))
				return letOrThen(alloc, kind, identifierAsNameAndRange(before), init, thenAndDedent.expr);
			else {
				addDiag(alloc, lexer, before.range, immutable ParseDiag(
					immutable ParseDiag.CantPrecedeEqLike(kind)));
				return immutable ExprAstKind(immutable BogusAst());
			}
		}();

		// Since we don't always expect a dedent here,
		// the dedent isn't *extra*, so increment to get the correct number of dedents.
		return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents + 1);
	}
}

immutable(ExprAstKind) letOrThen(Alloc)(
	ref Alloc alloc,
	immutable EqLikeKind kind,
	immutable NameAndRange nameAndRange,
	ref immutable ExprAst init,
	ref immutable ExprAst then,
) {
	final switch (kind) {
		case EqLikeKind.equals:
			return immutable ExprAstKind(immutable LetAst(nameAndRange, allocate(alloc, init), allocate(alloc, then)));
		case EqLikeKind.mutEquals:
			return unreachable!(immutable ExprAstKind)();
		case EqLikeKind.then:
			return immutable ExprAstKind(immutable ThenAst(nameAndRange, allocate(alloc, init), allocate(alloc, then)));
	}
}

immutable(NameAndRange) identifierAsNameAndRange(ref immutable ExprAst a) {
	return immutable NameAndRange(a.range.start, asIdentifier(a.kind).name);
}

immutable(ExprAndMaybeDedent) parseCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ExprAst target,
	immutable Bool allowBlock,
	immutable u32 curIndent,
) {
	immutable Pos start = curPos(lexer); // TODO: logically the call starts at the LHS start.
	immutable NameAndRange funName = takeNameAndRange(alloc, lexer);
	immutable Opt!Operator operator = operatorForSym(funName.name);
	if (has(operator)) {
		immutable Bool tookColon = tryTake(lexer, ':');
		if (!tryTake(lexer, ' ')) {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.space)));
			skipUntilNewlineNoDiag(lexer);
			return immutable ExprAndMaybeDedent(target, none!size_t);
		} else {
			immutable ArgCtx argCtx = immutable ArgCtx(False, tookColon);
			immutable ExprAndMaybeDedent rhs = parseExprArg(alloc, lexer, argCtx, curIndent);
			//TODO: use a more appropriate fn then
			verify(!has(rhs.dedents));
			immutable Pos end = curPos(lexer);
			immutable ExprAst expr = tookColon
				? operatorCallAst(alloc, target, funName, rhs.expr, end)
				: injectOperator(alloc, target, funName, force(operator), rhs.expr, end);
			return immutable ExprAndMaybeDedent(expr, none!size_t);
		}
	} else {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
		immutable Bool tookColon = tryTake(lexer, ':');
		immutable ArgsAndMaybeDedent args = parseArgs(alloc, lexer, ArgCtx(allowBlock, tookColon), curIndent);
		immutable ExprAstKind exprKind = immutable ExprAstKind(
			immutable CallAst(CallAst.Style.infix, funName, typeArgs, prepend(alloc, target, args.args)));
		return immutable ExprAndMaybeDedent(immutable ExprAst(range(lexer, start), exprKind), args.dedent);
	}
}

immutable(ExprAst) injectOperator(Alloc)(
	ref Alloc alloc,
	ref immutable ExprAst lhs,
	immutable NameAndRange name,
	immutable Operator operator,
	ref immutable ExprAst rhs,
	immutable Pos end,
) {
	if (isCall(lhs.kind) && asCall(lhs.kind).style == CallAst.Style.infix) {
		immutable Opt!Operator lhsOperator = operatorForSym(asCall(lhs.kind).funName.name);
		immutable Arr!ExprAst args = asCall(lhs.kind).args;
		if (!empty(args) && (!has(lhsOperator) || lowerPrecedence(force(lhsOperator), operator))) {
			// TODO: don't mutate 'immutable'!
			Arr!ExprAst argsMutable = castMutable(args);
			setLast(argsMutable, injectOperator(alloc, last(args), name, operator, rhs, end));
			//TODO: also adjust the range of lhs, it is now bigger
			return lhs;
		} else
			return operatorCallAst(alloc, lhs, name, rhs, end);
	} else
		return operatorCallAst(alloc, lhs, name, rhs, end);
}

immutable(ExprAst) operatorCallAst(Alloc)(
	ref Alloc alloc,
	ref immutable ExprAst lhs,
	immutable NameAndRange name,
	ref immutable ExprAst rhs,
	immutable Pos end,
) {
	return immutable ExprAst(immutable RangeWithinFile(lhs.range.start, end), immutable ExprAstKind(
		immutable CallAst(
			CallAst.Style.infix,
			name,
			emptyArrWithSize!TypeAst,
			arrLiteral!ExprAst(alloc, [lhs, rhs]))));
}

immutable(Bool) lowerPrecedence(immutable Operator a, immutable Operator b) {
	return immutable Bool(precedence(a) < precedence(b));
}

immutable(uint) precedence(immutable Operator op) {
	final switch (op) {
		case Operator.equal:
		case Operator.notEqual:
		case Operator.less:
		case Operator.lessOrEqual:
		case Operator.greater:
		case Operator.greaterOrEqual:
		case Operator.compare:
		case Operator.arrow:
			return 1;
		case Operator.plus:
		case Operator.minus:
			return 2;
		case Operator.times:
		case Operator.divide:
			return 3;
		case Operator.power:
			return 4;
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
		(ref immutable ParenthesizedAst it) => recur(it.inner),
		(ref immutable(SeqAst)) => unreachable!(immutable Bool),
		(ref immutable(ThenAst)) => unreachable!(immutable Bool));
}

immutable(Bool) bodyUsesIt(ref immutable ExprAst body_) {
	return someInOwnBody(body_, (ref immutable ExprAst it) =>
		immutable Bool(
			isIdentifier(it.kind) &&
			symEq(asIdentifier(it.kind).name, shortSymAlphaLiteral("it"))));
}

immutable(ExprAst) tryParseDotsAndSubscripts(Alloc, SymAlloc)(
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
		return tryParseDotsAndSubscripts(alloc, lexer, expr);
	} else if (tryTake(lexer, '[')) {
		immutable Arr!ExprAst args = parseSubscriptArgs(alloc, lexer);
		immutable CallAst call = immutable CallAst(
			//TODO: the range is wrong..
			CallAst.Style.subscript,
			immutable NameAndRange(start, shortSymAlphaLiteral("subscript")),
			emptyArrWithSize!TypeAst,
			prepend(alloc, initial, args));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(call));
		return tryParseDotsAndSubscripts(alloc, lexer, expr);
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
				return tryTake(lexer, ", ");
		}();
		if (success)
			add(alloc, parameters, takeNameAndRange(alloc, lexer));
		else {
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.comma)));
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
		case ExpressionToken.Kind.lbracket:
			immutable Arr!ExprAst args = parseSubscriptArgs(alloc, lexer);
			immutable ExprAst expr = immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable CreateArrAst(args)));
			return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
		case ExpressionToken.Kind.lbrace:
			immutable Ptr!ExprAst body_ = allocExpr(alloc, parseExprNoBlock(alloc, lexer));
			takeOrAddDiagExpected(alloc, lexer, '}', ParseDiag.Expected.Kind.closingBrace);
			immutable Arr!(LambdaAst.Param) params = bodyUsesIt(body_)
				? arrLiteral!(LambdaAst.Param)(alloc, [immutable LambdaAst.Param(start, shortSymAlphaLiteral("it"))])
				: emptyArr!(LambdaAst.Param);
			immutable ExprAst expr = immutable ExprAst(
				getRange(),
				immutable ExprAstKind(immutable LambdaAst(params, body_)));
			return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
		case ExpressionToken.Kind.literal:
			immutable ExprAst expr = immutable ExprAst(getRange(), immutable ExprAstKind(asLiteral(et)));
			return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
		case ExpressionToken.Kind.lparen:
			immutable ExprAst expr = parseExprNoBlock(alloc, lexer);
			takeOrAddDiagExpected(alloc, lexer, ')', ParseDiag.Expected.Kind.closingParen);
			immutable ExprAst inner = tryParseDotsAndSubscripts(alloc, lexer, expr);
			return noDedent(immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable ParenthesizedAst(allocate(alloc, inner)))));
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
				return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
			}
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
	return addDedent(alloc, lexer, parseExprWorker(alloc, lexer, start, et, ArgCtx(True, True), curIndent), curIndent);
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
	immutable ArgCtx argCtx = immutable ArgCtx(True, True);
	immutable ExprAndMaybeDedent expr = parseExprBeforeCall(alloc, lexer, start, et, argCtx, curIndent);
	if (!has(expr.dedents)) {
		immutable Opt!EqLikeKind kind = tryTakeEqLikeKind(lexer);
		if (has(kind))
			return parseLetOrThen!(Alloc, SymAlloc)(alloc, lexer, start, expr.expr, force(kind), curIndent);
	}
	return addDedent(
		alloc,
		lexer,
		has(expr.dedents) ? expr : parseCalls(alloc, lexer, start, expr, True, curIndent), curIndent);
}

immutable(ExprAndDedent) addDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ExprAndMaybeDedent e,
	immutable u32 curIndent,
) {
	return immutable ExprAndDedent(
		e.expr,
		has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(alloc, lexer, curIndent));
}

immutable(Opt!EqLikeKind) tryTakeEqLikeKind(SymAlloc)(ref Lexer!SymAlloc lexer) {
	return tryTake(lexer, " = ")
		? some(EqLikeKind.equals)
		: tryTake(lexer, " := ")
		? some(EqLikeKind.mutEquals)
		: tryTake(lexer, " <- ")
		? some(EqLikeKind.then)
		: none!EqLikeKind;
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
