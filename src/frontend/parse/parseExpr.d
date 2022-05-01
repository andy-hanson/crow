module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	asCall,
	asIdentifier,
	BogusAst,
	CallAst,
	ExprAst,
	ExprAstKind,
	FunPtrAst,
	IdentifierAst,
	IfAst,
	IfOptionAst,
	InterpolatedAst,
	InterpolatedPart,
	isCall,
	isIdentifier,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	NameAndRange,
	NameOrUnderscoreOrNone,
	OptNameAndRange,
	ParenthesizedAst,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst,
	TypedAst,
	UnlessAst;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	curPos,
	getCurLiteral,
	getCurOperator,
	getCurSym,
	Lexer,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeArrow,
	nextToken,
	peekTokenExpression,
	QuoteKind,
	range,
	skipUntilNewlineNoDiag,
	StringPart,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNameOrUnderscore,
	takeNameOrUnderscoreOrNone,
	takeNewlineOrDedentAmount,
	takeOptNameAndRange,
	takeOrAddDiagExpectedToken,
	takeStringPart,
	Token,
	tryTakeNameOrOperatorAndRange,
	tryTakeOperator,
	tryTakeToken;
import frontend.parse.parseType : parseType, parseTypeRequireBracket, tryParseTypeArgsForExpr;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, small;
import util.col.arrUtil : append, arrLiteral, prepend;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : isSymOperator, Operator, operatorForSym, prependSet, shortSym, Sym, symForOperator;
import util.util : max, todo, unreachable, verify;

immutable(ExprAst) parseFunExprBody(scope ref Lexer lexer) {
	immutable Pos start = curPos(lexer);
	if (takeIndentOrDiagTopLevel(lexer)) {
		immutable ExprAndDedent ed = parseStatementsAndExtraDedents(lexer, 1);
		verify(ed.dedents == 0); // Since we started at the root, can't dedent more
		return ed.expr;
	} else
		return bogusExpr(range(lexer, start));
}

private:

immutable(ExprAst) bogusExpr(immutable RangeWithinFile range) {
	return immutable ExprAst(range, immutable ExprAstKind(immutable BogusAst()));
}

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

immutable(AllowedBlock) noBlock() {
	return immutable AllowedBlock(immutable AllowedBlock.NoBlock());
}

immutable(AllowedBlock) allowBlock(immutable uint curIndent) {
	return immutable AllowedBlock(immutable AllowedBlock.AllowBlock(curIndent));
}

immutable(bool) isAllowBlock(ref immutable AllowedBlock a) {
	return a.kind == AllowedBlock.Kind.allowBlock;
}

immutable(AllowedBlock.AllowBlock) asAllowBlock(ref immutable AllowedBlock a) {
	verify(isAllowBlock(a));
	return a.allowBlock;
}

struct AllowedCalls {
	immutable int minPrecedenceExclusive;
}

immutable(AllowedCalls) allowAllCalls() {
	return immutable AllowedCalls(int.min);
}

immutable(AllowedCalls) allowAllCallsExceptComma() {
	return immutable AllowedCalls(commaPrecedence);
}

enum AllowedPrefixCall { no, yes }

struct ArgCtx {
	// Allow 'foo: bar'. Not allowed after a '?' because then this is a ternary 'a ? b : c'.
	immutable AllowedPrefixCall allowedPrefixCall;
	// Allow things like 'if' that continue into an indented block.
	immutable AllowedBlock allowedBlock;
	immutable AllowedCalls allowedCalls;
}

immutable(ArgCtx) forbidPrefixCall(immutable ArgCtx a) {
	return immutable ArgCtx(AllowedPrefixCall.no, a.allowedBlock, a.allowedCalls);
}

immutable(ArgCtx) requirePrecedenceGt(immutable ArgCtx a, immutable int precedence) {
	return immutable ArgCtx(
		a.allowedPrefixCall,
		a.allowedBlock,
		immutable AllowedCalls(max(a.allowedCalls.minPrecedenceExclusive, precedence)));
}

