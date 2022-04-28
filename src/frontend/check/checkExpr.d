module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall :
	checkCall, checkCallNoLocals, checkIdentifierCall, eachFunInScope, markUsedFun, UsedFun;
import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.dicts : FunsDict, ModuleLocalFunIndex, StructsAndAliasesDict;
import frontend.check.inferringType :
	addDiag2,
	bogus,
	check,
	ClosureFieldBuilder,
	copyWithNewExpectedType,
	Expected,
	ExprCtx,
	FunOrLambdaInfo,
	inferred,
	isBogus,
	LocalNode,
	LocalsInfo,
	mustSetType,
	programState,
	rangeInFile2,
	shallowInstantiateType,
	tryGetDeeplyInstantiatedTypeFor,
	tryGetInferred,
	typeFromAst2,
	typeFromOptAst;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
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
	OptNameAndRange,
	ParenthesizedAst,
	rangeOfNameAndRange,
	rangeOfOptNameAndRange,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst,
	TypedAst,
	UnlessAst;
import model.constant : Constant;
import model.diag : Diag;
import model.model :
	Arity,
	arity,
	assertNonVariadic,
	asStructInst,
	body_,
	CalledDecl,
	CommonTypes,
	decl,
	Expr,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	FunKindAndStructs,
	IntegralTypes,
	isBogus,
	isStructInst,
	isTemplate,
	Local,
	matchArity,
	matchCalledDecl,
	matchStructBody,
	matchType,
	matchVariableRef,
	noCtx,
	Param,
	params,
	Purity,
	range,
	returnType,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	typeEquals,
	TypeParam,
	UnionMember,
	VariableRef,
	worstCasePurity;
import util.alloc.alloc : Alloc, allocateUninitialized;
import util.col.arr : empty, emptyArr, emptySmallArray, only, PtrAndSmallNumber, ptrsRange, sizeEq;
import util.col.arrUtil : arrLiteral, arrsCorrespond, map, mapZip, mapZipWithIndex, zipPtrFirst;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr, mutArrAt, mutArrSize, push, tempAsArr;
import util.col.mutMaxArr : fillMutMaxArr, initializeMutMaxArr, mutMaxArrSize, push, pushLeft, tempAsArr;
import util.col.str : copyToSafeCStr;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, initMemory;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : Operator, shortSym, Sym, symEq, symForOperator, symOfStr;
import util.util : todo;

immutable(Expr) checkFunctionBody(
	ref CheckCtx checkCtx,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable CommonTypes commonTypes,
	ref immutable FunsDict funsDict,
	scope FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	immutable Type returnType,
	immutable TypeParam[] typeParams,
	immutable Param[] params,
	immutable Ptr!SpecInst[] specs,
	immutable FunFlags flags,
	scope ref immutable ExprAst ast,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe_mut(checkCtx),
		structsAndAliasesDict,
		funsDict,
		commonTypes,
		specs,
		params,
		typeParams,
		flags,
		usedFuns);
	scope FunOrLambdaInfo funInfo =
		FunOrLambdaInfo(noneMut!(Ptr!LocalsInfo), params, none!(Ptr!(Expr.Lambda)));
	fillMutMaxArr(funInfo.paramsUsed, params.length, false);
	// leave funInfo.closureFields uninitialized, it won't be used
	scope LocalsInfo locals = LocalsInfo(ptrTrustMe_mut(funInfo), noneMut!(Ptr!LocalNode));
	immutable Expr res = checkAndExpect(exprCtx, locals, ast, returnType);
	checkUnusedParams(checkCtx, params, tempAsArr(funInfo.paramsUsed));
	return res;
}

private:

void checkUnusedParams(ref CheckCtx checkCtx, immutable Param[] params, scope immutable bool[] paramsUsed) {
	return zipPtrFirst!(Param, bool)(
		params,
		paramsUsed,
		(immutable Ptr!Param param, ref immutable bool used) {
			if (!used && has(param.deref().name))
				addDiag(checkCtx, param.deref().range, immutable Diag(immutable Diag.UnusedParam(param)));
		});
}

struct ExprAndType {
	immutable Expr expr;
	immutable Type type;
}

immutable(ExprAndType) checkAndInfer(ref ExprCtx ctx, ref LocalsInfo locals, ref immutable ExprAst ast) {
	Expected expected = Expected.infer();
	immutable Expr expr = checkExpr(ctx, locals, ast, expected);
	return immutable ExprAndType(expr, inferred(expected));
}

immutable(ExprAndType) checkAndExpect(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Opt!Type expected,
) {
	Expected et = Expected(expected);
	immutable Expr expr = checkExpr(ctx, locals, ast, et);
	return immutable ExprAndType(expr, inferred(et));
}

immutable(Expr) checkAndExpect(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Type expected,
) {
	return checkAndExpect(ctx, locals, ast, some(expected)).expr;
}

