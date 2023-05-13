module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	DestructureAst,
	EmptyAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
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
	ParenthesizedAst,
	PtrAst,
	SeqAst,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	WithAst;
import frontend.parse.lexer :
	addDiag,
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
	getPeekToken,
	Lexer,
	lookaheadWillTakeArrowAfterParenLeft,
	lookaheadWillTakeEqualsOrThen,
	lookaheadWillTakeQuestionEquals,
	NewlineOrIndent,
	nextToken,
	peekToken,
	peekTokenExpression,
	QuoteKind,
	range,
	rangeAtChar,
	skipUntilNewlineNoDiag,
	StringPart,
	takeIndentOrFailGeneric,
	takeName,
	takeNameAndRange,
	takeNameAndRangeAllowUnderscore,
	takeNewlineOrIndent_topLevel,
	takeNewlineOrDedentAmount,
	takeOrAddDiagExpectedToken,
	takeStringPart,
	Token,
	tryTakeNameOrOperatorAndRangeNoAssignment,
	tryTakeToken;
import frontend.parse.parseType : parseType, parseTypeForTypedExpr, tryParseTypeArgForExpr;
import model.model : AssertOrForbidKind;
import model.parseDiag : ParseDiag;
import util.col.arr : empty, only;
import util.col.arrUtil : arrLiteral, prepend;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some, some;
import util.sourceRange : Pos, RangeWithinFile;
import util.sym : AllSymbols, appendEquals, Sym, sym;
import util.union_ : Union;
import util.util : max, todo, unreachable, verify;

Opt!ExprAst parseFunExprBody(ref Lexer lexer) {
	final switch (takeNewlineOrIndent_topLevel(lexer)) {
		case NewlineOrIndent.newline:
			return none!ExprAst;
		case NewlineOrIndent.indent:
			ExprAndDedent ed = parseStatementsAndExtraDedents(lexer, 1);
			verify(ed.dedents == 0); // Since we started at the root, can't dedent more
			return some(ed.expr);
	}
}

private:

ExprAst bogusExpr(RangeWithinFile range) =>
	ExprAst(range, ExprAstKind(BogusAst()));

immutable struct AllowedBlock {
	immutable struct AllowBlock { uint curIndent; }
	private uint curIndent;
	private enum uint NO_BLOCK = uint.max;
}
bool isAllowBlock(AllowedBlock a) =>
	a.curIndent != AllowedBlock.NO_BLOCK;
AllowedBlock.AllowBlock asAllowBlock(AllowedBlock a) {
	verify(isAllowBlock(a));
	return AllowedBlock.AllowBlock(a.curIndent);
}
AllowedBlock noBlock() =>
	AllowedBlock(AllowedBlock.NO_BLOCK);
AllowedBlock allowBlock(uint curIndent) {
	verify(curIndent != AllowedBlock.NO_BLOCK);
	return AllowedBlock(curIndent);
}

immutable struct AllowedCalls {
	int minPrecedenceExclusive;
}

AllowedCalls allowAllCalls() =>
	AllowedCalls(int.min);

immutable struct ArgCtx {
	// Allow things like 'if' that continue into an indented block.
	AllowedBlock allowedBlock;
	AllowedCalls allowedCalls;
}

ArgCtx requirePrecedenceGt(ArgCtx a, int precedence) =>
	ArgCtx(
		a.allowedBlock,
		AllowedCalls(max(a.allowedCalls.minPrecedenceExclusive, precedence)));

ArgCtx requirePrecedenceGtComma(ArgCtx a) =>
	requirePrecedenceGt(a, commaPrecedence);

immutable struct ExprAndDedent {
	ExprAst expr;
	uint dedents;
}

// dedent=none means we didn't see a newline.
// dedent=0 means a newline was parsed and is on the same indent level.
immutable struct ExprAndMaybeDedent {
	ExprAst expr;
	Opt!uint dedents;
}

immutable struct OptNameOrDedent {
	immutable struct None {}
	immutable struct Colon {}
	immutable struct Comma {}
	immutable struct Dedent { uint dedents; }
	immutable struct Question {}
	mixin Union!(None, Colon, Comma, NameAndRange, Dedent, Question);
}

OptNameOrDedent noNameOrDedent() =>
	OptNameOrDedent(OptNameOrDedent.None());

immutable struct ExprAndMaybeNameOrDedent {
	ExprAst expr;
	OptNameOrDedent nameOrDedent;
}

ExprAst assertNoNameOrDedent(ExprAndMaybeNameOrDedent a) {
	verify(a.nameOrDedent.isA!(OptNameOrDedent.None));
	return a.expr;
}
ExprAst[] assertNoNameOrDedent(ArgsAndMaybeNameOrDedent a) {
	verify(a.nameOrDedent.isA!(OptNameOrDedent.None));
	return a.args;
}

immutable struct ArgsAndMaybeNameOrDedent {
	ExprAst[] args;
	OptNameOrDedent nameOrDedent;
}

ExprAndMaybeDedent noDedent(ExprAst e) =>
	ExprAndMaybeDedent(e, none!uint);

ExprAndMaybeDedent toMaybeDedent(ExprAndDedent a) =>
	ExprAndMaybeDedent(a.expr, some(a.dedents));

ArgsAndMaybeNameOrDedent parseArgsForOperator(ref Lexer lexer, ArgCtx ctx) {
	ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	return ArgsAndMaybeNameOrDedent(arrLiteral!ExprAst(lexer.alloc, [ad.expr]), ad.nameOrDedent);
}

