module frontend.check.checkExpr;

@safe @nogc pure nothrow:

import frontend.check.checkCall : checkCall, checkIdentifierCall, eachFunInScope, markUsedFun, UsedFun;
import frontend.check.checkCtx : addDiag, CheckCtx;
import frontend.check.dicts : FunsDict, StructsAndAliasesDict;
import frontend.check.inferringType :
	addDiag2,
	allocExpr,
	bogus,
	bogusWithoutChangingExpected,
	check,
	CheckedExpr,
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
	tryGetDeeplyInstantiatedType,
	tryGetDeeplyInstantiatedTypeFor,
	tryGetInferred;
import frontend.check.instantiate : instantiateFun, instantiateStructNeverDelay;
import frontend.check.typeFromAst : makeFutType;
import frontend.parse.ast :
	BogusAst,
	CallAst,
	CreateArrAst,
	ExprAst,
	ExprAstKind,
	FunPtrAst,
	IdentifierAst,
	IfAst,
	InterpolatedAst,
	InterpolatedPart,
	LambdaAst,
	LambdaSingleLineAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	matchInterpolatedPart,
	matchLiteralAst,
	NameAndRange,
	ParenthesizedAst,
	rangeOfNameAndRange,
	SeqAst,
	ThenAst,
	ThenVoidAst,
	TypeAst;
import model.constant : Constant;
import model.diag : Diag;
import model.model :
	arity,
	asStructInst,
	asUnion,
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
	isUnion,
	Local,
	matchCalledDecl,
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
	TypeParam,
	worstCasePurity;
import util.collection.arr :
	at,
	castImmutable,
	empty,
	emptyArr,
	emptyArrWithSize,
	first,
	only,
	ptrsRange,
	setAt,
	size,
	sizeEq,
	toArr;
import util.collection.arrUtil :
	arrLiteral,
	arrWithSizeLiteral,
	exists,
	findSome,
	fillArr_mut,
	map,
	mapOrNone,
	mapWithFirst,
	mapZip,
	mapZipWithIndex,
	prepend,
	tail,
	zipPtrFirst,
	zipSome;
import util.collection.mutArr :
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
import util.collection.str : copyStr;
import util.memory : nu;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.types : safeSizeTToU32;
import util.util : todo, unreachable, verify;

immutable(Ptr!Expr) checkFunctionBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx checkCtx,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable CommonTypes commonTypes,
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
		ptrTrustMe(structsAndAliasesDict),
		ptrTrustMe(funsDict),
		ptrTrustMe(commonTypes),
		specs,
		params,
		typeParams,
		flags,
		usedFuns,
		// TODO: use temp alloc
		fillArr_mut!(bool, Alloc)(alloc, size(params), (immutable size_t) =>
			false));
	immutable Ptr!Expr res = allocExpr(alloc, checkAndExpect!Alloc(alloc, exprCtx, ast, returnType));
	zipPtrFirst!(Param, bool)(
		params,
		castImmutable(exprCtx.paramsUsed),
		(immutable Ptr!Param param, ref immutable bool used) {
			if (!used && has(param.name))
				addDiag(alloc, checkCtx, param.range, immutable Diag(immutable Diag.UnusedParam(param)));
		});
	return res;
}

immutable(Expr) checkExpr(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	return checkExprWorker(alloc, ctx, ast, expected).expr;
}

private:

immutable(T) withLambda(T, Alloc)(
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

immutable(ExprAndType) checkAndInfer(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
) {
	Expected expected = Expected.infer();
	immutable Expr expr = checkExpr(alloc, ctx, ast, expected);
	return ExprAndType(expr, inferred(expected));
}

immutable(Expr) checkAndExpect(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Opt!Type expected,
) {
	Expected et = Expected(expected);
	return checkExpr(alloc, ctx, ast, et);
}

immutable(Expr) checkAndExpect(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Type expected,
) {
	return checkAndExpect(alloc, ctx, ast, some(expected));
}

immutable(Expr) checkAndExpect(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	immutable Ptr!StructInst expected,
) {
	return checkAndExpect(alloc, ctx, ast, immutable Type(expected));
}

immutable(CheckedExpr) checkIf(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable IfAst ast,
	ref Expected expected,
) {
	immutable Ptr!Expr cond = allocExpr(alloc, checkAndExpect(alloc, ctx, ast.cond, ctx.commonTypes.bool_));
	if (has(ast.else_)) {
		immutable Ptr!Expr then = allocExpr(alloc, checkExpr(alloc, ctx, ast.then, expected));
		immutable Ptr!Expr else_ = allocExpr(alloc, checkExpr(alloc, ctx, force(ast.else_), expected));
		return immutable CheckedExpr(immutable Expr(range, immutable Expr.Cond(inferred(expected), cond, then, else_)));
	} else {
		immutable Ptr!StructInst void_ = ctx.commonTypes.void_;
		immutable Ptr!Expr then = allocExpr(alloc, checkAndExpect(alloc, ctx, ast.then, void_));
		immutable Ptr!Expr else_ = allocExpr(alloc, immutable Expr(range, nu!(Expr.Literal)(
			alloc,
			void_,
			immutable Constant(immutable Constant.Void()))));
		immutable Type voidType = immutable Type(void_);
		immutable Expr expr = immutable Expr(range, immutable Expr.Cond(voidType, cond, then, else_));
		return check(alloc, ctx, expected, voidType, expr);
	}
}

immutable(CheckedExpr) checkInterpolated(Alloc)(
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
		immutable NameAndRange(range.range.start, shortSymAlphaLiteral("interp")),
		emptyArrWithSize!TypeAst,
		emptyArrWithSize!ExprAst);
	immutable ExprAst firstCallExpr = immutable ExprAst(
		immutable RangeWithinFile(range.range.start, range.range.start),
		immutable ExprAstKind(firstCall));
	immutable CallAst call = checkInterpolatedRecur!Alloc(alloc, ctx, ast.parts, range.start + 1, firstCallExpr);
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CallAst) checkInterpolatedRecur(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable InterpolatedPart[] parts,
	immutable Pos pos,
	ref immutable ExprAst left,
) {
	if (empty(parts))
		return immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(pos, shortSymAlphaLiteral("finish")),
			emptyArrWithSize!TypeAst,
			arrWithSizeLiteral!(ExprAst, Alloc)(alloc, [left]));
	else {
		immutable CallAst c = matchInterpolatedPart!(immutable CallAst)(
			parts[0],
			(ref immutable string it) {
				immutable ExprAst right = immutable ExprAst(
					// TODO: this length may be wrong in the presence of escapes
					immutable RangeWithinFile(pos, safeSizeTToU32(pos + it.length)),
					immutable ExprAstKind(
						immutable LiteralAst(it)));
				return immutable CallAst(
					CallAst.Style.infix,
					immutable NameAndRange(pos, shortSymAlphaLiteral("with-str")),
					emptyArrWithSize!TypeAst,
					arrWithSizeLiteral!ExprAst(alloc, [left, right]));
			},
			(ref immutable ExprAst e) =>
				immutable CallAst(
					CallAst.Style.infix,
					immutable NameAndRange(pos, shortSymAlphaLiteral("with-value")),
					emptyArrWithSize!TypeAst,
					arrWithSizeLiteral!ExprAst(alloc, [left, e])));
		immutable Pos newPos = matchInterpolatedPart!(immutable Pos)(
			parts[0],
			(ref immutable string it) => safeSizeTToU32(pos + it.length),
			(ref immutable ExprAst e) => e.range.end);
		immutable ExprAst newLeft = immutable ExprAst(
			immutable RangeWithinFile(pos, newPos),
			immutable ExprAstKind(c));
		return checkInterpolatedRecur(alloc, ctx, parts[1 .. $], newPos, newLeft);
	}
}