immutable(ArgCtx) requirePrecedenceGtComma(immutable ArgCtx a) {
	return requirePrecedenceGt(a, commaPrecedence);
}

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

immutable(OptNameOrDedent) noNameOrDedent() {
	return immutable OptNameOrDedent(immutable OptNameOrDedent.None());
}

immutable(bool) isNone(ref immutable OptNameOrDedent a) {
	return a.kind == OptNameOrDedent.Kind.none;
}

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

immutable(ExprAndMaybeDedent) noDedent(immutable ExprAst e) {
	return immutable ExprAndMaybeDedent(e, none!uint);
}

immutable(ExprAndMaybeDedent) toMaybeDedent(immutable ExprAndDedent a) {
	return immutable ExprAndMaybeDedent(a.expr, some(a.dedents));
}

immutable(ExprAst[]) parseSubscriptArgs(scope ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.bracketRight))
		//TODO: syntax error
		return emptyArr!ExprAst;
	else {
		ArrBuilder!ExprAst builder;
		immutable ArgCtx argCtx = immutable ArgCtx(AllowedPrefixCall.no, noBlock(), allowAllCallsExceptComma());
		immutable ArgsAndMaybeNameOrDedent res = parseArgsRecur(lexer, argCtx, builder);
		if (!tryTakeToken(lexer, Token.bracketRight))
			addDiagAtChar(lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingBracket)));
		return assertNoNameOrDedent(res);
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsForOperator(scope ref Lexer lexer, immutable ArgCtx ctx) {
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	return immutable ArgsAndMaybeNameOrDedent(arrLiteral!ExprAst(lexer.alloc, [ad.expr]), ad.nameOrDedent);
}

