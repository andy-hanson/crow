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
	Expected,
	ExprCtx,
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
	withCopyWithNewExpectedType;
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
	VariableRef,
	worstCasePurity;
import util.alloc.alloc : Alloc, allocateUninitialized;
import util.col.arr : empty, emptySmallArray, only, PtrAndSmallNumber, ptrsRange, sizeEq;
import util.col.arrUtil : arrLiteral, arrsCorrespond, contains, exists, map, mapZip, mapZipWithIndex, zipPtrFirst;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr, mutArrSize, push, tempAsArr;
import util.col.mutMaxArr : fillMutMaxArr, initializeMutMaxArr, mutMaxArrSize, push, pushLeft, tempAsArr;
import util.col.str : copyToSafeCStr;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, allocateMut, initMemory, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some;
import util.ptr : castImmutable, castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : Sym, sym, symOfStr;
import util.union_ : Union;
import util.util : max, todo, verify;

immutable(Expr) checkFunctionBody(
	ref CheckCtx checkCtx,
	scope ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref immutable CommonTypes commonTypes,
	ref immutable FunsDict funsDict,
	scope FullIndexDict!(ModuleLocalFunIndex, bool) usedFuns,
	immutable Type returnType,
	immutable TypeParam[] typeParams,
	immutable Param[] params,
	immutable SpecInst*[] specs,
	immutable FunFlags flags,
	scope ref immutable ExprAst ast,
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
	immutable Expr res = checkAndExpect(castNonScope_ref(exprCtx), locals, ast, returnType);
	checkUnusedParams(checkCtx, params, tempAsArr(funInfo.paramsUsed));
	return res;
}

private:

void checkUnusedParams(ref CheckCtx checkCtx, immutable Param[] params, scope const bool[] paramsUsed) =>
	zipPtrFirst!(immutable Param, const bool)(
		params,
		paramsUsed,
		(immutable Param* param, ref const bool used) {
			if (!used && has(param.name))
				addDiag(checkCtx, param.range, immutable Diag(immutable Diag.UnusedParam(param)));
		});

struct ExprAndType {
	immutable Expr expr;
	immutable Type type;
}

immutable(ExprAndType) checkAndInfer(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
) {
	Expected expected = Expected(immutable Expected.Infer());
	immutable Expr expr = checkExpr(ctx, locals, ast, expected);
	return immutable ExprAndType(expr, inferred(expected));
}

immutable(ExprAndType) checkAndExpectOrInfer(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Opt!Type optExpected,
) {
	if (has(optExpected)) {
		immutable Expr res = checkAndExpect(ctx, locals, ast, force(optExpected));
		return immutable ExprAndType(res, force(optExpected));
	} else
		return checkAndInfer(ctx, locals, ast);
}

immutable(Expr) checkAndExpect(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Type expected,
) {
	Expected et = Expected(expected);
	return checkExpr(ctx, locals, ast, et);
}

immutable(Expr) checkAndExpectBool(ref ExprCtx ctx, ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, immutable Type(ctx.commonTypes.bool_));

immutable(Expr) checkAndExpectCStr(ref ExprCtx ctx, ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, immutable Type(ctx.commonTypes.cString));

immutable(Expr) checkAndExpectVoid(ref ExprCtx ctx, ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, voidType(ctx));

immutable(Type) voidType(ref const ExprCtx ctx) =>
	immutable Type(ctx.commonTypes.void_);

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
		immutable NameAndRange(range.range.start, sym!"*"),
		[],
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
	immutable Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
	immutable Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
	return immutable Expr(
		range,
		immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Cond(inferred(expected), cond, then, else_))));
}

immutable(Expr) checkThrow(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable ThrowAst ast,
	ref Expected expected,
) {
	immutable Opt!Type inferred = tryGetInferred(expected);
	if (has(inferred)) {
		immutable Expr thrown = checkAndExpectCStr(ctx, locals, ast.thrown);
		return immutable Expr(range, immutable ExprKind(
			allocate(ctx.alloc, immutable ExprKind.Throw(force(inferred), thrown))));
	} else {
		addDiag2(ctx, range, immutable Diag(immutable Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.throw_)));
		return bogus(expected, range);
	}
}

immutable(Expr) checkAssertOrForbid(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable AssertOrForbidAst ast,
	ref Expected expected,
) {
	immutable Expr* condition = allocate(ctx.alloc, checkAndExpectBool(ctx, locals, ast.condition));
	immutable Opt!(Expr*) thrown = has(ast.thrown)
		? some(allocate(ctx.alloc, checkAndExpectCStr(ctx, locals, force(ast.thrown))))
		: none!(Expr*);
	return check(ctx, expected, voidType(ctx), immutable Expr(
		range,
		immutable ExprKind(immutable ExprKind.AssertOrForbid(ast.kind, condition, thrown))));
}

immutable(Expr) checkUnless(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable UnlessAst ast,
	ref Expected expected,
) {
	immutable Expr cond = checkAndExpectBool(ctx, locals, ast.cond);
	immutable Expr else_ = checkExpr(ctx, locals, ast.body_, expected);
	immutable Expr then = checkEmptyNew(ctx, range, expected);
	return immutable Expr(
		range,
		immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Cond(inferred(expected), cond, then, else_))));
}

immutable(Expr) checkExprOrEmptyNewAndExpect(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable Opt!ExprAst ast,
	immutable Type expected,
) {
	Expected e = Expected(expected);
	return checkExprOrEmptyNew(ctx, locals, range, ast, e);
}

immutable(Expr) checkExprOrEmptyNew(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable Opt!ExprAst ast,
	ref Expected expected,
) =>
	has(ast)
		? checkExpr(ctx, locals, force(ast), expected)
		: checkEmptyNew(ctx, range, expected);

immutable(Expr) checkEmptyNew(ref ExprCtx ctx, immutable FileAndRange range, ref Expected expected) =>
	checkCallNoLocals(ctx, range, callNewCall(range.range), expected);

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

	immutable StructInst* inst = optionType.isA!(StructInst*)
		? optionType.as!(StructInst*)
		// Arbitrary type that's not opt
		: ctx.commonTypes.void_;
	if (decl(*inst) != ctx.commonTypes.opt) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.IfNeedsOpt(optionType)));
		return bogus(expected, range);
	} else {
		immutable Type innerType = only(typeArgs(*inst));
		immutable Local* local = allocate(ctx.alloc, immutable Local(
			rangeInFile2(ctx, rangeOfNameAndRange(ast.name, ctx.allSymbols)),
			ast.name.name,
			LocalMutability.immut,
			innerType));
		immutable Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		immutable Expr else_ = checkExprOrEmptyNew(ctx, locals, range, ast.else_, expected);
		return immutable Expr(range, immutable ExprKind(
			allocate(ctx.alloc, immutable ExprKind.IfOption(inferred(expected), option, local, then, else_))));
	}
}

