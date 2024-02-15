module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates : eachFunInScope, funsInScope;
import frontend.check.checkCall.checkCall : checkCall, checkCallIdentifier, checkCallNamed, checkCallSpecial;
import frontend.check.checkCall.checkCallSpecs : isPurityAlwaysCompatibleConsideringSpecs, isShared;
import frontend.check.checkCtx : CheckCtx, markUsed;
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
	withInfer;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay, noDelayStructInsts;
import frontend.check.maps : FunsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst : checkDestructure, makeTupleType, typeFromDestructure;
import model.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	CallNamedAst,
	DestructureAst,
	DoAst,
	EmptyAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
	IfAst,
	IfOptionAst,
	InterpolatedAst,
	LambdaAst,
	LetAst,
	LiteralFloatAst,
	LiteralIntAst,
	LiteralNatAst,
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
	SharedAst,
	TernaryAst,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypedAst,
	UnlessAst,
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
	ClosureGetExpr,
	ClosureRef,
	ClosureSetExpr,
	CommonTypes,
	Destructure,
	emptySpecImpls,
	emptyTypeArgs,
	emptyTypeParams,
	EnumOrFlagsMember,
	Expr,
	ExprAndType,
	ExprKind,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	IntegralTypes,
	isDefinitelyByRef,
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
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	Mutability,
	PtrToFieldExpr,
	PtrToLocalExpr,
	Purity,
	purityRange,
	SeqExpr,
	SpecInst,
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
import util.alloc.alloc : Alloc;
import util.col.array :
	append,
	arrayOfSingle,
	arraysCorrespond,
	contains,
	every,
	exists,
	isEmpty,
	map,
	mapPointers,
	mapZipPointers3,
	newArray,
	only,
	PtrAndSmallNumber,
	small;
import util.col.enumMap : EnumMap, makeEnumMap;
import util.col.mutMaxArr : asTemporaryArray, initializeMutMaxArr, mutMaxArrSize;
import util.conv : safeToUshort;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optOrDefault, someMut, some;
import util.sourceRange : Pos, Range;
import util.symbol : prependSet, prependSetDeref, Symbol, symbol;
import util.union_ : Union;
import util.util : castImmutable, castNonScope_ref, max, ptrTrustMe;

Expr checkFunctionBody(
	ref CheckCtx checkCtx,
	in StructsAndAliasesMap structsAndAliasesMap,
	in CommonTypes commonTypes,
	in FunsMap funsMap,
	TypeContainer typeContainer,
	Type returnType,
	TypeParams typeParams,
	Destructure[] params,
	in immutable SpecInst*[] specs,
	in FunFlags flags,
	ExprAst* ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesMap,
		funsMap,
		ptrTrustMe(commonTypes),
		typeContainer,
		specs,
		typeParams,
		flags);
	Expr res = checkWithParamDestructures(
		castNonScope_ref(exprCtx), ast, noneMut!(LambdaInfo*), params,
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
	in FunsMap funsMap,
	TypeContainer typeContainer,
	FunFlags flags,
	ExprAst* ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesMap,
		funsMap,
		ptrTrustMe(commonTypes),
		typeContainer,
		[],
		emptyTypeParams,
		flags);
	LocalsInfo locals = LocalsInfo(noneMut!(LambdaInfo*), noneMut!(LocalNode*));
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
		(AssertOrForbidAst* a) =>
			checkAssertOrForbid(ctx, locals, ast, a, expected),
		(AssignmentAst* a) =>
			checkAssignment(ctx, locals, ast, a.left, a.keywordRange, &a.right, expected),
		(AssignmentCallAst* a) =>
			checkAssignmentCall(ctx, locals, ast, *a, expected),
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
			checkFor(ctx, locals, ast, *a, expected),
		(IdentifierAst a) =>
			checkIdentifier(ctx, locals, ast, a, expected),
		(IfAst* a) =>
			checkIf(ctx, locals, ast, &a.cond, &a.then, &a.else_, expected),
		(IfOptionAst* a) =>
			checkIfOption(ctx, locals, ast, a, expected),
		(InterpolatedAst a) =>
			checkInterpolated(ctx, locals, ast, a, expected),
		(LambdaAst* a) =>
			checkLambda(ctx, locals, ast, *a, expected),
		(LetAst* a) =>
			checkLet(ctx, locals, ast, a, expected),
		(LiteralFloatAst a) =>
			checkLiteralFloat(ctx, ast, a, expected),
		(LiteralIntAst a) =>
			checkLiteralInt(ctx, ast, a, expected),
		(LiteralNatAst a) =>
			checkLiteralNat(ctx, ast, a, expected),
		(LiteralStringAst a) =>
			checkLiteralString(ctx, ast, a.value, expected),
		(LoopAst* a) =>
			checkLoop(ctx, locals, ast, a, expected),
		(LoopBreakAst* a) =>
			checkLoopBreak(ctx, locals, ast, a, expected),
		(LoopContinueAst a) =>
			checkLoopContinue(ctx, locals, ast, a, expected),
		(LoopUntilAst* a) =>
			checkLoopUntil(ctx, locals, ast, a, expected),
		(LoopWhileAst* a) =>
			checkLoopWhile(ctx, locals, ast, a, expected),
		(MatchAst* a) =>
			checkMatch(ctx, locals, ast, a, expected),
		(ParenthesizedAst* a) =>
			checkExpr(ctx, locals, &a.inner, expected),
		(PtrAst* a) =>
			checkPointer(ctx, locals, ast, a, expected),
		(SeqAst* a) =>
			checkSeq(ctx, locals, ast, a, expected),
		(SharedAst* a) =>
			checkShared(ctx, locals, ast, a, expected),
		(TernaryAst* a) =>
			checkIf(ctx, locals, ast, &a.cond, &a.then, &a.else_, expected),
		(ThenAst* a) =>
			checkThen(ctx, locals, ast, *a, expected),
		(ThrowAst* a) =>
			checkThrow(ctx, locals, ast, a, expected),
		(TrustedAst* a) =>
			checkTrusted(ctx, locals, ast, a, expected),
		(TypedAst* a) =>
			checkTyped(ctx, locals, ast, a, expected),
		(UnlessAst* a) =>
			checkUnless(ctx, locals, ast, a, expected),
		(WithAst* a) =>
			checkWith(ctx, locals, ast, *a, expected));

