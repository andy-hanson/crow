module concretize.concretizeExpr;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : getConstantArr;
import concretize.concretizeCtx :
	ConcretizeCtx,
	ConcreteFunKey,
	concreteTypeFromClosure,
	concretizeParams,
	constantStr,
	constantSym,
	ContainingFunInfo,
	getOrAddNonTemplateConcreteFunAndFillBody,
	getConcreteType_fromConcretizeCtx = getConcreteType,
	getConcreteType_forStructInst_fromConcretizeCtx = getConcreteType_forStructInst,
	getCurIslandAndExclusionFun,
	getOrAddConcreteFunAndFillBody,
	getConcreteFunForLambdaAndFillBody,
	strType,
	symType,
	typeArgsScope,
	TypeArgsScope,
	typesToConcreteTypes_fromConcretizeCtx = typesToConcreteTypes;
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
	ConcreteLocalSource,
	ConcreteParam,
	ConcreteParamSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	isConstant,
	isSummon,
	mustBeNonPointer,
	name,
	purity,
	returnType;
import model.constant : asBool, asRecord, asUnion, Constant;
import model.model :
	Called,
	ClosureField,
	elementType,
	Expr,
	FunInst,
	FunKind,
	Local,
	matchCalled,
	matchExpr,
	Purity,
	range,
	RecordField,
	specImpls,
	SpecSig,
	StructInst,
	Type,
	typeArgs;
import util.collection.arr : at, empty, emptyArr, onlyPtr, ptrAt, size;
import util.collection.arrUtil : arrLiteral, every, map, mapWithIndex;
import util.collection.mutArr : MutArr, mutArrSize, push;
import util.collection.mutDict : addToMutDict, getOrAdd, mustDelete, mustGetAt_mut, MutDict;
import util.memory : allocate, nu;
import util.opt : force, forcePtr, has, none, some;
import util.ptr : comparePtr, Ptr, ptrTrustMe, ptrTrustMe_mut;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, symEq, symEqLongAlphaLiteral;
import util.types : safeSizeTToU8, safeSizeTToU16;
import util.util : todo, unreachable, verify;

immutable(ConcreteExpr) concretizeExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ContainingFunInfo containing,
	immutable Ptr!ConcreteFun cf,
	ref immutable Expr e,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(ptrTrustMe_mut(ctx), containing, cf);
	return concretizeExpr(alloc, exprCtx, e);
}

immutable(Ptr!ConcreteExpr) allocExpr(Alloc)(ref Alloc alloc, immutable ConcreteExpr e) {
	return allocate(alloc, e);
}

private:

// TODO: command line flag? (default to true)
immutable bool inlineConstants = true;

struct ConcretizeExprCtx {
	Ptr!ConcretizeCtx concretizeCtx;
	immutable ContainingFunInfo containing;
	immutable Ptr!ConcreteFun currentConcreteFun; // This is the ConcreteFun* for a lambda, not its containing fun
	size_t nextLambdaIndex = 0;
	size_t nextLocalIndex = 0;

	// Contains only the locals that are currently in scope.
	MutDict!(immutable Ptr!Local, immutable LocalOrConstant, comparePtr!Local) locals;
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
	ref immutable LocalOrConstant a,
	scope T delegate(immutable Ptr!ConcreteLocal) @safe @nogc pure nothrow cbLocal,
	scope T delegate(ref immutable TypedConstant) @safe @nogc pure nothrow cbTypedConstant,
) {
	final switch (a.kind_) {
		case LocalOrConstant.Kind.local:
			return cbLocal(a.local_);
		case LocalOrConstant.Kind.typedConstant:
			return cbTypedConstant(a.typedConstant_);
	}
}

immutable(ConcreteType) getConcreteType(Alloc)(ref Alloc alloc, ref ConcretizeExprCtx ctx, ref immutable Type t) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_fromConcretizeCtx(alloc, ctx.concretizeCtx.deref, t, s);
}

