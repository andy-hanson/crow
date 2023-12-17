module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates : eachFunInScope, funsInScope;
import frontend.check.checkCall.checkCall : checkCall, checkCallIdentifier, checkCallSpecial, checkCallSpecialNoLocals;
import frontend.check.checkCall.checkCallSpecs : isPurityAlwaysCompatibleConsideringSpecs;
import frontend.check.checkCtx : CheckCtx, markUsed;
import frontend.check.exprCtx :
	addDiag2,
	checkCanDoUnsafe,
	ClosureFieldBuilder,
	ExprCtx,
	FunOrLambdaInfo,
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
	findExpectedStructForLiteral,
	FunType,
	getExpectedForDiag,
	getFunType,
	handleExpectedLambda,
	inferred,
	isPurelyInferring,
	LoopInfo,
	OkSkipOrAbort,
	Pair,
	setExpectedIfNoInferred,
	tryGetNonInferringType,
	tryGetLoop,
	TypeAndContext,
	TypeContext,
	withCopyWithNewExpectedType;
import frontend.check.instantiate : InstantiateCtx, instantiateFun, instantiateStructNeverDelay, noDelayStructInsts;
import frontend.check.maps : FunsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst : checkDestructure, makeFutType, makeTupleType, typeFromDestructure;
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
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	WithAst;
import model.constant : Constant;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	Arity,
	AssertOrForbidExpr,
	BogusExpr,
	Called,
	CalledDecl,
	CallExpr,
	ClosureGetExpr,
	ClosureRef,
	ClosureSetExpr,
	CommonTypes,
	Destructure,
	emptySpecImpls,
	emptyTypeArgs,
	Expr,
	ExprAndType,
	ExprKind,
	FieldMutability,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	FunPtrExpr,
	IfExpr,
	IfOptionExpr,
	IntegralTypes,
	isDefinitelyByRef,
	LambdaExpr,
	LetExpr,
	LiteralCStringExpr,
	LiteralExpr,
	LiteralSymbolExpr,
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
	SeqExpr,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	ThrowExpr,
	toMutability,
	Type,
	TypeParams,
	UnionMember,
	VariableRef;
import util.alloc.alloc : Alloc, allocateUninitialized;
import util.col.array :
	append,
	arrayOfSingle,
	arraysCorrespond,
	contains,
	exists,
	isEmpty,
	map,
	mapPointers,
	mapZipPointers3,
	newArray,
	only,
	PtrAndSmallNumber;
import util.col.mutArr : asTemporaryArray, MutArr, mutArrSize, push;
import util.col.mutMaxArr : asTemporaryArray, initializeMutMaxArr, mutMaxArrSize, push;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, initMemory, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optOrDefault, someMut, some;
import util.sourceRange : Pos, Range;
import util.string : copyToCString;
import util.symbol : prependSet, prependSetDeref, Symbol, symbol, symbolOfString;
import util.union_ : Union;
import util.util : castImmutable, castNonScope_ref, max, ptrTrustMe, todo, unreachable;

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
		commonTypes,
		typeContainer,
		specs,
		typeParams,
		flags);
	// leave funInfo.closureFields uninitialized, it won't be used
	FunOrLambdaInfo funInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), none!(LambdaExpr*));
	Expr res = checkWithParamDestructures(
		castNonScope_ref(exprCtx), ast, funInfo, params,
		(ref LocalsInfo innerLocals) =>
			checkAndExpect(castNonScope_ref(exprCtx), innerLocals, ast, returnType));
	return res;
}

