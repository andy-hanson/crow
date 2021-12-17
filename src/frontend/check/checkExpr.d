module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall : checkCall, checkIdentifierCall, eachFunInScope, markUsedFun, UsedFun;
import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.dicts : FunsDict, StructsAndAliasesDict;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	CheckedExpr,
	CommonFuns,
	copyWithNewExpectedType,
	Expected,
	ExprCtx,
	inferred,
	isBogus,
	LambdaInfo,
	LocalAndUsed,
	programState,
	rangeInFile2,
	shallowInstantiateType,
	tryGetDeeplyInstantiatedTypeFor,
	tryGetInferred,
	typeFromAst2,
	typeFromOptAst;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay;
import frontend.check.typeFromAst : makeFutType;
import frontend.parse.ast :
	ArrowAccessAst,
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
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	matchInterpolatedPart,
	matchLiteralAst,
	matchNameOrUnderscoreOrNone,
	NameAndRange,
	NameOrUnderscoreOrNone,
	ParenthesizedAst,
	rangeOfNameAndRange,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst,
	TypedAst;
import model.constant : Constant;
import model.diag : Diag;
import model.model :
	Arity,
	arity,
	assertNonVariadic,
	asStructInst,
	body_,
	Called,
	CalledDecl,
	ClosureField,
	CommonTypes,
	decl,
	Expr,
	FunDecl,
	FunDeclAndArgs,
	FunFlags,
	FunInst,
	FunKind,
	FunKindAndStructs,
	getType,
	IntegralTypes,
	isBogus,
	isStructInst,
	isTemplate,
	Local,
	matchArity,
	matchCalledDecl,
	matchStructBody,
	matchType,
	noCtx,
	Param,
	params,
	Purity,
	range,
	returnType,
	SpecInst,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	TypeParam,
	UnionMember,
	worstCasePurity;
import util.alloc.alloc : Alloc;
import util.col.arr :
	castImmutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	only,
	ptrsRange,
	setAt,
	sizeEq;
import util.col.arrUtil :
	arrLiteral,
	arrsCorrespond,
	arrWithSizeLiteral,
	exists,
	fillArr_mut,
	map,
	mapOrNone,
	mapWithFirst,
	mapZip,
	mapZipWithIndex,
	prepend,
	zipPtrFirst;
import util.col.mutArr :
	moveToArr,
	mustPeek_mut,
	mustPop,
	MutArr,
	mutArrAt,
	mutArrIsEmpty,
	mutArrRange,
	mutArrRangeMut,
	mutArrSize,
	push,
	tempAsArr,
	tempAsArr_mut;
import util.col.str : copyStr;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : Operator, shortSym, Sym, symEq, symForOperator, symOfStr;
import util.util : todo, verify;

immutable(Expr) checkFunctionBody(
	ref Alloc alloc,
	ref CheckCtx checkCtx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable CommonTypes commonTypes,
	ref immutable CommonFuns commonFuns,
	ref immutable FunsDict funsDict,
	ref bool[] usedFuns,
	immutable Type returnType,
	immutable TypeParam[] typeParams,
	immutable Param[] params,
	immutable Ptr!SpecInst[] specs,
	immutable FunFlags flags,
	ref immutable ExprAst ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe_mut(checkCtx),
		structsAndAliasesDict,
		funsDict,
		commonTypes,
		commonFuns,
		specs,
		params,
		typeParams,
		flags,
		usedFuns,
		// TODO: use temp alloc
		fillArr_mut!bool(alloc, params.length, (immutable size_t) =>
			false));
	immutable Expr res = checkAndExpect(alloc, exprCtx, ast, returnType);
	zipPtrFirst!(Param, bool)(
		params,
		castImmutable(exprCtx.paramsUsed),
		(immutable Ptr!Param param, ref immutable bool used) {
			if (!used && has(param.deref().name))
				addDiag(alloc, checkCtx, param.deref().range, immutable Diag(immutable Diag.UnusedParam(param)));
		});
	return res;
}

immutable(Expr) checkExpr(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	return checkExprWorker(alloc, ctx, ast, expected).expr;
}

private:

immutable(T) withLambda(T)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref LambdaInfo info,
	scope immutable(T) delegate() @safe @nogc pure nothrow cb,
) {
	Ptr!LambdaInfo infoPtr = ptrTrustMe_mut(info);
	push(alloc, ctx.lambdas, infoPtr);
	immutable T res = cb();
	Ptr!LambdaInfo popped = mustPop(ctx.lambdas);
	verify(ptrEquals(popped, infoPtr));
	return res;
}

struct ExprAndType {
	immutable Expr expr;
	immutable Type type;
}

immutable(ExprAndType) checkAndInfer(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
) {
	Expected expected = Expected.infer();
	immutable Expr expr = checkExpr(alloc, ctx, ast, expected);
	return immutable ExprAndType(expr, inferred(expected));
}

immutable(ExprAndType) checkAndExpect(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Opt!Type expected,
) {
	Expected et = Expected(expected);
	immutable Expr expr = checkExpr(alloc, ctx, ast, et);
	return immutable ExprAndType(expr, inferred(et));
}

immutable(Expr) checkAndExpect(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Type expected,
) {
	return checkAndExpect(alloc, ctx, ast, some(expected)).expr;
}

immutable(Expr) checkAndExpect(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Ptr!StructInst expected,
) {
	return checkAndExpect(alloc, ctx, ast, immutable Type(expected));
}

