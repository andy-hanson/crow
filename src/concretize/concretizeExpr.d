module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : getConstantArr;
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
	getCurIslandAndExclusionFun,
	getOrAddConcreteFunAndFillBody,
	getConcreteFunForLambdaAndFillBody,
	cStrType,
	symType,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes;
import concretize.constantsOrExprs : asConstantsOrExprs, ConstantsOrExprs, matchConstantsOrExprs;
import model.concreteModel :
	asConstant,
	asRecord,
	asUnion,
	body_,
	byRef,
	byVal,
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFieldSource,
	ConcreteFun,
	ConcreteLambdaImpl,
	ConcreteLocal,
	ConcreteMutability,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	isConstant,
	isSummon,
	isVariadic,
	mustBeNonPointer,
	name,
	purity,
	returnType;
import model.constant : asBool, asRecord, asUnion, Constant;
import model.model :
	Called,
	ClosureField,
	Expr,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	Purity,
	range,
	specImpls,
	SpecSig,
	StructInst,
	Type,
	typeArgs;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, only, ptrAt;
import util.col.arrUtil : arrLiteral, map, mapWithIndex;
import util.col.mutArr : MutArr, mutArrSize, push;
import util.col.mutDict : getOrAdd;
import util.col.stackDict : StackDict, stackDictAdd, stackDictMustGet;
import util.memory : allocate;
import util.opt : force, has, none, some;
import util.ptr : nullPtr, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSym, SpecialSym, symEq, symForSpecial;
import util.util : todo, unreachable, verify;

@trusted immutable(ConcreteExpr) concretizeExpr(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ContainingFunInfo containing,
	immutable Ptr!ConcreteFun cf,
	ref immutable Expr e,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ctx.nextExprCtxId(), ptrTrustMe_mut(ctx), containing, cf);
	immutable Locals locals;
	return concretizeExpr(alloc, exprCtx, locals, e);
}

private:

struct ConcretizeExprCtx {
	@safe @nogc pure nothrow:

	immutable int id;
	Ptr!ConcretizeCtx concretizeCtxPtr;
	immutable ContainingFunInfo containing;
	immutable Ptr!ConcreteFun currentConcreteFunPtr; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;
	size_t nextLocalIndex = 0;

	ref inout(ConcretizeCtx) concretizeCtx() return scope inout {
		return concretizeCtxPtr.deref();
	}
	ref immutable(ConcreteFun) currentConcreteFun() return scope const {
		return currentConcreteFunPtr.deref();
	}
}

struct TypedConstant {
	immutable ConcreteType type;
	immutable Constant value;
}

struct LocalOrConstant {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Ptr!ConcreteLocal a) { kind_ = Kind.local; local_ = a; }
	@trusted immutable this(immutable TypedConstant a) { kind_ = Kind.typedConstant; typedConstant_ = a; }

	private:
	enum Kind {
		local,
		typedConstant,
	}
	immutable Kind kind_;
	union {
		immutable Ptr!ConcreteLocal local_;
		immutable TypedConstant typedConstant_;
	}
}

@trusted T matchLocalOrConstant(T)(
	scope ref immutable LocalOrConstant a,
	scope T delegate(immutable Ptr!ConcreteLocal) @safe @nogc pure nothrow cbLocal,
	scope T delegate(immutable TypedConstant) @safe @nogc pure nothrow cbTypedConstant,
) {
	final switch (a.kind_) {
		case LocalOrConstant.Kind.local:
			return cbLocal(a.local_);
		case LocalOrConstant.Kind.typedConstant:
			return cbTypedConstant(a.typedConstant_);
	}
}

immutable(ConcreteType) getConcreteType(ref Alloc alloc, ref ConcretizeExprCtx ctx, immutable Type t) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_fromConcretizeCtx(alloc, ctx.concretizeCtx, t, s);
}

immutable(ConcreteType) getConcreteType_forStructInst(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!StructInst i,
) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_forStructInst_fromConcretizeCtx(alloc, ctx.concretizeCtx, i, s);
}

immutable(ConcreteType[]) typesToConcreteTypes(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Type[] typeArgs,
) {
	immutable TypeArgsScope s = typeScope(ctx);
	return typesToConcreteTypes_fromConcretizeCtx(alloc, ctx.concretizeCtx, typeArgs, s);
}

