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
	ParenthesizedAst,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst;
import frontend.parse.lexer :
	addDiag,
	addDiagAtChar,
	addDiagOnReservedName,
	addDiagUnexpected,
	backUp,
	curPos,
	isOperatorChar,
	isReservedName,
	Lexer,
	lookaheadWillTakeArrow,
	next,
	range,
	Sign,
	skipUntilNewlineNoDiag,
	StringPart,
	takeIndentOrDiagTopLevel,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameRest,
	takeNewlineOrDedentAmount,
	takeNumber,
	takeOperator,
	takeOrAddDiagExpected,
	takeStringPart,
	tryTake;
import frontend.parse.parseType : tryParseTypeArgsBracketed;
import model.parseDiag : EqLikeKind, ParseDiag;
import util.collection.arr : ArrWithSize, empty, emptyArr, emptyArrWithSize, toArr;
import util.collection.arrUtil : append, arrLiteral, arrWithSizeLiteral, prepend;
import util.collection.arrBuilder : add, ArrBuilder, ArrWithSizeBuilder, finishArr;
import util.collection.str : CStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : Ptr;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym :
	getSymFromAlphaIdentifier,
	isAlphaIdentifierStart,
	isDigit,
	isSymOperator,
	Operator,
	operatorForSym,
	prependSet,
	shortSymAlphaLiteral,
	shortSymAlphaLiteralValue,
	Sym;
