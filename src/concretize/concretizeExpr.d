module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : AllConstantsBuilder, getConstantArr, getConstantPtr;
import concretize.concretizeCtx :
	ConcretizeCtx,
	ConcreteFunKey,
	concreteTypeFromClosure,
	concretizeParams,
	constantCStr,
	constantSym,
	ContainingFunInfo,
	getOrAddNonTemplateConcreteFunAndFillBody,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteType_forStructInst_fromConcretizeCtx = getConcreteType_forStructInst,
	getConcreteFunForLambdaAndFillBody,
	getOrAddConcreteFunAndFillBody,
	cStrType,
	symType,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes,
	voidType;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs;
import model.concreteModel :
	body_,
	byRef,
	byVal,
	ConcreteClosureRef,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteMutability,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	ConcreteVariableRef,
	isSummon,
	isVariadic,
	mustBeByVal,
	name,
	purity,
	ReferenceKind,
	returnType;
import model.constant : asBool, Constant, constantBool, constantZero;
import model.model :
	AssertOrForbidKind,
	Called,
	ClosureRef,
	ClosureReferenceKind,
	debugName,
	EnumFunction,
	Expr,
	ExprKind,
	FunInst,
	FunKind,
	getClosureReferenceKind,
	Local,
	LocalMutability,
	Param,
	Purity,
	range,
	specImpls,
	SpecSig,
	StructInst,
	Type,
	typeArgs,
	VariableRef,
	variableRefType;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, only, PtrAndSmallNumber;
import util.col.arrUtil : arrLiteral, map, mapZip;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutDict : getOrAdd;
import util.col.stackDict : StackDict2, stackDict2Add0, stackDict2Add1, stackDict2MustGet0, stackDict2MustGet1;
import util.col.str : SafeCStr, safeCStr;
import util.memory : allocate, overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.util : todo, unreachable, verify;
import versionInfo : VersionInfo;

ConcreteExpr concretizeExpr(ref ConcretizeCtx ctx, ref ContainingFunInfo containing, ConcreteFun* cf, ref Expr e) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe(ctx), containing, cf);
	Locals locals;
	return concretizeExpr(exprCtx, locals, e);
}

private:

struct ConcretizeExprCtx {
	@safe @nogc pure nothrow:

	ConcretizeCtx* concretizeCtxPtr;
	immutable ContainingFunInfo containing;
	immutable ConcreteFun* currentConcreteFunPtr; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;

	ref Alloc alloc() return scope =>
		concretizeCtx.alloc;

	ref inout(ConcretizeCtx) concretizeCtx() return scope inout =>
		*concretizeCtxPtr;

	ref ConcreteFun currentConcreteFun() return scope const =>
		*currentConcreteFunPtr;

	ref inout(AllConstantsBuilder) allConstants() return scope inout =>
		concretizeCtx.allConstants;
}

immutable struct TypedConstant {
	ConcreteType type;
	Constant value;
}

immutable struct LocalOrConstant {
	mixin Union!(ConcreteLocal*, TypedConstant);
}

ConcreteType getConcreteType(ref ConcretizeExprCtx ctx, in Type t) =>
	getConcreteType_fromConcretizeCtx(ctx.concretizeCtx, t, typeScope(ctx));

ConcreteType getConcreteType_forStructInst(ref ConcretizeExprCtx ctx, StructInst* i) =>
	getConcreteType_forStructInst_fromConcretizeCtx(ctx.concretizeCtx, i, typeScope(ctx));

ConcreteType[] typesToConcreteTypes(ref ConcretizeExprCtx ctx, in Type[] typeArgs) =>
	typesToConcreteTypes_fromConcretizeCtx(ctx.concretizeCtx, typeArgs, typeScope(ctx));

TypeArgsScope typeScope(ref ConcretizeExprCtx ctx) =>
	typeArgsScope(ctx.containing);

