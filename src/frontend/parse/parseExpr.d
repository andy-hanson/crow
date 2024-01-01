module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	alloc,
	allSymbols,
	curPos,
	ElifOrElse,
	EqualsOrThen,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	lookaheadEqualsOrThen,
	lookaheadLambda,
	lookaheadQuestionEquals,
	QuoteKind,
	range,
	rangeAtChar,
	rangeForCurToken,
	skipUntilNewlineNoDiag,
	StringPart,
	takeClosingBraceThenStringPart,
	takeInitialStringPart,
	takeNextToken,
	Token,
	TokenAndData,
	tryTakeNewlineThenAs,
	tryTakeNewlineThenElifOrElse,
	tryTakeNewlineThenElse;
import frontend.parse.lexToken : isNewlineToken;
import frontend.parse.parseType : parseType, parseTypeForTypedExpr, tryParseTypeArgForExpr;
import frontend.parse.parseUtil :
	peekEndOfLine,
	peekToken,
	takeDedent,
	takeIndentOrFailGeneric,
	takeNameAndRange,
	takeNameAndRangeAllowUnderscore,
	takeOrAddDiagExpectedToken,
	tryTakeToken;
import model.ast :
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
import model.model : AssertOrForbidKind;
import model.parseDiag : ParseDiag;
import util.col.array : isEmpty, newArray, only, prepend;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some, some;
import util.sourceRange : Pos, Range;
import util.symbol : AllSymbols, appendEquals, Symbol, symbol;
import util.util : max;

ExprAst parseFunExprBody(ref Lexer lexer) =>
	tryTakeToken(lexer, Token.newlineIndent)
		? parseStatementsAndDedent(lexer)
		: emptyAst(lexer);

private:

ExprAst bogusExpr(in Range range) =>
	ExprAst(range, ExprAstKind(BogusAst()));

enum AllowedBlock { no, yes }

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

ExprAst[] parseArgsForOperator(ref Lexer lexer, ArgCtx ctx) =>
	newArray!ExprAst(lexer.alloc, [parseExprAndCalls(lexer, ctx)]);

ExprAst[] parseArgs(ref Lexer lexer, ArgCtx ctx) {
	if (peekTokenExpression(lexer)) {
		ArrayBuilder!ExprAst builder;
		return parseArgsRecur(lexer, ctx, builder);
	} else
		return [];
}

bool peekTokenExpression(ref Lexer lexer) =>
	isExpressionStartToken(getPeekToken(lexer));

bool isExpressionStartToken(Token a) {
	final switch (a) {
		case Token.act:
		case Token.alias_:
		case Token.arrowAccess:
		case Token.arrowLambda:
		case Token.arrowThen:
		case Token.as:
		case Token.at:
		case Token.bare:
		case Token.builtin:
		case Token.builtinSpec:
		case Token.braceLeft:
		case Token.braceRight:
		case Token.bracketRight:
		case Token.colon:
		case Token.colon2:
		case Token.colonEqual:
		case Token.comma:
		case Token.dot:
		case Token.dot3:
		case Token.elif:
		case Token.else_:
		case Token.enum_:
		case Token.equal:
		case Token.export_:
		case Token.extern_:
		case Token.EOF:
		case Token.far:
		case Token.flags:
		case Token.forceCtx:
		case Token.fun:
		case Token.global:
		case Token.import_:
		case Token.mut:
		case Token.nameOrOperatorColonEquals:
		case Token.nameOrOperatorEquals:
		case Token.newlineDedent:
		case Token.newlineIndent:
		case Token.newlineSameIndent:
		case Token.noStd:
		case Token.parenRight:
		case Token.question:
		case Token.questionEqual:
		case Token.quotedText:
		case Token.record:
		case Token.semicolon:
		case Token.spec:
		case Token.summon:
		case Token.test:
		case Token.thread_local:
		case Token.unexpectedCharacter:
		case Token.union_:
		case Token.unsafe:
			return false;
		case Token.assert_:
		case Token.bang:
		case Token.bracketLeft:
		case Token.break_:
		case Token.continue_:
		case Token.forbid:
		case Token.if_:
		case Token.for_:
		case Token.literalFloat:
		case Token.literalInt:
		case Token.literalNat:
		case Token.loop:
		case Token.match:
		case Token.name:
		case Token.operator:
		case Token.parenLeft:
		case Token.quoteDouble:
		case Token.quoteDouble3:
		case Token.throw_:
		case Token.trusted:
		case Token.underscore:
		case Token.unless:
		case Token.until:
		case Token.with_:
		case Token.while_:
			return true;
	}
}