immutable(Expr) checkInterpolated(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable InterpolatedAst ast,
	ref Expected expected,
) {
	defaultExpectedToString(ctx, range, expected);
	// TODO: NEATER (don't create a synthetic AST)
	// "a{b}c" ==> "a" ~~ b.to-str ~~ "c"
	immutable CallAst call = checkInterpolatedRecur(ctx, ast.parts, range.start + 1, none!ExprAst);
	immutable Opt!Type inferred = tryGetInferred(expected);
	immutable CallAst callAndConvert = has(inferred) && isCStr(ctx.commonTypes, force(inferred))
		? immutable CallAst(
			//TODO: new kind (not infix)
			CallAst.Style.infix,
			immutable NameAndRange(range.start, sym!"to-c-string"),
			[],
			arrLiteral!ExprAst(ctx.alloc, [
				immutable ExprAst(range.range, immutable ExprAstKind(call))]))
		: call;
	return checkCall(ctx, locals, range, callAndConvert, expected);
}

immutable(bool) isCStr(scope ref immutable CommonTypes commonTypes, immutable Type a) {
	if (a.isA!(StructInst*)) {
		immutable StructInst* inst = a.as!(StructInst*);
		return decl(*inst) == commonTypes.ptrConst && only(typeArgs(*inst)) == immutable Type(commonTypes.char8);
	} else
		return false;
}

immutable(CallAst) checkInterpolatedRecur(
	ref ExprCtx ctx,
	immutable InterpolatedPart[] parts,
	immutable Pos pos,
	immutable Opt!ExprAst left,
) {
	immutable ExprAst right = parts[0].match!(immutable ExprAst)(
		(immutable string it) =>
			immutable ExprAst(
				// TODO: this length may be wrong in the presence of escapes
				immutable RangeWithinFile(pos, safeToUint(pos + it.length)),
				immutable ExprAstKind(immutable LiteralStringAst(it))),
		(immutable ExprAst e) =>
			immutable ExprAst(
				e.range,
				immutable ExprAstKind(immutable CallAst(
					//TODO: new kind (not infix)
					CallAst.Style.infix,
					immutable NameAndRange(pos, sym!"to-string"),
					[],
					arrLiteral!ExprAst(ctx.alloc, [e])))));
	immutable Pos newPos = parts[0].match!(immutable Pos)(
		(immutable string it) => safeToUint(pos + it.length),
		(immutable ExprAst e) => e.range.end + 1);
	immutable ExprAst newLeft = has(left)
		? immutable ExprAst(
			immutable RangeWithinFile(pos, newPos),
			immutable ExprAstKind(immutable CallAst(
				//TODO: new kind (not infix)
				CallAst.Style.infix,
				immutable NameAndRange(pos, sym!"~~"),
				[],
				arrLiteral!ExprAst(ctx.alloc, [force(left), right]))))
		: right;
	immutable InterpolatedPart[] rest = parts[1 .. $];
	return empty(rest)
		? newLeft.kind.as!CallAst
		: checkInterpolatedRecur(ctx, rest, newPos, some(newLeft));
}

struct ExpectedLambdaType {
	immutable StructInst* funStructInst;
	immutable StructDecl* funStruct;
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
	if (!has(expectedType) || !force(expectedType).isA!(StructInst*)) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	immutable StructInst* expectedStructInst = force(expectedType).as!(StructInst*);
	immutable StructDecl* funStruct = decl(*expectedStructInst);
	immutable Opt!FunKind opKind = getFunKindFromStruct(ctx.commonTypes, funStruct);
	if (!has(opKind)) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	} else {
		immutable FunKind kind = force(opKind);
		immutable Type nonInstantiatedNonFutReturnType = typeArgs(*expectedStructInst)[0];
		immutable Type[] nonInstantiatedParamTypes = typeArgs(*expectedStructInst)[1 .. $];

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

struct VariableRefAndType {
	@safe @nogc pure nothrow:

	immutable VariableRef variableRef;
	immutable Mutability mutability;
	bool[4]* isUsed; // null for Param
	immutable Type type;

	@trusted void setIsUsed(immutable LocalAccessKind kind) {
		if (isUsed != null) {
			(*isUsed)[kind] = true;
		}
	}
}

Opt!VariableRefAndType getIdentifierNonCall(
	ref Alloc alloc,
	ref LocalsInfo locals,
	immutable Sym name,
	immutable LocalAccessKind accessKind,
) {
	Opt!(LocalNode*) fromLocals = has(locals.locals)
		? getIdentifierInLocals(force(locals.locals), name, accessKind)
		: noneMut!(LocalNode*);
	if (has(fromLocals)) {
		LocalNode* node = force(fromLocals);
		node.isUsed[accessKind] = true;
		return some(VariableRefAndType(
			immutable VariableRef(node.local),
			toMutability(node.local.mutability),
			&node.isUsed,
			node.local.type));
	} else
		return getIdentifierFromFunOrLambda(alloc, name, *locals.funOrLambda, accessKind);
}

Opt!(LocalNode*) getIdentifierInLocals(
	LocalNode* node,
	immutable Sym name,
	immutable LocalAccessKind accessKind,
) {
	return node.local.name == name
		? some(node)
		: has(node.prev)
		? getIdentifierInLocals(force(node.prev), name, accessKind)
		: noneMut!(LocalNode*);
}

Opt!VariableRefAndType getIdentifierFromFunOrLambda(
	ref Alloc alloc,
	immutable Sym name,
	ref FunOrLambdaInfo info,
	immutable LocalAccessKind accessKind,
) {
	foreach (immutable Param* param; ptrsRange(info.params))
		if (has(param.name) && force(param.name) == name) {
			info.paramsUsed[param.index] = true;
			return some(VariableRefAndType(immutable VariableRef(param), Mutability.immut, null, param.type));
		}
	foreach (immutable size_t index, ref ClosureFieldBuilder field; tempAsArr(info.closureFields))
		if (field.name == name) {
			field.setIsUsed(accessKindInClosure(accessKind));
			return some(VariableRefAndType(
				immutable VariableRef(immutable ClosureRef(
					immutable PtrAndSmallNumber!(ExprKind.Lambda)(force(info.lambda), safeToUshort(index)))),
				field.mutability,
				field.isUsed,
				field.type));
		}

	Opt!VariableRefAndType optOuter = has(info.outer)
		? getIdentifierNonCall(alloc, *force(info.outer), name, accessKindInClosure(accessKind))
		: noneMut!VariableRefAndType;
	if (has(optOuter)) {
		VariableRefAndType outer = force(optOuter);
		immutable size_t closureFieldIndex = mutMaxArrSize(info.closureFields);
		push(
			info.closureFields,
			ClosureFieldBuilder(name, outer.mutability, outer.isUsed, outer.type, outer.variableRef));
		outer.setIsUsed(accessKindInClosure(accessKind));
		return some(VariableRefAndType(
			immutable VariableRef(immutable ClosureRef(
				immutable PtrAndSmallNumber!(ExprKind.Lambda)(force(info.lambda), safeToUshort(closureFieldIndex)))),
			outer.mutability,
			outer.isUsed,
			outer.type));
	} else
		return noneMut!VariableRefAndType;
}
immutable(LocalAccessKind) accessKindInClosure(immutable LocalAccessKind a) {
	final switch (a) {
		case LocalAccessKind.getOnStack:
		case LocalAccessKind.getThroughClosure:
			return LocalAccessKind.getThroughClosure;
		case LocalAccessKind.setOnStack:
		case LocalAccessKind.setThroughClosure:
			return LocalAccessKind.setThroughClosure;
	}
}

immutable(bool) nameIsParameterOrLocalInScope(ref Alloc alloc, ref LocalsInfo locals, immutable Sym name) {
	Opt!VariableRefAndType var = getIdentifierNonCall(alloc, locals, name, LocalAccessKind.getOnStack);
	return has(var);
}

immutable(Expr) checkIdentifier(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable IdentifierAst ast,
	ref Expected expected,
) {
	Opt!VariableRefAndType res = getIdentifierNonCall(ctx.alloc, locals, ast.name, LocalAccessKind.getOnStack);
	return has(res)
		? check(ctx, expected, force(res).type, toExpr(ctx.alloc, range, force(res).variableRef))
		: checkIdentifierCall(ctx, locals, range, ast.name, expected);
}

immutable(Expr) checkIdentifierSet(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable IdentifierSetAst ast,
	ref Expected expected,
) {
	Opt!VariableRefAndType optVar = getVariableRefForSet(ctx, locals, range, ast.name);
	if (has(optVar)) {
		VariableRefAndType var = force(optVar);
		immutable Expr value = checkAndExpect(ctx, locals, ast.value, var.type);
		return var.variableRef.matchWithPointers!(immutable Expr)(
			(immutable Local* local) =>
				check(ctx, expected, voidType(ctx), immutable Expr(
					range,
					immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.LocalSet(local, value))))),
			(immutable Param*) {
				addDiag2(ctx, range, immutable Diag(immutable Diag.ParamNotMutable()));
				return bogus(expected, range);
			},
			(immutable ClosureRef cr) =>
				check(ctx, expected, voidType(ctx), immutable Expr(
					range,
					immutable ExprKind(immutable ExprKind.ClosureSet(
						allocate(ctx.alloc, cr),
						allocate(ctx.alloc, value))))));
	} else
		return bogus(expected, range);
}

