module frontend.parse.parseExpr;

@safe @nogc pure nothrow:

import frontend.parse.lexer :
	addDiag,
	addDiagUnexpectedCurToken,
	curPos,
	ElifOrElseKeyword,
	EqualsOrThen,
	getPeekToken,
	getPeekTokenAndData,
	Lexer,
	lookaheadEqualsOrThen,
	lookaheadLambda,
	lookaheadNameColon,
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
	takeNextTokenMayContinueOntoNextLine,
	Token,
	TokenAndData,
	tryTakeNewlineThenAs,
	tryTakeNewlineThenElifOrElse,
	tryTakeNewlineThenElse;
import frontend.parse.lexToken : isNewlineToken;
import frontend.parse.parseType :
	parseDestructureNoRequireParens, parseDestructureRequireParens, parseTypeForTypedExpr, tryParseTypeArgForExpr;
import frontend.parse.parseUtil :
	peekEndOfLine,
	peekToken,
	takeDedent,
	takeIndentOrFailGeneric,
	takeNameAndRange,
	takeOrAddDiagExpectedToken,
	takeOrAddDiagExpectedTokenAndMayContinueOntoNextLine,
	takeOrAddDiagExpectedTokenAndSkipRestOfLine,
	tryTakeLiteralIntegral,
	tryTakeNameAndRange,
	tryTakeToken,
	tryTakeTokenAndMayContinueOntoNextLine;
import model.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	CallNamedAst,
	CaseAst,
	CaseMemberAst,
	DestructureAst,
	DoAst,
	EmptyAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
	IfAst,
	IfConditionAst,
	InterpolatedAst,
	LambdaAst,
	LetAst,
	LiteralIntegralAndRange,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopWhileOrUntilAst,
	MatchAst,
	MatchElseAst,
	NameAndRange,
	ParenthesizedAst,
	PtrAst,
	SeqAst,
	SharedAst,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	WithAst;
import model.model : AssertOrForbidKind;
import model.parseDiag : ParseDiag;
import util.col.array : emptySmallArray, isEmpty, newSmallArray, only2, SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, arrayBuilderIsEmpty, buildArray, buildSmallArray, Builder, finish;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some, some;
import util.sourceRange : Pos, Range, rangeOfStartAndLength;
import util.symbol : Symbol, symbol;
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

SmallArray!ExprAst parseArgs(ref Lexer lexer, ArgCtx ctx, ExprAst first) =>
	buildSmallArray!ExprAst(lexer.alloc, (scope ref Builder!ExprAst out_) {
		out_ ~= first;
		assert(ctx.allowedCalls.minPrecedenceExclusive >= commaPrecedence);
		if (peekTokenExpression(lexer)) {
			do {
				out_ ~= parseExprAndCalls(lexer, ctx);
			} while (tryTakeTokenAndMayContinueOntoNextLine(lexer, Token.comma));
		}
	});

bool peekTokenExpression(ref Lexer lexer) =>
	isExpressionStartToken(getPeekToken(lexer));