Expr checkExpr(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, ref Expected expected) =>
	ast.kind.matchWithPointers!Expr(
		(ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, ast, a, expected),
		(AssertOrForbidAst* a) =>
			checkAssertOrForbid(ctx, locals, ast, a, expected),
		(AssignmentAst* a) =>
			checkAssignment(ctx, locals, ast, a.left, &a.right, expected),
		(AssignmentCallAst* a) =>
			checkAssignmentCall(ctx, locals, ast, *a, expected),
		(BogusAst _) =>
			bogus(expected, ast),
		(CallAst a) =>
			checkCall(ctx, locals, ast, a, expected),
		(EmptyAst a) =>
			checkEmptyNew(ctx, ast, expected),
		(ForAst* a) =>
			checkFor(ctx, locals, ast, *a, expected),
		(IdentifierAst a) =>
			checkIdentifier(ctx, locals, ast, a, expected),
		(IfAst* a) =>
			checkIf(ctx, locals, ast, a, expected),
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
		(LoopContinueAst _) =>
			checkLoopContinue(ctx, ast, expected),
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
		(ThenAst* a) =>
			checkThen(ctx, locals, ast, *a, expected),
		(ThrowAst* a) =>
			checkThrow(ctx, locals, ast, a, expected),
		(TrustedAst* a) =>
			withTrusted!Expr(ctx, ast, () => checkExpr(ctx, locals, &a.inner, expected)),
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
	ref FunOrLambdaInfo funInfo,
	Destructure[] params,
	in Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	LocalsInfo locals = LocalsInfo(ptrTrustMe(funInfo), noneMut!(LocalNode*));
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

ExprAndType checkAndInfer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) {
	Expected expected = Expected(Expected.Infer());
	Expr expr = checkExpr(ctx, locals, ast, expected);
	return ExprAndType(expr, inferred(expected));
}

ExprAndType checkAndExpectOrInfer(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, Opt!Type optExpected) =>
	has(optExpected)
		? ExprAndType(checkAndExpect(ctx, locals, ast, force(optExpected)), force(optExpected))
		: checkAndInfer(ctx, locals, ast);

Expr checkAndExpect(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast, Type expected) {
	Expected et = Expected(Expected.LocalType(expected));
	return checkExpr(ctx, locals, ast, et);
}

Expr checkAndExpectBool(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.bool_));

Expr checkAndExpectCString(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.cString));

Expr checkAndExpectVoid(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* ast) =>
	checkAndExpect(ctx, locals, ast, voidType(ctx));

Type voidType(ref const ExprCtx ctx) =>
	Type(ctx.commonTypes.void_);

Expr checkArrowAccess(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	ref ArrowAccessAst ast,
	ref Expected expected,
) {
	// TODO: NO ALLOC
	ExprAst[] derefArgs = arrayOfSingle(ast.left);
	CallAst callDeref = CallAst(CallAst.style.single, NameAndRange(source.range.start, symbol!"*"), derefArgs);
	return checkCallSpecial(
		ctx, locals, source, ast.name.name, [ExprAst(source.range, ExprAstKind(callDeref))], expected);
}

Expr checkIf(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, IfAst* ast, ref Expected expected) {
	Expr cond = checkAndExpectBool(ctx, locals, &ast.cond);
	Expr then = checkExpr(ctx, locals, &ast.then, expected);
	Expr else_ = checkExpr(ctx, locals, &ast.else_, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, IfExpr(cond, then, else_))));
}

Expr checkThrow(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ThrowAst* ast, ref Expected expected) {
	if (isPurelyInferring(expected)) {
		addDiag2(ctx, source, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, source);
	} else {
		Expr thrown = checkAndExpectCString(ctx, locals, &ast.thrown);
		return Expr(source, ExprKind(allocate(ctx.alloc, ThrowExpr(thrown))));
	}
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
		? some(allocate(ctx.alloc, checkAndExpectCString(ctx, locals, &force(ast.thrown))))
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
	ExprAst* right,
	ref Expected expected,
) {
	if (left.kind.isA!IdentifierAst)
		return checkAssignIdentifier(ctx, locals, source, left.kind.as!IdentifierAst.name, right, expected);
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
			return checkCallSpecial(ctx, locals, source, force(name), args, expected);
		} else {
			addDiag2(ctx, source, Diag(Diag.AssignmentNotAllowed()));
			return bogus(expected, source);
		}
	} else if (left.kind.isA!ArrowAccessAst) {
		ArrowAccessAst leftArrow = left.kind.as!ArrowAccessAst;
		return checkCallSpecial(
			ctx, locals, source,
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
	ExprAst[2] args = [ast.left, ast.right];
	//TODO:NO ALLOC
	ExprAst* call = allocate(ctx.alloc, ExprAst(
		source.range,
		ExprAstKind(CallAst(CallAst.style.infix, ast.funName, args))));
	return checkAssignment(ctx, locals, source, ast.left, call, expected);
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
	Expr then = checkEmptyNew(ctx, source, expected);
	return Expr(source, ExprKind(allocate(ctx.alloc, IfExpr(cond, then, else_))));
}

Expr checkEmptyNew(ref ExprCtx ctx, ExprAst* source, ref Expected expected) =>
	checkCallSpecialNoLocals(ctx, source, symbol!"new", [], expected);

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
	defaultExpectedToString(ctx, source, expected);
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> "a" ~~ b.to ~~ "c"
	CallAst call = checkInterpolatedRecur(ctx, ast.parts, source.range.start + 1, none!ExprAst);
	Opt!Type inferred = tryGetNonInferringType(ctx.instantiateCtx, expected);
	CallAst callAndConvert = has(inferred) && !isString(force(inferred))
		? CallAst(
			//TODO: new kind (not infix)
			CallAst.Style.infix,
			NameAndRange(source.range.start, symbol!"to"),
			// TODO: NO ALLOC
			newArray!ExprAst(ctx.alloc, [ExprAst(source.range, ExprAstKind(call))]))
		: call;
	return checkCall(ctx, locals, source, callAndConvert, expected);
}

