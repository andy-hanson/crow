module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	BogusAst,
	CallAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
	IdentifierSetAst,
	IfAst,
	IfOptionAst,
	InterpolatedAst,
	InterpolatedPart,
	LambdaAst,
	LetAst,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	NameAndRange,
	NameOrUnderscoreOrNone,
	OptNameAndRange,
	ParenthesizedAst,
	PtrAst,
	SeqAst,
	ThenAst,
	ThrowAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	WithAst;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	curPos,
	EqualsOrThen,
	getCurLiteralFloat,
	getCurLiteralInt,
	getCurLiteralNat,
	getCurOperator,
	getCurSym,
	Lexer,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeArrow,
	NewlineOrIndent,
	nextToken,
	peekToken,
	peekTokenExpression,
	QuoteKind,
	range,
	skipUntilNewlineNoDiag,
	StringPart,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrUnderscore,
	takeNameOrUnderscoreOrNone,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrDedentAmount,
	takeOptNameAndRange,
	takeOrAddDiagExpectedToken,
	takeStringPart,
	Token,
	tryTakeNameOrOperatorAndRange,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.parseType : parseType, parseTypeRequireBracket, tryParseTypeArgsForExpr;
import model.model : AssertOrForbidKind;
import model.parseDiag : ParseDiag;
import util.col.arr : empty, only, small;
import util.col.arrUtil : append, arrLiteral, prepend;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : prependSet, Sym, sym;
import util.util : max, todo, unreachable, verify;

immutable(Opt!ExprAst) parseFunExprBody(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return none!ExprAst;
		case NewlineOrIndent.indent:			
			immutable ExprAndDedent ed = parseStatementsAndExtraDedents(lexer, 1);
			verify(ed.dedents == 0); // Since we started at the root, can't dedent more
			return some(ed.expr);
	}
}

private:

immutable(ExprAst) bogusExpr(immutable RangeWithinFile range) =>
	immutable ExprAst(range, immutable ExprAstKind(immutable BogusAst()));

struct AllowedBlock {
	@safe @nogc pure nothrow:

	struct NoBlock {}
	struct AllowBlock { immutable uint curIndent; }

	immutable this(immutable NoBlock a) { kind = Kind.noBlock; noBlock = a; }
	immutable this(immutable AllowBlock a) { kind = Kind.allowBlock; allowBlock = a; }

	private:
	enum Kind {
		noBlock,
		allowBlock,
	}
	immutable Kind kind;
	union {
		immutable NoBlock noBlock;
		immutable AllowBlock allowBlock;
	}
}

immutable(AllowedBlock) noBlock() =>
	immutable AllowedBlock(immutable AllowedBlock.NoBlock());

immutable(AllowedBlock) allowBlock(immutable uint curIndent) =>
	immutable AllowedBlock(immutable AllowedBlock.AllowBlock(curIndent));

immutable(bool) isAllowBlock(ref immutable AllowedBlock a) =>
	a.kind == AllowedBlock.Kind.allowBlock;

immutable(AllowedBlock.AllowBlock) asAllowBlock(ref immutable AllowedBlock a) {
	verify(isAllowBlock(a));
	return a.allowBlock;
}

struct AllowedCalls {
	immutable int minPrecedenceExclusive;
}

immutable(AllowedCalls) allowAllCalls() =>
	immutable AllowedCalls(int.min);

immutable(AllowedCalls) allowAllCallsExceptComma() =>
	immutable AllowedCalls(commaPrecedence);

struct ArgCtx {
	// Allow things like 'if' that continue into an indented block.
	immutable AllowedBlock allowedBlock;
	immutable AllowedCalls allowedCalls;
}

immutable(ArgCtx) requirePrecedenceGt(immutable ArgCtx a, immutable int precedence) =>
	immutable ArgCtx(
		a.allowedBlock,
		immutable AllowedCalls(max(a.allowedCalls.minPrecedenceExclusive, precedence)));

immutable(ArgCtx) requirePrecedenceGtComma(immutable ArgCtx a) =>
	requirePrecedenceGt(a, commaPrecedence);

struct ExprAndDedent {
	immutable ExprAst expr;
	immutable uint dedents;
}

// dedent=none means we didn't see a newline.
// dedent=0 means a newline was parsed and is on the same indent level.
struct ExprAndMaybeDedent {
	immutable ExprAst expr;
	immutable Opt!uint dedents;
}

struct OptNameOrDedent {
	@safe @nogc pure nothrow:

	struct Colon {}
	struct Comma {}
	struct Dedent { immutable uint dedents; }
	struct None {}
	struct Question {}

	immutable this(immutable NameAndRange a) { kind = Kind.name; name = a; }
	immutable this(immutable Colon a) { kind = Kind.colon; colon = a; }
	immutable this(immutable Comma a) { kind = Kind.comma; comma = a; }
	immutable this(immutable Dedent a) { kind = Kind.dedent; dedent = a; }
	immutable this(immutable None a) { kind = Kind.none; none = a; }
	immutable this(immutable Question a) { kind = Kind.question; question = a; }

	private:
	enum Kind {
		name,
		colon,
		comma,
		dedent,
		none,
		question,
	}
	immutable Kind kind;
	union {
		immutable NameAndRange name;
		immutable Colon colon;
		immutable Comma comma;
		immutable Dedent dedent;
		immutable None none;
		immutable Question question;
	}
}

immutable(OptNameOrDedent) noNameOrDedent() =>
	immutable OptNameOrDedent(immutable OptNameOrDedent.None());

immutable(bool) isNone(ref immutable OptNameOrDedent a) =>
	a.kind == OptNameOrDedent.Kind.none;

immutable(T) matchOptNameOrDedent(T)(
	ref immutable OptNameOrDedent a,
	scope immutable(T) delegate(ref immutable OptNameOrDedent.None) @safe @nogc pure nothrow cbNone,
	scope immutable(T) delegate(ref immutable OptNameOrDedent.Colon) @safe @nogc pure nothrow cbColon,
	scope immutable(T) delegate(ref immutable OptNameOrDedent.Comma) @safe @nogc pure nothrow cbComma,
	scope immutable(T) delegate(ref immutable NameAndRange) @safe @nogc pure nothrow cbName,
	scope immutable(T) delegate(ref immutable OptNameOrDedent.Dedent) @safe @nogc pure nothrow cbDedent,
	scope immutable(T) delegate(ref immutable OptNameOrDedent.Question) @safe @nogc pure nothrow cbQuestion,
) {
	final switch (a.kind) {
		case OptNameOrDedent.Kind.none:
			return cbNone(a.none);
		case OptNameOrDedent.Kind.colon:
			return cbColon(a.colon);
		case OptNameOrDedent.Kind.comma:
			return cbComma(a.comma);
		case OptNameOrDedent.Kind.name:
			return cbName(a.name);
		case OptNameOrDedent.Kind.dedent:
			return cbDedent(a.dedent);
		case OptNameOrDedent.Kind.question:
			return cbQuestion(a.question);
	}
}