immutable(Expr) checkAndExpect(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Ptr!StructInst expected,
) {
	return checkAndExpect(ctx, locals, ast, immutable Type(expected));
}

immutable(Expr) checkArrowAccess(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable ArrowAccessAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable CallAst callDeref = immutable CallAst(
		CallAst.style.single,
		immutable NameAndRange(range.range.start, symForOperator(Operator.times)),
		emptyArr!TypeAst,
		arrLiteral!ExprAst(ctx.alloc, [ast.left]));
	immutable CallAst callName = immutable CallAst(
		CallAst.style.infix,
		ast.name,
		ast.typeArgs,
		arrLiteral!ExprAst(ctx.alloc, [immutable ExprAst(range.range, immutable ExprAstKind(callDeref))]));
	return checkCall(ctx, locals, range, callName, expected);
}

immutable(Expr) checkIf(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable IfAst ast,
	ref Expected expected,
) {
	immutable Expr cond = checkAndExpect(ctx, locals, ast.cond, ctx.commonTypes.bool_);
	immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
	immutable Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Cond(inferred(expected), cond, then, else_)));
}

immutable(Expr) checkUnless(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable UnlessAst ast,
	ref Expected expected,
) {
	immutable Expr cond = checkAndExpect(ctx, locals, ast.cond, ctx.commonTypes.bool_);
	immutable Expr else_ = checkExpr(ctx, locals, ast.body_, expected);
	immutable Expr then = checkEmptyNew(ctx, locals, range, expected);
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Cond(inferred(expected), cond, then, else_)));
}

immutable(Expr) checkExprOrEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable Opt!ExprAst ast,
	ref Expected expected,
) {
	return has(ast)
		? checkExpr(ctx, locals, force(ast), expected)
		: checkEmptyNew(ctx, locals, range, expected);
}

immutable(Expr) checkEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref Expected expected,
) {
	immutable CallAst ast = immutable CallAst(CallAst.style.emptyParens,
		immutable NameAndRange(range.start, shortSym("new")),
		emptyArr!TypeAst,
		emptyArr!ExprAst);
	return checkCallNoLocals(ctx, range, ast, expected);
}

immutable(Expr) checkIfOption(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable IfOptionAst ast,
	ref Expected expected,
) {
	// We don't know the cond type, except that it's an option
	immutable ExprAndType optionAndType = checkAndInfer(ctx, locals, ast.option);
	immutable Expr option = optionAndType.expr;
	immutable Type optionType = optionAndType.type;

	immutable Ptr!StructInst inst = isStructInst(optionType)
		? asStructInst(optionType)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (!ptrEquals(decl(inst.deref()), ctx.commonTypes.opt)) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.IfNeedsOpt(optionType)));
		return bogus(expected, range);
	} else {
		immutable Type innerType = only(typeArgs(inst.deref()));
		immutable Ptr!Local local = allocate(ctx.alloc, immutable Local(
			rangeInFile2(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols)),
			ast.name.name,
			innerType));
		immutable Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		immutable Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
		return immutable Expr(
			range,
			allocate(ctx.alloc, immutable Expr.IfOption(inferred(expected), option, local, then, else_)));
	}
}

immutable(Expr) checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable InterpolatedAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> interp with-text "a" with-value b with-text "c" finish
	immutable CallAst firstCall = immutable CallAst(
		CallAst.style.single,
		immutable NameAndRange(range.range.start, shortSym("interp")),
		emptyArr!TypeAst,
		emptyArr!ExprAst);
	immutable ExprAst firstCallExpr = immutable ExprAst(
		immutable RangeWithinFile(range.range.start, range.range.start),
		immutable ExprAstKind(firstCall));
	immutable CallAst call = checkInterpolatedRecur(ctx, ast.parts, range.start + 1, firstCallExpr);
	return checkCall(ctx, locals, range, call, expected);
}

immutable(CallAst) checkInterpolatedRecur(
	ref ExprCtx ctx,
	immutable InterpolatedPart[] parts,
	immutable Pos pos,
	ref immutable ExprAst left,
) {
	if (empty(parts))
		return immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(pos, shortSym("finish")),
			emptyArr!TypeAst,
			arrLiteral!ExprAst(ctx.alloc, [left]));
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
					emptyArr!TypeAst,
					arrLiteral!ExprAst(ctx.alloc, [left, right]));
			},
			(ref immutable ExprAst e) =>
				immutable CallAst(
					CallAst.Style.infix,
					immutable NameAndRange(pos, shortSym("with-value")),
					emptyArr!TypeAst,
					arrLiteral!ExprAst(ctx.alloc, [left, e])),
		)(parts[0]);
		immutable Pos newPos = matchInterpolatedPart!(
			immutable Pos,
			(ref immutable string it) => safeToUint(pos + it.length),
			(ref immutable ExprAst e) => e.range.end,
		)(parts[0]);
		immutable ExprAst newLeft = immutable ExprAst(
			immutable RangeWithinFile(pos, newPos),
			immutable ExprAstKind(c));
		return checkInterpolatedRecur(ctx, parts[1 .. $], newPos, newLeft);
	}
}

