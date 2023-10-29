module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall.candidates : eachFunInScope, funsInScope;
import frontend.check.checkCall.checkCall : checkCall, checkCallIdentifier, checkCallSpecial, checkCallSpecialNoLocals;
import frontend.check.checkCall.checkCallSpecs : isPurityAlwaysCompatibleConsideringSpecs;
import frontend.check.checkCtx : CheckCtx, markUsed;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	checkCanDoUnsafe,
	ClosureFieldBuilder,
	Expected,
	ExprCtx,
	findExpectedStructForLiteral,
	FunOrLambdaInfo,
	FunType,
	getExpectedForDiag,
	getFunType,
	handleExpectedLambda,
	inferred,
	InferringTypeArgs,
	LocalAccessKind,
	LocalNode,
	LocalsInfo,
	LoopInfo,
	markIsUsedSetOnStack,
	OkSkipOrAbort,
	Pair,
	programState,
	rangeInFile2,
	setExpectedIfNoInferred,
	tryGetDeeplyInstantiatedTypeWorker,
	tryGetInferred,
	tryGetLoop,
	typeFromAst2,
	withCopyWithNewExpectedType,
	withTrusted;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay, noDelayStructInsts;
import frontend.check.maps : FunsMap, StructsAndAliasesMap;
import frontend.check.typeFromAst : checkDestructure, makeFutType, makeTupleType, typeFromDestructure;
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
import model.diag : Diag;
import model.model :
	Arity,
	arity,
	body_,
	Called,
	CalledDecl,
	ClosureRef,
	CommonTypes,
	decl,
	Destructure,
	Expr,
	ExprAndType,
	ExprKind,
	FieldMutability,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	IntegralTypes,
	isDefinitelyByRef,
	isTemplate,
	Local,
	LocalMutability,
	Mutability,
	name,
	Purity,
	range,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	toMutability,
	Type,
	typeArgs,
	TypeParam,
	UnionMember,
	VariableRef;
import util.alloc.alloc : Alloc, allocateUninitialized;
import util.col.arr : empty, only, PtrAndSmallNumber;
import util.col.arrUtil : append, arrLiteral, arrsCorrespond, contains, exists, map, mapZipPtrFirst3;
import util.col.mutArr : MutArr, mutArrSize, push, tempAsArr;
import util.col.mutMaxArr : initializeMutMaxArr, mutMaxArrSize, push, tempAsArr;
import util.col.str : copyToSafeCStr;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, initMemory, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, someMut, some;
import util.ptr : castImmutable, castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : UriAndRange, Pos, RangeWithinFile;
import util.sym : prependSet, prependSetDeref, Sym, sym, symOfStr;
import util.union_ : Union;
import util.util : max, todo, unreachable, verify;

Expr checkFunctionBody(
	ref CheckCtx checkCtx,
	in StructsAndAliasesMap structsAndAliasesMap,
	in CommonTypes commonTypes,
	in FunsMap funsMap,
	Type returnType,
	Sym funName,
	TypeParam[] typeParams,
	Destructure[] params,
	in immutable SpecInst*[] specs,
	in FunFlags flags,
	in ExprAst ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesMap,
		funsMap,
		commonTypes,
		funName,
		specs,
		params,
		typeParams,
		flags);
	// leave funInfo.closureFields uninitialized, it won't be used
	FunOrLambdaInfo funInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), none!(ExprKind.Lambda*));
	Expr res = checkWithParamDestructures(castNonScope_ref(exprCtx), funInfo, params, (ref LocalsInfo innerLocals) =>
		checkAndExpect(castNonScope_ref(exprCtx), innerLocals, ast, returnType));
	return res;
}

Expr checkExpr(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast, ref Expected expected) {
	UriAndRange range = rangeInFile2(ctx, ast.range);
	return ast.kind.matchIn!Expr(
		(in ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, range, a, expected),
		(in AssertOrForbidAst a) =>
			checkAssertOrForbid(ctx, locals, range, a, expected),
		(in AssignmentAst a) =>
			checkAssignment(ctx, locals, range, a, expected),
		(in AssignmentCallAst a) =>
			checkAssignmentCall(ctx, locals, range, a, expected),
		(in BogusAst _) =>
			bogus(expected, range),
		(in CallAst a) =>
			checkCall(ctx, locals, range, a, expected),
		(in EmptyAst a) =>
			checkEmptyNew(ctx, range, expected),
		(in ForAst a) =>
			checkFor(ctx, locals, range, a, expected),
		(in IdentifierAst a) =>
			checkIdentifier(ctx, locals, range, a, expected),
		(in IfAst a) =>
			checkIf(ctx, locals, range, a, expected),
		(in IfOptionAst a) =>
			checkIfOption(ctx, locals, range, a, expected),
		(in InterpolatedAst a) =>
			checkInterpolated(ctx, locals, range, a, expected),
		(in LambdaAst a) =>
			checkLambda(ctx, locals, range, a, expected),
		(in LetAst a) =>
			checkLet(ctx, locals, range, a, expected),
		(in LiteralFloatAst a) =>
			checkLiteralFloat(ctx, range, a, expected),
		(in LiteralIntAst a) =>
			checkLiteralInt(ctx, range, a, expected),
		(in LiteralNatAst a) =>
			checkLiteralNat(ctx, range, a, expected),
		(in LiteralStringAst a) =>
			checkLiteralString(ctx, range, ast, a.value, expected),
		(in LoopAst a) =>
			checkLoop(ctx, locals, range, a, expected),
		(in LoopBreakAst a) =>
			checkLoopBreak(ctx, locals, range, a, expected),
		(in LoopContinueAst _) =>
			checkLoopContinue(ctx, range, expected),
		(in LoopUntilAst a) =>
			checkLoopUntil(ctx, locals, range, a, expected),
		(in LoopWhileAst a) =>
			checkLoopWhile(ctx, locals, range, a, expected),
		(in MatchAst a) =>
			checkMatch(ctx, locals, range, a, expected),
		(in ParenthesizedAst a) =>
			checkExpr(ctx, locals, a.inner, expected),
		(in PtrAst a) =>
			checkPtr(ctx, locals, range, a, expected),
		(in SeqAst a) =>
			checkSeq(ctx, locals, range, a, expected),
		(in ThenAst a) =>
			checkThen(ctx, locals, range, a, expected),
		(in ThrowAst a) =>
			checkThrow(ctx, locals, range, a, expected),
		(in TrustedAst a) =>
			withTrusted!Expr(ctx, range, () => checkExpr(ctx, locals, a.inner, expected)),
		(in TypedAst a) =>
			checkTyped(ctx, locals, range, a, expected),
		(in UnlessAst a) =>
			checkUnless(ctx, locals, range, a, expected),
		(in WithAst a) =>
			checkWith(ctx, locals, range, a, expected));
}

