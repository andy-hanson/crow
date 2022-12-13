module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall :
	checkCall,
	checkCallNoLocals,
	checkIdentifierCall,
	eachFunInScope,
	isPurityAlwaysCompatibleConsideringSpecs,
	markUsedFun,
	UsedFun;
import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	checkCanDoUnsafe,
	ClosureFieldBuilder,
	Expected,
	ExprCtx,
	findExpectedStruct,
	FunOrLambdaInfo,
	getFunKindFromStruct,
	inferred,
	isBogus,
	LocalAccessKind,
	LocalNode,
	LocalsInfo,
	LoopInfo,
	markIsUsedSetOnStack,
	mustSetType,
	Pair,
	programState,
	rangeInFile2,
	shallowInstantiateType,
	tryGetDeeplyInstantiatedTypeFor,
	tryGetInferred,
	tryGetLoop,
	typeFromAst2,
	typeFromOptAst,
	withCopyWithNewExpectedType,
	withTrusted;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst : makeFutType;
import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	BogusAst,
	CallAst,
	ExprAst,
	ExprAstKind,
	ForAst,
	IdentifierAst,
	IdentifierSetAst,
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
	NameOrUnderscoreOrNone,
	OptNameAndRange,
	ParenthesizedAst,
	PtrAst,
	rangeOfNameAndRange,
	rangeOfOptNameAndRange,
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
	assertNonVariadic,
	body_,
	Called,
	CalledDecl,
	ClosureRef,
	CommonTypes,
	decl,
	Expr,
	ExprKind,
	FieldMutability,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	hasMutableField,
	IntegralTypes,
	isDefinitelyByRef,
	isTemplate,
	Local,
	LocalMutability,
	Mutability,
	name,
	Param,
	Purity,
	range,
	RecordField,
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
import util.col.arr : empty, only, PtrAndSmallNumber, ptrsRange, sizeEq;
import util.col.arrUtil : arrLiteral, arrsCorrespond, contains, exists, map, mapZip, mapZipWithIndex, zipPtrFirst;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr, mutArrSize, push, tempAsArr;
import util.col.mutMaxArr : fillMutMaxArr, initializeMutMaxArr, mutMaxArrSize, push, pushLeft, tempAsArr;
import util.col.str : copyToSafeCStr;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, initMemory, overwriteMemory;
import util.opt : force, has, MutOpt, none, noneMut, Opt, someMut, some;
import util.ptr : castImmutable, castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : Sym, sym, symOfStr;
import util.union_ : Union;
import util.util : max, todo, verify;

Expr checkFunctionBody(
	ref CheckCtx checkCtx,
	in StructsAndAliasesDict structsAndAliasesDict,
	in CommonTypes commonTypes,
	in FunsDict funsDict,
	scope FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	Type returnType,
	TypeParam[] typeParams,
	Param[] params,
	in immutable SpecInst*[] specs,
	in FunFlags flags,
	in ExprAst ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe(checkCtx),
		structsAndAliasesDict,
		funsDict,
		commonTypes,
		specs,
		params,
		typeParams,
		flags,
		usedFuns);
	FunOrLambdaInfo funInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), params, none!(ExprKind.Lambda*));
	fillMutMaxArr(funInfo.paramsUsed, params.length, false);
	// leave funInfo.closureFields uninitialized, it won't be used
	LocalsInfo locals = LocalsInfo(ptrTrustMe(funInfo), noneMut!(LocalNode*));
	Expr res = checkAndExpect(castNonScope_ref(exprCtx), locals, ast, returnType);
	checkUnusedParams(checkCtx, params, tempAsArr(funInfo.paramsUsed));
	return res;
}

Expr checkExpr(ref ExprCtx ctx, ref LocalsInfo locals, in ExprAst ast, ref Expected expected) {
	FileAndRange range = rangeInFile2(ctx, ast.range);
	return ast.kind.matchIn!Expr(
		(in ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, range, a, expected),
		(in AssertOrForbidAst a) =>
			checkAssertOrForbid(ctx, locals, range, a, expected),
		(in BogusAst _) =>
			bogus(expected, range),
		(in CallAst a) =>
			checkCall(ctx, locals, range, a, expected),
		(in ForAst a) =>
			checkFor(ctx, locals, range, a, expected),
		(in IdentifierAst a) =>
			checkIdentifier(ctx, locals, range, a, expected),
		(in IdentifierSetAst a) =>
			checkIdentifierSet(ctx, locals, range, a, expected),
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
			checkLoopContinue(ctx, locals, range, expected),
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

void checkUnusedParams(ref CheckCtx checkCtx, Param[] params, in bool[] paramsUsed) =>
	zipPtrFirst!(Param, const bool)(params, paramsUsed, (immutable Param* param, ref const bool used) {
		if (!used && has(param.name))
			addDiag(checkCtx, param.range, Diag(Diag.UnusedParam(param)));
	});

immutable struct ExprAndType {
	Expr expr;
	Type type;
}

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
	FileAndRange range,
	in ArrowAccessAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	ExprAst[1] derefArgs = [ast.left];
	scope CallAst callDeref =
		CallAst(CallAst.style.single, NameAndRange(range.range.start, sym!"*"), castNonScope(derefArgs));
	ExprAst[1] callArgs = [ExprAst(range.range, ExprAstKind(callDeref))];
	scope CallAst callName = CallAst(CallAst.style.infix, ast.name, castNonScope(callArgs));
	return checkCall(ctx, locals, range, callName, expected);
}

Expr checkIf(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in IfAst ast, ref Expected expected) {
	Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	Expr then = checkExpr(ctx, locals, ast.then, expected);
	Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Cond(inferred(expected), cond, then, else_))));
}

