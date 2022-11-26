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
import model.constant : Constant;
import model.model :
	AssertOrForbidKind,
	Called,
	ClosureRef,
	ClosureReferenceKind,
	debugName,
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
import util.memory : allocate, allocateMut, overwriteMemory;
import util.opt : force, has, none, Opt, some;
import util.ptr : castImmutable, castNonScope, castNonScope_ref, ptrTrustMe;
import util.sourceRange : FileAndRange;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.util : todo, unreachable, verify;
import versionInfo : VersionInfo;

@trusted immutable(ConcreteExpr) concretizeExpr(
	ref ConcretizeCtx ctx,
	ref immutable ContainingFunInfo containing,
	immutable ConcreteFun* cf,
	scope ref immutable Expr e,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe(ctx), containing, cf);
	immutable Locals locals;
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

	ref immutable(ConcreteFun) currentConcreteFun() return scope const =>
		*currentConcreteFunPtr;

	ref inout(AllConstantsBuilder) allConstants() return scope inout =>
		concretizeCtx.allConstants;
}

struct TypedConstant {
	immutable ConcreteType type;
	immutable Constant value;
}

struct LocalOrConstant {
	mixin Union!(immutable ConcreteLocal*, immutable TypedConstant);
}

immutable(ConcreteType) getConcreteType(ref ConcretizeExprCtx ctx, immutable Type t) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_fromConcretizeCtx(ctx.concretizeCtx, t, s);
}

immutable(ConcreteType) getConcreteType_forStructInst(ref ConcretizeExprCtx ctx, immutable StructInst* i) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_forStructInst_fromConcretizeCtx(ctx.concretizeCtx, i, s);
}

immutable(ConcreteType[]) typesToConcreteTypes(ref ConcretizeExprCtx ctx, immutable Type[] typeArgs) {
	immutable TypeArgsScope s = typeScope(ctx);
	return typesToConcreteTypes_fromConcretizeCtx(ctx.concretizeCtx, typeArgs, s);
}

immutable(TypeArgsScope) typeScope(ref ConcretizeExprCtx ctx) =>
	typeArgsScope(ctx.containing);

immutable(ConcreteExpr) concretizeCall(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Call e,
) {
	immutable ConcreteFun* concreteCalled = getConcreteFunFromCalled(ctx, e.called);
	immutable ConstantsOrExprs args =
		empty(e.args) || (!isSummon(*concreteCalled) && purity(concreteCalled.returnType) == Purity.data)
			? getConstantsOrExprs(ctx, locals, e.args)
			: immutable ConstantsOrExprs(getArgs(ctx, locals, e.args));
	immutable ConstantsOrExprs args2 = isVariadic(*concreteCalled)
		? constantsOrExprsArr(ctx, range, args, only(concreteCalled.paramsExcludingClosure).type)
		: args;
	immutable ConcreteExprKind kind = args2.match!(immutable ConcreteExprKind)(
		(immutable Constant[] constants) {
			immutable Opt!Constant constant =
				tryEvalConstant(*concreteCalled, constants, ctx.concretizeCtx.versionInfo);
			return has(constant)
				? immutable ConcreteExprKind(force(constant))
				: immutable ConcreteExprKind(immutable ConcreteExprKind.Call(
					concreteCalled,
					mapZip(
						ctx.alloc,
						concreteCalled.paramsExcludingClosure,
						constants,
						(ref immutable ConcreteParam p, ref immutable Constant x) =>
							immutable ConcreteExpr(p.type, FileAndRange.empty, immutable ConcreteExprKind(x)))));
		},
		(immutable ConcreteExpr[] exprs) =>
			immutable ConcreteExprKind(immutable ConcreteExprKind.Call(concreteCalled, exprs)));
	return immutable ConcreteExpr(concreteCalled.returnType, range, kind);
}

immutable(ConcreteFun*) getConcreteFunFromCalled(ref ConcretizeExprCtx ctx, ref immutable Called called) =>
	called.matchWithPointers!(immutable ConcreteFun*)(
		(immutable FunInst* funInst) =>
			getConcreteFunFromFunInst(ctx, funInst),
		(immutable SpecSig* specSig) =>
			ctx.containing.specImpls[specSig.indexOverAllSpecUses]);

immutable(ConcreteFun*) getConcreteFunFromFunInst(
	ref ConcretizeExprCtx ctx,
	immutable FunInst* funInst,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes(ctx, typeArgs(*funInst));
	immutable ConcreteFun*[] specImpls = map(ctx.alloc, specImpls(*funInst), (ref immutable Called it) =>
		getConcreteFunFromCalled(ctx, it));
	immutable ConcreteFunKey key = immutable ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(ctx.concretizeCtx, key);
}

