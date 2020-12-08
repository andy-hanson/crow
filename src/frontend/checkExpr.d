module frontend.checkExpr;

@safe @nogc pure nothrow:

import frontend.ast :
	BogusAst,
	CallAst,
	CreateArrAst,
	ExprAst,
	ExprAstKind,
	IdentifierAst,
	IfAst,
	LambdaAst,
	LetAst,
	LiteralAst,
	MatchAst,
	matchExprAstKind,
	matchLiteralAst,
	NameAndRange,
	rangeOfNameAndRange,
	SeqAst,
	ThenAst,
	TypeAst;
import frontend.checkCall : checkCall, checkIdentifierCall;
import frontend.checkCtx : CheckCtx;
import frontend.inferringType :
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
	programState,
	rangeInFile2,
	shallowInstantiateType,
	tryGetDeeplyInstantiatedType,
	tryGetDeeplyInstantiatedTypeFor,
	tryGetInferred,
	typeFromAst2;
import frontend.instantiate : instantiateStructNeverDelay;
import frontend.typeFromAst : makeFutType;
import model.constant : Constant;
import model.diag : Diag;
import model.model :
	asStructInst,
	asUnion,
	body_,
	ClosureField,
	CommonTypes,
	decl,
	Expr,
	FunDecl,
	FunKind,
	FunsMap,
	getFunStructInfo,
	getType,
	IntegralTypes,
	isBogus,
	isStructInst,
	isUnion,
	Local,
	matchType,
	Param,
	params,
	Purity,
	range,
	returnType,
	StructBody,
	StructDecl,
	StructDeclAndArgs,
	StructInst,
	StructsAndAliasesMap,
	Type,
	typeArgs,
	TypeParam,
	worstCasePurity;
import util.bools : Bool, False, not, True;
import util.collection.arr : Arr, empty, emptyArrWithSize, first, only, ptrsRange, arrRange = range, size, sizeEq;
import util.collection.arrUtil :
	arrLiteral,
	exists,
	map,
	mapOrNone,
	mapZip,
	mapZipWithIndex,
	prepend,
	slice,
	tail,
	zipSome;
import util.collection.mutArr :
	moveToArr,
	mustPeek_mut,
	mustPop,
	MutArr,
	mutArrAt,
	mutArrIsEmpty,
	mutArrRange,
	mutArrSize,
	push,
	tempAsArr,
	tempAsArr_mut;
import util.collection.str : copyStr, Str;
import util.memory : nu;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : Ptr, ptrEquals, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.types : i8, i16, i32, i64, u8, u16, u32, u64;
import util.util : todo, unreachable, verify;

immutable(Ptr!Expr) checkFunctionBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx checkCtx,
	ref immutable ExprAst ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable FunsMap funsMap,
	immutable Ptr!FunDecl fun,
	ref immutable CommonTypes commonTypes,
) {
	ExprCtx exprCtx = ExprCtx(
		ptrTrustMe_mut(checkCtx),
		ptrTrustMe(structsAndAliasesMap),
		ptrTrustMe(funsMap),
		ptrTrustMe(commonTypes),
		fun);
	return allocExpr(alloc, checkAndExpect!Alloc(alloc, exprCtx, ast, returnType(fun)));
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
	immutable Ptr!Expr then = allocExpr(alloc, checkExpr(alloc, ctx, ast.then, expected));
	if (!has(ast.else_))
		todo!void("!");
	immutable Ptr!Expr else_ = allocExpr(alloc, checkExpr(alloc, ctx, force(ast.else_), expected));
	return immutable CheckedExpr(immutable Expr(range, immutable Expr.Cond(inferred(expected), cond, then, else_)));
}