private:

Expr checkWithParamDestructures(
	ref ExprCtx ctx,
	ref FunOrLambdaInfo funInfo,
	Destructure[] params,
	in Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) {
	LocalsInfo locals = LocalsInfo(ptrTrustMe(funInfo), noneMut!(LocalNode*));
	Opt!Expr res = checkWithParamDestructuresRecur(ctx, locals, params, (ref LocalsInfo innerLocals) =>
		some(cb(innerLocals)));
	return has(res) ? force(res) : Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()));
}
Opt!Expr checkWithParamDestructuresRecur(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Destructure[] params,
	in Opt!Expr delegate(ref LocalsInfo) @safe @nogc pure nothrow cb,
) =>
	empty(params)
		? cb(locals)
		: checkWithDestructure(ctx, locals, params[0], (ref LocalsInfo innerLocals) =>
			checkWithParamDestructuresRecur(ctx, innerLocals, params[1 .. $], cb));

ExprAndType checkAndInfer(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast) {
	Expected expected = Expected(Expected.Infer());
	Expr expr = checkExpr(ctx, locals, ast, expected);
	return ExprAndType(expr, inferred(expected));
}

ExprAndType checkAndExpectOrInfer(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast, Opt!Type optExpected) =>
	has(optExpected)
		? ExprAndType(checkAndExpect(ctx, locals, ast, force(optExpected)), force(optExpected))
		: checkAndInfer(ctx, locals, ast);

Expr checkAndExpect(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast, Type expected) {
	Expected et = Expected(expected);
	return checkExpr(ctx, locals, ast, et);
}

Expr checkAndExpectBool(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.bool_));

Expr checkAndExpectCStr(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, Type(ctx.commonTypes.cString));

Expr checkAndExpectVoid(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, voidType(ctx));

Type voidType(ref const ExprCtx ctx) =>
	Type(ctx.commonTypes.void_);

Expr checkArrowAccess(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in ArrowAccessAst ast,
	ref Expected expected,
) {
	ExprAst[1] derefArgs = [*ast.left];
	CallAst callDeref =
		CallAst(CallAst.style.single, NameAndRange(range.range.start, sym!"*"), castNonScope(derefArgs));
	return checkCallSpecial(
		ctx, locals, range, ast.name.name, [ExprAst(range.range, ExprAstKind(callDeref))], expected);
}

Expr checkIf(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in IfAst ast, ref Expected expected) {
	Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	Expr then = checkExpr(ctx, locals, ast.then, expected);
	Expr else_ = checkExpr(ctx, locals, ast.else_, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.If(cond, then, else_))));
}

Expr checkThrow(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in ThrowAst ast, ref Expected expected) {
	Opt!Type inferred = tryGetInferred(expected);
	if (has(inferred)) {
		Expr thrown = checkAndExpectCStr(ctx, locals, ast.thrown);
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Throw(thrown))));
	} else {
		addDiag2(ctx, range, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, range);
	}
}

Expr checkAssertOrForbid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in AssertOrForbidAst ast,
	ref Expected expected,
) {
	Expr* condition = allocate(ctx.alloc, checkAndExpectBool(ctx, locals, ast.condition));
	Opt!(Expr*) thrown = has(ast.thrown)
		? some(allocate(ctx.alloc, checkAndExpectCStr(ctx, locals, force(ast.thrown))))
		: none!(Expr*);
	return check(ctx, expected, voidType(ctx), Expr(
		range,
		ExprKind(ExprKind.AssertOrForbid(ast.kind, condition, thrown))));
}

Expr checkAssignment(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in AssignmentAst ast,
	ref Expected expected,
) =>
	checkAssignment(ctx, locals, range, ast.left, ast.right, expected);