import util.util : max, todo, unreachable, verify;

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

	struct Dedent { immutable uint dedents; }
	struct None {}

	immutable this(immutable NameAndRange a) { kind = Kind.name; name = a; }
	immutable this(immutable Dedent a) { kind = Kind.dedent; dedent = a; }
	immutable this(immutable None a) { kind = Kind.none; none = a; }

	private:
	enum Kind {
		name,
		dedent,
		none,
	}
	immutable Kind kind;
	union {
		immutable NameAndRange name;
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

immutable(bool) isName(ref immutable OptNameOrDedent a) {
	return a.kind == OptNameOrDedent.Kind.name;
}

ref immutable(NameAndRange) asName(return scope ref immutable OptNameOrDedent a) {
	verify(isName(a));
	return a.name;
}

T matchOptNameOrDedent(T)(
	ref immutable OptNameOrDedent a,
	scope T delegate(ref immutable OptNameOrDedent.None) @safe @nogc pure nothrow cbNone,
	scope T delegate(ref immutable NameAndRange) @safe @nogc pure nothrow cbName,
	scope T delegate(ref immutable OptNameOrDedent.Dedent) @safe @nogc pure nothrow cbDedent,
) {
	final switch (a.kind) {
		case OptNameOrDedent.Kind.none:
			return cbNone(a.none);
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
static assert(ExprAndMaybeNameOrDedent.sizeof <= 80);

immutable(ExprAst) assertNoNameOrDedent(immutable ExprAndMaybeNameOrDedent a) {
	verify(isNone(a.nameOrDedent));
	return a.expr;
}

struct OptExprAndDedent {
	immutable Opt!(Ptr!ExprAst) expr;
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

immutable(ArrWithSize!ExprAst) parseSubscriptArgs(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	if (tryTake(lexer, ']'))
		return emptyArrWithSize!ExprAst;
	else {
		ArrWithSizeBuilder!ExprAst builder;
		immutable ArgCtx argCtx = immutable ArgCtx(noBlock(), allowAllCalls());
		immutable ArgsAndMaybeNameOrDedent res = parseArgsRecur(alloc, lexer, argCtx, builder);
		verify(isNone(res.nameOrDedent));
		if (!tryTake(lexer, ']'))
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingBracket)));
		return res.args;
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsForOperator(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref immutable ArgCtx ctx,
) {
	if (!tryTake(lexer, ' '))
		return immutable ArgsAndMaybeNameOrDedent(emptyArrWithSize!ExprAst, noNameOrDedent());
	else {
		immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(alloc, lexer, ctx);
		return immutable ArgsAndMaybeNameOrDedent(arrWithSizeLiteral!ExprAst(alloc, [ad.expr]), ad.nameOrDedent);
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgs(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref immutable ArgCtx ctx,
) {
	if (!tryTake(lexer, ' '))
		return immutable ArgsAndMaybeNameOrDedent(emptyArrWithSize!ExprAst, noNameOrDedent());
	else {
		ArrWithSizeBuilder!ExprAst builder;
		return parseArgsRecur(alloc, lexer, ctx, builder);
	}
}

immutable(ArgsAndMaybeNameOrDedent) parseArgsRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ArgCtx ctx,
	ref ArrWithSizeBuilder!ExprAst args,
) {
	immutable ExprAndMaybeNameOrDedent ad = parseExprAndCalls(alloc, lexer, ctx);
	add(alloc, args, ad.expr);
	return isNone(ad.nameOrDedent) && tryTake(lexer, ", ")
		? parseArgsRecur(alloc, lexer, ctx, args)
		: immutable ArgsAndMaybeNameOrDedent(finishArr(alloc, args), ad.nameOrDedent);
}

immutable(ExprAndDedent) parseLetOrThen(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref immutable ExprAst before,
	immutable EqLikeKind kind,
	immutable uint curIndent,
) {
	immutable ExprAndDedent initAndDedent = parseExprNoLet(alloc, lexer, curIndent);
	immutable ExprAst init = initAndDedent.expr;
	if (kind == EqLikeKind.mutEquals) {
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
			} else {
				addDiag(alloc, lexer, range(lexer, start), immutable ParseDiag(
					immutable ParseDiag.CantPrecedeEqLike(kind)));
				return immutable FromBefore(
					shortSymAlphaLiteral("bogus"),
					emptyArrWithSize!ExprAst,
					emptyArrWithSize!TypeAst,
					CallAst.Style.setSingle);
			}
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
		immutable ExprAndDedent thenAndDedent = mustParseNextLines(
			alloc,
			lexer,
			start,
			initAndDedent.dedents,
			curIndent);
		immutable ExprAstKind exprKind = letOrThen(
			alloc,
			kind,
			asIdentifierOrDiagnostic(alloc, lexer, before, kind),
			init,
			thenAndDedent.expr);
		return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
	}
}

immutable(ExprAndDedent) mustParseNextLines(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable uint dedentsBefore,
	immutable uint curIndent,
) {
	if (dedentsBefore != 0) {
		immutable RangeWithinFile range = range(lexer, start);
		addDiag(alloc, lexer, range, immutable ParseDiag(immutable ParseDiag.LetMustHaveThen()));
		return immutable ExprAndDedent(bogusExpr(range), dedentsBefore);
	} else
		return parseStatementsAndDedents(alloc, lexer, curIndent);
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
		case EqLikeKind.optEquals:
			return unreachable!(immutable ExprAstKind)();
		case EqLikeKind.then:
			return immutable ExprAstKind(immutable ThenAst(nameAndRange, allocate(alloc, init), allocate(alloc, then)));
	}
}

immutable(NameAndRange) asIdentifierOrDiagnostic(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref immutable ExprAst a,
	immutable EqLikeKind kind,
) {
	if (isIdentifier(a.kind))
		return identifierAsNameAndRange(a);
	else {
		addDiag(alloc, lexer, a.range, immutable ParseDiag(immutable ParseDiag.CantPrecedeEqLike(kind)));
		return immutable NameAndRange(a.range.start, shortSymAlphaLiteral("a"));
	}
}

immutable(NameAndRange) identifierAsNameAndRange(ref immutable ExprAst a) {
	return immutable NameAndRange(a.range.start, asIdentifier(a.kind).name);
}

immutable(ExprAndMaybeNameOrDedent) parseCalls(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	if (!tryTake(lexer, ' '))
		return immutable ExprAndMaybeNameOrDedent(lhs, noNameOrDedent());
	else {
		immutable NameAndRange funName = takeNameAndRange(alloc, lexer);
		return parseCallsAfterName(alloc, lexer, start, lhs, funName, argCtx);
	}
}

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterName(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable NameAndRange funName,
	immutable ArgCtx argCtx,
) {
	immutable int precedence = symPrecedence(funName.name);
	if (precedence > argCtx.allowedCalls.minPrecedenceExclusive) {
		//TODO: don't do this for operators
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
		immutable bool tookColon = tryTake(lexer, ':');
		immutable ArgCtx innerCtx = tookColon
			? immutable ArgCtx(argCtx.allowedBlock, allowAllCalls())
			: requirePrecedenceGt(argCtx, precedence);
		immutable ArgsAndMaybeNameOrDedent args = isSymOperator(funName.name)
			? parseArgsForOperator(alloc, lexer, innerCtx)
			: parseArgs(alloc, lexer, innerCtx);
		immutable ExprAstKind exprKind = immutable ExprAstKind(
			immutable CallAst(CallAst.Style.infix, funName, typeArgs, prepend!(ExprAst, Alloc)(alloc, lhs, args.args)));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), exprKind);
		return isName(args.nameOrDedent)
			? parseCallsAfterName(alloc, lexer, start, expr, asName(args.nameOrDedent), argCtx)
			: immutable ExprAndMaybeNameOrDedent(expr, args.nameOrDedent);
	} else
		return immutable ExprAndMaybeNameOrDedent(lhs, immutable OptNameOrDedent(funName));
}