ArgsAndMaybeNameOrDedent parseArgs(ref Lexer lexer, ArgCtx ctx) {
	if (tryTakeToken(lexer, Token.comma))
		return ArgsAndMaybeNameOrDedent([], OptNameOrDedent(OptNameOrDedent.Comma()));
	else if (tryTakeToken(lexer, Token.colon))
		return ArgsAndMaybeNameOrDedent([], OptNameOrDedent(OptNameOrDedent.Colon()));
	else if (peekTokenExpression(lexer)) {
		ArrBuilder!ExprAst builder;
		return parseArgsRecur(lexer, ctx, builder);
	} else
		return ArgsAndMaybeNameOrDedent([], noNameOrDedent());
}

ArgsAndMaybeNameOrDedent parseArgsRecur(ref Lexer lexer, ArgCtx ctx, ref ArrBuilder!ExprAst args) {
	verify(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
	ExprAndMaybeNameOrDedent ad = parseExprAndCalls(lexer, ctx);
	add(lexer.alloc, args, ad.expr);
	return ad.nameOrDedent.isA!(OptNameOrDedent.Comma)
		? parseArgsRecur(lexer, ctx, args)
		: ArgsAndMaybeNameOrDedent(finishArr(lexer.alloc, args), ad.nameOrDedent);
}

ExprAndDedent parseAssignment(ref Lexer lexer, Pos start, ref ExprAst left, Pos assignmentPos, uint curIndent) {
	ExprAndDedent right = parseExprNoLet(lexer, curIndent);
	return ExprAndDedent(
		ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, AssignmentAst(left, assignmentPos, right.expr)))),
		right.dedents);
}

ExprAndDedent parseNextLinesOrEmpty(
	ref Lexer lexer,
	Pos start,
	uint dedentsBefore,
	uint curIndent,
) =>
	dedentsBefore != 0
		? ExprAndDedent(emptyAst(lexer), dedentsBefore)
		: parseStatementsAndDedents(lexer, curIndent);

ExprAst emptyAst(ref Lexer lexer) =>
	ExprAst(rangeAtChar(lexer), ExprAstKind(EmptyAst()));

ExprAndMaybeNameOrDedent parseCalls(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	if (tryTakeToken(lexer, Token.comma)) {
		return canParseCommaExpr(argCtx)
			? parseCallsAfterComma(lexer, start, lhs, argCtx)
			: ExprAndMaybeNameOrDedent(lhs, OptNameOrDedent(OptNameOrDedent.Comma()));
	} else if (tryTakeToken(lexer, Token.question))
		return parseCallsAfterQuestion(lexer, start, lhs, argCtx);
	else if (tryTakeToken(lexer, Token.colon))
		return ExprAndMaybeNameOrDedent(lhs, OptNameOrDedent(OptNameOrDedent.Colon()));
	else {
		Opt!NameAndRange funName = tryTakeNameOrOperatorAndRangeNoAssignment(lexer);
		return has(funName)
			? parseCallsAfterName(lexer, start, lhs, force(funName), argCtx)
			: ExprAndMaybeNameOrDedent(lhs, noNameOrDedent());
	}
}

ExprAndMaybeNameOrDedent parseCallsAfterQuestion(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	if (canParseTernaryExpr(argCtx)) {
		ExprAndMaybeNameOrDedent then = parseExprAndCalls(lexer, argCtx);
		ExprAndMaybeNameOrDedent stopHere() {
			return ExprAndMaybeNameOrDedent(
				ExprAst(
					range(lexer, start),
					ExprAstKind(allocate(lexer.alloc, IfAst(lhs, then.expr, emptyAst(lexer))))),
				then.nameOrDedent);
		}
		return then.nameOrDedent.match!ExprAndMaybeNameOrDedent(
			(OptNameOrDedent.None) =>
				stopHere(),
			(OptNameOrDedent.Colon) {
				ExprAst else_ = parseAfterColon(lexer, argCtx);
				return ExprAndMaybeNameOrDedent(
					ExprAst(
						range(lexer, start),
						ExprAstKind(allocate(lexer.alloc, IfAst(lhs, then.expr, else_)))),
					OptNameOrDedent(OptNameOrDedent.None()));
			},
			(OptNameOrDedent.Comma) =>
				unreachable!ExprAndMaybeNameOrDedent,
			(NameAndRange _) =>
				unreachable!ExprAndMaybeNameOrDedent,
			(OptNameOrDedent.Dedent) =>
				stopHere(),
			(OptNameOrDedent.Question) =>
				todo!ExprAndMaybeNameOrDedent("!"));
	} else
		return ExprAndMaybeNameOrDedent(lhs, OptNameOrDedent(OptNameOrDedent.Question()));
}

ExprAst parseAfterColon(ref Lexer lexer, ArgCtx argCtx) {
	ExprAndMaybeNameOrDedent else_ = parseExprAndCalls(lexer, argCtx);
	return else_.nameOrDedent.match!ExprAst(
		(OptNameOrDedent.None) =>
			else_.expr,
		(OptNameOrDedent.Colon) =>
			todo!ExprAst("!"),
		(OptNameOrDedent.Comma) =>
			unreachable!ExprAst,
		(NameAndRange _) =>
			unreachable!ExprAst,
		(OptNameOrDedent.Dedent) =>
			unreachable!ExprAst,
		(OptNameOrDedent.Question) =>
			todo!ExprAst("!"));
}

bool canParseTernaryExpr(in ArgCtx argCtx) =>
	ternaryPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

