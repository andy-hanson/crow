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
	asCall,
	asIdentifier,
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
	isIdentifier,
	LambdaAst,
	LetAst,
	LiteralAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	matchExprAstKind,
	matchInterpolatedPart,
	matchLiteralAst,
	matchNameOrUnderscoreOrNone,
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
	asCall,
	asFunInst,
	asLocalGet,
	asParamGet,
	asRecord,
	asRecordFieldGet,
	assertNonVariadic,
	asStructInst,
	body_,
	CalledDecl,
	ClosureRef,
	CommonTypes,
	decl,
	Expr,
	FieldMutability,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunKind,
	FunKindAndStructs,
	hasMutableField,
	IntegralTypes,
	isBogus,
	isBuiltin,
	isCall,
	isDefinitelyByRef,
	isFunInst,
	isLocalGet,
	isParamGet,
	isRecordFieldGet,
	isStructInst,
	isTemplate,
	Local,
	LocalMutability,
	matchArity,
	matchCalledDecl,
	matchStructBody,
	matchType,
	matchVariableRef,
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
import util.col.arrUtil :
	arrLiteral, arrsCorrespond, contains, exists, map, map_mut, mapZip, mapZipWithIndex, zipPtrFirst;
import util.col.fullIndexDict : FullIndexDict;
import util.col.mutArr : MutArr, mutArrSize, push, tempAsArr;
import util.col.mutMaxArr : fillMutMaxArr, initializeMutMaxArr, mutMaxArrSize, push, pushLeft, tempAsArr, tempAsArr_mut;
import util.col.str : copyToSafeCStr;
import util.conv : safeToUshort, safeToUint;
import util.memory : allocate, allocateMut, initMemory, overwriteMemory;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, castNonScope_mut, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, Pos, RangeWithinFile;
import util.sym : Sym, sym, symOfStr;
import util.util : max, todo, unreachable, verify;

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
		ptrTrustMe_mut(checkCtx),
		structsAndAliasesDict,
		funsDict,
		commonTypes,
		specs,
		params,
		typeParams,
		flags,
		usedFuns);
	FunOrLambdaInfo funInfo = FunOrLambdaInfo(noneMut!(LocalsInfo*), params, none!(Expr.Lambda*));
	fillMutMaxArr(funInfo.paramsUsed, params.length, false);
	// leave funInfo.closureFields uninitialized, it won't be used
	scope LocalsInfo locals = LocalsInfo(ptrTrustMe_mut(funInfo), noneMut!(LocalNode*));
	immutable Expr res = checkAndExpect(exprCtx, locals, ast, returnType);
	checkUnusedParams(checkCtx, params, tempAsArr(funInfo.paramsUsed));
	return res;
}

private:

void checkUnusedParams(ref CheckCtx checkCtx, immutable Param[] params, scope immutable bool[] paramsUsed) =>
	zipPtrFirst!(Param, bool)(
		params,
		paramsUsed,
		(immutable Param* param, ref immutable bool used) {
			if (!used && has(param.name))
				addDiag(checkCtx, param.range, immutable Diag(immutable Diag.UnusedParam(param)));
		});

struct ExprAndType {
	immutable Expr expr;
	immutable Type type;
}

immutable(ExprAndType) checkAndInfer(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
) {
	Expected expected = Expected(immutable Expected.Infer());
	immutable Expr expr = checkExpr(ctx, locals, ast, expected);
	return immutable ExprAndType(expr, inferred(expected));
}

immutable(ExprAndType) checkAndExpectOrInfer(
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
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
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	immutable Type expected,
) {
	Expected et = Expected(expected);
	return checkExpr(ctx, locals, ast, et);
}

immutable(Expr) checkAndExpectBool(ref ExprCtx ctx, scope ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, immutable Type(ctx.commonTypes.bool_));

immutable(Expr) checkAndExpectCStr(ref ExprCtx ctx, scope ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, immutable Type(ctx.commonTypes.cString));