immutable(CheckedExpr) checkArrowAccess(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ArrowAccessAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> interp with-text "a" with-value b with-text "c" finish
	immutable CallAst callDeref = immutable CallAst(
		CallAst.style.single,
		immutable NameAndRange(range.range.start, symForOperator(Operator.times)),
		emptyArrWithSize!TypeAst,
		arrWithSizeLiteral!ExprAst(alloc, [ast.left]));
	immutable CallAst callName = immutable CallAst(
		CallAst.style.infix,
		ast.name,
		ast.typeArgs,
		arrWithSizeLiteral!ExprAst(alloc, [immutable ExprAst(range.range, immutable ExprAstKind(callDeref))]));
	return checkCall(alloc, ctx, range, callName, expected);
}

immutable(CheckedExpr) checkIf(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable IfAst ast,
	ref Expected expected,
) {
	immutable Expr cond = checkAndExpect(alloc, ctx, ast.cond, ctx.commonTypes.bool_);
	if (has(ast.else_)) {
		immutable Expr then = checkExpr(alloc, ctx, ast.then, expected);
		immutable Expr else_ = checkExpr(alloc, ctx, force(ast.else_), expected);
		return immutable CheckedExpr(immutable Expr(
			range,
			allocate(alloc, immutable Expr.Cond(inferred(expected), cond, then, else_))));
	} else {
		immutable ThenAndElse te = checkIfWithoutElse(alloc, ctx, range, none!(Ptr!Local), ast.then, expected);
		return immutable CheckedExpr(immutable Expr(range, allocate(alloc, immutable Expr.Cond(
			inferred(expected),
			cond,
			te.then,
			te.else_))));
	}
}

struct ThenAndElse {
	immutable Expr then;
	immutable Expr else_;
}

immutable(ThenAndElse) checkIfWithoutElse(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	immutable Opt!(Ptr!Local) local,
	ref immutable ExprAst thenAst,
	ref Expected expected,
) {
	immutable Expr then = checkWithOptLocal(alloc, ctx, local, thenAst, expected);
	immutable Type inferredType = inferred(expected);
	if (isVoid(ctx, inferredType))
		return immutable ThenAndElse(then, makeVoid(alloc, range, asStructInst(inferredType)));
	else if (isOptType(ctx.commonTypes, inferredType))
		return immutable ThenAndElse(then, makeNone(alloc, ctx, range, asStructInst(inferredType).deref()));
	else {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.IfWithoutElse(inferredType)));
		return immutable ThenAndElse(
			then,
			immutable Expr(range, immutable Expr.Bogus()));
	}
}

immutable(bool) isOptType(ref immutable CommonTypes commonTypes, immutable Type type) {
	return isStructInst(type) && ptrEquals(decl(asStructInst(type).deref()), commonTypes.opt);
}

immutable(Expr) makeNone(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable StructInst optStructInst,
) {
	immutable Type typeArg = only(typeArgs(optStructInst));
	immutable Ptr!FunInst noneInst = instantiateFun(
		alloc,
		ctx.perf,
		ctx.checkCtx.programState,
		immutable FunDeclAndArgs(ctx.commonFuns.noneFun, arrLiteral!Type(alloc, [typeArg]), emptyArr!Called));
	return immutable Expr(
		range,
		immutable Expr.Call(immutable Called(noneInst), emptyArr!Expr()));
}

immutable(bool) isVoid(ref const ExprCtx ctx, immutable Type type) {
	return isStructInst(type) && ptrEquals(asStructInst(type), ctx.commonTypes.void_);
}

immutable(Expr) makeVoid(ref Alloc alloc, ref immutable FileAndRange range, immutable Ptr!StructInst void_) {
	return immutable Expr(range, allocate(alloc, immutable Expr.Literal(
		void_,
		immutable Constant(immutable Constant.Void()))));
}

immutable(CheckedExpr) checkIfOption(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable IfOptionAst ast,
	ref Expected expected,
) {
	// We don't know the cond type, except that it's an option
	immutable ExprAndType optionAndType = checkAndInfer(alloc, ctx, ast.option);
	immutable Expr option = optionAndType.expr;
	immutable Type optionType = optionAndType.type;

	immutable Ptr!StructInst inst = isStructInst(optionType)
		? asStructInst(optionType)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (!ptrEquals(decl(inst.deref()), ctx.commonTypes.opt)) {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.IfNeedsOpt(optionType)));
		return bogus(expected, range);
	} else {
		immutable Type innerType = only(typeArgs(inst.deref()));
		immutable Ptr!Local local = allocate(alloc, immutable Local(
			rangeInFile2(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols)),
			ast.name.name,
			innerType));
		if (has(ast.else_)) {
			immutable Expr then = checkWithLocal(alloc, ctx, local, ast.then, expected);
			immutable Expr else_ = checkExpr(alloc, ctx, force(ast.else_), expected);
			return immutable CheckedExpr(immutable Expr(
				range,
				allocate(alloc, immutable Expr.IfOption(inferred(expected), option, local, then, else_))));
		} else {
			immutable ThenAndElse te = checkIfWithoutElse(alloc, ctx, range, some(local), ast.then, expected);
			return immutable CheckedExpr(immutable Expr(
				range,
				allocate(alloc, immutable Expr.IfOption(inferred(expected), option, local, te.then, te.else_))));
		}
	}
}