struct ExprAndMaybeNameOrDedent {
	immutable ExprAst expr;
	immutable OptNameOrDedent nameOrDedent;
}

immutable(ExprAst) assertNoNameOrDedent(immutable ExprAndMaybeNameOrDedent a) {
	verify(isNone(a.nameOrDedent));
	return a.expr;
}
immutable(ExprAst[]) assertNoNameOrDedent(immutable ArgsAndMaybeNameOrDedent a) {
	verify(isNone(a.nameOrDedent));
	return a.args;
}

struct OptExprAndDedent {
	immutable Opt!ExprAst expr;
	immutable uint dedents;
}

struct ArgsAndMaybeNameOrDedent {
	immutable ExprAst[] args;
	immutable OptNameOrDedent nameOrDedent;
}

immutable(ExprAndMaybeDedent) noDedent(immutable ExprAst e) =>
	immutable ExprAndMaybeDedent(e, none!uint);

immutable(ExprAndMaybeDedent) toMaybeDedent(immutable ExprAndDedent a) =>
	immutable ExprAndMaybeDedent(a.expr, some(a.dedents));

immutable(ExprAst[]) parseSubscriptArgs(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.bracketRight))
		//TODO: syntax error
		return [];
	else {
		ArrBuilder!ExprAst builder;
		immutable ArgCtx argCtx = immutable ArgCtx(noBlock(), allowAllCallsExceptComma());
		immutable ArgsAndMaybeNameOrDedent res = parseArgsRecur(lexer, argCtx, builder);
		if (!tryTakeToken(lexer, Token.bracketRight))
			addDiagAtChar(lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingBracket)));
		return assertNoNameOrDedent(res);
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsForOperator(ref Lexer lexer, immutable ArgCtx ctx) {
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	return immutable ArgsAndMaybeNameOrDedent(arrLiteral!ExprAst(lexer.alloc, [ad.expr]), ad.nameOrDedent);
}