immutable(int) symPrecedence(immutable Sym a) {
	immutable Opt!Operator operator = operatorForSym(a);
	return has(operator) ? operatorPrecedence(force(operator)) : 0;
}

immutable(int) operatorPrecedence(immutable Operator a) {
	final switch (a) {
		case Operator.concatEquals:
			return -1;
		case Operator.equal:
		case Operator.notEqual:
		case Operator.less:
		case Operator.lessOrEqual:
		case Operator.greater:
		case Operator.greaterOrEqual:
		case Operator.compare:
		case Operator.arrow:
		case Operator.concat:
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

immutable(ExprAndMaybeNameOrDedent) parseCallsAfterSimpleExpr(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref immutable ExprAst lhs,
	immutable ArgCtx argCtx,
) {
	immutable ExprAstKind kind = lhs.kind;
	if (((isCall(kind) && asCall(kind).style == CallAst.Style.single) || isIdentifier(kind))
		&& tryTake(lexer, ':')) {
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
		immutable ArgsAndMaybeNameOrDedent ad = parseArgs(alloc, lexer, argCtx);
		immutable CallAst call = immutable CallAst(
			CallAst.Style.prefix,
			nameAndTypeArgs.name,
			nameAndTypeArgs.typeArgs,
			ad.args);
		return immutable ExprAndMaybeNameOrDedent(
			immutable ExprAst(range(lexer, start), immutable ExprAstKind(call)),
			ad.nameOrDedent);
	} else
		return parseCalls(alloc, lexer, start, lhs, argCtx);
}

immutable(OptNameOrDedent) nameOrDedentFromOptDedents(immutable Opt!uint dedents) {
	return has(dedents)
		? immutable OptNameOrDedent(immutable OptNameOrDedent.Dedent(force(dedents)))
		: noNameOrDedent();
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
			CallAst.Style.dot, name, typeArgs, arrWithSizeLiteral!ExprAst(alloc, [initial]));
		immutable ExprAst expr = immutable ExprAst(range(lexer, start), immutable ExprAstKind(call));
		return tryParseDotsAndSubscripts(alloc, lexer, expr);
	} else if (tryTake(lexer, '[')) {
		immutable ArrWithSize!ExprAst args = parseSubscriptArgs(alloc, lexer);
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
	immutable uint curIndent,
) {
	immutable Ptr!ExprAst matched = tryTake(lexer, ' ')
		? allocate(alloc, parseExprNoBlock(alloc, lexer))
		: allocate(alloc, immutable ExprAst(range(lexer, start), immutable ExprAstKind(immutable BogusAst())));
	immutable uint dedentsAfterMatched = takeNewlineOrDedentAmount(alloc, lexer, curIndent);
	ArrBuilder!(MatchAst.CaseAst) cases;
	immutable uint dedents = dedentsAfterMatched != 0
		? dedentsAfterMatched
		: parseMatchCases(alloc, lexer, cases, curIndent);
	return immutable ExprAndDedent(
		immutable ExprAst(
			range(lexer, start),
			immutable ExprAstKind(immutable MatchAst(matched, finishArr(alloc, cases)))),
		dedents);
}

immutable(uint) parseMatchCases(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!(MatchAst.CaseAst) cases,
	immutable uint curIndent,
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
	immutable uint curIndent,
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
	immutable uint curIndent,
) {
	immutable ExprAndMaybeDedent beforeCallAndDedent = parseExprBeforeCall(alloc, lexer, noBlock());
	assert(!has(beforeCallAndDedent.dedents));
	immutable ExprAst beforeCall = beforeCallAndDedent.expr;
	immutable bool isOption = tryTake(lexer, " ?= ");
	immutable ExprAst optionOrCondition = isOption
		? parseExprNoBlock(alloc, lexer)
		: assertNoNameOrDedent(
			parseCallsAfterSimpleExpr(alloc, lexer, start, beforeCall, immutable ArgCtx(noBlock(), allowAllCalls())));
	immutable ExprAndDedent thenAndDedent = takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
		parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1));
	immutable ExprAst then = thenAndDedent.expr;
	immutable Pos elifStart = curPos(lexer);
	immutable OptExprAndDedent else_ = thenAndDedent.dedents != 0
		? immutable OptExprAndDedent(none!(Ptr!ExprAst), thenAndDedent.dedents)
		: tryTake(lexer, "elif ")
		? toOptExprAndDedent(alloc, parseIfRecur(alloc, lexer, elifStart, curIndent))
		: tryTake(lexer, "else")
		? toOptExprAndDedent(alloc, takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
			parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1)))
		: immutable OptExprAndDedent(none!(Ptr!ExprAst), 0);

	immutable ExprAstKind kind = isOption
		? immutable ExprAstKind(allocate(alloc, immutable IfOptionAst(
			asIdentifierOrDiagnostic(alloc, lexer, beforeCall, EqLikeKind.optEquals),
			optionOrCondition,
			then,
			has(else_.expr) ? some(force(else_.expr).deref()) : none!ExprAst)))
		: immutable ExprAstKind(immutable IfAst(
			allocate(alloc, optionOrCondition),
			allocate(alloc, then),
			else_.expr));
	return immutable ExprAndDedent(immutable ExprAst(range(lexer, start), kind), else_.dedents);
}