bool isExpressionStartToken(Token a) {
	final switch (a) {
		case Token.alias_:
		case Token.arrowAccess:
		case Token.arrowLambda:
		case Token.arrowThen:
		case Token.as:
		case Token.at:
		case Token.bare:
		case Token.builtin:
		case Token.braceLeft:
		case Token.braceRight:
		case Token.bracketRight:
		case Token.byRef:
		case Token.byVal:
		case Token.colon:
		case Token.colon2:
		case Token.colonEqual:
		case Token.comma:
		case Token.data:
		case Token.dot:
		case Token.dot3:
		case Token.elif:
		case Token.else_:
		case Token.enum_:
		case Token.equal:
		case Token.export_:
		case Token.extern_:
		case Token.EOF:
		case Token.flags:
		case Token.forceCtx:
		case Token.forceShared:
		case Token.function_:
		case Token.global:
		case Token.import_:
		case Token.mut:
		case Token.nameOrOperatorColonEquals:
		case Token.nameOrOperatorEquals:
		case Token.newlineDedent:
		case Token.newlineIndent:
		case Token.newlineSameIndent:
		case Token.nominal:
		case Token.noStd:
		case Token.packed:
		case Token.parenRight:
		case Token.pure_:
		case Token.question:
		case Token.questionEqual:
		case Token.quotedText:
		case Token.record:
		case Token.region:
		case Token.reserved:
		case Token.semicolon:
		case Token.spec:
		case Token.storage:
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
		case Token.do_:
		case Token.forbid:
		case Token.if_:
		case Token.for_:
		case Token.literalFloat:
		case Token.literalIntegral:
		case Token.loop:
		case Token.match:
		case Token.name:
		case Token.operator:
		case Token.parenLeft:
		case Token.quoteDouble:
		case Token.quoteDouble3:
		case Token.shared_:
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

ExprAst parseCalls(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	Pos beforeCall = curPos(lexer);
	return canParseCommaExpr(argCtx) && tryTakeToken(lexer, Token.comma)
		? parseCallsAfterComma(lexer, start, lhs, argCtx)
		: canParseTernaryExpr(argCtx) && tryTakeToken(lexer, Token.question)
		? parseCallsAfterQuestion(lexer, start, lhs, beforeCall, argCtx)
		: parseNamedCalls(lexer, start, lhs, argCtx);
}

ExprAst parseCallsAfterQuestion(ref Lexer lexer, Pos start, ref ExprAst lhs, Pos questionPos, ArgCtx argCtx) {
	ExprAst then = parseExprAndCalls(lexer, argCtx);
	Pos colonPos = curPos(lexer);
	bool hasColon = tryTakeToken(lexer, Token.colon);
	ExprAst else_ = hasColon
		? parseExprAndCalls(lexer, argCtx)
		: emptyAst(lexer);
	return ExprAst(
		range(lexer, start),
		ExprAstKind(IfAst(
			kind: hasColon ? IfAst.Kind.ternaryWithElse : IfAst.Kind.ternaryWithoutElse,
			firstKeywordPos: questionPos,
			secondKeywordPos: colonPos,
			condition: IfConditionAst(allocate(lexer.alloc, lhs)),
			thenElse: allocate!(ExprAst[2])(lexer.alloc, [then, else_]))));
}

bool canParseTernaryExpr(in ArgCtx argCtx) =>
	ternaryPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

bool canParseCommaExpr(in ArgCtx argCtx) =>
	commaPrecedence > argCtx.allowedCalls.minPrecedenceExclusive;

ExprAst parseCallsAfterComma(ref Lexer lexer, Pos start, ref ExprAst lhs, ArgCtx argCtx) {
	SmallArray!ExprAst args = parseArgs(lexer, requirePrecedenceGtComma(argCtx), lhs);
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
	Opt!NameAndPrecedence optName = tryTakeNameAndPrecedence(lexer, argCtx);
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
	SmallArray!ExprAst args = isOperator
		? newSmallArray!ExprAst(lexer.alloc, [lhs, parseExprAndCalls(lexer, innerCtx)])
		: parseArgs(lexer, innerCtx, lhs);
	ExprAstKind exprKind = () {
		if (has(assignment)) {
			final switch (force(assignment)) {
				case AssignmentKind.inPlace:
					return ExprAstKind(CallAst(CallAst.Style.infix, funName, args));
				case AssignmentKind.replace:
					return ExprAstKind(AssignmentCallAst(funName, allocate!(ExprAst[2])(lexer.alloc, only2(args))));
			}
		} else
			return ExprAstKind(CallAst(CallAst.Style.infix, funName, args, typeArg));
	}();
	ExprAst expr = ExprAst(range(lexer, start), exprKind);
	return parseCalls(lexer, start, expr, argCtx);
}

Opt!NameAndPrecedence tryTakeNameAndPrecedence(scope ref Lexer lexer, ArgCtx argCtx) {
	TokenAndData x = getPeekTokenAndData(lexer);
	if (x.isSymbol) {
		int precedence = symbolPrecedence(
			x.asSymbol,
			x.token == Token.nameOrOperatorEquals || x.token == Token.nameOrOperatorColonEquals);
		if (precedence > argCtx.allowedCalls.minPrecedenceExclusive) {
			if (tokenHasContinuation(x.token))
				takeNextTokenMayContinueOntoNextLine(lexer);
			else
				takeNextToken(lexer);
			return some(NameAndPrecedence(x.token, x.asSymbol, precedence));
		} else
			return none!NameAndPrecedence;
	} else
		return none!NameAndPrecedence;
}

bool tokenHasContinuation(Token a) {
	switch (a) {
		case Token.operator:
		case Token.nameOrOperatorColonEquals:
		case Token.nameOrOperatorEquals:
			return true;
		default:
			return false;
	}
}

enum AssignmentKind {
	inPlace, // foo=
	replace, // foo:=
}

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
	Pos start = initial.range.start;
	Pos dotPos = curPos(lexer);
	if (tryTakeToken(lexer, Token.dot)) {
		NameAndRange name = takeNameAndRange(lexer);
		Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
		CallAst call = CallAst(CallAst.Style.dot, name, newSmallArray(lexer.alloc, [initial]), typeArg);
		return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(call)));
	} else if (tryTakeToken(lexer, Token.arrowAccess)) {
		NameAndRange name = takeNameAndRange(lexer);
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(ArrowAccessAst(allocate(lexer.alloc, initial), dotPos, name))));
	} else if (tryTakeToken(lexer, Token.bracketLeft))
		return parseSubscript(lexer, initial, dotPos);
	else if (tryTakeToken(lexer, Token.colon2)) {
		TypeAst type = parseTypeForTypedExpr(lexer);
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(allocate(lexer.alloc, TypedAst(initial, dotPos, type)))));
	} else if (tryTakeToken(lexer, Token.bang)) {
		return tryParseDotsAndSubscripts(lexer, ExprAst(
			range(lexer, start),
			ExprAstKind(CallAst(
				CallAst.Style.suffixBang,
				NameAndRange(dotPos, symbol!"force"),
				newSmallArray(lexer.alloc, [initial])))));
	} else
		return initial;
}