bool canParseCommaExpr(in ArgCtx argCtx) =>
	commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

ExprAndMaybeNameOrDedent parseCallsAfterComma(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	ArrBuilder!ExprAst builder;
	add(lexer.alloc, builder, lhs);
	ArgsAndMaybeNameOrDedent args = peekTokenExpression(lexer)
		? parseArgsRecur(lexer, requirePrecedenceGtComma(argCtx), builder)
		: ArgsAndMaybeNameOrDedent(finishArr(lexer.alloc, builder), OptNameOrDedent(OptNameOrDedent.None()));
	RangeWithinFile range = range(lexer, start);
	return ExprAndMaybeNameOrDedent(
		ExprAst(range, ExprAstKind(
			//TODO: range is wrong..
			CallAst(CallAst.Style.comma, NameAndRange(range.start, sym!"new"), args.args))),
		args.nameOrDedent);
}

ExprAndMaybeNameOrDedent parseCallsAfterName(
	ref Lexer lexer,
	Pos start,
	ref ExprAst lhs,
	NameAndRange funName,
	ArgCtx argCtx,
) {
	int precedence = symPrecedence(funName.name, peekToken(lexer, Token.equal) || peekToken(lexer, Token.colonEqual));
	if (precedence > argCtx.allowedCalls.minPrecedenceExclusive) {
		Opt!AssignmentKind assignment = tryTakeToken(lexer, Token.colonEqual)
			? some(AssignmentKind.replace)
			: tryTakeToken(lexer, Token.equal)
			? some(AssignmentKind.inPlace)
			: none!AssignmentKind;
		bool isOperator = precedence != 0;
		//TODO: don't do this for operators
		Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
		ArgCtx innerCtx = requirePrecedenceGt(argCtx, precedence);
		ArgsAndMaybeNameOrDedent args = isOperator
			? parseArgsForOperator(lexer, innerCtx)
			: parseArgs(lexer, innerCtx);
		ExprAstKind exprKind = () {
			if (has(assignment)) {
				final switch (force(assignment)) {
					case AssignmentKind.inPlace:
						return ExprAstKind(CallAst(
							CallAst.Style.infix,
							appendEquals(funName, allSymbols(lexer)),
							prepend!ExprAst(lexer.alloc, lhs, args.args)));
					case AssignmentKind.replace:
						return ExprAstKind(allocate(lexer.alloc, AssignmentCallAst(lhs, funName, only(args.args))));
				}
			} else
				return ExprAstKind(
					CallAst(CallAst.Style.infix, funName, prepend!ExprAst(lexer.alloc, lhs, args.args), typeArg));
		}();
		ExprAst expr = ExprAst(range(lexer, start), exprKind);
		ExprAndMaybeNameOrDedent stopHere = ExprAndMaybeNameOrDedent(expr, args.nameOrDedent);
		return args.nameOrDedent.match!ExprAndMaybeNameOrDedent(
			(OptNameOrDedent.None) =>
				stopHere,
			(OptNameOrDedent.Colon) =>
				stopHere,
			(OptNameOrDedent.Comma) =>
				canParseCommaExpr(argCtx)
					? parseCallsAfterComma(lexer, start, expr, argCtx)
					: stopHere,
			(NameAndRange name) =>
				parseCallsAfterName(lexer, start, expr, name, argCtx),
			(OptNameOrDedent.Dedent) =>
				stopHere,
			(OptNameOrDedent.Question) =>
				parseCallsAfterQuestion(lexer, start, expr, argCtx));
	} else
		return ExprAndMaybeNameOrDedent(lhs, OptNameOrDedent(funName));
}

enum AssignmentKind {
	inPlace, // foo=
	replace, // foo:=
}

NameAndRange appendEquals(NameAndRange a, ref AllSymbols allSymbols) =>
	NameAndRange(a.start, .appendEquals(allSymbols, a.name));

// This is for the , in `1, 2`, not the comma between args
int commaPrecedence() =>
	-6;
// Precedence for '?' and ':' in 'a ? b : c'
int ternaryPrecedence() =>
	-5;

int symPrecedence(Sym a, bool isAssignment) {
	if (isAssignment) return -4;
	switch (a.value) {
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
		default:
			// All other names
			return 0;
	}
}

OptNameOrDedent nameOrDedentFromOptDedents(Opt!uint dedents) =>
	has(dedents)
		? OptNameOrDedent(OptNameOrDedent.Dedent(force(dedents)))
		: noNameOrDedent();

ExprAst tryParseDotsAndSubscripts(ref Lexer lexer, ExprAst initial) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.dot)) {
		NameAndRange name = takeNameAndRange(lexer);
		Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
		CallAst call = CallAst(CallAst.Style.dot, name, arrLiteral!ExprAst(lexer.alloc, [initial]), typeArg);
		return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.arrowAccess)) {
		NameAndRange name = takeNameAndRange(lexer);
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(ArrowAccessAst(allocate(lexer.alloc, initial), name))));
	} else if (tryTakeToken(lexer, Token.bracketLeft))
		return parseSubscript(lexer, initial, start);
	else if (tryTakeToken(lexer, Token.colon2)) {
		TypeAst type = parseTypeForTypedExpr(lexer);
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, TypedAst(initial, type)))));
	} else if (tryTakeToken(lexer, Token.bang)) {
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(CallAst(
				CallAst.Style.suffixBang, NameAndRange(start, sym!"force"), arrLiteral(lexer.alloc, [initial])))));
	} else
		return initial;
}