immutable(ExprAndDedent) takeIndentOrFail_ExprAndDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
	scope immutable(ExprAndDedent) delegate() @safe @nogc pure nothrow cbIndent,
) {
	return takeIndentOrFailGeneric!ExprAndDedent(
		alloc,
		lexer,
		curIndent,
		cbIndent,
		(immutable RangeWithinFile range, immutable uint nDedents) =>
			immutable ExprAndDedent(bogusExpr(range), nDedents));
}

immutable(ExprAndMaybeDedent) parseLambdaWithParenthesizedParameters(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
) {
	immutable LambdaAst.Param[] parameters = parseParenthesizedLambdaParameters(alloc, lexer);
	if (!tryTake(lexer, " =>"))
		addDiagAtChar(alloc, lexer, immutable ParseDiag(
			immutable ParseDiag.Expected(ParseDiag.Expected.Kind.lambdaArrow)));
	return parseLambdaAfterArrow(alloc, lexer, start, allowedBlock, parameters);
}

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParameters(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
) {
	if (tryTake(lexer, ')'))
		return emptyArr!(LambdaAst.Param);
	else {
		ArrBuilder!(LambdaAst.Param) parameters;
		return parseParenthesizedLambdaParametersRecur(alloc, lexer, parameters);
	}
}