immutable(CheckedExpr) checkInterpolated(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable InterpolatedAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> interp with-text "a" with-value b with-text "c" finish
	immutable CallAst firstCall = immutable CallAst(
		CallAst.style.single,
		immutable NameAndRange(range.range.start, shortSym("interp")),
		emptyArrWithSize!TypeAst,
		emptyArrWithSize!ExprAst);
	immutable ExprAst firstCallExpr = immutable ExprAst(
		immutable RangeWithinFile(range.range.start, range.range.start),
		immutable ExprAstKind(firstCall));
	immutable CallAst call = checkInterpolatedRecur(alloc, ctx, ast.parts, range.start + 1, firstCallExpr);
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CallAst) checkInterpolatedRecur(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable InterpolatedPart[] parts,
	immutable Pos pos,
	ref immutable ExprAst left,
) {
	if (empty(parts))
		return immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(pos, shortSym("finish")),
			emptyArrWithSize!TypeAst,
			arrWithSizeLiteral!ExprAst(alloc, [left]));
	else {
		immutable CallAst c = matchInterpolatedPart!(
			immutable CallAst,
			(ref immutable string it) {
				immutable ExprAst right = immutable ExprAst(
					// TODO: this length may be wrong in the presence of escapes
					immutable RangeWithinFile(pos, safeToUint(pos + it.length)),
					immutable ExprAstKind(immutable LiteralAst(it)));
				return immutable CallAst(
					CallAst.Style.infix,
					immutable NameAndRange(pos, shortSym("with-str")),
					emptyArrWithSize!TypeAst,
					arrWithSizeLiteral!ExprAst(alloc, [left, right]));
			},
			(ref immutable ExprAst e) =>
				immutable CallAst(
					CallAst.Style.infix,
					immutable NameAndRange(pos, shortSym("with-value")),
					emptyArrWithSize!TypeAst,
					arrWithSizeLiteral!ExprAst(alloc, [left, e])),
		)(parts[0]);
		immutable Pos newPos = matchInterpolatedPart!(
			immutable Pos,
			(ref immutable string it) => safeToUint(pos + it.length),
			(ref immutable ExprAst e) => e.range.end,
		)(parts[0]);
		immutable ExprAst newLeft = immutable ExprAst(
			immutable RangeWithinFile(pos, newPos),
			immutable ExprAstKind(c));
		return checkInterpolatedRecur(alloc, ctx, parts[1 .. $], newPos, newLeft);
	}
}

struct ExpectedLambdaType {
	immutable Ptr!StructInst funStructInst;
	immutable Ptr!StructDecl funStruct;
	immutable FunKind kind;
	immutable Type[] paramTypes;
	immutable Type nonInstantiatedPossiblyFutReturnType;
}

immutable(Opt!ExpectedLambdaType) getExpectedLambdaType(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref Expected expected,
) {
	immutable Opt!Type expectedType = shallowInstantiateType(expected);
	if (!has(expectedType) || !isStructInst(force(expectedType))) {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	immutable Ptr!StructInst expectedStructInst = asStructInst(force(expectedType));
	immutable Ptr!StructDecl funStruct = decl(expectedStructInst.deref());
	immutable Opt!FunKind opKind = getFunStructInfo(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		immutable FunKind kind = force(opKind);
		immutable Type nonInstantiatedNonFutReturnType = expectedStructInst.deref().typeArgs[0];
		immutable Type[] nonInstantiatedParamTypes = expectedStructInst.deref().typeArgs[1 .. $];
		immutable Opt!(Type[]) paramTypes = mapOrNone!Type(
			alloc,
			nonInstantiatedParamTypes,
			(ref immutable Type it) =>
				tryGetDeeplyInstantiatedTypeFor(alloc, programState(ctx), expected, it));
		if (has(paramTypes)) {
			immutable Type nonInstantiatedReturnType = kind == FunKind.ref_
				? makeFutType(alloc, programState(ctx), ctx.commonTypes, nonInstantiatedNonFutReturnType)
				: nonInstantiatedNonFutReturnType;
			return some(immutable ExpectedLambdaType(
				expectedStructInst,
				funStruct,
				kind,
				force(paramTypes),
				nonInstantiatedReturnType));
		} else {
			addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.LambdaCantInferParamTypes()));
			return none!ExpectedLambdaType;
		}
	}
}

immutable(Opt!FunKind) getFunStructInfo(ref immutable CommonTypes a, immutable Ptr!StructDecl s) {
	//TODO: use arrUtils
	foreach (ref immutable FunKindAndStructs fs; a.funKindsAndStructs)
		foreach (immutable Ptr!StructDecl funStruct; fs.structs)
			if (ptrEquals(s, funStruct))
				return some(fs.kind);
	return none!FunKind;
}

immutable(Opt!Expr) getIdentifierInLambda(
	ref immutable FileAndRange range,
	immutable Sym name,
	ref LambdaInfo lambda,
) {
	foreach (ref LocalAndUsed local; mutArrRangeMut!LocalAndUsed(lambda.locals))
		if (symEq(local.local.deref().name, name)) {
			local.isUsed = true;
			return some(immutable Expr(range, immutable Expr.LocalRef(local.local)));
		}
	foreach (immutable Ptr!Param param; ptrsRange(lambda.lambdaParams))
		if (has(param.deref().name) && symEq(force(param.deref().name), name))
			return some(immutable Expr(range, immutable Expr.ParamRef(param)));
	// Check if we've already added something with this name to closureFields to avoid adding it twice.
	foreach (immutable Ptr!ClosureField field; mutArrRange(lambda.closureFields))
		if (symEq(field.deref().name, name))
			return some(immutable Expr(range, immutable Expr.ClosureFieldRef(field)));
	return none!Expr;
}

struct IdentifierAndLambdas {
	immutable Expr expr;
	// Lambdas outside of this identifier. Se must note those as closures.
	Ptr!LambdaInfo[] outerLambdas;
}

