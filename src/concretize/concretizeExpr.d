module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArray, getConstantPointer;
import concretize.concretizeCtx :
	arrayElementType,
	boolType,
	ConcreteLambdaImpl,
	concreteTypeFromClosure,
	ConcreteVariantMember,
	ConcretizeCtx,
	concretizeLambdaParams,
	constantCString,
	constantSymbol,
	ContainingFunInfo,
	exceptionType,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteFunForLambda,
	getConcreteFun,
	getNonTemplateConcreteFun,
	SpecsScope,
	specsScopeForFun,
	typeArgsScopeForFun,
	TypeArgsScope,
	voidType,
	withConcreteTypes;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs;
import concretize.generate :
	genCall,
	genCallNoAllocArgs,
	genCallKindNoAllocArgs,
	genChar8Array,
	genChar8List,
	genChar32Array,
	genChar32List,
	genError,
	genNone,
	genStringLiteral,
	genSome,
	genLocalGet,
	genThrow,
	genThrowStringKind;
import model.ast : AssertOrForbidAst, ConditionAst, ExprAst;
import model.concreteModel :
	byRef,
	byVal,
	ConcreteClosureRef,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteMutability,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVariableRef,
	isBogus,
	isSummon,
	isVariadic,
	isVoid,
	mustBeByVal,
	name,
	purity,
	ReferenceKind,
	returnType;
import model.constant : asBool, Constant, constantBool, constantZero;
import model.model :
	AssertOrForbidExpr,
	Called,
	CalledSpecSig,
	CallExpr,
	CallOptionExpr,
	ClosureGetExpr,
	ClosureRef,
	ClosureReferenceKind,
	ClosureSetExpr,
	Condition,
	Destructure,
	EnumFunction,
	Expr,
	ExprAndType,
	FinallyExpr,
	FunInst,
	FunPointerExpr,
	IfExpr,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	Local,
	LocalGetExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopWhileOrUntilExpr,
	MatchEnumExpr,
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	MatchVariantExpr,
	Purity,
	PtrToFieldExpr,
	PtrToLocalExpr,
	SeqExpr,
	SpecInst,
	ThrowExpr,
	TrustedExpr,
	TryExpr,
	TryLetExpr,
	Type,
	TypedExpr,
	VariableRef,
	VariantMember;
import util.alloc.alloc : Alloc;
import util.alloc.stackAlloc : withMapOrNoneToStackArray;
import util.col.array :
	concatenate,
	findIndex,
	isEmpty,
	map,
	mapWithFirst,
	mapZip,
	mustFind,
	newArray,
	newSmallArray,
	only,
	only2,
	PtrAndSmallNumber,
	sizeEq,
	small,
	SmallArray;
import util.col.mutArr : asTemporaryArray, MutArr, mutArrSize, push;
import util.col.mutMap : getOrAdd, mustGet;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet, withStackMap;
import util.integralValues : IntegralValue, IntegralValues, integralValuesRange, mapToIntegralValues;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
import util.sourceRange : Range, UriAndRange;
import util.symbol : symbol, symbolOfString;
import util.union_ : Union;
import util.uri : Uri;
import util.util : castNonScope, castNonScope_ref, ptrTrustMe;
import versionInfo : isVersion, VersionFun, VersionInfo;

ConcreteExpr concretizeFunBody(ref ConcretizeCtx ctx, ConcreteFun* cf, in Destructure[] params, ref Expr e) =>
	withConcretizeExprCtx(ctx, cf, (ref ConcretizeExprCtx exprCtx) =>
		withStackMap!(ConcreteExpr, Local*, LocalOrConstant)((ref Locals locals) {
			// Ignore closure param, which is never destructured.
			ConcreteLocal[] paramsToDestructure =
				cf.paramsIncludingClosure[params.length + 1 == cf.paramsIncludingClosure.length ? 1 : 0 .. $];
			return concretizeWithParamDestructures(exprCtx, cf.returnType, locals, params, paramsToDestructure, e);
		}));

Out withConcretizeExprCtx(Out)(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in Out delegate(ref ConcretizeExprCtx) @safe @nogc pure nothrow cb,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe(ctx), fun);
	return cb(exprCtx);
}

ConcreteExpr concretizeBogus(ref ConcretizeExprCtx ctx, ConcreteType type, UriAndRange range) =>
	ConcreteExpr(type, range, concretizeBogusKind(ctx, range));
ConcreteExprKind concretizeBogusKind(ref ConcretizeExprCtx ctx, in UriAndRange range) =>
	genThrowStringKind(ctx, range, "Reached compile error");

private:

ConcreteExpr concretizeWithParamDestructures(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in Locals locals,
	in Destructure[] params,
	ConcreteLocal[] concreteParams,
	ref Expr expr,
) {
	assert(sizeEq(params, concreteParams));
	if (isEmpty(params))
		return concretizeExpr(ctx, type, locals, expr);
	else {
		ConcreteExpr rest(in Locals innerLocals) {
			return concretizeWithParamDestructures(
				ctx, type, innerLocals, params[1 .. $], concreteParams[1 .. $], expr);
		}
		return params[0].matchWithPointers!ConcreteExpr(
			(Destructure.Ignore*) =>
				rest(locals),
			(Local* local) =>
				rest(addLocal(locals, local, LocalOrConstant(&concreteParams[0]))),
			(Destructure.Split* x) =>
				concretizeWithDestructureSplit(
					ctx, type, toUriAndRange(ctx, params[0].range), locals, *x, &concreteParams[0],
					(in Locals innerLocals) => rest(innerLocals)));
	}
}

public struct ConcretizeExprCtx {
	@safe @nogc pure nothrow:

	ConcretizeCtx* concretizeCtxPtr;
	immutable ConcreteFun* currentConcreteFunPointer; // This is the ConcreteFun* for a lambda, not its containing fun. TODO: name too big. Just make it 'fun'!
	size_t nextLambdaIndex = 0;

	Uri curUri() scope const =>
		currentConcreteFunPointer.moduleUri; // TODO: since everything in the same function is in the same module, we don't really need to store it on each expr!

	ref Alloc alloc() return scope =>
		concretizeCtx.alloc;

	ref inout(ConcretizeCtx) concretizeCtx() return scope inout =>
		*concretizeCtxPtr;

	ref ConcreteFun currentConcreteFun() return scope const =>
		*currentConcreteFunPointer;

	ref inout(AllConstantsBuilder) allConstants() return scope inout =>
		concretizeCtx.allConstants;
}