ExprAst[] parseArgsRecur(ref Lexer lexer, ArgCtx ctx, ref ArrayBuilder!ExprAst args) {
	assert(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
	add(lexer.alloc, args, parseExprAndCalls(lexer, ctx));
	return tryTakeToken(lexer, Token.comma)
		? parseArgsRecur(lexer, ctx, args)
		: finish(lexer.alloc, args);
}

ExprAst parseAssignment(ref Lexer lexer, Pos start, ref ExprAst left, Pos assignmentPos) {
	ExprAst right = parseExprNoLet(lexer);
	return ExprAst(
		range(lexer, start),
		ExprAstKind(allocate(lexer.alloc, AssignmentAst(left, assignmentPos, right))));
}

ExprAst parseArgOrEmpty(ref Lexer lexer) =>
	peekEndOfLine(lexer)
		? emptyAst(lexer)
		: parseExprNoLet(lexer);

ExprAst parseNextLinesOrEmpty(ref Lexer lexer, Pos start) =>
	tryTakeToken(lexer, Token.newlineSameIndent)
		? parseStatements(lexer)
		: emptyAst(lexer);

ExprAst emptyAst(ref Lexer lexer) =>
	ExprAst(rangeAtChar(lexer), ExprAstKind(EmptyAst()));

ExprAst parseCalls(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) =>
	canParseCommaExpr(argCtx) && tryTakeToken(lexer, Token.comma)
		? parseCallsAfterComma(lexer, start, lhs, argCtx)
		: canParseTernaryExpr(argCtx) && tryTakeToken(lexer, Token.question)
		? parseCallsAfterQuestion(lexer, start, lhs, argCtx)
		: parseNamedCalls(lexer, start, lhs, argCtx);

ExprAst parseCallsAfterQuestion(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	ExprAst then = parseExprAndCalls(lexer, argCtx);
	if (tryTakeToken(lexer, Token.colon)) {
		ExprAst else_ = parseExprAndCalls(lexer, argCtx);
		return ExprAst(
				range(lexer, start),
				ExprAstKind(allocate(lexer.alloc, IfAst(lhs, then, else_))));
	} else
		return ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, IfAst(lhs, then, emptyAst(lexer)))));
}

bool canParseTernaryExpr(in ArgCtx argCtx) =>
	ternaryPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

bool canParseCommaExpr(in ArgCtx argCtx) =>
	commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

ExprAst parseCallsAfterComma(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	ArrayBuilder!ExprAst builder;
	add(lexer.alloc, builder, lhs);
	ExprAst[] args = peekTokenExpression(lexer)
		? parseArgsRecur(lexer, requirePrecedenceGtComma(argCtx), builder)
		: finish(lexer.alloc, builder);
	Range range = range(lexer, start);
	return ExprAst(range, ExprAstKind(
		//TODO: range is wrong..
		CallAst(CallAst.Style.comma, NameAndRange(range.start, symbol!"new"), args)));
}

struct NameAndPrecedence {
	Token token;
	Symbol name;
	int precedence;
}