immutable(ArgsAndMaybeNameOrDedent) parseArgs(ref Lexer lexer, immutable ArgCtx ctx) {
	if (tryTakeToken(lexer, Token.comma))
		return immutable ArgsAndMaybeNameOrDedent(
			[],
			immutable OptNameOrDedent(immutable OptNameOrDedent.Comma()));
	else if (tryTakeToken(lexer, Token.colon))
		return immutable ArgsAndMaybeNameOrDedent(
			[],
			immutable OptNameOrDedent(immutable OptNameOrDedent.Colon()));
	else if (peekTokenExpression(lexer)) {
		ArrBuilder!ExprAst builder;
		return parseArgsRecur(lexer, ctx, builder);
	} else
		return immutable ArgsAndMaybeNameOrDedent([], noNameOrDedent());
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsRecur(
	ref Lexer lexer,
	immutable ArgCtx ctx,
	ref ArrBuilder!ExprAst args,
) {
	verify(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	add(lexer.alloc, args, ad.expr);
	immutable(ArgsAndMaybeNameOrDedent) finish() =>
		immutable ArgsAndMaybeNameOrDedent(finishArr(lexer.alloc, args), ad.nameOrDedent);
	return matchOptNameOrDedent!(immutable ArgsAndMaybeNameOrDedent)(
		ad.nameOrDedent,
		(ref immutable OptNameOrDedent.None) =>
			finish(),
		(ref immutable OptNameOrDedent.Colon) =>
			finish(),
		(ref immutable OptNameOrDedent.Comma) =>
			parseArgsRecur(lexer, ctx, args),
		(ref immutable NameAndRange) =>
			finish(),
		(ref immutable OptNameOrDedent.Dedent) =>
			finish(),
		(ref immutable OptNameOrDedent.Question) =>
			finish());
}

immutable(ExprAndDedent) parseMutEquals(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst before,
	immutable uint curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
	if (before.kind.isA!IdentifierAst)
		return immutable ExprAndDedent(
			immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(allocate(lexer.alloc, immutable IdentifierSetAst(
					before.kind.as!IdentifierAst.name,
					initAndDedent.expr)))),
			initAndDedent.dedents);
	else if (before.kind.isA!CallAst) {
		immutable CallAst beforeCall = before.kind.as!CallAst;
		immutable CallAst.Style style = () {
			final switch (beforeCall.style) {
				case CallAst.Style.dot:
					return CallAst.Style.setDot;
				case CallAst.style.emptyParens:
					// `() := foo` is a syntax error
					return todo!(immutable CallAst.Style)("!");
				case CallAst.Style.single:
					// `a@<t> := foo` is a syntax error
					return todo!(immutable CallAst.Style)("!");
				case CallAst.Style.subscript:
					return CallAst.Style.setSubscript;
				case CallAst.Style.prefixOperator:
					if (beforeCall.funName.name == sym!"*")
						return CallAst.Style.setDeref;
					else
						// This is `~x := foo` or `-x := foo`. Have a diagnostic for this.
						return todo!(immutable CallAst.Style)("!");
				case CallAst.Style.suffixOperator:
					// `x! := foo`
					return todo!(immutable CallAst.Style)("!");
				case CallAst.Style.comma:
				case CallAst.Style.infix:
				case CallAst.Style.prefix:
				case CallAst.Style.setDeref:
				case CallAst.Style.setDot:
				case CallAst.Style.setSubscript:
					// We did parseExprBeforeCall before this, which can't parse any of these
					return unreachable!(immutable CallAst.Style)();
			}
		}();
		return makeCall(
			lexer, start, initAndDedent, beforeCall.funNameName, beforeCall.args, beforeCall.typeArgs, style);
	} else {
		addDiag(lexer, range(lexer, start), immutable ParseDiag(immutable ParseDiag.CantPrecedeMutEquals()));
		return makeCall(
			lexer, start, initAndDedent, sym!"bogus", [], [], CallAst.Style.setDot);
	}
}

immutable(ExprAndDedent) makeCall(
	ref Lexer lexer,
	immutable Pos start,
	immutable ExprAndDedent initAndDedent,
	immutable Sym name,
	immutable ExprAst[] args,
	immutable TypeAst[] typeArgs,
	immutable CallAst.Style style,
) {
	// TODO: range is wrong..
	immutable ExprAst call = immutable ExprAst(
		range(lexer, start),
		immutable ExprAstKind(immutable CallAst(
			style,
			immutable NameAndRange(
				start,
				style == CallAst.Style.setDeref ? sym!"set-deref" : prependSet(lexer.allSymbols, name)),
			typeArgs,
			append(lexer.alloc, args, initAndDedent.expr))));
	return immutable ExprAndDedent(call, initAndDedent.dedents);

}

immutable(ExprAndDedent) mustParseNextLines(
	ref Lexer lexer,
	immutable Pos start,
	immutable uint dedentsBefore,
	immutable uint curIndent,
) {
	if (dedentsBefore != 0) {
		immutable RangeWithinFile range = range(lexer, start);
		addDiag(lexer, range, immutable ParseDiag(immutable ParseDiag.LetMustHaveThen()));
		return immutable ExprAndDedent(bogusExpr(range), dedentsBefore);
	} else
		return parseStatementsAndDedents(lexer, curIndent);
}

immutable(NameAndRange) asIdentifierOrDiagnostic(ref Lexer lexer, ref immutable ExprAst a) {
	if (a.kind.isA!IdentifierAst)
		return immutable NameAndRange(a.range.start, a.kind.as!IdentifierAst.name);
	else {
		addDiag(lexer, a.range, immutable ParseDiag(immutable ParseDiag.CantPrecedeOptEquals()));
		return immutable NameAndRange(a.range.start, sym!"a");
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCalls(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	if (tryTakeToken(lexer, Token.comma)) {
		if (canParseCommaExpr(argCtx))
			return parseCallsAfterComma(lexer, start, lhs, argCtx);
		else
			return immutable ExprAndMaybeNameOrDedent(
				lhs,
				immutable OptNameOrDedent(immutable OptNameOrDedent.Comma()));
	} else if (tryTakeToken(lexer, Token.question))
		return parseCallsAfterQuestion(lexer, start, lhs, argCtx);
	else if (tryTakeToken(lexer, Token.colon))
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(immutable OptNameOrDedent.Colon()));
	else {
		immutable Opt!NameAndRange funName = tryTakeNameOrOperatorAndRange(lexer);
		return has(funName)
			? parseCallsAfterName(lexer, start, lhs, force(funName), argCtx)
			: immutable ExprAndMaybeNameOrDedent(lhs, noNameOrDedent());
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterQuestion(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	if (canParseTernaryExpr(argCtx)) {
		immutable ExprAndMaybeNameOrDedent then = parseExprAndCalls(lexer, argCtx);
		immutable(ExprAndMaybeNameOrDedent) stopHere() =>
			immutable ExprAndMaybeNameOrDedent(
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(
					allocate(lexer.alloc, immutable IfAst(lhs, then.expr, none!ExprAst)))),
				then.nameOrDedent);
		return matchOptNameOrDedent!(immutable ExprAndMaybeNameOrDedent)(
			then.nameOrDedent,
			(ref immutable OptNameOrDedent.None) =>
				stopHere(),
			(ref immutable OptNameOrDedent.Colon) {
				immutable ExprAst else_ = parseAfterColon(lexer, argCtx);
				return immutable ExprAndMaybeNameOrDedent(
					immutable ExprAst(
						range(lexer, start),
						immutable ExprAstKind(allocate(lexer.alloc, immutable IfAst(
							lhs,
							then.expr,
							some(else_))))),
					immutable OptNameOrDedent(immutable OptNameOrDedent.None()));
			},
			(ref immutable OptNameOrDedent.Comma) =>
				unreachable!(immutable ExprAndMaybeNameOrDedent),
			(ref immutable(NameAndRange)) =>
				unreachable!(immutable ExprAndMaybeNameOrDedent),
			(ref immutable OptNameOrDedent.Dedent) =>
				stopHere(),
			(ref immutable OptNameOrDedent.Question) =>
				todo!(immutable ExprAndMaybeNameOrDedent)("!"));
	} else
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(immutable OptNameOrDedent.Question()));
}

immutable(ExprAst) parseAfterColon(ref Lexer lexer, immutable ArgCtx argCtx) {
	immutable ExprAndMaybeNameOrDedent else_ = parseExprAndCalls(lexer, argCtx);
	return matchOptNameOrDedent!(immutable ExprAst)(
		else_.nameOrDedent,
		(ref immutable OptNameOrDedent.None) =>
			else_.expr,
		(ref immutable OptNameOrDedent.Colon) =>
			todo!(immutable ExprAst)("!"),
		(ref immutable OptNameOrDedent.Comma) =>
			unreachable!(immutable ExprAst),
		(ref immutable(NameAndRange)) =>
			unreachable!(immutable ExprAst),
		(ref immutable OptNameOrDedent.Dedent) =>
			unreachable!(immutable ExprAst),
		(ref immutable OptNameOrDedent.Question) =>
			todo!(immutable ExprAst)("!"));
}

immutable(bool) canParseTernaryExpr(ref immutable ArgCtx argCtx) =>
	ternaryPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

immutable(bool) canParseCommaExpr(ref immutable ArgCtx argCtx) =>
	commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterComma(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	ArrBuilder!ExprAst builder;
	add(lexer.alloc, builder, lhs);
	immutable ArgsAndMaybeNameOrDedent args = peekTokenExpression(lexer)
		? parseArgsRecur(lexer, requirePrecedenceGtComma(argCtx), builder)
		: immutable ArgsAndMaybeNameOrDedent(
			finishArr(lexer.alloc, builder),
			immutable OptNameOrDedent(immutable OptNameOrDedent.None()));
	immutable RangeWithinFile range = range(lexer, start);
	return immutable ExprAndMaybeNameOrDedent(
		immutable ExprAst(range, immutable ExprAstKind(
			immutable CallAst(
				CallAst.Style.comma,
				//TODO: range is wrong..
				immutable NameAndRange(range.start, sym!"new"),
				[],
				args.args))),
		args.nameOrDedent);
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterName(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable NameAndRange funName,
	immutable ArgCtx argCtx,
) {
	immutable int precedence = symPrecedence(funName.name);
	if (precedence > argCtx.allowedCalls.minPrecedenceExclusive) {
		//TODO: don't do this for operators
		immutable TypeAst[] typeArgs = tryParseTypeArgsForExpr(lexer);
		immutable ArgCtx innerCtx = requirePrecedenceGt(argCtx, precedence);
		immutable ArgsAndMaybeNameOrDedent args = isSymOperator(funName.name)
			? parseArgsForOperator(lexer, innerCtx)
			: parseArgs(lexer, innerCtx);
		immutable ExprAstKind exprKind = immutable ExprAstKind(
			immutable CallAst(CallAst.Style.infix, funName, typeArgs, prepend!ExprAst(lexer.alloc, lhs, args.args)));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), exprKind);
		immutable ExprAndMaybeNameOrDedent stopHere = immutable ExprAndMaybeNameOrDedent(expr, args.nameOrDedent);
		return matchOptNameOrDedent(
			args.nameOrDedent,
			(ref immutable OptNameOrDedent.None) =>
				stopHere,
			(ref immutable OptNameOrDedent.Colon) =>
				stopHere,
			(ref immutable OptNameOrDedent.Comma) =>
				canParseCommaExpr(argCtx)
					? parseCallsAfterComma(lexer, start, expr, argCtx)
					: stopHere,
			(ref immutable NameAndRange name) =>
				parseCallsAfterName(lexer, start, expr, name, argCtx),
			(ref immutable OptNameOrDedent.Dedent) =>
				stopHere,
			(ref immutable OptNameOrDedent.Question) =>
				parseCallsAfterQuestion(lexer, start, expr, argCtx));
	} else
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(funName));
}