struct ArrExpectedType {
	immutable Ptr!StructInst arrType;
	immutable Type elementType;
}

immutable(CheckedExpr) checkCreateArr(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable CreateArrAst ast,
	ref Expected expected,
) {
	immutable Opt!ArrExpectedType opAet = () {
		immutable Opt!Type opT = tryGetDeeplyInstantiatedType(alloc, programState(ctx), expected);
		if (has(opT)) {
			immutable Type t = force(opT);
			if (isStructInst(t)) {
				immutable Ptr!StructInst si = asStructInst(t);
				if (ptrEquals(decl(si), ctx.commonTypes.arr))
					return some(immutable ArrExpectedType(si, only(typeArgs(si))));
			}
		}
		return none!ArrExpectedType;
	}();

	immutable ExprAst[] argAsts = toArr(ast.args);
	if (has(opAet)) {
		immutable ArrExpectedType aet = force(opAet);
		immutable Expr[] args = map!Expr(alloc, argAsts, (ref immutable ExprAst it) =>
			checkAndExpect(alloc, ctx, it, aet.elementType));
		immutable Expr expr = immutable Expr(range, immutable Expr.CreateArr(aet.arrType, args));
		return immutable CheckedExpr(expr);
	} else if (empty(argAsts)) {
		addDiag2(alloc, ctx, range, Diag(Diag.CreateArrNoExpectedType()));
		return bogusWithoutChangingExpected(expected, range);
	} else {
		// Get type from the first arg's type.
		immutable ExprAndType firstArg = checkAndInfer(alloc, ctx, first(argAsts));
		immutable Type elementType = firstArg.type;
		immutable ExprAst[] restArgs = tail(argAsts);
		immutable Expr[] args = mapWithFirst!Expr(alloc, firstArg.expr, restArgs, (ref immutable ExprAst it) =>
			checkAndExpect(alloc, ctx, it, elementType));
		immutable Ptr!StructInst arrType = instantiateStructNeverDelay(
			alloc,
			ctx.checkCtx.programState,
			immutable StructDeclAndArgs(ctx.commonTypes.arr, arrLiteral!Type(alloc, [elementType])));
		immutable Expr expr = immutable Expr(range, immutable Expr.CreateArr(arrType, args));
		return check!Alloc(alloc, ctx, expected, immutable Type(arrType), expr);
	}
}

struct ExpectedLambdaType {
	immutable Ptr!StructInst funStructInst;
	immutable Ptr!StructDecl funStruct;
	immutable FunKind kind;
	immutable Type[] paramTypes;
	immutable Type nonInstantiatedPossiblyFutReturnType;
}