ExprAst parseNamedCalls(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	Pos pos = curPos(lexer);
	Opt!NameAndPrecedence optName = tryTakeToken!NameAndPrecedence(lexer, (TokenAndData x) {
		if (x.isSymbol) {
			int precedence = symbolPrecedence(
				x.asSymbol,
				x.token == Token.nameOrOperatorEquals || x.token == Token.nameOrOperatorColonEquals);
			return precedence > argCtx.allowedCalls.minPrecedenceExclusive
				? some(NameAndPrecedence(x.token, x.asSymbol, precedence))
				: none!NameAndPrecedence;
		} else
			return none!NameAndPrecedence;
	});
	if (!has(optName))
		return lhs;

	Token funToken = force(optName).token;
	NameAndRange funName = NameAndRange(pos, force(optName).name);
	int precedence = force(optName).precedence;
	Opt!AssignmentKind assignment = () {
		switch (funToken) {
			case Token.nameOrOperatorColonEquals:
				return some(AssignmentKind.replace);
			case Token.nameOrOperatorEquals:
				return some(AssignmentKind.inPlace);
			default:
				return none!AssignmentKind;
		}
	}();
	bool isOperator = precedence != 0;
	//TODO: don't do this for operators
	Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
	ArgCtx innerCtx = requirePrecedenceGt(argCtx, precedence);
	ExprAst[] args = isOperator
		? parseArgsForOperator(lexer, innerCtx)
		: parseArgs(lexer, innerCtx);
	ExprAstKind exprKind = () {
		if (has(assignment)) {
			final switch (force(assignment)) {
				case AssignmentKind.inPlace:
					return ExprAstKind(CallAst(CallAst.Style.infix, funName, prepend(lexer.alloc, lhs, args)));
				case AssignmentKind.replace:
					return ExprAstKind(allocate(lexer.alloc, AssignmentCallAst(lhs, funName, only(args))));
			}
		} else
			return ExprAstKind(CallAst(CallAst.Style.infix, funName, prepend(lexer.alloc, lhs, args), typeArg));
	}();
	ExprAst expr = ExprAst(range(lexer, start), exprKind);
	return parseCalls(lexer, start, expr, argCtx);
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

int symbolPrecedence(Symbol a, bool isAssignment) {
	if (isAssignment) return -4;
	switch (a.value) {
		case symbol!"||".value:
			return -3;
		case symbol!"&&".value:
			return -2;
		case symbol!"??".value:
			return -1;
		case symbol!"..".value:
			return 1;
		case symbol!"~".value:
		case symbol!"~~".value:
			return 2;
		case symbol!"==".value:
		case symbol!"!=".value:
		case symbol!"<".value:
		case symbol!"<=".value:
		case symbol!">".value:
		case symbol!">=".value:
		case symbol!"<=>".value:
			return 3;
		case symbol!"|".value:
			return 4;
		case symbol!"^".value:
			return 5;
		case symbol!"&".value:
			return 6;
		case symbol!"<<".value:
		case symbol!">>".value:
			return 7;
		case symbol!"+".value:
		case symbol!"-".value:
			return 8;
		case symbol!"*".value:
		case symbol!"/".value:
		case symbol!"%".value:
			return 9;
		case symbol!"**".value:
			return 10;
		default:
			// All other names
			return 0;
	}
}

ExprAst tryParseDotsAndSubscripts(ref Lexer lexer, ExprAst initial) {
	Pos start = curPos(lexer);
	if (tryTakeToken(lexer, Token.dot)) {
		NameAndRange name = takeNameAndRange(lexer);
		Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
		CallAst call = CallAst(CallAst.Style.dot, name, newArray!ExprAst(lexer.alloc, [initial]), typeArg);
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
				CallAst.Style.suffixBang, NameAndRange(start, symbol!"force"), newArray(lexer.alloc, [initial])))));
	} else
		return initial;
}

ExprAst parseSubscript(ref Lexer lexer, ExprAst initial, Pos start) {
	ExprAst arg = () {
		if (tryTakeToken(lexer, Token.bracketRight))
			return ExprAst(
				range(lexer, start),
				ExprAstKind(CallAst(CallAst.Style.emptyParens, NameAndRange(start, symbol!"new"), [])));
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
			NameAndRange(start, symbol!"subscript"),
			newArray!ExprAst(lexer.alloc, [initial, arg])))));
}