struct ExpectedLambdaType {
	immutable Ptr!StructInst funStructInst;
	immutable Ptr!StructDecl funStruct;
	immutable FunKind kind;
	immutable Type nonInstantiatedPossiblyFutReturnType;
}

immutable(Opt!ExpectedLambdaType) getExpectedLambdaType(
	ref TypeArgsArray paramTypes,
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref const Expected expected,
) {
	immutable Opt!Type expectedType = shallowInstantiateType(expected);
	if (!has(expectedType) || !isStructInst(force(expectedType))) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	immutable Ptr!StructInst expectedStructInst = asStructInst(force(expectedType));
	immutable Ptr!StructDecl funStruct = decl(expectedStructInst.deref());
	immutable Opt!FunKind opKind = getFunStructInfo(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		immutable FunKind kind = force(opKind);
		immutable Type nonInstantiatedNonFutReturnType = expectedStructInst.deref().typeArgs[0];
		immutable Type[] nonInstantiatedParamTypes = expectedStructInst.deref().typeArgs[1 .. $];

		foreach (ref immutable Type x; nonInstantiatedParamTypes) {
			immutable Opt!Type t = tryGetDeeplyInstantiatedTypeFor(ctx.alloc, ctx.programState, expected, x);
			if (has(t)) {
				push(paramTypes, force(t));
			} else {
				addDiag2(ctx, range, immutable Diag(immutable Diag.LambdaCantInferParamTypes()));
				return none!ExpectedLambdaType;
			}
		}

		immutable Type nonInstantiatedReturnType = kind == FunKind.ref_
			? makeFutType(ctx.alloc, ctx.programState, ctx.commonTypes, nonInstantiatedNonFutReturnType)
			: nonInstantiatedNonFutReturnType;
		return some(immutable ExpectedLambdaType(
			expectedStructInst,
			funStruct,
			kind,
			nonInstantiatedReturnType));
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

struct VariableRefAndType {
	immutable VariableRef variableRef;
	immutable Type type;
}

immutable(Opt!VariableRefAndType) getIdentifierNonCall(ref Alloc alloc, ref LocalsInfo locals, immutable Sym name) {
	immutable Opt!(Ptr!Local) fromLocals = has(locals.locals)
		? getIdentifierInLocals(force(locals.locals).deref(), name)
		: none!(Ptr!Local);
	return has(fromLocals)
		? some(immutable VariableRefAndType(immutable VariableRef(force(fromLocals)), force(fromLocals).deref().type))
		: getIdentifierFromFunOrLambda(alloc, name, locals.funOrLambda.deref());
}

immutable(Opt!(Ptr!Local)) getIdentifierInLocals(ref LocalNode node, immutable Sym name) {
	if (symEq(node.local.deref().name, name)) {
		node.isUsed = true;
		return some(node.local);
	} else if (has(node.prev))
		return getIdentifierInLocals(force(node.prev).deref(), name);
	else
		return none!(Ptr!Local);
}

immutable(Opt!VariableRefAndType) getIdentifierFromFunOrLambda(
	ref Alloc alloc,
	immutable Sym name,
	ref FunOrLambdaInfo info,
) {
	foreach (immutable Ptr!Param param; ptrsRange(info.params))
		if (has(param.deref().name) && symEq(force(param.deref().name), name)) {
			info.paramsUsed[param.deref().index] = true;
			return some(immutable VariableRefAndType(immutable VariableRef(param), param.deref().type));
		}
	foreach (immutable size_t index, ref immutable ClosureFieldBuilder field; tempAsArr(info.closureFields))
		if (symEq(field.name, name))
			return some(immutable VariableRefAndType(
				immutable VariableRef(immutable Expr.ClosureFieldRef(
					immutable PtrAndSmallNumber!(Expr.Lambda)(force(info.lambda), safeToUshort(index)))),
				field.type));

	immutable(Opt!VariableRefAndType) optOuter = has(info.outer)
		? getIdentifierNonCall(alloc, force(info.outer).deref(), name)
		: none!VariableRefAndType;
	if (has(optOuter)) {
		immutable VariableRefAndType outer = force(optOuter);
		immutable size_t closureFieldIndex = mutMaxArrSize(info.closureFields);
		push(info.closureFields, immutable ClosureFieldBuilder(name, outer.type, outer.variableRef));
		return some(immutable VariableRefAndType(
			immutable VariableRef(immutable Expr.ClosureFieldRef(
				immutable PtrAndSmallNumber!(Expr.Lambda)(force(info.lambda), safeToUshort(closureFieldIndex)))),
			outer.type));
	} else
		return none!VariableRefAndType;
}

immutable(bool) nameIsParameterOrLocalInScope(ref Alloc alloc, ref LocalsInfo locals, immutable Sym name) {
	immutable Opt!VariableRefAndType var = getIdentifierNonCall(alloc, locals, name);
	return has(var);
}

immutable(Expr) checkIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable IdentifierAst ast,
	ref Expected expected,
) {
	immutable Sym name = ast.name;
	immutable Opt!VariableRefAndType res = getIdentifierNonCall(ctx.alloc, locals, name);
	if (has(res)) {
		immutable Expr expr = toExpr(range, force(res).variableRef);
		return check(ctx, expected, force(res).type, expr);
	} else
		return checkIdentifierCall(ctx, locals, range, name, expected);
}

immutable(Expr) toExpr(immutable FileAndRange range, immutable VariableRef a) {
	return matchVariableRef(
		a,
		(immutable Ptr!Param x) =>
			immutable Expr(range, immutable Expr.ParamRef(x)),
		(immutable Ptr!Local x) =>
			immutable Expr(range, immutable Expr.LocalRef(x)),
		(immutable Expr.ClosureFieldRef x) =>
			immutable Expr(range, x));
}

struct IntRange {
	immutable long min;
	immutable long max;
}

immutable(Expr) checkLiteral(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref immutable ExprAst curAst,
	ref immutable LiteralAst ast,
	ref Expected expected,
) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	immutable Opt!(Ptr!StructInst) expectedStruct = has(expectedType) && isStructInst(force(expectedType))
		? some(asStructInst(force(expectedType)))
		: none!(Ptr!StructInst);
	immutable(bool) expectedStructIs(immutable Ptr!StructInst x) {
		return has(expectedStruct) && ptrEquals(force(expectedStruct), x);
	}
	immutable IntegralTypes integrals = ctx.commonTypes.integrals;

	immutable(Expr) asFloat32(immutable float value) {
		immutable Expr e = immutable Expr(range, allocate(ctx.alloc, immutable Expr.Literal(
			ctx.commonTypes.float32,
			immutable Constant(immutable Constant.Float(value)))));
		return check(ctx, expected, immutable Type(ctx.commonTypes.float32), e);
	}

	immutable(Expr) asFloat64(immutable double value) {
		immutable Expr e = immutable Expr(range, allocate(ctx.alloc, immutable Expr.Literal(
			ctx.commonTypes.float64,
			immutable Constant(immutable Constant.Float(value)))));
		return check(ctx, expected, immutable Type(ctx.commonTypes.float64), e);
	}

	return matchLiteralAst!(
		immutable Expr,
		(immutable LiteralAst.Float it) {
			if (it.overflow)
				todo!void("literal overflow");

			return expectedStructIs(ctx.commonTypes.float32)
				? asFloat32(it.value)
				: asFloat64(it.value);
		},
		(immutable LiteralAst.Int it) {
			if (expectedStructIs(ctx.commonTypes.float32))
				return asFloat32(cast(immutable float) it.value);
			if (expectedStructIs(ctx.commonTypes.float64))
				return asFloat64(cast(immutable double) it.value);
			else {
				immutable(Opt!IntRange) intRange = expectedStructIs(integrals.int8)
					? some(immutable IntRange(byte.min, byte.max))
					: expectedStructIs(integrals.int16)
					? some(immutable IntRange(short.min, short.max))
					: expectedStructIs(integrals.int32)
					? some(immutable IntRange(int.min, int.max))
					: expectedStructIs(integrals.int64)
					? some(immutable IntRange(long.min, long.max))
					: none!IntRange;
				immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
				if (has(intRange)) {
					if (it.overflow || it.value < force(intRange).min || it.value > force(intRange).max)
						todo!void("literal overflow");
					return immutable Expr(
						range,
						allocate(ctx.alloc, immutable Expr.Literal(force(expectedStruct), constant)));
				} else {
					immutable Expr e = immutable Expr(
						range,
						allocate(ctx.alloc, immutable Expr.Literal(integrals.int64, constant)));
					return check(ctx, expected, immutable Type(integrals.int64), e);
				}
			}
		},
		(immutable LiteralAst.Nat it) {
			if (expectedStructIs(ctx.commonTypes.float32))
				return asFloat32(cast(immutable float) it.value);
			if (expectedStructIs(ctx.commonTypes.float64))
				return asFloat64(cast(immutable double) it.value);
			else {
				immutable(Opt!ulong) max = expectedStructIs(integrals.nat8)
					? some!ulong(ubyte.max)
					: expectedStructIs(integrals.nat16)
					? some!ulong(ushort.max)
					: expectedStructIs(integrals.nat32)
					? some!ulong(uint.max)
					: expectedStructIs(integrals.nat64)
					? some(ulong.max)
					: expectedStructIs(integrals.int8)
					? some!ulong(byte.max)
					: expectedStructIs(integrals.int16)
					? some!ulong(short.max)
					: expectedStructIs(integrals.int32)
					? some!ulong(int.max)
					: expectedStructIs(integrals.int64)
					? some!ulong(long.max)
					: none!ulong;
				immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
				if (has(max)) {
					if (it.overflow || it.value > force(max))
						addDiag2(ctx, range, immutable Diag(
							immutable Diag.LiteralOverflow(force(expectedStruct))));
					return immutable Expr(
						range,
						allocate(ctx.alloc, immutable Expr.Literal(force(expectedStruct), constant)));
				} else {
					if (it.overflow)
						todo!void("literal overflow");
					immutable Expr e = immutable Expr(
						range,
						allocate(ctx.alloc, immutable Expr.Literal(integrals.nat64, constant)));
					return check(ctx, expected, immutable Type(integrals.nat64), e);
				}
			}
		},
		(immutable string value) =>
			checkStringLiteral(ctx, curAst, range, expected, expectedStruct, value),
	)(ast);
}