bool isString(Type a) =>
	// TODO: better
	a.isA!(StructInst*) && a.as!(StructInst*).decl.name == symbol!"string";

CallAst checkInterpolatedRecur(ref ExprCtx ctx, in InterpolatedPart[] parts, Pos pos, in Opt!ExprAst left) {
	ExprAst right = parts[0].matchIn!ExprAst(
		(in string it) =>
			// TODO: this length may be wrong in the presence of escapes
			ExprAst(Range(pos, safeToUint(pos + it.length)), ExprAstKind(LiteralStringAst(it))),
		(in ExprAst e) @safe =>
			ExprAst(e.range, ExprAstKind(CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				NameAndRange(pos, symbol!"to"),
				// TODO: NO ALLOC
				newArray!ExprAst(ctx.alloc, [e])))));
	Pos newPos = parts[0].matchIn!Pos(
		(in string x) =>
			// TODO: this length may be wrong in the presence of escapes
			safeToUint(pos + x.length),
		(in ExprAst x) =>
			x.range.end + 1);
	ExprAst newLeft = has(left)
		? ExprAst(
			Range(pos, newPos),
			ExprAstKind(CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				NameAndRange(pos, symbol!"~~"),
				// TODO: NO ALLOC
				newArray!ExprAst(ctx.alloc, [force(left), right]))))
		: right;
	scope InterpolatedPart[] rest = parts[1 .. $];
	return isEmpty(rest)
		? newLeft.kind.as!CallAst
		: checkInterpolatedRecur(ctx, rest, newPos, some(newLeft));
}

struct ExpectedLambdaType {
	TypeContext typeContext;
	StructInst* funStructInst;
	StructDecl* funStruct;
	FunKind kind;
	Type nonInstantiatedPossiblyFutReturnType;
	Type instantiatedParamType;
}

MutOpt!ExpectedLambdaType getExpectedLambdaType(
	ref ExprCtx ctx,
	ExprAst* source,
	ref Expected expected,
	in DestructureAst destructure,
) {
	Opt!Type declaredParamType = typeFromDestructure(ctx, destructure);
	if (has(declaredParamType) && force(declaredParamType).isA!(Type.Bogus))
		return noneMut!ExpectedLambdaType;
	OkSkipOrAbort!ExpectedLambdaType res = handleExpectedLambda!ExpectedLambdaType(
		ctx, expected, (TypeAndContext expectedType) {
			Opt!FunType optFunType = getFunType(ctx.commonTypes, expectedType.type);
			if (has(optFunType)) {
				FunType funType = force(optFunType);
				Opt!Type optExpectedParamType = tryGetNonInferringType(
					ctx.instantiateCtx, TypeAndContext(funType.nonInstantiatedParamType, expectedType.context));
				OkSkipOrAbort!Type actualParamType = () {
					if (has(optExpectedParamType)) {
						Type expectedParamType = force(optExpectedParamType);
						return !has(declaredParamType)
							? OkSkipOrAbort!Type.ok(expectedParamType)
							: expectedParamType == force(declaredParamType)
							? OkSkipOrAbort!Type.ok(expectedParamType)
							: OkSkipOrAbort!Type.skip;
					} else
						return has(declaredParamType)
							? OkSkipOrAbort!Type.ok(force(declaredParamType))
							: OkSkipOrAbort!Type.abort(Diag(Diag.LambdaCantInferParamType()));
				}();
				return actualParamType.mapOk((Type paramType) {
					Type nonInstantiatedReturnType = funType.kind == FunKind.far
						? makeFutType(ctx.instantiateCtx, ctx.commonTypes, funType.nonInstantiatedNonFutReturnType)
						: funType.nonInstantiatedNonFutReturnType;
					return ExpectedLambdaType(
						expectedType.context,
						funType.structInst, funType.structDecl, funType.kind,
						nonInstantiatedReturnType, paramType);
				});
			} else
				return OkSkipOrAbort!ExpectedLambdaType.skip;
		});
	return res.match!(MutOpt!ExpectedLambdaType)(
		(ref OkSkipOrAbort!ExpectedLambdaType.Ok x) =>
			someMut(x.value),
		(OkSkipOrAbort!ExpectedLambdaType.Skip) {
			// Skipped every lambda.
			addDiag2(ctx, source, Diag(Diag.LambdaNotExpected(getExpectedForDiag(ctx, expected))));
			return noneMut!ExpectedLambdaType;
		},
		(OkSkipOrAbort!ExpectedLambdaType.Abort x) {
			addDiag2(ctx, source, x.diag);
			return noneMut!ExpectedLambdaType;
		});
}