ExprAst parseSubscript(ref Lexer lexer, ExprAst initial, Pos start) {
	ExprAst arg = () {
		if (tryTakeToken(lexer, Token.bracketRight))
			return ExprAst(
				range(lexer, start),
				ExprAstKind(CallAst(CallAst.Style.emptyParens, NameAndRange(start, sym!"new"), [])));
		else {
			ExprAst res = parseExprNoBlock(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
			return res;
		}
	}();
	//TODO: the range is wrong..
	return tryParseDotsAndSubscripts(lexer, ExprAst(
		range(lexer, start),
		ExprAstKind(CallAst(
			CallAst.Style.subscript,
			NameAndRange(start, sym!"subscript"),
			arrLiteral!ExprAst(lexer.alloc, [initial, arg])))));
}

ExprAndDedent parseMatch(ref Lexer lexer, Pos start, uint curIndent) {
	ExprAst matched = parseExprNoBlock(lexer);
	uint dedentsAfterMatched = takeNewlineOrDedentAmount(lexer, curIndent);
	ArrBuilder!(MatchAst.CaseAst) cases;
	uint dedents = dedentsAfterMatched != 0
		? dedentsAfterMatched
		: parseMatchCases(lexer, cases, curIndent);
	return ExprAndDedent(
		ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, MatchAst(matched, finishArr(lexer.alloc, cases))))),
		dedents);
}

uint parseMatchCases(ref Lexer lexer, ref ArrBuilder!(MatchAst.CaseAst) cases, uint curIndent) {
	Pos startCase = curPos(lexer);
	if (tryTakeToken(lexer, Token.as)) {
		Sym memberName = takeName(lexer);
		Opt!DestructureAst destructure = peekToken(lexer, Token.newline)
			? none!DestructureAst
			: some(parseDestructureNoRequireParens(lexer));
		ExprAndDedent ed = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
			parseStatementsAndExtraDedents(lexer, curIndent + 1));
		add(lexer.alloc, cases, MatchAst.CaseAst(range(lexer, startCase), memberName, destructure, ed.expr));
		return ed.dedents == 0 ? parseMatchCases(lexer, cases, curIndent) : ed.dedents;
	} else
		return 0;
}

ExprAndDedent parseIf(ref Lexer lexer, Pos start, uint curIndent) =>
	parseIfRecur(lexer, start, curIndent);

ExprAndDedent parseIfRecur(ref Lexer lexer, Pos start, uint curIndent) {
	if (lookaheadWillTakeQuestionEquals(lexer)) {
		DestructureAst lhs = parseDestructureNoRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.questionEqual, ParseDiag.Expected.Kind.questionEqual);
		ConditionThenAndElse cte = parseConditionThenAndElse(lexer, curIndent);
		ExprAstKind kind = ExprAstKind(allocate(lexer.alloc, IfOptionAst(
			lhs,
			cte.condition,
			cte.then,
			cte.else_)));
		return ExprAndDedent(ExprAst(range(lexer, start), kind), cte.dedents);
	} else {
		ConditionThenAndElse cte = parseConditionThenAndElse(lexer, curIndent);
		ExprAstKind kind = ExprAstKind(allocate(lexer.alloc, IfAst(cte.condition, cte.then, cte.else_)));
		return ExprAndDedent(ExprAst(range(lexer, start), kind), cte.dedents);
	}
}

struct ConditionThenAndElse {
	ExprAst condition;
	ExprAst then;
	ExprAst else_;
	uint dedents;
}

ConditionThenAndElse parseConditionThenAndElse(ref Lexer lexer, uint curIndent) {
	ExprAst condition = parseExprNoBlock(lexer);
	ExprAndDedent thenAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	Pos elifStart = curPos(lexer);
	ExprAndDedent else_ = thenAndDedent.dedents != 0
		? ExprAndDedent(emptyAst(lexer), thenAndDedent.dedents)
		: tryTakeToken(lexer, Token.elif)
		? parseIfRecur(lexer, elifStart, curIndent)
		: tryTakeToken(lexer, Token.else_)
		? takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
			parseStatementsAndExtraDedents(lexer, curIndent + 1))
		: ExprAndDedent(emptyAst(lexer), 0);
	return ConditionThenAndElse(condition, thenAndDedent.expr, else_.expr, else_.dedents);
}

immutable struct ConditionAndBody {
	ExprAst condition;
	ExprAst body_;
	uint dedents;
}

ConditionAndBody parseConditionAndBody(ref Lexer lexer, uint curIndent) {
	ExprAst cond = parseExprNoBlock(lexer);
	ExprAndDedent bodyAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	return ConditionAndBody(cond, bodyAndDedent.expr, bodyAndDedent.dedents);
}

ExprAndDedent parseUnless(ref Lexer lexer, Pos start, uint curIndent) {
	ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return ExprAndDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, UnlessAst(cb.condition, cb.body_)))),
		cb.dedents);
}

ExprAndMaybeDedent parseThrow(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseThrowOrTrusted(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.throw_, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, ThrowAst(inner))));

ExprAndMaybeDedent parseTrusted(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseThrowOrTrusted(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.trusted, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, TrustedAst(inner))));

ExprAndMaybeDedent parseThrowOrTrusted(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind needsBlockKind,
	in ExprAstKind delegate(ExprAst inner) @safe @nogc pure nothrow cbMakeExpr,
) {
	ExprAndMaybeDedent inner = parseExprInlineOrBlock(lexer, start, allowedBlock, needsBlockKind);
	return ExprAndMaybeDedent(ExprAst(range(lexer, start), cbMakeExpr(inner.expr)), inner.dedents);
}