Expr checkThrow(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in ThrowAst ast, ref Expected expected) {
	Opt!Type inferred = tryGetInferred(expected);
	if (has(inferred)) {
		Expr thrown = checkAndExpectCStr(ctx, locals, ast.thrown);
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Throw(force(inferred), thrown))));
	} else {
		addDiag2(ctx, range, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, range);
	}
}

Expr checkAssertOrForbid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
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

Expr checkUnless(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in UnlessAst ast,
	ref Expected expected,
) {
	Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	Expr else_ = checkExpr(ctx, locals, ast.body_, expected);
	Expr then = checkEmptyNew(ctx, range, expected);
	return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Cond(inferred(expected), cond, then, else_))));
}

Expr checkExprOrEmptyNewAndExpect(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in Opt!ExprAst ast,
	Type expected,
) {
	Expected e = Expected(expected);
	return checkExprOrEmptyNew(ctx, locals, range, ast, e);
}

Expr checkExprOrEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in Opt!ExprAst ast,
	ref Expected expected,
) =>
	has(ast)
		? checkExpr(ctx, locals, force(ast), expected)
		: checkEmptyNew(ctx, range, expected);

Expr checkEmptyNew(ref ExprCtx ctx, in FileAndRange range, ref Expected expected) =>
	checkCallNoLocals(ctx, range, callNewCall(range.range), expected);

Expr checkIfOption(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in IfOptionAst ast,
	ref Expected expected,
) {
	// We don't know the cond type, except that it's an option
	ExprAndType optionAndType = checkAndInfer(ctx, locals, ast.option);
	Expr option = optionAndType.expr;
	Type optionType = optionAndType.type;

	StructInst* inst = optionType.isA!(StructInst*)
		? optionType.as!(StructInst*)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (decl(*inst) != ctx.commonTypes.opt) {
		addDiag2(ctx, range, Diag(Diag.IfNeedsOpt(optionType)));
		return bogus(expected, range);
	} else {
		Type innerType = only(typeArgs(*inst));
		Local* local = allocate(ctx.alloc, Local(
			rangeInFile2(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols)),
			ast.name.name,
			LocalMutability.immut,
			innerType));
		Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
		return Expr(range, ExprKind(
			allocate(ctx.alloc, ExprKind.IfOption(inferred(expected), option, local, then, else_))));
	}
}

Expr checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in InterpolatedAst ast,
	ref Expected expected,
) {
	defaultExpectedToString(ctx, range, expected);
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> "a" ~~ b.to-str ~~ "c"
	CallAst call = checkInterpolatedRecur(ctx, ast.parts, range.start + 1, none!ExprAst);
	Opt!Type inferred = tryGetInferred(expected);
	CallAst callAndConvert = has(inferred) && isCStr(ctx.commonTypes, force(inferred))
		? CallAst(
			//TODO: new kind (not infix)
			CallAst.Style.infix,
			NameAndRange(range.start, sym!"to-c-string"),
			// TODO: NO ALLOC
			arrLiteral!ExprAst(ctx.alloc, [ExprAst(range.range, ExprAstKind(call))]))
		: call;
	return checkCall(ctx, locals, range, callAndConvert, expected);
}

bool isCStr(in CommonTypes commonTypes, Type a) {
	if (a.isA!(StructInst*)) {
		StructInst* inst = a.as!(StructInst*);
		return decl(*inst) == commonTypes.ptrConst && only(typeArgs(*inst)) == Type(commonTypes.char8);
	} else
		return false;
}