immutable(Opt!ExpectedLambdaType) getExpectedLambdaType(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref Expected expected,
) {
	immutable Opt!Type expectedType = shallowInstantiateType(expected);
	if (!has(expectedType) || !isStructInst(force(expectedType))) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	immutable Ptr!StructInst expectedStructInst = asStructInst(force(expectedType));
	immutable Ptr!StructDecl funStruct = decl(expectedStructInst);
	immutable Opt!FunKind opKind = getFunStructInfo(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		immutable FunKind kind = force(opKind);
		immutable Type nonInstantiatedNonFutReturnType = first(expectedStructInst.typeArgs);
		immutable Type[] nonInstantiatedParamTypes = tail(expectedStructInst.typeArgs);
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
			addDiag2(alloc, ctx, range, Diag(Diag.LambdaCantInferParamTypes()));
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
		if (symEq(local.local.name, name)) {
			local.isUsed = true;
			return some(immutable Expr(range, immutable Expr.LocalRef(local.local)));
		}
	foreach (immutable Ptr!Param param; ptrsRange(lambda.lambdaParams))
		if (has(param.name) && symEq(force(param.name), name))
			return some(immutable Expr(range, immutable Expr.ParamRef(param)));
	// Check if we've already added something with this name to closureFields to avoid adding it twice.
	foreach (immutable Ptr!ClosureField field; mutArrRange(lambda.closureFields))
		if (symEq(field.name, name))
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
		immutable Opt!Expr id = getIdentifierInLambda(range, name, mutArrAt(ctx.lambdas, i));
		if (has(id))
			return someMut(IdentifierAndLambdas(force(id), tempAsArr_mut(ctx.lambdas)[i + 1 .. $]));
	}

	Ptr!LambdaInfo[] allLambdas = tempAsArr_mut(ctx.lambdas);
	foreach (ref LocalAndUsed local; mutArrRangeMut(ctx.messageOrFunctionLocals))
		if (symEq(local.local.name, name)) {
			local.isUsed = true;
			return someMut(IdentifierAndLambdas(immutable Expr(range, Expr.LocalRef(local.local)), allLambdas));
		}
	foreach (immutable Ptr!Param param; ptrsRange(ctx.outermostFunParams))
		if (has(param.name) && symEq(force(param.name), name)) {
			setAt(ctx.paramsUsed, param.index, true);
			return someMut(IdentifierAndLambdas(immutable Expr(range, Expr.ParamRef(param)), allLambdas));
		}
	return noneMut!IdentifierAndLambdas;
}

immutable(bool) nameIsParameterOrLocalInScope(ref ExprCtx ctx, immutable Sym name) {
	return has(getIdentifierNonCall(ctx, FileAndRange.empty, name));
}

immutable(CheckedExpr) checkRef(Alloc)(
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
		Ptr!LambdaInfo l0 = first(passedLambdas);
		// Shouldn't have already closed over it (or we should just be using that)
		verify(!exists!(immutable Ptr!ClosureField)(tempAsArr(l0.closureFields), (ref immutable Ptr!ClosureField it) =>
			symEq(it.name, name)));
		immutable Ptr!ClosureField field = nu!ClosureField(
			alloc,
			name,
			type,
			allocExpr(alloc, expr),
			mutArrSize(l0.closureFields));
		push(alloc, l0.closureFields, field);
		immutable Expr closureFieldRef = immutable Expr(range(expr), Expr.ClosureFieldRef(field));
		return checkRef!Alloc(alloc, ctx, closureFieldRef, name, tail(passedLambdas), expected);
	}
}

immutable(CheckedExpr) checkIdentifier(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable IdentifierAst ast,
	ref Expected expected,
) {
	immutable Sym name = ast.name;
	Opt!IdentifierAndLambdas opIdentifier = getIdentifierNonCall(ctx, range, name);
	return has(opIdentifier)
		? checkRef!Alloc(
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

immutable(CheckedExpr) checkLiteral(Alloc)(
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
	immutable Ptr!IntegralTypes integrals = ctx.commonTypes.integrals;

	immutable(CheckedExpr) asFloat(immutable double value) {
		immutable Expr e = immutable Expr(
			range,
			nu!(Expr.Literal)(alloc, ctx.commonTypes.float64, immutable Constant(value)));
		return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.float64), e);
	}

	return matchLiteralAst!(immutable CheckedExpr)(
		ast,
		(ref immutable LiteralAst.Float it) {
			if (it.overflow)
				todo!void("literal overflow");
			return asFloat(it.value);
		},
		(ref immutable LiteralAst.Int it) {
			if (ptrEquals(expectedStruct, ctx.commonTypes.float64))
				return asFloat(cast(immutable double) it.value);
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
						immutable Expr(range, nu!(Expr.Literal)(alloc, expectedStruct, constant)));
				} else {
					immutable Expr e = immutable Expr(range, nu!(Expr.Literal)(alloc, integrals.int64, constant));
					return check(alloc, ctx, expected, immutable Type(integrals.int64), e);
				}
			}
		},
		(ref immutable LiteralAst.Nat it) {
			if (ptrEquals(expectedStruct, ctx.commonTypes.float64))
				return asFloat(cast(immutable double) it.value);
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
						immutable Expr(range, nu!(Expr.Literal)(alloc, expectedStruct, constant)));
				} else {
					if (it.overflow)
						todo!void("literal overflow");
					immutable Expr e = immutable Expr(range, nu!(Expr.Literal)(alloc, integrals.nat64, constant));
					return check(alloc, ctx, expected, immutable Type(integrals.nat64), e);
				}
			}
		},
		(ref immutable string it) {
			if (ptrEquals(expectedStruct, ctx.commonTypes.char_)) {
				if (size(it) != 1)
					todo!void("char literal must be one char");
				return immutable CheckedExpr(immutable Expr(
					range,
					nu!(Expr.Literal)(
						alloc,
						expectedStruct,
						immutable Constant(immutable Constant.Integral(only(it))))));
			} else {
				immutable Expr e = immutable Expr(range, immutable Expr.StringLiteral(copyStr(alloc, it)));
				return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.str), e);
			}
		});
}