Opt!IdentifierAndLambdas getIdentifierNonCall(
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	immutable Sym name,
) {
	// Innermost lambda first
	foreach_reverse (immutable size_t i; 0 .. mutArrSize(ctx.lambdas)) {
		immutable Opt!Expr id = getIdentifierInLambda(range, name, mutArrAt(ctx.lambdas, i).deref());
		if (has(id))
			return someMut(IdentifierAndLambdas(force(id), tempAsArr_mut(ctx.lambdas)[i + 1 .. $]));
	}

	Ptr!LambdaInfo[] allLambdas = tempAsArr_mut(ctx.lambdas);
	foreach (ref LocalAndUsed local; mutArrRangeMut(ctx.messageOrFunctionLocals))
		if (symEq(local.local.deref().name, name)) {
			local.isUsed = true;
			return someMut(IdentifierAndLambdas(immutable Expr(
				range,
				immutable Expr.LocalRef(local.local)), allLambdas));
		}
	foreach (immutable Ptr!Param param; ptrsRange(ctx.outermostFunParams))
		if (has(param.deref().name) && symEq(force(param.deref().name), name)) {
			setAt(ctx.paramsUsed, param.deref().index, true);
			return someMut(IdentifierAndLambdas(immutable Expr(range, immutable Expr.ParamRef(param)), allLambdas));
		}
	return noneMut!IdentifierAndLambdas;
}

immutable(bool) nameIsParameterOrLocalInScope(ref ExprCtx ctx, immutable Sym name) {
	return has(getIdentifierNonCall(ctx, FileAndRange.empty, name));
}

immutable(CheckedExpr) checkRef(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable Expr expr,
	immutable Sym name,
	Ptr!LambdaInfo[] passedLambdas,
	ref Expected expected,
) {
	immutable Type type = getType(expr, ctx.commonTypes);
	if (empty(passedLambdas))
		return check(alloc, ctx, expected, type, expr);
	else {
		// First of passedLambdas is the outermost one where we found the param/local.
		// This one can access it directly.
		// Inner ones must reference this by a closure field.
		Ptr!LambdaInfo l0 = passedLambdas[0];
		// Shouldn't have already closed over it (or we should just be using that)
		verify(!exists!(immutable Ptr!ClosureField)(
			tempAsArr(l0.deref().closureFields),
			(ref immutable Ptr!ClosureField it) =>
				symEq(it.deref().name, name)));
		immutable Ptr!ClosureField field =
			allocate(alloc, immutable ClosureField(name, type, expr, mutArrSize(l0.deref().closureFields)));
		push(alloc, l0.deref().closureFields, field);
		immutable Expr closureFieldRef = immutable Expr(range(expr), immutable Expr.ClosureFieldRef(field));
		return checkRef(alloc, ctx, closureFieldRef, name, passedLambdas[1 .. $], expected);
	}
}

immutable(CheckedExpr) checkIdentifier(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable IdentifierAst ast,
	ref Expected expected,
) {
	immutable Sym name = ast.name;
	Opt!IdentifierAndLambdas opIdentifier = getIdentifierNonCall(ctx, range, name);
	return has(opIdentifier)
		? checkRef(
			alloc,
			ctx,
			force(opIdentifier).expr,
			name,
			force(opIdentifier).outerLambdas,
			expected)
		: checkIdentifierCall(alloc, ctx, range, name, expected);
}

struct IntRange {
	immutable long min;
	immutable long max;
}