CallAst checkInterpolatedRecur(ref ExprCtx ctx, in InterpolatedPart[] parts, Pos pos, in Opt!ExprAst left) {
	ExprAst right = parts[0].matchIn!ExprAst(
		(in string it) =>
			// TODO: this length may be wrong in the presence of escapes
			ExprAst(RangeWithinFile(pos, safeToUint(pos + it.length)), ExprAstKind(LiteralStringAst(it))),
		(in ExprAst e) @safe =>
			ExprAst(e.range, ExprAstKind(CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				NameAndRange(pos, sym!"to-string"),
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

immutable struct ExpectedLambdaType {
	StructInst* funStructInst;
	StructDecl* funStruct;
	FunKind kind;
	Type nonInstantiatedPossiblyFutReturnType;
}

Opt!ExpectedLambdaType getExpectedLambdaType(
	ref TypeArgsArray paramTypes,
	ref ExprCtx ctx,
	FileAndRange range,
	ref const Expected expected,
) {
	Opt!Type expectedType = shallowInstantiateType(expected);
	if (!has(expectedType) || !force(expectedType).isA!(StructInst*)) {
		addDiag2(ctx, range, Diag(Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	StructInst* expectedStructInst = force(expectedType).as!(StructInst*);
	StructDecl* funStruct = decl(*expectedStructInst);
	Opt!FunKind opKind = getFunKindFromStruct(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(ctx, range, Diag(Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		FunKind kind = force(opKind);
		Type nonInstantiatedNonFutReturnType = typeArgs(*expectedStructInst)[0];
		Type[] nonInstantiatedParamTypes = typeArgs(*expectedStructInst)[1 .. $];

		foreach (Type x; nonInstantiatedParamTypes) {
			Opt!Type t = tryGetDeeplyInstantiatedTypeFor(ctx.alloc, ctx.programState, expected, x);
			if (has(t)) {
				push(paramTypes, force(t));
			} else {
				addDiag2(ctx, range, Diag(Diag.LambdaCantInferParamTypes()));
				return none!ExpectedLambdaType;
			}
		}

		Type nonInstantiatedReturnType = kind == FunKind.ref_
			? makeFutType(ctx.alloc, ctx.programState, ctx.commonTypes, nonInstantiatedNonFutReturnType)
			: nonInstantiatedNonFutReturnType;
		return some(ExpectedLambdaType(expectedStructInst, funStruct, kind, nonInstantiatedReturnType));
	}
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
	foreach (Param* param; ptrsRange(info.params))
		if (has(param.name) && force(param.name) == name) {
			info.paramsUsed[param.index] = true;
			return someMut(VariableRefAndType(VariableRef(param), Mutability.immut, null, param.type));
		}
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
	FileAndRange range,
	in IdentifierAst ast,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType res = getIdentifierNonCall(ctx.alloc, locals, ast.name, LocalAccessKind.getOnStack);
	return has(res)
		? check(ctx, expected, force(res).type, toExpr(ctx.alloc, range, force(res).variableRef))
		: checkIdentifierCall(ctx, locals, range, ast.name, expected);
}

Expr checkIdentifierSet(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in IdentifierSetAst ast,
	ref Expected expected,
) {
	MutOpt!VariableRefAndType optVar = getVariableRefForSet(ctx, locals, range, ast.name);
	if (has(optVar)) {
		VariableRefAndType var = force(optVar);
		Expr value = checkAndExpect(ctx, locals, ast.value, var.type);
		return var.variableRef.matchWithPointers!Expr(
			(Local* local) =>
				check(ctx, expected, voidType(ctx), Expr(
					range,
					ExprKind(allocate(ctx.alloc, ExprKind.LocalSet(local, value))))),
			(Param*) {
				addDiag2(ctx, range, Diag(Diag.ParamNotMutable()));
				return bogus(expected, range);
			},
			(ClosureRef cr) =>
				check(ctx, expected, voidType(ctx), Expr(
					range,
					ExprKind(ExprKind.ClosureSet(allocate(ctx.alloc, cr), allocate(ctx.alloc, value))))));
	} else
		return bogus(expected, range);
}

MutOpt!VariableRefAndType getVariableRefForSet(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, Sym name) {
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

Expr toExpr(ref Alloc alloc, FileAndRange range, VariableRef a) =>
	a.matchWithPointers!Expr(
		(Local* x) =>
			Expr(range, ExprKind(ExprKind.LocalGet(x))),
		(Param* x) =>
			Expr(range, ExprKind(ExprKind.ParamGet(x))),
		(ClosureRef x) =>
			Expr(range, ExprKind(ExprKind.ClosureGet(allocate(alloc, x)))));

Expr checkLiteralFloat(ref ExprCtx ctx, FileAndRange range, in LiteralFloatAst ast, ref Expected expected) {
	immutable StructInst*[2] allowedTypes = [ctx.commonTypes.float32, ctx.commonTypes.float64];
	Opt!size_t opTypeIndex = findExpectedStruct(expected, allowedTypes);
	// default to float64
	size_t typeIndex = has(opTypeIndex) ? force(opTypeIndex) : 1;
	StructInst* numberType = allowedTypes[typeIndex];
	if (ast.overflow)
		addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
	return asFloat(ctx, range, numberType, ast.value, expected);
}

bool isFloatType(in CommonTypes commonTypes, StructInst* numberType) =>
	numberType == commonTypes.float32 || numberType == commonTypes.float64;

Expr asFloat(
	ref ExprCtx ctx,
	FileAndRange range,
	StructInst* numberType,
	double value,
	ref Expected expected,
) {
	verify(isFloatType(ctx.commonTypes, numberType));
	return check(
		ctx,
		expected,
		Type(numberType),
		Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Literal(numberType, Constant(Constant.Float(value)))))));
}

Expr checkLiteralInt(ref ExprCtx ctx, FileAndRange range, in LiteralIntAst ast, ref Expected expected) {
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
	Opt!size_t opTypeIndex = findExpectedStruct(expected, allowedTypes);
	// default to int64
	size_t typeIndex = has(opTypeIndex) ? force(opTypeIndex) : 3;
	StructInst* numberType = allowedTypes[typeIndex];
	if (isFloatType(ctx.commonTypes, numberType))
		return asFloat(ctx, range, numberType, cast(double) ast.value, expected);
	else {
		Constant constant = Constant(Constant.Integral(ast.value));
		if (ast.overflow || !contains(ranges[typeIndex], ast.value))
			addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
		return check(ctx, expected, Type(numberType), Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.Literal(numberType, constant)))));
	}
}
immutable struct IntRange {
	long min;
	long max;
}
bool contains(IntRange a, long value) =>
	a.min <= value && value <= a.max;

Expr checkLiteralNat(ref ExprCtx ctx, FileAndRange range, in LiteralNatAst ast, ref Expected expected) {
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
	Opt!size_t opTypeIndex = findExpectedStruct(expected, allowedTypes);
	// default to nat64
	size_t typeIndex = has(opTypeIndex) ? force(opTypeIndex) : 3;
	StructInst* numberType = allowedTypes[typeIndex];
	if (isFloatType(ctx.commonTypes, numberType))
		return asFloat(ctx, range, numberType, cast(double) ast.value, expected);
	else {
		Constant constant = Constant(Constant.Integral(ast.value));
		if (ast.overflow || ast.value > maximums[typeIndex])
			addDiag2(ctx, range, Diag(Diag.LiteralOverflow(numberType)));
		return check(ctx, expected, Type(numberType), Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.Literal(numberType, constant)))));
	}
}

Expr checkLiteralString(
	ref ExprCtx ctx,
	FileAndRange range,
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
		return Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.Literal(
				ctx.commonTypes.char8,
				Constant(Constant.Integral(char_))))));
	} else if (expectedStruct == ctx.commonTypes.symbol)
		return Expr(range, ExprKind(ExprKind.LiteralSymbol(symOfStr(ctx.allSymbols, value))));
	else if (expectedStruct == ctx.commonTypes.cString)
		return Expr(range, ExprKind(ExprKind.LiteralCString(copyToSafeCStr(ctx.alloc, value))));
	else {
		defaultExpectedToString(ctx, range, expected);
		scope ExprAst[1] args = [curAst];
		// TODO: NEATER (don't create a synthetic AST)
		scope CallAst ast = CallAst(
			CallAst.Style.emptyParens,
			NameAndRange(range.start, sym!"literal"),
			castNonScope(args));
		return checkCallNoLocals(ctx, range, ast, expected);
	}
}

