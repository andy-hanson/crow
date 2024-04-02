module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates : eachFunInScope, funsInScope;
import frontend.check.checkCall.checkCall :
	checkCall,
	checkCallArgAnd2Lambdas,
	checkCallArgAndLambda,
	checkCallIdentifier,
	checkCallNamed,
	checkCallSpecial,
	checkCallSpecialCb1,
	checkCallSpecialCbN;
import frontend.check.checkCall.checkCallSpecs :
	checkSpecSingleSigIgnoreParents2, isPurityAlwaysCompatibleConsideringSpecs, isShared;
import frontend.check.checkCtx : CheckCtx, CommonModule, markUsed;
import frontend.check.checkStructBodies : checkLiteralIntegral;
import frontend.check.exprCtx :
	addDiag2,
	checkCanDoUnsafe,
	ClosureFieldBuilder,
	ExprCtx,
	LambdaInfo,
	LocalAccessKind,
	LocalNode,
	LocalsInfo,
	markIsUsedSetOnStack,
	typeFromAst2,
	typeWithContainer,
	withTrusted;
import frontend.check.inferringType :
	bogus,
	check,
	Expected,
	ExpectedLambdaType,
	ExprAndOptionType,
	findExpectedStructForLiteral,
	getExpectedForDiag,
	getExpectedLambda,
	isPurelyInferring,
	LoopInfo,
	Pair,
	tryGetNonInferringType,
	tryGetLoop,
	TypeContext,
	withCopyWithNewExpectedType,
	withExpect,
	withExpectAndInfer,
	withExpectLoop,
	withExpectOption,
	withInfer;
import frontend.check.instantiate : instantiateFun, instantiateSpec, instantiateStructNeverDelay, noDelayStructInsts;
import frontend.check.maps : FunsMap, SpecsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst :
	checkDestructure, DestructureKind, getSpecFromCommonModule, makeTupleType, typeFromDestructure;
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
	ConditionAst,
	DestructureAst,
	DoAst,
	EmptyAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
	IfAst,
	InterpolatedAst,
	keywordRange,
	LambdaAst,
	LetAst,
	LiteralFloatAst,
	LiteralIntegral,
	LiteralIntegralAndRange,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopWhileOrUntilAst,
	MatchAst,
	ParenthesizedAst,
	PtrAst,
	SeqAst,
	SharedAst,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypedAst,
	WithAst;
import model.constant : Constant;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinFun,
	BuiltinUnary,
	Called,
	CalledDecl,
	CalledSpecSig,
	CallExpr,
	CharType,
	ClosureGetExpr,
	ClosureRef,
	ClosureSetExpr,
	CommonTypes,
	Condition,
	Destructure,
	emptySpecImpls,
	emptySpecs,
	emptyTypeArgs,
	emptyTypeParams,
	EnumOrFlagsMember,
	Expr,
	ExprAndType,
	ExprKind,
	FloatType,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	FunPointerExpr,
	IfExpr,
	IntegralType,
	IntegralTypes,
	isDefinitelyByRef,
	isSigned,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	Local,
	LocalGetExpr,
	localMustHaveNameRange,
	LocalSetExpr,
	LocalMutability,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopWhileOrUntilExpr,
	MatchEnumExpr,
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	Mutability,
	PtrToFieldExpr,
	PtrToLocalExpr,
	Purity,
	purityRange,
	SeqExpr,
	SpecDecl,
	Specs,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	ThrowExpr,
	TrustedExpr,
	toMutability,
	Type,
	TypedExpr,
	TypeParams,
	UnionMember,
	VariableRef;
import util.alloc.stackAlloc : MaxStackArray, withMaxStackArray, withStackArray;
import util.col.array :
	arrayOfSingle,
	contains,
	every,
	exists,
	indexOf,
	isEmpty,
	map,
	mapOpPointers,
	mustHaveIndexOfPointer,
	only,
	PtrAndSmallNumber,
	small,
	SmallArray,
	zipPtrFirst;
import util.col.arrayBuilder : buildArray, Builder;
import util.col.enumMap : EnumMap, makeEnumMap;
import util.col.exactSizeArrayBuilder : ExactSizeArrayBuilder, newExactSizeArrayBuilder, smallFinish;
import util.col.tempSet : TempSet, tryAdd, withTempSet;
import util.conv : safeToUshort;
import util.integralValues : IntegralValue;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optIf, optOrDefault, someMut, some;
import util.sourceRange : Range;
import util.string : smallString;
import util.symbol : prependSet, prependSetDeref, stringOfSymbol, Symbol, symbol;
import util.unicode : decodeAsSingleUnicodeChar;
import util.union_ : Union;
import util.util : castImmutable, castNonScope_ref, ptrTrustMe;

Expr checkFunctionBody(
	ref CheckCtx checkCtx,
	in StructsAndAliasesMap structsAndAliasesMap,
	in CommonTypes commonTypes,
	in SpecsMap specsMap,
	in FunsMap funsMap,
	TypeContainer typeContainer,
	Type returnType,
	TypeParams typeParams,
	Destructure[] params,
	in Specs specs,
	in FunFlags flags,
	ExprAst* ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesMap,
		specsMap,
		funsMap,
		ptrTrustMe(commonTypes),
		typeContainer,
		specs,
		typeParams,
		flags);
	Expr res = checkWithParamDestructures(
		castNonScope_ref(exprCtx), ast, params,
		(ref LocalsInfo innerLocals) =>
			checkAndExpect(castNonScope_ref(exprCtx), innerLocals, ast, returnType));
	return res;
}

immutable struct TestBody {
	Expr body_;
	Test.BodyType type;
}

TestBody checkTestBody(
	ref CheckCtx checkCtx,
	in StructsAndAliasesMap structsAndAliasesMap,
	in CommonTypes commonTypes,
	in SpecsMap specsMap,
	in FunsMap funsMap,
	TypeContainer typeContainer,
	FunFlags flags,
	ExprAst* ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesMap,
		specsMap,
		funsMap,
		ptrTrustMe(commonTypes),
		typeContainer,
		emptySpecs,
		emptyTypeParams,
		flags);
	LocalsInfo locals = LocalsInfo(0, noneMut!(LambdaInfo*), noneMut!(LocalNode*));
	ExprAndType body_ = withExpectAndInfer(
		[Type(commonTypes.void_), Type(commonTypes.voidFuture)],
		(ref Expected expected) =>
			checkExpr(castNonScope_ref(exprCtx), locals, ast, expected));
	Test.BodyType bodyType = body_.type == Type(commonTypes.void_)
		? Test.BodyType.void_
		: body_.type == Type(commonTypes.voidFuture)
		? Test.BodyType.voidFuture
		: Test.bodyType.bogus;
	return TestBody(castNonScope_ref(body_).expr, bodyType);
}

Expr checkExpr(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, ref Expected expected) =>
	ast.kind.matchWithPointers!Expr(
		(ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, ast, a, expected),
		(AssertOrForbidAst a) =>
			checkAssertOrForbid(ctx, locals, ast, a, expected),
		(AssignmentAst* a) =>
			checkAssignment(ctx, locals, ast, a.left, a.keywordRange, &a.right, expected),
		(AssignmentCallAst a) =>
			checkAssignmentCall(ctx, locals, ast, a, expected),
		(BogusAst _) =>
			bogus(expected, ast),
		(CallAst a) =>
			checkCall(ctx, locals, ast, a, expected),
		(CallNamedAst a) =>
			checkCallNamed(ctx, locals, ast, a, expected),
		(DoAst a) =>
			checkExpr(ctx, locals, a.body_, expected),
		(EmptyAst a) =>
			checkEmptyNew(ctx, locals, ast, ast.range, expected),
		(ForAst* a) =>
			checkFor(ctx, locals, ast, a, expected),
		(IdentifierAst a) =>
			checkIdentifier(ctx, locals, ast, a, expected),
		(IfAst a) =>
			checkIf(ctx, locals, ast, a, expected),
		(InterpolatedAst a) =>
			checkInterpolated(ctx, locals, ast, a, expected),
		(LambdaAst* a) =>
			checkLambda(ctx, locals, ast, a.param, &a.body_, expected),
		(LetAst* a) =>
			checkLet(ctx, locals, ast, a, expected),
		(LiteralFloatAst a) =>
			checkLiteralFloat(ctx, ast, a, expected),
		(LiteralIntegral a) =>
			checkLiteralIntegral(ctx, ast, a, expected),
		(LiteralStringAst a) =>
			checkLiteralString(ctx, ast, a.value, expected),
		(LoopAst* a) =>
			checkLoop(ctx, locals, ast, a, expected),
		(LoopBreakAst* a) =>
			checkLoopBreak(ctx, locals, ast, a, expected),
		(LoopContinueAst a) =>
			checkLoopContinue(ctx, locals, ast, a, expected),
		(LoopWhileOrUntilAst* a) =>
			checkLoopWhileOrUntil(ctx, locals, ast, a, expected),
		(MatchAst a) =>
			checkMatch(ctx, locals, ast, a, expected),
		(ParenthesizedAst* a) =>
			checkExpr(ctx, locals, &a.inner, expected),
		(PtrAst* a) =>
			checkPointer(ctx, locals, ast, a, expected),
		(SeqAst* a) =>
			checkSeq(ctx, locals, ast, a, expected),
		(SharedAst* a) =>
			checkShared(ctx, locals, ast, a, expected),
		(ThenAst* a) =>
			checkThen(ctx, locals, ast, a, expected),
		(ThrowAst* a) =>
			checkThrow(ctx, locals, ast, a, expected),
		(TrustedAst* a) =>
			checkTrusted(ctx, locals, ast, a, expected),
		(TypedAst* a) =>
			checkTyped(ctx, locals, ast, a, expected),
		(WithAst* a) =>
			checkWith(ctx, locals, ast, a, expected));