ConcreteType boolType(ref ConcretizeExprCtx ctx) =>
	.boolType(ctx.concretizeCtx);
ConcreteType voidType(ref ConcretizeExprCtx ctx) =>
	.voidType(ctx.concretizeCtx);

UriAndRange toUriAndRange(in ConcretizeExprCtx ctx, in Range a) =>
	UriAndRange(ctx.curUri, a);

immutable struct TypedConstant {
	ConcreteType type;
	Constant value;
}

immutable struct LocalOrConstant {
	mixin Union!(ConcreteLocal*, TypedConstant);
}

ConcreteType type(in LocalOrConstant a) =>
	a.matchIn!ConcreteType(
		(in ConcreteLocal x) =>
			x.type,
		(in TypedConstant x) =>
			x.type);

ConcreteType getConcreteType(ref ConcretizeExprCtx ctx, Type t) =>
	getConcreteType_fromConcretizeCtx(ctx.concretizeCtx, t, typeScope(ctx));

TypeArgsScope typeScope(ref const ConcretizeExprCtx ctx) =>
	typeArgsScopeForFun(ctx.currentConcreteFunPointer);

SpecsScope specsScope(ref const ConcretizeExprCtx ctx) =>
	specsScopeForFun(ctx.currentConcreteFunPointer);

ConcreteExpr concretizeCall(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref CallExpr e,
) {
	Opt!(ConcreteFun*) optConcreteCalled = getConcreteFunFromCalled(ctx, e.called);
	if (!has(optConcreteCalled) || isBogus(force(optConcreteCalled).returnType))
		return concretizeBogus(ctx, type, range);
	ConcreteFun* concreteCalled = force(optConcreteCalled);
	assert(concreteCalled.returnType == type);
	bool argsMayBeConstants =
		isEmpty(e.args) || (!isSummon(*concreteCalled) && purity(concreteCalled.returnType) == Purity.data);
	ConstantsOrExprs args = () {
		if (isVariadic(*concreteCalled)) {
			ConcreteType arrayType = only(concreteCalled.paramsIncludingClosure).type;
			ConcreteType elementType = arrayElementType(arrayType);
			return constantsOrExprsArr(
				ctx, range, arrayType,
				asConstantsOrExprsIf(ctx.alloc, argsMayBeConstants, map(ctx.alloc, e.args, (ref Expr arg) =>
					concretizeExpr(ctx, elementType, locals, arg))));
		} else
			return asConstantsOrExprsIf(
				ctx.alloc, argsMayBeConstants,
				mapZip(
					ctx.alloc, concreteCalled.paramsIncludingClosure, e.args,
					(ref ConcreteLocal param, ref Expr arg) =>
						concretizeExpr(ctx, param.type, locals, arg)));
	}();
	ConcreteExprKind kind = args.match!ConcreteExprKind(
		(Constant[] constants) {
			Opt!Constant constant =
				tryEvalConstant(*concreteCalled, constants, ctx.concretizeCtx.versionInfo);
			return has(constant)
				? ConcreteExprKind(force(constant))
				: genCallKindNoAllocArgs(concreteCalled, mapZip(
					ctx.alloc,
					concreteCalled.paramsIncludingClosure,
					constants,
					(ref ConcreteLocal p, ref Constant x) =>
						ConcreteExpr(p.type, UriAndRange.empty, ConcreteExprKind(x))));
		},
		(ConcreteExpr[] exprs) =>
			genCallKindNoAllocArgs(concreteCalled, exprs));
	return ConcreteExpr(type, range, kind);
}

ConcreteExpr concretizeCallOption(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref CallOptionExpr a,
) {
	// `a?.b` ==> `x ?= a ? (x.b,) : ()`
	// But `x.b` may already be an option and might not need to be wrapped
	Opt!(ConcreteFun*) optCalled = getConcreteFunFromCalled(ctx, a.called);
	if (!has(optCalled) || isBogus(force(optCalled).returnType))
		return concretizeBogus(ctx, type, range);
	ConcreteFun* called = force(optCalled);

	ConcreteExpr option = concretizeExpr(ctx, locals, a.firstArg);
	ConcreteLocal* local = allocate(ctx.alloc, ConcreteLocal(
		ConcreteLocalSource(ConcreteLocalSource.Generated.destruct),
		called.paramsIncludingClosure[0].type));
	assert(a.restArgs.length + 1 == called.paramsIncludingClosure.length);
	SmallArray!ConcreteExpr allArgs = mapWithFirst!(ConcreteExpr, Expr)(
		ctx.alloc,
		genLocalGet(range, local),
		a.restArgs,
		(size_t i, ref Expr x) => concretizeExpr(ctx, called.paramsIncludingClosure[i + 1].type, locals, x));
	ConcreteExpr call = genCallNoAllocArgs(range, called, allArgs);
	ConcreteExpr someCall = call.type == type ? call : genSome(ctx.concretizeCtx, range, type, call);
	assert(someCall.type == type);
	return genIfOption(
		ctx.alloc, range, option,
		RootLocalAndExpr(some(local), someCall),
		genNone(ctx.concretizeCtx, range, type));
}

ConstantsOrExprs asConstantsOrExprsIf(ref Alloc alloc, bool mayBeConstants, ConcreteExpr[] exprs) =>
	mayBeConstants
		? asConstantsOrExprs(alloc, exprs)
		: ConstantsOrExprs(exprs);

public Opt!(ConcreteFun*) getConcreteFunFromCalled(ref ConcretizeExprCtx ctx, ref Called called) =>
	called.matchWithPointers!(Opt!(ConcreteFun*))(
		(Called.Bogus*) =>
			none!(ConcreteFun*),
		(FunInst* funInst) =>
			getConcreteFunFromFunInst(ctx, funInst),
		(CalledSpecSig specSig) =>
			some(getSpecSigImplementation(ctx, specSig)));

ConcreteFun* getSpecSigImplementation(in ConcretizeExprCtx ctx, CalledSpecSig specSig) {
	size_t index = 0;
	SpecsScope scope_ = specsScope(ctx);
	foreach (SpecInst* x; scope_.specs)
		if (searchSpecSigIndexRecur(index, x, specSig.specInst))
			return scope_.specImpls[index + specSig.sigIndex];
	assert(false);
}
bool searchSpecSigIndexRecur(ref size_t index, in SpecInst* inst, in SpecInst* search) {
	foreach (SpecInst* parent; inst.parents) {
		if (searchSpecSigIndexRecur(index, parent, search))
			return true;
	}
	if (inst == search)
		return true;
	index += inst.decl.sigs.length;
	return false;
}