struct VariableRefAndType {
	@safe @nogc pure nothrow:

	immutable VariableRef variableRef;
	immutable Mutability mutability;
	bool[4]* isUsed; // null for Param
	immutable Type type;

	@trusted void setIsUsed(LocalAccessKind kind) {
		if (isUsed != null) {
			(*isUsed)[kind] = true;
		}
	}
}

MutOpt!VariableRefAndType getIdentifierNonCall(
	ref Alloc alloc,
	ref LocalsInfo locals,
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
	} else
		return getIdentifierFromFunOrLambda(alloc, name, *locals.funOrLambda, accessKind);
}

MutOpt!(LocalNode*) getIdentifierInLocals(LocalNode* node, Symbol name, LocalAccessKind accessKind) {
	return node.local.name == name
		? someMut(node)
		: has(node.prev)
		? getIdentifierInLocals(force(node.prev), name, accessKind)
		: noneMut!(LocalNode*);
}

MutOpt!VariableRefAndType getIdentifierFromFunOrLambda(
	ref Alloc alloc,
	Symbol name,
	ref FunOrLambdaInfo info,
	LocalAccessKind accessKind,
) {
	foreach (size_t index, ref ClosureFieldBuilder field; asTemporaryArray(info.closureFields))
		if (field.name == name) {
			field.setIsUsed(accessKindInClosure(accessKind));
			return someMut(VariableRefAndType(
				VariableRef(ClosureRef(PtrAndSmallNumber!LambdaExpr(force(info.lambda), safeToUshort(index)))),
				field.mutability,
				field.isUsed,
				field.type));
		}

	MutOpt!VariableRefAndType optOuter = has(info.outer)
		? getIdentifierNonCall(alloc, *force(info.outer), name, accessKindInClosure(accessKind))
		: noneMut!VariableRefAndType;
	if (has(optOuter)) {
		VariableRefAndType outer = force(optOuter);
		size_t closureFieldIndex = mutMaxArrSize(info.closureFields);
		push(
			info.closureFields,
			ClosureFieldBuilder(name, outer.mutability, outer.isUsed, outer.type, outer.variableRef));
		outer.setIsUsed(accessKindInClosure(accessKind));
		return someMut(VariableRefAndType(
			VariableRef(ClosureRef(PtrAndSmallNumber!LambdaExpr(force(info.lambda), safeToUshort(closureFieldIndex)))),
			outer.mutability,
			outer.isUsed,
			outer.type));
	} else
		return noneMut!VariableRefAndType;
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

bool nameIsParameterOrLocalInScope(ref Alloc alloc, ref LocalsInfo locals, Symbol name) =>
	has(getIdentifierNonCall(alloc, locals, name, LocalAccessKind.getOnStack));

Expr checkIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in IdentifierAst ast,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType res = getIdentifierNonCall(ctx.alloc, locals, ast.name, LocalAccessKind.getOnStack);
	return has(res)
		? check(ctx, source, expected, force(res).type, toExpr(ctx.alloc, source, force(res).variableRef))
		: checkCallIdentifier(ctx, source, ast.name, expected);
}