immutable(ConcreteExpr) concretizeClosureGet(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	ref immutable ExprKind.ClosureGet a,
) {
	immutable ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	return immutable ConcreteExpr(info.type, range, immutable ConcreteExprKind(
		allocate(ctx.alloc, immutable ConcreteExprKind.ClosureGet(info.closureRef, info.referenceKind))));
}

immutable(ConcreteExpr) concretizeClosureSet(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.ClosureSet a,
) {
	verify(getClosureReferenceKind(*a.closureRef) == ClosureReferenceKind.allocated);
	immutable ClosureFieldInfo info = getClosureFieldInfo(ctx, range, *a.closureRef);
	verify(info.referenceKind == ClosureReferenceKind.allocated);
	immutable ConcreteExpr value = concretizeExpr(ctx, locals, *a.value);
	return immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(
			allocate(ctx.alloc, immutable ConcreteExprKind.ClosureSet(info.closureRef, value))));
}

struct ClosureFieldInfo {
	immutable ConcreteClosureRef closureRef;
	immutable ConcreteType type; //If 'referenceKind' is 'allocated', this is the pointee type 
	immutable ClosureReferenceKind referenceKind;
}
immutable(ClosureFieldInfo) getClosureFieldInfo(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	immutable ClosureRef a,
) {
	immutable ConcreteParam* closureParam = force(ctx.currentConcreteFun.closureParam);
	immutable ConcreteType closureType = closureParam.type;
	immutable ConcreteStructBody.Record record = body_(*closureType.struct_).as!(ConcreteStructBody.Record);
	immutable ClosureReferenceKind referenceKind = getClosureReferenceKind(a);
	immutable ConcreteType fieldType = record.fields[a.index].type;
	immutable ConcreteType pointeeType = () {
		final switch (referenceKind) {
			case ClosureReferenceKind.direct:
				return fieldType;
			case ClosureReferenceKind.allocated:
				return removeIndirection(fieldType);
		}
	}();
	return immutable ClosureFieldInfo(
		immutable ConcreteClosureRef(immutable PtrAndSmallNumber!(ConcreteParam)(closureParam, a.index)),
		pointeeType,
		referenceKind);
}

immutable(ConstantsOrExprs) getConstantsOrExprs(
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr[] argExprs,
) =>
	asConstantsOrExprs(ctx.alloc, getArgs(ctx, locals, argExprs));

immutable(ConcreteExpr[]) getArgs(
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr[] argExprs,
) =>
	map(ctx.alloc, argExprs, (ref immutable Expr arg) =>
		concretizeExpr(ctx, locals, arg));

immutable(ConcreteExpr) createAllocExpr(ref Alloc alloc, immutable ConcreteExpr inner) {
	verify(inner.type.reference == ReferenceKind.byVal);
	return immutable ConcreteExpr(
		byRef(inner.type),
		inner.range,
		immutable ConcreteExprKind(allocate(alloc, immutable ConcreteExprKind.Alloc(inner))));
}

immutable(ConcreteExpr) getCurExclusion(
	ref ConcretizeExprCtx ctx,
	ref immutable ConcreteType type,
	immutable FileAndRange range,
) =>
	immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.Call(ctx.concretizeCtx.curExclusionFun, [])));

immutable(ConcreteField[]) concretizeClosureFields(
	ref ConcretizeCtx ctx,
	immutable VariableRef[] closure,
	immutable TypeArgsScope typeArgsScope,
) =>
	map(ctx.alloc, closure, (ref immutable VariableRef x) {
		immutable ConcreteType baseType = getConcreteType_fromConcretizeCtx(ctx, variableRefType(x), typeArgsScope);
		immutable ConcreteType type = () {
			final switch (getClosureReferenceKind(x)) {
				case ClosureReferenceKind.direct:
					return baseType;
				case ClosureReferenceKind.allocated:
					return addIndirection(baseType);
			}
		}();
		// Even if the variable is mutable, it's a const field holding a mut pointer
		return immutable ConcreteField(debugName(x), ConcreteMutability.const_, type);
	});

immutable(ConcreteType) addIndirection(immutable ConcreteType a) =>
	immutable ConcreteType(addIndirection(a.reference), a.struct_);
immutable(ReferenceKind) addIndirection(immutable ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return ReferenceKind.byRef;
		case ReferenceKind.byRef:
			return ReferenceKind.byRefRef;
		case ReferenceKind.byRefRef:
			return unreachable!(immutable ReferenceKind);
	}
}

immutable(ConcreteType) removeIndirection(immutable ConcreteType a) =>
	immutable ConcreteType(removeIndirection(a.reference), a.struct_);