immutable(CheckedExpr) checkLiteral(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LiteralAst ast,
	ref Expected expected,
) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	immutable Ptr!StructInst expectedStruct = has(expectedType) && isStructInst(force(expectedType))
		? asStructInst(force(expectedType))
		: ctx.commonTypes.bool_; // Just picking a random one that won't match any of the below tests
	immutable IntegralTypes integrals = ctx.commonTypes.integrals;

	immutable(CheckedExpr) asFloat32(immutable float value) {
		immutable Expr e = immutable Expr(range, allocate(alloc, immutable Expr.Literal(
			ctx.commonTypes.float32,
			immutable Constant(immutable Constant.Float(value)))));
		return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.float32), e);
	}

	immutable(CheckedExpr) asFloat64(immutable double value) {
		immutable Expr e = immutable Expr(range, allocate(alloc, immutable Expr.Literal(
			ctx.commonTypes.float64,
			immutable Constant(immutable Constant.Float(value)))));
		return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.float64), e);
	}

	return matchLiteralAst!(
		immutable CheckedExpr,
		(immutable LiteralAst.Float it) {
			if (it.overflow)
				todo!void("literal overflow");

			return ptrEquals(expectedStruct, ctx.commonTypes.float32)
				? asFloat32(it.value)
				: asFloat64(it.value);
		},
		(immutable LiteralAst.Int it) {
			if (ptrEquals(expectedStruct, ctx.commonTypes.float32))
				return asFloat32(cast(immutable float) it.value);
			if (ptrEquals(expectedStruct, ctx.commonTypes.float64))
				return asFloat64(cast(immutable double) it.value);
			else {
				immutable(Opt!IntRange) intRange = ptrEquals(expectedStruct, integrals.int8)
					? some(immutable IntRange(byte.min, byte.max))
					: ptrEquals(expectedStruct, integrals.int16)
					? some(immutable IntRange(short.min, short.max))
					: ptrEquals(expectedStruct, integrals.int32)
					? some(immutable IntRange(int.min, int.max))
					: ptrEquals(expectedStruct, integrals.int64)
					? some(immutable IntRange(long.min, long.max))
					: none!IntRange;
				immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
				if (has(intRange)) {
					if (it.overflow || it.value < force(intRange).min || it.value > force(intRange).max)
						todo!void("literal overflow");
					return immutable CheckedExpr(
						immutable Expr(range, allocate(alloc, immutable Expr.Literal(expectedStruct, constant))));
				} else {
					immutable Expr e = immutable Expr(
						range,
						allocate(alloc, immutable Expr.Literal(integrals.int64, constant)));
					return check(alloc, ctx, expected, immutable Type(integrals.int64), e);
				}
			}
		},
		(immutable LiteralAst.Nat it) {
			if (ptrEquals(expectedStruct, ctx.commonTypes.float32))
				return asFloat32(cast(immutable float) it.value);
			if (ptrEquals(expectedStruct, ctx.commonTypes.float64))
				return asFloat64(cast(immutable double) it.value);
			else {
				immutable(Opt!ulong) max = ptrEquals(expectedStruct, integrals.nat8)
					? some!ulong(ubyte.max)
					: ptrEquals(expectedStruct, integrals.nat16)
					? some!ulong(ushort.max)
					: ptrEquals(expectedStruct, integrals.nat32)
					? some!ulong(uint.max)
					: ptrEquals(expectedStruct, integrals.nat64)
					? some(ulong.max)
					: ptrEquals(expectedStruct, integrals.int8)
					? some!ulong(byte.max)
					: ptrEquals(expectedStruct, integrals.int16)
					? some!ulong(short.max)
					: ptrEquals(expectedStruct, integrals.int32)
					? some!ulong(int.max)
					: ptrEquals(expectedStruct, integrals.int64)
					? some!ulong(long.max)
					: none!ulong;
				immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
				if (has(max)) {
					if (it.overflow || it.value > force(max))
						addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.LiteralOverflow(expectedStruct)));
					return immutable CheckedExpr(
						immutable Expr(range, allocate(alloc, immutable Expr.Literal(expectedStruct, constant))));
				} else {
					if (it.overflow)
						todo!void("literal overflow");
					immutable Expr e = immutable Expr(
						range,
						allocate(alloc, immutable Expr.Literal(integrals.nat64, constant)));
					return check(alloc, ctx, expected, immutable Type(integrals.nat64), e);
				}
			}
		},
		(immutable string value) =>
			checkStringLiteral(alloc, ctx, range, expected, expectedStruct, value),
	)(ast);
}

immutable(CheckedExpr) checkStringLiteral(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref Expected expected,
	immutable Ptr!StructInst expectedStruct,
	immutable string value,
) {
	if (ptrEquals(expectedStruct, ctx.commonTypes.char_)) {
		if (value.length != 1)
			todo!void("char literal must be one char");
		return immutable CheckedExpr(immutable Expr(
			range,
			allocate(alloc, immutable Expr.Literal(
				expectedStruct,
				immutable Constant(immutable Constant.Integral(only(value)))))));
	} else if (ptrEquals(expectedStruct, ctx.commonTypes.sym))
		return immutable CheckedExpr(immutable Expr(
			range,
			immutable Expr.SymbolLiteral(symOfStr(ctx.allSymbols, value))));
	else {
		immutable Expr e = immutable Expr(range, immutable Expr.StringLiteral(copyStr(alloc, value)));
		return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.str), e);
	}
}


immutable(Expr) checkWithLocal(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Ptr!Local local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	// Look for a parameter with the name
	if (nameIsParameterOrLocalInScope(ctx, local.deref().name)) {
		addDiag2(alloc, ctx, local.deref().range, Diag(Diag.LocalShadowsPrevious(local.deref().name)));
		return bogus(expected, rangeInFile2(ctx, ast.range)).expr;
	} else {
		Ptr!(MutArr!LocalAndUsed) locals = mutArrIsEmpty(ctx.lambdas)
			? ptrTrustMe_mut(ctx.messageOrFunctionLocals)
			: ptrTrustMe_mut(mustPeek_mut(ctx.lambdas).deref().locals);
		push(alloc, locals.deref(), LocalAndUsed(false, local));
		immutable Expr res = checkExpr(alloc, ctx, ast, expected);
		LocalAndUsed popped = mustPop(locals.deref());
		verify(ptrEquals(popped.local, local));
		if (!popped.isUsed)
			addDiag2(alloc, ctx, local.deref().range, immutable Diag(
				immutable Diag.UnusedLocal(local)));
		return res;
	}
}

immutable(Param[]) checkFunOrSendFunParamsForLambda(
	ref Alloc alloc,
	ref const ExprCtx ctx,
	scope immutable LambdaAst.Param[] paramAsts,
	immutable Type[] expectedParamTypes,
) {
	return mapZipWithIndex!(Param, LambdaAst.Param, Type)(
		alloc,
		paramAsts,
		expectedParamTypes,
		(ref immutable LambdaAst.Param ast, ref immutable Type expectedParamType, immutable size_t index) =>
			immutable Param(
				rangeInFile2(ctx, rangeOfNameAndRange(ast, ctx.allSymbols)),
				some(ast.name),
				expectedParamType,
				index));
}