ConcreteExpr concretizeCall(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	in ExprKind.Call e,
) {
	ConcreteFun* concreteCalled = getConcreteFunFromCalled(ctx, e.called);
	ConstantsOrExprs args =
		empty(e.args) || (!isSummon(*concreteCalled) && purity(concreteCalled.returnType) == Purity.data)
			? getConstantsOrExprs(ctx, locals, e.args)
			: ConstantsOrExprs(getArgs(ctx, locals, e.args));
	ConstantsOrExprs args2 = isVariadic(*concreteCalled)
		? constantsOrExprsArr(ctx, range, args, only(concreteCalled.paramsExcludingClosure).type)
		: args;
	ConcreteExprKind kind = args2.match!ConcreteExprKind(
		(Constant[] constants) {
			Opt!Constant constant =
				tryEvalConstant(*concreteCalled, constants, ctx.concretizeCtx.versionInfo);
			return has(constant)
				? ConcreteExprKind(force(constant))
				: ConcreteExprKind(ConcreteExprKind.Call(
					concreteCalled,
					mapZip(
						ctx.alloc,
						concreteCalled.paramsExcludingClosure,
						constants,
						(ref ConcreteParam p, ref Constant x) =>
							ConcreteExpr(p.type, FileAndRange.empty, ConcreteExprKind(x)))));
		},
		(ConcreteExpr[] exprs) =>
			ConcreteExprKind(ConcreteExprKind.Call(concreteCalled, exprs)));
	return ConcreteExpr(concreteCalled.returnType, range, kind);
}

ConcreteFun* getConcreteFunFromCalled(ref ConcretizeExprCtx ctx, ref Called called) =>
	called.matchWithPointers!(ConcreteFun*)(
		(FunInst* funInst) =>
			getConcreteFunFromFunInst(ctx, funInst),
		(SpecSig* specSig) =>
			ctx.containing.specImpls[specSig.indexOverAllSpecUses]);

ConcreteFun* getConcreteFunFromFunInst(ref ConcretizeExprCtx ctx, FunInst* funInst) {
	ConcreteType[] typeArgs = typesToConcreteTypes(ctx, typeArgs(*funInst));
	immutable ConcreteFun*[] specImpls = map!(ConcreteFun*, Called)(ctx.alloc, specImpls(*funInst), (ref Called it) =>
		getConcreteFunFromCalled(ctx, it));
	ConcreteFunKey key = ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(ctx.concretizeCtx, key);
}

ConcreteExpr concretizeClosureGet(ref ConcretizeExprCtx ctx, FileAndRange range, in ExprKind.ClosureGet a) {
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	return ConcreteExpr(info.type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.ClosureGet(info.closureRef, info.referenceKind))));
}

ConcreteExpr concretizeClosureSet(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	in ExprKind.ClosureSet a,
) {
	verify(getClosureReferenceKind(*a.closureRef) == ClosureReferenceKind.allocated);
	ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	verify(info.referenceKind == ClosureReferenceKind.allocated);
	ConcreteExpr value = concretizeExpr(ctx, locals, *a.value);
	return ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.ClosureSet(info.closureRef, value))));
}

immutable struct ClosureFieldInfo {
	ConcreteClosureRef closureRef;
	ConcreteType type; //If 'referenceKind' is 'allocated', this is the pointee type 
	ClosureReferenceKind referenceKind;
}
ClosureFieldInfo getClosureFieldInfo(ref ConcretizeExprCtx ctx, FileAndRange range, ClosureRef a) {
	ConcreteParam* closureParam = force(ctx.currentConcreteFun.closureParam);
	ConcreteType closureType = closureParam.type;
	ConcreteStructBody.Record record = body_(*closureType.struct_).as!(ConcreteStructBody.Record);
	ClosureReferenceKind referenceKind = getClosureReferenceKind(a);
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
		ConcreteClosureRef(PtrAndSmallNumber!ConcreteParam(closureParam, a.index)),
		pointeeType,
		referenceKind);
}

ConstantsOrExprs getConstantsOrExprs(ref ConcretizeExprCtx ctx, in Locals locals, in Expr[] argExprs) =>
	asConstantsOrExprs(ctx.alloc, getArgs(ctx, locals, argExprs));

ConcreteExpr[] getArgs(ref ConcretizeExprCtx ctx, in Locals locals, in Expr[] argExprs) =>
	map(ctx.alloc, argExprs, (ref Expr arg) =>
		concretizeExpr(ctx, locals, arg));

ConcreteExpr createAllocExpr(ref Alloc alloc, ConcreteExpr inner) {
	verify(inner.type.reference == ReferenceKind.byVal);
	return ConcreteExpr(
		byRef(inner.type),
		inner.range,
		ConcreteExprKind(allocate(alloc, ConcreteExprKind.Alloc(inner))));
}

ConcreteExpr getCurExclusion(ref ConcretizeExprCtx ctx, ConcreteType type, FileAndRange range) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.Call(ctx.concretizeCtx.curExclusionFun, [])));