immutable(TypeArgsScope) typeScope(ref ConcretizeExprCtx ctx) {
	return typeArgsScope(ctx.containing);
}

immutable(ConcreteExpr) concretizeCall(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.Call e,
) {
	immutable Ptr!ConcreteFun concreteCalled = getConcreteFunFromCalled(alloc, ctx, e.called);
	immutable ConstantsOrExprs args =
		!isSummon(concreteCalled.deref()) && purity(concreteCalled.deref().returnType) == Purity.data && false // TODO
			? getConstantsOrExprs(alloc, ctx, locals, e.args)
			: immutable ConstantsOrExprs(getArgs(alloc, ctx, locals, e.args));
	immutable ConstantsOrExprs args2 = isVariadic(concreteCalled.deref())
		? constantsOrExprsArr(alloc, ctx, range, args, only(concreteCalled.deref().paramsExcludingCtxAndClosure).type)
		: args;
	return matchConstantsOrExprs!(immutable ConcreteExpr)(
		args2,
		(ref immutable Constant[] constants) => immutable ConcreteExpr(
			concreteCalled.deref().returnType,
			range,
			immutable ConcreteExprKind(evalConstant(concreteCalled.deref(), constants))),
		(ref immutable ConcreteExpr[] exprs) => immutable ConcreteExpr(
			concreteCalled.deref().returnType,
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.Call(concreteCalled, exprs))));
}

immutable(Ptr!ConcreteFun) getConcreteFunFromCalled(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Called called,
) {
	return matchCalled!(
		immutable Ptr!ConcreteFun,
		(immutable Ptr!FunInst funInst) =>
			getConcreteFunFromFunInst(alloc, ctx, funInst),
		(ref immutable SpecSig specSig) =>
			ctx.containing.specImpls[specSig.indexOverAllSpecUses],
	)(called);
}

immutable(Ptr!ConcreteFun) getConcreteFunFromFunInst(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!FunInst funInst,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes(alloc, ctx, typeArgs(funInst.deref));
	immutable Ptr!ConcreteFun[] specImpls = map!(Ptr!ConcreteFun)(
		alloc,
		specImpls(funInst.deref()),
		(ref immutable Called it) => getConcreteFunFromCalled(alloc, ctx, it));
	immutable ConcreteFunKey key = immutable ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(alloc, ctx.concretizeCtx, key);
}

immutable(ConcreteExpr) concretizeClosureFieldRef(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ClosureFieldRef e,
) {
	immutable Ptr!ConcreteParam closureParam = force(ctx.currentConcreteFun.closureParam);
	immutable ConcreteType closureType = closureParam.deref().type;
	immutable ConcreteStructBody.Record record = asRecord(body_(closureType.struct_.deref()));
	immutable Ptr!ConcreteField field = ptrAt(record.fields, e.field.deref().index);
	immutable ConcreteExpr closureParamRef = immutable ConcreteExpr(closureType, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(closureParam)));
	return immutable ConcreteExpr(field.deref().type, range, immutable ConcreteExprKind(
		allocate(alloc, immutable ConcreteExprKind.RecordFieldGet(closureParamRef, field))));
}

immutable(ConstantsOrExprs) getConstantsOrExprs(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr[] argExprs,
) {
	return asConstantsOrExprs(alloc, getArgs(alloc, ctx, locals, argExprs));
}

immutable(ConcreteExpr[]) getArgs(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr[] argExprs,
) {
	return map(alloc, argExprs, (ref immutable Expr arg) =>
		concretizeExpr(alloc, ctx, locals, arg));
}

immutable(ConcreteExpr) createAllocExpr(ref Alloc alloc, immutable ConcreteExpr inner) {
	verify(!inner.type.isPointer);
	return immutable ConcreteExpr(
		byRef(inner.type),
		inner.range,
		immutable ConcreteExprKind(allocate(alloc, immutable ConcreteExprKind.Alloc(inner))));
}

immutable(ConcreteExpr) getGetIslandAndExclusion(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable ConcreteType type,
	ref immutable FileAndRange range,
) {
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.Call(getCurIslandAndExclusionFun(alloc, ctx.concretizeCtx), emptyArr!ConcreteExpr)));
}