ExprAst parseMatch(ref Lexer lexer, Pos start) {
	ExprAst matched = parseExprNoBlock(lexer);
	ArrayBuilder!(MatchAst.CaseAst) cases;
	while (tryTakeNewlineThenAs(lexer)) {
		NameAndRange memberName = takeNameAndRange(lexer);
		Opt!DestructureAst destructure = peekEndOfLine(lexer)
			? none!DestructureAst
			: some(parseDestructureNoRequireParens(lexer));
		ExprAst then = parseIndentedStatements(lexer);
		add(lexer.alloc, cases, MatchAst.CaseAst(memberName, destructure, then));
	}
	return ExprAst(
		range(lexer, start),
		ExprAstKind(allocate(lexer.alloc, MatchAst(matched, finish(lexer.alloc, cases)))));
}

ExprAst parseIf(ref Lexer lexer, Pos start) =>
	parseIfRecur(lexer, start);

ExprAst parseIfRecur(ref Lexer lexer, Pos start) {
	if (lookaheadQuestionEquals(lexer)) {
		DestructureAst lhs = parseDestructureNoRequireParens(lexer);
		takeOrAddDiagExpectedToken(lexer, Token.questionEqual, ParseDiag.Expected.Kind.questionEqual);
		ConditionThenAndElse cte = parseConditionThenAndElse(lexer);
		ExprAstKind kind = ExprAstKind(allocate(lexer.alloc, IfOptionAst(
			lhs,
			cte.condition,
			cte.then,
			cte.else_)));
		return ExprAst(range(lexer, start), kind);
	} else {
		ConditionThenAndElse cte = parseConditionThenAndElse(lexer);
		ExprAstKind kind = ExprAstKind(allocate(lexer.alloc, IfAst(cte.condition, cte.then, cte.else_)));
		return ExprAst(range(lexer, start), kind);
	}
}

struct ConditionThenAndElse {
	ExprAst condition;
	ExprAst then;
	ExprAst else_;
}

ConditionThenAndElse parseConditionThenAndElse(ref Lexer lexer) {
	ExprAst condition = parseExprNoBlock(lexer);
	ExprAst then = parseIndentedStatements(lexer);
	Pos elifStart = curPos(lexer);
	Opt!ElifOrElse elifOrElse = tryTakeNewlineThenElifOrElse(lexer);
	ExprAst else_ = () {
		if (has(elifOrElse)) {
			final switch (force(elifOrElse)) {
				case ElifOrElse.elif:
					return parseIfRecur(lexer, elifStart);
				case ElifOrElse.else_:
					return parseIndentedStatements(lexer);
			}
		} else
			return emptyAst(lexer);
	}();
	return ConditionThenAndElse(condition, then, else_);
}

immutable struct ConditionAndBody {
	ExprAst condition;
	ExprAst body_;
}

ConditionAndBody parseConditionAndBody(ref Lexer lexer) {
	ExprAst cond = parseExprNoBlock(lexer);
	ExprAst body_ = parseIndentedStatements(lexer);
	return ConditionAndBody(cond, body_);
}

ExprAst parseUnless(ref Lexer lexer, Pos start) {
	ConditionAndBody cb = parseConditionAndBody(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, UnlessAst(cb.condition, cb.body_))));
}

ExprAst parseThrow(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseThrowOrTrusted(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.throw_, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, ThrowAst(inner))));

ExprAst parseTrusted(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseThrowOrTrusted(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.trusted, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, TrustedAst(inner))));

ExprAst parseThrowOrTrusted(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind needsBlockKind,
	in ExprAstKind delegate(ExprAst) @safe @nogc pure nothrow cbMakeExpr,
) {
	ExprAst inner = parseExprInlineOrBlock(lexer, start, allowedBlock, needsBlockKind);
	return ExprAst(range(lexer, start), cbMakeExpr(inner));
}