immutable(ConcreteType) getConcreteType_forStructInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!StructInst i,
) {
	immutable TypeArgsScope s = typeScope(ctx);
	return getConcreteType_forStructInst_fromConcretizeCtx(alloc, ctx.concretizeCtx, i, s);
}

immutable(ConcreteType[]) typesToConcreteTypes(Alloc)(
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

immutable(ConcreteExpr) concretizeCall(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Call e,
) {
	immutable Ptr!ConcreteFun concreteCalled = getConcreteFunFromCalled(alloc, ctx, e.called);
	immutable ConstantsOrExprs args =
		!isSummon(concreteCalled) && purity(concreteCalled.returnType) == Purity.data && false // TODO
			? getConstantsOrExprs(alloc, ctx, e.args)
			: immutable ConstantsOrExprs(getArgs(alloc, ctx, e.args));
	return matchConstantsOrExprs!(immutable ConcreteExpr)(
		args,
		(ref immutable Constant[] constants) => immutable ConcreteExpr(
			concreteCalled.returnType,
			range,
			immutable ConcreteExprKind(evalConstant(concreteCalled, constants))),
		(ref immutable ConcreteExpr[] exprs) => immutable ConcreteExpr(
			concreteCalled.returnType,
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.Call(concreteCalled, exprs))));
}

immutable(Ptr!ConcreteFun) getConcreteFunFromCalled(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Called called,
) {
	return matchCalled(
		called,
		(immutable Ptr!FunInst funInst) =>
			getConcreteFunFromFunInst(alloc, ctx, funInst),
		(ref immutable SpecSig specSig) =>
			at(ctx.containing.specImpls, specSig.indexOverAllSpecUses));
}

immutable(Ptr!ConcreteFun) getConcreteFunFromFunInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!FunInst funInst,
) {
	immutable ConcreteType[] typeArgs = typesToConcreteTypes(alloc, ctx, typeArgs(funInst.deref));
	immutable Ptr!ConcreteFun[] specImpls = map!(Ptr!ConcreteFun)(
		alloc,
		specImpls(funInst),
		(ref immutable Called it) => getConcreteFunFromCalled(alloc, ctx, it));
	immutable ConcreteFunKey key = immutable ConcreteFunKey(funInst, typeArgs, specImpls);
	return getOrAddConcreteFunAndFillBody(alloc, ctx.concretizeCtx, key);
}

immutable(ConcreteExpr) concretizeClosureFieldRef(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ClosureFieldRef e,
) {
	immutable Ptr!ConcreteParam closureParam = forcePtr(ptrTrustMe(ctx.currentConcreteFun.closureParam));
	immutable ConcreteType closureType = closureParam.type;
	immutable ConcreteStructBody.Record record = asRecord(body_(closureType.struct_));
	immutable Ptr!ConcreteField field = ptrAt(record.fields, e.field.index);
	immutable ConcreteExpr closureParamRef = immutable ConcreteExpr(closureType, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(closureParam)));
	return immutable ConcreteExpr(field.type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.RecordFieldGet(allocExpr(alloc, closureParamRef), field)));
}

struct ConstantsOrExprs {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Constant[] a) {
		verify(inlineConstants);
		kind_ = Kind.constants;
		constants = a;
	}
	@trusted immutable this(immutable ConcreteExpr[] a) { kind_ = Kind.exprs; exprs = a; }

	private:
	enum Kind {
		constants,
		exprs,
	}
	immutable Kind kind_;
	union {
		immutable Constant[] constants;
		immutable ConcreteExpr[] exprs;
	}
}

@trusted T matchConstantsOrExprs(T)(
	ref immutable ConstantsOrExprs a,
	scope T delegate(ref immutable Constant[]) @safe @nogc pure nothrow cbConstants,
	scope T delegate(ref immutable ConcreteExpr[]) @safe @nogc pure nothrow cbExprs,
) {
	final switch (a.kind_) {
		case ConstantsOrExprs.Kind.constants:
			return cbConstants(a.constants);
		case ConstantsOrExprs.Kind.exprs:
			return cbExprs(a.exprs);
	}
}