ExprAst parseSubscript(ref Lexer lexer, ExprAst initial, Pos subscriptPos) {
	ExprAst arg = () {
		if (tryTakeToken(lexer, Token.bracketRight))
			return ExprAst(
				range(lexer, subscriptPos),
				ExprAstKind(CallAst(
					CallAst.Style.emptyParens,
					NameAndRange(subscriptPos, symbol!"new"),
					emptySmallArray!ExprAst)));
		else {
			ExprAst res = parseExprNoBlock(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.bracketRight, ParseDiag.Expected.Kind.closingBracket);
			return res;
		}
	}();
	return tryParseDotsAndSubscripts(lexer, ExprAst(
		range(lexer, initial.range.start),
		ExprAstKind(CallAst(
			CallAst.Style.subscript,
			NameAndRange(subscriptPos, symbol!"subscript"),
			newSmallArray(lexer.alloc, [initial, arg])))));
}

ExprAst parseMatch(ref Lexer lexer, Pos start) {
	ExprAst matched = parseExprNoBlock(lexer);
	SmallArray!CaseAst cases = buildSmallArray(lexer.alloc, (scope ref Builder!CaseAst out_) {
		while (true) {
			Opt!Pos asPos = tryTakeNewlineThenAs(lexer);
			if (has(asPos)) {
				CaseMemberAst member = parseCaseMember(lexer);
				ExprAst then = parseIndentedStatements(lexer);
				out_ ~= CaseAst(force(asPos), member, then);
			} else
				break;
		}
	});
	Opt!(MatchElseAst*) else_ = tryParseElse(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(MatchAst(allocate(lexer.alloc, matched), cases, else_)));
}

CaseMemberAst parseCaseMember(ref Lexer lexer) {
	Opt!NameAndRange name = tryTakeNameAndRange(lexer);
	if (has(name)) {
		Opt!DestructureAst destructure = peekEndOfLine(lexer)
			? none!DestructureAst
			: some(parseDestructureNoRequireParens(lexer));
		return CaseMemberAst(CaseMemberAst.Name(force(name), destructure));
	} else {
		Opt!LiteralIntegralAndRange number = tryTakeLiteralIntegral(lexer);
		return has(number) ? CaseMemberAst(force(number)) : parseStringLiteralForMatchCase(lexer);
	}
}