ExprAndMaybeDedent parseAssertOrForbid(ref Lexer lexer, Pos start, AllowedBlock allowedBlock, AssertOrForbidKind kind) {
	ExprAndMaybeNameOrDedent condition = parseExprAndCalls(lexer, ArgCtx(allowedBlock, allowAllCalls));
	ExprAndMaybeDedent noThrown(Opt!uint dedents) {
		return ExprAndMaybeDedent(
			ExprAst(range(lexer, start), ExprAstKind(
				allocate(lexer.alloc, AssertOrForbidAst(kind, condition.expr, none!ExprAst)))),
			dedents);
	}
	return condition.nameOrDedent.match!ExprAndMaybeDedent(
		(OptNameOrDedent.None) =>
			noThrown(none!uint),
		(OptNameOrDedent.Colon) {
			ExprAst thrown = parseAfterColon(lexer, ArgCtx(allowedBlock, allowAllCalls));
			return noDedent(ExprAst(range(lexer, start), ExprAstKind(
				allocate(lexer.alloc, AssertOrForbidAst(kind, condition.expr, some(thrown))))));
		},
		(OptNameOrDedent.Comma) =>
			unreachable!ExprAndMaybeDedent,
		(NameAndRange _) =>
			unreachable!ExprAndMaybeDedent,
		(OptNameOrDedent.Dedent x) =>
			noThrown(some(x.dedents)),
		(OptNameOrDedent.Question) =>
			todo!ExprAndMaybeDedent("!"));
}

ExprAndMaybeDedent parseFor(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseForOrWith(
		lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.for_,
		(DestructureAst param, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, ForAst(param, col, body_, else_))));

ExprAndMaybeDedent parseWith(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseForOrWith(
		lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.with_,
		(DestructureAst param, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, WithAst(param, col, body_, else_))));

ExprAndMaybeDedent parseForOrWith(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind blockKind,
	in ExprAstKind delegate(
		DestructureAst, ExprAst rhs, ExprAst body_, ExprAst else_,
	) @safe @nogc pure nothrow cbMakeExprKind,
) {
	DestructureAst param = parseParameterForForOrWith(lexer);
	ExprAst rhs = parseExprNoBlock(lexer);
	bool semi = tryTakeToken(lexer, Token.semicolon);
	if (semi) {
		ExprAst body_ = parseExprNoBlock(lexer);
		return noDedent(ExprAst(range(lexer, start), cbMakeExprKind(param, rhs, body_, emptyAst(lexer))));
	} else if (isAllowBlock(allowedBlock)) {
		uint curIndent = asAllowBlock(allowedBlock).curIndent;
		return toMaybeDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () {
			ExprAndDedent body_ = parseStatementsAndExtraDedents(lexer, curIndent + 1);
			ExprAndDedent else_ = () {
				if (body_.dedents == 0 && tryTakeToken(lexer, Token.else_)) {
					return takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
						parseStatementsAndExtraDedents(lexer, curIndent + 1));
				} else
					return ExprAndDedent(emptyAst(lexer), body_.dedents);
			}();
			return ExprAndDedent(
				ExprAst(range(lexer, start), cbMakeExprKind(param, rhs, body_.expr, else_.expr)),
				else_.dedents);
		}));
	} else
		return exprBlockNotAllowed(lexer, start, blockKind);
}

ExprAndDedent parseLoop(ref Lexer lexer, Pos start, uint curIndent) {
	ExprAndDedent bodyAndDedent = takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
		parseStatementsAndExtraDedents(lexer, curIndent + 1));
	return ExprAndDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopAst(bodyAndDedent.expr)))),
		bodyAndDedent.dedents);
}

ExprAndDedent parseLoopBreak(ref Lexer lexer, Pos start, uint curIndent) {
	ExprAndDedent valueAndDedent = peekToken(lexer, Token.newline)
		? ExprAndDedent(emptyAst(lexer), takeNewlineOrDedentAmount(lexer, curIndent))
		: parseExprNoLet(lexer, curIndent);
	return ExprAndDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopBreakAst(valueAndDedent.expr)))),
		valueAndDedent.dedents);
}

ExprAndDedent parseLoopUntil(ref Lexer lexer, Pos start, uint curIndent) {
	ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return ExprAndDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopUntilAst(cb.condition, cb.body_)))),
		cb.dedents);
}

ExprAndDedent parseLoopWhile(ref Lexer lexer, Pos start, uint curIndent) {
	ConditionAndBody cb = parseConditionAndBody(lexer, curIndent);
	return ExprAndDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopWhileAst(cb.condition, cb.body_)))),
		cb.dedents);
}

ExprAndDedent takeIndentOrFail_ExprAndDedent(
	ref Lexer lexer,
	uint curIndent,
	in ExprAndDedent delegate() @safe @nogc pure nothrow cbIndent,
) =>
	takeIndentOrFailGeneric(lexer, curIndent, cbIndent, (RangeWithinFile range, uint nDedents) =>
		ExprAndDedent(bogusExpr(range), nDedents));

ExprAndMaybeDedent parseLambdaWithParenthesizedParameters(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) {
	DestructureAst parameter = parseDestructureRequireParens(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.arrowLambda, ParseDiag.Expected.Kind.lambdaArrow);
	return parseLambdaAfterArrow(lexer, start, allowedBlock, parameter);
}