private:

Expr checkWithParamDestructures(
	ref ExprCtx ctx,
	ExprAst* ast,
	MutOpt!(LambdaInfo*) lambdaInfo,
	Destructure[] params,
	in Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	LocalsInfo locals = LocalsInfo(lambdaInfo, noneMut!(LocalNode*));
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

Expr checkAndExpectBool(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.bool_));

Expr checkAndExpectString(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.string_));

Expr checkAndExpectVoid(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.void_));

Type voidType(ref const ExprCtx ctx) =>
	Type(ctx.commonTypes.void_);

Expr checkArrowAccess(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref ArrowAccessAst ast,
	ref Expected expected,
) {
	ExprAst[] derefArgs = arrayOfSingle(ast.left);
	CallAst callDeref = CallAst(CallAst.style.single, NameAndRange(source.range.start, symbol!"*"), derefArgs);
	ExprAst deref = ExprAst(Range(source.range.start, ast.name.start), ExprAstKind(callDeref));
	return checkCallSpecial(ctx, locals, source, ast.keywordRange, ast.name.name, [deref], expected);
}

Expr checkIf(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ExprAst* condAst,
	ExprAst* thenAst,
	ExprAst* elseAst,
	ref Expected expected,
) {
	Expr cond = checkAndExpectBool(ctx, locals, condAst);
	Expr then = checkExpr(ctx, locals, thenAst, expected);
	Expr else_ = checkExpr(ctx, locals, elseAst, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, IfExpr(cond, then, else_))));
}

Expr checkThrow(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ThrowAst* ast, ref Expected expected) {
	if (isPurelyInferring(expected)) {
		addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, source);
	} else {
		Expr thrown = checkAndExpectString(ctx, locals, &ast.thrown);
		return Expr(source, ExprKind(allocate(ctx.alloc, ThrowExpr(thrown))));
	}
}

Expr checkTrusted(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, TrustedAst* ast, ref Expected expected) {
	Expr inner = withTrusted!Expr(ctx, source, () => checkExpr(ctx, locals, &ast.inner, expected));
	return Expr(source, ExprKind(allocate(ctx.alloc, TrustedExpr(inner))));
}