immutable(CheckedExpr) checkFunPtr(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable FunPtrAst ast,
	ref Expected expected,
) {
	MutArr!(immutable Ptr!FunDecl) funsInScope = MutArr!(immutable Ptr!FunDecl)();
	eachFunInScope(ctx, ast.name, (ref immutable Opt!UsedFun used, immutable CalledDecl cd) {
		matchCalledDecl!(
			void,
			(immutable Ptr!FunDecl it) {
				if (has(used))
					markUsedFun(ctx, force(used));
				push(alloc, funsInScope, it);
			},
			(ref immutable SpecSig) {
				todo!void("!");
			},
		)(cd);
	});
	if (mutArrSize(funsInScope) != 1)
		todo!void("did not find or found too many");
	immutable Ptr!FunDecl funDecl = mutArrAt(funsInScope, 0);

	if (isTemplate(funDecl.deref()))
		todo!void("can't point to template");
	if (!funDecl.deref().noCtx)
		todo!void("fun-ptr can't take ctx");
	immutable size_t nParams = matchArity!(
		immutable size_t,
		(immutable size_t n) =>
			n,
		(ref immutable Arity.Varargs) =>
			todo!(immutable size_t)("ptr to variadic function?"),
	)(arity(funDecl.deref()));
	if (nParams >= ctx.commonTypes.funPtrStructs.length)
		todo!void("arity too high");

	immutable Ptr!FunInst funInst = instantiateFun(
		alloc,
		ctx.perf,
		ctx.programState,
		immutable FunDeclAndArgs(funDecl, emptyArr!Type, emptyArr!Called));

	immutable Ptr!StructDecl funPtrStruct = ctx.commonTypes.funPtrStructs[nParams];
	immutable Type[] returnTypeAndParamTypes = mapWithFirst(
		alloc,
		returnType(funDecl.deref()),
		assertNonVariadic(params(funInst.deref())),
		(ref immutable Param it) => it.type);

	immutable Ptr!StructInst structInst = instantiateStructNeverDelay(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(funPtrStruct, returnTypeAndParamTypes));
	immutable Expr expr = immutable Expr(range, immutable Expr.FunPtr(funInst, structInst));
	return check(alloc, ctx, expected, immutable Type(structInst), expr);
}

immutable(CheckedExpr) checkLambda(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LambdaAst ast,
	ref Expected expected,
) {
	return checkLambdaCommon(alloc, ctx, range, ast.params, ast.body_, expected);
}

immutable(CheckedExpr) checkLambdaCommon(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	scope immutable LambdaAst.Param[] paramAsts,
	ref immutable ExprAst bodyAst,
	ref Expected expected,
) {
	immutable Opt!ExpectedLambdaType opEt = getExpectedLambdaType(alloc, ctx, range, expected);
	if (!has(opEt))
		return bogus(expected, range);

	immutable ExpectedLambdaType et = force(opEt);
	immutable FunKind kind = et.kind;

	if (!sizeEq(paramAsts, et.paramTypes)) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaWrongNumberParams(et.funStructInst, paramAsts.length)));
		return bogus(expected, range);
	}

	immutable Param[] params = checkFunOrSendFunParamsForLambda(alloc, ctx, paramAsts, et.paramTypes);
	LambdaInfo info = LambdaInfo(kind, params);
	Expected returnTypeInferrer = copyWithNewExpectedType(expected, et.nonInstantiatedPossiblyFutReturnType);

	immutable Expr body_ = withLambda(alloc, ctx, info, () =>
		// Note: checking the body of the lambda may fill in candidate type args
		// if the expected return type contains candidate's type params
		checkExpr(alloc, ctx, bodyAst, returnTypeInferrer));
	immutable Ptr!ClosureField[] closureFields = moveToArr(alloc, info.closureFields);

	final switch (kind) {
		case FunKind.plain:
			foreach (immutable Ptr!ClosureField cf; closureFields)
				if (worstCasePurity(cf.deref().type) == Purity.mut)
					addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaClosesOverMut(cf)));
			break;
		case FunKind.mut:
		case FunKind.ref_:
			break;
	}

	immutable Type actualPossiblyFutReturnType = inferred(returnTypeInferrer);
	immutable Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? matchType!(
			immutable Opt!Type,
			(immutable Type.Bogus) =>
				some(immutable Type(immutable Type.Bogus())),
			(immutable Ptr!TypeParam) =>
				none!Type,
			(immutable Ptr!StructInst ap) =>
				ptrEquals(ap.deref().decl, ctx.commonTypes.fut)
					? some!Type(only(ap.deref().typeArgs))
					: none!Type,
		)(actualPossiblyFutReturnType)
		: some!Type(actualPossiblyFutReturnType);
	if (!has(actualNonFutReturnType)) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.SendFunDoesNotReturnFut(actualPossiblyFutReturnType)));
		return bogus(expected, range);
	} else {
		immutable Ptr!StructInst instFunStruct = instantiateStructNeverDelay(
			alloc,
			programState(ctx),
			immutable StructDeclAndArgs(
				et.funStruct,
				prepend!Type(alloc, force(actualNonFutReturnType), et.paramTypes)));
		immutable Expr.Lambda lambda = immutable Expr.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType);
		return immutable CheckedExpr(immutable Expr(range, allocate(alloc, lambda)));
	}
}

immutable(CheckedExpr) checkLet(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LetAst ast,
	ref Expected expected,
) {
	immutable ExprAndType init = checkAndExpect(alloc, ctx, ast.initializer, typeFromOptAst(alloc, ctx, ast.type));
	immutable Ptr!Local local = allocate(alloc, immutable Local(
		rangeInFile2(ctx, rangeOfNameAndRange(immutable NameAndRange(range.start, ast.name), ctx.allSymbols)),
		ast.name,
		init.type));
	immutable Expr then = checkWithLocal(alloc, ctx, local, ast.then, expected);
	return immutable CheckedExpr(immutable Expr(range, allocate(alloc, immutable Expr.Let(local, init.expr, then))));
}

immutable(Expr) checkWithOptLocal(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Opt!(Ptr!Local) local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	return has(local)
		? checkWithLocal(alloc, ctx, force(local), ast, expected)
		: checkExpr(alloc, ctx, ast, expected);
}