DestructureAst parseParameterForForOrWith(ref Lexer lexer) =>
	parseForThenOrWithParameter(lexer, Token.colon, ParseDiag.Expected.Kind.colon);

DestructureAst parseForThenOrWithParameter(
	ref Lexer lexer,
	Token endToken,
	ParseDiag.Expected.Kind expectedEndToken,
) {
	Pos pos = curPos(lexer);
	if (tryTakeToken(lexer, endToken))
		return DestructureAst(DestructureAst.Void(pos));
	else {
		DestructureAst res = parseDestructureNoRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, endToken, expectedEndToken);
		return res;
	}
}

ExprAndMaybeDedent parseLambdaAfterNameAndArrow(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	Sym paramName,
) =>
	parseLambdaAfterArrow(lexer, start, allowedBlock, DestructureAst(
		DestructureAst.Single(NameAndRange(start, paramName), false, none!(TypeAst*))));

ExprAndMaybeDedent parseLambdaAfterArrow(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	DestructureAst parameter,
) {
	ExprAndMaybeDedent body_ = parseExprInlineOrBlock(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.lambda);
	return ExprAndMaybeDedent(
		ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LambdaAst(parameter, body_.expr)))),
		body_.dedents);
}

ExprAndMaybeDedent parseExprInlineOrBlock(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind needsBlockKind,
) {
	bool inLine = peekTokenExpression(lexer);
	if (isAllowBlock(allowedBlock)) {
		uint curIndent = asAllowBlock(allowedBlock).curIndent;
		return inLine
			? parseExprAndAllCalls(lexer, allowBlock(curIndent))
			: toMaybeDedent(takeIndentOrFail_ExprAndDedent(lexer, curIndent, () =>
				parseStatementsAndExtraDedents(lexer, curIndent + 1)));
	} else
		return inLine
			? noDedent(parseExprNoBlock(lexer))
			: exprBlockNotAllowed(lexer, start, needsBlockKind);
}

ExprAndMaybeDedent skipRestOfLineAndReturnBogusNoDiag(ref Lexer lexer, Pos start) {
	skipUntilNewlineNoDiag(lexer);
	return noDedent(bogusExpr(range(lexer, start)));
}

ExprAndMaybeDedent skipRestOfLineAndReturnBogus(ref Lexer lexer, Pos start, ParseDiag diag) {
	addDiag(lexer, range(lexer, start), diag);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

ExprAndMaybeDedent exprBlockNotAllowed(ref Lexer lexer, Pos start, ParseDiag.NeedsBlockCtx.Kind kind) =>
	skipRestOfLineAndReturnBogus(lexer, start, ParseDiag(ParseDiag.NeedsBlockCtx(kind)));

ExprAndMaybeDedent parseExprBeforeCall(ref Lexer lexer, AllowedBlock allowedBlock) {
	Pos start = curPos(lexer);
	if (peekToken(lexer, Token.parenLeft) && lookaheadWillTakeArrowAfterParenLeft(lexer)) {
		return parseLambdaWithParenthesizedParameters(lexer, start, allowedBlock);
	}
	Token token = nextToken(lexer);
	switch (token) {
		case Token.parenLeft:
			if (tryTakeToken(lexer, Token.parenRight)) {
				ExprAst expr = ExprAst(
					range(lexer, start),
					//TODO: range is wrong..
					ExprAstKind(CallAst(CallAst.Style.emptyParens, NameAndRange(start, sym!"new"), [])));
				return noDedent(tryParseDotsAndSubscripts(lexer, expr));
			} else {
				ExprAst inner = parseExprNoBlock(lexer);
				takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
				ExprAst expr = ExprAst(
					range(lexer, start),
					ExprAstKind(allocate(lexer.alloc, ParenthesizedAst(inner))));
				return noDedent(tryParseDotsAndSubscripts(lexer, expr));
			}
		case Token.quoteDouble:
		case Token.quoteDouble3:
			QuoteKind quoteKind = token == Token.quoteDouble ? QuoteKind.double_ : QuoteKind.double3;
			StringPart part = takeStringPart(lexer, quoteKind);
			ExprAst quoted = () {
				final switch (part.after) {
					case StringPart.After.quote:
						return ExprAst(range(lexer, start), ExprAstKind(LiteralStringAst(part.text)));
					case StringPart.After.lbrace:
						return takeInterpolated(lexer, start, part.text, quoteKind);
				}
			}();
			return noDedent(tryParseDotsAndSubscripts(lexer, quoted));
		case Token.assert_:
			return parseAssertOrForbid(lexer, start, allowedBlock, AssertOrForbidKind.assert_);
		case Token.bang:
			ExprAndMaybeDedent inner = parseExprBeforeCall(lexer, noBlock());
			return ExprAndMaybeDedent(
				ExprAst(
					range(lexer, start),
					ExprAstKind(CallAst(
						CallAst.Style.prefixBang,
						NameAndRange(start, sym!"not"),
						arrLiteral(lexer.alloc, [inner.expr])))),
				inner.dedents);
		case Token.break_:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoopBreak(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.break_);
		case Token.continue_:
			return noDedent(ExprAst(range(lexer, start), ExprAstKind(LoopContinueAst())));
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
			Sym name = getCurSym(lexer);
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, name)
				: handleName(lexer, start, NameAndRange(start, name));
		case Token.operator:
			Sym operator = getCurOperator(lexer);
			if (operator == sym!"&") {
				ExprAndMaybeDedent inner = parseExprBeforeCall(lexer, noBlock());
				return ExprAndMaybeDedent(
					ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, PtrAst(inner.expr)))),
					inner.dedents);
			} else
				return handlePrefixOperator(lexer, allowedBlock, start, operator);
		case Token.literalFloat:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				ExprAst(range(lexer, start), ExprAstKind(getCurLiteralFloat(lexer)))));
		case Token.literalInt:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				ExprAst(range(lexer, start), ExprAstKind(getCurLiteralInt(lexer)))));
		case Token.literalNat:
			return noDedent(tryParseDotsAndSubscripts(
				lexer,
				ExprAst(range(lexer, start), ExprAstKind(getCurLiteralNat(lexer)))));
		case Token.loop:
			return isAllowBlock(allowedBlock)
				? toMaybeDedent(parseLoop(lexer, start, asAllowBlock(allowedBlock).curIndent))
				: exprBlockNotAllowed(lexer, start, ParseDiag.NeedsBlockCtx.Kind.loop);
		case Token.throw_:
			return parseThrow(lexer, start, allowedBlock);
		case Token.trusted:
			return parseTrusted(lexer, start, allowedBlock);
		case Token.underscore:
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, sym!"_")
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