immutable(ConcreteField[]) concretizeClosureFields(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Ptr!ClosureField[] closure,
	immutable TypeArgsScope typeArgsScope,
) {
	return mapWithIndex!ConcreteField(alloc, closure, (immutable size_t index, ref immutable Ptr!ClosureField it) =>
		immutable ConcreteField(
			immutable ConcreteFieldSource(it),
			index,
			ConcreteMutability.const_,
			getConcreteType_fromConcretizeCtx(alloc, ctx, it.deref().type, typeArgsScope)));
}

immutable(ConcreteExpr) concretizeFunPtr(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.FunPtr e,
) {
	immutable Ptr!ConcreteFun fun = getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx.concretizeCtx, e.funInst);
	immutable ConcreteType concreteType = getConcreteType_forStructInst(alloc, ctx, e.structInst);
	return immutable ConcreteExpr(concreteType, range, immutable ConcreteExprKind(
		immutable Constant(immutable Constant.FunPtr(fun))));
}

public immutable(Ptr!ConcreteParam) closureParam(ref Alloc alloc, immutable ConcreteType closureType) {
	return allocate(alloc, immutable ConcreteParam(
		immutable ConcreteParamSource(immutable ConcreteParamSource.Closure()),
		none!size_t,
		closureType));
}

immutable(ConcreteExpr) concretizeLambda(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.Lambda e,
) {
	// TODO: handle constants in closure
	// (do *not* include in the closure type, instead remember them for when compiling the lambda fn)

	//TODO:KILL? (We also have an ID within the type..)
	immutable size_t lambdaIndex = ctx.nextLambdaIndex;
	ctx.nextLambdaIndex++;

	immutable TypeArgsScope tScope = typeScope(ctx);
	immutable ConcreteParam[] params = concretizeParams(alloc, ctx.concretizeCtx, e.params, tScope);

	immutable ConcreteType concreteType = getConcreteType_forStructInst(alloc, ctx, e.type);
	immutable Ptr!ConcreteStruct concreteStruct = mustBeNonPointer(concreteType);

	immutable ConcreteExpr[] closureArgs =
		map!ConcreteExpr(alloc, e.closure, (ref immutable Ptr!ClosureField f) =>
			concretizeExpr(alloc, ctx, locals, f.deref().expr));
	immutable ConcreteField[] closureFields =
		concretizeClosureFields(alloc, ctx.concretizeCtx, e.closure, tScope);
	immutable ConcreteType closureType = concreteTypeFromClosure(
		alloc,
		ctx.concretizeCtx,
		closureFields,
		immutable ConcreteStructSource(
			immutable ConcreteStructSource.Lambda(ctx.currentConcreteFunPtr, lambdaIndex)));
	immutable Ptr!ConcreteParam closureParam = closureParam(alloc, closureType);
	immutable ConcreteExpr closure = empty(closureArgs)
		? immutable ConcreteExpr(
			closureType,
			range,
			immutable ConcreteExprKind(immutable Constant(immutable Constant.Void())))
		: createAllocExpr(alloc, immutable ConcreteExpr(
			byVal(closureType),
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.CreateRecord(closureArgs))));

	immutable Ptr!ConcreteFun fun = getConcreteFunForLambdaAndFillBody(
		alloc,
		ctx.concretizeCtx,
		ctx.currentConcreteFunPtr,
		lambdaIndex,
		getConcreteType(alloc, ctx, e.returnType),
		closureParam,
		params,
		ctx.containing,
		e.body_);
	immutable ConcreteLambdaImpl impl = immutable ConcreteLambdaImpl(closureType, fun);
	immutable(ConcreteExprKind) lambda(immutable Ptr!ConcreteStruct funStruct) {
		return immutable ConcreteExprKind(
			allocate(alloc, immutable ConcreteExprKind.Lambda(
				nextLambdaImplId(alloc, ctx.concretizeCtx, funStruct, impl),
				closure)));
	}
	if (e.kind == FunKind.ref_) {
		// For a fun-ref this is the inner 'act' type.
		immutable ConcreteField[] fields = asRecord(body_(concreteStruct.deref())).fields;
		verify(fields.length == 2);
		immutable ConcreteField islandAndExclusionField = fields[0];
		verify(symEq(name(islandAndExclusionField), symForSpecial(SpecialSym.island_and_exclusion)));
		immutable ConcreteField actionField = fields[1];
		verify(symEq(name(actionField), shortSym("action")));
		immutable ConcreteType funType = actionField.type;
		immutable ConcreteExpr islandAndExclusion =
			getGetIslandAndExclusion(alloc, ctx, islandAndExclusionField.type, range);
		return immutable ConcreteExpr(concreteType, range, immutable ConcreteExprKind(
			immutable ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(alloc, [
				islandAndExclusion,
				immutable ConcreteExpr(funType, range, lambda(mustBeNonPointer(funType)))]))));
	} else
		return immutable ConcreteExpr(concreteType, range, lambda(concreteStruct));
}