ExprAst parseAssertOrForbid(ref Lexer lexer, Pos start, AllowedBlock allowedBlock, AssertOrForbidKind kind) {
	ExprAst condition = parseExprAndCalls(lexer, ArgCtx(allowedBlock, allowAllCalls));
	if (tryTakeToken(lexer, Token.colon)) {
		ExprAst thrown = parseExprAndCalls(lexer, ArgCtx(allowedBlock, allowAllCalls));
		return ExprAst(range(lexer, start), ExprAstKind(
			allocate(lexer.alloc, AssertOrForbidAst(kind, condition, some(thrown)))));
	} else
		return ExprAst(range(lexer, start), ExprAstKind(
			allocate(lexer.alloc, AssertOrForbidAst(kind, condition, none!ExprAst))));
}

ExprAst parseFor(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseForOrWith(
		lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.for_,
		(DestructureAst param, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, ForAst(param, col, body_, else_))));

ExprAst parseWith(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseForOrWith(
		lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.with_,
		(DestructureAst param, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, WithAst(param, col, body_, else_))));

ExprAst parseForOrWith(
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
		return ExprAst(range(lexer, start), cbMakeExprKind(param, rhs, body_, emptyAst(lexer)));
	} else
		final switch (allowedBlock) {
			case AllowedBlock.no:
				return exprBlockNotAllowed(lexer, start, blockKind);
			case AllowedBlock.yes:
				return takeIndentOrFail_Expr(lexer, () {
					ExprAst body_ = parseStatementsAndDedent(lexer);
					ExprAst else_ = tryTakeNewlineThenElse(lexer) ? parseIndentedStatements(lexer) : emptyAst(lexer);
					return ExprAst(range(lexer, start), cbMakeExprKind(param, rhs, body_, else_));
				});
		}
}

ExprAst parseLoop(ref Lexer lexer, Pos start) {
	ExprAst body_ = parseIndentedStatements(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopAst(body_))));
}

ExprAst parseLoopBreak(ref Lexer lexer, Pos start) {
	ExprAst value = parseArgOrEmpty(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopBreakAst(value))));
}

ExprAst parseLoopUntil(ref Lexer lexer, Pos start) {
	ConditionAndBody cb = parseConditionAndBody(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopUntilAst(cb.condition, cb.body_))));
}

ExprAst parseLoopWhile(ref Lexer lexer, Pos start) {
	ConditionAndBody cb = parseConditionAndBody(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopWhileAst(cb.condition, cb.body_))));
}

ExprAst takeIndentOrFail_Expr(ref Lexer lexer, in ExprAst delegate() @safe @nogc pure nothrow cbIndent) =>
	takeIndentOrFailGeneric(lexer, cbIndent, (in Range range) => bogusExpr(range));

ExprAst parseLambdaWithParenthesizedParameters(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) {
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

ExprAst parseLambdaAfterNameAndArrow(ref Lexer lexer, Pos start, AllowedBlock allowedBlock, Symbol paramName) =>
	parseLambdaAfterArrow(lexer, start, allowedBlock, DestructureAst(
		DestructureAst.Single(NameAndRange(start, paramName), none!Pos, none!(TypeAst*))));

ExprAst parseLambdaAfterArrow(ref Lexer lexer, Pos start, AllowedBlock allowedBlock, DestructureAst parameter) {
	ExprAst body_ = parseExprInlineOrBlock(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.lambda);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LambdaAst(parameter, body_))));
}

ExprAst parseExprInlineOrBlock(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind needsBlockKind,
) {
	bool inLine = peekTokenExpression(lexer);
	return inLine
		? parseExprAndAllCalls(lexer, allowedBlock)
		: ifAllowBlock(lexer, start, allowedBlock, needsBlockKind, () => parseIndentedStatements(lexer));
}