private:

Expr checkWithParamDestructures(
	ref ExprCtx ctx,
	ExprAst* ast,
	Destructure[] params,
	in Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	LocalsInfo locals = LocalsInfo(0, noneMut!(LambdaInfo*), noneMut!(LocalNode*));
	Opt!Expr res = checkWithParamDestructuresRecur(ctx, locals, params, (ref LocalsInfo innerLocals) =>
		some(cb(innerLocals)));
	return has(res) ? force(res) : Expr(ast, ExprKind(BogusExpr()));
}
Opt!Expr checkWithParamDestructuresRecur(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Destructure[] params,
	in Opt!Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) =>
	isEmpty(params)
		? cb(locals)
		: checkWithDestructure(ctx, locals, params[0], (ref LocalsInfo innerLocals) =>
			checkWithParamDestructuresRecur(ctx, innerLocals, params[1 .. $], cb));

ExprAndType checkAndInfer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	withInfer((ref Expected e) =>
		checkExpr(ctx, locals, ast, e));

ExprAndType checkAndExpectOrInfer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, Opt!Type optExpected) =>
	has(optExpected)
		? ExprAndType(checkAndExpect(ctx, locals, ast, force(optExpected)), force(optExpected))
		: checkAndInfer(ctx, locals, ast);

Expr checkAndExpect(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, Type expected) =>
	withExpect(expected, (ref Expected e) =>
		checkExpr(ctx, locals, ast, e));

Type voidType(ref const ExprCtx ctx) =>
	Type(ctx.commonTypes.void_);

Expr checkArrowAccess(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref ArrowAccessAst ast,
	ref Expected expected,
) =>
	checkCallSpecialCb1(
		ctx, locals, source, ast.arrowRange, ast.name.name, expected,
		(ref Expected argExpected) =>
			checkCallSpecial(ctx, locals, source, ast.arrowRange, symbol!"*", arrayOfSingle(ast.left), argExpected));

Expr checkIf(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	IfAst ast,
	ref Expected expected,
) {
	if (isThrow(ast.firstBranch) || (isThrow(ast.secondBranch) && ast.kind != IfAst.Kind.ifElif))
		addDiag2(ctx, ast.firstKeywordRange, Diag(Diag.IfThrow()));
	Condition condition = checkCondition(ctx, locals, source, ast.condition);
	Opt!Destructure destructure = optDestructure(condition);
	bool isNegated = ast.isConditionNegated;
	Range emptyNewRange = ast.firstKeywordRange;
	Expr firstBranch = checkExprWithOptDestructureOrEmptyNew(
		ctx, locals, source, isNegated ? none!Destructure : destructure, ast.firstBranch, emptyNewRange, expected);
	Expr secondBranch = checkExprWithOptDestructureOrEmptyNew(
		ctx, locals, source, isNegated ? destructure : none!Destructure, ast.secondBranch, emptyNewRange, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, IfExpr(
		condition, isNegated ? secondBranch : firstBranch, isNegated ? firstBranch : secondBranch))));
}
bool isThrow(Opt!(ExprAst*) a) =>
	has(a) && force(a).kind.isA!(ThrowAst*);

Opt!Destructure optDestructure(Condition a) =>
	a.match!(Opt!Destructure)(
		(ref Expr _) =>
			none!Destructure,
		(ref Condition.UnpackOption x) =>
			some(x.destructure));

Condition checkCondition(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ConditionAst ast) =>
	ast.matchWithPointers!Condition(
		(ExprAst* x) =>
			Condition(allocate(ctx.alloc, checkAndExpect(ctx, locals, x, Type(ctx.commonTypes.bool_)))),
		(ConditionAst.UnpackOption* x) =>
			Condition(allocate(ctx.alloc, checkUnpackOption(ctx, locals, source, x))));
Condition.UnpackOption checkUnpackOption(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ConditionAst.UnpackOption* condAst,
) {
	ExprAndOptionType res = withExpectOption(ctx.instantiateCtx, ctx.commonTypes, (ref Expected expected) =>
		checkExpr(ctx, locals, condAst.option, expected));
	return Condition.UnpackOption(
		checkDestructure2(ctx, condAst.destructure, res.nonOptionType, DestructureKind.local),
		res.option);
}

Expr checkThrow(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ThrowAst* ast, ref Expected expected) {
	if (isPurelyInferring(expected)) {
		addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, source);
	} else
		return Expr(source, ExprKind(allocate(ctx.alloc, ThrowExpr(
			checkAndExpect(ctx, locals, &ast.thrown, Type(ctx.commonTypes.string_))))));
}

Expr checkTrusted(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, TrustedAst* ast, ref Expected expected) {
	Expr inner = withTrusted!Expr(ctx, source, () => checkExpr(ctx, locals, &ast.inner, expected));
	return Expr(source, ExprKind(allocate(ctx.alloc, TrustedExpr(inner))));
}

Expr checkAssertOrForbid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	AssertOrForbidAst ast,
	ref Expected expected,
) {
	Condition condition = checkCondition(ctx, locals, source, ast.condition);
	Opt!Destructure destructure = optDestructure(condition);
	return Expr(source, ExprKind(allocate(ctx.alloc, AssertOrForbidExpr(
		isForbid: ast.isForbid,
		condition: condition,
		thrown: optIf(has(ast.thrown), () {
			ExprAst* thrownAst = &force(ast.thrown).expr;
			if (thrownAst.kind.isA!(ThrowAst*))
				addDiag2(ctx, thrownAst.kind.as!(ThrowAst*).keywordRange(thrownAst), Diag(
					Diag.AssertOrForbidMessageIsThrow()));
			return allocate(ctx.alloc, withExpect(Type(ctx.commonTypes.string_), (ref Expected expectString) =>
				checkExprWithOptDestructure(
					ctx, locals, ast.isForbid ? destructure : none!Destructure, thrownAst, expectString)));
		}),
		after: checkExprWithOptDestructure(
			ctx, locals, ast.isForbid ? none!Destructure : destructure, ast.after, expected)))));
}

Expr checkAssignment(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref ExprAst left,
	Range keywordRange,
	ExprAst* right,
	ref Expected expected,
) {
	if (left.kind.isA!IdentifierAst)
		return checkAssignIdentifier(
			ctx, locals, source, keywordRange, left.kind.as!IdentifierAst.name, right, expected);
	else if (left.kind.isA!CallAst) {
		CallAst leftCall = left.kind.as!CallAst;
		Opt!Symbol name = () {
			switch (leftCall.style) {
				case CallAst.Style.dot:
					return some(prependSet(leftCall.funName.name));
				case CallAst.Style.prefixOperator:
					return leftCall.funName.name == symbol!"*" ? some(symbol!"set-deref") : none!Symbol;
				case CallAst.Style.subscript:
					return some(symbol!"set-subscript");
				default:
					return none!Symbol;
			}
		}();
		if (has(name))
			return checkCallSpecialCbN(
				ctx, locals, source, keywordRange, force(name), expected, leftCall.args.length + 1,
				(size_t i, ref Expected argExpected) =>
					checkExpr(ctx, locals, i == leftCall.args.length ? right : &leftCall.args[i], argExpected));
		else {
			addDiag2(ctx, source, Diag(Diag.AssignmentNotAllowed()));
			return bogus(expected, source);
		}
	} else if (left.kind.isA!ArrowAccessAst) {
		ArrowAccessAst leftArrow = left.kind.as!ArrowAccessAst;
		return checkCallSpecial(
			ctx, locals, source, keywordRange,
			prependSetDeref(leftArrow.name.name),
			[*leftArrow.left, *right],
			expected);
	} else {
		addDiag2(ctx, source, Diag(Diag.AssignmentNotAllowed()));
		return bogus(expected, source);
	}
}

Expr checkAssignmentCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref AssignmentCallAst ast,
	ref Expected expected,
) {
	//TODO:NO ALLOC
	ExprAst* call = allocate(ctx.alloc, ExprAst(
		source.range,
		ExprAstKind(CallAst(CallAst.style.infix, ast.funName, small!ExprAst(*ast.leftAndRight)))));
	return checkAssignment(ctx, locals, source, ast.left, ast.keywordRange, call, expected);
}

Expr checkEmptyNew(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, in Range range, ref Expected expected) =>
	checkCallSpecial(ctx, locals, source, range, symbol!"new", [], expected);