immutable(ArgsAndMaybeNameOrDedent) parseArgs(scope ref Lexer lexer, immutable ArgCtx ctx) {
	if (tryTakeToken(lexer, Token.comma))
		return immutable ArgsAndMaybeNameOrDedent(
			emptyArr!ExprAst,
			immutable OptNameOrDedent(immutable OptNameOrDedent.Comma()));
	else if (tryTakeToken(lexer, Token.colon))
		return immutable ArgsAndMaybeNameOrDedent(
			emptyArr!ExprAst,
			immutable OptNameOrDedent(immutable OptNameOrDedent.Colon()));
	else if (peekTokenExpression(lexer)) {
		ArrBuilder!ExprAst builder;
		return parseArgsRecur(lexer, ctx, builder);
	} else
		return immutable ArgsAndMaybeNameOrDedent(emptyArr!ExprAst, noNameOrDedent());
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsRecur(
	scope ref Lexer lexer,
	immutable ArgCtx ctx,
	ref ArrBuilder!ExprAst args,
) {
	verify(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	add(lexer.alloc, args, ad.expr);
	immutable(ArgsAndMaybeNameOrDedent) finish() {
		return immutable ArgsAndMaybeNameOrDedent(finishArr(lexer.alloc, args), ad.nameOrDedent);
	}
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
	scope ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst before,
	immutable uint curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
	struct FromBefore {
		immutable Sym name;
		immutable ExprAst[] args;
		immutable TypeAst[] typeArgs;
		immutable CallAst.Style style;
	}
	immutable FromBefore fromBefore = () {
		if (isIdentifier(before.kind))
			return immutable FromBefore(
				asIdentifier(before.kind).name,
				emptyArr!ExprAst,
				emptyArr!TypeAst,
				CallAst.Style.setSingle);
		else if (isCall(before.kind)) {
			immutable CallAst beforeCall = asCall(before.kind);
			immutable CallAst.Style style = () {
				final switch (beforeCall.style) {
					case CallAst.Style.dot:
						return CallAst.Style.setDot;
					case CallAst.style.emptyParens:
						// `() := foo` is a syntax error
						return todo!(immutable CallAst.Style)("!");
					case CallAst.Style.single:
						return CallAst.Style.setSingle;
					case CallAst.Style.subscript:
						return CallAst.Style.setSubscript;
					case CallAst.Style.prefixOperator:
						if (beforeCall.funName.name == symForOperator(Operator.times))
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
					case CallAst.Style.setSingle:
					case CallAst.Style.setSubscript:
						// We did parseExprBeforeCall before this, which can't parse any of these
						return unreachable!(immutable CallAst.Style)();
				}
			}();
			return immutable FromBefore(beforeCall.funNameName, beforeCall.args, beforeCall.typeArgs, style);
		} else {
			addDiag(lexer, range(lexer, start), immutable ParseDiag(immutable ParseDiag.CantPrecedeMutEquals()));
			return immutable FromBefore(shortSym("bogus"), emptyArr!ExprAst, emptyArr!TypeAst, CallAst.Style.setSingle);
		}
	}();
	// TODO: range is wrong..
	immutable ExprAst call = immutable ExprAst(
		range(lexer, start),
		immutable ExprAstKind(immutable CallAst(
			fromBefore.style,
			immutable NameAndRange(
				before.range.start,
				fromBefore.style == CallAst.Style.setDeref
					? shortSym("set-deref")
					: prependSet(lexer.allSymbols, fromBefore.name)),
			fromBefore.typeArgs,
			append(lexer.alloc, fromBefore.args, initAndDedent.expr))));
	return immutable ExprAndDedent(call, initAndDedent.dedents);
}

immutable(ExprAndDedent) mustParseNextLines(
	scope ref Lexer lexer,
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

immutable(NameAndRange) asIdentifierOrDiagnostic(scope ref Lexer lexer, ref immutable ExprAst a) {
	if (isIdentifier(a.kind))
		return identifierAsNameAndRange(a);
	else {
		addDiag(lexer, a.range, immutable ParseDiag(immutable ParseDiag.CantPrecedeOptEquals()));
		return immutable NameAndRange(a.range.start, shortSym("a"));
	}
}

immutable(NameAndRange) identifierAsNameAndRange(ref immutable ExprAst a) {
	return immutable NameAndRange(a.range.start, asIdentifier(a.kind).name);
}

immutable(ExprAndMaybeNameOrDedent) parseCalls(
	scope ref Lexer lexer,
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
	} else if (tryTakeToken(lexer, Token.question)) {
		return parseCallsAfterQuestion(lexer, start, lhs, argCtx);
	} else if (tryTakeToken(lexer, Token.colon)) {
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(immutable OptNameOrDedent.Colon()));
	} else {
		immutable Opt!NameAndRange funName = tryTakeNameOrOperatorAndRange(lexer);
		return has(funName)
			? parseCallsAfterName(lexer, start, lhs, force(funName), argCtx)
			: immutable ExprAndMaybeNameOrDedent(lhs, noNameOrDedent());
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterQuestion(
	scope ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	if (canParseTernaryExpr(argCtx)) {
		immutable ExprAndMaybeNameOrDedent then = parseExprAndCalls(lexer, forbidPrefixCall(argCtx));
		immutable(ExprAndMaybeNameOrDedent) stopHere() {
			return immutable ExprAndMaybeNameOrDedent(
				immutable ExprAst(range(lexer, start), immutable ExprAstKind(
					allocate(lexer.alloc, immutable IfAst(lhs, then.expr, none!ExprAst)))),
				then.nameOrDedent);
		}
		return matchOptNameOrDedent!(immutable ExprAndMaybeNameOrDedent)(
			then.nameOrDedent,
			(ref immutable OptNameOrDedent.None) =>
				stopHere(),
			(ref immutable OptNameOrDedent.Colon) {
				immutable ExprAndMaybeNameOrDedent else_ = parseExprAndCalls(lexer, forbidPrefixCall(argCtx));
				immutable(ExprAndMaybeNameOrDedent) stopAfterElse() {
					return immutable ExprAndMaybeNameOrDedent(
						immutable ExprAst(
							range(lexer, start),
							immutable ExprAstKind(allocate(lexer.alloc, immutable IfAst(
								lhs,
								then.expr,
								some(else_.expr))))),
						else_.nameOrDedent);
				}
				return matchOptNameOrDedent!(immutable ExprAndMaybeNameOrDedent)(
					else_.nameOrDedent,
					(ref immutable OptNameOrDedent.None) =>
						stopAfterElse(),
					(ref immutable OptNameOrDedent.Colon) =>
						todo!(immutable ExprAndMaybeNameOrDedent)("!"),
					(ref immutable OptNameOrDedent.Comma) =>
						unreachable!(immutable ExprAndMaybeNameOrDedent),
					(ref immutable(NameAndRange)) =>
						unreachable!(immutable ExprAndMaybeNameOrDedent),
					(ref immutable OptNameOrDedent.Dedent) =>
						unreachable!(immutable ExprAndMaybeNameOrDedent),
					(ref immutable OptNameOrDedent.Question) =>
						todo!(immutable ExprAndMaybeNameOrDedent)("!"));
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

immutable(bool) canParseTernaryExpr(ref immutable ArgCtx argCtx) {
	return ternaryPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;
}

immutable(bool) canParseCommaExpr(ref immutable ArgCtx argCtx) {
	return commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterComma(
	scope ref Lexer lexer,
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
				immutable NameAndRange(range.start, shortSym("new")),
				emptyArr!TypeAst,
				args.args))),
		args.nameOrDedent);
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterName(
	scope ref Lexer lexer,
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

immutable(int) symPrecedence(immutable Sym a) {
	immutable Opt!Operator operator = operatorForSym(a);
	return has(operator) ? operatorPrecedence(force(operator)) : 0;
}

// This is for the , in `1, 2`, not the comma between args
immutable int commaPrecedence = -6;
// Precedence for '?' and ':' in 'a ? b : c'
immutable int ternaryPrecedence = -5;

immutable(int) operatorPrecedence(immutable Operator a) {
	final switch (a) {
		case Operator.tildeEquals:
		case Operator.tilde2Equals:
			return -4;
		case Operator.or2:
			return -3;
		case Operator.and2:
			return -2;
		case Operator.question2:
			return -1;
		case Operator.range:
			return 1;
		case Operator.tilde:
		case Operator.tilde2:
			return 2;
		case Operator.equal:
		case Operator.notEqual:
		case Operator.less:
		case Operator.lessOrEqual:
		case Operator.greater:
		case Operator.greaterOrEqual:
		case Operator.compare:
			return 3;
		case Operator.or1:
			return 4;
		case Operator.xor1:
			return 5;
		case Operator.and1:
			return 6;
		case Operator.shiftLeft:
		case Operator.shiftRight:
			return 7;
		case Operator.plus:
		case Operator.minus:
			return 8;
		case Operator.times:
		case Operator.divide:
		case Operator.modulo:
			return 9;
		case Operator.exponent:
			return 10;
		case Operator.not:
			// prefix only
			return unreachable!int();
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterSimpleExpr(
	scope ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	immutable ExprAstKind kind = lhs.kind;
	if (argCtx.allowedPrefixCall == AllowedPrefixCall.yes
		&& ((isCall(kind) && asCall(kind).style == CallAst.Style.single) || isIdentifier(kind))
		&& tryTakeToken(lexer, Token.colon)) {
		struct NameAndTypeArgs {
			immutable NameAndRange name;
			immutable TypeAst[] typeArgs;
		}
		immutable NameAndTypeArgs nameAndTypeArgs = () {
			if (isCall(kind))
				return immutable NameAndTypeArgs(asCall(kind).funName, asCall(kind).typeArgs);
			else
				return immutable NameAndTypeArgs(
					immutable NameAndRange(lhs.range.start, asIdentifier(kind).name),
					emptyArr!TypeAst);
		}();
		immutable ArgsAndMaybeNameOrDedent ad = parseArgs(lexer, requirePrecedenceGtComma(argCtx));
		immutable CallAst call = immutable CallAst(
			CallAst.Style.prefix,
			nameAndTypeArgs.name,
			nameAndTypeArgs.typeArgs,
			ad.args);
		return immutable ExprAndMaybeNameOrDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)),
			ad.nameOrDedent);
	} else
		return parseCalls(lexer, start, lhs, argCtx);
}

immutable(OptNameOrDedent) nameOrDedentFromOptDedents(immutable Opt!uint dedents) {
	return has(dedents)
		? immutable OptNameOrDedent(immutable OptNameOrDedent.Dedent(force(dedents)))
		: noNameOrDedent();
}

immutable(ExprAst) tryParseDotsAndSubscripts(scope ref Lexer lexer, immutable ExprAst initial) {
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
			immutable NameAndRange(start, shortSym("subscript")),
			emptyArr!TypeAst,
			prepend(lexer.alloc, initial, args));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.colon2)) {
		immutable TypeAst type = parseTypeRequireBracket(lexer);
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable TypedAst(initial, type)))));
	} else if (tryTakeOperator(lexer, Operator.not)) {
		immutable CallAst call = immutable CallAst(
			CallAst.Style.suffixOperator,
			immutable NameAndRange(start, symForOperator(Operator.not)),
			emptyArr!TypeAst,
			arrLiteral!ExprAst(lexer.alloc, [initial]));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else
		return initial;
}