ExprAst skipRestOfLineAndReturnBogusNoDiag(ref Lexer lexer, Pos start) {
	skipUntilNewlineNoDiag(lexer);
	return bogusExpr(rangeForCurToken(lexer, start));
}

ExprAst skipRestOfLineAndReturnBogus(ref Lexer lexer, Pos start, ParseDiag diag) {
	addDiag(lexer, range(lexer, start), diag);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

ExprAst exprBlockNotAllowed(ref Lexer lexer, Pos start, ParseDiag.NeedsBlockCtx.Kind kind) =>
	skipRestOfLineAndReturnBogus(lexer, start, ParseDiag(ParseDiag.NeedsBlockCtx(kind)));

ExprAst ifAllowBlock(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind kind,
	in ExprAst delegate() @safe @nogc pure nothrow cbAllowBlock,
) {
	final switch (allowedBlock) {
		case AllowedBlock.no:
			return exprBlockNotAllowed(lexer, start, kind);
		case AllowedBlock.yes:
			return cbAllowBlock();
	}
}

ExprAst parseExprBeforeCall(ref Lexer lexer, AllowedBlock allowedBlock) {
	Pos start = curPos(lexer);
	if (lookaheadLambda(lexer))
		return parseLambdaWithParenthesizedParameters(lexer, start, allowedBlock);

	ExprAst ifAllowBlock(
		ParseDiag.NeedsBlockCtx.Kind kind,
		in ExprAst delegate() @safe @nogc pure nothrow cbAllowBlock,
	) {
		return .ifAllowBlock(lexer, start, allowedBlock, kind, cbAllowBlock);
	}

	// Don't skip newline tokens
	if (isNewlineToken(getPeekToken(lexer)))
		return badToken(lexer, start, getPeekTokenAndData(lexer));

	TokenAndData token = takeNextToken(lexer);
	switch (token.token) {
		case Token.parenLeft:
			if (tryTakeToken(lexer, Token.parenRight)) {
				ExprAst expr = ExprAst(
					range(lexer, start),
					//TODO: range is wrong..
					ExprAstKind(CallAst(CallAst.Style.emptyParens, NameAndRange(start, symbol!"new"), [])));
				return tryParseDotsAndSubscripts(lexer, expr);
			} else {
				ExprAst inner = parseExprNoBlock(lexer);
				takeOrAddDiagExpectedToken(lexer, Token.parenRight, ParseDiag.Expected.Kind.closingParen);
				ExprAst expr = ExprAst(
					range(lexer, start),
					ExprAstKind(allocate(lexer.alloc, ParenthesizedAst(inner))));
				return tryParseDotsAndSubscripts(lexer, expr);
			}
		case Token.quoteDouble:
		case Token.quoteDouble3:
			QuoteKind quoteKind = token.token == Token.quoteDouble ? QuoteKind.double_ : QuoteKind.double3;
			StringPart part = takeInitialStringPart(lexer, quoteKind);
			ExprAst quoted = () {
				final switch (part.after) {
					case StringPart.After.quote:
						return ExprAst(range(lexer, start), ExprAstKind(LiteralStringAst(part.text)));
					case StringPart.After.lbrace:
						return takeInterpolated(lexer, start, part.text, quoteKind);
				}
			}();
			return tryParseDotsAndSubscripts(lexer, quoted);
		case Token.assert_:
			return parseAssertOrForbid(lexer, start, allowedBlock, AssertOrForbidKind.assert_);
		case Token.bang:
			ExprAst inner = parseExprBeforeCall(lexer, AllowedBlock.no);
			return ExprAst(
				range(lexer, start),
				ExprAstKind(CallAst(
					CallAst.Style.prefixBang,
					NameAndRange(start, symbol!"not"),
					newArray(lexer.alloc, [inner]))));
		case Token.break_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.break_, () => parseLoopBreak(lexer, start));
		case Token.continue_:
			return ExprAst(range(lexer, start), ExprAstKind(LoopContinueAst()));
		case Token.if_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.if_, () => parseIf(lexer, start));
		case Token.for_:
			return parseFor(lexer, start, allowedBlock);
		case Token.forbid:
			return parseAssertOrForbid(lexer, start, allowedBlock, AssertOrForbidKind.forbid);
		case Token.match:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.match, () => parseMatch(lexer, start));
		case Token.name:
			Symbol name = token.asSymbol;
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, name)
				: handleName(lexer, start, NameAndRange(start, name));
		case Token.operator:
			Symbol operator = token.asSymbol;
			if (operator == symbol!"&") {
				ExprAst inner = parseExprBeforeCall(lexer, AllowedBlock.no);
				return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, PtrAst(inner))));
			} else
				return handlePrefixOperator(lexer, allowedBlock, start, operator);
		case Token.literalFloat:
			return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(token.asLiteralFloat())));
		case Token.literalInt:
			return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(token.asLiteralInt())));
		case Token.literalNat:
			return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(token.asLiteralNat())));
		case Token.loop:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.loop, () => parseLoop(lexer, start));
		case Token.throw_:
			return parseThrow(lexer, start, allowedBlock);
		case Token.trusted:
			return parseTrusted(lexer, start, allowedBlock);
		case Token.underscore:
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, symbol!"_")
				: badToken(lexer, start, token);
		case Token.unless:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.unless, () => parseUnless(lexer, start));
		case Token.until:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.until, () => parseLoopUntil(lexer, start));
		case Token.while_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.while_, () => parseLoopWhile(lexer, start));
		case Token.with_:
			return parseWith(lexer, start, allowedBlock);
		default:
			return badToken(lexer, start, token);
	}
}