struct ArrExpectedType {
	immutable Bool isFromExpected;
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
		if (has(ast.elementType)) {
			immutable Type ta = typeFromAst2(alloc, ctx, force(ast.elementType));
			immutable Ptr!StructInst arrType = instantiateStructNeverDelay!Alloc(
				alloc,
				programState(ctx),
				immutable StructDeclAndArgs(ctx.commonTypes.arr, arrLiteral!Type(alloc, [ta])));
			return some(immutable ArrExpectedType(False, arrType, ta));
		} else {
			immutable Opt!Type opT = tryGetDeeplyInstantiatedType(alloc, programState(ctx), expected);
			if (has(opT)) {
				immutable Type t = force(opT);
				if (isStructInst(t)) {
					immutable Ptr!StructInst si = asStructInst(t);
					if (ptrEquals(decl(si), ctx.commonTypes.arr))
						return some(immutable ArrExpectedType(True, si, only(typeArgs(si))));
				}
			}
			addDiag2(alloc, ctx, range, Diag(Diag.CreateArrNoExpectedType()));
			return none!ArrExpectedType;
		}
	}();

	if (has(opAet)) {
		immutable ArrExpectedType aet = force(opAet);
		immutable Arr!Expr args = map!Expr(alloc, ast.args, (ref immutable ExprAst it) =>
			checkAndExpect(alloc, ctx, it, aet.elementType));
		immutable Expr expr = immutable Expr(range, Expr.CreateArr(aet.arrType, args));
		return aet.isFromExpected
			? CheckedExpr(expr)
			: check!Alloc(alloc, ctx, expected, immutable Type(aet.arrType), expr);
	} else
		return bogusWithoutChangingExpected(expected, range);
}

