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
	ParenthesizedAst,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst,
	TypedAst;
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
	peekToken,
	peekTokenExpression,
	range,
	skipUntilNewlineNoDiag,
	StringPart,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameOrOperator,
	takeNameOrOperatorAndRange,
	takeNameOrUnderscoreOrNone,
	takeNewlineOrDedentAmount,
	takeOrAddDiagExpectedToken,
	takeStringPart,
	Token,
	tryTakeToken;
import frontend.parse.parseType : parseType, parseTypeRequireBracket, tryParseTypeArgsForExpr;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : ArrWithSize, empty, emptyArr, emptyArrWithSize, only, toArr;
import util.col.arrUtil : append, arrLiteral, arrWithSizeLiteral, prepend;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrWithSizeBuilder : add, ArrWithSizeBuilder, finishArrWithSize;
import util.memory : allocate;
import util.opt : force, has, none, nonePtr, Opt, OptPtr, some, somePtr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym :
	isSymOperator,
	Operator,
	operatorForSym,
	prependSet,
	shortSym,
	Sym,
	symEq,
	symForOperator;
import util.util : max, todo, unreachable, verify;

immutable(ExprAst) parseFunExprBody(ref Lexer lexer) {
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

struct ArgCtx {
	// Allow things like 'if', 'match', '\' that continue into an indented block.
	immutable AllowedBlock allowedBlock;
	// In `a b: c d e`, we parse `a b (c d e) and not `(a b c) d e`, since `: turns on `allowCall`.
	immutable AllowedCalls allowedCalls;
}

immutable(ArgCtx) requirePrecedenceGt(ref immutable ArgCtx a, immutable int precedence) {
	return immutable ArgCtx(
		a.allowedBlock,
		immutable AllowedCalls(max(a.allowedCalls.minPrecedenceExclusive, precedence)));
}

immutable(ArgCtx) requirePrecedenceGtComma(ref immutable ArgCtx a) {
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

	struct Comma {}
	struct Dedent { immutable uint dedents; }
	struct None {}

	immutable this(immutable NameAndRange a) { kind = Kind.name; name = a; }
	immutable this(immutable Comma a) { kind = Kind.comma; comma = a; }
	immutable this(immutable Dedent a) { kind = Kind.dedent; dedent = a; }
	immutable this(immutable None a) { kind = Kind.none; none = a; }

	private:
	enum Kind {
		name,
		comma,
		dedent,
		none,
	}
	immutable Kind kind;
	union {
		immutable NameAndRange name;
		immutable Comma comma;
		immutable Dedent dedent;
		immutable None none;
	}
}

immutable(OptNameOrDedent) noNameOrDedent() {
	return immutable OptNameOrDedent(immutable OptNameOrDedent.None());
}

immutable(bool) isNone(ref immutable OptNameOrDedent a) {
	return a.kind == OptNameOrDedent.Kind.none;
}

T matchOptNameOrDedent(T)(
	ref immutable OptNameOrDedent a,
	scope T delegate(ref immutable OptNameOrDedent.None) @safe @nogc pure nothrow cbNone,
	scope T delegate(ref immutable OptNameOrDedent.Comma) @safe @nogc pure nothrow cbComma,
	scope T delegate(ref immutable NameAndRange) @safe @nogc pure nothrow cbName,
	scope T delegate(ref immutable OptNameOrDedent.Dedent) @safe @nogc pure nothrow cbDedent,
) {
	final switch (a.kind) {
		case OptNameOrDedent.Kind.none:
			return cbNone(a.none);
		case OptNameOrDedent.Kind.comma:
			return cbComma(a.comma);
		case OptNameOrDedent.Kind.name:
			return cbName(a.name);
		case OptNameOrDedent.Kind.dedent:
			return cbDedent(a.dedent);
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
immutable(ArrWithSize!ExprAst) assertNoNameOrDedent(immutable ArgsAndMaybeNameOrDedent a) {
	verify(isNone(a.nameOrDedent));
	return a.args;
}

struct OptExprAndDedent {
	immutable Opt!ExprAst expr;
	immutable uint dedents;
}

struct ArgsAndMaybeNameOrDedent {
	immutable ArrWithSize!ExprAst args;
	immutable OptNameOrDedent nameOrDedent;
}

immutable(ExprAndMaybeDedent) noDedent(immutable ExprAst e) {
	return immutable ExprAndMaybeDedent(e, none!uint);
}

immutable(ExprAndMaybeDedent) toMaybeDedent(immutable ExprAndDedent a) {
	return immutable ExprAndMaybeDedent(a.expr, some(a.dedents));
}

immutable(ArrWithSize!ExprAst) parseSubscriptArgs(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.bracketRight))
		//TODO: syntax error
		return emptyArrWithSize!ExprAst;
	else {
		ArrWithSizeBuilder!ExprAst builder;
		immutable ArgCtx argCtx = immutable ArgCtx(noBlock(), allowAllCallsExceptComma());
		immutable ArgsAndMaybeNameOrDedent res = parseArgsRecur(lexer, argCtx, builder);
		if (!tryTakeToken(lexer, Token.bracketRight))
			addDiagAtChar(lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingBracket)));
		return assertNoNameOrDedent(res);
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsForOperator(ref Lexer lexer, ref immutable ArgCtx ctx) {
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	return immutable ArgsAndMaybeNameOrDedent(arrWithSizeLiteral!ExprAst(lexer.alloc, [ad.expr]), ad.nameOrDedent);
}

immutable(ArgsAndMaybeNameOrDedent) parseArgs(ref Lexer lexer, immutable ArgCtx ctx) {
	if (tryTakeToken(lexer, Token.comma))
		return immutable ArgsAndMaybeNameOrDedent(
			emptyArrWithSize!ExprAst,
			immutable OptNameOrDedent(immutable OptNameOrDedent.Comma()));
	else if (peekTokenExpression(lexer)) {
		ArrWithSizeBuilder!ExprAst builder;
		return parseArgsRecur(lexer, ctx, builder);
	} else
		return immutable ArgsAndMaybeNameOrDedent(emptyArrWithSize!ExprAst, noNameOrDedent());
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsRecur(
	ref Lexer lexer,
	immutable ArgCtx ctx,
	ref ArrWithSizeBuilder!ExprAst args,
) {
	verify(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	add(lexer.alloc, args, ad.expr);
	immutable(ArgsAndMaybeNameOrDedent) finish() {
		return immutable ArgsAndMaybeNameOrDedent(finishArrWithSize(lexer.alloc, args), ad.nameOrDedent);
	}
	return matchOptNameOrDedent!(immutable ArgsAndMaybeNameOrDedent)(
		ad.nameOrDedent,
		(ref immutable OptNameOrDedent.None) =>
			finish(),
		(ref immutable OptNameOrDedent.Comma) =>
			parseArgsRecur(lexer, ctx, args),
		(ref immutable NameAndRange) =>
			finish(),
		(ref immutable OptNameOrDedent.Dedent) =>
			finish());
}

immutable(ExprAndDedent) parseMutEquals(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst before,
	immutable uint curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
	struct FromBefore {
		immutable Sym name;
		immutable ArrWithSize!ExprAst args;
		immutable ArrWithSize!TypeAst typeArgs;
		immutable CallAst.Style style;
	}
	immutable FromBefore fromBefore = () {
		if (isIdentifier(before.kind))
			return immutable FromBefore(
				asIdentifier(before.kind).name,
				emptyArrWithSize!ExprAst,
				emptyArrWithSize!TypeAst,
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
						if (symEq(beforeCall.funName.name, symForOperator(Operator.times)))
							return CallAst.Style.setDeref;
						else
							// This is `~x := foo` or `-x := foo`. Have a diagnostic for this.
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
			return immutable FromBefore(
				shortSym("bogus"),
				emptyArrWithSize!ExprAst,
				emptyArrWithSize!TypeAst,
				CallAst.Style.setSingle);
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
	} else if (peekToken(lexer, Token.name) || peekToken(lexer, Token.operator)) {
		immutable NameAndRange funName = takeNameOrOperatorAndRange(lexer);
		return parseCallsAfterName(lexer, start, lhs, funName, argCtx);
	} else
		return immutable ExprAndMaybeNameOrDedent(lhs, noNameOrDedent());
}

immutable(bool) canParseCommaExpr(ref immutable ArgCtx argCtx) {
	return commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterComma(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	ArrWithSizeBuilder!ExprAst builder;
	add(lexer.alloc, builder, lhs);
	immutable ArgsAndMaybeNameOrDedent args = peekTokenExpression(lexer)
		? parseArgsRecur(lexer, requirePrecedenceGtComma(argCtx), builder)
		: immutable ArgsAndMaybeNameOrDedent(
			finishArrWithSize(lexer.alloc, builder),
			immutable OptNameOrDedent(immutable OptNameOrDedent.None()));
	immutable RangeWithinFile range = range(lexer, start);
	return immutable ExprAndMaybeNameOrDedent(
		immutable ExprAst(range, immutable ExprAstKind(
			immutable CallAst(
				CallAst.Style.comma,
				//TODO: range is wrong..
				immutable NameAndRange(range.start, shortSym("new")),
				emptyArrWithSize!TypeAst,
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
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsForExpr(lexer);
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
			(ref immutable OptNameOrDedent.Comma) =>
				canParseCommaExpr(argCtx)
					? parseCallsAfterComma(lexer, start, expr, argCtx)
					: stopHere,
			(ref immutable NameAndRange name) =>
				parseCallsAfterName(lexer, start, expr, name, argCtx),
			(ref immutable OptNameOrDedent.Dedent) =>
				stopHere);
	} else
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(funName));
}

immutable(int) symPrecedence(immutable Sym a) {
	immutable Opt!Operator operator = operatorForSym(a);
	return has(operator) ? operatorPrecedence(force(operator)) : 0;
}

// This is for the , in `1, 2`, not the comma between args
immutable int commaPrecedence = -4;

immutable(int) operatorPrecedence(immutable Operator a) {
	final switch (a) {
		case Operator.concatEquals:
			return -3;
		case Operator.or2:
			return -2;
		case Operator.and2:
			return -1;
		case Operator.equal:
		case Operator.notEqual:
		case Operator.less:
		case Operator.lessOrEqual:
		case Operator.greater:
		case Operator.greaterOrEqual:
		case Operator.compare:
		case Operator.range:
		case Operator.tilde:
			return 1;
		case Operator.or1:
			return 2;
		case Operator.xor1:
			return 3;
		case Operator.and1:
			return 4;
		case Operator.shiftLeft:
		case Operator.shiftRight:
			return 5;
		case Operator.plus:
		case Operator.minus:
			return 6;
		case Operator.times:
		case Operator.divide:
			return 7;
		case Operator.exponent:
			return 8;
		case Operator.not:
			// prefix only
			return unreachable!int();
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterSimpleExpr(
	ref Lexer lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	immutable ExprAstKind kind = lhs.kind;
	if (((isCall(kind) && asCall(kind).style == CallAst.Style.single) || isIdentifier(kind))
		&& tryTakeToken(lexer, Token.colon)) {
		struct NameAndTypeArgs {
			immutable NameAndRange name;
			immutable ArrWithSize!TypeAst typeArgs;
		}
		immutable NameAndTypeArgs nameAndTypeArgs = () {
			if (isCall(kind))
				return immutable NameAndTypeArgs(asCall(kind).funName, asCall(kind).typeArgs);
			else
				return immutable NameAndTypeArgs(
					immutable NameAndRange(lhs.range.start, asIdentifier(kind).name),
					emptyArrWithSize!TypeAst);
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

immutable(ExprAst) tryParseDotsAndSubscripts(ref Lexer lexer, immutable ExprAst initial) {
	immutable Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.dot)) {
		immutable NameAndRange name = takeNameAndRange(lexer);
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsForExpr(lexer);
		immutable CallAst call = immutable CallAst(
			CallAst.Style.dot, name, typeArgs, arrWithSizeLiteral!ExprAst(lexer.alloc, [initial]));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.arrowAccess)) {
		immutable NameAndRange name = takeNameAndRange(lexer);
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsForExpr(lexer);
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable ArrowAccessAst(initial, name, typeArgs)))));
	} else if (tryTakeToken(lexer, Token.bracketLeft)) {
		immutable ArrWithSize!ExprAst args = parseSubscriptArgs(lexer);
		immutable CallAst call = immutable CallAst(
			//TODO: the range is wrong..
			CallAst.Style.subscript,
			immutable NameAndRange(start, shortSym("subscript")),
			emptyArrWithSize!TypeAst,
			prepend(lexer.alloc, initial, args));
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.colon2)) {
		immutable TypeAst type = parseTypeRequireBracket(lexer);
		return tryParseDotsAndSubscripts(lexer, immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(allocate(lexer.alloc, immutable TypedAst(initial, type)))));
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

immutable(ExprAndDedent) parseIf(
	ref Lexer lexer,
	immutable Pos start,
	immutable uint curIndent,
) {
	return parseIfRecur(lexer, start, curIndent);
}

immutable(OptExprAndDedent) toOptExprAndDedent(immutable ExprAndDedent a) {
	return immutable OptExprAndDedent(some(a.expr), a.dedents);
}

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
		: assertNoNameOrDedent(parseCallsAfterSimpleExpr(
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

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(
	ref Lexer lexer,
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

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParameters(ref Lexer lexer) {
	if (tryTakeToken(lexer, Token.parenRight))
		return emptyArr!(LambdaAst.Param);
	else {
		ArrBuilder!(LambdaAst.Param) parameters;
		return parseParenthesizedLambdaParametersRecur(lexer, parameters);
	}
}

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParametersRecur(
	ref Lexer lexer,
	ref ArrBuilder!(LambdaAst.Param) parameters,
) {
	immutable Pos start = curPos(lexer);
	immutable Sym name = takeName(lexer);
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
				: exprBlockNotAllowed(lexer, start, ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.lambda);
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
	immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind kind,
) {
	return skipRestOfLineAndReturnBogus(
		lexer,
		start,
		immutable ParseDiag(immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx(kind)));
}

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
						immutable NameAndRange(start, shortSym("new")),
						emptyArrWithSize!TypeAst,
						emptyArrWithSize!ExprAst)));
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
			immutable StringPart part = takeStringPart(lexer);
			final switch (part.after) {
				case StringPart.After.quote:
					return handleLiteral(lexer, start, immutable LiteralAst(part.text));
				case StringPart.After.lbrace:
					immutable ExprAst interpolated = takeInterpolated(lexer, start, part.text);
					return noDedent(tryParseDotsAndSubscripts(lexer, interpolated));
			}
		case Token.if_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseIf(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.if_);
		case Token.match:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseMatch(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match);
		case Token.name:
			immutable Sym name = getCurSym(lexer);
			if (tryTakeToken(lexer, Token.arrowLambda))
				return parseLambdaAfterArrow(
					lexer,
					start,
					allowedBlock,
					arrLiteral!(LambdaAst.Param)(lexer.alloc, [immutable LambdaAst.Param(start, name)]));
			else
				return handleName(lexer, start, immutable NameAndRange(start, name));
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
		default:
			addDiagUnexpectedCurToken(lexer, start, token);
			return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
	}
}

immutable(ExprAndMaybeDedent) handlePrefixOperator(
	ref Lexer lexer,
	immutable AllowedBlock allowedBlock,
	immutable Pos start,
	immutable Operator operator,
) {
	immutable ExprAndMaybeDedent arg = parseExprBeforeCall(lexer, allowedBlock);
	immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(
		immutable CallAst(
			CallAst.Style.prefixOperator,
			immutable NameAndRange(start, symForOperator(operator)),
			emptyArrWithSize!TypeAst,
			arrWithSizeLiteral!ExprAst(lexer.alloc, [arg.expr]))));
	return immutable ExprAndMaybeDedent(expr, arg.dedents);
}

immutable(ExprAndMaybeDedent) handleLiteral(ref Lexer lexer, immutable Pos start, immutable LiteralAst literal) {
	immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(literal));
	return noDedent(tryParseDotsAndSubscripts(lexer, expr));
}