ConcreteField[] concretizeClosureFields(ref ConcretizeCtx ctx, VariableRef[] closure, TypeArgsScope typeArgsScope) =>
	map(ctx.alloc, closure, (ref VariableRef x) {
		ConcreteType baseType = getConcreteType_fromConcretizeCtx(ctx, variableRefType(x), typeArgsScope);
		ConcreteType type = () {
			final switch (getClosureReferenceKind(x)) {
				case ClosureReferenceKind.direct:
					return baseType;
				case ClosureReferenceKind.allocated:
					return addIndirection(baseType);
			}
		}();
		// Even if the variable is mutable, it's a const field holding a mut pointer
		return ConcreteField(debugName(x), ConcreteMutability.const_, type);
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
			return unreachable!ReferenceKind;
	}
}

ConcreteType removeIndirection(ConcreteType a) =>
	ConcreteType(removeIndirection(a.reference), a.struct_);
ReferenceKind removeIndirection(ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return unreachable!ReferenceKind;
		case ReferenceKind.byRef:
			return ReferenceKind.byVal;
		case ReferenceKind.byRefRef:
			return ReferenceKind.byRef;
	}
}

ConcreteExpr concretizeDrop(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.Drop e,
) {
	ConcreteExpr arg = concretizeExpr(ctx, locals, e.arg);
	ConcreteExprKind kind = arg.kind.isA!Constant
		? constantVoidKind()
		: ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Drop(arg)));
	return ConcreteExpr(voidType(ctx.concretizeCtx), range, kind);
}

ConcreteExpr constantVoid(ref ConcretizeCtx ctx, FileAndRange range) =>
	ConcreteExpr(voidType(ctx), range, constantVoidKind());

ConcreteExprKind constantVoidKind() =>
	ConcreteExprKind(constantZero);

ConcreteExpr concretizeFunPtr(ref ConcretizeExprCtx ctx, FileAndRange range, ExprKind.FunPtr e) {
	ConcreteFun* fun = getOrAddNonTemplateConcreteFunAndFillBody(ctx.concretizeCtx, e.funInst);
	ConcreteType concreteType = getConcreteType_forStructInst(ctx, e.structInst);
	return ConcreteExpr(concreteType, range, ConcreteExprKind(Constant(Constant.FunPtr(fun))));
}

ConcreteParam* closureParam(ref Alloc alloc, ConcreteType closureType) =>
	allocate(alloc, ConcreteParam(
		ConcreteParamSource(ConcreteParamSource.Closure()),
		none!size_t,
		closureType));

ConcreteExpr concretizeLambda(ref ConcretizeExprCtx ctx, FileAndRange range, in Locals locals, ref ExprKind.Lambda e) {
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

	//TODO:KILL? (We also have an ID within the type..)
	size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	TypeArgsScope tScope = typeScope(ctx);
	ConcreteParam[] params = concretizeParams(ctx.concretizeCtx, e.params, tScope);

	ConcreteType concreteType = getConcreteType_forStructInst(ctx, e.funType);
	ConcreteStruct* concreteStruct = mustBeByVal(concreteType);

	ConcreteVariableRef[] closureArgs = map(ctx.alloc, e.closure, (ref VariableRef x) =>
		concretizeVariableRefForClosure(ctx, range, locals, x));
	ConcreteField[] closureFields = concretizeClosureFields(ctx.concretizeCtx, e.closure, tScope);
	ConcreteType closureType = concreteTypeFromClosure(
		ctx.concretizeCtx,
		closureFields,
		ConcreteStructSource(ConcreteStructSource.Lambda(ctx.currentConcreteFunPtr, lambdaIndex)));
	ConcreteParam* closureParam = closureParam(ctx.alloc, closureType);
	Opt!(ConcreteExpr*) closure = empty(closureArgs)
		? none!(ConcreteExpr*)
		: some(allocate(ctx.alloc, createAllocExpr(ctx.alloc, ConcreteExpr(
			byVal(closureType),
			range,
			ConcreteExprKind(ConcreteExprKind.ClosureCreate(closureArgs))))));

	ConcreteFun* fun = getConcreteFunForLambdaAndFillBody(
		ctx.concretizeCtx,
		ctx.currentConcreteFunPtr,
		lambdaIndex,
		getConcreteType(ctx, e.returnType),
		closureParam,
		params,
		ctx.containing,
		e.body_);
	ConcreteLambdaImpl impl = ConcreteLambdaImpl(closureType, fun);
	ConcreteExprKind lambda(ConcreteStruct* funStruct) {
		return ConcreteExprKind(ConcreteExprKind.Lambda(nextLambdaImplId(ctx.concretizeCtx, funStruct, impl), closure));
	}
	if (e.kind == FunKind.ref_) {
		// For a fun-ref this is the inner 'act' type.
		ConcreteField[] fields = body_(*concreteStruct).as!(ConcreteStructBody.Record).fields;
		verify(fields.length == 2);
		ConcreteField exclusionField = fields[0];
		verify(exclusionField.debugName == sym!"exclusion");
		ConcreteField actionField = fields[1];
		verify(actionField.debugName == sym!"action");
		ConcreteType funType = actionField.type;
		ConcreteExpr exclusion = getCurExclusion(ctx, exclusionField.type, range);
		return ConcreteExpr(concreteType, range, ConcreteExprKind(
			ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(ctx.alloc, [
				exclusion,
				ConcreteExpr(funType, range, lambda(mustBeByVal(funType)))]))));
	} else
		return ConcreteExpr(concreteType, range, lambda(concreteStruct));
}