CaseMemberAst parseStringLiteralForMatchCase(ref Lexer lexer) {
	Pos start = curPos(lexer);
	if (takeOrAddDiagExpectedToken(lexer, Token.quoteDouble, ParseDiag.Expected.Kind.matchCase)) {
		StringPart part = takeInitialStringPart(lexer, QuoteKind.quoteDouble);
		final switch (part.after) {
			case StringPart.After.quote:
				break;
			case StringPart.After.lbrace:
				addDiag(lexer, range(lexer, start), ParseDiag(ParseDiag.MatchCaseInterpolated()));
				break;
		}
		return CaseMemberAst(CaseMemberAst.String(range(lexer, start), part.text));
	} else {
		skipUntilNewlineNoDiag(lexer);
		return CaseMemberAst(CaseMemberAst.Bogus());
	}
}

ExprAst parseDo(ref Lexer lexer, Pos start) {
	ExprAst body_ = parseIndentedStatements(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(DoAst(allocate(lexer.alloc, body_))));
}

ExprAst parseIf(ref Lexer lexer, Pos start) =>
	parseIfRecur(lexer, start);

ExprAst parseIfRecur(ref Lexer lexer, Pos start) {
	IfConditionAst condition = () {
		if (lookaheadQuestionEquals(lexer)) {
			DestructureAst lhs = parseDestructureNoRequireParens(lexer);
			Pos questionEqualPos = curPos(lexer);
			takeOrAddDiagExpectedToken(lexer, Token.questionEqual, ParseDiag.Expected.Kind.questionEqual);
			ExprAst option = parseExprNoBlock(lexer);
			return IfConditionAst(allocate(lexer.alloc,
				IfConditionAst.UnpackOption(lhs, questionEqualPos, allocate(lexer.alloc, option))));
		} else
			return IfConditionAst(allocate(lexer.alloc, parseExprNoBlock(lexer)));
	}();

	ExprAst then = parseIndentedStatements(lexer);
	Opt!ElifOrElseKeyword elifOrElse = tryTakeNewlineThenElifOrElse(lexer);

	ExprAst else_ = () {
		if (has(elifOrElse)) {
			final switch (force(elifOrElse).kind) {
				case ElifOrElseKeyword.Kind.elif:
					return parseIfRecur(lexer, force(elifOrElse).pos);
				case ElifOrElseKeyword.Kind.else_:
					return parseIndentedStatements(lexer);
			}
		} else
			return emptyAst(lexer);
	}();

	IfAst.Kind kind = () {
		if (has(elifOrElse)) {
			final switch (force(elifOrElse).kind) {
				case ElifOrElseKeyword.Kind.elif:
					return IfAst.Kind.ifElif;
				case ElifOrElseKeyword.Kind.else_:
					return IfAst.Kind.ifElse;
			}
		} else
			return IfAst.Kind.ifWithoutElse;
	}();

	ExprAstKind exprKind = ExprAstKind(IfAst(
		kind: kind,
		firstKeywordPos: start,
		secondKeywordPos: has(elifOrElse) ? force(elifOrElse).pos : 0,
		condition,
		allocate!(ExprAst[2])(lexer.alloc, [then, else_])));
	return ExprAst(range(lexer, start), exprKind);
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
	ExprAst else_ = ExprAst(rangeOfStartAndLength(start, "unless".length), ExprAstKind(EmptyAst()));
	return ExprAst(range(lexer, start), ExprAstKind(IfAst(
		kind: IfAst.Kind.unless,
		firstKeywordPos: start,
		secondKeywordPos: 0,
		condition: IfConditionAst(allocate(lexer.alloc, cb.condition)),
		thenElse: allocate!(ExprAst[2])(lexer.alloc, [cb.body_, else_]))));
}

ExprAst parseShared(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parsePrefixKeyword(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.shared_, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, SharedAst(inner))));

ExprAst parseThrow(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parsePrefixKeyword(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.throw_, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, ThrowAst(inner))));