Expr checkAssertOrForbid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	AssertOrForbidAst* ast,
	ref Expected expected,
) {
	Expr* condition = allocate(ctx.alloc, checkAndExpectBool(ctx, locals, &ast.condition));
	Opt!(Expr*) thrown = has(ast.thrown)
		? some(allocate(ctx.alloc, checkAndExpectString(ctx, locals, &force(ast.thrown))))
		: none!(Expr*);
	return check(ctx, source, expected, voidType(ctx), Expr(
		source,
		ExprKind(AssertOrForbidExpr(ast.kind, condition, thrown))));
}

Expr checkAssignment(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in ExprAst left,
	in Range keywordRange,
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
					return some(prependSet(ctx.allSymbols, leftCall.funNameName));
				case CallAst.Style.prefixOperator:
					return leftCall.funNameName == symbol!"*" ? some(symbol!"set-deref") : none!Symbol;
				case CallAst.Style.subscript:
					return some(symbol!"set-subscript");
				default:
					return none!Symbol;
			}
		}();
		if (has(name)) {
			//TODO:PERF use temp alloc
			ExprAst[] args = append(ctx.alloc, leftCall.args, *right);
			return checkCallSpecial(ctx, locals, source, keywordRange, force(name), args, expected);
		} else {
			addDiag2(ctx, source, Diag(Diag.AssignmentNotAllowed()));
			return bogus(expected, source);
		}
	} else if (left.kind.isA!ArrowAccessAst) {
		ArrowAccessAst leftArrow = left.kind.as!ArrowAccessAst;
		return checkCallSpecial(
			ctx, locals, source, keywordRange,
			prependSetDeref(ctx.allSymbols, leftArrow.name.name),
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
		ExprAstKind(CallAst(CallAst.style.infix, ast.funName, ast.leftAndRight))));
	return checkAssignment(ctx, locals, source, ast.left, ast.keywordRange(ctx.allSymbols), call, expected);
}

Expr checkUnless(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	UnlessAst* ast,
	ref Expected expected,
) {
	Expr cond = checkAndExpectBool(ctx, locals, &ast.cond);
	Expr else_ = checkExpr(ctx, locals, &ast.body_, expected);
	Expr then = checkExpr(ctx, locals, &ast.emptyElse, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, IfExpr(cond, then, else_))));
}

Expr checkEmptyNew(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, in Range range, ref Expected expected) =>
	checkCallSpecial(ctx, locals, source, range, symbol!"new", [], expected);

Expr checkIfOption(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	IfOptionAst* ast,
	ref Expected expected,
) {
	// We don't know the cond type, except that it's an option
	ExprAndType option = checkAndInfer(ctx, locals, &ast.option);
	StructInst* inst = option.type.isA!(StructInst*)
		? option.type.as!(StructInst*)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (inst.decl != ctx.commonTypes.opt) {
		addDiag2(ctx, source, Diag(Diag.IfNeedsOpt(typeWithContainer(ctx, option.type))));
		return bogus(expected, source);
	} else {
		Type nonOptionalType = only(inst.typeArgs);
		Destructure destructure = checkDestructure2(ctx, ast.destructure, nonOptionalType);
		Expr then = checkExprWithDestructure(ctx, locals, destructure, &ast.then, expected);
		Expr else_ = checkExpr(ctx, locals, &ast.else_, expected);
		return Expr(source, ExprKind(allocate(ctx.alloc, IfOptionExpr(destructure, option, then, else_))));
	}
}

Expr checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in InterpolatedAst ast,
	ref Expected expected,
) {
	ExprAst[] args = map(ctx.alloc, ast.parts, (ref ExprAst part) =>
		part.kind.isA!LiteralStringAst
			? part
			: ExprAst(part.range, ExprAstKind(CallAst(
				CallAst.Style.implicit,
				NameAndRange(source.range.start, symbol!"to"),
				newArray!ExprAst(ctx.alloc, [part])))));
	CallAst call = CallAst(CallAst.style.implicit, NameAndRange(source.range.start, symbol!"interpolate"), args);
	return checkCall(ctx, locals, source, call, expected);
}

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
	foreach (size_t index, ref ClosureFieldBuilder field; asTemporaryArray(info.closureFields))
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
		size_t closureFieldIndex = mutMaxArrSize(info.closureFields);
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
		? check(ctx, source, expected, force(res).type, toExpr(ctx.alloc, source, force(res).variableRef))
		: checkCallIdentifier(ctx, locals, source, ast.name, expected);
}

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
				check(ctx, source, expected, voidType(ctx), Expr(
					source,
					ExprKind(LocalSetExpr(local, allocate(ctx.alloc, value))))),
			(ClosureRef x) =>
				check(ctx, source, expected, voidType(ctx), Expr(
					source,
					ExprKind(ClosureSetExpr(x, allocate(ctx.alloc, value))))));
	} else
		return checkCallSpecial(
			ctx, locals, source, keywordRange, prependSet(ctx.allSymbols, left), [*right], expected);
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