Opt!VariableRefAndType getVariableRefForSet(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	immutable Sym name,
) {
	Opt!VariableRefAndType opVar = getIdentifierNonCall(ctx.alloc, locals, name, LocalAccessKind.setOnStack);
	if (has(opVar)) {
		VariableRefAndType var = force(opVar);
		final switch (var.mutability) {
			case Mutability.immut:
				addDiag2(ctx, range, immutable Diag(immutable Diag.LocalNotMutable(var.variableRef)));
				break;
			case Mutability.mut:
				break;
		}
		return some(var);
	} else
		return noneMut!VariableRefAndType;
}

immutable(Expr) toExpr(ref Alloc alloc, immutable FileAndRange range, immutable VariableRef a) =>
	a.matchWithPointers!(immutable Expr)(
		(immutable Local* x) =>
			immutable Expr(range, immutable ExprKind(immutable ExprKind.LocalGet(x))),
		(immutable Param* x) =>
			immutable Expr(range, immutable ExprKind(immutable ExprKind.ParamGet(x))),
		(immutable ClosureRef x) =>
			immutable Expr(range, immutable ExprKind(immutable ExprKind.ClosureGet(allocate(alloc, x)))));

struct IntRange {
	immutable long min;
	immutable long max;
}

immutable(StructInst*) expectedStructOrNull(ref const Expected expected) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	return has(expectedType) && force(expectedType).isA!(StructInst*)
		? force(expectedType).as!(StructInst*)
		: null;
}

immutable(Expr) checkLiteralFloat(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LiteralFloatAst ast,
	ref Expected expected,
) {
	if (ast.overflow)
		todo!void("literal overflow\n");
	return asFloat(ctx, range, ast.value, expected);
}

immutable(Expr) asFloat(ref ExprCtx ctx, immutable FileAndRange range, immutable double value, ref Expected expected) {
	immutable StructInst* type = expectedStructOrNull(expected) == ctx.commonTypes.float32
		? ctx.commonTypes.float32
		: ctx.commonTypes.float64;
	immutable Expr e = immutable Expr(range, immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(
		type,
		immutable Constant(immutable Constant.Float(value))))));
	return check(ctx, expected, immutable Type(type), e);
}

immutable(Expr) checkLiteralInt(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LiteralIntAst ast,
	ref Expected expected,
) {
	immutable StructInst* expectedStruct = expectedStructOrNull(expected);
	if (expectedStruct == ctx.commonTypes.float32 || expectedStruct == ctx.commonTypes.float64)
		return asFloat(ctx, range, cast(immutable double) ast.value, expected);
	else {
		immutable IntegralTypes integrals = ctx.commonTypes.integrals;
		immutable(Opt!IntRange) intRange = expectedStruct == integrals.int8
			? some(immutable IntRange(byte.min, byte.max))
			: expectedStruct == integrals.int16
			? some(immutable IntRange(short.min, short.max))
			: expectedStruct == integrals.int32
			? some(immutable IntRange(int.min, int.max))
			: expectedStruct == integrals.int64
			? some(immutable IntRange(long.min, long.max))
			: none!IntRange;
		immutable Constant constant = immutable Constant(immutable Constant.Integral(ast.value));
		if (has(intRange)) {
			if (ast.overflow || ast.value < force(intRange).min || ast.value > force(intRange).max)
				todo!void("literal overflow");
			return immutable Expr(
				range,
				immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(expectedStruct, constant))));
		} else {
			immutable Expr e = immutable Expr(
				range,
				immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(integrals.int64, constant))));
			return check(ctx, expected, immutable Type(integrals.int64), e);
		}
	}
}