ExprAndMaybeDedent badToken(ref Lexer lexer, Pos start, Token token) {
	addDiagUnexpectedCurToken(lexer, start, token);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

ExprAndMaybeDedent handlePrefixOperator(
	ref Lexer lexer,
	AllowedBlock allowedBlock,
	Pos start,
	Sym operator,
) {
	ExprAndMaybeDedent arg = parseExprBeforeCall(lexer, allowedBlock);
	ExprAst expr = ExprAst(range(lexer, start), ExprAstKind(
		CallAst(CallAst.Style.prefixOperator, NameAndRange(start, operator), arrLiteral(lexer.alloc, [arg.expr]))));
	return ExprAndMaybeDedent(expr, arg.dedents);
}

ExprAndMaybeDedent handleName(ref Lexer lexer, Pos start, NameAndRange name) {
	Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
	if (has(typeArg))
		return noDedent(ExprAst(
			range(lexer, start),
			ExprAstKind(CallAst(CallAst.Style.single, name, [], typeArg))));
	else {
		ExprAst expr = ExprAst(range(lexer, start), ExprAstKind(IdentifierAst(name.name)));
		return noDedent(tryParseDotsAndSubscripts(lexer, expr));
	}
}

ExprAst takeInterpolated(ref Lexer lexer, Pos start, string firstText, QuoteKind quoteKind) {
	ArrBuilder!InterpolatedPart parts;
	if (!empty(firstText))
		add(lexer.alloc, parts, InterpolatedPart(firstText));
	return takeInterpolatedRecur(lexer, start, parts, quoteKind);
}

ExprAst takeInterpolatedRecur(ref Lexer lexer, Pos start, ref ArrBuilder!InterpolatedPart parts, QuoteKind quoteKind) {
	ExprAst e = parseExprNoBlock(lexer);
	add(lexer.alloc, parts, InterpolatedPart(e));
	takeOrAddDiagExpectedToken(lexer, Token.braceRight, ParseDiag.Expected.Kind.closeInterpolated);
	StringPart part = takeStringPart(lexer, quoteKind);
	if (!empty(part.text))
		add(lexer.alloc, parts, InterpolatedPart(part.text));
	final switch (part.after) {
		case StringPart.After.quote:
			return ExprAst(range(lexer, start), ExprAstKind(InterpolatedAst(finishArr(lexer.alloc, parts))));
		case StringPart.After.lbrace:
			return takeInterpolatedRecur(lexer, start, parts, quoteKind);
	}
}

ExprAndMaybeDedent assertNoNameAfter(ExprAndMaybeNameOrDedent a) =>
	ExprAndMaybeDedent(a.expr, assertNoName(a.nameOrDedent));

Opt!uint assertNoName(OptNameOrDedent a) =>
	a.match!(Opt!uint)(
		(OptNameOrDedent.None) =>
			none!uint,
		(OptNameOrDedent.Colon) =>
			unreachable!(Opt!uint),
		(OptNameOrDedent.Comma) =>
			unreachable!(Opt!uint),
		(NameAndRange _) =>
			// We allowed all calls, so should be no dangling names
			unreachable!(Opt!uint),
		(OptNameOrDedent.Dedent it) =>
			some(it.dedents),
		(OptNameOrDedent.Question) =>
			unreachable!(Opt!uint));

ExprAst parseExprNoBlock(ref Lexer lexer) {
	ExprAndMaybeDedent ed = parseExprAndAllCalls(lexer, noBlock());
	verify(!has(ed.dedents));
	return ed.expr;
}

ExprAndMaybeDedent parseExprAndAllCalls(ref Lexer lexer, AllowedBlock allowedBlock) {
	ArgCtx argCtx = ArgCtx(allowedBlock, allowAllCalls());
	return assertNoNameAfter(parseExprAndCalls(lexer, argCtx));
}

ExprAndMaybeNameOrDedent parseExprAndCalls(ref Lexer lexer, ArgCtx argCtx) {
	Pos start = curPos(lexer);
	ExprAndMaybeDedent ed = parseExprBeforeCall(lexer, argCtx.allowedBlock);
	return has(ed.dedents)
		? ExprAndMaybeNameOrDedent(ed.expr, nameOrDedentFromOptDedents(ed.dedents))
		: parseCalls(lexer, start, ed.expr, argCtx);
}

ExprAndDedent parseExprNoLet(ref Lexer lexer, uint curIndent) =>
	addDedent(lexer, parseExprAndAllCalls(lexer, allowBlock(curIndent)), curIndent);

ExprAndDedent parseSingleStatementLine(ref Lexer lexer, uint curIndent) {
	Pos start = curPos(lexer);
	Opt!EqualsOrThen et = lookaheadWillTakeEqualsOrThen(lexer);
	if (has(et))
		return parseEqualsOrThen(lexer, curIndent, force(et));
	else {
		ExprAndMaybeDedent expr = parseExprBeforeCall(lexer, allowBlock(curIndent));
		Pos assignmentPos = curPos(lexer);
		if (!has(expr.dedents) && tryTakeToken(lexer, Token.colonEqual))
			return parseAssignment(lexer, start, expr.expr, assignmentPos, curIndent);
		else {
			ExprAndMaybeDedent fullExpr = has(expr.dedents)
				? expr
				: assertNoNameAfter(
					parseCalls(lexer, start, expr.expr, ArgCtx(allowBlock(curIndent), allowAllCalls())));
			return addDedent(lexer, fullExpr, curIndent);
		}
	}
}

public DestructureAst parseDestructureRequireParens(ref Lexer lexer) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.parenLeft)) {
		if (tryTakeToken(lexer, Token.parenRight))
			return DestructureAst(DestructureAst.Void(start));
		else {
			DestructureAst res = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
			return res;
		}
	} else {
		NameAndRange name = takeNameAndRangeAllowUnderscore(lexer);
		bool mut = tryTakeToken(lexer, Token.mut);
		Opt!(TypeAst*) type = () {
			switch (getPeekToken(lexer)) {
				case Token.arrowThen:
				case Token.colon:
				case Token.comma:
				case Token.equal:
				case Token.newline:
				case Token.parenRight:
				case Token.questionEqual:
					return none!(TypeAst*);
				default:
					return some(allocate(lexer.alloc, parseType(lexer)));
			}
		}();
		return DestructureAst(DestructureAst.Single(name, mut, type));
	}
}