struct ExpectedLambdaType {
	immutable Ptr!StructInst funStructInst;
	immutable Ptr!StructDecl funStruct;
	immutable FunKind kind;
	immutable Arr!Type paramTypes;
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
	immutable Ptr!StructDecl funStruct = expectedStructInst.decl;
	immutable Opt!FunKind opKind = getFunStructInfo(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		immutable FunKind kind = force(opKind);
		immutable Type nonInstantiatedNonFutReturnType = first(expectedStructInst.typeArgs);
		immutable Arr!Type nonInstantiatedParamTypes = tail(expectedStructInst.typeArgs);
		immutable Opt!(Arr!Type) paramTypes = mapOrNone!Type(
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

immutable(Opt!Expr) getIdentifierInLambda(
	ref immutable FileAndRange range,
	immutable Sym name,
	const Ptr!LambdaInfo lambda,
) {
	foreach (immutable Ptr!Local local; mutArrRange(lambda.locals))
		if (symEq(local.name, name))
			return some(immutable Expr(range, immutable Expr.LocalRef(local)));
	foreach (immutable Ptr!Param param; ptrsRange(lambda.lambdaParams))
		if (symEq(param.name, name))
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
	Arr!(Ptr!LambdaInfo) outerLambdas;
}

Opt!IdentifierAndLambdas getIdentifierNonCall(
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	immutable Sym name,
) {
	// Innermost lambda first
	foreach_reverse (immutable size_t i; 0..mutArrSize(ctx.lambdas)) {
		const Ptr!LambdaInfo lambda = mutArrAt(ctx.lambdas, i);
		immutable Opt!Expr id = getIdentifierInLambda(range, name, lambda);
		if (has(id))
			return someMut(IdentifierAndLambdas(force(id), slice(tempAsArr_mut(ctx.lambdas), i + 1)));
	}

	Arr!(Ptr!LambdaInfo) allLambdas = tempAsArr_mut(ctx.lambdas);
	foreach (immutable Ptr!Local local; mutArrRange(ctx.messageOrFunctionLocals))
		if (symEq(local.name, name))
			return someMut(IdentifierAndLambdas(immutable Expr(range, Expr.LocalRef(local)), allLambdas));
	foreach (immutable Ptr!Param param; ptrsRange(params(ctx.outermostFun)))
		if (symEq(param.name, name))
			return someMut(IdentifierAndLambdas(immutable Expr(range, Expr.ParamRef(param)), allLambdas));
	return noneMut!IdentifierAndLambdas;
}

immutable(Bool) nameIsParameterOrLocalInScope(ref ExprCtx ctx, immutable Sym name) {
	return has(getIdentifierNonCall(ctx, FileAndRange.empty, name));
}

immutable(CheckedExpr) checkRef(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable Expr expr,
	immutable Sym name,
	Arr!(Ptr!LambdaInfo) passedLambdas,
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
	return matchLiteralAst!(immutable CheckedExpr)(
		ast,
		(immutable double it) {
			immutable Expr e = immutable Expr(
				range,
				nu!(Expr.Literal)(alloc, ctx.commonTypes.float64, immutable Constant(it)));
			return check(alloc, ctx, expected, immutable Type(ctx.commonTypes.float64), e);
		},
		(ref immutable LiteralAst.Int it) {
			immutable(Opt!IntRange) intRange = ptrEquals(expectedStruct, integrals.int8)
				? some(immutable IntRange(i8.min, i8.max))
				: ptrEquals(expectedStruct, integrals.int16)
				? some(immutable IntRange(i16.min, i16.max))
				: ptrEquals(expectedStruct, integrals.int32)
				? some(immutable IntRange(i32.min, i32.max))
				: ptrEquals(expectedStruct, integrals.int64)
				? some(immutable IntRange(i64.min, i64.max))
				: none!IntRange;
			immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
			if (has(intRange)) {
				if (it.overflow || it.value < force(intRange).min || it.value > force(intRange).max)
					todo!void("literal overflow");
				return immutable CheckedExpr(immutable Expr(range, nu!(Expr.Literal)(alloc, expectedStruct, constant)));
			} else {
				immutable Expr e = immutable Expr(range, nu!(Expr.Literal)(alloc, integrals.int64, constant));
				return check(alloc, ctx, expected, immutable Type(integrals.int64), e);
			}
		},
		(ref immutable LiteralAst.Nat it) {
			immutable(Opt!ulong) max = ptrEquals(expectedStruct, integrals.nat8)
				? some!ulong(u8.max)
				: ptrEquals(expectedStruct, integrals.nat16)
				? some!ulong(u16.max)
				: ptrEquals(expectedStruct, integrals.nat32)
				? some!ulong(u32.max)
				: ptrEquals(expectedStruct, integrals.nat64)
				? some(u64.max)
				: ptrEquals(expectedStruct, integrals.int8)
				? some!ulong(i8.max)
				: ptrEquals(expectedStruct, integrals.int16)
				? some!ulong(i16.max)
				: ptrEquals(expectedStruct, integrals.int32)
				? some!ulong(i32.max)
				: ptrEquals(expectedStruct, integrals.int64)
				? some!ulong(i64.max)
				: none!ulong;
			immutable Constant constant = immutable Constant(immutable Constant.Integral(it.value));
			if (has(max)) {
				if (it.overflow || it.value > force(max))
					todo!void("literal overflow");
				return immutable CheckedExpr(immutable Expr(range, nu!(Expr.Literal)(alloc, expectedStruct, constant)));
			} else {
				immutable Expr e = immutable Expr(range, nu!(Expr.Literal)(alloc, integrals.nat64, constant));
				return check(alloc, ctx, expected, immutable Type(integrals.nat64), e);
			}
		},
		(ref immutable Str it) {
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
		Ptr!(MutArr!(immutable Ptr!Local)) locals = mutArrIsEmpty(ctx.lambdas)
			? ptrTrustMe_mut(ctx.messageOrFunctionLocals)
			: ptrTrustMe_mut(mustPeek_mut(ctx.lambdas).locals);
		push(alloc, locals.deref, local);
		immutable Expr res = checkExpr(alloc, ctx, ast, expected);
		immutable Ptr!Local popped = mustPop(locals);
		verify(ptrEquals(popped, local));
		return res;
	}
}

immutable(Arr!Param) checkFunOrSendFunParamsForLambda(Alloc)(
	ref Alloc alloc,
	ref const ExprCtx ctx,
	immutable Arr!(LambdaAst.Param) paramAsts,
	immutable Arr!Type expectedParamTypes,
) {
	return mapZipWithIndex!(Param, LambdaAst.Param, Type, Alloc)(
		alloc,
		paramAsts,
		expectedParamTypes,
		(ref immutable LambdaAst.Param ast, ref immutable Type expectedParamType, immutable size_t index) =>
			immutable Param(rangeInFile2(ctx, rangeOfNameAndRange(ast)), ast.name, expectedParamType, index));
}

immutable(CheckedExpr) checkLambda(Alloc)(
	ref Alloc alloc,
	ref ExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable LambdaAst ast,
	ref Expected expected,
) {
	immutable Opt!ExpectedLambdaType opEt = getExpectedLambdaType(alloc, ctx, range, expected);
	if (!has(opEt))
		return bogus(expected, range);

	immutable ExpectedLambdaType et = force(opEt);
	immutable FunKind kind = et.kind;

	if (!sizeEq(ast.params, et.paramTypes)) {
		addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaWrongNumberParams(et.funStructInst, size(ast.params))));
		return bogus(expected, range);
	}

	immutable Arr!Param params = checkFunOrSendFunParamsForLambda(alloc, ctx, ast.params, et.paramTypes);
	LambdaInfo info = LambdaInfo(kind, params);
	Expected returnTypeInferrer = copyWithNewExpectedType(expected, et.nonInstantiatedPossiblyFutReturnType);

	immutable Ptr!Expr body_ = withLambda(alloc, ctx, info, () =>
		// Note: checking the body of the lambda may fill in candidate type args
		// if the expected return type contains candidate's type params
		allocExpr(alloc, checkExpr(alloc, ctx, ast.body_, returnTypeInferrer)));
	immutable Arr!(Ptr!ClosureField) closureFields = moveToArr(alloc, info.closureFields);

	final switch (kind) {
		case FunKind.ptr:
			foreach (immutable Ptr!ClosureField cf; arrRange(closureFields))
				addDiag2(alloc, ctx, range, immutable Diag(Diag.LambdaForFunPtrHasClosure(cf)));
			break;
		case FunKind.plain:
			foreach (immutable Ptr!ClosureField cf; arrRange(closureFields))
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
	return CheckedExpr(immutable Expr(range, Expr.Let(local, allocExpr(alloc, init.expr), then)));
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
	immutable Arr!(Ptr!StructInst) members;
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
		immutable Arr!(Ptr!StructInst) members = force(unionAndMembers).members;
		immutable Bool badCases = Bool(
			!sizeEq(members, ast.cases) ||
			zipSome(members, ast.cases, (ref immutable Ptr!StructInst member, ref immutable MatchAst.CaseAst caseAst) =>
				not(symEq(member.decl.name, caseAst.structName.name))));
		if (badCases) {
			addDiag2(alloc, ctx, range, immutable Diag(Diag.MatchCaseStructNamesDoNotMatch(members)));
			return bogus(expected, range);
		} else {
			immutable Arr!(Expr.Match.Case) cases = mapZip!(Expr.Match.Case)(
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
		arrLiteral!ExprAst(alloc, [ast.futExpr.deref, lambda]));
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
		(ref immutable IdentifierAst a) =>
			checkIdentifier(alloc, ctx, range, a, expected),
		(ref immutable IfAst a) =>
			checkIf(alloc, ctx, range, a, expected),
		(ref immutable LambdaAst a) =>
			checkLambda(alloc, ctx, range, a, expected),
		(ref immutable LetAst a) =>
			checkLet(alloc, ctx, range, a, expected),
		(ref immutable LiteralAst a) =>
			checkLiteral(alloc, ctx, range, a, expected),
		(ref immutable MatchAst a) =>
			checkMatch(alloc, ctx, range, a, expected),
		(ref immutable SeqAst a) =>
			checkSeq(alloc, ctx, range, a, expected),
		(ref immutable ThenAst a) =>
			checkThen(alloc, ctx, range, a, expected));
}