immutable(Expr) checkLiteralNat(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	ref immutable LiteralNatAst ast,
	ref Expected expected,
) {
	immutable StructInst* expectedStruct = expectedStructOrNull(expected);
	if (expectedStruct == ctx.commonTypes.float32 || expectedStruct == ctx.commonTypes.float64)
		return asFloat(ctx, range, cast(immutable double) ast.value, expected);
	else {
		immutable IntegralTypes integrals = ctx.commonTypes.integrals;
		immutable(Opt!ulong) max = expectedStruct == integrals.nat8
			? some!ulong(ubyte.max)
			: expectedStruct == integrals.nat16
			? some!ulong(ushort.max)
			: expectedStruct == integrals.nat32
			? some!ulong(uint.max)
			: expectedStruct == integrals.nat64
			? some(ulong.max)
			: expectedStruct == integrals.int8
			? some!ulong(byte.max)
			: expectedStruct == integrals.int16
			? some!ulong(short.max)
			: expectedStruct == integrals.int32
			? some!ulong(int.max)
			: expectedStruct == integrals.int64
			? some!ulong(long.max)
			: none!ulong;
		immutable Constant constant = immutable Constant(immutable Constant.Integral(ast.value));
		if (has(max)) {
			if (ast.overflow || ast.value > force(max))
				addDiag2(ctx, range, immutable Diag(
					immutable Diag.LiteralOverflow(expectedStruct)));
			return immutable Expr(
				range,
				immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(expectedStruct, constant))));
		} else {
			if (ast.overflow)
				todo!void("literal overflow");
			immutable Expr e = immutable Expr(
				range,
				immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(integrals.nat64, constant))));
			return check(ctx, expected, immutable Type(integrals.nat64), e);
		}
	}
}

immutable(Expr) checkLiteralString(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable ExprAst curAst,
	scope immutable string value,
	ref Expected expected,
) {
	immutable StructInst* expectedStruct = expectedStructOrNull(expected);
	if (expectedStruct == ctx.commonTypes.char8) {
		immutable char char_ = () {
			if (value.length != 1) {
				addDiag2(ctx, range, immutable Diag(immutable Diag.CharLiteralMustBeOneChar()));
				return 'a';
			} else
				return only(value);
		}();
		return immutable Expr(
			range,
			immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Literal(
				ctx.commonTypes.char8,
				immutable Constant(immutable Constant.Integral(char_))))));
	} else if (expectedStruct == ctx.commonTypes.symbol)
		return immutable Expr(
			range,
			immutable ExprKind(immutable ExprKind.LiteralSymbol(symOfStr(ctx.allSymbols, value))));
	else if (expectedStruct == ctx.commonTypes.cString)
		return immutable Expr(
			range,
			immutable ExprKind(immutable ExprKind.LiteralCString(copyToSafeCStr(ctx.alloc, value))));
	else {
		defaultExpectedToString(ctx, range, expected);
		scope immutable ExprAst[1] args = [curAst];
		// TODO: NEATER (don't create a synthetic AST)
		scope immutable CallAst ast = immutable CallAst(
			CallAst.Style.emptyParens,
			immutable NameAndRange(range.start, sym!"literal"),
			[],
			castNonScope(args));
		return checkCallNoLocals(ctx, range, ast, expected);
	}
}

void defaultExpectedToString(ref ExprCtx ctx, immutable FileAndRange range, ref Expected expected) {
	immutable Opt!Type inferred = tryGetInferred(expected);
	if (!has(inferred))
		mustSetType(ctx.alloc, ctx.programState, expected, getStrType(ctx, range));
}

immutable(Type) getStrType(ref ExprCtx ctx, immutable FileAndRange range) =>
	typeFromAst2(ctx, immutable TypeAst(immutable TypeAst.InstStruct(
		range.range,
		immutable NameAndRange(range.start, sym!"string"),
		emptySmallArray!TypeAst)));

immutable(Expr) checkWithLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable Local* local,
	ref immutable ExprAst ast,
	ref Expected expected,
) {
	// Look for a parameter with the name
	if (nameIsParameterOrLocalInScope(ctx.alloc, locals, local.name)) {
		addDiag2(ctx, local.range, immutable Diag(
			immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.paramOrLocal, local.name)));
		return bogus(expected, rangeInFile2(ctx, ast.range));
	} else {
		LocalNode localNode = LocalNode(locals.locals, [false, false, false, false], local);
		LocalsInfo newLocals = LocalsInfo(locals.funOrLambda, some(ptrTrustMe(localNode)));
		immutable Expr res = checkExpr(ctx, newLocals, ast, expected);
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

void addUnusedLocalDiags(ref ExprCtx ctx, immutable Local* local, scope ref LocalNode node) {
	immutable bool isGot = node.isUsed[LocalAccessKind.getOnStack] || node.isUsed[LocalAccessKind.getThroughClosure];
	immutable bool isSet = node.isUsed[LocalAccessKind.setOnStack] || node.isUsed[LocalAccessKind.setThroughClosure];
	if (!isGot || (!isSet && local.mutability != LocalMutability.immut))
		addDiag2(ctx, local.range, immutable Diag(immutable Diag.UnusedLocal(local, isGot, isSet)));
}

immutable(Param[]) checkParamsForLambda(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope immutable LambdaAst.Param[] paramAsts,
	scope immutable Type[] expectedParamTypes,
) =>
	mapZipWithIndex!(Param, LambdaAst.Param, Type)(
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

immutable(Expr) checkPtr(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	scope ref immutable PtrAst ast,
	ref Expected expected,
) {
	if (ctx.outermostFunFlags.safety == FunFlags.Safety.safe)
		addDiag2(ctx, range, immutable Diag(immutable Diag.PtrIsUnsafe()));
	return getExpectedPointee(ctx, expected).match!(immutable Expr)(
		(immutable ExpectedPointee.None) {
			addDiag2(ctx, range, immutable Diag(immutable Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.pointer)));
			return bogus(expected, range);
		},
		(immutable ExpectedPointee.FunPointer) =>
			checkFunPointer(ctx, range, ast, expected),
		(immutable ExpectedPointee.Pointer x) =>
			checkPtrInner(ctx, locals, range, ast, x.pointer, x.pointee, x.mutability));
}

struct ExpectedPointee {
	struct None {}
	struct FunPointer {}
	struct Pointer { immutable Type pointer; immutable Type pointee; immutable PointerMutability mutability; }
	mixin Union!(immutable None, immutable FunPointer, immutable Pointer);
}
enum PointerMutability { immutable_, mutable }

immutable(ExpectedPointee) getExpectedPointee(ref ExprCtx ctx, ref const Expected expected) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType) && force(expectedType).isA!(StructInst*)) {
		immutable StructInst* inst = force(expectedType).as!(StructInst*);
		immutable StructDecl* decl = decl(*inst);
		if (decl == ctx.commonTypes.ptrConst)
			return immutable ExpectedPointee(immutable ExpectedPointee.Pointer(
				immutable Type(inst), only(typeArgs(*inst)), PointerMutability.immutable_));
		else if (decl == ctx.commonTypes.ptrMut)
			return immutable ExpectedPointee(immutable ExpectedPointee.Pointer(
				immutable Type(inst), only(typeArgs(*inst)), PointerMutability.mutable));
		else if (contains(ctx.commonTypes.funPtrStructs, decl))
			return immutable ExpectedPointee(immutable ExpectedPointee.FunPointer());
		else if (isDefinitelyByRef(*inst))
			return immutable ExpectedPointee(immutable ExpectedPointee.Pointer(
				immutable Type(inst),
				immutable Type(instantiateStructNeverDelay(
					ctx.alloc, ctx.programState, ctx.commonTypes.byVal, [immutable Type(inst)])),
				hasMutableField(*inst) ? PointerMutability.mutable : PointerMutability.immutable_));
		else
			return immutable ExpectedPointee(immutable ExpectedPointee.None());
	} else
		return immutable ExpectedPointee(immutable ExpectedPointee.None());
}