Expr checkAssignment(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in ExprAst left,
	in ExprAst right,
	ref Expected expected,
) {
	if (left.kind.isA!IdentifierAst)
		return checkAssignIdentifier(ctx, locals, range, left.kind.as!IdentifierAst.name, right, expected);
	else if (left.kind.isA!CallAst) {
		CallAst leftCall = left.kind.as!CallAst;
		Opt!Sym name = () {
			switch (leftCall.style) {
				case CallAst.Style.dot:
					return some(prependSet(ctx.allSymbols, leftCall.funNameName));
				case CallAst.Style.prefixOperator:
					return leftCall.funNameName == sym!"*" ? some(sym!"set-deref") : none!Sym;
				case CallAst.Style.subscript:
					return some(sym!"set-subscript");
				default:
					return none!Sym;
			}
		}();
		if (has(name)) {
			//TODO:PERF use temp alloc
			ExprAst[] args = append(ctx.alloc, leftCall.args, right);
			return checkCallSpecial(ctx, locals, range, force(name), args, expected);
		} else {
			addDiag2(ctx, range, Diag(Diag.AssignmentNotAllowed()));
			return bogus(expected, range);
		}
	} else if (left.kind.isA!ArrowAccessAst) {
		ArrowAccessAst leftArrow = left.kind.as!ArrowAccessAst;
		ExprAst[2] args = [*leftArrow.left, right];
		return checkCallSpecial(
			ctx, locals, range, prependSetDeref(ctx.allSymbols, leftArrow.name.name), args, expected);
	} else {
		addDiag2(ctx, range, Diag(Diag.AssignmentNotAllowed()));
		return bogus(expected, range);
	}
}

Expr checkAssignmentCall(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in AssignmentCallAst ast,
	ref Expected expected,
) {
	ExprAst[2] args = [castNonScope_ref(ast.left), castNonScope_ref(ast.right)];
	return checkAssignment(
		ctx, locals, range, ast.left,
		ExprAst(range.range, ExprAstKind(CallAst(
			CallAst.style.infix,
			ast.funName,
			args))),
		expected);
}

Expr checkUnless(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in UnlessAst ast,
	ref Expected expected,
) {
	Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	Expr else_ = checkExpr(ctx, locals, ast.body_, expected);
	Expr then = checkEmptyNew(ctx, range, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.If(cond, then, else_))));
}

Expr checkEmptyNew(ref ExprCtx ctx, in UriAndRange range, ref Expected expected) =>
	checkCallSpecialNoLocals(ctx, range, sym!"new", [], expected);

Expr checkIfOption(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in IfOptionAst ast,
	ref Expected expected,
) {
	// We don't know the cond type, except that it's an option
	ExprAndType option = checkAndInfer(ctx, locals, ast.option);
	StructInst* inst = option.type.isA!(StructInst*)
		? option.type.as!(StructInst*)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (decl(*inst) != ctx.commonTypes.opt) {
		addDiag2(ctx, range, Diag(Diag.IfNeedsOpt(option.type)));
		return bogus(expected, range);
	} else {
		Type nonOptionalType = only(typeArgs(*inst));
		Destructure destructure = checkDestructure(ctx, ast.destructure, nonOptionalType);
		Expr then = checkExprWithDestructure(ctx, locals, destructure, ast.then, expected);
		Expr else_ = checkExpr(ctx, locals, ast.else_, expected);
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.IfOption(destructure, option, then, else_))));
	}
}

Expr checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in InterpolatedAst ast,
	ref Expected expected,
) {
	defaultExpectedToString(ctx, range, expected);
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> "a" ~~ b.to ~~ "c"
	CallAst call = checkInterpolatedRecur(ctx, ast.parts, range.start + 1, none!ExprAst);
	Opt!Type inferred = tryGetInferred(expected);
	CallAst callAndConvert = has(inferred) && !isString(force(inferred))
		? CallAst(
			//TODO: new kind (not infix)
			CallAst.Style.infix,
			NameAndRange(range.start, sym!"to"),
			// TODO: NO ALLOC
			arrLiteral!ExprAst(ctx.alloc, [ExprAst(range.range, ExprAstKind(call))]))
		: call;
	return checkCall(ctx, locals, range, callAndConvert, expected);
}

bool isString(Type a) =>
	// TODO: better
	a.isA!(StructInst*) && decl(*a.as!(StructInst*)).name == sym!"string";

CallAst checkInterpolatedRecur(ref ExprCtx ctx, in InterpolatedPart[] parts, Pos pos, in Opt!ExprAst left) {
	ExprAst right = parts[0].matchIn!ExprAst(
		(in string it) =>
			// TODO: this length may be wrong in the presence of escapes
			ExprAst(RangeWithinFile(pos, safeToUint(pos + it.length)), ExprAstKind(LiteralStringAst(it))),
		(in ExprAst e) @safe =>
			ExprAst(e.range, ExprAstKind(CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				NameAndRange(pos, sym!"to"),
				// TODO: NO ALLOC
				arrLiteral!ExprAst(ctx.alloc, [castNonScope_ref(e)])))));
	Pos newPos = parts[0].matchIn!Pos(
		(in string x) =>
			// TODO: this length may be wrong in the presence of escapes
			safeToUint(pos + x.length),
		(in ExprAst x) =>
			x.range.end + 1);
	ExprAst newLeft = has(left)
		? ExprAst(
			RangeWithinFile(pos, newPos),
			ExprAstKind(CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				NameAndRange(pos, sym!"~~"),
				// TODO: NO ALLOC
				arrLiteral!ExprAst(ctx.alloc, [castNonScope_ref(force(left)), right]))))
		: right;
	scope InterpolatedPart[] rest = parts[1 .. $];
	return empty(rest)
		? newLeft.kind.as!CallAst
		: checkInterpolatedRecur(ctx, rest, newPos, some(newLeft));
}

struct ExpectedLambdaType {
	InferringTypeArgs inferringTypeArgs;
	StructInst* funStructInst;
	StructDecl* funStruct;
	FunKind kind;
	Type nonInstantiatedPossiblyFutReturnType;
	Type instantiatedParamType;
}