DestructureAst parseDestructureNoRequireParens(ref Lexer lexer) {
	DestructureAst first = parseDestructureRequireParens(lexer);
	if (tryTakeToken(lexer, Token.comma)) {
		ArrBuilder!DestructureAst parts;
		add(lexer.alloc, parts, first);
		do {
			add(lexer.alloc, parts, parseDestructureRequireParens(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		return DestructureAst(finishArr(lexer.alloc, parts));
	} else
		return first;
}

ExprAndDedent parseEqualsOrThen(ref Lexer lexer, uint curIndent, EqualsOrThen kind) {
	Pos start = curPos(lexer);
	final switch (kind) {
		case EqualsOrThen.equals:
			DestructureAst left = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.equal, ParseDiag.Expected.Kind.equals);
			ExprAndDedent initAndDedent = parseExprNoLet(lexer, curIndent);
			ExprAndDedent thenAndDedent = parseNextLinesOrEmpty(lexer, start, initAndDedent.dedents, curIndent);
			return ExprAndDedent(
				ExprAst(range(lexer, start), ExprAstKind(
					allocate(lexer.alloc, LetAst(left, initAndDedent.expr, thenAndDedent.expr)))),
				thenAndDedent.dedents);
		case EqualsOrThen.then:
			DestructureAst param =
				parseForThenOrWithParameter(lexer, Token.arrowThen, ParseDiag.Expected.Kind.then);
			ExprAndDedent futureAndDedent = parseExprNoLet(lexer, curIndent);
			ExprAndDedent thenAndDedent = parseNextLinesOrEmpty(lexer, start, futureAndDedent.dedents, curIndent);
			ExprAstKind exprKind = ExprAstKind(
				allocate(lexer.alloc, ThenAst(param, futureAndDedent.expr, thenAndDedent.expr)));
			return ExprAndDedent(ExprAst(range(lexer, start), exprKind), thenAndDedent.dedents);
	}
}

ExprAndDedent addDedent(ref Lexer lexer, ExprAndMaybeDedent e, uint curIndent) =>
	ExprAndDedent(e.expr, has(e.dedents) ? force(e.dedents) : takeNewlineOrDedentAmount(lexer, curIndent));

ExprAndDedent parseStatementsAndDedents(ref Lexer lexer, uint curIndent) {
	ExprAndDedent res = parseStatementsAndExtraDedents(lexer, curIndent);
	// Since we don't always expect a dedent here,
	// the dedent isn't *extra*, so increment to get the correct number of dedents.
	return ExprAndDedent(res.expr, res.dedents + 1);
}

// Return value is number of dedents - 1; the number of *extra* dedents
ExprAndDedent parseStatementsAndExtraDedents(ref Lexer lexer, uint curIndent) {
	Pos start = curPos(lexer);
	ExprAndDedent ed = parseSingleStatementLine(lexer, curIndent);
	return parseStatementsAndExtraDedentsRecur(lexer, start, ed.expr, curIndent, ed.dedents);
}

ExprAndDedent parseStatementsAndExtraDedentsRecur(
	ref Lexer lexer,
	Pos start,
	ExprAst expr,
	uint curIndent,
	uint dedents,
) {
	if (dedents == 0) {
		ExprAndDedent ed = parseSingleStatementLine(lexer, curIndent);
		SeqAst seq = SeqAst(expr, ed.expr);
		return parseStatementsAndExtraDedentsRecur(
			lexer,
			start,
			ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, seq))),
			curIndent,
			ed.dedents);
	} else
		return ExprAndDedent(expr, dedents - 1);
}