// This is for the , in `1, 2`, not the comma between args
immutable int commaPrecedence = -6;
// Precedence for '?' and ':' in 'a ? b : c'
immutable int ternaryPrecedence = -5;

immutable(bool) isSymOperator(immutable Sym a) =>
	symPrecedence(a) != 0;

immutable(int) symPrecedence(immutable Sym a) {
	switch (a.value) {
		case sym!"~=".value:
		case sym!"~~=".value:
			return -4;
		case sym!"||".value:
			return -3;
		case sym!"&&".value:
			return -2;
		case sym!"??".value:
			return -1;
		case sym!"..".value:
			return 1;
		case sym!"~".value:
		case sym!"~~".value:
			return 2;
		case sym!"==".value:
		case sym!"!=".value:
		case sym!"<".value:
		case sym!"<=".value:
		case sym!">".value:
		case sym!">=".value:
		case sym!"<=>".value:
			return 3;
		case sym!"|".value:
			return 4;
		case sym!"^".value:
			return 5;
		case sym!"&".value:
			return 6;
		case sym!"<<".value:
		case sym!">>".value:
			return 7;
		case sym!"+".value:
		case sym!"-".value:
			return 8;
		case sym!"*".value:
		case sym!"/".value:
		case sym!"%".value:
			return 9;
		case sym!"**".value:
			return 10;
		case sym!"!".value:
			// prefix/suffix only
			return unreachable!int();
		default:
			// All other names
			return 0;
	}
}

immutable(OptNameOrDedent) nameOrDedentFromOptDedents(immutable Opt!uint dedents) =>
	has(dedents)
		? immutable OptNameOrDedent(immutable OptNameOrDedent.Dedent(force(dedents)))
		: noNameOrDedent();

immutable(ExprAst) tryParseDotsAndSubscripts(ref Lexer lexer, immutable ExprAst initial) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.dot)) {
		immutable NameAndRange name = takeNameAndRange(lexer);
		immutable TypeAst[] typeArgs = tryParseTypeArgsForExpr(lexer);
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, name, typeArgs, arrLiteral!ExprAst(lexer.alloc, [initial]));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.arrowAccess)) {
		immutable NameAndRange name = takeNameAndRange(lexer);
		immutable TypeAst[] typeArgs = tryParseTypeArgsForExpr(lexer);
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable ArrowAccessAst(initial, name, small(typeArgs))))));
	} else if (tryTakeToken(lexer, Token.bracketLeft)) {
		immutable ExprAst[] args = parseSubscriptArgs(lexer);
		immutable CallAst call = immutable CallAst(
			//TODO: the range is wrong..
			CallAst.Style.subscript,
			immutable NameAndRange(start, sym!"subscript"),
			[],
			prepend(lexer.alloc, initial, args));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.colon2)) {
		immutable TypeAst type = parseTypeRequireBracket(lexer);
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable TypedAst(initial, type)))));
	} else if (tryTakeOperator(lexer, sym!"!")) {
		immutable CallAst call = immutable CallAst(
			CallAst.Style.suffixOperator,
			immutable NameAndRange(start, sym!"!"),
			[],
			arrLiteral!ExprAst(lexer.alloc, [initial]));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else
		return initial;
}

immutable(ExprAndDedent) parseMatch(
	ref Lexer lexer,
	immutable Pos start,
	immutable uint curIndent,
) {
	immutable ExprAst matched = parseExprNoBlock(lexer);
	immutable uint dedentsAfterMatched = takeNewlineOrDedentAmount(lexer, curIndent);
	ArrBuilder!(MatchAst.CaseAst) cases;
	immutable uint dedents = dedentsAfterMatched != 0
		? dedentsAfterMatched
		: parseMatchCases(lexer, cases, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable MatchAst(matched, finishArr(lexer.alloc, cases))))),
		dedents);
}

immutable(uint) parseMatchCases(
	ref Lexer lexer,
	ref ArrBuilder!(MatchAst.CaseAst) cases,
	immutable uint curIndent,
) {
	immutable Pos startCase = curPos(lexer);
	if (tryTakeToken(lexer, Token.as)) {
		immutable Sym memberName = takeName(lexer);
		immutable NameOrUnderscoreOrNone localName = takeNameOrUnderscoreOrNone(lexer);
		immutable ExprAndDedent ed = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
			parseStatementsAndExtraDedents(lexer, curIndent + 1));
		add(lexer.alloc, cases, immutable MatchAst.CaseAst(range(lexer, startCase), memberName, localName, ed.expr));
		return ed.dedents == 0 ? parseMatchCases(lexer, cases, curIndent) : ed.dedents;
	} else
		return 0;
}

immutable(ExprAndDedent) parseIf(ref Lexer lexer, immutable Pos start, immutable uint curIndent) =>
	parseIfRecur(lexer, start, curIndent);