Opt!(ConcreteFun*) getConcreteFunFromFunInst(ref ConcretizeExprCtx ctx, FunInst* funInst) =>
	withMapOrNoneToStackArray!(ConcreteFun*, immutable ConcreteFun*, Called)(
		funInst.specImpls,
		(ref Called x) => getConcreteFunFromCalled(ctx, x),
		(scope immutable ConcreteFun*[] specImpls) =>
			withConcreteTypes(ctx.concretizeCtx, funInst.typeArgs, typeScope(ctx), (scope ConcreteType[] typeArgs) =>
				getConcreteFun(ctx.concretizeCtx, funInst.decl, typeArgs, specImpls)));

ConcreteExpr concretizeClosureGet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in ClosureGetExpr a,
) {
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, a.closureRef);
	assert(info.type == type);
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.ClosureGet(info.closureRef, info.referenceKind))));
}

ConcreteExpr concretizeClosureSet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	in ClosureSetExpr a,
) {
	assert(a.closureRef.closureReferenceKind == ClosureReferenceKind.allocated);
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, a.closureRef);
	assert(info.referenceKind == ClosureReferenceKind.allocated);
	ConcreteExpr value = concretizeExpr(ctx, info.type, locals, *a.value);
	assert(isVoid(type));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.ClosureSet(info.closureRef, value))));
}

immutable struct ClosureFieldInfo {
	ConcreteClosureRef closureRef;
	ConcreteType type; // If 'referenceKind' is 'allocated', this is the pointee type
	ClosureReferenceKind referenceKind;
}
ClosureFieldInfo getClosureFieldInfo(ref ConcretizeExprCtx ctx, in UriAndRange range, in ClosureRef a) {
	ConcreteLocal* closureParam = &ctx.currentConcreteFun.paramsIncludingClosure[0];
	ConcreteType closureType = closureParam.type;
	ConcreteStructBody.Record record = closureType.struct_.body_.as!(ConcreteStructBody.Record);
	ClosureReferenceKind referenceKind = a.closureReferenceKind;
	ConcreteType fieldType = record.fields[a.index].type;
	ConcreteType pointeeType = () {
		final switch (referenceKind) {
			case ClosureReferenceKind.direct:
				return fieldType;
			case ClosureReferenceKind.allocated:
				return removeIndirection(fieldType);
		}
	}();
	return ClosureFieldInfo(
		ConcreteClosureRef(PtrAndSmallNumber!ConcreteLocal(closureParam, a.index)),
		pointeeType,
		referenceKind);
}

ConcreteExpr createAllocExpr(ref Alloc alloc, ConcreteExpr inner) {
	assert(inner.type.reference == ReferenceKind.byVal);
	return ConcreteExpr(
		byRef(inner.type),
		inner.range,
		ConcreteExprKind(allocate(alloc, ConcreteExprKind.Alloc(inner))));
}

SmallArray!ConcreteField concretizeClosureFields(
	ref ConcretizeCtx ctx,
	SmallArray!VariableRef closure,
	TypeArgsScope typeArgsScope,
) =>
	map!(ConcreteField, VariableRef)(ctx.alloc, closure, (ref VariableRef x) {
		ConcreteType baseType = getConcreteType_fromConcretizeCtx(ctx, x.type, typeArgsScope);
		ConcreteType type = () {
			final switch (x.closureReferenceKind) {
				case ClosureReferenceKind.direct:
					return baseType;
				case ClosureReferenceKind.allocated:
					return addIndirection(baseType);
			}
		}();
		// Even if the variable is mutable, it's a const field holding a mut pointer
		return ConcreteField(x.name, ConcreteMutability.const_, type);
	});

ConcreteType addIndirection(ConcreteType a) =>
	ConcreteType(addIndirection(a.reference), a.struct_);
ReferenceKind addIndirection(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return ReferenceKind.byRef;
		case ReferenceKind.byRef:
			return ReferenceKind.byRefRef;
		case ReferenceKind.byRefRef:
			assert(false);
	}
}

ConcreteType removeIndirection(ConcreteType a) =>
	ConcreteType(removeIndirection(a.reference), a.struct_);
ReferenceKind removeIndirection(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			assert(false);
		case ReferenceKind.byRef:
			return ReferenceKind.byVal;
		case ReferenceKind.byRefRef:
			return ReferenceKind.byRef;
	}
}

ConcreteExpr concretizeFunPointer(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	FunPointerExpr a,
) {
	Opt!(ConcreteFun*) called = getConcreteFunFromCalled(ctx, a.called);
	return has(called)
		? ConcreteExpr(type, range, ConcreteExprKind(Constant(Constant.FunPointer(force(called)))))
		: concretizeBogus(ctx, type, range);
}

ConcreteExpr concretizeLambda(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	LambdaExpr* e,
) {
	if (e.kind == LambdaExpr.Kind.explicitShared) {
		ConcreteType innerType = getConcreteType(ctx, Type(force(e.mutTypeForExplicitShared)));
		ConcreteExpr inner = concretizeLambdaInner(ctx, innerType, range, locals, e);
		ConcreteType[2] lambdaTypeArgs = only2(innerType.struct_.source.as!(ConcreteStructSource.Inst).typeArgs);
		ConcreteFun* sharedOfMutLambda = getConcreteFun(
			ctx.concretizeCtx, ctx.concretizeCtx.program.commonFuns.sharedOfMutLambda, lambdaTypeArgs, []);
		return genCall(ctx.alloc, range, sharedOfMutLambda, [inner]);
	} else
		return concretizeLambdaInner(ctx, type, range, locals, e);
}