immutable(Expr) checkWithLocal(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	immutable Ptr!Local local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	// Look for a parameter with the name
	if (nameIsParameterOrLocalInScope(ctx, local.name)) {
		addDiag2(alloc, ctx, local.range, Diag(Diag.LocalShadowsPrevious(local.name)));
		return bogus(expected, rangeInFile2(ctx, ast.range)).expr;
	} else {
		Ptr!(MutArr!LocalAndUsed) locals = mutArrIsEmpty(ctx.lambdas)
			? ptrTrustMe_mut(ctx.messageOrFunctionLocals)
			: ptrTrustMe_mut(mustPeek_mut(ctx.lambdas).locals);
		push(alloc, locals.deref, LocalAndUsed(false, local));
		immutable Expr res = checkExpr(alloc, ctx, ast, expected);
		LocalAndUsed popped = mustPop(locals);
		verify(ptrEquals(popped.local, local));
		if (!popped.isUsed)
			addDiag2!Alloc(alloc, ctx, local.range, immutable Diag(
				immutable Diag.UnusedLocal(local)));
		return res;
	}
}

immutable(Param[]) checkFunOrSendFunParamsForLambda(Alloc)(
	ref Alloc alloc,
	ref const ExprCtx ctx,
	immutable LambdaAst.Param[] paramAsts,
	immutable Type[] expectedParamTypes,
) {
	return mapZipWithIndex!(Param, LambdaAst.Param, Type, Alloc)(
		alloc,
		paramAsts,
		expectedParamTypes,
		(ref immutable LambdaAst.Param ast, ref immutable Type expectedParamType, immutable size_t index) =>
			immutable Param(rangeInFile2(ctx, rangeOfNameAndRange(ast)), some(ast.name), expectedParamType, index));
}

immutable(CheckedExpr) checkFunPtr(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable FunPtrAst ast,
	ref Expected expected,
) {
	MutArr!(immutable Ptr!FunDecl) funsInScope = MutArr!(immutable Ptr!FunDecl)();
	eachFunInScope(ctx, ast.name, (ref immutable Opt!UsedFun used, immutable CalledDecl cd) {
		matchCalledDecl!void(
			cd,
			(immutable Ptr!FunDecl it) {
				if (has(used))
					markUsedFun(ctx, force(used));
				push(alloc, funsInScope, it);
			},
			(ref immutable SpecSig) {
				todo!void("!");
			});
	});
	if (mutArrSize(funsInScope) != 1)
		todo!void("did not find or found too many");
	immutable Ptr!FunDecl funDecl = mutArrAt(funsInScope, 0);

	if (isTemplate(funDecl))
		todo!void("can't point to template");
	if (!funDecl.noCtx)
		todo!void("fun-ptr can't take ctx");
	if (arity(funDecl) >= size(ctx.commonTypes.funPtrStructs))
		todo!void("arity too high");

	immutable Ptr!FunInst funInst = instantiateFun(
		alloc,
		ctx.programState,
		immutable FunDeclAndArgs(funDecl, emptyArr!Type, emptyArr!Called));

	immutable Ptr!StructDecl funPtrStruct = at(ctx.commonTypes.funPtrStructs, arity(funInst));
	immutable Type[] returnTypeAndParamTypes =
		mapWithFirst(alloc, returnType(funDecl), params(funInst), (ref immutable Param it) => it.type);

	immutable Ptr!StructInst structInst = instantiateStructNeverDelay(
		alloc,
		ctx.programState,
		immutable StructDeclAndArgs(funPtrStruct, returnTypeAndParamTypes));
	immutable Expr expr = immutable Expr(range, immutable Expr.FunPtr(funInst, structInst));
	return check(alloc, ctx, expected, immutable Type(structInst), expr);
}