immutable(ExprAndDedent) parseMatch(
	scope ref Lexer lexer,
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
	scope ref Lexer lexer,
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

immutable(ExprAndDedent) parseIf(scope ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	return parseIfRecur(lexer, start, curIndent);
}

immutable(OptExprAndDedent) toOptExprAndDedent(immutable ExprAndDedent a) {
	return immutable OptExprAndDedent(some(a.expr), a.dedents);
}

immutable(ExprAndDedent) parseIfRecur(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable uint curIndent,
) {
	immutable ExprAndMaybeDedent beforeCallAndDedent = parseExprBeforeCall(lexer, noBlock());
	assert(!has(beforeCallAndDedent.dedents));
	immutable ExprAst beforeCall = beforeCallAndDedent.expr;
	immutable bool isOption = tryTakeToken(lexer, Token.questionEqual);
	immutable ExprAst optionOrCondition = isOption
		? parseExprNoBlock(lexer)
		: assertNoNameOrDedent(parseCallsAfterSimpleExpr(
			lexer, start, beforeCall, immutable ArgCtx(AllowedPrefixCall.no, noBlock(), allowAllCalls())));
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

immutable(ExprAndDedent) parseUnless(scope ref Lexer lexer, immutable Pos start, immutable uint curIndent) {
	immutable ExprAst cond = parseExprNoBlock(lexer);
	immutable ExprAndDedent thenAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable UnlessAst(cond, thenAndDedent.expr)))),
		thenAndDedent.dedents);
}

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(
	scope ref Lexer lexer,
	immutable uint curIndent,
	scope immutable(ExprAndDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndDedent(
		lexer,
		curIndent,
		cbIndent,
		(immutable RangeWithinFile range, immutable uint nDedents) =>
			immutable ExprAndDedent(bogusExpr(range), nDedents));
}

immutable(ExprAndMaybeDedent) parseLambdaWithParenthesizedParameters(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	immutable LambdaAst.Param[] parameters = parseParenthesizedLambdaParameters(lexer);
	if (!tryTakeToken(lexer, Token.arrowLambda))
		addDiagAtChar(lexer, immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.lambdaArrow)));
	return parseLambdaAfterArrow(lexer, start, allowedBlock, parameters);
}

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParameters(scope ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenRight))
		return emptyArr!(LambdaAst.Param);
	else {
		ArrBuilder!(LambdaAst.Param) parameters;
		return parseParenthesizedLambdaParametersRecur(lexer, parameters);
	}
}

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParametersRecur(
	scope ref Lexer lexer,
	ref ArrBuilder!(LambdaAst.Param) parameters,
) {
	immutable Pos start = curPos(lexer);
	immutable Opt!Sym name = takeNameOrUnderscore(lexer);
	add(lexer.alloc, parameters, immutable LambdaAst.Param(start, name));
	if (tryTakeToken(lexer, Token.comma))
		return parseParenthesizedLambdaParametersRecur(lexer, parameters);
	else {
		if (!tryTakeToken(lexer, Token.parenRight))
			addDiagAtChar(lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingParen)));
		return finishArr(lexer.alloc, parameters);
	}
}