ConcreteExpr concretizeLambdaInner(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	LambdaExpr* e,
) {
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

	//TODO:KILL? (We also have an ID within the type..)
	size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	TypeArgsScope tScope = typeScope(ctx);
	SmallArray!ConcreteField closureFields = concretizeClosureFields(ctx.concretizeCtx, e.closure, tScope);
	ConcreteType closureType = concreteTypeFromClosure(
		ctx.concretizeCtx,
		closureFields,
		ConcreteStructSource(ConcreteStructSource.Lambda(ctx.currentConcreteFunPointer, lambdaIndex)));
	ConcreteLocal[] paramsIncludingClosure = concretizeLambdaParams(ctx.concretizeCtx, closureType, e.param, tScope);

	ConcreteStruct* concreteStruct = mustBeByVal(type);

	ConcreteVariableRef[] closureArgs = map(ctx.alloc, e.closure, (ref VariableRef x) =>
		concretizeVariableRefForClosure(ctx, range, locals, x));
	Opt!(ConcreteExpr*) closure = isEmpty(closureArgs)
		? none!(ConcreteExpr*)
		: some(allocate(ctx.alloc, createAllocExpr(ctx.alloc, ConcreteExpr(
			byVal(closureType),
			range,
			ConcreteExprKind(ConcreteExprKind.ClosureCreate(closureArgs))))));

	ConcreteType returnType = getConcreteType(ctx, e.returnType);
	if (isBogus(returnType))
		return concretizeBogus(ctx, type, range);

	ConcreteFun* fun = getConcreteFunForLambda(
		ctx.concretizeCtx,
		ctx.currentConcreteFunPointer,
		lambdaIndex,
		returnType,
		e.param,
		paramsIncludingClosure,
		&e.body_());
	ConcreteLambdaImpl impl = ConcreteLambdaImpl(closureType, fun);
	return ConcreteExpr(type, range, ConcreteExprKind(
		ConcreteExprKind.Lambda(nextLambdaImplId(ctx.concretizeCtx, concreteStruct, impl), closure)));
}

size_t nextLambdaImplId(ref ConcretizeCtx ctx, ConcreteStruct* funStruct, ConcreteLambdaImpl impl) =>
	nextLambdaImplIdInner(ctx.alloc, impl, getOrAdd(ctx.alloc, ctx.lambdaStructToImpls, funStruct, () =>
		MutArr!ConcreteLambdaImpl()));
size_t nextLambdaImplIdInner(ref Alloc alloc, ConcreteLambdaImpl impl, ref MutArr!ConcreteLambdaImpl impls) {
	size_t res = mutArrSize(impls);
	push(alloc, impls, impl);
	return res;
}

public size_t ensureVariantMember(
	ref ConcretizeCtx ctx,
	ConcreteType variantType,
	VariantMember* member,
	ConcreteType type,
) {
	MutArr!ConcreteVariantMember* members = &mustGet(ctx.variantStructToMembers, mustBeByVal(variantType));
	Opt!size_t found = findIndex!ConcreteVariantMember(asTemporaryArray(*members), (in ConcreteVariantMember x) =>
		x.member == member && x.type == type);
	return optOrDefault!size_t(found, () {
		size_t res = mutArrSize(*members);
		push(ctx.alloc, *members, ConcreteVariantMember(member, type));
		return res;
	});
}

ConcreteLocal* makeLocalWorker(ref ConcretizeExprCtx ctx, Local* source, ConcreteType type) =>
	allocate(ctx.alloc, ConcreteLocal(ConcreteLocalSource(source), type));

ConcreteLocal* concretizeLocal(ref ConcretizeExprCtx ctx, Local* local) =>
	makeLocalWorker(ctx, local, getConcreteType(ctx, local.type));

alias Locals = StackMap!(Local*, LocalOrConstant);
alias addLocal = stackMapAdd!(Local*, LocalOrConstant);
alias getLocal = stackMapMustGet!(Local*, LocalOrConstant);

ConcreteExpr concretizeLet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref LetExpr e,
) {
	ConcreteType localType = getConcreteType(ctx, e.destructure.type);
	return concretizeWithDestructureAndLet(
			ctx, type, range, locals, e.destructure,
			concretizeExpr(ctx, localType, locals, e.value),
			(in Locals innerLocals) =>
				concretizeExpr(ctx, type, innerLocals, e.then));
}

RootLocalAndExpr concretizeExprWithDestructure(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref Destructure destructure,
	ref Expr expr,
) =>
	concretizeWithDestructure(ctx, type, range, locals, destructure, (in Locals innerLocals) =>
		concretizeExpr(ctx, type, innerLocals, expr));

struct RootLocalAndExpr {
	Opt!(ConcreteLocal*) rootLocal;
	ConcreteExpr expr;
}

ConcreteExpr concretizeWithDestructureAndLet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref Destructure destructure,
	ConcreteExpr value,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) {
	RootLocalAndExpr then = concretizeWithDestructure(ctx, type, range, locals, destructure, cb);
	if (has(then.rootLocal))
		return ConcreteExpr(type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.Let(force(then.rootLocal), value, then.expr))));
	else {
		if (value.kind.isA!Constant)
			return then.expr;
		else {
			ConcreteExpr drop = ConcreteExpr(voidType(ctx), range, ConcreteExprKind(
				allocate(ctx.alloc, ConcreteExprKind.Drop(value))));
			return ConcreteExpr(type, range, ConcreteExprKind(
				allocate(ctx.alloc, ConcreteExprKind.Seq(drop, then.expr))));
		}
	}
}

RootLocalAndExpr concretizeWithDestructure(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref Destructure destructure,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) =>
	destructure.matchWithPointers!RootLocalAndExpr(
		(Destructure.Ignore*) {
			ConcreteExpr then = cb(locals);
			return RootLocalAndExpr(none!(ConcreteLocal*), then);
		},
		(Local* local) {
			ConcreteLocal* concreteLocal = concretizeLocal(ctx, local);
			ConcreteExpr then = cb(addLocal(locals, local, LocalOrConstant(concreteLocal)));
			return RootLocalAndExpr(some(concreteLocal), then);
		},
		(Destructure.Split* x) {
			if (x.destructuredType.isBogus)
				return RootLocalAndExpr(none!(ConcreteLocal*), concretizeBogus(ctx, type, range));
			else {
				ConcreteLocal* temp = allocate(ctx.alloc, ConcreteLocal(
					ConcreteLocalSource(ConcreteLocalSource.Generated.destruct),
					getConcreteType(ctx, destructure.type)));
				return RootLocalAndExpr(
					some(temp),
					concretizeWithDestructureSplit(ctx, type, range, locals, *x, temp, cb));
			}
		});

ConcreteExpr concretizeWithDestructureSplit(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	in Destructure.Split split,
	ConcreteLocal* destructured,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) =>
	concretizeWithDestructurePartsRecur(
		ctx, type, locals, allocate(ctx.alloc, genLocalGet(range, destructured)), split.parts, 0, cb);