immutable(Expr) checkStringLiteral(
	ref ExprCtx ctx,
	ref immutable ExprAst curAst,
	immutable FileAndRange range,
	ref Expected expected,
	immutable Opt!(Ptr!StructInst) expectedStruct,
	immutable string value,
) {
	return has(expectedStruct) && ptrEquals(force(expectedStruct), ctx.commonTypes.char8)
		? checkStringLiteralTypedAsChar(ctx, range, value)
		: has(expectedStruct) && ptrEquals(force(expectedStruct), ctx.commonTypes.sym)
		? immutable Expr(range, immutable Expr.LiteralSymbol(symOfStr(ctx.allSymbols, value)))
		: has(expectedStruct) && ptrEquals(force(expectedStruct), ctx.commonTypes.cStr)
		? immutable Expr(range, immutable Expr.LiteralCString(copyToSafeCStr(ctx.alloc, value)))
		: checkStringExpressionTypedAsOther(ctx, curAst, range, expected, expectedStruct);
}

immutable(Expr) checkStringLiteralTypedAsChar(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	immutable string value,
) {
	immutable char char_ = () {
		if (value.length != 1) {
			addDiag2(ctx, range, immutable Diag(immutable Diag.CharLiteralMustBeOneChar()));
			return 'a';
		} else
			return only(value);
	}();
	return immutable Expr(
		range,
		allocate(ctx.alloc, immutable Expr.Literal(
			ctx.commonTypes.char8,
			immutable Constant(immutable Constant.Integral(char_)))));
}