immutable(ExprAndMaybeDedent) handleName(ref Lexer lexer, immutable Pos start, immutable NameAndRange name) {
	immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsForExpr(lexer);
	if (!empty(toArr(typeArgs))) {
		return noDedent(immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(
				immutable CallAst(CallAst.Style.single, name, typeArgs, emptyArrWithSize!ExprAst))));
	} else {
		immutable ExprAst expr = immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable IdentifierAst(name.name)));
		return noDedent(tryParseDotsAndSubscripts(lexer, expr));
	}
}

immutable(ExprAst) takeInterpolated(ref Lexer lexer, immutable Pos start, immutable string firstText) {
	ArrBuilder!InterpolatedPart parts;
	if (!empty(firstText))
		add(lexer.alloc, parts, immutable InterpolatedPart(firstText));
	return takeInterpolatedRecur(lexer, start, parts);
}

immutable(ExprAst) takeInterpolatedRecur(ref Lexer lexer, immutable Pos start, ref ArrBuilder!InterpolatedPart parts) {
	immutable ExprAst e = parseExprNoBlock(lexer);
	add(lexer.alloc, parts, immutable InterpolatedPart(e));
	takeOrAddDiagExpectedToken(lexer, Token.braceRight, ParseDiag.Expected.Kind.closeInterpolated);
	immutable StringPart part = takeStringPart(lexer);
	if (!empty(part.text))
		add(lexer.alloc, parts, immutable InterpolatedPart(part.text));
	final switch (part.after) {
		case StringPart.After.quote:
			return immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable InterpolatedAst(finishArr(lexer.alloc, parts))));
		case StringPart.After.lbrace:
			return takeInterpolatedRecur(lexer, start, parts);
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
		(ref immutable OptNameOrDedent.Comma) =>
			unreachable!(immutable Opt!uint),
		(ref immutable NameAndRange) =>
			// We allowed all calls, so should be no dangling names
			unreachable!(immutable Opt!uint),
		(ref immutable OptNameOrDedent.Dedent it) =>
			some(it.dedents));
}