ConcreteExpr concretizeWithDestructurePartsRecur(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in Locals locals,
	ConcreteExpr* getTemp,
	in Destructure[] parts,
	size_t partIndex,
	in ConcreteExpr delegate(in Locals) @safe @nogc pure nothrow cb,
) {
	if (partIndex == parts.length)
		return cb(locals);
	else {
		Destructure part = parts[partIndex];
		UriAndRange range = toUriAndRange(ctx, part.range);
		ConcreteType valueType = mustBeByVal(getTemp.type).body_.as!(ConcreteStructBody.Record).fields[partIndex].type;
		ConcreteType expectedType = getConcreteType(ctx, part.type);
		if (expectedType == valueType) {
			ConcreteExpr value = ConcreteExpr(valueType, range, isVoid(valueType)
				? ConcreteExprKind(constantZero)
				: ConcreteExprKind(ConcreteExprKind.RecordFieldGet(getTemp, partIndex)));
			return concretizeWithDestructureAndLet(ctx, type, range, locals, part, value, (in Locals innerLocals) =>
				concretizeWithDestructurePartsRecur(ctx, type, innerLocals, getTemp, parts, partIndex + 1, cb));
		} else
			return concretizeBogus(ctx, type, range);
	}
}

ConcreteExpr concretizeIf(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref IfExpr a,
) =>
	a.condition.match!ConcreteExpr(
		(ref Expr x) {
			ConcreteExpr cond = concretizeExpr(ctx, boolType(ctx), locals, x);
			return cond.kind.isA!Constant
				? concretizeExpr(ctx, type, locals, asBool(cond.kind.as!Constant) ? a.trueBranch : a.falseBranch)
				: ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
					ConcreteExprKind.If(
						cond,
						concretizeExpr(ctx, type, locals, a.trueBranch),
						concretizeExpr(ctx, type, locals, a.falseBranch)))));
		},
		(ref Condition.UnpackOption x) =>
			genIfOption(
				ctx.alloc, range, concretizeExpr(ctx, locals, x.option),
				concretizeExprWithDestructure(ctx, type, range, locals, x.destructure, a.trueBranch),
				concretizeExpr(ctx, type, locals, a.falseBranch)));

ConcreteExpr genIfOption(
	ref Alloc alloc,
	in UriAndRange range,
	ConcreteExpr option,
	RootLocalAndExpr then,
	ConcreteExpr else_,
) =>
	ConcreteExpr(else_.type, range, ConcreteExprKind(
		allocate(alloc, ConcreteExprKind.MatchUnion(
			option,
			integralValuesRange(2),
			newSmallArray!(ConcreteExprKind.MatchUnion.Case)(alloc, [
				ConcreteExprKind.MatchUnion.Case(none!(ConcreteLocal*), else_),
				ConcreteExprKind.MatchUnion.Case(then.rootLocal, then.expr)]),
			none!(ConcreteExpr*)))));

ConcreteExpr concretizeLiteralStringLike(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	LiteralStringLikeExpr.Kind kind,
	string value,
) {
	final switch (kind) {
		case LiteralStringLikeExpr.Kind.char8Array:
			return genChar8Array(ctx.concretizeCtx, range, value);
		case LiteralStringLikeExpr.Kind.char8List:
			return genChar8List(ctx.concretizeCtx, type, range, value);
		case LiteralStringLikeExpr.Kind.char32Array:
			return genChar32Array(ctx.concretizeCtx, range, value);
		case LiteralStringLikeExpr.Kind.char32List:
			return genChar32List(ctx.concretizeCtx, type, range, value);
		case LiteralStringLikeExpr.Kind.cString:
			return ConcreteExpr(type, range, ConcreteExprKind(constantCString(ctx.concretizeCtx, value)));
		case LiteralStringLikeExpr.Kind.string_:
			return genStringLiteral(ctx.concretizeCtx, range, value);
		case LiteralStringLikeExpr.Kind.symbol:
			return ConcreteExpr(type, range, ConcreteExprKind(
				constantSymbol(ctx.concretizeCtx, symbolOfString(value))));
	}
}

ConcreteExpr concretizeLocalGet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	Local* local,
) {
	LocalOrConstant concrete = castNonScope_ref(getLocal(locals, local));
	return concrete.matchWithPointers!ConcreteExpr(
		(ConcreteLocal* x) =>
			isBogus(x.type)
				? concretizeBogus(ctx, type, range)
				: genLocalGet(range, x),
		(TypedConstant x) =>
			ConcreteExpr(type, range, ConcreteExprKind(x.value)));
}

ConcreteExpr concretizePtrToLocal(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	in PtrToLocalExpr a,
) {
	ConcreteExprKind kind = castNonScope_ref(getLocal(locals, a.local)).matchWithPointers!ConcreteExprKind(
		(ConcreteLocal* local) =>
			ConcreteExprKind(ConcreteExprKind.PtrToLocal(local)),
		(TypedConstant x) =>
			//TODO: what if pointee is a reference?
			ConcreteExprKind(getConstantPointer(ctx.alloc, ctx.allConstants, mustBeByVal(x.type), x.value)));
	return ConcreteExpr(type, range, kind);
}

ConcreteExpr concretizePtrToField(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref PtrToFieldExpr a,
) =>
	ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.PtrToField(concretizeExpr(ctx, locals, a.target), a.fieldIndex))));

ConcreteExpr concretizeLocalSet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	LocalSetExpr a,
) {
	ConcreteLocal* local = getLocal(locals, a.local).as!(ConcreteLocal*);
	ConcreteExpr value = concretizeExpr(ctx, local.type, locals, *a.value);
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.LocalSet(castNonScope(local), value))));
}