immutable(Expr) checkStringExpressionTypedAsOther(
	ref ExprCtx ctx,
	ref immutable ExprAst curAst,
	immutable FileAndRange range,
	ref Expected expected,
	immutable Opt!(Ptr!StructInst) expectedStruct,
) {
	if (!has(expectedStruct))
		mustSetType(ctx.alloc, ctx.programState, expected, getStrType(ctx, range));
	// TODO: NEATER (don't create a synthetic AST)
	immutable CallAst ast = immutable CallAst(
		CallAst.Style.emptyParens,
		immutable NameAndRange(range.start, shortSym("literal")),
		emptyArr!TypeAst,
		// TODO: allocating should be unnecessary, do on stack
		arrLiteral!ExprAst(ctx.alloc, [curAst]));
	return checkCallNoLocals(ctx, range, ast, expected);
}

immutable(Type) getStrType(ref ExprCtx ctx, immutable FileAndRange range) {
	return typeFromAst2(ctx, immutable TypeAst(immutable TypeAst.InstStruct(
		range.range,
		immutable NameAndRange(range.start, shortSym("str")),
		emptySmallArray!TypeAst)));
}

immutable(Expr) checkWithLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable Ptr!Local local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	// Look for a parameter with the name
	if (nameIsParameterOrLocalInScope(ctx.alloc, locals, local.deref().name)) {
		addDiag2(ctx, local.deref().range, immutable Diag(
			immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.deref().name)));
		return bogus(expected, rangeInFile2(ctx, ast.range));
	} else {
		LocalNode localNode = LocalNode(locals.locals, false, local);
		LocalsInfo newLocals = LocalsInfo(locals.funOrLambda, someMut(ptrTrustMe_mut(localNode)));
		immutable Expr res = checkExpr(ctx, newLocals, ast, expected);
		if (!localNode.isUsed)
			addDiag2(ctx, local.deref().range, immutable Diag(immutable Diag.UnusedLocal(local)));
		return res;
	}
}