immutable(ExprAst) parseExprNoBlock(ref Lexer lexer) {
	immutable ExprAndMaybeDedent ed = parseExprAndAllCalls(lexer, noBlock());
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprAndAllCalls(ref Lexer lexer, immutable AllowedBlock allowedBlock) {
	immutable ArgCtx argCtx = immutable ArgCtx(allowedBlock, allowAllCalls());
	return assertNoNameAfter(parseExprAndCalls(lexer, argCtx));
}

immutable(ExprAndMaybeNameOrDedent) parseExprAndCalls(ref Lexer lexer, ref immutable ArgCtx argCtx) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(lexer, argCtx.allowedBlock);
	return has(ed.dedents)
		? immutable ExprAndMaybeNameOrDedent(ed.expr, nameOrDedentFromOptDedents(ed.dedents))
		: parseCallsAfterSimpleExpr(lexer, start, ed.expr, argCtx);
}

immutable(ExprAndDedent) parseExprNoLet(ref Lexer lexer, immutable uint curIndent) {
	return addDedent(lexer, parseExprAndAllCalls(lexer, allowBlock(curIndent)), curIndent);
}

immutable(ExprAndDedent) parseSingleStatementLine(ref Lexer lexer, immutable uint curIndent) {
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
					immutable ArgCtx(allowBlock(curIndent), allowAllCalls())));
			return addDedent(lexer, fullExpr, curIndent);
		}
	}
}