immutable(OptExprAndDedent) toOptExprAndDedent(immutable ExprAndDedent a) =>
	immutable OptExprAndDedent(some(a.expr), a.dedents);

immutable(ExprAndDedent) parseIfRecur(
	ref Lexer lexer,
	immutable Pos start,
	immutable uint curIndent,
) {
	immutable ExprAndMaybeDedent beforeCallAndDedent = parseExprBeforeCall(lexer, noBlock());
	assert(!has(beforeCallAndDedent.dedents));
	immutable ExprAst beforeCall = beforeCallAndDedent.expr;
	immutable bool isOption = tryTakeToken(lexer, Token.questionEqual);
	immutable ExprAst optionOrCondition = isOption
		? parseExprNoBlock(lexer)
		: assertNoNameOrDedent(parseCalls(
			lexer, start, beforeCall, immutable ArgCtx(noBlock(), allowAllCalls())));
	immutable ExprAndDedent thenAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	immutable ExprAst then = thenAndDedent.expr;
	immutable Pos elifStart = curPos(lexer);
	immutable OptExprAndDedent else_ = thenAndDedent.dedents != 0
		? immutable OptExprAndDedent(none!ExprAst, thenAndDedent.dedents)
		: tryTakeToken(lexer, Token.elif)
		? toOptExprAndDedent(parseIfRecur(lexer, elifStart, curIndent))
		: tryTakeToken(lexer, Token.else_)
		? toOptExprAndDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
			parseStatementsAndExtraDedents(lexer, curIndent + 1)))
		: immutable OptExprAndDedent(none!ExprAst, 0);

	immutable ExprAstKind kind = isOption
		? immutable ExprAstKind(allocate(lexer.alloc, immutable IfOptionAst(
			asIdentifierOrDiagnostic(lexer, beforeCall),
			optionOrCondition,
			then,
			has(else_.expr) ? some(force(else_.expr)) : none!ExprAst)))
		: immutable ExprAstKind(allocate(lexer.alloc, immutable IfAst(optionOrCondition, then, else_.expr)));
	return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), kind), else_.dedents);
}

struct ConditionAndBody {
	immutable ExprAst condition;
	immutable ExprAst body_;
	immutable uint dedents;
}

immutable(ConditionAndBody) parseConditionAndBody(ref Lexer lexer, immutable uint curIndent) {
	immutable ExprAst cond = parseExprNoBlock(lexer);
	immutable ExprAndDedent bodyAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	return immutable ConditionAndBody(cond, bodyAndDedent.expr, bodyAndDedent.dedents);
}

immutable(ExprAndDedent) parseUnless(ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable UnlessAst(cb.condition, cb.body_)))),
		cb.dedents);
}

immutable(ExprAndMaybeDedent) parseThrow(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	immutable ExprAndMaybeDedent thrown = parseExprAndAllCalls(lexer, allowedBlock);
	return immutable ExprAndMaybeDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable ThrowAst(thrown.expr)))),
		thrown.dedents);
}

immutable(ExprAndMaybeDedent) parseAssertOrForbid(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable AssertOrForbidKind kind,
) {
	immutable ExprAndMaybeNameOrDedent condition =
		parseExprAndCalls(lexer, immutable ArgCtx(allowedBlock, allowAllCalls));
	immutable(ExprAndMaybeDedent) noThrown(immutable Opt!uint dedents) =>
		immutable ExprAndMaybeDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(
				allocate(lexer.alloc, immutable AssertOrForbidAst(kind, condition.expr, none!ExprAst)))),
			dedents);
	return matchOptNameOrDedent!(immutable ExprAndMaybeDedent)(
		condition.nameOrDedent,
		(ref immutable OptNameOrDedent.None) =>
			noThrown(none!uint),
		(ref immutable OptNameOrDedent.Colon) {
			immutable ExprAst thrown =
				parseAfterColon(lexer, immutable ArgCtx(allowedBlock, allowAllCalls));
			return noDedent(immutable ExprAst(range(lexer, start), immutable ExprAstKind(
				allocate(lexer.alloc, immutable AssertOrForbidAst(kind, condition.expr, some(thrown))))));
		},
		(ref immutable OptNameOrDedent.Comma) =>
			unreachable!(immutable ExprAndMaybeDedent),
		(ref immutable(NameAndRange)) =>
			unreachable!(immutable ExprAndMaybeDedent),
		(ref immutable OptNameOrDedent.Dedent x) =>
			noThrown(some(x.dedents)),
		(ref immutable OptNameOrDedent.Question) =>
			todo!(immutable ExprAndMaybeDedent)("!"));
}

immutable(ExprAndMaybeDedent) parseFor(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	return parseForOrWith(
		lexer,
		start,
		allowedBlock,
		ParseDiag.NeedsBlockCtx.Kind.for_,
		(
			immutable OptNameAndRange[] params,
			immutable ExprAst col,
			immutable ExprAst body_,
			immutable Opt!ExprAst else_,
		) =>
			immutable ExprAstKind(allocate(lexer.alloc, immutable ForAst(params, col, body_, else_))));
}

immutable(ExprAndMaybeDedent) parseWith(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	return parseForOrWith(
		lexer,
		start,
		allowedBlock,
		ParseDiag.NeedsBlockCtx.Kind.with_,
		(
			immutable OptNameAndRange[] params,
			immutable ExprAst col,
			immutable ExprAst body_,
			immutable Opt!ExprAst else_,
		) =>
			immutable ExprAstKind(allocate(lexer.alloc, immutable WithAst(params, col, body_, else_))));
}