immutable(ExprAndMaybeDedent) parseLambdaAfterArrow(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable Opt!Sym paramName,
) {
	return parseLambdaAfterArrow(lexer, start, allowedBlock, arrLiteral!(LambdaAst.Param)(lexer.alloc, [
		immutable LambdaAst.Param(start, paramName)]));
}

immutable(ExprAndMaybeDedent) parseLambdaAfterArrow(
	scope ref Lexer lexer,
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
	scope ref Lexer lexer,
	immutable Pos start,
) {
	skipUntilNewlineNoDiag(lexer);
	return noDedent(bogusExpr(range(lexer, start)));
}

immutable(ExprAndMaybeDedent) skipRestOfLineAndReturnBogus(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable ParseDiag diag,
) {
	addDiag(lexer, range(lexer, start), diag);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

immutable(ExprAndMaybeDedent) exprBlockNotAllowed(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable ParseDiag.NeedsBlockCtx.Kind kind,
) {
	return skipRestOfLineAndReturnBogus(lexer, start, immutable ParseDiag(immutable ParseDiag.NeedsBlockCtx(kind)));
}

immutable(ExprAndMaybeDedent) parseExprBeforeCall(scope ref Lexer lexer, immutable AllowedBlock allowedBlock) {
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
						immutable NameAndRange(start, shortSym("new")),
						emptyArr!TypeAst,
						emptyArr!ExprAst)));
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
			final switch (part.after) {
				case StringPart.After.quote:
					return handleLiteral(lexer, start, immutable LiteralAst(part.text));
				case StringPart.After.lbrace:
					immutable ExprAst interpolated = takeInterpolated(lexer, start, part.text, quoteKind);
					return noDedent(tryParseDotsAndSubscripts(lexer, interpolated));
			}
		case Token.if_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseIf(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.if_);
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
			// '&' can't be used as a prefix operator, instead it makes a fun-ptr
			immutable Operator operator = getCurOperator(lexer);
			if (operator == Operator.and1) {
				immutable Sym name = takeNameOrOperator(lexer);
				return noDedent(immutable ExprAst(
					range(lexer, start),
					immutable ExprAstKind(immutable FunPtrAst(name))));
			} else
				return handlePrefixOperator(lexer, allowedBlock, start, getCurOperator(lexer));
		case Token.literal:
			return handleLiteral(lexer, start, getCurLiteral(lexer));
		case Token.underscore:
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterArrow(lexer, start, allowedBlock, none!Sym)
				: badToken(lexer, start, token);
		case Token.unless:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseUnless(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.unless);
		default:
			return badToken(lexer, start, token);
	}
}