ExprAst badToken(ref Lexer lexer, Pos start, TokenAndData token) {
	addDiagUnexpectedCurToken(lexer, start, token);
	return skipRestOfLineAndReturnBogusNoDiag(lexer, start);
}

ExprAst handlePrefixOperator(ref Lexer lexer, AllowedBlock allowedBlock, Pos start, Symbol operator) {
	ExprAst arg = parseExprBeforeCall(lexer, allowedBlock);
	return ExprAst(range(lexer, start), ExprAstKind(
		CallAst(CallAst.Style.prefixOperator, NameAndRange(start, operator), newArray(lexer.alloc, [arg]))));
}

ExprAst handleName(ref Lexer lexer, Pos start, NameAndRange name) {
	Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
	return has(typeArg)
		? ExprAst(range(lexer, start), ExprAstKind(CallAst(CallAst.Style.single, name, [], typeArg)))
		: tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(IdentifierAst(name.name))));
}

ExprAst takeInterpolated(ref Lexer lexer, Pos start, string firstText, QuoteKind quoteKind) {
	ArrayBuilder!InterpolatedPart parts;
	if (!isEmpty(firstText))
		add(lexer.alloc, parts, InterpolatedPart(firstText));
	return takeInterpolatedRecur(lexer, start, parts, quoteKind);
}

ExprAst takeInterpolatedRecur(
	ref Lexer lexer,
	Pos start,
	ref ArrayBuilder!InterpolatedPart parts,
	QuoteKind quoteKind,
) {
	ExprAst e = () {
		if (peekToken(lexer, Token.braceRight)) {
			addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.MissingExpression()));
			return bogusExpr(range(lexer, start));
		} else
			return parseExprNoBlock(lexer);
	}();
	add(lexer.alloc, parts, InterpolatedPart(e));
	StringPart part = takeClosingBraceThenStringPart(lexer, quoteKind);
	if (!isEmpty(part.text))
		add(lexer.alloc, parts, InterpolatedPart(part.text));
	final switch (part.after) {
		case StringPart.After.quote:
			return ExprAst(range(lexer, start), ExprAstKind(InterpolatedAst(finish(lexer.alloc, parts))));
		case StringPart.After.lbrace:
			return takeInterpolatedRecur(lexer, start, parts, quoteKind);
	}
}