struct EnumAndMembers {
	immutable StructBody.Enum.Member[] members;
}

struct UnionAndMembers {
	immutable Ptr!StructInst structInst;
	immutable UnionMember[] members;
}

struct EnumOrUnionAndMembers {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable EnumAndMembers a) { kind = Kind.enumAndMembers; enumAndMembers = a; }
	@trusted immutable this(immutable UnionAndMembers a) { kind = Kind.unionAndMembers; unionAndMembers = a; }

	private:

	enum Kind {
		enumAndMembers,
		unionAndMembers,
	}
	immutable Kind kind;
	union {
		EnumAndMembers enumAndMembers;
		UnionAndMembers unionAndMembers;
	}
}

@trusted immutable(T) matchEnumOrUnionAndMembers(T)(
	ref immutable EnumOrUnionAndMembers a,
	scope immutable(T) delegate(ref immutable EnumAndMembers) @safe @nogc pure nothrow cbEnumAndMembers,
	scope immutable(T) delegate(ref immutable UnionAndMembers) @safe @nogc pure nothrow cbUnionAndMembers,
) {
	final switch (a.kind) {
		case EnumOrUnionAndMembers.Kind.enumAndMembers:
			return cbEnumAndMembers(a.enumAndMembers);
		case EnumOrUnionAndMembers.Kind.unionAndMembers:
			return cbUnionAndMembers(a.unionAndMembers);
	}
}

immutable(Opt!EnumOrUnionAndMembers) getEnumOrUnionBody(immutable Type a) {
	return matchType!(
		immutable Opt!EnumOrUnionAndMembers,
		(immutable Type.Bogus) => none!EnumOrUnionAndMembers,
		(immutable Ptr!TypeParam) => none!EnumOrUnionAndMembers,
		(immutable Ptr!StructInst structInst) =>
			matchStructBody!(
				immutable Opt!EnumOrUnionAndMembers,
				(ref immutable StructBody.Bogus) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Builtin) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Enum it) =>
					some(immutable EnumOrUnionAndMembers(immutable EnumAndMembers(it.members))),
				(ref immutable StructBody.Flags) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.ExternPtr) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Record) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Union it) =>
					some(immutable EnumOrUnionAndMembers(immutable UnionAndMembers(structInst, it.members))),
			)(body_(structInst.deref())),
	)(a);
}

immutable(CheckedExpr) checkMatch(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
) {
	immutable ExprAndType matchedAndType = checkAndInfer(alloc, ctx, ast.matched);
	immutable Opt!EnumOrUnionAndMembers enumOrUnionAndMembers = getEnumOrUnionBody(matchedAndType.type);
	if (has(enumOrUnionAndMembers))
		return matchEnumOrUnionAndMembers!(immutable CheckedExpr)(
			force(enumOrUnionAndMembers),
			(ref immutable EnumAndMembers it) =>
				checkMatchEnum(alloc, ctx, range, ast, expected, matchedAndType.expr, it.members),
			(ref immutable UnionAndMembers it) =>
				checkMatchUnion(alloc, ctx, range, ast, expected, matchedAndType.expr, it.structInst, it.members));
	else {
		if (!isBogus(matchedAndType.type))
			addDiag2(
				alloc,
				ctx,
				rangeInFile2(ctx, ast.matched.range),
				immutable Diag(immutable Diag.MatchOnNonUnion(matchedAndType.type)));
		return bogus(expected, rangeInFile2(ctx, ast.matched.range));
	}
}