Expr checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref InterpolatedAst ast,
	ref Expected expected,
) =>
	checkCallSpecialCbN(
		ctx, locals, source, source.range[0 .. 1], symbol!"interpolate", expected, ast.parts.length,
		(size_t i, ref Expected argExpected) {
			ExprAst* part = &ast.parts[i];
			return part.kind.isA!LiteralStringAst
				? checkLiteralString(ctx, part, part.kind.as!LiteralStringAst.value, argExpected)
				: checkCallSpecial(ctx, locals, source, part.range, symbol!"to", arrayOfSingle(part), argExpected);
		});

struct VariableRefAndType {
	@safe @nogc pure nothrow:

	immutable VariableRef variableRef;
	immutable Mutability mutability;
	EnumMap!(LocalAccessKind, bool)* isUsed; // null for Param
	immutable Type type;

	@trusted void setIsUsed(LocalAccessKind kind) {
		if (isUsed != null)
			(*isUsed)[kind] = true;
	}
}

MutOpt!VariableRefAndType getIdentifierNonCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Opt!(ExprAst*) source, // If missing, no diags
	Symbol name,
	LocalAccessKind accessKind,
) {
	MutOpt!(LocalNode*) fromLocals = has(locals.locals)
		? getIdentifierInLocals(force(locals.locals), name, accessKind)
		: noneMut!(LocalNode*);
	if (has(fromLocals)) {
		LocalNode* node = force(fromLocals);
		node.isUsed[accessKind] = true;
		return someMut(VariableRefAndType(
			VariableRef(node.local),
			toMutability(node.local.mutability),
			&node.isUsed,
			node.local.type));
	} else if (has(locals.lambda))
		return getIdentifierFromLambda(ctx, source, name, *force(locals.lambda), accessKindInClosure(accessKind));
	else
		return noneMut!VariableRefAndType;
}

MutOpt!(LocalNode*) getIdentifierInLocals(LocalNode* node, Symbol name, LocalAccessKind accessKind) {
	return node.local.name == name
		? someMut(node)
		: has(node.prev)
		? getIdentifierInLocals(force(node.prev), name, accessKind)
		: noneMut!(LocalNode*);
}

MutOpt!VariableRefAndType getIdentifierFromLambda(
	ref ExprCtx ctx,
	Opt!(ExprAst*) source,
	Symbol name,
	ref LambdaInfo info,
	LocalAccessKind accessKind,
) {
	foreach (size_t index, ref ClosureFieldBuilder field; info.closureFields.soFar)
		if (field.name == name) {
			field.setIsUsed(accessKind);
			return someMut(VariableRefAndType(
				VariableRef(ClosureRef(PtrAndSmallNumber!LambdaExpr(info.lambda, safeToUshort(index)))),
				field.mutability,
				field.isUsed,
				field.type));
		}

	MutOpt!VariableRefAndType optOuter = getIdentifierNonCall(
		ctx, *info.outer, source, name, accessKind);
	if (has(optOuter)) {
		VariableRefAndType outer = force(optOuter);
		size_t closureFieldIndex = info.closureFields.soFar.length;
		if (has(source))
			checkClosureMutability(ctx, force(source), info.lambda.kind, name, outer.mutability, outer.type);
		info.closureFields ~= ClosureFieldBuilder(name, outer.mutability, outer.isUsed, outer.type, outer.variableRef);
		outer.setIsUsed(accessKind);
		return someMut(VariableRefAndType(
			VariableRef(ClosureRef(PtrAndSmallNumber!LambdaExpr(info.lambda, safeToUshort(closureFieldIndex)))),
			outer.mutability,
			outer.isUsed,
			outer.type));
	} else
		return noneMut!VariableRefAndType;
}

void checkClosureMutability(
	ref ExprCtx ctx,
	ExprAst* source,
	LambdaExpr.Kind lambdaKind,
	Symbol name,
	Mutability mutability,
	Type type,
) {
	Purity expectedPurity = () {
		final switch (lambdaKind) {
			case LambdaExpr.Kind.data:
				return Purity.data;
			case LambdaExpr.Kind.shared_:
				return Purity.shared_;
			case LambdaExpr.Kind.mut:
			case LambdaExpr.Kind.explicitShared:
				return Purity.mut;
		}
	}();
	if (expectedPurity != Purity.mut) {
		if (mutability != Mutability.immut)
			addDiag2(ctx, source.range, Diag(
				Diag.LambdaClosurePurity(lambdaKind, name, Purity.mut, none!TypeWithContainer)));
		else if (!isPurityAlwaysCompatibleConsideringSpecs(ctx.outermostFunSpecs, type, expectedPurity))
			addDiag2(ctx, source.range, Diag(
				Diag.LambdaClosurePurity(
					lambdaKind, name,
					purityRange(type).worstCase,
					some(typeWithContainer(ctx, type)))));
	}
}

LocalAccessKind accessKindInClosure(LocalAccessKind a) {
	final switch (a) {
		case LocalAccessKind.getOnStack:
		case LocalAccessKind.getThroughClosure:
			return LocalAccessKind.getThroughClosure;
		case LocalAccessKind.setOnStack:
		case LocalAccessKind.setThroughClosure:
			return LocalAccessKind.setThroughClosure;
	}
}

bool nameIsParameterOrLocalInScope(ref ExprCtx ctx, ref LocalsInfo locals, Symbol name) =>
	has(getIdentifierNonCall(ctx, locals, none!(ExprAst*), name, LocalAccessKind.getOnStack));

Expr checkIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in IdentifierAst ast,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType res = getIdentifierNonCall(
		ctx, locals, some(source), ast.name, LocalAccessKind.getOnStack);
	return has(res)
		? check(ctx, expected, force(res).type, source, exprKindForVariableRef(force(res).variableRef))
		: checkCallIdentifier(ctx, locals, source, ast.name, expected);
}

ExprKind exprKindForVariableRef(VariableRef a) =>
	a.matchWithPointers!ExprKind(
		(Local* x) =>
			ExprKind(LocalGetExpr(x)),
		(ClosureRef x) =>
			ExprKind(ClosureGetExpr(x)));

Expr checkAssignIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in Range keywordRange,
	in Symbol left,
	ExprAst* right,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType optVar = getVariableRefForSet(ctx, locals, source, left);
	if (has(optVar)) {
		VariableRefAndType var = force(optVar);
		Expr value = checkAndExpect(ctx, locals, right, var.type);
		return var.variableRef.matchWithPointers!Expr(
			(Local* local) =>
				check(ctx, expected, voidType(ctx), source, ExprKind(LocalSetExpr(local, allocate(ctx.alloc, value)))),
			(ClosureRef x) =>
				check(ctx, expected, voidType(ctx), source, ExprKind(ClosureSetExpr(x, allocate(ctx.alloc, value)))));
	} else
		return checkCallSpecial(ctx, locals, source, keywordRange, prependSet(left), [*right], expected);
}

MutOpt!VariableRefAndType getVariableRefForSet(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, Symbol name) {
	MutOpt!VariableRefAndType opVar = getIdentifierNonCall(ctx, locals, some(source), name, LocalAccessKind.setOnStack);
	if (has(opVar)) {
		VariableRefAndType var = force(opVar);
		final switch (var.mutability) {
			case Mutability.immut:
				addDiag2(ctx, source, Diag(Diag.LocalNotMutable(var.variableRef)));
				break;
			case Mutability.mut:
				break;
		}
		return someMut(var);
	} else
		return noneMut!VariableRefAndType;
}

Expr checkLiteralFloat(ref ExprCtx ctx, ExprAst* source, in LiteralFloatAst ast, ref Expected expected) {
	immutable StructInst*[2] allowedTypes = [ctx.commonTypes.float32, ctx.commonTypes.float64];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	return has(opTypeIndex)
		? asFloat(
			ctx, source, floatTypes[force(opTypeIndex)], allowedTypes[force(opTypeIndex)],
			ast.value, ast.overflow, expected)
		: bogus(expected, source);
}

Expr asFloat(
	ref ExprCtx ctx,
	ExprAst* source,
	FloatType floatType,
	StructInst* inst,
	double value,
	bool overflow,
	ref Expected expected,
) {
	if (overflow)
		addDiag2(ctx, source, Diag(Diag.LiteralFloatAccuracy(floatType, value)));
	return check(ctx, expected, Type(inst), source, ExprKind(LiteralExpr(Constant(Constant.Float(value)))));
}

immutable IntegralType[4] natTypes = [IntegralType.nat8, IntegralType.nat16, IntegralType.nat32, IntegralType.nat64];
immutable IntegralType[4] intTypes = [IntegralType.int8, IntegralType.int16, IntegralType.int32, IntegralType.int64];
immutable FloatType[2] floatTypes = [FloatType.float32, FloatType.float64];