immutable(ExprAndMaybeDedent) parseForOrWith(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable ParseDiag.NeedsBlockCtx.Kind blockKind,
	scope immutable(ExprAstKind) delegate(
		immutable LambdaAst.Param[], immutable ExprAst rhs, immutable ExprAst body_, immutable Opt!ExprAst else_,
	) @safe @nogc pure nothrow cbMakeExprKind,
) {
	immutable LambdaAst.Param[] params = parseParametersForForOrWith(lexer);
	immutable ExprAst rhs = parseExprNoBlock(lexer);	
	immutable bool semi = tryTakeToken(lexer, Token.semicolon);
	if (semi) {
		immutable ExprAst body_ = parseExprNoBlock(lexer);
		return noDedent(immutable ExprAst(range(lexer, start), cbMakeExprKind(params, rhs, body_, none!ExprAst)));
	} else if (isAllowBlock(allowedBlock)) {
		immutable uint curIndent = asAllowBlock(allowedBlock).curIndent;
		return toMaybeDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () {
			immutable ExprAndDedent body_ = parseStatementsAndExtraDedents(lexer, curIndent + 1);
			immutable OptExprAndDedent else_ = () {
				if (body_.dedents == 0 && tryTakeToken(lexer, Token.else_)) {
					return toOptExprAndDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
						parseStatementsAndExtraDedents(lexer, curIndent + 1)));
				} else
					return immutable OptExprAndDedent(none!ExprAst, body_.dedents);
			}();
			return immutable ExprAndDedent(
				immutable ExprAst(range(lexer, start), cbMakeExprKind(params, rhs, body_.expr, else_.expr)),
				else_.dedents);
		}));
	} else
		return exprBlockNotAllowed(lexer, start, blockKind);
}

immutable(ExprAndDedent) parseLoop(ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable ExprAndDedent bodyAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable LoopAst(bodyAndDedent.expr)))),
		bodyAndDedent.dedents);
}

immutable(ExprAndDedent) parseLoopBreak(ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable OptExprAndDedent valueAndDedent = peekToken(lexer, Token.newline)
		? immutable OptExprAndDedent(none!ExprAst, takeNewlineOrDedentAmount(lexer, curIndent))
		: toOptExprAndDedent(parseExprNoLet(lexer, curIndent));
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable LoopBreakAst(valueAndDedent.expr)))),
		valueAndDedent.dedents);
}

immutable(ExprAndDedent) parseLoopUntil(ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable LoopUntilAst(cb.condition, cb.body_)))),
		cb.dedents);
}

immutable(ExprAndDedent) parseLoopWhile(ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable LoopWhileAst(cb.condition, cb.body_)))),
		cb.dedents);
}

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(
	ref Lexer lexer,
	immutable uint curIndent,
	scope immutable(ExprAndDedent) delegate() @safe @nogc pure nothrow cbIndent,
) =>
	takeIndentOrFailGeneric!ExprAndDedent(
		lexer,
		curIndent,
		cbIndent,
		(immutable RangeWithinFile range, immutable uint nDedents) =>
			immutable ExprAndDedent(bogusExpr(range), nDedents));

immutable(ExprAndMaybeDedent) parseLambdaWithParenthesizedParameters(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	immutable LambdaAst.Param[] parameters = parseParenthesizedLambdaParameters(lexer);
	if (!tryTakeToken(lexer, Token.arrowLambda))
		addDiagAtChar(lexer, immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.lambdaArrow)));
	return parseLambdaAfterArrow(lexer, start, allowedBlock, parameters);
}

immutable(LambdaAst.Param[]) parseParametersForForOrWith(ref Lexer lexer) =>
	parseForThenWithOrLambdaParameters(lexer, Token.colon, ParseDiag.Expected.Kind.colon);

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParameters(ref Lexer lexer) =>
	parseForThenWithOrLambdaParameters(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);

immutable(LambdaAst.Param[]) parseForThenWithOrLambdaParameters(
	ref Lexer lexer,
	immutable Token endToken,
	immutable ParseDiag.Expected.Kind expectedEndToken,
) {
	if (tryTakeToken(lexer, endToken))
		return [];
	else {
		ArrBuilder!(LambdaAst.Param) parameters;
		return parseLambdaParametersRecur(lexer, parameters, endToken, expectedEndToken);
	}
}

immutable(LambdaAst.Param[]) parseLambdaParametersRecur(
	ref Lexer lexer,
	ref ArrBuilder!(LambdaAst.Param) parameters,
	immutable Token endToken,
	immutable ParseDiag.Expected.Kind expectedEndToken,
) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = takeNameOrUnderscore(lexer);
	add(lexer.alloc, parameters, immutable LambdaAst.Param(start, name));
	if (tryTakeToken(lexer, Token.comma))
		return parseLambdaParametersRecur(lexer, parameters, endToken, expectedEndToken);
	else {
		if (!tryTakeToken(lexer, endToken))
			addDiagAtChar(lexer, immutable ParseDiag(immutable ParseDiag.Expected(expectedEndToken)));
		return finishArr(lexer.alloc, parameters);
	}
}

immutable(ExprAndMaybeDedent) parseLambdaAfterArrow(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable Opt!Sym paramName,
) =>
	parseLambdaAfterArrow(lexer, start, allowedBlock, arrLiteral!(LambdaAst.Param)(lexer.alloc, [
		immutable LambdaAst.Param(start, paramName)]));

immutable(ExprAndMaybeDedent) parseLambdaAfterArrow(
	ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable LambdaAst.Param[] parameters,
) {
	immutable bool inLine = peekTokenExpression(lexer);
	immutable ExprAndMaybeDedent body_ = () {
		if (isAllowBlock(allowedBlock)) {
			immutable uint curIndent = asAllowBlock(allowedBlock).curIndent;
			return inLine
				? toMaybeDedent(parseExprNoLet(lexer, curIndent))
				: toMaybeDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
					parseStatementsAndExtraDedents(lexer, curIndent + 1)));
		} else
			return inLine
				? noDedent(parseExprNoBlock(lexer))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.lambda);
	}();
	return immutable ExprAndMaybeDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable LambdaAst(parameters, body_.expr)))),
		body_.dedents);
}

immutable(ExprAndMaybeDedent) skipRestOfLineAndReturnBogusNoDiag(
	ref Lexer lexer,
	immutable Pos start,
) {
	skipUntilNewlineNoDiag(lexer);
	return noDedent(bogusExpr(range(lexer, start)));
}