Expr toExpr(ref Alloc alloc, ExprAst* source, VariableRef a) =>
	a.matchWithPointers!Expr(
		(Local* x) =>
			Expr(source, ExprKind(LocalGetExpr(x))),
		(ClosureRef x) =>
			Expr(source, ExprKind(ClosureGetExpr(x))));

Expr checkLiteralFloat(ref ExprCtx ctx, ExprAst* source, in LiteralFloatAst ast, ref Expected expected) {
	immutable StructInst*[2] allowedTypes = [ctx.commonTypes.float32, ctx.commonTypes.float64];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	if (has(opTypeIndex)) {
		StructInst* numberType = allowedTypes[force(opTypeIndex)];
		if (ast.overflow)
			addDiag2(ctx, source, Diag(Diag.LiteralOverflow(typeWithContainer(ctx, Type(numberType)))));
		return asFloat(ctx, source, numberType, ast.value, expected);
	} else
		return bogus(expected, source);
}

bool isFloatType(in CommonTypes commonTypes, StructInst* numberType) =>
	numberType == commonTypes.float32 || numberType == commonTypes.float64;

Expr asFloat(
	ref ExprCtx ctx,
	ExprAst* source,
	StructInst* numberType,
	double value,
	ref Expected expected,
) {
	assert(isFloatType(ctx.commonTypes, numberType));
	return check(ctx, source, expected, Type(numberType), Expr(source, ExprKind(
		allocate(ctx.alloc, LiteralExpr(Constant(Constant.Float(value)))))));
}

Expr checkLiteralInt(ref ExprCtx ctx, ExprAst* source, in LiteralIntAst ast, ref Expected expected) {
	IntegralTypes integrals = ctx.commonTypes.integrals;
	immutable StructInst*[6] allowedTypes = [
		integrals.int8, integrals.int16, integrals.int32, integrals.int64,
		ctx.commonTypes.float32, ctx.commonTypes.float64,
	];
	IntRange[4] ranges = [
		IntRange(byte.min, byte.max),
		IntRange(short.min, short.max),
		IntRange(int.min, int.max),
		IntRange(long.min, long.max),
	];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		StructInst* numberType = allowedTypes[typeIndex];
		if (isFloatType(ctx.commonTypes, numberType))
			return asFloat(ctx, source, numberType, cast(double) ast.value, expected);
		else {
			Constant constant = Constant(Constant.Integral(ast.value));
			if (ast.overflow || !contains(ranges[typeIndex], ast.value))
				addDiag2(ctx, source, Diag(Diag.LiteralOverflow(typeWithContainer(ctx, Type(numberType)))));
			return check(ctx, source, expected, Type(numberType), Expr(source, ExprKind(
				allocate(ctx.alloc, LiteralExpr(constant)))));
		}
	} else
		return bogus(expected, source);
}
immutable struct IntRange {
	long min;
	long max;
}
bool contains(IntRange a, long x) =>
	a.min <= x && x <= a.max;

Expr checkLiteralNat(ref ExprCtx ctx, ExprAst* source, in LiteralNatAst ast, ref Expected expected) {
	IntegralTypes integrals = ctx.commonTypes.integrals;
	immutable StructInst*[10] allowedTypes = [
		integrals.nat8, integrals.nat16, integrals.nat32, integrals.nat64,
		integrals.int8, integrals.int16, integrals.int32, integrals.int64,
		ctx.commonTypes.float32, ctx.commonTypes.float64,
	];
	ulong[8] maximums = [
		ubyte.max, ushort.max, uint.max, ulong.max,
		byte.max, short.max, int.max, long.max,
	];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		StructInst* numberType = allowedTypes[typeIndex];
		if (isFloatType(ctx.commonTypes, numberType))
			return asFloat(ctx, source, numberType, cast(double) ast.value, expected);
		else {
			Constant constant = Constant(Constant.Integral(ast.value));
			if (ast.overflow || ast.value > maximums[typeIndex])
				addDiag2(ctx, source, Diag(Diag.LiteralOverflow(typeWithContainer(ctx, Type(numberType)))));
			return check(ctx, source, expected, Type(numberType), Expr(source, ExprKind(
				allocate(ctx.alloc, LiteralExpr(constant)))));
		}
	} else
		return bogus(expected, source);
}