immutable(Expr) checkAndExpectVoid(ref ExprCtx ctx, scope ref LocalsInfo locals, scope ref immutable ExprAst ast) =>
	checkAndExpect(ctx, locals, ast, immutable Type(ctx.commonTypes.void_));

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
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Cond(inferred(expected), cond, then, else_)));
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
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Throw(force(inferred), thrown)));
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
	immutable Expr condition = checkAndExpectBool(ctx, locals, ast.condition);
	immutable Opt!Expr thrown = has(ast.thrown)
		? some(checkAndExpectCStr(ctx, locals, force(ast.thrown)))
		: none!Expr;
	return check(ctx, expected, immutable Type(ctx.commonTypes.void_), immutable Expr(
		range,
		allocate(ctx.alloc, immutable Expr.AssertOrForbid(ast.kind, condition, thrown))));
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
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Cond(inferred(expected), cond, then, else_)));
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
	scope ref Expected expected,
) =>
	has(ast)
		? checkExpr(ctx, locals, force(ast), expected)
		: checkEmptyNew(ctx, range, expected);

immutable(Expr) checkEmptyNew(ref ExprCtx ctx, immutable FileAndRange range, scope ref Expected expected) =>
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

	immutable StructInst* inst = isStructInst(optionType)
		? asStructInst(optionType)
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
	if (isStructInst(a)) {
		immutable StructInst* inst = asStructInst(a);
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
	immutable ExprAst right = matchInterpolatedPart!(
		immutable ExprAst,
		(ref immutable string it) =>
			immutable ExprAst(
				// TODO: this length may be wrong in the presence of escapes
				immutable RangeWithinFile(pos, safeToUint(pos + it.length)),
				immutable ExprAstKind(immutable LiteralAst(it))),
		(ref immutable ExprAst e) =>
			immutable ExprAst(
				e.range,
				immutable ExprAstKind(immutable CallAst(
					//TODO: new kind (not infix)
					CallAst.Style.infix,
					immutable NameAndRange(pos, sym!"to-string"),
					[],
					arrLiteral!ExprAst(ctx.alloc, [e])))),
	)(parts[0]);
	immutable Pos newPos = matchInterpolatedPart!(
		immutable Pos,
		(ref immutable string it) => safeToUint(pos + it.length),
		(ref immutable ExprAst e) => e.range.end + 1,
	)(parts[0]);
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
		? asCall(newLeft.kind)
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
	if (!has(expectedType) || !isStructInst(force(expectedType))) {
		addDiag2(ctx, range, immutable Diag(immutable Diag.ExpectedTypeIsNotALambda(expectedType)));
		return none!ExpectedLambdaType;
	}
	immutable StructInst* expectedStructInst = asStructInst(force(expectedType));
	immutable StructDecl* funStruct = decl(*expectedStructInst);
	immutable Opt!FunKind opKind = getFunStructInfo(ctx.commonTypes, funStruct);
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

immutable(Opt!FunKind) getFunStructInfo(ref immutable CommonTypes a, immutable StructDecl* s) {
	//TODO: use arrUtils
	foreach (ref immutable FunKindAndStructs fs; a.funKindsAndStructs)
		foreach (immutable StructDecl* funStruct; fs.structs)
			if (s == funStruct)
				return some(fs.kind);
	return none!FunKind;
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
		return someMut(VariableRefAndType(
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
		? someMut(node)
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
			return someMut(VariableRefAndType(immutable VariableRef(param), Mutability.immut, null, param.type));
		}
	foreach (immutable size_t index, ref ClosureFieldBuilder field; tempAsArr_mut(info.closureFields))
		if (field.name == name) {
			field.setIsUsed(accessKindInClosure(accessKind));
			return someMut(VariableRefAndType(
				immutable VariableRef(immutable ClosureRef(
					immutable PtrAndSmallNumber!(Expr.Lambda)(force(info.lambda), safeToUshort(index)))),
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
		return someMut(VariableRefAndType(
			immutable VariableRef(immutable ClosureRef(
				immutable PtrAndSmallNumber!(Expr.Lambda)(force(info.lambda), safeToUshort(closureFieldIndex)))),
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
	if (has(res)) {
		immutable Expr expr = toExpr(range, force(res).variableRef);
		return check(ctx, expected, force(res).type, expr);
	} else
		return checkIdentifierCall(ctx, locals, range, ast.name, expected);
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
		immutable Expr expr = matchVariableRef!(immutable Expr)(
			var.variableRef,
			(immutable Local* local) =>
				immutable Expr(range, allocate(ctx.alloc, immutable Expr.LocalSet(local, value))),
			(immutable Param*) =>
				unreachable!(immutable Expr),
			(immutable ClosureRef cr) =>
				immutable Expr(range, immutable Expr.ClosureSet(cr, allocate(ctx.alloc, value))));
		return check(ctx, expected, immutable Type(ctx.commonTypes.void_), expr);
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
		return someMut(var);
	} else
		return noneMut!VariableRefAndType;
}

immutable(Expr) toExpr(immutable FileAndRange range, immutable VariableRef a) =>
	matchVariableRef!(immutable Expr)(
		a,
		(immutable Local* x) =>
			immutable Expr(range, immutable Expr.LocalGet(x)),
		(immutable Param* x) =>
			immutable Expr(range, immutable Expr.ParamGet(x)),
		(immutable ClosureRef x) =>
			immutable Expr(range, immutable Expr.ClosureGet(x)));

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
	immutable Opt!(StructInst*) expectedStruct = has(expectedType) && isStructInst(force(expectedType))
		? some(asStructInst(force(expectedType)))
		: none!(StructInst*);
	immutable(bool) expectedStructIs(immutable StructInst* x) =>
		has(expectedStruct) && force(expectedStruct) == x;
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
				todo!void("literal overflow\n");

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
	immutable Opt!(StructInst*) expectedStruct,
	immutable string value,
) =>
	has(expectedStruct) && force(expectedStruct) == ctx.commonTypes.char8
		? checkStringLiteralTypedAsChar(ctx, range, value)
		: has(expectedStruct) && force(expectedStruct) == ctx.commonTypes.symbol
		? immutable Expr(range, immutable Expr.LiteralSymbol(symOfStr(ctx.allSymbols, value)))
		: has(expectedStruct) && force(expectedStruct) == ctx.commonTypes.cString
		? immutable Expr(range, immutable Expr.LiteralCString(copyToSafeCStr(ctx.alloc, value)))
		: checkStringExpressionTypedAsOther(ctx, curAst, range, expected);

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
) {
	defaultExpectedToString(ctx, range, expected);
	// TODO: NEATER (don't create a synthetic AST)
	immutable CallAst ast = immutable CallAst(
		CallAst.Style.emptyParens,
		immutable NameAndRange(range.start, sym!"literal"),
		[],
		// TODO: allocating should be unnecessary, do on stack
		arrLiteral!ExprAst(ctx.alloc, [curAst]));
	return checkCallNoLocals(ctx, range, ast, expected);
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
		LocalsInfo newLocals = LocalsInfo(locals.funOrLambda, someMut(ptrTrustMe_mut(localNode)));
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
	return matchExpectedPointee!(immutable Expr)(
		getExpectedPointee(ctx, expected),
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
	@safe @nogc pure nothrow:

	struct None {}
	struct FunPointer {}
	struct Pointer { immutable Type pointer; immutable Type pointee; immutable PointerMutability mutability; }

	immutable this(immutable None a) { kind = Kind.none; none = a; }
	immutable this(immutable FunPointer a) { kind = Kind.funPointer; funPointer = a; }
	immutable this(immutable Pointer a) { kind = Kind.pointer; pointer = a; }

	private:
	enum Kind { none, funPointer, pointer }
	immutable Kind kind;
	union {
		immutable None none;
		immutable FunPointer funPointer;
		immutable Pointer pointer;
	}
}
enum PointerMutability { immutable_, mutable }

immutable(T) matchExpectedPointee(T)(
	immutable ExpectedPointee a,
	scope immutable(T) delegate(immutable ExpectedPointee.None) @safe @nogc pure nothrow cbNone,
	scope immutable(T) delegate(immutable ExpectedPointee.FunPointer) @safe @nogc pure nothrow cbFunPointer,
	scope immutable(T) delegate(immutable ExpectedPointee.Pointer) @safe @nogc pure nothrow cbPointer,
) {
	final switch (a.kind) {
		case ExpectedPointee.Kind.none:
			return cbNone(a.none);
		case ExpectedPointee.Kind.funPointer:
			return cbFunPointer(a.funPointer);
		case ExpectedPointee.Kind.pointer:
			return cbPointer(a.pointer);
	}
}

immutable(ExpectedPointee) getExpectedPointee(ref ExprCtx ctx, ref const Expected expected) {
	immutable Opt!Type expectedType = tryGetInferred(expected);
	if (has(expectedType) && isStructInst(force(expectedType))) {
		immutable StructInst* inst = asStructInst(force(expectedType));
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
	if (isLocalGet(inner)) {
		immutable Local* local = asLocalGet(inner).local;
		if (local.mutability < pointerMutability)
			addDiag2(ctx, range, immutable Diag(immutable Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.local)));
		if (pointerMutability == PointerMutability.mutable)
			markIsUsedSetOnStack(locals, local);
		return immutable Expr(range, immutable Expr.PtrToLocal(pointerType, local));
	} else if (isParamGet(inner))
		return immutable Expr(range, immutable Expr.PtrToParam(pointerType, asParamGet(inner).param));
	else if (isCall(inner))
		return checkPtrOfCall(ctx, range, asCall(inner), pointerType, pointerMutability);
	else {
		addDiag2(ctx, range, immutable Diag(immutable Diag.PtrUnsupported()));
		return immutable Expr(range, immutable Expr.Bogus());
	}
}

immutable(Expr) checkPtrOfCall(
	ref ExprCtx ctx,
	immutable FileAndRange range,
	immutable Expr.Call call,
	immutable Type pointerType,
	immutable PointerMutability pointerMutability,
) {
	immutable(Expr) fail() {
		addDiag2(ctx, range, immutable Diag(immutable Diag.PtrUnsupported()));
		return immutable Expr(range, immutable Expr.Bogus());
	}

	if (isFunInst(call.called)) {
		immutable FunInst* getFieldFun = asFunInst(call.called);
		if (isRecordFieldGet(decl(*getFieldFun).body_)) {
			immutable FunBody.RecordFieldGet rfg = asRecordFieldGet(decl(*getFieldFun).body_);
			immutable Expr target = only(call.args);
			immutable StructInst* recordType = asStructInst(only(assertNonVariadic(getFieldFun.params)).type);
			immutable RecordField field = asRecord(body_(*recordType)).fields[rfg.fieldIndex];
			immutable PointerMutability fieldMutability = pointerMutabilityFromField(field.mutability);
			if (isDefinitelyByRef(*recordType)) {
				if (fieldMutability < pointerMutability)
					addDiag2(ctx, range, immutable Diag(immutable Diag.PtrMutToConst(Diag.PtrMutToConst.Kind.field)));
				return immutable Expr(range, allocate(ctx.alloc,
					immutable Expr.PtrToField(pointerType, target, rfg.fieldIndex)));
			} else if (isCall(target)) {
				immutable Expr.Call targetCall = asCall(target);
				immutable FunInst* derefFun = asFunInst(targetCall.called);
				if (isFunInst(targetCall.called) && isDerefFunction(ctx, derefFun)) {
					immutable StructInst* ptrStructInst = asStructInst(only(assertNonVariadic(derefFun.params)).type);
					immutable Expr targetPtr = only(targetCall.args);
					if (max(fieldMutability, mutabilityForPtrDecl(ctx, decl(*ptrStructInst))) < pointerMutability)
						todo!void("diag: can't get mut* to immutable field");
					return immutable Expr(range, allocate(ctx.alloc,
						immutable Expr.PtrToField(pointerType, targetPtr, rfg.fieldIndex)));
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

immutable(bool) isDerefFunction(ref ExprCtx ctx, immutable FunInst* a) {
	immutable FunBody body_ = decl(*a).body_;
	return isBuiltin(body_) && decl(*a).name == sym!"*" && arity(*a) == immutable Arity(1);
}

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
	if (!isIdentifier(ast.inner.kind))
		todo!void("diag: fun-pointer ast should just be an identifier");
	immutable Sym name = asIdentifier(ast.inner.kind).name;
	MutArr!(immutable FunDecl*) funsInScope = MutArr!(immutable FunDecl*)();
	eachFunInScope(ctx, name, (immutable UsedFun used, immutable CalledDecl cd) {
		matchCalledDecl!(
			void,
			(immutable FunDecl* it) {
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
	immutable FunDecl* funDecl = funsInScope[0];

	if (isTemplate(*funDecl))
		todo!void("can't point to template");
	immutable size_t nParams = matchArity!(
		immutable size_t,
		(immutable size_t n) =>
			n,
		(ref immutable Arity.Varargs) =>
			todo!(immutable size_t)("ptr to variadic function?"),
	)(arity(*funDecl));
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

	Expr.Lambda* lambda = () @trusted { return allocateUninitialized!(Expr.Lambda)(ctx.alloc); }();

	FunOrLambdaInfo lambdaInfo =
		FunOrLambdaInfo(someMut(castNonScope_mut(ptrTrustMe_mut(locals))), params, some(castImmutable(lambda)));
	fillMutMaxArr(lambdaInfo.paramsUsed, params.length, false);
	initializeMutMaxArr(lambdaInfo.closureFields);
	scope LocalsInfo lambdaLocalsInfo = LocalsInfo(ptrTrustMe_mut(lambdaInfo), noneMut!(LocalNode*));

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
			foreach (ref ClosureFieldBuilder cf; tempAsArr_mut(lambdaInfo.closureFields)) {
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
		map_mut(ctx.alloc, tempAsArr_mut(lambdaInfo.closureFields), (ref ClosureFieldBuilder x) =>
			x.variableRef);

	immutable Opt!Type actualNonFutReturnType = kind == FunKind.ref_
		? matchType!(immutable Opt!Type)(
			actualPossiblyFutReturnType,
			(immutable Type.Bogus) =>
				some(immutable Type(immutable Type.Bogus())),
			(immutable TypeParam*) =>
				none!Type,
			(immutable StructInst* ap) =>
				decl(*ap) == ctx.commonTypes.future
					? some!Type(only(typeArgs(*ap)))
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
		initMemory(lambda, immutable Expr.Lambda(
			params,
			body_,
			closureFields,
			instFunStruct,
			kind,
			actualPossiblyFutReturnType));
		//TODO: this check should never fail, so could just set inferred directly with no check
		return check(ctx, expected, immutable Type(instFunStruct), immutable Expr(range, castImmutable(lambda)));
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
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Let(local, init.expr, then)));
	} else {
		if (ast.mut) todo!void("'mut' makes no sense for nameless local");
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

immutable(Opt!EnumOrUnionAndMembers) getEnumOrUnionBody(immutable Type a) =>
	matchType!(immutable Opt!EnumOrUnionAndMembers)(
		a,
		(immutable Type.Bogus) => none!EnumOrUnionAndMembers,
		(immutable TypeParam*) => none!EnumOrUnionAndMembers,
		(immutable StructInst* structInst) =>
			matchStructBody!(immutable Opt!EnumOrUnionAndMembers)(
				body_(*structInst),
				(ref immutable StructBody.Bogus) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Builtin) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Enum it) =>
					some(immutable EnumOrUnionAndMembers(immutable EnumAndMembers(it.members))),
				(ref immutable StructBody.Flags) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.ExternPointer) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Record) =>
					none!EnumOrUnionAndMembers,
				(ref immutable StructBody.Union it) =>
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
		Expr.Loop* loop =
			allocateMut(ctx.alloc, Expr.Loop(type, immutable Expr(FileAndRange.empty, immutable Expr.Bogus())));
		LoopInfo info = LoopInfo(immutable Type(ctx.commonTypes.void_), castImmutable(loop), type, false);
		scope Expected bodyExpected = Expected(&info);
		immutable Expr body_ = checkExpr(ctx, locals, ast.body_, bodyExpected);
		overwriteMemory(&loop.body_, body_);
		if (!info.hasBreak)
			addDiag2(ctx, range, immutable Diag(immutable Diag.LoopWithoutBreak()));
		return immutable Expr(range, castImmutable(loop));
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
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.LoopBreak(loop.loop, value)));
	}
}

immutable(Expr) checkLoopContinue(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref Expected expected,
) {
	Opt!(LoopInfo*) optLoop = tryGetLoop(expected);
	if (!has(optLoop)) {
		scope immutable CallAst call = immutable CallAst(
			CallAst.Style.infix,
			immutable NameAndRange(range.range.start, sym!"loop-continue"),
			[],
			[]);
		return checkCall(ctx, locals, range, call, expected);
	} else {
		LoopInfo* loop = force(optLoop);
		return immutable Expr(range, allocate(ctx.alloc, immutable Expr.LoopContinue(loop.loop)));
	}
}

immutable(Expr) checkLoopUntil(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopUntilAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, immutable Type(ctx.commonTypes.void_), immutable Expr(
		range,
		allocate(ctx.alloc, immutable Expr.LoopUntil(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_)))));

immutable(Expr) checkLoopWhile(
	ref ExprCtx ctx,
	ref LocalsInfo locals,
	immutable FileAndRange range,
	ref immutable LoopWhileAst ast,
	ref Expected expected,
) =>
	check(ctx, expected, immutable Type(ctx.commonTypes.void_), immutable Expr(
		range,
		allocate(ctx.alloc, immutable Expr.LoopWhile(
			checkAndExpectBool(ctx, locals, ast.condition),
			checkAndExpectVoid(ctx, locals, ast.body_)))));

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
			member.name == caseAst.memberName);
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
	immutable Opt!(Local*) local = matchNameOrUnderscoreOrNone!(
		immutable Opt!(Local*),
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
		(ref immutable NameOrUnderscoreOrNone.Underscore) {
			if (!has(member.type))
				addDiag2(ctx, localRange, immutable Diag(
					immutable Diag.MatchCaseShouldNotHaveLocal(sym!"_")));
			return none!(Local*);
		},
		(ref immutable NameOrUnderscoreOrNone.None) {
			if (has(member.type))
				addDiag2(ctx, rangeInFile2(ctx, caseAst.range), immutable Diag(
					immutable Diag.MatchCaseShouldHaveLocal(member.name)));
			return none!(Local*);
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
	immutable Expr first = checkAndExpectVoid(ctx, locals, ast.first);
	immutable Expr then = checkExpr(ctx, locals, ast.then, expected);
	return immutable Expr(range, allocate(ctx.alloc, immutable Expr.Seq(first, then)));
}

immutable(bool) hasBreakOrContinue(immutable ExprAst a) =>
	matchExprAstKind!(
		immutable bool,
		(scope ref immutable(ArrowAccessAst)) =>
			false,
		(scope ref immutable(AssertOrForbidAst)) =>
			false,
		(scope ref immutable(BogusAst)) =>
			false,
		(scope ref immutable(CallAst)) =>
			false,
		(scope ref immutable(ForAst)) =>
			false,
		(scope ref immutable(IdentifierAst)) =>
			false,
		(scope ref immutable(IdentifierSetAst)) =>
			false,
		(scope ref immutable IfAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
		(scope ref immutable IfOptionAst x) =>
			hasBreakOrContinue(x.then) || (has(x.else_) && hasBreakOrContinue(force(x.else_))),
		(scope ref immutable(InterpolatedAst)) =>
			false,
		(scope ref immutable(LambdaAst)) =>
			false,
		(scope ref immutable LetAst x) =>
			hasBreakOrContinue(x.then),
		(scope ref immutable(LiteralAst)) =>
			false,
		(scope ref immutable(LoopAst)) =>
			false,
		(scope ref immutable(LoopBreakAst)) =>
			true,
		(scope ref immutable(LoopContinueAst)) =>
			true,
		(scope ref immutable(LoopUntilAst)) =>
			false,
		(scope ref immutable(LoopWhileAst)) =>
			false,
		(scope ref immutable MatchAst x) =>
			exists!(immutable MatchAst.CaseAst)(x.cases, (ref immutable MatchAst.CaseAst case_) =>
				hasBreakOrContinue(case_.then)),
		(scope ref immutable(ParenthesizedAst)) =>
			false,
		(scope ref immutable(PtrAst)) =>
			false,
		(scope ref immutable SeqAst x) =>
			hasBreakOrContinue(x.then),
		//Hmm... maybe this should be allowed some day. Not in primitive loop but in for-break.
		(scope ref immutable ThenAst x) =>
			hasBreakOrContinue(x.then),
		(scope ref immutable(ThrowAst)) =>
			false,
		(scope ref immutable(TypedAst)) =>
			false,
		(scope ref immutable(UnlessAst) x) =>
			hasBreakOrContinue(x.body_),
		(scope ref immutable(WithAst)) =>
			false,
	)(a.kind);

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
	scope ref ExprCtx ctx,
	scope ref LocalsInfo locals,
	scope ref immutable ExprAst ast,
	scope ref Expected expected,
) {
	immutable FileAndRange range = rangeInFile2(ctx, ast.range);
	return matchExprAstKind!(
		immutable Expr,
		(scope ref immutable ArrowAccessAst a) =>
			checkArrowAccess(ctx, locals, range, a, expected),
		(scope ref immutable AssertOrForbidAst a) =>
			checkAssertOrForbid(ctx, locals, range, a, expected),
		(scope ref immutable(BogusAst)) =>
			bogus(expected, range),
		(scope ref immutable CallAst a) =>
			checkCall(ctx, locals, range, a, expected),
		(scope ref immutable ForAst a) =>
			checkFor(ctx, locals, range, a, expected),
		(scope ref immutable IdentifierAst a) =>
			checkIdentifier(ctx, locals, range, a, expected),
		(scope ref immutable IdentifierSetAst a) =>
			checkIdentifierSet(ctx, locals, range, a, expected),
		(scope ref immutable IfAst a) =>
			checkIf(ctx, locals, range, a, expected),
		(scope ref immutable IfOptionAst a) =>
			checkIfOption(ctx, locals, range, a, expected),
		(scope ref immutable InterpolatedAst a) =>
			checkInterpolated(ctx, locals, range, a, expected),
		(scope ref immutable LambdaAst a) =>
			checkLambda(ctx, locals, range, a, expected),
		(scope ref immutable LetAst a) =>
			checkLet(ctx, locals, range, a, expected),
		(scope ref immutable LiteralAst a) =>
			checkLiteral(ctx, range, ast, a, expected),
		(scope ref immutable LoopAst a) =>
			checkLoop(ctx, locals, range, a, expected),
		(scope ref immutable LoopBreakAst a) =>
			checkLoopBreak(ctx, locals, range, a, expected),
		(scope ref immutable(LoopContinueAst)) =>
			checkLoopContinue(ctx, locals, range, expected),
		(scope ref immutable LoopUntilAst a) =>
			checkLoopUntil(ctx, locals, range, a, expected),
		(scope ref immutable LoopWhileAst a) =>
			checkLoopWhile(ctx, locals, range, a, expected),
		(scope ref immutable MatchAst a) =>
			checkMatch(ctx, locals, range, a, expected),
		(scope ref immutable ParenthesizedAst a) =>
			checkExpr(ctx, locals, a.inner, expected),
		(scope ref immutable PtrAst a) =>
			checkPtr(ctx, locals, range, a, expected),
		(scope ref immutable SeqAst a) =>
			checkSeq(ctx, locals, range, a, expected),
		(scope ref immutable ThenAst a) =>
			checkThen(ctx, locals, range, a, expected),
		(scope ref immutable ThrowAst a) =>
			checkThrow(ctx, locals, range, a, expected),
		(scope ref immutable TypedAst a) =>
			checkTyped(ctx, locals, range, a, expected),
		(scope ref immutable UnlessAst a) =>
			checkUnless(ctx, locals, range, a, expected),
		(scope ref immutable WithAst a) =>
			checkWith(ctx, locals, range, a, expected),
	)(ast.kind);
}