public immutable(size_t) nextLambdaImplId(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!ConcreteStruct funStruct,
	immutable ConcreteLambdaImpl impl,
) {
	return nextLambdaImplIdInner(alloc, impl, getOrAdd(alloc, ctx.funStructToImpls, funStruct, () =>
		MutArr!(immutable ConcreteLambdaImpl)()));
}
immutable(size_t) nextLambdaImplIdInner(
	ref Alloc alloc,
	immutable ConcreteLambdaImpl impl,
	ref MutArr!(immutable ConcreteLambdaImpl) impls,
) {
	immutable size_t res = mutArrSize(impls);
	push(alloc, impls, impl);
	return res;
}

immutable(Ptr!ConcreteLocal) makeLocalWorker(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local source,
	immutable ConcreteType type,
) {
	immutable Ptr!ConcreteLocal res = allocate(alloc, immutable ConcreteLocal(source, ctx.nextLocalIndex, type));
	ctx.nextLocalIndex++;
	return res;
}

immutable(Ptr!ConcreteLocal) concretizeLocal(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local local,
) {
	return makeLocalWorker(alloc, ctx, local, getConcreteType(alloc, ctx, local.deref().type));
}

alias Locals = immutable StackDict!(
	immutable Ptr!Local,
	immutable LocalOrConstant,
	nullPtr!Local,
	ptrEquals!Local);
alias addLocal = stackDictAdd!(
	immutable Ptr!Local,
	immutable LocalOrConstant,
	nullPtr!Local,
	ptrEquals!Local);
alias getLocal = stackDictMustGet!(
	immutable Ptr!Local,
	immutable LocalOrConstant,
	nullPtr!Local,
	ptrEquals!Local);

immutable(ConcreteExpr) concretizeWithLocal(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	immutable Ptr!Local modelLocal,
	ref immutable LocalOrConstant concreteLocal,
	ref immutable Expr expr,
) {
	scope immutable Locals newLocals = addLocal(locals, modelLocal, concreteLocal);
	return concretizeExpr(alloc, ctx, newLocals, expr);
}

immutable(ConcreteExpr) concretizeLet(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.Let e,
) {
	immutable ConcreteExpr value = concretizeExpr(alloc, ctx, locals, e.value);
	immutable LocalOrConstant localOrConstant = isConstant(value.kind)
		? immutable LocalOrConstant(immutable TypedConstant(value.type, asConstant(value.kind)))
		: immutable LocalOrConstant(concretizeLocal(alloc, ctx, e.local));
	immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, locals, e.local, localOrConstant, e.then);
	return matchLocalOrConstant!(immutable ConcreteExpr)(
		localOrConstant,
		(immutable Ptr!ConcreteLocal local) =>
			immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
				allocate(alloc, immutable ConcreteExprKind.Let(local, value, then)))),
		(immutable TypedConstant) =>
			then);
}