immutable(ConstantsOrExprs) getConstantsOrExprs(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Expr[] argExprs,
) {
	immutable ConcreteExpr[] exprs = getArgs(alloc, ctx, argExprs);
	return inlineConstants && every!ConcreteExpr(exprs, (ref immutable ConcreteExpr arg) => isConstant(arg.kind))
		? immutable ConstantsOrExprs(map(alloc, exprs, (ref immutable ConcreteExpr arg) => asConstant(arg.kind)))
		: immutable ConstantsOrExprs(exprs);
}

immutable(ConcreteExpr[]) getArgs(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Expr[] argExprs,
) {
	return map(alloc, argExprs, (ref immutable Expr arg) =>
		concretizeExpr(alloc, ctx, arg));
}

immutable(ConcreteExpr) createAllocExpr(Alloc)(ref Alloc alloc, immutable ConcreteExpr inner) {
	verify(!inner.type.isPointer);
	return immutable ConcreteExpr(
		byRef(inner.type),
		inner.range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.Alloc(allocExpr(alloc, inner))));
}

immutable(ConcreteExpr) getGetIslandAndExclusion(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable ConcreteType type,
	ref immutable FileAndRange range,
) {
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.Call(getCurIslandAndExclusionFun(alloc, ctx.concretizeCtx), emptyArr!ConcreteExpr)));
}

immutable(ConcreteField[]) concretizeClosureFields(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Ptr!ClosureField[] closure,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return mapWithIndex!ConcreteField(alloc, closure, (immutable size_t index, ref immutable Ptr!ClosureField it) =>
		immutable ConcreteField(
			immutable ConcreteFieldSource(it),
			safeSizeTToU8(index),
			false,
			getConcreteType_fromConcretizeCtx(alloc, ctx, it.type, typeArgsScope)));
}

immutable(ConcreteExpr) concretizeFunPtr(Alloc)(
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

immutable(ConcreteExpr) concretizeLambda(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
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
			concretizeExpr(alloc, ctx, f.expr));
	immutable ConcreteField[] closureFields =
		concretizeClosureFields(alloc, ctx.concretizeCtx, e.closure, tScope);
	immutable ConcreteType closureType = concreteTypeFromClosure(
		alloc,
		ctx.concretizeCtx,
		closureFields,
		immutable ConcreteStructSource(
			immutable ConcreteStructSource.Lambda(ctx.currentConcreteFun, lambdaIndex)));
	immutable Ptr!ConcreteParam closureParam = nu!ConcreteParam(
		alloc,
		immutable ConcreteParamSource(immutable ConcreteParamSource.Closure()),
		none!size_t,
		closureType);
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
		ctx.currentConcreteFun,
		lambdaIndex,
		getConcreteType(alloc, ctx, e.returnType),
		closureParam,
		params,
		ctx.containing,
		ptrTrustMe(e.body_));
	immutable ConcreteLambdaImpl impl = immutable ConcreteLambdaImpl(closureType, fun);
	immutable(ConcreteExprKind) lambda(immutable Ptr!ConcreteStruct funStruct) {
		return immutable ConcreteExprKind(
			immutable ConcreteExprKind.Lambda(
				nextLambdaImplId(alloc, ctx, funStruct, impl),
				allocate(alloc, closure)));
	}
	if (e.kind == FunKind.ref_) {
		// For a fun-ref this is the inner 'act' type.
		immutable ConcreteField[] fields = asRecord(body_(concreteStruct)).fields;
		verify(size(fields) == 2);
		immutable ConcreteField islandAndExclusionField = at(fields, 0);
		verify(symEqLongAlphaLiteral(name(islandAndExclusionField), "island-and-exclusion"));
		immutable ConcreteField funField = at(fields, 1);
		verify(symEq(name(funField), shortSymAlphaLiteral("fun")));
		immutable ConcreteType funType = funField.type;
		immutable ConcreteExpr islandAndExclusion =
			getGetIslandAndExclusion(alloc, ctx, islandAndExclusionField.type, range);
		return immutable ConcreteExpr(concreteType, range, immutable ConcreteExprKind(
			immutable ConcreteExprKind.CreateRecord(arrLiteral!ConcreteExpr(alloc, [
				islandAndExclusion,
				immutable ConcreteExpr(funType, range, lambda(mustBeNonPointer(funType)))]))));
	} else
		return immutable ConcreteExpr(concreteType, range, lambda(concreteStruct));
}