public size_t nextLambdaImplId(ref ConcretizeCtx ctx, ConcreteStruct* funStruct, ConcreteLambdaImpl impl) =>
	nextLambdaImplIdInner(ctx.alloc, impl, getOrAdd(ctx.alloc, ctx.funStructToImpls, funStruct, () =>
		MutArr!ConcreteLambdaImpl()));
size_t nextLambdaImplIdInner(ref Alloc alloc, ConcreteLambdaImpl impl, ref MutArr!ConcreteLambdaImpl impls) {
	size_t res = mutArrSize(impls);
	push(alloc, impls, impl);
	return res;
}

ConcreteLocal* makeLocalWorker(ref ConcretizeExprCtx ctx, Local* source, ConcreteType type) =>
	allocate(ctx.alloc, ConcreteLocal(source, type));

ConcreteLocal* concretizeLocal(ref ConcretizeExprCtx ctx, Local* local) =>
	makeLocalWorker(ctx, local, getConcreteType(ctx, local.type));

alias Locals = immutable StackDict2!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias addLocal = stackDict2Add0!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias addLoop = stackDict2Add1!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias getLocal = stackDict2MustGet0!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
//TODO: use an alias
ConcreteExprKind.Loop* getLoop(in Locals locals, ExprKind.Loop* key) =>
	stackDict2MustGet1!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*)(locals, key);

ConcreteExpr concretizeWithLocal(
	ref ConcretizeExprCtx ctx,
	in Locals locals,
	Local* modelLocal,
	in LocalOrConstant concreteLocal,
	ref Expr expr,
) {
	scope Locals newLocals = addLocal(locals, modelLocal, concreteLocal);
	return concretizeExpr(ctx, newLocals, expr);
}

ConcreteExpr concretizeLet(ref ConcretizeExprCtx ctx, FileAndRange range, in Locals locals, ref ExprKind.Let e) {
	ConcreteExpr value = concretizeExpr(ctx, locals, e.value);
	if (e.local.mutability == LocalMutability.immut && value.kind.isA!Constant) {
		LocalOrConstant lc = LocalOrConstant(TypedConstant(value.type, value.kind.as!Constant));
		return concretizeWithLocal(ctx, locals, e.local, lc, e.then);
	} else {
		ConcreteLocal* local = concretizeLocal(ctx, e.local);
		LocalOrConstant lc = LocalOrConstant(local);
		ConcreteExpr then = concretizeWithLocal(ctx, locals, e.local, lc, e.then);
		return ConcreteExpr(then.type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.Let(local, value, then))));
	}
}

ConcreteExpr concretizeIfOption(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.IfOption e,
) {
	ConcreteExpr option = concretizeExpr(ctx, locals, e.option);
	if (option.kind.isA!Constant)
		return todo!ConcreteExpr("constant option");
	else {
		ConcreteType someType = force(body_(*mustBeByVal(option.type)).as!(ConcreteStructBody.Union).members[1]);
		ConcreteType type = getConcreteType(ctx, e.type);
		ConcreteExprKind.MatchUnion.Case noneCase = ConcreteExprKind.MatchUnion.Case(
			none!(ConcreteLocal*),
			concretizeExpr(ctx, locals, e.else_));
		ConcreteLocal* someLocal = makeLocalWorker(ctx, e.local, someType);
		ConcreteExpr then = concretizeWithLocal(ctx, locals, e.local, LocalOrConstant(someLocal), e.then);
		ConcreteExprKind.MatchUnion.Case someCase = ConcreteExprKind.MatchUnion.Case(some(someLocal), then);
		return ConcreteExpr(type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.MatchUnion(
				option,
				arrLiteral!(ConcreteExprKind.MatchUnion.Case)(ctx.alloc, [noneCase, someCase])))));
	}
}