ExprAst parseExprNoBlock(ref Lexer lexer) =>
	parseExprAndAllCalls(lexer, AllowedBlock.no);

ExprAst parseExprAndAllCalls(ref Lexer lexer, AllowedBlock allowedBlock) =>
	parseExprAndCalls(lexer, ArgCtx(allowedBlock, allowAllCalls()));

ExprAst parseExprAndCalls(ref Lexer lexer, ArgCtx argCtx) {
	Pos start = curPos(lexer);
	ExprAst left = parseExprBeforeCall(lexer, argCtx.allowedBlock);
	return parseCalls(lexer, start, left, argCtx);
}

ExprAst parseExprNoLet(ref Lexer lexer) =>
	parseExprAndAllCalls(lexer, AllowedBlock.yes);

ExprAst parseSingleStatementLine(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!EqualsOrThen et = lookaheadEqualsOrThen(lexer);
	if (has(et))
		return parseEqualsOrThen(lexer, force(et));
	else {
		ExprAst expr = parseExprBeforeCall(lexer, AllowedBlock.yes);
		Pos assignmentPos = curPos(lexer);
		return tryTakeToken(lexer, Token.colonEqual)
			? parseAssignment(lexer, start, expr, assignmentPos)
			: parseCalls(lexer, start, expr, ArgCtx(AllowedBlock.yes, allowAllCalls()));
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
		Pos posForMut = curPos(lexer);
		Opt!Pos mut = tryTakeToken(lexer, Token.mut) ? some(posForMut) : none!Pos;
		Opt!(TypeAst*) type = () {
			switch (getPeekToken(lexer)) {
				case Token.arrowThen:
				case Token.colon:
				case Token.comma:
				case Token.equal:
				case Token.newlineDedent:
				case Token.newlineIndent:
				case Token.newlineSameIndent:
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
		ArrayBuilder!DestructureAst parts;
		add(lexer.alloc, parts, first);
		do {
			add(lexer.alloc, parts, parseDestructureRequireParens(lexer));
		} while (tryTakeToken(lexer, Token.comma));
		return DestructureAst(finish(lexer.alloc, parts));
	} else
		return first;
}

ExprAst parseEqualsOrThen(ref Lexer lexer, EqualsOrThen kind) {
	Pos start = curPos(lexer);
	final switch (kind) {
		case EqualsOrThen.equals:
			DestructureAst left = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.equal, ParseDiag.Expected.Kind.equals);
			ExprAst init = parseExprNoLet(lexer);
			ExprAst then = parseNextLinesOrEmpty(lexer, start);
			return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LetAst(left, init, then))));
		case EqualsOrThen.then:
			DestructureAst param =
				parseForThenOrWithParameter(lexer, Token.arrowThen, ParseDiag.Expected.Kind.then);
			ExprAst future = parseExprNoLet(lexer);
			ExprAst then = parseNextLinesOrEmpty(lexer, start);
			return ExprAst(range(lexer, start), ExprAstKind(
				allocate(lexer.alloc, ThenAst(param, future, then))));
	}
}

ExprAst parseStatements(ref Lexer lexer) {
	Pos start = curPos(lexer);
	return parseStatementsRecur(lexer, start, parseSingleStatementLine(lexer));
}

ExprAst parseStatementsRecur(ref Lexer lexer, Pos start, ExprAst res) {
	if (tryTakeToken(lexer, Token.newlineSameIndent)) {
		ExprAst nextLine = parseSingleStatementLine(lexer);
		return parseStatementsRecur(lexer, start, ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, SeqAst(res, nextLine)))));
	} else
		return res;
}

ExprAst parseIndentedStatements(ref Lexer lexer) =>
	takeIndentOrFail_Expr(lexer, () => parseStatementsAndDedent(lexer));

ExprAst parseStatementsAndDedent(ref Lexer lexer) {
	ExprAst res = parseStatements(lexer);
	takeDedent(lexer);
	return res;
}