MutOpt!ExpectedLambdaType getExpectedLambdaType(
	ref ExprCtx ctx,
	UriAndRange range,
	ref Expected expected,
	in DestructureAst destructure,
) {
	Opt!Type declaredParamType = typeFromDestructure(ctx, destructure);
	if (has(declaredParamType) && force(declaredParamType).isA!(Type.Bogus))
		return noneMut!ExpectedLambdaType;
	OkSkipOrAbort!ExpectedLambdaType res = handleExpectedLambda!ExpectedLambdaType(
		ctx.alloc, expected, (Type expectedType, InferringTypeArgs funTypeInferring) {
			Opt!FunType optFunType = getFunType(ctx.commonTypes, expectedType);
			if (has(optFunType)) {
				FunType funType = force(optFunType);
				Opt!Type optExpectedParamType = tryGetDeeplyInstantiatedTypeWorker(
					ctx.alloc, ctx.programState, funType.nonInstantiatedParamType, funTypeInferring);
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
						? makeFutType(
							ctx.alloc, ctx.programState, ctx.commonTypes, funType.nonInstantiatedNonFutReturnType)
						: funType.nonInstantiatedNonFutReturnType;
					return ExpectedLambdaType(
						funTypeInferring,
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
			addDiag2(ctx, range, Diag(Diag.LambdaNotExpected(getExpectedForDiag(ctx.alloc, expected))));
			return noneMut!ExpectedLambdaType;
		},
		(OkSkipOrAbort!ExpectedLambdaType.Abort x) {
			addDiag2(ctx, range, x.diag);
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
	Sym name,
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

MutOpt!(LocalNode*) getIdentifierInLocals(LocalNode* node, Sym name, LocalAccessKind accessKind) {
	return node.local.name == name
		? someMut(node)
		: has(node.prev)
		? getIdentifierInLocals(force(node.prev), name, accessKind)
		: noneMut!(LocalNode*);
}

MutOpt!VariableRefAndType getIdentifierFromFunOrLambda(
	ref Alloc alloc,
	Sym name,
	ref FunOrLambdaInfo info,
	LocalAccessKind accessKind,
) {
	foreach (size_t index, ref ClosureFieldBuilder field; tempAsArr(info.closureFields))
		if (field.name == name) {
			field.setIsUsed(accessKindInClosure(accessKind));
			return someMut(VariableRefAndType(
				VariableRef(ClosureRef(PtrAndSmallNumber!(ExprKind.Lambda)(force(info.lambda), safeToUshort(index)))),
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
			VariableRef(ClosureRef(
				PtrAndSmallNumber!(ExprKind.Lambda)(force(info.lambda), safeToUshort(closureFieldIndex)))),
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

bool nameIsParameterOrLocalInScope(ref Alloc alloc, ref LocalsInfo locals, Sym name) =>
	has(getIdentifierNonCall(alloc, locals, name, LocalAccessKind.getOnStack));

Expr checkIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in IdentifierAst ast,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType res = getIdentifierNonCall(ctx.alloc, locals, ast.name, LocalAccessKind.getOnStack);
	return has(res)
		? check(ctx, expected, force(res).type, toExpr(ctx.alloc, range, force(res).variableRef))
		: checkCallIdentifier(ctx, range, ast.name, expected);
}

Expr checkAssignIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in Sym left,
	in ExprAst right,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType optVar = getVariableRefForSet(ctx, locals, range, left);
	if (has(optVar)) {
		VariableRefAndType var = force(optVar);
		Expr value = checkAndExpect(ctx, locals, right, var.type);
		return var.variableRef.matchWithPointers!Expr(
			(Local* local) =>
				check(ctx, expected, voidType(ctx), Expr(
					range,
					ExprKind(allocate(ctx.alloc, ExprKind.LocalSet(local, value))))),
			(ClosureRef cr) =>
				check(ctx, expected, voidType(ctx), Expr(
					range,
					ExprKind(ExprKind.ClosureSet(allocate(ctx.alloc, cr), allocate(ctx.alloc, value))))));
	} else
		return checkCallSpecial!1(ctx, locals, range, prependSet(ctx.allSymbols, left), [right], expected);
}

MutOpt!VariableRefAndType getVariableRefForSet(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, Sym name) {
	MutOpt!VariableRefAndType opVar = getIdentifierNonCall(ctx.alloc, locals, name, LocalAccessKind.setOnStack);
	if (has(opVar)) {
		VariableRefAndType var = force(opVar);
		final switch (var.mutability) {
			case Mutability.immut:
				addDiag2(ctx, range, Diag(Diag.LocalNotMutable(var.variableRef)));
				break;
			case Mutability.mut:
				break;
		}
		return someMut(var);
	} else
		return noneMut!VariableRefAndType;
}

Expr toExpr(ref Alloc alloc, UriAndRange range, VariableRef a) =>
	a.matchWithPointers!Expr(
		(Local* x) =>
			Expr(range, ExprKind(ExprKind.LocalGet(x))),
		(ClosureRef x) =>
			Expr(range, ExprKind(ExprKind.ClosureGet(allocate(alloc, x)))));

Expr checkLiteralFloat(ref ExprCtx ctx, UriAndRange range, in LiteralFloatAst ast, ref Expected expected) {
	immutable StructInst*[2] allowedTypes = [ctx.commonTypes.float32, ctx.commonTypes.float64];
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, range, expected, allowedTypes, 1);
	if (has(opTypeIndex)) {
		StructInst* numberType = allowedTypes[force(opTypeIndex)];
		if (ast.overflow)
			addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
		return asFloat(ctx, range, numberType, ast.value, expected);
	} else
		return bogus(expected, range);
}

bool isFloatType(in CommonTypes commonTypes, StructInst* numberType) =>
	numberType == commonTypes.float32 || numberType == commonTypes.float64;

Expr asFloat(
	ref ExprCtx ctx,
	UriAndRange range,
	StructInst* numberType,
	double value,
	ref Expected expected,
) {
	verify(isFloatType(ctx.commonTypes, numberType));
	return check(ctx, expected, Type(numberType), Expr(range, ExprKind(
		allocate(ctx.alloc, ExprKind.Literal(Constant(Constant.Float(value)))))));
}

Expr checkLiteralInt(ref ExprCtx ctx, UriAndRange range, in LiteralIntAst ast, ref Expected expected) {
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
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, range, expected, allowedTypes, 3);
	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		StructInst* numberType = allowedTypes[typeIndex];
		if (isFloatType(ctx.commonTypes, numberType))
			return asFloat(ctx, range, numberType, cast(double) ast.value, expected);
		else {
			Constant constant = Constant(Constant.Integral(ast.value));
			if (ast.overflow || !contains(ranges[typeIndex], ast.value))
				addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
			return check(ctx, expected, Type(numberType), Expr(range, ExprKind(
				allocate(ctx.alloc, ExprKind.Literal(constant)))));
		}
	} else
		return bogus(expected, range);
}
immutable struct IntRange {
	long min;
	long max;
}
bool contains(IntRange a, long value) =>
	a.min <= value && value <= a.max;

Expr checkLiteralNat(ref ExprCtx ctx, UriAndRange range, in LiteralNatAst ast, ref Expected expected) {
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
	Opt!size_t opTypeIndex = findExpectedStructForLiteral(ctx, range, expected, allowedTypes, 3);
	if (has(opTypeIndex)) {
		size_t typeIndex = force(opTypeIndex);
		StructInst* numberType = allowedTypes[typeIndex];
		if (isFloatType(ctx.commonTypes, numberType))
			return asFloat(ctx, range, numberType, cast(double) ast.value, expected);
		else {
			Constant constant = Constant(Constant.Integral(ast.value));
			if (ast.overflow || ast.value > maximums[typeIndex])
				addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
			return check(ctx, expected, Type(numberType), Expr(range, ExprKind(
				allocate(ctx.alloc, ExprKind.Literal(constant)))));
		}
	} else
		return bogus(expected, range);
}

Expr checkLiteralString(
	ref ExprCtx ctx,
	UriAndRange range,
	in ExprAst curAst,
	scope string value,
	ref Expected expected,
) {
	StructInst* expectedStruct = expectedStructOrNull(expected);
	if (expectedStruct == ctx.commonTypes.char8) {
		char char_ = () {
			if (value.length != 1) {
				addDiag2(ctx, range, Diag(Diag.CharLiteralMustBeOneChar()));
				return 'a';
			} else
				return only(value);
		}();
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Literal(Constant(Constant.Integral(char_))))));
	} else if (expectedStruct == ctx.commonTypes.symbol)
		return Expr(range, ExprKind(ExprKind.LiteralSymbol(symOfStr(ctx.allSymbols, value))));
	else if (expectedStruct == ctx.commonTypes.cString)
		return Expr(range, ExprKind(ExprKind.LiteralCString(copyToSafeCStr(ctx.alloc, value))));
	else {
		defaultExpectedToString(ctx, range, expected);
		return checkCallSpecialNoLocals(ctx, range, sym!"literal", [castNonScope_ref(curAst)], expected);
	}
}

StructInst* expectedStructOrNull(ref const Expected expected) {
	Opt!Type expectedType = tryGetInferred(expected);
	return has(expectedType) && force(expectedType).isA!(StructInst*)
		? force(expectedType).as!(StructInst*)
		: null;
}

void defaultExpectedToString(ref ExprCtx ctx, UriAndRange range, ref Expected expected) {
	setExpectedIfNoInferred(expected, () => getStringType(ctx, range));
}

Type getStringType(ref ExprCtx ctx, UriAndRange range) =>
	typeFromAst2(ctx, TypeAst(NameAndRange(range.start, sym!"string")));

Expr checkExprWithDestructure(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref Destructure destructure,
	in ExprAst ast,
	ref Expected expected,
) {
	Opt!Expr res = checkWithDestructure(ctx, locals, destructure, (ref LocalsInfo innerLocals) =>
		some(checkExpr(ctx, innerLocals, ast, expected)));
	return has(res) ? force(res) : bogus(expected, rangeInFile2(ctx, ast.range));
}
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
		addDiag2(ctx, local.range, Diag(
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
		addDiag2(ctx, local.range, Diag(Diag.Unused(Diag.Unused.Kind(Diag.Unused.Kind.Local(local, isGot, isSet)))));
}

Expr checkPtr(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in PtrAst ast, ref Expected expected) {
	return getExpectedPointee(ctx, expected).match!Expr(
		(ExpectedPointee.None) {
			addDiag2(ctx, range, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.pointer)));
			return bogus(expected, range);
		},
		(ExpectedPointee.FunPointer) =>
			checkFunPointer(ctx, range, ast, expected),
		(ExpectedPointee.Pointer x) =>
			checkPtrInner(ctx, locals, range, ast, x.pointer, x.pointee, x.mutability, expected));
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

ExpectedPointee getExpectedPointee(ref ExprCtx ctx, in Expected expected) {
	Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType) && force(expectedType).isA!(StructInst*)) {
		StructInst* inst = force(expectedType).as!(StructInst*);
		StructDecl* decl = decl(*inst);
		if (decl == ctx.commonTypes.ptrConst)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(typeArgs(*inst)), PointerMutability.immutable_));
		else if (decl == ctx.commonTypes.ptrMut)
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst), only(typeArgs(*inst)), PointerMutability.mutable));
		else if (decl == ctx.commonTypes.funPtrStruct)
			return ExpectedPointee(ExpectedPointee.FunPointer());
		else
			return ExpectedPointee(ExpectedPointee.None());
	} else
		return ExpectedPointee(ExpectedPointee.None());
}