Expr checkLiteralIntegral(ref ExprCtx ctx, ExprAst* source, in LiteralIntegral ast, ref Expected expected) {
	IntegralTypes integrals = ctx.commonTypes.integrals;
	immutable StructInst*[10] allowedTypes = [
		integrals.nat8, integrals.nat16, integrals.nat32, integrals.nat64,
		integrals.int8, integrals.int16, integrals.int32, integrals.int64,
		ctx.commonTypes.float32, ctx.commonTypes.float64,
	];
	IntegralType[8] integralTypes;
	integralTypes[0 .. natTypes.length] = natTypes;
	integralTypes[natTypes.length .. integralTypes.length] = intTypes;
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		StructInst* numberType = allowedTypes[typeIndex];
		if (typeIndex < integralTypes.length)
			return check(
				ctx, expected, Type(numberType), source,
				ExprKind(LiteralExpr(Constant(checkLiteralIntegral(
					ctx.checkCtx, integralTypes[typeIndex], LiteralIntegralAndRange(source.range, ast))))));
		else {
			double value = ast.isSigned ? double(ast.value.asSigned) : double(ast.value.asUnsigned);
			return asFloat(
				ctx, source, floatTypes[typeIndex - integralTypes.length], numberType, value, ast.overflow, expected);
		}
	} else
		return bogus(expected, source);
}

Expr checkLiteralString(ref ExprCtx ctx, ExprAst* source, string value, ref Expected expected) {
	immutable StructInst*[9] allowedTypes = [
		ctx.commonTypes.char8,
		ctx.commonTypes.char32,
		ctx.commonTypes.char8Array,
		ctx.commonTypes.char8List,
		ctx.commonTypes.char32Array,
		ctx.commonTypes.char32List,
		ctx.commonTypes.cString,
		ctx.commonTypes.string_,
		ctx.commonTypes.symbol,
	];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	static immutable LiteralStringLikeExpr.Kind[allowedTypes.length] kinds = [
		LiteralStringLikeExpr.Kind.cString, // won't be used
		LiteralStringLikeExpr.Kind.cString, // won't be used
		LiteralStringLikeExpr.Kind.char8Array,
		LiteralStringLikeExpr.Kind.char8List,
		LiteralStringLikeExpr.Kind.char32Array,
		LiteralStringLikeExpr.Kind.char32List,
		LiteralStringLikeExpr.Kind.cString,
		LiteralStringLikeExpr.Kind.string_,
		LiteralStringLikeExpr.Kind.symbol,
	];

	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		ExprKind expr = () {
			if (typeIndex == 0) // char8
				return ExprKind(LiteralExpr(Constant(IntegralValue(char8LiteralValue(ctx, source.range, value)))));
			else if (typeIndex == 1) // CHAR32
				return ExprKind(LiteralExpr(Constant(IntegralValue(char32LiteralValue(ctx, source.range, value)))));
			else {
				string checkNoNul(Diag.StringLiteralInvalid.Reason reason) {
					Opt!size_t index = indexOf(value, '\0');
					if (has(index)) {
						addDiag2(ctx, source.range, Diag(Diag.StringLiteralInvalid(reason)));
						return value[0 .. force(index)];
					} else
						return value;
				}
				LiteralStringLikeExpr.Kind kind = kinds[typeIndex];
				string fixedValue = () {
					final switch (kind) {
						case LiteralStringLikeExpr.Kind.char8Array:
						case LiteralStringLikeExpr.Kind.char8List:
						case LiteralStringLikeExpr.Kind.char32Array:
						case LiteralStringLikeExpr.Kind.char32List:
							return value;
						case LiteralStringLikeExpr.Kind.cString:
							return checkNoNul(Diag.StringLiteralInvalid.Reason.cStringContainsNul);
						case LiteralStringLikeExpr.Kind.string_:
							return checkNoNul(Diag.StringLiteralInvalid.Reason.stringContainsNul);
						case LiteralStringLikeExpr.Kind.symbol:
							return checkNoNul(Diag.StringLiteralInvalid.Reason.symbolContainsNul);
					}
				}();
				return ExprKind(LiteralStringLikeExpr(kind, smallString(fixedValue)));
			}
		}();
		return check(ctx, expected, Type(allowedTypes[typeIndex]), source, expr);
	} else
		return bogus(expected, source);
}

char char8LiteralValue(ref ExprCtx ctx, Range diagRange, string value) {
	if (value.length != 1) {
		addDiag2(ctx, diagRange, Diag(Diag.CharLiteralMustBeOneChar()));
		return 'a';
	} else
		return only(value);
}

dchar char32LiteralValue(ref ExprCtx ctx, Range diagRange, string value) =>
	optOrDefault!dchar(decodeAsSingleUnicodeChar(value), () {
		addDiag2(ctx, diagRange, Diag(Diag.CharLiteralMustBeOneChar()));
		return 'a';
	});

Expr checkExprWithOptDestructure(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Opt!Destructure destructure,
	ExprAst* ast,
	ref Expected expected,
) =>
	has(destructure)
		? checkExprWithDestructure(ctx, locals, force(destructure), ast, expected)
		: checkExpr(ctx, locals, ast, expected);

Expr checkExprWithDestructure(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Destructure destructure,
	ExprAst* ast,
	ref Expected expected,
) =>
	optOrDefault!Expr(
		checkWithDestructure(ctx, locals, destructure, (ref LocalsInfo innerLocals) =>
			some(checkExpr(ctx, innerLocals, ast, expected))),
		() => bogus(expected, ast));

Opt!Expr checkWithDestructure(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref Destructure destructure,
	in Opt!Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) =>
	destructure.matchWithPointers!(Opt!Expr)(
		(Destructure.Ignore*) =>
			cb(locals),
		(Local* x) =>
			checkWithLocal(ctx, locals, x, cb),
		(Destructure.Split* x) =>
			checkWithDestructureParts(ctx, locals, x.parts, cb));
Opt!Expr checkWithDestructureParts(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Destructure[] parts,
	in Opt!Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	switch (parts.length) {
		case 0:
			assert(false);
		case 1:
			return checkWithDestructure(ctx, locals, only(parts), cb);
		default:
			return checkWithDestructure(ctx, locals, parts[0], (ref LocalsInfo innerLocals) =>
				checkWithDestructureParts(ctx, innerLocals, parts[1 .. $], cb));
	}
}

Opt!Expr checkWithLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Local* local,
	in Opt!Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	if (nameIsParameterOrLocalInScope(ctx, locals, local.name))
		addDiag2(ctx, localMustHaveNameRange(*local), Diag(
			Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.name)));

	LocalNode localNode = LocalNode(
		locals.locals,
		makeEnumMap!(LocalAccessKind, bool)((LocalAccessKind _) => false),
		local);
	LocalsInfo newLocals = LocalsInfo(
		locals.countAllAccessibleLocals + 1,
		locals.lambda,
		someMut(ptrTrustMe(localNode)));
	Opt!Expr res = cb(newLocals);
	if (localNode.local.mutability == LocalMutability.mutOnStack &&
		(localNode.isUsed[LocalAccessKind.getThroughClosure] ||
		 localNode.isUsed[LocalAccessKind.setThroughClosure])) {
		//TODO:BETTER
		overwriteMemory(&local.mutability, LocalMutability.mutAllocated);
	}
	addUnusedLocalDiags(ctx, local, localNode);
	return res;
}

void addUnusedLocalDiags(ref ExprCtx ctx, Local* local, scope ref LocalNode node) {
	bool isGot = node.isUsed[LocalAccessKind.getOnStack] || node.isUsed[LocalAccessKind.getThroughClosure];
	bool isSet = node.isUsed[LocalAccessKind.setOnStack] || node.isUsed[LocalAccessKind.setThroughClosure];
	if (!isGot || (!isSet && local.mutability != LocalMutability.immut))
		addDiag2(ctx, localMustHaveNameRange(*local), Diag(
			Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Local(local, isGot, isSet)))));
}

Expr checkPointer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, PtrAst* ast, ref Expected expected) =>
	getExpectedPointee(ctx, expected).match!Expr(
		(ExpectedPointee.None) {
			addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.pointer)));
			return bogus(expected, source);
		},
		(ExpectedPointee.FunPointer) =>
			checkFunPointer(ctx, source, *ast, expected),
		(ExpectedPointee.Pointer x) =>
			checkPointerInner(ctx, locals, source, ast, x.pointer, x.pointee, x.mutability, expected));

immutable struct ExpectedPointee {
	immutable struct None {}
	immutable struct FunPointer {}
	immutable struct Pointer {
		Type pointer;
		Type pointee;
		PointerMutability mutability;
	}
	mixin Union!(None, FunPointer, Pointer);
}
enum PointerMutability { readOnly, writeable }

ExpectedPointee getExpectedPointee(ref ExprCtx ctx, ref const Expected expected) {
	Opt!Type expectedType = tryGetNonInferringType(ctx.instantiateCtx, expected);
	if (has(expectedType) && force(expectedType).isA!(StructInst*)) {
		StructInst* inst = force(expectedType).as!(StructInst*);
		if (inst.decl == ctx.commonTypes.ptrConst)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(inst.typeArgs), PointerMutability.readOnly));
		else if (inst.decl == ctx.commonTypes.ptrMut)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(inst.typeArgs), PointerMutability.writeable));
		else if (inst.decl == ctx.commonTypes.funPtrStruct)
			return ExpectedPointee(ExpectedPointee.FunPointer());
		else
			return ExpectedPointee(ExpectedPointee.None());
	} else
		return ExpectedPointee(ExpectedPointee.None());
}