immutable(ExprAndMaybeDedent) badToken(scope ref Lexer lexer, immutable Pos start, immutable Token token) {
	addDiagUnexpectedCurToken(lexer, start, token);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

immutable(ExprAndMaybeDedent) handlePrefixOperator(
	scope ref Lexer lexer,
	immutable AllowedBlock allowedBlock,
	immutable Pos start,
	immutable Operator operator,
) {
	immutable ExprAndMaybeDedent arg = parseExprBeforeCall(lexer, allowedBlock);
	immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(
		immutable CallAst(
			CallAst.Style.prefixOperator,
			immutable NameAndRange(start, symForOperator(operator)),
			emptyArr!TypeAst,
			arrLiteral!ExprAst(lexer.alloc, [arg.expr]))));
	return immutable ExprAndMaybeDedent(expr, arg.dedents);
}

immutable(ExprAndMaybeDedent) handleLiteral(
	scope ref Lexer lexer,
	immutable Pos start,
	immutable LiteralAst literal,
) {
	immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(literal));
	return noDedent(tryParseDotsAndSubscripts(lexer, expr));
}

immutable(ExprAndMaybeDedent) handleName(scope ref Lexer lexer, immutable Pos start, immutable NameAndRange name) {
	immutable TypeAst[] typeArgs = tryParseTypeArgsForExpr(lexer);
	if (!empty(typeArgs)) {
		return noDedent(immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(
				immutable CallAst(CallAst.Style.single, name, typeArgs, emptyArr!ExprAst))));
	} else {
		immutable ExprAst expr = immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable IdentifierAst(name.name)));
		return noDedent(tryParseDotsAndSubscripts(lexer, expr));
	}
}