Expr checkPtrInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in PtrAst ast,
	Type pointerType,
	Type pointeeType,
	PointerMutability expectedMutability,
	ref Expected expected,
) {
	if (!checkCanDoUnsafe(ctx))
		addDiag2(ctx, range, Diag(Diag.PtrIsUnsafe()));
	Expr inner = checkAndExpect(ctx, locals, ast.inner, pointeeType);
	if (inner.kind.isA!(ExprKind.LocalGet)) {
		Local* local = inner.kind.as!(ExprKind.LocalGet).local;
		if (local.mutability < expectedMutability)
			addDiag2(ctx, range, Diag(Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.local)));
		if (expectedMutability == PointerMutability.mutable)
			markIsUsedSetOnStack(locals, local);
		return check(ctx, expected, pointerType, Expr(range, ExprKind(ExprKind.PtrToLocal(local))));
	} else if (inner.kind.isA!(ExprKind.Call))
		return checkPtrOfCall(ctx, range, inner.kind.as!(ExprKind.Call), pointerType, expectedMutability, expected);
	else {
		addDiag2(ctx, range, Diag(Diag.PtrUnsupported()));
		return bogus(expected, range);
	}
}

Expr checkPtrOfCall(
	ref ExprCtx ctx,
	UriAndRange range,
	ExprKind.Call call,
	Type pointerType,
	PointerMutability expectedMutability,
	ref Expected expected,
) {
	Expr fail() {
		addDiag2(ctx, range, Diag(Diag.PtrUnsupported()));
		return bogus(expected, range);
	}

	if (call.called.isA!(FunInst*)) {
		FunInst* getFieldFun = call.called.as!(FunInst*);
		if (decl(*getFieldFun).body_.isA!(FunBody.RecordFieldGet)) {
			FunBody.RecordFieldGet rfg = decl(*getFieldFun).body_.as!(FunBody.RecordFieldGet);
			Expr target = only(call.args);
			StructInst* recordType = only(getFieldFun.paramTypes).as!(StructInst*);
			PointerMutability fieldMutability = pointerMutabilityFromField(
				body_(*decl(*recordType)).as!(StructBody.Record).fields[rfg.fieldIndex].mutability);
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < expectedMutability)
					addDiag2(ctx, range, Diag(Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.field)));
				return check(ctx, expected, pointerType, Expr(range, ExprKind(allocate(ctx.alloc,
					ExprKind.PtrToField(ExprAndType(target, Type(recordType)), rfg.fieldIndex)))));
			} else if (target.kind.isA!(ExprKind.Call)) {
				ExprKind.Call targetCall = target.kind.as!(ExprKind.Call);
				Called called = targetCall.called;
				if (called.isA!(FunInst*) && isDerefFunction(ctx, called.as!(FunInst*))) {
					FunInst* derefFun = called.as!(FunInst*);
					Type derefedType = only(derefFun.paramTypes);
					PointerMutability pointerMutability =
						mutabilityForPtrDecl(ctx, decl(*derefedType.as!(StructInst*)));
					Expr targetPtr = only(targetCall.args);
					if (max(fieldMutability, pointerMutability) < expectedMutability)
						todo!void("diag: can't get mut* to immutable field");
					return check(ctx, expected, pointerType, Expr(range, ExprKind(allocate(ctx.alloc,
						ExprKind.PtrToField(ExprAndType(targetPtr, derefedType), rfg.fieldIndex)))));
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
	decl(*a).body_.isA!(FunBody.Builtin) && decl(*a).name == sym!"*" && arity(*a) == Arity(1);

PointerMutability mutabilityForPtrDecl(in ExprCtx ctx, in StructDecl* a) {
	if (a == ctx.commonTypes.ptrConst)
		return PointerMutability.immutable_;
	else {
		verify(a == ctx.commonTypes.ptrMut);
		return PointerMutability.mutable;
	}
}

Expr checkFunPointer(ref ExprCtx ctx, UriAndRange range, in PtrAst ast, ref Expected expected) {
	if (!ast.inner.kind.isA!IdentifierAst)
		todo!void("diag: fun-pointer ast should just be an identifier");
	Sym name = ast.inner.kind.as!IdentifierAst.name;
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
	if (isTemplate(*funDecl))
		todo!void("can't point to template");
	FunInst* funInst = instantiateFun(ctx.alloc, ctx.programState, funDecl, [], []);
	Type paramType = makeTupleType(ctx.alloc, ctx.programState, ctx.commonTypes, funInst.paramTypes);
	StructInst* structInst = instantiateStructNeverDelay(
		ctx.alloc, ctx.programState, ctx.commonTypes.funPtrStruct, [funInst.returnType, paramType]);
	return check(ctx, expected, Type(structInst), Expr(range, ExprKind(ExprKind.FunPtr(funInst))));
}

Expr checkLambda(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in LambdaAst ast, ref Expected expected) {
	MutOpt!ExpectedLambdaType opEt = getExpectedLambdaType(ctx, range, expected, ast.param);
	if (!has(opEt))
		return bogus(expected, range);

	ExpectedLambdaType et = force(opEt);
	FunKind kind = et.kind;

	Destructure param = checkDestructure(ctx, ast.param, et.instantiatedParamType);

	ExprKind.Lambda* lambda = () @trusted { return allocateUninitialized!(ExprKind.Lambda)(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo = FunOrLambdaInfo(someMut(ptrTrustMe(locals)), some(castImmutable(lambda)));
	initializeMutMaxArr(lambdaInfo.closureFields);

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	LocalsInfo bodyLocals = LocalsInfo(ptrTrustMe(lambdaInfo), noneMut!(LocalNode*));
	Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(
		expected,
		et.nonInstantiatedPossiblyFutReturnType,
		et.inferringTypeArgs,
		(ref Expected returnTypeInferrer) =>
			checkExprWithDestructure(ctx, bodyLocals, param, ast.body_, returnTypeInferrer));
	Expr body_ = bodyAndType.a;
	Type actualPossiblyFutReturnType = bodyAndType.b;

	VariableRef[] closureFields = checkClosure(ctx, range, kind, tempAsArr(lambdaInfo.closureFields));

	Type actualNonFutReturnType = kind == FunKind.far
		? unwrapFutureType(actualPossiblyFutReturnType, ctx)
		: actualPossiblyFutReturnType;
	StructInst* instFunStruct = instantiateStructNeverDelay(
		ctx.alloc, ctx.programState, et.funStruct, [actualNonFutReturnType, param.type]);
	initMemory(lambda, ExprKind.Lambda(
		param,
		body_,
		closureFields,
		kind,
		actualPossiblyFutReturnType));
	//TODO: this check should never fail, so could just set inferred directly with no check
	return check(ctx, expected, Type(instFunStruct), Expr(range, ExprKind(castImmutable(lambda))));
}

Type unwrapFutureType(Type a, in ExprCtx ctx) {
	if (a.isA!(Type.Bogus))
		return Type(Type.Bogus());
	else {
		verify(decl(*a.as!(StructInst*)) == ctx.commonTypes.future);
		return only(typeArgs(*a.as!(StructInst*)));
	}
}

VariableRef[] checkClosure(ref ExprCtx ctx, UriAndRange range, FunKind kind, ClosureFieldBuilder[] closureFields) {
	final switch (kind) {
		case FunKind.fun:
			foreach (ref ClosureFieldBuilder cf; closureFields) {
				if (!isPurityAlwaysCompatibleConsideringSpecs(ctx.outermostFunSpecs, cf.type, Purity.shared_))
					addDiag2(ctx, range, Diag(Diag.LambdaClosesOverMut(cf.name, some(cf.type))));
				else {
					final switch (cf.mutability) {
						case Mutability.immut:
							break;
						case Mutability.mut:
							addDiag2(ctx, range, Diag(Diag.LambdaClosesOverMut(cf.name, none!Type)));
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

Destructure checkDestructure(ref ExprCtx ctx, in DestructureAst ast, Type type) =>
	.checkDestructure(
		ctx.checkCtx, ctx.commonTypes, ctx.structsAndAliasesMap, ctx.outermostFunTypeParams,
		noDelayStructInsts, ast, some(type));

Expr checkLet(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in LetAst ast, ref Expected expected) {
	ExprAndType value = checkAndExpectOrInfer(ctx, locals, ast.value, typeFromDestructure(ctx, ast.destructure));
	Destructure destructure = checkDestructure(ctx, ast.destructure, value.type);
	Expr then = checkExprWithDestructure(ctx, locals, destructure, ast.then, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Let(destructure, value.expr, then))));
}

Expr checkLoop(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in LoopAst ast, ref Expected expected) {
	Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType)) {
		Type type = force(expectedType);
		ExprKind.Loop* loop = allocate(ctx.alloc, ExprKind.Loop(
			range.range,
			Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()))));
		LoopInfo info = LoopInfo(voidType(ctx), castImmutable(loop), type, false);
		scope Expected bodyExpected = Expected(&info);
		Expr body_ = checkExpr(ctx, locals, ast.body_, castNonScope_ref(bodyExpected));
		overwriteMemory(&loop.body_, body_);
		if (!info.hasBreak)
			addDiag2(ctx, range, Diag(Diag.LoopWithoutBreak()));
		return Expr(range, ExprKind(castImmutable(loop)));
	} else {
		addDiag2(ctx, range, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.loop)));
		return bogus(expected, range);
	}
}

Expr checkLoopBreak(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in LoopBreakAst ast,
	ref Expected expected,
) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (!has(optLoop))
		return checkCallSpecial!1(ctx, locals, range, sym!"loop-break", [ast.value], expected);
	else {
		LoopInfo* loop = force(optLoop);
		loop.hasBreak = true;
		Expr value = checkAndExpect(ctx, locals, ast.value, loop.type);
		return Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.LoopBreak(loop.loop, value))));
	}
}