immutable(LambdaAst.Param[]) parseParenthesizedLambdaParametersRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref ArrBuilder!(LambdaAst.Param) parameters,
) {
	immutable Pos start = curPos(lexer);
	immutable Sym name = takeName(alloc, lexer);
	add(alloc, parameters, immutable LambdaAst.Param(start, name));
	if (tryTake(lexer, ", "))
		return parseParenthesizedLambdaParametersRecur(alloc, lexer, parameters);
	else {
		if (!tryTake(lexer, ')'))
			addDiagAtChar(alloc, lexer, immutable ParseDiag(
				immutable ParseDiag.Expected(ParseDiag.Expected.Kind.closingParen)));
		return finishArr(alloc, parameters);
	}
}

immutable(ExprAndMaybeDedent) parseLambdaAfterArrow(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable AllowedBlock allowedBlock,
	immutable LambdaAst.Param[] parameters,
) {
	immutable bool inLine = tryTake(lexer, ' ');
	immutable ExprAndMaybeDedent body_ = () {
		if (isAllowBlock(allowedBlock)) {
			immutable uint curIndent = asAllowBlock(allowedBlock).curIndent;
			return inLine
				? toMaybeDedent(parseExprNoLet(alloc, lexer, curIndent))
				: toMaybeDedent(takeIndentOrFail_ExprAndDedent(alloc, lexer, curIndent, () =>
					parseStatementsAndExtraDedents(alloc, lexer, curIndent + 1)));
		} else
			return inLine
				? noDedent(parseExprNoBlock(alloc, lexer))
				: exprBlockNotAllowed(alloc, lexer, start, ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.lambda);
	}();
	immutable LambdaAst lambda = immutable LambdaAst(parameters, allocExpr(alloc, body_.expr));
	return immutable ExprAndMaybeDedent(
		immutable ExprAst(range(lexer, start), immutable ExprAstKind(lambda)),
		body_.dedents);
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

immutable(ExprAndMaybeDedent) exprBlockNotAllowed(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind kind,
) {
	return skipRestOfLineAndReturnBogus(
		alloc,
		lexer,
		start,
		immutable ParseDiag(immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx(kind)));
}

immutable(ExprAndMaybeDedent) parseExprBeforeCall(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable AllowedBlock allowedBlock,
) {
	immutable Pos start = curPos(lexer);
	immutable(RangeWithinFile) getRange() {
		return range(lexer, start);
	}

	immutable(ExprAndMaybeDedent) blockNotAllowed(immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind kind) {
		return exprBlockNotAllowed(alloc, lexer, start, kind);
	}

	immutable(ExprAndMaybeDedent) handleLiteral(immutable LiteralAst literal) {
		immutable ExprAst expr = immutable ExprAst(getRange(), immutable ExprAstKind(literal));
		return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
	}

	immutable(ExprAndMaybeDedent) handleName(immutable NameAndRange name) {
		immutable ArrWithSize!TypeAst typeArgs = tryParseTypeArgsBracketed(alloc, lexer);
		if (!empty(toArr(typeArgs))) {
			return noDedent(immutable ExprAst(
				getRange(),
				immutable ExprAstKind(
					immutable CallAst(CallAst.Style.single, name, typeArgs, emptyArrWithSize!ExprAst))));
		} else {
			immutable ExprAst expr = immutable ExprAst(
				getRange(),
				immutable ExprAstKind(immutable IdentifierAst(name.name)));
			return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
		}
	}

	immutable CStr begin = lexer.ptr;
	immutable char c = next(lexer);
	switch (c) {
		case '(':
			if (lookaheadWillTakeArrow(lexer)) {
				return parseLambdaWithParenthesizedParameters(alloc, lexer, start, allowedBlock);
			} else {
				immutable ExprAst inner = parseExprNoBlock(alloc, lexer);
				takeOrAddDiagExpected(alloc, lexer, ')', ParseDiag.Expected.Kind.closingParen);
				immutable ExprAst expr = immutable ExprAst(
					getRange(),
					immutable ExprAstKind(immutable ParenthesizedAst(allocate(alloc, inner))));
				return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
			}
		case '[':
			immutable ArrWithSize!ExprAst args = parseSubscriptArgs(alloc, lexer);
			immutable ExprAst expr = immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable CreateArrAst(args)));
			return noDedent(tryParseDotsAndSubscripts(alloc, lexer, expr));
		case '&':
			immutable Sym name = takeName(alloc, lexer);
			return noDedent(immutable ExprAst(
				getRange(),
				immutable ExprAstKind(immutable FunPtrAst(name))));
		case '"': {
			immutable StringPart part = takeStringPart(alloc, lexer);
			final switch (part.after) {
				case StringPart.After.quote:
					return handleLiteral(immutable LiteralAst(part.text));
				case StringPart.After.lbrace:
					immutable ExprAst interpolated = takeInterpolated(alloc, lexer, start, part.text);
					return noDedent(tryParseDotsAndSubscripts(alloc, lexer, interpolated));
			}
		}
		case '+':
		case '-':
			return isDigit(*lexer.ptr)
				? handleLiteral(takeNumber(alloc, lexer, some(c == '+' ? Sign.plus : Sign.minus)))
				: handleName(takeOperator(alloc, lexer, begin));
		default:
			if (isOperatorChar(c))
				return handleName(takeOperator(alloc, lexer, begin));
			else if (isAlphaIdentifierStart(c)) {
				immutable string nameStr = takeNameRest(lexer, begin);
				immutable Sym name = getSymFromAlphaIdentifier(lexer.allSymbols, nameStr);
				if (isReservedName(name))
					switch (name.value) {
						case shortSymAlphaLiteralValue("if"):
							return isAllowBlock(allowedBlock)
								? toMaybeDedent(parseIf(alloc, lexer, start, asAllowBlock(allowedBlock).curIndent))
								: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.if_);
						case shortSymAlphaLiteralValue("match"):
							return isAllowBlock(allowedBlock)
								? toMaybeDedent(parseMatch(alloc, lexer, start, asAllowBlock(allowedBlock).curIndent))
								: blockNotAllowed(ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match);
						default:
							addDiagOnReservedName(alloc, lexer, immutable NameAndRange(start, name));
							return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
					}
				else if (tryTake(lexer, " =>"))
					return parseLambdaAfterArrow(
						alloc,
						lexer,
						start,
						allowedBlock,
						arrLiteral!(LambdaAst.Param)(alloc, [immutable LambdaAst.Param(start, name)]));
				else
					return handleName(immutable NameAndRange(start, name));
			} else if (isDigit(c)) {
				backUp(lexer);
				return handleLiteral(takeNumber(alloc, lexer, none!Sign));
			} else {
				backUp(lexer);
				addDiagUnexpected(alloc, lexer);
				return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
			}
	}
}