ConcreteExpr concretizeLocalGet(FileAndRange range, in Locals locals, Local* local) =>
	castNonScope_ref(getLocal(locals, local)).matchWithPointers!ConcreteExpr(
		(ConcreteLocal* local) =>
			ConcreteExpr(local.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(local))),
		(TypedConstant x) =>
			ConcreteExpr(x.type, range, ConcreteExprKind(x.value)));

ConcreteExpr concretizePtrToLocal(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ExprKind.PtrToLocal a,
) {
	ConcreteExprKind kind = castNonScope_ref(getLocal(locals, a.local)).matchWithPointers!ConcreteExprKind(
		(ConcreteLocal* local) =>
			ConcreteExprKind(ConcreteExprKind.PtrToLocal(local)),
		(TypedConstant x) =>
			//TODO: what if pointee is a reference?
			ConcreteExprKind(getConstantPtr(ctx.alloc, ctx.allConstants, mustBeByVal(x.type), x.value)));
	return ConcreteExpr(getConcreteType(ctx, a.ptrType), range, kind);
}

ConcreteExpr concretizePtrToField(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.PtrToField a,
) {
	ConcreteExpr target = concretizeExpr(ctx, locals, a.target);
	ConcreteType pointerType = getConcreteType(ctx, a.pointerType);
	return ConcreteExpr(
		pointerType,
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.PtrToField(target, a.fieldIndex))));
}

ConcreteExpr concretizeLocalSet(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LocalSet a,
) {
	ConcreteLocal* local = getLocal(locals, a.local).as!(ConcreteLocal*);
	ConcreteExpr value = concretizeExpr(ctx, locals, a.value);
	return ConcreteExpr(voidType(ctx.concretizeCtx), range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.LocalSet(castNonScope(local), value))));
}

ConcreteExpr concretizeLoop(ref ConcretizeExprCtx ctx, FileAndRange range, in Locals locals, ref ExprKind.Loop a) {
	immutable ConcreteExprKind.Loop* res = allocate(ctx.alloc, ConcreteExprKind.Loop());
	scope Locals localsWithLoop = addLoop(castNonScope_ref(locals), castNonScope(&a), res);
	overwriteMemory(&res.body_, concretizeExpr(ctx, localsWithLoop, a.body_));
	return ConcreteExpr(getConcreteType(ctx, a.type), range, ConcreteExprKind(res));
}

ConcreteExpr concretizeLoopBreak(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopBreak a,
) {
	ConcreteExprKind.Loop* loop = castNonScope(getLoop(locals, a.loop));
	ConcreteExpr value = concretizeExpr(ctx, locals, a.value);
	return ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.LoopBreak(loop, value))));
}

ConcreteExpr concretizeLoopContinue(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	in ExprKind.LoopContinue a,
) {
	ConcreteExprKind.Loop* loop = castNonScope(getLoop(locals, a.loop));
	return ConcreteExpr(voidType(ctx.concretizeCtx), range, ConcreteExprKind(ConcreteExprKind.LoopContinue(loop)));
}

ConcreteExpr concretizeLoopUntil(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopUntil a,
) =>
	concretizeLoopUntilOrWhile(ctx, range, locals, a.condition, a.body_, true);

ConcreteExpr concretizeLoopWhile(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.LoopWhile a,
) =>
	concretizeLoopUntilOrWhile(ctx, range, locals, a.condition, a.body_, false);