immutable(Expr) checkPtrInner(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	scope ref immutable PtrAst ast,
	immutable Type pointerType,
	immutable Type pointeeType,
	immutable PointerMutability pointerMutability,
) {
	immutable Expr inner = checkAndExpect(ctx, locals, ast.inner, pointeeType);
	if (inner.kind.isA!(ExprKind.LocalGet)) {
		immutable Local* local = inner.kind.as!(ExprKind.LocalGet).local;
		if (local.mutability < pointerMutability)
			addDiag2(ctx, range, immutable Diag(immutable Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.local)));
		if (pointerMutability == PointerMutability.mutable)
			markIsUsedSetOnStack(locals, local);
		return immutable Expr(range, immutable ExprKind(immutable ExprKind.PtrToLocal(pointerType, local)));
	} else if (inner.kind.isA!(ExprKind.ParamGet))
		return immutable Expr(range, immutable ExprKind(
			immutable ExprKind.PtrToParam(pointerType, inner.kind.as!(ExprKind.ParamGet).param)));
	else if (inner.kind.isA!(ExprKind.Call))
		return checkPtrOfCall(ctx, range, inner.kind.as!(ExprKind.Call), pointerType, pointerMutability);
	else {
		addDiag2(ctx, range, immutable Diag(immutable Diag.PtrUnsupported()));
		return immutable Expr(range, immutable ExprKind(immutable ExprKind.Bogus()));
	}
}

immutable(Expr) checkPtrOfCall(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	immutable ExprKind.Call call,
	immutable Type pointerType,
	immutable PointerMutability pointerMutability,
) {
	immutable(Expr) fail() {
		addDiag2(ctx, range, immutable Diag(immutable Diag.PtrUnsupported()));
		return immutable Expr(range, immutable ExprKind(immutable ExprKind.Bogus()));
	}

	if (call.called.isA!(FunInst*)) {
		immutable FunInst* getFieldFun = call.called.as!(FunInst*);
		if (decl(*getFieldFun).body_.isA!(FunBody.RecordFieldGet)) {
			immutable FunBody.RecordFieldGet rfg = decl(*getFieldFun).body_.as!(FunBody.RecordFieldGet);
			immutable Expr target = only(call.args);
			immutable StructInst* recordType = only(assertNonVariadic(getFieldFun.params)).type.as!(StructInst*);
			immutable RecordField field = body_(*recordType).as!(StructBody.Record).fields[rfg.fieldIndex];
			immutable PointerMutability fieldMutability = pointerMutabilityFromField(field.mutability);
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < pointerMutability)
					addDiag2(ctx, range, immutable Diag(immutable Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.field)));
				return immutable Expr(range, immutable ExprKind(allocate(ctx.alloc,
					immutable ExprKind.PtrToField(pointerType, target, rfg.fieldIndex))));
			} else if (target.kind.isA!(ExprKind.Call)) {
				immutable ExprKind.Call targetCall = target.kind.as!(ExprKind.Call);
				immutable Called called = targetCall.called;
				if (called.isA!(FunInst*) && isDerefFunction(ctx, called.as!(FunInst*))) {
					immutable FunInst* derefFun = called.as!(FunInst*);
					immutable StructInst* ptrStructInst =
						only(assertNonVariadic(derefFun.params)).type.as!(StructInst*);
					immutable Expr targetPtr = only(targetCall.args);
					if (max(fieldMutability, mutabilityForPtrDecl(ctx, decl(*ptrStructInst))) < pointerMutability)
						todo!void("diag: can't get mut* to immutable field");
					return immutable Expr(range, immutable ExprKind(allocate(ctx.alloc,
						immutable ExprKind.PtrToField(pointerType, targetPtr, rfg.fieldIndex))));
				} else
					return fail();
			} else
				return fail();
		} else
			return fail();
	} else
		return fail();
}

immutable(PointerMutability) pointerMutabilityFromField(immutable FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return PointerMutability.immutable_;
		case FieldMutability.private_:
		case FieldMutability.public_:
			return PointerMutability.mutable;
	}
}

immutable(bool) isDerefFunction(ref ExprCtx ctx, immutable FunInst* a) =>
	decl(*a).body_.isA!(FunBody.Builtin) && decl(*a).name == sym!"*" && arity(*a) == immutable Arity(1);

immutable(PointerMutability) mutabilityForPtrDecl(scope ref const ExprCtx ctx, scope immutable StructDecl* a) {
	if (a == ctx.commonTypes.ptrConst)
		return PointerMutability.immutable_;
	else {
		verify(a == ctx.commonTypes.ptrMut);
		return PointerMutability.mutable;
	}
}