immutable(ReferenceKind) removeIndirection(immutable ReferenceKind a) {
	final switch (a) {
		case ReferenceKind.byVal:
			return unreachable!(immutable ReferenceKind);
		case ReferenceKind.byRef:
			return ReferenceKind.byVal;
		case ReferenceKind.byRefRef:
			return ReferenceKind.byRef;
	}
}

immutable(ConcreteExpr) concretizeDrop(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Drop e,
) {
	immutable ConcreteExpr arg = concretizeExpr(ctx, locals, e.arg);
	immutable ConcreteExprKind kind = arg.kind.isA!Constant
		? constantVoidKind()
		: immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Drop(arg)));
	return immutable ConcreteExpr(voidType(ctx.concretizeCtx), range, kind);
}

immutable(ConcreteExpr) constantVoid(ref ConcretizeCtx ctx, immutable FileAndRange range) =>
	immutable ConcreteExpr(voidType(ctx), range, constantVoidKind());

immutable(ConcreteExprKind) constantVoidKind() =>
	immutable ConcreteExprKind(immutable Constant(immutable Constant.Void()));

immutable(ConcreteExpr) concretizeFunPtr(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	ref immutable ExprKind.FunPtr e,
) {
	immutable ConcreteFun* fun = getOrAddNonTemplateConcreteFunAndFillBody(ctx.concretizeCtx, e.funInst);
	immutable ConcreteType concreteType = getConcreteType_forStructInst(ctx, e.structInst);
	return immutable ConcreteExpr(concreteType, range, immutable ConcreteExprKind(
		immutable Constant(immutable Constant.FunPtr(fun))));
}

immutable(ConcreteParam*) closureParam(ref Alloc alloc, immutable ConcreteType closureType) =>
	allocate(alloc, immutable ConcreteParam(
		immutable ConcreteParamSource(immutable ConcreteParamSource.Closure()),
		none!size_t,
		closureType));

immutable(ConcreteExpr) concretizeLambda(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Lambda e,
) {
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

	//TODO:KILL? (We also have an ID within the type..)
	immutable size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	immutable TypeArgsScope tScope = typeScope(ctx);
	immutable ConcreteParam[] params = concretizeParams(ctx.concretizeCtx, e.params, tScope);

	immutable ConcreteType concreteType = getConcreteType_forStructInst(ctx, e.funType);
	immutable ConcreteStruct* concreteStruct = mustBeByVal(concreteType);

	immutable ConcreteVariableRef[] closureArgs = map(ctx.alloc, e.closure, (ref immutable VariableRef x) =>
		concretizeVariableRefForClosure(ctx, range, locals, x));
	immutable ConcreteField[] closureFields = concretizeClosureFields(ctx.concretizeCtx, e.closure, tScope);
	immutable ConcreteType closureType = concreteTypeFromClosure(
		ctx.concretizeCtx,
		closureFields,
		immutable ConcreteStructSource(
			immutable ConcreteStructSource.Lambda(ctx.currentConcreteFunPtr, lambdaIndex)));
	immutable ConcreteParam* closureParam = closureParam(ctx.alloc, closureType);
	immutable Opt!(ConcreteExpr*) closure = empty(closureArgs)
		? none!(ConcreteExpr*)
		: some(allocate(ctx.alloc, createAllocExpr(ctx.alloc, immutable ConcreteExpr(
			byVal(closureType),
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.ClosureCreate(closureArgs))))));

	immutable ConcreteFun* fun = getConcreteFunForLambdaAndFillBody(
		ctx.concretizeCtx,
		ctx.currentConcreteFunPtr,
		lambdaIndex,
		getConcreteType(ctx, e.returnType),
		closureParam,
		params,
		ctx.containing,
		e.body_);
	immutable ConcreteLambdaImpl impl = immutable ConcreteLambdaImpl(closureType, fun);
	immutable(ConcreteExprKind) lambda(immutable ConcreteStruct* funStruct) =>
		immutable ConcreteExprKind(
			immutable ConcreteExprKind.Lambda(nextLambdaImplId(ctx.concretizeCtx, funStruct, impl), closure));
	if (e.kind == FunKind.ref_) {
		// For a fun-ref this is the inner 'act' type.
		immutable ConcreteField[] fields = body_(*concreteStruct).as!(ConcreteStructBody.Record).fields;
		verify(fields.length == 2);
		immutable ConcreteField exclusionField = fields[0];
		verify(exclusionField.debugName == sym!"exclusion");
		immutable ConcreteField actionField = fields[1];
		verify(actionField.debugName == sym!"action");
		immutable ConcreteType funType = actionField.type;
		immutable ConcreteExpr exclusion = getCurExclusion(ctx, exclusionField.type, range);
		return immutable ConcreteExpr(concreteType, range, immutable ConcreteExprKind(
			immutable ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(ctx.alloc, [
				exclusion,
				immutable ConcreteExpr(funType, range, lambda(mustBeByVal(funType)))]))));
	} else
		return immutable ConcreteExpr(concreteType, range, lambda(concreteStruct));
}