ConcreteExpr concretizeLoopWhileOrUntil(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref LoopWhileOrUntilExpr expr,
) {
	ConcreteExpr doAndContinue(ConcreteExpr x) =>
		genDoAndContinue(ctx.alloc, type, range, x);
	ConcreteExpr breakWith(ConcreteExpr x) =>
		genBreak(ctx.alloc, range, x);
	return expr.condition.match!ConcreteExpr(
		(ref Expr x) {
			/*
			while cond
				body
			after
			==>
			loop
				if cond
					body
					continue
				else
					break after
			*/
			ConcreteExpr condition = concretizeExpr(ctx, boolType(ctx), locals, x);
			ConcreteExpr doAndContinue = doAndContinue(concretizeExpr(ctx, voidType(ctx), locals, expr.body_));
			ConcreteExpr break_ = breakWith(concretizeExpr(ctx, type, locals, expr.after));
			ConcreteExprKind.If if_ = expr.isUntil
				? ConcreteExprKind.If(condition, break_, doAndContinue)
				: ConcreteExprKind.If(condition, doAndContinue, break_);
			return genLoop(ctx, type, range, ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc, if_))));
		},
		(ref Condition.UnpackOption unpack) {
			IfOptionBranches branches = () {
				if (expr.isUntil) {
					/*
					until x ?= xs
						body
					after
					==>
					loop
						if x ?= xs
							break after
						else
							body
							continue
					*/
					RootLocalAndExpr after = concretizeExprWithDestructure(
						ctx, type, range, locals, unpack.destructure, expr.after);
					return IfOptionBranches(
						after.rootLocal, breakWith(after.expr),
						doAndContinue(concretizeExpr(ctx, voidType(ctx), locals, expr.body_)));
				} else {
					/*
					while x ?= xs
						body
					after
					==>
					loop
						if x ?= xs
							body
							continue
						else
							break after
					*/
					RootLocalAndExpr body_ = concretizeExprWithDestructure(
						ctx, voidType(ctx), range, locals, unpack.destructure, expr.body_);
					return IfOptionBranches(
						body_.rootLocal, doAndContinue(body_.expr),
						breakWith(concretizeExpr(ctx, type, locals, expr.after)));
				}
			}();
			return genLoop(ctx, type, range, genIfOption(
				ctx.alloc, range,
				concretizeExpr(ctx, locals, unpack.option),
				RootLocalAndExpr(branches.rootLocal, branches.some),
				branches.none));
		});
}
immutable struct IfOptionBranches {
	Opt!(ConcreteLocal*) rootLocal;
	ConcreteExpr some;
	ConcreteExpr none;
}

ConcreteExpr genLoop(ref ConcretizeExprCtx ctx, ConcreteType type, in UriAndRange range, ConcreteExpr body_) =>
	ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Loop(body_))));

ConcreteExpr genDoAndContinue(ref Alloc alloc, ConcreteType type, in UriAndRange range, ConcreteExpr a) =>
	genSeq(alloc, range, a, genContinue(type, range));

ConcreteExpr genSeq(ref Alloc alloc, in UriAndRange range, ConcreteExpr a, ConcreteExpr b) {
	assert(isVoid(a.type));
	return ConcreteExpr(b.type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.Seq(a, b))));
}

ConcreteExpr genContinue(ConcreteType type, in UriAndRange range) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.LoopContinue()));

ConcreteExpr genBreak(ref Alloc alloc, in UriAndRange range, ConcreteExpr value) =>
	ConcreteExpr(value.type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.LoopBreak(value))));

ConcreteExpr concretizeMatchEnum(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref MatchEnumExpr a,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, a.matched);
	IntegralValues values = mapToIntegralValues!(MatchEnumExpr.Case)(a.cases, (ref MatchEnumExpr.Case x) =>
		x.member.value);
	// TODO: If matched is a constant, just compile the relevant case
	ConcreteExpr[] cases = map(ctx.alloc, values, (ref IntegralValue value) =>
		concretizeExpr(
			ctx, type, locals,
			mustFind!(MatchEnumExpr.Case)(a.cases, (ref MatchEnumExpr.Case x) => x.member.value == value).then));
	Opt!(ConcreteExpr*) else_ = optIf(has(a.else_), () =>
		allocate(ctx.alloc, concretizeExpr(ctx, type, locals, force(a.else_))));
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.MatchEnumOrIntegral(matched, values, cases, else_))));
}

ConcreteExpr concretizeMatchIntegral(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref MatchIntegralExpr a,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, a.matched);
	IntegralValues values = mapToIntegralValues!(MatchIntegralExpr.Case)(a.cases, (ref MatchIntegralExpr.Case x) =>
		x.value);
	// TODO: If matched is a constant, just compile the relevant case
	ConcreteExpr[] cases = map(ctx.alloc, values, (ref IntegralValue value) =>
		concretizeExpr(
			ctx, type, locals,
			mustFind!(MatchIntegralExpr.Case)(a.cases, (ref MatchIntegralExpr.Case x) => x.value == value).then));
	Opt!(ConcreteExpr*) else_ = some(allocate(ctx.alloc, concretizeExpr(ctx, type, locals, a.else_)));
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.MatchEnumOrIntegral(matched, values, cases, else_))));
}

ConcreteExpr concretizeMatchStringLike(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref MatchStringLikeExpr a,
) {
	Opt!(ConcreteFun*) equals = getConcreteFunFromCalled(ctx, a.equals);
	if (!has(equals)) return concretizeBogus(ctx, type, range);

	ConcreteExpr matched = concretizeExpr(ctx, locals, a.matched);
	SmallArray!(ConcreteExprKind.MatchStringLike.Case) cases = map(
		ctx.alloc, a.cases, (ref MatchStringLikeExpr.Case case_) =>
			ConcreteExprKind.MatchStringLike.Case(
				concretizeLiteralStringLike(ctx, matched.type, range, a.kind, case_.value),
				concretizeExpr(ctx, type, locals, case_.then)));
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.MatchStringLike(matched, force(equals), cases, concretizeExpr(ctx, type, locals, a.else_)))));
}

ConcreteExpr concretizeMatchUnion(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref MatchUnionExpr a,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, a.matched);
	IntegralValues values = mapToIntegralValues!(MatchUnionExpr.Case)(a.cases, (ref MatchUnionExpr.Case x) =>
		IntegralValue(x.member.memberIndex));
	SmallArray!(ConcreteExprKind.MatchUnion.Case) cases = map(ctx.alloc, values, (ref IntegralValue value) {
		MatchUnionExpr.Case case_ = mustFind!(MatchUnionExpr.Case)(a.cases, (ref MatchUnionExpr.Case x) =>
			IntegralValue(x.member.memberIndex) == value);
		return toMatchUnionCase(concretizeExprWithDestructure(ctx, type, range, locals, case_.destructure, case_.then));
	});
	Opt!(ConcreteExpr*) else_ = optIf(has(a.else_), () =>
		allocate(ctx.alloc, concretizeExpr(ctx, type, locals, *force(a.else_))));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.MatchUnion(matched, values, cases, else_))));
}

ConcreteExpr concretizeMatchVariant(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref MatchVariantExpr a,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, a.matched);
	ValuesAndCases vc = concretizeMatchVariantCases(ctx, type, range, locals, matched.type, a.cases);
	ConcreteExpr* else_ = allocate(ctx.alloc, concretizeExpr(ctx, type, locals, a.else_));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.MatchUnion(matched, vc.values, vc.cases, some(else_)))));
}