StructInst* expectedStructOrNull(ref const Expected expected) {
	Opt!Type expectedType = tryGetInferred(expected);
	return has(expectedType) && force(expectedType).isA!(StructInst*)
		? force(expectedType).as!(StructInst*)
		: null;
}

void defaultExpectedToString(ref ExprCtx ctx, FileAndRange range, ref Expected expected) {
	Opt!Type inferred = tryGetInferred(expected);
	if (!has(inferred))
		mustSetType(ctx.alloc, ctx.programState, expected, getStrType(ctx, range));
}

Type getStrType(ref ExprCtx ctx, FileAndRange range) =>
	typeFromAst2(ctx, TypeAst(NameAndRange(range.start, sym!"string")));

Expr checkWithLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Local* local,
	in ExprAst ast,
	ref Expected expected,
) {
	// Look for a parameter with the name
	if (nameIsParameterOrLocalInScope(ctx.alloc, locals, local.name)) {
		addDiag2(ctx, local.range, Diag(
			Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.name)));
		return bogus(expected, rangeInFile2(ctx, ast.range));
	} else {
		LocalNode localNode = LocalNode(locals.locals, [false, false, false, false], local);
		LocalsInfo newLocals = LocalsInfo(locals.funOrLambda, someMut(ptrTrustMe(localNode)));
		Expr res = checkExpr(ctx, newLocals, ast, expected);
		if (localNode.local.mutability == LocalMutability.mutOnStack &&
			(localNode.isUsed[LocalAccessKind.getThroughClosure] ||
			 localNode.isUsed[LocalAccessKind.setThroughClosure])) {
			//TODO:BETTER
			overwriteMemory(&local.mutability, LocalMutability.mutAllocated);
		}
		addUnusedLocalDiags(ctx, local, localNode);
		return res;
	}
}

void addUnusedLocalDiags(ref ExprCtx ctx, Local* local, scope ref LocalNode node) {
	bool isGot = node.isUsed[LocalAccessKind.getOnStack] || node.isUsed[LocalAccessKind.getThroughClosure];
	bool isSet = node.isUsed[LocalAccessKind.setOnStack] || node.isUsed[LocalAccessKind.setThroughClosure];
	if (!isGot || (!isSet && local.mutability != LocalMutability.immut))
		addDiag2(ctx, local.range, Diag(Diag.UnusedLocal(local, isGot, isSet)));
}

Param[] checkParamsForLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	in LambdaAst.Param[] paramAsts,
	in Type[] expectedParamTypes,
) =>
	mapZipWithIndex!(Param, LambdaAst.Param, Type)(
		ctx.alloc,
		paramAsts,
		expectedParamTypes,
		(in LambdaAst.Param ast, in Type type, size_t index) {
			RangeWithinFile range = rangeOfOptNameAndRange(ast, ctx.allSymbols);
			Opt!Sym name = () {
				if (has(ast.name) && nameIsParameterOrLocalInScope(ctx.alloc, locals, force(ast.name))) {
					addDiag(ctx.checkCtx, range, Diag(
						Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, force(ast.name))));
					return none!Sym;
				} else
					return ast.name;
			}();
			return Param(rangeInFile2(ctx, range), name, type, index);
		});