Expr checkAssignIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
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
					ExprKind(allocate(ctx.alloc, LocalSetExpr(local, value))))),
			(ClosureRef x) =>
				check(ctx, source, expected, voidType(ctx), Expr(
					source,
					ExprKind(ClosureSetExpr(x, allocate(ctx.alloc, value))))));
	} else
		return checkCallSpecial(ctx, locals, source, prependSet(ctx.allSymbols, left), [*right], expected);
}

MutOpt!VariableRefAndType getVariableRefForSet(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, Symbol name) {
	MutOpt!VariableRefAndType opVar = getIdentifierNonCall(ctx.alloc, locals, name, LocalAccessKind.setOnStack);
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
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes, 1);
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
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes, 3);
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
bool contains(IntRange a, long value) =>
	a.min <= value && value <= a.max;

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
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, source, expected, allowedTypes, 3);
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

Expr checkLiteralString(ref ExprCtx ctx, ExprAst* source, scope string value, ref Expected expected) {
	StructInst* expectedStruct = expectedStructOrNull(ctx.instantiateCtx, expected);
	if (expectedStruct == ctx.commonTypes.char8) {
		char char_ = () {
			if (value.length != 1) {
				addDiag2(ctx, source, Diag(Diag.CharLiteralMustBeOneChar()));
				return 'a';
			} else
				return only(value);
		}();
		return Expr(source, ExprKind(allocate(ctx.alloc, LiteralExpr(Constant(Constant.Integral(char_))))));
	} else if (expectedStruct == ctx.commonTypes.symbol)
		return Expr(source, ExprKind(LiteralSymbolExpr(symbolOfString(ctx.allSymbols, value))));
	else if (expectedStruct == ctx.commonTypes.cString)
		return Expr(source, ExprKind(LiteralCStringExpr(copyToCString(ctx.alloc, value))));
	else {
		defaultExpectedToString(ctx, source, expected);
		return checkCallSpecialNoLocals(ctx, source, symbol!"literal", arrayOfSingle(source), expected);
	}
}

StructInst* expectedStructOrNull(ref InstantiateCtx ctx, ref const Expected expected) {
	Opt!Type expectedType = tryGetNonInferringType(ctx, expected);
	return has(expectedType) && force(expectedType).isA!(StructInst*)
		? force(expectedType).as!(StructInst*)
		: null;
}

void defaultExpectedToString(ref ExprCtx ctx, ExprAst* source, ref Expected expected) {
	setExpectedIfNoInferred(expected, () => getStringType(ctx, source));
}

Type getStringType(ref ExprCtx ctx, ExprAst* source) =>
	typeFromAst2(ctx, TypeAst(NameAndRange(source.range.start, symbol!"string")));

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
			return unreachable!(Opt!Expr);
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
	if (nameIsParameterOrLocalInScope(ctx.alloc, locals, local.name))
		addDiag2(ctx, localMustHaveNameRange(*local, ctx.allSymbols), Diag(
			Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.name)));

	LocalNode localNode = LocalNode(locals.locals, [false, false, false, false], local);
	LocalsInfo newLocals = LocalsInfo(locals.funOrLambda, someMut(ptrTrustMe(localNode)));
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
enum PointerMutability { immutable_, mutable }

ExpectedPointee getExpectedPointee(ref ExprCtx ctx, ref const Expected expected) {
	Opt!Type expectedType = tryGetNonInferringType(ctx.instantiateCtx, expected);
	if (has(expectedType) && force(expectedType).isA!(StructInst*)) {
		StructInst* inst = force(expectedType).as!(StructInst*);
		if (inst.decl == ctx.commonTypes.ptrConst)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(inst.typeArgs), PointerMutability.immutable_));
		else if (inst.decl == ctx.commonTypes.ptrMut)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(inst.typeArgs), PointerMutability.mutable));
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
		if (expectedMutability == PointerMutability.mutable)
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
	Expr fail() {
		addDiag2(ctx, source, Diag(Diag.PointerUnsupported()));
		return bogus(expected, source);
	}

	if (call.called.isA!(FunInst*)) {
		FunInst* getFieldFun = call.called.as!(FunInst*);
		if (getFieldFun.decl.body_.isA!(FunBody.RecordFieldGet)) {
			FunBody.RecordFieldGet rfg = getFieldFun.decl.body_.as!(FunBody.RecordFieldGet);
			Expr target = only(call.args);
			StructInst* recordType = only(getFieldFun.paramTypes).as!(StructInst*);
			PointerMutability fieldMutability = pointerMutabilityFromField(
				recordType.decl.body_.as!(StructBody.Record).fields[rfg.fieldIndex].mutability);
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < expectedMutability)
					addDiag2(ctx, source, Diag(Diag.PointerMutToConst(Diag.PointerMutToConst.Kind.field)));
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
					if (max(fieldMutability, pointerMutability) < expectedMutability)
						todo!void("diag: can't get mut* to immutable field");
					return check(ctx, source, expected, pointerType, Expr(source, ExprKind(allocate(ctx.alloc,
						PtrToFieldExpr(ExprAndType(targetPtr, derefedType), rfg.fieldIndex)))));
				} else
					return fail();
			} else
				return fail();
		} else
			return fail();
	} else
		return fail();
}