immutable struct ValuesAndCases {
	IntegralValues values;
	SmallArray!(ConcreteExprKind.MatchUnion.Case) cases;
}
ValuesAndCases concretizeMatchVariantCases(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ConcreteType variantType,
	in MatchVariantExpr.Case[] cases,
) {
	IntegralValues values = mapToIntegralValues!(MatchVariantExpr.Case)(cases, (ref MatchVariantExpr.Case x) =>
		memberIndexForMatchVariantCase(ctx, variantType, x));
	SmallArray!(ConcreteExprKind.MatchUnion.Case) concreteCases = map(ctx.alloc, values, (ref IntegralValue value) {
		MatchVariantExpr.Case case_ = mustFind!(MatchVariantExpr.Case)(cases, (ref MatchVariantExpr.Case x) =>
			memberIndexForMatchVariantCase(ctx, variantType, x) == value);
		return toMatchUnionCase(concretizeExprWithDestructure(ctx, type, range, locals, case_.destructure, case_.then));
	});
	return ValuesAndCases(values, concreteCases);
}

ConcreteExprKind.MatchUnion.Case toMatchUnionCase(RootLocalAndExpr x) =>
	ConcreteExprKind.MatchUnion.Case(x.rootLocal, x.expr);

IntegralValue memberIndexForMatchVariantCase(
	ref ConcretizeExprCtx ctx,
	ConcreteType variantType,
	ref MatchVariantExpr.Case a,
) =>
	IntegralValue(ensureVariantMember(
		ctx.concretizeCtx, variantType, a.member, getConcreteType(ctx, a.destructure.type)));

ConcreteVariableRef concretizeVariableRefForClosure(
	ref ConcretizeExprCtx ctx,
	in UriAndRange range,
	in Locals locals,
	VariableRef a,
) =>
	a.matchWithPointers!ConcreteVariableRef(
		(Local* x) =>
			getLocal(locals, x).matchWithPointers!ConcreteVariableRef(
				(ConcreteLocal* local) =>
					ConcreteVariableRef(local),
				(TypedConstant constant) =>
					ConcreteVariableRef(constant.value)),
		(ClosureRef x) =>
			ConcreteVariableRef(getClosureFieldInfo(ctx, range, x).closureRef));

ConcreteExpr concretizeAssertOrForbid(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	in Expr expr,
	ref AssertOrForbidExpr a,
) {
	ConcreteExpr defaultThrown() =>
		genError(ctx, range, defaultAssertOrForbidMessage(ctx, expr, a));
	ConcreteExpr throwNoDestructure() =>
		genThrow(ctx.alloc, type, range, has(a.thrown)
			? concretizeExpr(ctx, exceptionType(ctx.concretizeCtx), locals, *force(a.thrown))
			: defaultThrown());

	return a.condition.match!ConcreteExpr(
		(ref Expr x) {
			ConcreteExpr condition = concretizeExpr(ctx, boolType(ctx), locals, x);
			ConcreteExpr throw_ = throwNoDestructure();
			ConcreteExpr after = concretizeExpr(ctx, type, locals, a.after);
			return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc, a.isForbid
				? ConcreteExprKind.If(condition, throw_, after)
				: ConcreteExprKind.If(condition, after, throw_))));
		},
		(ref Condition.UnpackOption x) {
			ConcreteExpr option = concretizeExpr(ctx, locals, x.option);
			if (a.isForbid) {
				RootLocalAndExpr thrown = has(a.thrown)
					? concretizeExprWithDestructure(
						ctx, exceptionType(ctx.concretizeCtx), range, locals, x.destructure, *force(a.thrown))
					: RootLocalAndExpr(none!(ConcreteLocal*), defaultThrown());
				ConcreteExpr after = concretizeExpr(ctx, type, locals, a.after);
				return genIfOption(
					ctx.alloc, range, option,
					RootLocalAndExpr(thrown.rootLocal, genThrow(ctx.alloc, type, range, thrown.expr)),
					after);
			} else {
				return genIfOption(
					ctx.alloc, range, option,
					concretizeExprWithDestructure(ctx, type, range, locals, x.destructure, a.after),
					throwNoDestructure());
			}
		});
}

immutable struct PrefixAndRange {
	string prefix;
	Range range;
}
string defaultAssertOrForbidMessage(ref ConcretizeExprCtx ctx, in Expr expr, in AssertOrForbidExpr a) {
	PrefixAndRange x = expr.ast.kind.as!AssertOrForbidAst.condition.match!PrefixAndRange(
		(ref ExprAst condition) =>
			PrefixAndRange(
				a.isForbid ? "Forbidden expression is true: " : "Asserted expression is false: ",
				expr.ast.kind.as!AssertOrForbidAst.condition.range),
		(ref ConditionAst.UnpackOption unpack) =>
			PrefixAndRange(
				a.isForbid ? "Forbidden option is non-empty: " : "Asserted option is empty: ",
				unpack.option.range));
	string exprText = ctx.concretizeCtx.fileContentGetters.getSourceText(ctx.curUri, x.range);
	return concatenate(ctx.alloc, x.prefix, exprText);
}

ConcreteExpr concretizeExpr(ref ConcretizeExprCtx ctx, in Locals locals, ref ExprAndType a) =>
	concretizeExpr(ctx, getConcreteType(ctx, a.type), locals, a.expr);