immutable(ConcreteExpr) concretizeIfOption(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.IfOption e,
) {
	immutable ConcreteExpr option = concretizeExpr(alloc, ctx, locals, e.option);
	if (isConstant(option.kind))
		return todo!(immutable ConcreteExpr)("constant option");
	else {
		immutable ConcreteType someType = force(asUnion(body_(mustBeNonPointer(option.type).deref())).members[1]);
		immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
		immutable ConcreteExprKind.MatchUnion.Case noneCase = immutable ConcreteExprKind.MatchUnion.Case(
			none!(Ptr!ConcreteLocal),
			concretizeExpr(alloc, ctx, locals, e.else_));
		immutable Ptr!ConcreteLocal someLocal = makeLocalWorker(alloc, ctx, e.local, someType);
		immutable LocalOrConstant lc = immutable LocalOrConstant(someLocal);
		immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, locals, e.local, lc, e.then);
		immutable ConcreteExprKind.MatchUnion.Case someCase =
			immutable ConcreteExprKind.MatchUnion.Case(some(someLocal), then);
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			allocate(alloc, immutable ConcreteExprKind.MatchUnion(
				option,
				arrLiteral!(ConcreteExprKind.MatchUnion.Case)(alloc, [noneCase, someCase])))));
	}
}

immutable(ConcreteExpr) concretizeLocalRef(
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.LocalRef e,
) {
	return matchLocalOrConstant!(immutable ConcreteExpr)(
		getLocal(locals, e.local),
		(immutable Ptr!ConcreteLocal local) =>
			immutable ConcreteExpr(local.deref().type, range, immutable ConcreteExprKind(
				immutable ConcreteExprKind.LocalRef(local))),
		(immutable TypedConstant it) =>
			immutable ConcreteExpr(it.type, range, immutable ConcreteExprKind(it.value)));
}

immutable(ConcreteExpr) concretizeMatchEnum(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.MatchEnum e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, locals, e.matched);
	//TODO: If matched is a constant, just compile the relevant case
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	immutable ConcreteExpr[] cases = map!ConcreteExpr(alloc, e.cases, (ref immutable Expr case_) =>
		concretizeExpr(alloc, ctx, locals, case_));
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		allocate(alloc, immutable ConcreteExprKind.MatchEnum(matched, cases))));
}

immutable(ConcreteExpr) concretizeMatchUnion(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	scope ref immutable Locals locals,
	ref immutable Expr.MatchUnion e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, locals, e.matched);
	immutable ConcreteType ct = getConcreteType_forStructInst(alloc, ctx, e.matchedUnion);
	immutable Ptr!ConcreteStruct matchedUnion = mustBeNonPointer(ct);
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	if (isConstant(matched.kind)) {
		immutable Constant.Union u = asUnion(asConstant(matched.kind));
		immutable Expr.MatchUnion.Case case_ = e.cases[u.memberIndex];
		if (has(case_.local)) {
			immutable ConcreteType caseType = force(asUnion(body_(matchedUnion.deref())).members[u.memberIndex]);
			immutable LocalOrConstant lc = immutable LocalOrConstant(immutable TypedConstant(caseType, u.arg));
			return concretizeWithLocal(alloc, ctx, locals, force(case_.local), lc, case_.then);
		} else
			return concretizeExpr(alloc, ctx, locals, case_.then);
	} else {
		immutable ConcreteExprKind.MatchUnion.Case[] cases = map!(ConcreteExprKind.MatchUnion.Case)(
			alloc,
			e.cases,
			(ref immutable Expr.MatchUnion.Case case_) {
				if (has(case_.local)) {
					immutable Ptr!ConcreteLocal local = concretizeLocal(alloc, ctx, force(case_.local));
					immutable LocalOrConstant lc = immutable LocalOrConstant(local);
					immutable ConcreteExpr then =
						concretizeWithLocal(alloc, ctx, locals, force(case_.local), lc, case_.then);
					return immutable ConcreteExprKind.MatchUnion.Case(some(local), then);
				} else
					return immutable ConcreteExprKind.MatchUnion.Case(
						none!(Ptr!ConcreteLocal),
						concretizeExpr(alloc, ctx, locals, case_.then));
			});
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			allocate(alloc, immutable ConcreteExprKind.MatchUnion(matched, cases))));
	}
}

immutable(ConcreteExpr) concretizeParamRef(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ParamRef e,
) {
	immutable size_t paramIndex = e.param.deref().index;
	// NOTE: we'll never see a ParamRef to a param from outside of a lambda --
	// that would be a ClosureFieldRef instead.
	immutable Ptr!ConcreteParam concreteParam = ptrAt(ctx.currentConcreteFun.paramsExcludingCtxAndClosure, paramIndex);
	return immutable ConcreteExpr(concreteParam.deref().type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(concreteParam)));
}