immutable(Expr) checkFunPointer(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable PtrAst ast,
	ref Expected expected,
) {
	if (!ast.inner.kind.isA!IdentifierAst)
		todo!void("diag: fun-pointer ast should just be an identifier");
	immutable Sym name = ast.inner.kind.as!IdentifierAst.name;
	MutArr!(immutable FunDecl*) funsInScope = MutArr!(immutable FunDecl*)();
	eachFunInScope(ctx, name, (immutable UsedFun used, immutable CalledDecl cd) {
		cd.matchWithPointers!void(
			(immutable FunDecl* x) {
				markUsedFun(ctx, used);
				push(ctx.alloc, funsInScope, x);
			},
			(immutable SpecSig) {
				todo!void("!");
			});
	});
	if (mutArrSize(funsInScope) != 1)
		todo!void("did not find or found too many");
	immutable FunDecl* funDecl = funsInScope[0];

	if (isTemplate(*funDecl))
		todo!void("can't point to template");
	immutable size_t nParams = arity(*funDecl).match!(immutable size_t)(
		(immutable size_t n) =>
			n,
		(immutable Arity.Varargs) =>
			todo!(immutable size_t)("ptr to variadic function?"));
	if (nParams >= ctx.commonTypes.funPtrStructs.length)
		todo!void("arity too high");

	immutable FunInst* funInst = instantiateFun(ctx.alloc, ctx.programState, funDecl, [], []);
	immutable StructDecl* funPtrStruct = ctx.commonTypes.funPtrStructs[nParams];
	scope TypeArgsArray returnTypeAndParamTypes = typeArgsArray();
	push(returnTypeAndParamTypes, funDecl.returnType);
	foreach (ref immutable Param x; assertNonVariadic(funInst.params))
		push(returnTypeAndParamTypes, x.type);
	immutable StructInst* structInst =
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, funPtrStruct, tempAsArr(returnTypeAndParamTypes));
	immutable Expr expr = immutable Expr(range, immutable ExprKind(immutable ExprKind.FunPtr(funInst, structInst)));
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

	ExprKind.Lambda* lambda = () @trusted { return allocateUninitialized!(ExprKind.Lambda)(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo =
		FunOrLambdaInfo(some(ptrTrustMe(locals)), params, some(castImmutable(lambda)));
	fillMutMaxArr(lambdaInfo.paramsUsed, params.length, false);
	initializeMutMaxArr(lambdaInfo.closureFields);
	LocalsInfo lambdaLocalsInfo = LocalsInfo(ptrTrustMe(lambdaInfo), noneMut!(LocalNode*));

	// Checking the body of the lambda may fill in candidate type args
	// if the expected return type contains candidate's type params
	immutable Pair!(Expr, Type) bodyAndType = withCopyWithNewExpectedType!Expr(
		expected,
		et.nonInstantiatedPossiblyFutReturnType,
		(ref Expected returnTypeInferrer) =>
			checkExpr(ctx, lambdaLocalsInfo, ast.body_, returnTypeInferrer));
	immutable Expr body_ = bodyAndType.a;
	immutable Type actualPossiblyFutReturnType = bodyAndType.b;

	checkUnusedParams(ctx.checkCtx, params, tempAsArr(lambdaInfo.paramsUsed));

	final switch (kind) {
		case FunKind.plain:
			foreach (ref ClosureFieldBuilder cf; tempAsArr(lambdaInfo.closureFields)) {
				final switch (cf.mutability) {
					case Mutability.immut:
						break;
					case Mutability.mut:
						addDiag2(ctx, range, immutable Diag(immutable Diag.LambdaClosesOverMut(cf.name, none!Type)));
				}
				if (worstCasePurity(cf.type) == Purity.mut)
					addDiag2(ctx, range, immutable Diag(immutable Diag.LambdaClosesOverMut(cf.name, some(cf.type))));
			}
			break;
		case FunKind.mut:
		case FunKind.ref_:
			break;
		case FunKind.pointer:
			todo!void("ensure no closure");
			break;
	}
	immutable VariableRef[] closureFields =
		map(ctx.alloc, tempAsArr(lambdaInfo.closureFields), (ref ClosureFieldBuilder x) =>
			x.variableRef);

	immutable Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? actualPossiblyFutReturnType.match!(immutable Opt!Type)(
			(immutable Type.Bogus) =>
				some(immutable Type(immutable Type.Bogus())),
			(ref immutable(TypeParam)) =>
				none!Type,
			(ref immutable StructInst x) =>
				decl(x) == ctx.commonTypes.future
					? some!Type(only(typeArgs(x)))
					: none!Type)
		: some!Type(actualPossiblyFutReturnType);
	if (!has(actualNonFutReturnType)) {
		addDiag2(ctx, range, immutable Diag(
			immutable Diag.SendFunDoesNotReturnFut(actualPossiblyFutReturnType)));
		return bogus(expected, range);
	} else {
		pushLeft(paramTypes, force(actualNonFutReturnType));
		immutable StructInst* instFunStruct =
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, et.funStruct, tempAsArr(paramTypes));
		initMemory(lambda, immutable ExprKind.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType));
		//TODO: this check should never fail, so could just set inferred directly with no check
		return check(
			ctx,
			expected,
			immutable Type(instFunStruct),
			immutable Expr(range, immutable ExprKind(castImmutable(lambda))));
	}
}

immutable(Expr) checkLet(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LetAst ast,
	ref Expected expected,
) {
	immutable ExprAndType init = checkAndExpectOrInfer(ctx, locals, ast.initializer, typeFromOptAst(ctx, ast.type));
	if (has(ast.name)) {
		immutable Local* local = allocate(ctx.alloc, immutable Local(
			rangeInFile2(ctx, rangeOfOptNameAndRange(immutable OptNameAndRange(range.start, ast.name), ctx.allSymbols)),
			force(ast.name),
			ast.mut ? LocalMutability.mutOnStack : LocalMutability.immut,
			init.type));
		immutable Expr then = checkWithLocal(ctx, locals, local, ast.then, expected);
		return immutable Expr(range, immutable ExprKind(
			allocate(ctx.alloc, immutable ExprKind.Let(local, init.expr, then))));
	} else {
		if (ast.mut) todo!void("'mut' makes no sense for nameless local");
		immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
		return immutable Expr(range,
			immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Seq(
				immutable Expr(
					init.expr.range,
					immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Drop(init.expr)))),
				then))));
	}
}

immutable(Expr) checkWithOptLocal(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable Opt!(Local*) local,
	ref immutable ExprAst ast,
	ref Expected expected,
) =>
	has(local)
		? checkWithLocal(ctx, locals, force(local), ast, expected)
		: checkExpr(ctx, locals, ast, expected);

struct EnumAndMembers {
	immutable StructBody.Enum.Member[] members;
}

struct UnionAndMembers {
	immutable StructInst* structInst;
	immutable UnionMember[] members;
}

struct EnumOrUnionAndMembers {
	mixin Union!(immutable EnumAndMembers, immutable UnionAndMembers);
}

immutable(Opt!EnumOrUnionAndMembers) getEnumOrUnionBody(immutable Type a) =>
	a.matchWithPointers!(immutable Opt!EnumOrUnionAndMembers)(
		(immutable Type.Bogus) =>
			none!EnumOrUnionAndMembers,
		(immutable TypeParam*) =>
			none!EnumOrUnionAndMembers,
		(immutable StructInst* structInst) =>
			body_(*structInst).match!(immutable Opt!EnumOrUnionAndMembers)(
				(immutable StructBody.Bogus) =>
					none!EnumOrUnionAndMembers,
				(immutable StructBody.Builtin) =>
					none!EnumOrUnionAndMembers,
				(immutable StructBody.Enum it) =>
					some(immutable EnumOrUnionAndMembers(immutable EnumAndMembers(it.members))),
				(immutable StructBody.Extern) =>
					none!EnumOrUnionAndMembers,
				(immutable StructBody.Flags) =>
					none!EnumOrUnionAndMembers,
				(immutable StructBody.Record) =>
					none!EnumOrUnionAndMembers,
				(immutable StructBody.Union it) =>
					some(immutable EnumOrUnionAndMembers(immutable UnionAndMembers(structInst, it.members)))));

immutable(Expr) checkLoop(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopAst ast,
	ref Expected expected,
) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType)) {
		immutable Type type = force(expectedType);
		ExprKind.Loop* loop = allocateMut(ctx.alloc, ExprKind.Loop(
			type,
			immutable Expr(FileAndRange.empty, immutable ExprKind(immutable ExprKind.Bogus()))));
		LoopInfo info = LoopInfo(voidType(ctx), castImmutable(loop), type, false);
		scope Expected bodyExpected = Expected(&info);
		immutable Expr body_ = checkExpr(ctx, locals, ast.body_, castNonScope_ref(bodyExpected));
		overwriteMemory(&loop.body_, body_);
		if (!info.hasBreak)
			addDiag2(ctx, range, immutable Diag(immutable Diag.LoopWithoutBreak()));
		return immutable Expr(range, immutable ExprKind(castImmutable(loop)));
	} else {
		addDiag2(ctx, range, immutable Diag(immutable Diag.NeedsExpectedType(Diag.NeedsExpectedType.Kind.loop)));
		return bogus(expected, range);
	}
}