public immutable(size_t) nextLambdaImplId(
	ref ConcretizeCtx ctx,
	immutable ConcreteStruct* funStruct,
	immutable ConcreteLambdaImpl impl,
) =>
	nextLambdaImplIdInner(ctx.alloc, impl, getOrAdd(ctx.alloc, ctx.funStructToImpls, funStruct, () =>
		MutArr!(immutable ConcreteLambdaImpl)()));
immutable(size_t) nextLambdaImplIdInner(
	ref Alloc alloc,
	immutable ConcreteLambdaImpl impl,
	ref MutArr!(immutable ConcreteLambdaImpl) impls,
) {
	immutable size_t res = mutArrSize(impls);
	push(alloc, impls, impl);
	return res;
}

immutable(ConcreteLocal*) makeLocalWorker(
	ref ConcretizeExprCtx ctx,
	immutable Local* source,
	immutable ConcreteType type,
) =>
	allocate(ctx.alloc, immutable ConcreteLocal(source, type));

immutable(ConcreteLocal*) concretizeLocal(ref ConcretizeExprCtx ctx, immutable Local* local) =>
	makeLocalWorker(ctx, local, getConcreteType(ctx, local.type));

alias Locals = immutable StackDict2!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias addLocal = stackDict2Add0!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias addLoop = stackDict2Add1!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
alias getLocal = stackDict2MustGet0!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*);
//TODO: use an alias
@trusted immutable(ConcreteExprKind.Loop*) getLoop(
	return scope ref immutable Locals locals,
	immutable ExprKind.Loop* key,
) =>
	stackDict2MustGet1!(Local*, LocalOrConstant, ExprKind.Loop*, ConcreteExprKind.Loop*)(locals, key);

@trusted immutable(ConcreteExpr) concretizeWithLocal(
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	immutable Local* modelLocal,
	ref immutable LocalOrConstant concreteLocal,
	ref immutable Expr expr,
) {
	scope immutable Locals newLocals = addLocal(locals, modelLocal, concreteLocal);
	return concretizeExpr(ctx, newLocals, expr);
}

immutable(ConcreteExpr) concretizeLet(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Let e,
) {
	immutable ConcreteExpr value = concretizeExpr(ctx, locals, e.value);
	if (e.local.mutability == LocalMutability.immut && value.kind.isA!Constant) {
		immutable LocalOrConstant lc =
			immutable LocalOrConstant(immutable TypedConstant(value.type, value.kind.as!Constant));
		return concretizeWithLocal(ctx, locals, e.local, lc, e.then);
	} else {
		immutable ConcreteLocal* local = concretizeLocal(ctx, e.local);
		immutable LocalOrConstant lc = immutable LocalOrConstant(local);
		immutable ConcreteExpr then = concretizeWithLocal(ctx, locals, e.local, lc, e.then);
		return immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
			allocate(ctx.alloc, immutable ConcreteExprKind.Let(local, value, then))));
	}
}

immutable(ConcreteExpr) concretizeIfOption(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.IfOption e,
) {
	immutable ConcreteExpr option = concretizeExpr(ctx, locals, e.option);
	if (option.kind.isA!Constant)
		return todo!(immutable ConcreteExpr)("constant option");
	else {
		immutable ConcreteType someType =
			force(body_(*mustBeByVal(option.type)).as!(ConcreteStructBody.Union).members[1]);
		immutable ConcreteType type = getConcreteType(ctx, e.type);
		immutable ConcreteExprKind.MatchUnion.Case noneCase = immutable ConcreteExprKind.MatchUnion.Case(
			none!(ConcreteLocal*),
			concretizeExpr(ctx, locals, e.else_));
		immutable ConcreteLocal* someLocal = makeLocalWorker(ctx, e.local, someType);
		immutable LocalOrConstant lc = immutable LocalOrConstant(someLocal);
		immutable ConcreteExpr then = concretizeWithLocal(ctx, locals, e.local, lc, e.then);
		immutable ConcreteExprKind.MatchUnion.Case someCase =
			immutable ConcreteExprKind.MatchUnion.Case(some(someLocal), then);
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			allocate(ctx.alloc, immutable ConcreteExprKind.MatchUnion(
				option,
				arrLiteral!(ConcreteExprKind.MatchUnion.Case)(ctx.alloc, [noneCase, someCase])))));
	}
}