immutable(CheckedExpr) checkMatchEnum(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
	ref immutable Expr matched,
	ref immutable StructBody.Enum.Member[] members,
) {
	immutable bool goodCases = arrsCorrespond!(StructBody.Enum.Member, MatchAst.CaseAst)(
		members,
		ast.cases,
		(ref immutable StructBody.Enum.Member member, ref immutable MatchAst.CaseAst caseAst) =>
			symEq(member.name, caseAst.memberName));
	if (!goodCases) {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map!Sym(alloc, members, (ref immutable StructBody.Enum.Member member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable Expr[] cases = map!Expr(alloc, ast.cases, (ref immutable MatchAst.CaseAst caseAst) {
			matchNameOrUnderscoreOrNone!(
				void,
				(immutable(Sym)) =>
					todo!void("diagnostic: no local for enum match"),
				(ref immutable NameOrUnderscoreOrNone.Underscore) =>
					todo!void("diagnostic: unnecessary underscore"),
				(ref immutable NameOrUnderscoreOrNone.None) {},
			)(caseAst.local);
			return checkExpr(alloc, ctx, caseAst.then, expected);
		});
		return immutable CheckedExpr(immutable Expr(
			range,
			allocate(alloc, immutable Expr.MatchEnum(matched, cases, inferred(expected)))));
	}
}

immutable(CheckedExpr) checkMatchUnion(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
	ref immutable Expr matched,
	immutable Ptr!StructInst matchedUnion,
	immutable UnionMember[] members,
) {
	immutable bool goodCases = arrsCorrespond!(UnionMember, MatchAst.CaseAst)(
		members,
		ast.cases,
		(ref immutable UnionMember member, ref immutable MatchAst.CaseAst caseAst) =>
			symEq(member.name, caseAst.memberName));
	if (!goodCases) {
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map!Sym(alloc, members, (ref immutable UnionMember member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable Expr.MatchUnion.Case[] cases = mapZip!(Expr.MatchUnion.Case)(
			alloc,
			members,
			ast.cases,
			(ref immutable UnionMember member, ref immutable MatchAst.CaseAst caseAst) =>
				checkMatchCase(alloc, ctx, member, caseAst, expected));
		return immutable CheckedExpr(immutable Expr(
			range,
			allocate(alloc, immutable Expr.MatchUnion(matched, matchedUnion, cases, inferred(expected)))));
	}
}

immutable(Expr.MatchUnion.Case) checkMatchCase(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable UnionMember member,
	ref immutable MatchAst.CaseAst caseAst,
	ref Expected expected,
) {
	immutable Opt!(Ptr!Local) local = matchNameOrUnderscoreOrNone!(
		immutable Opt!(Ptr!Local),
		(immutable Sym name) {
			immutable FileAndRange localRange = rangeInFile2(ctx, caseAst.localRange(ctx.allSymbols));
			if (has(member.type))
				return some(allocate(alloc, immutable Local(localRange, name, force(member.type))));
			else {
				addDiag2(alloc, ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(name)));
				return none!(Ptr!Local);
			}
		},
		(ref immutable NameOrUnderscoreOrNone.Underscore) {
			if (!has(member.type))
				todo!void("diagnostic: unnecessary underscore");
			return none!(Ptr!Local);
		},
		(ref immutable NameOrUnderscoreOrNone.None) {
			if (has(member.type))
				addDiag2(alloc, ctx, rangeInFile2(ctx, caseAst.range), immutable Diag(
					immutable Diag.MatchCaseShouldHaveLocal(member.name)));
			return none!(Ptr!Local);
		},
	)(caseAst.local);
	immutable Expr then = isBogus(expected)
		? bogus(expected, rangeInFile2(ctx, caseAst.range)).expr
		: checkWithOptLocal(alloc, ctx, local, caseAst.then, expected);
	return immutable Expr.MatchUnion.Case(local, then);
}

immutable(CheckedExpr) checkSeq(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable SeqAst ast,
	ref Expected expected,
) {
	immutable Expr first = checkAndExpect(alloc, ctx, ast.first, ctx.commonTypes.void_);
	immutable Expr then = checkExpr(alloc, ctx, ast.then, expected);
	return immutable CheckedExpr(immutable Expr(range, allocate(alloc, immutable Expr.Seq(first, then))));
}

immutable(CheckedExpr) checkThen(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ThenAst ast,
	ref Expected expected,
) {
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(alloc, immutable LambdaAst(
			//TODO: use temp alloc?
			arrLiteral!(LambdaAst.Param)(alloc, [ast.left]),
			ast.then))));
	// TODO: NEATER (don't create a synthetic AST)
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSym("then")),
		emptyArrWithSize!TypeAst,
		arrWithSizeLiteral!ExprAst(alloc, [ast.futExpr, lambda]));
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CheckedExpr) checkThenVoid(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ThenVoidAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(alloc, immutable LambdaAst(emptyArr!(LambdaAst.Param), ast.then))));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSym("then-void")),
		emptyArrWithSize!TypeAst,
		arrWithSizeLiteral!ExprAst(alloc, [ast.futExpr, lambda]));
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CheckedExpr) checkTyped(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable TypedAst ast,
	ref Expected expected,
) {

	immutable Type type = typeFromAst2(alloc, ctx, ast.type);
	immutable Opt!Type inferred = tryGetInferred(expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && typeEquals(force(inferred), type))
		addDiag2(alloc, ctx, range, immutable Diag(immutable Diag.TypeAnnotationUnnecessary(type)));
	immutable Expr expr = checkAndExpect(alloc, ctx, ast.expr, type);
	return check(alloc, ctx, expected, type, expr);
}

immutable(CheckedExpr) checkExprWorker(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	immutable FileAndRange range = rangeInFile2(ctx, ast.range);
	return matchExprAstKind!(
		immutable CheckedExpr,
		(ref immutable ArrowAccessAst a) =>
			checkArrowAccess(alloc, ctx, range, a, expected),
		(ref immutable(BogusAst)) =>
			bogus(expected, range),
		(ref immutable CallAst a) =>
			checkCall(alloc, ctx, range, a, expected),
		(ref immutable FunPtrAst a) =>
			checkFunPtr(alloc, ctx, range, a, expected),
		(ref immutable IdentifierAst a) =>
			checkIdentifier(alloc, ctx, range, a, expected),
		(ref immutable IfAst a) =>
			checkIf(alloc, ctx, range, a, expected),
		(ref immutable IfOptionAst a) =>
			checkIfOption(alloc, ctx, range, a, expected),
		(ref immutable InterpolatedAst a) =>
			checkInterpolated(alloc, ctx, range, a, expected),
		(ref immutable LambdaAst a) =>
			checkLambda(alloc, ctx, range, a, expected),
		(ref immutable LetAst a) =>
			checkLet(alloc, ctx, range, a, expected),
		(ref immutable LiteralAst a) =>
			checkLiteral(alloc, ctx, range, a, expected),
		(ref immutable MatchAst a) =>
			checkMatch(alloc, ctx, range, a, expected),
		(ref immutable ParenthesizedAst a) =>
			checkExprWorker(alloc, ctx, a.inner, expected),
		(ref immutable SeqAst a) =>
			checkSeq(alloc, ctx, range, a, expected),
		(ref immutable ThenAst a) =>
			checkThen(alloc, ctx, range, a, expected),
		(ref immutable ThenVoidAst a) =>
			checkThenVoid(alloc, ctx, range, a, expected),
		(ref immutable TypedAst a) =>
			checkTyped(alloc, ctx, range, a, expected),
	)(ast.kind);
}