ExprAst parseTrusted(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parsePrefixKeyword(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.trusted, (ExprAst inner) =>
		ExprAstKind(allocate(lexer.alloc, TrustedAst(inner))));

ExprAst parsePrefixKeyword(
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
	if (tryTakeTokenAndMayContinueOntoNextLine(lexer, Token.colon)) {
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
		(DestructureAst param, Pos colon, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, ForAst(param, colon, col, body_, else_))));

ExprAst parseWith(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) =>
	parseForOrWith(
		lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.with_,
		(DestructureAst param, Pos colon, ExprAst col, ExprAst body_, ExprAst else_) =>
			ExprAstKind(allocate(lexer.alloc, WithAst(param, colon, col, body_, else_))));

ExprAst parseForOrWith(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	ParseDiag.NeedsBlockCtx.Kind blockKind,
	in ExprAstKind delegate(
		DestructureAst, Pos colon, ExprAst rhs, ExprAst body_, ExprAst else_,
	) @safe @nogc pure nothrow cbMakeExprKind,
) {
	DestructureAndEndTokenPos paramAndColon = parseForThenOrWithParameter(
		lexer, Token.colon, ParseDiag.Expected.Kind.colon);
	DestructureAst param = paramAndColon.destructure;
	Pos colon = paramAndColon.endTokenPos;
	ExprAst rhs = parseExprNoBlock(lexer);
	bool semi = tryTakeToken(lexer, Token.semicolon);
	if (semi) {
		ExprAst body_ = parseExprNoBlock(lexer);
		return ExprAst(range(lexer, start), cbMakeExprKind(param, colon, rhs, body_, emptyAst(lexer)));
	} else
		final switch (allowedBlock) {
			case AllowedBlock.no:
				return exprBlockNotAllowed(lexer, start, blockKind);
			case AllowedBlock.yes:
				return takeIndentOrFail_Expr(lexer, () {
					ExprAst body_ = parseStatementsAndDedent(lexer);
					ExprAst else_ = parseElseOrEmpty(lexer);
					return ExprAst(range(lexer, start), cbMakeExprKind(param, colon, rhs, body_, else_));
				});
		}
}

Opt!(MatchElseAst*) tryParseElse(ref Lexer lexer) {
	Opt!Pos pos = tryTakeNewlineThenElse(lexer);
	return optIf(has(pos), () => allocate(lexer.alloc, MatchElseAst(force(pos), parseIndentedStatements(lexer))));
}

ExprAst parseElseOrEmpty(ref Lexer lexer) =>
	has(tryTakeNewlineThenElse(lexer)) ? parseIndentedStatements(lexer) : emptyAst(lexer);

ExprAst parseLoop(ref Lexer lexer, Pos start) {
	ExprAst body_ = parseIndentedStatements(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopAst(body_))));
}

ExprAst parseLoopBreak(ref Lexer lexer, Pos start) {
	ExprAst value = parseArgOrEmpty(lexer);
	return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LoopBreakAst(value))));
}

ExprAst parseLoopWhileOrUntil(ref Lexer lexer, Pos start, bool isUntil) {
	ConditionAndBody cb = parseConditionAndBody(lexer);
	return ExprAst(
		range(lexer, start),
		ExprAstKind(allocate(lexer.alloc, LoopWhileOrUntilAst(isUntil, cb.condition, cb.body_))));
}

ExprAst takeIndentOrFail_Expr(ref Lexer lexer, in ExprAst delegate() @safe @nogc pure nothrow cbIndent) =>
	takeIndentOrFailGeneric(lexer, cbIndent, (in Range range) => bogusExpr(range));

ExprAst parseLambdaWithParenthesizedParameters(ref Lexer lexer, Pos start, AllowedBlock allowedBlock) {
	DestructureAst parameter = parseDestructureRequireParens(lexer);
	Pos arrowPos = curPos(lexer);
	takeOrAddDiagExpectedToken(lexer, Token.arrowLambda, ParseDiag.Expected.Kind.lambdaArrow);
	return parseLambdaAfterArrow(lexer, start, allowedBlock, parameter, arrowPos);
}