Expr checkLoopContinue(ref ExprCtx ctx, UriAndRange range, ref Expected expected) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	return has(optLoop)
		? Expr(range, ExprKind(ExprKind.LoopContinue(force(optLoop).loop)))
		: checkCallSpecialNoLocals(ctx, range, sym!"loop-continue", [], expected);
}

Expr checkLoopUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in LoopUntilAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, voidType(ctx), Expr(
		range,
		ExprKind(allocate(ctx.alloc, ExprKind.LoopUntil(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_))))));

Expr checkLoopWhile(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in LoopWhileAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, voidType(ctx), Expr(
		range,
		ExprKind(allocate(ctx.alloc, ExprKind.LoopWhile(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_))))));

Expr checkMatch(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in MatchAst ast, ref Expected expected) {
	ExprAndType matchedAndType = checkAndInfer(ctx, locals, ast.matched);
	Type matchedType = matchedAndType.type;
	StructBody body_ = matchedType.isA!(StructInst*)
		? body_(*decl(*matchedType.as!(StructInst*)))
		: StructBody(StructBody.Bogus());
	if (body_.isA!(StructBody.Enum))
		return checkMatchEnum(ctx, locals, range, ast, expected, matchedAndType, body_.as!(StructBody.Enum).members);
	else if (body_.isA!(StructBody.Union))
		return checkMatchUnion(
			ctx, locals, range, ast, expected, matchedAndType,
			body_.as!(StructBody.Union).members,
			matchedType.as!(StructInst*).instantiatedTypes);
	else {
		if (!matchedType.isA!(Type.Bogus))
			addDiag2(ctx, rangeInFile2(ctx, ast.matched.range), Diag(Diag.MatchOnNonUnion(matchedType)));
		return bogus(expected, rangeInFile2(ctx, ast.matched.range));
	}
}