Expr checkLiteralString(ref ExprCtx ctx, ExprAst* source, string value, ref Expected expected) {
	immutable StructInst*[4] allowedTypes = [
		ctx.commonTypes.char8,
		ctx.commonTypes.cString,
		ctx.commonTypes.string_,
		ctx.commonTypes.symbol,
	];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes);
	static immutable LiteralStringLikeExpr.Kind[4] kinds = [
		LiteralStringLikeExpr.Kind.cString, // won't be used
		LiteralStringLikeExpr.Kind.cString,
		LiteralStringLikeExpr.Kind.string_,
		LiteralStringLikeExpr.Kind.symbol,
	];

	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		Expr expr = () {
			if (typeIndex == 0) { // char8
				char char_ = () {
					if (value.length != 1) {
						addDiag2(ctx, source, Diag(Diag.CharLiteralMustBeOneChar()));
						return 'a';
					} else
						return only(value);
				}();
				return Expr(source, ExprKind(allocate(ctx.alloc, LiteralExpr(Constant(Constant.Integral(char_))))));
			} else {
				LiteralStringLikeExpr.Kind kind = kinds[typeIndex];
				if (kind != LiteralStringLikeExpr.Kind.string_ && contains(value, '\0')) {
					addDiag2(ctx, source.range, Diag(Diag.StringLiteralInvalid(kind == LiteralStringLikeExpr.Kind.symbol
						? Diag.StringLiteralInvalid.Reason.symbolContainsNul
						: Diag.StringLiteralInvalid.Reason.cStringContainsNul)));
				}
				return Expr(source, ExprKind(LiteralStringLikeExpr(kind, value)));
			}
		}();
		return check(ctx, source, expected, Type(allowedTypes[typeIndex]), expr);
	} else
		return bogus(expected, source);
}

Expr checkExprWithDestructure(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref Destructure destructure,
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
		addDiag2(ctx, localMustHaveNameRange(*local, ctx.allSymbols), Diag(
			Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.name)));

	LocalNode localNode = LocalNode(
		locals.locals,
		makeEnumMap!(LocalAccessKind, bool)((LocalAccessKind _) => false),
		local);
	LocalsInfo newLocals = LocalsInfo(locals.lambda, someMut(ptrTrustMe(localNode)));
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
		addDiag2(ctx, localMustHaveNameRange(*local, ctx.allSymbols), Diag(
			Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Local(local, isGot, isSet)))));
}

Expr checkPointer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, PtrAst* ast, ref Expected expected) {
	return getExpectedPointee(ctx, expected).match!Expr(
		(ExpectedPointee.None) {
			addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.pointer)));
			return bogus(expected, source);
		},
		(ExpectedPointee.FunPointer) =>
			checkFunPointer(ctx, source, *ast, expected),
		(ExpectedPointee.Pointer x) =>
			checkPointerInner(ctx, locals, source, ast, x.pointer, x.pointee, x.mutability, expected));
}

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
		return check(ctx, source, expected, pointerType, Expr(source, ExprKind(PtrToLocalExpr(local))));
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
				return check(ctx, source, expected, pointerType, Expr(source, ExprKind(allocate(ctx.alloc,
					PtrToFieldExpr(ExprAndType(target, Type(recordType)), rfg.fieldIndex)))));
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
						return check(ctx, source, expected, pointerType, Expr(source, ExprKind(allocate(ctx.alloc,
							PtrToFieldExpr(ExprAndType(targetPtr, derefedType), rfg.fieldIndex)))));
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
	Type paramType = makeTupleType(ctx.instantiateCtx, ctx.commonTypes, funInst.paramTypes);
	StructInst* structInst = instantiateStructNeverDelay(
		ctx.instantiateCtx, ctx.commonTypes.funPtrStruct, [funInst.returnType, paramType]);
	return check(ctx, source, expected, Type(structInst), Expr(source, ExprKind(FunPointerExpr(funInst))));
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
		ctx, locals, &ast.inner, *inner, expected,
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