Expr checkPointerInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	PtrAst* ast,
	Type pointerType,
	Type pointeeType,
	PointerMutability expectedMutability,
	ref Expected expected,
) {
	if (!checkCanDoUnsafe(ctx))
		addDiag2(ctx, source, Diag(Diag.PointerIsUnsafe()));
	Expr inner = checkAndExpect(ctx, locals, &ast.inner, pointeeType);
	if (inner.kind.isA!LocalGetExpr) {
		Local* local = inner.kind.as!LocalGetExpr.local;
		if (local.mutability < expectedMutability)
			addDiag2(ctx, source, Diag(Diag.PointerMutToConst(Diag.PointerMutToConst.Kind.local)));
		if (expectedMutability == PointerMutability.writeable)
			markIsUsedSetOnStack(locals, local);
		return check(ctx, expected, pointerType, source, ExprKind(PtrToLocalExpr(local)));
	} else if (inner.kind.isA!CallExpr)
		return checkPointerOfCall(ctx, source, inner.kind.as!CallExpr, pointerType, expectedMutability, expected);
	else {
		addDiag2(ctx, source, Diag(Diag.PointerUnsupported()));
		return bogus(expected, source);
	}
}

Expr checkPointerOfCall(
	ref ExprCtx ctx,
	ExprAst* source,
	ref CallExpr call,
	Type pointerType,
	PointerMutability expectedMutability,
	ref Expected expected,
) {
	Expr fail(Diag.PointerUnsupported.Reason reason = Diag.PointerUnsupported.Reason.other) {
		addDiag2(ctx, source, Diag(Diag.PointerUnsupported(reason)));
		return bogus(expected, source);
	}

	if (call.called.isA!(FunInst*)) {
		FunInst* getFieldFun = call.called.as!(FunInst*);
		if (getFieldFun.decl.body_.isA!(FunBody.RecordFieldGet)) {
			FunBody.RecordFieldGet rfg = getFieldFun.decl.body_.as!(FunBody.RecordFieldGet);
			Expr target = only(call.args);
			StructInst* recordType = only(getFieldFun.paramTypes).as!(StructInst*);
			PointerMutability fieldMutability =
				has(recordType.decl.body_.as!(StructBody.Record).fields[rfg.fieldIndex].mutability)
					? PointerMutability.writeable
					: PointerMutability.readOnly;
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < expectedMutability)
					addDiag2(ctx, source, Diag(Diag.PointerMutToConst(Diag.PointerMutToConst.Kind.fieldOfByRef)));
				return check(ctx, expected, pointerType, source, ExprKind(allocate(ctx.alloc,
					PtrToFieldExpr(ExprAndType(target, Type(recordType)), rfg.fieldIndex))));
			} else if (target.kind.isA!CallExpr) {
				CallExpr targetCall = target.kind.as!CallExpr;
				Called called = targetCall.called;
				if (called.isA!(FunInst*) && isDerefFunction(ctx, called.as!(FunInst*))) {
					FunInst* derefFun = called.as!(FunInst*);
					Type derefedType = only(derefFun.paramTypes);
					PointerMutability pointerMutability = mutabilityForPtrDecl(ctx, derefedType.as!(StructInst*).decl);
					Expr targetPtr = only(targetCall.args);
					// Ignore fieldMutability -- we'll allow mutating a non-mut field from a mut pointer.
					// But not allow any mutation from a non-mut pointer even for mutable fields.
					if (pointerMutability < expectedMutability) {
						addDiag2(ctx, source, Diag(Diag.PointerMutToConst(Diag.PointerMutToConst.Kind.fieldOfByVal)));
						return bogus(expected, source);
					} else
						return check(ctx, expected, pointerType, source, ExprKind(allocate(ctx.alloc,
							PtrToFieldExpr(ExprAndType(targetPtr, derefedType), rfg.fieldIndex))));
				} else
					return fail();
			} else
				return fail(Diag.PointerUnsupported.Reason.recordNotByRef);
		} else
			return fail();
	} else
		return fail();
}

bool isDerefFunction(ref ExprCtx ctx, FunInst* a) {
	if (a.decl.body_.isA!BuiltinFun) {
		BuiltinFun builtin = a.decl.body_.as!BuiltinFun;
		return builtin.isA!BuiltinUnary && builtin.as!BuiltinUnary == BuiltinUnary.deref;
	} else
		return false;
}

PointerMutability mutabilityForPtrDecl(in ExprCtx ctx, in StructDecl* a) {
	if (a == ctx.commonTypes.ptrConst)
		return PointerMutability.readOnly;
	else {
		assert(a == ctx.commonTypes.ptrMut);
		return PointerMutability.writeable;
	}
}

Expr checkFunPointer(ref ExprCtx ctx, ExprAst* source, in PtrAst ast, ref Expected expected) {
	Opt!(FunDecl*) fun = getFunDeclFromExpr(ctx, ast.inner);
	return has(fun) ? checkFunPointerInner(ctx, source, force(fun), expected) : bogus(expected, source);
}

Opt!(FunDecl*) getFunDeclFromExpr(ref ExprCtx ctx, in ExprAst ast) {
	if (ast.kind.isA!IdentifierAst)
		return funWithName(ctx, ast.range, ast.kind.as!IdentifierAst.name);
	else {
		addDiag2(ctx, ast.range, Diag(Diag.FunPointerExprMustBeName()));
		return none!(FunDecl*);
	}
}

Expr checkFunPointerInner(ref ExprCtx ctx, ExprAst* source, FunDecl* funDecl, ref Expected expected) {
	FunInst* funInst = instantiateFun(ctx.instantiateCtx, funDecl, emptyTypeArgs, emptySpecImpls);
	Type paramType = makeTupleType(ctx.checkCtx, ctx.commonTypes, funInst.paramTypes, () => source.range);
	StructInst* structInst = instantiateStructNeverDelay(
		ctx.instantiateCtx, ctx.commonTypes.funPtrStruct, [funInst.returnType, paramType]);
	return check(ctx, expected, Type(structInst), source, ExprKind(FunPointerExpr(funInst)));
}

Opt!(FunDecl*) funWithName(ref ExprCtx ctx, Range range, Symbol name) {
	MutOpt!(FunDecl*) res = MutOpt!(FunDecl*)();
	MutOpt!(Diag.FunPointerNotSupported.Reason) diag = noneMut!(Diag.FunPointerNotSupported.Reason);
	eachFunInScope(funsInScope(ctx), name, (CalledDecl cd) {
		cd.matchWithPointers!void(
			(FunDecl* x) {
				markUsed(ctx.checkCtx, x);
				if (has(res))
					diag = someMut(Diag.FunPointerNotSupported.Reason.multiple);
				else if (x.isTemplate)
					diag = someMut(Diag.FunPointerNotSupported.Reason.template_);
				res = someMut(x);
			},
			(CalledSpecSig _) {
				diag = someMut(Diag.FunPointerNotSupported.Reason.spec);
			});
	});
	if (has(diag)) {
		addDiag2(ctx, range, Diag(Diag.FunPointerNotSupported(force(diag), name)));
		return none!(FunDecl*);
	} else if (has(res))
		return some(force(res));
	else {
		addDiag2(ctx, range, Diag(Diag.NameNotFound(Diag.NameNotFound.Kind.function_, name)));
		return none!(FunDecl*);
	}
}

Expr checkShared(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, SharedAst* ast, ref Expected expected) {
	void diag(Diag diag) {
		addDiag2(ctx, ast.keywordRange(*source), diag);
	}

	if (!ast.inner.kind.isA!(LambdaAst*)) {
		diag(Diag(Diag.SharedArgIsNotLambda()));
		return bogus(expected, source);
	}
	LambdaAst* inner = ast.inner.kind.as!(LambdaAst*);

	MutOpt!ExpectedLambdaType opEt = getExpectedLambda(ctx, source, typeFromDestructure(ctx, inner.param), expected);
	if (!has(opEt))
		return bogus(expected, source);

	ExpectedLambdaType et = force(opEt);
	if (et.funType.kind != FunKind.shared_) {
		diag(Diag(Diag.SharedNotExpected(Diag.SharedNotExpected.Reason.notShared, getExpectedForDiag(ctx, expected))));
		return bogus(expected, source);
	}

	if (!isFuture(ctx, et.funType.returnType)) {
		diag(Diag(Diag.SharedNotExpected(Diag.SharedNotExpected.Reason.notFuture, getExpectedForDiag(ctx, expected))));
		return bogus(expected, source);
	}

	LambdaAndReturnType res = checkLambdaInner(
		ctx, locals, &ast.inner, inner.param, &inner.body_, expected,
		some(instantiateStructNeverDelay(
			ctx.instantiateCtx, ctx.commonTypes.funStructs[FunKind.mut], et.funType.structInst.typeArgs)),
		et.instantiatedParamType,
		et.funType.returnType,
		et.typeContext,
		et.funType.funStruct,
		LambdaExpr.Kind.explicitShared);

	if (!isShared(ctx.outermostFunSpecs, et.instantiatedParamType))
		diag(Diag(Diag.SharedLambdaTypeIsNotShared(
			Diag.SharedLambdaTypeIsNotShared.Kind.paramType, typeWithContainer(ctx, et.instantiatedParamType))));
	if (!isShared(ctx.outermostFunSpecs, res.returnType))
		diag(Diag(Diag.SharedLambdaTypeIsNotShared(
			Diag.SharedLambdaTypeIsNotShared.Kind.returnType, typeWithContainer(ctx, res.returnType))));

	bool allShared = every!VariableRef(res.expr.kind.as!(LambdaExpr*).closure, (in VariableRef x) =>
		x.mutability == LocalMutability.immut && isShared(ctx.outermostFunSpecs, x.type));
	if (allShared)
		diag(Diag(Diag.SharedLambdaUnused()));
	return res.expr;
}