immutable(ExprAndMaybeDedent) skipRestOfLineAndReturnBogus(
	ref Lexer lexer,
	immutable Pos start,
	immutable ParseDiag diag,
) {
	addDiag(lexer, range(lexer, start), diag);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

immutable(ExprAndMaybeDedent) exprBlockNotAllowed(
	ref Lexer lexer,
	immutable Pos start,
	immutable ParseDiag.NeedsBlockCtx.Kind kind,
) =>
	skipRestOfLineAndReturnBogus(lexer, start, immutable ParseDiag(immutable ParseDiag.NeedsBlockCtx(kind)));

immutable(ExprAndMaybeDedent) parseExprBeforeCall(ref Lexer lexer, immutable AllowedBlock allowedBlock) {
	immutable Pos start = curPos(lexer);
	immutable Token token = nextToken(lexer);
	switch (token) {
		case Token.parenLeft:
			if (lookaheadWillTakeArrow(lexer))
				return parseLambdaWithParenthesizedParameters(lexer, start, allowedBlock);
			else if (tryTakeToken(lexer, Token.parenRight)) {
				immutable ExprAst expr = immutable ExprAst(
					range(lexer, start),
					immutable ExprAstKind(immutable CallAst(
						CallAst.Style.emptyParens,
						//TODO: range is wrong..
						immutable NameAndRange(start, sym!"new"),
						[],
						[])));
				return noDedent(tryParseDotsAndSubscripts(lexer, expr));
			} else {
				immutable ExprAst inner = parseExprNoBlock(lexer);
				takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
				immutable ExprAst expr = immutable ExprAst(
					range(lexer, start),
					immutable ExprAstKind(allocate(lexer.alloc, immutable ParenthesizedAst(inner))));
				return noDedent(tryParseDotsAndSubscripts(lexer, expr));
			}
		case Token.quoteDouble:
		case Token.quoteDouble3:
			immutable QuoteKind quoteKind = token == Token.quoteDouble ? QuoteKind.double_ : QuoteKind.double3;
			immutable StringPart part = takeStringPart(lexer, quoteKind);
			immutable ExprAst quoted = () {
				final switch (part.after) {
					case StringPart.After.quote:
						return immutable ExprAst(
							range(lexer, start),
							immutable ExprAstKind(immutable LiteralStringAst(part.text)));
					case StringPart.After.lbrace:
						return takeInterpolated(lexer, start, part.text, quoteKind);
				}
			}();
			return noDedent(tryParseDotsAndSubscripts(lexer, quoted));
		case Token.assert_:
			return parseAssertOrForbid(lexer, start, allowedBlock, AssertOrForbidKind.assert_);
		case Token.break_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoopBreak(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.break_);
		case Token.continue_:
			return noDedent(immutable ExprAst(range(lexer, start), immutable ExprAstKind(immutable LoopContinueAst())));
		case Token.if_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseIf(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.if_);
		case Token.for_:
			return parseFor(lexer, start, allowedBlock);
		case Token.forbid:
			return parseAssertOrForbid(lexer, start, allowedBlock, AssertOrForbidKind.forbid);
		case Token.match:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseMatch(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.match);
		case Token.name:
			immutable Sym name = getCurSym(lexer);
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterArrow(lexer, start, allowedBlock, some(name))
				: handleName(lexer, start, immutable NameAndRange(start, name));
		case Token.operator:
			immutable Sym operator = getCurOperator(lexer);
			if (operator == sym!"&") {
				immutable ExprAndMaybeDedent inner = parseExprBeforeCall(lexer, noBlock());
				return immutable ExprAndMaybeDedent(
					immutable ExprAst(
						range(lexer, start),
						immutable ExprAstKind(allocate(lexer.alloc, immutable PtrAst(inner.expr)))),
					inner.dedents);
			} else
				return handlePrefixOperator(lexer, allowedBlock, start, operator);
		case Token.literalFloat:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(getCurLiteralFloat(lexer)))));
		case Token.literalInt:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(getCurLiteralInt(lexer)))));
		case Token.literalNat:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(getCurLiteralNat(lexer)))));
		case Token.loop:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoop(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.loop);
		case Token.throw_:
			return parseThrow(lexer, start, allowedBlock);
		case Token.underscore:
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterArrow(lexer, start, allowedBlock, none!Sym)
				: badToken(lexer, start, token);
		case Token.unless:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseUnless(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.unless);
		case Token.until:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoopUntil(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.until);
		case Token.while_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoopWhile(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.while_);
		case Token.with_:
			return parseWith(lexer, start, allowedBlock);
		default:
			return badToken(lexer, start, token);
	}
}

immutable(ExprAndMaybeDedent) badToken(ref Lexer lexer, immutable Pos start, immutable Token token) {
	addDiagUnexpectedCurToken(lexer, start, token);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

immutable(ExprAndMaybeDedent) handlePrefixOperator(
	ref Lexer lexer,
	immutable AllowedBlock allowedBlock,
	immutable Pos start,
	immutable Sym operator,
) {
	immutable ExprAndMaybeDedent arg = parseExprBeforeCall(lexer, allowedBlock);
	immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(
		immutable CallAst(
			CallAst.Style.prefixOperator,
			immutable NameAndRange(start, operator),
			[],
			arrLiteral!ExprAst(lexer.alloc, [arg.expr]))));
	return immutable ExprAndMaybeDedent(expr, arg.dedents);
}

immutable(ExprAndMaybeDedent) handleName(ref Lexer lexer, immutable Pos start, immutable NameAndRange name) {
	immutable TypeAst[] typeArgs = tryParseTypeArgsForExpr(lexer);
	if (!empty(typeArgs))
		return noDedent(immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable CallAst(CallAst.Style.single, name, typeArgs, []))));
	else {
		immutable ExprAst expr = immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable IdentifierAst(name.name)));
		return noDedent(tryParseDotsAndSubscripts(lexer, expr));
	}
}

immutable(ExprAst) takeInterpolated(
	ref Lexer lexer,
	immutable Pos start,
	immutable string firstText,
	immutable QuoteKind quoteKind,
) {
	ArrBuilder!InterpolatedPart parts;
	if (!empty(firstText))
		add(lexer.alloc, parts, immutable InterpolatedPart(firstText));
	return takeInterpolatedRecur(lexer, start, parts, quoteKind);
}

immutable(ExprAst) takeInterpolatedRecur(
	ref Lexer lexer,
	immutable Pos start,
	ref ArrBuilder!InterpolatedPart parts,
	immutable QuoteKind quoteKind,
) {
	immutable ExprAst e = parseExprNoBlock(lexer);
	add(lexer.alloc, parts, immutable InterpolatedPart(e));
	takeOrAddDiagExpectedToken(lexer, Token.braceRight, ParseDiag.Expected.Kind.closeInterpolated);
	immutable StringPart part = takeStringPart(lexer, quoteKind);
	if (!empty(part.text))
		add(lexer.alloc, parts, immutable InterpolatedPart(part.text));
	final switch (part.after) {
		case StringPart.After.quote:
			return immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable InterpolatedAst(finishArr(lexer.alloc, parts))));
		case StringPart.After.lbrace:
			return takeInterpolatedRecur(lexer, start, parts, quoteKind);
	}
}