struct DestructureAndEndTokenPos {
	DestructureAst destructure;
	Pos endTokenPos;
}
DestructureAndEndTokenPos parseForThenOrWithParameter(
	ref Lexer lexer,
	Token endToken,
	ParseDiag.Expected.Kind expectedEndToken,
) {
	Pos pos = curPos(lexer);
	if (tryTakeToken(lexer, endToken))
		return DestructureAndEndTokenPos(DestructureAst(DestructureAst.Void(range(lexer, pos))), pos);
	else {
		DestructureAst res = parseDestructureNoRequireParens(lexer);
		Pos endTokenPos = curPos(lexer);
		takeOrAddDiagExpectedTokenAndMayContinueOntoNextLine(lexer, endToken, expectedEndToken);
		return DestructureAndEndTokenPos(res, endTokenPos);
	}
}

ExprAst parseLambdaAfterNameAndArrow(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	Symbol paramName,
	Pos arrowPos,
) =>
	parseLambdaAfterArrow(
		lexer, start, allowedBlock,
		DestructureAst(DestructureAst.Single(NameAndRange(start, paramName), none!Pos, none!(TypeAst*))),
		arrowPos);

ExprAst parseLambdaAfterArrow(
	ref Lexer lexer,
	Pos start,
	AllowedBlock allowedBlock,
	DestructureAst parameter,
	Pos arrowPos,
) {
	ExprAst body_ = parseExprInlineOrBlock(lexer, start, allowedBlock, ParseDiag.NeedsBlockCtx.Kind.lambda);
	return ExprAst(range(lexer, start), ExprAstKind(
		allocate(lexer.alloc, LambdaAst(parameter, some(arrowPos), body_))));
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
				//TODO: range is wrong..
				ExprAst expr = ExprAst(range(lexer, start), ExprAstKind(
					CallAst(CallAst.Style.emptyParens, NameAndRange(start, symbol!"new"), emptySmallArray!ExprAst)));
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
			QuoteKind quoteKind = token.token == Token.quoteDouble ? QuoteKind.quoteDouble : QuoteKind.quoteDouble3;
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
					newSmallArray(lexer.alloc, [inner]))));
		case Token.break_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.break_, () => parseLoopBreak(lexer, start));
		case Token.continue_:
			return ExprAst(range(lexer, start), ExprAstKind(LoopContinueAst()));
		case Token.do_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.do_, () => parseDo(lexer, start));
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
			Pos arrowPos = curPos(lexer);
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, name, arrowPos)
				: handleName(lexer, start, NameAndRange(start, name));
		case Token.operator:
			Symbol operator = token.asSymbol;
			if (operator == symbol!"&") {
				ExprAst inner = parseExprBeforeCall(lexer, AllowedBlock.no);
				return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, PtrAst(inner))));
			} else
				return handlePrefixOperator(lexer, allowedBlock, start, operator);
		case Token.literalFloat:
			return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(token.asLiteralFloat)));
		case Token.literalIntegral:
			return tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(token.asLiteralIntegral)));
		case Token.loop:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.loop, () => parseLoop(lexer, start));
		case Token.shared_:
			return parseShared(lexer, start, allowedBlock);
		case Token.throw_:
			return parseThrow(lexer, start, allowedBlock);
		case Token.trusted:
			return parseTrusted(lexer, start, allowedBlock);
		case Token.underscore:
			Pos arrowPos = curPos(lexer);
			return tryTakeToken(lexer, Token.arrowLambda)
				? parseLambdaAfterNameAndArrow(lexer, start, allowedBlock, symbol!"_", arrowPos)
				: badToken(lexer, start, token);
		case Token.unless:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.unless, () => parseUnless(lexer, start));
		case Token.until:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.until, () =>
				parseLoopWhileOrUntil(lexer, start, isUntil: true));
		case Token.while_:
			return ifAllowBlock(ParseDiag.NeedsBlockCtx.Kind.while_, () =>
				parseLoopWhileOrUntil(lexer, start, isUntil: false));
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
		CallAst(CallAst.Style.prefixOperator, NameAndRange(start, operator), newSmallArray(lexer.alloc, [arg]))));
}

ExprAst handleName(ref Lexer lexer, Pos start, NameAndRange name) {
	Opt!(TypeAst*) typeArg = tryParseTypeArgForExpr(lexer);
	return has(typeArg)
		? ExprAst(range(lexer, start), ExprAstKind(
			CallAst(CallAst.Style.single, name, emptySmallArray!ExprAst, typeArg)))
		: tryParseDotsAndSubscripts(lexer, ExprAst(range(lexer, start), ExprAstKind(IdentifierAst(name.name))));
}