Expr checkMatchEnum(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	in StructBody.Enum.Member[] members,
) {
	bool goodCases = arrsCorrespond!(StructBody.Enum.Member, MatchAst.CaseAst)(
		members,
		ast.cases,
		(in StructBody.Enum.Member member, in MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, range, Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref StructBody.Enum.Member member) => member.name))));
		return bogus(expected, range);
	} else {
		Expr[] cases = map(ctx.alloc, ast.cases, (ref MatchAst.CaseAst caseAst) {
			if (has(caseAst.destructure))
				todo!void("diag: enum match has no value");
			return checkExpr(ctx, locals, caseAst.then, expected);
		});
		return Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.MatchEnum(matched, cases))));
	}
}

Expr checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UriAndRange range,
	in MatchAst ast,
	ref Expected expected,
	ref ExprAndType matched,
	in UnionMember[] declaredMembers,
	in Type[] instantiatedTypes,
) {
	bool goodCases = arrsCorrespond!(UnionMember, MatchAst.CaseAst)(
		declaredMembers,
		ast.cases,
		(in UnionMember member, in MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, range, Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, declaredMembers, (ref UnionMember member) => member.name))));
		return bogus(expected, range);
	} else {
		ExprKind.MatchUnion.Case[] cases =
			mapZipPtrFirst3!(ExprKind.MatchUnion.Case, UnionMember, Type, MatchAst.CaseAst)(
				ctx.alloc, declaredMembers, instantiatedTypes, ast.cases,
				(UnionMember* member, ref Type type, ref MatchAst.CaseAst caseAst) =>
					checkMatchCase(ctx, locals, member, type, caseAst, expected));
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.MatchUnion(matched, cases))));
	}
}