immutable(Param[]) checkParamsForLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope immutable LambdaAst.Param[] paramAsts,
	scope immutable Type[] expectedParamTypes,
) {
	return mapZipWithIndex!(Param, LambdaAst.Param, Type)(
		ctx.alloc,
		paramAsts,
		expectedParamTypes,
		(ref immutable LambdaAst.Param ast, ref immutable Type type, immutable size_t index) {
			immutable RangeWithinFile range = rangeOfOptNameAndRange(ast, ctx.allSymbols);
			immutable Opt!Sym name = () {
				if (has(ast.name) && nameIsParameterOrLocalInScope(ctx.alloc, locals, force(ast.name))) {
					addDiag(ctx.checkCtx, range, immutable Diag(
						immutable Diag.DuplicateDeclaration(
							Diag.DuplicateDeclaration.Kind.paramOrLocal,
							force(ast.name))));
					return none!Sym;
				} else
					return ast.name;
			}();
			return immutable Param(rangeInFile2(ctx, range), name, type, index);
		});
}

immutable(Expr) checkFunPtr(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref immutable FunPtrAst ast,
	ref Expected expected,
) {
	MutArr!(immutable Ptr!FunDecl) funsInScope = MutArr!(immutable Ptr!FunDecl)();
	eachFunInScope(ctx, ast.name, (immutable UsedFun used, immutable CalledDecl cd) {
		matchCalledDecl!(
			void,
			(immutable Ptr!FunDecl it) {
				markUsedFun(ctx, used);
				push(ctx.alloc, funsInScope, it);
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

	immutable Ptr!FunInst funInst = instantiateFun(ctx.alloc, ctx.programState, funDecl, [], []);
	immutable Ptr!StructDecl funPtrStruct = ctx.commonTypes.funPtrStructs[nParams];
	scope TypeArgsArray returnTypeAndParamTypes = typeArgsArray();
	push(returnTypeAndParamTypes, returnType(funDecl.deref()));
	foreach (ref immutable Param x; assertNonVariadic(params(funInst.deref())))
		push(returnTypeAndParamTypes, x.type);
	immutable Ptr!StructInst structInst =
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, funPtrStruct, tempAsArr(returnTypeAndParamTypes));
	immutable Expr expr = immutable Expr(range, immutable Expr.FunPtr(funInst, structInst));
	return check(ctx, expected, immutable Type(structInst), expr);
}

immutable(Expr) checkLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LambdaAst ast,
	ref Expected expected,
) {
	scope TypeArgsArray paramTypes = typeArgsArray();
	immutable Opt!ExpectedLambdaType opEt = getExpectedLambdaType(paramTypes, ctx, range, expected);
	if (!has(opEt))
		return bogus(expected, range);

	immutable ExpectedLambdaType et = force(opEt);
	immutable FunKind kind = et.kind;

	if (!sizeEq(ast.params, tempAsArr(paramTypes))) {
		addDiag2(ctx, range, immutable Diag(Diag.LambdaWrongNumberParams(et.funStructInst, ast.params.length)));
		return bogus(expected, range);
	}

	immutable Param[] params = checkParamsForLambda(ctx, locals, ast.params, tempAsArr(paramTypes));
	Expected returnTypeInferrer = copyWithNewExpectedType(expected, et.nonInstantiatedPossiblyFutReturnType);

	Ptr!(Expr.Lambda) lambda = () @trusted { return allocateUninitialized!(Expr.Lambda)(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo = FunOrLambdaInfo(someMut(ptrTrustMe_mut(locals)), params, some(castImmutable(lambda)));
	fillMutMaxArr(lambdaInfo.paramsUsed, params.length, false);
	initializeMutMaxArr(lambdaInfo.closureFields);
	scope LocalsInfo lambdaLocalsInfo = LocalsInfo(ptrTrustMe_mut(lambdaInfo), noneMut!(Ptr!LocalNode));

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	immutable Expr body_ = checkExpr(ctx, lambdaLocalsInfo, ast.body_, returnTypeInferrer);

	checkUnusedParams(ctx.checkCtx, params, tempAsArr(lambdaInfo.paramsUsed));

	final switch (kind) {
		case FunKind.plain:
			foreach (ref immutable ClosureFieldBuilder cf; tempAsArr(lambdaInfo.closureFields))
				if (worstCasePurity(cf.type) == Purity.mut)
					addDiag2(ctx, range, immutable Diag(immutable Diag.LambdaClosesOverMut(cf.name, cf.type)));
			break;
		case FunKind.mut:
		case FunKind.ref_:
			break;
	}
	immutable VariableRef[] closureFields =
		map(ctx.alloc, tempAsArr(lambdaInfo.closureFields), (ref immutable ClosureFieldBuilder x) =>
			x.variableRef);

	immutable Type actualPossiblyFutReturnType = inferred(returnTypeInferrer);
	immutable Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? matchType!(immutable Opt!Type)(
			actualPossiblyFutReturnType,
			(immutable Type.Bogus) =>
				some(immutable Type(immutable Type.Bogus())),
			(immutable Ptr!TypeParam) =>
				none!Type,
			(immutable Ptr!StructInst ap) =>
				ptrEquals(ap.deref().decl, ctx.commonTypes.fut)
					? some!Type(only(ap.deref().typeArgs))
					: none!Type)
		: some!Type(actualPossiblyFutReturnType);
	if (!has(actualNonFutReturnType)) {
		addDiag2(ctx, range, immutable Diag(
			immutable Diag.SendFunDoesNotReturnFut(actualPossiblyFutReturnType)));
		return bogus(expected, range);
	} else {
		pushLeft(paramTypes, force(actualNonFutReturnType));
		immutable Ptr!StructInst instFunStruct =
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, et.funStruct, tempAsArr(paramTypes));
		initMemory(lambda.rawPtr(), immutable Expr.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType));
		return immutable Expr(range, castImmutable(lambda));
	}
}

immutable(Expr) checkLet(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LetAst ast,
	ref Expected expected,
) {
	immutable ExprAndType init = checkAndExpect(ctx, locals, ast.initializer, typeFromOptAst(ctx, ast.type));
	if (has(ast.name)) {
		immutable Ptr!Local local = allocate(ctx.alloc, immutable Local(
			rangeInFile2(ctx, rangeOfOptNameAndRange(immutable OptNameAndRange(range.start, ast.name), ctx.allSymbols)),
			force(ast.name),
			init.type));
		immutable Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Let(local, init.expr, then)));
	} else {
		immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
		return immutable Expr(range,
			allocate(ctx.alloc, immutable Expr.Seq(
				immutable Expr(init.expr.range, allocate(ctx.alloc, immutable Expr.Drop(init.expr))),
				then)));
	}
}