ExprAst takeInterpolated(ref Lexer lexer, Pos start, string firstText, QuoteKind quoteKind) {
	ExprAst[] parts = buildArray!ExprAst(lexer.alloc, (scope ref Builder!ExprAst res) {
		if (!isEmpty(firstText))
			res ~= ExprAst(range(lexer, start), ExprAstKind(LiteralStringAst(firstText)));
		while (true) {
			res ~= () {
				if (peekToken(lexer, Token.braceRight)) {
					Pos pos = curPos(lexer);
					Range range = Range(pos - 1, pos + 1);
					addDiag(lexer, range, ParseDiag(ParseDiag.MissingExpression()));
					return bogusExpr(range);
				} else
					return parseExprNoBlock(lexer);
			}();
			Pos stringStart = curPos(lexer);
			StringPart part = takeClosingBraceThenStringPart(lexer, quoteKind);
			if (!isEmpty(part.text))
				res ~= ExprAst(range(lexer, stringStart), ExprAstKind(LiteralStringAst(part.text)));
			final switch (part.after) {
				case StringPart.After.quote:
					return;
				case StringPart.After.lbrace:
					continue;
			}
		}
	});
	return ExprAst(range(lexer, start), ExprAstKind(InterpolatedAst(parts)));
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

public ExprAst parseSingleStatementLine(ref Lexer lexer) {
	Pos start = curPos(lexer);
	Opt!EqualsOrThen et = lookaheadEqualsOrThen(lexer);
	if (has(et))
		return parseEqualsOrThen(lexer, force(et));
	else if (lookaheadNameColon(lexer))
		return parseNamedCall(lexer, start);
	else {
		ExprAst expr = parseExprBeforeCall(lexer, AllowedBlock.yes);
		Pos assignmentPos = curPos(lexer);
		return tryTakeTokenAndMayContinueOntoNextLine(lexer, Token.colonEqual)
			? parseAssignment(lexer, start, expr, assignmentPos)
			: parseCalls(lexer, start, expr, ArgCtx(AllowedBlock.yes, allowAllCalls()));
	}
}

ExprAst parseNamedCall(ref Lexer lexer, Pos start) {
	ArrayBuilder!NameAndRange names;
	ArrayBuilder!ExprAst values;
	do {
		NameAndRange name = takeNameAndRange(lexer);
		if (takeOrAddDiagExpectedTokenAndSkipRestOfLine(lexer, Token.colon, ParseDiag.Expected.Kind.namedArgument)) {
			add(lexer.alloc, names, name);
			add(lexer.alloc, values, parseExprNoLet(lexer));
		}
	} while (tryTakeToken(lexer, Token.newlineSameIndent));
	return arrayBuilderIsEmpty(names)
		? ExprAst(range(lexer, start), ExprAstKind(BogusAst()))
		: ExprAst(range(lexer, start), ExprAstKind(
			CallNamedAst(finish(lexer.alloc, names), finish(lexer.alloc, values))));
}

ExprAst parseEqualsOrThen(ref Lexer lexer, EqualsOrThen kind) {
	Pos start = curPos(lexer);
	final switch (kind) {
		case EqualsOrThen.equals:
			DestructureAst left = parseDestructureNoRequireParens(lexer);
			takeOrAddDiagExpectedTokenAndMayContinueOntoNextLine(lexer, Token.equal, ParseDiag.Expected.Kind.equals);
			ExprAst init = parseExprNoLet(lexer);
			ExprAst then = parseNextLinesOrEmpty(lexer, start);
			return ExprAst(range(lexer, start), ExprAstKind(allocate(lexer.alloc, LetAst(left, init, then))));
		case EqualsOrThen.then:
			DestructureAndEndTokenPos param =
				parseForThenOrWithParameter(lexer, Token.arrowThen, ParseDiag.Expected.Kind.then);
			ExprAst future = parseExprNoLet(lexer);
			ExprAst then = parseNextLinesOrEmpty(lexer, start);
			return ExprAst(range(lexer, start), ExprAstKind(
				allocate(lexer.alloc, ThenAst(param.destructure, param.endTokenPos, future, then))));
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