immutable(ExprAst) takeInterpolated(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	immutable string firstText,
) {
	ArrBuilder!InterpolatedPart parts;
	if (!empty(firstText))
		add(alloc, parts, immutable InterpolatedPart(firstText));
	return takeInterpolatedRecur(alloc, lexer, start, parts);
}

immutable(ExprAst) takeInterpolatedRecur(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable Pos start,
	ref ArrBuilder!InterpolatedPart parts,
) {
	immutable ExprAst e = parseExprNoBlock(alloc, lexer);
	add(alloc, parts, immutable InterpolatedPart(e));
	if (!tryTake(lexer, '}'))
		todo!void("!");
	immutable StringPart part = takeStringPart(alloc, lexer);
	if (!empty(part.text))
		add(alloc, parts, immutable InterpolatedPart(part.text));
	final switch (part.after) {
		case StringPart.After.quote:
			return immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable InterpolatedAst(finishArr(alloc, parts))));
		case StringPart.After.lbrace:
			return takeInterpolatedRecur(alloc, lexer, start, parts);
	}
}

immutable(ExprAndMaybeDedent) assertNoNameAfter(immutable ExprAndMaybeNameOrDedent a) {
	immutable Opt!uint dedent = matchOptNameOrDedent!(immutable Opt!uint)(
		a.nameOrDedent,
		(ref immutable OptNameOrDedent.None) =>
			none!uint,
		(ref immutable NameAndRange) =>
			// We allowed all calls, so should be no dangling names
			unreachable!(immutable Opt!uint),
		(ref immutable OptNameOrDedent.Dedent it) =>
			some(it.dedents));
	return immutable ExprAndMaybeDedent(a.expr, dedent);
}