immutable(Expr) checkWithOptLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable Opt!(Ptr!Local) local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	return has(local)
		? checkWithLocal(ctx, locals, force(local), ast, expected)
		: checkExpr(ctx, locals, ast, expected);
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
	return matchType!(immutable Opt!EnumOrUnionAndMembers)(
		a,
		(immutable Type.Bogus) => none!EnumOrUnionAndMembers,
		(immutable Ptr!TypeParam) => none!EnumOrUnionAndMembers,
		(immutable Ptr!StructInst structInst) =>
			matchStructBody!(immutable Opt!EnumOrUnionAndMembers)(
				body_(structInst.deref()),
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
					some(immutable EnumOrUnionAndMembers(immutable UnionAndMembers(structInst, it.members)))));
}

immutable(Expr) checkMatch(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
) {
	immutable ExprAndType matchedAndType = checkAndInfer(ctx, locals, ast.matched);
	immutable Opt!EnumOrUnionAndMembers enumOrUnionAndMembers = getEnumOrUnionBody(matchedAndType.type);
	if (has(enumOrUnionAndMembers))
		return matchEnumOrUnionAndMembers!(immutable Expr)(
			force(enumOrUnionAndMembers),
			(ref immutable EnumAndMembers it) =>
				checkMatchEnum(ctx, locals, range, ast, expected, matchedAndType.expr, it.members),
			(ref immutable UnionAndMembers it) =>
				checkMatchUnion(ctx, locals, range, ast, expected, matchedAndType.expr, it.structInst, it.members));
	else {
		if (!isBogus(matchedAndType.type))
			addDiag2(ctx, rangeInFile2(ctx, ast.matched.range), immutable Diag(
				immutable Diag.MatchOnNonUnion(matchedAndType.type)));
		return bogus(expected, rangeInFile2(ctx, ast.matched.range));
	}
}

immutable(Expr) checkMatchEnum(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
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
		addDiag2(ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map!Sym(ctx.alloc, members, (ref immutable StructBody.Enum.Member member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable Expr[] cases = map!Expr(ctx.alloc, ast.cases, (ref immutable MatchAst.CaseAst caseAst) {
			matchNameOrUnderscoreOrNone!(
				void,
				(immutable(Sym)) =>
					todo!void("diagnostic: no local for enum match"),
				(ref immutable NameOrUnderscoreOrNone.Underscore) =>
					todo!void("diagnostic: unnecessary underscore"),
				(ref immutable NameOrUnderscoreOrNone.None) {},
			)(caseAst.local);
			return checkExpr(ctx, locals, caseAst.then, expected);
		});
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.MatchEnum(matched, cases, inferred(expected))));
	}
}