PointerMutability pointerMutabilityFromField(FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return PointerMutability.immutable_;
		case FieldMutability.private_:
		case FieldMutability.public_:
			return PointerMutability.mutable;
	}
}

bool isDerefFunction(ref ExprCtx ctx, FunInst* a) =>
	a.decl.body_.isA!(FunBody.Builtin) && a.decl.name == symbol!"*" && a.arity == Arity(1);

PointerMutability mutabilityForPtrDecl(in ExprCtx ctx, in StructDecl* a) {
	if (a == ctx.commonTypes.ptrConst)
		return PointerMutability.immutable_;
	else {
		assert(a == ctx.commonTypes.ptrMut);
		return PointerMutability.mutable;
	}
}

Expr checkFunPointer(ref ExprCtx ctx, ExprAst* source, in PtrAst ast, ref Expected expected) {
	if (!ast.inner.kind.isA!IdentifierAst)
		todo!void("diag: fun-pointer ast should just be an identifier");
	Symbol name = ast.inner.kind.as!IdentifierAst.name;
	MutArr!(FunDecl*) funs = MutArr!(FunDecl*)();
	eachFunInScope(funsInScope(ctx), name, (CalledDecl cd) {
		cd.matchWithPointers!void(
			(FunDecl* x) {
				markUsed(ctx.checkCtx, x);
				push(ctx.alloc, funs, x);
			},
			(SpecSig) {
				todo!void("!");
			});
	});
	if (mutArrSize(funs) != 1)
		todo!void("did not find or found too many");
	FunDecl* funDecl = funs[0];
	if (funDecl.isTemplate)
		todo!void("can't point to template");
	FunInst* funInst = instantiateFun(ctx.instantiateCtx, funDecl, emptyTypeArgs, emptySpecImpls);
	Type paramType = makeTupleType(ctx.instantiateCtx, ctx.commonTypes, funInst.paramTypes);
	StructInst* structInst = instantiateStructNeverDelay(
		ctx.instantiateCtx, ctx.commonTypes.funPtrStruct, [funInst.returnType, paramType]);
	return check(ctx, source, expected, Type(structInst), Expr(source, ExprKind(FunPtrExpr(funInst))));
}