immutable(ExprAst) parseExprNoBlock(Alloc, SymAlloc)(ref Alloc alloc, ref Lexer!SymAlloc lexer) {
	immutable ExprAndMaybeDedent ed = parseExprAndAllCalls(alloc, lexer, noBlock());
	verify(!has(ed.dedents));
	return ed.expr;
}

immutable(ExprAndMaybeDedent) parseExprAndAllCalls(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable AllowedBlock allowedBlock,
) {
	immutable ArgCtx argCtx = immutable ArgCtx(allowedBlock, allowAllCalls());
	return assertNoNameAfter(parseExprAndCalls(alloc, lexer, argCtx));
}

immutable(ExprAndMaybeNameOrDedent) parseExprAndCalls(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	ref immutable ArgCtx argCtx,
) {
	immutable Pos start = curPos(lexer);
	immutable ExprAndMaybeDedent ed = parseExprBeforeCall(alloc, lexer, argCtx.allowedBlock);
	return has(ed.dedents)
		? immutable ExprAndMaybeNameOrDedent(ed.expr, nameOrDedentFromOptDedents(ed.dedents))
		: parseCallsAfterSimpleExpr(alloc, lexer, start, ed.expr, argCtx);
}

immutable(ExprAndDedent) parseExprNoLet(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	return addDedent(alloc, lexer, parseExprAndAllCalls(alloc, lexer, allowBlock(curIndent)), curIndent);
}

immutable(ExprAndDedent) parseSingleStatementLine(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	immutable Pos start = curPos(lexer);
	if (tryTake(lexer, "<- ")) {
		immutable ExprAndDedent init = parseExprNoLet(alloc, lexer, curIndent);
		immutable ExprAndDedent then = mustParseNextLines(alloc, lexer, start, init.dedents, curIndent);
		return immutable ExprAndDedent(
			immutable ExprAst(
				range(lexer, start),
				immutable ExprAstKind(immutable ThenVoidAst(allocate(alloc, init.expr), allocate(alloc, then.expr)))),
			then.dedents);
	} else {
		immutable ExprAndMaybeDedent expr = parseExprBeforeCall(alloc, lexer, allowBlock(curIndent));
		if (!has(expr.dedents)) {
			immutable Opt!EqLikeKind kind = tryTakeEqLikeKind(lexer);
			if (has(kind))
				return parseLetOrThen!(Alloc, SymAlloc)(alloc, lexer, start, expr.expr, force(kind), curIndent);
		}
		return addDedent(
			alloc,
			lexer,
			has(expr.dedents)
				? expr
				: assertNoNameAfter(parseCallsAfterSimpleExpr(
					alloc,
					lexer,
					start,
					expr.expr,
					immutable ArgCtx(allowBlock(curIndent), allowAllCalls()))),
			curIndent);
	}
}

immutable(ExprAndDedent) addDedent(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable ExprAndMaybeDedent e,
	immutable uint curIndent,
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

immutable(ExprAndDedent) parseStatementsAndDedents(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
) {
	immutable ExprAndDedent res = parseStatementsAndExtraDedents(alloc, lexer, curIndent);
	// Since we don't always expect a dedent here,
	// the dedent isn't *extra*, so increment to get the correct number of dedents.
	return immutable ExprAndDedent(res.expr, res.dedents + 1);
}

// Return value is number of dedents - 1; the number of *extra* dedents
immutable(ExprAndDedent) parseStatementsAndExtraDedents(Alloc, SymAlloc)(
	ref Alloc alloc,
	ref Lexer!SymAlloc lexer,
	immutable uint curIndent,
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
	immutable uint curIndent,
	immutable uint dedents,
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