ConcreteExpr concretizeLoopUntilOrWhile(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref Expr conditionExpr,
	ref Expr bodyExpr,
	bool isUntil,
) {
	ConcreteExprKind.Loop* res = allocate(ctx.alloc, ConcreteExprKind.Loop());
	ConcreteExpr breakVoid = ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.LoopBreak(res, constantVoid(ctx.concretizeCtx, range)))));
	ConcreteExpr doAndContinue = ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Seq(
			concretizeExpr(ctx, locals, bodyExpr),
			ConcreteExpr(
				voidType(ctx.concretizeCtx),
				range,
				ConcreteExprKind(ConcreteExprKind.LoopContinue(res)))))));
	ConcreteExpr condition = concretizeExpr(ctx, locals, conditionExpr);
	ConcreteExprKind.Cond cond = isUntil
		? ConcreteExprKind.Cond(condition, breakVoid, doAndContinue)
		: ConcreteExprKind.Cond(condition, doAndContinue, breakVoid);
	overwriteMemory(&res.body_, ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		ConcreteExprKind(allocate(ctx.alloc, cond))));
	return ConcreteExpr(voidType(ctx.concretizeCtx), range, ConcreteExprKind(res));
}

ConcreteExpr concretizeMatchEnum(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.MatchEnum e,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	//TODO: If matched is a constant, just compile the relevant case
	ConcreteType type = getConcreteType(ctx, e.type);
	ConcreteExpr[] cases = map(ctx.alloc, e.cases, (ref Expr case_) =>
		concretizeExpr(ctx, locals, case_));
	return ConcreteExpr(type, range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.MatchEnum(matched, cases))));
}

ConcreteExpr concretizeMatchUnion(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	ref ExprKind.MatchUnion e,
) {
	ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	ConcreteType ct = getConcreteType_forStructInst(ctx, e.matchedUnion);
	ConcreteStruct* matchedUnion = mustBeByVal(ct);
	ConcreteType type = getConcreteType(ctx, e.type);
	if (matched.kind.isA!Constant) {
		Constant.Union u = *matched.kind.as!Constant.as!(Constant.Union*);
		ExprKind.MatchUnion.Case case_ = e.cases[u.memberIndex];
		if (has(case_.local)) {
			ConcreteType caseType =
				force(body_(*matchedUnion).as!(ConcreteStructBody.Union).members[u.memberIndex]);
			LocalOrConstant lc = LocalOrConstant(TypedConstant(caseType, u.arg));
			return concretizeWithLocal(ctx, locals, force(case_.local), lc, case_.then);
		} else
			return concretizeExpr(ctx, locals, case_.then);
	} else {
		ConcreteExprKind.MatchUnion.Case[] cases = map(
			ctx.alloc,
			e.cases,
			(ref ExprKind.MatchUnion.Case case_) {
				if (has(case_.local)) {
					ConcreteLocal* local = concretizeLocal(ctx, force(case_.local));
					return ConcreteExprKind.MatchUnion.Case(
						some(local),
						concretizeWithLocal(ctx, locals, force(case_.local), LocalOrConstant(local), case_.then));
				} else
					return ConcreteExprKind.MatchUnion.Case(
						none!(ConcreteLocal*),
						concretizeExpr(ctx, locals, case_.then));
			});
		return ConcreteExpr(type, range, ConcreteExprKind(
			allocate(ctx.alloc, ConcreteExprKind.MatchUnion(matched, cases))));
	}
}

ConcreteParam* getParam(ref ConcretizeExprCtx ctx, in Param param) =>
	&ctx.currentConcreteFun.paramsExcludingClosure[param.index];

ConcreteExpr concretizeParamGet(ref ConcretizeExprCtx ctx, FileAndRange range, in Param param) {
	ConcreteParam* concreteParam = getParam(ctx, param);
	return ConcreteExpr(concreteParam.type, range, ConcreteExprKind(ConcreteExprKind.ParamGet(concreteParam)));
}

ConcreteExpr concretizePtrToParam(ref ConcretizeExprCtx ctx, FileAndRange range, in ExprKind.PtrToParam a) {
	ConcreteParam* concreteParam = &ctx.currentConcreteFun.paramsExcludingClosure[a.param.index];
	return ConcreteExpr(
		getConcreteType(ctx, a.ptrType),
		range,
		ConcreteExprKind(ConcreteExprKind.PtrToParam(concreteParam)));
}

ConcreteVariableRef concretizeVariableRefForClosure(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
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
		(Param* x) =>
			ConcreteVariableRef(getParam(ctx, *x)),
		(ClosureRef x) =>
			ConcreteVariableRef(getClosureFieldInfo(ctx, range, x).closureRef));