immutable(ExprAndDedent) parseEqualsOrThen(ref Lexer lexer, immutable uint curIndent) {
	immutable Pos start = curPos(lexer);
	immutable NameAndRange name = takeNameAndRange(lexer);
	immutable TypeAndEqualsOrThen te = parseTypeAndEqualsOrThen(lexer);
	immutable ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
	immutable ExprAndDedent thenAndDedent =
		mustParseNextLines(lexer, start, initAndDedent.dedents, curIndent);
	immutable ExprAstKind exprKind =
		letOrThen(lexer.alloc, name, te.type, te.equalsOrThen, initAndDedent.expr, thenAndDedent.expr);
	return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
}

immutable(ExprAstKind) letOrThen(
	ref Alloc alloc,
	immutable NameAndRange name,
	immutable OptPtr!TypeAst type,
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
	immutable OptPtr!TypeAst type;
	immutable EqualsOrThen equalsOrThen;
}
immutable(TypeAndEqualsOrThen) parseTypeAndEqualsOrThen(ref Lexer lexer) {
	immutable Opt!EqualsOrThen res = tryTakeEqualsOrThen(lexer);
	if (has(res))
		return immutable TypeAndEqualsOrThen(nonePtr!TypeAst, force(res));
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
		return immutable TypeAndEqualsOrThen(somePtr(allocate(lexer.alloc, type)), equalsOrThen);
	}
}

immutable(Opt!EqualsOrThen) tryTakeEqualsOrThen(ref Lexer lexer) {
	return tryTakeToken(lexer, Token.equal)
		? some(EqualsOrThen.equals)
		: tryTakeToken(lexer, Token.arrowThen)
		? some(EqualsOrThen.then)
		: none!EqualsOrThen;
}

immutable(ExprAndDedent) addDedent(ref Lexer lexer, immutable ExprAndMaybeDedent e, immutable uint curIndent) {
	return immutable ExprAndDedent(
		e.expr,
		has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(lexer, curIndent));
}


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