immutable(CheckedExpr) checkLambdaSingleLine(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LambdaSingleLineAst ast,
	ref Expected expected,
) {
	immutable Opt!Pos itPos = findIt(ast.body_);
	return has(itPos)
		? checkLambdaCommon(alloc, ctx, range, [immutable LambdaAst.Param(force(itPos), itSym)], ast.body_, expected)
		: checkLambdaCommon(alloc, ctx, range, [], ast.body_, expected);
}

immutable Sym itSym = shortSymAlphaLiteral("it");

immutable(Opt!Pos) findIt(ref immutable ExprAst a) {
	// Since this is only used checking for 'it' in a braced lambda, any multi-line ast is unreachable
	return matchExprAstKind!(immutable Opt!Pos)(
		a.kind,
		(ref immutable(BogusAst)) =>
			none!Pos,
		(ref immutable CallAst e) =>
			findSome(toArr(e.args), (ref immutable ExprAst arg) => findIt(arg)),
		(ref immutable CreateArrAst e) =>
			findSome(toArr(e.args), (ref immutable ExprAst arg) => findIt(arg)),
		(ref immutable(FunPtrAst)) =>
			none!Pos,
		(ref immutable IdentifierAst id) =>
			symEq(id.name, itSym) ? some(a.range.start) : none!Pos,
		(ref immutable(IfAst)) =>
			unreachable!(immutable Opt!Pos),
		(ref immutable InterpolatedAst it) =>
			findSome(it.parts, (ref immutable InterpolatedPart part) =>
				matchInterpolatedPart!(immutable Opt!Pos)(
					part,
					(ref immutable string) => none!Pos,
					(ref immutable ExprAst e) => findIt(e))),
		(ref immutable(LambdaAst)) =>
			none!Pos,
		(ref immutable(LambdaSingleLineAst)) =>
			none!Pos,
		(ref immutable(LetAst)) =>
			unreachable!(immutable Opt!Pos),
		(ref immutable(LiteralAst)) =>
			none!Pos,
		(ref immutable(MatchAst)) =>
			unreachable!(immutable Opt!Pos),
		(ref immutable ParenthesizedAst it) =>
			findIt(it.inner),
		(ref immutable(SeqAst)) =>
			unreachable!(immutable Opt!Pos),
		(ref immutable(ThenAst)) =>
			unreachable!(immutable Opt!Pos),
		(ref immutable(ThenVoidAst)) =>
			unreachable!(immutable Opt!Pos));
}

immutable(CheckedExpr) checkLambda(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LambdaAst ast,
	ref Expected expected,
) {
	return checkLambdaCommon!Alloc(alloc, ctx, range, ast.params, ast.body_, expected);
}