immutable(Expr) checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
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
		addDiag2(ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map!Sym(ctx.alloc, members, (ref immutable UnionMember member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable Expr.MatchUnion.Case[] cases = mapZip!(Expr.MatchUnion.Case)(
			ctx.alloc,
			members,
			ast.cases,
			(ref immutable UnionMember member, ref immutable MatchAst.CaseAst caseAst) =>
				checkMatchCase(ctx, locals, member, caseAst, expected));
		return immutable Expr(
			range,
			allocate(ctx.alloc, immutable Expr.MatchUnion(matched, matchedUnion, cases, inferred(expected))));
	}
}

immutable(Expr.MatchUnion.Case) checkMatchCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref immutable UnionMember member,
	ref immutable MatchAst.CaseAst caseAst,
	ref Expected expected,
) {
	immutable FileAndRange localRange = rangeInFile2(ctx, caseAst.localRange(ctx.allSymbols));
	immutable Opt!(Ptr!Local) local = matchNameOrUnderscoreOrNone!(
		immutable Opt!(Ptr!Local),
		(immutable Sym name) {
			if (has(member.type))
				return some(allocate(ctx.alloc, immutable Local(localRange, name, force(member.type))));
			else {
				addDiag2(ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(name)));
				return none!(Ptr!Local);
			}
		},
		(ref immutable NameOrUnderscoreOrNone.Underscore) {
			if (!has(member.type))
				addDiag2(ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(shortSym("_"))));
			return none!(Ptr!Local);
		},
		(ref immutable NameOrUnderscoreOrNone.None) {
			if (has(member.type))
				addDiag2(ctx, rangeInFile2(ctx, caseAst.range), immutable Diag(
					immutable Diag.MatchCaseShouldHaveLocal(member.name)));
			return none!(Ptr!Local);
		},
	)(caseAst.local);
	immutable Expr then = isBogus(expected)
		? bogus(expected, rangeInFile2(ctx, caseAst.range))
		: checkWithOptLocal(ctx, locals, local, caseAst.then, expected);
	return immutable Expr.MatchUnion.Case(local, then);
}

immutable(Expr) checkSeq(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable SeqAst ast,
	ref Expected expected,
) {
	immutable Expr first = checkAndExpect(ctx, locals, ast.first, ctx.commonTypes.void_);
	immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Seq(first, then)));
}

immutable(Expr) checkThen(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable ThenAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst(
			arrLiteral!(LambdaAst.Param)(ctx.alloc, [ast.left]),
			ast.then))));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSym("then")),
		emptyArr!TypeAst,
		arrLiteral!ExprAst(ctx.alloc, [ast.futExpr, lambda]));
	return checkCall(ctx, locals, range, call, expected);
}

immutable(Expr) checkThenVoid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable ThenVoidAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst(emptyArr!(LambdaAst.Param), ast.then))));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSym("then-void")),
		emptyArr!TypeAst,
		arrLiteral!ExprAst(ctx.alloc, [ast.futExpr, lambda]));
	return checkCall(ctx, locals, range, call, expected);
}

immutable(Expr) checkTyped(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable TypedAst ast,
	ref Expected expected,
) {
	immutable Type type = typeFromAst2(ctx, ast.type);
	immutable Opt!Type inferred = tryGetInferred(expected);
	// If inferred != type, we'll fail in 'check'
	if (has(inferred) && typeEquals(force(inferred), type))
		addDiag2(ctx, range, immutable Diag(immutable Diag.TypeAnnotationUnnecessary(type)));
	immutable Expr expr = checkAndExpect(ctx, locals, ast.expr, type);
	return check(ctx, expected, type, expr);
}

public immutable(Expr) checkExpr(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	scope ref Expected expected,
) {
	immutable FileAndRange range = rangeInFile2(ctx, ast.range);
	return matchExprAstKind!(
		immutable Expr,
		(ref immutable ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, range, a, expected),
		(ref immutable(BogusAst)) =>
			bogus(expected, range),
		(ref immutable CallAst a) =>
			checkCall(ctx, locals, range, a, expected),
		(ref immutable FunPtrAst a) =>
			checkFunPtr(ctx, range, a, expected),
		(ref immutable IdentifierAst a) =>
			checkIdentifier(ctx, locals, range, a, expected),
		(ref immutable IfAst a) =>
			checkIf(ctx, locals, range, a, expected),
		(ref immutable IfOptionAst a) =>
			checkIfOption(ctx, locals, range, a, expected),
		(ref immutable InterpolatedAst a) =>
			checkInterpolated(ctx, locals, range, a, expected),
		(ref immutable LambdaAst a) =>
			checkLambda(ctx, locals, range, a, expected),
		(ref immutable LetAst a) =>
			checkLet(ctx, locals, range, a, expected),
		(ref immutable LiteralAst a) =>
			checkLiteral(ctx, range, ast, a, expected),
		(ref immutable MatchAst a) =>
			checkMatch(ctx, locals, range, a, expected),
		(ref immutable ParenthesizedAst a) =>
			checkExpr(ctx, locals, a.inner, expected),
		(ref immutable SeqAst a) =>
			checkSeq(ctx, locals, range, a, expected),
		(ref immutable ThenAst a) =>
			checkThen(ctx, locals, range, a, expected),
		(ref immutable ThenVoidAst a) =>
			checkThenVoid(ctx, locals, range, a, expected),
		(ref immutable TypedAst a) =>
			checkTyped(ctx, locals, range, a, expected),
		(ref immutable UnlessAst a) =>
			checkUnless(ctx, locals, range, a, expected),
	)(ast.kind);
}