Expr checkLambda(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref LambdaAst ast, ref Expected expected) {
	MutOpt!ExpectedLambdaType opEt = getExpectedLambda(ctx, source, typeFromDestructure(ctx, ast.param), expected);
	if (!has(opEt))
		return bogus(expected, source);

	ExpectedLambdaType et = force(opEt);
	FunKind kind = et.funType.kind;
	if (kind == FunKind.function_) {
		addDiag2(ctx, source, Diag(Diag.LambdaCantBeFunctionPointer()));
		return bogus(expected, source);
	}
	return checkLambdaInner(
		ctx, locals, source, ast, expected, none!(StructInst*),
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
	ref LambdaAst ast,
	ref Expected expected,
	Opt!(StructInst*) mutTypeForExplicitShared,
	Type paramType,
	Type nonInstantiatedReturnType,
	TypeContext returnTypeContext,
	StructDecl* funStruct,
	LambdaExpr.Kind kind,
) {
	Destructure param = checkDestructure2(ctx, ast.param, paramType);

	LambdaExpr* lambda = allocate(ctx.alloc, LambdaExpr(kind, param, mutTypeForExplicitShared));

	LambdaInfo lambdaInfo = LambdaInfo(ptrTrustMe(locals), lambda);
	initializeMutMaxArr(lambdaInfo.closureFields);

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	LocalsInfo bodyLocals = LocalsInfo(someMut(ptrTrustMe(lambdaInfo)), noneMut!(LocalNode*));
	Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(expected,
		nonInstantiatedReturnType,
		returnTypeContext,
		(ref Expected returnTypeInferrer) =>
			checkExprWithDestructure(ctx, bodyLocals, param, &ast.body_, returnTypeInferrer));

	StructInst* instFunStruct = instantiateStructNeverDelay(ctx.instantiateCtx, funStruct, [bodyAndType.b, param.type]);
	lambda.fillLate(
		body_: bodyAndType.a,
		closure: small!VariableRef(
			map!(VariableRef, ClosureFieldBuilder)(
				ctx.alloc,
				asTemporaryArray(lambdaInfo.closureFields),
				(ref const ClosureFieldBuilder x) =>
					x.variableRef)),
		returnType: bodyAndType.b);
	//TODO: this check should never fail, so could just set inferred directly with no check
	return LambdaAndReturnType(
		check(ctx, source, expected, Type(instFunStruct), Expr(source, ExprKind(castImmutable(lambda)))),
		bodyAndType.b);
}

Opt!Type typeFromDestructure(ref ExprCtx ctx, in DestructureAst ast) =>
	.typeFromDestructure(
		ctx.checkCtx, ctx.commonTypes, ast, ctx.structsAndAliasesMap, ctx.outermostFunTypeParams, noDelayStructInsts);

Destructure checkDestructure2(ref ExprCtx ctx, ref DestructureAst ast, Type type) =>
	.checkDestructure(
		ctx.checkCtx, ctx.commonTypes, ctx.structsAndAliasesMap, ctx.typeContainer, ctx.outermostFunTypeParams,
		noDelayStructInsts, ast, some(type));

Expr checkLet(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, LetAst* ast, ref Expected expected) {
	ExprAndType value = checkAndExpectOrInfer(ctx, locals, &ast.value, typeFromDestructure(ctx, ast.destructure));
	Destructure destructure = checkDestructure2(ctx, ast.destructure, value.type);
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

Expr checkLoopUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	LoopUntilAst* ast,
	ref Expected expected,
) =>
	check(ctx, source, expected, voidType(ctx), Expr(
		source,
		ExprKind(allocate(ctx.alloc, LoopUntilExpr(
			checkAndExpectBool(ctx, locals, &ast.condition),
			checkAndExpectVoid(ctx, locals, &ast.body_))))));

Expr checkLoopWhile(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	LoopWhileAst* ast,
	ref Expected expected,
) =>
	check(ctx, source, expected, voidType(ctx), Expr(
		source,
		ExprKind(allocate(ctx.alloc, LoopWhileExpr(
			checkAndExpectBool(ctx, locals, &ast.condition),
			checkAndExpectVoid(ctx, locals, &ast.body_))))));

Expr checkMatch(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, MatchAst* ast, ref Expected expected) {
	ExprAndType matchedAndType = checkAndInfer(ctx, locals, &ast.matched);
	Type matchedType = matchedAndType.type;
	Opt!(StructInst*) inst = matchedType.isA!(StructInst*) ? some(matchedType.as!(StructInst*)) : none!(StructInst*);
	Opt!(StructDecl*) decl = has(inst) ? some(force(inst).decl) : none!(StructDecl*);
	StructBody body_ = has(decl) ? force(decl).body_ : StructBody(StructBody.Bogus());
	if (body_.isA!(StructBody.Enum))
		return checkMatchEnum(
			ctx, locals, source, *ast, expected, matchedAndType, force(decl), body_.as!(StructBody.Enum).members);
	else if (body_.isA!(StructBody.Union))
		return checkMatchUnion(
			ctx, locals, source, *ast, expected, matchedAndType,
			body_.as!(StructBody.Union).members,
			force(inst).instantiatedTypes);
	else {
		if (!matchedType.isA!(Type.Bogus))
			addDiag2(ctx, ast.matched.range, Diag(Diag.MatchOnNonEnumOrUnion(typeWithContainer(ctx, matchedType))));
		return bogus(expected, &ast.matched);
	}
}

Expr checkMatchEnum(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	StructDecl* matchedEnum,
	in EnumOrFlagsMember[] members,
) {
	if (checkMatchCaseNames!EnumOrFlagsMember(ctx, members, *source, ast)) {
		Expr[] cases = mapPointers(ctx.alloc, ast.cases, (MatchAst.CaseAst* caseAst) {
			if (has(caseAst.destructure))
				addDiag2(ctx, force(caseAst.destructure).range(ctx.allSymbols), Diag(
					Diag.MatchCaseNoValueForEnum(matchedEnum)));
			return checkExpr(ctx, locals, &caseAst.then, expected);
		});
		return Expr(
			source,
			ExprKind(allocate(ctx.alloc, MatchEnumExpr(matched, cases))));
	} else
		return bogus(expected, source);
}

Expr checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	in UnionMember[] members,
	in Type[] instantiatedTypes,
) {
	if (checkMatchCaseNames!UnionMember(ctx, members, *source, ast)) {
		MatchUnionExpr.Case[] cases =
			mapZipPointers3!(MatchUnionExpr.Case, UnionMember, Type, MatchAst.CaseAst)(
				ctx.alloc, members, instantiatedTypes, ast.cases,
				(UnionMember* member, Type* type, MatchAst.CaseAst* caseAst) =>
					checkMatchUnionCase(ctx, locals, member, *type, caseAst, expected));
		return Expr(source, ExprKind(allocate(ctx.alloc, MatchUnionExpr(matched, cases))));
	} else
		return bogus(expected, source);
}