ConcreteExpr concretizeThrow(ref ConcretizeExprCtx ctx, FileAndRange range, in Locals locals, ref ExprKind.Throw a) =>
	ConcreteExpr(getConcreteType(ctx, a.type), range, ConcreteExprKind(
		allocate(ctx.alloc, ConcreteExprKind.Throw(concretizeExpr(ctx, locals, a.thrown)))));

ConcreteExpr cStrConcreteExpr(ref ConcretizeCtx ctx, FileAndRange range, SafeCStr value) =>
	ConcreteExpr(cStrType(ctx), range, ConcreteExprKind(constantCStr(ctx, value)));

ConcreteExpr concretizeAssertOrForbid(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	in Locals locals,
	in ExprKind.AssertOrForbid a,
) {
	ConcreteExpr condition = concretizeExpr(ctx, locals, *a.condition);
	ConcreteExpr thrown = has(a.thrown)
		? concretizeExpr(ctx, locals, *force(a.thrown))
		: cStrConcreteExpr(ctx.concretizeCtx, range, defaultAssertOrForbidMessage(a.kind));
	ConcreteExpr void_ = constantVoid(ctx.concretizeCtx, range);
	ConcreteType voidType = voidType(ctx.concretizeCtx);
	ConcreteExpr throw_ = ConcreteExpr(
		voidType,
		range,
		ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Throw(thrown))));
	ConcreteExprKind.Cond cond = () {
		final switch (a.kind) {
			case AssertOrForbidKind.assert_:
				return ConcreteExprKind.Cond(condition, void_, throw_);
			case AssertOrForbidKind.forbid:
				return ConcreteExprKind.Cond(condition, throw_, void_);
		}
	}();
	return ConcreteExpr(voidType, range, ConcreteExprKind(allocate(ctx.alloc, cond)));
}

SafeCStr defaultAssertOrForbidMessage(AssertOrForbidKind a) {
	final switch (a) {
		case AssertOrForbidKind.assert_:
			return safeCStr!"assert failed";
		case AssertOrForbidKind.forbid:
			return safeCStr!"forbid failed";
	}
}

ConcreteExpr concretizeExpr(ref ConcretizeExprCtx ctx, in Locals locals, ref Expr e) {
	FileAndRange range = e.range;
	return e.kind.match!ConcreteExpr(
		(ExprKind.AssertOrForbid x) =>
			concretizeAssertOrForbid(ctx, range, locals, x),
		(ExprKind.Bogus) =>
			unreachable!ConcreteExpr,
		(ExprKind.Call e) =>
			concretizeCall(ctx, range, locals, e),
		(ExprKind.ClosureGet e) =>
			concretizeClosureGet(ctx, range, e),
		(ExprKind.ClosureSet e) =>
			concretizeClosureSet(ctx, range, locals, e),
		(ref ExprKind.Cond e) {
			ConcreteExpr cond = concretizeExpr(ctx, locals, e.cond);
			return cond.kind.isA!Constant
				? concretizeExpr(ctx, locals, asBool(cond.kind.as!Constant) ? e.then : e.else_)
				: ConcreteExpr(
					getConcreteType(ctx, e.type),
					range,
					ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.Cond(
						cond,
						concretizeExpr(ctx, locals, e.then),
						concretizeExpr(ctx, locals, e.else_)))));
		},
		(ref ExprKind.Drop e) =>
			concretizeDrop(ctx, range, locals, e),
		(ExprKind.FunPtr e) =>
			concretizeFunPtr(ctx, range, e),
		(ref ExprKind.IfOption e) =>
			concretizeIfOption(ctx, range, locals, e),
		(ref ExprKind.Lambda e) =>
			concretizeLambda(ctx, range, locals, e),
		(ref ExprKind.Let e) =>
			concretizeLet(ctx, range, locals, e),
		(ref ExprKind.Literal e) =>
			ConcreteExpr(getConcreteType_forStructInst(ctx, e.structInst), range, ConcreteExprKind(e.value)),
		(ExprKind.LiteralCString e) =>
			cStrConcreteExpr(ctx.concretizeCtx, range, e.value),
		(ExprKind.LiteralSymbol e) =>
			ConcreteExpr(
				symType(ctx.concretizeCtx),
				range,
				ConcreteExprKind(constantSym(ctx.concretizeCtx, e.value))),
		(ExprKind.LocalGet e) =>
			concretizeLocalGet(range, locals, e.local),
		(ref ExprKind.LocalSet e) =>
			concretizeLocalSet(ctx, range, locals, e),
		(ref ExprKind.Loop e) =>
			concretizeLoop(ctx, range, locals, e),
		(ref ExprKind.LoopBreak e) =>
			concretizeLoopBreak(ctx, range, locals, e),
		(ExprKind.LoopContinue e) =>
			concretizeLoopContinue(ctx, range, locals, e),
		(ref ExprKind.LoopUntil e) =>
			concretizeLoopUntil(ctx, range, locals, e),
		(ref ExprKind.LoopWhile e) =>
			concretizeLoopWhile(ctx, range, locals, e),
		(ref ExprKind.MatchEnum e) =>
			concretizeMatchEnum(ctx, range, locals, e),
		(ref ExprKind.MatchUnion e) =>
			concretizeMatchUnion(ctx, range, locals, e),
		(ExprKind.ParamGet e) =>
			concretizeParamGet(ctx, range, *e.param),
		(ref ExprKind.PtrToField e) =>
			concretizePtrToField(ctx, range, locals, e),
		(ExprKind.PtrToLocal e) =>
			concretizePtrToLocal(ctx, range, locals, e),
		(ExprKind.PtrToParam e) =>
			concretizePtrToParam(ctx, range, e),
		(ref ExprKind.Seq e) {
			ConcreteExpr first = concretizeExpr(ctx, locals, e.first);
			ConcreteExpr then = concretizeExpr(ctx, locals, e.then);
			return first.kind.isA!Constant
				? then
				: ConcreteExpr(then.type, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.Seq(first, then))));
		},
		(ref ExprKind.Throw e) =>
			concretizeThrow(ctx, range, locals, e));
}