immutable(CheckedExpr) checkLambdaCommon(Alloc)(
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
		addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaWrongNumberParams(et.funStructInst, size(paramAsts))));
		return bogus(expected, range);
	}

	immutable Param[] params = checkFunOrSendFunParamsForLambda(alloc, ctx, paramAsts, et.paramTypes);
	LambdaInfo info = LambdaInfo(kind, params);
	Expected returnTypeInferrer = copyWithNewExpectedType(expected, et.nonInstantiatedPossiblyFutReturnType);

	immutable Ptr!Expr body_ = withLambda(alloc, ctx, info, () =>
		// Note: checking the body of the lambda may fill in candidate type args
		// if the expected return type contains candidate's type params
		allocExpr(alloc, checkExpr(alloc, ctx, bodyAst, returnTypeInferrer)));
	immutable Ptr!ClosureField[] closureFields = moveToArr(alloc, info.closureFields);

	final switch (kind) {
		case FunKind.plain:
			foreach (immutable Ptr!ClosureField cf; closureFields)
				if (worstCasePurity(cf.type) == Purity.mut)
					addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaClosesOverMut(cf)));
			break;
		case FunKind.mut:
		case FunKind.ref_:
			break;
	}

	immutable Type actualPossiblyFutReturnType = inferred(returnTypeInferrer);
	immutable Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? matchType(
			actualPossiblyFutReturnType,
			(ref immutable Type.Bogus) =>
				some(immutable Type(immutable Type.Bogus())),
			(immutable Ptr!TypeParam) =>
				none!Type,
			(immutable Ptr!StructInst ap) =>
				ptrEquals(ap.decl, ctx.commonTypes.fut)
					? some!Type(only(ap.typeArgs))
					: none!Type)
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
		immutable Expr.Lambda lambda = Expr.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType);
		return CheckedExpr(immutable Expr(range, lambda));
	}
}

immutable(CheckedExpr) checkLet(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LetAst ast,
	ref Expected expected,
) {
	immutable ExprAndType init = checkAndInfer(alloc, ctx, ast.initializer);
	immutable Ptr!Local local = nu!Local(
		alloc,
		rangeInFile2(ctx, rangeOfNameAndRange(ast.name)),
		ast.name.name,
		init.type);
	immutable Ptr!Expr then = allocExpr(alloc, checkWithLocal(alloc, ctx, local, ast.then, expected));
	return CheckedExpr(immutable Expr(range, immutable Expr.Let(local, allocExpr(alloc, init.expr), then)));
}