@trusted immutable(ConcreteExpr) concretizeLocalGet(
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	immutable Local* local,
) {
	immutable LocalOrConstant lc = castNonScope(getLocal(locals, local));
	return lc.matchWithPointers!(immutable ConcreteExpr)(
		(immutable ConcreteLocal* local) =>
			immutable ConcreteExpr(local.type, range, immutable ConcreteExprKind(
				immutable ConcreteExprKind.LocalGet(local))),
		(immutable TypedConstant x) =>
			immutable ConcreteExpr(x.type, range, immutable ConcreteExprKind(x.value)));
}

// TODO: not @trusted
@trusted immutable(ConcreteExpr) concretizePtrToLocal(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	immutable ExprKind.PtrToLocal a,
) {
	immutable ConcreteExprKind kind = getLocal(locals, a.local).matchWithPointers!(immutable ConcreteExprKind)(
		(immutable ConcreteLocal* local) =>
			immutable ConcreteExprKind(immutable ConcreteExprKind.PtrToLocal(local)),
		(immutable TypedConstant x) =>
			//TODO: what if pointee is a reference?
			immutable ConcreteExprKind(getConstantPtr(ctx.alloc, ctx.allConstants, mustBeByVal(x.type), x.value)));
	return immutable ConcreteExpr(getConcreteType(ctx, a.ptrType), range, kind);
}

immutable(ConcreteExpr) concretizePtrToField(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.PtrToField a,
) {
	immutable ConcreteExpr target = concretizeExpr(ctx, locals, a.target);
	immutable ConcreteType pointerType = getConcreteType(ctx, a.pointerType);
	return immutable ConcreteExpr(
		pointerType,
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.PtrToField(target, a.fieldIndex))));
}

immutable(ConcreteExpr) concretizeLocalSet(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.LocalSet a,
) {
	immutable ConcreteLocal* local = getLocal(locals, a.local).as!(ConcreteLocal*);
	immutable ConcreteExpr value = concretizeExpr(ctx, locals, a.value);
	return immutable ConcreteExpr(voidType(ctx.concretizeCtx), range, immutable ConcreteExprKind(
		allocate(ctx.alloc, immutable ConcreteExprKind.LocalSet(castNonScope(local), value))));
}

immutable(ConcreteExpr) concretizeLoop(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Loop a,
) {
	ConcreteExprKind.Loop* res = allocateMut(ctx.alloc, ConcreteExprKind.Loop());
	scope immutable Locals localsWithLoop = addLoop(castNonScope_ref(locals), castNonScope(&a), castImmutable(res));
	overwriteMemory(&res.body_, concretizeExpr(ctx, localsWithLoop, a.body_));
	return immutable ConcreteExpr(getConcreteType(ctx, a.type), range, immutable ConcreteExprKind(castImmutable(res)));
}

immutable(ConcreteExpr) concretizeLoopBreak(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.LoopBreak a,
) {
	immutable ConcreteExprKind.Loop* loop = castNonScope(getLoop(locals, a.loop));
	immutable ConcreteExpr value = concretizeExpr(ctx, locals, a.value);
	return immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.LoopBreak(loop, value))));
}

immutable(ConcreteExpr) concretizeLoopContinue(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.LoopContinue a,
) {
	immutable ConcreteExprKind.Loop* loop = castNonScope(getLoop(locals, a.loop));
	return immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.LoopContinue(loop)));
}

immutable(ConcreteExpr) concretizeLoopUntil(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.LoopUntil a,
) =>
	concretizeLoopUntilOrWhile(ctx, range, locals, a.condition, a.body_, true);

immutable(ConcreteExpr) concretizeLoopWhile(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.LoopWhile a,
) =>
	concretizeLoopUntilOrWhile(ctx, range, locals, a.condition, a.body_, false);

immutable(ConcreteExpr) concretizeLoopUntilOrWhile(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr conditionExpr,
	ref immutable Expr bodyExpr,
	immutable bool isUntil,
) {
	ConcreteExprKind.Loop* res = allocateMut(ctx.alloc, ConcreteExprKind.Loop());
	immutable ConcreteExpr breakVoid = immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.LoopBreak(
			castImmutable(res),
			constantVoid(ctx.concretizeCtx, range)))));
	immutable ConcreteExpr doAndContinue = immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Seq(
			concretizeExpr(ctx, locals, bodyExpr),
			immutable ConcreteExpr(
				voidType(ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(immutable ConcreteExprKind.LoopContinue(castImmutable(res))))))));
	immutable ConcreteExpr condition = concretizeExpr(ctx, locals, conditionExpr);
	immutable ConcreteExprKind.Cond cond = isUntil
		? immutable ConcreteExprKind.Cond(condition, breakVoid, doAndContinue)
		: immutable ConcreteExprKind.Cond(condition, doAndContinue, breakVoid);
	immutable ConcreteExpr body_ = immutable ConcreteExpr(
		voidType(ctx.concretizeCtx),
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, cond)));
	overwriteMemory(&res.body_, body_);
	return immutable ConcreteExpr(voidType(ctx.concretizeCtx), range, immutable ConcreteExprKind(castImmutable(res)));
}