ConstantsOrExprs constantsOrExprsArr(
	ref ConcretizeExprCtx ctx,
	FileAndRange range,
	ConstantsOrExprs args,
	ConcreteType arrayType,
) {
	ConcreteStruct* arrayStruct = mustBeByVal(arrayType);
	return args.match!ConstantsOrExprs(
		(Constant[] constants) =>
			ConstantsOrExprs(arrLiteral!Constant(ctx.alloc, [
				getConstantArr(ctx.alloc, ctx.allConstants, arrayStruct, constants)])),
		(ConcreteExpr[] exprs) =>
			ConstantsOrExprs(arrLiteral!ConcreteExpr(ctx.alloc, [
				ConcreteExpr(arrayType, range, ConcreteExprKind(
					allocate(ctx.alloc, ConcreteExprKind.CreateArr(arrayStruct, exprs))))])));
}

Opt!Constant tryEvalConstant(
	in ConcreteFun fn,
	in Constant[] /*parameters*/,
	in VersionInfo versionInfo,
) =>
	body_(fn).matchIn!(Opt!Constant)(
		(in ConcreteFunBody.Builtin) {
			// TODO: don't just special-case this one..
			Opt!Sym name = name(fn);
			return has(name) ? tryEvalConstantBuiltin(force(name), versionInfo) : none!Constant;
		},
		(in Constant x) =>
			some(x),
		(in ConcreteFunBody.CreateRecord) => none!Constant,
		(in ConcreteFunBody.CreateUnion) => none!Constant,
		(in EnumFunction _) => none!Constant,
		(in ConcreteFunBody.Extern) => none!Constant,
		(in ConcreteExpr e) =>
			e.kind.isA!Constant
				? some(e.kind.as!Constant)
				: none!Constant,
		(in ConcreteFunBody.FlagsFn) => none!Constant,
		(in ConcreteFunBody.RecordFieldGet) => none!Constant,
		(in ConcreteFunBody.RecordFieldSet) => none!Constant,
		(in ConcreteFunBody.ThreadLocal) => none!Constant);

Opt!Constant tryEvalConstantBuiltin(Sym name, in VersionInfo versionInfo) {
	switch (name.value) {
		case sym!"is-big-endian".value:
			return some(constantBool(versionInfo.isBigEndian));
		case sym!"is-interpreted".value:
			return some(constantBool(versionInfo.isInterpreted));
		case sym!"is-jit".value:
			return some(constantBool(versionInfo.isJit));
		case sym!"is-single-threaded".value:
			return some(constantBool(versionInfo.isSingleThreaded));
		case sym!"is-wasm".value:
			return some(constantBool(versionInfo.isWasm));
		case sym!"is-windows".value:
			return some(constantBool(versionInfo.isWindows));
		default:
			return none!Constant;
	}
}