immutable(ExprAst) takeInterpolated(
	scope ref Lexer lexer,
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
	scope ref Lexer lexer,
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

immutable(ExprAndMaybeDedent) assertNoNameAfter(immutable ExprAndMaybeNameOrDedent a) {
	return immutable ExprAndMaybeDedent(a.expr, assertNoName(a.nameOrDedent));
}

immutable(Opt!uint) assertNoName(immutable OptNameOrDedent a) {
	return matchOptNameOrDedent!(immutable Opt!uint)(
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
}

immutable(ExprAst) parseExprNoBlock(scope ref Lexer lexer) {
	immutable ExprAndMaybeDedent ed = parseExprAndAllCalls(lexer, noBlock());
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprAndAllCalls(scope ref Lexer lexer, immutable AllowedBlock allowedBlock) {
	immutable ArgCtx argCtx = immutable ArgCtx(AllowedPrefixCall.yes, allowedBlock, allowAllCalls());
	return assertNoNameAfter(parseExprAndCalls(lexer, argCtx));
}

immutable(ExprAndMaybeNameOrDedent) parseExprAndCalls(scope ref Lexer lexer, immutable ArgCtx argCtx) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(lexer, argCtx.allowedBlock);
	return has(ed.dedents)
		? immutable ExprAndMaybeNameOrDedent(ed.expr, nameOrDedentFromOptDedents(ed.dedents))
		: parseCallsAfterSimpleExpr(lexer, start, ed.expr, argCtx);
}

immutable(ExprAndDedent) parseExprNoLet(scope ref Lexer lexer, immutable uint curIndent) {
	return addDedent(lexer, parseExprAndAllCalls(lexer, allowBlock(curIndent)), curIndent);
}

immutable(ExprAndDedent) parseSingleStatementLine(scope ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	if (lookaheadWillTakeEqualsOrThen(lexer))
		return parseEqualsOrThen(lexer, curIndent);
	else if (tryTakeToken(lexer, Token.arrowThen)) {
		immutable ExprAndDedent init = parseExprNoLet(lexer, curIndent);
		immutable ExprAndDedent then = mustParseNextLines(lexer, start, init.dedents, curIndent);
		return immutable ExprAndDedent(
			immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(allocate(lexer.alloc, immutable ThenVoidAst(init.expr, then.expr)))),
			then.dedents);
	} else {
		immutable ExprAndMaybeDedent expr = parseExprBeforeCall(lexer, allowBlock(curIndent));
		if (!has(expr.dedents) && tryTakeToken(lexer, Token.colonEqual))
			return parseMutEquals(lexer, start, expr.expr, curIndent);
		else {
			immutable ExprAndMaybeDedent fullExpr = has(expr.dedents)
				? expr
				: assertNoNameAfter(parseCallsAfterSimpleExpr(
					lexer,
					start,
					expr.expr,
					immutable ArgCtx(AllowedPrefixCall.yes, allowBlock(curIndent), allowAllCalls())));
			return addDedent(lexer, fullExpr, curIndent);
		}
	}
}

immutable(ExprAndDedent) parseEqualsOrThen(scope ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	immutable OptNameAndRange name = takeOptNameAndRange(lexer);
	immutable TypeAndEqualsOrThen te = parseTypeAndEqualsOrThen(lexer);
	immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
	immutable ExprAndDedent thenAndDedent =
		mustParseNextLines(lexer, start, initAndDedent.dedents, curIndent);
	immutable ExprAstKind exprKind =
		letOrThen(lexer.alloc, name, te.type, te.equalsOrThen, initAndDedent.expr, thenAndDedent.expr);
	return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
}

immutable(ExprAstKind) letOrThen(
	scope ref Alloc alloc,
	immutable OptNameAndRange name,
	immutable Opt!(TypeAst*) type,
	immutable EqualsOrThen kind,
	immutable ExprAst init,
	immutable ExprAst then,
) {
	final switch (kind) {
		case EqualsOrThen.equals:
			return immutable ExprAstKind(allocate(alloc, immutable LetAst(name.name, type, init, then)));
		case EqualsOrThen.then:
			// TODO: use the type (need lambda parameter types)
			return immutable ExprAstKind(allocate(alloc, immutable ThenAst(name, init, then)));
	}
}

enum EqualsOrThen { equals, then }
struct TypeAndEqualsOrThen {
	immutable Opt!(TypeAst*) type;
	immutable EqualsOrThen equalsOrThen;
}
immutable(TypeAndEqualsOrThen) parseTypeAndEqualsOrThen(scope ref Lexer lexer) {
	immutable Opt!EqualsOrThen res = tryTakeEqualsOrThen(lexer);
	if (has(res))
		return immutable TypeAndEqualsOrThen(none!(TypeAst*), force(res));
	else {
		immutable TypeAst type = parseType(lexer);
		immutable Opt!EqualsOrThen optEqualsOrThen = tryTakeEqualsOrThen(lexer);
		immutable EqualsOrThen equalsOrThen = () {
			if (has(optEqualsOrThen))
				return force(optEqualsOrThen);
			else {
				addDiagAtChar(lexer, immutable ParseDiag(
					immutable ParseDiag.Expected(ParseDiag.Expected.Kind.equalsOrThen)));
				return EqualsOrThen.equals;
			}
		}();
		return immutable TypeAndEqualsOrThen(some(allocate(lexer.alloc, type)), equalsOrThen);
	}
}

immutable(Opt!EqualsOrThen) tryTakeEqualsOrThen(scope ref Lexer lexer) {
	return tryTakeToken(lexer, Token.equal)
		? some(EqualsOrThen.equals)
		: tryTakeToken(lexer, Token.arrowThen)
		? some(EqualsOrThen.then)
		: none!EqualsOrThen;
}

immutable(ExprAndDedent) addDedent(scope ref Lexer lexer, immutable ExprAndMaybeDedent e, immutable uint curIndent) {
	return immutable ExprAndDedent(
		e.expr,
		has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(lexer, curIndent));
}


immutable(ExprAndDedent) parseStatementsAndDedents(scope ref Lexer lexer, immutable uint curIndent) {
	immutable ExprAndDedent res = parseStatementsAndExtraDedents(lexer, curIndent);
	// Since we don't always expect a dedent here,
	// the dedent isn't *extra*, so increment to get the correct number of dedents.
	return immutable ExprAndDedent(res.expr, res.dedents + 1);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndExtraDedents(scope ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndDedent ed = parseSingleStatementLine(lexer, curIndent);
	return parseStatementsAndExtraDedentsRecur(lexer, start, ed.expr, curIndent, ed.dedents);
}

immutable(ExprAndDedent) parseStatementsAndExtraDedentsRecur(
	scope ref Lexer lexer,
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