immutable(Expr) checkLoopBreak(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopBreakAst ast,
	ref Expected expected,
) {
	Opt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (!has(optLoop)) {
		// TODO: NEATER (don't create a synthetic AST)
		immutable ExprAst arg = has(ast.value) ? force(ast.value) : callNew(range.range);
		immutable ExprAst[1] args = [arg];
		scope immutable CallAst call = immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(range.range.start, sym!"loop-break"),
			[],
			args);
		return checkCall(ctx, locals, range, call, expected);
	} else {
		LoopInfo* loop = force(optLoop);
		loop.hasBreak = true;
		immutable Expr value = checkExprOrEmptyNewAndExpect(ctx, locals, range, ast.value, loop.type);
		return immutable Expr(
			range,
			immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.LoopBreak(loop.loop, value))));
	}
}

immutable(Expr) checkLoopContinue(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref Expected expected,
) {
	Opt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (has(optLoop))
		return immutable Expr(range, immutable ExprKind(immutable ExprKind.LoopContinue(force(optLoop).loop)));
	else {
		scope immutable CallAst call = immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(range.range.start, sym!"loop-continue"),
			[],
			[]);
		return checkCall(ctx, locals, range, call, expected);
	}
}

immutable(Expr) checkLoopUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopUntilAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, voidType(ctx), immutable Expr(
		range,
		immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.LoopUntil(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_))))));

immutable(Expr) checkLoopWhile(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopWhileAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, voidType(ctx), immutable Expr(
		range,
		immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.LoopWhile(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_))))));

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
		return force(enumOrUnionAndMembers).match!(immutable Expr)(
			(immutable EnumAndMembers it) =>
				checkMatchEnum(ctx, locals, range, ast, expected, matchedAndType.expr, it.members),
			(immutable UnionAndMembers it) =>
				checkMatchUnion(ctx, locals, range, ast, expected, matchedAndType.expr, it.structInst, it.members));
	else {
		if (!matchedAndType.type.isA!(Type.Bogus))
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
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref immutable StructBody.Enum.Member member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable Expr[] cases = map(ctx.alloc, ast.cases, (ref immutable MatchAst.CaseAst caseAst) {
			caseAst.local.match!void(
				(immutable(Sym)) =>
					todo!void("diagnostic: no local for enum match"),
				(immutable NameOrUnderscoreOrNone.Underscore) =>
					todo!void("diagnostic: unnecessary underscore"),
				(immutable NameOrUnderscoreOrNone.None) {});
			return checkExpr(ctx, locals, caseAst.then, expected);
		});
		return immutable Expr(
			range,
			immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.MatchEnum(matched, cases, inferred(expected)))));
	}
}

immutable(Expr) checkMatchUnion(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable MatchAst ast,
	ref Expected expected,
	ref immutable Expr matched,
	immutable StructInst* matchedUnion,
	immutable UnionMember[] members,
) {
	immutable bool goodCases = arrsCorrespond!(UnionMember, MatchAst.CaseAst)(
		members,
		ast.cases,
		(ref immutable UnionMember member, ref immutable MatchAst.CaseAst caseAst) =>
			member.name == caseAst.memberName);
	if (!goodCases) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.MatchCaseNamesDoNotMatch(
			map(ctx.alloc, members, (ref immutable UnionMember member) => member.name))));
		return bogus(expected, range);
	} else {
		immutable ExprKind.MatchUnion.Case[] cases = mapZip!(ExprKind.MatchUnion.Case)(
			ctx.alloc,
			members,
			ast.cases,
			(ref immutable UnionMember member, ref immutable MatchAst.CaseAst caseAst) =>
				checkMatchCase(ctx, locals, member, caseAst, expected));
		return immutable Expr(range, immutable ExprKind(allocate(
			ctx.alloc,
			immutable ExprKind.MatchUnion(matched, matchedUnion, cases, inferred(expected)))));
	}
}

immutable(ExprKind.MatchUnion.Case) checkMatchCase(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	ref immutable UnionMember member,
	ref immutable MatchAst.CaseAst caseAst,
	ref Expected expected,
) {
	immutable FileAndRange localRange = rangeInFile2(ctx, caseAst.localRange(ctx.allSymbols));
	immutable Opt!(Local*) local = caseAst.local.match!(immutable Opt!(Local*))(
		(immutable Sym name) {
			if (has(member.type))
				return some(allocate(
					ctx.alloc,
					immutable Local(localRange, name, LocalMutability.immut, force(member.type))));
			else {
				addDiag2(ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(name)));
				return none!(Local*);
			}
		},
		(immutable NameOrUnderscoreOrNone.Underscore) {
			if (!has(member.type))
				addDiag2(ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(sym!"_")));
			return none!(Local*);
		},
		(immutable NameOrUnderscoreOrNone.None) {
			if (has(member.type))
				addDiag2(ctx, rangeInFile2(ctx, caseAst.range), immutable Diag(
					immutable Diag.MatchCaseShouldHaveLocal(member.name)));
			return none!(Local*);
		});
	immutable Expr then = isBogus(expected)
		? bogus(expected, rangeInFile2(ctx, caseAst.range))
		: checkWithOptLocal(ctx, locals, local, caseAst.then, expected);
	return immutable ExprKind.MatchUnion.Case(local, then);
}

immutable(Expr) checkSeq(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable SeqAst ast,
	ref Expected expected,
) {
	immutable Expr first = checkAndExpectVoid(ctx, locals, ast.first);
	immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
	return immutable Expr(range, immutable ExprKind(allocate(ctx.alloc, immutable ExprKind.Seq(first, then))));
}