immutable(ushort) nextLambdaImplId(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!ConcreteStruct funStruct,
	ref immutable ConcreteLambdaImpl impl,
) {
	return nextLambdaImplIdInner!Alloc(
		alloc,
		impl,
		getOrAdd(alloc, ctx.concretizeCtx.funStructToImpls, funStruct, () =>
			MutArr!(immutable ConcreteLambdaImpl)()));
}
immutable(ushort) nextLambdaImplIdInner(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteLambdaImpl impl,
	ref MutArr!(immutable ConcreteLambdaImpl) impls,
) {
	immutable ushort res = safeSizeTToU16(mutArrSize(impls));
	push(alloc, impls, impl);
	return res;
}

immutable(Ptr!ConcreteLocal) makeLocalWorker(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable ConcreteLocalSource source,
	immutable ConcreteType type,
) {
	immutable Ptr!ConcreteLocal res = nu!ConcreteLocal(alloc, source, ctx.nextLocalIndex, type);
	ctx.nextLocalIndex++;
	return res;
}

immutable(Ptr!ConcreteLocal) concretizeLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local local,
) {
	return makeLocalWorker(alloc, ctx, immutable ConcreteLocalSource(local), getConcreteType(alloc, ctx, local.type));
}

immutable(ConcreteExpr) concretizeWithLocal(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable Ptr!Local modelLocal,
	ref immutable LocalOrConstant concreteLocal,
	ref immutable Expr expr,
) {
	addToMutDict(alloc, ctx.locals, modelLocal, concreteLocal);
	immutable ConcreteExpr res = concretizeExpr(alloc, ctx, expr);
	mustDelete(ctx.locals, modelLocal);
	return res;
}

immutable(ConcreteExpr) concretizeLet(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.Let e,
) {
	immutable Ptr!ConcreteExpr value = allocExpr(alloc, concretizeExpr(alloc, ctx, e.value));
	immutable LocalOrConstant localOrConstant = isConstant(value.kind)
		? immutable LocalOrConstant(immutable TypedConstant(value.type, asConstant(value.kind)))
		: immutable LocalOrConstant(concretizeLocal(alloc, ctx, e.local));
	immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, e.local, localOrConstant, e.then);
	return matchLocalOrConstant!(immutable ConcreteExpr)(
		localOrConstant,
		(immutable Ptr!ConcreteLocal local) =>
			immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
				immutable ConcreteExprKind.Let(local, value, allocExpr(alloc, then)))),
		(ref immutable TypedConstant) =>
			then);
}