immutable(Expr) checkWithOptLocal(Alloc)(
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

struct UnionAndMembers {
	immutable Ptr!StructInst matchedUnion;
	immutable Ptr!StructInst[] members;
}

immutable(Opt!UnionAndMembers) getUnionBody(ref immutable Type t) {
	if (isStructInst(t)) {
		immutable Ptr!StructInst matchedUnion = asStructInst(t);
		immutable StructBody body_ = body_(matchedUnion);
		return isUnion(body_)
			? some(immutable UnionAndMembers(matchedUnion, asUnion(body_).members))
			: none!UnionAndMembers;
	} else
		return none!UnionAndMembers;
}

immutable(CheckedExpr) checkMatch(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
) {
	immutable ExprAndType matchedAndType = checkAndInfer(alloc, ctx, ast.matched);
	immutable Opt!UnionAndMembers unionAndMembers = getUnionBody(matchedAndType.type);
	if (!has(unionAndMembers)) {
		if (!isBogus(matchedAndType.type))
			addDiag2(
				alloc,
				ctx,
				rangeInFile2(ctx, ast.matched.range),
				immutable Diag(immutable Diag.MatchOnNonUnion(matchedAndType.type)));
		return bogus(expected, rangeInFile2(ctx, ast.matched.range));
	} else {
		immutable Ptr!StructInst matchedUnion = force(unionAndMembers).matchedUnion;
		immutable Ptr!StructInst[] members = force(unionAndMembers).members;
		immutable bool badCases =
			!sizeEq(members, ast.cases) ||
			zipSome!(Ptr!StructInst, MatchAst.CaseAst)(
				members,
				ast.cases,
				(ref immutable Ptr!StructInst member, ref immutable MatchAst.CaseAst caseAst) =>
					!symEq(member.decl.name, caseAst.structName.name));
		if (badCases) {
			addDiag2(alloc, ctx, range, immutable Diag(Diag.MatchCaseStructNamesDoNotMatch(members)));
			return bogus(expected, range);
		} else {
			immutable Expr.Match.Case[] cases = mapZip!(Expr.Match.Case)(
				alloc,
				members,
				ast.cases,
				(ref immutable Ptr!StructInst member, ref immutable MatchAst.CaseAst caseAst) {
					immutable Opt!(Ptr!Local) local = has(caseAst.local)
						? some(nu!Local(
							alloc,
							rangeInFile2(ctx, rangeOfNameAndRange(force(caseAst.local))),
							force(caseAst.local).name,
							immutable Type(member)))
						: none!(Ptr!Local);
					immutable Expr then = isBogus(expected)
						? bogus(expected, range).expr
						: checkWithOptLocal(alloc, ctx, local, caseAst.then.deref, expected);
					return immutable Expr.Match.Case(local, allocExpr(alloc, then));
				});
			return CheckedExpr(immutable Expr(range, Expr.Match(
				allocExpr(alloc, matchedAndType.expr),
				matchedUnion,
				cases,
				inferred(expected))));
		}
	}
}

immutable(CheckedExpr) checkSeq(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable SeqAst ast,
	ref Expected expected,
) {
	immutable Ptr!Expr first = allocExpr(alloc, checkAndExpect(alloc, ctx, ast.first, ctx.commonTypes.void_));
	immutable Ptr!Expr then = allocExpr(alloc, checkExpr(alloc, ctx, ast.then, expected));
	return CheckedExpr(immutable Expr(range, Expr.Seq(first, then)));
}

immutable(CheckedExpr) checkThen(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ThenAst ast,
	ref Expected expected,
) {
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(immutable LambdaAst(
			//TODO: use temp alloc?
			arrLiteral!(LambdaAst.Param)(alloc, [ast.left]),
			ast.then)));
	// TODO: NEATER (don't create a synthetic AST)
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSymAlphaLiteral("then")),
		emptyArrWithSize!TypeAst,
		arrWithSizeLiteral!ExprAst(alloc, [ast.futExpr.deref, lambda]));
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CheckedExpr) checkThenVoid(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable ThenVoidAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(immutable LambdaAst(
			emptyArr!(LambdaAst.Param),
			ast.then)));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, shortSymAlphaLiteral("then-void")),
		emptyArrWithSize!TypeAst,
		arrWithSizeLiteral!ExprAst(alloc, [ast.futExpr.deref, lambda]));
	return checkCall(alloc, ctx, range, call, expected);
}

immutable(CheckedExpr) checkExprWorker(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	immutable FileAndRange range = rangeInFile2(ctx, ast.range);
	return matchExprAstKind!(immutable CheckedExpr)(
		ast.kind,
		(ref immutable BogusAst) =>
			unreachable!(immutable CheckedExpr),
		(ref immutable CallAst a) =>
			checkCall(alloc, ctx, range, a, expected),
		(ref immutable CreateArrAst a) =>
			checkCreateArr(alloc, ctx, range, a, expected),
		(ref immutable FunPtrAst a) =>
			checkFunPtr(alloc, ctx, range, a, expected),
		(ref immutable IdentifierAst a) =>
			checkIdentifier(alloc, ctx, range, a, expected),
		(ref immutable IfAst a) =>
			checkIf(alloc, ctx, range, a, expected),
		(ref immutable InterpolatedAst a) =>
			checkInterpolated(alloc, ctx, range, a, expected),
		(ref immutable LambdaAst a) =>
			checkLambda(alloc, ctx, range, a, expected),
		(ref immutable LambdaSingleLineAst a) =>
			checkLambdaSingleLine(alloc, ctx, range, a, expected),
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
			checkThenVoid(alloc, ctx, range, a, expected));
}