ConcreteExpr concretizeExpr(ref ConcretizeExprCtx ctx, ConcreteType type, in Locals locals, ref Expr a) {
	UriAndRange range = UriAndRange(ctx.curUri, a.range);
	if (isBogus(type))
		return concretizeBogus(ctx, type, range);
	return a.kind.match!ConcreteExpr(
		(ref AssertOrForbidExpr x) =>
			concretizeAssertOrForbid(ctx, type, range, locals, a, x),
		(BogusExpr) =>
			concretizeBogus(ctx, type, range),
		(CallExpr x) =>
			concretizeCall(ctx, type, range, locals, x),
		(ref CallOptionExpr x) =>
			concretizeCallOption(ctx, type, range, locals, x),
		(ClosureGetExpr x) =>
			concretizeClosureGet(ctx, type, range, x),
		(ClosureSetExpr x) =>
			concretizeClosureSet(ctx, type, range, locals, x),
		(ref FinallyExpr x) =>
			concretizeFinally(ctx, type, range, locals, x),
		(FunPointerExpr x) =>
			concretizeFunPointer(ctx, type, range, x),
		(ref IfExpr x) =>
			concretizeIf(ctx, type, range, locals, x),
		(ref LambdaExpr x) =>
			concretizeLambda(ctx, type, range, locals, ptrTrustMe(x)), // TODO: use matchWithPointers --------------------------------------------
		(ref LetExpr x) =>
			concretizeLet(ctx, type, range, locals, x),
		(LiteralExpr x) =>
			ConcreteExpr(type, range, ConcreteExprKind(x.value)),
		(LiteralStringLikeExpr x) =>
			concretizeLiteralStringLike(ctx, type, range, x.kind, x.value),
		(LocalGetExpr x) =>
			concretizeLocalGet(ctx, type, range, locals, x.local),
		(LocalSetExpr x) =>
			concretizeLocalSet(ctx, type, range, locals, x),
		(ref LoopExpr x) =>
			genLoop(ctx, type, range, concretizeExpr(ctx, type, locals, x.body_)),
		(ref LoopBreakExpr x) =>
			genBreak(ctx.alloc, range, concretizeExpr(ctx, type, locals, x.value)),
		(LoopContinueExpr) =>
			genContinue(type, range),
		(ref LoopWhileOrUntilExpr x) =>
			concretizeLoopWhileOrUntil(ctx, type, range, locals, x),
		(ref MatchEnumExpr x) =>
			concretizeMatchEnum(ctx, type, range, locals, x),
		(ref MatchIntegralExpr x) =>
			concretizeMatchIntegral(ctx, type, range, locals, x),
		(ref MatchStringLikeExpr x) =>
			concretizeMatchStringLike(ctx, type, range, locals, x),
		(ref MatchUnionExpr x) =>
			concretizeMatchUnion(ctx, type, range, locals, x),
		(ref MatchVariantExpr x) =>
			concretizeMatchVariant(ctx, type, range, locals, x),
		(ref PtrToFieldExpr x) =>
			concretizePtrToField(ctx, type, range, locals, x),
		(PtrToLocalExpr x) =>
			concretizePtrToLocal(ctx, type, range, locals, x),
		(ref SeqExpr x) {
			ConcreteExpr first = concretizeExpr(ctx, voidType(ctx), locals, x.first);
			ConcreteExpr then = concretizeExpr(ctx, type, locals, x.then);
			return first.kind.isA!Constant
				? then
				: ConcreteExpr(type, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.Seq(first, then))));
		},
		(ref ThrowExpr x) =>
			ConcreteExpr(type, range, ConcreteExprKind(
				allocate(ctx.alloc, ConcreteExprKind.Throw(
					concretizeExpr(ctx, exceptionType(ctx.concretizeCtx), locals, x.thrown))))),
		(ref TrustedExpr x) =>
			concretizeExpr(ctx, type, locals, x.inner),
		(ref TryExpr x) =>
			concretizeTry(ctx, type, range, locals, x),
		(ref TryLetExpr x) =>
			concretizeTryLet(ctx, type, range, locals, x),
		(ref TypedExpr x) =>
			concretizeExpr(ctx, type, locals, x.inner));
}

ConstantsOrExprs constantsOrExprsArr(
	ref ConcretizeExprCtx ctx,
	in UriAndRange range,
	ConcreteType arrayType,
	ConstantsOrExprs args,
) =>
	args.match!ConstantsOrExprs(
		(Constant[] constants) =>
			ConstantsOrExprs(newArray!Constant(ctx.alloc, [
				getConstantArray(ctx.alloc, ctx.allConstants, mustBeByVal(arrayType), constants)])),
		(ConcreteExpr[] exprs) =>
			ConstantsOrExprs(newArray!ConcreteExpr(ctx.alloc, [
				ConcreteExpr(arrayType, range, ConcreteExprKind(ConcreteExprKind.CreateArray(exprs)))])));

Opt!Constant tryEvalConstant(
	in ConcreteFun fn,
	in Constant[] /*parameters*/,
	in VersionInfo versionInfo,
) =>
	fn.body_.matchIn!(Opt!Constant)(
		(in ConcreteFunBody.Builtin x) {
			return x.kind.isA!VersionFun
				? some(constantBool(isVersion(versionInfo, x.kind.as!VersionFun)))
				: none!Constant;
		},
		(in Constant x) =>
			some(x),
		(in ConcreteFunBody.CreateRecord) => none!Constant,
		(in ConcreteFunBody.CreateUnion) => none!Constant,
		(in EnumFunction _) => none!Constant,
		(in ConcreteFunBody.Extern) => none!Constant,
		(in ConcreteExpr x) =>
			x.kind.isA!Constant
				? some(x.kind.as!Constant)
				: none!Constant,
		(in ConcreteFunBody.FlagsFn) => none!Constant,
		(in ConcreteFunBody.RecordFieldCall) => none!Constant,
		(in ConcreteFunBody.RecordFieldGet) => none!Constant,
		(in ConcreteFunBody.RecordFieldPointer) => none!Constant,
		(in ConcreteFunBody.RecordFieldSet) => none!Constant,
		(in ConcreteFunBody.VarGet) => none!Constant,
		(in ConcreteFunBody.VarSet) => none!Constant);

ConcreteExpr concretizeFinally(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref FinallyExpr a,
) =>
	ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.Finally(
			concretizeExpr(ctx, voidType(ctx), locals, a.right),
			concretizeExpr(ctx, type, locals, a.below)))));

ConcreteExpr concretizeTry(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref TryExpr a,
) {
	ConcreteExpr tried = concretizeExpr(ctx, type, locals, a.tried);
	ValuesAndCases vc = concretizeMatchVariantCases(
		ctx, type, range, locals, exceptionType(ctx.concretizeCtx), a.catches);
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.Try(tried, vc.values, vc.cases))));
}

ConcreteExpr concretizeTryLet(
	ref ConcretizeExprCtx ctx,
	ConcreteType type,
	in UriAndRange range,
	in Locals locals,
	ref TryLetExpr a,
) {
	/*
	try x, y = some-pair catch foo : caught
	then
	==>
	try pair = some-pair catch foo : caught
	x, y = pair
	then
	*/
	ConcreteType localType = getConcreteType(ctx, a.destructure.type);
	ConcreteExpr value = concretizeExpr(ctx, localType, locals, a.value);
	IntegralValue catchMemberIndex = memberIndexForMatchVariantCase(ctx, exceptionType(ctx.concretizeCtx), a.catch_);
	ConcreteExprKind.MatchUnion.Case catchExpr = toMatchUnionCase(
		concretizeExprWithDestructure(ctx, type, range, locals, a.catch_.destructure, a.catch_.then));
	RootLocalAndExpr then = concretizeExprWithDestructure(
		ctx, type, range, locals, a.destructure, a.then);
	return ConcreteExpr(type, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.TryLet(then.rootLocal, value, catchMemberIndex, catchExpr, then.expr))));
}