ExprKind.MatchUnion.Case checkMatchCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	UnionMember* member,
	Type memberType,
	in MatchAst.CaseAst caseAst,
	ref Expected expected,
) {
	Destructure destructure = checkDestructure(
		ctx, has(caseAst.destructure) ? force(caseAst.destructure) : DestructureAst(DestructureAst.Void()), memberType);
	return ExprKind.MatchUnion.Case(
		destructure, checkExprWithDestructure(ctx, locals, destructure, caseAst.then, expected));
}

Expr checkSeq(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in SeqAst ast, ref Expected expected) {
	Expr first = checkAndExpectVoid(ctx, locals, ast.first);
	Expr then = checkExpr(ctx, locals, ast.then, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Seq(first, then))));
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

Expr checkFor(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in ForAst ast, ref Expected expected) {
	bool isForBreak = hasBreakOrContinue(ast.body_);
	scope LambdaAst lambdaAstBody = LambdaAst(ast.param, ast.body_);
	scope ExprAst lambdaBody = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaAstBody)));
	Sym funName = isForBreak ? sym!"for-break" : sym!"for-loop";
	if (!ast.else_.kind.isA!EmptyAst) {
		scope LambdaAst lambdaAstElse = LambdaAst(
			DestructureAst(DestructureAst.Void(range.range.start)),
			castNonScope_ref(ast.else_));
		scope ExprAst lambdaElse_ = ExprAst(ast.else_.range, ExprAstKind(ptrTrustMe(lambdaAstElse)));
		return checkCallSpecial!3(ctx, locals, range, funName, [ast.collection, lambdaBody, lambdaElse_], expected);
	} else
		return checkCallSpecial!2(ctx, locals, range, funName, [ast.collection, lambdaBody], expected);
}

Expr checkWith(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in WithAst ast, ref Expected expected) {
	if (!ast.else_.kind.isA!(EmptyAst))
		todo!void("diag: no 'else' for 'with'");
	LambdaAst lambdaInner = LambdaAst(ast.param, ast.body_);
	ExprAst lambda = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaInner)));
	return checkCallSpecial!2(ctx, locals, range, sym!"with-block", [ast.arg, lambda], expected);
}

Expr checkThen(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in ThenAst ast, ref Expected expected) {
	LambdaAst lambdaInner = LambdaAst(ast.left, ast.then);
	ExprAst lambda = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaInner)));
	return checkCallSpecial!2(ctx, locals, range, sym!"then", [ast.futExpr, lambda], expected);
}

Expr checkTyped(ref ExprCtx ctx, ref LocalsInfo locals, UriAndRange range, in TypedAst ast, ref Expected expected) {
	Type type = typeFromAst2(ctx, ast.type);
	Opt!Type inferred = tryGetInferred(expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, range, Diag(Diag.TypeAnnotationUnnecessary(type)));
	Expr expr = checkAndExpect(ctx, locals, ast.expr, type);
	return check(ctx, expected, type, expr);
}