immutable(ExprAndMaybeDedent) assertNoNameAfter(immutable ExprAndMaybeNameOrDedent a) =>
	immutable ExprAndMaybeDedent(a.expr, assertNoName(a.nameOrDedent));

immutable(Opt!uint) assertNoName(immutable OptNameOrDedent a) =>
	matchOptNameOrDedent!(immutable Opt!uint)(
		a,
		(ref immutable OptNameOrDedent.None) =>
			none!uint,
		(ref immutable OptNameOrDedent.Colon) =>
			unreachable!(immutable Opt!uint),
		(ref immutable OptNameOrDedent.Comma) =>
			unreachable!(immutable Opt!uint),
		(ref immutable(NameAndRange)) =>
			// We allowed all calls, so should be no dangling names
			unreachable!(immutable Opt!uint),
		(ref immutable OptNameOrDedent.Dedent it) =>
			some(it.dedents),
		(ref immutable OptNameOrDedent.Question) =>
			unreachable!(immutable Opt!uint));

immutable(ExprAst) parseExprNoBlock(ref Lexer lexer) {
	immutable ExprAndMaybeDedent ed = parseExprAndAllCalls(lexer, noBlock());
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprAndAllCalls(ref Lexer lexer, immutable AllowedBlock allowedBlock) {
	immutable ArgCtx argCtx = immutable ArgCtx(allowedBlock, allowAllCalls());
	return assertNoNameAfter(parseExprAndCalls(lexer, argCtx));
}

immutable(ExprAndMaybeNameOrDedent) parseExprAndCalls(ref Lexer lexer, immutable ArgCtx argCtx) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(lexer, argCtx.allowedBlock);
	return has(ed.dedents)
		? immutable ExprAndMaybeNameOrDedent(ed.expr, nameOrDedentFromOptDedents(ed.dedents))
		: parseCalls(lexer, start, ed.expr, argCtx);
}

immutable(ExprAndDedent) parseExprNoLet(ref Lexer lexer, immutable uint curIndent) =>
	addDedent(lexer, parseExprAndAllCalls(lexer, allowBlock(curIndent)), curIndent);

immutable(ExprAndDedent) parseSingleStatementLine(ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	immutable Opt!EqualsOrThen et = lookaheadWillTakeEqualsOrThen(lexer);
	if (has(et))
		return parseEqualsOrThen(lexer, curIndent, force(et));
	else {
		immutable ExprAndMaybeDedent expr = parseExprBeforeCall(lexer, allowBlock(curIndent));
		if (!has(expr.dedents) && tryTakeToken(lexer, Token.colonEqual))
			return parseMutEquals(lexer, start, expr.expr, curIndent);
		else {
			immutable ExprAndMaybeDedent fullExpr = has(expr.dedents)
				? expr
				: assertNoNameAfter(parseCalls(
					lexer,
					start,
					expr.expr,
					immutable ArgCtx(allowBlock(curIndent), allowAllCalls())));
			return addDedent(lexer, fullExpr, curIndent);
		}
	}
}

immutable(ExprAndDedent) parseEqualsOrThen(
	ref Lexer lexer,
	immutable uint curIndent,
	immutable EqualsOrThen kind,
) {
	immutable Pos start = curPos(lexer);
	final switch (kind) {
		case EqualsOrThen.equals:
			immutable OptNameAndRange name = takeOptNameAndRange(lexer);
			immutable bool mut = tryTakeToken(lexer, Token.mut);
			immutable Opt!(TypeAst*) type = parseTypeThenEquals(lexer);
			immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
			immutable ExprAndDedent thenAndDedent = mustParseNextLines(lexer, start, initAndDedent.dedents, curIndent);
			immutable ExprAstKind exprKind = immutable ExprAstKind(
				allocate(lexer.alloc, immutable LetAst(name.name, mut, type, initAndDedent.expr, thenAndDedent.expr)));
			return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
		case EqualsOrThen.then:
			immutable LambdaAst.Param[] params =
				parseForThenWithOrLambdaParameters(lexer, Token.arrowThen, ParseDiag.Expected.Kind.then);
			immutable ExprAndDedent futureAndDedent = parseExprNoLet(lexer, curIndent);
			immutable ExprAndDedent thenAndDedent =
				mustParseNextLines(lexer, start, futureAndDedent.dedents, curIndent);
			immutable ExprAstKind exprKind = immutable ExprAstKind(
				allocate(lexer.alloc, immutable ThenAst(params, futureAndDedent.expr, thenAndDedent.expr)));
			return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
	}
}

immutable(Opt!(TypeAst*)) parseTypeThenEquals(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.equal))
		return none!(TypeAst*);
	else {
		immutable TypeAst res = parseType(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.equal, ParseDiag.Expected.Kind.equals);
		return some(allocate(lexer.alloc, res));
	}
}

immutable(ExprAndDedent) addDedent(ref Lexer lexer, immutable ExprAndMaybeDedent e, immutable uint curIndent) =>
	immutable ExprAndDedent(
		e.expr,
		has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(lexer, curIndent));

immutable(ExprAndDedent) parseStatementsAndDedents(ref Lexer lexer, immutable uint curIndent) {
	immutable ExprAndDedent res = parseStatementsAndExtraDedents(lexer, curIndent);
	// Since we don't always expect a dedent here,
	// the dedent isn't *extra*, so increment to get the correct number of dedents.
	return immutable ExprAndDedent(res.expr, res.dedents + 1);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndExtraDedents(ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndDedent ed = parseSingleStatementLine(lexer, curIndent);
	return parseStatementsAndExtraDedentsRecur(lexer, start, ed.expr, curIndent, ed.dedents);
}

immutable(ExprAndDedent) parseStatementsAndExtraDedentsRecur(
	ref Lexer lexer,
	immutable Pos start,
	immutable ExprAst expr,
	immutable uint curIndent,
	immutable uint dedents,
) {
	if (dedents == 0) {
		immutable ExprAndDedent ed = parseSingleStatementLine(lexer, curIndent);
		immutable SeqAst seq = immutable SeqAst(expr, ed.expr);
		return parseStatementsAndExtraDedentsRecur(
			lexer,
			start,
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(allocate(lexer.alloc, seq))),
			curIndent,
			ed.dedents);
	} else
		return immutable ExprAndDedent(expr, dedents - 1);
}