bool isFuture(in ExprCtx ctx, in Type a) =>
	a.isA!(StructInst*) && a.as!(StructInst*).decl == ctx.commonTypes.future;

Expr checkLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref DestructureAst paramAst,
	ExprAst* bodyAst,
	ref Expected expected,
) {
	MutOpt!ExpectedLambdaType opEt = getExpectedLambda(ctx, source, typeFromDestructure(ctx, paramAst), expected);
	if (!has(opEt))
		return bogus(expected, source);

	ExpectedLambdaType et = force(opEt);
	FunKind kind = et.funType.kind;
	if (kind == FunKind.function_) {
		addDiag2(ctx, source, Diag(Diag.LambdaCantBeFunctionPointer()));
		return bogus(expected, source);
	}
	return checkLambdaInner(
		ctx, locals, source, paramAst, bodyAst, expected, none!(StructInst*),
		et.instantiatedParamType,
		et.funType.returnType,
		et.typeContext,
		et.funType.funStruct,
		toLambdaKind(et.funType.kind)).expr;
}

LambdaExpr.Kind toLambdaKind(FunKind a) {
	final switch (a) {
		case FunKind.data:
			return LambdaExpr.Kind.data;
		case FunKind.shared_:
			return LambdaExpr.Kind.shared_;
		case FunKind.mut:
			return LambdaExpr.Kind.mut;
		case FunKind.function_:
			assert(false);
	}
}

struct LambdaAndReturnType { Expr expr; Type returnType; }
LambdaAndReturnType checkLambdaInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref DestructureAst paramAst,
	ExprAst* bodyAst,
	ref Expected expected,
	Opt!(StructInst*) mutTypeForExplicitShared,
	Type paramType,
	Type nonInstantiatedReturnType,
	TypeContext returnTypeContext,
	StructDecl* funStruct,
	LambdaExpr.Kind kind,
) {
	Destructure param = checkDestructure2(ctx, paramAst, paramType, DestructureKind.param);
	LambdaExpr* lambda = allocate(ctx.alloc, LambdaExpr(kind, param, mutTypeForExplicitShared));
	return withMaxStackArray!(LambdaAndReturnType, ClosureFieldBuilder)(
		locals.countAllAccessibleLocals,
		(scope ref MaxStackArray!ClosureFieldBuilder xs) {
			LambdaInfo lambdaInfo = LambdaInfo(ptrTrustMe(locals), lambda, xs.move);
			// Checking the body of the lambda may fill in candidate type args
			// if the expected return type contains candidate's type params
			LocalsInfo bodyLocals = LocalsInfo(
				locals.countAllAccessibleLocals,
				someMut(ptrTrustMe(lambdaInfo)),
				noneMut!(LocalNode*));
			Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(expected,
				nonInstantiatedReturnType,
				returnTypeContext,
				(ref Expected returnTypeInferrer) =>
					checkExprWithDestructure(ctx, bodyLocals, param, bodyAst, returnTypeInferrer));
			StructInst* instFunStruct = instantiateStructNeverDelay(
				ctx.instantiateCtx, funStruct, [bodyAndType.b, param.type]);
			lambda.fillLate(
				body_: bodyAndType.a,
				closure: small!VariableRef(
					map!(VariableRef, ClosureFieldBuilder)(
						ctx.alloc,
						lambdaInfo.closureFields.finish,
						(ref const ClosureFieldBuilder x) =>
							x.variableRef)),
				returnType: bodyAndType.b);
			return LambdaAndReturnType(
				//TODO: this check should never fail, so could just set inferred directly with no check
				check(ctx, expected, Type(instFunStruct), source, ExprKind(castImmutable(lambda))),
				bodyAndType.b);
		});
}

Opt!Type typeFromDestructure(ref ExprCtx ctx, in DestructureAst ast) =>
	.typeFromDestructure(
		ctx.checkCtx, ctx.commonTypes, ast, ctx.structsAndAliasesMap, ctx.outermostFunTypeParams, noDelayStructInsts);

Destructure checkDestructure2(ref ExprCtx ctx, ref DestructureAst ast, Type type, DestructureKind kind) =>
	.checkDestructure(
		ctx.checkCtx, ctx.commonTypes, ctx.structsAndAliasesMap, ctx.typeContainer, ctx.outermostFunTypeParams,
		noDelayStructInsts, ast, some(type), kind);

Expr checkLet(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, LetAst* ast, ref Expected expected) {
	ExprAndType value = checkAndExpectOrInfer(ctx, locals, &ast.value, typeFromDestructure(ctx, ast.destructure));
	Destructure destructure = checkDestructure2(ctx, ast.destructure, value.type, DestructureKind.local);
	Expr then = checkExprWithDestructure(ctx, locals, destructure, &ast.then, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, LetExpr(destructure, value.expr, then))));
}

Expr checkLoop(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, LoopAst* ast, ref Expected expected) {
	Opt!Type expectedType = tryGetNonInferringType(ctx.instantiateCtx, expected);
	if (has(expectedType)) {
		Type type = force(expectedType);
		LoopExpr* loop = allocate(ctx.alloc, LoopExpr(Expr(source, ExprKind(BogusExpr()))));
		LoopInfo info = LoopInfo(voidType(ctx), castImmutable(loop), type, false);
		Expr body_ = withExpectLoop(info, (ref Expected bodyExpected) =>
			checkExpr(ctx, locals, &ast.body_, castNonScope_ref(bodyExpected)));
		overwriteMemory(&loop.body_, body_);
		if (!info.hasBreak)
			addDiag2(ctx, source, Diag(Diag.LoopWithoutBreak()));
		return Expr(source, ExprKind(castImmutable(loop)));
	} else {
		addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.loop)));
		return bogus(expected, source);
	}
}

Expr checkLoopBreak(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	LoopBreakAst* ast,
	ref Expected expected,
) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (!has(optLoop))
		return checkCallSpecial(
			ctx, locals, source, ast.keywordRange(source), symbol!"loop-break", [ast.value], expected);
	else {
		LoopInfo* loop = force(optLoop);
		loop.hasBreak = true;
		Expr value = checkAndExpect(ctx, locals, &ast.value, loop.type);
		return Expr(
			source,
			ExprKind(allocate(ctx.alloc, LoopBreakExpr(loop.loop, value))));
	}
}

Expr checkLoopContinue(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in LoopContinueAst ast,
	ref Expected expected,
) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	return has(optLoop)
		? Expr(source, ExprKind(LoopContinueExpr(force(optLoop).loop)))
		: checkCallSpecial(ctx, locals, source, ast.keywordRange(source), symbol!"loop-continue", [], expected);
}

Expr checkLoopWhileOrUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	LoopWhileOrUntilAst* ast,
	ref Expected expected,
) {
	bool isUntil = ast.isUntil;
	Condition condition = checkCondition(ctx, locals, source, ast.condition);
	Opt!Destructure destructure = optDestructure(condition);
	return Expr(source, ExprKind(allocate(ctx.alloc, LoopWhileOrUntilExpr(
		isUntil: isUntil,
		condition: condition,
		body_: withExpect(voidType(ctx), (ref Expected bodyExpected) =>
			checkExprWithOptDestructure(
				ctx, locals, isUntil ? none!Destructure : destructure, &ast.body_, bodyExpected)),
		after: checkExprWithOptDestructure(
			ctx, locals, isUntil ? destructure : none!Destructure, &ast.after, expected)))));
}

Expr checkMatch(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref MatchAst ast, ref Expected expected) {
	ExprAndType matched = checkAndInfer(ctx, locals, ast.matched);
	StructInst* inst = matched.type.isA!(StructInst*)
		? matched.type.as!(StructInst*)
		// Use an arbitrary non-matchable inst as default
		: ctx.commonTypes.void_;
	StructDecl* decl = inst.decl;
	StructBody body_ = decl.body_;
	if (body_.isA!(StructBody.Enum*))
		return checkMatchEnum(ctx, locals, source, ast, expected, matched, decl, *body_.as!(StructBody.Enum*));
	else if (body_.isA!(StructBody.Union*))
		return checkMatchUnion(ctx, locals, source, ast, expected, matched, *body_.as!(StructBody.Union*), inst);
	else {
		Opt!CharType charType = optAsCharType(ctx.commonTypes, inst);
		Opt!IntegralType integral = optAsIntegralType(ctx.commonTypes, inst);
		Opt!(LiteralStringLikeExpr.Kind) stringLike = getMatchableStringLike(ctx.commonTypes, inst);
		if (has(charType))
			return checkMatchChar(ctx, locals, source, ast, expected, matched, force(charType));
		else if (has(integral))
			return checkMatchIntegral(ctx, locals, source, ast, expected, matched, force(integral));
		else if (has(stringLike))
			return checkMatchStringLike(ctx, locals, source, ast, expected, matched, force(stringLike));
		else {
			if (!matched.type.isBogus)
				addDiag2(ctx, ast.matched.range, Diag(
					Diag.MatchOnNonEnumOrUnion(typeWithContainer(ctx, matched.type))));
			return bogus(expected, ast.matched);
		}
	}
}