immutable(bool) hasBreakOrContinue(immutable ExprAst a) =>
	a.kind.match!(immutable bool)(
		(ref immutable(ArrowAccessAst)) =>
			false,
		(ref immutable(AssertOrForbidAst)) =>
			false,
		(immutable(BogusAst)) =>
			false,
		(immutable(CallAst)) =>
			false,
		(ref immutable(ForAst)) =>
			false,
		(immutable(IdentifierAst)) =>
			false,
		(ref immutable(IdentifierSetAst)) =>
			false,
		(ref immutable IfAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
		(ref immutable IfOptionAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
		(immutable(InterpolatedAst)) =>
			false,
		(ref immutable(LambdaAst)) =>
			false,
		(ref immutable LetAst x) =>
			hasBreakOrContinue(x.then),
		(immutable(LiteralFloatAst)) =>
			false,
		(immutable(LiteralIntAst)) =>
			false,
		(immutable(LiteralNatAst)) =>
			false,
		(immutable(LiteralStringAst)) =>
			false,
		(ref immutable(LoopAst)) =>
			false,
		(ref immutable(LoopBreakAst)) =>
			true,
		(immutable(LoopContinueAst)) =>
			true,
		(ref immutable(LoopUntilAst)) =>
			false,
		(ref immutable(LoopWhileAst)) =>
			false,
		(ref immutable MatchAst x) =>
			exists!(immutable MatchAst.CaseAst)(x.cases, (ref immutable MatchAst.CaseAst case_) =>
				hasBreakOrContinue(case_.then)),
		(ref immutable(ParenthesizedAst)) =>
			false,
		(ref immutable(PtrAst)) =>
			false,
		(ref immutable SeqAst x) =>
			hasBreakOrContinue(x.then),
		// TODO: Maybe this should be allowed some day. Not in primitive loop but in for-break.
		(ref immutable ThenAst x) =>
			hasBreakOrContinue(x.then),
		(ref immutable(ThrowAst)) =>
			false,
		(ref immutable(TypedAst)) =>
			false,
		(ref immutable(UnlessAst) x) =>
			hasBreakOrContinue(x.body_),
		(ref immutable(WithAst)) =>
			false);

immutable(ExprAst) callNew(immutable RangeWithinFile range) =>
	immutable ExprAst(range, immutable ExprAstKind(callNewCall(range)));
immutable(CallAst) callNewCall(immutable RangeWithinFile range) =>
	immutable CallAst(
		CallAst.style.emptyParens,
		immutable NameAndRange(range.start, sym!"new"),
		[],
		[]);

immutable(Expr) checkFor(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable ForAst ast,
	ref Expected expected,
) {
	// TODO: NEATER (don't create a synthetic AST)
	immutable bool isForBreak = hasBreakOrContinue(ast.body_);
	immutable ExprAst lambdaBody = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst(ast.params, ast.body_))));
	immutable ExprAst lambdaElse_ = has(ast.else_)
		? immutable ExprAst(
			force(ast.else_).range,
			immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst([], force(ast.else_)))))
		: immutable ExprAst(range.range, immutable ExprAstKind(immutable BogusAst())); // won't be used
	immutable ExprAst[3] allArgs = [ast.collection, lambdaBody, lambdaElse_];
	scope immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, isForBreak ? sym!"for-break" : sym!"for-loop"),
		[],
		has(ast.else_) ? allArgs : allArgs[0 .. 2]);
	return checkCall(ctx, locals, range, call, expected);
}

immutable(Expr) checkWith(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable WithAst ast,
	ref Expected expected,
) {
	if (has(ast.else_))
		todo!void("diag: no 'else' for 'with'");

	// TODO: NEATER (don't create a synthetic AST)
	immutable ExprAst lambda = immutable ExprAst(
		range.range,
		immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst(ast.params, ast.body_))));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, sym!"with-block"),
		[],
		arrLiteral!ExprAst(ctx.alloc, [ast.arg, lambda]));
	return checkCall(ctx, locals, range, call, expected);
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
		immutable ExprAstKind(allocate(ctx.alloc, immutable LambdaAst(ast.left, ast.then))));
	immutable CallAst call = immutable CallAst(
		CallAst.Style.infix,
		immutable NameAndRange(range.range.start, sym!"then"),
		[],
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
	if (has(inferred) && force(inferred) == type)
		addDiag2(ctx, range, immutable Diag(immutable Diag.TypeAnnotationUnnecessary(type)));
	immutable Expr expr = checkAndExpect(ctx, locals, ast.expr, type);
	return check(ctx, expected, type, expr);
}

public immutable(Expr) checkExpr(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	ref Expected expected,
) {
	immutable FileAndRange range = rangeInFile2(ctx, ast.range);
	return castNonScope_ref(ast).kind.match!(immutable Expr)(
		(ref immutable ArrowAccessAst a) @safe =>
			checkArrowAccess(ctx, locals, range, a, expected),
		(ref immutable AssertOrForbidAst a) =>
			checkAssertOrForbid(ctx, locals, range, a, expected),
		(immutable(BogusAst)) =>
			bogus(expected, range),
		(immutable CallAst a) =>
			checkCall(ctx, locals, range, a, expected),
		(ref immutable ForAst a) =>
			checkFor(ctx, locals, range, a, expected),
		(immutable IdentifierAst a) =>
			checkIdentifier(ctx, locals, range, a, expected),
		(ref immutable IdentifierSetAst a) =>
			checkIdentifierSet(ctx, locals, range, a, expected),
		(ref immutable IfAst a) =>
			checkIf(ctx, locals, range, a, expected),
		(ref immutable IfOptionAst a) =>
			checkIfOption(ctx, locals, range, a, expected),
		(immutable InterpolatedAst a) =>
			checkInterpolated(ctx, locals, range, a, expected),
		(ref immutable LambdaAst a) =>
			checkLambda(ctx, locals, range, a, expected),
		(ref immutable LetAst a) =>
			checkLet(ctx, locals, range, a, expected),
		(immutable LiteralFloatAst a) =>
			checkLiteralFloat(ctx, range, a, expected),
		(immutable LiteralIntAst a) =>
			checkLiteralInt(ctx, range, a, expected),
		(immutable LiteralNatAst a) =>
			checkLiteralNat(ctx, range, a, expected),
		(immutable LiteralStringAst a) =>
			checkLiteralString(ctx, range, ast, a.value, expected),
		(ref immutable LoopAst a) =>
			checkLoop(ctx, locals, range, a, expected),
		(ref immutable LoopBreakAst a) =>
			checkLoopBreak(ctx, locals, range, a, expected),
		(immutable(LoopContinueAst)) =>
			checkLoopContinue(ctx, locals, range, expected),
		(ref immutable LoopUntilAst a) =>
			checkLoopUntil(ctx, locals, range, a, expected),
		(ref immutable LoopWhileAst a) =>
			checkLoopWhile(ctx, locals, range, a, expected),
		(ref immutable MatchAst a) =>
			checkMatch(ctx, locals, range, a, expected),
		(ref immutable ParenthesizedAst a) =>
			checkExpr(ctx, locals, a.inner, expected),
		(ref immutable PtrAst a) =>
			checkPtr(ctx, locals, range, a, expected),
		(ref immutable SeqAst a) =>
			checkSeq(ctx, locals, range, a, expected),
		(ref immutable ThenAst a) =>
			checkThen(ctx, locals, range, a, expected),
		(ref immutable ThrowAst a) =>
			checkThrow(ctx, locals, range, a, expected),
		(ref immutable TypedAst a) =>
			checkTyped(ctx, locals, range, a, expected),
		(ref immutable UnlessAst a) =>
			checkUnless(ctx, locals, range, a, expected),
		(ref immutable WithAst a) =>
			checkWith(ctx, locals, range, a, expected));
}