Expr checkLambda(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref LambdaAst ast, ref Expected expected) {
	MutOpt!ExpectedLambdaType opEt = getExpectedLambdaType(ctx, source, expected, ast.param);
	if (!has(opEt))
		return bogus(expected, source);

	ExpectedLambdaType et = force(opEt);
	FunKind kind = et.kind;

	Destructure param = checkDestructure2(ctx, ast.param, et.instantiatedParamType);

	LambdaExpr* lambda = () @trusted { return allocateUninitialized!LambdaExpr(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo = FunOrLambdaInfo(someMut(ptrTrustMe(locals)), some(castImmutable(lambda)));
	initializeMutMaxArr(lambdaInfo.closureFields);

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	LocalsInfo bodyLocals = LocalsInfo(ptrTrustMe(lambdaInfo), noneMut!(LocalNode*));
	Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(
		expected,
		et.nonInstantiatedPossiblyFutReturnType,
		et.typeContext,
		(ref Expected returnTypeInferrer) =>
			checkExprWithDestructure(ctx, bodyLocals, param, &ast.body_, returnTypeInferrer));
	Expr body_ = bodyAndType.a;
	Type actualPossiblyFutReturnType = bodyAndType.b;

	VariableRef[] closureFields = checkClosure(ctx, source, kind, asTemporaryArray(lambdaInfo.closureFields));

	Type actualNonFutReturnType = kind == FunKind.far
		? unwrapFutureType(actualPossiblyFutReturnType, ctx)
		: actualPossiblyFutReturnType;
	StructInst* instFunStruct = instantiateStructNeverDelay(
		ctx.instantiateCtx, et.funStruct, [actualNonFutReturnType, param.type]);
	initMemory(lambda, LambdaExpr(
		param,
		body_,
		closureFields,
		kind,
		actualPossiblyFutReturnType));
	//TODO: this check should never fail, so could just set inferred directly with no check
	return check(ctx, source, expected, Type(instFunStruct), Expr(source, ExprKind(castImmutable(lambda))));
}

Type unwrapFutureType(Type a, in ExprCtx ctx) {
	if (a.isA!(Type.Bogus))
		return Type(Type.Bogus());
	else {
		assert(a.as!(StructInst*).decl == ctx.commonTypes.future);
		return only(a.as!(StructInst*).typeArgs);
	}
}

VariableRef[] checkClosure(ref ExprCtx ctx, ExprAst* source, FunKind kind, ClosureFieldBuilder[] closureFields) {
	final switch (kind) {
		case FunKind.fun:
			foreach (ref ClosureFieldBuilder cf; closureFields) {
				if (!isPurityAlwaysCompatibleConsideringSpecs(ctx.outermostFunSpecs, cf.type, Purity.shared_))
					addDiag2(ctx, source, Diag(
						Diag.LambdaClosesOverMut(cf.name, some(typeWithContainer(ctx, cf.type)))));
				else {
					final switch (cf.mutability) {
						case Mutability.immut:
							break;
						case Mutability.mut:
							addDiag2(ctx, source, Diag(Diag.LambdaClosesOverMut(cf.name, none!TypeWithContainer)));
					}
				}
			}
			break;
		case FunKind.act:
		case FunKind.far:
			break;
		case FunKind.pointer:
			todo!void("ensure no closure");
			break;
	}
	return map(ctx.alloc, closureFields, (ref ClosureFieldBuilder x) => x.variableRef);
}

Opt!Type typeFromDestructure(ref ExprCtx ctx, in DestructureAst ast) =>
	.typeFromDestructure(ctx.checkCtx, ctx.commonTypes, ast, ctx.structsAndAliasesMap, ctx.outermostFunTypeParams);

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
		LoopExpr* loop = allocate(ctx.alloc, LoopExpr(
			source.range,
			Expr(source, ExprKind(BogusExpr()))));
		LoopInfo info = LoopInfo(voidType(ctx), castImmutable(loop), type, false);
		scope Expected bodyExpected = Expected(&info);
		Expr body_ = checkExpr(ctx, locals, &ast.body_, castNonScope_ref(bodyExpected));
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
		return checkCallSpecial(ctx, locals, source, symbol!"loop-break", [ast.value], expected);
	else {
		LoopInfo* loop = force(optLoop);
		loop.hasBreak = true;
		Expr value = checkAndExpect(ctx, locals, &ast.value, loop.type);
		return Expr(
			source,
			ExprKind(allocate(ctx.alloc, LoopBreakExpr(loop.loop, value))));
	}
}

Expr checkLoopContinue(ref ExprCtx ctx, ExprAst* source, ref Expected expected) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	return has(optLoop)
		? Expr(source, ExprKind(LoopContinueExpr(force(optLoop).loop)))
		: checkCallSpecialNoLocals(ctx, source, symbol!"loop-continue", [], expected);
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
	StructBody body_ = matchedType.isA!(StructInst*)
		? matchedType.as!(StructInst*).decl.body_
		: StructBody(StructBody.Bogus());
	if (body_.isA!(StructBody.Enum))
		return checkMatchEnum(ctx, locals, source, *ast, expected, matchedAndType, body_.as!(StructBody.Enum).members);
	else if (body_.isA!(StructBody.Union))
		return checkMatchUnion(
			ctx, locals, source, *ast, expected, matchedAndType,
			body_.as!(StructBody.Union).members,
			matchedType.as!(StructInst*).instantiatedTypes);
	else {
		if (!matchedType.isA!(Type.Bogus))
			addDiag2(ctx, ast.matched.range, Diag(Diag.MatchOnNonUnion(typeWithContainer(ctx, matchedType))));
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
	in StructBody.Enum.Member[] members,
) {
	bool goodCases = arraysCorrespond!(StructBody.Enum.Member, MatchAst.CaseAst)(
		members,
		ast.cases,
		(ref StructBody.Enum.Member member, ref MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, source, Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref StructBody.Enum.Member member) => member.name))));
		return bogus(expected, source);
	} else {
		Expr[] cases = mapPointers(ctx.alloc, ast.cases, (MatchAst.CaseAst* caseAst) {
			if (has(caseAst.destructure))
				todo!void("diag: enum match has no value");
			return checkExpr(ctx, locals, &caseAst.then, expected);
		});
		return Expr(
			source,
			ExprKind(allocate(ctx.alloc, MatchEnumExpr(matched, cases))));
	}
}