immutable(ConcreteExpr) concretizeIfOption(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.IfOption e,
) {
	immutable ConcreteExpr option = concretizeExpr(alloc, ctx, e.option);
	if (inlineConstants && isConstant(option.kind)) {
		return todo!(immutable ConcreteExpr)("constant option");
	} else {
		immutable ConcreteType someType = at(asUnion(body_(mustBeNonPointer(option.type).deref())).members, 1);
		immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
		immutable ConcreteExprKind.MatchUnion.Case noneCase = immutable ConcreteExprKind.MatchUnion.Case(
			none!(Ptr!ConcreteLocal),
			concretizeExpr(alloc, ctx, e.else_));
		// Local for the 'some'
		immutable Ptr!ConcreteLocal someLocal = makeLocalWorker(
			alloc,
			ctx,
			immutable ConcreteLocalSource(immutable ConcreteLocalSource.Matched()),
			someType);
		// Local for the 'value' of the 'some'
		immutable Ptr!ConcreteLocal valueLocal = concretizeLocal(alloc, ctx, e.local);
		immutable LocalOrConstant lc = immutable LocalOrConstant(valueLocal);
		immutable ConcreteExpr then = immutable ConcreteExpr(
			type,
			range,
			immutable ConcreteExprKind(immutable ConcreteExprKind.Let(
				valueLocal,
				allocExpr(alloc, getSomeValue(alloc, range, someLocal, valueLocal.type)),
				allocExpr(alloc, concretizeWithLocal(alloc, ctx, e.local, lc, e.then)))));
		immutable ConcreteExprKind.MatchUnion.Case someCase =
			immutable ConcreteExprKind.MatchUnion.Case(some(someLocal), then);
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(immutable ConcreteExprKind.MatchUnion(
			allocExpr(alloc, option),
			arrLiteral!(ConcreteExprKind.MatchUnion.Case)(alloc, [noneCase, someCase]))));
	}
}

immutable(ConcreteExpr) getSomeValue(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable Ptr!ConcreteLocal someLocal,
	ref immutable ConcreteType valueType,
) {
	immutable Ptr!ConcreteField field = onlyPtr(asRecord(body_(mustBeNonPointer(someLocal.type).deref())).fields);
	immutable Ptr!ConcreteExpr target = allocate(alloc, immutable ConcreteExpr(
		someLocal.type,
		range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.LocalRef(someLocal))));
	return immutable ConcreteExpr(
		valueType,
		range,
		immutable ConcreteExprKind(immutable ConcreteExprKind.RecordFieldGet(target, field)));
}

immutable(ConcreteExpr) concretizeMatchEnum(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.MatchEnum e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, e.matched);
	//TODO: If matched is a constant, just compile the relevant case
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	immutable ConcreteExpr[] cases = map!ConcreteExpr(alloc, e.cases, (ref immutable Expr case_) =>
		concretizeExpr(alloc, ctx, case_));
	return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.MatchEnum(allocExpr(alloc, matched), cases)));
}

immutable(ConcreteExpr) concretizeMatchUnion(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.MatchUnion e,
) {
	immutable ConcreteExpr matched = concretizeExpr(alloc, ctx, e.matched);
	immutable ConcreteType ct = getConcreteType_forStructInst(alloc, ctx, e.matchedUnion);
	immutable Ptr!ConcreteStruct matchedUnion = mustBeNonPointer(ct);
	immutable ConcreteType type = getConcreteType(alloc, ctx, e.type);
	if (isConstant(matched.kind)) {
		immutable Constant.Union u = asUnion(asConstant(matched.kind));
		immutable Expr.MatchUnion.Case case_ = at(e.cases, u.memberIndex);
		if (has(case_.local)) {
			immutable ConcreteType caseType = at(asUnion(body_(matchedUnion)).members, u.memberIndex);
			immutable LocalOrConstant lc = immutable LocalOrConstant(immutable TypedConstant(caseType, u.arg));
			return concretizeWithLocal(alloc, ctx, force(case_.local), lc, case_.then);
		} else
			return concretizeExpr(alloc, ctx, case_.then);
	} else {
		immutable ConcreteExprKind.MatchUnion.Case[] cases = map!(ConcreteExprKind.MatchUnion.Case)(
			alloc,
			e.cases,
			(ref immutable Expr.MatchUnion.Case case_) {
				if (has(case_.local)) {
					immutable Ptr!ConcreteLocal local = concretizeLocal(alloc, ctx, force(case_.local));
					immutable LocalOrConstant lc = immutable LocalOrConstant(local);
					immutable ConcreteExpr then = concretizeWithLocal(alloc, ctx, force(case_.local), lc, case_.then);
					return immutable ConcreteExprKind.MatchUnion.Case(some(local), then);
				} else
					return immutable ConcreteExprKind.MatchUnion.Case(
						none!(Ptr!ConcreteLocal),
						concretizeExpr(alloc, ctx, case_.then));
			});
		return immutable ConcreteExpr(type, range, immutable ConcreteExprKind(
			immutable ConcreteExprKind.MatchUnion(allocExpr(alloc, matched), cases)));
	}
}