immutable(ConcreteExpr) concretizeMatchEnum(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.MatchEnum e,
) {
	immutable ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	//TODO: If matched is a constant, just compile the relevant case
	immutable ConcreteType type = getConcreteType(ctx, e.type);
	immutable ConcreteExpr[] cases = map(ctx.alloc, e.cases, (ref immutable Expr case_) =>
		concretizeExpr(ctx, locals, case_));
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		allocate(ctx.alloc, immutable ConcreteExprKind.MatchEnum(matched, cases))));
}

immutable(ConcreteExpr) concretizeMatchUnion(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.MatchUnion e,
) {
	immutable ConcreteExpr matched = concretizeExpr(ctx, locals, e.matched);
	immutable ConcreteType ct = getConcreteType_forStructInst(ctx, e.matchedUnion);
	immutable ConcreteStruct* matchedUnion = mustBeByVal(ct);
	immutable ConcreteType type = getConcreteType(ctx, e.type);
	if (matched.kind.isA!Constant) {
		immutable Constant.Union u = *matched.kind.as!Constant.as!(Constant.Union*);
		immutable ExprKind.MatchUnion.Case case_ = e.cases[u.memberIndex];
		if (has(case_.local)) {
			immutable ConcreteType caseType =
				force(body_(*matchedUnion).as!(ConcreteStructBody.Union).members[u.memberIndex]);
			immutable LocalOrConstant lc = immutable LocalOrConstant(immutable TypedConstant(caseType, u.arg));
			return concretizeWithLocal(ctx, locals, force(case_.local), lc, case_.then);
		} else
			return concretizeExpr(ctx, locals, case_.then);
	} else {
		immutable ConcreteExprKind.MatchUnion.Case[] cases = map(
			ctx.alloc,
			e.cases,
			(ref immutable ExprKind.MatchUnion.Case case_) {
				if (has(case_.local)) {
					immutable ConcreteLocal* local = concretizeLocal(ctx, force(case_.local));
					immutable LocalOrConstant lc = immutable LocalOrConstant(local);
					immutable ConcreteExpr then = concretizeWithLocal(ctx, locals, force(case_.local), lc, case_.then);
					return immutable ConcreteExprKind.MatchUnion.Case(some(local), then);
				} else
					return immutable ConcreteExprKind.MatchUnion.Case(
						none!(ConcreteLocal*),
						concretizeExpr(ctx, locals, case_.then));
			});
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			allocate(ctx.alloc, immutable ConcreteExprKind.MatchUnion(matched, cases))));
	}
}

immutable(ConcreteParam*) getParam(ref ConcretizeExprCtx ctx, immutable Param* param) {
	return &ctx.currentConcreteFun.paramsExcludingClosure[param.index];
}

immutable(ConcreteExpr) concretizeParamGet(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	immutable Param* param,
) {
	immutable ConcreteParam* concreteParam = getParam(ctx, param);
	return immutable ConcreteExpr(concreteParam.type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamGet(concreteParam)));
}

immutable(ConcreteExpr) concretizePtrToParam(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	immutable ExprKind.PtrToParam a,
) {
	immutable ConcreteParam* concreteParam = &ctx.currentConcreteFun.paramsExcludingClosure[a.param.index];
	return immutable ConcreteExpr(
		getConcreteType(ctx, a.ptrType),
		range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.PtrToParam(concreteParam)));
}

immutable(ConcreteVariableRef) concretizeVariableRefForClosure(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	immutable VariableRef a,
) =>
	a.matchWithPointers!(immutable ConcreteVariableRef)(
		(immutable Local* x) =>
			getLocal(locals, x).matchWithPointers!(immutable ConcreteVariableRef)(
				(immutable ConcreteLocal* local) =>
					immutable ConcreteVariableRef(local),
				(immutable TypedConstant constant) =>
					immutable ConcreteVariableRef(constant.value)),
		(immutable Param* x) =>
			immutable ConcreteVariableRef(getParam(ctx, x)),
		(immutable ClosureRef x) =>
			immutable ConcreteVariableRef(getClosureFieldInfo(ctx, range, x).closureRef));