bool checkMatchCaseNames(Member)(ref ExprCtx ctx, in Member[] members, in ExprAst source, in MatchAst ast) {
	bool ok = arraysCorrespond!(MatchAst.CaseAst, Member)(
		ast.cases, members, (ref MatchAst.CaseAst caseAst, ref Member member) =>
			caseAst.memberName.name == member.name);
	if (!ok)
		addDiag2(ctx, ast.keywordRange(source), Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref Member member) => member.name))));
	return ok;
}

MatchUnionExpr.Case checkMatchUnionCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UnionMember* member,
	Type memberType,
	MatchAst.CaseAst* caseAst,
	ref Expected expected,
) {
	if (has(caseAst.destructure)) {
		Destructure destructure = checkDestructure2(ctx, force(caseAst.destructure), memberType);
		return MatchUnionExpr.Case(
			destructure, checkExprWithDestructure(ctx, locals, destructure, &caseAst.then, expected));
	} else {
		if (memberType != Type(ctx.commonTypes.void_))
			addDiag2(ctx, caseAst.memberNameRange(ctx.allSymbols), Diag(Diag.MatchCaseShouldUseIgnore(member)));
		return MatchUnionExpr.Case(
			Destructure(allocate(ctx.alloc, Destructure.Ignore(caseAst.memberName.start, memberType))),
			checkExpr(ctx, locals, &caseAst.then, expected));
	}
}

Expr checkSeq(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, SeqAst* ast, ref Expected expected) {
	Expr first = checkAndExpectVoid(ctx, locals, &ast.first);
	Expr then = checkExpr(ctx, locals, &ast.then, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, SeqExpr(first, then))));
}