Expr checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ExprAst* source,
	in MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	in UnionMember[] declaredMembers,
	in Type[] instantiatedTypes,
) {
	bool goodCases = arraysCorrespond!(UnionMember, MatchAst.CaseAst)(
		declaredMembers,
		ast.cases,
		(ref UnionMember member, ref MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, source, Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, declaredMembers, (ref UnionMember member) => member.name))));
		return bogus(expected, source);
	} else {
		MatchUnionExpr.Case[] cases =
			mapZipPointers3!(MatchUnionExpr.Case, UnionMember, Type, MatchAst.CaseAst)(
				ctx.alloc, declaredMembers, instantiatedTypes, ast.cases,
				(UnionMember* member, Type* type, MatchAst.CaseAst* caseAst) =>
					checkMatchCase(ctx, locals, member, *type, caseAst, expected));
		return Expr(source, ExprKind(allocate(ctx.alloc, MatchUnionExpr(matched, cases))));
	}
}

MatchUnionExpr.Case checkMatchCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UnionMember* member,
	Type memberType,
	MatchAst.CaseAst* caseAst,
	ref Expected expected,
) {
	immutable DestructureAst destructureVoidAst = DestructureAst(DestructureAst.Void());
	Destructure destructure = checkDestructure2(
		ctx, has(caseAst.destructure) ? force(caseAst.destructure) : destructureVoidAst, memberType);
	return MatchUnionExpr.Case(
		destructure, checkExprWithDestructure(ctx, locals, destructure, &caseAst.then, expected));
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
	ExprAst lambdaBody = ExprAst(source.range, ExprAstKind(allocate(ctx.alloc, LambdaAst(ast.param, ast.body_))));
	Symbol funName = hasBreakOrContinue(ast.body_) ? symbol!"for-break" : symbol!"for-loop";
	if (!ast.else_.kind.isA!EmptyAst) {
		// TODO: NO ALLOC
		ExprAst lambdaElse_ = ExprAst(ast.else_.range, ExprAstKind(
			allocate(ctx.alloc, LambdaAst(DestructureAst(DestructureAst.Void(source.range.start)), ast.else_))));
		return checkCallSpecial(ctx, locals, source, funName, [ast.collection, lambdaBody, lambdaElse_], expected);
	} else
		return checkCallSpecial(ctx, locals, source, funName, [ast.collection, lambdaBody], expected);
}

Expr checkWith(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref WithAst ast, ref Expected expected) {
	if (!ast.else_.kind.isA!(EmptyAst))
		todo!void("diag: no 'else' for 'with'");
	// TODO: NO ALLOC
	ExprAst lambda = ExprAst(source.range, ExprAstKind(allocate(ctx.alloc, LambdaAst(ast.param, ast.body_))));
	return checkCallSpecial(ctx, locals, source, symbol!"with-block", [ast.arg, lambda], expected);
}

Expr checkThen(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, ref ThenAst ast, ref Expected expected) {
	// TODO: NO ALLOC
	ExprAst lambda = ExprAst(source.range, ExprAstKind(allocate(ctx.alloc, LambdaAst(ast.left, ast.then))));
	return checkCallSpecial(ctx, locals, source, symbol!"then", [ast.futExpr, lambda], expected);
}

Expr checkTyped(ref ExprCtx ctx, ref LocalsInfo locals, ExprAst* source, TypedAst* ast, ref Expected expected) {
	Type type = typeFromAst2(ctx, ast.type);
	Opt!Type inferred = tryGetNonInferringType(ctx.instantiateCtx, expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, source, Diag(Diag.TypeAnnotationUnnecessary(typeWithContainer(ctx, type))));
	Expr expr = checkAndExpect(ctx, locals, &ast.expr, type);
	return check(ctx, source, expected, type, expr);
}