Expr checkPtr(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in PtrAst ast, ref Expected expected) {
	if (!checkCanDoUnsafe(ctx))
		addDiag2(ctx, range, Diag(Diag.PtrIsUnsafe()));
	return getExpectedPointee(ctx, expected).match!Expr(
		(ExpectedPointee.None) {
			addDiag2(ctx, range, Diag(Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.pointer)));
			return bogus(expected, range);
		},
		(ExpectedPointee.FunPointer) =>
			checkFunPointer(ctx, range, ast, expected),
		(ExpectedPointee.Pointer x) =>
			checkPtrInner(ctx, locals, range, ast, x.pointer, x.pointee, x.mutability));
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
		else if (contains(ctx.commonTypes.funPtrStructs, decl))
			return ExpectedPointee(ExpectedPointee.FunPointer());
		else if (isDefinitelyByRef(*inst))
			return ExpectedPointee(ExpectedPointee.Pointer(
				Type(inst),
				Type(instantiateStructNeverDelay(ctx.alloc, ctx.programState, ctx.commonTypes.byVal, [Type(inst)])),
				hasMutableField(*inst) ? PointerMutability.mutable : PointerMutability.immutable_));
		else
			return ExpectedPointee(ExpectedPointee.None());
	} else
		return ExpectedPointee(ExpectedPointee.None());
}

Expr checkPtrInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in PtrAst ast,
	Type pointerType,
	Type pointeeType,
	PointerMutability pointerMutability,
) {
	Expr inner = checkAndExpect(ctx, locals, ast.inner, pointeeType);
	if (inner.kind.isA!(ExprKind.LocalGet)) {
		Local* local = inner.kind.as!(ExprKind.LocalGet).local;
		if (local.mutability < pointerMutability)
			addDiag2(ctx, range, Diag(Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.local)));
		if (pointerMutability == PointerMutability.mutable)
			markIsUsedSetOnStack(locals, local);
		return Expr(range, ExprKind(ExprKind.PtrToLocal(pointerType, local)));
	} else if (inner.kind.isA!(ExprKind.ParamGet))
		return Expr(range, ExprKind(ExprKind.PtrToParam(pointerType, inner.kind.as!(ExprKind.ParamGet).param)));
	else if (inner.kind.isA!(ExprKind.Call))
		return checkPtrOfCall(ctx, range, inner.kind.as!(ExprKind.Call), pointerType, pointerMutability);
	else {
		addDiag2(ctx, range, Diag(Diag.PtrUnsupported()));
		return Expr(range, ExprKind(ExprKind.Bogus()));
	}
}