bool hasBreakOrContinue(in ExprAst a) =>
	a.kind.matchIn!bool(
		(in ArrowAccessAst _) =>
			false,
		(in AssertOrForbidAst _) =>
			false,
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
			hasBreakOrContinue(x.then) || hasBreakOrContinue(x.else_),
		(in IfOptionAst x) =>
			hasBreakOrContinue(x.then) || hasBreakOrContinue(x.else_),
		(in InterpolatedAst _) =>
			false,
		(in LambdaAst _) =>
			false,
		(in LetAst x) =>
			hasBreakOrContinue(x.then),
		(in LiteralFloatAst _) =>
			false,
		(in LiteralIntAst _) =>
			false,
		(in LiteralNatAst _) =>
			false,
		(in LiteralStringAst _) =>
			false,
		(in LoopAst _) =>
			false,
		(in LoopBreakAst _) =>
			true,
		(in LoopContinueAst _) =>
			true,
		(in LoopUntilAst _) =>
			false,
		(in LoopWhileAst _) =>
			false,
		(in MatchAst x) =>
			exists!(MatchAst.CaseAst)(x.cases, (in MatchAst.CaseAst case_) =>
				hasBreakOrContinue(case_.then)),
		(in ParenthesizedAst _) =>
			false,
		(in PtrAst _) =>
			false,
		(in SeqAst x) =>
			hasBreakOrContinue(x.then),
		(in SharedAst x) =>
			false,
		(in TernaryAst x) =>
			hasBreakOrContinue(x.then) || hasBreakOrContinue(x.else_),
		// TODO: Maybe this should be allowed some day. Not in primitive loop but in for-break.
		(in ThenAst x) =>
			hasBreakOrContinue(x.then),
		(in ThrowAst _) =>
			false,
		(in TrustedAst _) =>
			false,
		(in TypedAst _) =>
			false,
		(in UnlessAst x) =>
			hasBreakOrContinue(x.body_),
		(in WithAst _) =>
			false);

Expr checkFor(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref ForAst ast, ref Expected expected) {
	// TODO: NO ALLOC
	ExprAst lambdaBody = ExprAst(source.range, ExprAstKind(
		allocate(ctx.alloc, LambdaAst(ast.param, none!Pos, ast.body_))));
	Symbol funName = hasBreakOrContinue(ast.body_) ? symbol!"for-break" : symbol!"for-loop";
	Range keywordRange = ast.forKeywordRange(*source);
	if (!ast.else_.kind.isA!EmptyAst) {
		// TODO: NO ALLOC
		ExprAst lambdaElse_ = ExprAst(ast.else_.range, ExprAstKind(
			allocate(ctx.alloc, LambdaAst(DestructureAst(DestructureAst.Void(source.range)), none!Pos, ast.else_))));
		return checkCallSpecial(
			ctx, locals, source, keywordRange, funName, [ast.collection, lambdaBody, lambdaElse_], expected);
	} else
		return checkCallSpecial(ctx, locals, source, keywordRange, funName, [ast.collection, lambdaBody], expected);
}

Expr checkWith(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref WithAst ast, ref Expected expected) {
	Range keywordRange = ast.withKeywordRange(*source);
	if (!ast.else_.kind.isA!(EmptyAst))
		addDiag2(ctx, keywordRange, Diag(Diag.WithHasElse()));
	// TODO: NO ALLOC
	ExprAst lambda = ExprAst(source.range, ExprAstKind(allocate(ctx.alloc, LambdaAst(ast.param, none!Pos, ast.body_))));
	return checkCallSpecial(ctx, locals, source, keywordRange, symbol!"with-block", [ast.arg, lambda], expected);
}

Expr checkThen(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref ThenAst ast, ref Expected expected) {
	// TODO: NO ALLOC
	ExprAst lambda = ExprAst(source.range, ExprAstKind(allocate(ctx.alloc, LambdaAst(ast.left, none!Pos, ast.then))));
	return checkCallSpecial(ctx, locals, source, ast.keywordRange, symbol!"then", [ast.futExpr, lambda], expected);
}

Expr checkTyped(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, TypedAst* ast, ref Expected expected) {
	Type type = typeFromAst2(ctx, ast.type);
	Opt!Type inferred = tryGetNonInferringType(ctx.instantiateCtx, expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, source, Diag(Diag.TypeAnnotationUnnecessary(typeWithContainer(ctx, type))));
	Expr expr = checkAndExpect(ctx, locals, &ast.expr, type);
	return check(ctx, source, expected, type, Expr(source, ExprKind(allocate(ctx.alloc, TypedExpr(expr)))));
}