Expr checkMatchEnum(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	StructDecl* matchedEnum,
	in StructBody.Enum body_,
) =>
	checkMatchEnumOrUnion!(MatchEnumExpr.Case)(
		ctx, locals, source, ast, expected, matchedEnum, body_.members, body_.membersByName,
		(size_t memberIndex, EnumOrFlagsMember* member, CaseAst* caseAst, CaseMemberAst.Name* name) {
			if (has(name.destructure))
				addDiag2(ctx, force(name.destructure).range, Diag(
					Diag.MatchCaseNoValueForEnumOrSymbol(some(matchedEnum))));
			return MatchEnumExpr.Case(member, checkExpr(ctx, locals, &caseAst.then, expected));
		},
		(SmallArray!(MatchEnumExpr.Case) cases, Opt!Expr else_) =>
			Expr(source, ExprKind(allocate(ctx.alloc, MatchEnumExpr(matched, cases, else_)))));

Expr checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	in StructBody.Union body_,
	StructInst* matchedUnion,
) =>
	checkMatchEnumOrUnion!(MatchUnionExpr.Case)(
		ctx, locals, source, ast, expected, matchedUnion.decl, body_.members, body_.membersByName,
		(size_t memberIndex, UnionMember* member, CaseAst* caseAst, CaseMemberAst.Name* name) {
			Type memberType = matchedUnion.instantiatedTypes[memberIndex];
			if (has(name.destructure)) {
				Destructure destructure = checkDestructure2(
					ctx, force(name.destructure), memberType, DestructureKind.local);
				return MatchUnionExpr.Case(
					member, destructure, checkExprWithDestructure(ctx, locals, destructure, &caseAst.then, expected));
			} else {
				if (memberType != Type(ctx.commonTypes.void_))
					addDiag2(ctx, name.name.range, Diag(Diag.MatchCaseShouldUseIgnore(member)));
				return MatchUnionExpr.Case(
					member,
					Destructure(allocate(ctx.alloc, Destructure.Ignore(name.name.start, memberType))),
					checkExpr(ctx, locals, &caseAst.then, expected));
			}
		},
		(SmallArray!(MatchUnionExpr.Case) cases, Opt!Expr else_) {
			Opt!(Expr*) elsePtr = optIf(has(else_), () => allocate(ctx.alloc, force(else_)));
			return Expr(source, ExprKind(allocate(ctx.alloc, MatchUnionExpr(matched, cases, elsePtr))));
		});

Opt!CharType optAsCharType(ref CommonTypes commonTypes, in StructInst* inst) =>
	inst == commonTypes.char8
		? some(CharType.char8)
		: inst == commonTypes.char32
		? some(CharType.char32)
		: none!CharType;

Expr checkMatchChar(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	CharType charType,
) {
	SmallArray!(MatchIntegralExpr.Case) cases = withTempSet!(SmallArray!(MatchIntegralExpr.Case), IntegralValue)(
		ast.cases.length, (scope ref TempSet!IntegralValue seen) =>
			mapOpPointers!(MatchIntegralExpr.Case, CaseAst)(ctx.alloc, ast.cases, (CaseAst* caseAst) {
				Opt!string stringValue = stringFromCaseAst(ctx, caseAst.member);
				if (has(stringValue)) {
					IntegralValue value = () {
						final switch (charType) {
							case CharType.char8:
								return IntegralValue(
									char8LiteralValue(ctx, caseAst.member.nameRange, force(stringValue)));
							case CharType.char32:
								return IntegralValue(
									char32LiteralValue(ctx, caseAst.member.nameRange, force(stringValue)));
						}
					}();
					if (tryAdd(seen, value))
						return some(MatchIntegralExpr.Case(value, checkExpr(ctx, locals, &caseAst.then, expected)));
					else {
						addDiag2(ctx, caseAst.member.nameRange, Diag(
							Diag.MatchCaseDuplicate(Diag.MatchCaseDuplicate.Kind(force(stringValue)))));
						return none!(MatchIntegralExpr.Case);
					}
				} else
					return none!(MatchIntegralExpr.Case);
			}));
	Expr else_ = checkMatchElse(ctx, locals, source, ast, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc,
		MatchIntegralExpr(MatchIntegralExpr.Kind(charType), matched, cases, else_))));
}

Opt!(IntegralType) optAsIntegralType(ref CommonTypes commonTypes, in StructInst* inst) {
	foreach (IntegralType x, ref immutable StructInst* y; commonTypes.integrals.map)
		if (y == inst)
			return some(x);
	return none!IntegralType;
}

Expr checkMatchIntegral(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	IntegralType integralType,
) {
	SmallArray!(MatchIntegralExpr.Case) cases = withTempSet!(SmallArray!(MatchIntegralExpr.Case), IntegralValue)(
		ast.cases.length, (scope ref TempSet!IntegralValue seen) =>
			mapOpPointers!(MatchIntegralExpr.Case, CaseAst)(ctx.alloc, ast.cases, (CaseAst* caseAst) {
				Opt!IntegralValue optValue = caseAst.member.match!(Opt!IntegralValue)(
					(CaseMemberAst.Name x) {
						addDiag2(ctx, x.name.range, Diag(Diag.MatchCaseForType(Diag.MatchCaseForType.Kind.numeric)));
						return none!IntegralValue;
					},
					(LiteralIntegralAndRange x) =>
						some(checkLiteralIntegral(ctx.checkCtx, integralType, x)),
					(CaseMemberAst.String x) {
						addDiag2(ctx, x.range, Diag(Diag.MatchCaseForType(Diag.MatchCaseForType.Kind.numeric)));
						return none!IntegralValue;
					},
					(CaseMemberAst.Bogus) =>
						none!IntegralValue);
				if (has(optValue)) {
					IntegralValue value = force(optValue);
					if (tryAdd(seen, value))
						return some(MatchIntegralExpr.Case(value, checkExpr(ctx, locals, &caseAst.then, expected)));
					else {
						addDiag2(ctx, caseAst.member.nameRange, Diag(
							Diag.MatchCaseDuplicate(isSigned(integralType)
								? Diag.MatchCaseDuplicate.Kind(value.asSigned())
								: Diag.MatchCaseDuplicate.Kind(value.asUnsigned()))));
						return none!(MatchIntegralExpr.Case);
					}
				} else
					return none!(MatchIntegralExpr.Case);
			}));
	Expr else_ = checkMatchElse(ctx, locals, source, ast, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc,
		MatchIntegralExpr(MatchIntegralExpr.Kind(integralType), matched, cases, else_))));
}

Opt!(LiteralStringLikeExpr.Kind) getMatchableStringLike(in CommonTypes commonTypes, in StructInst* inst) =>
	inst == commonTypes.symbol ? some(LiteralStringLikeExpr.Kind.symbol) :
	inst == commonTypes.string_ ? some(LiteralStringLikeExpr.Kind.string_) :
	inst == commonTypes.char32Array ? some(LiteralStringLikeExpr.Kind.char32Array) :
	inst == commonTypes.char32List ? some(LiteralStringLikeExpr.Kind.char32List) :
	inst == commonTypes.char8Array ? some(LiteralStringLikeExpr.Kind.char8Array) :
	inst == commonTypes.char8List ? some(LiteralStringLikeExpr.Kind.char8List) :
	none!(LiteralStringLikeExpr.Kind);

Expr checkMatchStringLike(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	LiteralStringLikeExpr.Kind kind,
) {
	Opt!(SpecDecl*) spec = getSpecFromCommonModule(
		ctx.checkCtx, ctx.specsMap, ast.keywordRange(*source), symbol!"equal", CommonModule.compare);
	if (!has(spec))
		return bogus(expected, source);

	Called equals = checkSpecSingleSigIgnoreParents2(
		ctx.checkCtx,
		ctx.funsMap,
		ast.keywordRange(*source),
		ctx.typeContainer,
		ctx.outermostFunSpecs,
		ctx.outermostFunFlags,
		instantiateSpec(ctx.instantiateCtx, force(spec), [matched.type]));
	SmallArray!(MatchStringLikeExpr.Case) cases = withTempSet!(SmallArray!(MatchStringLikeExpr.Case), string)(
		ast.cases.length, (scope ref TempSet!string seen) =>
			mapOpPointers!(MatchStringLikeExpr.Case, CaseAst)(ctx.alloc, ast.cases, (CaseAst* caseAst) {
				Opt!string optValue = stringFromCaseAst(ctx, caseAst.member);
				if (has(optValue)) {
					string value = force(optValue);
					if (tryAdd(seen, value))
						return some(MatchStringLikeExpr.Case(value, checkExpr(ctx, locals, &caseAst.then, expected)));
					else {
						addDiag2(ctx, caseAst.member.nameRange, Diag(
							Diag.MatchCaseDuplicate(Diag.MatchCaseDuplicate.Kind(value))));
						return none!(MatchStringLikeExpr.Case);
					}
				} else
					return none!(MatchStringLikeExpr.Case);
			}));
	Expr else_ = checkMatchElse(ctx, locals, source, ast, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, MatchStringLikeExpr(kind, matched, equals, cases, else_))));
}