Expr checkPtrOfCall(
	ref ExprCtx ctx,
	FileAndRange range,
	ExprKind.Call call,
	Type pointerType,
	PointerMutability pointerMutability,
) {
	Expr fail() {
		addDiag2(ctx, range, Diag(Diag.PtrUnsupported()));
		return Expr(range, ExprKind(ExprKind.Bogus()));
	}

	if (call.called.isA!(FunInst*)) {
		FunInst* getFieldFun = call.called.as!(FunInst*);
		if (decl(*getFieldFun).body_.isA!(FunBody.RecordFieldGet)) {
			FunBody.RecordFieldGet rfg = decl(*getFieldFun).body_.as!(FunBody.RecordFieldGet);
			Expr target = only(call.args);
			StructInst* recordType = only(assertNonVariadic(getFieldFun.params)).type.as!(StructInst*);
			RecordField field = body_(*recordType).as!(StructBody.Record).fields[rfg.fieldIndex];
			PointerMutability fieldMutability = pointerMutabilityFromField(field.mutability);
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < pointerMutability)
					addDiag2(ctx, range, Diag(Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.field)));
				return Expr(range, ExprKind(allocate(ctx.alloc,
					ExprKind.PtrToField(pointerType, target, rfg.fieldIndex))));
			} else if (target.kind.isA!(ExprKind.Call)) {
				ExprKind.Call targetCall = target.kind.as!(ExprKind.Call);
				Called called = targetCall.called;
				if (called.isA!(FunInst*) && isDerefFunction(ctx, called.as!(FunInst*))) {
					FunInst* derefFun = called.as!(FunInst*);
					StructInst* ptrStructInst = only(assertNonVariadic(derefFun.params)).type.as!(StructInst*);
					Expr targetPtr = only(targetCall.args);
					if (max(fieldMutability, mutabilityForPtrDecl(ctx, decl(*ptrStructInst))) < pointerMutability)
						todo!void("diag: can't get mut* to immutable field");
					return Expr(range, ExprKind(allocate(ctx.alloc,
						ExprKind.PtrToField(pointerType, targetPtr, rfg.fieldIndex))));
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

Expr checkFunPointer(ref ExprCtx ctx, FileAndRange range, in PtrAst ast, ref Expected expected) {
	if (!ast.inner.kind.isA!IdentifierAst)
		todo!void("diag: fun-pointer ast should just be an identifier");
	Sym name = ast.inner.kind.as!IdentifierAst.name;
	MutArr!(FunDecl*) funsInScope = MutArr!(FunDecl*)();
	eachFunInScope(ctx, name, (UsedFun used, CalledDecl cd) {
		cd.matchWithPointers!void(
			(FunDecl* x) {
				markUsedFun(ctx, used);
				push(ctx.alloc, funsInScope, x);
			},
			(SpecSig) {
				todo!void("!");
			});
	});
	if (mutArrSize(funsInScope) != 1)
		todo!void("did not find or found too many");
	FunDecl* funDecl = funsInScope[0];

	if (isTemplate(*funDecl))
		todo!void("can't point to template");
	size_t nParams = arity(*funDecl).match!size_t(
		(size_t n) =>
			n,
		(Arity.Varargs) =>
			todo!size_t("ptr to variadic function?"));
	if (nParams >= ctx.commonTypes.funPtrStructs.length)
		todo!void("arity too high");

	FunInst* funInst = instantiateFun(ctx.alloc, ctx.programState, funDecl, [], []);
	StructDecl* funPtrStruct = ctx.commonTypes.funPtrStructs[nParams];
	scope TypeArgsArray returnTypeAndParamTypes = typeArgsArray();
	push(returnTypeAndParamTypes, funDecl.returnType);
	foreach (ref Param x; assertNonVariadic(funInst.params))
		push(returnTypeAndParamTypes, x.type);
	StructInst* structInst =
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, funPtrStruct, tempAsArr(returnTypeAndParamTypes));
	return check(ctx, expected, Type(structInst), Expr(range, ExprKind(ExprKind.FunPtr(funInst, structInst))));
}

Expr checkLambda(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in LambdaAst ast, ref Expected expected) {
	scope TypeArgsArray paramTypes = typeArgsArray();
	Opt!ExpectedLambdaType opEt = getExpectedLambdaType(paramTypes, ctx, range, expected);
	if (!has(opEt))
		return bogus(expected, range);

	ExpectedLambdaType et = force(opEt);
	FunKind kind = et.kind;

	if (!sizeEq(ast.params, tempAsArr(paramTypes))) {
		addDiag2(ctx, range, Diag(Diag.LambdaWrongNumberParams(et.funStructInst, ast.params.length)));
		return bogus(expected, range);
	}

	Param[] params = checkParamsForLambda(ctx, locals, ast.params, tempAsArr(paramTypes));

	ExprKind.Lambda* lambda = () @trusted { return allocateUninitialized!(ExprKind.Lambda)(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo =
		FunOrLambdaInfo(someMut(ptrTrustMe(locals)), params, some(castImmutable(lambda)));
	fillMutMaxArr(lambdaInfo.paramsUsed, params.length, false);
	initializeMutMaxArr(lambdaInfo.closureFields);
	LocalsInfo lambdaLocalsInfo = LocalsInfo(ptrTrustMe(lambdaInfo), noneMut!(LocalNode*));

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(
		expected,
		et.nonInstantiatedPossiblyFutReturnType,
		(ref Expected returnTypeInferrer) =>
			checkExpr(ctx, lambdaLocalsInfo, ast.body_, returnTypeInferrer));
	Expr body_ = bodyAndType.a;
	Type actualPossiblyFutReturnType = bodyAndType.b;

	checkUnusedParams(ctx.checkCtx, params, tempAsArr(lambdaInfo.paramsUsed));

	VariableRef[] closureFields = checkClosure(ctx, range, kind, tempAsArr(lambdaInfo.closureFields));

	Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? actualPossiblyFutReturnType.match!(Opt!Type)(
			(Type.Bogus _) =>
				some(Type(Type.Bogus())),
			(ref TypeParam _) =>
				none!Type,
			(ref StructInst x) =>
				decl(x) == ctx.commonTypes.future
					? some(only(typeArgs(x)))
					: none!Type)
		: some(actualPossiblyFutReturnType);
	if (!has(actualNonFutReturnType)) {
		addDiag2(ctx, range, Diag(Diag.SendFunDoesNotReturnFut(actualPossiblyFutReturnType)));
		return bogus(expected, range);
	} else {
		pushLeft(paramTypes, force(actualNonFutReturnType));
		StructInst* instFunStruct =
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, et.funStruct, tempAsArr(paramTypes));
		initMemory(lambda, ExprKind.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType));
		//TODO: this check should never fail, so could just set inferred directly with no check
		return check(ctx, expected, Type(instFunStruct), Expr(range, ExprKind(castImmutable(lambda))));
	}
}

VariableRef[] checkClosure(ref ExprCtx ctx, FileAndRange range, FunKind kind, ClosureFieldBuilder[] closureFields) {
	final switch (kind) {
		case FunKind.fun:
			foreach (ref ClosureFieldBuilder cf; closureFields) {
				if (!isPurityAlwaysCompatibleConsideringSpecs(ctx, cf.type, Purity.sendable))
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
		case FunKind.ref_:
			break;
		case FunKind.pointer:
			todo!void("ensure no closure");
			break;
	}
	return map(ctx.alloc, closureFields, (ref ClosureFieldBuilder x) => x.variableRef);
}

Expr checkLet(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in LetAst ast, ref Expected expected) {
	ExprAndType init = checkAndExpectOrInfer(ctx, locals, ast.initializer, typeFromOptAst(ctx, ast.type));
	if (has(ast.name)) {
		Local* local = allocate(ctx.alloc, Local(
			rangeInFile2(ctx, rangeOfOptNameAndRange(OptNameAndRange(range.start, ast.name), ctx.allSymbols)),
			force(ast.name),
			ast.mut ? LocalMutability.mutOnStack : LocalMutability.immut,
			init.type));
		Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		return Expr(range, ExprKind(allocate(ctx.alloc, ExprKind.Let(local, init.expr, then))));
	} else {
		if (ast.mut) todo!void("'mut' makes no sense for nameless local");
		Expr then = checkExpr(ctx, locals, ast.then, expected);
		return Expr(range,
			ExprKind(allocate(ctx.alloc, ExprKind.Seq(
				Expr(init.expr.range, ExprKind(allocate(ctx.alloc, ExprKind.Drop(init.expr)))),
				then))));
	}
}

Expr checkWithOptLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	Opt!(Local*) local,
	in ExprAst ast,
	ref Expected expected,
) =>
	has(local)
		? checkWithLocal(ctx, locals, force(local), ast, expected)
		: checkExpr(ctx, locals, ast, expected);

immutable struct EnumAndMembers {
	StructBody.Enum.Member[] members;
}

immutable struct UnionAndMembers {
	StructInst* structInst;
	UnionMember[] members;
}

immutable struct EnumOrUnionAndMembers {
	mixin Union!(EnumAndMembers, UnionAndMembers);
}

Opt!EnumOrUnionAndMembers getEnumOrUnionBody(Type a) =>
	a.matchWithPointers!(Opt!EnumOrUnionAndMembers)(
		(Type.Bogus) =>
			none!EnumOrUnionAndMembers,
		(TypeParam*) =>
			none!EnumOrUnionAndMembers,
		(StructInst* structInst) =>
			body_(*structInst).match!(Opt!EnumOrUnionAndMembers)(
				(StructBody.Bogus) =>
					none!EnumOrUnionAndMembers,
				(StructBody.Builtin) =>
					none!EnumOrUnionAndMembers,
				(StructBody.Enum it) =>
					some(EnumOrUnionAndMembers(EnumAndMembers(it.members))),
				(StructBody.Extern) =>
					none!EnumOrUnionAndMembers,
				(StructBody.Flags) =>
					none!EnumOrUnionAndMembers,
				(StructBody.Record) =>
					none!EnumOrUnionAndMembers,
				(StructBody.Union it) =>
					some(EnumOrUnionAndMembers(UnionAndMembers(structInst, it.members)))));

Expr checkLoop(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in LoopAst ast, ref Expected expected) {
	Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType)) {
		Type type = force(expectedType);
		ExprKind.Loop* loop = allocate(ctx.alloc, ExprKind.Loop(
			type,
			Expr(FileAndRange.empty, ExprKind(ExprKind.Bogus()))));
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
	FileAndRange range,
	in LoopBreakAst ast,
	ref Expected expected,
) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (!has(optLoop)) {
		// TODO: NEATER (don't create a synthetic AST)
		ExprAst[1] args = [has(ast.value) ? force(ast.value) : callNew(range.range)];
		return checkCall(
			ctx, locals, range,
			CallAst(CallAst.Style.infix, NameAndRange(range.range.start, sym!"loop-break"), castNonScope(args)),
			expected);
	} else {
		LoopInfo* loop = force(optLoop);
		loop.hasBreak = true;
		Expr value = checkExprOrEmptyNewAndExpect(ctx, locals, range, ast.value, loop.type);
		return Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.LoopBreak(loop.loop, value))));
	}
}