immutable(ConcreteExpr) concretizeExpr(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	scope ref immutable Locals locals,
	ref immutable Expr e,
) {
	immutable FileAndRange range = range(e);
	return matchExpr!(immutable ConcreteExpr)(
		e,
		(ref immutable Expr.Bogus) =>
			unreachable!(immutable ConcreteExpr),
		(ref immutable Expr.Call e) =>
			concretizeCall(alloc, ctx, range, locals, e),
		(ref immutable Expr.ClosureFieldRef e) =>
			concretizeClosureFieldRef(alloc, ctx, range, e),
		(ref immutable Expr.Cond e) {
			immutable ConcreteExpr cond = concretizeExpr(alloc, ctx, locals, e.cond);
			return isConstant(cond.kind)
				? concretizeExpr(alloc, ctx, locals, asBool(asConstant(cond.kind)) ? e.then : e.else_)
				: immutable ConcreteExpr(
					getConcreteType(alloc, ctx, e.type),
					range,
					immutable ConcreteExprKind(allocate(alloc, immutable ConcreteExprKind.Cond(
						cond,
						concretizeExpr(alloc, ctx, locals, e.then),
						concretizeExpr(alloc, ctx, locals, e.else_)))));
		},
		(ref immutable Expr.FunPtr e) =>
			concretizeFunPtr(alloc, ctx, range, e),
		(ref immutable Expr.IfOption e) =>
			concretizeIfOption(alloc, ctx, range, locals, e),
		(ref immutable Expr.Lambda e) =>
			concretizeLambda(alloc, ctx, range, locals, e),
		(ref immutable Expr.Let e) =>
			concretizeLet(alloc, ctx, range, locals, e),
		(ref immutable Expr.Literal e) =>
			immutable ConcreteExpr(
				getConcreteType_forStructInst(alloc, ctx, e.structInst),
				range,
				immutable ConcreteExprKind(e.value)),
		(ref immutable Expr.LocalRef e) =>
			concretizeLocalRef(range, locals, e),
		(ref immutable Expr.MatchEnum e) =>
			concretizeMatchEnum(alloc, ctx, range, locals, e),
		(ref immutable Expr.MatchUnion e) =>
			concretizeMatchUnion(alloc, ctx, range, locals, e),
		(ref immutable Expr.ParamRef e) =>
			concretizeParamRef(alloc, ctx, range, e),
		(ref immutable Expr.Seq e) {
			immutable ConcreteExpr first = concretizeExpr(alloc, ctx, locals, e.first);
			immutable ConcreteExpr then = concretizeExpr(alloc, ctx, locals, e.then);
			return isConstant(first.kind)
				? then
				: immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
					allocate(alloc, immutable ConcreteExprKind.Seq(first, then))));
		},
		(ref immutable Expr.CStringLiteral e) =>
			immutable ConcreteExpr(
				cStrType(alloc, ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(constantCStr(alloc, ctx.concretizeCtx, e.value))),
		(ref immutable Expr.SymbolLiteral e) =>
			immutable ConcreteExpr(
				symType(alloc, ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(constantSym(alloc, ctx.concretizeCtx, e.value))));
}

immutable(ConstantsOrExprs) constantsOrExprsArr(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	ref immutable ConstantsOrExprs args,
	ref immutable ConcreteType arrayType,
) {
	immutable Ptr!ConcreteStruct arrayStruct = mustBeNonPointer(arrayType);
	return matchConstantsOrExprs(
		args,
		(ref immutable Constant[] constants) =>
			immutable ConstantsOrExprs(arrLiteral!Constant(alloc, [
				getConstantArr(alloc, ctx.concretizeCtx.allConstants, arrayStruct, constants)])),
		(ref immutable ConcreteExpr[] exprs) =>
			immutable ConstantsOrExprs(arrLiteral!ConcreteExpr(alloc, [
				immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
					allocate(alloc, immutable ConcreteExprKind.CreateArr(arrayStruct, exprs))))])));
}

immutable(Constant) evalConstant(ref immutable ConcreteFun fn, immutable Constant[] /*parameters*/) {
	return todo!(immutable Constant)("evalConstant");
}