immutable(ConcreteExpr) concretizeThrow(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.Throw a,
) =>
	immutable ConcreteExpr(getConcreteType(ctx, a.type), range, immutable ConcreteExprKind(
		allocate(ctx.alloc, immutable ConcreteExprKind.Throw(concretizeExpr(ctx, locals, a.thrown)))));

immutable(ConcreteExpr) cStrConcreteExpr(
	ref ConcretizeCtx ctx,
	immutable FileAndRange range,
	immutable SafeCStr value,
) =>
	immutable ConcreteExpr(cStrType(ctx), range, immutable ConcreteExprKind(constantCStr(ctx, value)));

immutable(ConcreteExpr) concretizeAssertOrForbid(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable ExprKind.AssertOrForbid a,
) {
	immutable ConcreteExpr condition = concretizeExpr(ctx, locals, *a.condition);
	immutable ConcreteExpr thrown = has(a.thrown)
		? concretizeExpr(ctx, locals, *force(a.thrown))
		: cStrConcreteExpr(ctx.concretizeCtx, range, defaultAssertOrForbidMessage(a.kind));
	immutable ConcreteExpr void_ = constantVoid(ctx.concretizeCtx, range);
	immutable ConcreteType voidType = voidType(ctx.concretizeCtx);
	immutable ConcreteExpr throw_ = immutable ConcreteExpr(
		voidType,
		range,
		immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Throw(thrown))));
	immutable ConcreteExprKind.Cond cond = () {
		final switch (a.kind) {
			case AssertOrForbidKind.assert_:
				return immutable ConcreteExprKind.Cond(condition, void_, throw_);
			case AssertOrForbidKind.forbid:
				return immutable ConcreteExprKind.Cond(condition, throw_, void_);
		}
	}();
	return immutable ConcreteExpr(voidType, range, immutable ConcreteExprKind(allocate(ctx.alloc, cond)));
}

immutable(SafeCStr) defaultAssertOrForbidMessage(immutable AssertOrForbidKind a) {
	final switch (a) {
		case AssertOrForbidKind.assert_:
			return safeCStr!"assert failed";
		case AssertOrForbidKind.forbid:
			return safeCStr!"forbid failed";
	}
}

immutable(ConcreteExpr) concretizeExpr(
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr e,
) {
	immutable FileAndRange range = e.range;
	return e.kind.match!(immutable ConcreteExpr)(
		(immutable ExprKind.AssertOrForbid x) =>
			concretizeAssertOrForbid(ctx, range, locals, x),
		(immutable ExprKind.Bogus) =>
			unreachable!(immutable ConcreteExpr),
		(immutable ExprKind.Call e) =>
			concretizeCall(ctx, range, locals, e),
		(immutable ExprKind.ClosureGet e) =>
			concretizeClosureGet(ctx, range, e),
		(immutable ExprKind.ClosureSet e) =>
			concretizeClosureSet(ctx, range, locals, e),
		(ref immutable ExprKind.Cond e) {
			immutable ConcreteExpr cond = concretizeExpr(ctx, locals, e.cond);
			return cond.kind.isA!Constant
				? concretizeExpr(ctx, locals, cond.kind.as!Constant.as!(Constant.BoolConstant).value ? e.then : e.else_)
				: immutable ConcreteExpr(
					getConcreteType(ctx, e.type),
					range,
					immutable ConcreteExprKind(allocate(ctx.alloc, immutable ConcreteExprKind.Cond(
						cond,
						concretizeExpr(ctx, locals, e.then),
						concretizeExpr(ctx, locals, e.else_)))));
		},
		(ref immutable ExprKind.Drop e) =>
			concretizeDrop(ctx, range, locals, e),
		(immutable ExprKind.FunPtr e) =>
			concretizeFunPtr(ctx, range, e),
		(ref immutable ExprKind.IfOption e) =>
			concretizeIfOption(ctx, range, locals, e),
		(ref immutable ExprKind.Lambda e) =>
			concretizeLambda(ctx, range, locals, e),
		(ref immutable ExprKind.Let e) =>
			concretizeLet(ctx, range, locals, e),
		(ref immutable ExprKind.Literal e) =>
			immutable ConcreteExpr(
				getConcreteType_forStructInst(ctx, e.structInst),
				range,
				immutable ConcreteExprKind(e.value)),
		(immutable ExprKind.LiteralCString e) =>
			cStrConcreteExpr(ctx.concretizeCtx, range, e.value),
		(immutable ExprKind.LiteralSymbol e) =>
			immutable ConcreteExpr(
				symType(ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(constantSym(ctx.concretizeCtx, e.value))),
		(immutable ExprKind.LocalGet e) =>
			concretizeLocalGet(range, locals, e.local),
		(ref immutable ExprKind.LocalSet e) =>
			concretizeLocalSet(ctx, range, locals, e),
		(ref immutable ExprKind.Loop e) =>
			concretizeLoop(ctx, range, locals, e),
		(ref immutable ExprKind.LoopBreak e) =>
			concretizeLoopBreak(ctx, range, locals, e),
		(immutable ExprKind.LoopContinue e) =>
			concretizeLoopContinue(ctx, range, locals, e),
		(ref immutable ExprKind.LoopUntil e) =>
			concretizeLoopUntil(ctx, range, locals, e),
		(ref immutable ExprKind.LoopWhile e) =>
			concretizeLoopWhile(ctx, range, locals, e),
		(ref immutable ExprKind.MatchEnum e) =>
			concretizeMatchEnum(ctx, range, locals, e),
		(ref immutable ExprKind.MatchUnion e) =>
			concretizeMatchUnion(ctx, range, locals, e),
		(immutable ExprKind.ParamGet e) =>
			concretizeParamGet(ctx, range, e.param),
		(ref immutable ExprKind.PtrToField e) =>
			concretizePtrToField(ctx, range, locals, e),
		(immutable ExprKind.PtrToLocal e) =>
			concretizePtrToLocal(ctx, range, locals, e),
		(immutable ExprKind.PtrToParam e) =>
			concretizePtrToParam(ctx, range, e),
		(ref immutable ExprKind.Seq e) {
			immutable ConcreteExpr first = concretizeExpr(ctx, locals, e.first);
			immutable ConcreteExpr then = concretizeExpr(ctx, locals, e.then);
			return first.kind.isA!Constant
				? then
				: immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
					allocate(ctx.alloc, immutable ConcreteExprKind.Seq(first, then))));
		},
		(ref immutable ExprKind.Throw e) =>
			concretizeThrow(ctx, range, locals, e));
}