Expr checkLoopContinue(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, ref Expected expected) {
	MutOpt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (has(optLoop))
		return Expr(range, ExprKind(ExprKind.LoopContinue(force(optLoop).loop)));
	else {
		scope CallAst call = CallAst(CallAst.Style.infix, NameAndRange(range.range.start, sym!"loop-continue"), []);
		return checkCall(ctx, locals, range, call, expected);
	}
}

Expr checkLoopUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
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
	FileAndRange range,
	in LoopWhileAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, voidType(ctx), Expr(
		range,
		ExprKind(allocate(ctx.alloc, ExprKind.LoopWhile(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_))))));

Expr checkMatch(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in MatchAst ast, ref Expected expected) {
	ExprAndType matchedAndType = checkAndInfer(ctx, locals, ast.matched);
	Opt!EnumOrUnionAndMembers enumOrUnionAndMembers = getEnumOrUnionBody(matchedAndType.type);
	if (has(enumOrUnionAndMembers))
		return force(enumOrUnionAndMembers).match!Expr(
			(EnumAndMembers it) =>
				checkMatchEnum(ctx, locals, range, ast, expected, matchedAndType.expr, it.members),
			(UnionAndMembers it) =>
				checkMatchUnion(ctx, locals, range, ast, expected, matchedAndType.expr, it.structInst, it.members));
	else {
		if (!matchedAndType.type.isA!(Type.Bogus))
			addDiag2(ctx, rangeInFile2(ctx, ast.matched.range), Diag(Diag.MatchOnNonUnion(matchedAndType.type)));
		return bogus(expected, rangeInFile2(ctx, ast.matched.range));
	}
}

Expr checkMatchEnum(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in MatchAst ast,
	ref Expected expected,
	ref Expr matched,
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
			caseAst.local.match!void(
				(Sym) =>
					todo!void("diagnostic: no local for enum match"),
				(NameOrUnderscoreOrNone.Underscore) =>
					todo!void("diagnostic: unnecessary underscore"),
				(NameOrUnderscoreOrNone.None) {});
			return checkExpr(ctx, locals, caseAst.then, expected);
		});
		return Expr(
			range,
			ExprKind(allocate(ctx.alloc, ExprKind.MatchEnum(matched, cases, inferred(expected)))));
	}
}

Expr checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	FileAndRange range,
	in MatchAst ast,
	ref Expected expected,
	ref Expr matched,
	StructInst* matchedUnion,
	in UnionMember[] members,
) {
	bool goodCases = arrsCorrespond!(UnionMember, MatchAst.CaseAst)(
		members,
		ast.cases,
		(in UnionMember member, in MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, range, Diag(Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref UnionMember member) => member.name))));
		return bogus(expected, range);
	} else {
		ExprKind.MatchUnion.Case[] cases = mapZip!(ExprKind.MatchUnion.Case, UnionMember, MatchAst.CaseAst)(
			ctx.alloc,
			members,
			ast.cases,
			(ref UnionMember member, ref MatchAst.CaseAst caseAst) =>
				checkMatchCase(ctx, locals, member, caseAst, expected));
		return Expr(range, ExprKind(allocate(
			ctx.alloc,
			ExprKind.MatchUnion(matched, matchedUnion, cases, inferred(expected)))));
	}
}