immutable(ConcreteExpr) concretizeParamRef(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable FileAndRange range,
	ref immutable Expr.ParamRef e,
) {
	immutable size_t paramIndex = e.param.index;
	// NOTE: we'll never see a ParamRef to a param from outside of a lambda --
	// that would be a ClosureFieldRef instead.
	immutable Ptr!ConcreteParam concreteParam = ptrAt(ctx.currentConcreteFun.paramsExcludingCtxAndClosure, paramIndex);
	return immutable ConcreteExpr(concreteParam.type, range, immutable ConcreteExprKind(
		immutable ConcreteExprKind.ParamRef(concreteParam)));
}

immutable(Ptr!ConcreteField) getMatchingField(immutable Ptr!ConcreteStruct struct_, immutable size_t fieldIndex) {
	return ptrAt(asRecord(body_(struct_)).fields, fieldIndex);
}

immutable(Ptr!ConcreteField) getMatchingField(Alloc)(
	ref Alloc alloc,
	ref const ConcretizeExprCtx ctx,
	immutable Ptr!StructInst targetType,
	immutable Ptr!RecordField field,
) {
	immutable ConcreteType type = getConcreteType_forStructInst(alloc, ctx, targetType);
	return getMatchingField(type, field.index);
}

immutable(ConcreteExpr) concretizeExpr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	ref immutable Expr e,
) {
	immutable FileAndRange range = range(e);
	return matchExpr!(immutable ConcreteExpr)(
		e,
		(ref immutable Expr.Bogus) =>
			unreachable!(immutable ConcreteExpr),
		(ref immutable Expr.Call e) =>
			concretizeCall(alloc, ctx, range, e),
		(ref immutable Expr.ClosureFieldRef e) =>
			concretizeClosureFieldRef(alloc, ctx, range, e),
		(ref immutable Expr.Cond e) {
			immutable ConcreteExpr cond = concretizeExpr(alloc, ctx, e.cond);
			return inlineConstants && isConstant(cond.kind)
				? concretizeExpr(alloc, ctx, asBool(asConstant(cond.kind)) ? e.then : e.else_)
				: immutable ConcreteExpr(
					getConcreteType(alloc, ctx, e.type),
					range,
					immutable ConcreteExprKind(immutable ConcreteExprKind.Cond(
						allocExpr(alloc, cond),
						allocExpr(alloc, concretizeExpr(alloc, ctx, e.then)),
						allocExpr(alloc, concretizeExpr(alloc, ctx, e.else_)))));
		},
		(ref immutable Expr.CreateArr e) =>
			concretizeCreateArr(alloc, ctx, range, e),
		(ref immutable Expr.FunPtr e) =>
			concretizeFunPtr(alloc, ctx, range, e),
		(ref immutable Expr.IfOption e) =>
			concretizeIfOption(alloc, ctx, range, e),
		(ref immutable Expr.ImplicitConvertToUnion e) {
			immutable ConcreteExpr inner = concretizeExpr(alloc, ctx, e.inner);
			immutable ConcreteType unionType = getConcreteType_forStructInst(alloc, ctx, e.unionType);
			if (inlineConstants && isConstant(inner.kind))
				return immutable ConcreteExpr(unionType, range, immutable ConcreteExprKind(immutable Constant(
					immutable Constant.Union(e.memberIndex, allocate(alloc, asConstant(inner.kind))))));
			else
				return immutable ConcreteExpr(unionType, range, immutable ConcreteExprKind(
					immutable ConcreteExprKind.ConvertToUnion(e.memberIndex, allocExpr(alloc, inner))));
		},
		(ref immutable Expr.Lambda e) =>
			concretizeLambda(alloc, ctx, range, e),
		(ref immutable Expr.Let e) =>
			concretizeLet(alloc, ctx, range, e),
		(ref immutable Expr.Literal e) =>
			immutable ConcreteExpr(
				getConcreteType_forStructInst(alloc, ctx, e.structInst),
				range,
				immutable ConcreteExprKind(e.value)),
		(ref immutable Expr.LocalRef e) =>
			matchLocalOrConstant!(immutable ConcreteExpr)(
				mustGetAt_mut(ctx.locals, e.local),
				(immutable Ptr!ConcreteLocal local) =>
					immutable ConcreteExpr(local.type, range, immutable ConcreteExprKind(
						immutable ConcreteExprKind.LocalRef(local))),
				(ref immutable TypedConstant it) =>
					immutable ConcreteExpr(it.type, range, immutable ConcreteExprKind(it.value))),
		(ref immutable Expr.MatchEnum e) =>
			concretizeMatchEnum(alloc, ctx, range, e),
		(ref immutable Expr.MatchUnion e) =>
			concretizeMatchUnion(alloc, ctx, range, e),
		(ref immutable Expr.ParamRef e) =>
			concretizeParamRef(alloc, ctx, range, e),
		(ref immutable Expr.Seq e) {
			immutable ConcreteExpr first = concretizeExpr(alloc, ctx, e.first);
			immutable ConcreteExpr then = concretizeExpr(alloc, ctx, e.then);
			return isConstant(first.kind)
				? then
				: immutable ConcreteExpr(then.type, range, immutable ConcreteExprKind(
					immutable ConcreteExprKind.Seq(allocExpr(alloc, first), allocExpr(alloc, then))));
		},
		(ref immutable Expr.StringLiteral e) =>
			immutable ConcreteExpr(
				strType(alloc, ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(constantStr(alloc, ctx.concretizeCtx, e.literal))),
		(ref immutable Expr.SymbolLiteral e) =>
			immutable ConcreteExpr(
				symType(alloc, ctx.concretizeCtx),
				range,
				immutable ConcreteExprKind(constantSym(alloc, ctx.concretizeCtx, e.value))));
}

immutable(ConcreteExpr) concretizeCreateArr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeExprCtx ctx,
	immutable FileAndRange range,
	ref immutable Expr.CreateArr e,
) {
	immutable ConstantsOrExprs args = getConstantsOrExprs(alloc, ctx, e.args);
	immutable ConcreteType arrayType = getConcreteType_forStructInst(alloc, ctx, e.arrType);
	immutable Ptr!ConcreteStruct arrayStruct = mustBeNonPointer(arrayType);
	immutable ConcreteType elementType = getConcreteType(alloc, ctx, elementType(e));
	return matchConstantsOrExprs!(immutable ConcreteExpr)(
		args,
		(ref immutable Constant[] constants) =>
			immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
				getConstantArr(alloc, ctx.concretizeCtx.allConstants, arrayStruct, elementType, constants))),
		(ref immutable ConcreteExpr[] exprs) {
			return immutable ConcreteExpr(arrayType, range, immutable ConcreteExprKind(
				allocate(alloc, immutable ConcreteExprKind.CreateArr(arrayStruct, elementType, exprs))));
		});
}

immutable(Constant) evalConstant(ref immutable ConcreteFun fn, immutable Constant[] /*parameters*/) {
	return todo!(immutable Constant)("evalConstant");
}