immutable(ConstantsOrExprs) constantsOrExprsArr(
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	immutable ConstantsOrExprs args,
	immutable ConcreteType arrayType,
) {
	immutable ConcreteStruct* arrayStruct = mustBeByVal(arrayType);
	return args.match!(immutable ConstantsOrExprs)(
		(immutable Constant[] constants) =>
			immutable ConstantsOrExprs(arrLiteral!Constant(ctx.alloc, [
				getConstantArr(ctx.alloc, ctx.allConstants, arrayStruct, constants)])),
		(immutable ConcreteExpr[] exprs) =>
			immutable ConstantsOrExprs(arrLiteral!ConcreteExpr(ctx.alloc, [
				immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
					allocate(ctx.alloc, immutable ConcreteExprKind.CreateArr(arrayStruct, exprs))))])));
}

immutable(Opt!Constant) tryEvalConstant(
	ref immutable ConcreteFun fn,
	immutable Constant[] /*parameters*/,
	immutable VersionInfo versionInfo,
) =>
	body_(fn).match!(immutable Opt!Constant)(
		(immutable ConcreteFunBody.Builtin) {
			// TODO: don't just special-case this one..
			immutable Opt!Sym name = name(fn);
			return has(name) ? tryEvalConstantBuiltin(force(name), versionInfo) : none!Constant;
		},
		(immutable ConcreteFunBody.CreateEnum) => none!Constant,
		(immutable ConcreteFunBody.CreateExtern) => none!Constant,
		(immutable ConcreteFunBody.CreateRecord) => none!Constant,
		(immutable ConcreteFunBody.CreateUnion) => none!Constant,
		(immutable EnumFunction) => none!Constant,
		(immutable ConcreteFunBody.Extern) => none!Constant,
		(immutable ConcreteExpr e) =>
			e.kind.isA!Constant
				? some(e.kind.as!Constant)
				: none!Constant,
		(immutable ConcreteFunBody.FlagsFn) => none!Constant,
		(immutable ConcreteFunBody.RecordFieldGet) => none!Constant,
		(immutable ConcreteFunBody.RecordFieldSet) => none!Constant,
		(immutable ConcreteFunBody.ThreadLocal) => none!Constant);

immutable(Opt!Constant) tryEvalConstantBuiltin(immutable Sym name, ref immutable VersionInfo versionInfo) {
	switch (name.value) {
		case sym!"is-big-endian".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isBigEndian)));
		case sym!"is-interpreted".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isInterpreted)));
		case sym!"is-jit".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isJit)));
		case sym!"is-single-threaded".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isSingleThreaded)));
		case sym!"is-wasm".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isWasm)));
		case sym!"is-windows".value:
			return some(immutable Constant(immutable Constant.BoolConstant(versionInfo.isWindows)));
		default:
			return none!Constant;
	}
}