ExprKind.MatchUnion.Case checkMatchCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref UnionMember member,
	in MatchAst.CaseAst caseAst,
	ref Expected expected,
) {
	FileAndRange localRange = rangeInFile2(ctx, caseAst.localRange(ctx.allSymbols));
	Opt!(Local*) local = caseAst.local.matchIn!(Opt!(Local*))(
		(in Sym name) {
			if (has(member.type))
				return some(allocate(
					ctx.alloc,
					Local(localRange, name, LocalMutability.immut, force(member.type))));
			else {
				addDiag2(ctx, localRange, Diag(Diag.MatchCaseShouldNotHaveLocal(name)));
				return none!(Local*);
			}
		},
		(in NameOrUnderscoreOrNone.Underscore) {
			if (!has(member.type))
				addDiag2(ctx, localRange, Diag(Diag.MatchCaseShouldNotHaveLocal(sym!"_")));
			return none!(Local*);
		},
		(in NameOrUnderscoreOrNone.None) {
			if (has(member.type))
				addDiag2(ctx, rangeInFile2(ctx, caseAst.range), Diag(Diag.MatchCaseShouldHaveLocal(member.name)));
			return none!(Local*);
		});
	Expr then = isBogus(expected)
		? bogus(expected, rangeInFile2(ctx, caseAst.range))
		: checkWithOptLocal(ctx, locals, local, caseAst.then, expected);
	return ExprKind.MatchUnion.Case(local, then);
}

Expr checkSeq(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in SeqAst ast, ref Expected expected) {
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
		(in BogusAst _) =>
			false,
		(in CallAst _) =>
			false,
		(in ForAst _) =>
			false,
		(in IdentifierAst _) =>
			false,
		(in IdentifierSetAst _) =>
			false,
		(in IfAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
		(in IfOptionAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
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

ExprAst callNew(RangeWithinFile range) =>
	ExprAst(range, ExprAstKind(callNewCall(range)));
CallAst callNewCall(RangeWithinFile range) =>
	CallAst(CallAst.style.emptyParens, NameAndRange(range.start, sym!"new"), []);

Expr checkFor(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in ForAst ast, ref Expected expected) {
	// TODO: NEATER (don't create a synthetic AST)
	bool isForBreak = hasBreakOrContinue(ast.body_);
	scope LambdaAst lambdaAstBody = LambdaAst(ast.params, ast.body_);
	scope ExprAst lambdaBody = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaAstBody)));
	scope ExprAst bogus = ExprAst(range.range, ExprAstKind(BogusAst())); // won't be used
	scope LambdaAst lambdaAstElse = has(ast.else_)
		? LambdaAst([], force(castNonScope_ref(ast.else_)))
		: LambdaAst([], bogus);
	scope ExprAst lambdaElse_ = has(ast.else_)
		? ExprAst(force(ast.else_).range, ExprAstKind(ptrTrustMe(lambdaAstElse)))
		: bogus;
	ExprAst[3] allArgs = [ast.collection, lambdaBody, lambdaElse_];
	scope CallAst call = CallAst(
		CallAst.Style.infix,
		NameAndRange(range.range.start, isForBreak ? sym!"for-break" : sym!"for-loop"),
		has(ast.else_) ? castNonScope(allArgs) : castNonScope(allArgs)[0 .. 2]);
	return checkCall(ctx, locals, range, call, expected);
}

Expr checkWith(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in WithAst ast, ref Expected expected) {
	if (has(ast.else_))
		todo!void("diag: no 'else' for 'with'");

	// TODO: NEATER (don't create a synthetic AST)
	LambdaAst lambdaInner = LambdaAst(ast.params, ast.body_);
	ExprAst lambda = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaInner)));
	ExprAst[2] args = [ast.arg, lambda];
	return checkCall(
		ctx, locals, range,
		CallAst(CallAst.Style.infix, NameAndRange(range.range.start, sym!"with-block"), castNonScope(args)),
		expected);
}

Expr checkThen(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in ThenAst ast, ref Expected expected) {
	// TODO: NEATER (don't create a synthetic AST)
	LambdaAst lambdaInner = LambdaAst(ast.left, ast.then);
	ExprAst lambda = ExprAst(range.range, ExprAstKind(ptrTrustMe(lambdaInner)));
	ExprAst[2] args = [ast.futExpr, lambda];
	return checkCall(
		ctx, locals, range,
		CallAst(CallAst.Style.infix, NameAndRange(range.range.start, sym!"then"), castNonScope(args)),
		expected);
}

Expr checkTyped(ref ExprCtx ctx, ref LocalsInfo locals, FileAndRange range, in TypedAst ast, ref Expected expected) {
	Type type = typeFromAst2(ctx, ast.type);
	Opt!Type inferred = tryGetInferred(expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, range, Diag(Diag.TypeAnnotationUnnecessary(type)));
	Expr expr = checkAndExpect(ctx, locals, ast.expr, type);
	return check(ctx, expected, type, expr);
}