Expr checkMatchElse(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref MatchAst ast,
	ref Expected expected,
) =>
	checkExprOrEmptyNew(
		ctx, locals, source,
		optIf(has(ast.else_), () => &force(ast.else_).expr),
		ast.keywordRange(*source),
		expected);

Expr checkExprOrEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* parent,
	Opt!(ExprAst*) ast,
	Range emptyNewRange,
	ref Expected expected,
) =>
	has(ast)
		? checkExpr(ctx, locals, force(ast), expected)
		: checkEmptyNew(ctx, locals, parent, emptyNewRange, expected);

Expr checkExprWithOptDestructureOrEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* parent,
	Opt!Destructure destructure,
	Opt!(ExprAst*) ast,
	Range emptyNewRange,
	ref Expected expected,
) =>
	has(ast)
		? checkExprWithOptDestructure(ctx, locals, destructure, force(ast), expected)
		: checkEmptyNew(ctx, locals, parent, emptyNewRange, expected);

Opt!string stringFromCaseAst(ref ExprCtx ctx, CaseMemberAst ast) =>
	ast.match!(Opt!string)(
		(CaseMemberAst.Name x) {
			if (has(x.destructure))
				addDiag2(ctx, force(x.destructure).range, Diag(
					Diag.MatchCaseNoValueForEnumOrSymbol(none!(StructDecl*))));
			return some(stringOfSymbol(ctx.alloc, x.name.name));
		},
		(LiteralIntegralAndRange x) {
			addDiag2(ctx, x.range, Diag(Diag.MatchCaseForType(Diag.MatchCaseForType.Kind.stringLike)));
			return none!string;
		},
		(CaseMemberAst.String x) =>
			some(x.value),
		(CaseMemberAst.Bogus) =>
			none!string);

Expr checkMatchEnumOrUnion(Case, Member, MembersByName)(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref MatchAst ast,
	ref Expected expected,
	StructDecl* matchedEnumOrUnion,
	Member[] members,
	MembersByName membersByName,
	in Case delegate(size_t, Member*, CaseAst*, CaseMemberAst.Name*) @safe @nogc pure nothrow cbCase,
	in Expr delegate(SmallArray!Case, Opt!Expr) @safe @nogc pure nothrow cbFinish,
) =>
	withStackArray!(Expr, bool)(members.length, (size_t _) => false, (scope bool[] seen) {
		bool hasCaseDiag = false;
		ExactSizeArrayBuilder!Case cases = newExactSizeArrayBuilder!Case(ctx.alloc, ast.cases.length);
		foreach (ref CaseAst caseAst; ast.cases) {
			Opt!(CaseMemberAst.Name*) asName = caseAst.member.isA!(CaseMemberAst.Name)
				? some(&caseAst.member.as!(CaseMemberAst.Name)())
				: none!(CaseMemberAst.Name*);
			Opt!Symbol name = has(asName) ? some(force(asName).name.name) : none!Symbol;
			Opt!(Member*) optMember = has(name) ? membersByName[force(name)] : none!(Member*);
			if (has(optMember)) {
				Member* member = force(optMember);
				size_t index = mustHaveIndexOfPointer(members, member);
				if (seen[index]) {
					hasCaseDiag = true;
					addDiag2(ctx, caseAst.member.nameRange, Diag(
						Diag.MatchCaseDuplicate(Diag.MatchCaseDuplicate.Kind(force(name)))));
				} else {
					seen[index] = true;
					cases ~= cbCase(index, member, &caseAst, force(asName));
				}
			} else {
				hasCaseDiag = true;
				addDiag2(ctx, caseAst.member.nameRange, has(asName)
					? Diag(Diag.MatchCaseNameDoesNotMatch(name, matchedEnumOrUnion))
					: Diag(Diag.MatchCaseForType(Diag.MatchCaseForType.Kind.enumOrUnion)));
			}
		}
		if (hasCaseDiag)
			return bogus(expected, source);
		else
			return cbFinish(smallFinish(cases), () {
				if (every(seen)) {
					if (has(ast.else_))
						addDiag2(ctx, force(ast.else_).keywordRange, Diag(Diag.MatchUnnecessaryElse()));
					return none!Expr;
				} else {
					if (has(ast.else_))
						return some(checkExpr(ctx, locals, &force(ast.else_).expr, expected));
					else {
						immutable Member*[] unhandledCases = buildArray!(immutable Member*)(
							ctx.alloc, (scope ref Builder!(immutable Member*) out_) {
								zipPtrFirst!(Member, bool)(members, seen, (Member* member, ref bool seenIt) {
									if (!seenIt)
										out_ ~= member;
								});
							});
						addDiag2(ctx, ast.keywordRange(*source), Diag(Diag.MatchUnhandledCases(unhandledCases)));
						return some(bogus(expected, source));
					}
				}
			}());
	});

Expr checkSeq(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, SeqAst* ast, ref Expected expected) {
	Expr first = checkAndExpect(ctx, locals, &ast.first, voidType(ctx));
	Expr then = checkExpr(ctx, locals, &ast.then, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, SeqExpr(first, then))));
}

bool hasBreakOrContinue(in ExprAst a) =>
	a.kind.matchIn!bool(
		(in ArrowAccessAst _) =>
			false,
		(in AssertOrForbidAst x) =>
			hasBreakOrContinue(*x.after),
		(in AssignmentAst _) =>
			false,
		(in AssignmentCallAst _) =>
			false,
		(in BogusAst _) =>
			false,
		(in CallAst _) =>
			false,
		(in CallNamedAst _) =>
			false,
		(in DoAst x) =>
			hasBreakOrContinue(*x.body_),
		(in EmptyAst _) =>
			false,
		(in ForAst _) =>
			false,
		(in IdentifierAst _) =>
			false,
		(in IfAst x) =>
			exists!ExprAst(x.allBranches, (in ExprAst y) => hasBreakOrContinue(y)),
		(in InterpolatedAst _) =>
			false,
		(in LambdaAst _) =>
			false,
		(in LetAst x) =>
			hasBreakOrContinue(x.then),
		(in LiteralFloatAst _) =>
			false,
		(in LiteralIntegral _) =>
			false,
		(in LiteralStringAst _) =>
			false,
		(in LoopAst _) =>
			false,
		(in LoopBreakAst _) =>
			true,
		(in LoopContinueAst _) =>
			true,
		(in LoopWhileOrUntilAst x) =>
			hasBreakOrContinue(x.after),
		(in MatchAst x) =>
			exists!(CaseAst)(x.cases, (in CaseAst case_) =>
				hasBreakOrContinue(case_.then)),
		(in ParenthesizedAst _) =>
			false,
		(in PtrAst _) =>
			false,
		(in SeqAst x) =>
			hasBreakOrContinue(x.then),
		(in SharedAst x) =>
			false,
		// TODO: Maybe this should be allowed some day. Not in primitive loop but in for-break.
		(in ThenAst x) =>
			hasBreakOrContinue(x.then),
		(in ThrowAst _) =>
			false,
		(in TrustedAst _) =>
			false,
		(in TypedAst _) =>
			false,
		(in WithAst _) =>
			false);

Expr checkFor(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ForAst* ast, ref Expected expected) {
	Symbol funName = hasBreakOrContinue(ast.body_) ? symbol!"for-break" : symbol!"for-loop";
	Range keywordRange = ast.forKeywordRange(*source);
	return ast.else_.kind.isA!EmptyAst
		? checkCallArgAndLambda(
			ctx, locals, source, keywordRange, funName, &ast.collection, ast.param, &ast.body_, expected)
		: checkCallArgAnd2Lambdas(
			ctx, locals, source, keywordRange, funName, &ast.collection, ast.param, &ast.body_, &ast.else_, expected);
}

Expr checkWith(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, WithAst* ast, ref Expected expected) {
	Range keywordRange = ast.withKeywordRange(*source);
	if (!ast.else_.kind.isA!(EmptyAst))
		addDiag2(ctx, keywordRange, Diag(Diag.WithHasElse()));
	return checkCallArgAndLambda(
		ctx, locals, source, keywordRange, symbol!"with-block", &ast.arg, ast.param, &ast.body_, expected);
}

Expr checkThen(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ThenAst* ast, ref Expected expected) =>
	checkCallArgAndLambda(
		ctx, locals, source, ast.keywordRange, symbol!"then", &ast.futExpr, ast.left, &ast.then, expected);

Expr checkTyped(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, TypedAst* ast, ref Expected expected) {
	Type type = typeFromAst2(ctx, ast.type);
	Opt!Type inferred = tryGetNonInferringType(ctx.instantiateCtx, expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, source, Diag(Diag.TypeAnnotationUnnecessary(typeWithContainer(ctx, type))));
	Expr expr = checkAndExpect(ctx, locals, &ast.expr, type);
	return check(ctx, expected, type, source, ExprKind(allocate(ctx.alloc, TypedExpr(expr))));
}
